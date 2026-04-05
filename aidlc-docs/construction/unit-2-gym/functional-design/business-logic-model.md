# Business Logic Model — Unit 2: Gym

## Purpose

Defines the step-by-step business logic flows for Unit 2. Each flow describes operations, decision points, error paths, and expected outcomes. Pseudocode is used for algorithmic sections. All flows execute within the `GymNotifier` and `GymDao` layers.

---

## 1. Exercise Library Loading Flow (First Launch)

Triggered once on first Gym module initialization. Ensures the bundled exercise library is available before the user can interact with the exercise picker or routine builder.

### Flow Steps

1. GymNotifier's `build()` method is called by Riverpod when the Gym module is first loaded.
2. Call `GymDao.countExercises()`.
   - 2a. If `count > 0`: library already seeded. Skip to step 8.
   - 2b. If `count == 0`: proceed to step 3.
3. Load `assets/exercises.json` via Flutter's `rootBundle.loadString('assets/exercises.json')`.
4. Parse the JSON string into a `List<Map<String, dynamic>>`.
5. Map each JSON object to an `ExercisesCompanion`:
   ```
   for each json in parsedList:
     companion = ExercisesCompanion(
       name:             json['name'],
       primaryMuscle:    MuscleGroup.fromString(json['primaryMuscle']),
       secondaryMuscles: json['secondaryMuscles']?.join(','),   // JSON re-encoded below
       equipment:        Equipment.fromString(json['equipment']),
       instructions:     json['instructions'],
       isCustom:         Value(false),
       isDownloaded:     Value(true),
       createdAt:        Value(DateTime.now()),
     )
   ```
6. Call `GymDao.bulkInsertExercises(companions)` inside a single Drift transaction.
   - If the transaction succeeds: library is ready.
   - If the transaction fails: catch `DatabaseFailure`. Log error. Do not crash. On next app launch, `countExercises()` will still return 0 and seeding will be retried.
7. Verify seeding by calling `countExercises()` again (optional sanity check).
8. Library is ready. GymNotifier initializes exercise streams normally.

### Error Paths

- **Asset not found**: `FlutterError` from `rootBundle`. Wrap in `DatabaseFailure(userMessage: "Error al cargar biblioteca de ejercicios")`. Show banner. App remains functional for workouts already logged.
- **JSON parse error**: Wrap in `DatabaseFailure`. Log the malformed entry. Skip that entry and continue with the rest (partial seeding acceptable — retried on next launch only for count == 0).
- **Drift transaction failure**: rollback leaves `count == 0`. Retry on next launch.

### Expected Outcomes

- **Success**: All ~200 exercises are in the `exercises` table. `isDownloaded = true`, `isCustom = false`.
- **Failure**: Zero exercises in table. User sees empty exercise library with a "Reintentar" option.

---

## 2. Create Routine Flow

User builds a new routine from scratch: names it, adds exercises, sets per-exercise defaults, and saves.

### Flow Steps

1. User taps "Nueva rutina" on the Gym home screen.
2. `RoutineBuilderScreen` opens in creation mode with an empty exercise list.
3. User enters a routine name (1-50 chars per BR-GYM-07).
4. User taps "Agregar ejercicio":
   - 4a. `ExercisePickerScreen` opens. User can filter by muscle group or search by name.
   - 4b. User selects an exercise. Check for duplicate in the current list (BR-GYM-09). If duplicate: show toast "El ejercicio ya esta en la rutina". Stay on picker.
   - 4c. Exercise added to the bottom of the local list with defaults: `defaultSets = 3`, `defaultReps = 10`, `defaultWeightKg = null`, `restSeconds = 90`.
5. User adjusts per-exercise defaults inline (sets, reps, weight, rest seconds).
6. User reorders exercises via drag-and-drop. `sortOrder` values are updated in memory.
7. User taps "Guardar rutina".
8. **Validate `RoutineInput`**:
   - 8a. Name: BR-GYM-07 (1-50 chars)
   - 8b. Exercises: BR-GYM-08 (at least 1), BR-GYM-09 (no duplicates)
   - 8c. Per-exercise fields: BR-GYM-32 (sets 1-20, reps 1-100, weight >= 0), BR-GYM-12 (restSeconds 10-600)
   - If any validation fails: show inline error on the offending field. Stay on screen.
9. Call `GymNotifier.createRoutine(input)`:
   - 9a. Insert the `Routine` row via `GymDao.insertRoutine()`. Obtain new `routineId`.
   - 9b. Build `List<RoutineExercisesCompanion>` from `input.exercises` with sequential `sortOrder` (0, 1, 2, ...).
   - 9c. Call `GymDao.setRoutineExercises(routineId, companions)` — atomic delete-all + re-insert.
   - 9d. If any step fails: wrap in `DatabaseFailure`. Roll back (Drift transaction). Return `Result.failure`.
10. On success: navigate back to Gym home. Routine appears in the list.

### Error Paths

- **Validation failure**: Inline error. User corrects and retries.
- **Database failure**: Snackbar "Error al guardar rutina". Retry available.

### Expected Outcomes

- **Success**: One new row in `routines` + N rows in `routine_exercises`. Routine visible in list.
- **Failure**: No rows inserted. User informed.

---

## 3. Start Workout from Routine Flow

User selects a saved routine and begins a workout session, with the previous session's weights pre-filled.

### Flow Steps

1. User taps a routine card → "Iniciar entrenamiento".
2. Check `GymDao.getActiveWorkout()`:
   - 2a. If non-null: show dialog "Ya tienes un entrenamiento en curso. Termina o descarta ese primero." Return. (BR-GYM-13)
   - 2b. If null: proceed.
3. Call `GymNotifier.startWorkout(routineId: id)`:
   - 3a. Insert a new `Workout` row via `GymDao.insertWorkout()`: `routineId = id`, `startedAt = DateTime.now()`, `finishedAt = null`.
   - 3b. Obtain the new `workoutId`.
4. Load `RoutineExerciseWithExercise` list via `GymDao.watchRoutineExercises(routineId)`.
5. **Pre-fill previous weights**: For each exercise in the routine:
   - Query the most recent non-warmup `workout_set` for this `exerciseId` across all previous completed workouts: `SELECT weightKg FROM workout_sets WHERE exerciseId = ? AND isWarmup = 0 ORDER BY createdAt DESC LIMIT 1`.
   - If a previous weight is found: pre-fill `defaultWeightKg` with that value (overrides routine default).
   - If no previous weight: use `routineExercise.defaultWeightKg` (which may be null).
6. Navigate to `ActiveWorkoutScreen`. Render exercise list with pre-filled defaults.
7. Start the elapsed workout timer (`currentWorkoutDuration` computed from `DateTime.now() - startedAt`).

### Error Paths

- **Workout insert failure**: `DatabaseFailure`. Snackbar. No navigation.
- **Routine not found**: If routine was deleted between tap and start (race condition): `NotFoundFailure`. Return to Gym home.

### Expected Outcomes

- **Success**: New workout row in `workouts` (finishedAt = null). ActiveWorkoutScreen shows exercises with last-session weights.
- **Blocked**: Dialog telling user to finish current workout first.

---

## 4. Start Empty Workout Flow

User begins a workout without selecting a routine. Exercises are added on the fly.

### Flow Steps

1. User taps "Entrenamiento libre" (empty workout) on Gym home.
2. Check `GymDao.getActiveWorkout()` (same guard as flow 3 step 2).
3. Call `GymNotifier.startWorkout(routineId: null)`:
   - Insert `Workout` row with `routineId = null`, `startedAt = DateTime.now()`, `finishedAt = null`.
4. Navigate to `ActiveWorkoutScreen` with an empty exercise list and an "Agregar ejercicio" CTA button.
5. User taps "Agregar ejercicio" mid-workout → `ExercisePickerScreen` → exercise added to the session.
   - Rest timer for ad-hoc exercises defaults to 90 seconds (BR-GYM-25).
6. Workout proceeds normally — same set logging, PR detection, and rest timer flows apply.

### Error Paths

- Same as Flow 3.

### Expected Outcomes

- **Success**: Workout row with `routineId = null`. User adds exercises freely.

---

## 5. Log Set Flow

The core per-set interaction. Validates input, persists immediately, triggers rest timer, and checks for new PRs.

### Flow Steps

1. User fills in set data in the `SetLogWidget`: reps, weight (optional), RIR (optional), warmup toggle.
2. User taps the checkmark to confirm the set.
3. `GymNotifier.logSet(exerciseId, input)` is called.
4. **Validate `SetInput`**:
   - 4a. `reps > 0` (BR-GYM-17)
   - 4b. `weightKg >= 0.0` if not null (BR-GYM-18)
   - 4c. `rir` in range 0-5 if not null (BR-GYM-19)
   - If any fails: return `Result.failure(ValidationFailure)`. Show inline error. Do not proceed.
5. Determine `setNumber`:
   - Query current count of sets for this `(workoutId, exerciseId)`: `SELECT COUNT(*) FROM workout_sets WHERE workoutId = ? AND exerciseId = ?`
   - `setNumber = count + 1`
6. Insert `WorkoutSet` via `GymDao.insertWorkoutSet()`. (BR-GYM-14 — auto-save immediately)
7. **PR Check** (only if `isWarmup == false`):
   - 7a. Call `GymDao.getPersonalRecord(exerciseId)` — returns current max `weightKg` for non-warmup sets.
   - 7b. **Weight PR check** (if `weightKg != null`):
     - If `weightKg > currentWeightPR` (or `currentWeightPR == null`): create `PRRecord(type: weight, previousValue: currentWeightPR, newValue: weightKg)`.
   - 7c. **Volume PR check** (if `weightKg != null`):
     - `setVolume = weightKg * reps`
     - Compute `currentVolumePR = MAX(weightKg * reps) WHERE exerciseId = ? AND isWarmup = 0 AND weightKg IS NOT NULL` (excluding the just-inserted set)
     - If `setVolume > currentVolumePR` (or `currentVolumePR == null`): create `PRRecord(type: volume, previousValue: currentVolumePR, newValue: setVolume)`.
   - 7d. Collect all `PRRecord` objects from this set into a list (may be 0, 1, or 2 records).
8. **Start rest timer** (if `isWarmup == false`):
   - Look up `restSeconds` from `routineExercise` for this exercise in the active workout's routine (if any).
   - If not found (empty workout or ad-hoc exercise): use 90 seconds.
   - Emit timer start event to `RestTimerNotifier` with the resolved duration.
9. Update `GymState.activeSets` via the Drift watch stream (auto-refreshes).
10. Return `Result.success(workoutSet)`. UI shows the logged set in the set list. If PRs were detected, show a PR badge/animation.

### Error Paths

- **Validation failure**: Inline field error. Set not persisted. No timer started.
- **Database failure**: Snackbar "Error al guardar la serie". Retry available. No timer started.

### Expected Outcomes

- **Normal set**: Set row in `workout_sets`. Rest timer starts. No PRs.
- **PR set**: Set row in `workout_sets`. Rest timer starts. PR badge shown. `PRRecord` objects ready for `WorkoutSummary`.
- **Warmup set**: Set row in `workout_sets`. No rest timer. No PR check.

---

## 6. Rest Timer Flow

Manages the countdown display after a set is logged.

### Flow Steps

1. `RestTimerNotifier` receives a start event with `duration` (from flow 5, step 8).
2. If an existing timer is running: cancel it first (new set overrides old timer).
3. Initialize timer state: `remaining = duration`, `isRunning = true`, `totalDuration = duration`.
4. Start a `Timer.periodic(const Duration(seconds: 1))` tick:
   ```
   every tick:
     remaining -= 1 second
     if remaining <= Duration.zero:
       remaining = Duration.zero
       isRunning = false
       cancel timer
       trigger haptic (BR-GYM-27)
       show visual "Time's up!" indicator
   ```
5. UI renders a circular countdown progress indicator and digital readout (`remaining.inSeconds`).
6. **"+30s" tap** (BR-GYM-26):
   - `remaining += const Duration(seconds: 30)`
   - Timer continues (no restart)
7. **User skips rest** (taps "Saltar"):
   - Cancel the periodic timer. Set `isRunning = false`. `remaining = Duration.zero`.
   - No haptic feedback (user-initiated skip).
8. Timer expiry (step 4 inner `if`): haptic fires, visual indicator changes, UI prompts user to start the next set.

### Error Paths

- **Haptic failure** (`HapticFeedback.vibrate()` unavailable): Silently swallowed. Visual indicator still shows expiry.

### Expected Outcomes

- **Normal completion**: Countdown reaches zero. Haptic fires. User sees time-up indicator.
- **Extended**: "+30s" taps extend the countdown correctly.
- **Skipped**: Timer cancelled. No haptic.

---

## 7. Complete Workout Flow

User finishes their workout. Computes the workout summary, persists `finishedAt`, detects all PRs set during the session, and emits `WorkoutCompletedEvent`.

### Flow Steps

1. User taps "Terminar entrenamiento" on `ActiveWorkoutScreen`.
2. Show confirmation dialog "Finalizar entrenamiento?" with optional note input (BR-GYM-16 — maxLength: 200).
3. User confirms. Call `GymNotifier.finishWorkout(note: note)`.
4. Retrieve active workout: `activeWorkout = GymDao.getActiveWorkout()`.
   - If null: edge case (workout was discarded concurrently). Return early with no-op.
5. Retrieve all sets for the active workout: `sets = await GymDao.watchWorkoutSets(activeWorkout.id).first`.
6. **Compute WorkoutSummary**:
   ```
   nonWarmupSets = sets.where((s) => !s.isWarmup)
   weightedSets = nonWarmupSets.where((s) => s.weightKg != null)

   totalSets = nonWarmupSets.length
   totalVolume = weightedSets.fold(0.0, (sum, s) => sum + s.weightKg! * s.reps)

   // Volume by muscle group
   volumeByMuscleGroup = {}
   for s in weightedSets:
     muscle = exercise(s.exerciseId).primaryMuscle.name
     volumeByMuscleGroup[muscle] = (volumeByMuscleGroup[muscle] ?? 0.0) + s.weightKg! * s.reps

   // Exercises performed (distinct, ordered by first appearance)
   exercisesPerformed = nonWarmupSets.map((s) => exerciseName(s.exerciseId)).distinct().toList()

   duration = DateTime.now() - activeWorkout.startedAt
   ```
7. **Aggregate PR detection across full workout**:
   ```
   prRecords = []
   for exerciseId in nonWarmupSets.map((s) => s.exerciseId).distinct():
     setsForExercise = nonWarmupSets.where((s) => s.exerciseId == exerciseId && s.weightKg != null)
     if setsForExercise.isEmpty: continue

     maxWeightInSession = setsForExercise.map((s) => s.weightKg!).max()
     historicWeightPR = GymDao.getPersonalRecord(exerciseId)  // includes today's sets
     // Note: getPersonalRecord already includes today's sets, so if today's max == overall max → new PR
     previousHistoricPR = historicWeightPR before today (computed by excluding today's sets)
     if maxWeightInSession > previousHistoricPR:
       prRecords.add(PRRecord(type: weight, exerciseId, newValue: maxWeightInSession, previousValue: previousHistoricPR))

     maxVolumeInSession = setsForExercise.map((s) => s.weightKg! * s.reps).max()
     previousVolumePR = MAX(weightKg * reps) for exerciseId WHERE createdAt < today's workout startedAt AND isWarmup = 0
     if maxVolumeInSession > previousVolumePR:
       prRecords.add(PRRecord(type: volume, exerciseId, newValue: maxVolumeInSession, previousValue: previousVolumePR))
   ```
8. **Persist workout completion**:
   - Update workout row: `finishedAt = DateTime.now()`, `note = note`.
   - `GymDao.updateWorkout(activeWorkout.copyWith(finishedAt: now, note: note))`.
9. **Emit EventBus event** (BR-GYM-31):
   ```
   eventBus.emit(WorkoutCompletedEvent(
     workoutId:   activeWorkout.id,
     duration:    duration,
     totalVolume: totalVolume,
   ))
   ```
10. **Build final WorkoutSummary** with computed values (step 6) and `prRecords` (step 7).
11. Cancel the active rest timer (if still running).
12. Navigate to `WorkoutSummaryScreen` passing the `WorkoutSummary`.

### Error Paths

- **Workout not found** (concurrent discard): Return gracefully. Navigate to Gym home.
- **Database update failure**: `DatabaseFailure`. Snackbar "Error al finalizar el entrenamiento". User can retry. `finishedAt` not set (workout remains in-progress).
- **EventBus emit failure**: Fire-and-forget. Emit errors are swallowed. Workout still considered complete.

### Expected Outcomes

- **Success**: `Workout.finishedAt` set. `WorkoutSummaryScreen` shown with totals and PR highlights. `WorkoutCompletedEvent` emitted.
- **Failure**: `finishedAt` remains null. User can retry. In-progress workout preserved.

---

## 8. PR Detection Algorithm

Centralized description of the PR detection logic used across log-set (per-set) and finish-workout (aggregate) flows.

### Algorithm

```
function detectPRs(exerciseId, candidateSets):
  // candidateSets: non-warmup sets with weightKg != null for this exercise

  // --- Weight PR ---
  maxCandidateWeight = candidateSets.map((s) => s.weightKg!).max()
  historicBest = SELECT MAX(weightKg)
                 FROM workout_sets
                 WHERE exerciseId = @exerciseId
                   AND isWarmup = 0
                   AND weightKg IS NOT NULL
                   AND id NOT IN candidateSets.map((s) => s.id)
  // historicBest = null if no prior data

  weightPR = null
  if maxCandidateWeight > (historicBest ?? -infinity):
    weightPR = PRRecord(
      type:          PRType.weight,
      exerciseId:    exerciseId,
      exerciseName:  exercise.name,
      previousValue: historicBest,  // null if first-ever PR
      newValue:      maxCandidateWeight,
    )

  // --- Volume PR ---
  maxCandidateVolume = candidateSets.map((s) => s.weightKg! * s.reps).max()
  historicVolumeBest = SELECT MAX(weightKg * reps)
                       FROM workout_sets
                       WHERE exerciseId = @exerciseId
                         AND isWarmup = 0
                         AND weightKg IS NOT NULL
                         AND id NOT IN candidateSets.map((s) => s.id)

  volumePR = null
  if maxCandidateVolume > (historicVolumeBest ?? -infinity):
    volumePR = PRRecord(
      type:          PRType.volume,
      exerciseId:    exerciseId,
      exerciseName:  exercise.name,
      previousValue: historicVolumeBest,
      newValue:      maxCandidateVolume,
    )

  return [weightPR, volumePR].whereNotNull()
```

### Constraints

- **Warmup exclusion**: `isWarmup = false` is enforced in both the candidate set filter and the historic query.
- **Bodyweight exclusion**: `weightKg IS NOT NULL` is enforced in both queries.
- **No cross-exercise comparison**: Each `exerciseId` is evaluated independently.
- **Dual PR**: A single set can set both a weight PR and a volume PR simultaneously.

---

## 9. 1RM Calculation (Epley Formula)

Read-only computation. Used in the exercise detail screen and workout summary to show estimated strength levels. Never stored.

### Algorithm

```
function estimateOneRepMax(weightKg, reps):
  if weightKg == null: return null    // bodyweight, cannot estimate
  if reps <= 0:        return null    // invalid input
  if reps == 1:        return weightKg  // actual 1RM, no estimation needed

  // Epley formula
  estimated1RM = weightKg * (1.0 + reps / 30.0)
  return round(estimated1RM, 2)
```

### Display

- Shown on the PR history card for each exercise: "1RM estimado: X kg / Y lbs"
- Uses the best (highest) non-warmup set (max weight or max volume set) as input
- Unit conversion applied for display per `AppSettings.weightUnit`

---

## 10. Body Measurement Flow (Phase 2)

UI flow for logging body measurements. The underlying DAO and Notifier methods are available in MVP but the screen is not yet in the navigation (deferred to Phase 2).

### Flow Steps

1. User navigates to "Medidas corporales" (Phase 2 screen).
2. `BodyMeasurementFormScreen` opens. Fields: date picker, weight, body fat %, waist, chest, arm.
3. User fills in at least one field.
4. **Validate `MeasurementInput`** (BR-GYM-28, BR-GYM-29):
   - At least one non-null field.
   - Each non-null field within its valid range.
5. Call `GymNotifier.logMeasurement(input)`.
6. Insert row via `GymDao.insertMeasurement()`.
7. After success, refresh `GymDao.watchMeasurements()` stream. Weight trend chart updates.

### Error Paths

- **All fields null**: `ValidationFailure`. Inline error "Ingresa al menos una medida".
- **Out-of-range field**: `ValidationFailure` with field-specific message.
- **Database failure**: `DatabaseFailure`. Snackbar with retry.

### Expected Outcomes

- **Success**: New row in `body_measurements`. Trend chart updated.
- **Failure**: No row inserted. User informed.

---

## 11. Weight Unit Conversion Flow

Stateless, always-on conversion applied at display time. No dedicated "flow" — it is a cross-cutting concern applied in every weight-displaying widget.

### Algorithm

```
function displayWeight(storedKg, weightUnit):
  if weightUnit == WeightUnit.lbs:
    return storedKg * 2.20462
  else:
    return storedKg  // kg — no conversion

function storeWeight(displayedValue, weightUnit):
  if weightUnit == WeightUnit.lbs:
    return displayedValue / 2.20462
  else:
    return displayedValue  // already in kg
```

### Precision Rules

- Displayed values are rounded to 1 decimal place for kg and 1 decimal place for lbs.
- Stored values retain full `double` precision (no rounding on storage).
- Conversion factor: exactly `2.20462` (same constant in all code paths, no variation).

### Application Points

| UI Element | Direction | Notes |
|---|---|---|
| Set weight input field | User enters display unit → store as kg | Applied in `logSet()` input parsing |
| Set weight display in workout log | kg stored → display unit | Applied in `WorkoutSetTile` |
| Routine default weight | User enters display unit → store as kg | Applied in `createRoutine()` |
| PR record display | kg stored → display unit | Applied in PR badge and history screen |
| Body measurement weight input | User enters display unit → store as kg | Applied in `logMeasurement()` |
| Workout summary total volume | Always in kg internally; display converted | Volume label shows "kg" or "lbs" suffix |

---

## Testable Properties (PBT-01 Compliance)

Properties identified for property-based testing in Unit 2.

### Round-Trip Properties

| Property ID | Component | Description |
|---|---|---|
| RT-GYM-01 | Weight unit conversion | For any `weightKg > 0`: `storeWeight(displayWeight(kg, lbs), lbs) ≈ kg` (within float epsilon). Conversion is reversible. |
| RT-GYM-02 | Exercise JSON asset | For any valid `Exercise` row, serializing to `Map` and deserializing via `ExercisesCompanion.fromJson` yields the same values. |
| RT-GYM-03 | Routine exercise round-trip | `setRoutineExercises(routineId, companions)` followed by `watchRoutineExercises(routineId).first` returns exactly the same ordered list. |
| RT-GYM-04 | Workout set persistence | `insertWorkoutSet(companion)` then `watchWorkoutSets(workoutId).first` contains the inserted set with all fields equal to input. |

### Invariant Properties

| Property ID | Component | Description |
|---|---|---|
| INV-GYM-01 | Active workout uniqueness | At any point in time: `SELECT COUNT(*) FROM workouts WHERE finishedAt IS NULL` is always 0 or 1. |
| INV-GYM-02 | Set number sequentiality | For any (workoutId, exerciseId), `setNumber` values form a contiguous sequence starting from 1 with no gaps after all sets are inserted. |
| INV-GYM-03 | Warmup exclusion invariant | For any exercise: `getPersonalRecord(exerciseId)` is always the max of `weightKg` where `isWarmup = false`. No warmup set value ever exceeds or equals the returned PR value unless warmup weight happens to equal the working PR (edge case is acceptable). |
| INV-GYM-04 | Volume non-negativity | `totalVolume` in any `WorkoutSummary` is always >= 0.0. |
| INV-GYM-05 | PR newValue >= previousValue | For any `PRRecord`, `newValue >= (previousValue ?? 0.0)`. A PR can never be lower than the previous best. |
| INV-GYM-06 | Body measurement at least one field | Every `BodyMeasurement` row in the database has at least one non-null measurement field among the five optional columns. |
| INV-GYM-07 | Epley formula monotonicity | `estimateOneRepMax(w, r)` is strictly increasing in both `w` and `r` for `w > 0` and `r > 1`. |
| INV-GYM-08 | Routine sort order | For any routine, `routine_exercises` rows form a zero-based contiguous `sortOrder` sequence: `{0, 1, 2, ..., n-1}`. |

### Idempotence Properties

| Property ID | Component | Description |
|---|---|---|
| IDP-GYM-01 | Exercise library seeding | Calling the seeding flow twice (even if `countExercises() == 0` for both calls) produces the same final set of rows as calling it once (Drift upsert or pre-check prevents duplicates). |
| IDP-GYM-02 | setRoutineExercises | Calling `setRoutineExercises(routineId, sameList)` twice in a row produces the same database state as calling it once. |
| IDP-GYM-03 | Rest timer cancellation | Cancelling an already-cancelled rest timer has no effect (no exception, no state change). |
| IDP-GYM-04 | finishWorkout idempotence | If `finishWorkout()` is called on a workout that already has `finishedAt != null`, the method returns a `NotFoundFailure` (or no-op) without modifying the workout or emitting a duplicate event. |

### Commutativity Properties

| Property ID | Component | Description |
|---|---|---|
| COM-GYM-01 | PR detection order | For a given set of non-warmup sets logged in a single workout, the detected PRs are the same regardless of the order the sets were logged (PR is based on max value, which is order-independent). |
| COM-GYM-02 | Weight unit conversion display | Displaying a set's weight in kg and then converting to lbs, vs. displaying directly in lbs from the stored kg value, produces the same result. (No intermediate rounding between steps.) |

### Components with No PBT Properties Identified

| Component | Rationale |
|---|---|
| Rest timer haptic feedback | Pure side-effect (device vibration). No data transformation to verify with properties. |
| ExercisePicker UI filter | Filtering by muscle group is a deterministic query; example-based tests cover the filter logic adequately. |
| Workout resume dialog | Platform-level UI concern; property testing is not meaningful for dialog display logic. |
