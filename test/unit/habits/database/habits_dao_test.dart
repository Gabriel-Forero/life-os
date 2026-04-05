import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/habits/database/habits_dao.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late HabitsDao dao;

  setUp(() async {
    db = _createInMemoryDb();
    dao = db.habitsDao;
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> _insertHabit({
    String name = 'Meditar',
    String frequencyType = 'daily',
  }) async {
    return dao.insertHabit(HabitsCompanion.insert(
      name: name,
      icon: const Value('self_improvement'),
      color: const Value(0xFF8B5CF6),
      frequencyType: frequencyType,
      isQuantitative: const Value(false),
      isArchived: const Value(false),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  group('HabitsDao — Habits CRUD', () {
    test('insertHabit returns id', () async {
      final id = await _insertHabit();
      expect(id, greaterThan(0));
    });

    test('watchActiveHabits returns non-archived', () async {
      await _insertHabit(name: 'Active');
      final archivedId = await _insertHabit(name: 'Archived');
      await dao.archiveHabit(archivedId);

      final habits = await dao.watchActiveHabits().first;
      expect(habits, hasLength(1));
      expect(habits.first.name, 'Active');
    });

    test('watchArchivedHabits returns only archived', () async {
      await _insertHabit(name: 'Active');
      final archivedId = await _insertHabit(name: 'Archived');
      await dao.archiveHabit(archivedId);

      final archived = await dao.watchArchivedHabits().first;
      expect(archived, hasLength(1));
      expect(archived.first.name, 'Archived');
    });

    test('restoreHabit unarchives', () async {
      final id = await _insertHabit();
      await dao.archiveHabit(id);
      await dao.restoreHabit(id);

      final habits = await dao.watchActiveHabits().first;
      expect(habits, hasLength(1));
    });
  });

  group('HabitsDao — Habit Logs', () {
    test('insertHabitLog and getLogForDate', () async {
      final habitId = await _insertHabit();
      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);

      await dao.insertHabitLog(HabitLogsCompanion.insert(
        habitId: habitId,
        date: date,
        completedAt: today,
        createdAt: today,
      ));

      final log = await dao.getLogForDate(habitId, date);
      expect(log, isNotNull);
      expect(log!.habitId, habitId);
    });

    test('deleteHabitLog removes check-in', () async {
      final habitId = await _insertHabit();
      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);

      await dao.insertHabitLog(HabitLogsCompanion.insert(
        habitId: habitId,
        date: date,
        completedAt: today,
        createdAt: today,
      ));
      await dao.deleteHabitLog(habitId, date);

      final log = await dao.getLogForDate(habitId, date);
      expect(log, isNull);
    });

    test('watchHabitLogs returns logs in range', () async {
      final habitId = await _insertHabit();
      final now = DateTime.now();

      // Log for today
      await dao.insertHabitLog(HabitLogsCompanion.insert(
        habitId: habitId,
        date: DateTime(now.year, now.month, now.day),
        completedAt: now,
        createdAt: now,
      ));

      final from = DateTime(now.year, now.month, 1);
      final to = DateTime(now.year, now.month + 1, 0);
      final logs = await dao.watchHabitLogs(habitId, from, to).first;
      expect(logs, hasLength(1));
    });

    test('quantitative log stores value', () async {
      final habitId = await dao.insertHabit(HabitsCompanion.insert(
        name: 'Leer',
        icon: const Value('book'),
        color: const Value(0xFF3B82F6),
        frequencyType: 'daily',
        isQuantitative: const Value(true),
        quantitativeTarget: const Value(30.0),
        quantitativeUnit: const Value('paginas'),
        isArchived: const Value(false),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);

      await dao.insertHabitLog(HabitLogsCompanion.insert(
        habitId: habitId,
        date: date,
        completedAt: today,
        value: const Value(35.0),
        createdAt: today,
      ));

      final log = await dao.getLogForDate(habitId, date);
      expect(log!.value, 35.0);
    });
  });

  group('HabitsDao — Streaks', () {
    test('streakCount for daily habit', () async {
      final habitId = await _insertHabit();
      final today = DateTime.now();

      // Log 5 consecutive days
      for (var i = 4; i >= 0; i--) {
        final date = DateTime(today.year, today.month, today.day)
            .subtract(Duration(days: i));
        await dao.insertHabitLog(HabitLogsCompanion.insert(
          habitId: habitId,
          date: date,
          completedAt: date,
          createdAt: date,
        ));
      }

      final streak = await dao.streakCount(habitId, today);
      expect(streak, 5);
    });

    test('streakCount resets on missed day', () async {
      final habitId = await _insertHabit();
      final today = DateTime.now();

      // Log day 3, 2 ago (skip day 1 ago = missed yesterday)
      for (final daysAgo in [3, 2, 0]) {
        final date = DateTime(today.year, today.month, today.day)
            .subtract(Duration(days: daysAgo));
        await dao.insertHabitLog(HabitLogsCompanion.insert(
          habitId: habitId,
          date: date,
          completedAt: date,
          createdAt: date,
        ));
      }

      final streak = await dao.streakCount(habitId, today);
      expect(streak, 1); // Only today
    });

    test('completionRate calculates correctly', () async {
      final habitId = await _insertHabit();
      final today = DateTime.now();

      // Log 3 of last 10 days
      for (final daysAgo in [0, 2, 5]) {
        final date = DateTime(today.year, today.month, today.day)
            .subtract(Duration(days: daysAgo));
        await dao.insertHabitLog(HabitLogsCompanion.insert(
          habitId: habitId,
          date: date,
          completedAt: date,
          createdAt: date,
        ));
      }

      final from = DateTime(today.year, today.month, today.day)
          .subtract(const Duration(days: 9));
      final to = DateTime(today.year, today.month, today.day);
      final rate = await dao.completionRate(habitId, from, to);
      expect(rate, closeTo(0.3, 0.01)); // 3/10
    });
  });
}
