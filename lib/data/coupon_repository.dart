import 'package:drift/drift.dart';

import '../domain/coupon.dart';
import 'database.dart';

class CouponRepository {
  CouponRepository(this._db);

  final AppDatabase _db;

  /// All coupons, soonest expiry first; coupons without expiry go last.
  Stream<List<Coupon>> watchAll() {
    return _db.select(_db.coupons).watch().map((rows) {
      final list = rows.map(_fromRow).toList();
      list.sort(_byExpiry);
      return list;
    });
  }

  Future<Coupon?> get(String id) async {
    final row = await (_db.select(_db.coupons)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<List<Coupon>> getAll() async {
    final list = (await _db.select(_db.coupons).get()).map(_fromRow).toList();
    list.sort(_byExpiry);
    return list;
  }

  Future<void> upsert(Coupon c) =>
      _db.into(_db.coupons).insertOnConflictUpdate(_toCompanion(c));

  Future<void> delete(String id) =>
      (_db.delete(_db.coupons)..where((t) => t.id.equals(id))).go();

  Future<void> setStatus(String id, CouponStatus status) =>
      (_db.update(_db.coupons)..where((t) => t.id.equals(id)))
          .write(CouponsCompanion(status: Value(status.name)));

  /// Distinct merchant names already used, for autocompletion.
  Future<List<String>> merchants() async {
    final q = _db.selectOnly(_db.coupons, distinct: true)
      ..addColumns([_db.coupons.merchant]);
    final rows = await q.get();
    final names = rows.map((r) => r.read(_db.coupons.merchant)!).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  static int _byExpiry(Coupon a, Coupon b) {
    final ea = a.expiresAt, eb = b.expiresAt;
    if (ea == null && eb == null) return b.createdAt.compareTo(a.createdAt);
    if (ea == null) return 1;
    if (eb == null) return -1;
    return ea.compareTo(eb);
  }

  static T _enum<T extends Enum>(List<T> values, String name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }

  Coupon _fromRow(CouponRow r) => Coupon(
        id: r.id,
        title: r.title,
        merchant: r.merchant,
        kind: _enum(CouponKind.values, r.kind, CouponKind.digital),
        createdAt: r.createdAt,
        category: r.category,
        tag: r.tag,
        codeValue: r.codeValue,
        codeFormat: r.codeFormat,
        discountType:
            _enum(DiscountType.values, r.discountType, DiscountType.other),
        discountValue: r.discountValue,
        minSpend: r.minSpend,
        conditions: r.conditions,
        validFrom: r.validFrom,
        expiresAt: r.expiresAt,
        status: _enum(CouponStatus.values, r.status, CouponStatus.active),
        imagePath: r.imagePath,
        source: _enum(CouponSource.values, r.source, CouponSource.manual),
      );

  CouponsCompanion _toCompanion(Coupon c) => CouponsCompanion(
        id: Value(c.id),
        title: Value(c.title),
        merchant: Value(c.merchant),
        kind: Value(c.kind.name),
        createdAt: Value(c.createdAt),
        category: Value(c.category),
        tag: Value(c.tag),
        codeValue: Value(c.codeValue),
        codeFormat: Value(c.codeFormat),
        discountType: Value(c.discountType.name),
        discountValue: Value(c.discountValue),
        minSpend: Value(c.minSpend),
        conditions: Value(c.conditions),
        validFrom: Value(c.validFrom),
        expiresAt: Value(c.expiresAt),
        status: Value(c.status.name),
        imagePath: Value(c.imagePath),
        source: Value(c.source.name),
      );
}
