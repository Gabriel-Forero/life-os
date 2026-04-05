import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/finance/database/finance_dao.dart';
import 'package:life_os/features/finance/database/predefined_categories.dart';
import 'package:life_os/features/finance/domain/chart_data.dart';

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

  Future<void> _addExpense(int catId, int amount, DateTime date) async {
    await dao.insertTransaction(TransactionsCompanion.insert(
      type: 'expense',
      amountCents: amount,
      categoryId: catId,
      date: date,
      createdAt: date,
      updatedAt: date,
    ));
  }

  Future<void> _addIncome(int catId, int amount, DateTime date) async {
    await dao.insertTransaction(TransactionsCompanion.insert(
      type: 'income',
      amountCents: amount,
      categoryId: catId,
      date: date,
      createdAt: date,
      updatedAt: date,
    ));
  }

  group('ChartDataComputer — pieChartData', () {
    test('returns slices grouped by category', () async {
      final cats = await dao.getCategoriesByType('expense');
      final catFood = cats.firstWhere((c) => c.name == 'Alimentacion');
      final catTransport = cats.firstWhere((c) => c.name == 'Transporte');

      final now = DateTime.now();
      await _addExpense(catFood.id, 30000, now);
      await _addExpense(catFood.id, 20000, now);
      await _addExpense(catTransport.id, 50000, now);

      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final txs = await dao.watchTransactions(from, to).first;

      final slices = computePieChartData(txs);
      expect(slices, hasLength(2));

      final foodSlice = slices.firstWhere((s) => s.categoryId == catFood.id);
      expect(foodSlice.totalCents, 50000);
      expect(foodSlice.percentage, closeTo(0.5, 0.01));

      final transportSlice =
          slices.firstWhere((s) => s.categoryId == catTransport.id);
      expect(transportSlice.totalCents, 50000);
    });

    test('excludes income from pie chart', () async {
      final cats = await dao.getCategoriesByType('expense');
      final cat = cats.first;
      final incomeCats = await dao.getCategoriesByType('income');
      final incomeCat = incomeCats.first;

      final now = DateTime.now();
      await _addExpense(cat.id, 10000, now);
      await _addIncome(incomeCat.id, 50000, now);

      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final txs = await dao.watchTransactions(from, to).first;

      final slices = computePieChartData(txs);
      expect(slices, hasLength(1));
      expect(slices.first.totalCents, 10000);
    });

    test('returns empty list when no expenses', () async {
      final slices = computePieChartData([]);
      expect(slices, isEmpty);
    });
  });

  group('ChartDataComputer — barChartData', () {
    test('groups by day for range <= 31 days', () async {
      final cats = await dao.getCategoriesByType('expense');
      final cat = cats.first;
      final incomeCats = await dao.getCategoriesByType('income');
      final incomeCat = incomeCats.first;

      final day1 = DateTime(2026, 4, 1);
      final day2 = DateTime(2026, 4, 2);

      await _addExpense(cat.id, 10000, day1);
      await _addExpense(cat.id, 5000, day1);
      await _addIncome(incomeCat.id, 30000, day2);

      final from = DateTime(2026, 4, 1);
      final to = DateTime(2026, 4, 30, 23, 59, 59);
      final txs = await dao.watchTransactions(from, to).first;

      final bars = computeBarChartData(txs, from, to);
      expect(bars.isNotEmpty, isTrue);

      final bar1 = bars.firstWhere(
        (b) => b.date.day == 1,
        orElse: () => DailyBar(date: day1, incomeCents: 0, expenseCents: 0),
      );
      expect(bar1.expenseCents, 15000);

      final bar2 = bars.firstWhere(
        (b) => b.date.day == 2,
        orElse: () => DailyBar(date: day2, incomeCents: 0, expenseCents: 0),
      );
      expect(bar2.incomeCents, 30000);
    });
  });

  group('ChartDataComputer — lineChartData', () {
    test('computes cumulative net balance', () async {
      final cats = await dao.getCategoriesByType('expense');
      final cat = cats.first;
      final incomeCats = await dao.getCategoriesByType('income');
      final incomeCat = incomeCats.first;

      final day1 = DateTime(2026, 4, 1);
      final day2 = DateTime(2026, 4, 2);
      final day3 = DateTime(2026, 4, 3);

      await _addIncome(incomeCat.id, 100000, day1);
      await _addExpense(cat.id, 30000, day2);
      await _addExpense(cat.id, 20000, day3);

      final from = DateTime(2026, 4, 1);
      final to = DateTime(2026, 4, 30, 23, 59, 59);
      final txs = await dao.watchTransactions(from, to).first;

      final points = computeLineChartData(txs, from);

      // Day 1: +100000 → cumulative = 100000
      // Day 2: -30000 → cumulative = 70000
      // Day 3: -20000 → cumulative = 50000
      final point1 = points.firstWhere((p) => p.date.day == 1);
      expect(point1.cumulativeCents, 100000);

      final point2 = points.firstWhere((p) => p.date.day == 2);
      expect(point2.cumulativeCents, 70000);

      final point3 = points.firstWhere((p) => p.date.day == 3);
      expect(point3.cumulativeCents, 50000);
    });
  });
}
