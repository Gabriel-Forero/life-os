import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/sleep/database/sleep_dao.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late SleepDao dao;

  setUp(() async {
    db = _createInMemoryDb();
    dao = db.sleepDao;
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<int> insertLog({
    DateTime? date,
    DateTime? bedTime,
    DateTime? wakeTime,
    int qualityRating = 4,
    int sleepScore = 80,
  }) async {
    final now = DateTime.now();
    final bed = bedTime ?? DateTime(2024, 1, 15, 22, 0);
    final wake = wakeTime ?? DateTime(2024, 1, 16, 6, 0);
    return dao.insertSleepLog(SleepLogsCompanion.insert(
      date: date ?? DateTime(2024, 1, 16),
      bedTime: bed,
      wakeTime: wake,
      qualityRating: qualityRating,
      sleepScore: sleepScore,
      createdAt: now,
    ));
  }

  // ---------------------------------------------------------------------------
  // SleepLogs CRUD
  // ---------------------------------------------------------------------------

  group('SleepDao — SleepLogs CRUD', () {
    test('insertSleepLog returns id > 0', () async {
      final id = await insertLog();
      expect(id, greaterThan(0));
    });

    test('getSleepLogById returns inserted log', () async {
      final id = await insertLog(qualityRating: 3, sleepScore: 65);
      final log = await dao.getSleepLogById(id);
      expect(log, isNotNull);
      expect(log!.qualityRating, 3);
      expect(log.sleepScore, 65);
    });

    test('getSleepLogById returns null for unknown id', () async {
      final log = await dao.getSleepLogById(9999);
      expect(log, isNull);
    });

    test('watchSleepLogs returns logs within date range', () async {
      await insertLog(date: DateTime(2024, 1, 10));
      await insertLog(date: DateTime(2024, 1, 15));
      await insertLog(date: DateTime(2024, 1, 20));

      final logs = await dao
          .watchSleepLogs(DateTime(2024, 1, 12), DateTime(2024, 1, 18))
          .first;
      expect(logs, hasLength(1));
      expect(logs.first.date.day, 15);
    });

    test('watchSleepLogs returns in descending date order', () async {
      await insertLog(date: DateTime(2024, 1, 10));
      await insertLog(date: DateTime(2024, 1, 15));
      await insertLog(date: DateTime(2024, 1, 12));

      final logs = await dao
          .watchSleepLogs(DateTime(2024, 1, 1), DateTime(2024, 1, 31))
          .first;
      expect(logs.map((l) => l.date.day).toList(), [15, 12, 10]);
    });

    test('getSleepLogForDate returns log for given date', () async {
      await insertLog(date: DateTime(2024, 1, 15));
      final log = await dao.getSleepLogForDate(DateTime(2024, 1, 15));
      expect(log, isNotNull);
    });

    test('getSleepLogForDate returns null for missing date', () async {
      final log = await dao.getSleepLogForDate(DateTime(2024, 1, 15));
      expect(log, isNull);
    });

    test('deleteSleepLog removes record', () async {
      final id = await insertLog();
      await dao.deleteSleepLog(id);
      final log = await dao.getSleepLogById(id);
      expect(log, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // SleepInterruptions
  // ---------------------------------------------------------------------------

  group('SleepDao — SleepInterruptions', () {
    late int logId;

    setUp(() async {
      logId = await insertLog();
    });

    Future<int> insertInterruption({int minutes = 10}) =>
        dao.insertInterruption(SleepInterruptionsCompanion.insert(
          sleepLogId: logId,
          time: DateTime(2024, 1, 16, 2, 0),
          durationMinutes: minutes,
          createdAt: DateTime.now(),
        ));

    test('insertInterruption returns id > 0', () async {
      final id = await insertInterruption();
      expect(id, greaterThan(0));
    });

    test('getInterruptionsForLog returns all interruptions for log', () async {
      await insertInterruption(minutes: 5);
      await insertInterruption(minutes: 10);
      final interruptions = await dao.getInterruptionsForLog(logId);
      expect(interruptions, hasLength(2));
    });

    test('getInterruptionsForLog returns empty for unknown logId', () async {
      final interruptions = await dao.getInterruptionsForLog(9999);
      expect(interruptions, isEmpty);
    });

    test('deleteInterruption removes record', () async {
      final id = await insertInterruption();
      await dao.deleteInterruption(id);
      final interruptions = await dao.getInterruptionsForLog(logId);
      expect(interruptions, isEmpty);
    });

    test('watchInterruptionsForLog emits updates', () async {
      final stream = dao.watchInterruptionsForLog(logId);
      await insertInterruption();
      final interruptions = await stream.first;
      expect(interruptions, hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // EnergyLogs
  // ---------------------------------------------------------------------------

  group('SleepDao — EnergyLogs', () {
    final testDate = DateTime(2024, 1, 15);

    Future<int> insertEnergy({
      String timeOfDay = 'morning',
      int level = 7,
    }) =>
        dao.insertEnergyLog(EnergyLogsCompanion.insert(
          date: testDate,
          timeOfDay: timeOfDay,
          level: level,
          createdAt: DateTime.now(),
        ));

    test('insertEnergyLog returns id > 0', () async {
      final id = await insertEnergy();
      expect(id, greaterThan(0));
    });

    test('watchEnergyLogsForDate returns all logs for date', () async {
      await insertEnergy(timeOfDay: 'morning', level: 7);
      await insertEnergy(timeOfDay: 'afternoon', level: 5);
      await insertEnergy(timeOfDay: 'evening', level: 6);

      final logs = await dao.watchEnergyLogsForDate(testDate).first;
      expect(logs, hasLength(3));
    });

    test('insertEnergyLog with replace mode updates existing record', () async {
      await insertEnergy(timeOfDay: 'morning', level: 5);
      await insertEnergy(timeOfDay: 'morning', level: 8); // should replace

      final logs = await dao.watchEnergyLogsForDate(testDate).first;
      expect(logs.where((l) => l.timeOfDay == 'morning'), hasLength(1));
      expect(
        logs.firstWhere((l) => l.timeOfDay == 'morning').level,
        8,
      );
    });

    test('getEnergyLogForTimeOfDay returns correct log', () async {
      await insertEnergy(timeOfDay: 'afternoon', level: 6);
      final log = await dao.getEnergyLogForTimeOfDay(testDate, 'afternoon');
      expect(log, isNotNull);
      expect(log!.level, 6);
    });

    test('watchEnergyLogs returns logs in date range', () async {
      await insertEnergy();
      await dao.insertEnergyLog(EnergyLogsCompanion.insert(
        date: DateTime(2024, 1, 20),
        timeOfDay: 'morning',
        level: 9,
        createdAt: DateTime.now(),
      ));

      final logs = await dao
          .watchEnergyLogs(DateTime(2024, 1, 14), DateTime(2024, 1, 16))
          .first;
      expect(logs, hasLength(1));
    });
  });
}
