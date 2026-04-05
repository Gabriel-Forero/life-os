import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/gym/database/gym_tables.dart';

part 'gym_dao.g.dart';

@DriftAccessor(tables: [
  Exercises,
  Routines,
  RoutineExercises,
  Workouts,
  WorkoutSets,
  BodyMeasurements,
])
class GymDao extends DatabaseAccessor<AppDatabase> with _$GymDaoMixin {
  GymDao(super.db);

  // --- Exercises ---

  Future<int> insertExercise(ExercisesCompanion entry) =>
      into(exercises).insert(entry);

  Future<void> updateExercise(Exercise entry) =>
      (update(exercises)..where((e) => e.id.equals(entry.id))).write(
        ExercisesCompanion(
          name: Value(entry.name),
          primaryMuscle: Value(entry.primaryMuscle),
          secondaryMuscles: Value(entry.secondaryMuscles),
          equipment: Value(entry.equipment),
          instructions: Value(entry.instructions),
        ),
      );

  Future<void> bulkInsertExercises(List<ExercisesCompanion> entries) =>
      batch((b) => b.insertAll(exercises, entries));

  Future<int> countExercises() async {
    final query = selectOnly(exercises)..addColumns([exercises.id.count()]);
    final result = await query.getSingle();
    return result.read(exercises.id.count()) ?? 0;
  }

  Stream<List<Exercise>> watchExercises({
    String? muscleGroup,
    String? query,
  }) {
    final q = select(exercises);
    if (muscleGroup != null) {
      q.where((e) => e.primaryMuscle.equals(muscleGroup));
    }
    if (query != null && query.isNotEmpty) {
      q.where((e) => e.name.like('%$query%'));
    }
    q.orderBy([(e) => OrderingTerm.asc(e.name)]);
    return q.watch();
  }

  Future<int> countSetsForExercise(int exerciseId) async {
    final query = selectOnly(workoutSets)
      ..addColumns([workoutSets.id.count()])
      ..where(workoutSets.exerciseId.equals(exerciseId));
    final result = await query.getSingle();
    return result.read(workoutSets.id.count()) ?? 0;
  }

  // --- Routines ---

  Future<int> insertRoutine(RoutinesCompanion entry) =>
      into(routines).insert(entry);

  Future<void> updateRoutine(Routine entry) =>
      (update(routines)..where((r) => r.id.equals(entry.id))).write(
        RoutinesCompanion(
          name: Value(entry.name),
          description: Value(entry.description),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteRoutine(int id) async {
    await (delete(routineExercises)..where((re) => re.routineId.equals(id)))
        .go();
    await (delete(routines)..where((r) => r.id.equals(id))).go();
  }

  Stream<List<Routine>> watchRoutines() =>
      (select(routines)..orderBy([(r) => OrderingTerm.desc(r.updatedAt)]))
          .watch();

  // --- Routine Exercises ---

  Future<void> setRoutineExercises(
    int routineId,
    List<RoutineExercisesCompanion> exerciseList,
  ) async {
    await (delete(routineExercises)
          ..where((re) => re.routineId.equals(routineId)))
        .go();
    await batch((b) => b.insertAll(routineExercises, exerciseList));
  }

  Stream<List<RoutineExercise>> watchRoutineExercises(int routineId) =>
      (select(routineExercises)
            ..where((re) => re.routineId.equals(routineId))
            ..orderBy([(re) => OrderingTerm.asc(re.sortOrder)]))
          .watch();

  // --- Workouts ---

  Future<int> insertWorkout(WorkoutsCompanion entry) =>
      into(workouts).insert(entry);

  Future<Workout?> getActiveWorkout() =>
      (select(workouts)..where((w) => w.finishedAt.isNull()))
          .getSingleOrNull();

  Future<void> finishWorkout(int id, DateTime finishedAt) =>
      (update(workouts)..where((w) => w.id.equals(id)))
          .write(WorkoutsCompanion(finishedAt: Value(finishedAt)));

  Future<void> deleteWorkout(int id) async {
    await (delete(workoutSets)..where((s) => s.workoutId.equals(id))).go();
    await (delete(workouts)..where((w) => w.id.equals(id))).go();
  }

  Stream<List<Workout>> watchWorkouts({int? limit}) {
    final q = select(workouts)
      ..where((w) => w.finishedAt.isNotNull())
      ..orderBy([(w) => OrderingTerm.desc(w.startedAt)]);
    if (limit != null) q.limit(limit);
    return q.watch();
  }

  // --- Workout Sets ---

  Future<int> insertWorkoutSet(WorkoutSetsCompanion entry) =>
      into(workoutSets).insert(entry);

  Future<void> updateWorkoutSet(WorkoutSet entry) =>
      (update(workoutSets)..where((s) => s.id.equals(entry.id))).write(
        WorkoutSetsCompanion(
          reps: Value(entry.reps),
          weightKg: Value(entry.weightKg),
          rir: Value(entry.rir),
          isWarmup: Value(entry.isWarmup),
        ),
      );

  Future<void> deleteWorkoutSet(int id) =>
      (delete(workoutSets)..where((s) => s.id.equals(id))).go();

  Stream<List<WorkoutSet>> watchWorkoutSets(int workoutId) =>
      (select(workoutSets)
            ..where((s) => s.workoutId.equals(workoutId))
            ..orderBy([
              (s) => OrderingTerm.asc(s.exerciseId),
              (s) => OrderingTerm.asc(s.setNumber),
            ]))
          .watch();

  Future<double?> getWeightPR(int exerciseId) async {
    final query = selectOnly(workoutSets)
      ..addColumns([workoutSets.weightKg.max()])
      ..where(
        workoutSets.exerciseId.equals(exerciseId) &
            workoutSets.isWarmup.equals(false) &
            workoutSets.weightKg.isNotNull(),
      );
    final result = await query.getSingle();
    return result.read(workoutSets.weightKg.max());
  }

  Future<double?> getVolumePR(int exerciseId) async {
    // Volume = weight * reps. We need to compute per-row and take max.
    // Drift doesn't support computed columns easily, so we query all work sets.
    final sets = await (select(workoutSets)
          ..where(
            (s) =>
                s.exerciseId.equals(exerciseId) &
                s.isWarmup.equals(false) &
                s.weightKg.isNotNull(),
          ))
        .get();

    if (sets.isEmpty) return null;
    return sets
        .map((s) => s.weightKg! * s.reps)
        .reduce((a, b) => a > b ? a : b);
  }

  // --- Body Measurements ---

  Future<int> insertMeasurement(BodyMeasurementsCompanion entry) =>
      into(bodyMeasurements).insert(entry);

  Stream<List<BodyMeasurement>> watchMeasurements({int? limit}) {
    final q = select(bodyMeasurements)
      ..orderBy([(m) => OrderingTerm.desc(m.date)]);
    if (limit != null) q.limit(limit);
    return q.watch();
  }

  Future<BodyMeasurement?> getLatestMeasurement() =>
      (select(bodyMeasurements)
            ..orderBy([(m) => OrderingTerm.desc(m.date)])
            ..limit(1))
          .getSingleOrNull();
}
