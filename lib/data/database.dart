import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

@DataClassName('CouponRow')
class Coupons extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get merchant => text()();
  TextColumn get kind => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get category => text().nullable()();
  TextColumn get tag => text().nullable()();
  TextColumn get codeValue => text().nullable()();
  TextColumn get codeFormat => text().nullable()();
  TextColumn get discountType => text()();
  RealColumn get discountValue => real().nullable()();
  RealColumn get minSpend => real().nullable()();
  TextColumn get conditions => text().nullable()();
  DateTimeColumn get validFrom => dateTime().nullable()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get imagePath => text().nullable()();
  TextColumn get source => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Coupons])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'tempusfugit'));

  @override
  int get schemaVersion => 1;
}
