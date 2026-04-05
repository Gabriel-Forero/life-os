# Domain Entities — Unit 2: Gym

## Purpose

Defines every domain entity for Unit 2 with complete field specifications, Dart types, constraints, defaults, and descriptions. These definitions drive Drift table generation, sealed class hierarchies, input DTOs, and value objects used by the Gym module across the entire LifeOS application.

---

## 1. Muscle Group Enum

All 11 muscle groups used by the exercise library. Used in `primaryMuscle` (required, single value) and `secondaryMuscles` (optional, JSON list).

| Enum Value | Spanish Label | Category |
|---|---|---|
| `pecho` | Pecho | Upper Body — Push |
| `espalda` | Espalda | Upper Body — Pull |
| `hombros` | Hombros | Upper Body — Push |
| `biceps` | Biceps | Upper Body — Pull |
| `triceps` | Triceps | Upper Body — Push |
| `cuadriceps` | Cuadriceps | Lower Body |
| `isquiotibiales` | Isquiotibiales | Lower Body |
| `gluteos` | Gluteos | Lower Body |
| `pantorrillas` | Pantorrillas | Lower Body |
| `core` | Core | Core / Stability |
| `cardio` | Cardio | Cardio |

### Dart Enum Definition

```
enum MuscleGroup {
  pecho, espalda, hombros, biceps, triceps,
  cuadriceps, isquiotibiales, gluteos, pantorrillas,
  core, cardio
}
```

Stored in Drift as a `TextColumn` using a `TypeConverter<MuscleGroup, String>` that maps enum name to its string value. Unknown values during deserialization fall back to `MuscleGroup.pecho` (safe default, logged as warning).

---

## 2. Equipment Enum

Equipment required to perform an exercise. Used in `exercises.equipment`.

| Enum Value | Spanish Label |
|---|---|
| `barra` | Barra |
| `mancuernas` | Mancuernas |
| `maquina` | Maquina |
| `cable` | Cable |
| `pesoCorporal` | Peso corporal |
| `bandaElastica` | Banda elastica |
| `kettlebell` | Kettlebell |
| `otro` | Otro |

### Dart Enum Definition

```
enum Equipment {
  barra, mancuernas, maquina, cable,
  pesoCorporal, bandaElastica, kettlebell, otro
}
```

Stored as `TextColumn` via `TypeConverter<Equipment, String>`. Same fallback strategy as MuscleGroup.

---

## 3. Exercises (Drift Table)

The exercise library. Contains both bundled exercises (loaded from `assets/exercises.json` on first launch) and user-created custom exercises.

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `name` | `String` | `TextColumn` | Required, unique (case-insensitive), minLength: 1, maxLength: 100, trimmed | None (required) | Exercise display name (e.g., "Press de banca", "Sentadilla") |
| `primaryMuscle` | `MuscleGroup` | `TextColumn` | Required, stored via TypeConverter | None (required) | Single primary muscle group targeted |
| `secondaryMuscles` | `String?` | `TextColumn` | Optional, JSON-encoded `List<String>` of MuscleGroup enum names | `null` | Secondary muscle groups engaged (may be empty list or null) |
| `equipment` | `Equipment` | `TextColumn` | Required, stored via TypeConverter | None (required) | Equipment needed to perform this exercise |
| `instructions` | `String?` | `TextColumn` | Optional, maxLength: 500 | `null` | Step-by-step execution instructions (Spanish, plain text) |
| `isCustom` | `bool` | `BoolColumn` | Required | `false` | `true` for user-created exercises; `false` for bundled library exercises |
| `isDownloaded` | `bool` | `BoolColumn` | Required | `false` | `true` if this exercise was seeded from the JSON asset on first launch; helps distinguish seeded vs later-added custom exercises |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp of initial record creation |

### Exercises Notes

- **Uniqueness**: Name uniqueness is case-insensitive. "Press de banca" and "press de banca" cannot coexist. Enforced at the Notifier layer before insert (case-folded query) and by a Drift unique index on the lowercased name.
- **secondaryMuscles encoding**: Stored as a JSON string (e.g., `'["triceps","hombros"]'`). Decoded via a Drift `TypeConverter<List<String>, String>` or extension method. Null means no secondary muscles specified.
- **Library seeding**: On first launch, `GymDao.countExercises()` returns 0. `GymDao.bulkInsertExercises()` loads and inserts all ~200 exercises from `assets/exercises.json`. `isDownloaded = true` and `isCustom = false` for all seeded exercises.
- **Custom exercises**: Created by the user with `isCustom = true, isDownloaded = false`. Can be edited or deleted freely.
- **Bundled exercises**: `isCustom = false`. The user cannot delete or rename bundled exercises. Instructions and icon are read-only.

---

## 4. Routines (Drift Table)

Named workout templates the user creates in advance. Each routine contains an ordered list of exercises with defaults.

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `name` | `String` | `TextColumn` | Required, minLength: 1, maxLength: 50, trimmed | None (required) | Routine display name (e.g., "Push Day A", "Piernas") |
| `description` | `String?` | `TextColumn` | Optional, maxLength: 200 | `null` | Optional note describing the routine's purpose or structure |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp of routine creation |
| `updatedAt` | `DateTime` | `DateTimeColumn` | Required, updated on every write | `DateTime.now()` at insert and update | Timestamp of last modification to the routine or its exercises |

### Routines Notes

- **Exercise membership**: Exercises within a routine are stored in the `routine_exercises` join table, not in this table directly.
- **Cascade delete**: Deleting a routine deletes all of its `routine_exercises` rows. Workouts previously started from this routine retain their `routineId` as a nullable FK (not cascaded — historical workouts are preserved).
- **Minimum exercises**: A routine must have at least 1 exercise before it can be saved or used to start a workout (BR-GYM-08).

---

## 5. Routine Exercises (Drift Table)

Join table that defines which exercises belong to a routine, their order, and their per-exercise training defaults.

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `routineId` | `int` | `IntColumn` | Required, FK → routines.id (CASCADE DELETE) | None (required) | Owning routine |
| `exerciseId` | `int` | `IntColumn` | Required, FK → exercises.id | None (required) | The exercise being referenced |
| `sortOrder` | `int` | `IntColumn` | Required, non-negative | Sequential 0-based at creation | Determines display and execution order within the routine (drag-to-reorder updates this) |
| `defaultSets` | `int` | `IntColumn` | Required, range 1-20 | `3` | Suggested number of sets pre-filled when logging from this routine |
| `defaultReps` | `int` | `IntColumn` | Required, range 1-100 | `10` | Suggested reps per set pre-filled when logging |
| `defaultWeightKg` | `double?` | `RealColumn` | Optional, non-negative if present | `null` | Suggested weight in kg. Null means bodyweight or user sets their own. Displayed after unit conversion |
| `restSeconds` | `int` | `IntColumn` | Required, range 10-600 | `90` | Rest timer duration in seconds after completing a set of this exercise |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp of entry creation |

### Routine Exercises Notes

- **Unique constraint**: One row per (routineId, exerciseId) pair. The same exercise cannot appear twice in the same routine.
- **setRoutineExercises atomicity**: `GymDao.setRoutineExercises()` deletes all existing rows for the routine and re-inserts the full list in one database transaction. This ensures sort order is always consistent and avoids partial updates.
- **restSeconds fallback**: If a workout is started without a routine (empty workout), or an exercise is added mid-workout without a routine reference, rest timer defaults to 90 seconds.
- **Weight display**: `defaultWeightKg` is always stored in kg. UI reads `AppSettings.weightUnit` and converts for display (kg → lbs: × 2.20462).

---

## 6. Workouts (Drift Table)

Records each workout session, whether started from a routine or as an empty session.

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `routineId` | `int?` | `IntColumn` | Optional, FK → routines.id (SET NULL on delete) | `null` | Source routine, if the workout was started from one. Null for empty workouts |
| `startedAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp when the workout began |
| `finishedAt` | `DateTime?` | `DateTimeColumn` | Optional; `null` means the workout is still in progress | `null` | Timestamp when the workout was completed via `finishWorkout()` |
| `note` | `String?` | `TextColumn` | Optional, maxLength: 200 | `null` | User note about the session (e.g., "Felt strong today") |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp of row creation (same as startedAt in practice) |

### Workouts Notes

- **In-progress detection**: `finishedAt == null` means the workout is currently active or was interrupted. At most one such row should exist at any time (BR-GYM-12).
- **Resume on relaunch**: On app launch, `GymDao.getActiveWorkout()` checks for a row where `finishedAt IS NULL`. If found, the user is offered a dialog to resume or discard it.
- **Discard**: Calling `GymNotifier.discardWorkout()` deletes the workout row and all of its `workout_sets` rows in a database transaction. This is a hard delete — discarded workouts are not recoverable.
- **Duration calculation**: `duration = finishedAt - startedAt`. For in-progress workouts, `duration = DateTime.now() - startedAt` (computed in `GymNotifier.currentWorkoutDuration`).
- **routineId after routine deletion**: If the source routine is deleted, `routineId` is set to NULL via a database trigger or handled at the application layer (workout history is preserved).

---

## 7. Workout Sets (Drift Table)

Each logged set within a workout. Auto-saved immediately upon logging (Q5:A).

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `workoutId` | `int` | `IntColumn` | Required, FK → workouts.id (CASCADE DELETE) | None (required) | Owning workout session |
| `exerciseId` | `int` | `IntColumn` | Required, FK → exercises.id | None (required) | The exercise performed in this set |
| `setNumber` | `int` | `IntColumn` | Required, positive (>= 1) | Sequential per exercise per workout | Order of this set within the exercise (1st set, 2nd set, etc.) |
| `reps` | `int` | `IntColumn` | Required, positive (> 0) | None (required) | Number of repetitions performed |
| `weightKg` | `double?` | `RealColumn` | Optional, non-negative if present | `null` | Weight lifted in kg. `null` means bodyweight exercise (no external load) |
| `rir` | `int?` | `IntColumn` | Optional, range 0-5 | `null` | Reps In Reserve: how many more reps the user could have performed. 0 = failure, 5 = very easy |
| `isWarmup` | `bool` | `BoolColumn` | Required | `false` | Whether this is a warmup set. Warmup sets are excluded from PR tracking and volume calculations |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp when this set was logged |

### Workout Sets Notes

- **Auto-save (Q5:A)**: Each call to `GymNotifier.logSet()` immediately persists the row to Drift. There is no staging area or "batch save" step.
- **Bodyweight display (Q6:B)**: When `weightKg == null`, the UI displays "Peso corporal × {reps}". For volume calculations involving bodyweight exercises, the latest `body_measurements.weightKg` is used if available, otherwise the set is excluded from volume totals.
- **Warmup exclusion**: Sets with `isWarmup = true` are excluded from: weight PR, volume PR, 1RM estimation, and per-muscle-group volume totals shown in the workout summary.
- **setNumber convention**: Starts at 1 for each (workoutId, exerciseId) group. Assigned sequentially in the Notifier before insert. Resequencing is not needed since sets can be deleted but not reordered.
- **RIR range**: 0 = trained to failure (could not complete another rep), 5 = could easily do 5+ more reps. Values outside 0-5 are rejected by validation.

---

## 8. Body Measurements (Drift Table)

Periodic body composition and circumference measurements. Phase 2 feature.

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `date` | `DateTime` | `DateTimeColumn` | Required, date only (time portion ignored at query level) | `DateTime.now()` date part | The date this measurement was taken |
| `weightKg` | `double?` | `RealColumn` | Optional, range 20.0-500.0 kg if present | `null` | Body weight in kg. Null if not measured this entry |
| `bodyFatPercent` | `double?` | `RealColumn` | Optional, range 0.0-100.0 if present | `null` | Body fat percentage. Null if not measured |
| `waistCm` | `double?` | `RealColumn` | Optional, positive if present | `null` | Waist circumference in cm |
| `chestCm` | `double?` | `RealColumn` | Optional, positive if present | `null` | Chest circumference in cm |
| `armCm` | `double?` | `RealColumn` | Optional, positive if present | `null` | Upper arm circumference in cm |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp of row creation |

### Body Measurements Notes

- **At least one field required**: At least one of `weightKg`, `bodyFatPercent`, `waistCm`, `chestCm`, or `armCm` must be non-null per entry (BR-GYM-25).
- **Weight for bodyweight volume**: `GymDao.getLatestMeasurement()` is called during workout summary generation to retrieve the most recent `weightKg` for use in bodyweight exercise volume calculations.
- **Weight display unit**: `weightKg` is stored in kg but displayed in the user's preferred unit per AppSettings (`weightUnit` field). Conversion applies: kg × 2.20462 for lbs.
- **Phase 2**: This table is created in the schema from day one but the UI flow for logging measurements is deferred to Phase 2. The `GymNotifier.logMeasurement()` method is available but not surfaced in the MVP navigation.

---

## Input DTOs (Value Objects)

### SetInput

Carries the user's logged set data from the UI to `GymNotifier.logSet()` and `GymNotifier.updateSet()`.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `reps` | `int` | Required, > 0 | Number of repetitions |
| `weightKg` | `double?` | Optional, >= 0.0 if present | Weight in kg. Null indicates bodyweight |
| `rir` | `int?` | Optional, range 0-5 if present | Reps in reserve |
| `isWarmup` | `bool` | Required, defaults `false` | Whether this is a warmup set |

### RoutineInput

Carries data for creating or updating a routine.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `name` | `String` | Required, 1-50 chars after trim | Routine name |
| `description` | `String?` | Optional, maxLength: 200 | Optional description |
| `exercises` | `List<RoutineExerciseInput>` | Required, length >= 1 | Ordered list of exercises with their defaults |

### RoutineExerciseInput

Nested within `RoutineInput`. Defines a single exercise entry within the routine.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `exerciseId` | `int` | Required, must exist in exercises table | Referenced exercise |
| `sortOrder` | `int` | Required, >= 0 | Display and execution order |
| `defaultSets` | `int` | Required, range 1-20 | Default set count |
| `defaultReps` | `int` | Required, range 1-100 | Default rep count |
| `defaultWeightKg` | `double?` | Optional, >= 0.0 if present | Default weight in kg |
| `restSeconds` | `int` | Required, range 10-600 | Rest timer for this exercise |

### ExerciseInput

Carries data for creating a custom exercise.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `name` | `String` | Required, 1-100 chars after trim, globally unique (case-insensitive) | Exercise name |
| `primaryMuscle` | `MuscleGroup` | Required | Primary muscle group |
| `secondaryMuscles` | `List<MuscleGroup>` | Optional, may be empty | Secondary muscle groups |
| `equipment` | `Equipment` | Required | Equipment needed |
| `instructions` | `String?` | Optional, maxLength: 500 | Execution instructions |

### MeasurementInput

Carries data for logging a body measurement entry.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `date` | `DateTime` | Required | Date of measurement |
| `weightKg` | `double?` | Optional, range 20.0-500.0 | Body weight in kg |
| `bodyFatPercent` | `double?` | Optional, range 0.0-100.0 | Body fat percentage |
| `waistCm` | `double?` | Optional, > 0.0 | Waist circumference cm |
| `chestCm` | `double?` | Optional, > 0.0 | Chest circumference cm |
| `armCm` | `double?` | Optional, > 0.0 | Arm circumference cm |
| _At least one measurement field must be non-null_ | — | Enforced in Notifier | Prevents empty entries |

---

## GymState (Notifier State Value Object)

The state exposed by `GymNotifier` to the UI layer via Riverpod's `AsyncNotifier`.

```
class GymState {
  // Library & routines (loaded once, refreshed on mutation)
  List<Exercise> exercises;               // Filtered exercise list (by muscle group / search query)
  List<Routine> routines;                 // All user routines

  // Active workout (null when no workout in progress)
  Workout? activeWorkout;
  List<WorkoutSet> activeSets;            // All sets for the active workout, streamed live

  // Computed from activeSets (non-warmup sets only)
  Duration? currentWorkoutDuration;       // DateTime.now() - activeWorkout.startedAt
  Map<String, double> volumeByMuscleGroup; // muscle group name → total kg*reps

  // Weekly stats (rolling 7 days)
  int workoutsThisWeek;

  // Rest timer state (managed separately in TimerNotifier)
  // (RestTimerState is not part of GymState — it lives in a dedicated RestTimerNotifier)
}
```

---

## RoutineExerciseWithExercise (Join Result Value Object)

Returned by `GymDao.watchRoutineExercises()`. Combines data from the `routine_exercises` and `exercises` tables for display in the routine builder and workout screens.

| Field | Dart Type | Source | Description |
|---|---|---|---|
| `routineExercise` | `RoutineExercise` | routine_exercises row | Full routine exercise row (sortOrder, defaults, restSeconds) |
| `exercise` | `Exercise` | exercises row | Full exercise row (name, primaryMuscle, equipment) |

Convenience getters exposed on this class:
- `name` → `exercise.name`
- `primaryMuscle` → `exercise.primaryMuscle`
- `restSeconds` → `routineExercise.restSeconds`
- `defaultSets` → `routineExercise.defaultSets`
- `defaultReps` → `routineExercise.defaultReps`

---

## WorkoutSummary (Value Object)

Computed at the end of a workout (in `GymNotifier.finishWorkout()`) and displayed on the workout complete screen. Passed as part of the return value and also used to populate the `WorkoutCompletedEvent`.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `workoutId` | `int` | Required, positive | Completed workout ID |
| `duration` | `Duration` | Required, non-negative | Total workout duration |
| `totalSets` | `int` | Required, non-negative | Count of non-warmup sets logged |
| `totalVolume` | `double` | Required, non-negative | Sum of (weightKg × reps) for all non-warmup, non-bodyweight sets |
| `exercisesPerformed` | `List<String>` | Required (may be empty) | Ordered list of distinct exercise names logged |
| `newPRs` | `List<PRRecord>` | Required (may be empty) | All new personal records set during this workout |
| `volumeByMuscleGroup` | `Map<String, double>` | Required (may be empty map) | Total volume (kg×reps) per muscle group name, non-warmup sets only |
| `startedAt` | `DateTime` | Required | Workout start timestamp |
| `finishedAt` | `DateTime` | Required | Workout finish timestamp |

---

## PRRecord (Value Object)

Represents a new personal record detected when a set is logged. One `PRRecord` per (exercise, PR type) pair per workout.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `exerciseId` | `int` | Required, positive | The exercise for which the PR was set |
| `exerciseName` | `String` | Required, non-empty | Denormalized exercise name for display |
| `type` | `PRType` | Required | Whether this is a weight PR or volume PR |
| `previousValue` | `double?` | Optional | The previous PR value (null if this is the first-ever PR for this exercise) |
| `newValue` | `double` | Required, positive | The new PR value (kg for weight PR; kg×reps for volume PR) |

### PRType Enum

```
enum PRType {
  weight,   // Maximum weight lifted in a single set (non-warmup)
  volume    // Maximum single-set volume: weight × reps (non-warmup)
}
```

---

## WeightUnit (Enum in AppSettings)

New field added to the `AppSettings` Drift table as part of Unit 2 (Q2:B). Defines the user's preferred display unit for weight throughout the Gym module.

| Enum Value | Label | Conversion from kg |
|---|---|---|
| `kg` | kg | × 1.0 (no conversion) |
| `lbs` | lbs | × 2.20462 |

**Storage**: `weightUnit` is stored as a `TextColumn` in `AppSettings` using a `TypeConverter<WeightUnit, String>`. Default value: `'kg'`.

**Scope**: All weight-related display values in the Gym module read `AppSettings.weightUnit` and apply the conversion. Internal storage is always in kg.

---

## Entity Relationship Summary

```
AppSettings (1 row)
  |-- weightUnit: WeightUnit       (new field for Gym module, Q2:B)

Exercise (many rows)
  |-- primaryMuscle: MuscleGroup   (required enum)
  |-- secondaryMuscles: JSON list  (optional)
  |-- equipment: Equipment         (required enum)
  |
  └──< RoutineExercise (many, via routine_exercises)
        |-- routineId FK → Routine
        |-- restSeconds (per-exercise timer, Q3:B)
        |
        └── Routine (1)
              |-- name, description
              └── (cascade delete → RoutineExercise rows)

Workout (many rows)
  |-- routineId? FK → Routine      (nullable, preserved on routine delete)
  |-- finishedAt? = null means in-progress
  |
  └──< WorkoutSet (many, cascade delete)
        |-- exerciseId FK → Exercise
        |-- weightKg?  (null = bodyweight, Q6:B)
        |-- isWarmup   (excluded from PR/volume, Q4:C)
        |-- rir?       (0-5, reps in reserve)

BodyMeasurement (many rows)
  |-- weightKg?  (used for bodyweight exercise volume fallback)
  └── (standalone, no FK references)

PRRecord (in-memory value object, not persisted as its own table)
  |-- derived from workout_sets (max weight / max volume per exerciseId)
  └── surfaced via GymNotifier after set logging

WorkoutSummary (in-memory value object, computed at finishWorkout())
  |-- populated from workout_sets for a single workoutId
  |-- newPRs: List<PRRecord>
  └── triggers WorkoutCompletedEvent on EventBus
```
