import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/coupon.dart';
import '../../providers.dart';
import '../add/add_coupon_flow.dart';
import '../common/expiry.dart';
import '../detail/coupon_detail_page.dart';

enum _Filter { active, expired, used }

class CouponListPage extends ConsumerStatefulWidget {
  const CouponListPage({super.key});

  @override
  ConsumerState<CouponListPage> createState() => _CouponListPageState();
}

class _CouponListPageState extends ConsumerState<CouponListPage> {
  _Filter _filter = _Filter.active;

  bool _matches(Coupon c, _Filter f, DateTime now) {
    switch (f) {
      case _Filter.used:
        return c.isUsed;
      case _Filter.expired:
        return !c.isUsed && c.isExpired(now);
      case _Filter.active:
        return !c.isUsed && !c.isExpired(now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupons = ref.watch(couponsProvider);
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('I miei coupon')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddCouponSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
      ),
      body: coupons.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (all) {
          final counts = {
            for (final f in _Filter.values)
              f: all.where((c) => _matches(c, f, now)).length,
          };
          final shown = all.where((c) => _matches(c, _filter, now)).toList();
          if (_filter != _Filter.active) {
            shown.sort((a, b) => (b.expiresAt ?? b.createdAt).compareTo(a.expiresAt ?? a.createdAt));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: SegmentedButton<_Filter>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                        value: _Filter.active,
                        label: Text('Attivi (${counts[_Filter.active]})')),
                    ButtonSegment(
                        value: _Filter.expired,
                        label: Text('Scaduti (${counts[_Filter.expired]})')),
                    ButtonSegment(
                        value: _Filter.used,
                        label: Text('Usati (${counts[_Filter.used]})')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? _EmptyState(filter: _filter, hasAny: all.isNotEmpty)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount: shown.length,
                        itemBuilder: (context, i) =>
                            _CouponTile(coupon: shown[i], now: now),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.hasAny});

  final _Filter filter;
  final bool hasAny;

  @override
  Widget build(BuildContext context) {
    final text = !hasAny
        ? 'Nessun coupon ancora.\nPremi "Aggiungi" e scansiona il primo.'
        : switch (filter) {
            _Filter.active => 'Nessun coupon attivo.',
            _Filter.expired => 'Nessun coupon scaduto.',
            _Filter.used => 'Nessun coupon usato.',
          };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  const _CouponTile({required this.coupon, required this.now});

  final Coupon coupon;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final discount = coupon.discountLabel;
    final seed = coupon.merchant.codeUnits.fold<int>(0, (a, b) => a + b);
    final color = Colors.primaries[seed % Colors.primaries.length].shade600;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(
          coupon.merchant.isEmpty ? '?' : coupon.merchant[0].toUpperCase(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(coupon.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [
          coupon.merchant,
          if (discount.isNotEmpty) discount,
          coupon.kind == CouponKind.physical ? 'fisico' : 'digitale',
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: ExpiryChip(coupon: coupon, now: now),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => CouponDetailPage(couponId: coupon.id))),
    );
  }
}
