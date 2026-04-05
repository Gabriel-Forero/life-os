import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/finance/database/finance_tables.dart';

part 'finance_dao.g.dart';

@DriftAccessor(tables: [
  Transactions,
  Categories,
  Budgets,
  SavingsGoals,
  RecurringTransactions,
])
class FinanceDao extends DatabaseAccessor<AppDatabase>
    with _$FinanceDaoMixin {
  FinanceDao(super.db);

  // --- Transactions ---

  Future<int> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<void> updateTransaction(Transaction entry) =>
      (update(transactions)..where((t) => t.id.equals(entry.id)))
          .write(TransactionsCompanion(
        type: Value(entry.type),
        amountCents: Value(entry.amountCents),
        categoryId: Value(entry.categoryId),
        note: Value(entry.note),
        date: Value(entry.date),
        updatedAt: Value(DateTime.now()),
      ));

  Future<void> deleteTransaction(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Stream<List<Transaction>> watchTransactions(
    DateTime from,
    DateTime to,
  ) =>
      (select(transactions)
            ..where(
              (t) =>
                  t.date.isBiggerOrEqualValue(from) &
                  t.date.isSmallerOrEqualValue(to),
            )
            ..orderBy([
              (t) => OrderingTerm.desc(t.date),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .watch();

  Future<List<Transaction>> getTransactionsByCategory(
    int categoryId,
    DateTime from,
    DateTime to,
  ) =>
      (select(transactions)
            ..where(
              (t) =>
                  t.categoryId.equals(categoryId) &
                  t.date.isBiggerOrEqualValue(from) &
                  t.date.isSmallerOrEqualValue(to),
            ))
          .get();

  Future<int> sumByType(String type, DateTime from, DateTime to) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.amountCents.sum()])
      ..where(
        transactions.type.equals(type) &
            transactions.date.isBiggerOrEqualValue(from) &
            transactions.date.isSmallerOrEqualValue(to),
      );
    final result = await query.getSingle();
    return result.read(transactions.amountCents.sum()) ?? 0;
  }

  // --- Categories ---

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  Future<void> updateCategory(Category entry) =>
      (update(categories)..where((c) => c.id.equals(entry.id))).write(
        CategoriesCompanion(
          icon: Value(entry.icon),
          color: Value(entry.color),
        ),
      );

  Future<void> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  Stream<List<Category>> watchCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .watch();

  Future<List<Category>> getCategoriesByType(String type) =>
      (select(categories)
            ..where(
              (c) => c.type.equals(type) | c.type.equals('both'),
            )
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .get();

  Future<Category?> getCategoryByName(String name) =>
      (select(categories)..where((c) => c.name.equals(name)))
          .getSingleOrNull();

  Future<int> countTransactionsInCategory(int categoryId) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.id.count()])
      ..where(transactions.categoryId.equals(categoryId));
    final result = await query.getSingle();
    return result.read(transactions.id.count()) ?? 0;
  }

  Future<void> reassignTransactions(int fromCategoryId, int toCategoryId) =>
      (update(transactions)
            ..where((t) => t.categoryId.equals(fromCategoryId)))
          .write(TransactionsCompanion(categoryId: Value(toCategoryId)));

  // --- Budgets ---

  Future<int> insertBudget(BudgetsCompanion entry) =>
      into(budgets).insert(entry);

  Future<void> updateBudget(Budget entry) =>
      (update(budgets)..where((b) => b.id.equals(entry.id))).write(
        BudgetsCompanion(
          amountCents: Value(entry.amountCents),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Stream<List<Budget>> watchBudgets(int month, int year) =>
      (select(budgets)
            ..where(
              (b) => b.month.equals(month) & b.year.equals(year),
            ))
          .watch();

  Future<Budget?> getBudget(int categoryId, int month, int year) =>
      (select(budgets)
            ..where(
              (b) =>
                  b.categoryId.equals(categoryId) &
                  b.month.equals(month) &
                  b.year.equals(year),
            ))
          .getSingleOrNull();

  Future<int> spentInBudget(int categoryId, int month, int year) async {
    final from = DateTime(year, month);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);

    final query = selectOnly(transactions)
      ..addColumns([transactions.amountCents.sum()])
      ..where(
        transactions.categoryId.equals(categoryId) &
            transactions.type.equals('expense') &
            transactions.date.isBiggerOrEqualValue(from) &
            transactions.date.isSmallerOrEqualValue(to),
      );
    final result = await query.getSingle();
    return result.read(transactions.amountCents.sum()) ?? 0;
  }

  Future<void> deleteBudgetsForCategory(int categoryId) =>
      (delete(budgets)..where((b) => b.categoryId.equals(categoryId))).go();

  // --- Savings Goals ---

  Future<int> insertSavingsGoal(SavingsGoalsCompanion entry) =>
      into(savingsGoals).insert(entry);

  Future<void> updateSavingsGoal(SavingsGoal entry) =>
      (update(savingsGoals)..where((g) => g.id.equals(entry.id))).write(
        SavingsGoalsCompanion(
          currentCents: Value(entry.currentCents),
          isCompleted: Value(entry.isCompleted),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteSavingsGoal(int id) =>
      (delete(savingsGoals)..where((g) => g.id.equals(id))).go();

  Stream<List<SavingsGoal>> watchSavingsGoals() =>
      (select(savingsGoals)
            ..orderBy([(g) => OrderingTerm.asc(g.isCompleted)]))
          .watch();

  // --- Recurring Transactions ---

  Future<int> insertRecurring(RecurringTransactionsCompanion entry) =>
      into(recurringTransactions).insert(entry);

  Future<List<RecurringTransaction>> getDueRecurrings(DateTime now) =>
      (select(recurringTransactions)
            ..where(
              (r) =>
                  r.isActive.equals(true) &
                  r.nextOccurrence.isSmallerOrEqualValue(now),
            ))
          .get();

  Future<void> updateNextOccurrence(int id, DateTime next) =>
      (update(recurringTransactions)..where((r) => r.id.equals(id)))
          .write(RecurringTransactionsCompanion(nextOccurrence: Value(next)));
}
