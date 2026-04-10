import 'dart:async';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/finance/data/finance_repository.dart';
import 'package:life_os/features/finance/domain/finance_input.dart';
import 'package:life_os/features/finance/domain/finance_validators.dart';
import 'package:life_os/features/finance/domain/models/transaction_model.dart';

// ---------------------------------------------------------------------------
// Pending-delete helper
// ---------------------------------------------------------------------------

/// Holds the transaction being soft-deleted plus a timer that will physically
/// remove it from the DB after the undo window expires.
class _PendingDelete {
  _PendingDelete({required this.transaction, required this.timer});

  final TransactionModel transaction;
  final Timer timer;
}

class FinanceNotifier {
  FinanceNotifier({required this.repository, required this.eventBus});

  final FinanceRepository repository;
  final EventBus eventBus;

  _PendingDelete? _pendingDelete;

  // --- Transactions ---

  Future<Result<String>> addTransaction(TransactionInput input) async {
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
      final id = await repository.insertTransaction(
        type: input.type,
        amountCents: input.amountCents,
        categoryId: categoryId,
        note: noteResult.valueOrNull,
        date: date,
        createdAt: now,
        updatedAt: now,
      );

      // Post-insert: emit events for expenses
      if (input.type == 'expense') {
        final category = await repository.getCategoriesByType('expense');
        final catName = category
            .where((c) => c.id == categoryId)
            .map((c) => c.name)
            .firstOrNull ?? 'Otros';

        eventBus.emit(ExpenseAddedEvent(
          transactionId: int.tryParse(id) ?? 0,
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

  Future<Result<void>> editTransaction(String id, TransactionInput input) async {
    final amountResult = validateTransactionAmount(input.amountCents);
    if (amountResult.isFailure) return Failure(amountResult.failureOrNull!);

    final noteResult = validateTransactionNote(input.note);
    if (noteResult.isFailure) return Failure(noteResult.failureOrNull!);

    final categoryId = await _resolveCategory(input.categoryId, input.type);
    final date = input.date ?? DateTime.now();

    try {
      await repository.updateTransaction(
        id: id,
        type: input.type,
        amountCents: input.amountCents,
        categoryId: categoryId,
        note: noteResult.valueOrNull,
        date: date,
        updatedAt: DateTime.now(),
      );
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al actualizar transaccion',
        debugMessage: 'updateTransaction failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> removeTransaction(String id) async {
    try {
      await repository.deleteTransaction(id);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al eliminar transaccion',
        debugMessage: 'deleteTransaction failed: $e',
        originalError: e,
      ));
    }
  }

  /// Soft-deletes a transaction: hides it from the UI immediately and schedules
  /// the physical DB removal after 5 seconds. If [undoDelete] is called before
  /// the timer fires the transaction is silently restored.
  ///
  /// Returns [Success] immediately so the caller can show the undo SnackBar.
  Future<Result<void>> removeTransactionWithUndo(String id) async {
    try {
      // Fetch the transaction before hiding it.
      final allTxs = await repository.watchTransactions(
        DateTime(2000),
        DateTime(2100),
      ).first;
      final tx = allTxs.where((t) => t.id == id).firstOrNull;
      if (tx == null) {
        return Failure(NotFoundFailure(
          userMessage: 'Transaccion no encontrada',
          debugMessage: 'removeTransactionWithUndo: id=$id not found',
          entityType: 'Transaction',
          entityId: id,
        ));
      }

      // Cancel any previous pending delete first.
      _pendingDelete?.timer.cancel();

      // Schedule physical deletion after 5 seconds.
      final timer = Timer(const Duration(seconds: 5), () async {
        await repository.deleteTransaction(id);
        _pendingDelete = null;
      });

      _pendingDelete = _PendingDelete(transaction: tx, timer: timer);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al eliminar transaccion',
        debugMessage: 'removeTransactionWithUndo failed: $e',
        originalError: e,
      ));
    }
  }

  /// Cancels a pending undo-delete. The transaction was never physically removed
  /// so no restore is needed — just cancel the timer.
  void undoDelete() {
    _pendingDelete?.timer.cancel();
    _pendingDelete = null;
  }

  /// Whether there is a pending soft-delete in progress.
  bool get hasPendingDelete => _pendingDelete != null;

  /// The ID of the transaction currently pending deletion (null if none).
  String? get pendingDeleteId => _pendingDelete?.transaction.id;

  // --- Categories ---

  Future<Result<String>> addCategory(CategoryInput input) async {
    final nameResult = validateCategoryName(input.name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    final trimmedName = nameResult.valueOrNull!;

    // Check uniqueness
    final existing = await repository.getCategoryByName(trimmedName);
    if (existing != null) {
      return const Failure(ValidationFailure(
        userMessage: 'Ya existe una categoria con ese nombre',
        debugMessage: 'Duplicate category name',
        field: 'name',
      ));
    }

    try {
      final id = await repository.insertCategory(
        name: trimmedName,
        icon: input.icon,
        color: input.color,
        type: input.type,
        isPredefined: false,
        sortOrder: 99,
        createdAt: DateTime.now(),
      );
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
    String id, {
    String? icon,
    int? color,
  }) async {
    try {
      await repository.updateCategory(
        id: id,
        icon: icon,
        color: color,
      );
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al actualizar categoria',
        debugMessage: 'editPredefinedCategory failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> deleteCategory(String id, String targetCategoryId) async {
    try {
      await repository.reassignTransactions(id, targetCategoryId);
      await repository.deleteBudgetsForCategory(id);
      await repository.deleteCategory(id);
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
    required String categoryId,
    required int amountCents,
    required int month,
    required int year,
  }) async {
    final amountResult = validateBudgetAmount(amountCents);
    if (amountResult.isFailure) return Failure(amountResult.failureOrNull!);

    try {
      final existing = await repository.getBudget(categoryId, month, year);
      if (existing != null) {
        await repository.updateBudget(
          id: existing.id,
          amountCents: amountCents,
          updatedAt: DateTime.now(),
        );
      } else {
        await repository.insertBudget(
          categoryId: categoryId,
          amountCents: amountCents,
          month: month,
          year: year,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
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

  // --- Auto-repeat budgets ---

  /// Checks if the target month has budgets. If not, copies from the previous
  /// month (only budgets with autoRepeat = true) and the global budget config.
  /// Returns [Success(true)] if budgets were copied, [Success(false)] if the
  /// target month already had budgets.
  Future<Result<bool>> ensureBudgetsForMonth(int month, int year) async {
    try {
      final existing = await repository.getBudgetsForMonth(month, year);
      if (existing.isNotEmpty) return const Success(false);

      // Determine previous month
      final prevMonth = month == 1 ? 12 : month - 1;
      final prevYear = month == 1 ? year - 1 : year;

      final prevBudgets = await repository.getBudgetsForMonth(prevMonth, prevYear);
      if (prevBudgets.isEmpty) return const Success(false);

      await repository.copyBudgetsToMonth(
        fromMonth: prevMonth,
        fromYear: prevYear,
        toMonth: month,
        toYear: year,
      );

      await repository.copyMonthlyConfig(
        fromMonth: prevMonth,
        fromYear: prevYear,
        toMonth: month,
        toYear: year,
      );

      await repository.copyGroupBudgetsToMonth(
        fromMonth: prevMonth,
        fromYear: prevYear,
        toMonth: month,
        toYear: year,
      );

      return const Success(true);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al copiar presupuestos',
        debugMessage: 'ensureBudgetsForMonth failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Budget Templates ---

  Future<Result<String>> saveAsTemplate({
    required String name,
    required int month,
    required int year,
  }) async {
    final nameResult = validateCategoryName(name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    try {
      final templateId = await repository.saveCurrentBudgetsAsTemplate(
        name: nameResult.valueOrNull!,
        month: month,
        year: year,
      );
      return Success(templateId);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al guardar plantilla',
        debugMessage: 'saveAsTemplate failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> applyTemplate({
    required String templateId,
    required int month,
    required int year,
  }) async {
    try {
      await repository.applyTemplate(
        templateId: templateId,
        month: month,
        year: year,
      );
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al aplicar plantilla',
        debugMessage: 'applyTemplate failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> deleteTemplate(String templateId) async {
    try {
      await repository.deleteTemplate(templateId);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al eliminar plantilla',
        debugMessage: 'deleteTemplate failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Category Groups ---

  Future<Result<String>> addGroup({
    required String name,
    required int color,
  }) async {
    final nameResult = validateCategoryName(name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    try {
      final id = await repository.insertGroup(
        name: nameResult.valueOrNull!,
        color: color,
        createdAt: DateTime.now(),
      );
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al crear grupo',
        debugMessage: 'addGroup failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> removeGroup(String groupId) async {
    try {
      await repository.deleteGroup(groupId);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al eliminar grupo',
        debugMessage: 'removeGroup failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> assignCategoryToGroup(
      String groupId, String categoryId) async {
    try {
      await repository.addCategoryToGroup(groupId, categoryId);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al asignar categoria al grupo',
        debugMessage: 'assignCategoryToGroup failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> unassignCategoryFromGroup(
      String groupId, String categoryId) async {
    try {
      await repository.removeCategoryFromGroup(groupId, categoryId);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al desasignar categoria del grupo',
        debugMessage: 'unassignCategoryFromGroup failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> setGroupBudget({
    required String groupId,
    required int amountCents,
    required int month,
    required int year,
  }) async {
    final amountResult = validateBudgetAmount(amountCents);
    if (amountResult.isFailure) return Failure(amountResult.failureOrNull!);

    try {
      await repository.setGroupBudget(
        groupId: groupId,
        amountCents: amountCents,
        month: month,
        year: year,
      );
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al guardar presupuesto de grupo',
        debugMessage: 'setGroupBudget failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Global Budget ---

  Future<Result<void>> setGlobalBudget({
    required int amountCents,
    required int month,
    required int year,
  }) async {
    final amountResult = validateBudgetAmount(amountCents);
    if (amountResult.isFailure) return Failure(amountResult.failureOrNull!);

    try {
      await repository.setGlobalBudget(
        amountCents: amountCents,
        month: month,
        year: year,
      );
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al guardar presupuesto global',
        debugMessage: 'setGlobalBudget failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Savings Goals ---

  Future<Result<String>> addSavingsGoal(SavingsGoalInput input) async {
    final targetResult = validateSavingsGoalTarget(input.targetCents);
    if (targetResult.isFailure) return Failure(targetResult.failureOrNull!);

    final deadlineResult = validateSavingsGoalDeadline(input.deadline);
    if (deadlineResult.isFailure) return Failure(deadlineResult.failureOrNull!);

    final nameResult = validateCategoryName(input.name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    try {
      final now = DateTime.now();
      final id = await repository.insertSavingsGoal(
        name: nameResult.valueOrNull!,
        targetCents: input.targetCents,
        currentCents: 0,
        deadline: input.deadline,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al crear meta de ahorro',
        debugMessage: 'insertSavingsGoal failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> contributeToGoal(String goalId, int amountCents) async {
    if (amountCents <= 0) {
      return const Failure(ValidationFailure(
        userMessage: 'El monto debe ser mayor a \$0',
        debugMessage: 'contribution amountCents must be positive',
        field: 'amountCents',
      ));
    }

    try {
      final goals = await repository.watchSavingsGoals().first;
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

      await repository.updateSavingsGoal(
        id: goalId,
        currentCents: newCurrent,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
      );

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
  ///
  /// For each active template whose [nextOccurrence] is in the past, inserts
  /// all overdue transactions (handles the case where the app was closed for
  /// multiple days) and advances [nextOccurrence] to the future.
  ///
  /// Returns [Success] with the total number of transactions created, or a
  /// [Failure] on database error.
  Future<Result<int>> processRecurringTransactions() async {
    try {
      final now = DateTime.now();
      final dueRecurrings = await repository.getDueRecurrings(now);

      if (dueRecurrings.isEmpty) return const Success(0);

      var created = 0;
      for (final recurring in dueRecurrings) {
        var nextDate = recurring.nextOccurrence;

        // Create all overdue occurrences (handles multi-day app inactivity).
        while (!nextDate.isAfter(now)) {
          await repository.insertTransaction(
            type: recurring.type,
            amountCents: recurring.amountCents,
            categoryId: recurring.categoryId,
            note:
                '${recurring.note?.isNotEmpty == true ? '${recurring.note} ' : ''}(recurrente)'
                    .trim(),
            date: nextDate,
            recurringId: recurring.id,
            createdAt: now,
            updatedAt: now,
          );
          created++;
          nextDate = _advanceDate(nextDate, recurring.frequency);
        }

        // Persist the updated nextOccurrence.
        await repository.updateNextOccurrence(recurring.id, nextDate);
      }

      return Success(created);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al procesar recurrentes',
        debugMessage: 'processRecurringTransactions failed: $e',
        originalError: e,
      ));
    }
  }

  DateTime _advanceDate(DateTime date, String frequency) {
    return switch (frequency) {
      'daily' => date.add(const Duration(days: 1)),
      'weekly' => date.add(const Duration(days: 7)),
      'biweekly' => date.add(const Duration(days: 14)),
      'monthly' => DateTime(date.year, date.month + 1, date.day),
      'yearly' => DateTime(date.year + 1, date.month, date.day),
      _ => date.add(const Duration(days: 30)),
    };
  }

  // --- Private helpers ---

  Future<String> _resolveCategory(String? categoryId, String type) async {
    if (categoryId != null) return categoryId;

    final defaultName = type == 'income' ? 'General' : 'Otros';
    final cat = await repository.getCategoryByName(defaultName);
    if (cat != null) return cat.id;

    // Fallback: first category of matching type
    final cats = await repository.getCategoriesByType(type);
    if (cats.isNotEmpty) return cats.first.id;

    // Last resort: any category
    final all = await repository.watchCategories().first;
    return all.isNotEmpty ? all.first.id : '1';
  }

  static const _thresholds = [
    (value: 0.50, label: 50),
    (value: 0.75, label: 75),
    (value: 0.90, label: 90),
    (value: 1.0, label: 100),
  ];

  Future<void> _checkBudgetThreshold(
    String categoryId,
    int expenseAmount,
  ) async {
    final now = DateTime.now();
    final budget = await repository.getBudget(categoryId, now.month, now.year);
    if (budget == null) return;

    final totalSpent = await repository.spentInBudget(categoryId, now.month, now.year);
    final previousSpent = totalSpent - expenseAmount;

    final currentUtil = totalSpent / budget.amountCents;
    final previousUtil = previousSpent / budget.amountCents;

    final catName = (await repository.getCategoriesByType('expense'))
        .where((c) => c.id == categoryId)
        .map((c) => c.name)
        .firstOrNull ?? '';

    for (final t in _thresholds) {
      if (previousUtil < t.value && currentUtil >= t.value) {
        eventBus.emit(BudgetThresholdEvent(
          budgetId: int.tryParse(budget.id) ?? 0,
          categoryName: catName,
          percentage: currentUtil,
          threshold: t.label,
          level: 'category',
        ));
      }
    }

    // Check group-level threshold
    final groupId = await repository.getCategoryGroupId(categoryId);
    if (groupId != null) {
      final gb = await repository.getGroupBudget(groupId, now.month, now.year);
      if (gb != null) {
        final groupSpent = await repository.spentInGroup(groupId, now.month, now.year);
        final groupPrevSpent = groupSpent - expenseAmount;
        final groupUtil = groupSpent / gb.amountCents;
        final groupPrevUtil = groupPrevSpent / gb.amountCents;

        final groups = await repository.watchGroups().first;
        final groupName = groups
            .where((g) => g.id == groupId)
            .map((g) => g.name)
            .firstOrNull ?? '';

        for (final t in _thresholds) {
          if (groupPrevUtil < t.value && groupUtil >= t.value) {
            eventBus.emit(BudgetThresholdEvent(
              budgetId: int.tryParse(gb.id) ?? 0,
              categoryName: groupName,
              percentage: groupUtil,
              threshold: t.label,
              level: 'group',
            ));
          }
        }
      }
    }

    // Check global-level threshold
    final config = await repository.getMonthlyConfig(now.month, now.year);
    if (config?.globalBudgetCents != null && config!.globalBudgetCents! > 0) {
      final from = DateTime(now.year, now.month);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final globalSpent = await repository.sumByType('expense', from, to);
      final globalPrev = globalSpent - expenseAmount;
      final globalUtil = globalSpent / config.globalBudgetCents!;
      final globalPrevUtil = globalPrev / config.globalBudgetCents!;

      for (final t in _thresholds) {
        if (globalPrevUtil < t.value && globalUtil >= t.value) {
          eventBus.emit(BudgetThresholdEvent(
            budgetId: int.tryParse(config.id) ?? 0,
            categoryName: 'Global',
            percentage: globalUtil,
            threshold: t.label,
            level: 'global',
          ));
        }
      }
    }
  }
}
