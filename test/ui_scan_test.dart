import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempusfugit/features/scan/barcode_scan_page.dart';

void main() {
  testWidgets('the scanner page draws a frame and tells what to do', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BarcodeScanPage()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Inquadra il codice'), findsOneWidget);
    expect(find.text('Il codice viene letto in automatico'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
