import 'dart:async';

import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/goals/data/goals_repository.dart';
import 'package:life_os/features/goals/domain/goals_input.dart';
import 'package:life_os/features/goals/domain/goals_validators.dart';
import 'package:life_os/features/goals/domain/models/life_goal_model.dart';

class GoalsNotifier {
  GoalsNotifier({required this.repository, required this.eventBus}) {
    _subscribeToEvents();
  }

  final GoalsRepository repository;
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

  Future<Result<String>> addGoal(GoalInput input) async {
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
      final id = await repository.insertGoal(
        name: nameResult.valueOrNull!,
        description: descResult.valueOrNull,
        category: catResult.valueOrNull!,
        icon: input.icon,
        color: input.color,
        targetDate: dateResult.valueOrNull,
        status: 'active',
        progress: 0,
        createdAt: now,
        updatedAt: now,
      );
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al crear el objetivo',
        debugMessage: 'insertGoal failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> editGoal(LifeGoalModel current, GoalInput input) async {
    final nameResult = validateGoalName(input.name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    final descResult = validateGoalDescription(input.description);
    if (descResult.isFailure) return Failure(descResult.failureOrNull!);

    final catResult = validateGoalCategory(input.category);
    if (catResult.isFailure) return Failure(catResult.failureOrNull!);

    final dateResult = validateGoalTargetDate(input.targetDate);
    if (dateResult.isFailure) return Failure(dateResult.failureOrNull!);

    try {
      await repository.updateGoal(current.copyWith(
        name: nameResult.valueOrNull!,
        description: descResult.valueOrNull,
        category: catResult.valueOrNull!,
        icon: input.icon,
        color: input.color,
        targetDate: dateResult.valueOrNull,
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

  Future<Result<void>> changeGoalStatus(String goalId, String status) async {
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
      await repository.updateGoalStatus(goalId, status);
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

  Future<Result<String>> addSubGoal(SubGoalInput input) async {
    final nameResult = validateSubGoalName(input.name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    final descResult = validateSubGoalDescription(input.description);
    if (descResult.isFailure) return Failure(descResult.failureOrNull!);

    final weightResult = validateSubGoalWeight(input.weight);
    if (weightResult.isFailure) return Failure(weightResult.failureOrNull!);

    // Check total weight sum
    final existing = await repository.getSubGoalsForGoal(input.goalId);
    final existingWeights = existing.map((s) => s.weight).toList();
    final sumResult = validateWeightSum(existingWeights, input.weight);
    if (sumResult.isFailure) return Failure(sumResult.failureOrNull!);

    try {
      final now = DateTime.now();
      final id = await repository.insertSubGoal(
        goalId: input.goalId,
        name: nameResult.valueOrNull!,
        description: descResult.valueOrNull,
        weight: input.weight,
        progress: 0,
        linkedModule: input.linkedModule,
        linkedEntityId: input.linkedEntityId,
        isOverridden: false,
        sortOrder: input.sortOrder,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );
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
    String subGoalId,
    int progress,
  ) async {
    final progressResult = validateSubGoalProgress(progress);
    if (progressResult.isFailure) return Failure(progressResult.failureOrNull!);

    final subGoal = await repository.getSubGoalById(subGoalId);
    if (subGoal == null) {
      return const Failure(NotFoundFailure(
        userMessage: 'Sub-objetivo no encontrado',
        debugMessage: 'SubGoal not found',
        entityType: 'SubGoal',
        entityId: 'unknown',
      ));
    }

    try {
      await repository.updateSubGoalProgress(
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

  Future<Result<String>> addMilestone(MilestoneInput input) async {
    final nameResult = validateMilestoneName(input.name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    final progressResult =
        validateMilestoneTargetProgress(input.targetProgress);
    if (progressResult.isFailure) return Failure(progressResult.failureOrNull!);

    final dateResult = validateMilestoneTargetDate(input.targetDate);
    if (dateResult.isFailure) return Failure(dateResult.failureOrNull!);

    try {
      final now = DateTime.now();
      final id = await repository.insertMilestone(
        goalId: input.goalId,
        name: nameResult.valueOrNull!,
        targetDate: dateResult.valueOrNull,
        targetProgress: progressResult.valueOrNull!,
        isCompleted: false,
        completedAt: null,
        sortOrder: input.sortOrder,
        createdAt: now,
      );
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al crear el hito',
        debugMessage: 'insertMilestone failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> completeMilestone(String milestoneId) async {
    final milestone = await repository.getMilestoneById(milestoneId);
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
      await repository.completeMilestone(milestoneId);
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

  Future<int> calculateWeightedProgress(String goalId) =>
      repository.calculateWeightedProgress(goalId);

  Future<void> _recalculateAndPersistGoalProgress(String goalId) async {
    final progress = await repository.calculateWeightedProgress(goalId);
    await repository.updateGoalProgress(goalId, progress);
    eventBus.emit(GoalProgressUpdatedEvent(
      goalId: int.tryParse(goalId) ?? 0,
      progress: progress,
    ));
  }

  // ---------------------------------------------------------------------------
  // Auto-progress from EventBus
  // ---------------------------------------------------------------------------

  Future<void> onHabitCheckedIn(HabitCheckedInEvent event) async {
    final linked = await repository.getSubGoalsLinkedTo('habits', event.habitId);
    for (final subGoal in linked) {
      if (subGoal.isOverridden) continue;
      final newProgress = (subGoal.progress + 10).clamp(0, 100);
      await repository.updateSubGoalProgress(subGoal.id, newProgress);
      await _recalculateAndPersistGoalProgress(subGoal.goalId);
    }
  }

  Future<void> onSleepLogSaved(SleepLogSavedEvent event) async {
    final linked = await repository.getSubGoalsLinkedTo('sleep', event.sleepLogId);
    for (final subGoal in linked) {
      if (subGoal.isOverridden) continue;
      final newProgress = event.sleepScore.clamp(0, 100);
      await repository.updateSubGoalProgress(subGoal.id, newProgress);
      await _recalculateAndPersistGoalProgress(subGoal.goalId);
    }
  }

  Future<void> onMoodLogged(MoodLoggedEvent event) async {
    final linked = await repository.getSubGoalsLinkedTo('mental', event.moodLogId);
    for (final subGoal in linked) {
      if (subGoal.isOverridden) continue;
      final newProgress = event.level.clamp(0, 100);
      await repository.updateSubGoalProgress(subGoal.id, newProgress);
      await _recalculateAndPersistGoalProgress(subGoal.goalId);
    }
  }
}
