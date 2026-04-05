import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/goals/database/goals_dao.dart';
import 'package:life_os/features/goals/database/goals_tables.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<int> _insertGoal(
  GoalsDao dao, {
  String name = 'Meta de prueba',
  String category = 'personal',
  String icon = 'track_changes',
  int color = 0xFF06B6D4,
  String status = 'active',
  int progress = 0,
  DateTime? targetDate,
}) {
  final now = DateTime.now();
  return dao.insertGoal(LifeGoalsCompanion.insert(
    name: name,
    description: const Value(null),
    category: category,
    icon: icon,
    color: Value(color),
    targetDate: Value(targetDate),
    status: Value(status),
    progress: Value(progress),
    createdAt: now,
    updatedAt: now,
  ));
}

Future<int> _insertSubGoal(
  GoalsDao dao, {
  required int goalId,
  String name = 'Sub-meta',
  double weight = 1.0,
  int progress = 0,
  String? linkedModule,
  int? linkedEntityId,
  bool isOverridden = false,
  int sortOrder = 0,
}) {
  final now = DateTime.now();
  return dao.insertSubGoal(SubGoalsCompanion.insert(
    goalId: goalId,
    name: name,
    description: const Value(null),
    weight: weight,
    progress: Value(progress),
    linkedModule: Value(linkedModule),
    linkedEntityId: Value(linkedEntityId),
    isOverridden: Value(isOverridden),
    sortOrder: Value(sortOrder),
    status: const Value('active'),
    createdAt: now,
    updatedAt: now,
  ));
}

Future<int> _insertMilestone(
  GoalsDao dao, {
  required int goalId,
  String name = 'Hito de prueba',
  int targetProgress = 50,
  DateTime? targetDate,
  int sortOrder = 0,
}) {
  final now = DateTime.now();
  return dao.insertMilestone(GoalMilestonesCompanion.insert(
    goalId: goalId,
    name: name,
    targetDate: Value(targetDate),
    targetProgress: Value(targetProgress),
    isCompleted: const Value(false),
    completedAt: const Value(null),
    sortOrder: Value(sortOrder),
    createdAt: now,
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
  // LifeGoals CRUD
  // ---------------------------------------------------------------------------

  group('GoalsDao — LifeGoals CRUD', () {
    test('insertGoal returns id > 0', () async {
      final id = await _insertGoal(dao);
      expect(id, greaterThan(0));
    });

    test('getGoalById returns inserted goal', () async {
      final id = await _insertGoal(dao, name: 'Correr maraton');
      final goal = await dao.getGoalById(id);
      expect(goal, isNotNull);
      expect(goal!.name, 'Correr maraton');
    });

    test('getGoalById returns null for unknown id', () async {
      final goal = await dao.getGoalById(9999);
      expect(goal, isNull);
    });

    test('updateGoal changes name and category', () async {
      final id = await _insertGoal(dao, name: 'Original');
      final goal = await dao.getGoalById(id);
      await dao.updateGoal(goal!.copyWith(name: 'Actualizado'));
      final updated = await dao.getGoalById(id);
      expect(updated!.name, 'Actualizado');
    });

    test('updateGoalProgress persists new progress', () async {
      final id = await _insertGoal(dao, progress: 0);
      await dao.updateGoalProgress(id, 75);
      final goal = await dao.getGoalById(id);
      expect(goal!.progress, 75);
    });

    test('updateGoalStatus persists new status', () async {
      final id = await _insertGoal(dao);
      await dao.updateGoalStatus(id, 'completed');
      final goal = await dao.getGoalById(id);
      expect(goal!.status, 'completed');
    });

    test('deleteGoal removes goal and cascades', () async {
      final goalId = await _insertGoal(dao);
      await _insertSubGoal(dao, goalId: goalId);
      await _insertMilestone(dao, goalId: goalId);
      await dao.deleteGoal(goalId);
      final goal = await dao.getGoalById(goalId);
      expect(goal, isNull);
      final subs = await dao.getSubGoalsForGoal(goalId);
      expect(subs, isEmpty);
      final milestones = await dao.getMilestonesForGoal(goalId);
      expect(milestones, isEmpty);
    });

    test('getAllGoals returns all inserted goals', () async {
      await _insertGoal(dao, name: 'Meta 1');
      await _insertGoal(dao, name: 'Meta 2');
      await _insertGoal(dao, name: 'Meta 3');
      final goals = await dao.getAllGoals();
      expect(goals.length, 3);
    });

    test('watchAllGoals emits list including newly inserted goal', () async {
      final id = await _insertGoal(dao, name: 'Streaming Meta');
      final goals = await dao.watchAllGoals().first;
      expect(goals.any((g) => g.id == id), isTrue);
    });

    test('watchGoalsByCategory filters by category', () async {
      await _insertGoal(dao, name: 'Meta salud', category: 'salud');
      await _insertGoal(dao, name: 'Meta finanzas', category: 'finanzas');
      final saludGoals =
          await dao.watchGoalsByCategory('salud').first;
      expect(saludGoals.length, 1);
      expect(saludGoals.first.name, 'Meta salud');
    });
  });

  // ---------------------------------------------------------------------------
  // SubGoals CRUD
  // ---------------------------------------------------------------------------

  group('GoalsDao — SubGoals CRUD', () {
    late int goalId;

    setUp(() async {
      goalId = await _insertGoal(dao);
    });

    test('insertSubGoal returns id > 0', () async {
      final id = await _insertSubGoal(dao, goalId: goalId);
      expect(id, greaterThan(0));
    });

    test('getSubGoalById returns inserted sub-goal', () async {
      final id =
          await _insertSubGoal(dao, goalId: goalId, name: 'Sub-meta A');
      final sub = await dao.getSubGoalById(id);
      expect(sub, isNotNull);
      expect(sub!.name, 'Sub-meta A');
    });

    test('getSubGoalById returns null for unknown id', () async {
      final sub = await dao.getSubGoalById(9999);
      expect(sub, isNull);
    });

    test('getSubGoalsForGoal returns all sub-goals for that goal', () async {
      await _insertSubGoal(dao,
          goalId: goalId, name: 'A', weight: 0.5, sortOrder: 0);
      await _insertSubGoal(dao,
          goalId: goalId, name: 'B', weight: 0.5, sortOrder: 1);
      final subs = await dao.getSubGoalsForGoal(goalId);
      expect(subs.length, 2);
    });

    test('getSubGoalsForGoal orders by sortOrder ascending', () async {
      await _insertSubGoal(dao,
          goalId: goalId, name: 'B', weight: 0.5, sortOrder: 1);
      await _insertSubGoal(dao,
          goalId: goalId, name: 'A', weight: 0.5, sortOrder: 0);
      final subs = await dao.getSubGoalsForGoal(goalId);
      expect(subs.first.name, 'A');
      expect(subs.last.name, 'B');
    });

    test('updateSubGoalProgress persists progress and isOverridden', () async {
      final id =
          await _insertSubGoal(dao, goalId: goalId, progress: 0);
      await dao.updateSubGoalProgress(id, 60, isOverridden: true);
      final sub = await dao.getSubGoalById(id);
      expect(sub!.progress, 60);
      expect(sub.isOverridden, isTrue);
    });

    test('deleteSubGoal removes sub-goal', () async {
      final id = await _insertSubGoal(dao, goalId: goalId);
      await dao.deleteSubGoal(id);
      final sub = await dao.getSubGoalById(id);
      expect(sub, isNull);
    });

    test('getSubGoalsLinkedTo returns matching sub-goals', () async {
      await _insertSubGoal(dao,
          goalId: goalId,
          name: 'Linked habit',
          linkedModule: 'habits',
          linkedEntityId: 42);
      await _insertSubGoal(dao,
          goalId: goalId,
          name: 'Unlinked',
          linkedModule: null);
      final linked = await dao.getSubGoalsLinkedTo('habits', 42);
      expect(linked.length, 1);
      expect(linked.first.name, 'Linked habit');
    });

    test('getSubGoalsLinkedTo returns empty when none match', () async {
      await _insertSubGoal(dao,
          goalId: goalId,
          linkedModule: 'habits',
          linkedEntityId: 1);
      final linked = await dao.getSubGoalsLinkedTo('habits', 999);
      expect(linked, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Weighted Progress Calculation
  // ---------------------------------------------------------------------------

  group('GoalsDao — calculateWeightedProgress', () {
    late int goalId;

    setUp(() async {
      goalId = await _insertGoal(dao);
    });

    test('returns 0 when no sub-goals', () async {
      final progress = await dao.calculateWeightedProgress(goalId);
      expect(progress, 0);
    });

    test('single sub-goal with full weight: progress mirrors sub-goal', () async {
      await _insertSubGoal(dao,
          goalId: goalId, weight: 1.0, progress: 60);
      final progress = await dao.calculateWeightedProgress(goalId);
      expect(progress, 60);
    });

    test('two equal-weight sub-goals: progress is their average', () async {
      await _insertSubGoal(dao,
          goalId: goalId, name: 'A', weight: 0.5, progress: 40);
      await _insertSubGoal(dao,
          goalId: goalId, name: 'B', weight: 0.5, progress: 80);
      final progress = await dao.calculateWeightedProgress(goalId);
      // (0.5 * 40) + (0.5 * 80) = 20 + 40 = 60
      expect(progress, 60);
    });

    test('unequal weights: weighted sum is correct', () async {
      await _insertSubGoal(dao,
          goalId: goalId, name: 'Heavy', weight: 0.7, progress: 100);
      await _insertSubGoal(dao,
          goalId: goalId, name: 'Light', weight: 0.3, progress: 0);
      final progress = await dao.calculateWeightedProgress(goalId);
      // (0.7 * 100) + (0.3 * 0) = 70
      expect(progress, 70);
    });

    test('all sub-goals at 0 progress yields 0', () async {
      await _insertSubGoal(dao,
          goalId: goalId, name: 'A', weight: 0.5, progress: 0);
      await _insertSubGoal(dao,
          goalId: goalId, name: 'B', weight: 0.5, progress: 0);
      final progress = await dao.calculateWeightedProgress(goalId);
      expect(progress, 0);
    });

    test('all sub-goals at 100 progress yields 100', () async {
      await _insertSubGoal(dao,
          goalId: goalId, name: 'A', weight: 0.5, progress: 100);
      await _insertSubGoal(dao,
          goalId: goalId, name: 'B', weight: 0.5, progress: 100);
      final progress = await dao.calculateWeightedProgress(goalId);
      expect(progress, 100);
    });

    test('result is always clamped to [0, 100]', () async {
      // Edge case: floating-point rounding might push slightly above 100
      await _insertSubGoal(dao,
          goalId: goalId, weight: 1.0, progress: 100);
      final progress = await dao.calculateWeightedProgress(goalId);
      expect(progress, inInclusiveRange(0, 100));
    });
  });

  // ---------------------------------------------------------------------------
  // GoalMilestones CRUD
  // ---------------------------------------------------------------------------

  group('GoalsDao — GoalMilestones CRUD', () {
    late int goalId;

    setUp(() async {
      goalId = await _insertGoal(dao);
    });

    test('insertMilestone returns id > 0', () async {
      final id = await _insertMilestone(dao, goalId: goalId);
      expect(id, greaterThan(0));
    });

    test('getMilestoneById returns inserted milestone', () async {
      final id = await _insertMilestone(
          dao, goalId: goalId, name: 'Primer hito');
      final milestone = await dao.getMilestoneById(id);
      expect(milestone, isNotNull);
      expect(milestone!.name, 'Primer hito');
    });

    test('getMilestoneById returns null for unknown id', () async {
      final milestone = await dao.getMilestoneById(9999);
      expect(milestone, isNull);
    });

    test('completeMilestone sets isCompleted = true and completedAt', () async {
      final id = await _insertMilestone(dao, goalId: goalId);
      await dao.completeMilestone(id);
      final milestone = await dao.getMilestoneById(id);
      expect(milestone!.isCompleted, isTrue);
      expect(milestone.completedAt, isNotNull);
    });

    test('getMilestonesForGoal returns all milestones for goal', () async {
      await _insertMilestone(dao,
          goalId: goalId, name: 'Hito 1', targetProgress: 25, sortOrder: 0);
      await _insertMilestone(dao,
          goalId: goalId, name: 'Hito 2', targetProgress: 50, sortOrder: 1);
      await _insertMilestone(dao,
          goalId: goalId, name: 'Hito 3', targetProgress: 75, sortOrder: 2);
      final milestones = await dao.getMilestonesForGoal(goalId);
      expect(milestones.length, 3);
    });

    test('getMilestonesForGoal orders by sortOrder then targetProgress', () async {
      await _insertMilestone(dao,
          goalId: goalId, name: 'B', targetProgress: 75, sortOrder: 1);
      await _insertMilestone(dao,
          goalId: goalId, name: 'A', targetProgress: 25, sortOrder: 0);
      final milestones = await dao.getMilestonesForGoal(goalId);
      expect(milestones.first.name, 'A');
      expect(milestones.last.name, 'B');
    });

    test('deleteMilestone removes milestone', () async {
      final id = await _insertMilestone(dao, goalId: goalId);
      await dao.deleteMilestone(id);
      final milestone = await dao.getMilestoneById(id);
      expect(milestone, isNull);
    });
  });
}
