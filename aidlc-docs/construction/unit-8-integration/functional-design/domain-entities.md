# Domain Entities — Unit 8: Integration + Intelligence

## AI Database Tables

### ai_configurations
| Column      | Type          | Constraints                          | Notes                                |
|-------------|---------------|--------------------------------------|--------------------------------------|
| id          | INTEGER PK    | autoIncrement                        |                                      |
| providerKey | TEXT          | NOT NULL                             | 'openai' / 'anthropic' / 'custom'   |
| modelName   | TEXT          | NOT NULL                             | e.g. 'gpt-4o', 'claude-3-5-sonnet' |
| isDefault   | BOOLEAN       | DEFAULT false                        | Only one row should have true        |
| createdAt   | DATETIME      | NOT NULL                             |                                      |
| updatedAt   | DATETIME      | NOT NULL                             |                                      |

### ai_conversations
| Column    | Type       | Constraints                    | Notes                     |
|-----------|------------|--------------------------------|---------------------------|
| id        | INTEGER PK | autoIncrement                  |                           |
| configId  | INTEGER FK | REFERENCES ai_configurations   | Nullable (config deleted) |
| title     | TEXT       | NOT NULL, length 1-100         |                           |
| createdAt | DATETIME   | NOT NULL                       |                           |
| updatedAt | DATETIME   | NOT NULL                       |                           |

### ai_messages
| Column         | Type       | Constraints                   | Notes                           |
|----------------|------------|-------------------------------|---------------------------------|
| id             | INTEGER PK | autoIncrement                 |                                 |
| conversationId | INTEGER FK | REFERENCES ai_conversations   | CASCADE delete                  |
| role           | TEXT       | NOT NULL                      | 'user' / 'assistant' / 'system' |
| content        | TEXT       | NOT NULL                      |                                 |
| tokenCount     | INTEGER    | NULLABLE                      | Filled post-response            |
| createdAt      | DATETIME   | NOT NULL                      |                                 |

## AIProvider Interface

```
abstract class AIProvider {
  // Send a user prompt with optional system context.
  // Returns a Stream<String> of token chunks (streaming response).
  Stream<String> sendMessage(String prompt, {String? systemContext});

  // List available models for this provider.
  Future<List<String>> listModels();
}
```

Implementations must be stateless regarding conversation history; the caller manages history injection.

## BackupHandler Interface

```
abstract class BackupHandler {
  String get moduleName;
  Future<List<Map<String, dynamic>>> exportRecords();
  Future<BackupImportModuleResult> importRecords(List<Map<String, dynamic>> records);
}
```

Each feature module registers a BackupHandler with the integration layer. The BackupEngine calls exportRecords() during export and importRecords() during import.

## EventBus Subscription Graph

```
WorkoutCompletedEvent
  --> HabitsNotifier.onWorkoutCompleted()        (auto check-in linked habits)
  --> NutritionNotifier.adjustGoalsForTraining() (apply +15% cal, +20% protein, +10% carbs)
  --> DayScoreNotifier.calculateDayScore()       (recalculate score)

ExpenseAddedEvent
  --> (integration/event_wiring) suggestion logic (food category => nutrition note)

BudgetThresholdEvent
  --> DashboardNotifier.refresh()
  --> NotificationScheduler.scheduleImmediate()

HabitCheckedInEvent
  --> GoalsNotifier.onHabitCheckedIn()
  --> DashboardNotifier.refresh()
  --> DayScoreNotifier.calculateDayScore()

SleepLogSavedEvent
  --> GoalsNotifier.onSleepLogSaved()
  --> DashboardNotifier.refresh()
  --> DayScoreNotifier.calculateDayScore()

MoodLoggedEvent
  --> GoalsNotifier.onMoodLogged()
  --> DashboardNotifier.refresh()
  --> DayScoreNotifier.calculateDayScore()

GoalProgressUpdatedEvent
  --> DashboardNotifier.refresh()
```
