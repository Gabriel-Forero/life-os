import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:life_os/core/constants/app_breakpoints.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/finance/data/finance_repository.dart';
import 'package:life_os/features/finance/domain/amount_formatting.dart';
import 'package:life_os/features/finance/domain/budget_analytics.dart';
import 'package:life_os/features/finance/domain/models/category_model.dart';

class BudgetAnalyticsScreen extends ConsumerWidget {
  const BudgetAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(financeRepositoryProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.finance,
          title: const Text('Analisis de presupuesto'),
          bottom: const TabBar(
            labelColor: AppColors.finance,
            indicatorColor: AppColors.finance,
            tabs: [
              Tab(text: 'Comparacion'),
              Tab(text: 'Tendencias'),
              Tab(text: 'Proyeccion'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ComparisonTab(repo: repo),
            _TrendTab(repo: repo),
            _ProjectionTab(repo: repo),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1: Month vs Month comparison
// ---------------------------------------------------------------------------

class _ComparisonTab extends StatelessWidget {
  const _ComparisonTab({required this.repo});
  final FinanceRepository repo;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        repo.getMonthlySpentByCategory(now.month, now.year),
        repo.getMonthlySpentByCategory(prevMonth, prevYear),
        repo.watchCategories().first,
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final currentSpent = snap.data![0] as Map<String, int>;
        final previousSpent = snap.data![1] as Map<String, int>;
        final categories = snap.data![2] as List<CategoryModel>;
        final catMap = {for (final c in categories) c.id: c};

        final items = computeMonthComparison(
          currentSpentByCategory: currentSpent,
          previousSpentByCategory: previousSpent,
        );

        final totalCurrent = currentSpent.values.fold<int>(0, (a, b) => a + b);
        final totalPrevious = previousSpent.values.fold<int>(0, (a, b) => a + b);
        final totalChange = totalPrevious > 0
            ? ((totalCurrent - totalPrevious) / totalPrevious * 100).round()
            : 0;

        final theme = Theme.of(context);
        final currentLabel =
            DateFormat('MMMM', 'es').format(DateTime(now.year, now.month));
        final prevLabel =
            DateFormat('MMMM', 'es').format(DateTime(prevYear, prevMonth));

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppBreakpoints.isMediumOrLarger(constraints)
                      ? AppBreakpoints.maxContentWidth
                      : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(currentLabel,
                                      style: theme.textTheme.labelSmall),
                                  Text(totalCurrent.toCurrency('COP'),
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            Icon(
                              totalChange > 0
                                  ? Icons.trending_up
                                  : totalChange < 0
                                      ? Icons.trending_down
                                      : Icons.trending_flat,
                              color: totalChange > 0
                                  ? AppColors.error
                                  : totalChange < 0
                                      ? AppColors.finance
                                      : null,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${totalChange > 0 ? '+' : ''}$totalChange%',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: totalChange > 0
                                    ? AppColors.error
                                    : AppColors.finance,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(prevLabel,
                                      style: theme.textTheme.labelSmall),
                                  Text(totalPrevious.toCurrency('COP'),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: theme.textTheme.bodySmall?.color,
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (items.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text('No hay datos para comparar',
                              style: theme.textTheme.bodyMedium),
                        ),
                      )
                    else
                      ...items.map((item) {
                        final cat = catMap[item.categoryId] as dynamic;
                        final name = cat?.name as String? ??
                            'Cat #${item.categoryId}';
                        final pct = item.changePercent;
                        final pctText = pct != null
                            ? '${pct > 0 ? '+' : ''}${(pct * 100).round()}%'
                            : 'Nuevo';
                        final pctColor = pct != null
                            ? (pct > 0 ? AppColors.error : AppColors.finance)
                            : AppColors.info;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(name,
                                      style: theme.textTheme.titleSmall),
                                ),
                                Expanded(
                                  child: Text(
                                    item.currentCents.toCurrency('COP'),
                                    style: theme.textTheme.bodySmall,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  item.increased
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 16,
                                  color: pctColor,
                                ),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    pctText,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      color: pctColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.previousCents.toCurrency('COP'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2: Trends (3-6 months)
// ---------------------------------------------------------------------------

class _TrendTab extends StatefulWidget {
  const _TrendTab({required this.repo});
  final FinanceRepository repo;

  @override
  State<_TrendTab> createState() => _TrendTabState();
}

class _TrendTabState extends State<_TrendTab> {
  int _months = 3;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);

    return FutureBuilder<List<dynamic>>(
      future: _loadTrendData(now),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final trendData =
            snap.data![0] as Map<({int month, int year}), Map<String, int>>;
        final categories = snap.data![1] as List<CategoryModel>;
        final catMap = {for (final c in categories) c.id: c};

        final trends = computeTrend(trendData);

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppBreakpoints.isMediumOrLarger(constraints)
                      ? AppBreakpoints.maxContentWidth
                      : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Range selector
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('3 meses'),
                          selected: _months == 3,
                          selectedColor: AppColors.finance.withAlpha(40),
                          onSelected: (_) => setState(() => _months = 3),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('6 meses'),
                          selected: _months == 6,
                          selectedColor: AppColors.finance.withAlpha(40),
                          onSelected: (_) => setState(() => _months = 6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (trends.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text('No hay suficientes datos',
                              style: theme.textTheme.bodyMedium),
                        ),
                      )
                    else
                      ...trends.map((trend) {
                        final cat = catMap[trend.categoryId];
                        final name = cat?.name as String? ??
                            'Cat #${trend.categoryId}';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(name,
                                        style: theme.textTheme.titleSmall),
                                    Text(
                                      'Prom: ${trend.averageCents.round().toCurrency('COP')}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(color: AppColors.finance),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Mini bar chart per month
                                _MiniTrendBars(
                                  totals: trend.monthlyTotals,
                                  maxCents: trend.monthlyTotals
                                      .map((t) => t.totalCents)
                                      .fold(0,
                                          (a, b) => a > b ? a : b),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> _loadTrendData(DateTime now) async {
    final data = <({int month, int year}), Map<String, int>>{};
    for (var i = _months - 1; i >= 0; i--) {
      var m = now.month - i;
      var y = now.year;
      while (m < 1) {
        m += 12;
        y--;
      }
      data[(month: m, year: y)] =
          await widget.repo.getMonthlySpentByCategory(m, y);
    }
    final cats = await widget.repo.watchCategories().first;
    return [data, cats];
  }
}

class _MiniTrendBars extends StatelessWidget {
  const _MiniTrendBars({required this.totals, required this.maxCents});

  final List<MonthlyTotal> totals;
  final int maxCents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: totals.map((t) {
        final fraction = maxCents > 0 ? t.totalCents / maxCents : 0.0;
        final label = DateFormat('MMM', 'es').format(DateTime(t.year, t.month));

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Text(
                  t.totalCents.toCurrency('COP'),
                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  height: 40 * fraction,
                  constraints: const BoxConstraints(minHeight: 2),
                  decoration: BoxDecoration(
                    color: AppColors.finance.withAlpha(180),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                Text(label,
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 3: End-of-month projection
// ---------------------------------------------------------------------------

class _ProjectionTab extends StatelessWidget {
  const _ProjectionTab({required this.repo});
  final FinanceRepository repo;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        repo.watchBudgets(now.month, now.year).first,
        repo.watchCategories().first,
        ...[], // spacer
      ]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final budgets = snap.data![0] as List;
        final categories = snap.data![1] as List;
        final catMap = {for (final c in categories) (c as dynamic).id as String: c};

        return FutureBuilder<List<int>>(
          future: Future.wait(
            budgets.map((b) =>
                repo.spentInBudget((b as dynamic).categoryId as String, now.month, now.year)),
          ),
          builder: (context, spentSnap) {
            final spentList =
                spentSnap.data ?? List.filled(budgets.length, 0);
            final theme = Theme.of(context);

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppBreakpoints.isMediumOrLarger(constraints)
                          ? AppBreakpoints.maxContentWidth
                          : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Daily summary banner
                        _DailySummaryBanner(
                          totalSpent: spentList.fold(0, (a, b) => a + b),
                          totalBudget: budgets.fold<int>(
                              0, (s, b) => s + ((b as dynamic).amountCents as int)),
                          daysPassed: daysPassed,
                          daysRemaining: daysInMonth - daysPassed,
                        ),
                        const SizedBox(height: 16),

                        if (budgets.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text('No hay presupuestos para proyectar',
                                  style: theme.textTheme.bodyMedium),
                            ),
                          )
                        else
                          ...List.generate(budgets.length, (i) {
                            final b = budgets[i] as dynamic;
                            final spent = i < spentList.length ? spentList[i] : 0;
                            final cat = catMap[b.categoryId as int];
                            final name = cat?.name as String? ?? 'Cat #${b.categoryId}';

                            final proj = computeProjection(
                              spentCents: spent,
                              budgetCents: b.amountCents as int,
                              daysPassed: daysPassed,
                              daysInMonth: daysInMonth,
                            );

                            return _ProjectionCard(
                              categoryName: name,
                              budgetCents: b.amountCents as int,
                              spentCents: spent,
                              projection: proj,
                            );
                          }),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Daily summary banner
// ---------------------------------------------------------------------------

class _DailySummaryBanner extends StatelessWidget {
  const _DailySummaryBanner({
    required this.totalSpent,
    required this.totalBudget,
    required this.daysPassed,
    required this.daysRemaining,
  });

  final int totalSpent;
  final int totalBudget;
  final int daysPassed;
  final int daysRemaining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = computeDailySummary(
      totalSpentCents: totalSpent,
      totalBudgetCents: totalBudget,
      daysPassed: daysPassed,
      daysRemaining: daysRemaining,
    );

    final color = summary.utilizationPercent >= 85
        ? AppColors.error
        : summary.utilizationPercent >= 60
            ? AppColors.warning
            : AppColors.finance;

    return Card(
      color: color.withAlpha(15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.today, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen del dia $daysPassed',
                    style: theme.textTheme.titleSmall?.copyWith(color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gastado: ${totalSpent.toCurrency('COP')} '
                    '(${summary.utilizationPercent.round()}%)',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (daysRemaining > 0)
                    Text(
                      'Te quedan ${summary.remainingCents.toCurrency('COP')} '
                      'para $daysRemaining dias '
                      '(${summary.availablePerDay.toCurrency('COP')}/dia)',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Projection card per category
// ---------------------------------------------------------------------------

class _ProjectionCard extends StatelessWidget {
  const _ProjectionCard({
    required this.categoryName,
    required this.budgetCents,
    required this.spentCents,
    required this.projection,
  });

  final String categoryName;
  final int budgetCents;
  final int spentCents;
  final ProjectionResult projection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = projection.willExceed ? AppColors.error : AppColors.finance;
    final utilization =
        budgetCents > 0 ? (spentCents / budgetCents).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(categoryName, style: theme.textTheme.titleSmall),
                if (projection.willExceed)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      projection.exceedDay != null
                          ? 'Excede el dia ${projection.exceedDay}'
                          : 'Excedera',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.error),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: utilization,
                minHeight: 6,
                backgroundColor: theme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gastado: ${spentCents.toCurrency('COP')}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Proyeccion: ${projection.projectedCents.toCurrency('COP')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Text(
              'Presupuesto: ${budgetCents.toCurrency('COP')} · '
              'Ritmo: ${projection.dailyRate.toCurrency('COP')}/dia',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
