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

int _moodScore(MoodLog log) {
  final v = (log.valence - 1) / 4.0 * 50.0;
  final e = (log.energy - 1) / 4.0 * 50.0;
  return (v + e).round().clamp(0, 100);
}

List<String> _parseTags(String raw) =>
    raw.isEmpty ? [] : raw.split(',').map((t) => t.trim()).toList();

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class MentalHistoryScreen extends ConsumerStatefulWidget {
  const MentalHistoryScreen({super.key});

  @override
  ConsumerState<MentalHistoryScreen> createState() => _MentalHistoryScreenState();
}

class _MentalHistoryScreenState extends ConsumerState<MentalHistoryScreen>
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
    final dao = ref.watch(mentalDaoProvider);
    final theme = Theme.of(context);
    final mentalColor = AppColors.mental;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Historial Mental'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: mentalColor,
        actions: [
          Semantics(
            button: true,
            label: 'Ver patrones de IA',
            child: IconButton(
              key: const ValueKey('ai-insights-button'),
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Patrones de IA',
              onPressed: () => context.push(AppRoutes.mentalInsights),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: mentalColor,
          labelColor: mentalColor,
          tabs: const [
            Tab(key: ValueKey('mood-calendar-tab'), text: 'Calendario'),
            Tab(key: ValueKey('mood-trends-tab'), text: 'Tendencias'),
          ],
        ),
      ),
      body: StreamBuilder<List<MoodLog>>(
        stream: dao.watchMoodLogs(monthStart, monthEnd),
        builder: (context, snapshot) {
          final data = snapshot.data ?? [];
          final avgScore = data.isEmpty
              ? 0.0
              : data.map(_moodScore).reduce((a, b) => a + b) / data.length;

          return TabBarView(
            controller: _tabController,
            children: [
              _CalendarView(
                data: data,
                monthStart: monthStart,
                mentalColor: mentalColor,
                theme: theme,
              ),
              _TrendsView(
                data: data,
                avgScore: avgScore,
                mentalColor: mentalColor,
                theme: theme,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Calendar View
// ---------------------------------------------------------------------------

class _CalendarView extends StatelessWidget {
  const _CalendarView({
    required this.data,
    required this.monthStart,
    required this.mentalColor,
    required this.theme,
  });

  final List<MoodLog> data;
  final DateTime monthStart;
  final Color mentalColor;
  final ThemeData theme;

  Color _scoreColor(int score) {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return mentalColor;
    if (score >= 25) return AppColors.warning;
    return AppColors.error;
  }

  void _showDayDetail(BuildContext context, MoodLog entry) {
    final score = _moodScore(entry);
    final tags = _parseTags(entry.tags);
    final color = _scoreColor(score);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${entry.date.day}/${entry.date.month}/${entry.date.year}',
          style: TextStyle(color: color),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withAlpha(40),
                    child: Text(
                      '$score',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Valencia: ${entry.valence}/5'),
                      Text('Energia: ${entry.energy}/5'),
                    ],
                  ),
                ],
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: tags
                      .map((t) => Chip(
                            label: Text(t, style: const TextStyle(fontSize: 11)),
                            backgroundColor: mentalColor.withAlpha(30),
                          ))
                      .toList(),
                ),
              ],
              if (entry.journalNote != null && entry.journalNote!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Nota:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(entry.journalNote!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('calendar-scroll'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary
          Card(
            key: const ValueKey('mood-calendar-summary'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: mentalColor.withAlpha(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Semantics(
                        label: 'Dias registrados: ${data.length}',
                        child: _MiniStat(
                          key: const ValueKey('days-logged-stat'),
                          value: '${data.length}',
                          label: 'Dias\nregistrados',
                          color: mentalColor,
                        ),
                      ),
                      Semantics(
                        label: 'Promedio de animo',
                        child: _MiniStat(
                          key: const ValueKey('avg-mood-stat'),
                          value: data.isEmpty
                              ? '--'
                              : (data.map(_moodScore).reduce((a, b) => a + b) /
                                      data.length)
                                  .round()
                                  .toString(),
                          label: 'Promedio\nde animo',
                          color: mentalColor,
                        ),
                      ),
                      Semantics(
                        label: 'Mejor dia',
                        child: _MiniStat(
                          key: const ValueKey('best-day-stat'),
                          value: data.isEmpty
                              ? '--'
                              : data
                                  .map(_moodScore)
                                  .reduce((a, b) => a > b ? a : b)
                                  .toString(),
                          label: 'Mejor\ndia',
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  if (data.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Builder(builder: (ctx) {
                      final goodDays = data.where((e) => _moodScore(e) >= 50).length;
                      final goodPct = (goodDays / data.length * 100).round();
                      final avg = (data.map(_moodScore).reduce((a, b) => a + b) /
                              data.length)
                          .round();
                      return Semantics(
                        label: 'Este mes $goodPct por ciento dias buenos, humor promedio $avg de 100',
                        child: Text(
                          'Este mes: $goodPct% dias buenos, humor promedio $avg/100',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: mentalColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Calendar grid
          Text(
            '${_monthName(monthStart.month)} ${monthStart.year}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Day headers
          Row(
            children: _dayLabels.map((d) {
              return Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),

          Card(
            key: const ValueKey('mood-calendar-grid'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: DateUtils.getDaysInMonth(
                    monthStart.year, monthStart.month),
                itemBuilder: (context, index) {
                  final day = index + 1;
                  final entry =
                      data.where((e) => e.date.day == day).firstOrNull;
                  final score = entry != null ? _moodScore(entry) : null;
                  final color = score != null ? _scoreColor(score) : null;

                  return Semantics(
                    button: entry != null,
                    label: score != null
                        ? 'Dia $day: $score puntos'
                        : 'Dia $day sin registro',
                    child: GestureDetector(
                      onTap: entry != null
                          ? () => _showDayDetail(context, entry)
                          : null,
                      child: Container(
                        key: ValueKey('calendar-day-$day'),
                        decoration: BoxDecoration(
                          color: color?.withAlpha(40),
                          border: Border.all(
                            color: color ?? Colors.grey.withAlpha(40),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 11,
                              color: color ?? Colors.grey,
                              fontWeight: entry != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
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

          // Recent logs list
          Text(
            'Registros recientes',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            key: const ValueKey('mood-log-list'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: data.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No hay registros este mes',
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
                      final score = _moodScore(entry);
                      final tags = _parseTags(entry.tags);
                      final hasNote = entry.journalNote != null &&
                          entry.journalNote!.isNotEmpty;
                      return Semantics(
                        label:
                            '${entry.date.day}/${entry.date.month}: animo $score',
                        child: Padding(
                          key: ValueKey('mood-list-item-$i'),
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _scoreColor(score).withAlpha(40),
                              child: Text(
                                '$score',
                                style: TextStyle(
                                  color: _scoreColor(score),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                tags.isEmpty
                                    ? const Text('Sin etiquetas',
                                        style: TextStyle(fontSize: 12))
                                    : Text(tags.join(', '),
                                        style: const TextStyle(fontSize: 12)),
                                if (hasNote) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.journalNote!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurface
                                          .withAlpha(160),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                            isThreeLine: hasNote,
                            trailing: Text(
                              'V:${entry.valence} E:${entry.energy}',
                              style: TextStyle(
                                color: mentalColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // Gratitude history (entries tagged "gratitud")
          Builder(builder: (ctx) {
            final gratitudeEntries = data
                .where((e) => _parseTags(e.tags).contains('gratitud'))
                .toList();
            if (gratitudeEntries.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Entradas de Gratitud',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Card(
                  key: const ValueKey('gratitude-log-list'),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: gratitudeEntries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final entry = gratitudeEntries[i];
                      return ListTile(
                        key: ValueKey('gratitude-item-$i'),
                        leading: Icon(Icons.favorite,
                            color: mentalColor, size: 20),
                        title: Text(
                          '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: entry.journalNote != null &&
                                entry.journalNote!.isNotEmpty
                            ? Text(
                                entry.journalNote!,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trends View — fl_chart LineCharts with real data
// ---------------------------------------------------------------------------

class _TrendsView extends StatelessWidget {
  const _TrendsView({
    required this.data,
    required this.avgScore,
    required this.mentalColor,
    required this.theme,
  });

  final List<MoodLog> data;
  final double avgScore;
  final Color mentalColor;
  final ThemeData theme;

  Widget _buildLineChart({
    required List<MoodLog> sorted,
    required double Function(MoodLog) getValue,
    required Color color,
    double? minY,
    double? maxY,
  }) {
    if (sorted.length < 2) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Sin datos suficientes'),
        ),
      );
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
                interval: (sorted.length / 5).ceilToDouble(),
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

  Map<String, int> _topTags() {
    final counts = <String, int>{};
    for (final entry in data) {
      for (final tag in _parseTags(entry.tags)) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final sorted = Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    return Map.fromEntries(sorted.entries.take(5));
  }

  @override
  Widget build(BuildContext context) {
    // Sort ascending for charts
    final sorted = [...data]..sort((a, b) => a.date.compareTo(b.date));

    return SingleChildScrollView(
      key: const ValueKey('trends-scroll'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mood Score trend (valence*50/4 + energy*50/4)
          ChartCard(
            key: const ValueKey('mood-trend-chart'),
            title: 'Puntuacion de Animo',
            child: _buildLineChart(
              sorted: sorted,
              getValue: (m) => _moodScore(m).toDouble(),
              color: mentalColor,
              minY: 0,
              maxY: 100,
            ),
          ),

          const SizedBox(height: 12),

          // Valence trend
          ChartCard(
            key: const ValueKey('valence-trend-chart'),
            title: 'Valencia (1-5)',
            child: _buildLineChart(
              sorted: sorted,
              getValue: (m) => m.valence.toDouble(),
              color: mentalColor,
              minY: 1,
              maxY: 5,
            ),
          ),

          const SizedBox(height: 12),

          // Energy trend
          ChartCard(
            key: const ValueKey('energy-trend-chart'),
            title: 'Energia (1-5)',
            child: _buildLineChart(
              sorted: sorted,
              getValue: (m) => m.energy.toDouble(),
              color: AppColors.sleep,
              minY: 1,
              maxY: 5,
            ),
          ),

          const SizedBox(height: 12),

          // Top tags (chips, kept as-is)
          ChartCard(
            key: const ValueKey('top-tags-card'),
            title: 'Etiquetas frecuentes',
            child: _topTags().isEmpty
                ? const Center(child: Text('Sin etiquetas registradas'))
                : Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _topTags().entries.map((e) {
                      return Semantics(
                        label: '${e.key}: ${e.value} veces',
                        child: Chip(
                          key: ValueKey('top-tag-${e.key}'),
                          label: Text('${e.key} (${e.value})'),
                          backgroundColor: mentalColor.withAlpha(30),
                          labelStyle: TextStyle(color: mentalColor, fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MiniStat
// ---------------------------------------------------------------------------

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
