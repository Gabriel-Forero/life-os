class SubGoalModel {
  const SubGoalModel({
    required this.id,
    required this.goalId,
    required this.name,
    this.description,
    required this.weight,
    required this.progress,
    this.linkedModule,
    this.linkedEntityId,
    required this.isOverridden,
    required this.sortOrder,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String goalId;
  final String name;
  final String? description;
  final double weight; // 0.0–1.0
  final int progress; // 0–100
  final String? linkedModule; // habits / sleep / mental
  final int? linkedEntityId;
  final bool isOverridden;
  final int sortOrder;
  final String status; // active / completed
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'goalId': goalId,
        'name': name,
        'description': description,
        'weight': weight,
        'progress': progress,
        'linkedModule': linkedModule,
        'linkedEntityId': linkedEntityId,
        'isOverridden': isOverridden,
        'sortOrder': sortOrder,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SubGoalModel.fromMap(Map<String, dynamic> map) => SubGoalModel(
        id: map['id'] as String,
        goalId: map['goalId'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        weight: (map['weight'] as num).toDouble(),
        progress: map['progress'] as int? ?? 0,
        linkedModule: map['linkedModule'] as String?,
        linkedEntityId: map['linkedEntityId'] as int?,
        isOverridden: map['isOverridden'] as bool? ?? false,
        sortOrder: map['sortOrder'] as int? ?? 0,
        status: map['status'] as String? ?? 'active',
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
