import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

import '../../ui/theme.dart';

/// Maps mobile_scanner's `BarcodeFormat.name` to a barcode_widget symbology.
/// Returns null for formats we cannot redraw (those fall back to plain text).
Barcode? barcodeFor(String? format) {
  switch (format) {
    case 'ean13':
      return Barcode.ean13();
    case 'ean8':
      return Barcode.ean8();
    case 'upcA':
      return Barcode.upcA();
    case 'upcE':
      return Barcode.upcE();
    case 'code128':
      return Barcode.code128();
    case 'code39':
      return Barcode.code39();
    case 'code93':
      return Barcode.code93();
    case 'codabar':
      return Barcode.codabar();
    case 'itf':
    case 'itf14':
      return Barcode.itf();
    case 'qrCode':
      return Barcode.qrCode();
    case 'pdf417':
      return Barcode.pdf417();
    case 'aztec':
      return Barcode.aztec();
    case 'dataMatrix':
      return Barcode.dataMatrix();
    default:
      return null;
  }
}

/// Renders a coupon code as a barcode when its symbology is known, and always
/// shows the value as text underneath (cashiers can type it in).
class CodeView extends StatelessWidget {
  const CodeView({
    super.key,
    required this.value,
    required this.format,
    this.height = 120,
    this.textStyle,
  });

  final String value;
  final String? format;
  final double height;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final barcode = barcodeFor(format);
    final style = textStyle ?? Theme.of(context).textTheme.titleMedium;
    // One line, scaled down if needed: a code split across lines is unreadable.
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(value, textAlign: TextAlign.center, style: style),
    );

    // Plain-text code (promo code): nothing to draw.
    if (barcode == null) return text;

    // A scanned code can still be impossible to redraw (wrong length or check
    // digit for its symbology). Say so briefly instead of showing an empty box.
    if (!barcode.isValid(value)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          text,
          const SizedBox(height: 8),
          Text(
            'Non riesco a ridisegnare il codice a barre: leggi il numero alla cassa.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: style?.color),
          ),
        ],
      );
    }

    final isSquare =
        format == 'qrCode' || format == 'aztec' || format == 'dataMatrix';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BarcodeWidget(
          barcode: barcode,
          data: value,
          height: isSquare ? height * 1.6 : height,
          width: isSquare ? height * 1.6 : double.infinity,
          drawText: false,
          color: codeInk,
          backgroundColor: codeSurface,
        ),
        const SizedBox(height: 8),
        text,
      ],
    );
  }
}
