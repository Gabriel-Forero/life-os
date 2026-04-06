import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/goals/database/goals_dao.dart';
import 'package:life_os/features/goals/domain/goals_input.dart';
import 'package:life_os/features/goals/domain/goals_validators.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<int> _insertGoal(GoalsDao dao) {
  final now = DateTime.now();
  return dao.insertGoal(LifeGoalsCompanion.insert(
    name: 'Property Test Goal',
    description: const Value(null),
    category: 'personal',
    icon: 'track_changes',
    color: const Value(0xFF06B6D4),
    targetDate: const Value(null),
    status: const Value('active'),
    progress: const Value(0),
    createdAt: now,
    updatedAt: now,
  ));
}

Future<int> _insertSubGoal(
  GoalsDao dao, {
  required int goalId,
  required double weight,
  required int progress,
  String name = 'Sub',
}) {
  final now = DateTime.now();
  return dao.insertSubGoal(SubGoalsCompanion.insert(
    goalId: goalId,
    name: name,
    description: const Value(null),
    weight: weight,
    progress: Value(progress),
    linkedModule: const Value(null),
    linkedEntityId: const Value(null),
    isOverridden: const Value(false),
    sortOrder: const Value(0),
    status: const Value('active'),
    createdAt: now,
    updatedAt: now,
  ));
}

void main() {
  late AppDatabase db;
  late GoalsDao dao;

  setUp(() {
    db = _createInMemoryDb();
    dao = db.goalsDao;
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Invariant: Goal progress is always in [0, 100]
  // ---------------------------------------------------------------------------

  group('Goals PBT — progress always in [0, 100]', () {
    test('weighted progress is [0,100] for all valid weight/progress combos',
        () async {
      // Test all combinations of (progress, weight) that are valid
      final progressValues = [0, 10, 25, 50, 75, 90, 100];
      // Use pairs that sum to 1.0
      final weightPairs = [
        [0.5, 0.5],
        [0.3, 0.7],
        [0.1, 0.9],
        [0.6, 0.4],
        [0.2, 0.8],
      ];

      for (final progA in progressValues) {
        for (final progB in progressValues) {
          for (final weights in weightPairs) {
            final goalId = await _insertGoal(dao);
            await _insertSubGoal(dao,
                goalId: goalId,
                name: 'A',
                weight: weights[0],
                progress: progA);
            await _insertSubGoal(dao,
                goalId: goalId,
                name: 'B',
                weight: weights[1],
                progress: progB);

            final progress = await dao.calculateWeightedProgress(goalId);

            expect(
              progress,
              inInclusiveRange(0, 100),
              reason:
                  'progress=$progress out of [0,100] for w=(${weights[0]},${weights[1]}), p=($progA,$progB)',
            );
          }
        }
      }
    });

    test('single sub-goal: weighted progress equals sub-goal progress', () async {
      final progressValues = List.generate(11, (i) => i * 10);
      for (final prog in progressValues) {
        final goalId = await _insertGoal(dao);
        await _insertSubGoal(dao,
            goalId: goalId, weight: 1.0, progress: prog);
        final progress = await dao.calculateWeightedProgress(goalId);
        expect(
          progress,
          prog,
          reason: 'Single sub-goal at $prog% should yield $prog%',
        );
      }
    });

    test('three sub-goals summing to 1.0 always within [0,100]', () async {
      // weights: 0.2, 0.3, 0.5 → sum = 1.0
      const weights = [0.2, 0.3, 0.5];
      final progressValues = [0, 33, 66, 100];

      for (final pA in progressValues) {
        for (final pB in progressValues) {
          for (final pC in progressValues) {
            final goalId = await _insertGoal(dao);
            await _insertSubGoal(dao,
                goalId: goalId, name: 'A', weight: weights[0], progress: pA);
            await _insertSubGoal(dao,
                goalId: goalId, name: 'B', weight: weights[1], progress: pB);
            await _insertSubGoal(dao,
                goalId: goalId, name: 'C', weight: weights[2], progress: pC);

            final progress = await dao.calculateWeightedProgress(goalId);
            expect(progress, inInclusiveRange(0, 100));
          }
        }
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Invariant: Weights must sum to 1.0 (±0.001)
  // ---------------------------------------------------------------------------

  group('Goals PBT — weight sum invariant', () {
    test('validateWeightSum passes for exact 1.0', () {
      final result = validateWeightSum([0.5, 0.3], 0.2);
      expect(result.isSuccess, isTrue);
    });

    test('validateWeightSum passes within tolerance of 0.001', () {
      // floating-point: 0.1 + 0.2 + 0.7 might be 0.9999... or 1.0000...
      final result = validateWeightSum([0.1, 0.2], 0.7);
      expect(result.isSuccess, isTrue);
    });

    test('validateWeightSum allows partial sum < 1.0 (building phase)', () {
      // 0.3 + 0.3 + 0.3 = 0.9 — allowed during sub-goal addition
      final result = validateWeightSum([0.3, 0.3], 0.3);
      expect(result.isSuccess, isTrue);
    });

    test('validateWeightSum fails when total > 1.0 by more than tolerance', () {
      // 0.6 + 0.6 = 1.2 — fails
      final result = validateWeightSum([0.6], 0.6);
      expect(result.isFailure, isTrue);
    });

    test('validateWeightSum passes for any two weights summing to 1.0', () {
      // All pairs from 0.1 to 0.9 in steps of 0.1
      for (var i = 1; i <= 9; i++) {
        final w1 = i / 10.0;
        final w2 = 1.0 - w1;
        final result = validateWeightSum([w1], w2);
        expect(
          result.isSuccess,
          isTrue,
          reason: 'w1=$w1, w2=$w2 should sum to 1.0',
        );
      }
    });

    test('single weight of 1.0 passes with empty existing list', () {
      final result = validateWeightSum([], 1.0);
      expect(result.isSuccess, isTrue);
    });

    test('single weight of 0.5 passes with empty existing list (partial)', () {
      final result = validateWeightSum([], 0.5);
      expect(result.isSuccess, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Invariant: Weighted progress formula consistency
  // ---------------------------------------------------------------------------

  group('Goals PBT — weighted progress formula consistency', () {
    test('formula: sum(w_i * p_i) always equals dao result', () async {
      // Test specific combinations and verify dao matches manual formula
      final cases = [
        {'weights': [0.5, 0.5], 'progresses': [40, 80]},
        {'weights': [0.3, 0.7], 'progresses': [100, 0]},
        {'weights': [0.2, 0.3, 0.5], 'progresses': [50, 60, 70]},
        {'weights': [1.0], 'progresses': [73]},
        {'weights': [0.25, 0.25, 0.25, 0.25], 'progresses': [10, 30, 50, 70]},
      ];

      for (final testCase in cases) {
        final weights = (testCase['weights'] as List).cast<double>();
        final progresses = (testCase['progresses'] as List).cast<int>();

        final goalId = await _insertGoal(dao);
        for (var i = 0; i < weights.length; i++) {
          await _insertSubGoal(dao,
              goalId: goalId,
              name: 'Sub$i',
              weight: weights[i],
              progress: progresses[i]);
        }

        final daoResult = await dao.calculateWeightedProgress(goalId);

        // Manual calculation
        double manual = 0.0;
        for (var i = 0; i < weights.length; i++) {
          manual += weights[i] * progresses[i];
        }
        final expected = manual.round().clamp(0, 100);

        expect(
          daoResult,
          expected,
          reason:
              'DAO result $daoResult != manual $expected for weights=$weights, progresses=$progresses',
        );
      }
    });

    test('progress monotonically increases as any sub-goal progress increases',
        () async {
      // With two equal-weight sub-goals, increasing either one increases total
      final goalId = await _insertGoal(dao);
      final subIdA = await _insertSubGoal(dao,
          goalId: goalId, name: 'A', weight: 0.5, progress: 0);
      await _insertSubGoal(dao,
          goalId: goalId, name: 'B', weight: 0.5, progress: 0);

      var prevProgress = await dao.calculateWeightedProgress(goalId);
      expect(prevProgress, 0);

      for (final newProg in [20, 40, 60, 80, 100]) {
        await dao.updateSubGoalProgress(subIdA, newProg);
        final current = await dao.calculateWeightedProgress(goalId);
        expect(
          current,
          greaterThanOrEqualTo(prevProgress),
          reason:
              'progress should not decrease when sub-goal A goes to $newProg',
        );
        prevProgress = current;
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Validator properties
  // ---------------------------------------------------------------------------

  group('Goals PBT — validators', () {
    test('validateGoalName accepts any string of length 1–100', () {
      for (var len = 1; len <= 100; len++) {
        final result = validateGoalName('a' * len);
        expect(result.isSuccess, isTrue,
            reason: 'Name of length $len should be valid');
      }
    });

    test('validateGoalName rejects empty and > 100', () {
      expect(validateGoalName('').isFailure, isTrue);
      expect(validateGoalName('a' * 101).isFailure, isTrue);
    });

    test('validateSubGoalProgress accepts 0–100 inclusive', () {
      for (var p = 0; p <= 100; p++) {
        final result = validateSubGoalProgress(p);
        expect(result.isSuccess, isTrue, reason: 'Progress $p should be valid');
      }
    });

    test('validateSubGoalProgress rejects out-of-range values', () {
      expect(validateSubGoalProgress(-1).isFailure, isTrue);
      expect(validateSubGoalProgress(101).isFailure, isTrue);
    });

    test('validateMilestoneTargetProgress accepts 0–100 inclusive', () {
      for (var p = 0; p <= 100; p++) {
        final result = validateMilestoneTargetProgress(p);
        expect(result.isSuccess, isTrue,
            reason: 'Milestone targetProgress $p should be valid');
      }
    });

    test('validateGoalCategory accepts all GoalCategory values', () {
      for (final cat in GoalCategory.values) {
        final result = validateGoalCategory(cat.name);
        expect(result.isSuccess, isTrue,
            reason: '${cat.name} should be a valid category');
      }
    });

    test('validateGoalCategory rejects unknown strings', () {
      // Note: category matching is case-insensitive, so 'SALUD' is valid.
      // Only truly unknown values are rejected.
      for (final invalid in ['unknown', 'health', 'sport', '']) {
        final result = validateGoalCategory(invalid);
        expect(result.isFailure, isTrue,
            reason: '"$invalid" should be invalid');
      }
    });
  });
}
