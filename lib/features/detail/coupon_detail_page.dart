import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/coupon.dart';
import '../../providers.dart';
import '../../ui/feedback.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.dart';
import '../../ui/urgency.dart';
import '../../ui/widgets/info_row.dart';
import '../../ui/widgets/merchant_avatar.dart';
import '../form/coupon_form_page.dart';
import 'barcode_view.dart';
import 'cassa_page.dart';

class CouponDetailPage extends ConsumerWidget {
  const CouponDetailPage({super.key, required this.couponId});

  final String couponId;

  static final _date = DateFormat('EEEE d MMMM y', 'it');

  Future<void> _toggleUsed(
    BuildContext context,
    WidgetRef ref,
    Coupon c,
  ) async {
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

  Future<void> _delete(BuildContext context, WidgetRef ref, Coupon c) async {
    final repo = ref.read(couponRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await repo.delete(c.id);
    haptic();
    navigator.pop();
    showUndoSnackBar(messenger, 'Coupon eliminato', () => repo.upsert(c));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupon = ref
        .watch(couponsProvider)
        .value
        ?.where((c) => c.id == couponId)
        .firstOrNull;
    if (coupon == null) {
      // Deleted (or still loading): nothing to show.
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Coupon non trovato.')),
      );
    }

    final now = DateTime.now();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final hasCode = coupon.codeValue != null;
    final photo =
        coupon.imagePath != null && File(coupon.imagePath!).existsSync()
        ? coupon.imagePath!
        : null;

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Altre azioni',
            onSelected: (v) {
              if (v == 'edit') {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CouponFormPage(existing: coupon),
                  ),
                );
              } else {
                _delete(context, ref, coupon);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Modifica')),
              PopupMenuItem(value: 'delete', child: Text('Elimina')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.xl),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              MerchantAvatar(name: coupon.merchant, size: 56),
              const SizedBox(width: Gap.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(coupon.title, style: text.headlineSmall),
                    ),
                    Text(
                      coupon.merchant,
                      style: text.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.l),
          _ExpiryBanner(coupon: coupon, now: now),
          if (hasCode) ...[
            const SizedBox(height: Gap.l),
            _CodeCard(
              coupon: coupon,
              onOpen: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CassaPage(coupon: coupon),
                ),
              ),
            ),
          ],
          const SizedBox(height: Gap.l),
          _InfoCard(coupon: coupon),
          if (photo != null) ...[
            const SizedBox(height: Gap.l),
            _PhotoCard(path: photo),
          ],
        ],
      ),
      // The actions you need at the till stay in thumb reach.
      bottomNavigationBar: Material(
        color: scheme.surfaceContainer,
        elevation: 3,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.l, Gap.m),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasCode && !coupon.isUsed) ...[
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CassaPage(coupon: coupon),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Mostra in cassa'),
                  ),
                  const SizedBox(height: Gap.s),
                ],
                coupon.isUsed
                    ? FilledButton.tonalIcon(
                        onPressed: () => _toggleUsed(context, ref, coupon),
                        icon: const Icon(Icons.undo),
                        label: const Text('Riattiva'),
                      )
                    : FilledButton.tonalIcon(
                        onPressed: () => _toggleUsed(context, ref, coupon),
                        icon: const Icon(Icons.check),
                        label: const Text('Segna come usato'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The most important fact first: when does it expire, in the urgency colours.
class _ExpiryBanner extends StatelessWidget {
  const _ExpiryBanner({required this.coupon, required this.now});

  final Coupon coupon;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final level = urgencyOf(coupon, now);
    final colors = urgencyPair(context, level);
    final text = Theme.of(context).textTheme;
    final headline = expiryText(coupon, now);
    final detail = coupon.expiresAt == null
        ? null
        : CouponDetailPage._date.format(coupon.expiresAt!);

    return Semantics(
      container: true,
      label: [headline, ?detail].join(', '),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(Gap.l),
        decoration: BoxDecoration(
          color: colors.container,
          borderRadius: BorderRadius.circular(Corner.large),
        ),
        child: Row(
          children: [
            Icon(urgencyIcon(level), size: 32, color: colors.onContainer),
            const SizedBox(width: Gap.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: text.titleMedium?.copyWith(
                      color: colors.onContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (detail != null)
                    Text(
                      detail,
                      style: text.bodyMedium?.copyWith(
                        color: colors.onContainer,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The code on a light card (always, even in dark mode: readers need dark bars
/// on a light background). Tapping it opens the full-screen checkout view.
class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.coupon, required this.onOpen});

  final Coupon coupon;
  final VoidCallback onOpen;

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: coupon.codeValue!));
    haptic();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Codice copiato')));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: codeSurface,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: 'Codice ${coupon.codeValue}. Tocca per mostrarlo in cassa',
            excludeSemantics: true,
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.all(Gap.l),
                child: CodeView(
                  value: coupon.codeValue!,
                  format: coupon.codeFormat,
                  textStyle: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: codeInk, letterSpacing: 1.5),
                ),
              ),
            ),
          ),
          // Handy for promo codes typed into a website.
          TextButton.icon(
            onPressed: () => _copy(context),
            style: TextButton.styleFrom(foregroundColor: codeInk),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copia codice'),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.coupon});

  final Coupon coupon;

  @override
  Widget build(BuildContext context) {
    final date = CouponDetailPage._date;
    final rows = <Widget>[
      InfoRow(
        icon: coupon.kind == CouponKind.physical
            ? Icons.receipt_long_outlined
            : Icons.qr_code_2,
        label: 'Tipo',
        value: coupon.kind == CouponKind.physical
            ? 'Coupon fisico'
            : 'Coupon digitale',
      ),
      if (coupon.discountLabel.isNotEmpty)
        InfoRow(
          icon: Icons.local_offer_outlined,
          label: 'Sconto',
          value: coupon.discountLabel,
        ),
      if (coupon.validFrom != null)
        InfoRow(
          icon: Icons.event_available_outlined,
          label: 'Valido dal',
          value: date.format(coupon.validFrom!),
        ),
      if (coupon.minSpend != null)
        InfoRow(
          icon: Icons.shopping_cart_outlined,
          label: 'Spesa minima',
          value:
              '${coupon.minSpend!.toStringAsFixed(2).replaceAll('.', ',')} €',
        ),
      if (coupon.conditions != null)
        InfoRow(
          icon: Icons.info_outline,
          label: 'Condizioni',
          value: coupon.conditions!,
        ),
      if (coupon.tag != null)
        InfoRow(icon: Icons.link, label: 'Associato a', value: coupon.tag!),
    ];
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(indent: 54),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Foto originale del coupon. Tocca per ingrandire',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => _PhotoViewer(path: path)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 160,
                child: Image.file(File(path), fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(Gap.m),
                child: Text(
                  'Foto originale · tocca per ingrandire',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Foto originale'),
      ),
      body: Center(
        child: InteractiveViewer(maxScale: 5, child: Image.file(File(path))),
      ),
    );
  }
}
