import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';

// ---------------------------------------------------------------------------
// Weekly Summary Screen — Feature 3
// ---------------------------------------------------------------------------

/// Generates and displays a personalized AI weekly summary of all LifeOS modules.
class WeeklySummaryScreen extends ConsumerStatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  ConsumerState<WeeklySummaryScreen> createState() =>
      _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends ConsumerState<WeeklySummaryScreen> {
  bool _isGenerating = false;
  String? _summary;
  String? _error;
  DateTime? _generatedAt;
  _WeeklyData? _weeklyData;

  @override
  void initState() {
    super.initState();
    _loadOrGenerate();
  }

  Future<void> _loadOrGenerate() async {
    final cached = ref.read(weeklySummaryProvider);
    if (cached.summary != null && cached.isCurrentWeek) {
      setState(() {
        _summary = cached.summary;
        _generatedAt = cached.generatedAt;
        _weeklyData = cached.weeklyData;
      });
      return;
    }
    await _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _isGenerating = true;
      _error = null;
      _summary = null;
    });

    try {
      final data = await _gatherWeeklyData();
      setState(() => _weeklyData = data);

      final notifier = ref.read(aiNotifierProvider);
      final config = await notifier.dao.getDefaultConfiguration();

      if (config == null) {
        setState(() {
          _isGenerating = false;
          _error =
              'No hay proveedor de IA configurado. Ve a Configuracion > IA.';
        });
        return;
      }

      final contextPrompt = _buildSummaryContext(data);
      const systemPrompt =
          'Eres el asistente de bienestar personal de LifeOS. '
          'Genera resumenes semanales motivadores y concretos en espanol.';

      const userPrompt =
          'Genera un resumen semanal personalizado de mi progreso en LifeOS. '
          'Incluye logros, areas de mejora, y 2-3 sugerencias concretas. '
          'Tono motivacional pero realista. En espanol, max 300 palabras.';

      final provider = notifier.providerFactory(config);
      final buffer = StringBuffer();

      await for (final chunk in provider.sendMessage(
        '$contextPrompt\n\n$userPrompt',
        systemContext: systemPrompt,
      )) {
        buffer.write(chunk);
        if (mounted) {
          setState(() => _summary = buffer.toString());
        }
      }

      final finalSummary = buffer.toString().trim();
      final now = DateTime.now();

      ref.read(weeklySummaryProvider.notifier).save(
            summary: finalSummary,
            generatedAt: now,
            weeklyData: data,
          );

      setState(() {
        _summary = finalSummary;
        _generatedAt = now;
        _isGenerating = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = 'Error al generar el resumen: $e';
        _isGenerating = false;
      });
    }
  }

  Future<_WeeklyData> _gatherWeeklyData() async {
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));
    final prevWeekStart = now.subtract(const Duration(days: 14));

    // Finance
    final financeDao = ref.read(financeDaoProvider);
    final income = await financeDao.sumByType('income', weekStart, now);
    final expenses = await financeDao.sumByType('expense', weekStart, now);

    // Gym workouts
    int gymWorkouts = 0;
    try {
      final workouts = await ref.read(gymDaoProvider).watchWorkouts(limit: 50).first;
      gymWorkouts = workouts.where((w) {
        if (w.finishedAt == null) return false;
        return w.finishedAt!.isAfter(weekStart);
      }).length;
    } on Exception {
      gymWorkouts = 0;
    }

    // Sleep
    double avgSleepScore = 0;
    double avgSleepHours = 0;
    try {
      final sleepLogs = await ref.read(sleepDaoProvider).watchSleepLogs(weekStart, now).first;
      if (sleepLogs.isNotEmpty) {
        final scores = sleepLogs.where((l) => l.sleepScore != null).toList();
        if (scores.isNotEmpty) {
          avgSleepScore =
              scores.map((l) => l.sleepScore).reduce((a, b) => a + b) /
                  scores.length;
        }
        final withTimes = sleepLogs.where((l) =>
            l.bedTime != null).toList();
        if (withTimes.isNotEmpty) {
          final totalMinutes = withTimes
              .map((l) => l.wakeTime.difference(l.bedTime).inMinutes.abs())
              .reduce((a, b) => a + b);
          avgSleepHours = totalMinutes / withTimes.length / 60;
        }
      }
    } on Exception {
      avgSleepScore = 0;
    }

    // Habits
    double habitCompletionRate = 0;
    int bestStreak = 0;
    try {
      final habitsDao = ref.read(habitsDaoProvider);
      final activeHabits = await habitsDao.watchActiveHabits().first;
      if (activeHabits.isNotEmpty) {
        double totalRate = 0;
        for (final h in activeHabits) {
          totalRate += await habitsDao.completionRate(h.id, weekStart, now);
          final streak = await habitsDao.streakCount(h.id, now);
          if (streak > bestStreak) bestStreak = streak;
        }
        habitCompletionRate = totalRate / activeHabits.length;
      }
    } on Exception {
      habitCompletionRate = 0;
    }

    // Mood
    double avgMood = 0;
    try {
      final moodLogs = await ref.read(mentalDaoProvider).getMoodLogs(weekStart, now);
      if (moodLogs.isNotEmpty) {
        avgMood = moodLogs.map((m) {
              final v = (m.valence - 1) / 4.0 * 50.0;
              final e = (m.energy - 1) / 4.0 * 50.0;
              return (v + e).round();
            }).reduce((a, b) => a + b) /
            moodLogs.length;
      }
    } on Exception {
      avgMood = 0;
    }

    // Goals
    int activeGoals = 0;
    double avgGoalProgress = 0;
    try {
      final goals = await ref.read(goalsDaoProvider).getAllGoals();
      final active = goals.where((g) => g.status == 'active').toList();
      activeGoals = active.length;
      if (active.isNotEmpty) {
        avgGoalProgress =
            active.map((g) => g.progress).reduce((a, b) => a + b) /
                active.length;
      }
    } on Exception {
      activeGoals = 0;
    }

    return _WeeklyData(
      incomeCents: income,
      expensesCents: expenses,
      gymWorkouts: gymWorkouts,
      avgSleepScore: avgSleepScore,
      avgSleepHours: avgSleepHours,
      habitCompletionRate: habitCompletionRate,
      bestStreak: bestStreak,
      avgMood: avgMood,
      activeGoals: activeGoals,
      avgGoalProgress: avgGoalProgress,
      weekStart: weekStart,
      weekEnd: now,
    );
  }

  String _buildSummaryContext(_WeeklyData data) {
    final lines = <String>[
      'Datos de la semana (${_formatDate(data.weekStart)} al ${_formatDate(data.weekEnd)}):',
      '',
      'FINANZAS:',
      '- Ingresos: \$${(data.incomeCents / 100).toStringAsFixed(2)}',
      '- Gastos: \$${(data.expensesCents / 100).toStringAsFixed(2)}',
      '- Balance: \$${((data.incomeCents - data.expensesCents) / 100).toStringAsFixed(2)}',
      '',
      'GIMNASIO:',
      '- Entrenamientos completados: ${data.gymWorkouts}',
      '',
      'SUENO:',
      if (data.avgSleepScore > 0)
        '- Puntaje promedio: ${data.avgSleepScore.toStringAsFixed(0)}/100',
      if (data.avgSleepHours > 0)
        '- Horas promedio: ${data.avgSleepHours.toStringAsFixed(1)}h',
      '',
      'HABITOS:',
      '- Tasa de cumplimiento: ${(data.habitCompletionRate * 100).toStringAsFixed(0)}%',
      if (data.bestStreak > 0) '- Mejor racha activa: ${data.bestStreak} dias',
      '',
      'BIENESTAR MENTAL:',
      if (data.avgMood > 0)
        '- Estado de animo promedio: ${data.avgMood.toStringAsFixed(1)}/10',
      '',
      'METAS:',
      '- Objetivos activos: ${data.activeGoals}',
      if (data.avgGoalProgress > 0)
        '- Progreso promedio: ${data.avgGoalProgress.toStringAsFixed(0)}%',
    ];
    return lines.join('\n');
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('weekly_summary_screen'),
      appBar: AppBar(
        title: const Text('Resumen Semanal'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          Semantics(
            label: 'Regenerar resumen semanal',
            button: true,
            child: IconButton(
              key: const ValueKey('regenerate_summary_button'),
              icon: const Icon(Icons.refresh),
              tooltip: 'Regenerar',
              onPressed: _isGenerating ? null : _generate,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Week stats cards
            if (_weeklyData != null) ...[
              _WeekStatsGrid(data: _weeklyData!),
              const SizedBox(height: 20),
            ],

            // AI Summary card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.primary.withAlpha(60),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Tu Resumen Semanal',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_generatedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Generado el ${_formatDateFull(_generatedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                    const Divider(height: 24),

                    if (_isGenerating) ...[
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 12),
                      if (_summary != null && _summary!.isNotEmpty)
                        Text(
                          _summary!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                        ),
                    ] else if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      )
                    else if (_summary != null)
                      Text(
                        _summary!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                      )
                    else
                      Center(
                        child: Text(
                          'Generando tu resumen...',
                          style: TextStyle(color: theme.colorScheme.outline),
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

  String _formatDateFull(DateTime d) {
    final months = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${d.day} ${months[d.month]}. ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Weekly stats grid
// ---------------------------------------------------------------------------

class _WeekStatsGrid extends StatelessWidget {
  const _WeekStatsGrid({required this.data});

  final _WeeklyData data;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem(
        label: 'Gastos',
        value: '\$${(data.expensesCents / 100).toStringAsFixed(0)}',
        icon: Icons.account_balance_wallet,
        color: AppColors.finance,
      ),
      _StatItem(
        label: 'Entrenamientos',
        value: '${data.gymWorkouts}',
        icon: Icons.fitness_center,
        color: AppColors.gym,
      ),
      _StatItem(
        label: 'Habitos %',
        value: '${(data.habitCompletionRate * 100).toStringAsFixed(0)}%',
        icon: Icons.check_circle,
        color: AppColors.habits,
      ),
      _StatItem(
        label: 'Sueno',
        value: data.avgSleepHours > 0
            ? '${data.avgSleepHours.toStringAsFixed(1)}h'
            : '--',
        icon: Icons.bedtime_outlined,
        color: AppColors.sleep,
      ),
      if (data.avgMood > 0)
        _StatItem(
          label: 'Animo',
          value: '${data.avgMood.toStringAsFixed(1)}/10',
          icon: Icons.mood,
          color: AppColors.mental,
        ),
      if (data.activeGoals > 0)
        _StatItem(
          label: 'Metas',
          value: '${data.activeGoals}',
          icon: Icons.flag_outlined,
          color: AppColors.goals,
        ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final theme = Theme.of(context);
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: stat.color.withAlpha(60)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(stat.icon, color: stat.color, size: 20),
                const SizedBox(height: 4),
                Text(
                  stat.value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: stat.color,
                  ),
                ),
                Text(
                  stat.label,
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

// ---------------------------------------------------------------------------
// Weekly data model
// ---------------------------------------------------------------------------

class _WeeklyData {
  const _WeeklyData({
    required this.incomeCents,
    required this.expensesCents,
    required this.gymWorkouts,
    required this.avgSleepScore,
    required this.avgSleepHours,
    required this.habitCompletionRate,
    required this.bestStreak,
    required this.avgMood,
    required this.activeGoals,
    required this.avgGoalProgress,
    required this.weekStart,
    required this.weekEnd,
  });

  final int incomeCents;
  final int expensesCents;
  final int gymWorkouts;
  final double avgSleepScore;
  final double avgSleepHours;
  final double habitCompletionRate;
  final int bestStreak;
  final double avgMood;
  final int activeGoals;
  final double avgGoalProgress;
  final DateTime weekStart;
  final DateTime weekEnd;
}

// ---------------------------------------------------------------------------
// Weekly Summary Cache Provider
// ---------------------------------------------------------------------------

class WeeklySummaryState {
  const WeeklySummaryState({
    this.summary,
    this.generatedAt,
    this.weeklyData,
  });

  final String? summary;
  final DateTime? generatedAt;
  final _WeeklyData? weeklyData;

  bool get isCurrentWeek {
    if (generatedAt == null) return false;
    final now = DateTime.now();
    final diff = now.difference(generatedAt!);
    // Consider current week if generated within last 7 days
    // and on the same calendar week (Monday as start)
    return diff.inDays < 7 &&
        _isoWeekNumber(now) == _isoWeekNumber(generatedAt!);
  }

  static int _isoWeekNumber(DateTime date) {
    final dayOfYear =
        date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}

class WeeklySummaryNotifier extends StateNotifier<WeeklySummaryState> {
  WeeklySummaryNotifier() : super(const WeeklySummaryState());

  void save({
    required String summary,
    required DateTime generatedAt,
    required _WeeklyData weeklyData,
  }) {
    state = WeeklySummaryState(
      summary: summary,
      generatedAt: generatedAt,
      weeklyData: weeklyData,
    );
  }

  void clear() {
    state = const WeeklySummaryState();
  }
}

final weeklySummaryProvider =
    StateNotifierProvider<WeeklySummaryNotifier, WeeklySummaryState>(
  (ref) => WeeklySummaryNotifier(),
);
