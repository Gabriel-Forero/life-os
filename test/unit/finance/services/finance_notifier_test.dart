import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/finance/database/finance_dao.dart';
import 'package:life_os/features/finance/database/predefined_categories.dart';
import 'package:life_os/features/finance/domain/finance_input.dart';
import 'package:life_os/features/finance/providers/finance_notifier.dart';

void main() {
  late AppDatabase db;
  late FinanceDao dao;
  late EventBus eventBus;
  late FinanceNotifier notifier;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.financeDao;
    eventBus = EventBus();
    await seedPredefinedCategories(dao);
    notifier = FinanceNotifier(dao: dao, eventBus: eventBus);
  });

  tearDown(() async {
    eventBus.dispose();
    await db.close();
  });

  group('FinanceNotifier — addTransaction', () {
    test('adds expense and returns Success', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;

      final result = await notifier.addTransaction(TransactionInput(
        type: 'expense',
        amountCents: 25000,
        categoryId: catId,
      ));

      expect(result, isA<Success<int>>());
    });

    test('adds income with default category when categoryId is null', () async {
      final result = await notifier.addTransaction(TransactionInput(
        type: 'income',
        amountCents: 3500000,
      ));

      expect(result, isA<Success<int>>());

      // Verify it used the "General" default category
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final txs = await dao.watchTransactions(from, to).first;
      expect(txs, hasLength(1));

      final general = await dao.getCategoryByName('General');
      expect(txs.first.categoryId, general!.id);
    });

    test('adds expense with default "Otros" when categoryId is null', () async {
      final result = await notifier.addTransaction(TransactionInput(
        type: 'expense',
        amountCents: 15000,
      ));

      expect(result, isA<Success<int>>());

      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final txs = await dao.watchTransactions(from, to).first;

      final otros = await dao.getCategoryByName('Otros');
      expect(txs.first.categoryId, otros!.id);
    });

    test('rejects zero amount', () async {
      final result = await notifier.addTransaction(TransactionInput(
        type: 'expense',
        amountCents: 0,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects invalid type', () async {
      final result = await notifier.addTransaction(TransactionInput(
        type: 'transfer',
        amountCents: 1000,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('emits ExpenseAddedEvent on expense', () async {
      final events = <ExpenseAddedEvent>[];
      eventBus.on<ExpenseAddedEvent>().listen(events.add);

      final cats = await dao.getCategoriesByType('expense');
      await notifier.addTransaction(TransactionInput(
        type: 'expense',
        amountCents: 50000,
        categoryId: cats.first.id,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events, hasLength(1));
      expect(events.first.amount, 50000);
    });

    test('does NOT emit ExpenseAddedEvent on income', () async {
      final events = <ExpenseAddedEvent>[];
      eventBus.on<ExpenseAddedEvent>().listen(events.add);

      await notifier.addTransaction(TransactionInput(
        type: 'income',
        amountCents: 100000,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events, isEmpty);
    });
  });

  group('FinanceNotifier — budget threshold', () {
    test('emits BudgetThresholdEvent at 50% and 75%', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;
      final now = DateTime.now();

      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId,
        amountCents: 100000,
        month: now.month,
        year: now.year,
        createdAt: now,
        updatedAt: now,
      ));

      final events = <BudgetThresholdEvent>[];
      eventBus.on<BudgetThresholdEvent>().listen(events.add);

      // Add expense that crosses 50% and 75% (80000 of 100000)
      await notifier.addTransaction(TransactionInput(
        type: 'expense',
        amountCents: 80000,
        categoryId: catId,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Should cross 50%, 75% thresholds (category level)
      final catEvents =
          events.where((e) => e.level == 'category').toList();
      expect(catEvents.length, greaterThanOrEqualTo(2));
      expect(catEvents.map((e) => e.threshold), contains(50));
      expect(catEvents.map((e) => e.threshold), contains(75));
    });

    test('emits BudgetThresholdEvent at 100%', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;
      final now = DateTime.now();

      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId,
        amountCents: 100000,
        month: now.month,
        year: now.year,
        createdAt: now,
        updatedAt: now,
      ));

      final events = <BudgetThresholdEvent>[];
      eventBus.on<BudgetThresholdEvent>().listen(events.add);

      // Add expense that crosses 100% (100000 of 100000)
      await notifier.addTransaction(TransactionInput(
        type: 'expense',
        amountCents: 100000,
        categoryId: catId,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Should emit 50%, 75%, 90%, and 100% (4 thresholds)
      final catEvents =
          events.where((e) => e.level == 'category').toList();
      expect(catEvents, hasLength(4));
    });

    test('does NOT re-emit if already above threshold', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;
      final now = DateTime.now();

      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId,
        amountCents: 100000,
        month: now.month,
        year: now.year,
        createdAt: now,
        updatedAt: now,
      ));

      // First expense: 90000 (crosses 50%, 75%)
      await notifier.addTransaction(TransactionInput(
        type: 'expense',
        amountCents: 90000,
        categoryId: catId,
      ));

      final events = <BudgetThresholdEvent>[];
      eventBus.on<BudgetThresholdEvent>().listen(events.add);

      // Second expense: 5000 (still above 90%, below 100%, no new crossing)
      await notifier.addTransaction(TransactionInput(
        type: 'expense',
        amountCents: 5000,
        categoryId: catId,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events, isEmpty);
    });
  });

  group('FinanceNotifier — setBudget', () {
    test('creates new budget', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;
      final now = DateTime.now();

      final result = await notifier.setBudget(
        categoryId: catId,
        amountCents: 500000,
        month: now.month,
        year: now.year,
      );

      expect(result, isA<Success<void>>());

      final budgets = await dao.watchBudgets(now.month, now.year).first;
      expect(budgets, hasLength(1));
      expect(budgets.first.amountCents, 500000);
    });

    test('upserts existing budget', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;
      final now = DateTime.now();

      await notifier.setBudget(
        categoryId: catId,
        amountCents: 500000,
        month: now.month,
        year: now.year,
      );

      // Update to new amount
      await notifier.setBudget(
        categoryId: catId,
        amountCents: 700000,
        month: now.month,
        year: now.year,
      );

      final budgets = await dao.watchBudgets(now.month, now.year).first;
      expect(budgets, hasLength(1));
      expect(budgets.first.amountCents, 700000);
    });

    test('rejects zero amount', () async {
      final result = await notifier.setBudget(
        categoryId: 1,
        amountCents: 0,
        month: 1,
        year: 2026,
      );
      expect(result, isA<Failure<void>>());
    });
  });

  group('FinanceNotifier — ensureBudgetsForMonth (auto-repeat)', () {
    test('copies budgets from previous month when target month is empty',
        () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;

      // Create budget for March 2026
      await notifier.setBudget(
        categoryId: catId,
        amountCents: 500000,
        month: 3,
        year: 2026,
      );

      // Set global budget for March
      await dao.setGlobalBudget(amountCents: 3000000, month: 3, year: 2026);

      // Ensure budgets for April (should auto-copy)
      final result = await notifier.ensureBudgetsForMonth(4, 2026);
      expect(result, isA<Success<bool>>());
      expect(result.valueOrNull, isTrue); // budgets were copied

      final budgets = await dao.getBudgetsForMonth(4, 2026);
      expect(budgets, hasLength(1));
      expect(budgets.first.amountCents, 500000);

      final config = await dao.getMonthlyConfig(4, 2026);
      expect(config, isNotNull);
      expect(config!.globalBudgetCents, 3000000);
    });

    test('does not copy if target month already has budgets', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;

      // Create budget for March and April
      await notifier.setBudget(
        categoryId: catId,
        amountCents: 500000,
        month: 3,
        year: 2026,
      );
      await notifier.setBudget(
        categoryId: catId,
        amountCents: 300000,
        month: 4,
        year: 2026,
      );

      final result = await notifier.ensureBudgetsForMonth(4, 2026);
      expect(result, isA<Success<bool>>());
      expect(result.valueOrNull, isFalse); // nothing copied

      // April budget unchanged
      final budgets = await dao.getBudgetsForMonth(4, 2026);
      expect(budgets.first.amountCents, 300000);
    });

    test('skips budgets with autoRepeat false', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId1 = cats[0].id;
      final catId2 = cats[1].id;

      // Budget with autoRepeat true (default)
      await notifier.setBudget(
        categoryId: catId1,
        amountCents: 500000,
        month: 3,
        year: 2026,
      );
      // Budget with autoRepeat false
      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId2,
        amountCents: 200000,
        month: 3,
        year: 2026,
        autoRepeat: const Value(false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await notifier.ensureBudgetsForMonth(4, 2026);

      final budgets = await dao.getBudgetsForMonth(4, 2026);
      expect(budgets, hasLength(1));
      expect(budgets.first.categoryId, catId1);
    });

    test('handles January (copies from December of previous year)', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;

      await notifier.setBudget(
        categoryId: catId,
        amountCents: 400000,
        month: 12,
        year: 2025,
      );

      await notifier.ensureBudgetsForMonth(1, 2026);

      final budgets = await dao.getBudgetsForMonth(1, 2026);
      expect(budgets, hasLength(1));
      expect(budgets.first.amountCents, 400000);
    });
  });

  group('FinanceNotifier — budget templates', () {
    test('saveAsTemplate captures current month budgets', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;

      await notifier.setBudget(
        categoryId: catId,
        amountCents: 500000,
        month: 4,
        year: 2026,
      );

      final result = await notifier.saveAsTemplate(
        name: 'Mes normal',
        month: 4,
        year: 2026,
      );

      expect(result, isA<Success<int>>());
      final templateId = result.valueOrNull!;
      final items = await dao.getTemplateItems(templateId);
      expect(items, hasLength(1));
      expect(items.first.amountCents, 500000);
    });

    test('saveAsTemplate rejects empty name', () async {
      final result = await notifier.saveAsTemplate(
        name: '',
        month: 4,
        year: 2026,
      );
      expect(result, isA<Failure<int>>());
    });

    test('applyTemplate overwrites target month budgets', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;

      // Existing budget for May
      await notifier.setBudget(
        categoryId: catId,
        amountCents: 300000,
        month: 5,
        year: 2026,
      );

      // Create template with different amount
      await notifier.setBudget(
        categoryId: catId,
        amountCents: 700000,
        month: 4,
        year: 2026,
      );
      final saveResult = await notifier.saveAsTemplate(
        name: 'Vacaciones',
        month: 4,
        year: 2026,
      );

      // Apply template to May
      final result = await notifier.applyTemplate(
        templateId: saveResult.valueOrNull!,
        month: 5,
        year: 2026,
      );
      expect(result, isA<Success<void>>());

      final budgets = await dao.getBudgetsForMonth(5, 2026);
      expect(budgets, hasLength(1));
      expect(budgets.first.amountCents, 700000);
    });

    test('deleteTemplate removes template', () async {
      final saveResult = await notifier.saveAsTemplate(
        name: 'Test',
        month: 4,
        year: 2026,
      );
      final templateId = saveResult.valueOrNull!;

      final result = await notifier.deleteTemplate(templateId);
      expect(result, isA<Success<void>>());

      final templates = await dao.watchTemplates().first;
      expect(templates, isEmpty);
    });
  });

  group('FinanceNotifier — global budget', () {
    test('setGlobalBudget creates config', () async {
      final result = await notifier.setGlobalBudget(
        amountCents: 3000000,
        month: 4,
        year: 2026,
      );
      expect(result, isA<Success<void>>());

      final config = await dao.getMonthlyConfig(4, 2026);
      expect(config!.globalBudgetCents, 3000000);
    });

    test('setGlobalBudget rejects zero', () async {
      final result = await notifier.setGlobalBudget(
        amountCents: 0,
        month: 4,
        year: 2026,
      );
      expect(result, isA<Failure<void>>());
    });
  });

  group('FinanceNotifier — category groups', () {
    test('addGroup creates group', () async {
      final result = await notifier.addGroup(
        name: 'Necesidades',
        color: 0xFF10B981,
      );
      expect(result, isA<Success<int>>());

      final groups = await dao.watchGroups().first;
      expect(groups, hasLength(1));
      expect(groups.first.name, 'Necesidades');
    });

    test('addGroup rejects empty name', () async {
      final result = await notifier.addGroup(name: '', color: 0xFF000000);
      expect(result, isA<Failure<int>>());
    });

    test('removeGroup deletes group', () async {
      final addResult = await notifier.addGroup(
        name: 'Test',
        color: 0xFF000000,
      );
      final groupId = addResult.valueOrNull!;

      final result = await notifier.removeGroup(groupId);
      expect(result, isA<Success<void>>());

      final groups = await dao.watchGroups().first;
      expect(groups, isEmpty);
    });

    test('assignCategoryToGroup adds membership', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;

      final addResult = await notifier.addGroup(
        name: 'Necesidades',
        color: 0xFF10B981,
      );
      final groupId = addResult.valueOrNull!;

      final result =
          await notifier.assignCategoryToGroup(groupId, catId);
      expect(result, isA<Success<void>>());

      final members = await dao.getGroupMembers(groupId);
      expect(members, hasLength(1));
    });

    test('unassignCategoryFromGroup removes membership', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;

      final addResult = await notifier.addGroup(
        name: 'Necesidades',
        color: 0xFF10B981,
      );
      final groupId = addResult.valueOrNull!;
      await notifier.assignCategoryToGroup(groupId, catId);

      final result =
          await notifier.unassignCategoryFromGroup(groupId, catId);
      expect(result, isA<Success<void>>());

      final members = await dao.getGroupMembers(groupId);
      expect(members, isEmpty);
    });

    test('setGroupBudget creates group budget', () async {
      final addResult = await notifier.addGroup(
        name: 'Necesidades',
        color: 0xFF10B981,
      );
      final groupId = addResult.valueOrNull!;

      final result = await notifier.setGroupBudget(
        groupId: groupId,
        amountCents: 1000000,
        month: 4,
        year: 2026,
      );
      expect(result, isA<Success<void>>());

      final gb = await dao.getGroupBudget(groupId, 4, 2026);
      expect(gb!.amountCents, 1000000);
    });

    test('setGroupBudget rejects zero amount', () async {
      final result = await notifier.setGroupBudget(
        groupId: 1,
        amountCents: 0,
        month: 4,
        year: 2026,
      );
      expect(result, isA<Failure<void>>());
    });

    test('ensureBudgetsForMonth also copies group budgets', () async {
      final addResult = await notifier.addGroup(
        name: 'Necesidades',
        color: 0xFF10B981,
      );
      final groupId = addResult.valueOrNull!;

      // Create category budget + group budget for March
      final cats = await dao.getCategoriesByType('expense');
      await notifier.setBudget(
        categoryId: cats.first.id,
        amountCents: 500000,
        month: 3,
        year: 2026,
      );
      await notifier.setGroupBudget(
        groupId: groupId,
        amountCents: 1000000,
        month: 3,
        year: 2026,
      );

      // Ensure April
      await notifier.ensureBudgetsForMonth(4, 2026);

      final gb = await dao.getGroupBudget(groupId, 4, 2026);
      expect(gb, isNotNull);
      expect(gb!.amountCents, 1000000);
    });
  });
}
