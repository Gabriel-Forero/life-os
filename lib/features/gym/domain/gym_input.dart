class SetInput {
  const SetInput({
    required this.reps,
    this.weightKg,
    this.rir,
    this.isWarmup = false,
  });

  final int reps;
  final double? weightKg;
  final int? rir;
  final bool isWarmup;
}

class RoutineInput {
  const RoutineInput({
    required this.name,
    this.description,
    required this.exercises,
  });

  final String name;
  final String? description;
  final List<RoutineExerciseInput> exercises;
}

class RoutineExerciseInput {
  const RoutineExerciseInput({
    required this.exerciseId,
    this.dayNumber = 1,
    this.dayName,
    this.defaultSets = 3,
    this.defaultReps = 10,
    this.defaultWeightKg,
    this.restSeconds = 90,
  });

  final int exerciseId;
  /// 1-based day number. Single-day routines always use 1.
  final int dayNumber;
  /// Optional label for the day, e.g. "Push", "Pull".
  final String? dayName;
  final int defaultSets;
  final int defaultReps;
  final double? defaultWeightKg;
  final int restSeconds;
}

class MeasurementInput {
  const MeasurementInput({
    this.weightKg,
    this.bodyFatPercent,
    this.waistCm,
    this.chestCm,
    this.armCm,
  });

  final double? weightKg;
  final double? bodyFatPercent;
  final double? waistCm;
  final double? chestCm;
  final double? armCm;

  bool get hasAnyValue =>
      weightKg != null ||
      bodyFatPercent != null ||
      waistCm != null ||
      chestCm != null ||
      armCm != null;
}
