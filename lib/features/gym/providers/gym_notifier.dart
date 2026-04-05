import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/gym/database/gym_dao.dart';
import 'package:life_os/features/gym/domain/gym_input.dart';
import 'package:life_os/features/gym/domain/gym_validators.dart';

class GymNotifier {
  GymNotifier({required this.dao, required this.eventBus});

  final GymDao dao;
  final EventBus eventBus;

  // --- Workout Lifecycle ---

  Future<Result<int>> startWorkout({int? routineId}) async {
    final active = await dao.getActiveWorkout();
    if (active != null) {
      return const Failure(ValidationFailure(
        userMessage: 'Ya tienes un entrenamiento en curso',
        debugMessage: 'Cannot start workout: one already active',
        field: 'workout',
      ));
    }

    try {
      final id = await dao.insertWorkout(WorkoutsCompanion.insert(
        routineId: Value(routineId),
        startedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al iniciar entrenamiento',
        debugMessage: 'insertWorkout failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<int>> logSet(
    int workoutId,
    int exerciseId,
    SetInput input,
  ) async {
    final repsResult = validateReps(input.reps);
    if (repsResult.isFailure) return Failure(repsResult.failureOrNull!);

    final weightResult = validateWeight(input.weightKg);
    if (weightResult.isFailure) return Failure(weightResult.failureOrNull!);

    final rirResult = validateRIR(input.rir);
    if (rirResult.isFailure) return Failure(rirResult.failureOrNull!);

    try {
      // Determine set number
      final existingSets = await dao.watchWorkoutSets(workoutId).first;
      final exerciseSets =
          existingSets.where((s) => s.exerciseId == exerciseId);
      final setNumber = exerciseSets.length + 1;

      final id = await dao.insertWorkoutSet(WorkoutSetsCompanion.insert(
        workoutId: workoutId,
        exerciseId: exerciseId,
        setNumber: setNumber,
        reps: input.reps,
        weightKg: Value(input.weightKg),
        rir: Value(input.rir),
        isWarmup: Value(input.isWarmup),
        createdAt: DateTime.now(),
      ));
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al registrar serie',
        debugMessage: 'insertWorkoutSet failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> finishWorkout(int workoutId, {String? note}) async {
    try {
      final now = DateTime.now();
      await dao.finishWorkout(workoutId, now);

      if (note != null) {
        await (dao.db.update(dao.db.workouts)
              ..where((w) => w.id.equals(workoutId)))
            .write(WorkoutsCompanion(note: Value(note)));
      }

      // Compute summary for event
      final sets = await dao.watchWorkoutSets(workoutId).first;
      final workSets = sets.where((s) => !s.isWarmup);
      final totalVolume = workSets
          .where((s) => s.weightKg != null)
          .fold<double>(0.0, (sum, s) => sum + s.weightKg! * s.reps);

      final workout = (await dao.watchWorkouts().first)
          .where((w) => w.id == workoutId)
          .firstOrNull;
      final duration = workout != null && workout.finishedAt != null
          ? workout.finishedAt!.difference(workout.startedAt)
          : Duration.zero;

      eventBus.emit(WorkoutCompletedEvent(
        workoutId: workoutId,
        duration: duration,
        totalVolume: totalVolume,
      ));

      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al finalizar entrenamiento',
        debugMessage: 'finishWorkout failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> discardWorkout(int workoutId) async {
    try {
      await dao.deleteWorkout(workoutId);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al descartar entrenamiento',
        debugMessage: 'deleteWorkout failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Routines ---

  Future<Result<int>> createRoutine(RoutineInput input) async {
    final nameResult = validateRoutineName(input.name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    if (input.exercises.isEmpty) {
      return const Failure(ValidationFailure(
        userMessage: 'Agrega al menos un ejercicio a tu rutina',
        debugMessage: 'Routine must have at least 1 exercise',
        field: 'exercises',
      ));
    }

    try {
      final now = DateTime.now();
      final routineId = await dao.insertRoutine(RoutinesCompanion.insert(
        name: nameResult.valueOrNull!,
        description: Value(input.description),
        createdAt: now,
        updatedAt: now,
      ));

      final companions = input.exercises
          .asMap()
          .entries
          .map(
            (e) => RoutineExercisesCompanion.insert(
              routineId: routineId,
              exerciseId: e.value.exerciseId,
              sortOrder: Value(e.key),
              defaultSets: Value(e.value.defaultSets),
              defaultReps: Value(e.value.defaultReps),
              defaultWeightKg: Value(e.value.defaultWeightKg),
              restSeconds: Value(e.value.restSeconds),
              createdAt: now,
            ),
          )
          .toList();

      await dao.setRoutineExercises(routineId, companions);
      return Success(routineId);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al crear rutina',
        debugMessage: 'createRoutine failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Custom Exercises ---

  Future<Result<int>> addCustomExercise({
    required String name,
    required String primaryMuscle,
    String? equipment,
    String? instructions,
    List<String>? secondaryMuscles,
  }) async {
    final nameResult = validateExerciseName(name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    try {
      final id = await dao.insertExercise(ExercisesCompanion.insert(
        name: nameResult.valueOrNull!,
        primaryMuscle: primaryMuscle,
        secondaryMuscles: Value(
          secondaryMuscles != null ? jsonEncode(secondaryMuscles) : null,
        ),
        equipment: Value(equipment),
        instructions: Value(instructions),
        isCustom: const Value(true),
        isDownloaded: const Value(false),
        createdAt: DateTime.now(),
      ));
      return Success(id);
    } on Exception catch (e) {
      if (e.toString().contains('UNIQUE')) {
        return const Failure(ValidationFailure(
          userMessage: 'Ya existe un ejercicio con ese nombre',
          debugMessage: 'Duplicate exercise name',
          field: 'name',
        ));
      }
      return Failure(DatabaseFailure(
        userMessage: 'Error al crear ejercicio',
        debugMessage: 'insertExercise failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> deleteCustomExercise(int exerciseId) async {
    final setsCount = await dao.countSetsForExercise(exerciseId);
    if (setsCount > 0) {
      return Failure(ValidationFailure(
        userMessage:
            'Este ejercicio tiene $setsCount series registradas. No se puede eliminar.',
        debugMessage:
            'Cannot delete exercise $exerciseId: $setsCount workout_sets reference it',
        field: 'exerciseId',
      ));
    }

    try {
      // Also remove from any routines
      await dao.db.transaction(() async {
        await (dao.db.delete(dao.db.routineExercises)
              ..where((re) => re.exerciseId.equals(exerciseId)))
            .go();
        await (dao.db.delete(dao.db.exercises)
              ..where((e) => e.id.equals(exerciseId)))
            .go();
      });
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al eliminar ejercicio',
        debugMessage: 'deleteCustomExercise failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Body Measurements ---

  Future<Result<int>> logMeasurement(MeasurementInput input) async {
    if (!input.hasAnyValue) {
      return const Failure(ValidationFailure(
        userMessage: 'Ingresa al menos una medida',
        debugMessage: 'All measurement fields are null',
        field: 'measurement',
      ));
    }

    try {
      final id = await dao.insertMeasurement(BodyMeasurementsCompanion.insert(
        date: DateTime.now(),
        weightKg: Value(input.weightKg),
        bodyFatPercent: Value(input.bodyFatPercent),
        waistCm: Value(input.waistCm),
        chestCm: Value(input.chestCm),
        armCm: Value(input.armCm),
        createdAt: DateTime.now(),
      ));
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al registrar medidas',
        debugMessage: 'insertMeasurement failed: $e',
        originalError: e,
      ));
    }
  }
}
