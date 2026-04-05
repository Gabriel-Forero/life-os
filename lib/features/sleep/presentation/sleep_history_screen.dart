import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';

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
                    child: data.isEmpty
                        ? Center(
                            child: Text(
                              'Sin datos esta semana',
                              style: theme.textTheme.bodySmall,
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(data.length, (i) {
                              final entry = data[i];
                              final barHeight =
                                  (entry.sleepScore / 100.0) * 120;
                              final dayLabel =
                                  _dayLabels[(entry.date.weekday - 1) % 7];
                              return Expanded(
                                child: Semantics(
                                  label: '$dayLabel: ${entry.sleepScore} puntos',
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
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        decoration: BoxDecoration(
                                          color: sleepColor.withAlpha(200),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dayLabel,
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
                  if (data.isEmpty)
                    Text('Sin datos', style: theme.textTheme.bodySmall)
                  else
                    ...data.map((entry) {
                      final hours =
                          entry.wakeTime.difference(entry.bedTime).inMinutes /
                              60.0;
                      final pct = (hours / 10.0).clamp(0.0, 1.0);
                      final dayLabel =
                          _dayLabels[(entry.date.weekday - 1) % 7];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Semantics(
                          label: '$dayLabel: ${hours.toStringAsFixed(1)} horas',
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  dayLabel,
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
                                    valueColor:
                                        AlwaysStoppedAnimation(sleepColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${hours.toStringAsFixed(1)}h',
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
