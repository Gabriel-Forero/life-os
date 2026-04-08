import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/finance/domain/budget_analytics.dart';

void main() {
  group('computeMonthComparison', () {
    test('returns change per category between two months', () {
      final current = {1: 500000, 2: 200000};
      final previous = {1: 400000, 2: 300000};

      final result = computeMonthComparison(
        currentSpentByCategory: current,
        previousSpentByCategory: previous,
      );

      expect(result, hasLength(2));
      final cat1 = result.firstWhere((r) => r.categoryId == 1);
      expect(cat1.currentCents, 500000);
      expect(cat1.previousCents, 400000);
      expect(cat1.changePercent, closeTo(0.25, 0.01));

      final cat2 = result.firstWhere((r) => r.categoryId == 2);
      expect(cat2.changePercent, closeTo(-0.333, 0.01));
    });

    test('handles category only in current month', () {
      final current = {1: 500000, 3: 100000};
      final previous = {1: 400000};

      final result = computeMonthComparison(
        currentSpentByCategory: current,
        previousSpentByCategory: previous,
      );

      final cat3 = result.firstWhere((r) => r.categoryId == 3);
      expect(cat3.previousCents, 0);
      expect(cat3.changePercent, isNull); // can't compute % from 0
    });

    test('returns empty for no data', () {
      final result = computeMonthComparison(
        currentSpentByCategory: {},
        previousSpentByCategory: {},
      );
      expect(result, isEmpty);
    });
  });

  group('computeTrend', () {
    test('returns monthly totals for each category', () {
      final monthlyData = {
        (month: 1, year: 2026): {1: 100000, 2: 50000},
        (month: 2, year: 2026): {1: 120000, 2: 60000},
        (month: 3, year: 2026): {1: 90000, 2: 70000},
      };

      final result = computeTrend(monthlyData);

      expect(result, hasLength(2)); // 2 categories
      final cat1 = result.firstWhere((t) => t.categoryId == 1);
      expect(cat1.monthlyTotals, hasLength(3));
      expect(cat1.averageCents, closeTo(103333, 1));
    });

    test('returns empty for no data', () {
      final result = computeTrend({});
      expect(result, isEmpty);
    });
  });

  group('computeProjection', () {
    test('projects end-of-month spending based on daily rate', () {
      final result = computeProjection(
        spentCents: 300000,
        budgetCents: 500000,
        daysPassed: 15,
        daysInMonth: 30,
      );

      expect(result.projectedCents, 600000); // 300000/15*30
      expect(result.dailyRate, 20000); // 300000/15
      expect(result.willExceed, isTrue);
      expect(result.exceedDay, isNotNull);
      expect(result.exceedDay, 25); // 500000/20000 = 25
    });

    test('returns no exceed when under budget', () {
      final result = computeProjection(
        spentCents: 100000,
        budgetCents: 500000,
        daysPassed: 15,
        daysInMonth: 30,
      );

      // dailyRate = 100000 ~/ 15 = 6666, projected = 6666 * 30 = 199980
      expect(result.projectedCents, 199980);
      expect(result.willExceed, isFalse);
      expect(result.exceedDay, isNull);
    });

    test('handles zero days passed', () {
      final result = computeProjection(
        spentCents: 0,
        budgetCents: 500000,
        daysPassed: 0,
        daysInMonth: 30,
      );

      expect(result.projectedCents, 0);
      expect(result.dailyRate, 0);
      expect(result.willExceed, isFalse);
    });

    test('handles zero budget', () {
      final result = computeProjection(
        spentCents: 100000,
        budgetCents: 0,
        daysPassed: 10,
        daysInMonth: 30,
      );

      expect(result.projectedCents, 300000);
      expect(result.willExceed, isFalse); // no budget = nothing to exceed
    });
  });

  group('computeDailySummary', () {
    test('computes daily summary with available per day', () {
      final result = computeDailySummary(
        totalSpentCents: 300000,
        totalBudgetCents: 1000000,
        daysPassed: 10,
        daysRemaining: 20,
      );

      expect(result.remainingCents, 700000);
      expect(result.availablePerDay, 35000); // 700000/20
      expect(result.utilizationPercent, closeTo(30, 0.1));
    });

    test('handles zero days remaining', () {
      final result = computeDailySummary(
        totalSpentCents: 1000000,
        totalBudgetCents: 1000000,
        daysPassed: 30,
        daysRemaining: 0,
      );

      expect(result.remainingCents, 0);
      expect(result.availablePerDay, 0);
    });
  });
}
