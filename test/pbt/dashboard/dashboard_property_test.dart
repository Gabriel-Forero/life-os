import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/dashboard/providers/day_score_notifier.dart';

// ---------------------------------------------------------------------------
// Property-Based Tests for DayScore Invariants
//
// These tests verify mathematical invariants of the DayScore calculation
// across a wide range of input combinations.
// ---------------------------------------------------------------------------

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

/// Generates a [DayScoreNotifier] with given raw module scores.
Future<({DayScoreNotifier notifier, AppDatabase db, EventBus bus})>
    _setup(Map<String, double> scores) async {
  final db = _createInMemoryDb();
  final dao = db.dashboardDao;
  final bus = EventBus();
  await dao.seedDefaultConfigsIfEmpty();
  final notifier = DayScoreNotifier(
    dao: dao,
    eventBus: bus,
    moduleScoreProvider: (key) async => scores[key] ?? 0.0,
  );
  return (notifier: notifier, db: db, bus: bus);
}

void main() {
  // ---------------------------------------------------------------------------
  // Invariant 1: Score is always in [0, 100]
  // ---------------------------------------------------------------------------
  group('Property: DayScore is always in [0, 100]', () {
    final testCases = [
      {'finance': 0.0, 'gym': 0.0, 'nutrition': 0.0, 'habits': 0.0},
      {'finance': 100.0, 'gym': 100.0, 'nutrition': 100.0, 'habits': 100.0},
      {'finance': 50.0, 'gym': 50.0, 'nutrition': 50.0, 'habits': 50.0},
      {'finance': 0.0, 'gym': 100.0, 'nutrition': 0.0, 'habits': 100.0},
      {'finance': 25.0, 'gym': 75.0, 'nutrition': 33.3, 'habits': 66.7},
      {'finance': 1.0, 'gym': 99.0, 'nutrition': 49.5, 'habits': 50.5},
      {'finance': 100.0, 'gym': 0.0, 'nutrition': 100.0, 'habits': 0.0},
    ];

    for (final scores in testCases) {
      test('scores=$scores', () async {
        final (:notifier, :db, :bus) = await _setup(scores);
        try {
          final result = await notifier.calculateDayScore(DateTime.utc(2026, 4, 4));
          final score = result.valueOrNull!;
          expect(score, inInclusiveRange(0, 100),
              reason: 'DayScore must be in [0, 100] for scores $scores');
        } finally {
          notifier.dispose();
          bus.dispose();
          await db.close();
        }
      });
    }
  });

  // ---------------------------------------------------------------------------
  // Invariant 2: Equal scores with any weights → totalScore equals that score
  // ---------------------------------------------------------------------------
  group('Property: Equal module scores → totalScore equals that score', () {
    final equalScoreCases = [0.0, 25.0, 50.0, 75.0, 100.0];

    for (final score in equalScoreCases) {
      test('all modules = $score', () async {
        final scores = {
          'finance': score,
          'gym': score,
          'nutrition': score,
          'habits': score,
        };
        final (:notifier, :db, :bus) = await _setup(scores);
        try {
          final result = await notifier.calculateDayScore(DateTime.utc(2026, 4, 4));
          expect(result.valueOrNull, score.round(),
              reason:
                  'When all modules have score $score, total must be $score');
        } finally {
          notifier.dispose();
          bus.dispose();
          await db.close();
        }
      });
    }
  });

  // ---------------------------------------------------------------------------
  // Invariant 3: Higher weight for higher-scoring module → higher total score
  // ---------------------------------------------------------------------------
  group('Property: Higher weight on higher module → higher or equal score', () {
    test('weighting high-scoring module increases or maintains score', () async {
      // finance=90 (high), others=50
      // Case A: equal weights → (90+50+50+50)/4 = 60
      // Case B: finance weight=3 → (90×3+50+50+50)/(3+1+1+1) = (270+150)/6 = 70
      final scores = {
        'finance': 90.0,
        'gym': 50.0,
        'nutrition': 50.0,
        'habits': 50.0,
      };

      // Case A: equal weights (already default)
      final setupA = await _setup(scores);
      final resultA = await setupA.notifier
          .calculateDayScore(DateTime.utc(2026, 4, 4));
      final scoreA = resultA.valueOrNull!;

      setupA.notifier.dispose();
      setupA.bus.dispose();
      await setupA.db.close();

      // Case B: finance weight = 3
      final setupB = await _setup(scores);
      await setupB.db.dashboardDao.updateWeightByKey('finance', 3.0);
      final resultB = await setupB.notifier
          .calculateDayScore(DateTime.utc(2026, 4, 4));
      final scoreB = resultB.valueOrNull!;

      setupB.notifier.dispose();
      setupB.bus.dispose();
      await setupB.db.close();

      expect(scoreB, greaterThanOrEqualTo(scoreA),
          reason:
              'Increasing weight of high-scoring module must not decrease score. '
              'A=$scoreA, B=$scoreB');
    });
  });

  // ---------------------------------------------------------------------------
  // Invariant 4: Disabling all modules → score = 0
  // ---------------------------------------------------------------------------
  group('Property: No enabled modules → score = 0', () {
    test('all modules disabled returns 0', () async {
      final scores = {
        'finance': 80.0,
        'gym': 70.0,
        'nutrition': 60.0,
        'habits': 90.0,
      };
      final (:notifier, :db, :bus) = await _setup(scores);
      try {
        final configs = await db.dashboardDao.getScoreConfigs();
        for (final c in configs) {
          await db.dashboardDao
              .updateScoreConfig(c.id, weight: c.weight, isEnabled: false);
        }

        final result = await notifier.calculateDayScore(DateTime.utc(2026, 4, 4));
        expect(result.valueOrNull, 0,
            reason: 'Score must be 0 when no modules are enabled');
      } finally {
        notifier.dispose();
        bus.dispose();
        await db.close();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Invariant 5: score is idempotent — same inputs → same output
  // ---------------------------------------------------------------------------
  group('Property: DayScore calculation is deterministic', () {
    test('same inputs on different calls return same score', () async {
      const scores = {
        'finance': 67.0,
        'gym': 82.0,
        'nutrition': 55.0,
        'habits': 91.0,
      };
      final (:notifier, :db, :bus) = await _setup(scores);
      try {
        final date = DateTime.utc(2026, 4, 4);
        final r1 = await notifier.calculateDayScore(date);
        final r2 = await notifier.calculateDayScore(date);
        expect(r1.valueOrNull, r2.valueOrNull,
            reason: 'Repeated calculation must be deterministic');
      } finally {
        notifier.dispose();
        bus.dispose();
        await db.close();
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Invariant 6: Single enabled module → totalScore equals that module's score
  // ---------------------------------------------------------------------------
  group('Property: Single enabled module → total equals its score', () {
    final singleModuleCases = [
      ('finance', 42.0),
      ('gym', 73.0),
      ('nutrition', 100.0),
      ('habits', 0.0),
    ];

    for (final (module, rawScore) in singleModuleCases) {
      test('only $module enabled with score $rawScore', () async {
        final scores = {
          'finance': module == 'finance' ? rawScore : 50.0,
          'gym': module == 'gym' ? rawScore : 50.0,
          'nutrition': module == 'nutrition' ? rawScore : 50.0,
          'habits': module == 'habits' ? rawScore : 50.0,
        };
        final (:notifier, :db, :bus) = await _setup(scores);
        try {
          final configs = await db.dashboardDao.getScoreConfigs();
          for (final c in configs) {
            if (c.moduleKey != module) {
              await db.dashboardDao.updateScoreConfig(
                c.id,
                weight: c.weight,
                isEnabled: false,
              );
            }
          }

          final result =
              await notifier.calculateDayScore(DateTime.utc(2026, 4, 4));
          expect(result.valueOrNull, rawScore.round(),
              reason: 'Single-module score must equal the module raw score');
        } finally {
          notifier.dispose();
          bus.dispose();
          await db.close();
        }
      });
    }
  });

  // ---------------------------------------------------------------------------
  // Invariant 7: Score persisted = score returned
  // ---------------------------------------------------------------------------
  group('Property: Score returned == score stored in DB', () {
    test('returned score matches persisted score', () async {
      const scores = {
        'finance': 65.0,
        'gym': 80.0,
        'nutrition': 70.0,
        'habits': 85.0,
      };
      final (:notifier, :db, :bus) = await _setup(scores);
      try {
        final date = DateTime.utc(2026, 4, 4);
        final result = await notifier.calculateDayScore(date);
        final persisted = await db.dashboardDao.getDayScoreForDate(date);
        expect(result.valueOrNull, persisted!.totalScore,
            reason: 'Returned score must match persisted score');
      } finally {
        notifier.dispose();
        bus.dispose();
        await db.close();
      }
    });
  });
}
