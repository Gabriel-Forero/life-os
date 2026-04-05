# Component Definitions

## Purpose

Defines every module/feature in LifeOS with its responsibilities, data layer, state layer, and UI screens. LifeOS is organized as a feature-first Flutter project where each module owns its own DAO/Repository, Notifier, models, and screens.

---

## Component Summary

| # | Module | Type | Data Layer | Tables | Screens |
|---|--------|------|------------|--------|---------|
| 1 | Core | Shared infrastructure | Drift DB, Services | 0 | 0 |
| 2 | Finance | Local-only | FinanceDao | 5 | 4 |
| 3 | Gym | Local-only | GymDao | 6 | 5 |
| 4 | Nutrition | Hybrid (API) | NutritionDao + OpenFoodFactsClient → NutritionRepository | 6 | 4 |
| 5 | Habits | Local-only | HabitsDao | 2 | 3 |
| 6 | Sleep | Local-only | SleepDao | 3 | 3 |
| 7 | Mental | Local-only | MentalDao | 2 | 3 |
| 8 | Goals | Local-only | GoalsDao | 3 | 3 |
| 9 | Intelligence | Hybrid (API) | AIDao + AIProviderClients → AIRepository | 3 | 3 |
| 10 | DayScore | Local-only | DayScoreDao | 4 | 2 |
| 11 | Dashboard | Read-only composite | None (reads other Notifiers) | 0 | 1 |
| 12 | Onboarding | Local-only | AppSettings (Drift) | 0* | 3 |

*Onboarding reads/writes the shared AppSettings table managed by Core.

**Total Drift tables: ~34** (Finance 5 + Gym 6 + Nutrition 6 + Habits 2 + Sleep 3 + Mental 2 + Goals 3 + Intelligence 3 + DayScore 4 = 34, plus AppSettings in Core = 35)

---

## 1. Core

**Purpose**: Shared infrastructure that all feature modules depend on. Owns the Drift database instance, routing, theme, and cross-cutting services.

**Responsibilities**:
- Initialize and provide the single Drift `AppDatabase` instance
- Define the `go_router` configuration with all module routes
- Provide the custom dark theme (`ThemeData`)
- Host cross-cutting services: EventBus, NotificationService, HapticService, SecureStorageService, BackupService, ExerciseLibraryService
- Shared widgets (cards, charts, buttons, date pickers, empty states)
- Extension methods on `DateTime`, `num`, `String`
- AppSettings table (locale, theme variant, first-launch flag, notification prefs)

**Data Layer**: Drift `AppDatabase` (singleton, provided via Riverpod). Contains the `AppSettings` table (1 table).

**State Layer**: No dedicated Notifier. Settings accessed via `appSettingsProvider`.

**UI Screens**: None directly. Provides the `MaterialApp.router` shell.

---

## 2. Finance

**Purpose**: Personal finance tracking -- income, expenses, budgets, savings goals, and recurring transactions.

**Responsibilities**:
- CRUD for transactions (income/expense with amount, category, date, note)
- Manage spending categories (user-defined, with icon + color)
- Budget tracking per category per month with threshold alerts
- Savings goals with target amounts and deadlines
- Recurring transaction scheduling (daily/weekly/monthly/yearly)
- Emit `ExpenseAddedEvent` and `BudgetThresholdEvent` via EventBus
- Summary calculations: monthly totals, category breakdowns, budget utilization

**Data Layer**: `FinanceDao` (direct Drift DAO)

| Table | Key Columns |
|-------|-------------|
| `transactions` | id, amount, type(income/expense), categoryId, date, note, isRecurring |
| `categories` | id, name, icon, color, type(income/expense), isDefault |
| `budgets` | id, categoryId, amount, month, year |
| `savings_goals` | id, name, targetAmount, currentAmount, deadline, icon |
| `recurring_transactions` | id, transactionTemplateId, frequency, nextOccurrence, isActive |

**State Layer**: `FinanceNotifier` (AsyncNotifier)

**UI Screens**:
- TransactionsListScreen (filterable by date range, category, type)
- AddEditTransactionScreen
- BudgetOverviewScreen (per-month budget bars)
- SavingsGoalsScreen

---

## 3. Gym

**Purpose**: Workout tracking with an exercise library, custom routines, workout logging, and body measurement history.

**Responsibilities**:
- Provide a pre-loaded exercise library (downloaded on first launch via ExerciseLibraryService)
- CRUD for custom exercises
- Build routines from exercises (ordered, with default sets/reps/weight)
- Log workouts: start/end time, exercises performed, sets with reps + weight + RIR
- Track body measurements over time (weight, body fat, arm, chest, etc.)
- Emit `WorkoutCompletedEvent` via EventBus
- Computed stats: volume per muscle group, PRs, workout frequency

**Data Layer**: `GymDao` (direct Drift DAO)

| Table | Key Columns |
|-------|-------------|
| `exercises` | id, name, muscleGroup, equipment, instructions, isCustom, isDownloaded |
| `routines` | id, name, description, createdAt |
| `routine_exercises` | id, routineId, exerciseId, sortOrder, defaultSets, defaultReps, defaultWeight |
| `workouts` | id, routineId (nullable), startedAt, finishedAt, note |
| `workout_sets` | id, workoutId, exerciseId, setNumber, reps, weight, rir, isWarmup |
| `body_measurements` | id, date, weight, bodyFat, neck, chest, arm, waist, hip, thigh, calf |

**State Layer**: `GymNotifier` (AsyncNotifier)

**UI Screens**:
- ExerciseLibraryScreen (search, filter by muscle group)
- RoutineBuilderScreen
- ActiveWorkoutScreen (real-time set logging)
- WorkoutHistoryScreen
- BodyMeasurementsScreen

---

## 4. Nutrition

**Purpose**: Food logging, meal tracking, water intake, and nutritional goal management. Integrates with Open Food Facts API for barcode scanning and food search.

**Responsibilities**:
- Search and retrieve food items from Open Food Facts API
- Cache food items locally for offline use
- Log meals (breakfast/lunch/dinner/snack) with food items and quantities
- Meal templates for quick re-logging of frequent meals
- Daily nutrition goals (calories, protein, carbs, fat, water)
- Water intake logging
- Listen to `ExpenseAddedEvent` for food-related expense correlation

**Data Layer**: `NutritionRepository` (wraps `NutritionDao` + `OpenFoodFactsClient`)

| Table | Key Columns |
|-------|-------------|
| `food_items` | id, barcode, name, brand, calories, protein, carbs, fat, servingSize, servingUnit, source(api/manual) |
| `meal_logs` | id, date, mealType(breakfast/lunch/dinner/snack), note |
| `meal_log_items` | id, mealLogId, foodItemId, quantity, servingUnit |
| `meal_templates` | id, name, mealType |
| `nutrition_goals` | id, calories, protein, carbs, fat, waterMl, effectiveDate |
| `water_logs` | id, date, amountMl, time |

**State Layer**: `NutritionNotifier` (AsyncNotifier)

**UI Screens**:
- DailyNutritionScreen (macro rings, meal list, water tracker)
- FoodSearchScreen (API search + barcode scanner)
- MealLogScreen (add/edit meal with food items)
- NutritionGoalsScreen

---

## 5. Habits

**Purpose**: Daily habit tracking with streak calculation and flexible scheduling.

**Responsibilities**:
- CRUD for habits (name, icon, color, frequency, target per period)
- Log daily habit completions (check-in)
- Streak calculation (current streak, longest streak)
- Frequency types: daily, specific days of week, X times per week
- Emit `HabitCheckedInEvent` via EventBus
- Habit completion rate statistics

**Data Layer**: `HabitsDao` (direct Drift DAO)

| Table | Key Columns |
|-------|-------------|
| `habits` | id, name, icon, color, frequency, targetPerPeriod, daysOfWeek (nullable), createdAt, isArchived |
| `habit_logs` | id, habitId, date, completedAt, value (nullable, for quantifiable habits) |

**State Layer**: `HabitsNotifier` (AsyncNotifier)

**UI Screens**:
- HabitsDashboardScreen (today's habits with check-in toggles)
- AddEditHabitScreen
- HabitDetailScreen (streak chart, completion history)

---

## 6. Sleep

**Purpose**: Sleep tracking, interruption logging, and morning energy assessment.

**Responsibilities**:
- Log sleep sessions (bed time, wake time, quality rating)
- Track sleep interruptions (wake-ups during night with optional reason)
- Morning energy level logging (1-10 scale with optional note)
- Sleep duration and quality trend analysis
- Emit `SleepLogSavedEvent` via EventBus
- Sleep statistics: average duration, quality trends, interruption patterns

**Data Layer**: `SleepDao` (direct Drift DAO)

| Table | Key Columns |
|-------|-------------|
| `sleep_logs` | id, date, bedTime, wakeTime, qualityRating (1-5), note |
| `sleep_interruptions` | id, sleepLogId, time, durationMinutes, reason (nullable) |
| `energy_logs` | id, date, time, level (1-10), note |

**State Layer**: `SleepNotifier` (AsyncNotifier)

**UI Screens**:
- SleepLogScreen (log tonight's sleep)
- SleepHistoryScreen (duration/quality trend charts)
- EnergyTrackerScreen

---

## 7. Mental

**Purpose**: Mental wellness tracking through mood logging and guided breathing exercises.

**Responsibilities**:
- Log mood entries (emotion, intensity, triggers, note)
- Guided breathing session tracking (technique, duration, completed)
- Mood trend analysis over time
- Emit `MoodLoggedEvent` via EventBus
- Breathing technique library (box breathing, 4-7-8, etc.)

**Data Layer**: `MentalDao` (direct Drift DAO)

| Table | Key Columns |
|-------|-------------|
| `mood_logs` | id, date, time, emotion, intensity (1-10), triggers (comma-separated), note |
| `breathing_sessions` | id, date, technique, durationSeconds, completedAt |

**State Layer**: `MentalNotifier` (AsyncNotifier)

**UI Screens**:
- MoodLogScreen (quick mood entry with emotion picker)
- BreathingScreen (guided breathing with timer animation)
- MentalHistoryScreen (mood trends, breathing session history)

---

## 8. Goals

**Purpose**: Life goal management with hierarchical sub-goals and milestones.

**Responsibilities**:
- CRUD for life goals (name, description, category, target date, status)
- Sub-goal decomposition (goals can have child goals)
- Milestone tracking with completion dates
- Progress calculation (manual or derived from sub-goals/milestones)
- Listen to `HabitCheckedInEvent`, `SleepLogSavedEvent`, `MoodLoggedEvent` for auto-progress
- Emit `GoalProgressUpdatedEvent` via EventBus

**Data Layer**: `GoalsDao` (direct Drift DAO)

| Table | Key Columns |
|-------|-------------|
| `life_goals` | id, name, description, category, targetDate, status(active/completed/paused/abandoned), progress (0-100), parentGoalId (nullable) |
| `sub_goals` | id, parentGoalId, name, description, status, sortOrder |
| `goal_milestones` | id, goalId, name, targetDate, completedDate (nullable), sortOrder |

**State Layer**: `GoalsNotifier` (AsyncNotifier)

**UI Screens**:
- GoalsOverviewScreen (goal cards with progress bars)
- GoalDetailScreen (sub-goals, milestones, progress timeline)
- AddEditGoalScreen

---

## 9. Intelligence

**Purpose**: AI-powered insights and conversations using configurable AI providers (OpenAI, Anthropic, local models, etc.).

**Responsibilities**:
- Manage AI provider configurations (API keys stored via SecureStorageService, model selection)
- Maintain conversation history with context
- Send prompts to configured AI providers and stream responses
- Store conversations and messages locally for history
- Provide AI-generated insights when requested by other modules

**Data Layer**: `AIRepository` (wraps `AIDao` + `AIProviderClients`)

| Table | Key Columns |
|-------|-------------|
| `ai_configurations` | id, providerName, modelName, isDefault, createdAt |
| `ai_conversations` | id, title, configurationId, createdAt, updatedAt |
| `ai_messages` | id, conversationId, role(user/assistant/system), content, createdAt, tokenCount |

**State Layer**: `AINotifier` (AsyncNotifier)

**UI Screens**:
- AIConfigurationScreen (provider setup, model selection)
- ConversationListScreen
- ChatScreen (streaming message display)

---

## 10. DayScore

**Purpose**: Daily life quality scoring that aggregates data from multiple modules into a single composite score with configurable weights.

**Responsibilities**:
- Calculate daily composite score (0-100) from module-specific components
- Configurable score components with weights (e.g., sleep 20%, habits 25%, gym 15%, etc.)
- Store daily scores with component breakdowns
- Life snapshots: periodic summaries capturing score + key metrics
- Listen to events from all modules to trigger score recalculation
- Historical score trends and analytics

**Data Layer**: `DayScoreDao` (direct Drift DAO)

| Table | Key Columns |
|-------|-------------|
| `day_scores` | id, date, totalScore (0-100), calculatedAt |
| `score_components` | id, dayScoreId, moduleName, rawValue, weight, weightedScore |
| `day_score_configs` | id, moduleName, weight, isEnabled, scoringRule |
| `life_snapshots` | id, date, totalScore, summaryJson, createdAt |

**State Layer**: `DayScoreNotifier` (AsyncNotifier)

**UI Screens**:
- DayScoreScreen (today's score with component breakdown ring chart)
- ScoreHistoryScreen (trend line, heatmap calendar)

---

## 11. Dashboard

**Purpose**: Central hub that aggregates today's key data from all modules into a single scrollable overview.

**Responsibilities**:
- Display today's DayScore prominently
- Show today's habit completion status
- Show today's nutrition summary (calories, macros)
- Show latest workout summary
- Show sleep quality from last night
- Show active budget alerts
- Show active goal progress highlights
- Quick-action shortcuts to frequently used screens
- Listen to `GoalProgressUpdatedEvent`, `BudgetThresholdEvent` for live updates

**Data Layer**: None. Reads from other module Notifiers via Riverpod `ref.watch`.

**State Layer**: `DashboardNotifier` (AsyncNotifier) -- aggregates and caches cross-module data.

**UI Screens**:
- DashboardScreen (scrollable card-based overview)

---

## 12. Onboarding

**Purpose**: First-launch experience that guides the user through initial setup (module selection, goals, preferences).

**Responsibilities**:
- Multi-step onboarding wizard
- Module selection (which modules to enable)
- Initial goal setting
- Notification preferences
- Theme preferences
- Mark onboarding as complete in AppSettings
- Trigger ExerciseLibraryService download if Gym module is enabled

**Data Layer**: Reads/writes `AppSettings` table via Core.

**State Layer**: `OnboardingNotifier` (AsyncNotifier)

**UI Screens**:
- WelcomeScreen
- ModuleSelectionScreen
- PreferencesScreen (notifications, theme)
