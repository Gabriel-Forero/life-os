# Business Rules — Unit 4: Habits

## Purpose

Defines all business rules for Unit 4 covering habit creation and editing, frequency and streak logic, check-in and undo flows, archival and restoration, quantitative tracking, EventBus auto-check integration, and reminder scheduling. Each rule includes an ID, description, rationale, and validation criteria.

---

## Habit Creation and Editing Rules

### BR-HAB-01: Habit Name Is Required and Length-Bounded

**Description**: A habit name is required and must be between 1 and 50 characters after trimming whitespace.

**Rationale**: The name is the primary identifier shown in the habit list and on the calendar. An empty or excessively long name breaks the card layout.

**Validation Criteria**:
- `name.trim().isEmpty` → `ValidationFailure(field: 'name', userMessage: "El nombre del hábito es obligatorio")`
- `name.trim().length > 50` → `ValidationFailure(field: 'name', userMessage: "El nombre no puede superar los 50 caracteres")`
- Name is stored trimmed

---

### BR-HAB-02: Habit Name Uniqueness Among Active Habits

**Description**: Habit names must be unique case-insensitively among non-archived habits. Archived habit names are excluded from the uniqueness check. If an archived habit is restored, the uniqueness constraint is re-evaluated at restoration time.

**Rationale**: Duplicate active habit names cause confusion in the habit list and in EventBus auto-check matching.

**Validation Criteria**:
- Before inserting: `SELECT id FROM habits WHERE LOWER(name) = LOWER(:name) AND isArchived = false`
- If a match is found: `ValidationFailure(field: 'name', userMessage: "Ya tienes un hábito activo con ese nombre")`
- When editing: the same check is applied, excluding the habit's own row
- Before restoring an archived habit: re-check uniqueness against current active habits. If a conflict exists: `ConflictFailure(userMessage: "Ya existe un hábito activo con el mismo nombre. Renómbralo antes de restaurarlo")`

---

### BR-HAB-03: Icon and Color Are Required

**Description**: Every habit must have a Material icon name and an ARGB color value. Neither may be left unset.

**Rationale**: The habit card always renders both icon and color. Missing values produce a broken UI state.

**Validation Criteria**:
- `icon.trim().isEmpty` → `ValidationFailure(field: 'icon', userMessage: "Selecciona un icono para el hábito")`
- `color` validation is implicit: any non-zero `int` is accepted. A value of `0x00000000` (fully transparent black) is rejected as visually unusable: `ValidationFailure(field: 'color', userMessage: "Selecciona un color para el hábito")`

---

### BR-HAB-04: Weekly Target Is Required for Weekly Frequency

**Description**: When `frequencyType = weekly`, the `weeklyTarget` field must be provided and must be an integer between 1 and 7 inclusive. When `frequencyType != weekly`, `weeklyTarget` must be null.

**Rationale**: The weekly streak algorithm (Q1:C) counts completed days per ISO week and compares to the target. A missing or out-of-range target makes the computation undefined.

**Validation Criteria**:
- `frequencyType == weekly AND weeklyTarget == null` → `ValidationFailure(field: 'weeklyTarget', userMessage: "Indica cuántas veces a la semana quieres completar este hábito")`
- `frequencyType == weekly AND (weeklyTarget < 1 OR weeklyTarget > 7)` → `ValidationFailure(field: 'weeklyTarget', userMessage: "El objetivo semanal debe estar entre 1 y 7")`
- `frequencyType != weekly AND weeklyTarget != null` → `weeklyTarget` is silently set to null before insert/update

---

### BR-HAB-05: Custom Days Are Required for Custom Frequency

**Description**: When `frequencyType = custom`, the `customDays` list must be provided, must contain at least one element, and all values must be weekday integers in 1 (Monday) – 7 (Sunday). Duplicates are removed before storage. When `frequencyType != custom`, `customDays` must be null.

**Rationale**: Custom frequency relies on `customDays` to determine which days are "applicable" for streak computation. An empty or null list makes the habit effectively never applicable.

**Validation Criteria**:
- `frequencyType == custom AND (customDays == null OR customDays.isEmpty)` → `ValidationFailure(field: 'customDays', userMessage: "Selecciona al menos un día de la semana")`
- `frequencyType == custom AND customDays.any((d) => d < 1 || d > 7)` → `ValidationFailure(field: 'customDays', userMessage: "Los días deben ser valores entre 1 (lunes) y 7 (domingo)")`
- Duplicates in `customDays` are silently removed via `customDays.toSet().toList()..sort()` before storage
- `frequencyType != custom AND customDays != null` → `customDays` is silently set to null before insert/update

---

### BR-HAB-06: Quantitative Fields Must Be Consistent

**Description**: When `isQuantitative = true`, both `quantitativeTarget` and `quantitativeUnit` must be provided. When `isQuantitative = false`, both must be null. Partial combinations are invalid.

**Rationale**: The check-in flow branches based on `isQuantitative`. A habit that claims to be quantitative but lacks a target or unit cannot be meaningfully tracked.

**Validation Criteria**:
- `isQuantitative == true AND quantitativeTarget == null` → `ValidationFailure(field: 'quantitativeTarget', userMessage: "Ingresa el objetivo cuantitativo")`
- `isQuantitative == true AND quantitativeTarget <= 0.0` → `ValidationFailure(field: 'quantitativeTarget', userMessage: "El objetivo debe ser mayor a 0")`
- `isQuantitative == true AND (quantitativeUnit == null OR quantitativeUnit.trim().isEmpty)` → `ValidationFailure(field: 'quantitativeUnit', userMessage: "Indica la unidad de medida (ej. paginas, minutos)")`
- `isQuantitative == true AND quantitativeUnit.trim().length > 20` → `ValidationFailure(field: 'quantitativeUnit', userMessage: "La unidad no puede superar los 20 caracteres")`
- `isQuantitative == false AND quantitativeTarget != null` → silently set to null before insert/update
- `isQuantitative == false AND quantitativeUnit != null` → silently set to null before insert/update

---

### BR-HAB-07: Linked Event Must Be a Recognised Type

**Description**: When `linkedEvent` is non-null, its value must match a recognised EventBus event type name. Currently the only supported value is `"WorkoutCompletedEvent"`.

**Rationale**: An unrecognised `linkedEvent` string would never trigger auto-check, silently producing a habit that appears linked but never automatically completes.

**Validation Criteria**:
- Recognised event types: `{"WorkoutCompletedEvent"}` (set grows as new events are added)
- `linkedEvent != null AND !recognisedEventTypes.contains(linkedEvent)` → `ValidationFailure(field: 'linkedEvent', userMessage: "Evento no reconocido")`
- `linkedEvent == null` is always valid (habit has no auto-check binding)

---

## Frequency and Streak Rules

### BR-HAB-08: Daily Streak Definition (Q1:C)

**Description**: For `frequencyType = daily`, the streak is the count of consecutive calendar days ending on `asOf` (inclusive) for which a qualifying log exists. A qualifying log is one where the habit was completed: boolean habits need any log; quantitative habits need `value >= quantitativeTarget`.

**Rationale**: A missed day (no qualifying log) resets the streak to zero.

**Validation Criteria**:
- `streakCount(habitId, asOf)`:
  1. Start from `asOf` and walk backwards through calendar days
  2. For each day: check if a qualifying log exists (via `getLogForDate(habitId, day)`)
  3. Stop at the first day with no qualifying log
  4. Return the count of consecutive qualifying days found
- A qualifying log for a quantitative habit: `log.value != null AND log.value >= habit.quantitativeTarget`
- A qualifying log for a boolean habit: any row in `habit_logs` for `(habitId, day)`
- Today with no log yet counts as 0 toward the streak; the previous streak is preserved until the day ends (no premature reset)

---

### BR-HAB-09: Weekly Streak Definition (Q1:C)

**Description**: For `frequencyType = weekly`, the streak is the count of consecutive ISO calendar weeks ending on the week containing `asOf` for which the habit was completed at least `weeklyTarget` times with qualifying logs.

**Rationale**: Weekly habits should reward consistent effort over a week regardless of which specific days are chosen.

**Validation Criteria**:
- `streakCount(habitId, asOf)`:
  1. Determine the ISO week of `asOf`
  2. Count qualifying logs within that week; compare to `weeklyTarget`
  3. Walk backwards week by week; stop at the first week where qualifying log count < `weeklyTarget`
  4. Return the count of consecutive qualifying weeks
- A week that has not yet ended (current week) is included in the streak only if it already meets the target
- Partial weeks (at the beginning of habit tracking) are evaluated on available days only if the current ISO week is the first week — otherwise full-week thresholds apply

---

### BR-HAB-10: Custom Streak Definition (Q1:C)

**Description**: For `frequencyType = custom`, the streak is the count of consecutive applicable days ending on the most recent applicable day on or before `asOf` for which a qualifying log exists. Days not in `customDays` are skipped and do not break the streak.

**Rationale**: A habit scheduled only for Monday/Wednesday/Friday should not be broken by the intervening days. Only scheduled days count.

**Validation Criteria**:
- `streakCount(habitId, asOf)`:
  1. Build the list of applicable days: calendar days on or before `asOf` where `weekday` is in `habit.customDays`
  2. Walk backwards through this list; stop at the first applicable day with no qualifying log
  3. Return the count of consecutive qualifying applicable days
- Non-applicable days (weekdays not in `customDays`) are completely ignored in streak evaluation
- A new habit with `customDays` that excludes today still has a 0 streak on day 0 (no applicable days yet completed)

---

## Check-In and Undo Rules

### BR-HAB-11: One Log Per Habit Per Date (Boolean Habits)

**Description**: For boolean (non-quantitative) habits, at most one log may exist per `(habitId, date)` pair. Attempting to check in a habit that already has a log for the given date returns `AlreadyCheckedInFailure`.

**Validation Criteria**:
- Before inserting: `getLogForDate(habitId, date)` — if a row is found: `AlreadyCheckedInFailure(userMessage: "Este hábito ya fue completado hoy")`
- The check and insert are not wrapped in a transaction for this simple case, but the application layer retries on duplicate key violation (race condition guard)

---

### BR-HAB-12: Quantitative Check-In Upserts the Value

**Description**: For quantitative habits, checking in on a date that already has a log replaces the existing `value` rather than creating a duplicate row. The log's `completedAt` is updated to the time of the edit.

**Rationale**: The user may refine their progress count after the initial entry (e.g., they first log 20 pages then update to 35). Accumulation is not supported — the latest value is authoritative.

**Validation Criteria**:
- `value` must be >= 0.0: `ValidationFailure(field: 'value', userMessage: "El valor no puede ser negativo")`
- `null` value is rejected for quantitative habits: `ValidationFailure(field: 'value', userMessage: "Ingresa el valor para este hábito")`
- If a log already exists for `(habitId, date)`: update `value` and `completedAt` via `NutritionDao.updateHabitLog()`. Do not insert a new row.
- If no log exists: insert a new `habit_logs` row.

---

### BR-HAB-13: Quantitative Completion Threshold (Q2:A)

**Description**: A quantitative habit is considered "completed" for a given date if and only if `log.value >= habit.quantitativeTarget`. A log with `value < quantitativeTarget` represents partial progress — it is stored and displayed but does not count as a completed day for streak computation.

**Rationale**: Partial progress should be visible and motivating, but the streak should only reward achieving the goal (Q2:A).

**Validation Criteria**:
- Streak queries use: `isCompleted = (log.value >= habit.quantitativeTarget)`
- The habit list UI shows a partial indicator (e.g., half-filled circle) when `0.0 <= value < quantitativeTarget`
- The habit list UI shows a completion indicator when `value >= quantitativeTarget`
- `HabitWithStatus.isCompletedForDate` uses this threshold
- `HabitWithStatus.isPartialForDate` is true when `log != null AND value < quantitativeTarget`

---

### BR-HAB-14: Undo Check-In (UncheckIn)

**Description**: A check-in can be undone for a given `(habitId, date)` by deleting the corresponding log. This is only allowed for the current day (today) by default. Past dates cannot be unchecked to preserve historical integrity.

**Rationale**: Users may accidentally check in the wrong habit. Same-day undo prevents data corruption while protecting historical streaks.

**Validation Criteria**:
- `uncheckIn(habitId, date)`:
  - If `date != today`: `ValidationFailure(userMessage: "Solo puedes desmarcar el día de hoy")`
  - If no log exists for `(habitId, date)`: `NotFoundFailure(userMessage: "No hay registro para este hábito hoy")`
  - On success: delete the row via `HabitsDao.deleteHabitLog(habitId, date)`. Emit no EventBus event (undo is a correction, not a completion)
- After deletion, the Drift stream for active habits refreshes automatically, updating the UI

---

## Archival and Restoration Rules

### BR-HAB-15: Archive Soft-Deletes the Habit (Q3:A)

**Description**: Archiving a habit sets `isArchived = true` and `updatedAt = now()`. No logs are deleted. The habit is removed from the active habits list and excluded from streak computation while archived. The habit and all its history remain in the database and are restorable.

**Rationale**: Permanent deletion would destroy historical data. Soft-delete allows users to pause or retire a habit while keeping their streak history (Q3:A).

**Validation Criteria**:
- `archiveHabit(habitId)`:
  - Confirm the habit exists and `isArchived = false`: if not found or already archived: `NotFoundFailure`
  - Update: `SET isArchived = true, updatedAt = now()`
  - No logs are deleted or modified
  - The `watchActiveHabits()` stream excludes archived habits immediately upon update

---

### BR-HAB-16: Restore Checks Name Uniqueness Before Unarchiving (Q3:A)

**Description**: Restoring a habit sets `isArchived = false` and `updatedAt = now()`. Before restore, the system re-checks that the habit's name is still unique among active habits. If a conflict exists, the restore is blocked with a descriptive error.

**Rationale**: While the habit was archived, another habit with the same name may have been created. Restoring without checking would silently violate BR-HAB-02.

**Validation Criteria**:
- `restoreHabit(habitId)`:
  - Confirm the habit exists and `isArchived = true`: if not found or already active: `NotFoundFailure`
  - Check name uniqueness: `SELECT id FROM habits WHERE LOWER(name) = LOWER(:name) AND isArchived = false AND id != :habitId`
  - If conflict: `ConflictFailure(userMessage: "Ya existe un hábito activo con el nombre '{name}'. Renómbralo antes de restaurar.")`
  - On success: `SET isArchived = false, updatedAt = now()`

---

### BR-HAB-17: Archived Habits Are Displayed Separately

**Description**: The habit list screen has two distinct sections: an active habits section (the primary view) and an archived habits section (accessible via a secondary tab or expandable section). Active and archived habits are never displayed in the same list.

**Validation Criteria**:
- `watchActiveHabits()` returns only `isArchived = false` rows, ordered by name
- `watchArchivedHabits()` returns only `isArchived = true` rows, ordered by name
- The archived section is only loaded when the user navigates to it (lazy loading to save resources)

---

## EventBus Auto-Check Rules

### BR-HAB-18: Auto-Check on WorkoutCompletedEvent (Q4:A)

**Description**: When a `WorkoutCompletedEvent` is received on the EventBus, `HabitsNotifier.onWorkoutCompleted()` queries for all active non-archived habits where `linkedEvent = 'WorkoutCompletedEvent'` and performs an automatic check-in for today on each of them. Already-completed habits for today are skipped silently.

**Rationale**: Habits that are inherently tied to a workout (e.g., "Hacer ejercicio") should not require a separate manual check-in after the workout is logged (Q4:A).

**Validation Criteria**:
- Trigger: `WorkoutCompletedEvent` fired by Unit 2 (Gym) after a workout session is saved
- Query: `SELECT * FROM habits WHERE linkedEvent = 'WorkoutCompletedEvent' AND isArchived = false`
- For each matched habit:
  - If a qualifying log already exists for today: skip (do not update or duplicate)
  - Otherwise: call `checkIn(habitId: habit.id, date: today)` (with `value = quantitativeTarget` for quantitative habits — auto-check assumes full completion)
  - After each successful auto-check-in: emit `HabitCheckedInEvent` on the EventBus
- All auto-check-ins run sequentially in a single `onWorkoutCompleted()` call
- Failures for individual habits are logged and skipped; they do not block other habits in the batch

---

### BR-HAB-19: Auto-Check Assumes Full Completion for Quantitative Habits

**Description**: When an EventBus auto-check triggers a check-in for a quantitative habit, the logged `value` is set to `habit.quantitativeTarget` (full completion). The auto-check does not ask the user to input a value.

**Rationale**: An EventBus event signals that the corresponding activity was performed. For a habit like "Correr 5km" linked to `WorkoutCompletedEvent`, it is assumed the goal was met. Users can manually edit the value afterward if needed.

**Validation Criteria**:
- Auto-check sets `value = habit.quantitativeTarget` (not null, not zero)
- If the user edits the auto-checked log (via `checkIn()` with a different value), the edit follows BR-HAB-12 (upsert)
- Manual editing of auto-checked logs is always permitted

---

### BR-HAB-20: HabitCheckedInEvent Is Emitted After Every Successful Check-In

**Description**: After every successful manual or automatic check-in, `HabitsNotifier` emits a `HabitCheckedInEvent` on the EventBus. This event carries `habitId`, `date`, and `isAutoChecked` metadata for downstream subscribers.

**Rationale**: Other modules or future features may need to react to habit completions (e.g., a rewards system or a dashboard widget). Emitting on every check-in ensures consistent cross-module communication.

**Validation Criteria**:
- `HabitCheckedInEvent` is emitted after `HabitsDao.insertHabitLog()` or `HabitsDao.updateHabitLog()` returns successfully
- `HabitCheckedInEvent` is NOT emitted on `uncheckIn()` (undo is a correction, not a completion — BR-HAB-14)
- The event must not be emitted on validation or database failures

---

## Reminder Rules

### BR-HAB-21: Reminder Time Format

**Description**: The `reminderTime` field is stored as `"HH:mm"` in 24-hour format. Values outside valid time ranges are rejected. Null disables the reminder for the habit.

**Validation Criteria**:
- `reminderTime` must match the pattern `^([01][0-9]|2[0-3]):[0-5][0-9]$` if non-null
- Invalid format → `ValidationFailure(field: 'reminderTime', userMessage: "Hora de recordatorio inválida")`
- `reminderTime = null` is valid (no reminder)

---

### BR-HAB-22: Reminders Fire Only on Applicable Days

**Description**: A scheduled reminder for a habit with `frequencyType = custom` only fires on days that are in `customDays`. For `daily` habits, reminders fire every day. For `weekly` habits, reminders fire every day of the week (the user decides when to complete their weekly sessions).

**Rationale**: Firing a reminder for a custom habit on a day when it is not scheduled creates unnecessary noise.

**Validation Criteria**:
- `daily` or `weekly` habits with `reminderTime` set: reminder fires every day at the specified time
- `custom` habits with `reminderTime` set: reminder fires only on days where `today.weekday` is in `habit.customDays`
- If the habit is already completed for the day when the reminder fires: suppress the reminder
- If the habit is archived: suppress all reminders

---

## Completion Rate Rule

### BR-HAB-23: Completion Rate Calculation

**Description**: `completionRate(habitId, from, to)` returns the fraction of applicable days in the range `[from, to]` on which the habit was completed (qualifying log present). The range is inclusive on both ends. Future days are excluded.

**Rationale**: Completion rate gives users a performance metric for their habit over a period (e.g., the last 30 days).

**Validation Criteria**:
- `applicableDays`: all days in `[from, min(to, today)]` that are scheduled for the habit (all days for `daily`/`weekly`; only `customDays` weekdays for `custom`)
- `completedDays`: subset of `applicableDays` with a qualifying log
- `completionRate = completedDays.length / applicableDays.length` (returns 0.0 if `applicableDays.isEmpty`)
- Partial quantitative logs (value < target) do not count as completed days (Q2:A)
- Result is a `double` in `[0.0, 1.0]`; displayed as a percentage rounded to the nearest integer (e.g., 0.733 → "73%")
