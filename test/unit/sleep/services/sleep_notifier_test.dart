import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/sleep/database/sleep_dao.dart';
import 'package:life_os/features/sleep/domain/sleep_input.dart';
import 'package:life_os/features/sleep/domain/sleep_validators.dart';
import 'package:life_os/features/sleep/providers/sleep_notifier.dart';

void main() {
  late AppDatabase db;
  late SleepDao dao;
  late EventBus eventBus;
  late SleepNotifier notifier;

  final bedTime = DateTime(2024, 1, 15, 22, 0);
  final wakeTime = DateTime(2024, 1, 16, 6, 0); // 8h

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.sleepDao;
    eventBus = EventBus();
    notifier = SleepNotifier(dao: dao, eventBus: eventBus);
  });

  tearDown(() async {
    eventBus.dispose();
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // calculateSleepScore unit tests
  // ---------------------------------------------------------------------------

  group('calculateSleepScore', () {
    test('perfect sleep returns 100', () {
      final score = calculateSleepScore(
        hoursSlept: 8,
        qualityRating: 5,
        interruptionCount: 0,
      );
      expect(score, 100);
    });

    test('zero interruptions does not penalize', () {
      final score = calculateSleepScore(
        hoursSlept: 8,
        qualityRating: 5,
        interruptionCount: 0,
      );
      // 100*0.4 + 100*0.4 + 100*0.2 = 100
      expect(score, 100);
    });

    test('each interruption costs 15 points in interruption component', () {
      final score = calculateSleepScore(
        hoursSlept: 8,
        qualityRating: 5,
        interruptionCount: 3,
      );
      // duration=100, quality=100, interruption=max(0,100-45)=55
      // 40 + 40 + 11 = 91
      expect(score, 91);
    });

    test('interruption score floored at 0', () {
      final score = calculateSleepScore(
        hoursSlept: 8,
        qualityRating: 5,
        interruptionCount: 10, // 10*15=150 → clamped to 0
      );
      // 40 + 40 + 0 = 80
      expect(score, 80);
    });

    test('short sleep reduces duration score', () {
      final score = calculateSleepScore(
        hoursSlept: 4,
        qualityRating: 5,
        interruptionCount: 0,
      );
      // duration=50, quality=100, interruption=100
      // 20 + 40 + 20 = 80
      expect(score, 80);
    });

    test('over 8h duration capped at 100', () {
      final score = calculateSleepScore(
        hoursSlept: 10,
        qualityRating: 5,
        interruptionCount: 0,
      );
      expect(score, 100);
    });

    test('minimum quality rating lowers score', () {
      final score = calculateSleepScore(
        hoursSlept: 8,
        qualityRating: 1,
        interruptionCount: 0,
      );
      // duration=100, quality=20, interruption=100
      // 40 + 8 + 20 = 68
      expect(score, 68);
    });
  });

  // ---------------------------------------------------------------------------
  // SleepNotifier — logSleep
  // ---------------------------------------------------------------------------

  group('SleepNotifier — logSleep', () {
    test('creates sleep log and returns id', () async {
      final result = await notifier.logSleep(SleepInput(
        date: DateTime(2024, 1, 16),
        bedTime: bedTime,
        wakeTime: wakeTime,
        qualityRating: 4,
      ));
      expect(result, isA<Success<int>>());
      expect(result.valueOrNull, greaterThan(0));
    });

    test('emits SleepLogSavedEvent on success', () async {
      final events = <SleepLogSavedEvent>[];
      eventBus.on<SleepLogSavedEvent>().listen(events.add);

      await notifier.logSleep(SleepInput(
        date: DateTime(2024, 1, 16),
        bedTime: bedTime,
        wakeTime: wakeTime,
        qualityRating: 5,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events, hasLength(1));
      expect(events.first.hoursSlept, closeTo(8.0, 0.01));
      expect(events.first.sleepScore, equals(100));
    });

    test('rejects wakeTime before bedTime', () async {
      final result = await notifier.logSleep(SleepInput(
        date: DateTime(2024, 1, 16),
        bedTime: wakeTime,
        wakeTime: bedTime, // reversed
        qualityRating: 4,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects sleep duration under 30 minutes', () async {
      final result = await notifier.logSleep(SleepInput(
        date: DateTime(2024, 1, 16),
        bedTime: bedTime,
        wakeTime: bedTime.add(const Duration(minutes: 20)),
        qualityRating: 4,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects quality rating < 1', () async {
      final result = await notifier.logSleep(SleepInput(
        date: DateTime(2024, 1, 16),
        bedTime: bedTime,
        wakeTime: wakeTime,
        qualityRating: 0,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects quality rating > 5', () async {
      final result = await notifier.logSleep(SleepInput(
        date: DateTime(2024, 1, 16),
        bedTime: bedTime,
        wakeTime: wakeTime,
        qualityRating: 6,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects note exceeding 200 chars', () async {
      final result = await notifier.logSleep(SleepInput(
        date: DateTime(2024, 1, 16),
        bedTime: bedTime,
        wakeTime: wakeTime,
        qualityRating: 4,
        note: 'x' * 201,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('accepts note exactly 200 chars', () async {
      final result = await notifier.logSleep(SleepInput(
        date: DateTime(2024, 1, 16),
        bedTime: bedTime,
        wakeTime: wakeTime,
        qualityRating: 4,
        note: 'x' * 200,
      ));
      expect(result, isA<Success<int>>());
    });
  });

  // ---------------------------------------------------------------------------
  // SleepNotifier — addInterruption
  // ---------------------------------------------------------------------------

  group('SleepNotifier — addInterruption', () {
    late int logId;

    setUp(() async {
      final r = await notifier.logSleep(SleepInput(
        date: DateTime(2024, 1, 16),
        bedTime: bedTime,
        wakeTime: wakeTime,
        qualityRating: 4,
      ));
      logId = r.valueOrNull!;
    });

    test('adds interruption successfully', () async {
      final result = await notifier.addInterruption(SleepInterruptionInput(
        sleepLogId: logId,
        time: DateTime(2024, 1, 16, 2, 0),
        durationMinutes: 15,
      ));
      expect(result, isA<Success<int>>());
    });

    test('rejects zero durationMinutes', () async {
      final result = await notifier.addInterruption(SleepInterruptionInput(
        sleepLogId: logId,
        time: DateTime(2024, 1, 16, 2, 0),
        durationMinutes: 0,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects negative durationMinutes', () async {
      final result = await notifier.addInterruption(SleepInterruptionInput(
        sleepLogId: logId,
        time: DateTime(2024, 1, 16, 2, 0),
        durationMinutes: -5,
      ));
      expect(result, isA<Failure<int>>());
    });
  });

  // ---------------------------------------------------------------------------
  // SleepNotifier — logEnergy
  // ---------------------------------------------------------------------------

  group('SleepNotifier — logEnergy', () {
    test('logs morning energy successfully', () async {
      final result = await notifier.logEnergy(EnergyInput(
        date: DateTime(2024, 1, 16),
        timeOfDay: 'morning',
        level: 8,
      ));
      expect(result, isA<Success<int>>());
    });

    test('logs all three time-of-day slots', () async {
      for (final tod in ['morning', 'afternoon', 'evening']) {
        final r = await notifier.logEnergy(EnergyInput(
          date: DateTime(2024, 1, 16),
          timeOfDay: tod,
          level: 7,
        ));
        expect(r, isA<Success<int>>(), reason: 'Failed for $tod');
      }
    });

    test('rejects invalid timeOfDay', () async {
      final result = await notifier.logEnergy(EnergyInput(
        date: DateTime(2024, 1, 16),
        timeOfDay: 'midnight',
        level: 7,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects level 0', () async {
      final result = await notifier.logEnergy(EnergyInput(
        date: DateTime(2024, 1, 16),
        timeOfDay: 'morning',
        level: 0,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects level > 10', () async {
      final result = await notifier.logEnergy(EnergyInput(
        date: DateTime(2024, 1, 16),
        timeOfDay: 'morning',
        level: 11,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('accepts level 1', () async {
      final result = await notifier.logEnergy(EnergyInput(
        date: DateTime(2024, 1, 16),
        timeOfDay: 'morning',
        level: 1,
      ));
      expect(result, isA<Success<int>>());
    });

    test('accepts level 10', () async {
      final result = await notifier.logEnergy(EnergyInput(
        date: DateTime(2024, 1, 16),
        timeOfDay: 'evening',
        level: 10,
      ));
      expect(result, isA<Success<int>>());
    });
  });
}
