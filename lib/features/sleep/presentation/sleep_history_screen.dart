import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/core/widgets/chart_card.dart';

const _dayLabels = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do'];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SleepHistoryScreen extends ConsumerStatefulWidget {
  const SleepHistoryScreen({super.key});

  @override
  ConsumerState<SleepHistoryScreen> createState() => _SleepHistoryScreenState();
}

class _SleepHistoryScreenState extends ConsumerState<SleepHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dao = ref.watch(sleepDaoProvider);
    final theme = Theme.of(context);
    final sleepColor = AppColors.sleep;

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1 + 6));
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Historial de Sueno'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: sleepColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_outlined),
            tooltip: 'Energia',
            onPressed: () => context.push(AppRoutes.energy),
          ),
          IconButton(
            icon: const Icon(Icons.query_stats),
            tooltip: 'Ritmo Circadiano',
            onPressed: () => context.push(AppRoutes.circadian),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            tooltip: 'Importar datos de salud',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Importar datos de salud'),
                content: const Text(
                  'La integracion con plataformas de salud estara disponible proximamente.',
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: sleepColor,
          labelColor: sleepColor,
          tabs: const [
            Tab(key: ValueKey('weekly-tab'), text: 'Semanal'),
            Tab(key: ValueKey('monthly-tab'), text: 'Mensual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StreamBuilder<List<SleepLog>>(
            stream: dao.watchSleepLogs(weekStart, now),
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              final avgScore = data.isEmpty
                  ? 0.0
                  : data.map((e) => e.sleepScore).reduce((a, b) => a + b) /
                      data.length;
              final avgHours = data.isEmpty
                  ? 0.0
                  : data
                          .map((e) =>
                              e.wakeTime.difference(e.bedTime).inMinutes /
                              60.0)
                          .reduce((a, b) => a + b) /
                      data.length;
              return _WeeklyView(
                data: data,
                avgScore: avgScore,
                avgHours: avgHours,
                sleepColor: sleepColor,
                theme: theme,
              );
            },
          ),
          StreamBuilder<List<SleepLog>>(
            stream: dao.watchSleepLogs(monthStart, monthEnd),
            builder: (context, snapshot) {
              final data = snapshot.data ?? [];
              return _MonthlyView(
                data: data,
                monthStart: monthStart,
                sleepColor: sleepColor,
                theme: theme,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly View
// ---------------------------------------------------------------------------

class _WeeklyView extends StatelessWidget {
  const _WeeklyView({
    required this.data,
    required this.avgScore,
    required this.avgHours,
    required this.sleepColor,
    required this.theme,
  });

  final List<SleepLog> data;
  final double avgScore;
  final double avgHours;
  final Color sleepColor;
  final ThemeData theme;

  Widget _buildLineChart({
    required List<SleepLog> sorted,
    required double Function(SleepLog) getValue,
    required Color color,
    double? minY,
    double? maxY,
  }) {
    if (sorted.length < 2) {
      return const Center(child: Text('Sin datos suficientes'));
    }
    final spots = sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), getValue(e.value));
    }).toList();

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
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
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  final d = sorted[idx].date;
                  return Text(
                    '${d.day}/${d.month}',
                    style: const TextStyle(fontSize: 9),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withAlpha(40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort ascending for charts
    final sorted = [...data]..sort((a, b) => a.date.compareTo(b.date));

    return SingleChildScrollView(
      key: const ValueKey('weekly-scroll'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Stats
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Promedio de puntuacion: ${avgScore.round()}',
                  child: _StatCard(
                    key: const ValueKey('avg-score-card'),
                    label: 'Puntuacion Prom.',
                    value: avgScore.round().toString(),
                    icon: Icons.star_outline,
                    color: sleepColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  label: 'Promedio de horas: ${avgHours.toStringAsFixed(1)}',
                  child: _StatCard(
                    key: const ValueKey('avg-hours-card'),
                    label: 'Horas Prom.',
                    value: '${avgHours.toStringAsFixed(1)}h',
                    icon: Icons.access_time,
                    color: sleepColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sleep Score LineChart
          ChartCard(
            key: const ValueKey('score-chart-card'),
            title: 'Puntuacion de Sueno',
            child: _buildLineChart(
              sorted: sorted,
              getValue: (s) => s.sleepScore.toDouble(),
              color: sleepColor,
              minY: 0,
              maxY: 100,
            ),
          ),
          const SizedBox(height: 12),

          // Sleep Duration LineChart
          ChartCard(
            key: const ValueKey('hours-chart-card'),
            title: 'Horas de Sueno',
            child: _buildLineChart(
              sorted: sorted,
              getValue: (s) =>
                  s.wakeTime.difference(s.bedTime).inMinutes / 60.0,
              color: sleepColor.withAlpha(180),
            ),
          ),
          const SizedBox(height: 12),

          // Bed time consistency — hour of day when going to bed
          ChartCard(
            key: const ValueKey('bedtime-chart-card'),
            title: 'Hora de dormir',
            child: _buildLineChart(
              sorted: sorted,
              getValue: (s) =>
                  s.bedTime.hour + s.bedTime.minute / 60.0,
              color: AppColors.info,
            ),
          ),


          const SizedBox(height: 12),

          // Log list
          Card(
            key: const ValueKey('sleep-log-list-card'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: data.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No hay registros esta semana',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final entry = data[i];
                      final hours = entry.wakeTime
                              .difference(entry.bedTime)
                              .inMinutes /
                          60.0;
                      return Semantics(
                        label:
                            'Sueno del ${entry.date.day}/${entry.date.month}: ${entry.sleepScore} puntos',
                        child: ListTile(
                          key: ValueKey('sleep-log-item-$i'),
                          leading: CircleAvatar(
                            backgroundColor: sleepColor.withAlpha(30),
                            child: Text(
                              '${entry.sleepScore}',
                              style: TextStyle(
                                  color: sleepColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                              '${entry.date.day}/${entry.date.month}/${entry.date.year}'),
                          subtitle: Text(
                              '${hours.toStringAsFixed(1)}h • Calidad ${entry.qualityRating}/5'),
                          trailing: Icon(
                            entry.sleepScore >= 80
                                ? Icons.check_circle
                                : entry.sleepScore >= 60
                                    ? Icons.info_outline
                                    : Icons.warning_amber,
                            color: entry.sleepScore >= 80
                                ? AppColors.success
                                : entry.sleepScore >= 60
                                    ? AppColors.warning
                                    : AppColors.error,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Monthly View (calendar grid with real data)
// ---------------------------------------------------------------------------

class _MonthlyView extends StatelessWidget {
  const _MonthlyView({
    required this.data,
    required this.monthStart,
    required this.sleepColor,
    required this.theme,
  });

  final List<SleepLog> data;
  final DateTime monthStart;
  final Color sleepColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    // Build a map of day → sleepScore for quick lookup
    final scoreByDay = <int, int>{};
    for (final entry in data) {
      scoreByDay[entry.date.day] = entry.sleepScore;
    }

    final daysInMonth = DateUtils.getDaysInMonth(monthStart.year, monthStart.month);
    final monthLabel =
        '${_monthName(monthStart.month)} ${monthStart.year}';

    return SingleChildScrollView(
      key: const ValueKey('monthly-scroll'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            monthLabel,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            key: const ValueKey('monthly-calendar-card'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: daysInMonth,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final score = scoreByDay[day];
                  final hasData = score != null;
                  final color = hasData
                      ? (score >= 80
                          ? AppColors.success
                          : score >= 60
                              ? AppColors.warning
                              : AppColors.error)
                      : Colors.transparent;

                  return Semantics(
                    label: hasData
                        ? 'Dia $day: puntuacion $score'
                        : 'Dia $day sin datos',
                    child: Container(
                      key: ValueKey('month-day-$day'),
                      decoration: BoxDecoration(
                        color: hasData ? color.withAlpha(40) : null,
                        border: Border.all(
                          color: hasData ? color : Colors.grey.withAlpha(40),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 11,
                            color: hasData ? color : Colors.grey,
                            fontWeight:
                                hasData ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: AppColors.success, label: 'Bueno (80+)'),
              const SizedBox(width: 12),
              _LegendItem(color: AppColors.warning, label: 'Regular (60-79)'),
              const SizedBox(width: 12),
              _LegendItem(color: AppColors.error, label: 'Bajo (<60)'),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int month) => const [
        '',
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ][month];
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _StatCard
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  const _StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
