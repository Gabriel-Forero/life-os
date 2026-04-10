import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/database/connection/connection.dart';
import 'package:life_os/core/database/daos/app_settings_dao.dart';
import 'package:life_os/core/services/accessibility_service.dart';
import 'package:life_os/core/services/app_logger.dart';
import 'package:life_os/core/services/backup_engine.dart';
import 'package:life_os/core/services/biometric_service.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/core/services/haptic_service.dart';
import 'package:life_os/core/services/notification_scheduler.dart';
import 'package:life_os/core/services/secure_storage_service.dart';
import 'package:life_os/features/dashboard/data/dashboard_repository.dart';
import 'package:life_os/features/dashboard/data/drift_dashboard_repository.dart';
import 'package:life_os/features/dashboard/database/dashboard_dao.dart';
import 'package:life_os/features/dashboard/providers/dashboard_notifier.dart';
import 'package:life_os/features/dashboard/providers/day_score_notifier.dart';
import 'package:life_os/features/finance/data/finance_repository.dart';
import 'package:life_os/features/finance/data/firestore_finance_repository.dart';
import 'package:life_os/features/finance/database/finance_dao.dart';
import 'package:life_os/features/finance/providers/finance_notifier.dart';
import 'package:life_os/features/goals/data/drift_goals_repository.dart';
import 'package:life_os/features/goals/data/goals_repository.dart';
import 'package:life_os/features/goals/database/goals_dao.dart';
import 'package:life_os/features/goals/providers/goals_notifier.dart';
import 'package:life_os/features/gym/data/drift_gym_repository.dart';
import 'package:life_os/features/gym/data/gym_repository.dart';
import 'package:life_os/features/gym/database/gym_dao.dart';
import 'package:life_os/features/gym/providers/gym_notifier.dart';
import 'package:life_os/features/habits/data/drift_habits_repository.dart';
import 'package:life_os/features/habits/data/habits_repository.dart';
import 'package:life_os/features/habits/database/habits_dao.dart';
import 'package:life_os/features/habits/providers/habits_notifier.dart';
import 'package:life_os/features/intelligence/data/ai_repository.dart';
import 'package:life_os/features/intelligence/data/drift_ai_repository.dart';
import 'package:life_os/features/intelligence/database/ai_dao.dart';
import 'package:life_os/features/intelligence/domain/ai_provider.dart';
import 'package:life_os/features/intelligence/domain/anthropic_provider.dart';
import 'package:life_os/features/intelligence/domain/gemini_provider.dart';
import 'package:life_os/features/intelligence/domain/models/ai_configuration_model.dart';
import 'package:life_os/features/intelligence/domain/openai_provider.dart';
import 'package:life_os/features/intelligence/providers/ai_notifier.dart';
import 'package:life_os/features/sleep/services/alarm_service.dart';
import 'package:life_os/features/mental/data/drift_mental_repository.dart';
import 'package:life_os/features/mental/data/mental_repository.dart';
import 'package:life_os/features/mental/database/mental_dao.dart';
import 'package:life_os/features/settings/data/drift_settings_repository.dart';
import 'package:life_os/features/settings/data/settings_repository.dart';
import 'package:life_os/features/mental/providers/mental_notifier.dart';
import 'package:life_os/features/nutrition/data/drift_nutrition_data_repository.dart';
import 'package:life_os/features/nutrition/data/nutrition_data_repository.dart';
import 'package:life_os/features/nutrition/data/nutrition_repository.dart';
import 'package:life_os/features/nutrition/data/open_food_facts_client.dart';
import 'package:life_os/features/nutrition/database/nutrition_dao.dart';
import 'package:life_os/features/nutrition/providers/nutrition_notifier.dart';
import 'package:life_os/features/sleep/data/drift_sleep_repository.dart';
import 'package:life_os/features/sleep/data/sleep_repository.dart';
import 'package:life_os/features/sleep/database/sleep_dao.dart';
import 'package:life_os/features/sleep/providers/sleep_notifier.dart';

// ============================================================
// DATABASE
// ============================================================

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(createDatabaseConnection());
  ref.onDispose(db.close);
  return db;
});

// ============================================================
// DAOs
// ============================================================

final appSettingsDaoProvider = Provider<AppSettingsDao>((ref) {
  return ref.watch(appDatabaseProvider).appSettingsDao;
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return DriftSettingsRepository(dao: ref.watch(appSettingsDaoProvider));
});

final financeDaoProvider = Provider<FinanceDao>((ref) {
  return ref.watch(appDatabaseProvider).financeDao;
});

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  // TODO: Replace 'test_user' with authenticated user ID
  return FirestoreFinanceRepository(userId: 'test_user');
});

final gymDaoProvider = Provider<GymDao>((ref) {
  return ref.watch(appDatabaseProvider).gymDao;
});

final gymRepositoryProvider = Provider<GymRepository>((ref) {
  return DriftGymRepository(dao: ref.watch(gymDaoProvider));
});

final nutritionDaoProvider = Provider<NutritionDao>((ref) {
  return ref.watch(appDatabaseProvider).nutritionDao;
});

final nutritionDataRepositoryProvider =
    Provider<NutritionDataRepository>((ref) {
  return DriftNutritionDataRepository(dao: ref.watch(nutritionDaoProvider));
});

final habitsDaoProvider = Provider<HabitsDao>((ref) {
  return ref.watch(appDatabaseProvider).habitsDao;
});

final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  return DriftHabitsRepository(dao: ref.watch(habitsDaoProvider));
});

final dashboardDaoProvider = Provider<DashboardDao>((ref) {
  return ref.watch(appDatabaseProvider).dashboardDao;
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DriftDashboardRepository(dao: ref.watch(dashboardDaoProvider));
});

final sleepDaoProvider = Provider<SleepDao>((ref) {
  return ref.watch(appDatabaseProvider).sleepDao;
});

final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  return DriftSleepRepository(dao: ref.watch(sleepDaoProvider));
});

final mentalDaoProvider = Provider<MentalDao>((ref) {
  return ref.watch(appDatabaseProvider).mentalDao;
});

final mentalRepositoryProvider = Provider<MentalRepository>((ref) {
  return DriftMentalRepository(dao: ref.watch(mentalDaoProvider));
});

final goalsDaoProvider = Provider<GoalsDao>((ref) {
  return ref.watch(appDatabaseProvider).goalsDao;
});

final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return DriftGoalsRepository(dao: ref.watch(goalsDaoProvider));
});

final aiDaoProvider = Provider<AiDao>((ref) {
  return ref.watch(appDatabaseProvider).aiDao;
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return DriftAiRepository(dao: ref.watch(aiDaoProvider));
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
    repository: ref.watch(financeRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

final gymNotifierProvider = Provider<GymNotifier>((ref) {
  return GymNotifier(
    repository: ref.watch(gymRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

final nutritionNotifierProvider = Provider<NutritionNotifier>((ref) {
  return NutritionNotifier(repository: ref.watch(nutritionDataRepositoryProvider));
});

final habitsNotifierProvider = Provider<HabitsNotifier>((ref) {
  return HabitsNotifier(
    repository: ref.watch(habitsRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

Future<double> _calculateFinanceScore(Ref ref) async {
  try {
    final repo = ref.read(financeRepositoryProvider);
    final now = DateTime.now();
    // Get total budget and total expenses this month
    final budgets = await repo.watchBudgets(now.month, now.year).first;
    if (budgets.isEmpty) return 0.0;
    int totalBudgetCents = 0;
    int totalSpentCents = 0;
    for (final budget in budgets) {
      totalBudgetCents += budget.amountCents;
      totalSpentCents += await repo.spentInBudget(
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
    final repo = ref.read(gymRepositoryProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(const Duration(days: 7));
    final workouts = await repo.watchWorkouts(limit: 20).first;
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
    final repo = ref.read(nutritionDataRepositoryProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final goal = await repo.getActiveGoal(today);
    if (goal == null || goal.caloriesKcal <= 0) return 0.0;
    final mealLogs = await repo.watchMealLogs(today).first;
    if (mealLogs.isEmpty) return 0.0;
    double totalCal = 0;
    for (final meal in mealLogs) {
      final items = await repo.watchMealLogItems(meal.id).first;
      for (final item in items) {
        final food = await repo.getFoodItemById(item.foodItemId);
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
    final repo = ref.read(habitsRepositoryProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activeHabits = await repo.watchActiveHabits().first;
    if (activeHabits.isEmpty) return 0.0;
    int completedToday = 0;
    for (final habit in activeHabits) {
      final log = await repo.getLogForDate(habit.id, today);
      if (log != null) completedToday++;
    }
    return (completedToday / activeHabits.length * 100.0).clamp(0.0, 100.0);
  } on Exception {
    return 0.0;
  }
}

final dayScoreNotifierProvider = ChangeNotifierProvider<DayScoreNotifier>((ref) {
  return DayScoreNotifier(
    repository: ref.watch(dashboardRepositoryProvider),
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
    repository: ref.watch(dashboardRepositoryProvider),
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
    repository: ref.watch(sleepRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

final mentalNotifierProvider = Provider<MentalNotifier>((ref) {
  return MentalNotifier(
    repository: ref.watch(mentalRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

final goalsNotifierProvider = Provider<GoalsNotifier>((ref) {
  return GoalsNotifier(
    repository: ref.watch(goalsRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
});

AIProvider _createAIProvider(AiConfigurationModel config) {
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
    repository: ref.watch(aiRepositoryProvider),
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
    dataRepository: ref.watch(nutritionDataRepositoryProvider),
    apiClient: ref.watch(openFoodFactsClientProvider),
  );
});
