class WorkoutSetModel {
  const WorkoutSetModel({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.setNumber,
    required this.reps,
    this.weightKg,
    this.rir,
    required this.isWarmup,
    required this.createdAt,
  });

  final String id;
  final String workoutId;
  final String exerciseId;
  final int setNumber;
  final int reps;
  final double? weightKg;
  final int? rir;
  final bool isWarmup;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'workoutId': workoutId,
        'exerciseId': exerciseId,
        'setNumber': setNumber,
        'reps': reps,
        'weightKg': weightKg,
        'rir': rir,
        'isWarmup': isWarmup,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WorkoutSetModel.fromMap(Map<String, dynamic> map) =>
      WorkoutSetModel(
        id: map['id'] as String,
        workoutId: map['workoutId'] as String,
        exerciseId: map['exerciseId'] as String,
        setNumber: map['setNumber'] as int,
        reps: map['reps'] as int,
        weightKg: map['weightKg'] as double?,
        rir: map['rir'] as int?,
        isWarmup: map['isWarmup'] as bool,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
