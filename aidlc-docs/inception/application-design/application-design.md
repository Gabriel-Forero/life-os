# Application Design -- LifeOS

## Purpose

Consolidation document that provides a complete architectural reference for LifeOS. Brings together component definitions, method signatures, service layer, and dependency mapping into a single overview. For full details, see the linked documents.

---

## Architecture Overview

LifeOS is a cross-platform Flutter application for holistic life tracking. It is structured as a feature-first monolith with 12 modules sharing a single Drift (SQLite) database. The architecture follows a layered pattern with strict dependency rules to prevent circular references.

### Core Technology Stack

| Concern | Technology |
|---------|------------|
| Framework | Flutter (cross-platform: iOS, Android, potentially desktop) |
| State Management | Riverpod (AsyncNotifier pattern) |
| Database | Drift (SQLite, type-safe, reactive streams) |
| Navigation | go_router |
| Design System | Custom dark theme (not Material/Cupertino defaults) |
| Error Handling | Result type (sealed class) in business layer, AsyncValue in UI |
| Cross-Module Comms | EventBus (StreamController broadcast) |

### Design Principles

1. **Feature-first organization** -- each module owns its models, DAO/Repository, Notifier, and screens
2. **Hybrid data layer** -- local modules use DAO directly; API-connected modules use Repository pattern
3. **Reactive by default** -- Drift `watch()` streams flow through Notifiers into UI via `ref.watch`
4. **Decoupled communication** -- modules never call each other's Notifiers directly; they communicate via typed EventBus events
5. **Layered error handling** -- `Result<T>` for business operations, `AsyncValue<T>` for UI state

---

## Layer Architecture

```
+-----------------------------------------------------------------------+
|                             UI LAYER                                  |
|  Screens + Widgets (ref.watch Notifiers, render AsyncValue states)    |
+-----------------------------------+-----------------------------------+
                                    |
                              ref.watch / ref.read
                                    |
+-----------------------------------v-----------------------------------+
|                          NOTIFIER LAYER                               |
|  AsyncNotifiers: hold state, validate, emit events, return Result<T>  |
+----------+-------------------+--------------------+-------------------+
           |                   |                    |
    [Local modules]     [Hybrid modules]     [EventBus events]
           |                   |                    |
+----------v----------+ +-----v-----------+  +-----v---------+
|     DAO LAYER       | | REPOSITORY LAYER|  |   EVENT BUS   |
|  Drift DAOs with    | | DAO + API Client|  | Broadcast      |
|  type-safe queries  | | (cache + fetch) |  | stream         |
+----------+----------+ +-----+-----------+  +---------------+
           |                   |
+----------v-------------------v------------------------------------+
|                     DRIFT DATABASE (SQLite)                       |
|  AppDatabase singleton -- 35 tables -- reactive .watch() streams  |
+------------------------------------------------------------------+
                               |
                       +-------+--------+
                       |                |
              +--------v------+  +------v---------+
              | Platform Svcs |  | External APIs  |
              | SecureStorage |  | OpenFoodFacts  |
              | Notifications |  | AI Providers   |
              | Haptics       |  +----------------+
              | FileSystem    |
              +--------------+
```

---

## Component Summary Table

| Module | Purpose | Tables | Data Pattern | Notifier | Key Events |
|--------|---------|--------|--------------|----------|------------|
| Core | Shared infra, DB, router, theme, services | 1 (AppSettings) | DAO | ThemeNotifier, settings | -- |
| Finance | Income, expenses, budgets, savings | 5 | DAO | FinanceNotifier | Emits: ExpenseAdded, BudgetThreshold |
| Gym | Workouts, exercises, routines, body measurements | 6 | DAO | GymNotifier | Emits: WorkoutCompleted |
| Nutrition | Food logging, water, meal templates | 6 | Repository | NutritionNotifier | Subscribes: ExpenseAdded, WorkoutCompleted |
| Habits | Daily habit tracking, streaks | 2 | DAO | HabitsNotifier | Emits: HabitCheckedIn. Subscribes: WorkoutCompleted |
| Sleep | Sleep logs, interruptions, energy | 3 | DAO | SleepNotifier | Emits: SleepLogSaved |
| Mental | Mood tracking, breathing exercises | 2 | DAO | MentalNotifier | Emits: MoodLogged |
| Goals | Life goals, sub-goals, milestones | 3 | DAO | GoalsNotifier | Emits: GoalProgressUpdated. Subscribes: HabitCheckedIn, SleepLogSaved, MoodLogged |
| Intelligence | AI conversations, provider configs | 3 | Repository | AINotifier | -- |
| DayScore | Daily composite score, snapshots | 4 | DAO | DayScoreNotifier | Subscribes: WorkoutCompleted, HabitCheckedIn, SleepLogSaved, MoodLogged |
| Dashboard | Aggregated daily overview | 0 | Read-only | DashboardNotifier | Subscribes: BudgetThreshold, GoalProgressUpdated |
| Onboarding | First-launch setup wizard | 0 | Settings | OnboardingNotifier | -- |

**Total: 35 Drift tables**

---

## Error Handling Pattern

### Business Layer: Result Type

```dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);
}

sealed class AppFailure {
  String get message;
}

class ValidationFailure extends AppFailure {
  @override final String message;
  final Map<String, String> fieldErrors;
  ValidationFailure(this.message, {this.fieldErrors = const {}});
}

class DatabaseFailure extends AppFailure {
  @override final String message;
  DatabaseFailure(this.message);
}

class NetworkFailure extends AppFailure {
  @override final String message;
  final int? statusCode;
  NetworkFailure(this.message, {this.statusCode});
}

class NotFoundFailure extends AppFailure {
  @override final String message;
  NotFoundFailure(this.message);
}
```

### UI Layer: AsyncValue

```dart
// In the widget:
ref.watch(financeNotifierProvider).when(
  data: (state) => TransactionList(state.transactions),
  loading: () => LoadingIndicator(),
  error: (error, stack) => ErrorDisplay(error),
);
```

### Flow

```
User Action
  --> Notifier method called
    --> Validates input
    --> Calls DAO/Repository
    --> Returns Result<T>
      --> Success: update state, emit events
      --> Failure: state.error or show snackbar
```

---

## EventBus Pattern

### Architecture

```dart
// Core provides singleton EventBus
final eventBusProvider = Provider<EventBus>((ref) => EventBus());

// Emitting module (e.g., GymNotifier):
ref.read(eventBusProvider).emit(WorkoutCompletedEvent(
  workoutId: workout.id,
  duration: duration,
  totalSets: setCount,
));

// Subscribing module (e.g., HabitsNotifier):
// In build():
ref.read(eventBusProvider).on<WorkoutCompletedEvent>().listen((event) {
  _autoCheckGymHabits(event);
});
```

### Event Routing Summary

```
Gym ----WorkoutCompleted----> Habits, Nutrition, DayScore
Finance --ExpenseAdded------> Nutrition
Finance --BudgetThreshold---> Dashboard, Notifications
Habits ---HabitCheckedIn----> Goals, Dashboard, DayScore
Sleep ----SleepLogSaved-----> Goals, Dashboard, DayScore
Mental ---MoodLogged--------> Goals, Dashboard, DayScore
Goals ----GoalProgress------> Dashboard
```

---

## Provider Hierarchy (DAG Levels)

```
Level 0 -- Core Infrastructure (no dependencies)
  AppDatabase, EventBus, NotificationService, HapticService,
  SecureStorageService, BackupService, ExerciseLibraryService,
  ThemeNotifier, all DAOs, API clients, Repositories

Level 1 -- Feature Notifiers (depend on Core only)
  FinanceNotifier, GymNotifier, NutritionNotifier, HabitsNotifier,
  SleepNotifier, MentalNotifier, GoalsNotifier, AINotifier,
  OnboardingNotifier

Level 2 -- Aggregation Notifiers (depend on Core + Level 1)
  DayScoreNotifier

Level 3 -- Display Notifiers (depend on Core + Level 1 + Level 2)
  DashboardNotifier
```

### Dependency Rules

1. A module at Level N may only depend on modules at Level < N
2. Same-level modules communicate exclusively via EventBus
3. DAOs are Level 0 (instantiated from AppDatabase, no cross-deps)
4. Repositories are Level 0 (compose DAO + API client, no Notifier deps)

---

## Database Overview (35 Tables)

| Module | Tables |
|--------|--------|
| Core | app_settings |
| Finance | transactions, categories, budgets, savings_goals, recurring_transactions |
| Gym | exercises, routines, routine_exercises, workouts, workout_sets, body_measurements |
| Nutrition | food_items, meal_logs, meal_log_items, meal_templates, nutrition_goals, water_logs |
| Habits | habits, habit_logs |
| Sleep | sleep_logs, sleep_interruptions, energy_logs |
| Mental | mood_logs, breathing_sessions |
| Goals | life_goals, sub_goals, goal_milestones |
| Intelligence | ai_configurations, ai_conversations, ai_messages |
| DayScore | day_scores, score_components, day_score_configs, life_snapshots |

---

## Navigation Structure (go_router)

```
/                        --> DashboardScreen (or /onboarding if first launch)
/onboarding              --> OnboardingFlow (welcome, modules, preferences)
/finance                 --> TransactionsListScreen
/finance/add             --> AddEditTransactionScreen
/finance/budgets         --> BudgetOverviewScreen
/finance/savings         --> SavingsGoalsScreen
/gym                     --> ExerciseLibraryScreen
/gym/routines            --> RoutineBuilderScreen
/gym/workout             --> ActiveWorkoutScreen
/gym/history             --> WorkoutHistoryScreen
/gym/measurements        --> BodyMeasurementsScreen
/nutrition               --> DailyNutritionScreen
/nutrition/search        --> FoodSearchScreen
/nutrition/meal          --> MealLogScreen
/nutrition/goals         --> NutritionGoalsScreen
/habits                  --> HabitsDashboardScreen
/habits/add              --> AddEditHabitScreen
/habits/:id              --> HabitDetailScreen
/sleep                   --> SleepLogScreen
/sleep/history           --> SleepHistoryScreen
/sleep/energy            --> EnergyTrackerScreen
/mental                  --> MoodLogScreen
/mental/breathing        --> BreathingScreen
/mental/history          --> MentalHistoryScreen
/goals                   --> GoalsOverviewScreen
/goals/add               --> AddEditGoalScreen
/goals/:id               --> GoalDetailScreen
/intelligence            --> ConversationListScreen
/intelligence/config     --> AIConfigurationScreen
/intelligence/chat/:id   --> ChatScreen
/score                   --> DayScoreScreen
/score/history           --> ScoreHistoryScreen
/settings                --> SettingsScreen (theme, notifications, backup, about)
```

---

## Detailed Documentation References

| Document | Path | Contents |
|----------|------|----------|
| Component Definitions | `components.md` | Full module descriptions, responsibilities, tables, screens |
| Component Methods | `component-methods.md` | DAO/Repository/Notifier method signatures for all modules |
| Service Layer | `services.md` | EventBus, Notification, Haptic, SecureStorage, Backup, ExerciseLibrary, Theme |
| Dependency Map | `component-dependency.md` | Dependency matrix, DAG levels, event flow diagrams, provider registry |
