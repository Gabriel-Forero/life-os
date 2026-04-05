import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/mental/database/mental_dao.dart';
import 'package:life_os/features/mental/database/mental_tables.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late MentalDao dao;

  setUp(() async {
    db = _createInMemoryDb();
    dao = db.mentalDao;
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // MoodLogs
  // ---------------------------------------------------------------------------

  group('MentalDao — MoodLogs', () {
    Future<int> _insertMood({
      DateTime? date,
      int valence = 4,
      int energy = 3,
      String tags = 'trabajo',
      String? journalNote,
    }) =>
        dao.insertMoodLog(MoodLogsCompanion.insert(
          date: date ?? DateTime(2024, 1, 15, 9, 0),
          valence: valence,
          energy: energy,
          tags: Value(tags),
          journalNote: Value(journalNote),
          createdAt: DateTime.now(),
        ));

    test('insertMoodLog returns id > 0', () async {
      final id = await _insertMood();
      expect(id, greaterThan(0));
    });

    test('getMoodLogById returns inserted log', () async {
      final id = await _insertMood(valence: 5, energy: 5);
      final log = await dao.getMoodLogById(id);
      expect(log, isNotNull);
      expect(log!.valence, 5);
      expect(log.energy, 5);
    });

    test('getMoodLogById returns null for unknown id', () async {
      final log = await dao.getMoodLogById(9999);
      expect(log, isNull);
    });

    test('getMoodLogs returns logs in date range', () async {
      await _insertMood(date: DateTime(2024, 1, 10));
      await _insertMood(date: DateTime(2024, 1, 15));
      await _insertMood(date: DateTime(2024, 1, 20));

      final logs = await dao.getMoodLogs(
        DateTime(2024, 1, 12),
        DateTime(2024, 1, 18),
      );
      expect(logs, hasLength(1));
      expect(logs.first.date.day, 15);
    });

    test('watchMoodLogs stream emits on insert', () async {
      final stream = dao.watchMoodLogs(
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 31),
      );

      await _insertMood();
      final logs = await stream.first;
      expect(logs, hasLength(1));
    });

    test('watchMoodLogs returns in descending date order', () async {
      await _insertMood(date: DateTime(2024, 1, 10));
      await _insertMood(date: DateTime(2024, 1, 15));
      await _insertMood(date: DateTime(2024, 1, 12));

      final logs = await dao
          .watchMoodLogs(DateTime(2024, 1, 1), DateTime(2024, 1, 31))
          .first;
      expect(logs.map((l) => l.date.day).toList(), [15, 12, 10]);
    });

    test('tags stored and retrieved as comma-separated string', () async {
      final id = await _insertMood(tags: 'trabajo,familia,ejercicio');
      final log = await dao.getMoodLogById(id);
      expect(log!.tags, 'trabajo,familia,ejercicio');
    });

    test('deleteMoodLog removes record', () async {
      final id = await _insertMood();
      await dao.deleteMoodLog(id);
      final log = await dao.getMoodLogById(id);
      expect(log, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // BreathingSessions
  // ---------------------------------------------------------------------------

  group('MentalDao — BreathingSessions', () {
    Future<int> _insertSession({
      String technique = 'box',
      int duration = 240,
      bool completed = true,
    }) =>
        dao.insertBreathingSession(BreathingSessionsCompanion.insert(
          techniqueName: technique,
          durationSeconds: duration,
          isCompleted: Value(completed),
          createdAt: DateTime.now(),
        ));

    test('insertBreathingSession returns id > 0', () async {
      final id = await _insertSession();
      expect(id, greaterThan(0));
    });

    test('watchBreathingSessions returns sessions in range', () async {
      final now = DateTime.now();
      await _insertSession();

      final sessions = await dao
          .watchBreathingSessions(
            now.subtract(const Duration(hours: 1)),
            now.add(const Duration(hours: 1)),
          )
          .first;
      expect(sessions, hasLength(1));
    });

    test('getBreathingSessions returns completed sessions', () async {
      final now = DateTime.now();
      await _insertSession(completed: true);
      await _insertSession(completed: false);

      final sessions = await dao.getBreathingSessions(
        now.subtract(const Duration(hours: 1)),
        now.add(const Duration(hours: 1)),
      );
      expect(sessions, hasLength(2));
    });

    test('countCompletedSessions returns correct count', () async {
      await _insertSession(completed: true);
      await _insertSession(completed: true);
      await _insertSession(completed: false);

      final count = await dao.countCompletedSessions();
      expect(count, 2);
    });

    test('all three techniques can be stored', () async {
      for (final technique in ['box', '4_7_8', 'coherent']) {
        final id = await _insertSession(technique: technique);
        expect(id, greaterThan(0));
      }
    });
  });
}
