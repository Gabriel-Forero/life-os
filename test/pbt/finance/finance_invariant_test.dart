import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
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

  group('INV-FIN-01: totalIncome - totalExpenses == netBalance', () {
    test('for 100 random transactions', () async {
      final random = Random(42);
      final cats = await dao.watchCategories().first;
      final now = DateTime.now();

      var expectedIncome = 0;
      var expectedExpenses = 0;

      for (var i = 0; i < 100; i++) {
        final isIncome = random.nextBool();
        final amount = random.nextInt(5000000) + 1;
        final cat = cats[random.nextInt(cats.length)];

        await notifier.addTransaction(TransactionInput(
          type: isIncome ? 'income' : 'expense',
          amountCents: amount,
          categoryId: cat.id,
        ));

        if (isIncome) {
          expectedIncome += amount;
        } else {
          expectedExpenses += amount;
        }
      }

      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final totalIncome = await dao.sumByType('income', from, to);
      final totalExpenses = await dao.sumByType('expense', from, to);

      expect(totalIncome, expectedIncome);
      expect(totalExpenses, expectedExpenses);
      expect(totalIncome - totalExpenses, expectedIncome - expectedExpenses);
    });
  });

  group('INV-FIN-04: All transaction amounts are strictly positive', () {
    test('after inserting 50 random transactions', () async {
      final random = Random(42);
      final cats = await dao.watchCategories().first;
      final now = DateTime.now();

      for (var i = 0; i < 50; i++) {
        final amount = random.nextInt(10000000) + 1;
        final cat = cats[random.nextInt(cats.length)];
        await notifier.addTransaction(TransactionInput(
          type: random.nextBool() ? 'income' : 'expense',
          amountCents: amount,
          categoryId: cat.id,
        ));
      }

      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final txs = await dao.watchTransactions(from, to).first;

      for (final tx in txs) {
        expect(tx.amountCents, greaterThan(0),
            reason: 'Transaction ${tx.id} has non-positive amount');
      }
    });
  });

  group('INV-FIN-05: Every transaction has valid categoryId', () {
    test('after 50 transactions with random categories', () async {
      final random = Random(42);
      final cats = await dao.watchCategories().first;
      final catIds = cats.map((c) => c.id).toSet();
      final now = DateTime.now();

      for (var i = 0; i < 50; i++) {
        final cat = cats[random.nextInt(cats.length)];
        await notifier.addTransaction(TransactionInput(
          type: random.nextBool() ? 'income' : 'expense',
          amountCents: random.nextInt(5000000) + 1,
          categoryId: cat.id,
        ));
      }

      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final txs = await dao.watchTransactions(from, to).first;

      for (final tx in txs) {
        expect(catIds.contains(tx.categoryId), isTrue,
            reason: 'Transaction ${tx.id} references non-existent category ${tx.categoryId}');
      }
    });
  });

  group('IDP-FIN-02: Budget upsert is idempotent', () {
    test('setting same budget twice results in one row', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;
      final now = DateTime.now();

      await notifier.setBudget(
        categoryId: catId,
        amountCents: 500000,
        month: now.month,
        year: now.year,
      );

      await notifier.setBudget(
        categoryId: catId,
        amountCents: 500000,
        month: now.month,
        year: now.year,
      );

      final budgets = await dao.watchBudgets(now.month, now.year).first;
      expect(budgets, hasLength(1));
      expect(budgets.first.amountCents, 500000);
    });
  });
}
