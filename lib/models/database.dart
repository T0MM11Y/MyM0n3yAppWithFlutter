import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:mymoney/models/category.dart';
import 'package:mymoney/models/transaction.dart';
import 'package:mymoney/models/transaction_with_category.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart'; // Ensure this file is correctly generated

@DriftDatabase(
  tables: [Categories, Transactions],
)
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<Category>> getAllCategories(int type) {
    return (select(categories)..where((tbl) => tbl.type.equals(type))).get();
  }

  Future<void> updateCategory(int id, String name) {
    return (update(categories)..where((tbl) => tbl.id.equals(id)))
        .write(CategoriesCompanion(name: Value(name)));
  }

  Future<void> deleteCategory(int id) {
    return (delete(categories)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Function to get the type of a category
  Future<int> getCategoryType(int id) async {
    final category = await (select(categories)
          ..where((tbl) => tbl.id.equals(id))
          ..limit(1))
        .getSingle();
    return category.type;
  }

  Future<void> deleteTransaction(int id) {
    return (delete(transactions)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> updateTransaction(int id, String name, int amount,
      int categoryId, DateTime transactionDate) {
    return (update(transactions)..where((tbl) => tbl.id.equals(id))).write(
      TransactionsCompanion(
        name: Value(name),
        amount: Value(amount),
        categoryId: Value(categoryId),
        transactionDate: Value(transactionDate),
      ),
    );
  }

  Future<void> editTransaction(int id, String name, int amount, int categoryId,
      DateTime transactionDate) {
    return (update(transactions)..where((tbl) => tbl.id.equals(id)))
        .write(TransactionsCompanion(
      name: Value(name),
      amount: Value(amount),
      categoryId: Value(categoryId),
      transactionDate: Value(transactionDate),
    ));
  }

  Stream<List<TransactionWithCategory>> getTransactionsByMonth(
      DateTime selectedDate) {
    final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final endOfMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);

    final query = (select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId))
    ])
          ..where(transactions.transactionDate
              .isBetweenValues(startOfMonth, endOfMonth)))
        .watch();

    return query.map((rows) => rows.map((row) {
          return TransactionWithCategory(
            transaction: row.readTable(transactions),
            category: row.readTable(categories),
          );
        }).toList());
  }

  Future<Map<String, double>> getMonthlyTotals(DateTime selectedDate) async {
    final startOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final endOfMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);

    final incomeCategoryIds = await (select(categories)
          ..where((c) => c.type.equals(0)))
        .map((c) => c.id)
        .get();
    final expenseCategoryIds = await (select(categories)
          ..where((c) => c.type.equals(1)))
        .map((c) => c.id)
        .get();

    final incomeQuery = select(transactions)
      ..where((tbl) =>
          tbl.transactionDate.isBetweenValues(startOfMonth, endOfMonth))
      ..where((tbl) => tbl.categoryId.isIn(incomeCategoryIds));

    final expenseQuery = select(transactions)
      ..where((tbl) =>
          tbl.transactionDate.isBetweenValues(startOfMonth, endOfMonth))
      ..where((tbl) => tbl.categoryId.isIn(expenseCategoryIds));

    final totalIncome = (await incomeQuery.map((row) => row.amount).get())
        .fold<double>(0, (previousValue, element) => previousValue + element);

    final totalExpense = (await expenseQuery.map((row) => row.amount).get())
        .fold<double>(0, (previousValue, element) => previousValue + element);

    return {
      'income': totalIncome,
      'expense': totalExpense,
    };
  }

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'db.sqlite'));
      return NativeDatabase(file);
    });
  }
}
