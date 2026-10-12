enum CouponKind { physical, digital }

enum CouponStatus { active, used }

enum DiscountType { percent, amount, freebie, twoForOne, other }

enum CouponSource { manual, barcodeScan, photo, gallery }

/// A coupon the user wants to remember. [expiresAt] is a calendar date: the
/// coupon is usable through the end of that day (local time).
class Coupon {
  const Coupon({
    required this.id,
    required this.title,
    required this.merchant,
    required this.kind,
    required this.createdAt,
    this.category,
    this.tag,
    this.codeValue,
    this.codeFormat,
    this.discountType = DiscountType.other,
    this.discountValue,
    this.minSpend,
    this.conditions,
    this.validFrom,
    this.expiresAt,
    this.status = CouponStatus.active,
    this.imagePath,
    this.source = CouponSource.manual,
  });

  final String id;
  final String title;

  /// Shop or brand the coupon belongs to.
  final String merchant;
  final CouponKind kind;
  final DateTime createdAt;
  final String? category;

  /// Free-form association, e.g. "regalo di Anna" or "ordine #123".
  final String? tag;
  final String? codeValue;

  /// Barcode symbology name (e.g. `ean13`, `qrCode`); null for plain-text codes.
  final String? codeFormat;
  final DiscountType discountType;
  final double? discountValue;
  final double? minSpend;
  final String? conditions;
  final DateTime? validFrom;
  final DateTime? expiresAt;
  final CouponStatus status;
  final String? imagePath;
  final CouponSource source;

  bool get isUsed => status == CouponStatus.used;

  /// Moment after which the coupon is no longer valid, or null if it has no expiry.
  DateTime? get expiryInstant {
    final e = expiresAt;
    if (e == null) return null;
    return DateTime(e.year, e.month, e.day + 1);
  }

  bool isExpired(DateTime now) {
    final end = expiryInstant;
    return end != null && !now.isBefore(end);
  }

  /// Whole calendar days from [now] until the expiry date (0 = expires today,
  /// negative = already expired). Null if there is no expiry.
  int? daysLeft(DateTime now) {
    final e = expiresAt;
    if (e == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(e.year, e.month, e.day).difference(today).inDays;
  }

  Coupon copyWith({
    String? title,
    String? merchant,
    CouponKind? kind,
    String? category,
    String? tag,
    String? codeValue,
    String? codeFormat,
    DiscountType? discountType,
    double? discountValue,
    double? minSpend,
    String? conditions,
    DateTime? validFrom,
    DateTime? expiresAt,
    CouponStatus? status,
    String? imagePath,
    CouponSource? source,
  }) {
    return Coupon(
      id: id,
      createdAt: createdAt,
      title: title ?? this.title,
      merchant: merchant ?? this.merchant,
      kind: kind ?? this.kind,
      category: category ?? this.category,
      tag: tag ?? this.tag,
      codeValue: codeValue ?? this.codeValue,
      codeFormat: codeFormat ?? this.codeFormat,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minSpend: minSpend ?? this.minSpend,
      conditions: conditions ?? this.conditions,
      validFrom: validFrom ?? this.validFrom,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      source: source ?? this.source,
    );
  }

  /// Short human label of the discount, e.g. "-20%", "5 €", "2x1".
  String get discountLabel {
    final v = discountValue;
    String num(double x) =>
        (x == x.roundToDouble() ? x.toStringAsFixed(0) : x.toStringAsFixed(2))
            .replaceAll('.', ',');
    switch (discountType) {
      case DiscountType.percent:
        return v == null ? '' : '-${num(v)}%';
      case DiscountType.amount:
        return v == null ? '' : '${num(v)} €';
      case DiscountType.freebie:
        return 'Omaggio';
      case DiscountType.twoForOne:
        return '2x1';
      case DiscountType.other:
        return '';
    }
  }
}
