import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/finance/database/finance_dao.dart';
import 'package:life_os/features/finance/database/predefined_categories.dart';

void main() {
  late AppDatabase db;
  late FinanceDao dao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.financeDao;
    await seedPredefinedCategories(dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('RT-FIN-01: Transaction insert → query round-trip', () {
    test('for 50 random transactions', () async {
      final random = Random(42);
      final cats = await dao.getCategoriesByType('expense');
      final now = DateTime.now();

      for (var i = 0; i < 50; i++) {
        final amount = random.nextInt(10000000) + 1;
        final catId = cats[random.nextInt(cats.length)].id;
        final type = random.nextBool() ? 'expense' : 'income';

        final id = await dao.insertTransaction(TransactionsCompanion.insert(
          type: type,
          amountCents: amount,
          categoryId: catId,
          date: now,
          createdAt: now,
          updatedAt: now,
        ));

        final from = DateTime(now.year, now.month, 1);
        final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        final txs = await dao.watchTransactions(from, to).first;
        final inserted = txs.firstWhere((t) => t.id == id);

        expect(inserted.amountCents, amount,
            reason: 'Amount mismatch for tx $id');
        expect(inserted.type, type, reason: 'Type mismatch for tx $id');
        expect(inserted.categoryId, catId,
            reason: 'Category mismatch for tx $id');
      }
    });
  });

  group('RT-FIN-02: Category insert → query round-trip', () {
    test('for 20 random categories', () async {
      final random = Random(42);

      for (var i = 0; i < 20; i++) {
        final name = 'TestCat_${random.nextInt(100000)}';
        final color = random.nextInt(0xFFFFFFFF);
        final icon = 'icon_$i';

        final id = await dao.insertCategory(CategoriesCompanion.insert(
          name: name,
          icon: Value(icon),
          color: Value(color),
          type: const Value('expense'),
          isPredefined: const Value(false),
          sortOrder: Value(20 + i),
          createdAt: DateTime.now(),
        ));

        final cats = await dao.watchCategories().first;
        final inserted = cats.firstWhere((c) => c.id == id);

        expect(inserted.name, name, reason: 'Name mismatch');
        expect(inserted.color, color, reason: 'Color mismatch');
        expect(inserted.icon, icon, reason: 'Icon mismatch');
      }
    });
  });

  group('RT-FIN-03: Budget upsert → query returns latest', () {
    test('for 30 random upserts', () async {
      final random = Random(42);
      final cats = await dao.getCategoriesByType('expense');
      final catId = cats.first.id;

      for (var i = 0; i < 30; i++) {
        final amount = random.nextInt(5000000) + 1;

        final existing = await dao.getBudget(catId, 4, 2026);
        if (existing != null) {
          await (db.update(db.budgets)
                ..where((b) => b.id.equals(existing.id)))
              .write(BudgetsCompanion(
            amountCents: Value(amount),
            updatedAt: Value(DateTime.now()),
          ));
        } else {
          await dao.insertBudget(BudgetsCompanion.insert(
            categoryId: catId,
            amountCents: amount,
            month: 4,
            year: 2026,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }

        final budget = await dao.getBudget(catId, 4, 2026);
        expect(budget, isNotNull);
        expect(budget!.amountCents, amount,
            reason: 'Budget should reflect latest amount after upsert $i');
      }
    });
  });
}
