import 'package:life_os/features/goals/domain/models/goal_milestone_model.dart';
import 'package:life_os/features/goals/domain/models/life_goal_model.dart';
import 'package:life_os/features/goals/domain/models/sub_goal_model.dart';

abstract class GoalsRepository {
  // --- LifeGoals CRUD ---

  Future<String> insertGoal({
    required String name,
    String? description,
    required String category,
    required String icon,
    required int color,
    DateTime? targetDate,
    required String status,
    required int progress,
    required DateTime createdAt,
    required DateTime updatedAt,
  });

  Future<void> updateGoal(LifeGoalModel goal);

  Future<void> updateGoalProgress(String goalId, int progress);

  Future<void> updateGoalStatus(String goalId, String status);

  Future<void> deleteGoal(String goalId);

  Future<LifeGoalModel?> getGoalById(String goalId);

  Stream<LifeGoalModel?> watchGoal(String goalId);

  Stream<List<LifeGoalModel>> watchAllGoals();

  Stream<List<LifeGoalModel>> watchGoalsByCategory(String category);

  Future<List<LifeGoalModel>> getAllGoals();

  // --- SubGoals CRUD ---

  Future<String> insertSubGoal({
    required String goalId,
    required String name,
    String? description,
    required double weight,
    required int progress,
    String? linkedModule,
    int? linkedEntityId,
    required bool isOverridden,
    required int sortOrder,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
  });

  Future<void> updateSubGoal(SubGoalModel subGoal);

  Future<void> updateSubGoalProgress(
    String subGoalId,
    int progress, {
    bool? isOverridden,
  });

  Future<void> deleteSubGoal(String subGoalId);

  Future<SubGoalModel?> getSubGoalById(String subGoalId);

  Future<List<SubGoalModel>> getSubGoalsForGoal(String goalId);

  Stream<List<SubGoalModel>> watchSubGoals(String goalId);

  Future<List<SubGoalModel>> getSubGoalsLinkedTo(
    String module,
    int entityId,
  );

  // --- Weighted Progress ---

  Future<int> calculateWeightedProgress(String goalId);

  // --- GoalMilestones CRUD ---

  Future<String> insertMilestone({
    required String goalId,
    required String name,
    DateTime? targetDate,
    required int targetProgress,
    required bool isCompleted,
    DateTime? completedAt,
    required int sortOrder,
    required DateTime createdAt,
  });

  Future<void> completeMilestone(String milestoneId);

  Future<void> deleteMilestone(String milestoneId);

  Future<GoalMilestoneModel?> getMilestoneById(String milestoneId);

  Future<List<GoalMilestoneModel>> getMilestonesForGoal(String goalId);

  Stream<List<GoalMilestoneModel>> watchMilestones(String goalId);
}
