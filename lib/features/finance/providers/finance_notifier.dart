import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/finance/database/finance_dao.dart';
import 'package:life_os/features/finance/domain/finance_input.dart';
import 'package:life_os/features/finance/domain/finance_validators.dart';

class FinanceNotifier {
  FinanceNotifier({required this.dao, required this.eventBus});

  final FinanceDao dao;
  final EventBus eventBus;

  // --- Transactions ---

  Future<Result<int>> addTransaction(TransactionInput input) async {
    // Validate
    final typeResult = validateTransactionType(input.type);
    if (typeResult.isFailure) return Failure(typeResult.failureOrNull!);

    final amountResult = validateTransactionAmount(input.amountCents);
    if (amountResult.isFailure) return Failure(amountResult.failureOrNull!);

    final noteResult = validateTransactionNote(input.note);
    if (noteResult.isFailure) return Failure(noteResult.failureOrNull!);

    final date = input.date ?? DateTime.now();
    final dateResult = validateTransactionDate(date);
    if (dateResult.isFailure) return Failure(dateResult.failureOrNull!);

    // Resolve default category
    final categoryId = await _resolveCategory(input.categoryId, input.type);

    try {
      final now = DateTime.now();
      final id = await dao.insertTransaction(TransactionsCompanion.insert(
        type: input.type,
        amountCents: input.amountCents,
        categoryId: categoryId,
        note: Value(noteResult.valueOrNull),
        date: date,
        createdAt: now,
        updatedAt: now,
      ));

      // Post-insert: emit events for expenses
      if (input.type == 'expense') {
        final category = await dao.getCategoriesByType('expense');
        final catName = category
            .where((c) => c.id == categoryId)
            .map((c) => c.name)
            .firstOrNull ?? 'Otros';

        eventBus.emit(ExpenseAddedEvent(
          transactionId: id,
          categoryName: catName,
          amount: input.amountCents.toDouble(),
        ));

        // Check budget thresholds
        await _checkBudgetThreshold(categoryId, input.amountCents);
      }

      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al guardar transaccion',
        debugMessage: 'insertTransaction failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> editTransaction(int id, TransactionInput input) async {
    final amountResult = validateTransactionAmount(input.amountCents);
    if (amountResult.isFailure) return Failure(amountResult.failureOrNull!);

    final noteResult = validateTransactionNote(input.note);
    if (noteResult.isFailure) return Failure(noteResult.failureOrNull!);

    final categoryId = await _resolveCategory(input.categoryId, input.type);
    final date = input.date ?? DateTime.now();

    try {
      await (dao.db.update(dao.db.transactions)
            ..where((t) => t.id.equals(id)))
          .write(TransactionsCompanion(
        type: Value(input.type),
        amountCents: Value(input.amountCents),
        categoryId: Value(categoryId),
        note: Value(noteResult.valueOrNull),
        date: Value(date),
        updatedAt: Value(DateTime.now()),
      ));
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al actualizar transaccion',
        debugMessage: 'updateTransaction failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> removeTransaction(int id) async {
    try {
      await dao.deleteTransaction(id);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al eliminar transaccion',
        debugMessage: 'deleteTransaction failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Categories ---

  Future<Result<int>> addCategory(CategoryInput input) async {
    final nameResult = validateCategoryName(input.name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    final trimmedName = nameResult.valueOrNull!;

    // Check uniqueness
    final existing = await dao.getCategoryByName(trimmedName);
    if (existing != null) {
      return const Failure(ValidationFailure(
        userMessage: 'Ya existe una categoria con ese nombre',
        debugMessage: 'Duplicate category name',
        field: 'name',
      ));
    }

    try {
      final id = await dao.insertCategory(CategoriesCompanion.insert(
        name: trimmedName,
        icon: Value(input.icon),
        color: Value(input.color),
        type: Value(input.type),
        isPredefined: const Value(false),
        sortOrder: const Value(99),
        createdAt: DateTime.now(),
      ));
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al crear categoria',
        debugMessage: 'insertCategory failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> editPredefinedCategory(
    int id, {
    String? icon,
    int? color,
  }) async {
    try {
      await (dao.db.update(dao.db.categories)
            ..where((c) => c.id.equals(id)))
          .write(CategoriesCompanion(
        icon: icon != null ? Value(icon) : const Value.absent(),
        color: color != null ? Value(color) : const Value.absent(),
      ));
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al actualizar categoria',
        debugMessage: 'editPredefinedCategory failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> deleteCategory(int id, int targetCategoryId) async {
    try {
      await dao.db.transaction(() async {
        await dao.reassignTransactions(id, targetCategoryId);
        await dao.deleteBudgetsForCategory(id);
        await dao.deleteCategory(id);
      });
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al eliminar categoria',
        debugMessage: 'deleteCategory failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Budgets ---

  Future<Result<void>> setBudget({
    required int categoryId,
    required int amountCents,
    required int month,
    required int year,
  }) async {
    final amountResult = validateBudgetAmount(amountCents);
    if (amountResult.isFailure) return Failure(amountResult.failureOrNull!);

    try {
      final existing = await dao.getBudget(categoryId, month, year);
      if (existing != null) {
        await (dao.db.update(dao.db.budgets)
              ..where((b) => b.id.equals(existing.id)))
            .write(BudgetsCompanion(
          amountCents: Value(amountCents),
          updatedAt: Value(DateTime.now()),
        ));
      } else {
        await dao.insertBudget(BudgetsCompanion.insert(
          categoryId: categoryId,
          amountCents: amountCents,
          month: month,
          year: year,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al guardar presupuesto',
        debugMessage: 'setBudget failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Savings Goals ---

  Future<Result<int>> addSavingsGoal(SavingsGoalInput input) async {
    final targetResult = validateSavingsGoalTarget(input.targetCents);
    if (targetResult.isFailure) return Failure(targetResult.failureOrNull!);

    final deadlineResult = validateSavingsGoalDeadline(input.deadline);
    if (deadlineResult.isFailure) return Failure(deadlineResult.failureOrNull!);

    final nameResult = validateCategoryName(input.name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    try {
      final now = DateTime.now();
      final id = await dao.insertSavingsGoal(SavingsGoalsCompanion.insert(
        name: nameResult.valueOrNull!,
        targetCents: input.targetCents,
        currentCents: const Value(0),
        deadline: Value(input.deadline),
        isCompleted: const Value(false),
        createdAt: now,
        updatedAt: now,
      ));
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al crear meta de ahorro',
        debugMessage: 'insertSavingsGoal failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> contributeToGoal(int goalId, int amountCents) async {
    if (amountCents <= 0) {
      return const Failure(ValidationFailure(
        userMessage: 'El monto debe ser mayor a \$0',
        debugMessage: 'contribution amountCents must be positive',
        field: 'amountCents',
      ));
    }

    try {
      final goals = await dao.watchSavingsGoals().first;
      final goal = goals.where((g) => g.id == goalId).firstOrNull;
      if (goal == null) {
        return Failure(NotFoundFailure(
          userMessage: 'Meta no encontrada',
          debugMessage: 'SavingsGoal with id=$goalId not found',
          entityType: 'SavingsGoal',
          entityId: goalId,
        ));
      }

      final newCurrent = goal.currentCents + amountCents;
      final isCompleted = newCurrent >= goal.targetCents;

      await (dao.db.update(dao.db.savingsGoals)
            ..where((g) => g.id.equals(goalId)))
          .write(SavingsGoalsCompanion(
        currentCents: Value(newCurrent),
        isCompleted: Value(isCompleted),
        updatedAt: Value(DateTime.now()),
      ));

      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al contribuir a la meta',
        debugMessage: 'contributeToGoal failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Recurring Transactions ---

  /// Processes any overdue recurring transactions.
  /// Currently a no-op stub — recurring transaction scheduling will be
  /// implemented when the recurring-transactions feature is built out.
  Future<void> processRecurringTransactions() async {
    // TODO: Query recurring transaction templates and insert due entries.
    // Safe to call on every startup; returns immediately until implemented.
  }

  // --- Private helpers ---

  Future<int> _resolveCategory(int? categoryId, String type) async {
    if (categoryId != null) return categoryId;

    final defaultName = type == 'income' ? 'General' : 'Otros';
    final cat = await dao.getCategoryByName(defaultName);
    if (cat != null) return cat.id;

    // Fallback: first category of matching type
    final cats = await dao.getCategoriesByType(type);
    if (cats.isNotEmpty) return cats.first.id;

    // Last resort: any category
    final all = await dao.watchCategories().first;
    return all.isNotEmpty ? all.first.id : 1;
  }

  Future<void> _checkBudgetThreshold(
    int categoryId,
    int expenseAmount,
  ) async {
    final now = DateTime.now();
    final budget = await dao.getBudget(categoryId, now.month, now.year);
    if (budget == null) return;

    final totalSpent = await dao.spentInBudget(categoryId, now.month, now.year);
    final previousSpent = totalSpent - expenseAmount;

    final currentUtil = totalSpent / budget.amountCents;
    final previousUtil = previousSpent / budget.amountCents;

    final catName = (await dao.getCategoriesByType('expense'))
        .where((c) => c.id == categoryId)
        .map((c) => c.name)
        .firstOrNull ?? '';

    if (previousUtil < 0.8 && currentUtil >= 0.8) {
      eventBus.emit(BudgetThresholdEvent(
        budgetId: budget.id,
        categoryName: catName,
        percentage: currentUtil,
      ));
    }

    if (previousUtil < 1.0 && currentUtil >= 1.0) {
      eventBus.emit(BudgetThresholdEvent(
        budgetId: budget.id,
        categoryName: catName,
        percentage: currentUtil,
      ));
    }
  }
}
