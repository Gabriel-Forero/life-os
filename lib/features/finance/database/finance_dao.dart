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
  CategoryGroups,
  CategoryGroupMembers,
  GroupBudgets,
  BudgetTemplates,
  BudgetTemplateItems,
  MonthlyBudgetConfigs,
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

  Future<List<Budget>> getBudgetsForMonth(int month, int year) =>
      (select(budgets)
            ..where(
              (b) => b.month.equals(month) & b.year.equals(year),
            ))
          .get();

  Future<void> copyBudgetsToMonth({
    required int fromMonth,
    required int fromYear,
    required int toMonth,
    required int toYear,
  }) async {
    final source = await (select(budgets)
          ..where(
            (b) =>
                b.month.equals(fromMonth) &
                b.year.equals(fromYear) &
                b.autoRepeat.equals(true),
          ))
        .get();

    final now = DateTime.now();
    for (final b in source) {
      await into(budgets).insert(BudgetsCompanion.insert(
        categoryId: b.categoryId,
        amountCents: b.amountCents,
        month: toMonth,
        year: toYear,
        autoRepeat: Value(b.autoRepeat),
        createdAt: now,
        updatedAt: now,
      ));
    }
  }

  // --- Budget Templates ---

  Future<int> insertTemplate(BudgetTemplatesCompanion entry) =>
      into(budgetTemplates).insert(entry);

  Stream<List<BudgetTemplate>> watchTemplates() =>
      (select(budgetTemplates)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch();

  Future<void> deleteTemplate(int id) async {
    await (delete(budgetTemplateItems)
          ..where((i) => i.templateId.equals(id)))
        .go();
    await (delete(budgetTemplates)..where((t) => t.id.equals(id))).go();
  }

  Future<int> insertTemplateItem(BudgetTemplateItemsCompanion entry) =>
      into(budgetTemplateItems).insert(entry);

  Future<List<BudgetTemplateItem>> getTemplateItems(int templateId) =>
      (select(budgetTemplateItems)
            ..where((i) => i.templateId.equals(templateId)))
          .get();

  Future<int> saveCurrentBudgetsAsTemplate({
    required String name,
    required int month,
    required int year,
  }) async {
    final now = DateTime.now();
    final templateId =
        await into(budgetTemplates).insert(BudgetTemplatesCompanion.insert(
      name: name,
      createdAt: now,
      updatedAt: now,
    ));

    final currentBudgets = await getBudgetsForMonth(month, year);
    for (final b in currentBudgets) {
      await into(budgetTemplateItems)
          .insert(BudgetTemplateItemsCompanion.insert(
        templateId: templateId,
        categoryId: b.categoryId,
        amountCents: b.amountCents,
      ));
    }

    return templateId;
  }

  Future<void> applyTemplate({
    required int templateId,
    required int month,
    required int year,
  }) async {
    // Delete existing budgets for the target month
    await (delete(budgets)
          ..where(
            (b) => b.month.equals(month) & b.year.equals(year),
          ))
        .go();

    // Insert from template
    final items = await getTemplateItems(templateId);
    final now = DateTime.now();
    for (final item in items) {
      await into(budgets).insert(BudgetsCompanion.insert(
        categoryId: item.categoryId,
        amountCents: item.amountCents,
        month: month,
        year: year,
        createdAt: now,
        updatedAt: now,
      ));
    }
  }

  // --- Monthly Budget Config ---

  Future<MonthlyBudgetConfig?> getMonthlyConfig(int month, int year) =>
      (select(monthlyBudgetConfigs)
            ..where(
              (c) => c.month.equals(month) & c.year.equals(year),
            ))
          .getSingleOrNull();

  Future<void> setGlobalBudget({
    required int amountCents,
    required int month,
    required int year,
  }) async {
    final existing = await getMonthlyConfig(month, year);
    final now = DateTime.now();
    if (existing != null) {
      await (update(monthlyBudgetConfigs)
            ..where((c) => c.id.equals(existing.id)))
          .write(MonthlyBudgetConfigsCompanion(
        globalBudgetCents: Value(amountCents),
        updatedAt: Value(now),
      ));
    } else {
      await into(monthlyBudgetConfigs)
          .insert(MonthlyBudgetConfigsCompanion.insert(
        globalBudgetCents: Value(amountCents),
        month: month,
        year: year,
        createdAt: now,
        updatedAt: now,
      ));
    }
  }

  Future<void> copyMonthlyConfig({
    required int fromMonth,
    required int fromYear,
    required int toMonth,
    required int toYear,
  }) async {
    final source = await getMonthlyConfig(fromMonth, fromYear);
    if (source == null || source.globalBudgetCents == null) return;
    await setGlobalBudget(
      amountCents: source.globalBudgetCents!,
      month: toMonth,
      year: toYear,
    );
  }

  /// Returns expenses grouped by category for a given month.
  /// Used by budget analytics for comparison and trends.
  Future<Map<int, int>> getMonthlySpentByCategory(int month, int year) async {
    final from = DateTime(year, month);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);

    final rows = await (select(transactions)
          ..where(
            (t) =>
                t.type.equals('expense') &
                t.date.isBiggerOrEqualValue(from) &
                t.date.isSmallerOrEqualValue(to),
          ))
        .get();

    final result = <int, int>{};
    for (final tx in rows) {
      result[tx.categoryId] = (result[tx.categoryId] ?? 0) + tx.amountCents;
    }
    return result;
  }

  /// Returns daily expense totals for a given month (for projection).
  Future<List<({DateTime date, int cents})>> getDailyExpenses(
      int month, int year) async {
    final from = DateTime(year, month);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);

    final rows = await (select(transactions)
          ..where(
            (t) =>
                t.type.equals('expense') &
                t.date.isBiggerOrEqualValue(from) &
                t.date.isSmallerOrEqualValue(to),
          ))
        .get();

    final byDay = <DateTime, int>{};
    for (final tx in rows) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      byDay[day] = (byDay[day] ?? 0) + tx.amountCents;
    }

    return byDay.entries
        .map((e) => (date: e.key, cents: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // --- Category Groups ---

  Future<int> insertGroup(CategoryGroupsCompanion entry) =>
      into(categoryGroups).insert(entry);

  Stream<List<CategoryGroup>> watchGroups() =>
      (select(categoryGroups)
            ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
          .watch();

  Future<void> deleteGroup(int id) async {
    // Delete group budgets
    await (delete(groupBudgets)..where((gb) => gb.groupId.equals(id))).go();
    // Delete memberships
    await (delete(categoryGroupMembers)
          ..where((m) => m.groupId.equals(id)))
        .go();
    // Delete group
    await (delete(categoryGroups)..where((g) => g.id.equals(id))).go();
  }

  Future<void> addCategoryToGroup(int groupId, int categoryId) =>
      into(categoryGroupMembers).insert(CategoryGroupMembersCompanion.insert(
        groupId: groupId,
        categoryId: categoryId,
      ));

  Future<void> removeCategoryFromGroup(int groupId, int categoryId) =>
      (delete(categoryGroupMembers)
            ..where(
              (m) =>
                  m.groupId.equals(groupId) &
                  m.categoryId.equals(categoryId),
            ))
          .go();

  Future<List<CategoryGroupMember>> getGroupMembers(int groupId) =>
      (select(categoryGroupMembers)
            ..where((m) => m.groupId.equals(groupId)))
          .get();

  Future<int?> getCategoryGroupId(int categoryId) async {
    final member = await (select(categoryGroupMembers)
          ..where((m) => m.categoryId.equals(categoryId)))
        .getSingleOrNull();
    return member?.groupId;
  }

  // --- Group Budgets ---

  Future<GroupBudget?> getGroupBudget(int groupId, int month, int year) =>
      (select(groupBudgets)
            ..where(
              (gb) =>
                  gb.groupId.equals(groupId) &
                  gb.month.equals(month) &
                  gb.year.equals(year),
            ))
          .getSingleOrNull();

  Stream<List<GroupBudget>> watchGroupBudgets(int month, int year) =>
      (select(groupBudgets)
            ..where(
              (gb) => gb.month.equals(month) & gb.year.equals(year),
            ))
          .watch();

  Future<void> setGroupBudget({
    required int groupId,
    required int amountCents,
    required int month,
    required int year,
  }) async {
    final existing = await getGroupBudget(groupId, month, year);
    final now = DateTime.now();
    if (existing != null) {
      await (update(groupBudgets)..where((gb) => gb.id.equals(existing.id)))
          .write(GroupBudgetsCompanion(
        amountCents: Value(amountCents),
        updatedAt: Value(now),
      ));
    } else {
      await into(groupBudgets).insert(GroupBudgetsCompanion.insert(
        groupId: groupId,
        amountCents: amountCents,
        month: month,
        year: year,
        createdAt: now,
        updatedAt: now,
      ));
    }
  }

  Future<int> spentInGroup(int groupId, int month, int year) async {
    final members = await getGroupMembers(groupId);
    if (members.isEmpty) return 0;

    final catIds = members.map((m) => m.categoryId).toList();
    final from = DateTime(year, month);
    final to = DateTime(year, month + 1, 0, 23, 59, 59);

    final query = selectOnly(transactions)
      ..addColumns([transactions.amountCents.sum()])
      ..where(
        transactions.categoryId.isIn(catIds) &
            transactions.type.equals('expense') &
            transactions.date.isBiggerOrEqualValue(from) &
            transactions.date.isSmallerOrEqualValue(to),
      );
    final result = await query.getSingle();
    return result.read(transactions.amountCents.sum()) ?? 0;
  }

  Future<void> copyGroupBudgetsToMonth({
    required int fromMonth,
    required int fromYear,
    required int toMonth,
    required int toYear,
  }) async {
    final source = await (select(groupBudgets)
          ..where(
            (gb) =>
                gb.month.equals(fromMonth) & gb.year.equals(fromYear),
          ))
        .get();

    final now = DateTime.now();
    for (final gb in source) {
      await into(groupBudgets).insert(GroupBudgetsCompanion.insert(
        groupId: gb.groupId,
        amountCents: gb.amountCents,
        month: toMonth,
        year: toYear,
        createdAt: now,
        updatedAt: now,
      ));
    }
  }

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
