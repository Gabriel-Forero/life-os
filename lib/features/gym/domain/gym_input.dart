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

  final String exerciseId;
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
    this.heightCm,
    this.bodyFatPercent,
    this.muscleMassKg,
    this.bodyWaterPercent,
    this.waistCm,
    this.chestCm,
    this.armCm,
    this.neckCm,
    this.shouldersCm,
    this.forearmCm,
    this.thighCm,
    this.calfCm,
    this.hipCm,
    this.photoFrontPath,
    this.photoSidePath,
    this.photoBackPath,
    this.note,
  });

  final double? weightKg;
  final double? heightCm;
  final double? bodyFatPercent;
  final double? muscleMassKg;
  final double? bodyWaterPercent;
  final double? waistCm;
  final double? chestCm;
  final double? armCm;
  final double? neckCm;
  final double? shouldersCm;
  final double? forearmCm;
  final double? thighCm;
  final double? calfCm;
  final double? hipCm;
  final String? photoFrontPath;
  final String? photoSidePath;
  final String? photoBackPath;
  final String? note;

  bool get hasAnyValue =>
      weightKg != null ||
      heightCm != null ||
      bodyFatPercent != null ||
      muscleMassKg != null ||
      bodyWaterPercent != null ||
      waistCm != null ||
      chestCm != null ||
      armCm != null ||
      neckCm != null ||
      shouldersCm != null ||
      forearmCm != null ||
      thighCm != null ||
      calfCm != null ||
      hipCm != null;
}
