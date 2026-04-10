import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/gym/data/gym_repository.dart';
import 'package:life_os/features/gym/database/gym_dao.dart';
import 'package:life_os/features/gym/domain/models/body_measurement_model.dart';
import 'package:life_os/features/gym/domain/models/exercise_model.dart';
import 'package:life_os/features/gym/domain/models/routine_exercise_model.dart';
import 'package:life_os/features/gym/domain/models/routine_model.dart';
import 'package:life_os/features/gym/domain/models/workout_model.dart';
import 'package:life_os/features/gym/domain/models/workout_set_model.dart';

class DriftGymRepository implements GymRepository {
  DriftGymRepository({required this.dao});

  final GymDao dao;

  // --- Mapping helpers ---

  static ExerciseModel _toExerciseModel(Exercise row) => ExerciseModel(
        id: row.id.toString(),
        name: row.name,
        primaryMuscle: row.primaryMuscle,
        secondaryMuscles: row.secondaryMuscles,
        equipment: row.equipment,
        instructions: row.instructions,
        isCustom: row.isCustom,
        isDownloaded: row.isDownloaded,
        createdAt: row.createdAt,
      );

  static RoutineModel _toRoutineModel(Routine row) => RoutineModel(
        id: row.id.toString(),
        name: row.name,
        description: row.description,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static RoutineExerciseModel _toRoutineExerciseModel(
    RoutineExercise row,
  ) =>
      RoutineExerciseModel(
        id: row.id.toString(),
        routineId: row.routineId.toString(),
        exerciseId: row.exerciseId.toString(),
        sortOrder: row.sortOrder,
        dayNumber: row.dayNumber,
        dayName: row.dayName,
        defaultSets: row.defaultSets,
        defaultReps: row.defaultReps,
        defaultWeightKg: row.defaultWeightKg,
        restSeconds: row.restSeconds,
        createdAt: row.createdAt,
      );

  static WorkoutModel _toWorkoutModel(Workout row) => WorkoutModel(
        id: row.id.toString(),
        routineId: row.routineId?.toString(),
        startedAt: row.startedAt,
        finishedAt: row.finishedAt,
        note: row.note,
        createdAt: row.createdAt,
      );

  static WorkoutSetModel _toWorkoutSetModel(WorkoutSet row) =>
      WorkoutSetModel(
        id: row.id.toString(),
        workoutId: row.workoutId.toString(),
        exerciseId: row.exerciseId.toString(),
        setNumber: row.setNumber,
        reps: row.reps,
        weightKg: row.weightKg,
        rir: row.rir,
        isWarmup: row.isWarmup,
        createdAt: row.createdAt,
      );

  static BodyMeasurementModel _toBodyMeasurementModel(
    BodyMeasurement row,
  ) =>
      BodyMeasurementModel(
        id: row.id.toString(),
        date: row.date,
        weightKg: row.weightKg,
        bodyFatPercent: row.bodyFatPercent,
        waistCm: row.waistCm,
        chestCm: row.chestCm,
        armCm: row.armCm,
        neckCm: row.neckCm,
        shouldersCm: row.shouldersCm,
        forearmCm: row.forearmCm,
        thighCm: row.thighCm,
        calfCm: row.calfCm,
        hipCm: row.hipCm,
        muscleMassKg: row.muscleMassKg,
        bodyWaterPercent: row.bodyWaterPercent,
        heightCm: row.heightCm,
        photoFrontPath: row.photoFrontPath,
        photoSidePath: row.photoSidePath,
        photoBackPath: row.photoBackPath,
        note: row.note,
        createdAt: row.createdAt,
      );

  // --- Exercises ---

  @override
  Future<String> insertExercise({
    required String name,
    required String primaryMuscle,
    String? secondaryMuscles,
    String? equipment,
    String? instructions,
    required bool isCustom,
    required bool isDownloaded,
    required DateTime createdAt,
  }) async {
    final id = await dao.insertExercise(ExercisesCompanion.insert(
      name: name,
      primaryMuscle: primaryMuscle,
      secondaryMuscles: Value(secondaryMuscles),
      equipment: Value(equipment),
      instructions: Value(instructions),
      isCustom: Value(isCustom),
      isDownloaded: Value(isDownloaded),
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Future<void> updateExercise(ExerciseModel exercise) async {
    final intId = int.tryParse(exercise.id);
    if (intId == null) return;
    await dao.updateExercise(Exercise(
      id: intId,
      name: exercise.name,
      primaryMuscle: exercise.primaryMuscle,
      secondaryMuscles: exercise.secondaryMuscles,
      equipment: exercise.equipment,
      instructions: exercise.instructions,
      isCustom: exercise.isCustom,
      isDownloaded: exercise.isDownloaded,
      createdAt: exercise.createdAt,
    ));
  }

  @override
  Future<void> bulkInsertExercises(List<ExerciseModel> exercises) async {
    final companions = exercises
        .map((e) => ExercisesCompanion.insert(
              name: e.name,
              primaryMuscle: e.primaryMuscle,
              secondaryMuscles: Value(e.secondaryMuscles),
              equipment: Value(e.equipment),
              instructions: Value(e.instructions),
              isCustom: Value(e.isCustom),
              isDownloaded: Value(e.isDownloaded),
              createdAt: e.createdAt,
            ))
        .toList();
    await dao.bulkInsertExercises(companions);
  }

  @override
  Future<int> countExercises() => dao.countExercises();

  @override
  Stream<List<ExerciseModel>> watchExercises({
    String? muscleGroup,
    String? query,
  }) {
    return dao
        .watchExercises(muscleGroup: muscleGroup, query: query)
        .map((rows) => rows.map(_toExerciseModel).toList());
  }

  @override
  Future<int> countSetsForExercise(String exerciseId) async {
    final intId = int.tryParse(exerciseId);
    if (intId == null) return 0;
    return dao.countSetsForExercise(intId);
  }

  @override
  Future<void> deleteExercise(String exerciseId) async {
    final intId = int.tryParse(exerciseId);
    if (intId == null) return;
    await (dao.db.delete(dao.db.exercises)
          ..where((e) => e.id.equals(intId)))
        .go();
  }

  @override
  Future<void> deleteExerciseFromRoutines(String exerciseId) async {
    final intId = int.tryParse(exerciseId);
    if (intId == null) return;
    await (dao.db.delete(dao.db.routineExercises)
          ..where((re) => re.exerciseId.equals(intId)))
        .go();
  }

  // --- Routines ---

  @override
  Future<String> insertRoutine({
    required String name,
    String? description,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final id = await dao.insertRoutine(RoutinesCompanion.insert(
      name: name,
      description: Value(description),
      createdAt: createdAt,
      updatedAt: updatedAt,
    ));
    return id.toString();
  }

  @override
  Future<void> updateRoutine(RoutineModel routine) async {
    final intId = int.tryParse(routine.id);
    if (intId == null) return;
    await dao.updateRoutine(Routine(
      id: intId,
      name: routine.name,
      description: routine.description,
      createdAt: routine.createdAt,
      updatedAt: routine.updatedAt,
    ));
  }

  @override
  Future<void> deleteRoutine(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.deleteRoutine(intId);
  }

  @override
  Stream<List<RoutineModel>> watchRoutines() {
    return dao
        .watchRoutines()
        .map((rows) => rows.map(_toRoutineModel).toList());
  }

  // --- Routine Exercises ---

  @override
  Future<void> setRoutineExercises(
    String routineId,
    List<RoutineExerciseModel> exerciseList,
  ) async {
    final intRoutineId = int.tryParse(routineId);
    if (intRoutineId == null) return;
    final companions = exerciseList.map((e) {
      final intExerciseId = int.parse(e.exerciseId);
      return RoutineExercisesCompanion.insert(
        routineId: intRoutineId,
        exerciseId: intExerciseId,
        sortOrder: Value(e.sortOrder),
        dayNumber: Value(e.dayNumber),
        dayName: Value(e.dayName),
        defaultSets: Value(e.defaultSets),
        defaultReps: Value(e.defaultReps),
        defaultWeightKg: Value(e.defaultWeightKg),
        restSeconds: Value(e.restSeconds),
        createdAt: e.createdAt,
      );
    }).toList();
    await dao.setRoutineExercises(intRoutineId, companions);
  }

  @override
  Stream<List<RoutineExerciseModel>> watchRoutineExercises(
    String routineId,
  ) {
    final intId = int.tryParse(routineId);
    if (intId == null) return Stream.value([]);
    return dao
        .watchRoutineExercises(intId)
        .map((rows) => rows.map(_toRoutineExerciseModel).toList());
  }

  @override
  Stream<List<RoutineExerciseModel>> watchRoutineExercisesForDay(
    String routineId,
    int dayNumber,
  ) {
    final intId = int.tryParse(routineId);
    if (intId == null) return Stream.value([]);
    return dao
        .watchRoutineExercisesForDay(intId, dayNumber)
        .map((rows) => rows.map(_toRoutineExerciseModel).toList());
  }

  @override
  Future<List<int>> getDayNumbers(String routineId) async {
    final intId = int.tryParse(routineId);
    if (intId == null) return [];
    return dao.getDayNumbers(intId);
  }

  @override
  Future<Map<int, String?>> getDayNames(String routineId) async {
    final intId = int.tryParse(routineId);
    if (intId == null) return {};
    return dao.getDayNames(intId);
  }

  // --- Workouts ---

  @override
  Future<String> insertWorkout({
    String? routineId,
    required DateTime startedAt,
    required DateTime createdAt,
  }) async {
    final intRoutineId =
        routineId != null ? int.tryParse(routineId) : null;
    final id = await dao.insertWorkout(WorkoutsCompanion.insert(
      routineId: Value(intRoutineId),
      startedAt: startedAt,
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Future<WorkoutModel?> getActiveWorkout() async {
    final row = await dao.getActiveWorkout();
    return row != null ? _toWorkoutModel(row) : null;
  }

  @override
  Future<void> finishWorkout(String id, DateTime finishedAt) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.finishWorkout(intId, finishedAt);
  }

  @override
  Future<void> updateWorkoutNote(String id, String? note) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await (dao.db.update(dao.db.workouts)
          ..where((w) => w.id.equals(intId)))
        .write(WorkoutsCompanion(note: Value(note)));
  }

  @override
  Future<void> deleteWorkout(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.deleteWorkout(intId);
  }

  @override
  Stream<List<WorkoutModel>> watchWorkouts({int? limit}) {
    return dao
        .watchWorkouts(limit: limit)
        .map((rows) => rows.map(_toWorkoutModel).toList());
  }

  // --- Workout Sets ---

  @override
  Future<String> insertWorkoutSet({
    required String workoutId,
    required String exerciseId,
    required int setNumber,
    required int reps,
    double? weightKg,
    int? rir,
    required bool isWarmup,
    required DateTime createdAt,
  }) async {
    final intWorkoutId = int.parse(workoutId);
    final intExerciseId = int.parse(exerciseId);
    final id = await dao.insertWorkoutSet(WorkoutSetsCompanion.insert(
      workoutId: intWorkoutId,
      exerciseId: intExerciseId,
      setNumber: setNumber,
      reps: reps,
      weightKg: Value(weightKg),
      rir: Value(rir),
      isWarmup: Value(isWarmup),
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Future<void> updateWorkoutSet(WorkoutSetModel set) async {
    final intId = int.tryParse(set.id);
    if (intId == null) return;
    await dao.updateWorkoutSet(WorkoutSet(
      id: intId,
      workoutId: int.parse(set.workoutId),
      exerciseId: int.parse(set.exerciseId),
      setNumber: set.setNumber,
      reps: set.reps,
      weightKg: set.weightKg,
      rir: set.rir,
      isWarmup: set.isWarmup,
      createdAt: set.createdAt,
    ));
  }

  @override
  Future<void> deleteWorkoutSet(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.deleteWorkoutSet(intId);
  }

  @override
  Stream<List<WorkoutSetModel>> watchWorkoutSets(String workoutId) {
    final intId = int.tryParse(workoutId);
    if (intId == null) return Stream.value([]);
    return dao
        .watchWorkoutSets(intId)
        .map((rows) => rows.map(_toWorkoutSetModel).toList());
  }

  @override
  Future<double?> getWeightPR(String exerciseId) async {
    final intId = int.tryParse(exerciseId);
    if (intId == null) return null;
    return dao.getWeightPR(intId);
  }

  @override
  Future<double?> getVolumePR(String exerciseId) async {
    final intId = int.tryParse(exerciseId);
    if (intId == null) return null;
    return dao.getVolumePR(intId);
  }

  // --- Body Measurements ---

  @override
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
  }) async {
    final id =
        await dao.insertMeasurement(BodyMeasurementsCompanion.insert(
      date: date,
      weightKg: Value(weightKg),
      bodyFatPercent: Value(bodyFatPercent),
      waistCm: Value(waistCm),
      chestCm: Value(chestCm),
      armCm: Value(armCm),
      neckCm: Value(neckCm),
      shouldersCm: Value(shouldersCm),
      forearmCm: Value(forearmCm),
      thighCm: Value(thighCm),
      calfCm: Value(calfCm),
      hipCm: Value(hipCm),
      muscleMassKg: Value(muscleMassKg),
      bodyWaterPercent: Value(bodyWaterPercent),
      heightCm: Value(heightCm),
      photoFrontPath: Value(photoFrontPath),
      photoSidePath: Value(photoSidePath),
      photoBackPath: Value(photoBackPath),
      note: Value(note),
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Stream<List<BodyMeasurementModel>> watchMeasurements({int? limit}) {
    return dao
        .watchMeasurements(limit: limit)
        .map((rows) => rows.map(_toBodyMeasurementModel).toList());
  }

  @override
  Future<BodyMeasurementModel?> getLatestMeasurement() async {
    final row = await dao.getLatestMeasurement();
    return row != null ? _toBodyMeasurementModel(row) : null;
  }
}
