import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/finance/database/finance_dao.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late FinanceDao dao;

  setUp(() async {
    db = _createInMemoryDb();
    dao = db.financeDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('FinanceDao — Transactions', () {
    Future<int> _insertExpenseCategory() async {
      return dao.insertCategory(CategoriesCompanion.insert(
        name: 'Alimentacion',
        icon: const Value('restaurant'),
        color: const Value(0xFF10B981),
        type: const Value('expense'),
        isPredefined: const Value(true),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));
    }

    test('insertTransaction returns id', () async {
      final catId = await _insertExpenseCategory();
      final id = await dao.insertTransaction(TransactionsCompanion.insert(
        type: 'expense',
        amountCents: 25000,
        categoryId: catId,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      expect(id, greaterThan(0));
    });

    test('watchTransactions returns inserted transactions', () async {
      final catId = await _insertExpenseCategory();
      final now = DateTime.now();

      await dao.insertTransaction(TransactionsCompanion.insert(
        type: 'expense',
        amountCents: 50000,
        categoryId: catId,
        date: now,
        createdAt: now,
        updatedAt: now,
      ));

      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final txs = await dao.watchTransactions(from, to).first;

      expect(txs, hasLength(1));
      expect(txs.first.amountCents, 50000);
      expect(txs.first.type, 'expense');
    });

    test('deleteTransaction removes the row', () async {
      final catId = await _insertExpenseCategory();
      final id = await dao.insertTransaction(TransactionsCompanion.insert(
        type: 'expense',
        amountCents: 10000,
        categoryId: catId,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      await dao.deleteTransaction(id);
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final txs = await dao.watchTransactions(from, to).first;
      expect(txs, isEmpty);
    });

    test('sumByType returns correct sum for expenses', () async {
      final catId = await _insertExpenseCategory();
      final now = DateTime.now();

      for (final amount in [10000, 20000, 30000]) {
        await dao.insertTransaction(TransactionsCompanion.insert(
          type: 'expense',
          amountCents: amount,
          categoryId: catId,
          date: now,
          createdAt: now,
          updatedAt: now,
        ));
      }

      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final sum = await dao.sumByType('expense', from, to);
      expect(sum, 60000);
    });

    test('sumByType returns 0 when no transactions exist', () async {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final sum = await dao.sumByType('income', from, to);
      expect(sum, 0);
    });
  });

  group('FinanceDao — Categories', () {
    test('insertCategory returns id', () async {
      final id = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Mascota',
        icon: const Value('pets'),
        color: const Value(0xFF10B981),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(20),
        createdAt: DateTime.now(),
      ));
      expect(id, greaterThan(0));
    });

    test('watchCategories returns all categories', () async {
      await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Cat1',
        icon: const Value('star'),
        color: const Value(0xFF000000),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));
      await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Cat2',
        icon: const Value('star'),
        color: const Value(0xFF000000),
        type: const Value('income'),
        isPredefined: const Value(false),
        sortOrder: const Value(1),
        createdAt: DateTime.now(),
      ));

      final cats = await dao.watchCategories().first;
      expect(cats, hasLength(2));
    });

    test('getCategoriesByType filters correctly', () async {
      await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Expense Cat',
        icon: const Value('star'),
        color: const Value(0xFF000000),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));
      await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Income Cat',
        icon: const Value('star'),
        color: const Value(0xFF000000),
        type: const Value('income'),
        isPredefined: const Value(false),
        sortOrder: const Value(1),
        createdAt: DateTime.now(),
      ));

      final expenses = await dao.getCategoriesByType('expense');
      expect(expenses, hasLength(1));
      expect(expenses.first.name, 'Expense Cat');
    });
  });

  group('FinanceDao — Budgets', () {
    test('insertBudget and spentInBudget calculates correctly', () async {
      final catId = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Food',
        icon: const Value('restaurant'),
        color: const Value(0xFF10B981),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));

      final now = DateTime.now();
      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId,
        amountCents: 500000,
        month: now.month,
        year: now.year,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Add expenses
      await dao.insertTransaction(TransactionsCompanion.insert(
        type: 'expense',
        amountCents: 100000,
        categoryId: catId,
        date: now,
        createdAt: now,
        updatedAt: now,
      ));
      await dao.insertTransaction(TransactionsCompanion.insert(
        type: 'expense',
        amountCents: 150000,
        categoryId: catId,
        date: now,
        createdAt: now,
        updatedAt: now,
      ));

      final spent = await dao.spentInBudget(catId, now.month, now.year);
      expect(spent, 250000);
    });

    test('watchBudgets returns budgets for given month', () async {
      final catId = await dao.insertCategory(CategoriesCompanion.insert(
        name: 'Transport',
        icon: const Value('car'),
        color: const Value(0xFF3B82F6),
        type: const Value('expense'),
        isPredefined: const Value(false),
        sortOrder: const Value(0),
        createdAt: DateTime.now(),
      ));

      final now = DateTime.now();
      await dao.insertBudget(BudgetsCompanion.insert(
        categoryId: catId,
        amountCents: 300000,
        month: now.month,
        year: now.year,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final budgets = await dao.watchBudgets(now.month, now.year).first;
      expect(budgets, hasLength(1));
      expect(budgets.first.amountCents, 300000);
    });
  });
}
