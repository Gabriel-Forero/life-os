class WorkoutModel {
  const WorkoutModel({
    required this.id,
    this.routineId,
    required this.startedAt,
    this.finishedAt,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String? routineId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? note;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'routineId': routineId,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WorkoutModel.fromMap(Map<String, dynamic> map) => WorkoutModel(
        id: map['id'] as String,
        routineId: map['routineId'] as String?,
        startedAt: DateTime.parse(map['startedAt'] as String),
        finishedAt: map['finishedAt'] != null
            ? DateTime.parse(map['finishedAt'] as String)
            : null,
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
