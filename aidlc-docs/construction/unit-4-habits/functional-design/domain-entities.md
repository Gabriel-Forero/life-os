# Domain Entities — Unit 4: Habits

## Purpose

Defines every domain entity for Unit 4 with complete field specifications, Dart types, constraints, defaults, and descriptions. These definitions drive Drift table generation, input DTOs, value objects, and state objects used by the Habits module across the entire LifeOS application. Streaks are computed on-the-fly by `HabitsDao` based on the `habit_logs` history and the habit's frequency configuration (Q1:C). Quantitative completion requires the logged value to meet or exceed the target; partial progress is tracked but does not count toward the streak (Q2:A). Deleted habits are soft-deleted via the `isArchived` flag — history is fully preserved and habits are restorable (Q3:A). Auto-check integration with the EventBus uses the `linkedEvent` field to match incoming events to habits (Q4:A).

---

## 1. FrequencyType Enum

The three scheduling modes that determine when a habit is expected to be performed and how consecutive completion is evaluated.

| Enum Value | Spanish Label | Streak Unit | Completion Window |
|---|---|---|---|
| `daily` | Diario | Consecutive calendar days | One log per calendar day |
| `weekly` | Semanal | Consecutive calendar weeks | `weeklyTarget` logs in a given ISO week |
| `custom` | Personalizado | Consecutive applicable days | One log per enabled weekday (`customDays`) |

### Dart Enum Definition

```
enum FrequencyType {
  daily, weekly, custom
}
```

Stored in Drift as a `TextColumn` using a `TypeConverter<FrequencyType, String>` that maps the enum name to its string value. Unknown values during deserialization fall back to `FrequencyType.daily` (safe default, logged as warning).

---

## 2. Habits (Drift Table)

The habit definition library. One row per user-defined habit. Active habits are those where `isArchived = false`.

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `name` | `String` | `TextColumn` | Required, minLength: 1, maxLength: 50, trimmed, unique (case-insensitive) among non-archived habits | None (required) | Habit display name (e.g., "Leer", "Meditar", "Correr") |
| `icon` | `String` | `TextColumn` | Required, must be a valid Material icon codepoint name | None (required) | Material icon identifier for the habit card (e.g., `"book"`, `"self_improvement"`) |
| `color` | `int` | `IntColumn` | Required, ARGB integer | None (required) | Display color for the habit card as a 32-bit ARGB int (e.g., `0xFF4CAF50` for green) |
| `frequencyType` | `FrequencyType` | `TextColumn` | Required, stored via TypeConverter | `FrequencyType.daily` | How often the habit is expected to be performed |
| `weeklyTarget` | `int?` | `IntColumn` | Required when `frequencyType = weekly`, must be in 1–7, null otherwise | `null` | Number of times per week the habit must be completed to sustain the weekly streak |
| `customDays` | `String?` | `TextColumn` | Required when `frequencyType = custom`, JSON-encoded `List<int>` of weekday ints 1 (Monday) – 7 (Sunday), at least one element, null otherwise | `null` | The specific weekdays on which the habit is scheduled (custom frequency only) |
| `isQuantitative` | `bool` | `BoolColumn` | Required | `false` | Whether completing this habit requires logging a numeric value (e.g., pages read, steps walked) |
| `quantitativeTarget` | `double?` | `RealColumn` | Required when `isQuantitative = true`, must be > 0.0, null when `isQuantitative = false` | `null` | The minimum value that must be logged to count the habit as completed for the day |
| `quantitativeUnit` | `String?` | `TextColumn` | Required when `isQuantitative = true`, maxLength: 20, trimmed, null otherwise | `null` | Label for the quantitative unit (e.g., `"paginas"`, `"pasos"`, `"minutos"`) |
| `reminderTime` | `String?` | `TextColumn` | Optional, stored as `"HH:mm"` (24-hour), null if no reminder set | `null` | Daily reminder time in 24-hour format. Stored as text because Drift has no native `TimeOfDay` column type |
| `linkedEvent` | `String?` | `TextColumn` | Optional, null if not linked. Must be a recognised EventBus event type name when non-null | `null` | EventBus event type name that triggers an automatic check-in for this habit (e.g., `"WorkoutCompletedEvent"`) |
| `isArchived` | `bool` | `BoolColumn` | Required | `false` | Soft-delete flag. Archived habits are excluded from the active list and from streak computation but retain all historical logs |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp of record creation |
| `updatedAt` | `DateTime` | `DateTimeColumn` | Required, updated on every write | `DateTime.now()` at insert and update | Timestamp of last modification |

### Habits Notes

- **Name uniqueness**: Enforced case-insensitively among non-archived habits at the application layer. An archived habit's name is freed for reuse. If an archived habit is restored, the name uniqueness constraint is re-evaluated before restore (BR-HAB-02).
- **weeklyTarget validation**: Only meaningful when `frequencyType = weekly`. Values outside 1–7 are rejected (BR-HAB-04). When `frequencyType` is changed away from `weekly`, `weeklyTarget` is set to null.
- **customDays validation**: Only meaningful when `frequencyType = custom`. Must contain at least one weekday int in 1–7. Duplicates are removed before storage. When `frequencyType` is changed away from `custom`, `customDays` is set to null (BR-HAB-05).
- **quantitativeTarget and quantitativeUnit**: Both must be non-null together when `isQuantitative = true`, and both null when `isQuantitative = false`. Partial combinations are rejected (BR-HAB-06).
- **reminderTime format**: Stored as `"HH:mm"` string (e.g., `"07:30"`, `"20:00"`). Parsed back to `TimeOfDay` at read time. Malformed values are treated as null with a logged warning.
- **linkedEvent**: When non-null, must match a known EventBus event type. Currently only `"WorkoutCompletedEvent"` is supported. Future event types can be added without schema migration by updating the application layer (Q4:A).
- **Color storage**: The ARGB integer is the `int` value of a Flutter `Color` object (`color.value`). Reconstructed via `Color(argbInt)` at read time.

---

## 3. HabitLogs (Drift Table)

Records each individual check-in event. One row represents one completion of a habit on a given date. Multiple logs on the same date are prevented at the application layer for non-quantitative habits (see BR-HAB-10).

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `habitId` | `int` | `IntColumn` | Required, FK → habits.id (no cascade — logs are preserved when habit is archived) | None (required) | The habit this log belongs to |
| `date` | `DateTime` | `DateTimeColumn` | Required, date portion only (midnight-normalised). Unique per `(habitId, date)` pair (enforced at app layer) | None (required) | The calendar date of the check-in |
| `completedAt` | `DateTime` | `DateTimeColumn` | Required | `DateTime.now()` at insert | Precise timestamp when the check-in was recorded. Used for audit and display purposes |
| `value` | `double?` | `RealColumn` | Required when parent habit `isQuantitative = true`, must be >= 0.0. Null when `isQuantitative = false` | `null` | The numeric value logged for quantitative habits (e.g., 35 paginas, 8000 pasos). May be less than `quantitativeTarget` (partial progress) |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp of row creation |

### HabitLogs Notes

- **One log per (habitId, date)**: Enforced at the application layer. `checkIn()` checks for an existing log via `getLogForDate(habitId, date)` before inserting. If a log already exists, the operation is rejected with `AlreadyCheckedInFailure` unless the habit is quantitative, in which case the log is updated (value is replaced, not accumulated) — see BR-HAB-10.
- **Quantitative partial progress**: A log with `value < quantitativeTarget` is stored and displayed as partial progress but does not count as a completed day for streak purposes (Q2:A). The `value` column is never null for quantitative habits; `0.0` is valid and represents zero progress.
- **Date normalisation**: `date` is always stored as midnight UTC (or local midnight depending on app timezone settings). All streak and completion queries filter by the `date` column, not `completedAt`.
- **No cascade on archive**: Archiving a habit (setting `isArchived = true`) does not delete or otherwise affect `habit_logs` rows. This preserves historical data and enables restoration to the correct streak state (Q3:A).
- **Auto-check logs**: Logs created by the EventBus auto-check flow (`onWorkoutCompleted`) are indistinguishable from manual check-ins at the data layer. There is no `isAutoChecked` flag; the source of truth is always the log's presence.

---

## Input DTOs (Value Objects)

### HabitInput

Carries data from the UI to `HabitsNotifier.addHabit()` and `HabitsNotifier.editHabit()`.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `name` | `String` | Required, 1–50 chars after trim, unique (case-insensitive) among active habits | Habit display name |
| `icon` | `String` | Required, valid Material icon name | Material icon identifier |
| `color` | `int` | Required, valid ARGB int | Display color |
| `frequencyType` | `FrequencyType` | Required | Scheduling frequency |
| `weeklyTarget` | `int?` | Required and 1–7 when `frequencyType = weekly`, null otherwise | Weekly completion target |
| `customDays` | `List<int>?` | Required (length >= 1, values 1–7, no duplicates) when `frequencyType = custom`, null otherwise | Scheduled weekdays |
| `isQuantitative` | `bool` | Required | Whether numeric value is required |
| `quantitativeTarget` | `double?` | Required and > 0.0 when `isQuantitative = true`, null otherwise | Minimum value for completion |
| `quantitativeUnit` | `String?` | Required (1–20 chars after trim) when `isQuantitative = true`, null otherwise | Unit label |
| `reminderTime` | `String?` | Optional, format `"HH:mm"` if provided | Daily reminder time |
| `linkedEvent` | `String?` | Optional, must be a recognised event type if provided | EventBus auto-check binding |

### CheckInInput

Carries data from the UI to `HabitsNotifier.checkIn()`.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `habitId` | `int` | Required, must reference an existing non-archived habit | The habit to check in |
| `date` | `DateTime` | Required, date portion only | The day to log (defaults to today) |
| `value` | `double?` | Required and >= 0.0 when habit `isQuantitative = true`, null otherwise | Numeric value for quantitative check-in |

---

## HabitsState (Notifier State Value Object)

The state exposed by `HabitsNotifier` to the UI layer via Riverpod's `AsyncNotifier`.

```
class HabitsState {
  // Active habit list
  List<HabitWithStatus> activeHabits;     // All non-archived habits with today's completion status

  // Archived habit list (loaded on demand)
  List<Habit> archivedHabits;             // All archived habits (no status needed)

  // Date context
  DateTime selectedDate;                  // The day being viewed (defaults to today)
}
```

---

## HabitWithStatus (Join Result Value Object)

The primary display object. Combines a `Habit` row with its completion status for the selected date and streak information.

| Field | Dart Type | Source | Description |
|---|---|---|---|
| `habit` | `Habit` | habits row | The full habit definition |
| `logForDate` | `HabitLog?` | habit_logs row for `(habitId, selectedDate)` | The check-in log for the viewed date. Null if not yet checked in |
| `currentStreak` | `int` | `HabitsDao.streakCount(habitId, asOf: selectedDate)` | Current consecutive streak count (in the habit's streak unit) |
| `longestStreak` | `int` | `HabitsDao.longestStreak(habitId)` | All-time longest streak for display on the detail screen |

Convenience getters on `HabitWithStatus`:
- `isCompletedForDate` → `logForDate != null && (habit.isQuantitative ? logForDate!.value! >= habit.quantitativeTarget! : true)`
- `isPartialForDate` → `habit.isQuantitative && logForDate != null && logForDate!.value! < habit.quantitativeTarget!`
- `progressFraction` → for quantitative habits: `min(1.0, logForDate?.value ?? 0.0) / habit.quantitativeTarget!`; for boolean habits: `isCompletedForDate ? 1.0 : 0.0`

---

## HabitCalendarData (Value Object)

Used by the habit detail screen to render the completion calendar.

| Field | Dart Type | Source | Description |
|---|---|---|---|
| `habitId` | `int` | parameter | The habit being viewed |
| `from` | `DateTime` | parameter | Start of the calendar range (inclusive) |
| `to` | `DateTime` | parameter | End of the calendar range (inclusive) |
| `logs` | `List<HabitLog>` | `HabitsDao.watchHabitLogs(habitId, from, to)` | All logs in the range |
| `completionRate` | `double` | `HabitsDao.completionRate(habitId, from, to)` | Fraction of applicable days completed in the range (0.0–1.0) |

Convenience method on `HabitCalendarData`:
- `statusForDate(DateTime date)` → `CalendarDayStatus` enum: `completed`, `partial`, `missed`, `notApplicable`, `future`

---

## CalendarDayStatus Enum

Used by the habit calendar to colour-code each day cell.

| Enum Value | Description | Visual |
|---|---|---|
| `completed` | Log exists and value meets target (or boolean check-in present) | Filled circle in habit colour |
| `partial` | Quantitative log exists but value < target | Partially filled circle |
| `missed` | Day was applicable but no log recorded | Empty circle with muted colour |
| `notApplicable` | Day is not a scheduled day for the habit (custom frequency only) | No indicator |
| `future` | Date is after today | Dimmed — no interaction |

---

## Entity Relationship Summary

```
Habit (many rows)
  |-- frequencyType: daily / weekly / custom
  |-- isQuantitative: bool
  |-- linkedEvent: String? (auto-check EventBus binding)
  |-- isArchived: bool (soft delete — history preserved)
  |
  └──< HabitLog (many)
        |-- date: calendar date (one per habit per date, enforced at app layer)
        |-- value: double? (quantitative only)
        |-- completedAt: precise timestamp
        |
        +-- streak computation reads logs to count consecutive periods
        +-- calendar reads logs to colour-code each day cell
        +-- completionRate aggregates logs over a date range

EventBus integrations in HabitsNotifier:
  |-- Emits   HabitCheckedInEvent  → after every successful checkIn()
  └── Subscribes WorkoutCompletedEvent → onWorkoutCompleted()
        └── auto-checks all active habits where linkedEvent = 'WorkoutCompletedEvent'
```
