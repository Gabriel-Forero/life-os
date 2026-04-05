# LifeOS — Units of Work

## Purpose

Defines the 9 development units for the LifeOS Flutter monolith. Each unit represents a cohesive set of modules that can be designed, built, tested, and reviewed as a single increment through the full Construction phase.

---

## Unit Summary

| Unit | Name | Modules | Drift Tables | Stories | Phase | Build Order |
|---|---|---|---|---|---|---|
| 0 | Core Foundation | Core (DB, router, theme, services, EventBus, error handling, shared widgets) | 1 (AppSettings) | 7 (ONB) | MVP | First -- no dependencies |
| 1 | Finance | Finance (Transactions, Categories, Budgets, SavingsGoals, RecurringTransactions) | 5 | 14 (FIN) | MVP | After Unit 0 |
| 2 | Gym | Gym (Exercises, Routines, RoutineExercises, Workouts, WorkoutSets, BodyMeasurements) | 6 | 15 (GYM) | MVP | After Unit 0 |
| 3 | Nutrition | Nutrition (FoodItems, MealLogs, MealLogItems, MealTemplates, NutritionGoals, WaterLogs) + NutritionRepository (Open Food Facts) | 6 | 11 (NUT) | MVP | After Unit 0 |
| 4 | Habits | Habits (Habits, HabitLogs) | 2 | 10 (HAB) | MVP | After Unit 0 |
| 5 | Dashboard + DayScore | Dashboard (reads from other Notifiers), DayScore (DayScores, ScoreComponents, DayScoreConfigs, LifeSnapshots), Notifications | 4 | 4 (DASH) | MVP | After Units 1-4 |
| 6 | Sleep + Mental Wellness | Sleep (SleepLogs, SleepInterruptions, EnergyLogs) + Mental (MoodLogs, BreathingSessions) | 5 | 17 (SLP + MNT) | Phase 2 | After Unit 0 |
| 7 | Goals | Goals (LifeGoals, SubGoals, GoalMilestones) | 3 | 7 (GOAL) | Phase 2 | After Units 1-6 |
| 8 | Integration + Intelligence | Cross-module EventBus subscription wiring, DayScore subscriptions, Intelligence (AIConfigurations, AIConversations, AIMessages) + AIRepository | 3 | 7 (INT) | Post-modules | After all other units |

**Totals**: 9 units, 35 Drift tables, 92 stories

---

## Unit 0: Core Foundation

**Purpose**: Establish the shared infrastructure layer that every feature module depends on, and deliver the onboarding experience so the app is launchable from day one.

**Modules Included**: Core, Onboarding

**Phase**: MVP

**Estimated Complexity**: High (foundational -- everything else depends on this being correct)

### Drift Tables

| Table | Description |
|---|---|
| `app_settings` | Stores locale, theme variant, currency, user name, first-launch flag, notification preferences, and active module list |

### Key Responsibilities

- Initialize and provide the single Drift `AppDatabase` instance with all table definitions
- Configure `go_router` with shell route structure and all module route stubs
- Define the custom dark theme (`ThemeData`) and `ThemeNotifier`
- Implement cross-cutting services: EventBus (StreamController broadcast with typed events), NotificationService, HapticService, SecureStorageService, BackupService, ExerciseLibraryService
- Define the `Result<T>` type and `AppFailure` sealed class for business error handling
- Build shared widgets library: cards, chart wrappers, date pickers, empty states, swipe actions, progress bars
- Provide extension methods on `DateTime`, `num`, `String`
- Define all EventBus event types (sealed class `AppEvent` with 7 subclasses: `WorkoutCompletedEvent`, `ExpenseAddedEvent`, `BudgetThresholdEvent`, `HabitCheckedInEvent`, `SleepLogSavedEvent`, `MoodLoggedEvent`, `GoalProgressUpdatedEvent`)
- Implement the full onboarding wizard: welcome screen, language selection, name input, module selection, currency selection, guided tour, and first empty states
- Set up localization infrastructure with `intl` + ARB files (ES + EN)
- Configure Riverpod `ProviderScope` and all Level 0 providers

### Data Layer Pattern

DAO direct -- `AppSettings` table accessed via a lightweight provider, no full DAO class needed.

### Notifiers

| Notifier | Responsibility |
|---|---|
| `ThemeNotifier` | Manages theme variant selection |
| `OnboardingNotifier` | Drives the multi-step onboarding wizard, persists settings, triggers ExerciseLibraryService if Gym is enabled |

### UI Screens

| Screen | Description |
|---|---|
| `WelcomeScreen` | First-launch welcome with LifeOS branding and "Comenzar" button |
| `LanguageSelectionScreen` | Choose ES or EN with system language pre-selection |
| `NameInputScreen` | Enter user name with validation |
| `ModuleSelectionScreen` | Toggle modules on/off (minimum 1 required) |
| `CurrencySelectionScreen` | Search and select currency with COP default |
| `OnboardingTourScreen` | Brief guided tour adapted to selected modules |
| `MaterialApp.router` shell | App shell with bottom navigation and route configuration |

### EventBus

- **Events Emitted**: None (Core defines event types but does not emit domain events)
- **Events Subscribed**: None

### Dependencies

None -- this is the foundation unit with zero dependencies.

---

## Unit 1: Finance

**Purpose**: Deliver complete personal finance tracking with income/expense recording, category management, budget tracking with alerts, and financial charts.

**Modules Included**: Finance

**Phase**: MVP

**Estimated Complexity**: High (14 stories, 5 tables, charts, budget logic, recurring transactions)

### Drift Tables

| Table | Description |
|---|---|
| `transactions` | Income and expense records with amount, type, category, date, note, and recurring flag |
| `categories` | User-defined and predefined spending/income categories with icon, color, and type |
| `budgets` | Monthly budget amounts per category with threshold tracking |
| `savings_goals` | Named savings targets with amount, deadline, and progress tracking |
| `recurring_transactions` | Scheduled recurring transaction templates with frequency and next occurrence |

### Key Responsibilities

- CRUD for income and expense transactions (max 3-tap expense flow)
- Manage predefined categories (Alimentacion, Transporte, Entretenimiento, Salud, Hogar, Educacion, Ropa, Servicios, Otros) and custom categories with icon + color
- Transaction list with date grouping, scroll pagination, swipe-to-edit/delete with undo
- Monthly budget management with per-category allocation and threshold alerts (80% and 100%)
- Financial dashboard with balance, income vs. expenses summary
- Charts: pie chart by category, bar chart income vs. expenses, line chart savings trend
- Date range selector (predefined: this month, last month, custom range)
- Savings goals with target amount, deadline, and progress visualization (Post-MVP: FIN-14)
- Recurring transaction scheduling and notification (Post-MVP: FIN-15)
- Emit `ExpenseAddedEvent` on every expense transaction
- Emit `BudgetThresholdEvent` when utilization crosses 80% or 100%

### Data Layer Pattern

DAO direct -- `FinanceDao` performs all Drift queries. No external API dependency.

### Notifiers

| Notifier | Responsibility |
|---|---|
| `FinanceNotifier` | Manages transaction CRUD, budget calculations, category management, savings goals, recurring transactions. Emits EventBus events. |

### UI Screens

| Screen | Description |
|---|---|
| `TransactionsListScreen` | Chronological list with date grouping, swipe actions, date range filter |
| `AddEditTransactionScreen` | Form for income/expense with amount, category, note, recurring toggle |
| `BudgetOverviewScreen` | Monthly budget bars with per-category progress and alerts |
| `SavingsGoalsScreen` | Savings goal cards with progress bars and suggested monthly savings |

### EventBus

- **Events Emitted**: `ExpenseAddedEvent` (on expense add), `BudgetThresholdEvent` (on 80%/100% budget threshold crossing)
- **Events Subscribed**: None

### Dependencies

Unit 0 (Core Foundation) -- requires AppDatabase, EventBus, shared widgets, theme, router.

---

## Unit 2: Gym

**Purpose**: Deliver a complete workout tracking system with an exercise library, routine builder, real-time workout logging with rest timer, progress charts, PR detection, and body measurements.

**Modules Included**: Gym

**Phase**: MVP

**Estimated Complexity**: High (15 stories, 6 tables, real-time workout UI, exercise library download, PR algorithms)

### Drift Tables

| Table | Description |
|---|---|
| `exercises` | Exercise library entries with name, muscle group, equipment, instructions, custom/downloaded flags |
| `routines` | Named workout routines with description and creation date |
| `routine_exercises` | Junction table linking routines to exercises with sort order and default sets/reps/weight |
| `workouts` | Workout session records with optional routine reference, start/end timestamps, and note |
| `workout_sets` | Individual set records within a workout: exercise, set number, reps, weight, RIR, warmup flag |
| `body_measurements` | Periodic body measurement records: weight, body fat percentage, and circumference measurements |

### Key Responsibilities

- Pre-loaded exercise library with 200+ exercises (downloaded on first launch via ExerciseLibraryService)
- Exercise search and filter by muscle group and equipment
- CRUD for custom exercises with duplicate name validation
- Routine builder with drag-to-reorder, per-exercise sets/reps/rest configuration
- Start workout from routine (pre-fill with last session weights as reference)
- Start empty/freestyle workout with on-the-fly exercise addition
- Real-time set recording with weight (kg) and reps; bodyweight exercise support
- Rest timer with auto-start, countdown, adjustable duration (+30s), and haptic feedback at completion
- Mark sets as warmup (excluded from volume and PR calculations)
- Workout completion with summary: duration, exercises, total sets, total volume, new PRs
- Workout history list with date, routine name, duration, exercise count
- Exercise progress chart (weight max over time, toggleable to volume)
- Automatic PR detection (weight PR, rep PR at given weight) -- warmup excluded
- 1RM estimation using Epley formula (weight x (1 + reps/30))
- Body measurements recording and trend charts (Post-MVP: GYM-15)
- Emit `WorkoutCompletedEvent` on workout finish

### Data Layer Pattern

DAO direct -- `GymDao` performs all Drift queries. Exercise library downloaded via `ExerciseLibraryService` (Core).

### Notifiers

| Notifier | Responsibility |
|---|---|
| `GymNotifier` | Manages exercise library, routines, active workout state, set logging, PR detection, 1RM calculations, body measurements. Emits `WorkoutCompletedEvent`. |

### UI Screens

| Screen | Description |
|---|---|
| `ExerciseLibraryScreen` | Searchable, filterable exercise catalog with muscle group and equipment filters |
| `RoutineBuilderScreen` | Create/edit routines with drag-to-reorder exercises and default parameters |
| `ActiveWorkoutScreen` | Real-time workout logging with set entry, rest timer, warmup toggle, and live volume tracking |
| `WorkoutHistoryScreen` | Chronological workout list with detail drill-down showing all sets |
| `BodyMeasurementsScreen` | Log body metrics and view trend line charts |

### EventBus

- **Events Emitted**: `WorkoutCompletedEvent` (on workout finish)
- **Events Subscribed**: None

### Dependencies

Unit 0 (Core Foundation) -- requires AppDatabase, EventBus, ExerciseLibraryService, HapticService, shared widgets, theme, router.

---

## Unit 3: Nutrition

**Purpose**: Deliver food logging with Open Food Facts API integration, meal templates, daily macro goal tracking, and water intake management.

**Modules Included**: Nutrition + NutritionRepository (Open Food Facts API client)

**Phase**: MVP

**Estimated Complexity**: High (11 stories, 6 tables, API integration, barcode scanning, macro calculations)

### Drift Tables

| Table | Description |
|---|---|
| `food_items` | Cached food items from API or manually created, with barcode, name, brand, calories, protein, carbs, fat, serving size |
| `meal_logs` | Daily meal entries with date, meal type (breakfast/lunch/dinner/snack), and note |
| `meal_log_items` | Junction table linking meal logs to food items with quantity and serving unit |
| `meal_templates` | Saved meal combinations (name + meal type) for quick re-logging |
| `nutrition_goals` | Daily macro targets: calories, protein, carbs, fat, water (ml), with effective date |
| `water_logs` | Individual water intake records with date, amount (ml), and time |

### Key Responsibilities

- Quick meal logging (2-tap flow from favorites)
- Food item search via Open Food Facts API with local caching for offline use
- Barcode scanning for product lookup (Post-MVP: NUT-11)
- Add food to favorites for quick access
- Create custom food items with manual nutritional data
- Meal type selection with time-based auto-suggestion (breakfast/lunch/dinner/snack)
- Set daily macro goals (calories, protein, carbs, fat) with validation warning when macros do not sum to calorie target
- View macro progress bars (percentage of daily goal consumed)
- Water intake tracking with glass counter, increment/decrement, and daily goal
- Water reminders with smart postpone (skip if recently logged)
- Meal templates: save and reuse frequent meal combinations
- Listen to `ExpenseAddedEvent` to suggest meal logging when food-category expenses are recorded

### Data Layer Pattern

Repository -- `NutritionRepository` wraps `NutritionDao` (Drift DAO for local data) + `OpenFoodFactsClient` (HTTP client for API search and barcode lookup). The repository decides whether to fetch from API or return cached data.

### Notifiers

| Notifier | Responsibility |
|---|---|
| `NutritionNotifier` | Manages food search, meal logging, macro calculations, water tracking, templates, favorites. Subscribes to `ExpenseAddedEvent` and `WorkoutCompletedEvent`. |

### UI Screens

| Screen | Description |
|---|---|
| `DailyNutritionScreen` | Macro progress rings, meal list grouped by type, water tracker with glass counter |
| `FoodSearchScreen` | API search with results, barcode scanner button, favorites tab, recent items |
| `MealLogScreen` | Add/edit meal with food item selection, quantity adjustment, and meal type |
| `NutritionGoalsScreen` | Set/edit daily calorie and macro targets |

### EventBus

- **Events Emitted**: None (Nutrition is a consumer, not an emitter in the current design)
- **Events Subscribed**: `ExpenseAddedEvent` (correlate food-category expenses, suggest meal log), `WorkoutCompletedEvent` (suggest post-workout meal, adjust training day macros)

### Dependencies

Unit 0 (Core Foundation) -- requires AppDatabase, EventBus, NotificationService, shared widgets, theme, router.

---

## Unit 4: Habits

**Purpose**: Deliver daily habit tracking with flexible frequency scheduling, streak calculation, quantitative check-ins, calendar visualization, and statistics.

**Modules Included**: Habits

**Phase**: MVP

**Estimated Complexity**: Medium (10 stories, 2 tables, streak algorithm, calendar view)

### Drift Tables

| Table | Description |
|---|---|
| `habits` | Habit definitions with name, icon, color, frequency type, target per period, days of week, archive status |
| `habit_logs` | Daily completion records linking to a habit with date, completion timestamp, and optional numeric value for quantitative habits |

### Key Responsibilities

- CRUD for habits with name, icon, color, and frequency (daily, weekly, custom days)
- Configurable reminder notifications per habit with smart skip (suppress if already completed)
- One-tap daily check-in with satisfying animation
- Quantitative check-in for measurable habits (pages read, steps walked) with partial progress tracking
- Streak calculation: current streak and best streak for both daily and weekly habits
- Calendar view with color-coded days (green = completed, red = missed, gray = not applicable, yellow = pending today)
- Statistics: completion percentage, best streak, current streak
- Edit and delete habits with streak-aware deletion warning
- Activate/deactivate habits (pause without losing history)
- View inactive habits separately with reactivation option
- Emit `HabitCheckedInEvent` on check-in
- Listen to `WorkoutCompletedEvent` for auto-checking gym-related habits

### Data Layer Pattern

DAO direct -- `HabitsDao` performs all Drift queries. No external API dependency.

### Notifiers

| Notifier | Responsibility |
|---|---|
| `HabitsNotifier` | Manages habit CRUD, check-in recording, streak computation, statistics aggregation. Emits `HabitCheckedInEvent`. Subscribes to `WorkoutCompletedEvent` for auto-check. |

### UI Screens

| Screen | Description |
|---|---|
| `HabitsDashboardScreen` | Today's habits with one-tap check-in toggles, streak badges, and quantitative entry |
| `AddEditHabitScreen` | Form for habit creation/editing with frequency, reminder, icon, and color pickers |
| `HabitDetailScreen` | Individual habit view with calendar, streak counter, and completion statistics |

### EventBus

- **Events Emitted**: `HabitCheckedInEvent` (on check-in)
- **Events Subscribed**: `WorkoutCompletedEvent` (auto-check gym-related habits)

### Dependencies

Unit 0 (Core Foundation) -- requires AppDatabase, EventBus, NotificationService, shared widgets, theme, router.

---

## Unit 5: Dashboard + DayScore

**Purpose**: Deliver the unified dashboard that aggregates data from all active modules, the DayScore composite scoring system, and the notification summary layer.

**Modules Included**: Dashboard, DayScore, Notifications integration

**Phase**: MVP

**Estimated Complexity**: Medium (4 stories, 4 tables, but heavy read integration with all prior units)

### Drift Tables

| Table | Description |
|---|---|
| `day_scores` | Daily composite score records (0-100) with calculation timestamp |
| `score_components` | Individual module contributions to a day score, with raw value, weight, and weighted score |
| `day_score_configs` | Per-module scoring configuration: weight, enabled flag, and scoring rule |
| `life_snapshots` | Periodic summaries capturing total score and key metrics as JSON |

### Key Responsibilities

- Unified dashboard displaying today's key metrics from all active modules
- Time-of-day greeting ("Buenos dias, [Name]" / "Buenas tardes" / "Buenas noches")
- Quick action buttons that adapt to active modules (add transaction, start workout, check-in habit)
- Dashboard layout adapts automatically when modules are activated/deactivated
- Notification summary area showing pending alerts (budget thresholds, pending habits)
- DayScore calculation: composite 0-100 score from module-specific components with configurable weights
- Score component breakdown (ring chart showing each module's contribution)
- Score history with trend line and heatmap calendar
- Life snapshots for periodic summaries
- Listen to `BudgetThresholdEvent` for budget alert cards
- Listen to `HabitCheckedInEvent`, `GoalProgressUpdatedEvent` for live dashboard refreshes
- Read from `FinanceNotifier`, `GymNotifier`, `NutritionNotifier`, `HabitsNotifier` via Riverpod for real-time metric display

### Data Layer Pattern

DAO direct -- `DayScoreDao` for score persistence. Dashboard module has no tables of its own (reads from other Notifiers).

### Notifiers

| Notifier | Responsibility |
|---|---|
| `DayScoreNotifier` | Calculates composite daily score from module data, manages score configurations, persists scores and snapshots |
| `DashboardNotifier` | Aggregates cross-module data for display, manages notification summary, handles quick action routing |

### UI Screens

| Screen | Description |
|---|---|
| `DashboardScreen` | Scrollable card-based overview with greeting, DayScore, module metric cards, quick actions, notification summary |
| `DayScoreScreen` | Today's score with component breakdown ring chart |
| `ScoreHistoryScreen` | Score trend line chart and heatmap calendar |

### EventBus

- **Events Emitted**: None
- **Events Subscribed**: `BudgetThresholdEvent` (show budget alert card), `HabitCheckedInEvent` (refresh habit summary), `GoalProgressUpdatedEvent` (refresh goal highlights)

### Dependencies

- Unit 0 (Core Foundation) -- requires AppDatabase, EventBus, NotificationService, shared widgets, theme, router
- Unit 1 (Finance) -- reads from `FinanceNotifier` for balance, budget status
- Unit 2 (Gym) -- reads from `GymNotifier` for last workout summary
- Unit 3 (Nutrition) -- reads from `NutritionNotifier` for daily calorie/macro progress
- Unit 4 (Habits) -- reads from `HabitsNotifier` for today's habit completion status

---

## Unit 6: Sleep + Mental Wellness

**Purpose**: Deliver sleep tracking with interruption logging and energy assessment, plus mental wellness tracking with mood logging and guided breathing exercises. These two modules share similar daily tracking patterns and UI structures.

**Modules Included**: Sleep, Mental

**Phase**: Phase 2

**Estimated Complexity**: High (17 stories across 2 modules, 5 tables, sleep timeline UI, breathing animations)

### Drift Tables

| Table | Description |
|---|---|
| `sleep_logs` | Nightly sleep records with bed time, wake time, quality rating (1-5), and note |
| `sleep_interruptions` | Interruptions within a sleep session with time, duration, and optional reason |
| `energy_logs` | Energy level check-ins (1-10 scale) at morning, afternoon, and evening with timestamp and note |
| `mood_logs` | Mood entries with emotion, intensity (1-10), comma-separated trigger tags, and optional journal note |
| `breathing_sessions` | Guided breathing session records with technique name, duration, and completion status |

### Key Responsibilities

**Sleep Module:**
- Record bedtime with "Me voy a dormir" button and timestamp
- Set estimated fall-asleep time (configurable default, per-session override)
- Wake-up semi-auto-detection via phone unlock notification
- Record sleep interruptions (in-moment or retroactive) with reason
- Morning retroactive review with editable timeline visualization
- Sleep quality rating (1-5 stars)
- Sleep score calculation (0-100 based on duration, interruptions, quality)
- Sleep history with weekly bar charts and monthly trends
- Energy check-in 3x/day (morning, afternoon, evening) with correlation to sleep
- HealthKit/Health Connect import for smartwatch sleep data
- Emit `SleepLogSavedEvent` on sleep log completion

**Mental Wellness Module:**
- Quick mood check-in with 1-5 scale (emotion faces)
- Mood tags selection (Motivado, Estresado, Ansioso, Tranquilo, Feliz, Triste, Enojado, Agradecido, Energetico, Agotado)
- Mini journaling (1-3 sentences, 280 char soft limit)
- Gratitude entry (1-3 items per day)
- Guided breathing exercises: box breathing (4-4-4-4), 4-7-8, with visual animation and haptic transitions
- Customizable breathing session duration (default 3 min)
- Mood calendar view with color-coded days
- Breathing session history with streak tracking
- Emit `MoodLoggedEvent` on mood check-in

### Data Layer Pattern

DAO direct -- `SleepDao` and `MentalDao` perform all Drift queries. No external API dependency (HealthKit/Health Connect integration uses platform channels, not a REST API).

### Notifiers

| Notifier | Responsibility |
|---|---|
| `SleepNotifier` | Manages sleep logging, interruptions, energy check-ins, sleep score calculation, HealthKit import. Emits `SleepLogSavedEvent`. |
| `MentalNotifier` | Manages mood logging, tags, journaling, gratitude entries, breathing sessions. Emits `MoodLoggedEvent`. |

### UI Screens

| Screen | Description |
|---|---|
| `SleepLogScreen` | Bedtime button, morning review timeline, quality rating, interruption management |
| `SleepHistoryScreen` | Weekly/monthly sleep duration and quality trend charts, sleep score history |
| `EnergyTrackerScreen` | 3x daily energy level entry with sleep correlation chart |
| `MoodLogScreen` | Quick mood entry with emotion picker, tag selection, mini journal, gratitude |
| `BreathingScreen` | Guided breathing with technique selection, visual animation, haptic feedback, and timer |
| `MentalHistoryScreen` | Mood calendar, mood trends, tag frequency ranking, breathing session history |

### EventBus

- **Events Emitted**: `SleepLogSavedEvent` (on sleep log save), `MoodLoggedEvent` (on mood check-in)
- **Events Subscribed**: None

### Dependencies

Unit 0 (Core Foundation) -- requires AppDatabase, EventBus, HapticService, NotificationService, shared widgets, theme, router.

---

## Unit 7: Goals

**Purpose**: Deliver life goal management with hierarchical sub-goals, weighted progress calculation, milestones, and cross-module progress tracking.

**Modules Included**: Goals

**Phase**: Phase 2

**Estimated Complexity**: High (7 stories, 3 tables, cross-module progress linkage, weighted calculation logic)

### Drift Tables

| Table | Description |
|---|---|
| `life_goals` | Top-level life goals with name, description, category, target date, status (active/completed/paused/abandoned), progress (0-100), and optional parent reference |
| `sub_goals` | Child goals linked to a parent with name, description, status, module link, and sort order |
| `goal_milestones` | Named milestone checkpoints within a goal with target date and completion tracking |

### Key Responsibilities

- CRUD for life goals with name, icon, color, and optional deadline
- Sub-goal decomposition with optional module linkage (Finance savings goal, Habits streak, etc.)
- Sub-goal weight assignment (must sum to 100%; defaults to equal distribution)
- Weighted progress calculation: total goal progress = sum of (sub-goal progress x weight)
- Milestone management with target dates, completion marking, and overdue detection
- Goal detail view with sub-goal list, milestone timeline, and progress trend chart
- Goal dashboard with all active goals as progress cards, sortable by deadline
- Listen to `HabitCheckedInEvent` for auto-progress on habit-linked sub-goals
- Listen to `SleepLogSavedEvent` for auto-progress on sleep-linked sub-goals
- Listen to `MoodLoggedEvent` for auto-progress on wellness-linked sub-goals
- Emit `GoalProgressUpdatedEvent` on progress changes

### Data Layer Pattern

DAO direct -- `GoalsDao` performs all Drift queries. Cross-module data accessed via EventBus subscriptions.

### Notifiers

| Notifier | Responsibility |
|---|---|
| `GoalsNotifier` | Manages goal CRUD, sub-goal management, weight validation, weighted progress calculation, milestone tracking. Subscribes to module events for auto-progress. Emits `GoalProgressUpdatedEvent`. |

### UI Screens

| Screen | Description |
|---|---|
| `GoalsOverviewScreen` | Dashboard of all active goals as cards with progress bars, sortable by deadline |
| `GoalDetailScreen` | Full goal view with sub-goals, milestones timeline, progress trend chart, and edit actions |
| `AddEditGoalScreen` | Form for goal creation/editing with sub-goal builder, weight allocation, and milestone addition |

### EventBus

- **Events Emitted**: `GoalProgressUpdatedEvent` (on progress update or milestone completion)
- **Events Subscribed**: `HabitCheckedInEvent` (auto-progress habit-linked sub-goals), `SleepLogSavedEvent` (auto-progress sleep-linked sub-goals), `MoodLoggedEvent` (auto-progress wellness-linked sub-goals)

### Dependencies

- Unit 0 (Core Foundation) -- requires AppDatabase, EventBus, shared widgets, theme, router
- Unit 1 (Finance) -- sub-goals may link to Finance savings goals
- Unit 2 (Gym) -- sub-goals may reference workout frequency
- Unit 3 (Nutrition) -- sub-goals may reference nutrition targets
- Unit 4 (Habits) -- sub-goals may link to habit streaks (primary integration)
- Unit 5 (Dashboard + DayScore) -- goal progress feeds into DayScore
- Unit 6 (Sleep + Mental Wellness) -- sub-goals may link to sleep/mood targets

---

## Unit 8: Integration + Intelligence

**Purpose**: Wire all cross-module EventBus subscriptions end-to-end, implement DayScore event-driven recalculation, and deliver the AI-powered Intelligence module for insights and conversations.

**Modules Included**: Cross-module EventBus subscription wiring, DayScore event subscriptions, Intelligence (AI module)

**Phase**: Post-modules

**Estimated Complexity**: High (7 stories, 3 tables, API integration with multiple AI providers, end-to-end integration testing)

### Drift Tables

| Table | Description |
|---|---|
| `ai_configurations` | AI provider configs with provider name, model name, and default flag (API keys stored in SecureStorageService) |
| `ai_conversations` | Conversation threads with title, linked configuration, and timestamps |
| `ai_messages` | Individual messages within conversations with role (user/assistant/system), content, timestamp, and token count |

### Key Responsibilities

**Cross-Module Integration Wiring:**
- Wire `WorkoutCompletedEvent` subscriptions: HabitsNotifier (auto-check gym habits), NutritionNotifier (suggest post-workout meal), DayScoreNotifier (recalculate score)
- Wire `ExpenseAddedEvent` subscriptions: NutritionNotifier (food-expense correlation suggestion)
- Wire `BudgetThresholdEvent` subscriptions: DashboardNotifier (budget alert card), NotificationService (push notification)
- Wire `HabitCheckedInEvent` subscriptions: GoalsNotifier (auto-progress), DashboardNotifier (refresh), DayScoreNotifier (recalculate)
- Wire `SleepLogSavedEvent` subscriptions: GoalsNotifier (auto-progress), DashboardNotifier (refresh), DayScoreNotifier (recalculate)
- Wire `MoodLoggedEvent` subscriptions: GoalsNotifier (auto-progress), DashboardNotifier (refresh), DayScoreNotifier (recalculate)
- Wire `GoalProgressUpdatedEvent` subscriptions: DashboardNotifier (refresh goal highlights)
- Full end-to-end testing of all event flows

**DayScore Event-Driven Subscriptions:**
- Subscribe DayScoreNotifier to all relevant events for automatic score recalculation
- Ensure score updates propagate to DashboardNotifier in real-time

**Intelligence Module:**
- AI provider configuration management (OpenAI, Anthropic, local models)
- API key storage via SecureStorageService
- Conversation history with context management
- Send prompts to configured AI providers and stream responses
- Store conversations and messages locally for history
- Data export (JSON backup) and import (restore from backup) for all modules
- Module-specific and full export/import via BackupService

### Data Layer Pattern

Repository -- `AIRepository` wraps `AIDao` (Drift DAO for conversation/message persistence) + `AIProviderClients` (HTTP clients for AI API calls). API keys retrieved from `SecureStorageService`.

### Notifiers

| Notifier | Responsibility |
|---|---|
| `AINotifier` | Manages AI configuration, conversations, message streaming, and response handling |

### UI Screens

| Screen | Description |
|---|---|
| `AIConfigurationScreen` | Provider setup with model selection, API key input, and default provider toggle |
| `ConversationListScreen` | List of past AI conversations with title, date, and message count |
| `ChatScreen` | Streaming chat interface with user/assistant message bubbles and token tracking |

### EventBus

- **Events Emitted**: None (this unit wires subscriptions, it does not define new events)
- **Events Subscribed**: All events -- this unit implements and tests the full subscription graph across all modules

### Dependencies

All prior units (0-7) -- this is the final integration unit that requires every module to be built and functional.

---

## Code Organization Strategy

LifeOS follows a feature-first monolith structure where each module owns its complete vertical slice (data, domain, presentation, providers). The shared Drift database is defined in Core with tables registered per module.

### Flutter Project Structure

```
lib/
  main.dart                         # App entry point, ProviderScope, MaterialApp.router
  core/                             # Unit 0: Core Foundation
    database/
      app_database.dart             # Drift AppDatabase with all table registrations
      app_database.g.dart           # Generated Drift code
      tables/
        app_settings_table.dart     # AppSettings table definition
    router/
      app_router.dart               # go_router configuration with all routes
    theme/
      app_theme.dart                # Dark theme definition
      theme_notifier.dart           # Theme state management
    services/
      event_bus.dart                # EventBus (StreamController broadcast)
      event_types.dart              # Sealed class AppEvent + 7 event subclasses
      notification_service.dart     # Local notification management
      haptic_service.dart           # Haptic feedback abstraction
      secure_storage_service.dart   # Encrypted key-value storage
      backup_service.dart           # JSON export/import
      exercise_library_service.dart # Exercise library download and caching
    error/
      app_failure.dart              # AppFailure sealed class (business errors)
      result.dart                   # Result<T> type (Success | Failure)
    widgets/
      app_card.dart                 # Reusable card component
      chart_wrapper.dart            # Chart container with common styling
      date_picker.dart              # Styled date picker
      empty_state.dart              # Empty state with illustration and CTA
      swipe_action.dart             # Swipe-to-edit/delete widget
      progress_bar.dart             # Animated progress bar
    extensions/
      date_extensions.dart          # DateTime utility methods
      num_extensions.dart           # Number formatting
      string_extensions.dart        # String utilities
    l10n/
      intl_es.arb                   # Spanish translations
      intl_en.arb                   # English translations
    providers/
      core_providers.dart           # Level 0 providers (DB, services, DAOs)
  features/
    onboarding/                     # Unit 0: Onboarding (part of Core Foundation)
      presentation/
        welcome_screen.dart
        language_selection_screen.dart
        name_input_screen.dart
        module_selection_screen.dart
        currency_selection_screen.dart
        onboarding_tour_screen.dart
      providers/
        onboarding_notifier.dart
    finance/                        # Unit 1: Finance
      data/
        finance_dao.dart            # Drift DAO with all Finance queries
        tables/
          transactions_table.dart
          categories_table.dart
          budgets_table.dart
          savings_goals_table.dart
          recurring_transactions_table.dart
      domain/
        finance_models.dart         # Domain models (Transaction, Category, Budget, etc.)
      presentation/
        transactions_list_screen.dart
        add_edit_transaction_screen.dart
        budget_overview_screen.dart
        savings_goals_screen.dart
        widgets/                    # Finance-specific widgets (pie chart, bar chart, etc.)
      providers/
        finance_notifier.dart
    gym/                            # Unit 2: Gym
      data/
        gym_dao.dart
        tables/
          exercises_table.dart
          routines_table.dart
          routine_exercises_table.dart
          workouts_table.dart
          workout_sets_table.dart
          body_measurements_table.dart
      domain/
        gym_models.dart
      presentation/
        exercise_library_screen.dart
        routine_builder_screen.dart
        active_workout_screen.dart
        workout_history_screen.dart
        body_measurements_screen.dart
        widgets/
      providers/
        gym_notifier.dart
    nutrition/                      # Unit 3: Nutrition
      data/
        nutrition_dao.dart
        nutrition_repository.dart   # Wraps DAO + OpenFoodFactsClient
        api/
          open_food_facts_client.dart
        tables/
          food_items_table.dart
          meal_logs_table.dart
          meal_log_items_table.dart
          meal_templates_table.dart
          nutrition_goals_table.dart
          water_logs_table.dart
      domain/
        nutrition_models.dart
      presentation/
        daily_nutrition_screen.dart
        food_search_screen.dart
        meal_log_screen.dart
        nutrition_goals_screen.dart
        widgets/
      providers/
        nutrition_notifier.dart
    habits/                         # Unit 4: Habits
      data/
        habits_dao.dart
        tables/
          habits_table.dart
          habit_logs_table.dart
      domain/
        habits_models.dart
      presentation/
        habits_dashboard_screen.dart
        add_edit_habit_screen.dart
        habit_detail_screen.dart
        widgets/
      providers/
        habits_notifier.dart
    dashboard/                      # Unit 5: Dashboard
      presentation/
        dashboard_screen.dart
        widgets/
      providers/
        dashboard_notifier.dart
    day_score/                      # Unit 5: DayScore
      data/
        day_score_dao.dart
        tables/
          day_scores_table.dart
          score_components_table.dart
          day_score_configs_table.dart
          life_snapshots_table.dart
      domain/
        day_score_models.dart
      presentation/
        day_score_screen.dart
        score_history_screen.dart
        widgets/
      providers/
        day_score_notifier.dart
    sleep/                          # Unit 6: Sleep
      data/
        sleep_dao.dart
        tables/
          sleep_logs_table.dart
          sleep_interruptions_table.dart
          energy_logs_table.dart
      domain/
        sleep_models.dart
      presentation/
        sleep_log_screen.dart
        sleep_history_screen.dart
        energy_tracker_screen.dart
        widgets/
      providers/
        sleep_notifier.dart
    mental/                         # Unit 6: Mental
      data/
        mental_dao.dart
        tables/
          mood_logs_table.dart
          breathing_sessions_table.dart
      domain/
        mental_models.dart
      presentation/
        mood_log_screen.dart
        breathing_screen.dart
        mental_history_screen.dart
        widgets/
      providers/
        mental_notifier.dart
    goals/                          # Unit 7: Goals
      data/
        goals_dao.dart
        tables/
          life_goals_table.dart
          sub_goals_table.dart
          goal_milestones_table.dart
      domain/
        goals_models.dart
      presentation/
        goals_overview_screen.dart
        goal_detail_screen.dart
        add_edit_goal_screen.dart
        widgets/
      providers/
        goals_notifier.dart
    intelligence/                   # Unit 8: Intelligence
      data/
        ai_dao.dart
        ai_repository.dart          # Wraps AIDao + AIProviderClients
        api/
          ai_provider_clients.dart  # OpenAI, Anthropic, etc.
        tables/
          ai_configurations_table.dart
          ai_conversations_table.dart
          ai_messages_table.dart
      domain/
        ai_models.dart
      presentation/
        ai_configuration_screen.dart
        conversation_list_screen.dart
        chat_screen.dart
        widgets/
      providers/
        ai_notifier.dart
```

### Key Structural Conventions

- **Shared Drift database**: Defined once in `core/database/app_database.dart`. Each feature's table definitions are imported and registered in the database class annotation. This ensures a single SQLite file with all tables.
- **Feature isolation**: Each feature under `lib/features/` is self-contained with `data/`, `domain/`, `presentation/`, and `providers/` subdirectories. Features never import directly from another feature's `data/` or `presentation/` -- cross-module communication uses EventBus or Riverpod provider watching (only for Level 2+ aggregators).
- **Provider hierarchy**: Level 0 providers in `core/providers/`. Level 1 providers in each feature's `providers/`. Level 2 (DayScore) and Level 3 (Dashboard) providers explicitly declare their cross-module dependencies.
- **Table registration**: Each feature's `tables/` directory defines Drift table classes. These are all imported and listed in the `@DriftDatabase(tables: [...])` annotation in `app_database.dart`.
