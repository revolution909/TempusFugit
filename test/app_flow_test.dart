import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tempusfugit/app.dart';
import 'package:tempusfugit/data/database.dart';
import 'package:tempusfugit/domain/coupon.dart';
import 'package:tempusfugit/notifications/notification_service.dart';
import 'package:tempusfugit/providers.dart';

class FakeNotifications extends NotificationService {
  final syncs = <List<Coupon>>[];

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> sync(List<Coupon> coupons, {DateTime? now}) async => syncs.add(coupons);
}

Coupon seed(String id, String title, DateTime? exp,
        {CouponStatus status = CouponStatus.active, String? code, String? format}) =>
    Coupon(
      id: id,
      title: title,
      merchant: 'Lidl',
      kind: CouponKind.physical,
      createdAt: DateTime(2026, 1, 1),
      expiresAt: exp,
      status: status,
      codeValue: code,
      codeFormat: format,
      discountType: DiscountType.amount,
      discountValue: 5,
    );

void main() {
  late AppDatabase db;
  late FakeNotifications notifications;

  setUpAll(() async {
    await initializeDateFormatting('it');
    drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notifications = FakeNotifications();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const TempusFugitApp(),
    ));
    await tester.pumpAndSettle();
  }

  // Drift schedules a cleanup timer when its stream providers are disposed;
  // unmount and let it fire so the test binding sees no pending timers.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> insert(Coupon c) async {
    final container = ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    await container.read(couponRepositoryProvider).upsert(c);
    container.dispose();
  }

  testWidgets('empty state invites to add the first coupon', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('Nessun coupon ancora'), findsOneWidget);
    // The empty state carries the action, so there is no floating button yet,
    // and nothing to filter or search.
    expect(find.text('Aggiungi il primo coupon'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(TextField), findsNothing);
    await unmount(tester);
  });

  testWidgets('lists coupons by tab with urgency labels', (tester) async {
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    await insert(seed('1', 'Domani buono', d.add(const Duration(days: 1))));
    await insert(seed('2', 'Lontano buono', d.add(const Duration(days: 40))));
    await insert(seed('3', 'Vecchio buono', d.subtract(const Duration(days: 5))));
    await insert(seed('4', 'Gia usato', d.add(const Duration(days: 9)), status: CouponStatus.used));

    await pumpApp(tester);
    expect(find.text('Attivi (2)'), findsOneWidget);
    expect(find.text('Scaduti (1)'), findsOneWidget);
    expect(find.text('Usati (1)'), findsOneWidget);
    expect(find.text('Scade domani'), findsOneWidget);
    expect(find.text('Scade tra 40 giorni'), findsOneWidget);
    // soonest first
    expect(tester.getTopLeft(find.text('Domani buono')).dy,
        lessThan(tester.getTopLeft(find.text('Lontano buono')).dy));

    await tester.tap(find.text('Scaduti (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Vecchio buono'), findsOneWidget);
    expect(find.text('Scaduto da 5 giorni'), findsOneWidget);
    expect(find.text('Domani buono'), findsNothing);

    await tester.tap(find.text('Usati (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Gia usato'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('manual add saves a coupon and schedules reminders', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Aggiungi il primo coupon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inserisci a mano'));
    await tester.pumpAndSettle();

    // Merchant is required.
    await tester.tap(find.text('Salva coupon'));
    await tester.pumpAndSettle();
    expect(find.text('Indica il negozio'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Negozio / marchio *'), 'Coop');
    await tester.enterText(find.widgetWithText(TextFormField, 'Titolo'), 'Sconto estate');
    await tester.tap(find.text('+30 giorni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva coupon'));
    await tester.pumpAndSettle();

    expect(find.text('Sconto estate'), findsOneWidget);
    expect(find.text('Attivi (1)'), findsOneWidget);
    expect(find.text('Scade tra 30 giorni'), findsOneWidget);
    expect(notifications.syncs.last.single.merchant, 'Coop');
    await unmount(tester);
  });

  testWidgets('detail: mark used, then it moves to the used tab', (tester) async {
    final d = DateTime.now().add(const Duration(days: 10));
    await insert(seed('1', 'Buono uno', DateTime(d.year, d.month, d.day),
        code: '4006381333931', format: 'ean13'));
    await pumpApp(tester);

    await tester.tap(find.text('Buono uno'));
    await tester.pumpAndSettle();
    expect(find.text('Mostra in cassa'), findsOneWidget);
    expect(find.text('4006381333931'), findsOneWidget);

    await tester.tap(find.text('Segna come usato'));
    await tester.pumpAndSettle();
    expect(find.text('Riattiva'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Attivi (0)'), findsOneWidget);
    expect(find.text('Usati (1)'), findsOneWidget);
    // Used coupons must not keep reminders.
    expect(notifications.syncs.last.single.isUsed, isTrue);
    await unmount(tester);
  });

  testWidgets('checkout view shows the code', (tester) async {
    await insert(seed('1', 'Buono uno', DateTime.now().add(const Duration(days: 10)),
        code: 'ABC-12345', format: null));
    await pumpApp(tester);
    await tester.tap(find.text('Buono uno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mostra in cassa'));
    await tester.pumpAndSettle();
    expect(find.text('ABC-12345'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('delete is immediate and can be undone', (tester) async {
    await insert(seed('1', 'Da cancellare', DateTime.now().add(const Duration(days: 10))));
    await pumpApp(tester);
    await tester.tap(find.text('Da cancellare'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Altre azioni'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();

    // Back on the (now empty) list, with a way back.
    expect(find.text('Da cancellare'), findsNothing);
    expect(find.textContaining('Nessun coupon ancora'), findsOneWidget);
    expect(find.text('Coupon eliminato'), findsOneWidget);

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(find.text('Da cancellare'), findsOneWidget);
    expect(find.textContaining('Nessun coupon ancora'), findsNothing);
    await unmount(tester);
  });
}
