import '../../domain/coupon.dart';

class CouponGroup {
  const CouponGroup(this.title, this.coupons);
  final String title;
  final List<Coupon> coupons;
}

/// Splits active coupons into urgency buckets, soonest first, so the ones that
/// need attention are at the top. [coupons] must already be sorted by expiry.
List<CouponGroup> groupActive(List<Coupon> coupons, DateTime now) {
  final buckets = <String, List<Coupon>>{
    'Scadono presto': [],
    'Questa settimana': [],
    'Questo mese': [],
    'Più avanti': [],
    'Senza scadenza': [],
  };
  for (final c in coupons) {
    final days = c.daysLeft(now);
    final key = days == null
        ? 'Senza scadenza'
        : days <= 3
            ? 'Scadono presto'
            : days <= 7
                ? 'Questa settimana'
                : days <= 30
                    ? 'Questo mese'
                    : 'Più avanti';
    buckets[key]!.add(c);
  }
  return [
    for (final e in buckets.entries)
      if (e.value.isNotEmpty) CouponGroup(e.key, e.value),
  ];
}

const _folds = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'è': 'e', 'é': 'e', 'ê': 'e',
  'ë': 'e', 'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ò': 'o', 'ó': 'o',
  'ô': 'o', 'ö': 'o', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c',
};

/// Lowercase and strip accents, so "caffe" finds "Caffè".
String fold(String s) {
  final lower = s.toLowerCase();
  final b = StringBuffer();
  for (final ch in lower.split('')) {
    b.write(_folds[ch] ?? ch);
  }
  return b.toString();
}

/// Whether [c] matches every word of [query] in its merchant, title, tag,
/// category or discount label. An empty query matches everything.
bool matchesQuery(Coupon c, String query) {
  final words = fold(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return true;
  final haystack = fold([
    c.merchant,
    c.title,
    c.tag ?? '',
    c.category ?? '',
    c.discountLabel,
  ].join(' '));
  return words.every(haystack.contains);
}
