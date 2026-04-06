import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/database/daos/app_settings_dao.dart';
import 'package:life_os/core/services/accessibility_service.dart';
import 'package:life_os/core/services/app_logger.dart';
import 'package:life_os/core/services/backup_engine.dart';
import 'package:life_os/core/services/biometric_service.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/core/services/haptic_service.dart';
import 'package:life_os/core/services/notification_scheduler.dart';
import 'package:life_os/core/services/secure_storage_service.dart';
import 'package:life_os/features/dashboard/database/dashboard_dao.dart';
import 'package:life_os/features/dashboard/providers/dashboard_notifier.dart';
import 'package:life_os/features/dashboard/providers/day_score_notifier.dart';
import 'package:life_os/features/finance/database/finance_dao.dart';
import 'package:life_os/features/finance/providers/finance_notifier.dart';
import 'package:life_os/features/goals/database/goals_dao.dart';
import 'package:life_os/features/goals/providers/goals_notifier.dart';
import 'package:life_os/features/gym/database/gym_dao.dart';
import 'package:life_os/features/gym/providers/gym_notifier.dart';
import 'package:life_os/features/habits/database/habits_dao.dart';
import 'package:life_os/features/habits/providers/habits_notifier.dart';
import 'package:life_os/features/intelligence/database/ai_dao.dart';
import 'package:life_os/features/intelligence/domain/ai_provider.dart';
import 'package:life_os/features/intelligence/domain/anthropic_provider.dart';
import 'package:life_os/features/intelligence/domain/gemini_provider.dart';
import 'package:life_os/features/sleep/services/alarm_service.dart';
import 'package:life_os/features/intelligence/domain/openai_provider.dart';
import 'package:life_os/features/intelligence/providers/ai_notifier.dart';
import 'package:life_os/features/mental/database/mental_dao.dart';
import 'package:life_os/features/mental/providers/mental_notifier.dart';
import 'package:life_os/features/nutrition/data/nutrition_repository.dart';
import 'package:life_os/features/nutrition/data/open_food_facts_client.dart';
import 'package:life_os/features/nutrition/database/nutrition_dao.dart';
import 'package:life_os/features/nutrition/providers/nutrition_notifier.dart';
import 'package:life_os/features/sleep/database/sleep_dao.dart';
import 'package:life_os/features/sleep/providers/sleep_notifier.dart';
import 'package:path_provider/path_provider.dart';

// ============================================================
// DATABASE
// ============================================================

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(
    LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}${Platform.pathSeparator}life_os.sqlite';
      return NativeDatabase.createInBackground(File(path));
    }),
  );
  ref.onDispose(db.close);
  return db;
});

// ============================================================
// DAOs
// ============================================================

final appSettingsDaoProvider = Provider<AppSettingsDao>((ref) {
  return ref.watch(appDatabaseProvider).appSettingsDao;
});

final financeDaoProvider = Provider<FinanceDao>((ref) {
  return ref.watch(appDatabaseProvider).financeDao;
});

final gymDaoProvider = Provider<GymDao>((ref) {
  return ref.watch(appDatabaseProvider).gymDao;
});

final nutritionDaoProvider = Provider<NutritionDao>((ref) {
  return ref.watch(appDatabaseProvider).nutritionDao;
});

final habitsDaoProvider = Provider<HabitsDao>((ref) {
  return ref.watch(appDatabaseProvider).habitsDao;
});

final dashboardDaoProvider = Provider<DashboardDao>((ref) {
  return ref.watch(appDatabaseProvider).dashboardDao;
});

final sleepDaoProvider = Provider<SleepDao>((ref) {
  return ref.watch(appDatabaseProvider).sleepDao;
});

final mentalDaoProvider = Provider<MentalDao>((ref) {
  return ref.watch(appDatabaseProvider).mentalDao;
});

final goalsDaoProvider = Provider<GoalsDao>((ref) {
  return ref.watch(appDatabaseProvider).goalsDao;
});

final aiDaoProvider = Provider<AiDao>((ref) {
  return ref.watch(appDatabaseProvider).aiDao;
});

// ============================================================
// CORE SERVICES
// ============================================================

final eventBusProvider = Provider<EventBus>((ref) {
  final eventBus = EventBus();
  ref.onDispose(eventBus.dispose);
  return eventBus;
});

final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger());

final biometricServiceProvider =
    Provider<BiometricService>((ref) => BiometricService());

final secureStorageServiceProvider =
    Provider<SecureStorageService>((ref) => SecureStorageService());

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return NotificationScheduler(logger: logger);
});

final accessibilityServiceProvider =
    Provider<AccessibilityService>((ref) => AccessibilityService());

final hapticServiceProvider =
    Provider<HapticService>((ref) => HapticService());

final backupEngineProvider = Provider<BackupEngine>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return BackupEngine(logger: logger);
});

// ============================================================
// FEATURE NOTIFIERS
// ============================================================

final financeNotifierProvider = Provider<FinanceNotifier>((ref) {
  return FinanceNotifier(
    dao: ref.watch(financeDaoProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

final gymNotifierProvider = Provider<GymNotifier>((ref) {
  return GymNotifier(
    dao: ref.watch(gymDaoProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

final nutritionNotifierProvider = Provider<NutritionNotifier>((ref) {
  return NutritionNotifier(dao: ref.watch(nutritionDaoProvider));
});

final habitsNotifierProvider = Provider<HabitsNotifier>((ref) {
  return HabitsNotifier(
    dao: ref.watch(habitsDaoProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

Future<double> _calculateFinanceScore(Ref ref) async {
  try {
    final dao = ref.read(financeDaoProvider);
    final now = DateTime.now();
    // Get total budget and total expenses this month
    final budgets = await dao.watchBudgets(now.month, now.year).first;
    if (budgets.isEmpty) return 0.0;
    int totalBudgetCents = 0;
    int totalSpentCents = 0;
    for (final budget in budgets) {
      totalBudgetCents += budget.amountCents;
      totalSpentCents += await dao.spentInBudget(
        budget.categoryId,
        now.month,
        now.year,
      );
    }
    if (totalBudgetCents <= 0) return 0.0;
    // Lower spending ratio = higher score (inverted)
    final utilizationRatio = totalSpentCents / totalBudgetCents;
    return ((1.0 - utilizationRatio.clamp(0.0, 1.0)) * 100.0).clamp(0.0, 100.0);
  } on Exception {
    return 0.0;
  }
}

Future<double> _calculateGymScore(Ref ref) async {
  try {
    final dao = ref.read(gymDaoProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 7));
    final workouts = await dao.watchWorkouts(limit: 20).first;
    final workedOutToday = workouts.any((w) =>
      w.finishedAt != null &&
      w.finishedAt!.isAfter(today));
    if (workedOutToday) return 100.0;
    final workedOutThisWeek = workouts.any((w) =>
      w.finishedAt != null &&
      w.finishedAt!.isAfter(weekStart));
    return workedOutThisWeek ? 50.0 : 0.0;
  } on Exception {
    return 0.0;
  }
}

Future<double> _calculateNutritionScore(Ref ref) async {
  try {
    final dao = ref.read(nutritionDaoProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final goal = await dao.getActiveGoal(today);
    if (goal == null || goal.caloriesKcal <= 0) return 0.0;
    final mealLogs = await dao.watchMealLogs(today).first;
    if (mealLogs.isEmpty) return 0.0;
    double totalCal = 0;
    for (final meal in mealLogs) {
      final items = await dao.watchMealLogItems(meal.id).first;
      for (final item in items) {
        final food = await dao.getFoodItemById(item.foodItemId);
        if (food != null) {
          totalCal += food.caloriesPer100g * item.quantityG / 100;
        }
      }
    }
    return ((totalCal / goal.caloriesKcal) * 100.0).clamp(0.0, 100.0);
  } on Exception {
    return 0.0;
  }
}

Future<double> _calculateHabitsScore(Ref ref) async {
  try {
    final dao = ref.read(habitsDaoProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activeHabits = await dao.watchActiveHabits().first;
    if (activeHabits.isEmpty) return 0.0;
    int completedToday = 0;
    for (final habit in activeHabits) {
      final log = await dao.getLogForDate(habit.id, today);
      if (log != null) completedToday++;
    }
    return (completedToday / activeHabits.length * 100.0).clamp(0.0, 100.0);
  } on Exception {
    return 0.0;
  }
}

final dayScoreNotifierProvider = ChangeNotifierProvider<DayScoreNotifier>((ref) {
  return DayScoreNotifier(
    dao: ref.watch(dashboardDaoProvider),
    eventBus: ref.watch(eventBusProvider),
    moduleScoreProvider: (moduleKey) async {
      return switch (moduleKey) {
        'finance' => await _calculateFinanceScore(ref),
        'gym' => await _calculateGymScore(ref),
        'nutrition' => await _calculateNutritionScore(ref),
        'habits' => await _calculateHabitsScore(ref),
        _ => 0.0,
      };
    },
  );
});

final dashboardNotifierProvider = ChangeNotifierProvider<DashboardNotifier>((ref) {
  return DashboardNotifier(
    dao: ref.watch(dashboardDaoProvider),
    dayScoreNotifier: ref.watch(dayScoreNotifierProvider),
    moduleSubtitleProvider: (moduleKey) {
      // TODO: Implement per-module subtitle
      return '';
    },
  );
});

final alarmServiceProvider = Provider<AlarmService>((ref) => AlarmService());

final sleepNotifierProvider = Provider<SleepNotifier>((ref) {
  return SleepNotifier(
    dao: ref.watch(sleepDaoProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

final mentalNotifierProvider = Provider<MentalNotifier>((ref) {
  return MentalNotifier(
    dao: ref.watch(mentalDaoProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

final goalsNotifierProvider = Provider<GoalsNotifier>((ref) {
  return GoalsNotifier(
    dao: ref.watch(goalsDaoProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

AIProvider _createAIProvider(AiConfiguration config) {
  // The API key is read from secure storage at the call site; providers.dart
  // wires up the factory — the key is injected empty here as a placeholder
  // (the real key is fetched by SecureStorageService before sending messages).
  const apiKey = '';
  return switch (config.providerKey) {
    'anthropic' => AnthropicProvider(apiKey: apiKey, model: config.modelName),
    'gemini' => GeminiProvider(apiKey: apiKey, model: config.modelName),
    _ => OpenAIProvider(apiKey: apiKey, model: config.modelName),
  };
}

final aiNotifierProvider = Provider<AINotifier>((ref) {
  return AINotifier(
    dao: ref.watch(aiDaoProvider),
    providerFactory: _createAIProvider,
  );
});

// ============================================================
// STARTUP STATE
// ============================================================

/// Number of recurring transactions created during app startup.
/// Updated by main.dart after processRecurringTransactions() completes.
/// The Dashboard reads this to show a one-shot snackbar.
final recurringCreatedCountProvider = StateProvider<int>((ref) => 0);

// ============================================================
// NUTRITION API
// ============================================================

final openFoodFactsClientProvider =
    Provider<OpenFoodFactsClient>((ref) => OpenFoodFactsClient());

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  return NutritionRepository(
    dao: ref.watch(nutritionDaoProvider),
    apiClient: ref.watch(openFoodFactsClientProvider),
  );
});
