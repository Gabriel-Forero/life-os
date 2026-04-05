import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';

// ---------------------------------------------------------------------------
// Mock data (kept as fallback until real data stream is wired)
// ---------------------------------------------------------------------------

class _MockSleepEntry {
  const _MockSleepEntry({
    required this.date,
    required this.hoursSlept,
    required this.sleepScore,
    required this.qualityRating,
  });

  final DateTime date;
  final double hoursSlept;
  final int sleepScore;
  final int qualityRating;
}

final _mockWeekData = [
  _MockSleepEntry(date: DateTime(2024, 1, 10), hoursSlept: 6.5, sleepScore: 72, qualityRating: 3),
  _MockSleepEntry(date: DateTime(2024, 1, 11), hoursSlept: 7.0, sleepScore: 78, qualityRating: 4),
  _MockSleepEntry(date: DateTime(2024, 1, 12), hoursSlept: 5.5, sleepScore: 60, qualityRating: 2),
  _MockSleepEntry(date: DateTime(2024, 1, 13), hoursSlept: 8.0, sleepScore: 95, qualityRating: 5),
  _MockSleepEntry(date: DateTime(2024, 1, 14), hoursSlept: 7.5, sleepScore: 88, qualityRating: 4),
  _MockSleepEntry(date: DateTime(2024, 1, 15), hoursSlept: 6.0, sleepScore: 65, qualityRating: 3),
  _MockSleepEntry(date: DateTime(2024, 1, 16), hoursSlept: 7.8, sleepScore: 90, qualityRating: 5),
];

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

  double get _avgScore {
    if (_mockWeekData.isEmpty) return 0;
    return _mockWeekData.map((e) => e.sleepScore).reduce((a, b) => a + b) /
        _mockWeekData.length;
  }

  double get _avgHours {
    if (_mockWeekData.isEmpty) return 0;
    return _mockWeekData.map((e) => e.hoursSlept).reduce((a, b) => a + b) /
        _mockWeekData.length;
  }

  @override
  Widget build(BuildContext context) {
    // Read provider to ensure connection is established even if UI shows mock
    ref.watch(sleepNotifierProvider);

    final theme = Theme.of(context);
    final sleepColor = AppColors.sleep;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Historial de Sueno'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: sleepColor,
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
          _WeeklyView(
            data: _mockWeekData,
            avgScore: _avgScore,
            avgHours: _avgHours,
            sleepColor: sleepColor,
            theme: theme,
          ),
          _MonthlyView(sleepColor: sleepColor, theme: theme),
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

  final List<_MockSleepEntry> data;
  final double avgScore;
  final double avgHours;
  final Color sleepColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
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

          // Bar Chart — Sleep Score
          Card(
            key: const ValueKey('score-chart-card'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puntuacion de Sueno — Ultima semana',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 140,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(data.length, (i) {
                        final entry = data[i];
                        final barHeight = (entry.sleepScore / 100.0) * 120;
                        return Expanded(
                          child: Semantics(
                            label: '${_dayLabels[i]}: ${entry.sleepScore} puntos',
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${entry.sleepScore}',
                                  style: const TextStyle(fontSize: 9),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  key: ValueKey('bar-$i'),
                                  height: barHeight,
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  decoration: BoxDecoration(
                                    color: sleepColor.withAlpha(200),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dayLabels[i],
                                  style: theme.textTheme.labelSmall,
                                ),
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

          // Hours Slept Line (simple bars)
          Card(
            key: const ValueKey('hours-chart-card'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Horas de Sueno — Ultima semana',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...data.map((entry) {
                    final pct = (entry.hoursSlept / 10.0).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Semantics(
                        label: '${_dayLabels[data.indexOf(entry)]}: ${entry.hoursSlept} horas',
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                _dayLabels[data.indexOf(entry)],
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 16,
                                  backgroundColor: sleepColor.withAlpha(30),
                                  valueColor: AlwaysStoppedAnimation(sleepColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.hoursSlept}h',
                              style: theme.textTheme.labelSmall,
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

          // Log list
          Card(
            key: const ValueKey('sleep-log-list-card'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final entry = data[i];
                return Semantics(
                  label: 'Sueno del ${entry.date.day}/${entry.date.month}: ${entry.sleepScore} puntos',
                  child: ListTile(
                    key: ValueKey('sleep-log-item-$i'),
                    leading: CircleAvatar(
                      backgroundColor: sleepColor.withAlpha(30),
                      child: Text(
                        '${entry.sleepScore}',
                        style: TextStyle(color: sleepColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text('${entry.date.day}/${entry.date.month}/${entry.date.year}'),
                    subtitle: Text('${entry.hoursSlept}h • Calidad ${entry.qualityRating}/5'),
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
// Monthly View (simplified calendar grid)
// ---------------------------------------------------------------------------

class _MonthlyView extends StatelessWidget {
  const _MonthlyView({required this.sleepColor, required this.theme});

  final Color sleepColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('monthly-scroll'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enero 2024',
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
                itemCount: 31,
                itemBuilder: (context, index) {
                  final day = index + 1;
                  // Mock: some days have sleep data
                  final hasData = day <= 16 && day % 2 == 0;
                  final score = hasData ? (60 + (day * 3) % 40) : 0;
                  final color = hasData
                      ? (score >= 80
                          ? AppColors.success
                          : score >= 60
                              ? AppColors.warning
                              : AppColors.error)
                      : Colors.transparent;

                  return Semantics(
                    label: hasData ? 'Dia $day: puntuacion $score' : 'Dia $day sin datos',
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
                            fontWeight: hasData ? FontWeight.bold : FontWeight.normal,
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
