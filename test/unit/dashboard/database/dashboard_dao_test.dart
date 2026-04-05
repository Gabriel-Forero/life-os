import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/dashboard/database/dashboard_dao.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late DashboardDao dao;

  setUp(() async {
    db = _createInMemoryDb();
    dao = db.dashboardDao;
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // DayScoreConfigs
  // ---------------------------------------------------------------------------

  group('DashboardDao — DayScoreConfigs', () {
    test('seedDefaultConfigsIfEmpty seeds 4 modules', () async {
      await dao.seedDefaultConfigsIfEmpty();
      final configs = await dao.getScoreConfigs();
      expect(configs, hasLength(4));
      final keys = configs.map((c) => c.moduleKey).toList();
      expect(keys, containsAll(['finance', 'gym', 'nutrition', 'habits']));
    });

    test('seedDefaultConfigsIfEmpty is idempotent', () async {
      await dao.seedDefaultConfigsIfEmpty();
      await dao.seedDefaultConfigsIfEmpty();
      final configs = await dao.getScoreConfigs();
      expect(configs, hasLength(4));
    });

    test('default configs have weight 1.0 and isEnabled true', () async {
      await dao.seedDefaultConfigsIfEmpty();
      final configs = await dao.getScoreConfigs();
      for (final c in configs) {
        expect(c.weight, 1.0);
        expect(c.isEnabled, isTrue);
      }
    });

    test('updateWeightByKey changes weight', () async {
      await dao.seedDefaultConfigsIfEmpty();
      await dao.updateWeightByKey('finance', 2.5);
      final configs = await dao.getScoreConfigs();
      final finance = configs.firstWhere((c) => c.moduleKey == 'finance');
      expect(finance.weight, 2.5);
    });

    test('updateScoreConfig changes isEnabled and weight', () async {
      await dao.seedDefaultConfigsIfEmpty();
      final configs = await dao.getScoreConfigs();
      final gymConfig = configs.firstWhere((c) => c.moduleKey == 'gym');
      await dao.updateScoreConfig(
        gymConfig.id,
        weight: 3.0,
        isEnabled: false,
      );
      final updated = await dao.getScoreConfigs();
      final gym = updated.firstWhere((c) => c.moduleKey == 'gym');
      expect(gym.weight, 3.0);
      expect(gym.isEnabled, isFalse);
    });

    test('watchScoreConfigs emits on change', () async {
      await dao.seedDefaultConfigsIfEmpty();

      final stream = dao.watchScoreConfigs();
      final firstEmit = await stream.first;
      expect(firstEmit, hasLength(4));

      await dao.updateWeightByKey('habits', 5.0);
      final secondEmit = await stream.first;
      final habits = secondEmit.firstWhere((c) => c.moduleKey == 'habits');
      expect(habits.weight, 5.0);
    });
  });

  // ---------------------------------------------------------------------------
  // DayScores — upsert & queries
  // ---------------------------------------------------------------------------

  group('DashboardDao — DayScores', () {
    final testDate = DateTime.utc(2026, 4, 4);

    Future<void> _upsert({int score = 75}) => dao.upsertDayScore(
          date: testDate,
          totalScore: score,
          calculatedAt: testDate,
          components: [
            const ScoreComponentInput(
              moduleKey: 'finance',
              rawValue: 80.0,
              weight: 1.0,
              weightedScore: 80.0,
            ),
            const ScoreComponentInput(
              moduleKey: 'gym',
              rawValue: 70.0,
              weight: 1.0,
              weightedScore: 70.0,
            ),
          ],
        );

    test('upsertDayScore inserts new row', () async {
      await _upsert();
      final result = await dao.getDayScoreForDate(testDate);
      expect(result, isNotNull);
      expect(result!.totalScore, 75);
    });

    test('upsertDayScore updates existing row on same date', () async {
      await _upsert(score: 75);
      await _upsert(score: 90);
      final result = await dao.getDayScoreForDate(testDate);
      expect(result!.totalScore, 90);
    });

    test('upsertDayScore replaces components on re-calculation', () async {
      await _upsert();
      // Re-upsert with 3 components
      await dao.upsertDayScore(
        date: testDate,
        totalScore: 80,
        calculatedAt: testDate,
        components: [
          const ScoreComponentInput(
            moduleKey: 'finance',
            rawValue: 85.0,
            weight: 1.0,
            weightedScore: 85.0,
          ),
          const ScoreComponentInput(
            moduleKey: 'gym',
            rawValue: 75.0,
            weight: 1.0,
            weightedScore: 75.0,
          ),
          const ScoreComponentInput(
            moduleKey: 'habits',
            rawValue: 80.0,
            weight: 1.0,
            weightedScore: 80.0,
          ),
        ],
      );
      final dayScore = await dao.getDayScoreForDate(testDate);
      final components =
          await dao.getComponentsForDayScore(dayScore!.id);
      expect(components, hasLength(3));
    });

    test('getDayScoreForDate returns null for missing date', () async {
      final result =
          await dao.getDayScoreForDate(DateTime.utc(2020, 1, 1));
      expect(result, isNull);
    });

    test('getRecentDayScores returns latest first', () async {
      await dao.upsertDayScore(
        date: DateTime.utc(2026, 4, 1),
        totalScore: 60,
        calculatedAt: DateTime.utc(2026, 4, 1),
        components: [],
      );
      await dao.upsertDayScore(
        date: DateTime.utc(2026, 4, 3),
        totalScore: 80,
        calculatedAt: DateTime.utc(2026, 4, 3),
        components: [],
      );
      await dao.upsertDayScore(
        date: DateTime.utc(2026, 4, 2),
        totalScore: 70,
        calculatedAt: DateTime.utc(2026, 4, 2),
        components: [],
      );

      final scores = await dao.getRecentDayScores();
      expect(scores.first.totalScore, 80); // most recent first
    });

    test('getRecentDayScores respects limit', () async {
      for (var i = 1; i <= 35; i++) {
        await dao.upsertDayScore(
          date: DateTime.utc(2026, 1, i > 31 ? 31 : i),
          totalScore: i,
          calculatedAt: DateTime.utc(2026, 1, i > 31 ? 31 : i),
          components: [],
        );
      }
      final scores = await dao.getRecentDayScores(limit: 30);
      expect(scores.length, lessThanOrEqualTo(30));
    });
  });

  // ---------------------------------------------------------------------------
  // LifeSnapshots
  // ---------------------------------------------------------------------------

  group('DashboardDao — LifeSnapshots', () {
    final snapshotDate = DateTime.utc(2026, 4, 3);

    test('insertLifeSnapshot inserts new snapshot', () async {
      await dao.insertLifeSnapshot(
        date: snapshotDate,
        totalScore: 72,
        metrics: {'finance': {'balance': 1000}},
      );
      final result = await dao.getSnapshotForDate(snapshotDate);
      expect(result, isNotNull);
      expect(result!.totalScore, 72);
    });

    test('insertLifeSnapshot is idempotent for same date', () async {
      await dao.insertLifeSnapshot(
        date: snapshotDate,
        totalScore: 72,
        metrics: {'finance': {}},
      );
      // Second call should not throw or create duplicate
      await dao.insertLifeSnapshot(
        date: snapshotDate,
        totalScore: 99,
        metrics: {'finance': {}},
      );
      final result = await dao.getSnapshotForDate(snapshotDate);
      expect(result!.totalScore, 72); // original value preserved
    });

    test('getSnapshotForDate returns null for missing date', () async {
      final result =
          await dao.getSnapshotForDate(DateTime.utc(2020, 1, 1));
      expect(result, isNull);
    });

    test('getAllSnapshots returns all ordered by date desc', () async {
      await dao.insertLifeSnapshot(
        date: DateTime.utc(2026, 4, 1),
        totalScore: 65,
        metrics: {},
      );
      await dao.insertLifeSnapshot(
        date: DateTime.utc(2026, 4, 3),
        totalScore: 85,
        metrics: {},
      );
      await dao.insertLifeSnapshot(
        date: DateTime.utc(2026, 4, 2),
        totalScore: 75,
        metrics: {},
      );
      final snapshots = await dao.getAllSnapshots();
      expect(snapshots.first.totalScore, 85);
      expect(snapshots.last.totalScore, 65);
    });

    test('snapshot metricsJson round-trips through JSON', () async {
      final metrics = {
        'finance': {'balance': 500000, 'budgetUsed': 0.72},
        'gym': {'workoutsThisWeek': 3},
      };
      await dao.insertLifeSnapshot(
        date: snapshotDate,
        totalScore: 80,
        metrics: metrics,
      );
      final result = await dao.getSnapshotForDate(snapshotDate);
      expect(result!.metricsJson, contains('finance'));
      expect(result.metricsJson, contains('budgetUsed'));
    });
  });
}
