import 'package:life_os/features/gym/domain/models/body_measurement_model.dart';
import 'package:life_os/features/gym/domain/models/exercise_model.dart';
import 'package:life_os/features/gym/domain/models/routine_exercise_model.dart';
import 'package:life_os/features/gym/domain/models/routine_model.dart';
import 'package:life_os/features/gym/domain/models/workout_model.dart';
import 'package:life_os/features/gym/domain/models/workout_set_model.dart';

abstract class GymRepository {
  // --- Exercises ---

  Future<String> insertExercise({
    required String name,
    required String primaryMuscle,
    String? secondaryMuscles,
    String? equipment,
    String? instructions,
    required bool isCustom,
    required bool isDownloaded,
    required DateTime createdAt,
  });

  Future<void> updateExercise(ExerciseModel exercise);

  Future<void> bulkInsertExercises(List<ExerciseModel> exercises);

  Future<int> countExercises();

  Stream<List<ExerciseModel>> watchExercises({
    String? muscleGroup,
    String? query,
  });

  Future<int> countSetsForExercise(String exerciseId);

  Future<void> deleteExercise(String exerciseId);

  Future<void> deleteExerciseFromRoutines(String exerciseId);

  // --- Routines ---

  Future<String> insertRoutine({
    required String name,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
  });

  Future<void> updateRoutine(RoutineModel routine);

  Future<void> deleteRoutine(String id);

  Stream<List<RoutineModel>> watchRoutines();

  // --- Routine Exercises ---

  Future<void> setRoutineExercises(
    String routineId,
    List<RoutineExerciseModel> exerciseList,
  );

  Stream<List<RoutineExerciseModel>> watchRoutineExercises(String routineId);

  Stream<List<RoutineExerciseModel>> watchRoutineExercisesForDay(
    String routineId,
    int dayNumber,
  );

  Future<List<int>> getDayNumbers(String routineId);

  Future<Map<int, String?>> getDayNames(String routineId);

  // --- Workouts ---

  Future<String> insertWorkout({
    String? routineId,
    required DateTime startedAt,
    required DateTime createdAt,
  });

  Future<WorkoutModel?> getActiveWorkout();

  Future<void> finishWorkout(String id, DateTime finishedAt);

  Future<void> updateWorkoutNote(String id, String? note);

  Future<void> deleteWorkout(String id);

  Stream<List<WorkoutModel>> watchWorkouts({int? limit});

  // --- Workout Sets ---

  Future<String> insertWorkoutSet({
    required String workoutId,
    required String exerciseId,
    required int setNumber,
    required int reps,
    double? weightKg,
    int? rir,
    required bool isWarmup,
    required DateTime createdAt,
  });

  Future<void> updateWorkoutSet(WorkoutSetModel set);

  Future<void> deleteWorkoutSet(String id);

  Stream<List<WorkoutSetModel>> watchWorkoutSets(String workoutId);

  Future<double?> getWeightPR(String exerciseId);

  Future<double?> getVolumePR(String exerciseId);

  // --- Body Measurements ---

  Future<String> insertMeasurement({
    required DateTime date,
    double? weightKg,
    double? bodyFatPercent,
    double? waistCm,
    double? chestCm,
    double? armCm,
    double? neckCm,
    double? shouldersCm,
    double? forearmCm,
    double? thighCm,
    double? calfCm,
    double? hipCm,
    double? muscleMassKg,
    double? bodyWaterPercent,
    double? heightCm,
    String? photoFrontPath,
    String? photoSidePath,
    String? photoBackPath,
    String? note,
    required DateTime createdAt,
  });

  Stream<List<BodyMeasurementModel>> watchMeasurements({int? limit});

  Future<BodyMeasurementModel?> getLatestMeasurement();
}
