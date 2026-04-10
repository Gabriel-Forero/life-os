class GoalMilestoneModel {
  const GoalMilestoneModel({
    required this.id,
    required this.goalId,
    required this.name,
    this.targetDate,
    required this.targetProgress,
    required this.isCompleted,
    this.completedAt,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String goalId;
  final String name;
  final DateTime? targetDate;
  final int targetProgress; // 0–100
  final bool isCompleted;
  final DateTime? completedAt;
  final int sortOrder;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'goalId': goalId,
        'name': name,
        'targetDate': targetDate?.toIso8601String(),
        'targetProgress': targetProgress,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GoalMilestoneModel.fromMap(Map<String, dynamic> map) =>
      GoalMilestoneModel(
        id: map['id'] as String,
        goalId: map['goalId'] as String,
        name: map['name'] as String,
        targetDate: map['targetDate'] != null
            ? DateTime.parse(map['targetDate'] as String)
            : null,
        targetProgress: map['targetProgress'] as int? ?? 0,
        isCompleted: map['isCompleted'] as bool? ?? false,
        completedAt: map['completedAt'] != null
            ? DateTime.parse(map['completedAt'] as String)
            : null,
        sortOrder: map['sortOrder'] as int? ?? 0,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
