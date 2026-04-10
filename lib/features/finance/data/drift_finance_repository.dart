import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/finance/data/finance_repository.dart';
import 'package:life_os/features/finance/database/finance_dao.dart';
import 'package:life_os/features/finance/domain/models/budget_model.dart';
import 'package:life_os/features/finance/domain/models/budget_template_item_model.dart';
import 'package:life_os/features/finance/domain/models/budget_template_model.dart';
import 'package:life_os/features/finance/domain/models/category_group_member_model.dart';
import 'package:life_os/features/finance/domain/models/category_group_model.dart';
import 'package:life_os/features/finance/domain/models/category_model.dart';
import 'package:life_os/features/finance/domain/models/group_budget_model.dart';
import 'package:life_os/features/finance/domain/models/monthly_budget_config_model.dart';
import 'package:life_os/features/finance/domain/models/recurring_transaction_model.dart';
import 'package:life_os/features/finance/domain/models/savings_goal_model.dart';
import 'package:life_os/features/finance/domain/models/transaction_model.dart';

class DriftFinanceRepository implements FinanceRepository {
  DriftFinanceRepository({required this.dao});

  final FinanceDao dao;

  // =========================================================================
  // Mapping helpers
  // =========================================================================

  static TransactionModel _toTransactionModel(Transaction row) =>
      TransactionModel(
        id: row.id.toString(),
        type: row.type,
        amountCents: row.amountCents,
        categoryId: row.categoryId.toString(),
        note: row.note,
        date: row.date,
        recurringId: row.recurringId?.toString(),
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static CategoryModel _toCategoryModel(Category row) => CategoryModel(
        id: row.id.toString(),
        name: row.name,
        icon: row.icon,
        color: row.color,
        type: row.type,
        isPredefined: row.isPredefined,
        sortOrder: row.sortOrder,
        createdAt: row.createdAt,
      );

  static BudgetModel _toBudgetModel(Budget row) => BudgetModel(
        id: row.id.toString(),
        categoryId: row.categoryId.toString(),
        amountCents: row.amountCents,
        month: row.month,
        year: row.year,
        autoRepeat: row.autoRepeat,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static SavingsGoalModel _toSavingsGoalModel(SavingsGoal row) =>
      SavingsGoalModel(
        id: row.id.toString(),
        name: row.name,
        targetCents: row.targetCents,
        currentCents: row.currentCents,
        deadline: row.deadline,
        isCompleted: row.isCompleted,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static RecurringTransactionModel _toRecurringModel(
          RecurringTransaction row) =>
      RecurringTransactionModel(
        id: row.id.toString(),
        type: row.type,
        amountCents: row.amountCents,
        categoryId: row.categoryId.toString(),
        note: row.note,
        frequency: row.frequency,
        nextOccurrence: row.nextOccurrence,
        isActive: row.isActive,
        createdAt: row.createdAt,
      );

  static CategoryGroupModel _toGroupModel(CategoryGroup row) =>
      CategoryGroupModel(
        id: row.id.toString(),
        name: row.name,
        color: row.color,
        sortOrder: row.sortOrder,
        createdAt: row.createdAt,
      );

  static CategoryGroupMemberModel _toMemberModel(CategoryGroupMember row) =>
      CategoryGroupMemberModel(
        id: row.id.toString(),
        groupId: row.groupId.toString(),
        categoryId: row.categoryId.toString(),
      );

  static GroupBudgetModel _toGroupBudgetModel(GroupBudget row) =>
      GroupBudgetModel(
        id: row.id.toString(),
        groupId: row.groupId.toString(),
        amountCents: row.amountCents,
        month: row.month,
        year: row.year,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static BudgetTemplateModel _toTemplateModel(BudgetTemplate row) =>
      BudgetTemplateModel(
        id: row.id.toString(),
        name: row.name,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static BudgetTemplateItemModel _toTemplateItemModel(
          BudgetTemplateItem row) =>
      BudgetTemplateItemModel(
        id: row.id.toString(),
        templateId: row.templateId.toString(),
        categoryId: row.categoryId.toString(),
        amountCents: row.amountCents,
      );

  static MonthlyBudgetConfigModel _toConfigModel(MonthlyBudgetConfig row) =>
      MonthlyBudgetConfigModel(
        id: row.id.toString(),
        globalBudgetCents: row.globalBudgetCents,
        month: row.month,
        year: row.year,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  // =========================================================================
  // Transactions
  // =========================================================================

  @override
  Future<String> insertTransaction({
    required String type,
    required int amountCents,
    required String categoryId,
    String? note,
    required DateTime date,
    String? recurringId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final id = await dao.insertTransaction(TransactionsCompanion.insert(
      type: type,
      amountCents: amountCents,
      categoryId: int.parse(categoryId),
      note: Value(note),
      date: date,
      recurringId: Value(recurringId != null ? int.parse(recurringId) : null),
      createdAt: createdAt,
      updatedAt: updatedAt,
    ));
    return id.toString();
  }

  @override
  Future<void> updateTransaction({
    required String id,
    required String type,
    required int amountCents,
    required String categoryId,
    String? note,
    required DateTime date,
    required DateTime updatedAt,
  }) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await (dao.db.update(dao.db.transactions)
          ..where((t) => t.id.equals(intId)))
        .write(TransactionsCompanion(
      type: Value(type),
      amountCents: Value(amountCents),
      categoryId: Value(int.parse(categoryId)),
      note: Value(note),
      date: Value(date),
      updatedAt: Value(updatedAt),
    ));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.deleteTransaction(intId);
  }

  @override
  Stream<List<TransactionModel>> watchTransactions(
    DateTime from,
    DateTime to,
  ) {
    return dao
        .watchTransactions(from, to)
        .map((rows) => rows.map(_toTransactionModel).toList());
  }

  @override
  Future<List<TransactionModel>> getTransactionsByCategory(
    String categoryId,
    DateTime from,
    DateTime to,
  ) async {
    final intId = int.tryParse(categoryId);
    if (intId == null) return [];
    final rows = await dao.getTransactionsByCategory(intId, from, to);
    return rows.map(_toTransactionModel).toList();
  }

  @override
  Future<int> sumByType(String type, DateTime from, DateTime to) {
    return dao.sumByType(type, from, to);
  }

  // =========================================================================
  // Categories
  // =========================================================================

  @override
  Future<String> insertCategory({
    required String name,
    String icon = 'category',
    int color = 0xFF9CA3AF,
    String type = 'expense',
    bool isPredefined = false,
    int sortOrder = 0,
    required DateTime createdAt,
  }) async {
    final id = await dao.insertCategory(CategoriesCompanion.insert(
      name: name,
      icon: Value(icon),
      color: Value(color),
      type: Value(type),
      isPredefined: Value(isPredefined),
      sortOrder: Value(sortOrder),
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Future<void> updateCategory({
    required String id,
    String? icon,
    int? color,
  }) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await (dao.db.update(dao.db.categories)
          ..where((c) => c.id.equals(intId)))
        .write(CategoriesCompanion(
      icon: icon != null ? Value(icon) : const Value.absent(),
      color: color != null ? Value(color) : const Value.absent(),
    ));
  }

  @override
  Future<void> deleteCategory(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.deleteCategory(intId);
  }

  @override
  Stream<List<CategoryModel>> watchCategories() {
    return dao
        .watchCategories()
        .map((rows) => rows.map(_toCategoryModel).toList());
  }

  @override
  Future<List<CategoryModel>> getCategoriesByType(String type) async {
    final rows = await dao.getCategoriesByType(type);
    return rows.map(_toCategoryModel).toList();
  }

  @override
  Future<CategoryModel?> getCategoryByName(String name) async {
    final row = await dao.getCategoryByName(name);
    return row != null ? _toCategoryModel(row) : null;
  }

  @override
  Future<int> countTransactionsInCategory(String categoryId) async {
    final intId = int.tryParse(categoryId);
    if (intId == null) return 0;
    return dao.countTransactionsInCategory(intId);
  }

  @override
  Future<void> reassignTransactions(
      String fromCategoryId, String toCategoryId) async {
    final fromId = int.tryParse(fromCategoryId);
    final toId = int.tryParse(toCategoryId);
    if (fromId == null || toId == null) return;
    await dao.reassignTransactions(fromId, toId);
  }

  // =========================================================================
  // Budgets
  // =========================================================================

  @override
  Future<String> insertBudget({
    required String categoryId,
    required int amountCents,
    required int month,
    required int year,
    bool autoRepeat = true,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final id = await dao.insertBudget(BudgetsCompanion.insert(
      categoryId: int.parse(categoryId),
      amountCents: amountCents,
      month: month,
      year: year,
      autoRepeat: Value(autoRepeat),
      createdAt: createdAt,
      updatedAt: updatedAt,
    ));
    return id.toString();
  }

  @override
  Future<void> updateBudget({
    required String id,
    required int amountCents,
    required DateTime updatedAt,
  }) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await (dao.db.update(dao.db.budgets)..where((b) => b.id.equals(intId)))
        .write(BudgetsCompanion(
      amountCents: Value(amountCents),
      updatedAt: Value(updatedAt),
    ));
  }

  @override
  Stream<List<BudgetModel>> watchBudgets(int month, int year) {
    return dao
        .watchBudgets(month, year)
        .map((rows) => rows.map(_toBudgetModel).toList());
  }

  @override
  Future<BudgetModel?> getBudget(
      String categoryId, int month, int year) async {
    final intId = int.tryParse(categoryId);
    if (intId == null) return null;
    final row = await dao.getBudget(intId, month, year);
    return row != null ? _toBudgetModel(row) : null;
  }

  @override
  Future<int> spentInBudget(String categoryId, int month, int year) async {
    final intId = int.tryParse(categoryId);
    if (intId == null) return 0;
    return dao.spentInBudget(intId, month, year);
  }

  @override
  Future<void> deleteBudgetsForCategory(String categoryId) async {
    final intId = int.tryParse(categoryId);
    if (intId == null) return;
    await dao.deleteBudgetsForCategory(intId);
  }

  @override
  Future<List<BudgetModel>> getBudgetsForMonth(int month, int year) async {
    final rows = await dao.getBudgetsForMonth(month, year);
    return rows.map(_toBudgetModel).toList();
  }

  @override
  Future<void> copyBudgetsToMonth({
    required int fromMonth,
    required int fromYear,
    required int toMonth,
    required int toYear,
  }) {
    return dao.copyBudgetsToMonth(
      fromMonth: fromMonth,
      fromYear: fromYear,
      toMonth: toMonth,
      toYear: toYear,
    );
  }

  // =========================================================================
  // Budget Templates
  // =========================================================================

  @override
  Future<String> insertTemplate({
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final id = await dao.insertTemplate(BudgetTemplatesCompanion.insert(
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
    ));
    return id.toString();
  }

  @override
  Stream<List<BudgetTemplateModel>> watchTemplates() {
    return dao
        .watchTemplates()
        .map((rows) => rows.map(_toTemplateModel).toList());
  }

  @override
  Future<void> deleteTemplate(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.deleteTemplate(intId);
  }

  @override
  Future<String> insertTemplateItem({
    required String templateId,
    required String categoryId,
    required int amountCents,
  }) async {
    final id = await dao.insertTemplateItem(BudgetTemplateItemsCompanion.insert(
      templateId: int.parse(templateId),
      categoryId: int.parse(categoryId),
      amountCents: amountCents,
    ));
    return id.toString();
  }

  @override
  Future<List<BudgetTemplateItemModel>> getTemplateItems(
      String templateId) async {
    final intId = int.tryParse(templateId);
    if (intId == null) return [];
    final rows = await dao.getTemplateItems(intId);
    return rows.map(_toTemplateItemModel).toList();
  }

  @override
  Future<String> saveCurrentBudgetsAsTemplate({
    required String name,
    required int month,
    required int year,
  }) async {
    final id = await dao.saveCurrentBudgetsAsTemplate(
      name: name,
      month: month,
      year: year,
    );
    return id.toString();
  }

  @override
  Future<void> applyTemplate({
    required String templateId,
    required int month,
    required int year,
  }) async {
    final intId = int.tryParse(templateId);
    if (intId == null) return;
    await dao.applyTemplate(
      templateId: intId,
      month: month,
      year: year,
    );
  }

  // =========================================================================
  // Monthly Budget Config
  // =========================================================================

  @override
  Future<MonthlyBudgetConfigModel?> getMonthlyConfig(
      int month, int year) async {
    final row = await dao.getMonthlyConfig(month, year);
    return row != null ? _toConfigModel(row) : null;
  }

  @override
  Future<void> setGlobalBudget({
    required int amountCents,
    required int month,
    required int year,
  }) {
    return dao.setGlobalBudget(
      amountCents: amountCents,
      month: month,
      year: year,
    );
  }

  @override
  Future<void> copyMonthlyConfig({
    required int fromMonth,
    required int fromYear,
    required int toMonth,
    required int toYear,
  }) {
    return dao.copyMonthlyConfig(
      fromMonth: fromMonth,
      fromYear: fromYear,
      toMonth: toMonth,
      toYear: toYear,
    );
  }

  @override
  Future<Map<String, int>> getMonthlySpentByCategory(
      int month, int year) async {
    final intResult = await dao.getMonthlySpentByCategory(month, year);
    return intResult
        .map((key, value) => MapEntry(key.toString(), value));
  }

  @override
  Future<List<({DateTime date, int cents})>> getDailyExpenses(
      int month, int year) {
    return dao.getDailyExpenses(month, year);
  }

  // =========================================================================
  // Category Groups
  // =========================================================================

  @override
  Future<String> insertGroup({
    required String name,
    int color = 0xFF9CA3AF,
    required DateTime createdAt,
  }) async {
    final id = await dao.insertGroup(CategoryGroupsCompanion.insert(
      name: name,
      color: Value(color),
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Stream<List<CategoryGroupModel>> watchGroups() {
    return dao
        .watchGroups()
        .map((rows) => rows.map(_toGroupModel).toList());
  }

  @override
  Future<void> deleteGroup(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.deleteGroup(intId);
  }

  @override
  Future<void> addCategoryToGroup(String groupId, String categoryId) async {
    final gId = int.tryParse(groupId);
    final cId = int.tryParse(categoryId);
    if (gId == null || cId == null) return;
    await dao.addCategoryToGroup(gId, cId);
  }

  @override
  Future<void> removeCategoryFromGroup(
      String groupId, String categoryId) async {
    final gId = int.tryParse(groupId);
    final cId = int.tryParse(categoryId);
    if (gId == null || cId == null) return;
    await dao.removeCategoryFromGroup(gId, cId);
  }

  @override
  Future<List<CategoryGroupMemberModel>> getGroupMembers(
      String groupId) async {
    final intId = int.tryParse(groupId);
    if (intId == null) return [];
    final rows = await dao.getGroupMembers(intId);
    return rows.map(_toMemberModel).toList();
  }

  @override
  Future<String?> getCategoryGroupId(String categoryId) async {
    final intId = int.tryParse(categoryId);
    if (intId == null) return null;
    final result = await dao.getCategoryGroupId(intId);
    return result?.toString();
  }

  // =========================================================================
  // Group Budgets
  // =========================================================================

  @override
  Future<GroupBudgetModel?> getGroupBudget(
      String groupId, int month, int year) async {
    final intId = int.tryParse(groupId);
    if (intId == null) return null;
    final row = await dao.getGroupBudget(intId, month, year);
    return row != null ? _toGroupBudgetModel(row) : null;
  }

  @override
  Stream<List<GroupBudgetModel>> watchGroupBudgets(int month, int year) {
    return dao
        .watchGroupBudgets(month, year)
        .map((rows) => rows.map(_toGroupBudgetModel).toList());
  }

  @override
  Future<void> setGroupBudget({
    required String groupId,
    required int amountCents,
    required int month,
    required int year,
  }) async {
    final intId = int.tryParse(groupId);
    if (intId == null) return;
    await dao.setGroupBudget(
      groupId: intId,
      amountCents: amountCents,
      month: month,
      year: year,
    );
  }

  @override
  Future<int> spentInGroup(String groupId, int month, int year) async {
    final intId = int.tryParse(groupId);
    if (intId == null) return 0;
    return dao.spentInGroup(intId, month, year);
  }

  @override
  Future<void> copyGroupBudgetsToMonth({
    required int fromMonth,
    required int fromYear,
    required int toMonth,
    required int toYear,
  }) {
    return dao.copyGroupBudgetsToMonth(
      fromMonth: fromMonth,
      fromYear: fromYear,
      toMonth: toMonth,
      toYear: toYear,
    );
  }

  // =========================================================================
  // Savings Goals
  // =========================================================================

  @override
  Future<String> insertSavingsGoal({
    required String name,
    required int targetCents,
    int currentCents = 0,
    DateTime? deadline,
    bool isCompleted = false,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final id = await dao.insertSavingsGoal(SavingsGoalsCompanion.insert(
      name: name,
      targetCents: targetCents,
      currentCents: Value(currentCents),
      deadline: Value(deadline),
      isCompleted: Value(isCompleted),
      createdAt: createdAt,
      updatedAt: updatedAt,
    ));
    return id.toString();
  }

  @override
  Future<void> updateSavingsGoal({
    required String id,
    required int currentCents,
    required bool isCompleted,
    required DateTime updatedAt,
  }) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await (dao.db.update(dao.db.savingsGoals)
          ..where((g) => g.id.equals(intId)))
        .write(SavingsGoalsCompanion(
      currentCents: Value(currentCents),
      isCompleted: Value(isCompleted),
      updatedAt: Value(updatedAt),
    ));
  }

  @override
  Future<void> deleteSavingsGoal(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.deleteSavingsGoal(intId);
  }

  @override
  Stream<List<SavingsGoalModel>> watchSavingsGoals() {
    return dao
        .watchSavingsGoals()
        .map((rows) => rows.map(_toSavingsGoalModel).toList());
  }

  // =========================================================================
  // Recurring Transactions
  // =========================================================================

  @override
  Future<String> insertRecurring({
    required String type,
    required int amountCents,
    required String categoryId,
    String? note,
    String frequency = 'monthly',
    required DateTime nextOccurrence,
    bool isActive = true,
    required DateTime createdAt,
  }) async {
    final id =
        await dao.insertRecurring(RecurringTransactionsCompanion.insert(
      type: type,
      amountCents: amountCents,
      categoryId: int.parse(categoryId),
      note: Value(note),
      frequency: Value(frequency),
      nextOccurrence: nextOccurrence,
      isActive: Value(isActive),
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Future<List<RecurringTransactionModel>> getDueRecurrings(DateTime now) async {
    final rows = await dao.getDueRecurrings(now);
    return rows.map(_toRecurringModel).toList();
  }

  @override
  Future<void> updateNextOccurrence(String id, DateTime next) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.updateNextOccurrence(intId, next);
  }
}
