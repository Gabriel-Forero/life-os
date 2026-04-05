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
    test('emits BudgetThresholdEvent at 80%', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;
      final now = DateTime.now();

      // Set budget at 100000
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

      // Add expense that crosses 80% (80000 of 100000)
      await notifier.addTransaction(TransactionInput(
        type: 'expense',
        amountCents: 80000,
        categoryId: catId,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events, hasLength(1));
      expect(events.first.percentage, greaterThanOrEqualTo(0.8));
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
      // Should emit both 80% and 100%
      expect(events, hasLength(2));
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

      // First expense: 90000 (crosses 80%)
      await notifier.addTransaction(TransactionInput(
        type: 'expense',
        amountCents: 90000,
        categoryId: catId,
      ));

      final events = <BudgetThresholdEvent>[];
      eventBus.on<BudgetThresholdEvent>().listen(events.add);

      // Second expense: 5000 (still above 80%, below 100%, no new crossing)
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
}
