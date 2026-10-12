// Visual review harness: renders each screen of the real app to PNG files.
//
//   SCREENSHOT_DIR=/some/dir flutter test test/screenshots/screens_test.dart
//
// Skipped when SCREENSHOT_DIR is not set. These are for looking at, not golden
// files: font rasterisation differs per platform, so they are never compared.
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempusfugit/app.dart';
import 'package:tempusfugit/data/coupon_repository.dart';
import 'package:tempusfugit/data/database.dart';
import 'package:tempusfugit/domain/coupon.dart';
import 'package:tempusfugit/llm/llm_extractor.dart';
import 'package:tempusfugit/providers.dart';

import '../fake_llm.dart';
import '../support/fakes.dart';
import '../support/screenshot.dart';

void main() {
  final skip = screenshotDir == null ? 'set SCREENSHOT_DIR to render' : false;

  setUpAll(() async {
    await initializeDateFormatting('it');
    await loadFonts();
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  final today = DateTime.now();
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  Coupon coupon(
    String id,
    String title,
    String merchant,
    int? daysLeft, {
    CouponKind kind = CouponKind.digital,
    DiscountType type = DiscountType.percent,
    double? value,
    CouponStatus status = CouponStatus.active,
    String? code,
    String? format,
    String? tag,
    double? minSpend,
    String? conditions,
  }) =>
      Coupon(
        id: id,
        title: title,
        merchant: merchant,
        kind: kind,
        createdAt: DateTime(2026, 1, 1),
        expiresAt: daysLeft == null ? null : day(daysLeft),
        discountType: type,
        discountValue: value,
        status: status,
        codeValue: code,
        codeFormat: format,
        tag: tag,
        minSpend: minSpend,
        conditions: conditions,
      );

  final seed = [
    coupon('1', 'Sconto 20% su tutto', 'Zara', 1,
        value: 20, code: 'ZARA20', tag: 'regalo di Anna'),
    coupon('2', 'Buono 5 €', 'Esselunga', 2,
        kind: CouponKind.physical,
        type: DiscountType.amount,
        value: 5,
        code: '4006381333931',
        format: 'ean13',
        minSpend: 40,
        conditions: 'Non cumulabile con altre promozioni.'),
    coupon('3', 'Offerta 2x1', 'Pizzeria Da Gigi', 6,
        type: DiscountType.twoForOne, code: 'GIGI2X1'),
    coupon('4', 'Sconto 15%', 'Decathlon', 18, value: 15),
    coupon('5', 'Caffè in omaggio', 'Bar Centrale', 45,
        type: DiscountType.freebie, kind: CouponKind.physical),
    coupon('6', 'Buono 10 €', 'Feltrinelli', null,
        type: DiscountType.amount, value: 10, code: 'FELT10'),
    coupon('7', 'Sconto 30%', 'H&M', -4, value: 30),
    coupon('8', 'Buono 25 €', 'IKEA', 10,
        type: DiscountType.amount, value: 25, status: CouponStatus.used),
  ];

  Future<ProviderContainer?> pump(WidgetTester tester,
      {required List<Coupon> coupons,
      required Brightness brightness,
      double textScale = 1.0,
      FakeLlm? llm}) async {
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, textScale: textScale);
    useBrightness(tester, brightness);
    final db = AppDatabase(NativeDatabase.memory());
    final repo = CouponRepository(db);
    for (final c in coupons) {
      await repo.upsert(c);
    }
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(FakeNotifications()),
        llmExtractorProvider.overrideWithValue(llm ?? FakeLlm()),
      ],
      child: const TempusFugitApp(),
    ));
    await tester.pumpAndSettle();
    return null;
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final scale in [1.0, 2.0]) {
      final tag = '${brightness.name}_x${scale.toStringAsFixed(0)}';

      testWidgets('list $tag', skip: skip != false, (tester) async {
        await pump(tester,
            coupons: seed, brightness: brightness, textScale: scale);
        await shoot(tester, 'list_$tag');
        await unmount(tester);
      });

      testWidgets('empty $tag', skip: skip != false, (tester) async {
        await pump(tester,
            coupons: const [], brightness: brightness, textScale: scale);
        await shoot(tester, 'empty_$tag');
        await unmount(tester);
      });

      testWidgets('add sheet $tag', skip: skip != false, (tester) async {
        await pump(tester,
            coupons: seed, brightness: brightness, textScale: scale);
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await shoot(tester, 'add_$tag');
        await unmount(tester);
      });

      testWidgets('detail $tag', skip: skip != false, (tester) async {
        await pump(tester,
            coupons: seed, brightness: brightness, textScale: scale);
        await tester.ensureVisible(find.text('Buono 5 €').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Buono 5 €').first);
        await tester.pumpAndSettle();
        await shoot(tester, 'detail_$tag');
        await unmount(tester);
      });

      testWidgets('form $tag', skip: skip != false, (tester) async {
        await pump(tester,
            coupons: seed, brightness: brightness, textScale: scale);
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Inserisci a mano'));
        await tester.pumpAndSettle();
        await shoot(tester, 'form_$tag');
        await unmount(tester);
      });

      testWidgets('settings $tag', skip: skip != false, (tester) async {
        final llm = FakeLlm()..statusValue = const LlmNeedsDownload();
        await pump(tester,
            coupons: seed,
            brightness: brightness,
            textScale: scale,
            llm: llm);
        await tester.tap(find.byTooltip('Impostazioni'));
        await tester.pumpAndSettle();
        await shoot(tester, 'settings_$tag');
        await unmount(tester);
      });
    }
  }
}
