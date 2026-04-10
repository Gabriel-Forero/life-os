class SavingsGoalModel {
  const SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetCents,
    required this.currentCents,
    this.deadline,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int targetCents;
  final int currentCents;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavingsGoalModel copyWith({
    String? name,
    int? targetCents,
    int? currentCents,
    Object? deadline = _sentinel,
    bool? isCompleted,
    DateTime? updatedAt,
  }) =>
      SavingsGoalModel(
        id: id,
        name: name ?? this.name,
        targetCents: targetCents ?? this.targetCents,
        currentCents: currentCents ?? this.currentCents,
        deadline:
            identical(deadline, _sentinel) ? this.deadline : deadline as DateTime?,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'targetCents': targetCents,
        'currentCents': currentCents,
        'deadline': deadline?.toIso8601String(),
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) =>
      SavingsGoalModel(
        id: map['id'] as String,
        name: map['name'] as String,
        targetCents: map['targetCents'] as int,
        currentCents: map['currentCents'] as int? ?? 0,
        deadline: map['deadline'] != null
            ? DateTime.parse(map['deadline'] as String)
            : null,
        isCompleted: map['isCompleted'] as bool? ?? false,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}

const _sentinel = Object();
