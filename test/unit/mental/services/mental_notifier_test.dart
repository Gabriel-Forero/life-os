import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/mental/database/mental_dao.dart';
import 'package:life_os/features/mental/domain/mental_input.dart';
import 'package:life_os/features/mental/domain/mental_validators.dart';
import 'package:life_os/features/mental/providers/mental_notifier.dart';

void main() {
  late AppDatabase db;
  late MentalDao dao;
  late EventBus eventBus;
  late MentalNotifier notifier;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.mentalDao;
    eventBus = EventBus();
    notifier = MentalNotifier(dao: dao, eventBus: eventBus);
  });

  tearDown(() async {
    eventBus.dispose();
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // calculateMoodScore unit tests
  // ---------------------------------------------------------------------------

  group('calculateMoodScore', () {
    test('maximum valence and energy returns 100', () {
      expect(calculateMoodScore(valence: 5, energy: 5), 100);
    });

    test('minimum valence and energy returns 0', () {
      expect(calculateMoodScore(valence: 1, energy: 1), 0);
    });

    test('mid-range returns 50', () {
      expect(calculateMoodScore(valence: 3, energy: 3), 50);
    });

    test('high valence low energy returns ~50', () {
      // valence=5→50, energy=1→0 → total=50
      expect(calculateMoodScore(valence: 5, energy: 1), 50);
    });

    test('low valence high energy returns ~50', () {
      // valence=1→0, energy=5→50 → total=50
      expect(calculateMoodScore(valence: 1, energy: 5), 50);
    });

    test('score is always between 0 and 100', () {
      for (var v = 1; v <= 5; v++) {
        for (var e = 1; e <= 5; e++) {
          final score = calculateMoodScore(valence: v, energy: e);
          expect(score, inInclusiveRange(0, 100));
        }
      }
    });
  });

  // ---------------------------------------------------------------------------
  // MentalNotifier — logMood
  // ---------------------------------------------------------------------------

  group('MentalNotifier — logMood', () {
    test('creates mood log and returns id', () async {
      final result = await notifier.logMood(MoodInput(
        date: DateTime.now(),
        valence: 4,
        energy: 3,
        tags: ['trabajo'],
      ));
      expect(result, isA<Success<int>>());
      expect(result.valueOrNull, greaterThan(0));
    });

    test('emits MoodLoggedEvent on success', () async {
      final events = <MoodLoggedEvent>[];
      eventBus.on<MoodLoggedEvent>().listen(events.add);

      await notifier.logMood(MoodInput(
        date: DateTime.now(),
        valence: 5,
        energy: 5,
        tags: ['feliz', 'productivo'],
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events, hasLength(1));
      expect(events.first.level, 100);
      expect(events.first.tags, ['feliz', 'productivo']);
    });

    test('rejects valence < 1', () async {
      final result = await notifier.logMood(MoodInput(
        date: DateTime.now(),
        valence: 0,
        energy: 3,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects valence > 5', () async {
      final result = await notifier.logMood(MoodInput(
        date: DateTime.now(),
        valence: 6,
        energy: 3,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects energy < 1', () async {
      final result = await notifier.logMood(MoodInput(
        date: DateTime.now(),
        valence: 3,
        energy: 0,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects energy > 5', () async {
      final result = await notifier.logMood(MoodInput(
        date: DateTime.now(),
        valence: 3,
        energy: 6,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects journal note exceeding 280 chars', () async {
      final result = await notifier.logMood(MoodInput(
        date: DateTime.now(),
        valence: 3,
        energy: 3,
        journalNote: 'x' * 281,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('accepts journal note exactly 280 chars', () async {
      final result = await notifier.logMood(MoodInput(
        date: DateTime.now(),
        valence: 3,
        energy: 3,
        journalNote: 'x' * 280,
      ));
      expect(result, isA<Success<int>>());
    });

    test('rejects more than 10 tags', () async {
      final result = await notifier.logMood(MoodInput(
        date: DateTime.now(),
        valence: 3,
        energy: 3,
        tags: List.generate(11, (i) => 'tag$i'),
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects tag exceeding 30 chars', () async {
      final result = await notifier.logMood(MoodInput(
        date: DateTime.now(),
        valence: 3,
        energy: 3,
        tags: ['x' * 31],
      ));
      expect(result, isA<Failure<int>>());
    });

    test('stores tags as comma-separated string', () async {
      final id = await notifier.logMood(MoodInput(
        date: DateTime.now(),
        valence: 3,
        energy: 3,
        tags: ['trabajo', 'familia'],
      ));
      final log = await dao.getMoodLogById(id.valueOrNull!);
      expect(log!.tags, 'trabajo,familia');
    });

    test('no tags stores empty string', () async {
      final id = await notifier.logMood(MoodInput(
        date: DateTime.now(),
        valence: 3,
        energy: 3,
      ));
      final log = await dao.getMoodLogById(id.valueOrNull!);
      expect(log!.tags, '');
    });
  });

  // ---------------------------------------------------------------------------
  // MentalNotifier — startBreathingSession
  // ---------------------------------------------------------------------------

  group('MentalNotifier — startBreathingSession', () {
    test('saves box breathing session', () async {
      final result = await notifier.startBreathingSession(
        const BreathingSessionInput(
          techniqueName: 'box',
          durationSeconds: 240,
          isCompleted: true,
        ),
      );
      expect(result, isA<Success<int>>());
    });

    test('saves 4-7-8 session', () async {
      final result = await notifier.startBreathingSession(
        const BreathingSessionInput(
          techniqueName: '4_7_8',
          durationSeconds: 190,
          isCompleted: true,
        ),
      );
      expect(result, isA<Success<int>>());
    });

    test('saves coherent session', () async {
      final result = await notifier.startBreathingSession(
        const BreathingSessionInput(
          techniqueName: 'coherent',
          durationSeconds: 120,
          isCompleted: false,
        ),
      );
      expect(result, isA<Success<int>>());
    });

    test('rejects invalid technique name', () async {
      final result = await notifier.startBreathingSession(
        const BreathingSessionInput(
          techniqueName: 'wim_hof',
          durationSeconds: 120,
          isCompleted: true,
        ),
      );
      expect(result, isA<Failure<int>>());
    });

    test('rejects zero duration', () async {
      final result = await notifier.startBreathingSession(
        const BreathingSessionInput(
          techniqueName: 'box',
          durationSeconds: 0,
          isCompleted: false,
        ),
      );
      expect(result, isA<Failure<int>>());
    });

    test('rejects negative duration', () async {
      final result = await notifier.startBreathingSession(
        const BreathingSessionInput(
          techniqueName: 'box',
          durationSeconds: -10,
          isCompleted: false,
        ),
      );
      expect(result, isA<Failure<int>>());
    });
  });

  // ---------------------------------------------------------------------------
  // BreathingTechnique definitions
  // ---------------------------------------------------------------------------

  group('BreathingTechnique definitions', () {
    test('box technique has 16s cycle (4+4+4+4)', () {
      expect(breathingTechniques['box']!.cycleDuration, 16);
    });

    test('4_7_8 technique has 19s cycle (4+7+8+0)', () {
      expect(breathingTechniques['4_7_8']!.cycleDuration, 19);
    });

    test('coherent technique has 10s cycle (5+0+5+0)', () {
      expect(breathingTechniques['coherent']!.cycleDuration, 10);
    });

    test('all three techniques are defined', () {
      expect(breathingTechniques.containsKey('box'), isTrue);
      expect(breathingTechniques.containsKey('4_7_8'), isTrue);
      expect(breathingTechniques.containsKey('coherent'), isTrue);
    });
  });
}
