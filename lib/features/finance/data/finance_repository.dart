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

abstract class FinanceRepository {
  // --- Transactions ---

  Future<String> insertTransaction({
    required String type,
    required int amountCents,
    required String categoryId,
    String? note,
    required DateTime date,
    String? recurringId,
    required DateTime createdAt,
    required DateTime updatedAt,
  });

  Future<void> updateTransaction({
    required String id,
    required String type,
    required int amountCents,
    required String categoryId,
    String? note,
    required DateTime date,
    required DateTime updatedAt,
  });

  Future<void> deleteTransaction(String id);

  Stream<List<TransactionModel>> watchTransactions(
    DateTime from,
    DateTime to,
  );

  Future<List<TransactionModel>> getTransactionsByCategory(
    String categoryId,
    DateTime from,
    DateTime to,
  );

  Future<int> sumByType(String type, DateTime from, DateTime to);

  // --- Categories ---

  Future<String> insertCategory({
    required String name,
    String icon,
    int color,
    String type,
    bool isPredefined,
    int sortOrder,
    required DateTime createdAt,
  });

  Future<void> updateCategory({
    required String id,
    String? icon,
    int? color,
  });

  Future<void> deleteCategory(String id);

  Stream<List<CategoryModel>> watchCategories();

  Future<List<CategoryModel>> getCategoriesByType(String type);

  Future<CategoryModel?> getCategoryByName(String name);

  Future<int> countTransactionsInCategory(String categoryId);

  Future<void> reassignTransactions(String fromCategoryId, String toCategoryId);

  // --- Budgets ---

  Future<String> insertBudget({
    required String categoryId,
    required int amountCents,
    required int month,
    required int year,
    bool autoRepeat,
    required DateTime createdAt,
    required DateTime updatedAt,
  });

  Future<void> updateBudget({
    required String id,
    required int amountCents,
    required DateTime updatedAt,
  });

  Stream<List<BudgetModel>> watchBudgets(int month, int year);

  Future<BudgetModel?> getBudget(String categoryId, int month, int year);

  Future<int> spentInBudget(String categoryId, int month, int year);

  Future<void> deleteBudgetsForCategory(String categoryId);

  Future<List<BudgetModel>> getBudgetsForMonth(int month, int year);

  Future<void> copyBudgetsToMonth({
    required int fromMonth,
    required int fromYear,
    required int toMonth,
    required int toYear,
  });

  // --- Budget Templates ---

  Future<String> insertTemplate({
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
  });

  Stream<List<BudgetTemplateModel>> watchTemplates();

  Future<void> deleteTemplate(String id);

  Future<String> insertTemplateItem({
    required String templateId,
    required String categoryId,
    required int amountCents,
  });

  Future<List<BudgetTemplateItemModel>> getTemplateItems(String templateId);

  Future<String> saveCurrentBudgetsAsTemplate({
    required String name,
    required int month,
    required int year,
  });

  Future<void> applyTemplate({
    required String templateId,
    required int month,
    required int year,
  });

  // --- Monthly Budget Config ---

  Future<MonthlyBudgetConfigModel?> getMonthlyConfig(int month, int year);

  Future<void> setGlobalBudget({
    required int amountCents,
    required int month,
    required int year,
  });

  Future<void> copyMonthlyConfig({
    required int fromMonth,
    required int fromYear,
    required int toMonth,
    required int toYear,
  });

  /// Returns expenses grouped by category for a given month.
  Future<Map<String, int>> getMonthlySpentByCategory(int month, int year);

  /// Returns daily expense totals for a given month (for projection).
  Future<List<({DateTime date, int cents})>> getDailyExpenses(
      int month, int year);

  // --- Category Groups ---

  Future<String> insertGroup({
    required String name,
    int color,
    required DateTime createdAt,
  });

  Stream<List<CategoryGroupModel>> watchGroups();

  Future<void> deleteGroup(String id);

  Future<void> addCategoryToGroup(String groupId, String categoryId);

  Future<void> removeCategoryFromGroup(String groupId, String categoryId);

  Future<List<CategoryGroupMemberModel>> getGroupMembers(String groupId);

  Future<String?> getCategoryGroupId(String categoryId);

  // --- Group Budgets ---

  Future<GroupBudgetModel?> getGroupBudget(
      String groupId, int month, int year);

  Stream<List<GroupBudgetModel>> watchGroupBudgets(int month, int year);

  Future<void> setGroupBudget({
    required String groupId,
    required int amountCents,
    required int month,
    required int year,
  });

  Future<int> spentInGroup(String groupId, int month, int year);

  Future<void> copyGroupBudgetsToMonth({
    required int fromMonth,
    required int fromYear,
    required int toMonth,
    required int toYear,
  });

  // --- Savings Goals ---

  Future<String> insertSavingsGoal({
    required String name,
    required int targetCents,
    int currentCents,
    DateTime? deadline,
    bool isCompleted,
    required DateTime createdAt,
    required DateTime updatedAt,
  });

  Future<void> updateSavingsGoal({
    required String id,
    required int currentCents,
    required bool isCompleted,
    required DateTime updatedAt,
  });

  Future<void> deleteSavingsGoal(String id);

  Stream<List<SavingsGoalModel>> watchSavingsGoals();

  // --- Recurring Transactions ---

  Future<String> insertRecurring({
    required String type,
    required int amountCents,
    required String categoryId,
    String? note,
    String frequency,
    required DateTime nextOccurrence,
    bool isActive,
    required DateTime createdAt,
  });

  Future<List<RecurringTransactionModel>> getDueRecurrings(DateTime now);

  Future<void> updateNextOccurrence(String id, DateTime next);
}
