import 'dart:convert';

import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/gym/data/gym_repository.dart';
import 'package:life_os/features/gym/domain/gym_input.dart';
import 'package:life_os/features/gym/domain/gym_validators.dart';
import 'package:life_os/features/gym/domain/models/routine_exercise_model.dart';

class GymNotifier {
  GymNotifier({required this.repository, required this.eventBus});

  final GymRepository repository;
  final EventBus eventBus;

  // --- Workout Lifecycle ---

  Future<Result<String>> startWorkout({String? routineId}) async {
    final active = await repository.getActiveWorkout();
    if (active != null) {
      return const Failure(ValidationFailure(
        userMessage: 'Ya tienes un entrenamiento en curso',
        debugMessage: 'Cannot start workout: one already active',
        field: 'workout',
      ));
    }

    try {
      final id = await repository.insertWorkout(
        routineId: routineId,
        startedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al iniciar entrenamiento',
        debugMessage: 'insertWorkout failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<String>> logSet(
    String workoutId,
    String exerciseId,
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
      final existingSets = await repository.watchWorkoutSets(workoutId).first;
      final exerciseSets =
          existingSets.where((s) => s.exerciseId == exerciseId);
      final setNumber = exerciseSets.length + 1;

      final id = await repository.insertWorkoutSet(
        workoutId: workoutId,
        exerciseId: exerciseId,
        setNumber: setNumber,
        reps: input.reps,
        weightKg: input.weightKg,
        rir: input.rir,
        isWarmup: input.isWarmup,
        createdAt: DateTime.now(),
      );
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al registrar serie',
        debugMessage: 'insertWorkoutSet failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> finishWorkout(String workoutId,
      {String? note}) async {
    try {
      final now = DateTime.now();
      await repository.finishWorkout(workoutId, now);

      if (note != null) {
        await repository.updateWorkoutNote(workoutId, note);
      }

      // Compute summary for event
      final sets = await repository.watchWorkoutSets(workoutId).first;
      final workSets = sets.where((s) => !s.isWarmup);
      final totalVolume = workSets
          .where((s) => s.weightKg != null)
          .fold<double>(0.0, (sum, s) => sum + s.weightKg! * s.reps);

      final allWorkouts = await repository.watchWorkouts().first;
      final workout =
          allWorkouts.where((w) => w.id == workoutId).firstOrNull;
      final duration = workout != null && workout.finishedAt != null
          ? workout.finishedAt!.difference(workout.startedAt)
          : Duration.zero;

      eventBus.emit(WorkoutCompletedEvent(
        workoutId: int.tryParse(workoutId) ?? 0,
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

  Future<Result<void>> discardWorkout(String workoutId) async {
    try {
      await repository.deleteWorkout(workoutId);
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

  Future<Result<String>> createRoutine(RoutineInput input) async {
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
      final routineId = await repository.insertRoutine(
        name: nameResult.valueOrNull!,
        description: input.description,
        createdAt: now,
        updatedAt: now,
      );

      // Compute per-day position counters so sortOrder encodes
      // dayNumber * 1000 + positionWithinDay.
      final Map<int, int> dayPositions = {};
      final companions = input.exercises.map((ex) {
        final pos = dayPositions.update(
          ex.dayNumber,
          (v) => v + 1,
          ifAbsent: () => 0,
        );
        final sort = ex.dayNumber * 1000 + pos;
        return RoutineExerciseModel(
          id: '0', // ignored during insert
          routineId: routineId,
          exerciseId: ex.exerciseId,
          sortOrder: sort,
          dayNumber: ex.dayNumber,
          dayName: ex.dayName,
          defaultSets: ex.defaultSets,
          defaultReps: ex.defaultReps,
          defaultWeightKg: ex.defaultWeightKg,
          restSeconds: ex.restSeconds,
          createdAt: now,
        );
      }).toList();

      await repository.setRoutineExercises(routineId, companions);
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

  Future<Result<String>> addCustomExercise({
    required String name,
    required String primaryMuscle,
    String? equipment,
    String? instructions,
    List<String>? secondaryMuscles,
  }) async {
    final nameResult = validateExerciseName(name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    try {
      final id = await repository.insertExercise(
        name: nameResult.valueOrNull!,
        primaryMuscle: primaryMuscle,
        secondaryMuscles:
            secondaryMuscles != null ? jsonEncode(secondaryMuscles) : null,
        equipment: equipment,
        instructions: instructions,
        isCustom: true,
        isDownloaded: false,
        createdAt: DateTime.now(),
      );
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

  Future<Result<void>> deleteCustomExercise(String exerciseId) async {
    final setsCount = await repository.countSetsForExercise(exerciseId);
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
      await repository.deleteExerciseFromRoutines(exerciseId);
      await repository.deleteExercise(exerciseId);
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

  Future<Result<String>> logMeasurement(MeasurementInput input) async {
    if (!input.hasAnyValue) {
      return const Failure(ValidationFailure(
        userMessage: 'Ingresa al menos una medida',
        debugMessage: 'All measurement fields are null',
        field: 'measurement',
      ));
    }

    try {
      final id = await repository.insertMeasurement(
        date: DateTime.now(),
        weightKg: input.weightKg,
        bodyFatPercent: input.bodyFatPercent,
        waistCm: input.waistCm,
        chestCm: input.chestCm,
        armCm: input.armCm,
        neckCm: input.neckCm,
        shouldersCm: input.shouldersCm,
        forearmCm: input.forearmCm,
        thighCm: input.thighCm,
        calfCm: input.calfCm,
        hipCm: input.hipCm,
        muscleMassKg: input.muscleMassKg,
        bodyWaterPercent: input.bodyWaterPercent,
        heightCm: input.heightCm,
        photoFrontPath: input.photoFrontPath,
        photoSidePath: input.photoSidePath,
        photoBackPath: input.photoBackPath,
        note: input.note,
        createdAt: DateTime.now(),
      );
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
