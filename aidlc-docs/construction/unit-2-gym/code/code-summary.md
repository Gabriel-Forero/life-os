# Code Summary — Unit 2: Gym (TDD)

## Overview

Unit 2 delivers the complete Gym module following strict TDD. **~16 Dart files** created (6+ source + 5 UI + 4 test). **4 RED→GREEN TDD cycles** executed.

## TDD Cycles Executed

| Cycle | RED (Test First) | GREEN (Implement) | Tests |
|---|---|---|---|
| 1 | GymDao tests | 6 Drift tables + GymDao | 15 pass |
| 2 | Validators + 1RM + conversion tests | gym_validators.dart | 25 pass |
| 3 | GymNotifier tests | GymNotifier (workout lifecycle, routines, exercises) | 12 pass |
| 4 | PBT property tests | (validated existing code) | 8 pass |

**Total: 60 Gym-specific tests (52 unit + 8 PBT)**

## Files Created

### Database (2 source + 1 generated)
- `gym_tables.dart` — 6 Drift tables (Exercises, Routines, RoutineExercises, Workouts, WorkoutSets, BodyMeasurements)
- `gym_dao.dart` — Full DAO: exercise CRUD + bulk insert, routine CRUD + cascade delete, workout lifecycle, set CRUD, PR queries (weight + volume), body measurements

### Domain (2 files)
- `gym_input.dart` — SetInput, RoutineInput (nested RoutineExerciseInput), MeasurementInput DTOs
- `gym_validators.dart` — validateExerciseName, validateReps, validateWeight (nullable), validateRIR, validateRoutineName, calculate1RM (Epley), kgToLbs/lbsToKg

### Providers (1 file)
- `gym_notifier.dart` — Full business logic: startWorkout (single active guard), logSet (auto-save per set, validation), finishWorkout (summary, WorkoutCompletedEvent), discardWorkout, createRoutine (min 1 exercise), addCustomExercise (duplicate check), logMeasurement

### Presentation (5 files)
- `exercise_library_screen.dart` — Search + muscle group filters + exercise cards
- `routine_builder_screen.dart` — ReorderableListView, exercise picker, save validation
- `active_workout_screen.dart` — Live timer, set logging, rest timer, finish/discard
- `workout_history_screen.dart` — Chronological list, detail drill-down
- `body_measurements_screen.dart` — Form + trend charts (Phase 2)

### Assets (1 file)
- `assets/exercises.json` — 20 exercises covering all 11 muscle groups (expandable to 200+)

### Tests (4 files)
- **Unit**: gym_dao_test (15), gym_validators_test (25), gym_notifier_test (12)
- **PBT**: gym_property_test (8 properties: 2 RT, 4 INV, 2 IDP)

## Key Design Decisions Applied

- **Q1:A** — Exercise library bundled as JSON asset
- **Q2:B** — Weight stored as kg, display in kg/lbs per user preference
- **Q3:B** — Rest timer per-exercise in routine, 90s fallback
- **Q4:C** — Weight PR + Volume PR tracked (warmups excluded)
- **Q5:A** — Auto-save every set to Drift
- **Q6:B** — Nullable weightKg for bodyweight exercises
- **Q7:C** — Primary + secondary muscles per exercise

## Analysis Status

- Full test suite: **219 tests pass** (Unit 0 + Unit 1 + Unit 2, zero regressions)
