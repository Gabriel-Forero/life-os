import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/widgets/chart_card.dart';
import 'package:life_os/core/widgets/stat_card.dart';
import 'package:life_os/features/finance/domain/amount_formatting.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Enums y modelos
// ---------------------------------------------------------------------------

/// Rango de fechas seleccionable para el dashboard.
enum _DateRange { week, month, year }

extension _DateRangeLabel on _DateRange {
  String get label => switch (this) {
        _DateRange.week => 'Semana',
        _DateRange.month => 'Mes',
        _DateRange.year => 'Ano',
      };
}

class _MockPieSlice {
  const _MockPieSlice({
    required this.label,
    required this.color,
    required this.percentage,
  });

  final String label;
  final Color color;
  final double percentage;
}

const _mockPieSlices = [
  _MockPieSlice(label: 'Alimentacion', color: Color(0xFF10B981), percentage: 0.35),
  _MockPieSlice(label: 'Transporte', color: Color(0xFFF59E0B), percentage: 0.20),
  _MockPieSlice(label: 'Entretenimiento', color: Color(0xFF8B5CF6), percentage: 0.15),
  _MockPieSlice(label: 'Salud', color: Color(0xFFEC4899), percentage: 0.10),
  _MockPieSlice(label: 'Otros', color: Color(0xFF6366F1), percentage: 0.20),
];

class _MockBarDay {
  const _MockBarDay({
    required this.label,
    required this.incomeCents,
    required this.expenseCents,
  });

  final String label;
  final int incomeCents;
  final int expenseCents;
}

const _mockBarDays = [
  _MockBarDay(label: 'Lun', incomeCents: 0, expenseCents: 8000000),
  _MockBarDay(label: 'Mar', incomeCents: 300000000, expenseCents: 12000000),
  _MockBarDay(label: 'Mie', incomeCents: 0, expenseCents: 5500000),
  _MockBarDay(label: 'Jue', incomeCents: 0, expenseCents: 18000000),
  _MockBarDay(label: 'Vie', incomeCents: 0, expenseCents: 9000000),
  _MockBarDay(label: 'Sab', incomeCents: 0, expenseCents: 22000000),
  _MockBarDay(label: 'Dom', incomeCents: 0, expenseCents: 11000000),
];

const _mockLinePoints = [0.0, 2.8, 2.6, 2.7, 2.5, 2.6, 2.15];

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
  _DateRange _selectedRange = _DateRange.month;
  int? _touchedPieIndex;

  (DateTime, DateTime) _dateRangeFor(_DateRange range) {
    final now = DateTime.now();
    return switch (range) {
      _DateRange.week => (
          now.subtract(Duration(days: now.weekday - 1)),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        ),
      _DateRange.month => (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        ),
      _DateRange.year => (
          DateTime(now.year, 1, 1),
          DateTime(now.year, 12, 31, 23, 59, 59),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0', 'es_CO');
    final dao = ref.watch(financeDaoProvider);
    final (from, to) = _dateRangeFor(_selectedRange);

    return Scaffold(
      key: const ValueKey('finance-dashboard-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: const Text('Finanzas'),
        ),
        actions: [
          Semantics(
            label: 'Ver notificaciones financieras',
            button: true,
            child: IconButton(
              key: const ValueKey('dashboard-notifications-button'),
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
              tooltip: 'Notificaciones',
            ),
          ),
        ],
      ),
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
                // --- Selector de rango de fecha ---
                Semantics(
                  label: 'Seleccionar rango de fecha',
                  child: _DateRangeSelector(
                    key: const ValueKey('dashboard-date-range-selector'),
                    selected: _selectedRange,
                    onChanged: (range) =>
                        setState(() => _selectedRange = range),
                  ),
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

                // --- Grafico de pastel: gastos por categoria ---
                ChartCard(
                  key: const ValueKey('dashboard-pie-chart-card'),
                  title: 'Gastos por categoria',
                  height: 220,
                  testId: 'dashboard-pie-chart',
                  child: Semantics(
                    label: 'Grafico de pastel: distribucion de gastos. '
                        '${_mockPieSlices.map((s) => '${s.label} ${(s.percentage * 100).round()}%').join(', ')}',
                    child: _PieChartSection(
                      slices: _mockPieSlices,
                      touchedIndex: _touchedPieIndex,
                      onTouch: (index) =>
                          setState(() => _touchedPieIndex = index),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Grafico de barras: ingresos vs gastos diarios ---
                ChartCard(
                  key: const ValueKey('dashboard-bar-chart-card'),
                  title: 'Ingresos vs Gastos',
                  height: 200,
                  testId: 'dashboard-bar-chart',
                  child: Semantics(
                    label: 'Grafico de barras: ingresos y gastos por dia. '
                        '${_mockBarDays.map((d) => '${d.label}: gastos \$${formatter.format(d.expenseCents)}').join(', ')}',
                    child: const _BarChartSection(days: _mockBarDays),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Grafico de linea: saldo acumulado ---
                ChartCard(
                  key: const ValueKey('dashboard-line-chart-card'),
                  title: 'Saldo acumulado',
                  height: 180,
                  testId: 'dashboard-line-chart',
                  child: Semantics(
                    label:
                        'Grafico de linea: evolucion del saldo acumulado en el tiempo.',
                    child: const _LineChartSection(points: _mockLinePoints),
                  ),
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

class _DateRangeSelector extends StatelessWidget {
  const _DateRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final _DateRange selected;
  final ValueChanged<_DateRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_DateRange>(
      segments: _DateRange.values
          .map(
            (r) => ButtonSegment<_DateRange>(
              value: r,
              label: Text(r.label),
            ),
          )
          .toList(),
      selected: {selected},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) onChanged(set.first);
      },
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.finance.withAlpha(30),
        selectedForegroundColor: AppColors.finance,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: grafico de pastel
// ---------------------------------------------------------------------------

class _PieChartSection extends StatelessWidget {
  const _PieChartSection({
    required this.slices,
    required this.touchedIndex,
    required this.onTouch,
  });

  final List<_MockPieSlice> slices;
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
                return PieChartSectionData(
                  color: slice.color,
                  value: slice.percentage,
                  title: isTouched
                      ? '${(slice.percentage * 100).round()}%'
                      : '',
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
// Widget: grafico de barras
// ---------------------------------------------------------------------------

class _BarChartSection extends StatelessWidget {
  const _BarChartSection({required this.days});

  final List<_MockBarDay> days;

  @override
  Widget build(BuildContext context) {
    final maxVal = days.fold<int>(
      0,
      (m, d) => m > d.expenseCents + d.incomeCents
          ? m
          : d.expenseCents + d.incomeCents,
    );
    final maxY = maxVal > 0 ? (maxVal / 1000000.0) : 10.0;

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
                if (index < 0 || index >= days.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  days[index].label,
                  style: const TextStyle(fontSize: 10),
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
          days.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              if (days[i].incomeCents > 0)
                BarChartRodData(
                  toY: days[i].incomeCents / 1000000.0,
                  color: AppColors.finance,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              BarChartRodData(
                toY: days[i].expenseCents / 1000000.0,
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
// Widget: grafico de linea
// ---------------------------------------------------------------------------

class _LineChartSection extends StatelessWidget {
  const _LineChartSection({required this.points});

  final List<double> points;

  @override
  Widget build(BuildContext context) {
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
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              points.length,
              (i) => FlSpot(i.toDouble(), points[i]),
            ),
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

