import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tempusfugit/data/coupon_repository.dart';
import 'package:tempusfugit/data/database.dart';
import 'package:tempusfugit/domain/coupon.dart';

Coupon make(String id, DateTime? exp, {String merchant = 'Lidl'}) => Coupon(
      id: id,
      title: 'Buono $id',
      merchant: merchant,
      kind: CouponKind.physical,
      createdAt: DateTime(2026, 1, 1),
      expiresAt: exp,
      discountType: DiscountType.amount,
      discountValue: 5,
      codeValue: '1234567890128',
      codeFormat: 'ean13',
    );

void main() {
  late AppDatabase db;
  late CouponRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = CouponRepository(db);
  });
  tearDown(() => db.close());

  test('round-trips all fields', () async {
    final c = make('a', DateTime(2026, 12, 31)).copyWith(
      category: 'Spesa',
      tag: 'regalo di Anna',
      minSpend: 40,
      conditions: 'Non cumulabile',
      validFrom: DateTime(2026, 10, 1),
      imagePath: '/x.jpg',
      source: CouponSource.photo,
    );
    await repo.upsert(c);
    final back = (await repo.get('a'))!;
    expect(back.title, c.title);
    expect(back.kind, CouponKind.physical);
    expect(back.expiresAt, DateTime(2026, 12, 31));
    expect(back.validFrom, DateTime(2026, 10, 1));
    expect(back.discountType, DiscountType.amount);
    expect(back.discountValue, 5);
    expect(back.minSpend, 40);
    expect(back.codeFormat, 'ean13');
    expect(back.tag, 'regalo di Anna');
    expect(back.source, CouponSource.photo);
  });

  test('upsert updates, delete removes, setStatus marks used', () async {
    await repo.upsert(make('a', DateTime(2026, 12, 31)));
    await repo.upsert(make('a', DateTime(2027, 1, 1)));
    expect((await repo.getAll()), hasLength(1));
    expect((await repo.get('a'))!.expiresAt, DateTime(2027, 1, 1));

    await repo.setStatus('a', CouponStatus.used);
    expect((await repo.get('a'))!.isUsed, isTrue);

    await repo.delete('a');
    expect(await repo.get('a'), isNull);
  });

  test('sorted by expiry, undated last', () async {
    await repo.upsert(make('late', DateTime(2027, 1, 1)));
    await repo.upsert(make('none', null));
    await repo.upsert(make('soon', DateTime(2026, 11, 1)));
    expect((await repo.getAll()).map((c) => c.id), ['soon', 'late', 'none']);
    expect((await repo.watchAll().first).map((c) => c.id), ['soon', 'late', 'none']);
  });

  test('distinct merchants sorted case-insensitively', () async {
    await repo.upsert(make('1', null, merchant: 'lidl'));
    await repo.upsert(make('2', null, merchant: 'Coop'));
    await repo.upsert(make('3', null, merchant: 'lidl'));
    expect(await repo.merchants(), ['Coop', 'lidl']);
  });
}
