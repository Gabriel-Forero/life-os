# Business Logic Model — Unit 4: Habits

## Purpose

Defines the step-by-step business logic flows for Unit 4. Each flow describes operations, decision points, error paths, and expected outcomes. Pseudocode is used for algorithmic sections. All flows execute within `HabitsNotifier` and `HabitsDao` layers, with EventBus integrations handled by the notifier's subscription callbacks.

---

## 1. Create Habit Flow

The primary flow for defining a new habit. The user configures the habit's name, appearance, frequency, optional quantitative target, optional reminder, and optional EventBus link.

### Flow Steps

1. User taps "Agregar hábito" on the Habits screen.
2. `HabitFormScreen` opens with all fields empty. `frequencyType` defaults to `FrequencyType.daily`. `isQuantitative` defaults to `false`.
3. User fills in required fields: name, icon, color, and frequency configuration.
   - If `frequencyType = weekly`: show `weeklyTarget` spinner (1–7).
   - If `frequencyType = custom`: show weekday selector (Mon–Sun, multi-select).
4. User optionally enables quantitative tracking. If enabled: show `quantitativeTarget` and `quantitativeUnit` fields.
5. User optionally sets a reminder time. If set: show a time picker; store as `"HH:mm"`.
6. User optionally links an EventBus event from a picker. Currently only "WorkoutCompletedEvent" is available (BR-HAB-07).
7. User taps "Guardar".
8. **Validate `HabitInput`** (BR-HAB-01 through BR-HAB-07):
   ```
   errors = []
   if name.trim().isEmpty OR name.trim().length > 50: errors += name error
   if icon.trim().isEmpty: errors += icon error
   if color == 0x00000000: errors += color error
   if frequencyType == weekly:
     if weeklyTarget == null OR weeklyTarget < 1 OR weeklyTarget > 7: errors += weeklyTarget error
   if frequencyType == custom:
     if customDays == null OR customDays.isEmpty: errors += customDays error
     if customDays.any((d) => d < 1 || d > 7): errors += customDays range error
   if isQuantitative:
     if quantitativeTarget == null OR quantitativeTarget <= 0.0: errors += target error
     if quantitativeUnit == null OR quantitativeUnit.trim().isEmpty: errors += unit error
     if quantitativeUnit.trim().length > 20: errors += unit length error
   if reminderTime != null AND !validTimeFormat(reminderTime): errors += reminder error
   if linkedEvent != null AND !recognisedEventTypes.contains(linkedEvent): errors += event error
   ```
   - If `errors.isNotEmpty`: show inline validation errors. Stay on form.
9. **Check name uniqueness** (BR-HAB-02):
   - Query `SELECT id FROM habits WHERE LOWER(name) = LOWER(:name) AND isArchived = false`
   - If match found: `ValidationFailure`. Show inline error. Stay on form.
10. Build `HabitsCompanion`:
    - Normalise `customDays` if present: `.toSet().toList()..sort()`
    - Set `isArchived = false`, `createdAt = now()`, `updatedAt = now()`
11. Call `HabitsDao.insertHabit(companion)`. Receive `habitId`.
12. If `reminderTime` is set: schedule the local notification for the habit's reminder time (BR-HAB-22).
13. On success: navigate back to the Habits screen. `watchActiveHabits()` stream emits, list refreshes.

### Error Paths

- **Validation failure**: Inline errors on offending fields. Form stays open.
- **Name conflict**: Inline error "Ya tienes un hábito activo con ese nombre".
- **Database failure**: `DatabaseFailure`. Snackbar "Error al guardar el hábito". Retry available.

### Expected Outcomes

- **Success**: New row in `habits`. Habit appears in the active list immediately.
- **Failure**: No row inserted. User corrects and retries.

---

## 2. Edit Habit Flow

The user modifies an existing active habit's configuration. Logs are not affected by edits.

### Flow Steps

1. User long-presses or taps the edit action on an active habit card.
2. `HabitFormScreen` opens pre-filled with the habit's current values.
3. User modifies any fields.
4. **Validate `HabitInput`** — same as steps 8–9 of Flow 1, but name uniqueness check excludes the habit's own `id`.
5. Call `HabitsNotifier.editHabit(habitId, input)`:
   - Build updated `HabitsCompanion` with `updatedAt = now()`
   - Call `HabitsDao.updateHabit(habitId, companion)`
6. **Reminder reschedule**: If `reminderTime` changed, cancel the old notification and schedule a new one. If `reminderTime` was set to null, cancel the notification.
7. On success: navigate back. Drift stream emits; habit list refreshes with new values.

### Error Paths

- **Validation failure**: Inline errors. Form stays open.
- **Not found**: Habit was archived or deleted concurrently. `NotFoundFailure`. Navigate back with snackbar "El hábito ya no existe".
- **Database failure**: `DatabaseFailure`. Snackbar. Form stays open.

### Expected Outcomes

- **Success**: `habits` row updated. List reflects new name/icon/color/frequency.
- **Frequency change side effect**: If `frequencyType` changed (e.g., from `daily` to `custom`), streak counts are immediately recomputed under the new definition. Historical logs are unaffected.

---

## 3. Check-In Flow (Manual)

The primary daily interaction. The user marks a habit as done for today.

### Flow Steps

1. User taps the check-in button on a habit card for today.
2. **Branch on `isQuantitative`**:
   - 2a. **Boolean habit**: go to step 3.
   - 2b. **Quantitative habit**: a value input sheet appears. User enters a numeric value (>= 0). Validate: `value >= 0.0`. Go to step 4 with the entered value.
3. **Check for existing log** (BR-HAB-11):
   ```
   existingLog = HabitsDao.getLogForDate(habitId, today)
   if existingLog != null (boolean habit):
     return AlreadyCheckedInFailure
   ```
4. **Build log**:
   ```
   log = HabitLogsCompanion(
     habitId:     habitId,
     date:        today (midnight-normalised),
     completedAt: DateTime.now(),
     value:       value (null for boolean, entered value for quantitative),
     createdAt:   DateTime.now(),
   )
   ```
5. **Upsert logic** (BR-HAB-12 for quantitative, BR-HAB-11 for boolean):
   ```
   if isQuantitative AND existingLog != null:
     HabitsDao.updateHabitLog(existingLog.id, newValue: value, completedAt: now())
   else:
     HabitsDao.insertHabitLog(log)
   ```
6. **Emit EventBus event** (BR-HAB-20):
   ```
   eventBus.emit(HabitCheckedInEvent(
     habitId:      habitId,
     date:         today,
     isAutoChecked: false,
   ))
   ```
7. `watchActiveHabits()` stream emits; the habit card updates to show the completion indicator.

### Completion Indicator Logic

- **Boolean habit, log exists**: show filled circle in habit colour.
- **Quantitative habit, value >= target**: show filled circle in habit colour.
- **Quantitative habit, 0 <= value < target**: show partial circle (progress arc) with percentage label.
- **No log**: show empty circle.

### Error Paths

- **Already checked in (boolean)**: `AlreadyCheckedInFailure`. Show snackbar "Este hábito ya fue completado hoy".
- **Invalid value (quantitative)**: `ValidationFailure`. Value input sheet shows inline error.
- **Database failure**: `DatabaseFailure`. Snackbar. No row inserted/updated.

### Expected Outcomes

- **Boolean success**: New `habit_logs` row. Card shows completion. Streak may increment.
- **Quantitative success (new)**: New `habit_logs` row with `value`. Partial or full indicator shown.
- **Quantitative success (update)**: Existing row updated. Progress indicator updates.

---

## 4. UncheckIn Flow (Undo Today's Check-In)

The user undoes an accidental check-in for the current day.

### Flow Steps

1. User long-presses a completed habit card, revealing the "Desmarcar" action.
2. Call `HabitsNotifier.uncheckIn(habitId, date: today)`.
3. **Validate date** (BR-HAB-14):
   ```
   if date != today:
     return ValidationFailure(userMessage: "Solo puedes desmarcar el día de hoy")
   ```
4. **Find existing log**:
   ```
   existingLog = HabitsDao.getLogForDate(habitId, today)
   if existingLog == null:
     return NotFoundFailure(userMessage: "No hay registro para este hábito hoy")
   ```
5. Call `HabitsDao.deleteHabitLog(habitId, today)`.
6. **Do NOT emit** `HabitCheckedInEvent` (BR-HAB-14 — undo is a correction, not a completion).
7. Drift stream emits; habit card reverts to unchecked state.

### Error Paths

- **Date not today**: `ValidationFailure`. Snackbar "Solo puedes desmarcar el día de hoy".
- **Log not found**: `NotFoundFailure`. Snackbar "No hay registro para desmarcar".
- **Database failure**: `DatabaseFailure`. Snackbar. Log not deleted.

### Expected Outcomes

- **Success**: `habit_logs` row deleted. Card reverts to empty circle. Streak decrements if today was part of it.

---

## 5. Archive and Restore Flow

### Part A — Archive

1. User taps "Archivar" on an active habit (from long-press menu or detail screen).
2. Show confirmation dialog: "¿Archivar '{habit.name}'? No se eliminará tu historial."
3. User confirms.
4. Call `HabitsNotifier.archiveHabit(habitId)` (BR-HAB-15):
   ```
   HabitsDao.archiveHabit(habitId)
     → UPDATE habits SET isArchived = true, updatedAt = now() WHERE id = :habitId
   ```
5. Cancel any scheduled reminder notification for this habit (BR-HAB-22).
6. `watchActiveHabits()` stream emits; habit disappears from the active list immediately.
7. Show snackbar: "Hábito archivado" with an "Deshacer" action (triggers Part B within 5 seconds).

### Part B — Restore

1. User navigates to the Archived section (or taps "Deshacer" on the snackbar).
2. User selects a habit and taps "Restaurar".
3. Call `HabitsNotifier.restoreHabit(habitId)` (BR-HAB-16):
   ```
   existingConflict = SELECT id FROM habits
     WHERE LOWER(name) = LOWER(:habitName)
     AND isArchived = false
     AND id != :habitId
   if existingConflict != null:
     return ConflictFailure(userMessage: "Ya existe un hábito activo con el nombre '{name}'. Renómbralo antes de restaurar.")
   
   HabitsDao.restoreHabit(habitId)
     → UPDATE habits SET isArchived = false, updatedAt = now() WHERE id = :habitId
   ```
4. Re-schedule the reminder notification if `reminderTime` is set (BR-HAB-22).
5. `watchActiveHabits()` stream emits; restored habit appears in the active list.
6. Show snackbar: "Hábito restaurado".

### Error Paths

- **Archive — habit not found or already archived**: `NotFoundFailure`. Snackbar.
- **Restore — name conflict**: `ConflictFailure`. Show dialog with conflict details. User must edit the active habit's name first.
- **Database failure**: `DatabaseFailure`. Snackbar. State unchanged.

### Expected Outcomes

- **Archive**: Habit hidden from active list. All logs preserved. Reminder cancelled.
- **Restore**: Habit returns to active list with full streak history intact. Reminder re-enabled.

---

## 6. Streak Computation Flow

Streak computation is performed by `HabitsDao` as a SQL query. `HabitsNotifier` calls it when building `HabitWithStatus` objects.

### Daily Streak Algorithm

```
streakCount(habitId, asOf):
  count = 0
  day = asOf
  loop:
    log = getLogForDate(habitId, day)
    isCompleted = log != null AND (
      habit.isQuantitative ? log.value >= habit.quantitativeTarget : true
    )
    if NOT isCompleted:
      break
    count += 1
    day = day - 1 day
  return count
```

### Weekly Streak Algorithm

```
streakCount(habitId, asOf):
  count = 0
  weekStart = startOfIsoWeek(asOf)
  loop:
    weekEnd = weekStart + 6 days
    logs = watchHabitLogs(habitId, from: weekStart, to: min(weekEnd, today))
    qualifyingLogsInWeek = logs.where((log) =>
      habit.isQuantitative ? log.value >= habit.quantitativeTarget : true
    )
    if qualifyingLogsInWeek.length < habit.weeklyTarget:
      break
    count += 1
    weekStart = weekStart - 7 days
  return count
```

### Custom Streak Algorithm

```
streakCount(habitId, asOf):
  count = 0
  day = mostRecentApplicableDay(asOf, habit.customDays)
  // mostRecentApplicableDay: walk backwards from asOf to find the last day
  // whose weekday is in customDays
  loop:
    if day == null: break
    log = getLogForDate(habitId, day)
    isCompleted = log != null AND (
      habit.isQuantitative ? log.value >= habit.quantitativeTarget : true
    )
    if NOT isCompleted:
      break
    count += 1
    day = previousApplicableDay(day, habit.customDays)
    // previousApplicableDay: walk backwards from (day - 1) to find the
    // next applicable day
  return count
```

### Longest Streak Algorithm

```
longestStreak(habitId):
  // Walk the full log history for the habit
  // For daily: find the longest run of consecutive qualifying days
  // For weekly: find the longest run of consecutive qualifying weeks
  // For custom: find the longest run of consecutive qualifying applicable days
  // Implementation: fetch all logs ordered by date ascending, then run
  // a single-pass scan tracking currentRun and maxRun
  return maxRun
```

---

## 7. Habit Calendar View Flow

Renders a month-level calendar on the habit detail screen. Each day is colour-coded by `CalendarDayStatus`.

### Flow Steps

1. User opens the detail screen for a habit. The calendar defaults to the current month.
2. `HabitsNotifier` calls `HabitsDao.watchHabitLogs(habitId, from: monthStart, to: monthEnd)`. The Drift watch stream provides live updates.
3. For each calendar day in the visible month:
   ```
   statusForDate(day):
     if day > today: return CalendarDayStatus.future
     if habit.frequencyType == custom AND day.weekday NOT in habit.customDays:
       return CalendarDayStatus.notApplicable
     log = logs.firstWhereOrNull((l) => l.date == day)
     if log == null: return CalendarDayStatus.missed
     if habit.isQuantitative:
       if log.value >= habit.quantitativeTarget: return CalendarDayStatus.completed
       else: return CalendarDayStatus.partial
     else:
       return CalendarDayStatus.completed
   ```
4. Render the grid:
   - `completed` → filled circle in `habit.color`
   - `partial` → arc segment in `habit.color`, proportional to `value / quantitativeTarget`
   - `missed` → empty circle, muted grey
   - `notApplicable` → no indicator (blank cell)
   - `future` → dimmed date number, no indicator, no tap interaction
5. Display the completion rate for the visible month below the calendar:
   - `rate = HabitsDao.completionRate(habitId, from: monthStart, to: min(monthEnd, today))`
   - Format: "73% de los días aplicables" (or "73% de los días" for daily habits)
6. User can swipe left/right to navigate months. Each navigation triggers a new `watchHabitLogs()` call for the new month range.

### Error Paths

- **No logs in month**: All applicable days show `missed`, future days show `future`. Completion rate: 0%.
- **Database failure**: Error state in detail screen. Retry button.

---

## 8. Auto-Check on WorkoutCompletedEvent Flow

Triggered by the EventBus when a workout session is saved by Unit 2 (Gym).

### Flow Steps

1. `HabitsNotifier` subscribes to `WorkoutCompletedEvent` during its `build()` lifecycle.
2. `WorkoutCompletedEvent` fires (emitted by `GymNotifier.saveWorkout()`).
3. `HabitsNotifier.onWorkoutCompleted(event)` is called:
   ```
   linkedHabits = await HabitsDao.getLinkedHabits(eventType: 'WorkoutCompletedEvent')
   // SELECT * FROM habits WHERE linkedEvent = 'WorkoutCompletedEvent' AND isArchived = false
   ```
4. For each habit in `linkedHabits`:
   ```
   existingLog = await HabitsDao.getLogForDate(habit.id, today)
   if isAlreadyCompleted(habit, existingLog):
     continue  // skip silently
   
   value = habit.isQuantitative ? habit.quantitativeTarget : null
   
   try:
     if existingLog != null AND habit.isQuantitative:
       // existing partial log — update to full target
       await HabitsDao.updateHabitLog(existingLog.id, value: value, completedAt: now())
     else if existingLog == null:
       await HabitsDao.insertHabitLog(HabitLogsCompanion(
         habitId:     habit.id,
         date:        today,
         completedAt: now(),
         value:       value,
         createdAt:   now(),
       ))
     
     eventBus.emit(HabitCheckedInEvent(
       habitId:      habit.id,
       date:         today,
       isAutoChecked: true,
     ))
   catch DatabaseFailure as e:
     log.warning('Auto-check failed for habit ${habit.id}: $e')
     continue  // failure for one habit does not block others
   ```
5. After processing all habits: `watchActiveHabits()` stream emits (triggered by Drift's reactive query system), updating the habits screen.

### isAlreadyCompleted helper

```
isAlreadyCompleted(habit, log):
  if log == null: return false
  if habit.isQuantitative: return log.value >= habit.quantitativeTarget
  return true  // boolean habit — any log counts as completed
```

### Error Paths

- **No linked habits**: Loop executes zero iterations. No side effects.
- **Individual habit database failure**: Logged as warning. Processing continues for remaining habits.
- **All habits fail**: No EventBus events emitted. The workout save is unaffected (auto-check failure is non-fatal to Unit 2).

### Expected Outcomes

- **Normal**: All linked habits checked in for today. `HabitCheckedInEvent` emitted for each. UI updates automatically.
- **Already completed**: Skipped silently. No duplicate logs. No event emitted for the skipped habit.
- **Partial quantitative**: Existing partial log updated to full target value.

---

## 9. Completion Rate Computation Flow

Computes the fraction of applicable days completed over a given range.

### Flow Steps

```
completionRate(habitId, from, to):
  effectiveTo = min(to, today)
  if effectiveTo < from: return 0.0

  habit = HabitsDao.getHabitById(habitId)
  logs  = HabitsDao.getHabitLogs(habitId, from: from, to: effectiveTo)
  // Returns list of HabitLog rows, not a stream

  applicableDays = []
  day = from
  while day <= effectiveTo:
    if isApplicable(habit, day):
      applicableDays.add(day)
    day = day + 1 day

  if applicableDays.isEmpty: return 0.0

  completedDays = applicableDays.where((day) {
    log = logs.firstWhereOrNull((l) => l.date == day)
    return isCompleted(habit, log)
  })

  return completedDays.length / applicableDays.length

isApplicable(habit, day):
  switch habit.frequencyType:
    daily, weekly: return true
    custom: return day.weekday IN habit.customDays

isCompleted(habit, log):
  if log == null: return false
  if habit.isQuantitative: return log.value >= habit.quantitativeTarget
  return true
```

---

## 10. Property-Based Testing Properties (PBT-01 Compliance)

Properties identified for property-based testing in Unit 4.

### Round-Trip Properties

| Property ID | Component | Description |
|---|---|---|
| RT-HAB-01 | Habit persistence | `insertHabit(companion)` then `getHabitById(id)` returns all fields equal to the input companion. |
| RT-HAB-02 | CustomDays encode-decode | `jsonDecode(jsonEncode(customDays))` where `customDays` is a sorted, de-duplicated `List<int>` in 1–7 recovers an identical list. |
| RT-HAB-03 | HabitLog persistence | `insertHabitLog(log)` then `getLogForDate(habitId, date)` returns a row with the same `value` and `date`. |
| RT-HAB-04 | ReminderTime parse | Parsing `"HH:mm"` to `TimeOfDay` and back to `"HH:mm"` produces the original string for all valid times in 00:00–23:59. |

### Invariant Properties

| Property ID | Component | Description |
|---|---|---|
| INV-HAB-01 | Streak non-negativity | `streakCount(habitId, asOf)` is always >= 0 for any habit and any `asOf` date. |
| INV-HAB-02 | Streak ≤ days since creation | `streakCount(habitId, asOf)` never exceeds the number of applicable days between `habit.createdAt` and `asOf`. |
| INV-HAB-03 | Longest streak ≥ current streak | `longestStreak(habitId) >= streakCount(habitId, today)` always holds. |
| INV-HAB-04 | Completion rate bounds | `completionRate(habitId, from, to)` is always in `[0.0, 1.0]`. |
| INV-HAB-05 | No log after archive | After `archiveHabit(habitId)`, no new `habit_logs` rows are inserted by the application for the archived habit (no check-in allowed via normal flows). |
| INV-HAB-06 | Auto-check at-most-once | After `onWorkoutCompleted()`, there is at most one log row per linked habit per day. No duplicate rows are created regardless of how many `WorkoutCompletedEvent` events fire on the same day. |

### Idempotence Properties

| Property ID | Component | Description |
|---|---|---|
| IDP-HAB-01 | Archive idempotence | Calling `archiveHabit(habitId)` on an already-archived habit is a no-op (or returns `NotFoundFailure`). The `habits` row is unchanged after the second call. |
| IDP-HAB-02 | Auto-check idempotence | Calling `onWorkoutCompleted()` twice on the same day results in the same set of `habit_logs` rows as calling it once. |
| IDP-HAB-03 | UncheckIn idempotence | Calling `uncheckIn(habitId, today)` when no log exists returns `NotFoundFailure` and makes no database changes. |
| IDP-HAB-04 | Quantitative upsert | Calling `checkIn(habitId, value: v)` twice in a row results in a single `habit_logs` row with `value = v` (the second call updates, not duplicates). |

### Commutativity Properties

| Property ID | Component | Description |
|---|---|---|
| COM-HAB-01 | Streak order independence | The streak count for a daily habit is the same regardless of the order in which logs are inserted, as long as the set of logged dates is identical. |
| COM-HAB-02 | Completion rate order independence | `completionRate(habitId, from, to)` returns the same value regardless of the order in which logs are stored in the database. |
