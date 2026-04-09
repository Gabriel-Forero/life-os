import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/widgets/chart_card.dart';
import 'package:life_os/core/widgets/stat_card.dart';
import 'package:life_os/features/finance/domain/amount_formatting.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Enums y modelos
// ---------------------------------------------------------------------------

// Real data models
class _PieSlice {
  const _PieSlice({
    required this.label,
    required this.color,
    required this.amountCents,
  });

  final String label;
  final Color color;
  final int amountCents;
}

class _BarDay {
  const _BarDay({
    required this.label,
    required this.incomeCents,
    required this.expenseCents,
  });

  final String label;
  final int incomeCents;
  final int expenseCents;
}

// ---------------------------------------------------------------------------
// Pantalla principal del dashboard de finanzas
// ---------------------------------------------------------------------------

/// Dashboard de finanzas con resumen, grafico de pastel, barras y linea.
///
/// Accesibilidad: A11Y-FIN-03 — todos los graficos tienen Semantics con
/// descripcion textual alternativa del contenido representado.
class FinanceDashboardScreen extends ConsumerStatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  ConsumerState<FinanceDashboardScreen> createState() =>
      _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState
    extends ConsumerState<FinanceDashboardScreen> {
  late int _month;
  late int _year;
  int? _touchedPieIndex;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  void _changeMonth(int delta) {
    setState(() {
      var m = _month + delta;
      var y = _year;
      while (m < 1) { m += 12; y--; }
      while (m > 12) { m -= 12; y++; }
      _month = m;
      _year = y;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'es_CO');
    final dao = ref.watch(financeDaoProvider);
    final from = DateTime(_year, _month, 1);
    final to = DateTime(_year, _month + 1, 0, 23, 59, 59);

    return Scaffold(
      key: const ValueKey('finance-dashboard-screen'),
      body: FutureBuilder<List<int>>(
        future: Future.wait([
          dao.sumByType('income', from, to),
          dao.sumByType('expense', from, to),
        ]),
        builder: (context, snapshot) {
          final incomeCents = snapshot.data?[0] ?? 0;
          final expenseCents = snapshot.data?[1] ?? 0;
          final balanceCents = incomeCents - expenseCents;

          return RefreshIndicator(
            color: AppColors.finance,
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                // --- Selector de mes ---
                _MonthStrip(
                  key: const ValueKey('dashboard-month-strip'),
                  month: _month,
                  year: _year,
                  onMonthChange: _changeMonth,
                ),
                const SizedBox(height: 16),

                // --- Tarjetas de resumen ---
                Semantics(
                  label: 'Resumen financiero: '
                      'Ingresos ${incomeCents.toCurrency('COP')}, '
                      'Gastos ${expenseCents.toCurrency('COP')}, '
                      'Balance ${balanceCents.toCurrency('COP')}',
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          key: const ValueKey('dashboard-income-card'),
                          icon: Icons.arrow_upward_rounded,
                          value: '\$${formatter.format(incomeCents)}',
                          label: 'Ingresos',
                          color: AppColors.finance,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          key: const ValueKey('dashboard-expense-card'),
                          icon: Icons.arrow_downward_rounded,
                          value: '\$${formatter.format(expenseCents)}',
                          label: 'Gastos',
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          key: const ValueKey('dashboard-balance-card'),
                          icon: Icons.account_balance_wallet_outlined,
                          value: '\$${formatter.format(balanceCents)}',
                          label: 'Balance',
                          color: balanceCents >= 0
                              ? AppColors.finance
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // --- Grafico de pastel: gastos reales por categoria ---
                StreamBuilder<List<Transaction>>(
                  stream: dao.watchTransactions(from, to),
                  builder: (context, txSnapshot) {
                    final txList = txSnapshot.data ?? [];
                    final expenses = txList.where((t) => t.type == 'expense').toList();

                    return StreamBuilder<List<Category>>(
                      stream: dao.watchCategories(),
                      builder: (context, catSnapshot) {
                        final categories = catSnapshot.data ?? [];

                        // Group expenses by category
                        final Map<int, int> byCategory = {};
                        for (final tx in expenses) {
                          byCategory[tx.categoryId] =
                              (byCategory[tx.categoryId] ?? 0) + tx.amountCents;
                        }

                        final totalExpenses = byCategory.values
                            .fold<int>(0, (sum, v) => sum + v);

                        final List<_PieSlice> slices = [];
                        final catColors = [
                          AppColors.finance,
                          AppColors.gym,
                          AppColors.nutrition,
                          AppColors.habits,
                          AppColors.sleep,
                          AppColors.mental,
                          AppColors.goals,
                          AppColors.info,
                        ];

                        int colorIdx = 0;
                        for (final entry in byCategory.entries) {
                          final cat = categories.where((c) => c.id == entry.key).firstOrNull;
                          final label = cat?.name ?? 'Cat. ${entry.key}';
                          final color = cat != null
                              ? Color(cat.color)
                              : catColors[colorIdx % catColors.length];
                          colorIdx++;
                          slices.add(_PieSlice(
                            label: label,
                            color: color,
                            amountCents: entry.value,
                          ));
                        }

                        // Sort by amount descending, keep top 5 + Others
                        slices.sort((a, b) => b.amountCents.compareTo(a.amountCents));
                        List<_PieSlice> displaySlices = slices;
                        if (slices.length > 5) {
                          final top5 = slices.take(5).toList();
                          final othersCents = slices
                              .skip(5)
                              .fold<int>(0, (s, e) => s + e.amountCents);
                          top5.add(_PieSlice(
                            label: 'Otros',
                            color: Colors.grey,
                            amountCents: othersCents,
                          ));
                          displaySlices = top5;
                        }

                        return ChartCard(
                          key: const ValueKey('dashboard-pie-chart-card'),
                          title: 'Gastos por categoria',
                          height: 220,
                          testId: 'dashboard-pie-chart',
                          child: displaySlices.isEmpty
                              ? const Center(child: Text('Sin datos suficientes'))
                              : Semantics(
                                  label: 'Grafico de pastel: distribucion de gastos. '
                                      '${displaySlices.map((s) => '${s.label} ${totalExpenses > 0 ? (s.amountCents / totalExpenses * 100).round() : 0}%').join(', ')}',
                                  child: _RealPieChart(
                                    slices: displaySlices,
                                    total: totalExpenses,
                                    touchedIndex: _touchedPieIndex,
                                    onTouch: (index) =>
                                        setState(() => _touchedPieIndex = index),
                                  ),
                                ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // --- Grafico de barras: ingresos vs gastos por dia ---
                StreamBuilder<List<Transaction>>(
                  stream: dao.watchTransactions(from, to),
                  builder: (context, txSnapshot) {
                    final txList = txSnapshot.data ?? [];

                    // Group by day (up to 14 days in range)
                    final Map<String, _BarDay> byDay = {};
                    for (final tx in txList) {
                      final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2,'0')}-${tx.date.day.toString().padLeft(2,'0')}';
                      final label = '${tx.date.day}/${tx.date.month}';
                      final existing = byDay[key];
                      if (existing == null) {
                        byDay[key] = _BarDay(
                          label: label,
                          incomeCents: tx.type == 'income' ? tx.amountCents : 0,
                          expenseCents: tx.type == 'expense' ? tx.amountCents : 0,
                        );
                      } else {
                        byDay[key] = _BarDay(
                          label: existing.label,
                          incomeCents: existing.incomeCents + (tx.type == 'income' ? tx.amountCents : 0),
                          expenseCents: existing.expenseCents + (tx.type == 'expense' ? tx.amountCents : 0),
                        );
                      }
                    }

                    final sortedDays = byDay.entries.toList()
                      ..sort((a, b) => a.key.compareTo(b.key));
                    final days = sortedDays.map((e) => e.value).toList();

                    return ChartCard(
                      key: const ValueKey('dashboard-bar-chart-card'),
                      title: 'Ingresos vs Gastos',
                      height: 200,
                      testId: 'dashboard-bar-chart',
                      child: days.length < 2
                          ? const Center(child: Text('Sin datos suficientes'))
                          : Semantics(
                              label: 'Grafico de barras: ingresos y gastos por dia.',
                              child: _RealBarChart(days: days),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // --- Grafico de linea: saldo acumulado real ---
                StreamBuilder<List<Transaction>>(
                  stream: dao.watchTransactions(from, to),
                  builder: (context, txSnapshot) {
                    final txList = txSnapshot.data ?? [];

                    // Sort ascending by date
                    final sorted = [...txList]..sort((a, b) => a.date.compareTo(b.date));

                    // Build cumulative balance list
                    final List<({DateTime date, double balance})> balancePoints = [];
                    double running = 0;
                    for (final tx in sorted) {
                      running += tx.type == 'income'
                          ? tx.amountCents / 100.0
                          : -(tx.amountCents / 100.0);
                      balancePoints.add((date: tx.date, balance: running));
                    }

                    return ChartCard(
                      key: const ValueKey('dashboard-line-chart-card'),
                      title: 'Saldo acumulado',
                      height: 180,
                      testId: 'dashboard-line-chart',
                      child: balancePoints.length < 2
                          ? const Center(child: Text('Sin datos suficientes'))
                          : Semantics(
                              label: 'Grafico de linea: evolucion del saldo acumulado en el tiempo.',
                              child: _RealLineChart(points: balancePoints),
                            ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: selector de rango de fecha
// ---------------------------------------------------------------------------

class _MonthStrip extends StatelessWidget {
  const _MonthStrip({
    super.key,
    required this.month,
    required this.year,
    required this.onMonthChange,
  });

  final int month;
  final int year;
  final ValueChanged<int> onMonthChange;

  static const _kNames = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final now = DateTime.now();

    // 13 months: 6 before, current, 6 after
    final months = List.generate(13, (i) {
      final offset = i - 6;
      var m = month + offset;
      var y = year;
      while (m < 1) { m += 12; y--; }
      while (m > 12) { m -= 12; y++; }
      return (month: m, year: y, delta: offset);
    });

    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: months.length,
        itemBuilder: (context, index) {
          final item = months[index];
          final isSelected = item.delta == 0;
          final isCurrent =
              item.month == now.month && item.year == now.year;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => onMonthChange(item.delta),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.finance.withAlpha(brightness == Brightness.dark ? 25 : 15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.finance
                        : isCurrent
                            ? AppColors.finance.withAlpha(40)
                            : Colors.transparent,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _kNames[item.month - 1],
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? AppColors.finance
                            : AppColors.textSecondary(brightness),
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (item.year != now.year)
                      Text(
                        '${item.year}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary(brightness).withAlpha(120),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: grafico de pastel real
// ---------------------------------------------------------------------------

class _RealPieChart extends StatelessWidget {
  const _RealPieChart({
    required this.slices,
    required this.total,
    required this.touchedIndex,
    required this.onTouch,
  });

  final List<_PieSlice> slices;
  final int total;
  final int? touchedIndex;
  final ValueChanged<int?> onTouch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (event.isInterestedForInteractions &&
                      response?.touchedSection != null) {
                    onTouch(
                      response!.touchedSection!.touchedSectionIndex,
                    );
                  } else {
                    onTouch(null);
                  }
                },
              ),
              sections: List.generate(slices.length, (i) {
                final slice = slices[i];
                final isTouched = i == touchedIndex;
                final pct = total > 0
                    ? (slice.amountCents / total * 100).round()
                    : 0;
                return PieChartSectionData(
                  color: slice.color,
                  value: slice.amountCents.toDouble(),
                  title: isTouched ? '$pct%' : '',
                  radius: isTouched ? 72 : 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                );
              }),
              sectionsSpace: 2,
              centerSpaceRadius: 36,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: slices
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: s.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            s.label,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: grafico de barras real
// ---------------------------------------------------------------------------

class _RealBarChart extends StatelessWidget {
  const _RealBarChart({required this.days});

  final List<_BarDay> days;

  @override
  Widget build(BuildContext context) {
    // Show at most 14 days to keep labels readable
    final displayDays = days.length > 14 ? days.sublist(days.length - 14) : days;

    final maxVal = displayDays.fold<int>(
      0,
      (m, d) => m > d.expenseCents + d.incomeCents
          ? m
          : d.expenseCents + d.incomeCents,
    );
    final maxY = maxVal > 0 ? (maxVal / 100.0) : 100.0;

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= displayDays.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  displayDays[index].label,
                  style: const TextStyle(fontSize: 9),
                );
              },
              reservedSize: 20,
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0x1A9E9E9E),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          displayDays.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              if (displayDays[i].incomeCents > 0)
                BarChartRodData(
                  toY: displayDays[i].incomeCents / 100.0,
                  color: AppColors.finance,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              BarChartRodData(
                toY: displayDays[i].expenseCents / 100.0,
                color: AppColors.error,
                width: 8,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            ],
            barsSpace: 2,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: grafico de linea real (saldo acumulado)
// ---------------------------------------------------------------------------

class _RealLineChart extends StatelessWidget {
  const _RealLineChart({required this.points});

  final List<({DateTime date, double balance})> points;

  @override
  Widget build(BuildContext context) {
    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.balance);
    }).toList();

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY).abs() * 0.1 + 1;

    return LineChart(
      LineChartData(
        lineTouchData: const LineTouchData(enabled: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0x1A9E9E9E),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (points.length / 4).ceilToDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= points.length) {
                  return const SizedBox.shrink();
                }
                final d = points[idx].date;
                return Text(
                  '${d.day}/${d.month}',
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
        ),
        minY: minY - padding,
        maxY: maxY + padding,
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.finance,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.finance.withAlpha(40),
            ),
          ),
        ],
      ),
    );
  }
}
