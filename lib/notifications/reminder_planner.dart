import '../domain/coupon.dart';

class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.couponId,
    required this.fireAt,
    required this.daysBefore,
  });

  /// Stable notification id derived from the coupon id and offset slot.
  final int id;
  final String couponId;
  final DateTime fireAt;

  /// 0 = on the expiry day.
  final int daysBefore;
}

/// Decides which notifications should be pending, as pure data. Kept separate
/// from the platform plugin so it can be unit-tested and so we can respect
/// iOS's limit of ~64 pending local notifications by only keeping the nearest.
class ReminderPlanner {
  const ReminderPlanner({
    this.daysBefore = const [7, 1, 0],
    this.hour = 9,
    this.maxPending = 60,
  });

  final List<int> daysBefore;
  final int hour;
  final int maxPending;

  List<PlannedReminder> plan(Iterable<Coupon> coupons, DateTime now) {
    assert(daysBefore.length <= 4, 'notification ids reserve 4 slots per coupon');
    final out = <PlannedReminder>[];
    for (final c in coupons) {
      final e = c.expiresAt;
      if (c.isUsed || e == null || c.isExpired(now)) continue;
      for (var slot = 0; slot < daysBefore.length; slot++) {
        final d = daysBefore[slot];
        final fireAt = DateTime(e.year, e.month, e.day - d, hour);
        if (!fireAt.isAfter(now)) continue;
        out.add(PlannedReminder(
          id: notificationId(c.id, slot),
          couponId: c.id,
          fireAt: fireAt,
          daysBefore: d,
        ));
      }
    }
    out.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    return out.length > maxPending ? out.sublist(0, maxPending) : out;
  }

  /// FNV-1a hash folded into 29 bits, times 4 plus the slot: always fits a
  /// positive 32-bit int and is stable across runs (unlike `String.hashCode`).
  static int notificationId(String couponId, int slot) {
    var h = 0x811c9dc5;
    for (final unit in couponId.codeUnits) {
      h ^= unit;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return (h & 0x1FFFFFFF) * 4 + slot;
  }
}
