import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';

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
              child: Row(
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
                    label: score != null
                        ? 'Dia $day: $score puntos'
                        : 'Dia $day sin registro',
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
                      return Semantics(
                        label:
                            '${entry.date.day}/${entry.date.month}: animo $score',
                        child: ListTile(
                          key: ValueKey('mood-list-item-$i'),
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
                          subtitle: tags.isEmpty
                              ? const Text('Sin etiquetas')
                              : Text(tags.join(', ')),
                          trailing: Text(
                            'V:${entry.valence} E:${entry.energy}',
                            style: TextStyle(
                              color: mentalColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
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
// Trends View
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('trends-scroll'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Score chart (bar)
          Card(
            key: const ValueKey('mood-trend-chart'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puntuacion de Animo — Ultima semana',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Average line indicator
                  Row(
                    children: [
                      Container(width: 20, height: 2, color: mentalColor.withAlpha(100)),
                      const SizedBox(width: 4),
                      Text(
                        'Promedio: ${avgScore.round()}',
                        style: TextStyle(fontSize: 11, color: mentalColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 140,
                    child: data.isEmpty
                        ? Center(
                            child: Text(
                              'Sin datos este mes',
                              style: theme.textTheme.bodySmall,
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(data.length, (i) {
                              final entry = data[i];
                              final score = _moodScore(entry);
                              final barHeight = (score / 100.0) * 120;
                              final color = score >= 75
                                  ? AppColors.success
                                  : score >= 50
                                      ? mentalColor
                                      : AppColors.warning;
                              final dayLabel = _dayLabels[
                                  (entry.date.weekday - 1) % 7];

                              return Expanded(
                                child: Semantics(
                                  label: '$dayLabel: animo $score',
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text('$score',
                                          style:
                                              const TextStyle(fontSize: 9)),
                                      const SizedBox(height: 2),
                                      Container(
                                        key: ValueKey('mood-bar-$i'),
                                        height: barHeight,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        decoration: BoxDecoration(
                                          color: color.withAlpha(200),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(dayLabel,
                                          style: theme.textTheme.labelSmall),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Valence & Energy breakdown
          Card(
            key: const ValueKey('valence-energy-card'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valencia vs Energia',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (data.isEmpty)
                    Text('Sin datos', style: theme.textTheme.bodySmall)
                  else
                    ...data.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Semantics(
                          label:
                              'Dia ${entry.date.day}: Valencia ${entry.valence}, Energia ${entry.energy}',
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${entry.date.day}',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 52,
                                          child: Text('Valencia',
                                              style:
                                                  TextStyle(fontSize: 10)),
                                        ),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            child: LinearProgressIndicator(
                                              value: entry.valence / 5.0,
                                              minHeight: 8,
                                              backgroundColor: AppColors
                                                  .mental
                                                  .withAlpha(30),
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                      AppColors.mental),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('${entry.valence}',
                                            style: const TextStyle(
                                                fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 52,
                                          child: Text('Energia',
                                              style:
                                                  TextStyle(fontSize: 10)),
                                        ),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            child: LinearProgressIndicator(
                                              value: entry.energy / 5.0,
                                              minHeight: 8,
                                              backgroundColor: AppColors
                                                  .sleep
                                                  .withAlpha(30),
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                      AppColors.sleep),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text('${entry.energy}',
                                            style: const TextStyle(
                                                fontSize: 10)),
                                      ],
                                    ),
                                  ],
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
          ),

          const SizedBox(height: 12),

          // Top tags
          Card(
            key: const ValueKey('top-tags-card'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Etiquetas frecuentes',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
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
                ],
              ),
            ),
          ),
        ],
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
