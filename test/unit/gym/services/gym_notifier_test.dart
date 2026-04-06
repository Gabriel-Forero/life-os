import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/gym/database/gym_dao.dart';
import 'package:life_os/features/gym/domain/gym_input.dart';
import 'package:life_os/features/gym/providers/gym_notifier.dart';

void main() {
  late AppDatabase db;
  late GymDao dao;
  late EventBus eventBus;
  late GymNotifier notifier;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.gymDao;
    eventBus = EventBus();
    notifier = GymNotifier(dao: dao, eventBus: eventBus);
  });

  tearDown(() async {
    eventBus.dispose();
    await db.close();
  });

  Future<int> insertExercise({String name = 'Press de banca'}) async {
    return dao.insertExercise(ExercisesCompanion.insert(
      name: name,
      primaryMuscle: 'Pecho',
      isCustom: const Value(false),
      isDownloaded: const Value(true),
      createdAt: DateTime.now(),
    ));
  }

  group('GymNotifier — Workout Lifecycle', () {
    test('startWorkout creates in-progress workout', () async {
      final result = await notifier.startWorkout();
      expect(result, isA<Success<int>>());

      final active = await dao.getActiveWorkout();
      expect(active, isNotNull);
      expect(active!.finishedAt, isNull);
    });

    test('startWorkout fails if one already active', () async {
      await notifier.startWorkout();
      final result = await notifier.startWorkout();
      expect(result, isA<Failure<int>>());
    });

    test('logSet persists immediately (auto-save)', () async {
      final exId = await insertExercise();
      final wResult = await notifier.startWorkout();
      final workoutId = wResult.valueOrNull!;

      final setResult = await notifier.logSet(
        workoutId,
        exId,
        SetInput(reps: 10, weightKg: 80.0),
      );
      expect(setResult, isA<Success<int>>());

      final sets = await dao.watchWorkoutSets(workoutId).first;
      expect(sets, hasLength(1));
      expect(sets.first.reps, 10);
      expect(sets.first.weightKg, 80.0);
    });

    test('logSet with bodyweight (null weight)', () async {
      final exId = await insertExercise(name: 'Fondos');
      final wResult = await notifier.startWorkout();
      final workoutId = wResult.valueOrNull!;

      final setResult = await notifier.logSet(
        workoutId,
        exId,
        SetInput(reps: 15),
      );
      expect(setResult, isA<Success<int>>());

      final sets = await dao.watchWorkoutSets(workoutId).first;
      expect(sets.first.weightKg, isNull);
    });

    test('logSet rejects 0 reps', () async {
      final exId = await insertExercise();
      final wResult = await notifier.startWorkout();
      final workoutId = wResult.valueOrNull!;

      final result = await notifier.logSet(
        workoutId,
        exId,
        SetInput(reps: 0, weightKg: 80.0),
      );
      expect(result, isA<Failure<int>>());
    });

    test('finishWorkout sets finishedAt and emits event', () async {
      final exId = await insertExercise();
      final wResult = await notifier.startWorkout();
      final workoutId = wResult.valueOrNull!;

      await notifier.logSet(workoutId, exId, SetInput(reps: 10, weightKg: 80.0));
      await notifier.logSet(workoutId, exId, SetInput(reps: 8, weightKg: 85.0));

      final events = <WorkoutCompletedEvent>[];
      eventBus.on<WorkoutCompletedEvent>().listen(events.add);

      final result = await notifier.finishWorkout(workoutId);
      expect(result, isA<Success<void>>());

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events, hasLength(1));
      expect(events.first.workoutId, workoutId);

      final active = await dao.getActiveWorkout();
      expect(active, isNull);
    });

    test('discardWorkout deletes workout and all sets', () async {
      final exId = await insertExercise();
      final wResult = await notifier.startWorkout();
      final workoutId = wResult.valueOrNull!;

      await notifier.logSet(workoutId, exId, SetInput(reps: 10, weightKg: 60.0));
      await notifier.discardWorkout(workoutId);

      final active = await dao.getActiveWorkout();
      expect(active, isNull);

      final sets = await dao.watchWorkoutSets(workoutId).first;
      expect(sets, isEmpty);
    });
  });

  group('GymNotifier — Routines', () {
    test('createRoutine with exercises', () async {
      final exId = await insertExercise();

      final result = await notifier.createRoutine(RoutineInput(
        name: 'Push Day',
        exercises: [
          RoutineExerciseInput(
            exerciseId: exId,
            defaultSets: 4,
            defaultReps: 10,
            restSeconds: 120,
          ),
        ],
      ));
      expect(result, isA<Success<int>>());

      final routines = await dao.watchRoutines().first;
      expect(routines, hasLength(1));
      expect(routines.first.name, 'Push Day');
    });

    test('createRoutine fails with empty exercises', () async {
      final result = await notifier.createRoutine(RoutineInput(
        name: 'Empty',
        exercises: [],
      ));
      expect(result, isA<Failure<int>>());
    });

    test('createRoutine fails with empty name', () async {
      final exId = await insertExercise();
      final result = await notifier.createRoutine(RoutineInput(
        name: '',
        exercises: [RoutineExerciseInput(exerciseId: exId)],
      ));
      expect(result, isA<Failure<int>>());
    });
  });

  group('GymNotifier — Custom Exercise', () {
    test('addCustomExercise succeeds', () async {
      final result = await notifier.addCustomExercise(
        name: 'Sentadilla Bulgara',
        primaryMuscle: 'Cuadriceps',
        equipment: 'Mancuernas',
      );
      expect(result, isA<Success<int>>());

      final exercises = await dao.watchExercises(query: 'Bulgara').first;
      expect(exercises, hasLength(1));
      expect(exercises.first.isCustom, isTrue);
    });

    test('addCustomExercise fails on duplicate name', () async {
      await insertExercise(name: 'Existing');
      final result = await notifier.addCustomExercise(
        name: 'Existing',
        primaryMuscle: 'Pecho',
      );
      expect(result, isA<Failure<int>>());
    });
  });
}
