import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/providers/providers.dart';

// ---------------------------------------------------------------------------
// SmartAlert model
// ---------------------------------------------------------------------------

class SmartAlert {
  const SmartAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.moduleKey,
    required this.icon,
    required this.color,
    this.actionRoute,
  });

  final String id;
  final String title;
  final String message;
  final String moduleKey;
  final IconData icon;
  final Color color;

  /// Optional route to navigate to when the alert is tapped.
  final String? actionRoute;
}

// ---------------------------------------------------------------------------
// SmartAlertsService
// ---------------------------------------------------------------------------

class SmartAlertsService {
  SmartAlertsService({required this.ref});

  final Ref ref;

  /// Analyzes user data and returns a list of smart alerts.
  /// Should be called at most once per day.
  Future<List<SmartAlert>> generateAlerts() async {
    final alerts = <SmartAlert>[];

    await Future.wait([
      _checkProteinTrend(alerts),
      _checkWorkoutFrequency(alerts),
      _checkBudget(alerts),
      _checkSleepTrend(alerts),
      _checkHabitStreaks(alerts),
    ]);

    return alerts;
  }

  // ---------------------------------------------------------------------------
  // Protein trend check
  // ---------------------------------------------------------------------------

  Future<void> _checkProteinTrend(List<SmartAlert> alerts) async {
    try {
      final nutritionDao = ref.read(nutritionDaoProvider);
      final now = DateTime.now();
      final thisWeekStart = now.subtract(const Duration(days: 7));
      final lastWeekStart = now.subtract(const Duration(days: 14));
      final lastWeekEnd = now.subtract(const Duration(days: 7));

      // Get meal log items for both weeks and compute protein
      // We use a simplified approach: get food items from meal logs
      final thisWeekMeals = await nutritionDao.watchMealLogs(now).first;
      final _ = thisWeekMeals; // suppress unused warning - we use dates below

      // Gather protein from this week vs last week by checking food item logs
      // Since we can't easily aggregate across join without extra DAO methods,
      // we use a simplified metric: count of meal logs as proxy
      final thisWeekStart0 = DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day);
      final lastWeekStart0 = DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day);
      final lastWeekEnd0 = DateTime(lastWeekEnd.year, lastWeekEnd.month, lastWeekEnd.day);

      // Count meal logs (proxy for food activity)
      final thisWeekCount = await _countMealLogs(nutritionDao, thisWeekStart0, now);
      final lastWeekCount = await _countMealLogs(nutritionDao, lastWeekStart0, lastWeekEnd0);

      if (lastWeekCount > 0 && thisWeekCount < lastWeekCount * 0.8) {
        alerts.add(const SmartAlert(
          id: 'protein_trend',
          title: 'Actividad nutricional baja',
          message: 'Registraste menos comidas esta semana que la anterior. '
              'Manten un seguimiento constante para alcanzar tus metas.',
          moduleKey: 'nutrition',
          icon: Icons.restaurant,
          color: Color(0xFFF97316),
          actionRoute: '/nutrition',
        ));
      }
    } on Exception {
      // Silently ignore — alerts are best-effort
    }
  }

  Future<int> _countMealLogs(dynamic dao, DateTime from, DateTime to) async {
    try {
      // Use meal logs for each day in range
      int count = 0;
      var day = from;
      while (day.isBefore(to)) {
        final logs = await dao.watchMealLogs(day).first as List;
        count += logs.length;
        day = day.add(const Duration(days: 1));
      }
      return count;
    } on Exception {
      return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // Workout frequency check
  // ---------------------------------------------------------------------------

  Future<void> _checkWorkoutFrequency(List<SmartAlert> alerts) async {
    try {
      final gymDao = ref.read(gymDaoProvider);
      final now = DateTime.now();

      // Get workouts in last 14 days
      final workouts = await gymDao.watchWorkouts(limit: 20).first;
      final recent = workouts.where((w) {
        if (w.finishedAt == null) return false;
        return now.difference(w.finishedAt!).inDays <= 14;
      }).toList();

      final last7 = recent.where((w) =>
          now.difference(w.finishedAt!).inDays <= 7).length;
      final prev7 = recent.where((w) {
        final days = now.difference(w.finishedAt!).inDays;
        return days > 7 && days <= 14;
      }).length;

      // No workout in 7+ days but user was active before
      if (last7 == 0 && prev7 > 0) {
        alerts.add(const SmartAlert(
          id: 'workout_inactive',
          title: 'Sin entrenamientos esta semana',
          message: 'Llevas mas de 7 dias sin registrar un entrenamiento. '
              'Retoma tu rutina hoy!',
          moduleKey: 'gym',
          icon: Icons.fitness_center,
          color: Color(0xFFF59E0B),
          actionRoute: '/gym',
        ));
      }
    } on Exception {
      // Silently ignore
    }
  }

  // ---------------------------------------------------------------------------
  // Budget check
  // ---------------------------------------------------------------------------

  Future<void> _checkBudget(List<SmartAlert> alerts) async {
    try {
      final financeDao = ref.read(financeDaoProvider);
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final daysInMonth = monthEnd.day;
      final dayOfMonth = now.day;

      final totalExpenses = await financeDao.sumByType('expense', monthStart, monthEnd);
      final budgets = await financeDao.watchBudgets(now.month, now.year).first;

      if (budgets.isEmpty || totalExpenses == 0) return;

      // Sum total budget
      int totalBudget = 0;
      for (final b in budgets) {
        totalBudget += b.amountCents;
      }
      if (totalBudget == 0) return;

      // Expected spend at this point in the month (linear projection)
      final expectedFraction = dayOfMonth / daysInMonth;
      final spentFraction = totalExpenses / totalBudget;

      // If spending pace is >20% ahead of expected pace
      if (spentFraction > expectedFraction + 0.2) {
        final pct = (spentFraction * 100).round();
        alerts.add(SmartAlert(
          id: 'budget_overpace',
          title: 'Ritmo de gasto elevado',
          message: 'Has gastado el $pct% de tu presupuesto mensual, '
              'pero solo vamos por el dia $dayOfMonth del mes. '
              'Considera reducir gastos no esenciales.',
          moduleKey: 'finance',
          icon: Icons.account_balance_wallet,
          color: const Color(0xFF10B981),
          actionRoute: '/finance',
        ));
      }
    } on Exception {
      // Silently ignore
    }
  }

  // ---------------------------------------------------------------------------
  // Sleep trend check
  // ---------------------------------------------------------------------------

  Future<void> _checkSleepTrend(List<SmartAlert> alerts) async {
    try {
      final sleepDao = ref.read(sleepDaoProvider);
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 4));

      final logs = await sleepDao.watchSleepLogs(from, now).first;
      if (logs.length < 3) return;

      // Check if scores have been trending down for 3+ days
      final sorted = logs..sort((a, b) => a.date.compareTo(b.date));
      final scores = sorted
          .where((l) => l.sleepScore != null)
          .map((l) => l.sleepScore)
          .toList();

      if (scores.length < 3) return;

      // Check last 3 are decreasing
      final last3 = scores.sublist(scores.length - 3);
      final trending = last3[0] > last3[1] && last3[1] > last3[2];
      if (trending && last3[2] < 60) {
        alerts.add(SmartAlert(
          id: 'sleep_declining',
          title: 'Calidad de sueno bajando',
          message:
              'Tu puntaje de sueno ha bajado los ultimos 3 dias (${last3[2]}/100). '
              'Considera acostarte mas temprano o evitar pantallas antes de dormir.',
          moduleKey: 'sleep',
          icon: Icons.bedtime_outlined,
          color: const Color(0xFF6366F1),
          actionRoute: '/sleep/history',
        ));
      }
    } on Exception {
      // Silently ignore
    }
  }

  // ---------------------------------------------------------------------------
  // Habit streak check (streak about to break)
  // ---------------------------------------------------------------------------

  Future<void> _checkHabitStreaks(List<SmartAlert> alerts) async {
    try {
      final habitsDao = ref.read(habitsDaoProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      final activeHabits = await habitsDao.watchActiveHabits().first;

      for (final habit in activeHabits) {
        final streak = await habitsDao.streakCount(habit.id, yesterday);
        if (streak < 3) continue; // Only warn for meaningful streaks

        // Check if today's log exists
        final todayLog = await habitsDao.getLogForDate(habit.id, today);
        if (todayLog != null) continue; // Already done today

        // If it's after 8pm and still not completed
        if (now.hour >= 20) {
          alerts.add(SmartAlert(
            id: 'habit_streak_${habit.id}',
            title: 'Racha en riesgo: ${habit.name}',
            message:
                'Tienes una racha de $streak dias en "${habit.name}" '
                'y aun no la has completado hoy. No la pierdas!',
            moduleKey: 'habits',
            icon: Icons.local_fire_department,
            color: const Color(0xFF8B5CF6),
            actionRoute: '/habits',
          ));
          break; // Max 1 habit streak alert
        }
      }
    } on Exception {
      // Silently ignore
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// State: list of current smart alerts, plus dismissed IDs
class SmartAlertsState {
  const SmartAlertsState({
    this.alerts = const [],
    this.dismissed = const {},
    this.isLoading = false,
    this.lastGenerated,
  });

  final List<SmartAlert> alerts;
  final Set<String> dismissed;
  final bool isLoading;
  final DateTime? lastGenerated;

  List<SmartAlert> get visible =>
      alerts.where((a) => !dismissed.contains(a.id)).toList();

  SmartAlertsState copyWith({
    List<SmartAlert>? alerts,
    Set<String>? dismissed,
    bool? isLoading,
    DateTime? lastGenerated,
  }) =>
      SmartAlertsState(
        alerts: alerts ?? this.alerts,
        dismissed: dismissed ?? this.dismissed,
        isLoading: isLoading ?? this.isLoading,
        lastGenerated: lastGenerated ?? this.lastGenerated,
      );
}

class SmartAlertsNotifier extends StateNotifier<SmartAlertsState> {
  SmartAlertsNotifier(this._ref) : super(const SmartAlertsState());

  final Ref _ref;

  /// Generate alerts if not already done today.
  Future<void> generateIfNeeded() async {
    final last = state.lastGenerated;
    final now = DateTime.now();
    if (last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day) {
      return; // Already generated today
    }
    await _generate();
  }

  Future<void> _generate() async {
    state = state.copyWith(isLoading: true);
    try {
      final service = SmartAlertsService(ref: _ref);
      final alerts = await service.generateAlerts();
      state = state.copyWith(
        alerts: alerts,
        isLoading: false,
        lastGenerated: DateTime.now(),
      );
    } on Exception {
      state = state.copyWith(isLoading: false);
    }
  }

  void dismiss(String alertId) {
    final newDismissed = {...state.dismissed, alertId};
    state = state.copyWith(dismissed: newDismissed);
  }

  void dismissAll() {
    final allIds = state.alerts.map((a) => a.id).toSet();
    state = state.copyWith(dismissed: allIds);
  }
}

final smartAlertsProvider =
    StateNotifierProvider<SmartAlertsNotifier, SmartAlertsState>((ref) {
  return SmartAlertsNotifier(ref);
});
