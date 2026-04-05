import 'dart:async';

import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/goals/database/goals_dao.dart';
import 'package:life_os/features/goals/domain/goals_input.dart';
import 'package:life_os/features/goals/domain/goals_validators.dart';

class GoalsNotifier {
  GoalsNotifier({required this.dao, required this.eventBus}) {
    _subscribeToEvents();
  }

  final GoalsDao dao;
  final EventBus eventBus;

  final _subscriptions = <StreamSubscription<dynamic>>[];

  // ---------------------------------------------------------------------------
  // EventBus subscriptions (auto-progress stubs)
  // ---------------------------------------------------------------------------

  void _subscribeToEvents() {
    _subscriptions.add(
      eventBus.on<HabitCheckedInEvent>().listen(onHabitCheckedIn),
    );
    _subscriptions.add(
      eventBus.on<SleepLogSavedEvent>().listen(onSleepLogSaved),
    );
    _subscriptions.add(
      eventBus.on<MoodLoggedEvent>().listen(onMoodLogged),
    );
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  // ---------------------------------------------------------------------------
  // Goal CRUD
  // ---------------------------------------------------------------------------

  Future<Result<int>> addGoal(GoalInput input) async {
    final nameResult = validateGoalName(input.name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    final descResult = validateGoalDescription(input.description);
    if (descResult.isFailure) return Failure(descResult.failureOrNull!);

    final catResult = validateGoalCategory(input.category);
    if (catResult.isFailure) return Failure(catResult.failureOrNull!);

    final dateResult = validateGoalTargetDate(input.targetDate);
    if (dateResult.isFailure) return Failure(dateResult.failureOrNull!);

    try {
      final now = DateTime.now();
      final id = await dao.insertGoal(LifeGoalsCompanion.insert(
        name: nameResult.valueOrNull!,
        description: Value(descResult.valueOrNull),
        category: catResult.valueOrNull!,
        icon: input.icon,
        color: Value(input.color),
        targetDate: Value(dateResult.valueOrNull),
        status: const Value('active'),
        progress: const Value(0),
        createdAt: now,
        updatedAt: now,
      ));
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al crear el objetivo',
        debugMessage: 'insertGoal failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> editGoal(LifeGoal current, GoalInput input) async {
    final nameResult = validateGoalName(input.name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    final descResult = validateGoalDescription(input.description);
    if (descResult.isFailure) return Failure(descResult.failureOrNull!);

    final catResult = validateGoalCategory(input.category);
    if (catResult.isFailure) return Failure(catResult.failureOrNull!);

    final dateResult = validateGoalTargetDate(input.targetDate);
    if (dateResult.isFailure) return Failure(dateResult.failureOrNull!);

    try {
      await dao.updateGoal(current.copyWith(
        name: nameResult.valueOrNull!,
        description: Value(descResult.valueOrNull),
        category: catResult.valueOrNull!,
        icon: input.icon,
        color: input.color,
        targetDate: Value(dateResult.valueOrNull),
        updatedAt: DateTime.now(),
      ));
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al actualizar el objetivo',
        debugMessage: 'updateGoal failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> changeGoalStatus(int goalId, String status) async {
    const validStatuses = {'active', 'completed', 'paused', 'abandoned'};
    if (!validStatuses.contains(status)) {
      return Failure(ValidationFailure(
        userMessage: 'Estado no valido',
        debugMessage: 'status "$status" not in $validStatuses',
        field: 'status',
        value: status,
      ));
    }
    try {
      await dao.updateGoalStatus(goalId, status);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al cambiar el estado del objetivo',
        debugMessage: 'updateGoalStatus failed: $e',
        originalError: e,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Sub-Goal operations
  // ---------------------------------------------------------------------------

  Future<Result<int>> addSubGoal(SubGoalInput input) async {
    final nameResult = validateSubGoalName(input.name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    final descResult = validateSubGoalDescription(input.description);
    if (descResult.isFailure) return Failure(descResult.failureOrNull!);

    final weightResult = validateSubGoalWeight(input.weight);
    if (weightResult.isFailure) return Failure(weightResult.failureOrNull!);

    // Check total weight sum
    final existing = await dao.getSubGoalsForGoal(input.goalId);
    final existingWeights = existing.map((s) => s.weight).toList();
    final sumResult = validateWeightSum(existingWeights, input.weight);
    if (sumResult.isFailure) return Failure(sumResult.failureOrNull!);

    try {
      final now = DateTime.now();
      final id = await dao.insertSubGoal(SubGoalsCompanion.insert(
        goalId: input.goalId,
        name: nameResult.valueOrNull!,
        description: Value(descResult.valueOrNull),
        weight: input.weight,
        progress: const Value(0),
        linkedModule: Value(input.linkedModule),
        linkedEntityId: Value(input.linkedEntityId),
        isOverridden: const Value(false),
        sortOrder: Value(input.sortOrder),
        status: const Value('active'),
        createdAt: now,
        updatedAt: now,
      ));
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al crear el sub-objetivo',
        debugMessage: 'insertSubGoal failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> updateSubGoalProgress(
    int subGoalId,
    int progress,
  ) async {
    final progressResult = validateSubGoalProgress(progress);
    if (progressResult.isFailure) return Failure(progressResult.failureOrNull!);

    final subGoal = await dao.getSubGoalById(subGoalId);
    if (subGoal == null) {
      return const Failure(NotFoundFailure(
        userMessage: 'Sub-objetivo no encontrado',
        debugMessage: 'SubGoal not found',
        entityType: 'SubGoal',
        entityId: 'unknown',
      ));
    }

    try {
      await dao.updateSubGoalProgress(
        subGoalId,
        progressResult.valueOrNull!,
        isOverridden: true,
      );

      await _recalculateAndPersistGoalProgress(subGoal.goalId);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al actualizar el progreso del sub-objetivo',
        debugMessage: 'updateSubGoalProgress failed: $e',
        originalError: e,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Milestone operations
  // ---------------------------------------------------------------------------

  Future<Result<int>> addMilestone(MilestoneInput input) async {
    final nameResult = validateMilestoneName(input.name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    final progressResult =
        validateMilestoneTargetProgress(input.targetProgress);
    if (progressResult.isFailure) return Failure(progressResult.failureOrNull!);

    final dateResult = validateMilestoneTargetDate(input.targetDate);
    if (dateResult.isFailure) return Failure(dateResult.failureOrNull!);

    try {
      final now = DateTime.now();
      final id = await dao.insertMilestone(GoalMilestonesCompanion.insert(
        goalId: input.goalId,
        name: nameResult.valueOrNull!,
        targetDate: Value(dateResult.valueOrNull),
        targetProgress: Value(progressResult.valueOrNull!),
        isCompleted: const Value(false),
        completedAt: const Value(null),
        sortOrder: Value(input.sortOrder),
        createdAt: now,
      ));
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al crear el hito',
        debugMessage: 'insertMilestone failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> completeMilestone(int milestoneId) async {
    final milestone = await dao.getMilestoneById(milestoneId);
    if (milestone == null) {
      return Failure(NotFoundFailure(
        userMessage: 'Hito no encontrado',
        debugMessage: 'GoalMilestone not found for id $milestoneId',
        entityType: 'GoalMilestone',
        entityId: milestoneId,
      ));
    }
    if (milestone.isCompleted) {
      return const Failure(ValidationFailure(
        userMessage: 'Este hito ya fue completado',
        debugMessage: 'milestone already completed',
        field: 'isCompleted',
      ));
    }

    try {
      await dao.completeMilestone(milestoneId);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al completar el hito',
        debugMessage: 'completeMilestone failed: $e',
        originalError: e,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Weighted progress calculation
  // ---------------------------------------------------------------------------

  Future<int> calculateWeightedProgress(int goalId) =>
      dao.calculateWeightedProgress(goalId);

  Future<void> _recalculateAndPersistGoalProgress(int goalId) async {
    final progress = await dao.calculateWeightedProgress(goalId);
    await dao.updateGoalProgress(goalId, progress);
    eventBus.emit(GoalProgressUpdatedEvent(goalId: goalId, progress: progress));
  }

  // ---------------------------------------------------------------------------
  // Auto-progress from EventBus
  // ---------------------------------------------------------------------------

  Future<void> onHabitCheckedIn(HabitCheckedInEvent event) async {
    final linked = await dao.getSubGoalsLinkedTo('habits', event.habitId);
    for (final subGoal in linked) {
      if (subGoal.isOverridden) continue;
      // Each habit check-in contributes 10 progress points, capped at 100
      final newProgress = (subGoal.progress + 10).clamp(0, 100);
      await dao.updateSubGoalProgress(subGoal.id, newProgress);
      await _recalculateAndPersistGoalProgress(subGoal.goalId);
    }
  }

  Future<void> onSleepLogSaved(SleepLogSavedEvent event) async {
    final linked = await dao.getSubGoalsLinkedTo('sleep', event.sleepLogId);
    for (final subGoal in linked) {
      if (subGoal.isOverridden) continue;
      // Sleep score maps directly 0–100
      final newProgress = event.sleepScore.clamp(0, 100);
      await dao.updateSubGoalProgress(subGoal.id, newProgress);
      await _recalculateAndPersistGoalProgress(subGoal.goalId);
    }
  }

  Future<void> onMoodLogged(MoodLoggedEvent event) async {
    final linked = await dao.getSubGoalsLinkedTo('mental', event.moodLogId);
    for (final subGoal in linked) {
      if (subGoal.isOverridden) continue;
      // Mood level maps directly 0–100
      final newProgress = event.level.clamp(0, 100);
      await dao.updateSubGoalProgress(subGoal.id, newProgress);
      await _recalculateAndPersistGoalProgress(subGoal.goalId);
    }
  }
}
