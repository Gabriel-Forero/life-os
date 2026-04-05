import 'package:drift/drift.dart';

class Transactions extends Table {
  @override
  String get tableName => 'transactions';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'income' or 'expense'
  IntColumn get amountCents => integer()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get note => text().nullable().withLength(max: 200)();
  DateTimeColumn get date => dateTime()();
  IntColumn get recurringId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class Categories extends Table {
  @override
  String get tableName => 'categories';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 30).unique()();
  TextColumn get icon => text().withDefault(const Constant('category'))();
  IntColumn get color => integer().withDefault(const Constant(0xFF9CA3AF))();
  TextColumn get type =>
      text().withDefault(const Constant('expense'))(); // 'expense', 'income', 'both'
  BoolColumn get isPredefined =>
      boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

class Budgets extends Table {
  @override
  String get tableName => 'budgets';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get amountCents => integer()();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {categoryId, month, year},
      ];
}

class SavingsGoals extends Table {
  @override
  String get tableName => 'savings_goals';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get targetCents => integer()();
  IntColumn get currentCents => integer().withDefault(const Constant(0))();
  DateTimeColumn get deadline => dateTime().nullable()();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class RecurringTransactions extends Table {
  @override
  String get tableName => 'recurring_transactions';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  IntColumn get amountCents => integer()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get note => text().nullable().withLength(max: 200)();
  TextColumn get frequency =>
      text().withDefault(const Constant('monthly'))();
  DateTimeColumn get nextOccurrence => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
}
