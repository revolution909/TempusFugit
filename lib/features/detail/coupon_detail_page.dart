import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/coupon.dart';
import '../../providers.dart';
import '../common/expiry.dart';
import '../form/coupon_form_page.dart';
import 'barcode_view.dart';
import 'cassa_page.dart';

class CouponDetailPage extends ConsumerWidget {
  const CouponDetailPage({super.key, required this.couponId});

  final String couponId;

  static final _date = DateFormat('EEEE d MMMM y', 'it');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupon = ref.watch(couponsProvider).value?.where((c) => c.id == couponId).firstOrNull;
    if (coupon == null) {
      // Deleted (or still loading): nothing to show.
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Coupon non trovato.')));
    }
    final repo = ref.read(couponRepositoryProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(coupon.merchant),
        actions: [
          IconButton(
            tooltip: 'Modifica',
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => CouponFormPage(existing: coupon))),
          ),
          IconButton(
            tooltip: 'Elimina',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, repo, coupon),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(coupon.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Row(children: [
            ExpiryChip(coupon: coupon, now: now),
            const SizedBox(width: 8),
            Text(coupon.kind == CouponKind.physical ? 'Coupon fisico' : 'Coupon digitale'),
          ]),
          const SizedBox(height: 16),
          if (coupon.discountLabel.isNotEmpty)
            _row(Icons.local_offer, 'Sconto', coupon.discountLabel),
          if (coupon.expiresAt != null)
            _row(Icons.event, 'Scadenza', _date.format(coupon.expiresAt!)),
          if (coupon.validFrom != null)
            _row(Icons.event_available, 'Valido dal', _date.format(coupon.validFrom!)),
          if (coupon.minSpend != null)
            _row(Icons.shopping_cart, 'Spesa minima', '${coupon.minSpend!.toStringAsFixed(2).replaceAll('.', ',')} €'),
          if (coupon.conditions != null)
            _row(Icons.info_outline, 'Condizioni', coupon.conditions!),
          if (coupon.tag != null) _row(Icons.link, 'Associato a', coupon.tag!),
          const SizedBox(height: 16),
          if (coupon.codeValue != null) ...[
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CodeView(
                  value: coupon.codeValue!,
                  format: coupon.codeFormat,
                  textStyle: const TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => CassaPage(coupon: coupon))),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Mostra in cassa'),
            ),
          ],
          if (coupon.imagePath != null && File(coupon.imagePath!).existsSync()) ...[
            const SizedBox(height: 16),
            Text('Originale', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(coupon.imagePath!)),
            ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => repo.setStatus(
                coupon.id, coupon.isUsed ? CouponStatus.active : CouponStatus.used),
            icon: Icon(coupon.isUsed ? Icons.undo : Icons.check_circle_outline),
            label: Text(coupon.isUsed ? 'Riattiva' : 'Segna come usato'),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            SizedBox(width: 104, child: Text(label)),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );

  Future<void> _confirmDelete(BuildContext context, repo, Coupon coupon) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare il coupon?'),
        content: Text('"${coupon.title}" verrà rimosso definitivamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina')),
        ],
      ),
    );
    if (ok == true) {
      await repo.delete(coupon.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
