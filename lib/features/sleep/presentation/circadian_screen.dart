import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';

// ---------------------------------------------------------------------------
// Circadian Rhythm Screen
// ---------------------------------------------------------------------------

class CircadianScreen extends ConsumerWidget {
  const CircadianScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(sleepDaoProvider);
    final theme = Theme.of(context);
    final sleepColor = AppColors.sleep;

    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 30));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ritmo Circadiano'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: sleepColor,
      ),
      body: StreamBuilder<List<SleepLog>>(
        stream: dao.watchSleepLogs(from, now),
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          return _CircadianBody(data: data, sleepColor: sleepColor, theme: theme);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body — separated so it can receive data synchronously
// ---------------------------------------------------------------------------

class _CircadianBody extends StatelessWidget {
  const _CircadianBody({
    required this.data,
    required this.sleepColor,
    required this.theme,
  });

  final List<SleepLog> data;
  final Color sleepColor;
  final ThemeData theme;

  // Convert a DateTime to a fractional hour value on a 24-h scale.
  // Hours before noon are mapped above 24 so the axis reads naturally:
  // e.g. 07:00 → 31.0 (24 + 7), 22:00 → 22.0.
  double _toYValue(DateTime dt) {
    final h = dt.hour + dt.minute / 60.0;
    // Wake times (morning) are shifted to >24 so they appear above bed times
    return h < 14 ? h + 24 : h;
  }

  String _yLabel(double value) {
    final h = value.round() % 24;
    return '${h.toString().padLeft(2, '0')}:00';
  }

  // Standard deviation helper
  double _stdDev(List<double> values) {
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    return math.sqrt(variance);
  }

  @override
  Widget build(BuildContext context) {
    // Sort ascending by date for chart x-axis
    final sorted = [...data]..sort((a, b) => a.date.compareTo(b.date));

    final bedSpots = <FlSpot>[];
    final wakeSpots = <FlSpot>[];

    for (var i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      bedSpots.add(FlSpot(i.toDouble(), _toYValue(entry.bedTime)));
      wakeSpots.add(FlSpot(i.toDouble(), _toYValue(entry.wakeTime)));
    }

    // Consistency analysis
    final bedValues = sorted.map((e) => _toYValue(e.bedTime)).toList();
    final wakeValues = sorted.map((e) => _toYValue(e.wakeTime)).toList();
    final bedStd = _stdDev(bedValues);
    final wakeStd = _stdDev(wakeValues);
    final avgStd = (bedStd + wakeStd) / 2;

    final String consistencyLabel;
    final Color consistencyColor;
    if (avgStd < 0.5) {
      consistencyLabel = 'Muy consistente';
      consistencyColor = AppColors.success;
    } else if (avgStd < 1.0) {
      consistencyLabel = 'Bastante consistente';
      consistencyColor = AppColors.success;
    } else if (avgStd < 1.5) {
      consistencyLabel = 'Moderadamente irregular';
      consistencyColor = AppColors.warning;
    } else {
      consistencyLabel = 'Irregular';
      consistencyColor = AppColors.error;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Consistency card
          Card(
            key: const ValueKey('consistency-card'),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: consistencyColor.withAlpha(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.bedtime_outlined, color: consistencyColor, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Tu horario es $consistencyLabel',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: consistencyColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Variacion media: ${avgStd.toStringAsFixed(1)} h',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Chart card
          Card(
            key: const ValueKey('circadian-chart-card'),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ultimos 30 dias',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  // Legend
                  Row(
                    children: [
                      _LegendDot(color: AppColors.sleep, label: 'Hora de dormir'),
                      const SizedBox(width: 16),
                      _LegendDot(
                          color: AppColors.gym, label: 'Hora de despertar'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: data.isEmpty
                        ? Center(
                            child: Text(
                              'Sin datos en los ultimos 30 dias',
                              style: theme.textTheme.bodySmall,
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              minY: 18,
                              maxY: 33,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.withAlpha(40),
                                  strokeWidth: 1,
                                ),
                                horizontalInterval: 2,
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 2,
                                    reservedSize: 42,
                                    getTitlesWidget: (value, meta) => Text(
                                      _yLabel(value),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: math.max(
                                        1, (sorted.length / 5).floorToDouble()),
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
                                topTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                // Bed time line
                                LineChartBarData(
                                  spots: bedSpots,
                                  isCurved: true,
                                  color: AppColors.sleep,
                                  barWidth: 2.5,
                                  dotData: FlDotData(
                                    getDotPainter: (spot, pct, bar, idx) =>
                                        FlDotCirclePainter(
                                      radius: 3,
                                      color: AppColors.sleep,
                                      strokeWidth: 0,
                                      strokeColor: Colors.transparent,
                                    ),
                                  ),
                                  belowBarData: BarAreaData(show: false),
                                ),
                                // Wake time line
                                LineChartBarData(
                                  spots: wakeSpots,
                                  isCurved: true,
                                  color: AppColors.gym,
                                  barWidth: 2.5,
                                  dotData: FlDotData(
                                    getDotPainter: (spot, pct, bar, idx) =>
                                        FlDotCirclePainter(
                                      radius: 3,
                                      color: AppColors.gym,
                                      strokeWidth: 0,
                                      strokeColor: Colors.transparent,
                                    ),
                                  ),
                                  belowBarData: BarAreaData(show: false),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Stats cards
          if (data.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    key: const ValueKey('bed-std-card'),
                    label: 'Var. hora dormir',
                    value: '±${bedStd.toStringAsFixed(1)}h',
                    icon: Icons.bedtime_outlined,
                    color: AppColors.sleep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    key: const ValueKey('wake-std-card'),
                    label: 'Var. hora despertar',
                    value: '±${wakeStd.toStringAsFixed(1)}h',
                    icon: Icons.wb_sunny_outlined,
                    color: AppColors.gym,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consejo',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      avgStd < 1.0
                          ? 'Excelente consistencia. Mantener un horario regular favorece el descanso profundo.'
                          : 'Intenta acostarte y despertarte a la misma hora cada dia para mejorar tu ritmo circadiano.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label,
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
