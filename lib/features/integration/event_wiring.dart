import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/services/app_logger.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/core/services/notification_scheduler.dart';
import 'package:life_os/features/dashboard/providers/dashboard_notifier.dart';
import 'package:life_os/features/dashboard/providers/day_score_notifier.dart';
import 'package:life_os/features/habits/providers/habits_notifier.dart';
import 'package:life_os/features/nutrition/data/nutrition_data_repository.dart';

/// Sets up ALL cross-module EventBus subscriptions.
///
/// Must be called exactly once at app startup, after all notifiers
/// and services have been initialised. Returns a list of subscription
/// cancellation callbacks so callers can dispose cleanly.
List<void Function()> wireEventBus({
  required EventBus eventBus,
  required HabitsNotifier habitsNotifier,
  required NutritionDataRepository nutritionRepo,
  required DayScoreNotifier dayScoreNotifier,
  required DashboardNotifier dashboardNotifier,
  NotificationScheduler? notificationScheduler,
  AppLogger? logger,
}) {
  final log = logger ?? AppLogger(tag: 'EventWiring');
  final subs = <void Function()>[];

  // -------------------------------------------------------------------------
  // WorkoutCompletedEvent
  // -------------------------------------------------------------------------
  subs.add(
    eventBus.on<WorkoutCompletedEvent>().listen((event) async {
      log.info('WorkoutCompleted(workoutId=${event.workoutId}) received');

      // 1. Auto check-in habits linked to workout
      await habitsNotifier.onWorkoutCompleted(event);

      // 2. Adjust today's nutrition goals (+15% cal, +20% protein, +10% carbs)
      await _adjustNutritionForTraining(nutritionRepo, log);

      // 3. Recalculate day score
      await dayScoreNotifier.calculateDayScore(DateTime.now());
    }).cancel,
  );

  // -------------------------------------------------------------------------
  // ExpenseAddedEvent
  // -------------------------------------------------------------------------
  subs.add(
    eventBus.on<ExpenseAddedEvent>().listen((event) async {
      log.info(
        'ExpenseAdded(id=${event.transactionId}, '
        'category=${event.categoryName}) received',
      );
      // Stub: food category triggers future AI nutritional suggestion.
      // No crash when no AI provider is configured.
      final isFoodCategory = const ['alimentacion', 'comida', 'restaurante']
          .any((c) => event.categoryName.toLowerCase().contains(c));
      if (isFoodCategory) {
        log.info(
          'Food expense detected — AI nutrition suggestion stub triggered',
        );
      }
    }).cancel,
  );

  // -------------------------------------------------------------------------
  // BudgetThresholdEvent
  // -------------------------------------------------------------------------
  subs.add(
    eventBus.on<BudgetThresholdEvent>().listen((event) async {
      log.info(
        'BudgetThreshold(budgetId=${event.budgetId}, '
        '${(event.percentage * 100).round()}%) received',
      );
      await dashboardNotifier.refresh();
      final pct = (event.percentage * 100).round();
      await notificationScheduler?.showImmediate(
        id: 1000 + event.budgetId,
        title: 'Alerta de presupuesto',
        body:
            'Has utilizado el $pct% de tu presupuesto en '
            '"${event.categoryName}".',
      );
    }).cancel,
  );

  // -------------------------------------------------------------------------
  // HabitCheckedInEvent
  // -------------------------------------------------------------------------
  subs.add(
    eventBus.on<HabitCheckedInEvent>().listen((event) async {
      log.info(
        'HabitCheckedIn(habitId=${event.habitId}) received',
      );
      // GoalsNotifier handles its own subscription (Unit 7).
      await dashboardNotifier.refresh();
      await dayScoreNotifier.calculateDayScore(DateTime.now());
    }).cancel,
  );

  // -------------------------------------------------------------------------
  // SleepLogSavedEvent
  // -------------------------------------------------------------------------
  subs.add(
    eventBus.on<SleepLogSavedEvent>().listen((event) async {
      log.info(
        'SleepLogSaved(sleepLogId=${event.sleepLogId}) received',
      );
      // GoalsNotifier handles its own subscription (Unit 7).
      await dashboardNotifier.refresh();
      await dayScoreNotifier.calculateDayScore(DateTime.now());
    }).cancel,
  );

  // -------------------------------------------------------------------------
  // MoodLoggedEvent
  // -------------------------------------------------------------------------
  subs.add(
    eventBus.on<MoodLoggedEvent>().listen((event) async {
      log.info('MoodLogged(moodLogId=${event.moodLogId}) received');
      // GoalsNotifier handles its own subscription (Unit 7).
      await dashboardNotifier.refresh();
      await dayScoreNotifier.calculateDayScore(DateTime.now());
    }).cancel,
  );

  // -------------------------------------------------------------------------
  // GoalProgressUpdatedEvent
  // -------------------------------------------------------------------------
  subs.add(
    eventBus.on<GoalProgressUpdatedEvent>().listen((event) async {
      log.info(
        'GoalProgressUpdated(goalId=${event.goalId}, '
        'progress=${event.progress}) received',
      );
      await dashboardNotifier.refresh();
    }).cancel,
  );

  log.info('EventBus wired: ${subs.length} cross-module subscriptions active');
  return subs;
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/// Reads today's active nutrition goal and inserts an adjusted copy
/// for training days: +15% calories, +20% protein, +10% carbs, fat unchanged.
Future<void> _adjustNutritionForTraining(
  NutritionDataRepository repo,
  AppLogger log,
) async {
  final today = DateTime.now();
  final goal = await repo.getActiveGoal(today);

  if (goal == null) {
    log.warning('No active nutrition goal found; training adjustment skipped');
    return;
  }

  final adjustedCalories = (goal.caloriesKcal * 1.15).round();
  final adjustedProtein = goal.proteinG * 1.20;
  final adjustedCarbs = goal.carbsG * 1.10;

  await repo.insertNutritionGoal(
    caloriesKcal: adjustedCalories,
    proteinG: adjustedProtein,
    carbsG: adjustedCarbs,
    fatG: goal.fatG, // unchanged
    waterMl: goal.waterMl,
    effectiveDate: DateTime(today.year, today.month, today.day),
    createdAt: DateTime.now(),
  );

  log.info(
    'Nutrition adjusted for training day: '
    '${goal.caloriesKcal} -> $adjustedCalories kcal',
  );
}
