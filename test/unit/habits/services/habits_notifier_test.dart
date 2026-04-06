import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/habits/database/habits_dao.dart';
import 'package:life_os/features/habits/domain/habits_input.dart';
import 'package:life_os/features/habits/providers/habits_notifier.dart';

void main() {
  late AppDatabase db;
  late HabitsDao dao;
  late EventBus eventBus;
  late HabitsNotifier notifier;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.habitsDao;
    eventBus = EventBus();
    notifier = HabitsNotifier(dao: dao, eventBus: eventBus);
  });

  tearDown(() async {
    eventBus.dispose();
    await db.close();
  });

  group('HabitsNotifier — addHabit', () {
    test('creates habit', () async {
      final result = await notifier.addHabit(const HabitInput(
        name: 'Meditar',
        frequencyType: 'daily',
      ));
      expect(result, isA<Success<int>>());

      final habits = await dao.watchActiveHabits().first;
      expect(habits, hasLength(1));
      expect(habits.first.name, 'Meditar');
    });

    test('rejects empty name', () async {
      final result = await notifier.addHabit(const HabitInput(
        name: '',
        frequencyType: 'daily',
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects invalid frequency', () async {
      final result = await notifier.addHabit(const HabitInput(
        name: 'Test',
        frequencyType: 'biweekly',
      ));
      expect(result, isA<Failure<int>>());
    });

    test('creates habit with linked event', () async {
      final result = await notifier.addHabit(const HabitInput(
        name: 'Ir al gym',
        frequencyType: 'weekly',
        weeklyTarget: 4,
        linkedEvent: 'WorkoutCompletedEvent',
      ));
      expect(result, isA<Success<int>>());
    });
  });

  group('HabitsNotifier — checkIn', () {
    test('checks in and emits event', () async {
      final addResult = await notifier.addHabit(const HabitInput(
        name: 'Meditar',
        frequencyType: 'daily',
      ));
      final habitId = addResult.valueOrNull!;

      final events = <HabitCheckedInEvent>[];
      eventBus.on<HabitCheckedInEvent>().listen(events.add);

      final result = await notifier.checkIn(habitId);
      expect(result, isA<Success<void>>());

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events, hasLength(1));
      expect(events.first.habitId, habitId);
      expect(events.first.isCompleted, isTrue);
    });

    test('rejects duplicate check-in same day', () async {
      final addResult = await notifier.addHabit(const HabitInput(
        name: 'Meditar',
        frequencyType: 'daily',
      ));
      final habitId = addResult.valueOrNull!;

      await notifier.checkIn(habitId);
      final result = await notifier.checkIn(habitId);
      expect(result, isA<Failure<void>>());
    });

    test('quantitative check-in with value >= target is completed', () async {
      final addResult = await notifier.addHabit(const HabitInput(
        name: 'Leer',
        frequencyType: 'daily',
        isQuantitative: true,
        quantitativeTarget: 30,
        quantitativeUnit: 'paginas',
      ));
      final habitId = addResult.valueOrNull!;

      final events = <HabitCheckedInEvent>[];
      eventBus.on<HabitCheckedInEvent>().listen(events.add);

      await notifier.checkIn(habitId, value: 35);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events.first.isCompleted, isTrue);
    });

    test('quantitative check-in below target is not completed', () async {
      final addResult = await notifier.addHabit(const HabitInput(
        name: 'Caminar',
        frequencyType: 'daily',
        isQuantitative: true,
        quantitativeTarget: 10000,
        quantitativeUnit: 'pasos',
      ));
      final habitId = addResult.valueOrNull!;

      final events = <HabitCheckedInEvent>[];
      eventBus.on<HabitCheckedInEvent>().listen(events.add);

      await notifier.checkIn(habitId, value: 6000);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events.first.isCompleted, isFalse);
    });

    test('rejects zero quantitative value', () async {
      final addResult = await notifier.addHabit(const HabitInput(
        name: 'Leer',
        frequencyType: 'daily',
        isQuantitative: true,
        quantitativeTarget: 30,
      ));
      final result = await notifier.checkIn(addResult.valueOrNull!, value: 0);
      expect(result, isA<Failure<void>>());
    });
  });

  group('HabitsNotifier — uncheckIn', () {
    test('removes check-in', () async {
      final addResult = await notifier.addHabit(const HabitInput(
        name: 'Test',
        frequencyType: 'daily',
      ));
      final habitId = addResult.valueOrNull!;
      await notifier.checkIn(habitId);

      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);
      await notifier.uncheckIn(habitId, date);

      final log = await dao.getLogForDate(habitId, date);
      expect(log, isNull);
    });
  });

  group('HabitsNotifier — archive/restore', () {
    test('archive hides habit', () async {
      final addResult = await notifier.addHabit(const HabitInput(
        name: 'Archive me',
        frequencyType: 'daily',
      ));
      await notifier.archiveHabit(addResult.valueOrNull!);

      final active = await dao.watchActiveHabits().first;
      expect(active, isEmpty);

      final archived = await dao.watchArchivedHabits().first;
      expect(archived, hasLength(1));
    });

    test('restore brings habit back', () async {
      final addResult = await notifier.addHabit(const HabitInput(
        name: 'Restore me',
        frequencyType: 'daily',
      ));
      final id = addResult.valueOrNull!;
      await notifier.archiveHabit(id);
      await notifier.restoreHabit(id);

      final active = await dao.watchActiveHabits().first;
      expect(active, hasLength(1));
    });
  });

  group('HabitsNotifier — auto-check from WorkoutCompletedEvent', () {
    test('auto-checks linked habits on workout event', () async {
      await notifier.addHabit(const HabitInput(
        name: 'Ir al gym',
        frequencyType: 'weekly',
        weeklyTarget: 4,
        linkedEvent: 'WorkoutCompletedEvent',
      ));

      await notifier.onWorkoutCompleted(WorkoutCompletedEvent(
        workoutId: 1,
        duration: const Duration(minutes: 45),
        totalVolume: 5000,
      ));

      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);
      final habits = await dao.watchActiveHabits().first;
      final log = await dao.getLogForDate(habits.first.id, date);
      expect(log, isNotNull);
    });

    test('does not auto-check non-linked habits', () async {
      await notifier.addHabit(const HabitInput(
        name: 'Meditar',
        frequencyType: 'daily',
      ));

      await notifier.onWorkoutCompleted(WorkoutCompletedEvent(
        workoutId: 1,
        duration: const Duration(minutes: 30),
        totalVolume: 3000,
      ));

      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);
      final habits = await dao.watchActiveHabits().first;
      final log = await dao.getLogForDate(habits.first.id, date);
      expect(log, isNull);
    });
  });
}
