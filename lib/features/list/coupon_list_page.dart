import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/coupon.dart';
import '../../providers.dart';
import '../../ui/feedback.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets/empty_state.dart';
import '../../ui/widgets/section_header.dart';
import '../add/add_coupon_flow.dart';
import '../form/coupon_form_page.dart';
import '../settings/settings_page.dart';
import 'coupon_groups.dart';
import 'coupon_tile.dart';

enum _Filter { active, expired, used }

class CouponListPage extends ConsumerStatefulWidget {
  const CouponListPage({super.key});

  @override
  ConsumerState<CouponListPage> createState() => _CouponListPageState();
}

class _CouponListPageState extends ConsumerState<CouponListPage> {
  _Filter _filter = _Filter.active;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _inFilter(Coupon c, _Filter f, DateTime now) {
    switch (f) {
      case _Filter.used:
        return c.isUsed;
      case _Filter.expired:
        return !c.isUsed && c.isExpired(now);
      case _Filter.active:
        return !c.isUsed && !c.isExpired(now);
    }
  }

  Future<void> _toggleUsed(Coupon c) async {
    final repo = ref.read(couponRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final next = c.isUsed ? CouponStatus.active : CouponStatus.used;
    await repo.setStatus(c.id, next);
    haptic();
    showUndoSnackBar(
      messenger,
      next == CouponStatus.used ? 'Segnato come usato' : 'Coupon riattivato',
      () => repo.setStatus(c.id, c.status),
    );
  }

  Future<void> _delete(Coupon c) async {
    final repo = ref.read(couponRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.delete(c.id);
    haptic();
    showUndoSnackBar(messenger, 'Coupon eliminato', () => repo.upsert(c));
  }

  /// Long-press menu: the same actions as the swipe, reachable without a swipe.
  Future<void> _showActions(Coupon c) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.s),
              child: Text(c.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            ListTile(
              leading: Icon(c.isUsed ? Icons.undo : Icons.check_circle_outline),
              title: Text(c.isUsed ? 'Riattiva' : 'Segna come usato'),
              onTap: () => Navigator.pop(context, 'used'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Modifica'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Elimina'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'used':
        await _toggleUsed(c);
      case 'edit':
        await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => CouponFormPage(existing: c)));
      case 'delete':
        await _delete(c);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupons = ref.watch(couponsProvider);
    final now = DateTime.now();

    return Scaffold(
      // With no coupons the empty state already offers the action.
      floatingActionButton: (coupons.value?.isEmpty ?? true)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showAddCouponSheet(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi'),
            ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: const Text('Coupon'),
            actions: [
              IconButton(
                tooltip: 'Impostazioni',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SettingsPage())),
              ),
            ],
          ),
          ...coupons.when(
            loading: () => [
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (e, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Errore: $e')),
              ),
            ],
            data: (all) => _content(all, now),
          ),
          // Room for the floating button under the last item.
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  List<Widget> _content(List<Coupon> all, DateTime now) {
    final counts = {
      for (final f in _Filter.values) f: all.where((c) => _inFilter(c, f, now)).length,
    };
    final query = _search.text;
    var shown = all
        .where((c) => _inFilter(c, _filter, now) && matchesQuery(c, query))
        .toList();
    if (_filter != _Filter.active) {
      shown.sort((a, b) =>
          (b.expiresAt ?? b.createdAt).compareTo(a.expiresAt ?? a.createdAt));
    }

    final slivers = <Widget>[];

    if (all.isNotEmpty) {
      slivers.add(SliverToBoxAdapter(child: _searchBar()));
      slivers.add(SliverToBoxAdapter(child: _filterChips(counts)));
    }

    if (shown.isEmpty) {
      slivers.add(SliverFillRemaining(
        hasScrollBody: false,
        child: _emptyState(all.isEmpty, query.trim().isNotEmpty),
      ));
      return slivers;
    }

    Widget tile(Coupon c) => CouponTile(
          coupon: c,
          now: now,
          onToggleUsed: () => _toggleUsed(c),
          onDelete: () => _delete(c),
          onMore: () => _showActions(c),
        );

    if (_filter == _Filter.active) {
      for (final group in groupActive(shown, now)) {
        slivers.add(SliverToBoxAdapter(
            child: SectionHeader(group.title, count: group.coupons.length)));
        slivers.add(SliverList.builder(
          itemCount: group.coupons.length,
          itemBuilder: (context, i) => tile(group.coupons[i]),
        ));
      }
    } else {
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: Gap.s)));
      slivers.add(SliverList.builder(
        itemCount: shown.length,
        itemBuilder: (context, i) => tile(shown[i]),
      ));
    }
    return slivers;
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.xs, Gap.l, Gap.s),
      child: TextField(
        controller: _search,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cerca negozio o titolo',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Cancella ricerca',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(_search.clear),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Corner.extraLarge),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Corner.extraLarge),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Corner.extraLarge),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _filterChips(Map<_Filter, int> counts) {
    Widget chip(_Filter f, String label) => Padding(
          padding: const EdgeInsets.only(right: Gap.s),
          child: ChoiceChip(
            label: Text('$label (${counts[f]})'),
            selected: _filter == f,
            onSelected: (_) => setState(() => _filter = f),
          ),
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Gap.l),
      child: Row(children: [
        chip(_Filter.active, 'Attivi'),
        chip(_Filter.expired, 'Scaduti'),
        chip(_Filter.used, 'Usati'),
      ]),
    );
  }

  Widget _emptyState(bool noCouponsAtAll, bool searching) {
    if (noCouponsAtAll) {
      return EmptyState(
        icon: Icons.confirmation_number_outlined,
        title: 'Nessun coupon ancora',
        message: 'Scansiona o fotografa un coupon: ti avviso prima che scada.',
        actionLabel: 'Aggiungi il primo coupon',
        onAction: () => showAddCouponSheet(context, ref),
      );
    }
    if (searching) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'Nessun risultato',
        message: 'Nessun coupon corrisponde a «${_search.text.trim()}».',
      );
    }
    return switch (_filter) {
      _Filter.active => const EmptyState(
          icon: Icons.task_alt,
          title: 'Nessun coupon attivo',
          message: 'Tutti i tuoi coupon sono scaduti o già usati.',
        ),
      _Filter.expired => const EmptyState(
          icon: Icons.history,
          title: 'Nessun coupon scaduto',
          message: 'Bene: non hai lasciato scadere nulla.',
        ),
      _Filter.used => const EmptyState(
          icon: Icons.check_circle_outline,
          title: 'Nessun coupon usato',
          message: 'I coupon che segni come usati compaiono qui.',
        ),
    };
  }
}
