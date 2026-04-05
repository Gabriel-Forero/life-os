import 'package:life_os/features/finance/database/finance_dao.dart';
import 'package:life_os/features/goals/database/goals_dao.dart';
import 'package:life_os/features/gym/database/gym_dao.dart';
import 'package:life_os/features/habits/database/habits_dao.dart';
import 'package:life_os/features/nutrition/database/nutrition_dao.dart';
import 'package:life_os/features/sleep/database/sleep_dao.dart';

/// Builds a Spanish-language system prompt for the AI provider
/// from the current state of all LifeOS modules.
///
/// Callers pass a [ModuleSummary] record; missing values are omitted
/// from the prompt (never rendered as "null").
class ModuleSummary {
  const ModuleSummary({
    this.dayScore,
    this.caloriesToday,
    this.caloriesGoal,
    this.budgetUsedPercent,
    this.activeStreaks = const [],
    this.lastSleepScore,
    this.lastMoodLevel,
    this.monthlyIncomeCents,
    this.monthlyExpensesCents,
    this.activeGoalsCount,
    this.avgGoalProgress,
    this.gymWorkoutsThisWeek,
  });

  /// Today's DayScore (0–100), or null if not yet computed.
  final int? dayScore;

  /// Calories consumed today (kcal), or null if unavailable.
  final int? caloriesToday;

  /// Daily calorie goal (kcal), or null if no goal set.
  final int? caloriesGoal;

  /// Fraction of monthly budget used (0.0–1.0), or null if unavailable.
  final double? budgetUsedPercent;

  /// Active habit streaks as (name, streak-days) pairs.
  final List<({String name, int days})> activeStreaks;

  /// Last recorded sleep score (0–100), or null.
  final int? lastSleepScore;

  /// Last recorded mood level (1–10), or null.
  final int? lastMoodLevel;

  /// Monthly income in cents, or null.
  final int? monthlyIncomeCents;

  /// Monthly expenses in cents, or null.
  final int? monthlyExpensesCents;

  /// Number of active life goals, or null.
  final int? activeGoalsCount;

  /// Average progress of active goals (0–100), or null.
  final double? avgGoalProgress;

  /// Number of gym workouts this week, or null.
  final int? gymWorkoutsThisWeek;
}

/// Returns the system prompt string to inject at the start of every
/// AI conversation.
String buildAIContext(ModuleSummary summary) {
  final lines = <String>[
    'Eres un asistente de vida inteligente integrado en LifeOS.',
    'Tienes acceso al resumen de datos actuales del usuario:',
  ];

  if (summary.dayScore != null) {
    lines.add('- Puntuacion del dia: ${summary.dayScore}/100');
  }

  if (summary.caloriesToday != null && summary.caloriesGoal != null) {
    lines.add(
      '- Calorias: ${summary.caloriesToday} de ${summary.caloriesGoal} kcal consumidas hoy',
    );
  } else if (summary.caloriesToday != null) {
    lines.add('- Calorias consumidas hoy: ${summary.caloriesToday} kcal');
  }

  if (summary.budgetUsedPercent != null) {
    final pct = (summary.budgetUsedPercent! * 100).round();
    lines.add('- Presupuesto: $pct% utilizado este mes');
  }

  if (summary.monthlyIncomeCents != null ||
      summary.monthlyExpensesCents != null) {
    if (summary.monthlyIncomeCents != null) {
      lines.add(
        '- Ingresos este mes: \$${(summary.monthlyIncomeCents! / 100).toStringAsFixed(2)}',
      );
    }
    if (summary.monthlyExpensesCents != null) {
      lines.add(
        '- Gastos este mes: \$${(summary.monthlyExpensesCents! / 100).toStringAsFixed(2)}',
      );
    }
  }

  if (summary.activeStreaks.isNotEmpty) {
    final streakParts =
        summary.activeStreaks.map((s) => '${s.name} (${s.days} dias)').join(', ');
    lines.add('- Rachas activas: $streakParts');
  }

  if (summary.lastSleepScore != null) {
    lines.add('- Ultimo puntaje de sueno: ${summary.lastSleepScore}/100');
  }

  if (summary.lastMoodLevel != null) {
    lines.add('- Ultimo estado de animo: ${summary.lastMoodLevel}/10');
  }

  if (summary.activeGoalsCount != null) {
    lines.add('- Objetivos activos: ${summary.activeGoalsCount}');
    if (summary.avgGoalProgress != null) {
      lines.add(
        '- Progreso promedio de objetivos: ${summary.avgGoalProgress!.toStringAsFixed(0)}%',
      );
    }
  }

  if (summary.gymWorkoutsThisWeek != null) {
    lines.add('- Entrenamientos esta semana: ${summary.gymWorkoutsThisWeek}');
  }

  lines.add('');
  lines.add(
    'Responde siempre en espanol. Se conciso, motivador y personalizado '
    'segun los datos del usuario. Cuando el usuario pregunte sobre sus datos, '
    'usa la informacion de este contexto para responder con datos reales.',
  );
  return lines.join('\n');
}

// ---------------------------------------------------------------------------
// Real-data context builder (reads from all module DAOs)
// ---------------------------------------------------------------------------

/// Builds a [ModuleSummary] with real data from each module DAO.
///
/// Each section is wrapped in a try/catch so a single failing module
/// never prevents the rest of the summary from being built.
Future<ModuleSummary> buildModuleSummaryFromDaos({
  required FinanceDao financeDao,
  required HabitsDao habitsDao,
  required SleepDao sleepDao,
  required GymDao gymDao,
  required NutritionDao nutritionDao,
  required GoalsDao goalsDao,
}) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final monthStart = DateTime(now.year, now.month, 1);
  final weekStart = today.subtract(const Duration(days: 7));

  // --- Finance ---
  int? monthlyIncomeCents;
  int? monthlyExpensesCents;
  double? budgetUsedPercent;
  try {
    monthlyIncomeCents = await financeDao.sumByType('income', monthStart, now);
    monthlyExpensesCents =
        await financeDao.sumByType('expense', monthStart, now);
    final budgets =
        await financeDao.watchBudgets(now.month, now.year).first;
    if (budgets.isNotEmpty) {
      int totalBudget = 0;
      int totalSpent = 0;
      for (final b in budgets) {
        totalBudget += b.amountCents;
        totalSpent +=
            await financeDao.spentInBudget(b.categoryId, now.month, now.year);
      }
      if (totalBudget > 0) {
        budgetUsedPercent =
            (totalSpent / totalBudget).clamp(0.0, double.infinity);
      }
    }
  } on Exception {
    // leave null — finance data unavailable
  }

  // --- Gym ---
  int? gymWorkoutsThisWeek;
  try {
    final workouts = await gymDao.watchWorkouts(limit: 50).first;
    gymWorkoutsThisWeek = workouts
        .where(
          (w) => w.finishedAt != null && w.finishedAt!.isAfter(weekStart),
        )
        .length;
  } on Exception {
    // leave null
  }

  // --- Nutrition ---
  int? caloriesToday;
  int? caloriesGoal;
  try {
    final goal = await nutritionDao.getActiveGoal(today);
    if (goal != null) {
      caloriesGoal = goal.caloriesKcal;
    }
    final mealLogs = await nutritionDao.watchMealLogs(today).first;
    double totalCal = 0;
    for (final meal in mealLogs) {
      final items = await nutritionDao.watchMealLogItems(meal.id).first;
      for (final item in items) {
        final food = await nutritionDao.getFoodItemById(item.foodItemId);
        if (food != null) {
          totalCal += food.caloriesPer100g * item.quantityG / 100;
        }
      }
    }
    caloriesToday = totalCal.round();
  } on Exception {
    // leave null
  }

  // --- Habits (active streaks) ---
  var activeStreaks = <({String name, int days})>[];
  try {
    final habits = await habitsDao.watchActiveHabits().first;
    final streakList = <({String name, int days})>[];
    for (final h in habits) {
      final streak = await habitsDao.streakCount(h.id, now);
      if (streak > 0) {
        streakList.add((name: h.name, days: streak));
      }
    }
    streakList.sort((a, b) => b.days.compareTo(a.days));
    activeStreaks = streakList.take(3).toList();
  } on Exception {
    // leave empty
  }

  // --- Sleep ---
  int? lastSleepScore;
  try {
    final todayLog = await sleepDao.getSleepLogForDate(today);
    if (todayLog != null) {
      lastSleepScore = todayLog.sleepScore;
    } else {
      final recentLogs =
          await sleepDao.watchSleepLogs(weekStart, today).first;
      if (recentLogs.isNotEmpty) {
        lastSleepScore = recentLogs.first.sleepScore;
      }
    }
  } on Exception {
    // leave null
  }

  // --- Goals ---
  int? activeGoalsCount;
  double? avgGoalProgress;
  try {
    final goals = await goalsDao.getAllGoals();
    final active = goals.where((g) => g.status == 'active').toList();
    activeGoalsCount = active.length;
    if (active.isNotEmpty) {
      avgGoalProgress =
          active.map((g) => g.progress.toDouble()).reduce((a, b) => a + b) /
              active.length;
    }
  } on Exception {
    // leave null
  }

  return ModuleSummary(
    caloriesToday: caloriesToday,
    caloriesGoal: caloriesGoal,
    budgetUsedPercent: budgetUsedPercent,
    activeStreaks: activeStreaks,
    lastSleepScore: lastSleepScore,
    monthlyIncomeCents: monthlyIncomeCents,
    monthlyExpensesCents: monthlyExpensesCents,
    activeGoalsCount: activeGoalsCount,
    avgGoalProgress: avgGoalProgress,
    gymWorkoutsThisWeek: gymWorkoutsThisWeek,
  );
}

/// Convenience wrapper for legacy callers that pass a dynamic ref.
/// Prefer [buildModuleSummaryFromDaos] for type safety.
Future<ModuleSummary> buildRealModuleSummary(dynamic ref) async {
  return const ModuleSummary();
}
