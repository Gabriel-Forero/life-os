class RoutineExerciseModel {
  const RoutineExerciseModel({
    required this.id,
    required this.routineId,
    required this.exerciseId,
    required this.sortOrder,
    required this.dayNumber,
    this.dayName,
    required this.defaultSets,
    required this.defaultReps,
    this.defaultWeightKg,
    required this.restSeconds,
    required this.createdAt,
  });

  final String id;
  final String routineId;
  final String exerciseId;
  final int sortOrder;
  final int dayNumber;
  final String? dayName;
  final int defaultSets;
  final int defaultReps;
  final double? defaultWeightKg;
  final int restSeconds;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'routineId': routineId,
        'exerciseId': exerciseId,
        'sortOrder': sortOrder,
        'dayNumber': dayNumber,
        'dayName': dayName,
        'defaultSets': defaultSets,
        'defaultReps': defaultReps,
        'defaultWeightKg': defaultWeightKg,
        'restSeconds': restSeconds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RoutineExerciseModel.fromMap(Map<String, dynamic> map) =>
      RoutineExerciseModel(
        id: map['id'] as String,
        routineId: map['routineId'] as String,
        exerciseId: map['exerciseId'] as String,
        sortOrder: map['sortOrder'] as int,
        dayNumber: map['dayNumber'] as int,
        dayName: map['dayName'] as String?,
        defaultSets: map['defaultSets'] as int,
        defaultReps: map['defaultReps'] as int,
        defaultWeightKg: map['defaultWeightKg'] as double?,
        restSeconds: map['restSeconds'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
