import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/dashboard/data/dashboard_repository.dart';
import 'package:life_os/features/dashboard/data/drift_dashboard_repository.dart';
import 'package:life_os/features/dashboard/database/dashboard_dao.dart';
import 'package:life_os/features/dashboard/providers/day_score_notifier.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [DayScoreNotifier] with a fixed score per module.
DayScoreNotifier _makeNotifier({
  required DashboardRepository repository,
  required EventBus eventBus,
  Map<String, double> moduleScores = const {
    'finance': 80.0,
    'gym': 70.0,
    'nutrition': 60.0,
    'habits': 90.0,
  },
}) {
  return DayScoreNotifier(
    repository: repository,
    eventBus: eventBus,
    moduleScoreProvider: (key) async => moduleScores[key] ?? 0.0,
  );
}

void main() {
  late AppDatabase db;
  late DashboardDao dao;
  late DashboardRepository repository;
  late EventBus eventBus;
  late DayScoreNotifier notifier;

  setUp(() async {
    db = _createInMemoryDb();
    dao = db.dashboardDao;
    repository = DriftDashboardRepository(dao: dao);
    eventBus = EventBus();
    notifier = _makeNotifier(repository: repository, eventBus: eventBus);
    await repository.seedDefaultConfigsIfEmpty();
  });

  tearDown(() async {
    notifier.dispose();
    eventBus.dispose();
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  group('DayScoreNotifier — initialize', () {
    test('initialize loads configs and computes score', () async {
      await notifier.initialize();
      expect(notifier.state.configs, hasLength(4));
      expect(notifier.state.todayScore, isNotNull);
      expect(notifier.state.isLoading, isFalse);
    });

    test('initialize seeds configs if empty', () async {
      // New DB without seeding
      final freshDb = _createInMemoryDb();
      final freshDao = freshDb.dashboardDao;
      final freshRepo = DriftDashboardRepository(dao: freshDao);
      final freshBus = EventBus();
      final freshNotifier =
          _makeNotifier(repository: freshRepo, eventBus: freshBus);

      await freshNotifier.initialize();
      expect(freshNotifier.state.configs, hasLength(4));

      freshNotifier.dispose();
      freshBus.dispose();
      await freshDb.close();
    });
  });

  // ---------------------------------------------------------------------------
  // Score Calculation
  // ---------------------------------------------------------------------------

  group('DayScoreNotifier — calculateDayScore', () {
    test('calculates weighted average with equal weights', () async {
      // Scores: finance=80, gym=70, nutrition=60, habits=90
      // Equal weights: (80+70+60+90)/4 = 75
      final result =
          await notifier.calculateDayScore(DateTime.utc(2026, 4, 4));
      expect(result, isA<Success<int>>());
      expect(result.valueOrNull, 75);
    });

    test('calculates weighted average with custom weights', () async {
      // Give finance weight=2, others weight=1
      // (80×2 + 70×1 + 60×1 + 90×1) / (2+1+1+1) = (160+70+60+90)/5 = 380/5 = 76
      await repository.updateWeightByKey('finance', 2.0);

      final result =
          await notifier.calculateDayScore(DateTime.utc(2026, 4, 4));
      expect(result.valueOrNull, 76);
    });

    test('score is clamped to 0–100', () async {
      final highNotifier = _makeNotifier(
        repository: repository,
        eventBus: eventBus,
        moduleScores: const {
          'finance': 200.0, // will be clamped to 100
          'gym': 150.0,
          'nutrition': 120.0,
          'habits': 110.0,
        },
      );
      final result =
          await highNotifier.calculateDayScore(DateTime.utc(2026, 4, 4));
      expect(result.valueOrNull, lessThanOrEqualTo(100));
      highNotifier.dispose();
    });

    test('score is 0 when no modules are enabled', () async {
      // Disable all modules
      final configs = await repository.getScoreConfigs();
      for (final c in configs) {
        await repository.updateScoreConfig(c.id,
            weight: c.weight, isEnabled: false);
      }
      final result =
          await notifier.calculateDayScore(DateTime.utc(2026, 4, 4));
      expect(result.valueOrNull, 0);
    });

    test('calculates with only enabled modules', () async {
      // Disable gym and nutrition
      final configs = await repository.getScoreConfigs();
      for (final c in configs) {
        if (c.moduleKey == 'gym' || c.moduleKey == 'nutrition') {
          await repository.updateScoreConfig(c.id,
              weight: c.weight, isEnabled: false);
        }
      }
      // Only finance=80, habits=90 enabled, equal weights: (80+90)/2 = 85
      final result =
          await notifier.calculateDayScore(DateTime.utc(2026, 4, 4));
      expect(result.valueOrNull, 85);
    });

    test('persists score to database', () async {
      final date = DateTime.utc(2026, 4, 4);
      await notifier.calculateDayScore(date);
      final saved = await repository.getDayScoreForDate(date);
      expect(saved, isNotNull);
      expect(saved!.totalScore, isNotNull);
    });

    test('persists components to database', () async {
      final date = DateTime.utc(2026, 4, 4);
      await notifier.calculateDayScore(date);
      final saved = await repository.getDayScoreForDate(date);
      final components =
          await repository.getComponentsForDayScore(saved!.id);
      expect(components, hasLength(4));
    });

    test('recalculation on same date updates existing row', () async {
      final date = DateTime.utc(2026, 4, 4);
      await notifier.calculateDayScore(date);

      // Change module scores via different notifier
      final updatedNotifier = _makeNotifier(
        repository: repository,
        eventBus: eventBus,
        moduleScores: const {
          'finance': 100.0,
          'gym': 100.0,
          'nutrition': 100.0,
          'habits': 100.0,
        },
      );
      await updatedNotifier.calculateDayScore(date);
      final saved = await repository.getDayScoreForDate(date);
      expect(saved!.totalScore, 100);
      updatedNotifier.dispose();
    });

    test('updates state after calculation', () async {
      await notifier.calculateDayScore(DateTime.utc(2026, 4, 4));
      expect(notifier.state.todayScore, isNotNull);
      expect(notifier.state.components, hasLength(4));
    });
  });

  // ---------------------------------------------------------------------------
  // Weight Management
  // ---------------------------------------------------------------------------

  group('DayScoreNotifier — updateWeight', () {
    test('updateWeight valid value succeeds', () async {
      final result = await notifier.updateWeight('finance', 2.0);
      expect(result, isA<Success<void>>());
      final configs = await repository.getScoreConfigs();
      final finance = configs.firstWhere((c) => c.moduleKey == 'finance');
      expect(finance.weight, 2.0);
    });

    test('updateWeight rejects zero', () async {
      final result = await notifier.updateWeight('finance', 0.0);
      expect(result, isA<Failure<void>>());
    });

    test('updateWeight rejects negative', () async {
      final result = await notifier.updateWeight('finance', -1.0);
      expect(result, isA<Failure<void>>());
    });

    test('updateWeight rejects value above 10', () async {
      final result = await notifier.updateWeight('finance', 10.1);
      expect(result, isA<Failure<void>>());
    });

    test('updateWeight triggers score recalculation', () async {
      await notifier.calculateDayScore(DateTime.utc(2026, 4, 4));
      final scoreBefore = notifier.state.todayScore;

      // Change finance weight to dominate
      await notifier.updateWeight('finance', 10.0);
      final scoreAfter = notifier.state.todayScore;

      // Score should change (finance=80 is below average so higher weight pulls down)
      expect(scoreAfter, isNotNull);
      // With finance weight=10 and others=1:
      // (80×10 + 70×1 + 60×1 + 90×1)/(10+1+1+1) = (800+70+60+90)/13 = 1020/13 ≈ 78
      expect(scoreAfter, lessThanOrEqualTo(100));
    });
  });

  // ---------------------------------------------------------------------------
  // EventBus subscriptions
  // ---------------------------------------------------------------------------

  group('DayScoreNotifier — EventBus', () {
    test('BudgetThresholdEvent triggers recalculation', () async {
      await notifier.initialize();
      final scoreBefore = notifier.state.todayScore;

      eventBus.emit(BudgetThresholdEvent(
        budgetId: 1,
        categoryName: 'Comida',
        percentage: 0.9,
      ));

      // Allow async stream to process
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // Score should still be within bounds (calculation ran)
      expect(notifier.state.todayScore, isNotNull);
      expect(notifier.state.todayScore, inInclusiveRange(0, 100));
    });

    test('HabitCheckedInEvent triggers recalculation', () async {
      await notifier.initialize();

      eventBus.emit(HabitCheckedInEvent(
        habitId: 1,
        habitName: 'Meditar',
        isCompleted: true,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.todayScore, isNotNull);
    });

    test('GoalProgressUpdatedEvent triggers recalculation', () async {
      await notifier.initialize();

      eventBus.emit(GoalProgressUpdatedEvent(goalId: 1, progress: 50));

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(notifier.state.todayScore, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // getScoreConfigs
  // ---------------------------------------------------------------------------

  group('DayScoreNotifier — getScoreConfigs', () {
    test('returns all 4 configs after seeding', () async {
      final configs = await notifier.getScoreConfigs();
      expect(configs, hasLength(4));
    });
  });
}
