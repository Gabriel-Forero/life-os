# Business Rules — Unit 2: Gym

## Purpose

Defines all business rules for Unit 2 covering the exercise library, routine builder, workout logging, set tracking, PR detection, rest timer, and body measurements. Each rule includes an ID, description, rationale, and validation criteria.

---

## Exercise Library Rules

### BR-GYM-01: Exercise Library Seeding on First Launch

**Description**: On first app launch (or first time the Gym module is activated), `GymDao.countExercises()` is checked. If the result is 0, `GymDao.bulkInsertExercises()` is called to load the full exercise library from the `assets/exercises.json` bundled asset. Seeding is a one-time operation — subsequent launches skip it.

**Rationale**: Bundling exercises as a local JSON asset ensures the library is available offline with no network call. A count check prevents re-seeding if the user reinstalls or clears data partially.

**Validation Criteria**:
- If `countExercises() == 0`: load and insert all exercises from the asset; set `isDownloaded = true`, `isCustom = false` on each row
- If `countExercises() > 0`: seeding is skipped entirely (even if the count is less than the full library size)
- The seeding operation is wrapped in a single database transaction; if it fails, the count remains 0 and the operation is retried on the next launch
- After successful seeding, `countExercises()` equals the number of exercises in the JSON asset (approximately 200)
- Seeding occurs before the user can navigate to any exercise-related screen

---

### BR-GYM-02: Exercise Name Uniqueness

**Description**: No two exercises (bundled or custom) may have the same name, case-insensitively. "Press de Banca" and "press de banca" are considered the same name and cannot coexist.

**Rationale**: Prevents confusion in the exercise picker and search results. Ensures the library is clean regardless of how exercises were added.

**Validation Criteria**:
- Before inserting a custom exercise, query for an existing exercise whose name matches (case-insensitive)
- If a match is found: return `ValidationFailure(field: 'name', userMessage: "Ya existe un ejercicio con ese nombre")`
- If no match: proceed with insert
- The unique check is done in the Notifier layer (not relying solely on Drift unique index, since case-insensitive comparison is application-level)

---

### BR-GYM-03: Exercise Name Length

**Description**: Exercise names must be between 1 and 100 characters after trimming leading and trailing whitespace.

**Rationale**: Prevents empty or excessively long names that break UI layout (exercise cards, routine screens).

**Validation Criteria**:
- `name.trim().isEmpty` → `ValidationFailure(field: 'name', userMessage: "El nombre del ejercicio es obligatorio")`
- `name.trim().length > 100` → `ValidationFailure(field: 'name', userMessage: "El nombre no puede superar los 100 caracteres")`
- Name is stored trimmed

---

### BR-GYM-04: Custom Exercise CRUD

**Description**: Users can create, edit, and delete their own custom exercises (`isCustom = true`). Bundled library exercises (`isCustom = false`) are read-only — they cannot be renamed, edited, or deleted.

**Rationale**: The bundled library is a curated reference. Allowing deletion or renaming would break exercise history references. Custom exercises are fully user-owned.

**Validation Criteria**:
- Attempting to update or delete a bundled exercise (`isCustom = false`) returns `ValidationFailure(userMessage: "Los ejercicios de la biblioteca no se pueden modificar")`
- Custom exercises can be freely renamed (subject to BR-GYM-02 and BR-GYM-03), updated, and deleted
- Deleting a custom exercise that has `workout_sets` referencing it is allowed (sets retain the `exerciseId` FK as a dangling reference — historical data is preserved; the exercise ID column is not cascaded)
- If a custom exercise is in one or more routines, deleting it removes the corresponding `routine_exercises` rows (cascade within the routine, not workout history)

---

### BR-GYM-05: Exercise Instructions Length

**Description**: Exercise instructions are optional. If provided, they must not exceed 500 characters.

**Rationale**: Instructions are for brief step-by-step cues, not full articles. The 500-character cap keeps the UI clean and the asset file compact.

**Validation Criteria**:
- `instructions == null` is valid
- `instructions.trim().isEmpty` is treated as null (no instructions stored)
- `instructions.length > 500` → `ValidationFailure(field: 'instructions', userMessage: "Las instrucciones no pueden superar los 500 caracteres")`

---

### BR-GYM-06: Secondary Muscles Validation

**Description**: Secondary muscles are optional. If provided, the list must contain only valid `MuscleGroup` enum values. The primary muscle cannot appear in the secondary muscles list.

**Rationale**: A muscle cannot simultaneously be the primary and secondary focus. Prevents nonsensical data (e.g., primaryMuscle = pecho, secondaryMuscles = [pecho]).

**Validation Criteria**:
- `secondaryMuscles == null` or empty list: valid
- Any value in the list not matching a valid `MuscleGroup` enum name: `ValidationFailure(field: 'secondaryMuscles')`
- If `secondaryMuscles.contains(primaryMuscle)`: `ValidationFailure(userMessage: "El musculo primario no puede ser un musculo secundario")`

---

## Routine Rules

### BR-GYM-07: Routine Name Length

**Description**: Routine names must be between 1 and 50 characters after trimming.

**Rationale**: Routine names appear in cards and buttons throughout the UI. Short names ensure clean layout.

**Validation Criteria**:
- `name.trim().isEmpty` → `ValidationFailure(field: 'name', userMessage: "El nombre de la rutina es obligatorio")`
- `name.trim().length > 50` → `ValidationFailure(field: 'name', userMessage: "El nombre no puede superar los 50 caracteres")`
- Name stored trimmed

---

### BR-GYM-08: Routine Requires at Least One Exercise

**Description**: A routine must contain at least 1 exercise to be saved. An empty routine cannot be persisted via `GymNotifier.createRoutine()`.

**Rationale**: A routine with no exercises has no functional purpose and would result in a confusing empty workout if started.

**Validation Criteria**:
- `RoutineInput.exercises.isEmpty` → `ValidationFailure(userMessage: "La rutina debe tener al menos un ejercicio")`
- The routine row itself is not inserted until the exercise list is validated

---

### BR-GYM-09: Routine Exercise Uniqueness

**Description**: The same exercise cannot appear twice in the same routine. Each (routineId, exerciseId) pair must be unique.

**Rationale**: Having the same exercise listed twice in a routine is an input error. The user should increase sets instead.

**Validation Criteria**:
- Before saving: check for duplicate `exerciseId` values in `RoutineInput.exercises`
- If duplicates found: `ValidationFailure(userMessage: "El ejercicio ya esta en la rutina")`
- This is also enforced via a Drift unique index on (routineId, exerciseId) as a safety net

---

### BR-GYM-10: Routine Exercise Drag-to-Reorder

**Description**: The user can reorder exercises within a routine by drag-and-drop. After reordering, `sortOrder` values are updated sequentially (0, 1, 2, ...) and persisted via `GymDao.setRoutineExercises()`.

**Rationale**: Exercise order matters for workout flow. Compound movements should typically come first.

**Validation Criteria**:
- After a drag-to-reorder, `sortOrder` values form a zero-based sequential sequence with no gaps
- `GymDao.setRoutineExercises()` is called atomically: deletes all existing `routine_exercises` for the routine and re-inserts the full reordered list in one transaction
- No partial updates — either the full reorder succeeds or the original order is preserved

---

### BR-GYM-11: Routine Cascade Delete

**Description**: Deleting a routine deletes all of its `routine_exercises` rows. Workouts previously started from the deleted routine are not deleted — their `routineId` FK is set to `null`.

**Rationale**: Historical workout data is immutable and valuable. Deleting a routine should only remove the template, not the logged history.

**Validation Criteria**:
- After `GymDao.deleteRoutine(id)`:
  - All `routine_exercises` rows with `routineId = id` are deleted (CASCADE DELETE)
  - All `workouts` rows with `routineId = id` have `routineId` set to `null` (SET NULL behavior handled at application layer or via FK action)
  - `workout_sets` rows are not affected
- No error is thrown if the routine had 0 exercises

---

### BR-GYM-12: Rest Seconds Range

**Description**: The `restSeconds` field on a `routine_exercises` row must be between 10 and 600 seconds (inclusive). This defines the per-exercise rest timer duration.

**Rationale**: Less than 10 seconds is not practical for any exercise. More than 600 seconds (10 minutes) exceeds any reasonable rest period and likely indicates a data entry error.

**Validation Criteria**:
- `restSeconds < 10` → `ValidationFailure(field: 'restSeconds', userMessage: "El tiempo de descanso minimo es 10 segundos")`
- `restSeconds > 600` → `ValidationFailure(field: 'restSeconds', userMessage: "El tiempo de descanso maximo es 600 segundos")`
- Default: 90 seconds when not specified

---

## Workout Rules

### BR-GYM-13: Only One Active Workout at a Time

**Description**: At most one workout with `finishedAt == null` may exist at any time. Calling `GymNotifier.startWorkout()` when an active workout exists returns a `ValidationFailure`.

**Rationale**: Concurrent active workouts would produce ambiguous state for rest timers, PR detection, and volume tracking. The user must finish or discard the current workout before starting a new one.

**Validation Criteria**:
- Before inserting a new workout: call `GymDao.getActiveWorkout()`
- If result is non-null: return `ValidationFailure(userMessage: "Ya tienes un entrenamiento en curso")`
- The UI disables "Start workout" buttons when an active workout is detected

---

### BR-GYM-14: Auto-Save Every Set

**Description**: Each set logged via `GymNotifier.logSet()` is immediately persisted to Drift. There is no staging area. A partially logged workout is recoverable because all completed sets are already in the database.

**Rationale**: Auto-save prevents data loss if the app is killed, the phone runs out of battery, or the user forgets to finish the workout (Q5:A). Each set is a permanent record from the moment it is logged.

**Validation Criteria**:
- `GymDao.insertWorkoutSet()` is called synchronously within `logSet()` before returning a result
- A successful `logSet()` call produces exactly one row in `workout_sets` immediately
- Restarting the app after logging 3 sets shows those 3 sets when the in-progress workout is resumed

---

### BR-GYM-15: Offer Resume on Relaunch

**Description**: On app launch, if `GymDao.getActiveWorkout()` returns a non-null workout (i.e., `finishedAt == null`), the Gym module displays a resume dialog offering the user to continue or discard the interrupted workout.

**Rationale**: Users who close the app mid-workout should not lose their progress. The offer-to-resume pattern respects their intent.

**Validation Criteria**:
- Resume dialog is shown only once per app launch (not shown again on tab navigation)
- "Continuar" dismisses the dialog and navigates to the active workout screen with all logged sets visible
- "Descartar" calls `GymNotifier.discardWorkout()`, which hard-deletes the workout and all its sets, then shows the normal gym home screen
- If no active workout exists, no dialog is shown

---

### BR-GYM-16: Workout Note Length

**Description**: The optional workout note must not exceed 200 characters.

**Rationale**: Notes are quick session comments, not journals. The 200-character cap is consistent with other text fields across LifeOS.

**Validation Criteria**:
- `note == null` or `note.trim().isEmpty`: stored as null
- `note.length > 200` → `ValidationFailure(field: 'note', userMessage: "La nota no puede superar los 200 caracteres")`

---

## Set Rules

### BR-GYM-17: Reps Must Be Positive

**Description**: Every set must have at least 1 rep. Zero and negative rep counts are rejected.

**Rationale**: A set with 0 reps was not performed. Allowing it would corrupt volume and PR calculations.

**Validation Criteria**:
- `reps <= 0` → `ValidationFailure(field: 'reps', userMessage: "Debes completar al menos 1 repeticion")`
- Applies equally to warmup and working sets

---

### BR-GYM-18: Weight Nullable for Bodyweight (Q6:B)

**Description**: `weightKg` is nullable in `workout_sets`. A null value means the set was performed with bodyweight only (no external load). A non-null value must be non-negative.

**Rationale**: Many exercises (pull-ups, push-ups, dips) use bodyweight as the load. Forcing a weight entry would be incorrect and would break volume calculations. Explicit null is a cleaner model than using a sentinel value like `0.0` (Q6:B).

**Validation Criteria**:
- `weightKg == null`: valid; displayed as "Peso corporal × {reps}"
- `weightKg == 0.0`: valid; represents a plate-loaded bar or an explicitly entered zero (treated as external load of 0 kg, distinct from bodyweight)
- `weightKg < 0.0`: `ValidationFailure(field: 'weightKg', userMessage: "El peso no puede ser negativo")`
- Weight stored in kg regardless of display unit preference

---

### BR-GYM-19: RIR Range

**Description**: Reps In Reserve (RIR) is an optional subjective intensity metric. If provided, it must be an integer from 0 to 5 inclusive.

**Rationale**: RIR values outside 0-5 have no accepted meaning in strength training. Values beyond 5 are considered "very easy" and are not practically useful to distinguish.

**Validation Criteria**:
- `rir == null`: valid (user chose not to log RIR)
- `rir < 0` or `rir > 5` → `ValidationFailure(field: 'rir', userMessage: "El RIR debe estar entre 0 y 5")`

---

### BR-GYM-20: Warmup Sets Excluded from PR and Volume

**Description**: Sets marked `isWarmup = true` are excluded from all PR tracking (both weight PR and volume PR), all volume calculations (total volume, per-muscle-group volume, and 1RM estimation). Warmup sets are visible in the workout log UI but visually differentiated (e.g., a "W" badge).

**Rationale**: Warmup sets use sub-maximal loads to prepare the body. Including them in PR/volume math would artificially inflate data and obscure genuine performance trends (Q4:C).

**Validation Criteria**:
- When computing `getPersonalRecord(exerciseId)`: only query sets with `isWarmup = false`
- When computing workout summary totals: sum only `isWarmup = false` sets
- When checking for new PRs after `logSet()`: skip the check entirely if `isWarmup == true`
- Warmup sets are still persisted and visible in the workout history for transparency

---

## PR Detection Rules

### BR-GYM-21: Weight PR Definition

**Description**: A weight PR for an exercise is the maximum weight (`weightKg`) ever lifted in a single non-warmup set for that exercise across all completed workouts. Only sets where `weightKg IS NOT NULL` are considered. Bodyweight sets (`weightKg == null`) are not eligible for weight PR.

**Rationale**: Weight PR measures absolute load capacity. Bodyweight sets cannot be compared fairly across different body weights and time periods (Q4:C).

**Validation Criteria**:
- `GymDao.getPersonalRecord(exerciseId)` queries: `SELECT MAX(weightKg) FROM workout_sets WHERE exerciseId = ? AND isWarmup = 0 AND weightKg IS NOT NULL`
- After logging a set: if `isWarmup == false` and `weightKg != null` and `weightKg > currentWeightPR`: set a new weight PR, create a `PRRecord(type: PRType.weight)`
- If `currentWeightPR == null`: the set's weight becomes the first-ever PR; `PRRecord.previousValue = null`

---

### BR-GYM-22: Volume PR Definition

**Description**: A volume PR for an exercise is the maximum single-set volume (`weightKg × reps`) ever achieved in a non-warmup set. For bodyweight sets (`weightKg == null`), volume PR is skipped. The volume PR is tracked independently from the weight PR.

**Rationale**: Volume PR captures the best performance in terms of total work per set, which rewards both strength and endurance (high reps at moderate weight can be a PR even if absolute weight is lower). Tracked independently per Q4:C.

**Validation Criteria**:
- Volume PR = `MAX(weightKg * reps)` across all non-warmup sets where `weightKg IS NOT NULL` for this exercise
- After logging a set: if `isWarmup == false` and `weightKg != null`: compute `setVolume = weightKg * reps`; if `setVolume > currentVolumePR`: new volume PR, `PRRecord(type: PRType.volume)`
- A single logged set can produce both a weight PR and a volume PR simultaneously (two distinct `PRRecord` objects)

---

### BR-GYM-23: 1RM Estimation (Epley Formula)

**Description**: One-rep maximum (1RM) is estimated using the Epley formula: `1RM = weight × (1 + reps / 30)`. This is a read-only computed value for display purposes only — it is not stored in the database. The formula is only applied when `reps > 1`; a single-rep set at a given weight is the actual 1RM.

**Rationale**: The Epley formula is the most widely used 1RM estimator in fitness apps. Showing estimated 1RM helps users understand their strength level without requiring an actual maximal effort test. It is never used in PR detection (PRs use actual logged data).

**Validation Criteria**:
- `reps == 1`: return `weightKg` as the actual 1RM (no estimation needed)
- `reps > 1`: apply `weightKg * (1.0 + reps / 30.0)`, round to 2 decimal places
- `reps <= 0` or `weightKg == null`: return null (cannot estimate)
- Estimated 1RM is displayed in the exercise detail / PR history screen but never stored

---

## Rest Timer Rules

### BR-GYM-24: Auto-Start Rest Timer After Set

**Description**: After a user successfully logs a non-warmup set (and the set is persisted), the rest timer automatically starts counting down from the configured `restSeconds` for that exercise. For warmup sets, the rest timer does NOT auto-start.

**Rationale**: Automating the rest timer removes friction. The user should be able to log a set and immediately see the countdown without manually starting it. Warmup sets typically don't require tracked rest.

**Validation Criteria**:
- After `GymNotifier.logSet()` succeeds and `isWarmup == false`: start the rest timer with duration from `routineExercise.restSeconds` (if workout was started from a routine) or 90 seconds (if no routine or exercise not in routine)
- After `GymNotifier.logSet()` succeeds and `isWarmup == true`: do NOT start rest timer
- Rest timer state is managed by a dedicated `RestTimerNotifier` (not part of `GymState`)
- Only one rest timer can be active at a time; starting a new set cancels the previous timer and starts fresh

---

### BR-GYM-25: Rest Timer Fallback (Q3:B)

**Description**: If the workout was started without a routine (empty workout), or an exercise is added mid-workout without a corresponding `routine_exercises` entry, the rest timer defaults to 90 seconds.

**Rationale**: The 90-second fallback is the most common rest period for hypertrophy training. It provides a sensible default when no per-exercise preference has been configured (Q3:B).

**Validation Criteria**:
- Workout started with `routineId == null`: all exercises use 90-second rest timer
- Exercise added mid-workout (not part of the original routine): use 90-second rest timer
- Routine exercise with `restSeconds == null` (should not occur due to default, but defensive): use 90 seconds

---

### BR-GYM-26: Rest Timer Adjustment (+30 Seconds)

**Description**: While the rest timer is counting down, the user can tap a "+30s" button to extend the current countdown by 30 seconds. Multiple taps are allowed (each adds another 30 seconds). The adjustment can push the timer above its original `restSeconds` duration.

**Rationale**: Sometimes a user needs more rest than planned (fatigue, distraction, phone call). The +30s tap is the quickest adjustment without requiring the user to set an exact time.

**Validation Criteria**:
- Each tap on "+30s" increments the remaining countdown by exactly 30 seconds
- The timer continues counting down normally after the adjustment
- Multiple taps stack (tapping 3 times adds 90 seconds total)
- No upper cap on the adjusted time (user controls how much extra rest they take)

---

### BR-GYM-27: Haptic Feedback on Timer Completion

**Description**: When the rest timer reaches zero, the device vibrates with a brief haptic pattern to alert the user (who may have put down their phone). The app does not show a full notification — only in-app haptic + visual indicator.

**Rationale**: The user is typically not looking at the phone during rest. Haptic feedback provides a non-intrusive, silent signal that it is time to perform the next set.

**Validation Criteria**:
- On timer expiry (`remaining == Duration.zero`): trigger `HapticFeedback.vibrate()` (or medium impact)
- Haptic fires even if the app is in the foreground and the screen is on
- No persistent notification is sent to the OS notification tray (in-app only)
- If the screen is off and the timer expires, haptic fires when the app is next foregrounded (no background timer support needed for MVP)

---

## Body Measurement Rules

### BR-GYM-28: At Least One Measurement Field Required

**Description**: A body measurement entry must include at least one non-null measurement field: `weightKg`, `bodyFatPercent`, `waistCm`, `chestCm`, or `armCm`. An entry with all fields null cannot be saved.

**Rationale**: Saving a measurement entry with no data is meaningless and wastes a database row.

**Validation Criteria**:
- If all five fields are null: `ValidationFailure(userMessage: "Debes ingresar al menos una medida")`
- If at least one field is non-null and valid: proceed with insert
- Individual field validation still applies (ranges, positivity — see BR-GYM-29)

---

### BR-GYM-29: Measurement Field Ranges

**Description**: Each optional measurement field has a valid range. Values outside these ranges indicate a data entry error.

| Field | Range | Failure Message |
|---|---|---|
| `weightKg` | 20.0–500.0 kg | "El peso debe estar entre 20 y 500 kg" |
| `bodyFatPercent` | 0.0–100.0 | "El porcentaje de grasa debe estar entre 0 y 100" |
| `waistCm` | > 0.0 | "La circunferencia debe ser positiva" |
| `chestCm` | > 0.0 | "La circunferencia debe ser positiva" |
| `armCm` | > 0.0 | "La circunferencia debe ser positiva" |

**Rationale**: Prevents clearly erroneous values (e.g., 0 kg body weight, 150% body fat) from polluting the trend chart.

**Validation Criteria**:
- Each non-null field is checked against its range before insert
- A field failing its range check produces a `ValidationFailure` with the field name and appropriate user message
- Null fields skip range validation (not provided = not validated)

---

### BR-GYM-30: Weight Unit Preference (Q2:B)

**Description**: All weight values (`weightKg` in `workout_sets`, `defaultWeightKg` in `routine_exercises`, `weightKg` in `body_measurements`) are stored internally in kilograms as `double`. Display throughout the Gym module reads `AppSettings.weightUnit` and applies the appropriate conversion factor for presentation. The user can switch units at any time; stored values are not re-encoded.

**Rationale**: Storing a single canonical unit (kg) avoids dual-storage complexity and conversion rounding errors. Display conversion is stateless and reversible.

**Validation Criteria**:
- All weight fields are stored as kg in Drift (never lbs)
- UI reads: `displayWeight = weightKg * (weightUnit == WeightUnit.lbs ? 2.20462 : 1.0)`
- User-entered weights in the UI are converted before storage: `storedKg = enteredValue / (weightUnit == WeightUnit.lbs ? 2.20462 : 1.0)`
- Changing `weightUnit` in AppSettings immediately updates all displayed weights app-wide without any data migration
- PR records and volume calculations always use raw kg values from the database

---

### BR-GYM-31: Workout Completed Event Emission

**Description**: When `GymNotifier.finishWorkout()` is called and the workout is successfully persisted (i.e., `finishedAt` is set), a `WorkoutCompletedEvent` is emitted on the EventBus with the workout ID, duration, and total non-warmup volume.

**Rationale**: The EventBus event enables other modules (DayScore, Dashboard) to react to a completed workout without coupling to the Gym module.

**Validation Criteria**:
- `WorkoutCompletedEvent` is emitted only after `Workout.finishedAt` is successfully written to the database
- `totalVolume` in the event = sum of (`weightKg × reps`) for all non-warmup sets where `weightKg IS NOT NULL`
- If the workout has zero non-warmup sets, `totalVolume = 0.0` (event still emitted)
- If `finishWorkout()` fails with a `DatabaseFailure`, no event is emitted
- Event emission is fire-and-forget (per BR-EVT-01 in Unit 0)

---

### BR-GYM-32: Default Sets, Reps, and Rest Range Validation

**Description**: Default sets and reps in `RoutineInput.exercises` must fall within defined ranges. These defaults are pre-filled in the workout logging UI but the user can change them per set.

| Field | Range | Failure Message |
|---|---|---|
| `defaultSets` | 1–20 | "Los sets por defecto deben estar entre 1 y 20" |
| `defaultReps` | 1–100 | "Las repeticiones por defecto deben estar entre 1 y 100" |
| `defaultWeightKg` | >= 0.0 (if not null) | "El peso no puede ser negativo" |

**Rationale**: A routine with 0 default sets or 101 default reps is clearly a data entry error. Upper bounds prevent unrealistic values from appearing in the UI.

**Validation Criteria**:
- Applied during `RoutineInput` validation in `GymNotifier.createRoutine()`
- Each `RoutineExerciseInput` is validated individually
- Out-of-range values produce `ValidationFailure` with the relevant field name and user message
