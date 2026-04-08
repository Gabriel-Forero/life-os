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
  BoolColumn get autoRepeat =>
      boolean().withDefault(const Constant(true))();
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

class CategoryGroups extends Table {
  @override
  String get tableName => 'category_groups';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 30)();
  IntColumn get color => integer().withDefault(const Constant(0xFF9CA3AF))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

class CategoryGroupMembers extends Table {
  @override
  String get tableName => 'category_group_members';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer().references(CategoryGroups, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {groupId, categoryId},
      ];
}

class GroupBudgets extends Table {
  @override
  String get tableName => 'group_budgets';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer().references(CategoryGroups, #id)();
  IntColumn get amountCents => integer()();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {groupId, month, year},
      ];
}

class BudgetTemplates extends Table {
  @override
  String get tableName => 'budget_templates';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class BudgetTemplateItems extends Table {
  @override
  String get tableName => 'budget_template_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId =>
      integer().references(BudgetTemplates, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get amountCents => integer()();
}

class MonthlyBudgetConfigs extends Table {
  @override
  String get tableName => 'monthly_budget_configs';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get globalBudgetCents => integer().nullable()();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {month, year},
      ];
}
