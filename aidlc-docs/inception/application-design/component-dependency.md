# Component Dependency Map

## Purpose

Documents all inter-module dependencies in LifeOS: Riverpod provider dependencies, EventBus event flow, and data flow. Ensures the dependency graph is a DAG (directed acyclic graph) with no circular dependencies.

---

## Dependency Matrix

Rows depend on columns. An "R" means Riverpod `ref.watch`/`ref.read` dependency. An "E" means EventBus subscription. A dash means no dependency.

|               | Core | Finance | Gym | Nutrition | Habits | Sleep | Mental | Goals | Intelligence | DayScore | Dashboard | Onboarding |
|---------------|------|---------|-----|-----------|--------|-------|--------|-------|--------------|----------|-----------|------------|
| **Core**      | -    | -       | -   | -         | -      | -     | -      | -     | -            | -        | -         | -          |
| **Finance**   | R    | -       | -   | -         | -      | -     | -      | -     | -            | -        | -         | -          |
| **Gym**       | R    | -       | -   | -         | -      | -     | -      | -     | -            | -        | -         | -          |
| **Nutrition** | R    | E       | E   | -         | -      | -     | -      | -     | -            | -        | -         | -          |
| **Habits**    | R    | -       | E   | -         | -      | -     | -      | -     | -            | -        | -         | -          |
| **Sleep**     | R    | -       | -   | -         | -      | -     | -      | -     | -            | -        | -         | -          |
| **Mental**    | R    | -       | -   | -         | -      | -     | -      | -     | -            | -        | -         | -          |
| **Goals**     | R    | -       | -   | -         | E      | E     | E      | -     | -            | -        | -         | -          |
| **Intelligence** | R | -       | -   | -         | -      | -     | -      | -     | -            | -        | -         | -          |
| **DayScore**  | R    | R       | R   | R         | R      | R     | R      | R     | -            | -        | -         | -          |
| **Dashboard** | R    | R       | R   | R         | R      | R     | R      | R     | -            | R        | -         | -          |
| **Onboarding**| R    | -       | -   | -         | -      | -     | -      | -     | -            | -        | -         | -          |

---

## Riverpod Provider Dependency DAG

The following shows provider-level dependencies (what each module's Notifier reads/watches from Core or other modules). Arrows point from dependent to dependency.

```
Level 0 (no dependencies):
  Core
    AppDatabase
    EventBus
    NotificationService
    HapticService
    SecureStorageService
    BackupService
    ExerciseLibraryService
    ThemeNotifier

Level 1 (depend only on Core):
  Finance       --> [AppDatabase, EventBus]
  Gym           --> [AppDatabase, EventBus]
  Habits        --> [AppDatabase, EventBus]
  Sleep         --> [AppDatabase, EventBus]
  Mental        --> [AppDatabase, EventBus]
  Goals         --> [AppDatabase, EventBus]
  Intelligence  --> [AppDatabase, SecureStorageService]
  Nutrition     --> [AppDatabase, EventBus]
  Onboarding    --> [AppDatabase, ExerciseLibraryService]

Level 2 (depend on Level 0 + Level 1):
  DayScore      --> [AppDatabase, FinanceNotifier, GymNotifier,
                     NutritionNotifier, HabitsNotifier, SleepNotifier,
                     MentalNotifier, GoalsNotifier]

Level 3 (depend on Level 0 + Level 1 + Level 2):
  Dashboard     --> [DayScoreNotifier, FinanceNotifier, GymNotifier,
                     NutritionNotifier, HabitsNotifier, SleepNotifier,
                     MentalNotifier, GoalsNotifier, EventBus]
```

---

## EventBus Event Flow

### Emitters and Subscribers

```
WorkoutCompletedEvent
  Emitter:     GymNotifier.finishWorkout()
  Subscribers: HabitsNotifier    -- auto-check gym-related habits
               NutritionNotifier -- suggest post-workout meal logging
               DayScoreNotifier  -- trigger score recalculation

ExpenseAddedEvent
  Emitter:     FinanceNotifier.addTransaction() (when type == expense)
  Subscribers: NutritionNotifier -- correlate food-category expenses

BudgetThresholdEvent
  Emitter:     FinanceNotifier.addTransaction() / setBudget() (when utilization >= threshold)
  Subscribers: DashboardNotifier    -- show budget alert card
               NotificationService  -- send push notification

HabitCheckedInEvent
  Emitter:     HabitsNotifier.checkIn()
  Subscribers: GoalsNotifier     -- update habit-linked goal progress
               DashboardNotifier -- refresh habit summary
               DayScoreNotifier  -- trigger score recalculation

SleepLogSavedEvent
  Emitter:     SleepNotifier.logSleep()
  Subscribers: GoalsNotifier     -- update sleep-linked goal progress
               DashboardNotifier -- refresh sleep summary
               DayScoreNotifier  -- trigger score recalculation

MoodLoggedEvent
  Emitter:     MentalNotifier.logMood()
  Subscribers: GoalsNotifier     -- update wellness-linked goal progress
               DashboardNotifier -- refresh mental summary
               DayScoreNotifier  -- trigger score recalculation

GoalProgressUpdatedEvent
  Emitter:     GoalsNotifier.updateProgress() / completeMilestone()
  Subscribers: DashboardNotifier -- refresh goal highlights
```

### Event Flow Diagram

```
+------------------+                          +-------------------+
|   GymNotifier    |---WorkoutCompleted------>|  HabitsNotifier   |
|                  |---WorkoutCompleted------>| NutritionNotifier |
|                  |---WorkoutCompleted------>|  DayScoreNotifier |
+------------------+                          +-------------------+

+------------------+                          +-------------------+
| FinanceNotifier  |---ExpenseAdded---------->| NutritionNotifier |
|                  |---BudgetThreshold------->| DashboardNotifier |
|                  |---BudgetThreshold------->| NotificationSvc   |
+------------------+                          +-------------------+

+------------------+                          +-------------------+
| HabitsNotifier   |---HabitCheckedIn-------->|  GoalsNotifier    |
|                  |---HabitCheckedIn-------->| DashboardNotifier |
|                  |---HabitCheckedIn-------->|  DayScoreNotifier |
+------------------+                          +-------------------+

+------------------+                          +-------------------+
|  SleepNotifier   |---SleepLogSaved--------->|  GoalsNotifier    |
|                  |---SleepLogSaved--------->| DashboardNotifier |
|                  |---SleepLogSaved--------->|  DayScoreNotifier |
+------------------+                          +-------------------+

+------------------+                          +-------------------+
| MentalNotifier   |---MoodLogged------------>|  GoalsNotifier    |
|                  |---MoodLogged------------>| DashboardNotifier |
|                  |---MoodLogged------------>|  DayScoreNotifier |
+------------------+                          +-------------------+

+------------------+                          +-------------------+
|  GoalsNotifier   |---GoalProgressUpdated--->| DashboardNotifier |
+------------------+                          +-------------------+
```

---

## Data Flow Diagram

Shows how data flows from storage through the layers to the UI.

```
+===========================================================================+
|                              UI LAYER                                     |
|  DashboardScreen | HabitsDashboard | ActiveWorkout | DailyNutrition | ...|
+===================================|=======================================+
            |  ref.watch(xxxNotifierProvider)
            v
+===========================================================================+
|                          NOTIFIER LAYER (Riverpod)                        |
|  DashboardNotifier | HabitsNotifier | GymNotifier | NutritionNotifier ...|
|                                                                           |
|  - Holds AsyncValue<State>                                                |
|  - Business validation                                                    |
|  - Returns Result<T>                                                      |
|  - Emits/subscribes EventBus events                                       |
+==========================|================|===============================+
            |              |                |
     [Local modules]  [Hybrid modules]      |
            |              |                |
            v              v                |
+==================+ +===================+  |
|    DAO LAYER     | | REPOSITORY LAYER  |  |
| (Drift DAOs)    | | (Dao + ApiClient) |  |
|                  | |                   |  |
| FinanceDao       | | NutritionRepo    |  |
| GymDao           | |   NutritionDao   |  |
| HabitsDao        | |   OpenFoodFacts  |  |
| SleepDao         | |                   |  |
| MentalDao        | | AIRepository     |  |
| GoalsDao         | |   AIDao          |  |
| DayScoreDao      | |   AIProviders    |  |
+========|=========+ +========|==========+  |
         |                    |             |
         v                    v             |
+===========================================================================+
|                        DRIFT DATABASE (SQLite)                            |
|  AppDatabase singleton -- 35 tables across all modules                    |
|  Reactive streams via .watch() queries                                    |
+===========================================================================+
         |                                  |
         |                          +===============+
         |                          | EXTERNAL APIs |
         |                          | OpenFoodFacts |
         |                          | AI Providers  |
         |                          +===============+
         |
+===========================================================================+
|                        PLATFORM SERVICES                                  |
|  SecureStorage | Notifications | Haptics | FileSystem (Backup)            |
+===========================================================================+
```

---

## Cross-Cutting Dependency: EventBus Subscription Setup

Each Notifier that subscribes to events does so in its `build()` method:

```dart
// Example: GoalsNotifier subscribing to events
@override
Future<GoalsState> build() async {
  final eventBus = ref.read(eventBusProvider);

  // Subscribe to habit check-ins
  eventBus.on<HabitCheckedInEvent>().listen((event) {
    _handleHabitCheckIn(event);
  });

  // Subscribe to sleep logs
  eventBus.on<SleepLogSavedEvent>().listen((event) {
    _handleSleepLog(event);
  });

  // Subscribe to mood logs
  eventBus.on<MoodLoggedEvent>().listen((event) {
    _handleMoodLog(event);
  });

  // Load initial state
  return _loadGoals();
}
```

---

## Circular Dependency Prevention Rules

1. **Core depends on nothing** -- it is the foundation layer
2. **Feature modules (Level 1) depend only on Core** -- never on each other via Riverpod
3. **Cross-module communication uses EventBus only** -- never direct Notifier-to-Notifier calls between Level 1 modules
4. **DayScore (Level 2) may read from Level 1 Notifiers** -- it is a pure aggregator
5. **Dashboard (Level 3) may read from Level 1 + Level 2** -- it is a pure display aggregator
6. **No module at Level N may depend on a module at Level N or higher**

---

## Provider Registration Summary

| Provider | Type | Level |
|----------|------|-------|
| `appDatabaseProvider` | `Provider<AppDatabase>` | 0 |
| `eventBusProvider` | `Provider<EventBus>` | 0 |
| `notificationServiceProvider` | `Provider<NotificationService>` | 0 |
| `hapticServiceProvider` | `Provider<HapticService>` | 0 |
| `secureStorageServiceProvider` | `Provider<SecureStorageService>` | 0 |
| `backupServiceProvider` | `Provider<BackupService>` | 0 |
| `exerciseLibraryServiceProvider` | `Provider<ExerciseLibraryService>` | 0 |
| `themeNotifierProvider` | `NotifierProvider<ThemeNotifier, ThemeState>` | 0 |
| `financeDaoProvider` | `Provider<FinanceDao>` | 0 |
| `gymDaoProvider` | `Provider<GymDao>` | 0 |
| `nutritionDaoProvider` | `Provider<NutritionDao>` | 0 |
| `habitsDaoProvider` | `Provider<HabitsDao>` | 0 |
| `sleepDaoProvider` | `Provider<SleepDao>` | 0 |
| `mentalDaoProvider` | `Provider<MentalDao>` | 0 |
| `goalsDaoProvider` | `Provider<GoalsDao>` | 0 |
| `aiDaoProvider` | `Provider<AIDao>` | 0 |
| `dayScoreDaoProvider` | `Provider<DayScoreDao>` | 0 |
| `openFoodFactsClientProvider` | `Provider<OpenFoodFactsClient>` | 0 |
| `nutritionRepositoryProvider` | `Provider<NutritionRepository>` | 0 |
| `aiRepositoryProvider` | `Provider<AIRepository>` | 0 |
| `financeNotifierProvider` | `AsyncNotifierProvider<FinanceNotifier, FinanceState>` | 1 |
| `gymNotifierProvider` | `AsyncNotifierProvider<GymNotifier, GymState>` | 1 |
| `nutritionNotifierProvider` | `AsyncNotifierProvider<NutritionNotifier, NutritionState>` | 1 |
| `habitsNotifierProvider` | `AsyncNotifierProvider<HabitsNotifier, HabitsState>` | 1 |
| `sleepNotifierProvider` | `AsyncNotifierProvider<SleepNotifier, SleepState>` | 1 |
| `mentalNotifierProvider` | `AsyncNotifierProvider<MentalNotifier, MentalState>` | 1 |
| `goalsNotifierProvider` | `AsyncNotifierProvider<GoalsNotifier, GoalsState>` | 1 |
| `aiNotifierProvider` | `AsyncNotifierProvider<AINotifier, AIState>` | 1 |
| `onboardingNotifierProvider` | `AsyncNotifierProvider<OnboardingNotifier, OnboardingState>` | 1 |
| `dayScoreNotifierProvider` | `AsyncNotifierProvider<DayScoreNotifier, DayScoreState>` | 2 |
| `dashboardNotifierProvider` | `AsyncNotifierProvider<DashboardNotifier, DashboardState>` | 3 |
