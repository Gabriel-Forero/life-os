import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/gym/database/gym_dao.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late GymDao dao;

  setUp(() async {
    db = _createInMemoryDb();
    dao = db.gymDao;
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertExercise({String name = 'Press de banca'}) async {
    return dao.insertExercise(ExercisesCompanion.insert(
      name: name,
      primaryMuscle: 'Pecho',
      secondaryMuscles: const Value('["Triceps","Hombros"]'),
      equipment: const Value('Barra'),
      isCustom: const Value(false),
      isDownloaded: const Value(true),
      createdAt: DateTime.now(),
    ));
  }

  group('GymDao — Exercises', () {
    test('insertExercise returns id', () async {
      final id = await insertExercise();
      expect(id, greaterThan(0));
    });

    test('bulkInsertExercises inserts multiple', () async {
      final exercises = List.generate(
        10,
        (i) => ExercisesCompanion.insert(
          name: 'Exercise $i',
          primaryMuscle: 'Pecho',
          isCustom: const Value(false),
          isDownloaded: const Value(true),
          createdAt: DateTime.now(),
        ),
      );
      await dao.bulkInsertExercises(exercises);
      final count = await dao.countExercises();
      expect(count, 10);
    });

    test('countExercises returns correct count', () async {
      await insertExercise(name: 'Ex1');
      await insertExercise(name: 'Ex2');
      final count = await dao.countExercises();
      expect(count, 2);
    });

    test('watchExercises filters by muscle group', () async {
      await insertExercise(name: 'Bench');
      await dao.insertExercise(ExercisesCompanion.insert(
        name: 'Curl',
        primaryMuscle: 'Biceps',
        isCustom: const Value(false),
        isDownloaded: const Value(true),
        createdAt: DateTime.now(),
      ));

      final pecho = await dao.watchExercises(muscleGroup: 'Pecho').first;
      expect(pecho, hasLength(1));
      expect(pecho.first.name, 'Bench');
    });

    test('watchExercises filters by search query', () async {
      await insertExercise(name: 'Press de banca');
      await insertExercise(name: 'Press militar');
      await insertExercise(name: 'Curl biceps');

      final results = await dao.watchExercises(query: 'press').first;
      expect(results, hasLength(2));
    });
  });

  group('GymDao — Routines', () {
    test('insertRoutine returns id', () async {
      final id = await dao.insertRoutine(RoutinesCompanion.insert(
        name: 'Push Day',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      expect(id, greaterThan(0));
    });

    test('watchRoutines returns all', () async {
      await dao.insertRoutine(RoutinesCompanion.insert(
        name: 'Push', createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      await dao.insertRoutine(RoutinesCompanion.insert(
        name: 'Pull', createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));

      final routines = await dao.watchRoutines().first;
      expect(routines, hasLength(2));
    });

    test('deleteRoutine removes the row', () async {
      final id = await dao.insertRoutine(RoutinesCompanion.insert(
        name: 'Temp', createdAt: DateTime.now(), updatedAt: DateTime.now(),
      ));
      await dao.deleteRoutine(id);
      final routines = await dao.watchRoutines().first;
      expect(routines, isEmpty);
    });
  });

  group('GymDao — Workouts', () {
    test('insertWorkout and getActiveWorkout', () async {
      await dao.insertWorkout(WorkoutsCompanion.insert(
        startedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      final active = await dao.getActiveWorkout();
      expect(active, isNotNull);
      expect(active!.finishedAt, isNull);
    });

    test('finishWorkout sets finishedAt', () async {
      final id = await dao.insertWorkout(WorkoutsCompanion.insert(
        startedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      await dao.finishWorkout(id, DateTime.now());

      final active = await dao.getActiveWorkout();
      expect(active, isNull);
    });

    test('watchWorkouts returns completed workouts', () async {
      final id = await dao.insertWorkout(WorkoutsCompanion.insert(
        startedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));
      await dao.finishWorkout(id, DateTime.now());

      final workouts = await dao.watchWorkouts().first;
      expect(workouts, hasLength(1));
      expect(workouts.first.finishedAt, isNotNull);
    });
  });

  group('GymDao — Workout Sets', () {
    test('insertWorkoutSet and watchWorkoutSets', () async {
      final exId = await insertExercise();
      final wId = await dao.insertWorkout(WorkoutsCompanion.insert(
        startedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      await dao.insertWorkoutSet(WorkoutSetsCompanion.insert(
        workoutId: wId,
        exerciseId: exId,
        setNumber: 1,
        reps: 10,
        weightKg: const Value(80.0),
        isWarmup: const Value(false),
        createdAt: DateTime.now(),
      ));

      final sets = await dao.watchWorkoutSets(wId).first;
      expect(sets, hasLength(1));
      expect(sets.first.reps, 10);
      expect(sets.first.weightKg, 80.0);
    });

    test('bodyweight set has null weightKg', () async {
      final exId = await insertExercise(name: 'Fondos');
      final wId = await dao.insertWorkout(WorkoutsCompanion.insert(
        startedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      await dao.insertWorkoutSet(WorkoutSetsCompanion.insert(
        workoutId: wId,
        exerciseId: exId,
        setNumber: 1,
        reps: 15,
        isWarmup: const Value(false),
        createdAt: DateTime.now(),
      ));

      final sets = await dao.watchWorkoutSets(wId).first;
      expect(sets.first.weightKg, isNull);
    });

    test('getWeightPR returns max non-warmup weight', () async {
      final exId = await insertExercise();
      final wId = await dao.insertWorkout(WorkoutsCompanion.insert(
        startedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      // Warmup set — should be excluded
      await dao.insertWorkoutSet(WorkoutSetsCompanion.insert(
        workoutId: wId, exerciseId: exId, setNumber: 1, reps: 10,
        weightKg: const Value(100.0), isWarmup: const Value(true),
        createdAt: DateTime.now(),
      ));
      // Work set
      await dao.insertWorkoutSet(WorkoutSetsCompanion.insert(
        workoutId: wId, exerciseId: exId, setNumber: 2, reps: 8,
        weightKg: const Value(80.0), isWarmup: const Value(false),
        createdAt: DateTime.now(),
      ));

      final pr = await dao.getWeightPR(exId);
      expect(pr, 80.0); // Warmup excluded
    });

    test('getVolumePR returns max weight*reps non-warmup', () async {
      final exId = await insertExercise();
      final wId = await dao.insertWorkout(WorkoutsCompanion.insert(
        startedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      await dao.insertWorkoutSet(WorkoutSetsCompanion.insert(
        workoutId: wId, exerciseId: exId, setNumber: 1, reps: 10,
        weightKg: const Value(60.0), isWarmup: const Value(false),
        createdAt: DateTime.now(),
      )); // volume = 600
      await dao.insertWorkoutSet(WorkoutSetsCompanion.insert(
        workoutId: wId, exerciseId: exId, setNumber: 2, reps: 5,
        weightKg: const Value(80.0), isWarmup: const Value(false),
        createdAt: DateTime.now(),
      )); // volume = 400

      final pr = await dao.getVolumePR(exId);
      expect(pr, 600.0); // 60*10 > 80*5
    });
  });
}
