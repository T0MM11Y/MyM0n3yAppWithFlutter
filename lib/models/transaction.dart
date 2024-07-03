import 'package:drift/drift.dart';

@DataClassName('Transaction') // Corrected the data class name to singular form
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get categoryId =>
      integer().customConstraint('REFERENCES categories(id)')();
  DateTimeColumn get transactionDate =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get amount => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
