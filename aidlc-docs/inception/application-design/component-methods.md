# Component Methods

## Purpose

Defines key method signatures for every module's DAO/Repository and Notifier layers. Uses Dart-like pseudocode with `Result<T>` return types for business methods. This document covers WHAT operations exist, not HOW they are implemented (business rules are deferred to Functional Design).

---

## Conventions

- `Result<T>` = `sealed class` with `Success<T>` and `Failure<AppFailure>` variants
- DAO methods return `Future<T>` or `Stream<T>` (Drift-level, no business logic)
- Notifier methods return `Future<Result<T>>` (business layer, may validate/transform)
- `AsyncValue<T>` is the Riverpod state exposed to UI

---

## 1. Core (AppSettings)

### AppSettingsDao

```dart
Future<AppSetting?> getSetting(String key);                // Get a single setting by key
Future<void> setSetting(String key, String value);          // Upsert a setting
Stream<AppSetting?> watchSetting(String key);               // Watch a setting reactively
Future<Map<String, String>> getAllSettings();                // Get all settings as map
Future<void> setMultiple(Map<String, String> settings);     // Batch upsert settings
```

---

## 2. Finance

### FinanceDao

```dart
// Transactions
Future<int> insertTransaction(TransactionsCompanion entry);          // Insert, returns id
Future<void> updateTransaction(Transaction entry);                    // Update existing
Future<void> deleteTransaction(int id);                               // Soft or hard delete
Stream<List<Transaction>> watchTransactions(DateTime from, DateTime to); // Watch by date range
Future<List<Transaction>> getTransactionsByCategory(int categoryId, DateTime from, DateTime to); // Filter by category
Future<double> sumByType(TransactionType type, DateTime from, DateTime to); // Sum income or expenses

// Categories
Future<int> insertCategory(CategoriesCompanion entry);               // Insert, returns id
Future<void> updateCategory(Category entry);                          // Update existing
Future<void> deleteCategory(int id);                                  // Delete if no transactions reference it
Stream<List<Category>> watchCategories();                              // Watch all categories
Future<List<Category>> getCategoriesByType(TransactionType type);     // Filter by income/expense

// Budgets
Future<int> insertBudget(BudgetsCompanion entry);                    // Insert, returns id
Future<void> updateBudget(Budget entry);                              // Update existing
Stream<List<Budget>> watchBudgets(int month, int year);               // Watch budgets for month
Future<double> spentInBudget(int categoryId, int month, int year);   // Calculate spent amount

// Savings Goals
Future<int> insertSavingsGoal(SavingsGoalsCompanion entry);          // Insert, returns id
Future<void> updateSavingsGoal(SavingsGoal entry);                    // Update existing
Future<void> deleteSavingsGoal(int id);                               // Delete goal
Stream<List<SavingsGoal>> watchSavingsGoals();                        // Watch all active goals

// Recurring Transactions
Future<int> insertRecurring(RecurringTransactionsCompanion entry);   // Insert, returns id
Future<void> updateRecurring(RecurringTransaction entry);             // Update existing
Future<List<RecurringTransaction>> getDueRecurrings(DateTime now);   // Get transactions due for processing
Future<void> markProcessed(int id, DateTime nextOccurrence);          // Update next occurrence after processing
```

### FinanceNotifier

```dart
// State: AsyncValue<FinanceState>
// FinanceState { transactions, categories, budgets, savingsGoals, monthSummary }

Future<Result<Transaction>> addTransaction(TransactionInput input);   // Validate + insert + emit ExpenseAddedEvent if expense
Future<Result<Transaction>> editTransaction(int id, TransactionInput input); // Validate + update
Future<Result<void>> removeTransaction(int id);                       // Delete transaction
Future<Result<Category>> addCategory(CategoryInput input);            // Validate uniqueness + insert
Future<Result<Budget>> setBudget(int categoryId, double amount, int month, int year); // Upsert budget + check threshold
Future<Result<SavingsGoal>> addSavingsGoal(SavingsGoalInput input);  // Validate + insert
Future<Result<void>> contributeToGoal(int goalId, double amount);    // Add to currentAmount
Future<Result<void>> processRecurringTransactions();                   // Process all due recurrings

// Computed getters
double get totalIncomeThisMonth;                                       // Sum of income for current month
double get totalExpensesThisMonth;                                     // Sum of expenses for current month
double get netBalanceThisMonth;                                        // Income - expenses
Map<int, double> get budgetUtilization;                                // categoryId → percentage used
```

---

## 3. Gym

### GymDao

```dart
// Exercises
Future<int> insertExercise(ExercisesCompanion entry);                 // Insert, returns id
Future<void> updateExercise(Exercise entry);                           // Update existing
Stream<List<Exercise>> watchExercises({String? muscleGroup, String? query}); // Watch with optional filters
Future<void> bulkInsertExercises(List<ExercisesCompanion> entries);   // Batch insert for library download
Future<int> countExercises();                                          // Count for library status check

// Routines
Future<int> insertRoutine(RoutinesCompanion entry);                   // Insert, returns id
Future<void> updateRoutine(Routine entry);                             // Update existing
Future<void> deleteRoutine(int id);                                    // Delete routine + cascade routine_exercises
Stream<List<Routine>> watchRoutines();                                 // Watch all routines

// Routine Exercises
Future<void> setRoutineExercises(int routineId, List<RoutineExercisesCompanion> exercises); // Replace all exercises in routine
Stream<List<RoutineExerciseWithExercise>> watchRoutineExercises(int routineId); // Watch with joined exercise data

// Workouts
Future<int> insertWorkout(WorkoutsCompanion entry);                   // Insert, returns id
Future<void> updateWorkout(Workout entry);                             // Update (e.g., set finishedAt)
Stream<List<Workout>> watchWorkouts({int? limit});                    // Watch recent workouts
Future<Workout?> getActiveWorkout();                                   // Get in-progress workout (finishedAt == null)

// Workout Sets
Future<int> insertWorkoutSet(WorkoutSetsCompanion entry);             // Insert, returns id
Future<void> updateWorkoutSet(WorkoutSet entry);                       // Update existing
Future<void> deleteWorkoutSet(int id);                                 // Remove a set
Stream<List<WorkoutSet>> watchWorkoutSets(int workoutId);             // Watch sets for a workout
Future<double?> getPersonalRecord(int exerciseId);                    // Max weight for exercise

// Body Measurements
Future<int> insertMeasurement(BodyMeasurementsCompanion entry);       // Insert, returns id
Stream<List<BodyMeasurement>> watchMeasurements({int? limit});        // Watch recent measurements
Future<BodyMeasurement?> getLatestMeasurement();                       // Get most recent entry
```

### GymNotifier

```dart
// State: AsyncValue<GymState>
// GymState { exercises, routines, activeWorkout, recentWorkouts, latestMeasurement }

Future<Result<Workout>> startWorkout({int? routineId});               // Create workout, optionally from routine template
Future<Result<WorkoutSet>> logSet(int exerciseId, SetInput input);    // Add set to active workout
Future<Result<void>> updateSet(int setId, SetInput input);            // Edit a logged set
Future<Result<void>> removeSet(int setId);                             // Remove a set
Future<Result<Workout>> finishWorkout({String? note});                // Set finishedAt + emit WorkoutCompletedEvent
Future<Result<void>> discardWorkout();                                 // Delete in-progress workout
Future<Result<Routine>> createRoutine(RoutineInput input);            // Validate + insert routine with exercises
Future<Result<BodyMeasurement>> logMeasurement(MeasurementInput input); // Validate + insert measurement

// Computed getters
Duration? get currentWorkoutDuration;                                  // Elapsed time of active workout
Map<String, double> get volumeByMuscleGroup;                           // Total volume per muscle group this week
int get workoutsThisWeek;                                              // Count of completed workouts this week
```

---

## 4. Nutrition

### NutritionDao

```dart
// Food Items
Future<int> insertFoodItem(FoodItemsCompanion entry);                 // Insert, returns id
Future<void> updateFoodItem(FoodItem entry);                           // Update existing
Future<FoodItem?> getFoodItemByBarcode(String barcode);               // Lookup by barcode (cached)
Stream<List<FoodItem>> watchRecentFoodItems({int limit = 20});        // Watch recently used items

// Meal Logs
Future<int> insertMealLog(MealLogsCompanion entry);                   // Insert, returns id
Future<void> updateMealLog(MealLog entry);                             // Update existing
Future<void> deleteMealLog(int id);                                    // Delete meal + cascade items
Stream<List<MealLogWithItems>> watchMealLogs(DateTime date);          // Watch meals for a specific date

// Meal Log Items
Future<void> setMealLogItems(int mealLogId, List<MealLogItemsCompanion> items); // Replace all items in meal

// Meal Templates
Future<int> insertMealTemplate(MealTemplatesCompanion entry);         // Insert, returns id
Future<void> deleteMealTemplate(int id);                               // Delete template
Stream<List<MealTemplate>> watchMealTemplates();                       // Watch all templates

// Nutrition Goals
Future<int> insertNutritionGoal(NutritionGoalsCompanion entry);       // Insert, returns id
Future<NutritionGoal?> getActiveGoal(DateTime date);                   // Get goal effective for date
Stream<NutritionGoal?> watchActiveGoal();                              // Watch current goal

// Water Logs
Future<int> insertWaterLog(WaterLogsCompanion entry);                  // Insert, returns id
Future<void> deleteWaterLog(int id);                                    // Delete entry
Stream<List<WaterLog>> watchWaterLogs(DateTime date);                  // Watch water intake for date
Future<int> totalWater(DateTime date);                                  // Sum water for date in ml
```

### OpenFoodFactsClient

```dart
Future<FoodItemDto?> searchByBarcode(String barcode);                  // Lookup product by barcode
Future<List<FoodItemDto>> searchByName(String query, {int page = 1}); // Search products by name
```

### NutritionRepository

```dart
Future<Result<FoodItem>> findOrFetchByBarcode(String barcode);        // Check local cache, fetch from API if missing, cache result
Future<Result<List<FoodItem>>> searchFood(String query);              // Search API + merge with local items
Future<Result<MealLog>> logMeal(MealLogInput input);                  // Validate + insert meal log with items
Future<Result<void>> logWater(int amountMl);                           // Insert water log entry
Future<Result<void>> setNutritionGoal(NutritionGoalInput input);      // Validate + insert/update goal
Future<Result<MealLog>> applyTemplate(int templateId, DateTime date); // Create meal log from template
```

### NutritionNotifier

```dart
// State: AsyncValue<NutritionState>
// NutritionState { todayMeals, todayWater, activeGoal, recentFoods, templates }

Future<Result<FoodItem>> scanBarcode(String barcode);                  // Scan → findOrFetch → return food item
Future<Result<List<FoodItem>>> searchFood(String query);              // Delegate to repository
Future<Result<MealLog>> addMeal(MealLogInput input);                  // Delegate to repository
Future<Result<void>> removeMeal(int mealLogId);                        // Delete meal log
Future<Result<void>> addWater(int amountMl);                           // Delegate to repository
Future<Result<void>> updateGoal(NutritionGoalInput input);            // Delegate to repository

// Computed getters
int get caloriesConsumedToday;                                         // Sum of calories from today's meals
MacroSummary get macrosToday;                                          // Protein, carbs, fat totals
int get waterConsumedToday;                                            // Sum of water in ml
double get calorieGoalProgress;                                        // Consumed / goal ratio
```

---

## 5. Habits

### HabitsDao

```dart
Future<int> insertHabit(HabitsCompanion entry);                       // Insert, returns id
Future<void> updateHabit(Habit entry);                                 // Update existing
Future<void> archiveHabit(int id);                                     // Set isArchived = true
Stream<List<Habit>> watchActiveHabits();                               // Watch non-archived habits
Stream<List<HabitLog>> watchHabitLogs(int habitId, DateTime from, DateTime to); // Watch logs in range
Future<void> insertHabitLog(HabitLogsCompanion entry);                // Insert check-in
Future<void> deleteHabitLog(int habitId, DateTime date);              // Remove check-in for date
Future<int> streakCount(int habitId, DateTime asOf);                  // Calculate current streak length
Future<int> longestStreak(int habitId);                                // Calculate longest ever streak
Future<double> completionRate(int habitId, DateTime from, DateTime to); // Completion percentage in range
```

### HabitsNotifier

```dart
// State: AsyncValue<HabitsState>
// HabitsState { habits, todayLogs, streaks }

Future<Result<Habit>> addHabit(HabitInput input);                      // Validate + insert habit
Future<Result<Habit>> editHabit(int id, HabitInput input);            // Validate + update habit
Future<Result<void>> archiveHabit(int id);                             // Archive habit
Future<Result<void>> checkIn(int habitId, {double? value});           // Log completion + emit HabitCheckedInEvent
Future<Result<void>> uncheckIn(int habitId, DateTime date);           // Remove check-in

// Computed getters
int get completedTodayCount;                                           // Number of habits completed today
int get totalDueToday;                                                 // Number of habits due today
double get todayCompletionRate;                                        // Completed / due ratio
Map<int, int> get currentStreaks;                                      // habitId → current streak
```

---

## 6. Sleep

### SleepDao

```dart
// Sleep Logs
Future<int> insertSleepLog(SleepLogsCompanion entry);                 // Insert, returns id
Future<void> updateSleepLog(SleepLog entry);                           // Update existing
Future<void> deleteSleepLog(int id);                                   // Delete log + cascade interruptions
Stream<SleepLog?> watchSleepLog(DateTime date);                       // Watch log for specific date
Stream<List<SleepLog>> watchSleepLogs({int? limit});                  // Watch recent logs
Future<double> averageDuration(DateTime from, DateTime to);           // Avg sleep hours in range
Future<double> averageQuality(DateTime from, DateTime to);            // Avg quality rating in range

// Sleep Interruptions
Future<int> insertInterruption(SleepInterruptionsCompanion entry);    // Insert, returns id
Future<void> deleteInterruption(int id);                               // Delete interruption
Stream<List<SleepInterruption>> watchInterruptions(int sleepLogId);   // Watch interruptions for log

// Energy Logs
Future<int> insertEnergyLog(EnergyLogsCompanion entry);               // Insert, returns id
Stream<List<EnergyLog>> watchEnergyLogs(DateTime from, DateTime to); // Watch energy logs in range
Future<double> averageEnergy(DateTime from, DateTime to);             // Avg energy level in range
```

### SleepNotifier

```dart
// State: AsyncValue<SleepState>
// SleepState { lastNightLog, recentLogs, todayEnergy, weeklyStats }

Future<Result<SleepLog>> logSleep(SleepLogInput input);               // Validate + insert + emit SleepLogSavedEvent
Future<Result<SleepLog>> editSleepLog(int id, SleepLogInput input);  // Validate + update
Future<Result<void>> addInterruption(int sleepLogId, InterruptionInput input); // Add interruption to log
Future<Result<EnergyLog>> logEnergy(int level, {String? note});       // Validate + insert energy log

// Computed getters
Duration? get lastNightDuration;                                       // Calculated from last night's bed/wake times
double get weeklyAverageQuality;                                       // Average quality over past 7 days
double get weeklyAverageDuration;                                      // Average duration over past 7 days
```

---

## 7. Mental

### MentalDao

```dart
// Mood Logs
Future<int> insertMoodLog(MoodLogsCompanion entry);                   // Insert, returns id
Future<void> updateMoodLog(MoodLog entry);                             // Update existing
Future<void> deleteMoodLog(int id);                                    // Delete mood log
Stream<List<MoodLog>> watchMoodLogs(DateTime from, DateTime to);     // Watch logs in range
Stream<List<MoodLog>> watchTodayMoodLogs();                            // Watch today's mood entries
Future<double> averageMoodIntensity(DateTime from, DateTime to);      // Avg intensity in range
Future<Map<String, int>> triggerFrequency(DateTime from, DateTime to); // Count of each trigger

// Breathing Sessions
Future<int> insertBreathingSession(BreathingSessionsCompanion entry); // Insert, returns id
Stream<List<BreathingSession>> watchBreathingSessions({int? limit});  // Watch recent sessions
Future<int> totalBreathingMinutes(DateTime from, DateTime to);        // Sum of duration in range
```

### MentalNotifier

```dart
// State: AsyncValue<MentalState>
// MentalState { todayMoods, recentBreathingSessions, weeklyMoodTrend }

Future<Result<MoodLog>> logMood(MoodLogInput input);                   // Validate + insert + emit MoodLoggedEvent
Future<Result<MoodLog>> editMood(int id, MoodLogInput input);        // Validate + update
Future<Result<void>> removeMood(int id);                               // Delete mood log
Future<Result<BreathingSession>> logBreathingSession(BreathingSessionInput input); // Insert completed session

// Computed getters
double? get todayAverageMood;                                          // Average mood intensity today
int get breathingMinutesThisWeek;                                      // Total breathing minutes this week
List<String> get topTriggers;                                          // Most frequent triggers this month
```

---

## 8. Goals

### GoalsDao

```dart
// Life Goals
Future<int> insertGoal(LifeGoalsCompanion entry);                     // Insert, returns id
Future<void> updateGoal(LifeGoal entry);                               // Update existing
Future<void> deleteGoal(int id);                                       // Delete goal + cascade sub-goals/milestones
Stream<List<LifeGoal>> watchGoals({String? status});                  // Watch goals, optionally by status
Future<LifeGoal?> getGoal(int id);                                     // Get single goal by id

// Sub-Goals
Future<int> insertSubGoal(SubGoalsCompanion entry);                   // Insert, returns id
Future<void> updateSubGoal(SubGoal entry);                             // Update existing
Future<void> deleteSubGoal(int id);                                    // Delete sub-goal
Stream<List<SubGoal>> watchSubGoals(int parentGoalId);                // Watch sub-goals for parent

// Goal Milestones
Future<int> insertMilestone(GoalMilestonesCompanion entry);           // Insert, returns id
Future<void> updateMilestone(GoalMilestone entry);                     // Update existing
Future<void> deleteMilestone(int id);                                  // Delete milestone
Stream<List<GoalMilestone>> watchMilestones(int goalId);              // Watch milestones for goal
Future<void> completeMilestone(int id, DateTime completedDate);       // Mark milestone complete
```

### GoalsNotifier

```dart
// State: AsyncValue<GoalsState>
// GoalsState { activeGoals, completedGoals, goalDetails }

Future<Result<LifeGoal>> addGoal(GoalInput input);                    // Validate + insert goal
Future<Result<LifeGoal>> editGoal(int id, GoalInput input);          // Validate + update goal
Future<Result<void>> removeGoal(int id);                               // Delete goal
Future<Result<SubGoal>> addSubGoal(int parentGoalId, SubGoalInput input); // Add sub-goal to parent
Future<Result<GoalMilestone>> addMilestone(int goalId, MilestoneInput input); // Add milestone to goal
Future<Result<void>> completeMilestone(int milestoneId);              // Mark complete + recalculate progress
Future<Result<void>> updateProgress(int goalId, int progress);        // Manual progress update + emit GoalProgressUpdatedEvent
Future<Result<void>> changeStatus(int goalId, GoalStatus status);    // Change goal status

// Computed getters
int get activeGoalCount;                                               // Number of active goals
double get overallProgress;                                            // Average progress across active goals
List<LifeGoal> get upcomingDeadlines;                                  // Goals with deadlines within 30 days
```

---

## 9. Intelligence

### AIDao

```dart
// Configurations
Future<int> insertConfiguration(AIConfigurationsCompanion entry);     // Insert, returns id
Future<void> updateConfiguration(AIConfiguration entry);               // Update existing
Future<void> deleteConfiguration(int id);                              // Delete config
Stream<List<AIConfiguration>> watchConfigurations();                   // Watch all configs
Future<AIConfiguration?> getDefaultConfiguration();                    // Get config where isDefault == true

// Conversations
Future<int> insertConversation(AIConversationsCompanion entry);       // Insert, returns id
Future<void> updateConversation(AIConversation entry);                 // Update (e.g., title, updatedAt)
Future<void> deleteConversation(int id);                               // Delete conversation + cascade messages
Stream<List<AIConversation>> watchConversations({int? limit});        // Watch recent conversations

// Messages
Future<int> insertMessage(AIMessagesCompanion entry);                  // Insert, returns id
Stream<List<AIMessage>> watchMessages(int conversationId);            // Watch messages in conversation
Future<int> totalTokensUsed(int configurationId);                     // Sum tokens for a config
```

### AIProviderClient (abstract)

```dart
Stream<String> sendMessage(String prompt, List<AIMessage> history, AIConfiguration config); // Stream response chunks
Future<bool> validateApiKey(String apiKey, String provider);          // Test API key validity
```

### AIRepository

```dart
Future<Result<AIConfiguration>> addConfiguration(AIConfigInput input); // Validate + store API key securely + insert config
Future<Result<void>> removeConfiguration(int id);                      // Delete config + remove stored key
Future<Result<AIConversation>> startConversation({String? title});    // Create new conversation with default config
Stream<Result<String>> sendMessage(int conversationId, String prompt); // Send prompt, stream response, persist messages
Future<Result<void>> deleteConversation(int id);                       // Delete conversation and messages
Future<Result<AIConfiguration>> setDefaultConfiguration(int id);      // Mark config as default
```

### AINotifier

```dart
// State: AsyncValue<AIState>
// AIState { configurations, conversations, activeConversation, streamingResponse }

Future<Result<AIConfiguration>> addProvider(AIConfigInput input);      // Delegate to repository
Future<Result<void>> removeProvider(int id);                           // Delegate to repository
Future<Result<AIConversation>> newConversation({String? title});      // Delegate to repository
Future<Result<void>> sendMessage(String prompt);                       // Send to active conversation, update streaming state
Future<Result<void>> deleteConversation(int id);                       // Delegate to repository
void selectConversation(int conversationId);                           // Switch active conversation

// Computed getters
bool get isStreaming;                                                   // Whether a response is currently streaming
AIConfiguration? get activeConfig;                                     // Currently selected config
int get totalConversations;                                            // Count of conversations
```

---

## 10. DayScore

### DayScoreDao

```dart
// Day Scores
Future<int> insertDayScore(DayScoresCompanion entry);                  // Insert, returns id
Future<void> updateDayScore(DayScore entry);                           // Update existing
Stream<DayScore?> watchDayScore(DateTime date);                        // Watch score for date
Stream<List<DayScore>> watchDayScores(DateTime from, DateTime to);    // Watch scores in range
Future<double> averageScore(DateTime from, DateTime to);               // Avg score in range

// Score Components
Future<void> setScoreComponents(int dayScoreId, List<ScoreComponentsCompanion> components); // Replace all components for score
Stream<List<ScoreComponent>> watchScoreComponents(int dayScoreId);    // Watch components for score

// Day Score Configs
Future<void> upsertConfig(DayScoreConfigsCompanion entry);            // Upsert module weight config
Stream<List<DayScoreConfig>> watchConfigs();                           // Watch all configs
Future<List<DayScoreConfig>> getActiveConfigs();                       // Get enabled configs

// Life Snapshots
Future<int> insertSnapshot(LifeSnapshotsCompanion entry);             // Insert, returns id
Stream<List<LifeSnapshot>> watchSnapshots({int? limit});              // Watch recent snapshots
```

### DayScoreNotifier

```dart
// State: AsyncValue<DayScoreState>
// DayScoreState { todayScore, todayComponents, configs, recentScores, snapshots }

Future<Result<DayScore>> calculateTodayScore();                        // Gather data from all modules, compute weighted score, persist
Future<Result<void>> recalculate(DateTime date);                       // Recalculate score for a specific date
Future<Result<void>> updateConfig(String moduleName, double weight, bool isEnabled); // Update weight/enabled for module
Future<Result<LifeSnapshot>> createSnapshot();                         // Generate and persist a life snapshot

// Computed getters
int get todayTotalScore;                                               // Today's composite score (0-100)
Map<String, double> get componentBreakdown;                            // Module name → weighted score
double get weeklyAverage;                                              // Average score over past 7 days
String get trend;                                                       // "improving" | "stable" | "declining" based on 7-day trend
```

---

## 11. Dashboard

### DashboardNotifier

```dart
// State: AsyncValue<DashboardState>
// DashboardState { dayScore, habitSummary, nutritionSummary, workoutSummary, sleepSummary, budgetAlerts, goalHighlights }

Future<Result<void>> refresh();                                        // Reload all module summaries
void onEventReceived(AppEvent event);                                  // Handle EventBus events to trigger partial refresh

// Computed getters (derived from watched module states)
int get todayScore;                                                    // From DayScoreNotifier
String get habitStatus;                                                // "3/5 completed" from HabitsNotifier
int get caloriesConsumed;                                              // From NutritionNotifier
String get lastWorkoutSummary;                                         // From GymNotifier
String get sleepQuality;                                               // From SleepNotifier
List<BudgetAlert> get activeBudgetAlerts;                              // From FinanceNotifier
List<GoalHighlight> get goalHighlights;                                // From GoalsNotifier
```

---

## 12. Onboarding

### OnboardingNotifier

```dart
// State: AsyncValue<OnboardingState>
// OnboardingState { currentStep, selectedModules, preferences, isComplete }

Future<Result<void>> selectModules(Set<String> moduleNames);           // Store selected modules
Future<Result<void>> setPreferences(PreferencesInput input);          // Store notification + theme prefs
Future<Result<void>> completeOnboarding();                             // Write AppSettings, trigger exercise download if gym selected
bool get isOnboardingComplete;                                         // Check AppSettings for completion flag
int get currentStep;                                                   // Current wizard step index
int get totalSteps;                                                    // Total wizard steps
```
