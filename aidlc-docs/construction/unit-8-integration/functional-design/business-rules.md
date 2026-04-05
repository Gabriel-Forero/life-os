# Business Rules — Unit 8: Integration + Intelligence

## AI Provider Management Rules

BR-AI-01: Only one ai_configurations row may have isDefault = true at any time.
  - When setDefaultProvider(id) is called, all rows are first updated to isDefault = false, then the target row is updated to true.

BR-AI-02: providerKey must be one of: 'openai', 'anthropic', 'custom'.
  - Validation enforced at AIDao insert level.

BR-AI-03: modelName must not be empty.
  - Validation enforced at AIDao insert level.

BR-AI-04: Conversation title must be between 1 and 100 characters.
  - Trimmed before validation.

BR-AI-05: Message role must be 'user', 'assistant', or 'system'.
  - Validation enforced at AIDao insert level.

## Context Building Rules

BR-CTX-01: buildAIContext() reads current live state from Notifiers (not DB directly):
  - DayScore (integer 0-100, or null if not computed today)
  - Calories consumed today vs. goal (integers)
  - Budget spend % for current month (float 0-1)
  - Active habit streaks (list of {name, streak})
  - Last sleep score (integer 0-100, or null)
  - Last mood level (integer 1-10, or null)

BR-CTX-02: buildAIContext() returns a Spanish-language system prompt string.

BR-CTX-03: If a module value is unavailable (null), the context builder omits that line rather than inserting "null".

## Event Wiring Rules

BR-EW-01: wireEventBus(ref) must be called exactly once at app startup.

BR-EW-02: All EventBus subscriptions are created inside wireEventBus — no module notifier subscribes to another module's events directly.
  - Exception: GoalsNotifier subscribes to habit/sleep/mood events as part of its own lifecycle (Unit 7 design). The integration layer adds the remaining cross-module wires.

BR-EW-03: WorkoutCompletedEvent -> nutrition adjustment:
  - Reads the current active NutritionGoal for today.
  - Applies: calories +15%, protein +20%, carbs +10%, fat unchanged.
  - Inserts a new NutritionGoal row with effectiveDate = today (does not mutate existing row).
  - If no active goal exists, the adjustment is skipped with a warning log.

BR-EW-04: ExpenseAddedEvent with category 'alimentacion' or 'comida' triggers a no-op note (stub for future AI suggestion). No crash if AI provider not configured.

BR-EW-05: BudgetThresholdEvent:
  - Triggers DashboardNotifier.refresh().
  - Triggers NotificationScheduler to schedule an immediate budget alert notification.

BR-EW-06: HabitCheckedInEvent, SleepLogSavedEvent, MoodLoggedEvent:
  - Each triggers DashboardNotifier.refresh() and DayScoreNotifier.calculateDayScore().
  - GoalsNotifier already handles these internally (Unit 7).

BR-EW-07: GoalProgressUpdatedEvent triggers DashboardNotifier.refresh().

## Backup Rules

BR-BK-01: The integration layer provides a BackupHandler for ai_configurations, ai_conversations, and ai_messages tables combined into a single module named 'intelligence'.

BR-BK-02: During export, records are serialized to JSON using Drift's toJson() equivalent (column-name-keyed maps).

BR-BK-03: During import, existing records with the same id are skipped (no overwrite). New ids are inserted.

BR-BK-04: importRecords() returns BackupImportModuleResult with counts of inserted, skipped, and failed records.
