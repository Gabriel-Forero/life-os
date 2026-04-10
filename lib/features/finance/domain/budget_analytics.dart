// Pure functions for budget analytics — no DB or framework dependencies.

// ---------------------------------------------------------------------------
// Month comparison
// ---------------------------------------------------------------------------

class MonthComparisonItem {
  const MonthComparisonItem({
    required this.categoryId,
    required this.currentCents,
    required this.previousCents,
    required this.changePercent,
  });

  final String categoryId;
  final int currentCents;
  final int previousCents;

  /// Percentage change from previous to current. Null if previous was 0.
  final double? changePercent;

  bool get increased => currentCents > previousCents;
}

List<MonthComparisonItem> computeMonthComparison({
  required Map<String, int> currentSpentByCategory,
  required Map<String, int> previousSpentByCategory,
}) {
  final allCatIds = {
    ...currentSpentByCategory.keys,
    ...previousSpentByCategory.keys,
  };

  if (allCatIds.isEmpty) return [];

  return allCatIds.map((catId) {
    final current = currentSpentByCategory[catId] ?? 0;
    final previous = previousSpentByCategory[catId] ?? 0;
    final change = previous > 0 ? (current - previous) / previous : null;

    return MonthComparisonItem(
      categoryId: catId,
      currentCents: current,
      previousCents: previous,
      changePercent: change,
    );
  }).toList()
    ..sort((a, b) => b.currentCents.compareTo(a.currentCents));
}

// ---------------------------------------------------------------------------
// Trend (3-6 months)
// ---------------------------------------------------------------------------

class TrendItem {
  const TrendItem({
    required this.categoryId,
    required this.monthlyTotals,
    required this.averageCents,
  });

  final String categoryId;
  final List<MonthlyTotal> monthlyTotals;
  final double averageCents;
}

class MonthlyTotal {
  const MonthlyTotal({
    required this.month,
    required this.year,
    required this.totalCents,
  });

  final int month;
  final int year;
  final int totalCents;
}

List<TrendItem> computeTrend(
  Map<({int month, int year}), Map<String, int>> monthlyData,
) {
  if (monthlyData.isEmpty) return [];

  // Collect all category IDs
  final allCatIds = <String>{};
  for (final entry in monthlyData.values) {
    allCatIds.addAll(entry.keys);
  }

  // Sort month keys chronologically
  final sortedMonths = monthlyData.keys.toList()
    ..sort((a, b) {
      final cmp = a.year.compareTo(b.year);
      return cmp != 0 ? cmp : a.month.compareTo(b.month);
    });

  return allCatIds.map((catId) {
    final totals = sortedMonths.map((mk) {
      final spent = monthlyData[mk]?[catId] ?? 0;
      return MonthlyTotal(month: mk.month, year: mk.year, totalCents: spent);
    }).toList();

    final sum = totals.fold<int>(0, (s, t) => s + t.totalCents);
    final avg = totals.isNotEmpty ? sum / totals.length : 0.0;

    return TrendItem(
      categoryId: catId,
      monthlyTotals: totals,
      averageCents: avg,
    );
  }).toList()
    ..sort((a, b) => b.averageCents.compareTo(a.averageCents));
}

// ---------------------------------------------------------------------------
// Projection
// ---------------------------------------------------------------------------

class ProjectionResult {
  const ProjectionResult({
    required this.projectedCents,
    required this.dailyRate,
    required this.willExceed,
    required this.exceedDay,
  });

  final int projectedCents;
  final int dailyRate;
  final bool willExceed;

  /// Day of the month when the budget will be exceeded (null if won't exceed).
  final int? exceedDay;
}

ProjectionResult computeProjection({
  required int spentCents,
  required int budgetCents,
  required int daysPassed,
  required int daysInMonth,
}) {
  if (daysPassed <= 0) {
    return const ProjectionResult(
      projectedCents: 0,
      dailyRate: 0,
      willExceed: false,
      exceedDay: null,
    );
  }

  final dailyRate = spentCents ~/ daysPassed;
  final projected = dailyRate * daysInMonth;

  if (budgetCents <= 0) {
    return ProjectionResult(
      projectedCents: projected,
      dailyRate: dailyRate,
      willExceed: false,
      exceedDay: null,
    );
  }

  final willExceed = projected > budgetCents;
  int? exceedDay;
  if (willExceed && dailyRate > 0) {
    exceedDay = (budgetCents / dailyRate).ceil();
    if (exceedDay > daysInMonth) exceedDay = null;
  }

  return ProjectionResult(
    projectedCents: projected,
    dailyRate: dailyRate,
    willExceed: willExceed,
    exceedDay: exceedDay,
  );
}

// ---------------------------------------------------------------------------
// Daily summary
// ---------------------------------------------------------------------------

class DailySummary {
  const DailySummary({
    required this.remainingCents,
    required this.availablePerDay,
    required this.utilizationPercent,
  });

  final int remainingCents;
  final int availablePerDay;
  final double utilizationPercent;
}

DailySummary computeDailySummary({
  required int totalSpentCents,
  required int totalBudgetCents,
  required int daysPassed,
  required int daysRemaining,
}) {
  final remaining = (totalBudgetCents - totalSpentCents).clamp(0, totalBudgetCents);
  final perDay = daysRemaining > 0 ? remaining ~/ daysRemaining : 0;
  final util = totalBudgetCents > 0
      ? (totalSpentCents / totalBudgetCents) * 100
      : 0.0;

  return DailySummary(
    remainingCents: remaining,
    availablePerDay: perDay,
    utilizationPercent: util,
  );
}
