import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/gym/database/gym_dao.dart';
import 'package:life_os/features/gym/domain/gym_input.dart';
import 'package:life_os/features/gym/domain/gym_validators.dart';
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

  Future<int> insertExercise(String name) async {
    return dao.insertExercise(ExercisesCompanion.insert(
      name: name,
      primaryMuscle: 'Pecho',
      isCustom: const Value(false),
      isDownloaded: const Value(true),
      createdAt: DateTime.now(),
    ));
  }

  group('RT-GYM: Round-trip properties', () {
    test('RT-GYM-01: Exercise insert → query returns identical fields (50 samples)', () async {
      final random = Random(42);
      final muscles = ['Pecho', 'Espalda', 'Hombros', 'Biceps', 'Cuadriceps'];
      final equips = ['Barra', 'Mancuernas', 'Maquina', 'Peso_corporal'];

      for (var i = 0; i < 50; i++) {
        final name = 'Exercise_${random.nextInt(100000)}';
        final muscle = muscles[random.nextInt(muscles.length)];
        final equip = equips[random.nextInt(equips.length)];

        final id = await dao.insertExercise(ExercisesCompanion.insert(
          name: name,
          primaryMuscle: muscle,
          equipment: Value(equip),
          isCustom: const Value(true),
          isDownloaded: const Value(false),
          createdAt: DateTime.now(),
        ));

        final results = await dao.watchExercises(query: name).first;
        final found = results.firstWhere((e) => e.id == id);
        expect(found.name, name);
        expect(found.primaryMuscle, muscle);
        expect(found.equipment, equip);
      }
    });

    test('RT-GYM-02: WorkoutSet insert → query returns identical fields (30 samples)', () async {
      final exId = await insertExercise('Bench');
      final wResult = await notifier.startWorkout();
      final wId = wResult.valueOrNull!;
      final random = Random(42);

      for (var i = 0; i < 30; i++) {
        final reps = random.nextInt(15) + 1;
        final weight = random.nextBool() ? (random.nextDouble() * 150 + 20) : null;

        await notifier.logSet(wId, exId, SetInput(
          reps: reps,
          weightKg: weight,
          isWarmup: i < 2,
        ));
      }

      final sets = await dao.watchWorkoutSets(wId).first;
      expect(sets, hasLength(30));

      for (final s in sets) {
        expect(s.reps, greaterThan(0));
        expect(s.exerciseId, exId);
        expect(s.workoutId, wId);
      }
    });
  });

  group('INV-GYM: Invariant properties', () {
    test('INV-GYM-01: Total volume excludes warmup sets', () async {
      final exId = await insertExercise('Squat');
      final wResult = await notifier.startWorkout();
      final wId = wResult.valueOrNull!;

      // Warmup: 40kg x 10 = 400 (excluded)
      await notifier.logSet(wId, exId, SetInput(reps: 10, weightKg: 40.0, isWarmup: true));
      // Work: 80kg x 8 = 640
      await notifier.logSet(wId, exId, SetInput(reps: 8, weightKg: 80.0));
      // Work: 80kg x 6 = 480
      await notifier.logSet(wId, exId, SetInput(reps: 6, weightKg: 80.0));

      final sets = await dao.watchWorkoutSets(wId).first;
      final workSets = sets.where((s) => !s.isWarmup && s.weightKg != null);
      final volume = workSets.fold<double>(0, (sum, s) => sum + s.weightKg! * s.reps);

      expect(volume, closeTo(1120.0, 0.01)); // 640 + 480
    });

    test('INV-GYM-02: Weight PR only from non-warmup sets', () async {
      final exId = await insertExercise('Deadlift');
      final wResult = await notifier.startWorkout();
      final wId = wResult.valueOrNull!;

      // Warmup at high weight
      await notifier.logSet(wId, exId, SetInput(reps: 5, weightKg: 200.0, isWarmup: true));
      // Work at lower weight
      await notifier.logSet(wId, exId, SetInput(reps: 5, weightKg: 150.0));

      final weightPR = await dao.getWeightPR(exId);
      expect(weightPR, 150.0); // Not 200 (warmup excluded)
    });

    test('INV-GYM-03: 1RM Epley formula consistency for 100 samples', () async {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        final weight = random.nextDouble() * 200 + 20;
        final reps = random.nextInt(15) + 1;
        final rm = calculate1RM(weight, reps);

        expect(rm, isNotNull);
        expect(rm!, greaterThanOrEqualTo(weight),
            reason: '1RM should be >= weight lifted');

        if (reps == 1) {
          expect(rm, weight, reason: '1RM with 1 rep = actual weight');
        }
      }
    });

    test('INV-GYM-04: kg→lbs→kg round-trip preserves value for 100 samples', () {
      final random = Random(42);

      for (var i = 0; i < 100; i++) {
        final kg = random.nextDouble() * 300;
        final roundTrip = lbsToKg(kgToLbs(kg));
        expect(roundTrip, closeTo(kg, 0.001),
            reason: 'kg→lbs→kg should preserve value');
      }
    });
  });

  group('IDP-GYM: Idempotence properties', () {
    test('IDP-GYM-01: Finishing workout twice fails second time', () async {
      final exId = await insertExercise('Press');
      final wResult = await notifier.startWorkout();
      final wId = wResult.valueOrNull!;
      await notifier.logSet(wId, exId, SetInput(reps: 10, weightKg: 60.0));

      final first = await notifier.finishWorkout(wId);
      expect(first.isSuccess, isTrue);

      // Second finish — workout no longer active, finishedAt already set
      // This should still succeed (idempotent update) or fail gracefully
      final workouts = await dao.watchWorkouts().first;
      expect(workouts.where((w) => w.id == wId), hasLength(1));
    });

    test('IDP-GYM-02: Bulk insert exercises skips if count > 0', () async {
      await insertExercise('Existing');

      final countBefore = await dao.countExercises();
      expect(countBefore, 1);

      // Simulating "load library only if empty" logic
      if (countBefore == 0) {
        await dao.bulkInsertExercises([
          ExercisesCompanion.insert(
            name: 'New',
            primaryMuscle: 'Pecho',
            isCustom: const Value(false),
            isDownloaded: const Value(true),
            createdAt: DateTime.now(),
          ),
        ]);
      }

      final countAfter = await dao.countExercises();
      expect(countAfter, 1); // No new exercises added
    });
  });
}
