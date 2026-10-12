import 'package:flutter_test/flutter_test.dart';
import 'package:tempusfugit/domain/coupon.dart';
import 'package:tempusfugit/features/list/coupon_groups.dart';

void main() {
  final now = DateTime(2026, 10, 12, 15);
  Coupon c(String id, int? days, {String merchant = 'Lidl', String title = 't', String? tag}) =>
      Coupon(
        id: id,
        title: title,
        merchant: merchant,
        kind: CouponKind.digital,
        createdAt: DateTime(2026, 1, 1),
        expiresAt: days == null ? null : DateTime(2026, 10, 12 + days),
        tag: tag,
      );

  group('groupActive', () {
    test('buckets by days left with the right boundaries', () {
      final groups = groupActive([
        c('a', 0), c('b', 3), // presto
        c('c', 4), c('d', 7), // questa settimana
        c('e', 8), c('f', 30), // questo mese
        c('g', 31), // più avanti
        c('h', null),
      ], now);
      expect({for (final g in groups) g.title: g.coupons.map((e) => e.id).toList()}, {
        'Scadono presto': ['a', 'b'],
        'Questa settimana': ['c', 'd'],
        'Questo mese': ['e', 'f'],
        'Più avanti': ['g'],
        'Senza scadenza': ['h'],
      });
    });

    test('omits empty groups and keeps the order of the input', () {
      final groups = groupActive([c('x', 40), c('y', 41)], now);
      expect(groups, hasLength(1));
      expect(groups.single.title, 'Più avanti');
      expect(groups.single.coupons.map((e) => e.id), ['x', 'y']);
    });

    test('empty input gives no groups', () {
      expect(groupActive(const [], now), isEmpty);
    });
  });

  group('matchesQuery', () {
    final coupon = c('1', 3,
        merchant: 'Bar Centrale', title: 'Caffè in omaggio', tag: 'regalo di Anna');

    test('empty or blank query matches everything', () {
      expect(matchesQuery(coupon, ''), isTrue);
      expect(matchesQuery(coupon, '   '), isTrue);
    });

    test('ignores case and accents', () {
      expect(matchesQuery(coupon, 'CAFFE'), isTrue);
      expect(matchesQuery(coupon, 'caffè'), isTrue);
    });

    test('every word must match, in any field', () {
      expect(matchesQuery(coupon, 'bar omaggio'), isTrue);
      expect(matchesQuery(coupon, 'anna caffe'), isTrue);
      expect(matchesQuery(coupon, 'bar pizza'), isFalse);
    });

    test('finds by discount label', () {
      final pct = Coupon(
        id: 'p',
        title: 'Sconto',
        merchant: 'Zara',
        kind: CouponKind.digital,
        createdAt: DateTime(2026, 1, 1),
        discountType: DiscountType.percent,
        discountValue: 20,
      );
      expect(matchesQuery(pct, '20%'), isTrue);
    });

    test('no match', () {
      expect(matchesQuery(coupon, 'zzz'), isFalse);
    });
  });
}
