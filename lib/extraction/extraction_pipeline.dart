import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'rule_extractor.dart';

/// A barcode found in an image: the decoded value and its symbology name.
class FoundCode {
  const FoundCode(this.value, this.format);
  final String value;
  final String format;
}

class ScanResult {
  const ScanResult({required this.rawText, required this.extracted, this.code});

  final String rawText;
  final ExtractedCoupon extracted;
  final FoundCode? code;

  /// Barcode if one was decoded, otherwise a printed promo code (as plain text).
  String? get codeValue => code?.value ?? extracted.codeValue;
  String? get codeFormat => code?.format;
}

typedef BarcodeReader = Future<FoundCode?> Function(String imagePath);
typedef TextReader = Future<String> Function(String imagePath);

/// Image / text → coupon fields: barcode first (exact), then OCR + rules.
class ExtractionPipeline {
  ExtractionPipeline({
    RuleExtractor? rules,
    BarcodeReader? barcodeReader,
    TextReader? textReader,
  })  : _rules = rules ?? RuleExtractor(),
        _barcode = barcodeReader ?? _readBarcodeWithMlKit,
        _text = textReader ?? _readTextWithMlKit;

  final RuleExtractor _rules;
  final BarcodeReader _barcode;
  final TextReader _text;

  Future<ScanResult> fromImage(String imagePath, {DateTime? now}) async {
    // Either reader failing must not lose the other's result.
    FoundCode? code;
    var text = '';
    try {
      code = await _barcode(imagePath);
    } catch (_) {}
    try {
      text = await _text(imagePath);
    } catch (_) {}
    return ScanResult(
      rawText: text,
      code: code,
      extracted: _rules.extract(text, now: now ?? DateTime.now()),
    );
  }

  ScanResult fromText(String text, {DateTime? now}) => ScanResult(
        rawText: text,
        extracted: _rules.extract(text, now: now ?? DateTime.now()),
      );

  static Future<FoundCode?> _readBarcodeWithMlKit(String path) async {
    final controller = MobileScannerController(autoStart: false);
    try {
      final capture = await controller.analyzeImage(path);
      for (final b in capture?.barcodes ?? const <Barcode>[]) {
        final v = b.rawValue;
        if (v != null && v.isNotEmpty) return FoundCode(v, b.format.name);
      }
      return null;
    } finally {
      await controller.dispose();
    }
  }

  static Future<String> _readTextWithMlKit(String path) async {
    final recognizer = TextRecognizer();
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(path));
      return result.text;
    } finally {
      await recognizer.close();
    }
  }
}
