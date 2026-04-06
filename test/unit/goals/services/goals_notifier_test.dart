import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/goals/database/goals_dao.dart';
import 'package:life_os/features/goals/domain/goals_input.dart';
import 'package:life_os/features/goals/providers/goals_notifier.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<int> _addGoalRaw(
  GoalsDao dao, {
  String name = 'Test Goal',
  String category = 'personal',
  int progress = 0,
}) {
  final now = DateTime.now();
  return dao.insertGoal(LifeGoalsCompanion.insert(
    name: name,
    description: const Value(null),
    category: category,
    icon: 'track_changes',
    color: const Value(0xFF06B6D4),
    targetDate: const Value(null),
    status: const Value('active'),
    progress: Value(progress),
    createdAt: now,
    updatedAt: now,
  ));
}

Future<int> _addSubGoalRaw(
  GoalsDao dao, {
  required int goalId,
  String name = 'Sub',
  double weight = 1.0,
  int progress = 0,
  String? linkedModule,
  int? linkedEntityId,
  bool isOverridden = false,
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
    sortOrder: const Value(0),
    status: const Value('active'),
    createdAt: now,
    updatedAt: now,
  ));
}

Future<int> _addMilestoneRaw(
  GoalsDao dao, {
  required int goalId,
  String name = 'Hito',
  int targetProgress = 50,
  bool isCompleted = false,
}) {
  final now = DateTime.now();
  return dao.insertMilestone(GoalMilestonesCompanion.insert(
    goalId: goalId,
    name: name,
    targetDate: const Value(null),
    targetProgress: Value(targetProgress),
    isCompleted: Value(isCompleted),
    completedAt: const Value(null),
    sortOrder: const Value(0),
    createdAt: now,
  ));
}

void main() {
  late AppDatabase db;
  late GoalsDao dao;
  late EventBus eventBus;
  late GoalsNotifier notifier;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.goalsDao;
    eventBus = EventBus();
    notifier = GoalsNotifier(dao: dao, eventBus: eventBus);
  });

  tearDown(() async {
    notifier.dispose();
    eventBus.dispose();
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // addGoal
  // ---------------------------------------------------------------------------

  group('GoalsNotifier — addGoal', () {
    test('creates goal and returns id', () async {
      final result = await notifier.addGoal(const GoalInput(
        name: 'Correr maraton',
        category: 'salud',
        icon: 'track_changes',
      ));
      expect(result, isA<Success<int>>());
      expect(result.valueOrNull, greaterThan(0));
    });

    test('rejects empty name', () async {
      final result = await notifier.addGoal(const GoalInput(
        name: '',
        category: 'personal',
        icon: 'track_changes',
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects whitespace-only name', () async {
      final result = await notifier.addGoal(const GoalInput(
        name: '   ',
        category: 'personal',
        icon: 'track_changes',
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects name exceeding 100 chars', () async {
      final result = await notifier.addGoal(GoalInput(
        name: 'a' * 101,
        category: 'personal',
        icon: 'track_changes',
      ));
      expect(result, isA<Failure<int>>());
    });

    test('accepts name exactly 100 chars', () async {
      final result = await notifier.addGoal(GoalInput(
        name: 'a' * 100,
        category: 'personal',
        icon: 'track_changes',
      ));
      expect(result, isA<Success<int>>());
    });

    test('rejects invalid category', () async {
      final result = await notifier.addGoal(const GoalInput(
        name: 'Meta',
        category: 'invalid_category',
        icon: 'track_changes',
      ));
      expect(result, isA<Failure<int>>());
    });

    test('accepts all valid categories', () async {
      for (final cat in GoalCategory.values) {
        final result = await notifier.addGoal(GoalInput(
          name: 'Meta ${cat.name}',
          category: cat.name,
          icon: 'track_changes',
        ));
        expect(result, isA<Success<int>>(),
            reason: 'Category ${cat.name} should be valid');
      }
    });

    test('rejects description exceeding 500 chars', () async {
      final result = await notifier.addGoal(GoalInput(
        name: 'Meta',
        description: 'd' * 501,
        category: 'personal',
        icon: 'track_changes',
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects targetDate in the past', () async {
      final result = await notifier.addGoal(GoalInput(
        name: 'Meta',
        category: 'personal',
        icon: 'track_changes',
        targetDate: DateTime(2000, 1, 1),
      ));
      expect(result, isA<Failure<int>>());
    });

    test('accepts future targetDate', () async {
      final result = await notifier.addGoal(GoalInput(
        name: 'Meta',
        category: 'personal',
        icon: 'track_changes',
        targetDate: DateTime.now().add(const Duration(days: 30)),
      ));
      expect(result, isA<Success<int>>());
    });
  });

  // ---------------------------------------------------------------------------
  // addSubGoal + weight validation
  // ---------------------------------------------------------------------------

  group('GoalsNotifier — addSubGoal', () {
    late int goalId;

    setUp(() async {
      goalId = await _addGoalRaw(dao);
    });

    test('adds sub-goal with weight 1.0 to empty goal', () async {
      final result = await notifier.addSubGoal(SubGoalInput(
        goalId: goalId,
        name: 'Sub-meta',
        weight: 1.0,
      ));
      expect(result, isA<Success<int>>());
    });

    test('rejects weight = 0', () async {
      final result = await notifier.addSubGoal(SubGoalInput(
        goalId: goalId,
        name: 'Sub-meta',
        weight: 0.0,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects weight > 1.0', () async {
      final result = await notifier.addSubGoal(SubGoalInput(
        goalId: goalId,
        name: 'Sub-meta',
        weight: 1.1,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects sub-goal when cumulative weight would exceed 1.0', () async {
      // First sub-goal with 0.6 is OK (partial sum allowed)
      await notifier.addSubGoal(SubGoalInput(
        goalId: goalId,
        name: 'Primera',
        weight: 0.6,
      ));
      // Adding 0.5 would make total 1.1 — exceeds 1.0, should fail
      final result = await notifier.addSubGoal(SubGoalInput(
        goalId: goalId,
        name: 'Segunda',
        weight: 0.5,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('accepts two sub-goals summing exactly to 1.0', () async {
      final r1 = await notifier.addSubGoal(SubGoalInput(
        goalId: goalId,
        name: 'Primera',
        weight: 0.4,
      ));
      // At this point total is 0.4, adding 0.6 makes 1.0 — should succeed
      final r2 = await notifier.addSubGoal(SubGoalInput(
        goalId: goalId,
        name: 'Segunda',
        weight: 0.6,
      ));
      expect(r1, isA<Success<int>>());
      expect(r2, isA<Success<int>>());
    });

    test('rejects empty sub-goal name', () async {
      final result = await notifier.addSubGoal(SubGoalInput(
        goalId: goalId,
        name: '',
        weight: 1.0,
      ));
      expect(result, isA<Failure<int>>());
    });
  });

  // ---------------------------------------------------------------------------
  // updateSubGoalProgress
  // ---------------------------------------------------------------------------

  group('GoalsNotifier — updateSubGoalProgress', () {
    late int goalId;
    late int subGoalId;

    setUp(() async {
      goalId = await _addGoalRaw(dao);
      subGoalId = await _addSubGoalRaw(dao, goalId: goalId, weight: 1.0);
    });

    test('updates progress and marks as overridden', () async {
      final result = await notifier.updateSubGoalProgress(subGoalId, 50);
      expect(result, isA<Success<void>>());
      final sub = await dao.getSubGoalById(subGoalId);
      expect(sub!.progress, 50);
      expect(sub.isOverridden, isTrue);
    });

    test('rejects progress < 0', () async {
      final result = await notifier.updateSubGoalProgress(subGoalId, -1);
      expect(result, isA<Failure<void>>());
    });

    test('rejects progress > 100', () async {
      final result = await notifier.updateSubGoalProgress(subGoalId, 101);
      expect(result, isA<Failure<void>>());
    });

    test('rejects unknown sub-goal id', () async {
      final result = await notifier.updateSubGoalProgress(9999, 50);
      expect(result, isA<Failure<void>>());
    });

    test('recalculates and persists goal progress after update', () async {
      await notifier.updateSubGoalProgress(subGoalId, 80);
      final goal = await dao.getGoalById(goalId);
      expect(goal!.progress, 80);
    });

    test('emits GoalProgressUpdatedEvent after progress update', () async {
      final events = <GoalProgressUpdatedEvent>[];
      eventBus.on<GoalProgressUpdatedEvent>().listen(events.add);

      await notifier.updateSubGoalProgress(subGoalId, 60);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(events, hasLength(1));
      expect(events.first.goalId, goalId);
      expect(events.first.progress, 60);
    });
  });

  // ---------------------------------------------------------------------------
  // addMilestone
  // ---------------------------------------------------------------------------

  group('GoalsNotifier — addMilestone', () {
    late int goalId;

    setUp(() async {
      goalId = await _addGoalRaw(dao);
    });

    test('adds milestone and returns id', () async {
      final result = await notifier.addMilestone(MilestoneInput(
        goalId: goalId,
        name: 'Primer hito',
        targetProgress: 25,
      ));
      expect(result, isA<Success<int>>());
    });

    test('rejects empty milestone name', () async {
      final result = await notifier.addMilestone(MilestoneInput(
        goalId: goalId,
        name: '',
        targetProgress: 25,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects targetProgress < 0', () async {
      final result = await notifier.addMilestone(MilestoneInput(
        goalId: goalId,
        name: 'Hito',
        targetProgress: -1,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects targetProgress > 100', () async {
      final result = await notifier.addMilestone(MilestoneInput(
        goalId: goalId,
        name: 'Hito',
        targetProgress: 101,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects past targetDate', () async {
      final result = await notifier.addMilestone(MilestoneInput(
        goalId: goalId,
        name: 'Hito',
        targetProgress: 50,
        targetDate: DateTime(2000, 1, 1),
      ));
      expect(result, isA<Failure<int>>());
    });
  });

  // ---------------------------------------------------------------------------
  // completeMilestone
  // ---------------------------------------------------------------------------

  group('GoalsNotifier — completeMilestone', () {
    late int goalId;
    late int milestoneId;

    setUp(() async {
      goalId = await _addGoalRaw(dao);
      milestoneId =
          await _addMilestoneRaw(dao, goalId: goalId, name: 'Hito');
    });

    test('completes milestone successfully', () async {
      final result = await notifier.completeMilestone(milestoneId);
      expect(result, isA<Success<void>>());
      final milestone = await dao.getMilestoneById(milestoneId);
      expect(milestone!.isCompleted, isTrue);
    });

    test('rejects completing already-completed milestone', () async {
      await notifier.completeMilestone(milestoneId);
      final result = await notifier.completeMilestone(milestoneId);
      expect(result, isA<Failure<void>>());
    });

    test('rejects completing non-existent milestone', () async {
      final result = await notifier.completeMilestone(9999);
      expect(result, isA<Failure<void>>());
    });
  });

  // ---------------------------------------------------------------------------
  // Auto-progress from EventBus
  // ---------------------------------------------------------------------------

  group('GoalsNotifier — auto-progress from EventBus', () {
    late int goalId;

    setUp(() async {
      goalId = await _addGoalRaw(dao);
    });

    test('HabitCheckedInEvent increments linked sub-goal progress by 10', () async {
      final habitEntityId = 5;
      await _addSubGoalRaw(dao,
          goalId: goalId,
          name: 'Habit sub',
          weight: 1.0,
          linkedModule: 'habits',
          linkedEntityId: habitEntityId,
          isOverridden: false);

      eventBus.emit(HabitCheckedInEvent(
        habitId: habitEntityId,
        habitName: 'Ejercicio',
        isCompleted: true,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final subs = await dao.getSubGoalsForGoal(goalId);
      expect(subs.first.progress, 10);
    });

    test('HabitCheckedInEvent does not update isOverridden sub-goals', () async {
      final habitEntityId = 7;
      await _addSubGoalRaw(dao,
          goalId: goalId,
          name: 'Overridden',
          weight: 1.0,
          linkedModule: 'habits',
          linkedEntityId: habitEntityId,
          isOverridden: true,
          progress: 50);

      eventBus.emit(HabitCheckedInEvent(
        habitId: habitEntityId,
        habitName: 'Ejercicio',
        isCompleted: true,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final subs = await dao.getSubGoalsForGoal(goalId);
      expect(subs.first.progress, 50); // unchanged
    });

    test('SleepLogSavedEvent maps sleepScore to sub-goal progress', () async {
      final sleepLogId = 3;
      await _addSubGoalRaw(dao,
          goalId: goalId,
          name: 'Sleep sub',
          weight: 1.0,
          linkedModule: 'sleep',
          linkedEntityId: sleepLogId,
          isOverridden: false);

      eventBus.emit(SleepLogSavedEvent(
        sleepLogId: sleepLogId,
        sleepScore: 85,
        hoursSlept: 8.0,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final subs = await dao.getSubGoalsForGoal(goalId);
      expect(subs.first.progress, 85);
    });

    test('MoodLoggedEvent maps mood level to sub-goal progress', () async {
      final moodLogId = 9;
      await _addSubGoalRaw(dao,
          goalId: goalId,
          name: 'Mood sub',
          weight: 1.0,
          linkedModule: 'mental',
          linkedEntityId: moodLogId,
          isOverridden: false);

      eventBus.emit(MoodLoggedEvent(
        moodLogId: moodLogId,
        level: 75,
        tags: ['calma'],
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final subs = await dao.getSubGoalsForGoal(goalId);
      expect(subs.first.progress, 75);
    });

    test('auto-progress emits GoalProgressUpdatedEvent', () async {
      final habitEntityId = 11;
      await _addSubGoalRaw(dao,
          goalId: goalId,
          name: 'Habit sub',
          weight: 1.0,
          linkedModule: 'habits',
          linkedEntityId: habitEntityId);

      final events = <GoalProgressUpdatedEvent>[];
      eventBus.on<GoalProgressUpdatedEvent>().listen(events.add);

      eventBus.emit(HabitCheckedInEvent(
        habitId: habitEntityId,
        habitName: 'Test',
        isCompleted: true,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(events, hasLength(1));
      expect(events.first.goalId, goalId);
    });

    test('auto-progress is capped at 100', () async {
      final habitEntityId = 13;
      await _addSubGoalRaw(dao,
          goalId: goalId,
          name: 'Near full',
          weight: 1.0,
          linkedModule: 'habits',
          linkedEntityId: habitEntityId,
          progress: 95);

      eventBus.emit(HabitCheckedInEvent(
        habitId: habitEntityId,
        habitName: 'Test',
        isCompleted: true,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final subs = await dao.getSubGoalsForGoal(goalId);
      expect(subs.first.progress, 100); // capped, not 105
    });
  });

  // ---------------------------------------------------------------------------
  // calculateWeightedProgress
  // ---------------------------------------------------------------------------

  group('GoalsNotifier — calculateWeightedProgress', () {
    test('delegates to dao and returns correct value', () async {
      final goalId = await _addGoalRaw(dao);
      await _addSubGoalRaw(dao,
          goalId: goalId, name: 'A', weight: 0.6, progress: 50);
      await _addSubGoalRaw(dao,
          goalId: goalId, name: 'B', weight: 0.4, progress: 100);
      final progress = await notifier.calculateWeightedProgress(goalId);
      // (0.6 * 50) + (0.4 * 100) = 30 + 40 = 70
      expect(progress, 70);
    });
  });
}
