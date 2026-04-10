import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/goals/data/goals_repository.dart';
import 'package:life_os/features/goals/database/goals_dao.dart';
import 'package:life_os/features/goals/domain/models/goal_milestone_model.dart';
import 'package:life_os/features/goals/domain/models/life_goal_model.dart';
import 'package:life_os/features/goals/domain/models/sub_goal_model.dart';

class DriftGoalsRepository implements GoalsRepository {
  DriftGoalsRepository({required this.dao});

  final GoalsDao dao;

  // --- Mapping helpers ---

  static LifeGoalModel _toGoalModel(LifeGoal row) => LifeGoalModel(
        id: row.id.toString(),
        name: row.name,
        description: row.description,
        category: row.category,
        icon: row.icon,
        color: row.color,
        targetDate: row.targetDate,
        status: row.status,
        progress: row.progress,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static SubGoalModel _toSubGoalModel(SubGoal row) => SubGoalModel(
        id: row.id.toString(),
        goalId: row.goalId.toString(),
        name: row.name,
        description: row.description,
        weight: row.weight,
        progress: row.progress,
        linkedModule: row.linkedModule,
        linkedEntityId: row.linkedEntityId,
        isOverridden: row.isOverridden,
        sortOrder: row.sortOrder,
        status: row.status,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static GoalMilestoneModel _toMilestoneModel(GoalMilestone row) =>
      GoalMilestoneModel(
        id: row.id.toString(),
        goalId: row.goalId.toString(),
        name: row.name,
        targetDate: row.targetDate,
        targetProgress: row.targetProgress,
        isCompleted: row.isCompleted,
        completedAt: row.completedAt,
        sortOrder: row.sortOrder,
        createdAt: row.createdAt,
      );

  // --- LifeGoals CRUD ---

  @override
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
  }) async {
    final id = await dao.insertGoal(LifeGoalsCompanion.insert(
      name: name,
      description: Value(description),
      category: category,
      icon: icon,
      color: Value(color),
      targetDate: Value(targetDate),
      status: Value(status),
      progress: Value(progress),
      createdAt: createdAt,
      updatedAt: updatedAt,
    ));
    return id.toString();
  }

  @override
  Future<void> updateGoal(LifeGoalModel goal) async {
    final intId = int.tryParse(goal.id);
    if (intId == null) return;
    final driftGoal = LifeGoal(
      id: intId,
      name: goal.name,
      description: goal.description,
      category: goal.category,
      icon: goal.icon,
      color: goal.color,
      targetDate: goal.targetDate,
      status: goal.status,
      progress: goal.progress,
      createdAt: goal.createdAt,
      updatedAt: goal.updatedAt,
    );
    await dao.updateGoal(driftGoal);
  }

  @override
  Future<void> updateGoalProgress(String goalId, int progress) async {
    final intId = int.tryParse(goalId);
    if (intId == null) return;
    await dao.updateGoalProgress(intId, progress);
  }

  @override
  Future<void> updateGoalStatus(String goalId, String status) async {
    final intId = int.tryParse(goalId);
    if (intId == null) return;
    await dao.updateGoalStatus(intId, status);
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    final intId = int.tryParse(goalId);
    if (intId == null) return;
    await dao.deleteGoal(intId);
  }

  @override
  Future<LifeGoalModel?> getGoalById(String goalId) async {
    final intId = int.tryParse(goalId);
    if (intId == null) return null;
    final row = await dao.getGoalById(intId);
    return row != null ? _toGoalModel(row) : null;
  }

  @override
  Stream<LifeGoalModel?> watchGoal(String goalId) {
    final intId = int.tryParse(goalId);
    if (intId == null) return Stream.value(null);
    return dao.watchGoal(intId).map((row) => row != null ? _toGoalModel(row) : null);
  }

  @override
  Stream<List<LifeGoalModel>> watchAllGoals() {
    return dao.watchAllGoals().map((rows) => rows.map(_toGoalModel).toList());
  }

  @override
  Stream<List<LifeGoalModel>> watchGoalsByCategory(String category) {
    return dao
        .watchGoalsByCategory(category)
        .map((rows) => rows.map(_toGoalModel).toList());
  }

  @override
  Future<List<LifeGoalModel>> getAllGoals() async {
    final rows = await dao.getAllGoals();
    return rows.map(_toGoalModel).toList();
  }

  // --- SubGoals CRUD ---

  @override
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
  }) async {
    final intGoalId = int.parse(goalId);
    final id = await dao.insertSubGoal(SubGoalsCompanion.insert(
      goalId: intGoalId,
      name: name,
      description: Value(description),
      weight: weight,
      progress: Value(progress),
      linkedModule: Value(linkedModule),
      linkedEntityId: Value(linkedEntityId),
      isOverridden: Value(isOverridden),
      sortOrder: Value(sortOrder),
      status: Value(status),
      createdAt: createdAt,
      updatedAt: updatedAt,
    ));
    return id.toString();
  }

  @override
  Future<void> updateSubGoal(SubGoalModel subGoal) async {
    final intId = int.tryParse(subGoal.id);
    if (intId == null) return;
    final driftSubGoal = SubGoal(
      id: intId,
      goalId: int.parse(subGoal.goalId),
      name: subGoal.name,
      description: subGoal.description,
      weight: subGoal.weight,
      progress: subGoal.progress,
      linkedModule: subGoal.linkedModule,
      linkedEntityId: subGoal.linkedEntityId,
      isOverridden: subGoal.isOverridden,
      sortOrder: subGoal.sortOrder,
      status: subGoal.status,
      createdAt: subGoal.createdAt,
      updatedAt: subGoal.updatedAt,
    );
    await dao.updateSubGoal(driftSubGoal);
  }

  @override
  Future<void> updateSubGoalProgress(
    String subGoalId,
    int progress, {
    bool? isOverridden,
  }) async {
    final intId = int.tryParse(subGoalId);
    if (intId == null) return;
    await dao.updateSubGoalProgress(intId, progress, isOverridden: isOverridden);
  }

  @override
  Future<void> deleteSubGoal(String subGoalId) async {
    final intId = int.tryParse(subGoalId);
    if (intId == null) return;
    await dao.deleteSubGoal(intId);
  }

  @override
  Future<SubGoalModel?> getSubGoalById(String subGoalId) async {
    final intId = int.tryParse(subGoalId);
    if (intId == null) return null;
    final row = await dao.getSubGoalById(intId);
    return row != null ? _toSubGoalModel(row) : null;
  }

  @override
  Future<List<SubGoalModel>> getSubGoalsForGoal(String goalId) async {
    final intId = int.tryParse(goalId);
    if (intId == null) return [];
    final rows = await dao.getSubGoalsForGoal(intId);
    return rows.map(_toSubGoalModel).toList();
  }

  @override
  Stream<List<SubGoalModel>> watchSubGoals(String goalId) {
    final intId = int.tryParse(goalId);
    if (intId == null) return Stream.value([]);
    return dao
        .watchSubGoals(intId)
        .map((rows) => rows.map(_toSubGoalModel).toList());
  }

  @override
  Future<List<SubGoalModel>> getSubGoalsLinkedTo(
    String module,
    int entityId,
  ) async {
    final rows = await dao.getSubGoalsLinkedTo(module, entityId);
    return rows.map(_toSubGoalModel).toList();
  }

  // --- Weighted Progress ---

  @override
  Future<int> calculateWeightedProgress(String goalId) async {
    final intId = int.tryParse(goalId);
    if (intId == null) return 0;
    return dao.calculateWeightedProgress(intId);
  }

  // --- GoalMilestones CRUD ---

  @override
  Future<String> insertMilestone({
    required String goalId,
    required String name,
    DateTime? targetDate,
    required int targetProgress,
    required bool isCompleted,
    DateTime? completedAt,
    required int sortOrder,
    required DateTime createdAt,
  }) async {
    final intGoalId = int.parse(goalId);
    final id = await dao.insertMilestone(GoalMilestonesCompanion.insert(
      goalId: intGoalId,
      name: name,
      targetDate: Value(targetDate),
      targetProgress: Value(targetProgress),
      isCompleted: Value(isCompleted),
      completedAt: Value(completedAt),
      sortOrder: Value(sortOrder),
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Future<void> completeMilestone(String milestoneId) async {
    final intId = int.tryParse(milestoneId);
    if (intId == null) return;
    await dao.completeMilestone(intId);
  }

  @override
  Future<void> deleteMilestone(String milestoneId) async {
    final intId = int.tryParse(milestoneId);
    if (intId == null) return;
    await dao.deleteMilestone(intId);
  }

  @override
  Future<GoalMilestoneModel?> getMilestoneById(String milestoneId) async {
    final intId = int.tryParse(milestoneId);
    if (intId == null) return null;
    final row = await dao.getMilestoneById(intId);
    return row != null ? _toMilestoneModel(row) : null;
  }

  @override
  Future<List<GoalMilestoneModel>> getMilestonesForGoal(String goalId) async {
    final intId = int.tryParse(goalId);
    if (intId == null) return [];
    final rows = await dao.getMilestonesForGoal(intId);
    return rows.map(_toMilestoneModel).toList();
  }

  @override
  Stream<List<GoalMilestoneModel>> watchMilestones(String goalId) {
    final intId = int.tryParse(goalId);
    if (intId == null) return Stream.value([]);
    return dao
        .watchMilestones(intId)
        .map((rows) => rows.map(_toMilestoneModel).toList());
  }
}
