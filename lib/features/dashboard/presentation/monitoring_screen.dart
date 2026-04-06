import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';

// ---------------------------------------------------------------------------
// Pantalla: Panel de Monitoreo — metricas en tiempo real de todos los modulos
// ---------------------------------------------------------------------------

/// Muestra metricas clave de cada modulo (gym, finanzas, nutricion, habitos,
/// sueno, bienestar mental, metas) en un solo scroll.
///
/// Accesibilidad: A11Y-MON-01 — cada seccion tiene encabezado semantico y
/// cada dato tiene etiqueta descriptiva.
class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen> {
  // Datos calculados
  _GymMetrics? _gym;
  _FinanceMetrics? _finance;
  _NutritionMetrics? _nutrition;
  _HabitsMetrics? _habits;
  _SleepMetrics? _sleep;
  _MentalMetrics? _mental;
  _GoalsMetrics? _goals;

  // Ultima valoracion por modulo (dias desde el ultimo snapshot)
  int? _gymValuationDays;
  int? _financeValuationDays;
  int? _nutritionValuationDays;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        _fetchGym(now),
        _fetchFinance(now),
        _fetchNutrition(now),
        _fetchHabits(now),
        _fetchSleep(now),
        _fetchMental(now),
        _fetchGoals(),
        _fetchValuationDays(now),
      ]);
      if (mounted) {
        setState(() {
          _gym = results[0] as _GymMetrics;
          _finance = results[1] as _FinanceMetrics;
          _nutrition = results[2] as _NutritionMetrics;
          _habits = results[3] as _HabitsMetrics;
          _sleep = results[4] as _SleepMetrics;
          _mental = results[5] as _MentalMetrics;
          _goals = results[6] as _GoalsMetrics;
          final valuationDays = results[7] as _ValuationDays;
          _gymValuationDays = valuationDays.gym;
          _financeValuationDays = valuationDays.finance;
          _nutritionValuationDays = valuationDays.nutrition;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _error = e.toString(); });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Data fetchers
  // ---------------------------------------------------------------------------

  Future<_GymMetrics> _fetchGym(DateTime now) async {
    final dao = ref.read(gymDaoProvider);
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 7));
    final workouts = await dao.watchWorkouts(limit: 50).first;
    final weekWorkouts = workouts.where((w) =>
        w.finishedAt != null && w.finishedAt!.isAfter(weekStart)).toList();

    double totalVolume = 0;
    for (final w in weekWorkouts) {
      final sets = await dao.watchWorkoutSets(w.id).first;
      for (final s in sets) {
        if (!s.isWarmup && s.weightKg != null) {
          totalVolume += s.weightKg! * s.reps;
        }
      }
    }

    final lastWorkout = workouts.isNotEmpty ? workouts.first : null;
    final daysSince = lastWorkout?.finishedAt != null
        ? now.difference(lastWorkout!.finishedAt!).inDays
        : null;

    return _GymMetrics(
      workoutsThisWeek: weekWorkouts.length,
      weeklyGoal: 4,
      totalVolumeKg: totalVolume,
      daysSinceLastWorkout: daysSince,
    );
  }

  Future<_FinanceMetrics> _fetchFinance(DateTime now) async {
    final dao = ref.read(financeDaoProvider);
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final income = await dao.sumByType('income', monthStart, monthEnd);
    final expense = await dao.sumByType('expense', monthStart, monthEnd);
    final todayExpense = await dao.sumByType(
        'expense', todayStart, todayEnd.subtract(const Duration(seconds: 1)));

    final budgets = await dao.watchBudgets(now.month, now.year).first;
    int totalBudgetCents = 0;
    int totalSpentCents = 0;
    for (final b in budgets) {
      totalBudgetCents += b.amountCents;
      totalSpentCents += await dao.spentInBudget(
          b.categoryId, now.month, now.year);
    }
    final budgetUtilization = totalBudgetCents > 0
        ? (totalSpentCents / totalBudgetCents * 100).clamp(0, 100).toDouble()
        : 0.0;

    return _FinanceMetrics(
      monthBalanceCents: income - expense,
      budgetUtilizationPct: budgetUtilization,
      todayExpenseCents: todayExpense,
    );
  }

  Future<_NutritionMetrics> _fetchNutrition(DateTime now) async {
    final dao = ref.read(nutritionDaoProvider);
    final today = DateTime(now.year, now.month, now.day);
    final goal = await dao.getActiveGoal(today);
    final meals = await dao.watchMealLogs(today).first;

    double totalCal = 0;
    double totalProtein = 0;
    for (final meal in meals) {
      final items = await dao.watchMealLogItems(meal.id).first;
      for (final item in items) {
        final food = await dao.getFoodItemById(item.foodItemId);
        if (food != null) {
          final factor = item.quantityG / 100;
          totalCal += food.caloriesPer100g * factor;
          totalProtein += food.proteinPer100g * factor;
        }
      }
    }

    final waterLogs = await dao.watchWaterLogs(today).first;
    final totalWaterMl = waterLogs.fold<int>(
        0, (sum, w) => sum + w.amountMl);

    return _NutritionMetrics(
      caloriesKcal: totalCal.round(),
      goalCaloriesKcal: goal?.caloriesKcal.toInt() ?? 2500,
      proteinG: totalProtein,
      goalProteinG: goal?.proteinG ?? 150,
      waterMl: totalWaterMl,
      goalWaterMl: 2000,
    );
  }

  Future<_HabitsMetrics> _fetchHabits(DateTime now) async {
    final dao = ref.read(habitsDaoProvider);
    final today = DateTime(now.year, now.month, now.day);
    final activeHabits = await dao.watchActiveHabits().first;
    int completed = 0;
    int longestStreakDays = 0;
    String longestStreakName = '';

    for (final habit in activeHabits) {
      final log = await dao.getLogForDate(habit.id, today);
      if (log != null) completed++;

      final streak = await dao.streakCount(habit.id, now);
      if (streak > longestStreakDays) {
        longestStreakDays = streak;
        longestStreakName = habit.name;
      }
    }

    // Month completion rate
    final monthStart = DateTime(now.year, now.month, 1);
    double monthRate = 0;
    if (activeHabits.isNotEmpty) {
      double totalRate = 0;
      for (final habit in activeHabits) {
        totalRate += await dao.completionRate(habit.id, monthStart, now);
      }
      monthRate = (totalRate / activeHabits.length * 100).clamp(0, 100);
    }

    return _HabitsMetrics(
      completedToday: completed,
      totalToday: activeHabits.length,
      longestStreakDays: longestStreakDays,
      longestStreakName: longestStreakName,
      monthCompletionRate: monthRate,
    );
  }

  Future<_SleepMetrics> _fetchSleep(DateTime now) async {
    final dao = ref.read(sleepDaoProvider);
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 7));
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));

    final lastNight = await dao.getSleepLogForDate(yesterday);
    double? lastNightHours;
    int? lastNightScore;
    if (lastNight != null) {
      lastNightHours =
          lastNight.wakeTime.difference(lastNight.bedTime).inMinutes / 60.0;
      lastNightScore = lastNight.sleepScore;
    }

    final weekLogs = await dao.watchSleepLogs(weekStart, now).first;
    double avgHours = 0;
    if (weekLogs.isNotEmpty) {
      double total = 0;
      for (final l in weekLogs) {
        total += l.wakeTime.difference(l.bedTime).inMinutes / 60.0;
      }
      avgHours = total / weekLogs.length;
    }

    // Get today's energy
    int? energyToday;
    final energyLogs = await dao.watchEnergyLogsForDate(
        DateTime(now.year, now.month, now.day)).first;
    if (energyLogs.isNotEmpty) {
      energyToday = energyLogs.last.level;
    }

    return _SleepMetrics(
      lastNightHours: lastNightHours,
      lastNightScore: lastNightScore,
      avgWeekHours: avgHours,
      energyToday: energyToday,
    );
  }

  Future<_MentalMetrics> _fetchMental(DateTime now) async {
    final dao = ref.read(mentalDaoProvider);
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final todayMoods = await dao.getMoodLogs(todayStart, todayEnd);
    int? todayMood;
    if (todayMoods.isNotEmpty) {
      todayMood = todayMoods.last.valence;
    }

    final monthBreathing = await dao.getBreathingSessions(monthStart, now);
    final completedBreathing =
        monthBreathing.where((b) => b.isCompleted).length;

    final todayGratitude = await dao.getMoodLogs(todayStart, todayEnd);
    final hasGratitude = todayGratitude.isNotEmpty &&
        todayGratitude.any((m) => m.journalNote != null &&
            m.journalNote!.isNotEmpty);

    return _MentalMetrics(
      todayMoodValence: todayMood,
      breathingSessionsThisMonth: completedBreathing,
      gratitudeLoggedToday: hasGratitude,
    );
  }

  Future<_GoalsMetrics> _fetchGoals() async {
    final dao = ref.read(goalsDaoProvider);
    final allGoals = await dao.getAllGoals();
    final active = allGoals.where((g) => g.status == 'active').toList();
    final avgProgress = active.isEmpty
        ? 0.0
        : active.fold<double>(0.0, (s, g) => s + g.progress) / active.length;

    // Find nearest deadline
    final now = DateTime.now();
    final withDate = active.where((g) => g.targetDate != null).toList()
      ..sort((a, b) => a.targetDate!.compareTo(b.targetDate!));
    int? daysToNextDeadline;
    if (withDate.isNotEmpty) {
      daysToNextDeadline = withDate.first.targetDate!.difference(now).inDays;
    }

    return _GoalsMetrics(
      activeCount: active.length,
      avgProgress: avgProgress,
      daysToNextDeadline: daysToNextDeadline,
    );
  }

  Future<_ValuationDays> _fetchValuationDays(DateTime now) async {
    final dao = ref.read(dashboardDaoProvider);
    final snapshots = await dao.getAllSnapshots();

    int? lastDays(String moduleKey) {
      // Find snapshots that contain the specified moduleKey in their JSON
      for (final snap in snapshots) {
        try {
          final decoded = snap.metricsJson;
          if (decoded.contains('"moduleKey":"$moduleKey"') ||
              decoded.contains('"moduleKey": "$moduleKey"')) {
            return now.difference(snap.createdAt).inDays;
          }
        } catch (_) {}
      }
      return null;
    }

    return _ValuationDays(
      gym: lastDays('gym'),
      finance: lastDays('finance'),
      nutrition: lastDays('nutrition'),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('monitoring-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.dayScore,
        title: Semantics(
          header: true,
          child: const Text('Monitoreo'),
        ),
        leading: Semantics(
          label: 'Volver',
          button: true,
          child: IconButton(
            key: const ValueKey('monitoring-back-button'),
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver',
          ),
        ),
        actions: [
          Semantics(
            label: 'Actualizar metricas',
            button: true,
            child: IconButton(
              key: const ValueKey('monitoring-refresh-button'),
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadAll,
              tooltip: 'Actualizar',
            ),
          ),
          Semantics(
            label: 'Guardar valoracion',
            button: true,
            child: TextButton.icon(
              key: const ValueKey('monitoring-evolution-button'),
              onPressed: () => GoRouter.of(context).push(AppRoutes.evolution),
              icon: const Icon(Icons.timeline_outlined, size: 18),
              label: const Text('Evolucion'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text('Error cargando datos',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(_error!,
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadAll,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView(
                    key: const ValueKey('monitoring-list'),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      // --- Seccion Valoraciones ---
                      const SizedBox(height: 16),
                      Semantics(
                        header: true,
                        child: Text(
                          'Valoraciones',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _ValuationCard(
                              key: const ValueKey('valuation-card-gym'),
                              icon: Icons.fitness_center,
                              color: AppColors.gym,
                              moduleName: 'Gym',
                              daysSinceLast: _gymValuationDays,
                              onTap: () => GoRouter.of(context)
                                  .push(AppRoutes.gymValuation),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ValuationCard(
                              key: const ValueKey('valuation-card-finance'),
                              icon: Icons.account_balance_wallet_outlined,
                              color: AppColors.finance,
                              moduleName: 'Finanzas',
                              daysSinceLast: _financeValuationDays,
                              onTap: () => GoRouter.of(context)
                                  .push(AppRoutes.financeValuation),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ValuationCard(
                              key: const ValueKey('valuation-card-nutrition'),
                              icon: Icons.restaurant_outlined,
                              color: AppColors.nutrition,
                              moduleName: 'Nutricion',
                              daysSinceLast: _nutritionValuationDays,
                              onTap: () => GoRouter.of(context)
                                  .push(AppRoutes.nutritionValuation),
                            ),
                          ),
                        ],
                      ),
                      // --- Link a DayScore ---
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const ValueKey('monitoring-dayscose-button'),
                        onPressed: () =>
                            GoRouter.of(context).push(AppRoutes.dayScore),
                        icon: const Icon(Icons.stars_outlined, size: 18),
                        label: const Text('Ver DayScore del dia'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.dayScore,
                          side: const BorderSide(color: AppColors.dayScore),
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),

                      if (_gym != null) ...[
                        const SizedBox(height: 12),
                        _MonitoringSection(
                          key: const ValueKey('monitoring-gym'),
                          color: AppColors.gym,
                          icon: Icons.fitness_center,
                          title: 'Gym',
                          rows: [
                            _MetricRow(
                              label: 'Entrenamientos esta semana',
                              value: '${_gym!.workoutsThisWeek}/${_gym!.weeklyGoal}',
                            ),
                            _MetricRow(
                              label: 'Volumen total',
                              value: '${_formatVolume(_gym!.totalVolumeKg)} kg',
                            ),
                            _MetricRow(
                              label: 'Dias sin entrenar',
                              value: _gym!.daysSinceLastWorkout != null
                                  ? '${_gym!.daysSinceLastWorkout}'
                                  : '—',
                            ),
                          ],
                          onTap: () => GoRouter.of(context).go(AppRoutes.gym),
                        ),
                      ],
                      if (_finance != null) ...[
                        const SizedBox(height: 12),
                        _MonitoringSection(
                          key: const ValueKey('monitoring-finance'),
                          color: AppColors.finance,
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Finanzas',
                          rows: [
                            _MetricRow(
                              label: 'Balance del mes',
                              value: _formatCents(_finance!.monthBalanceCents),
                            ),
                            _MetricRow(
                              label: 'Presupuesto usado',
                              value:
                                  '${_finance!.budgetUtilizationPct.toStringAsFixed(0)}%',
                            ),
                            _MetricRow(
                              label: 'Gastos hoy',
                              value: _formatCents(_finance!.todayExpenseCents),
                            ),
                          ],
                          onTap: () =>
                              GoRouter.of(context).go(AppRoutes.finance),
                        ),
                      ],
                      if (_nutrition != null) ...[
                        const SizedBox(height: 12),
                        _MonitoringSection(
                          key: const ValueKey('monitoring-nutrition'),
                          color: AppColors.nutrition,
                          icon: Icons.restaurant_outlined,
                          title: 'Nutricion',
                          rows: [
                            _MetricRow(
                              label: 'Calorias hoy',
                              value:
                                  '${_nutrition!.caloriesKcal}/${_nutrition!.goalCaloriesKcal} kcal',
                            ),
                            _MetricRow(
                              label: 'Proteina',
                              value:
                                  '${_nutrition!.proteinG.toStringAsFixed(0)}g / ${_nutrition!.goalProteinG.toStringAsFixed(0)}g',
                            ),
                            _MetricRow(
                              label: 'Agua',
                              value:
                                  '${_nutrition!.waterMl} ml / ${_nutrition!.goalWaterMl} ml',
                            ),
                          ],
                          onTap: () =>
                              GoRouter.of(context).go(AppRoutes.nutrition),
                        ),
                      ],
                      if (_habits != null) ...[
                        const SizedBox(height: 12),
                        _MonitoringSection(
                          key: const ValueKey('monitoring-habits'),
                          color: AppColors.habits,
                          icon: Icons.check_circle_outline,
                          title: 'Habitos',
                          rows: [
                            _MetricRow(
                              label: 'Completados hoy',
                              value:
                                  '${_habits!.completedToday}/${_habits!.totalToday}',
                            ),
                            _MetricRow(
                              label: 'Racha mas larga',
                              value: _habits!.longestStreakDays > 0
                                  ? '${_habits!.longestStreakName} — ${_habits!.longestStreakDays}d'
                                  : '—',
                            ),
                            _MetricRow(
                              label: 'Tasa del mes',
                              value:
                                  '${_habits!.monthCompletionRate.toStringAsFixed(0)}%',
                            ),
                          ],
                          onTap: () =>
                              GoRouter.of(context).go(AppRoutes.habits),
                        ),
                      ],
                      if (_sleep != null) ...[
                        const SizedBox(height: 12),
                        _MonitoringSection(
                          key: const ValueKey('monitoring-sleep'),
                          color: AppColors.sleep,
                          icon: Icons.bedtime_outlined,
                          title: 'Sueno',
                          rows: [
                            _MetricRow(
                              label: 'Anoche',
                              value: _sleep!.lastNightHours != null
                                  ? '${_sleep!.lastNightHours!.toStringAsFixed(1)}h'
                                      '${_sleep!.lastNightScore != null ? ', Score ${_sleep!.lastNightScore}' : ''}'
                                  : '—',
                            ),
                            _MetricRow(
                              label: 'Promedio semana',
                              value: _sleep!.avgWeekHours > 0
                                  ? '${_sleep!.avgWeekHours.toStringAsFixed(1)}h'
                                  : '—',
                            ),
                            _MetricRow(
                              label: 'Energia hoy',
                              value: _sleep!.energyToday != null
                                  ? '${_sleep!.energyToday}/10'
                                  : '—',
                            ),
                          ],
                          onTap: () =>
                              GoRouter.of(context).push(AppRoutes.sleep),
                        ),
                      ],
                      if (_mental != null) ...[
                        const SizedBox(height: 12),
                        _MonitoringSection(
                          key: const ValueKey('monitoring-mental'),
                          color: AppColors.mental,
                          icon: Icons.psychology_outlined,
                          title: 'Bienestar Mental',
                          rows: [
                            _MetricRow(
                              label: 'Mood hoy',
                              value: _mental!.todayMoodValence != null
                                  ? '${_mental!.todayMoodValence}/5'
                                  : '—',
                            ),
                            _MetricRow(
                              label: 'Sesiones de respiracion',
                              value:
                                  '${_mental!.breathingSessionsThisMonth} este mes',
                            ),
                            _MetricRow(
                              label: 'Gratitud hoy',
                              value:
                                  _mental!.gratitudeLoggedToday ? 'Registrada' : 'Pendiente',
                            ),
                          ],
                          onTap: () =>
                              GoRouter.of(context).push(AppRoutes.mood),
                        ),
                      ],
                      if (_goals != null) ...[
                        const SizedBox(height: 12),
                        _MonitoringSection(
                          key: const ValueKey('monitoring-goals'),
                          color: AppColors.goals,
                          icon: Icons.flag_outlined,
                          title: 'Metas',
                          rows: [
                            _MetricRow(
                              label: 'Metas activas',
                              value: '${_goals!.activeCount}',
                            ),
                            _MetricRow(
                              label: 'Progreso promedio',
                              value:
                                  '${_goals!.avgProgress.toStringAsFixed(0)}%',
                            ),
                            _MetricRow(
                              label: 'Proxima deadline',
                              value: _goals!.daysToNextDeadline != null
                                  ? 'en ${_goals!.daysToNextDeadline} dias'
                                  : '—',
                            ),
                          ],
                          onTap: () =>
                              GoRouter.of(context).go(AppRoutes.goals),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Semantics(
                        label: 'Guardar valoracion del dia',
                        button: true,
                        child: FilledButton.icon(
                          key: const ValueKey('monitoring-save-snapshot-button'),
                          onPressed: () =>
                              GoRouter.of(context).push(AppRoutes.evolution),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.dayScore,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: const Icon(Icons.save_outlined),
                          label: const Text(
                            'Ver Evolucion',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ---------------------------------------------------------------------------
  // Formatters
  // ---------------------------------------------------------------------------

  String _formatVolume(double kg) {
    if (kg >= 1000) {
      return '${(kg / 1000).toStringAsFixed(1)}k';
    }
    return kg.toStringAsFixed(0);
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
// Valuation data models
// ---------------------------------------------------------------------------

class _ValuationDays {
  _ValuationDays({this.gym, this.finance, this.nutrition});
  final int? gym;
  final int? finance;
  final int? nutrition;
}

// ---------------------------------------------------------------------------
// Widget: tarjeta de valoracion de modulo
// ---------------------------------------------------------------------------

class _ValuationCard extends StatelessWidget {
  const _ValuationCard({
    super.key,
    required this.icon,
    required this.color,
    required this.moduleName,
    required this.daysSinceLast,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String moduleName;
  final int? daysSinceLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastLabel = daysSinceLast != null
        ? daysSinceLast == 0
            ? 'Hoy'
            : 'hace $daysSinceLast ${daysSinceLast == 1 ? 'dia' : 'dias'}'
        : 'Sin registro';

    return Semantics(
      label: 'Valoracion $moduleName, $lastLabel. Toca para valorarte.',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withAlpha(60)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 6),
                Text(
                  moduleName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Ultima: $lastLabel',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(140),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Valorarme'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metric data models
// ---------------------------------------------------------------------------

class _GymMetrics {
  _GymMetrics({
    required this.workoutsThisWeek,
    required this.weeklyGoal,
    required this.totalVolumeKg,
    required this.daysSinceLastWorkout,
  });
  final int workoutsThisWeek;
  final int weeklyGoal;
  final double totalVolumeKg;
  final int? daysSinceLastWorkout;
}

class _FinanceMetrics {
  _FinanceMetrics({
    required this.monthBalanceCents,
    required this.budgetUtilizationPct,
    required this.todayExpenseCents,
  });
  final int monthBalanceCents;
  final double budgetUtilizationPct;
  final int todayExpenseCents;
}

class _NutritionMetrics {
  _NutritionMetrics({
    required this.caloriesKcal,
    required this.goalCaloriesKcal,
    required this.proteinG,
    required this.goalProteinG,
    required this.waterMl,
    required this.goalWaterMl,
  });
  final int caloriesKcal;
  final int goalCaloriesKcal;
  final double proteinG;
  final double goalProteinG;
  final int waterMl;
  final int goalWaterMl;
}

class _HabitsMetrics {
  _HabitsMetrics({
    required this.completedToday,
    required this.totalToday,
    required this.longestStreakDays,
    required this.longestStreakName,
    required this.monthCompletionRate,
  });
  final int completedToday;
  final int totalToday;
  final int longestStreakDays;
  final String longestStreakName;
  final double monthCompletionRate;
}

class _SleepMetrics {
  _SleepMetrics({
    required this.lastNightHours,
    required this.lastNightScore,
    required this.avgWeekHours,
    required this.energyToday,
  });
  final double? lastNightHours;
  final int? lastNightScore;
  final double avgWeekHours;
  final int? energyToday;
}

class _MentalMetrics {
  _MentalMetrics({
    required this.todayMoodValence,
    required this.breathingSessionsThisMonth,
    required this.gratitudeLoggedToday,
  });
  final int? todayMoodValence;
  final int breathingSessionsThisMonth;
  final bool gratitudeLoggedToday;
}

class _GoalsMetrics {
  _GoalsMetrics({
    required this.activeCount,
    required this.avgProgress,
    required this.daysToNextDeadline,
  });
  final int activeCount;
  final double avgProgress;
  final int? daysToNextDeadline;
}

// ---------------------------------------------------------------------------
// Widget: seccion de monitoreo
// ---------------------------------------------------------------------------

class _MonitoringSection extends StatelessWidget {
  const _MonitoringSection({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.rows,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final List<_MetricRow> rows;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$title — toca para abrir el modulo',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withAlpha(50)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado
                Row(
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 8),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_outlined,
                      size: 18,
                      color: theme.disabledColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ...rows,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: fila de metrica clave
// ---------------------------------------------------------------------------

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(160),
                ),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
