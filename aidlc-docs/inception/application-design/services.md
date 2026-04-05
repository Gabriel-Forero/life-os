# Service Layer Definitions

## Purpose

Defines cross-cutting services that live in the Core module and are consumed by feature modules via Riverpod providers. Services encapsulate platform-specific or shared functionality that does not belong to any single feature module.

---

## Service Summary

| Service | Purpose | Stateful? | Provider Type |
|---------|---------|-----------|---------------|
| EventBus | Cross-module event broadcast | No (stream-based) | `Provider<EventBus>` |
| NotificationService | Local push notifications | No | `Provider<NotificationService>` |
| HapticService | Haptic feedback abstraction | No | `Provider<HapticService>` |
| SecureStorageService | Encrypted key-value storage | No | `Provider<SecureStorageService>` |
| BackupService | JSON export/import of all data | No | `Provider<BackupService>` |
| ExerciseLibraryService | Download + seed exercise library | No | `Provider<ExerciseLibraryService>` |
| ThemeService | Dark theme management | Yes | `NotifierProvider<ThemeNotifier, ThemeState>` |

---

## 1. EventBus

**Purpose**: Enables decoupled cross-module communication. Modules emit typed events; other modules subscribe to events they care about. Implemented as a singleton `StreamController.broadcast`.

**Dependencies**: None

### Key Methods

```dart
class EventBus {
  // Internal: final _controller = StreamController<AppEvent>.broadcast();

  void emit(AppEvent event);                           // Publish an event to all subscribers
  Stream<T> on<T extends AppEvent>();                  // Subscribe to a specific event type
  void dispose();                                       // Close the stream controller (app shutdown)
}
```

### Event Types

```dart
sealed class AppEvent {
  DateTime get timestamp;
}

class WorkoutCompletedEvent extends AppEvent {
  final int workoutId;
  final Duration duration;
  final int totalSets;
}

class ExpenseAddedEvent extends AppEvent {
  final int transactionId;
  final int categoryId;
  final double amount;
}

class BudgetThresholdEvent extends AppEvent {
  final int budgetId;
  final int categoryId;
  final double percentageUsed;                          // 0.0 to 1.0+
}

class HabitCheckedInEvent extends AppEvent {
  final int habitId;
  final String habitName;
  final DateTime date;
}

class SleepLogSavedEvent extends AppEvent {
  final int sleepLogId;
  final Duration duration;
  final int qualityRating;
}

class MoodLoggedEvent extends AppEvent {
  final int moodLogId;
  final String emotion;
  final int intensity;
}

class GoalProgressUpdatedEvent extends AppEvent {
  final int goalId;
  final int progress;                                   // 0-100
}
```

### Event Flow Matrix

| Event | Emitted By | Consumed By |
|-------|-----------|-------------|
| WorkoutCompletedEvent | GymNotifier | HabitsNotifier, NutritionNotifier, DayScoreNotifier |
| ExpenseAddedEvent | FinanceNotifier | NutritionNotifier (food correlation) |
| BudgetThresholdEvent | FinanceNotifier | DashboardNotifier, NotificationService |
| HabitCheckedInEvent | HabitsNotifier | GoalsNotifier, DashboardNotifier, DayScoreNotifier |
| SleepLogSavedEvent | SleepNotifier | GoalsNotifier, DashboardNotifier, DayScoreNotifier |
| MoodLoggedEvent | MentalNotifier | GoalsNotifier, DashboardNotifier, DayScoreNotifier |
| GoalProgressUpdatedEvent | GoalsNotifier | DashboardNotifier |

---

## 2. NotificationService

**Purpose**: Abstracts local push notification scheduling and display. Used for budget threshold alerts, habit reminders, sleep reminders, and goal deadline reminders. Uses `flutter_local_notifications` under the hood.

**Dependencies**: None (platform plugin)

### Key Methods

```dart
class NotificationService {
  Future<void> initialize();                             // Request permissions, configure channels
  Future<void> showImmediate({                           // Show a notification immediately
    required String title,
    required String body,
    String? payload,
  });
  Future<void> scheduleDaily({                           // Schedule a recurring daily notification
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  });
  Future<void> scheduleOnce({                            // Schedule a one-time notification
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
  });
  Future<void> cancel(int id);                           // Cancel a scheduled notification
  Future<void> cancelAll();                              // Cancel all scheduled notifications
  Future<List<PendingNotification>> getPending();        // List all pending notifications
}
```

---

## 3. HapticService

**Purpose**: Provides consistent haptic feedback across the app. Abstracts platform differences and allows global enable/disable via AppSettings.

**Dependencies**: AppSettingsDao (reads haptic preference)

### Key Methods

```dart
class HapticService {
  Future<void> light();                                  // Light tap feedback (toggle, check-in)
  Future<void> medium();                                 // Medium feedback (button press, navigation)
  Future<void> heavy();                                  // Heavy feedback (delete, discard)
  Future<void> success();                                // Success pattern (goal complete, workout done)
  Future<void> warning();                                // Warning pattern (budget threshold)
  Future<void> error();                                  // Error pattern (validation failure)
  Future<void> selectionClick();                         // Selection change feedback
  bool get isEnabled;                                    // Whether haptics are enabled in settings
  Future<void> setEnabled(bool enabled);                 // Toggle haptic feedback on/off
}
```

---

## 4. SecureStorageService

**Purpose**: Encrypted key-value storage for sensitive data (AI provider API keys, backup encryption keys). Uses `flutter_secure_storage` with platform-specific encryption (Keychain on iOS, EncryptedSharedPreferences on Android).

**Dependencies**: None (platform plugin)

### Key Methods

```dart
class SecureStorageService {
  Future<void> write(String key, String value);          // Store encrypted value
  Future<String?> read(String key);                      // Read encrypted value (null if not found)
  Future<void> delete(String key);                       // Delete a stored value
  Future<bool> containsKey(String key);                  // Check if key exists
  Future<Map<String, String>> readAll();                 // Read all stored key-value pairs
  Future<void> deleteAll();                              // Clear all stored values (factory reset)
}
```

### Key Naming Convention

```
ai_provider_key_{configurationId}    // AI provider API keys
backup_encryption_key                // Backup file encryption key
```

---

## 5. BackupService

**Purpose**: Full data export and import as JSON. Allows users to back up all their data to a file and restore from a backup. Supports encrypted backups using a user-provided passphrase.

**Dependencies**: `AppDatabase` (Drift), `SecureStorageService`

### Key Methods

```dart
class BackupService {
  Future<Result<File>> exportToJson({                    // Export all tables to a JSON file
    required String filePath,
    String? passphrase,                                   // Optional encryption passphrase
  });
  Future<Result<BackupMetadata>> peekBackup(File file, {  // Read backup metadata without importing
    String? passphrase,
  });
  Future<Result<void>> importFromJson({                  // Import all tables from a JSON file (replaces current data)
    required File file,
    String? passphrase,
  });
  Future<Result<void>> importMerge({                     // Import from JSON, merging with existing data (no duplicates)
    required File file,
    String? passphrase,
  });
  Future<BackupMetadata> getLastBackupInfo();             // When was the last backup performed
}
```

### BackupMetadata

```dart
class BackupMetadata {
  final DateTime createdAt;
  final String appVersion;
  final int tableCount;
  final Map<String, int> rowCounts;                       // tableName -> row count
  final bool isEncrypted;
}
```

### JSON Structure

```json
{
  "metadata": { "createdAt": "...", "appVersion": "...", "tableCount": 35 },
  "tables": {
    "transactions": [ { ... }, { ... } ],
    "categories": [ { ... } ],
    ...
  }
}
```

---

## 6. ExerciseLibraryService

**Purpose**: Downloads the bundled exercise library on first launch (or on demand) and seeds the Drift `exercises` table. The library is a JSON asset bundled with the app that contains ~300+ exercises with muscle group, equipment type, and instructions.

**Dependencies**: `GymDao`, `AppSettingsDao`

### Key Methods

```dart
class ExerciseLibraryService {
  Future<bool> isLibraryLoaded();                         // Check if exercises have been seeded (via AppSettings flag)
  Future<Result<int>> loadLibrary();                      // Parse bundled JSON asset, bulk insert into exercises table, returns count inserted
  Future<Result<int>> updateLibrary();                    // Re-parse and merge (update existing, insert new, keep custom)
  Future<int> exerciseCount();                            // Current count of library exercises (isCustom == false)
}
```

### Library JSON Format (bundled asset)

```json
[
  {
    "name": "Barbell Bench Press",
    "muscleGroup": "Chest",
    "equipment": "Barbell",
    "instructions": "Lie on bench, grip barbell..."
  }
]
```

---

## 7. ThemeService (ThemeNotifier)

**Purpose**: Manages the custom dark theme with optional variant selection. Unlike other services, this is implemented as a Riverpod Notifier because it holds reactive state (the current theme).

**Dependencies**: `AppSettingsDao`

### Key Methods

```dart
class ThemeNotifier extends Notifier<ThemeState> {
  ThemeData get currentTheme;                              // Build and return the current ThemeData
  Future<void> setAccentColor(Color color);               // Change accent color, persist to AppSettings
  Future<void> setFontScale(double scale);                // Change font scale (0.8 - 1.4), persist
  Future<void> toggleHighContrast();                       // Toggle high-contrast mode
  Future<void> resetToDefaults();                          // Reset all theme settings to defaults
}
```

### ThemeState

```dart
class ThemeState {
  final Color accentColor;                                 // User-selected accent color
  final double fontScale;                                  // Font scale multiplier
  final bool highContrast;                                 // High-contrast mode flag
  final ThemeData themeData;                               // Computed ThemeData object
}
```

### Theme Characteristics

- **Base**: Dark theme (not Material default dark, fully custom)
- **Background**: Near-black surfaces with subtle elevation differences
- **Typography**: Inter or similar clean sans-serif, scaled via fontScale
- **Colors**: User-selectable accent color with generated tonal palette
- **Components**: Custom card styles, bottom nav, app bars matching dark aesthetic
