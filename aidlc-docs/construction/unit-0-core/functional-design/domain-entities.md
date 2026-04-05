# Domain Entities -- Unit 0: Core Foundation

## Purpose

Defines every domain entity for Unit 0 with complete field specifications, Dart types, constraints, defaults, and descriptions. These definitions drive Drift table generation, sealed class hierarchies, and value objects used across the entire LifeOS application.

---

## 1. AppSettings (Drift Table)

Single-row table storing all user preferences and app configuration. Accessed via a lightweight Riverpod provider (no full DAO class).

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier (always 1 for single-row pattern) |
| `userName` | `String` | `TextColumn` | Required, minLength: 1, maxLength: 50, trimmed (no leading/trailing whitespace) | None (required during onboarding) | User display name shown in greetings and Dashboard |
| `language` | `String` | `TextColumn` | Required, enum: `'es'`, `'en'` | `'es'` | UI language / locale code |
| `currency` | `String` | `TextColumn` | Required, ISO 4217 code (3 uppercase letters), validated against known currency list | `'COP'` | Currency used in Finance module for display formatting |
| `primaryGoal` | `String` | `TextColumn` | Required, enum: `'save_money'`, `'get_fit'`, `'be_disciplined'`, `'balance'` | None (required during onboarding) | User primary motivation, used by Dashboard and Intelligence for prioritization |
| `enabledModules` | `String` | `TextColumn` | Required, JSON-encoded `List<String>` of module IDs, at least 1 module required | `'["finance"]'` | Active modules shown in navigation and Dashboard. Valid IDs: `finance`, `gym`, `nutrition`, `habits`, `sleep`, `mental`, `goals` |
| `themeMode` | `String` | `TextColumn` | Required, enum: `'dark'`, `'light'`, `'system'` | `'dark'` | Theme mode selection |
| `useBiometric` | `bool` | `BoolColumn` | Required | `false` | Whether biometric lock is enabled on app launch |
| `onboardingCompleted` | `bool` | `BoolColumn` | Required | `false` | Flag indicating onboarding wizard has been completed |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp of initial record creation |
| `updatedAt` | `DateTime` | `DateTimeColumn` | Required, updated on every write | `DateTime.now()` at insert and update | Timestamp of last modification |

### AppSettings Notes

- **Single-row pattern**: The table always contains exactly one row (id = 1). On first launch, the row is inserted with defaults during onboarding. Subsequent operations are updates only.
- **enabledModules encoding**: Stored as a JSON string (`'["finance","gym","habits"]'`). Decoded to `List<String>` via a Drift `TypeConverter` or extension method. The list must always contain at least one valid module ID.
- **primaryGoal mapping** (for UI labels):
  - `'save_money'` = "Ahorrar" (ES) / "Save Money" (EN)
  - `'get_fit'` = "Ponerme en forma" (ES) / "Get Fit" (EN)
  - `'be_disciplined'` = "Ser mas disciplinado" (ES) / "Be Disciplined" (EN)
  - `'balance'` = "Equilibrio general" (ES) / "Life Balance" (EN)
- **currency validation**: Although stored as a 3-letter string, the app maintains a curated list of supported currencies (COP, USD, EUR, MXN, ARS, PEN, CLP, BRL, GBP, CAD, and others). The Onboarding screen provides a searchable picker from this list.

---

## 2. AppEvent (Sealed Class Hierarchy -- EventBus)

Typed event hierarchy used by the EventBus for decoupled cross-module communication. All events are immutable value objects. The base class provides a `timestamp` field that is automatically set at creation time.

### Base Class

```
sealed class AppEvent
  Fields:
    - timestamp: DateTime (required, default: DateTime.now(), immutable)
      Auto-assigned at construction. Used for ordering, deduplication, and audit logging.
```

### Event Subclasses

#### 2.1 WorkoutCompletedEvent

Emitted by GymNotifier when a workout is finished (finishedAt set).

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `workoutId` | `int` | Required, positive | Drift row ID of the completed workout |
| `duration` | `Duration` | Required, non-negative | Total workout duration (finishedAt - startedAt) |
| `totalVolume` | `double` | Required, non-negative | Sum of (weight x reps) across all non-warmup sets in the workout |

#### 2.2 ExpenseAddedEvent

Emitted by FinanceNotifier when a new expense transaction is inserted.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `transactionId` | `int` | Required, positive | Drift row ID of the new transaction |
| `categoryName` | `String` | Required, non-empty | Display name of the transaction category (denormalized for subscriber convenience) |
| `amount` | `double` | Required, positive | Transaction amount in user currency |

#### 2.3 BudgetThresholdEvent

Emitted by FinanceNotifier when spending in a budget category crosses the 80% or 100% threshold.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `budgetId` | `int` | Required, positive | Drift row ID of the budget |
| `categoryName` | `String` | Required, non-empty | Display name of the budget category (denormalized) |
| `percentage` | `double` | Required, range 0.0 to unlimited (can exceed 1.0) | Current budget utilization as a fraction (0.8 = 80%, 1.0 = 100%, 1.2 = 120% overspent) |

#### 2.4 HabitCheckedInEvent

Emitted by HabitsNotifier when a habit is checked in (marked complete or skipped) for a date.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `habitId` | `int` | Required, positive | Drift row ID of the habit |
| `habitName` | `String` | Required, non-empty | Display name of the habit (denormalized) |
| `isCompleted` | `bool` | Required | `true` if the habit was completed, `false` if skipped |

#### 2.5 SleepLogSavedEvent

Emitted by SleepNotifier when a sleep log entry is saved.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `sleepLogId` | `int` | Required, positive | Drift row ID of the sleep log |
| `sleepScore` | `int` | Required, range 0-100 | Computed sleep quality score |
| `hoursSlept` | `double` | Required, range 0.0-24.0 | Total hours slept (decimal) |

#### 2.6 MoodLoggedEvent

Emitted by MentalNotifier when a mood entry is logged.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `moodLogId` | `int` | Required, positive | Drift row ID of the mood log |
| `level` | `int` | Required, range 1-5 | Mood intensity level (1 = very low, 5 = very high) |
| `tags` | `List<String>` | Required (may be empty list) | User-selected mood tags (e.g., "stressed", "energetic", "calm") |

#### 2.7 GoalProgressUpdatedEvent

Emitted by GoalsNotifier when progress on a life goal changes.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `goalId` | `int` | Required, positive | Drift row ID of the life goal |
| `progress` | `int` | Required, range 0-100 | Current goal completion percentage |

---

## 3. AppFailure (Sealed Class Hierarchy -- Error Handling)

Business-layer error types used with the `Result<T>` pattern. Each failure carries a `userMessage` (localized, safe to display in UI) and a `debugMessage` (for logging, may contain technical details). The base class is sealed to enable exhaustive pattern matching.

### Base Class

```
sealed class AppFailure
  Fields:
    - userMessage: String (required, non-empty, localized for display to user)
    - debugMessage: String (required, non-empty, for logging and debugging only)
```

### Failure Subclasses

#### 3.1 DatabaseFailure

Wraps SQLite/Drift errors such as constraint violations, migration failures, or I/O errors.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `userMessage` | `String` | Required, non-empty | Localized message (e.g., "Error al guardar datos" / "Error saving data") |
| `debugMessage` | `String` | Required, non-empty | Technical detail (e.g., "UNIQUE constraint failed: transactions.id") |
| `originalError` | `Object?` | Optional | The original exception caught from Drift/SQLite |

#### 3.2 NetworkFailure

Wraps HTTP/network errors from API calls (Open Food Facts, AI providers).

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `userMessage` | `String` | Required, non-empty | Localized message (e.g., "Sin conexion a internet" / "No internet connection") |
| `debugMessage` | `String` | Required, non-empty | Technical detail (e.g., "GET https://api.openfoodfacts.org/... returned 503") |
| `statusCode` | `int?` | Optional, range 100-599 if present | HTTP status code, null for connection timeouts or DNS failures |
| `url` | `String?` | Optional | The URL that failed, for debugging context |

#### 3.3 ValidationFailure

Represents business rule violations caught during input validation before persistence.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `userMessage` | `String` | Required, non-empty | Localized message (e.g., "El nombre es obligatorio" / "Name is required") |
| `debugMessage` | `String` | Required, non-empty | Technical detail (e.g., "userName failed minLength(1) check") |
| `field` | `String?` | Optional | The field name that failed validation (e.g., `'userName'`, `'amount'`) |
| `value` | `Object?` | Optional | The invalid value that was provided (for debugging, NEVER shown to user) |

#### 3.4 NotFoundFailure

Represents a lookup for an entity that does not exist in the database.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `userMessage` | `String` | Required, non-empty | Localized message (e.g., "Transaccion no encontrada" / "Transaction not found") |
| `debugMessage` | `String` | Required, non-empty | Technical detail (e.g., "Transaction with id=42 not found") |
| `entityType` | `String` | Required, non-empty | The type of entity (e.g., `'Transaction'`, `'Workout'`, `'Habit'`) |
| `entityId` | `Object` | Required | The ID that was looked up (usually `int`, but kept as `Object` for flexibility) |

#### 3.5 PermissionFailure

Represents a denied platform permission (notifications, biometrics, file access).

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `userMessage` | `String` | Required, non-empty | Localized message (e.g., "Se necesita permiso de notificaciones" / "Notification permission required") |
| `debugMessage` | `String` | Required, non-empty | Technical detail (e.g., "notification permission denied by user") |
| `permission` | `String` | Required, non-empty | The permission type (e.g., `'notification'`, `'biometric'`, `'storage'`) |

#### 3.6 BackupFailure

Represents errors during backup export or import operations.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `userMessage` | `String` | Required, non-empty | Localized message (e.g., "Error al exportar respaldo" / "Backup export failed") |
| `debugMessage` | `String` | Required, non-empty | Technical detail (e.g., "Failed to serialize finance module: OutOfMemoryError") |
| `phase` | `String` | Required, enum: `'export'`, `'import'`, `'validate'` | Which backup operation phase failed |

#### 3.7 AuthFailure

Represents biometric authentication failure.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `userMessage` | `String` | Required, non-empty | Localized message (e.g., "Autenticacion fallida" / "Authentication failed") |
| `debugMessage` | `String` | Required, non-empty | Technical detail (e.g., "local_auth returned AuthenticationException: notAvailable") |

---

## 4. BackupManifest (Value Object)

Metadata object stored as `manifest.json` at the root of the backup ZIP archive. Used to validate backup integrity and compatibility before importing.

| Field | Dart Type | Constraints | Default | Description |
|---|---|---|---|---|
| `appVersion` | `String` | Required, non-empty, semantic versioning format (e.g., `'1.2.3'`) | Current app version at export time | The LifeOS version that created this backup |
| `exportDate` | `DateTime` | Required | `DateTime.now()` at export time | Exact timestamp when the backup was created |
| `deviceInfo` | `String` | Required, non-empty | Populated from `device_info_plus` | Device model and OS version (e.g., "Samsung Galaxy S24 - Android 15") |
| `modules` | `List<BackupModuleEntry>` | Required, at least 1 entry | Populated from enabled modules | List of modules included in the backup with record counts |
| `driftSchemaVersion` | `int` | Required, positive | Current Drift schema version at export time | The Drift database schema version, used for migration compatibility check on import |

### BackupModuleEntry (Nested Value Object)

Each entry in the `modules` list of the BackupManifest.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `name` | `String` | Required, non-empty, must match a valid module ID (`settings`, `finance`, `gym`, `nutrition`, `habits`, `sleep`, `mental`, `goals`, `intelligence`, `dayscore`) | Module identifier matching the JSON filename in the ZIP |
| `recordCount` | `int` | Required, non-negative | Total number of records exported for this module across all its tables |

### BackupManifest JSON Structure

```json
{
  "appVersion": "1.0.0",
  "exportDate": "2026-04-03T14:30:00Z",
  "deviceInfo": "Samsung Galaxy S24 - Android 15",
  "driftSchemaVersion": 1,
  "modules": [
    { "name": "settings", "recordCount": 1 },
    { "name": "finance", "recordCount": 247 },
    { "name": "gym", "recordCount": 512 },
    { "name": "habits", "recordCount": 89 }
  ]
}
```

### BackupManifest Serialization

- **toJson()**: Converts to `Map<String, dynamic>` for JSON encoding. `exportDate` serialized as ISO 8601 string.
- **fromJson(Map<String, dynamic>)**: Factory constructor that parses and validates all fields. Throws `FormatException` on invalid data (caught by BackupService and wrapped in `BackupFailure`).

---

## 5. NotificationConfig (Value Object)

Configuration for each notification type in the app. Stored as part of AppSettings or as a separate lightweight structure. Each notification type is independently configurable.

### NotificationType Enum

| Value | Description | Default Enabled | Default Time |
|---|---|---|---|
| `habitReminder` | Daily reminder to check in habits | `false` | 09:00 |
| `budgetAlert` | Alert when a budget threshold is crossed (80% or 100%) | `false` | Immediate (triggered by event, not scheduled) |
| `waterReminder` | Periodic reminder to log water intake | `false` | Every 2 hours between 08:00 and 22:00 |
| `sleepBedtime` | Bedtime reminder based on desired sleep schedule | `false` | 22:00 |
| `recurringTransaction` | Reminder to review recurring transactions due today | `false` | 08:00 |

### NotificationConfig Fields

| Field | Dart Type | Constraints | Default | Description |
|---|---|---|---|---|
| `type` | `NotificationType` | Required | N/A (identifies the config) | Which notification this configuration is for |
| `enabled` | `bool` | Required | `false` | Whether this notification type is active |
| `time` | `TimeOfDay?` | Optional (required if type uses scheduled time) | See defaults per type above | The time of day to fire the notification (in user local timezone) |
| `repeatRule` | `RepeatRule` | Required | Varies by type | How often the notification repeats |

### RepeatRule Enum

| Value | Description | Used By |
|---|---|---|
| `daily` | Fire once per day at the specified time | `habitReminder`, `sleepBedtime`, `recurringTransaction` |
| `interval` | Fire at regular intervals within a time window | `waterReminder` (every 2 hours, 08:00-22:00) |
| `eventDriven` | Fire immediately when a triggering event occurs | `budgetAlert` |

### NotificationConfig Storage

Notification configurations are serialized as a JSON map and stored in the `AppSettings` table (or in a dedicated `notification_configs` column). Example:

```json
{
  "habitReminder": { "enabled": true, "time": "09:00", "repeatRule": "daily" },
  "budgetAlert": { "enabled": true, "time": null, "repeatRule": "eventDriven" },
  "waterReminder": { "enabled": false, "time": "08:00", "repeatRule": "interval" },
  "sleepBedtime": { "enabled": false, "time": "22:00", "repeatRule": "daily" },
  "recurringTransaction": { "enabled": false, "time": "08:00", "repeatRule": "daily" }
}
```

### NotificationConfig Serialization

- **toJson()**: Converts to `Map<String, dynamic>`. `TimeOfDay` serialized as `"HH:mm"` string. `null` time for event-driven types.
- **fromJson(Map<String, dynamic>)**: Factory constructor that parses and validates. Returns default config if JSON is malformed (graceful degradation, never crashes).

---

## Entity Relationship Summary

```
AppSettings (1 row)
  |-- stores --> enabledModules (JSON list of module IDs)
  |-- stores --> NotificationConfig (JSON map per notification type)
  |-- read by --> OnboardingNotifier, ThemeNotifier, all modules (for locale/currency)

AppEvent (sealed class, in-memory only)
  |-- emitted by --> Feature Notifiers (Gym, Finance, Habits, Sleep, Mental, Goals)
  |-- consumed by --> Other Notifiers, NotificationService, DayScoreNotifier
  |-- transported via --> EventBus (StreamController.broadcast)

AppFailure (sealed class, in-memory only)
  |-- returned in --> Result<T>.Failure
  |-- converted to --> AsyncValue.error in Notifier layer
  |-- displayed as --> userMessage in UI snackbars/dialogs

BackupManifest (value object, persisted as manifest.json in ZIP)
  |-- contains --> List<BackupModuleEntry>
  |-- validated by --> BackupService on import
  |-- created by --> BackupService on export

NotificationConfig (value object, persisted in AppSettings JSON)
  |-- managed by --> NotificationService
  |-- scheduled via --> flutter_local_notifications
```
