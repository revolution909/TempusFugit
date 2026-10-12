import 'package:flutter_test/flutter_test.dart';
import 'package:tempusfugit/domain/coupon.dart';
import 'package:tempusfugit/notifications/reminder_planner.dart';

Coupon coupon(String id, DateTime? expires,
        {CouponStatus status = CouponStatus.active}) =>
    Coupon(
      id: id,
      title: 't',
      merchant: 'm',
      kind: CouponKind.digital,
      createdAt: DateTime(2026, 1, 1),
      expiresAt: expires,
      status: status,
    );

void main() {
  const planner = ReminderPlanner();
  final now = DateTime(2026, 10, 12, 10);

  test('schedules 7d, 1d and same-day reminders at 09:00', () {
    final r = planner.plan([coupon('a', DateTime(2026, 11, 20))], now);
    expect(r.map((e) => e.fireAt), [
      DateTime(2026, 11, 13, 9),
      DateTime(2026, 11, 19, 9),
      DateTime(2026, 11, 20, 9),
    ]);
    expect(r.map((e) => e.daysBefore), [7, 1, 0]);
  });

  test('skips reminders already in the past', () {
    final r = planner.plan([coupon('a', DateTime(2026, 10, 14))], now);
    expect(r.map((e) => e.daysBefore), [1, 0]);
  });

  test('skips used, expired and undated coupons', () {
    final r = planner.plan([
      coupon('used', DateTime(2026, 11, 1), status: CouponStatus.used),
      coupon('old', DateTime(2026, 10, 1)),
      coupon('none', null),
    ], now);
    expect(r, isEmpty);
  });

  test('a coupon expiring today is still active until midnight', () {
    final c = coupon('a', DateTime(2026, 10, 12));
    expect(c.isExpired(DateTime(2026, 10, 12, 23, 59)), isFalse);
    expect(c.isExpired(DateTime(2026, 10, 13)), isTrue);
    expect(c.daysLeft(now), 0);
  });

  test('keeps only the nearest maxPending reminders', () {
    final coupons = [
      for (var i = 0; i < 40; i++) coupon('c$i', DateTime(2026, 12, 1 + i % 28)),
    ];
    final r = const ReminderPlanner(maxPending: 10).plan(coupons, now);
    expect(r, hasLength(10));
    final all = planner.plan(coupons, now);
    expect(r.last.fireAt.isAfter(all[10].fireAt), isFalse);
    expect(r.map((e) => e.fireAt), orderedEquals(all.take(10).map((e) => e.fireAt)));
  });

  test('notification ids are stable, positive 31-bit and unique per slot', () {
    final ids = {
      for (var s = 0; s < 3; s++) ReminderPlanner.notificationId('abc', s),
    };
    expect(ids, hasLength(3));
    expect(ReminderPlanner.notificationId('abc', 1),
        ReminderPlanner.notificationId('abc', 1));
    for (final id in ids) {
      expect(id, inInclusiveRange(0, 0x7FFFFFFF));
    }
  });
}
