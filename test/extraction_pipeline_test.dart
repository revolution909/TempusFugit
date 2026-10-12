import 'package:flutter_test/flutter_test.dart';
import 'package:tempusfugit/domain/coupon.dart';
import 'package:tempusfugit/extraction/extraction_pipeline.dart';

void main() {
  final now = DateTime(2026, 10, 12);

  test('combines barcode and OCR text', () async {
    final p = ExtractionPipeline(
      barcodeReader: (_) async => const FoundCode('8001234567890', 'ean13'),
      textReader: (_) async => 'Lidl\nBuono 10 € \nValido fino al 31/12/2026',
    );
    final r = await p.fromImage('x.jpg', now: now);
    expect(r.codeValue, '8001234567890');
    expect(r.codeFormat, 'ean13');
    expect(r.extracted.merchant, 'Lidl');
    expect(r.extracted.discountType, DiscountType.amount);
    expect(r.extracted.expiresAt, DateTime(2026, 12, 31));
  });

  test('falls back to printed promo code when there is no barcode', () async {
    final p = ExtractionPipeline(
      barcodeReader: (_) async => null,
      textReader: (_) async => 'Codice promo: SCONTO20',
    );
    final r = await p.fromImage('x.jpg', now: now);
    expect(r.codeValue, 'SCONTO20');
    expect(r.codeFormat, isNull);
  });

  test('a failing reader does not lose the other result', () async {
    final p = ExtractionPipeline(
      barcodeReader: (_) async => throw StateError('boom'),
      textReader: (_) async => 'Sconto 15%',
    );
    final r = await p.fromImage('x.jpg', now: now);
    expect(r.code, isNull);
    expect(r.extracted.discountValue, 15);

    final q = ExtractionPipeline(
      barcodeReader: (_) async => const FoundCode('123456', 'code128'),
      textReader: (_) async => throw StateError('boom'),
    );
    final r2 = await q.fromImage('x.jpg', now: now);
    expect(r2.codeValue, '123456');
    expect(r2.extracted.isEmpty, isTrue);
  });
}
