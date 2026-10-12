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
import 'package:tempusfugit/providers.dart';

import '../fake_llm.dart';
import 'fakes.dart';
import 'screenshot.dart';

/// Runs the real app against an in-memory database, a recording notification
/// service and a scriptable LLM.
class AppHarness {
  AppHarness() {
    SharedPreferences.setMockInitialValues({});
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    repo = CouponRepository(db);
  }

  late final AppDatabase db;
  late final CouponRepository repo;
  final notifications = FakeNotifications();
  final llm = FakeLlm();

  /// Date data plus real fonts: with the default test font ("Ahem") every
  /// letter is a wide square, which makes chips overflow and taps miss.
  static Future<void> init() async {
    await initializeDateFormatting('it');
    await loadFonts();
  }

  Future<void> seed(Iterable<Coupon> coupons) async {
    for (final c in coupons) {
      await repo.upsert(c);
    }
  }

  /// Phone-sized surface. [textScale] 2.0 is the largest Android setting.
  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(360, 780),
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = size * 2.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(notifications),
        llmExtractorProvider.overrideWithValue(llm),
      ],
      child: const TempusFugitApp(),
    ));
    await tester.pumpAndSettle();
  }

  /// Drift schedules a cleanup timer when its stream providers are disposed;
  /// unmount and let it fire so the test binding sees no pending timers.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Coupon `id` expiring [daysLeft] days from today (null = no expiry).
Coupon sample(
  String id, {
  String title = 'Buono',
  String merchant = 'Lidl',
  int? daysLeft,
  CouponStatus status = CouponStatus.active,
  CouponKind kind = CouponKind.digital,
  DiscountType type = DiscountType.amount,
  double? value = 5,
  String? code,
  String? format,
  String? tag,
}) {
  final today = DateTime.now();
  return Coupon(
    id: id,
    title: title,
    merchant: merchant,
    kind: kind,
    createdAt: DateTime(2026, 1, 1),
    expiresAt: daysLeft == null
        ? null
        : DateTime(today.year, today.month, today.day + daysLeft),
    discountType: type,
    discountValue: value,
    status: status,
    codeValue: code,
    codeFormat: format,
    tag: tag,
  );
}
