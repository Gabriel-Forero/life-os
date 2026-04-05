import 'package:life_os/core/database/app_database.dart';

class CategoryExpenseSlice {
  const CategoryExpenseSlice({
    required this.categoryId,
    required this.totalCents,
    required this.percentage,
  });

  final int categoryId;
  final int totalCents;
  final double percentage;
}

class DailyBar {
  const DailyBar({
    required this.date,
    required this.incomeCents,
    required this.expenseCents,
  });

  final DateTime date;
  final int incomeCents;
  final int expenseCents;
}

class CumulativePoint {
  const CumulativePoint({
    required this.date,
    required this.cumulativeCents,
  });

  final DateTime date;
  final int cumulativeCents;
}

List<CategoryExpenseSlice> computePieChartData(List<Transaction> transactions) {
  final expenses = transactions.where((t) => t.type == 'expense');
  if (expenses.isEmpty) return [];

  final byCategory = <int, int>{};
  for (final tx in expenses) {
    byCategory[tx.categoryId] =
        (byCategory[tx.categoryId] ?? 0) + tx.amountCents;
  }

  final total = byCategory.values.fold<int>(0, (a, b) => a + b);
  if (total == 0) return [];

  return byCategory.entries
      .map(
        (e) => CategoryExpenseSlice(
          categoryId: e.key,
          totalCents: e.value,
          percentage: e.value / total,
        ),
      )
      .toList()
    ..sort((a, b) => b.totalCents.compareTo(a.totalCents));
}

List<DailyBar> computeBarChartData(
  List<Transaction> transactions,
  DateTime from,
  DateTime to,
) {
  final byDay = <DateTime, ({int income, int expense})>{};

  for (final tx in transactions) {
    final dayKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
    final existing = byDay[dayKey] ?? (income: 0, expense: 0);

    if (tx.type == 'income') {
      byDay[dayKey] = (income: existing.income + tx.amountCents, expense: existing.expense);
    } else {
      byDay[dayKey] = (income: existing.income, expense: existing.expense + tx.amountCents);
    }
  }

  return byDay.entries
      .map(
        (e) => DailyBar(
          date: e.key,
          incomeCents: e.value.income,
          expenseCents: e.value.expense,
        ),
      )
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
}

List<CumulativePoint> computeLineChartData(
  List<Transaction> transactions,
  DateTime from,
) {
  final sorted = List<Transaction>.from(transactions)
    ..sort((a, b) => a.date.compareTo(b.date));

  final byDay = <DateTime, int>{};
  for (final tx in sorted) {
    final dayKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
    final delta = tx.type == 'income' ? tx.amountCents : -tx.amountCents;
    byDay[dayKey] = (byDay[dayKey] ?? 0) + delta;
  }

  final days = byDay.keys.toList()..sort();
  var cumulative = 0;
  final points = <CumulativePoint>[];

  for (final day in days) {
    cumulative += byDay[day]!;
    points.add(CumulativePoint(date: day, cumulativeCents: cumulative));
  }

  return points;
}
