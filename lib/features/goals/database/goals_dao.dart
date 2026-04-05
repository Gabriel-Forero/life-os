import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/goals/database/goals_tables.dart';

part 'goals_dao.g.dart';

@DriftAccessor(tables: [LifeGoals, SubGoals, GoalMilestones])
class GoalsDao extends DatabaseAccessor<AppDatabase> with _$GoalsDaoMixin {
  GoalsDao(super.db);

  // ---------------------------------------------------------------------------
  // LifeGoals CRUD
  // ---------------------------------------------------------------------------

  Future<int> insertGoal(LifeGoalsCompanion entry) =>
      into(lifeGoals).insert(entry);

  Future<void> updateGoal(LifeGoal entry) =>
      (update(lifeGoals)..where((g) => g.id.equals(entry.id))).write(
        LifeGoalsCompanion(
          name: Value(entry.name),
          description: Value(entry.description),
          category: Value(entry.category),
          icon: Value(entry.icon),
          color: Value(entry.color),
          targetDate: Value(entry.targetDate),
          status: Value(entry.status),
          progress: Value(entry.progress),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateGoalProgress(int goalId, int progress) =>
      (update(lifeGoals)..where((g) => g.id.equals(goalId))).write(
        LifeGoalsCompanion(
          progress: Value(progress),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateGoalStatus(int goalId, String status) =>
      (update(lifeGoals)..where((g) => g.id.equals(goalId))).write(
        LifeGoalsCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteGoal(int goalId) async {
    await (delete(goalMilestones)
          ..where((m) => m.goalId.equals(goalId)))
        .go();
    await (delete(subGoals)..where((s) => s.goalId.equals(goalId))).go();
    await (delete(lifeGoals)..where((g) => g.id.equals(goalId))).go();
  }

  Future<LifeGoal?> getGoalById(int goalId) =>
      (select(lifeGoals)..where((g) => g.id.equals(goalId))).getSingleOrNull();

  Stream<LifeGoal?> watchGoal(int goalId) =>
      (select(lifeGoals)..where((g) => g.id.equals(goalId))).watchSingleOrNull();

  Stream<List<LifeGoal>> watchAllGoals() =>
      (select(lifeGoals)
            ..orderBy([
              (g) => OrderingTerm.asc(g.status),
              (g) => OrderingTerm.asc(g.targetDate),
              (g) => OrderingTerm.asc(g.name),
            ]))
          .watch();

  Stream<List<LifeGoal>> watchGoalsByCategory(String category) =>
      (select(lifeGoals)
            ..where((g) => g.category.equals(category))
            ..orderBy([
              (g) => OrderingTerm.asc(g.status),
              (g) => OrderingTerm.asc(g.targetDate),
            ]))
          .watch();

  Future<List<LifeGoal>> getAllGoals() => select(lifeGoals).get();

  // ---------------------------------------------------------------------------
  // SubGoals CRUD
  // ---------------------------------------------------------------------------

  Future<int> insertSubGoal(SubGoalsCompanion entry) =>
      into(subGoals).insert(entry);

  Future<void> updateSubGoal(SubGoal entry) =>
      (update(subGoals)..where((s) => s.id.equals(entry.id))).write(
        SubGoalsCompanion(
          name: Value(entry.name),
          description: Value(entry.description),
          weight: Value(entry.weight),
          progress: Value(entry.progress),
          linkedModule: Value(entry.linkedModule),
          linkedEntityId: Value(entry.linkedEntityId),
          isOverridden: Value(entry.isOverridden),
          sortOrder: Value(entry.sortOrder),
          status: Value(entry.status),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateSubGoalProgress(
    int subGoalId,
    int progress, {
    bool? isOverridden,
  }) =>
      (update(subGoals)..where((s) => s.id.equals(subGoalId))).write(
        SubGoalsCompanion(
          progress: Value(progress),
          isOverridden:
              isOverridden != null ? Value(isOverridden) : const Value.absent(),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteSubGoal(int subGoalId) =>
      (delete(subGoals)..where((s) => s.id.equals(subGoalId))).go();

  Future<SubGoal?> getSubGoalById(int subGoalId) =>
      (select(subGoals)..where((s) => s.id.equals(subGoalId)))
          .getSingleOrNull();

  Future<List<SubGoal>> getSubGoalsForGoal(int goalId) =>
      (select(subGoals)
            ..where((s) => s.goalId.equals(goalId))
            ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
          .get();

  Stream<List<SubGoal>> watchSubGoals(int goalId) =>
      (select(subGoals)
            ..where((s) => s.goalId.equals(goalId))
            ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
          .watch();

  /// Returns sub-goals linked to a specific module and entity.
  Future<List<SubGoal>> getSubGoalsLinkedTo(
    String module,
    int entityId,
  ) =>
      (select(subGoals)
            ..where(
              (s) =>
                  s.linkedModule.equals(module) &
                  s.linkedEntityId.equals(entityId),
            ))
          .get();

  // ---------------------------------------------------------------------------
  // Weighted Progress Calculation
  // ---------------------------------------------------------------------------

  /// Calculates weighted progress for a goal from its sub-goals.
  /// Returns 0 if there are no sub-goals.
  Future<int> calculateWeightedProgress(int goalId) async {
    final subs = await getSubGoalsForGoal(goalId);
    if (subs.isEmpty) return 0;

    double weighted = 0.0;
    for (final sub in subs) {
      weighted += sub.weight * sub.progress;
    }
    return weighted.round().clamp(0, 100);
  }

  // ---------------------------------------------------------------------------
  // GoalMilestones CRUD
  // ---------------------------------------------------------------------------

  Future<int> insertMilestone(GoalMilestonesCompanion entry) =>
      into(goalMilestones).insert(entry);

  Future<void> completeMilestone(int milestoneId) =>
      (update(goalMilestones)
            ..where((m) => m.id.equals(milestoneId)))
          .write(
        GoalMilestonesCompanion(
          isCompleted: const Value(true),
          completedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteMilestone(int milestoneId) =>
      (delete(goalMilestones)..where((m) => m.id.equals(milestoneId))).go();

  Future<GoalMilestone?> getMilestoneById(int milestoneId) =>
      (select(goalMilestones)
            ..where((m) => m.id.equals(milestoneId)))
          .getSingleOrNull();

  Future<List<GoalMilestone>> getMilestonesForGoal(int goalId) =>
      (select(goalMilestones)
            ..where((m) => m.goalId.equals(goalId))
            ..orderBy([
              (m) => OrderingTerm.asc(m.sortOrder),
              (m) => OrderingTerm.asc(m.targetProgress),
            ]))
          .get();

  Stream<List<GoalMilestone>> watchMilestones(int goalId) =>
      (select(goalMilestones)
            ..where((m) => m.goalId.equals(goalId))
            ..orderBy([
              (m) => OrderingTerm.asc(m.sortOrder),
              (m) => OrderingTerm.asc(m.targetProgress),
            ]))
          .watch();
}
