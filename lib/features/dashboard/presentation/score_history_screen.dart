import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/dashboard/providers/day_score_notifier.dart';

// ---------------------------------------------------------------------------
// Score History Screen
// ---------------------------------------------------------------------------

/// Pantalla de historial de DayScore.
///
/// Muestra:
/// - Linea de tendencia de los ultimos 30 dias.
/// - Mapa de calor con la puntuacion diaria.
///
/// A11Y-DASH-03: todos los graficos tienen Semantics con descripcion textual.
class ScoreHistoryScreen extends StatefulWidget {
  const ScoreHistoryScreen({
    super.key,
    required this.notifier,
  });

  final DayScoreNotifier notifier;

  @override
  State<ScoreHistoryScreen> createState() => _ScoreHistoryScreenState();
}

class _ScoreHistoryScreenState extends State<ScoreHistoryScreen> {
  late DayScoreState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.notifier.state;
    _load();
  }

  Future<void> _load() async {
    await widget.notifier.initialize();
    if (mounted) {
      setState(() => _state = widget.notifier.state);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _state.history;

    return Scaffold(
      key: const ValueKey('score-history-screen'),
      appBar: AppBar(
        key: const ValueKey('score-history-app-bar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: const Text(
            'Historial de DayScore',
            key: ValueKey('score-history-title'),
          ),
        ),
      ),
      body: _state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? Semantics(
                  label: 'Sin historial de puntuaciones disponible',
                  child: const _EmptyHistoryCard(),
                )
              : ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    // --- Estadisticas rapidas ---
                    _HistoryStats(
                      key: const ValueKey('score-history-stats'),
                      scores: history,
                    ),
                    const SizedBox(height: 20),

                    // --- Grafico de linea: tendencia ---
                    Semantics(
                      label: 'Grafico de linea: tendencia de DayScore '
                          'en los ultimos ${history.length} dias. '
                          'Ultimo valor: ${history.first.totalScore}. '
                          'Primero: ${history.last.totalScore}.',
                      child: _TrendCard(
                        key: const ValueKey('score-history-trend-card'),
                        scores: history,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Mapa de calor ---
                    Semantics(
                      label: 'Mapa de calor: puntuacion diaria por dia. '
                          '${_buildHeatmapSemantics(history)}',
                      child: _HeatmapCard(
                        key: const ValueKey('score-history-heatmap-card'),
                        scores: history,
                      ),
                    ),
                  ],
                ),
    );
  }

  String _buildHeatmapSemantics(List<DayScore> scores) {
    final formatter = DateFormat('d MMM', 'es');
    return scores.take(7).map((s) {
      final date = formatter.format(s.date);
      return '$date: ${s.totalScore}';
    }).join(', ');
  }
}

// ---------------------------------------------------------------------------
// Widget: Estadisticas rapidas
// ---------------------------------------------------------------------------

class _HistoryStats extends StatelessWidget {
  const _HistoryStats({super.key, required this.scores});

  final List<DayScore> scores;

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) return const SizedBox.shrink();

    final avg = scores
            .fold<int>(0, (s, d) => s + d.totalScore) ~/
        scores.length;
    final max = scores.map((d) => d.totalScore).reduce((a, b) => a > b ? a : b);
    final min = scores.map((d) => d.totalScore).reduce((a, b) => a < b ? a : b);

    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: 'Promedio: $avg',
            child: _StatChip(
              key: const ValueKey('history-stat-avg'),
              label: 'Promedio',
              value: '$avg',
              color: AppColors.dayScore,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            label: 'Maximo: $max',
            child: _StatChip(
              key: const ValueKey('history-stat-max'),
              label: 'Maximo',
              value: '$max',
              color: AppColors.success,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            label: 'Minimo: $min',
            child: _StatChip(
              key: const ValueKey('history-stat-min'),
              label: 'Minimo',
              value: '$min',
              color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Tarjeta de linea de tendencia
// ---------------------------------------------------------------------------

class _TrendCard extends StatelessWidget {
  const _TrendCard({super.key, required this.scores});

  final List<DayScore> scores;

  @override
  Widget build(BuildContext context) {
    // Sort ascending for chart (oldest → newest)
    final sorted = [...scores]..sort((a, b) => a.date.compareTo(b.date));
    final spots = sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.totalScore.toDouble());
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tendencia (${scores.length} dias)',
              key: const ValueKey('trend-card-title'),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (sorted.length - 1).toDouble(),
                  minY: 0,
                  maxY: 100,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final idx = s.x.toInt();
                        final label = idx < sorted.length
                            ? DateFormat('d MMM', 'es').format(sorted[idx].date)
                            : '';
                        return LineTooltipItem(
                          '$label\n${s.y.toInt()}',
                          const TextStyle(fontSize: 11),
                        );
                      }).toList(),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0x1A9E9E9E),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 25,
                        reservedSize: 32,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (sorted.length / 5).ceilToDouble(),
                        reservedSize: 22,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= sorted.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            DateFormat('d/M').format(sorted[idx].date),
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
                      color: AppColors.dayScore,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, pct, bar, idx) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: AppColors.dayScore,
                          strokeWidth: 0,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.dayScore.withAlpha(40),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Mapa de calor
// ---------------------------------------------------------------------------

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({super.key, required this.scores});

  final List<DayScore> scores;

  @override
  Widget build(BuildContext context) {
    // Build a map: normalized-date → score
    final scoreMap = <String, int>{};
    for (final s in scores) {
      final key =
          '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}-${s.date.day.toString().padLeft(2, '0')}';
      scoreMap[key] = s.totalScore;
    }

    // Show last 5 weeks × 7 days = 35 cells
    final today = DateTime.now();
    final cells = List.generate(35, (i) {
      final d = today.subtract(Duration(days: 34 - i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return _HeatCell(date: d, score: scoreMap[key]);
    });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mapa de calor (35 dias)',
              key: const ValueKey('heatmap-card-title'),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            // Day-of-week labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                  .map((d) => Text(d,
                      style: Theme.of(context).textTheme.labelSmall))
                  .toList(),
            ),
            const SizedBox(height: 6),
            GridView.builder(
              key: const ValueKey('heatmap-grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: cells.length,
              itemBuilder: (ctx, i) {
                final cell = cells[i];
                final dateStr = DateFormat('d MMM', 'es').format(cell.date);
                final scoreStr = cell.score != null
                    ? 'Puntuacion: ${cell.score}'
                    : 'Sin dato';
                return Semantics(
                  label: '$dateStr, $scoreStr',
                  child: _HeatmapCell(
                    key: ValueKey('heatmap-cell-$i'),
                    cell: cell,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            // Legend
            const _HeatmapLegend(key: ValueKey('heatmap-legend')),
          ],
        ),
      ),
    );
  }
}

class _HeatCell {
  const _HeatCell({required this.date, this.score});

  final DateTime date;
  final int? score;
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({super.key, required this.cell});

  final _HeatCell cell;

  Color _cellColor(int? score) {
    if (score == null) {
      return AppColors.dayScore.withAlpha(15);
    }
    if (score >= 80) return AppColors.dayScore.withAlpha(230);
    if (score >= 60) return AppColors.dayScore.withAlpha(160);
    if (score >= 40) return AppColors.dayScore.withAlpha(100);
    if (score >= 20) return AppColors.dayScore.withAlpha(60);
    return AppColors.dayScore.withAlpha(25);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cellColor(cell.score),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Leyenda del mapa de calor: de menor a mayor puntuacion',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Menos', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 6),
          ...List.generate(
            5,
            (i) => Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: AppColors.dayScore.withAlpha([15, 40, 80, 150, 230][i]),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text('Mas', style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Sin historial
// ---------------------------------------------------------------------------

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timeline_rounded, size: 56),
            const SizedBox(height: 16),
            Text(
              'Sin historial todavia',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu historial de DayScore aparecera aqui '
              'despues del primer dia completo.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
