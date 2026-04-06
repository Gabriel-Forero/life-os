import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';

// ---------------------------------------------------------------------------
// Pantalla: Evolucion — comparacion de valoraciones guardadas
// ---------------------------------------------------------------------------

/// Muestra la valoracion actual frente a la ultima valoracion guardada.
/// Permite guardar una nueva valoracion y ver el historial completo.
///
/// Accesibilidad: A11Y-EVOL-01 — cada metrica de comparacion tiene
/// etiqueta semantica con el valor actual y el anterior.
class EvolutionScreen extends ConsumerStatefulWidget {
  const EvolutionScreen({super.key});

  @override
  ConsumerState<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends ConsumerState<EvolutionScreen> {
  _LifeSnapshot? _current;
  _LifeSnapshot? _previous;
  bool _isLoadingCurrent = true;
  bool _isSaving = false;
  bool _showHistory = false;
  List<_SnapshotEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoadingCurrent = true);
    try {
      final [current, previous, history] = await Future.wait([
        _buildCurrentSnapshot(),
        _loadPreviousSnapshot(),
        _loadHistory(),
      ]);
      if (mounted) {
        setState(() {
          _current = current as _LifeSnapshot;
          _previous = previous as _LifeSnapshot?;
          _history = history as List<_SnapshotEntry>;
          _isLoadingCurrent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCurrent = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<_LifeSnapshot> _buildCurrentSnapshot() async {
    final now = DateTime.now();
    final gymDao = ref.read(gymDaoProvider);
    final financeDao = ref.read(financeDaoProvider);
    final nutritionDao = ref.read(nutritionDaoProvider);
    final habitsDao = ref.read(habitsDaoProvider);
    final sleepDao = ref.read(sleepDaoProvider);
    final mentalDao = ref.read(mentalDaoProvider);
    final goalsDao = ref.read(goalsDaoProvider);

    // GYM
    final monthStart = DateTime(now.year, now.month, 1);
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 7));
    final workouts = await gymDao.watchWorkouts(limit: 100).first;
    final monthWorkouts = workouts.where((w) =>
        w.finishedAt != null && w.finishedAt!.isAfter(monthStart)).toList();
    double totalVolume = 0;
    for (final w in monthWorkouts) {
      final sets = await gymDao.watchWorkoutSets(w.id).first;
      for (final s in sets) {
        if (!s.isWarmup && s.weightKg != null) {
          totalVolume += s.weightKg! * s.reps;
        }
      }
    }

    // FINANCE
    final finMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final income =
        await financeDao.sumByType('income', monthStart, finMonthEnd);
    final expense =
        await financeDao.sumByType('expense', monthStart, finMonthEnd);
    final budgets =
        await financeDao.watchBudgets(now.month, now.year).first;
    int totalBudgetCents = 0;
    int totalSpentCents = 0;
    for (final b in budgets) {
      totalBudgetCents += b.amountCents;
      totalSpentCents +=
          await financeDao.spentInBudget(b.categoryId, now.month, now.year);
    }
    final budgetUtil = totalBudgetCents > 0
        ? (totalSpentCents / totalBudgetCents * 100).clamp(0, 100).toDouble()
        : 0.0;

    // NUTRITION (avg last 7 days)
    final today = DateTime(now.year, now.month, now.day);
    double totalCal = 0;
    double totalProtein = 0;
    int nutritionDays = 0;
    for (int d = 0; d < 7; d++) {
      final day = today.subtract(Duration(days: d));
      final meals = await nutritionDao.watchMealLogs(day).first;
      if (meals.isEmpty) continue;
      nutritionDays++;
      for (final meal in meals) {
        final items = await nutritionDao.watchMealLogItems(meal.id).first;
        for (final item in items) {
          final food = await nutritionDao.getFoodItemById(item.foodItemId);
          if (food != null) {
            final factor = item.quantityG / 100;
            totalCal += food.caloriesPer100g * factor;
            totalProtein += food.proteinPer100g * factor;
          }
        }
      }
    }
    final avgCal =
        nutritionDays > 0 ? (totalCal / nutritionDays).round() : 0;
    final avgProtein =
        nutritionDays > 0 ? totalProtein / nutritionDays : 0.0;

    // HABITS
    final activeHabits = await habitsDao.watchActiveHabits().first;
    double totalHabitRate = 0;
    int longestStreakDays = 0;
    for (final h in activeHabits) {
      totalHabitRate += await habitsDao.completionRate(h.id, monthStart, now);
      final s = await habitsDao.streakCount(h.id, now);
      if (s > longestStreakDays) longestStreakDays = s;
    }
    final habitRate = activeHabits.isNotEmpty
        ? (totalHabitRate / activeHabits.length * 100).clamp(0.0, 100.0)
        : 0.0;

    // SLEEP (avg last 7 days)
    final sleepLogs = await sleepDao.watchSleepLogs(weekStart, now).first;
    double totalSleepHours = 0;
    int totalSleepScore = 0;
    for (final s in sleepLogs) {
      totalSleepHours +=
          s.wakeTime.difference(s.bedTime).inMinutes / 60.0;
      totalSleepScore += s.sleepScore;
    }
    final sleepCount = sleepLogs.length;
    final avgSleepHours =
        sleepCount > 0 ? totalSleepHours / sleepCount : 0.0;
    final avgSleepScore =
        sleepCount > 0 ? (totalSleepScore / sleepCount).round() : 0;

    // MENTAL (avg last 30 days)
    final mentalFrom = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 30));
    final moodLogs = await mentalDao.getMoodLogs(mentalFrom, now);
    final avgMood = moodLogs.isEmpty
        ? 0.0
        : moodLogs.fold<double>(0, (s, m) => s + m.valence) / moodLogs.length;
    final breathingSessions =
        await mentalDao.getBreathingSessions(monthStart, now);
    final completedBreathing =
        breathingSessions.where((b) => b.isCompleted).length;

    // GOALS
    final allGoals = await goalsDao.getAllGoals();
    final active = allGoals.where((g) => g.status == 'active').toList();
    final avgGoalProgress = active.isEmpty
        ? 0.0
        : active.fold<double>(0, (s, g) => s + g.progress) / active.length;

    // DAY SCORE
    final dashDao = ref.read(dashboardDaoProvider);
    final todayScore = await dashDao.getDayScoreForDate(now);
    final avgDayScore = todayScore?.totalScore ?? 0;

    return _LifeSnapshot(
      timestamp: now,
      // Finance
      monthBalanceCents: income - expense,
      budgetUtilization: budgetUtil,
      // Gym
      workoutsThisMonth: monthWorkouts.length,
      totalVolumeThisMonthKg: totalVolume,
      // Nutrition
      avgCaloriesPerDay: avgCal,
      avgProteinPerDay: avgProtein,
      // Habits
      completionRate: habitRate,
      longestStreak: longestStreakDays,
      // Sleep
      avgSleepHours: avgSleepHours,
      avgSleepScore: avgSleepScore,
      // Mental
      avgMoodScore: avgMood,
      breathingSessionsThisMonth: completedBreathing,
      // Goals
      activeGoals: active.length,
      avgGoalProgress: avgGoalProgress,
      // DayScore
      avgDayScore: avgDayScore,
    );
  }

  Future<_LifeSnapshot?> _loadPreviousSnapshot() async {
    final dao = ref.read(dashboardDaoProvider);
    final snapshots = await dao.getAllSnapshots();
    if (snapshots.isEmpty) return null;
    final latest = snapshots.first;
    return _LifeSnapshot.fromJson(latest.metricsJson, latest.date);
  }

  Future<List<_SnapshotEntry>> _loadHistory() async {
    final dao = ref.read(dashboardDaoProvider);
    final snapshots = await dao.getAllSnapshots();
    return snapshots
        .map((s) => _SnapshotEntry(
              date: s.date,
              totalScore: s.totalScore,
              snapshot: _LifeSnapshot.fromJson(s.metricsJson, s.date),
            ))
        .toList();
  }

  Future<void> _saveSnapshot() async {
    if (_current == null) return;
    setState(() => _isSaving = true);
    try {
      final dao = ref.read(dashboardDaoProvider);
      await dao.insertLifeSnapshot(
        date: DateTime.now(),
        totalScore: _current!.avgDayScore,
        metrics: _current!.toJson(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valoracion guardada!')),
        );
        await _load(); // reload to get updated history and previous
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al guardar: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('evolution-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.dayScore,
        title: Semantics(
          header: true,
          child: const Text('Evolucion'),
        ),
        leading: Semantics(
          label: 'Volver',
          button: true,
          child: IconButton(
            key: const ValueKey('evolution-back-button'),
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver',
          ),
        ),
      ),
      body: _isLoadingCurrent
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const ValueKey('evolution-list'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                const SizedBox(height: 8),

                // --- Encabezado comparacion ---
                if (_previous != null) ...[
                  _ComparisonHeader(
                    currentDate: _current!.timestamp,
                    previousDate: _previous!.timestamp,
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Semantics(
                    label: 'Sin valoracion previa — guarda una para comparar',
                    child: Card(
                      key: const ValueKey('evolution-no-previous-card'),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: AppColors.dayScore.withAlpha(60)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppColors.dayScore),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Guarda tu primera valoracion para poder comparar tu evolucion.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // --- Comparacion de metricas ---
                if (_current != null) ...[
                  _SectionHeader(label: 'Gym'),
                  _ComparisonRow(
                    label: 'Entrenamientos este mes',
                    current: '${_current!.workoutsThisMonth}',
                    previous: _previous != null
                        ? '${_previous!.workoutsThisMonth}'
                        : null,
                    higherIsBetter: true,
                  ),
                  _ComparisonRow(
                    label: 'Volumen total (kg)',
                    current:
                        _current!.totalVolumeThisMonthKg.toStringAsFixed(0),
                    previous: _previous != null
                        ? _previous!.totalVolumeThisMonthKg.toStringAsFixed(0)
                        : null,
                    higherIsBetter: true,
                    currentNum: _current!.totalVolumeThisMonthKg,
                    previousNum: _previous?.totalVolumeThisMonthKg,
                  ),
                  const _SectionDivider(),

                  _SectionHeader(label: 'Finanzas'),
                  _ComparisonRow(
                    label: 'Balance del mes',
                    current: _formatCents(_current!.monthBalanceCents),
                    previous: _previous != null
                        ? _formatCents(_previous!.monthBalanceCents)
                        : null,
                    higherIsBetter: true,
                    currentNum: _current!.monthBalanceCents.toDouble(),
                    previousNum:
                        _previous?.monthBalanceCents.toDouble(),
                  ),
                  _ComparisonRow(
                    label: 'Uso de presupuesto',
                    current:
                        '${_current!.budgetUtilization.toStringAsFixed(0)}%',
                    previous: _previous != null
                        ? '${_previous!.budgetUtilization.toStringAsFixed(0)}%'
                        : null,
                    higherIsBetter: false,
                    currentNum: _current!.budgetUtilization,
                    previousNum: _previous?.budgetUtilization,
                  ),
                  const _SectionDivider(),

                  _SectionHeader(label: 'Nutricion'),
                  _ComparisonRow(
                    label: 'Calorias promedio/dia',
                    current: '${_current!.avgCaloriesPerDay} kcal',
                    previous: _previous != null
                        ? '${_previous!.avgCaloriesPerDay} kcal'
                        : null,
                  ),
                  _ComparisonRow(
                    label: 'Proteina promedio/dia',
                    current:
                        '${_current!.avgProteinPerDay.toStringAsFixed(0)} g',
                    previous: _previous != null
                        ? '${_previous!.avgProteinPerDay.toStringAsFixed(0)} g'
                        : null,
                    higherIsBetter: true,
                    currentNum: _current!.avgProteinPerDay,
                    previousNum: _previous?.avgProteinPerDay,
                  ),
                  const _SectionDivider(),

                  _SectionHeader(label: 'Habitos'),
                  _ComparisonRow(
                    label: 'Tasa de completitud',
                    current:
                        '${_current!.completionRate.toStringAsFixed(0)}%',
                    previous: _previous != null
                        ? '${_previous!.completionRate.toStringAsFixed(0)}%'
                        : null,
                    higherIsBetter: true,
                    currentNum: _current!.completionRate,
                    previousNum: _previous?.completionRate,
                  ),
                  _ComparisonRow(
                    label: 'Racha mas larga',
                    current: '${_current!.longestStreak} dias',
                    previous: _previous != null
                        ? '${_previous!.longestStreak} dias'
                        : null,
                    higherIsBetter: true,
                    currentNum: _current!.longestStreak.toDouble(),
                    previousNum: _previous?.longestStreak.toDouble(),
                  ),
                  const _SectionDivider(),

                  _SectionHeader(label: 'Sueno'),
                  _ComparisonRow(
                    label: 'Horas promedio',
                    current:
                        '${_current!.avgSleepHours.toStringAsFixed(1)} h',
                    previous: _previous != null
                        ? '${_previous!.avgSleepHours.toStringAsFixed(1)} h'
                        : null,
                    higherIsBetter: true,
                    currentNum: _current!.avgSleepHours,
                    previousNum: _previous?.avgSleepHours,
                  ),
                  _ComparisonRow(
                    label: 'Score promedio',
                    current: '${_current!.avgSleepScore}',
                    previous: _previous != null
                        ? '${_previous!.avgSleepScore}'
                        : null,
                    higherIsBetter: true,
                    currentNum: _current!.avgSleepScore.toDouble(),
                    previousNum: _previous?.avgSleepScore.toDouble(),
                  ),
                  const _SectionDivider(),

                  _SectionHeader(label: 'Bienestar Mental'),
                  _ComparisonRow(
                    label: 'Mood promedio',
                    current:
                        '${_current!.avgMoodScore.toStringAsFixed(1)}/5',
                    previous: _previous != null
                        ? '${_previous!.avgMoodScore.toStringAsFixed(1)}/5'
                        : null,
                    higherIsBetter: true,
                    currentNum: _current!.avgMoodScore,
                    previousNum: _previous?.avgMoodScore,
                  ),
                  _ComparisonRow(
                    label: 'Sesiones respiracion',
                    current: '${_current!.breathingSessionsThisMonth}',
                    previous: _previous != null
                        ? '${_previous!.breathingSessionsThisMonth}'
                        : null,
                    higherIsBetter: true,
                    currentNum:
                        _current!.breathingSessionsThisMonth.toDouble(),
                    previousNum:
                        _previous?.breathingSessionsThisMonth.toDouble(),
                  ),
                  const _SectionDivider(),

                  _SectionHeader(label: 'Metas'),
                  _ComparisonRow(
                    label: 'Metas activas',
                    current: '${_current!.activeGoals}',
                    previous: _previous != null
                        ? '${_previous!.activeGoals}'
                        : null,
                  ),
                  _ComparisonRow(
                    label: 'Progreso promedio',
                    current:
                        '${_current!.avgGoalProgress.toStringAsFixed(0)}%',
                    previous: _previous != null
                        ? '${_previous!.avgGoalProgress.toStringAsFixed(0)}%'
                        : null,
                    higherIsBetter: true,
                    currentNum: _current!.avgGoalProgress,
                    previousNum: _previous?.avgGoalProgress,
                  ),
                  const _SectionDivider(),

                  _SectionHeader(label: 'DayScore'),
                  _ComparisonRow(
                    label: 'DayScore',
                    current: '${_current!.avgDayScore}',
                    previous: _previous != null
                        ? '${_previous!.avgDayScore}'
                        : null,
                    higherIsBetter: true,
                    currentNum: _current!.avgDayScore.toDouble(),
                    previousNum: _previous?.avgDayScore.toDouble(),
                  ),
                ],

                const SizedBox(height: 24),

                // --- Botones ---
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Guardar valoracion actual',
                        button: true,
                        child: FilledButton.icon(
                          key: const ValueKey('evolution-save-button'),
                          onPressed: _isSaving ? null : _saveSnapshot,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.dayScore,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isSaving ? 'Guardando...' : 'Guardar Valoracion',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    if (_history.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Semantics(
                        label: 'Ver historial de valoraciones',
                        button: true,
                        child: OutlinedButton.icon(
                          key: const ValueKey('evolution-history-button'),
                          onPressed: () =>
                              setState(() => _showHistory = !_showHistory),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.dayScore,
                            side: const BorderSide(color: AppColors.dayScore),
                            minimumSize: const Size(100, 48),
                          ),
                          icon: Icon(_showHistory
                              ? Icons.expand_less
                              : Icons.history_outlined),
                          label: const Text('Historial'),
                        ),
                      ),
                    ],
                  ],
                ),

                // --- Historial de valoraciones ---
                if (_showHistory && _history.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      'Historial de Valoraciones',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._history.asMap().entries.map((entry) {
                    final snap = entry.value;
                    return _SnapshotHistoryCard(
                      key: ValueKey('snapshot-card-${snap.date.toIso8601String()}'),
                      entry: snap,
                      onTap: () =>
                          _showSnapshotComparison(context, snap.snapshot),
                    );
                  }),
                ],
              ],
            ),
    );
  }

  void _showSnapshotComparison(
      BuildContext context, _LifeSnapshot historical) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => _SnapshotComparisonScreen(
          current: _current!,
          historical: historical,
        ),
      ),
    );
  }

  String _formatCents(int cents) {
    final negative = cents < 0;
    final abs = cents.abs();
    final pesos = abs ~/ 100;
    final formatted = pesos.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '${negative ? '-' : ''}\$$formatted';
  }
}

// ---------------------------------------------------------------------------
// Modelo: LifeSnapshot
// ---------------------------------------------------------------------------

class _LifeSnapshot {
  const _LifeSnapshot({
    required this.timestamp,
    required this.monthBalanceCents,
    required this.budgetUtilization,
    required this.workoutsThisMonth,
    required this.totalVolumeThisMonthKg,
    required this.avgCaloriesPerDay,
    required this.avgProteinPerDay,
    required this.completionRate,
    required this.longestStreak,
    required this.avgSleepHours,
    required this.avgSleepScore,
    required this.avgMoodScore,
    required this.breathingSessionsThisMonth,
    required this.activeGoals,
    required this.avgGoalProgress,
    required this.avgDayScore,
  });

  final DateTime timestamp;
  final int monthBalanceCents;
  final double budgetUtilization;
  final int workoutsThisMonth;
  final double totalVolumeThisMonthKg;
  final int avgCaloriesPerDay;
  final double avgProteinPerDay;
  final double completionRate;
  final int longestStreak;
  final double avgSleepHours;
  final int avgSleepScore;
  final double avgMoodScore;
  final int breathingSessionsThisMonth;
  final int activeGoals;
  final double avgGoalProgress;
  final int avgDayScore;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'monthBalanceCents': monthBalanceCents,
        'budgetUtilization': budgetUtilization,
        'workoutsThisMonth': workoutsThisMonth,
        'totalVolumeThisMonthKg': totalVolumeThisMonthKg,
        'avgCaloriesPerDay': avgCaloriesPerDay,
        'avgProteinPerDay': avgProteinPerDay,
        'completionRate': completionRate,
        'longestStreak': longestStreak,
        'avgSleepHours': avgSleepHours,
        'avgSleepScore': avgSleepScore,
        'avgMoodScore': avgMoodScore,
        'breathingSessionsThisMonth': breathingSessionsThisMonth,
        'activeGoals': activeGoals,
        'avgGoalProgress': avgGoalProgress,
        'avgDayScore': avgDayScore,
      };

  factory _LifeSnapshot.fromJson(String jsonStr, DateTime fallbackDate) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return _LifeSnapshot(
        timestamp: map['timestamp'] != null
            ? DateTime.parse(map['timestamp'] as String)
            : fallbackDate,
        monthBalanceCents: (map['monthBalanceCents'] as num?)?.toInt() ?? 0,
        budgetUtilization:
            (map['budgetUtilization'] as num?)?.toDouble() ?? 0.0,
        workoutsThisMonth:
            (map['workoutsThisMonth'] as num?)?.toInt() ?? 0,
        totalVolumeThisMonthKg:
            (map['totalVolumeThisMonthKg'] as num?)?.toDouble() ?? 0.0,
        avgCaloriesPerDay:
            (map['avgCaloriesPerDay'] as num?)?.toInt() ?? 0,
        avgProteinPerDay:
            (map['avgProteinPerDay'] as num?)?.toDouble() ?? 0.0,
        completionRate: (map['completionRate'] as num?)?.toDouble() ?? 0.0,
        longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
        avgSleepHours: (map['avgSleepHours'] as num?)?.toDouble() ?? 0.0,
        avgSleepScore: (map['avgSleepScore'] as num?)?.toInt() ?? 0,
        avgMoodScore: (map['avgMoodScore'] as num?)?.toDouble() ?? 0.0,
        breathingSessionsThisMonth:
            (map['breathingSessionsThisMonth'] as num?)?.toInt() ?? 0,
        activeGoals: (map['activeGoals'] as num?)?.toInt() ?? 0,
        avgGoalProgress:
            (map['avgGoalProgress'] as num?)?.toDouble() ?? 0.0,
        avgDayScore: (map['avgDayScore'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return _LifeSnapshot(
        timestamp: fallbackDate,
        monthBalanceCents: 0,
        budgetUtilization: 0,
        workoutsThisMonth: 0,
        totalVolumeThisMonthKg: 0,
        avgCaloriesPerDay: 0,
        avgProteinPerDay: 0,
        completionRate: 0,
        longestStreak: 0,
        avgSleepHours: 0,
        avgSleepScore: 0,
        avgMoodScore: 0,
        breathingSessionsThisMonth: 0,
        activeGoals: 0,
        avgGoalProgress: 0,
        avgDayScore: 0,
      );
    }
  }
}

class _SnapshotEntry {
  _SnapshotEntry({
    required this.date,
    required this.totalScore,
    required this.snapshot,
  });
  final DateTime date;
  final int totalScore;
  final _LifeSnapshot snapshot;
}

// ---------------------------------------------------------------------------
// Widgets de apoyo
// ---------------------------------------------------------------------------

class _ComparisonHeader extends StatelessWidget {
  const _ComparisonHeader({
    required this.currentDate,
    required this.previousDate,
  });

  final DateTime currentDate;
  final DateTime previousDate;

  String _fmtDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return 'hace $diff dias';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dayScore.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.dayScore.withAlpha(50)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Valoracion Actual',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.dayScore,
                        fontWeight: FontWeight.w700)),
                Text(_fmtDate(currentDate),
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.compare_arrows_outlined,
              color: AppColors.dayScore, size: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Anterior',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.dayScore,
                        fontWeight: FontWeight.w700)),
                Text(_fmtDate(previousDate),
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 4),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(180),
                letterSpacing: 0.5,
              ),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1);
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.current,
    this.previous,
    this.higherIsBetter,
    this.currentNum,
    this.previousNum,
  });

  final String label;
  final String current;
  final String? previous;
  final bool? higherIsBetter;
  final double? currentNum;
  final double? previousNum;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? trendIcon;
    if (previous != null &&
        higherIsBetter != null &&
        currentNum != null &&
        previousNum != null) {
      final diff = currentNum! - previousNum!;
      if (diff.abs() > 0.01) {
        final improved = (diff > 0) == higherIsBetter!;
        trendIcon = Icon(
          improved ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: improved ? AppColors.success : AppColors.error,
          size: 16,
        );
      }
    }

    final semanticLabel = previous != null
        ? '$label: actual $current, anterior $previous'
        : '$label: $current';

    return Semantics(
      label: semanticLabel,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(160),
                ),
              ),
            ),
            Text(
              current,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (trendIcon != null) ...[
              const SizedBox(width: 4),
              trendIcon,
            ],
            if (previous != null) ...[
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  '(era: $previous)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(100),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SnapshotHistoryCard extends StatelessWidget {
  const _SnapshotHistoryCard({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final _SnapshotEntry entry;
  final VoidCallback onTap;

  String _fmtDate(DateTime d) {
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Valoracion del ${_fmtDate(entry.date)}, score ${entry.totalScore}. Toca para comparar.',
      button: true,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.dayScore.withAlpha(40)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.dayScore.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.timeline_outlined,
                      color: AppColors.dayScore, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fmtDate(entry.date),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'DayScore: ${entry.totalScore}  •  '
                        'Gym: ${entry.snapshot.workoutsThisMonth} entrenam.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_outlined,
                    color: Colors.grey, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pantalla: comparacion con snapshot historico especifico
// ---------------------------------------------------------------------------

class _SnapshotComparisonScreen extends StatelessWidget {
  const _SnapshotComparisonScreen({
    required this.current,
    required this.historical,
  });

  final _LifeSnapshot current;
  final _LifeSnapshot historical;

  String _fmtDate(DateTime d) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${d.day} de ${months[d.month - 1]} de ${d.year}';
  }

  String _formatCents(int cents) {
    final negative = cents < 0;
    final abs = cents.abs();
    final pesos = abs ~/ 100;
    final formatted = pesos.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '${negative ? '-' : ''}\$$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('snapshot-comparison-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.dayScore,
        title: Semantics(
          header: true,
          child: Text(
            'Valoracion del ${_fmtDate(historical.timestamp)}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        leading: Semantics(
          label: 'Volver',
          button: true,
          child: IconButton(
            key: const ValueKey('snapshot-comparison-back'),
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const SizedBox(height: 8),
          _ComparisonHeader(
            currentDate: current.timestamp,
            previousDate: historical.timestamp,
          ),
          const SizedBox(height: 8),

          _SectionHeader(label: 'Gym'),
          _ComparisonRow(
            label: 'Entrenamientos',
            current: '${current.workoutsThisMonth}',
            previous: '${historical.workoutsThisMonth}',
            higherIsBetter: true,
            currentNum: current.workoutsThisMonth.toDouble(),
            previousNum: historical.workoutsThisMonth.toDouble(),
          ),
          _ComparisonRow(
            label: 'Volumen (kg)',
            current: current.totalVolumeThisMonthKg.toStringAsFixed(0),
            previous: historical.totalVolumeThisMonthKg.toStringAsFixed(0),
            higherIsBetter: true,
            currentNum: current.totalVolumeThisMonthKg,
            previousNum: historical.totalVolumeThisMonthKg,
          ),
          const _SectionDivider(),

          _SectionHeader(label: 'Finanzas'),
          _ComparisonRow(
            label: 'Balance mes',
            current: _formatCents(current.monthBalanceCents),
            previous: _formatCents(historical.monthBalanceCents),
            higherIsBetter: true,
            currentNum: current.monthBalanceCents.toDouble(),
            previousNum: historical.monthBalanceCents.toDouble(),
          ),
          _ComparisonRow(
            label: 'Uso presupuesto',
            current: '${current.budgetUtilization.toStringAsFixed(0)}%',
            previous: '${historical.budgetUtilization.toStringAsFixed(0)}%',
            higherIsBetter: false,
            currentNum: current.budgetUtilization,
            previousNum: historical.budgetUtilization,
          ),
          const _SectionDivider(),

          _SectionHeader(label: 'Habitos'),
          _ComparisonRow(
            label: 'Tasa completitud',
            current: '${current.completionRate.toStringAsFixed(0)}%',
            previous: '${historical.completionRate.toStringAsFixed(0)}%',
            higherIsBetter: true,
            currentNum: current.completionRate,
            previousNum: historical.completionRate,
          ),
          _ComparisonRow(
            label: 'Racha mas larga',
            current: '${current.longestStreak} dias',
            previous: '${historical.longestStreak} dias',
            higherIsBetter: true,
            currentNum: current.longestStreak.toDouble(),
            previousNum: historical.longestStreak.toDouble(),
          ),
          const _SectionDivider(),

          _SectionHeader(label: 'Sueno'),
          _ComparisonRow(
            label: 'Horas promedio',
            current: '${current.avgSleepHours.toStringAsFixed(1)} h',
            previous: '${historical.avgSleepHours.toStringAsFixed(1)} h',
            higherIsBetter: true,
            currentNum: current.avgSleepHours,
            previousNum: historical.avgSleepHours,
          ),
          _ComparisonRow(
            label: 'Score promedio',
            current: '${current.avgSleepScore}',
            previous: '${historical.avgSleepScore}',
            higherIsBetter: true,
            currentNum: current.avgSleepScore.toDouble(),
            previousNum: historical.avgSleepScore.toDouble(),
          ),
          const _SectionDivider(),

          _SectionHeader(label: 'Mental'),
          _ComparisonRow(
            label: 'Mood promedio',
            current: '${current.avgMoodScore.toStringAsFixed(1)}/5',
            previous: '${historical.avgMoodScore.toStringAsFixed(1)}/5',
            higherIsBetter: true,
            currentNum: current.avgMoodScore,
            previousNum: historical.avgMoodScore,
          ),
          const _SectionDivider(),

          _SectionHeader(label: 'DayScore'),
          _ComparisonRow(
            label: 'DayScore',
            current: '${current.avgDayScore}',
            previous: '${historical.avgDayScore}',
            higherIsBetter: true,
            currentNum: current.avgDayScore.toDouble(),
            previousNum: historical.avgDayScore.toDouble(),
          ),
        ],
      ),
    );
  }
}
