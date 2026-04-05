import 'package:drift/drift.dart';

class Exercises extends Table {
  @override
  String get tableName => 'exercises';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100).unique()();
  TextColumn get primaryMuscle => text()();
  TextColumn get secondaryMuscles => text().nullable()(); // JSON list
  TextColumn get equipment => text().nullable()();
  TextColumn get instructions => text().nullable().withLength(max: 500)();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isDownloaded =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

class Routines extends Table {
  @override
  String get tableName => 'routines';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable().withLength(max: 200)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class RoutineExercises extends Table {
  @override
  String get tableName => 'routine_exercises';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer().references(Routines, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  /// Encodes day and position: dayNumber * 1000 + positionWithinDay.
  /// Single-day routines use dayNumber=1, so sortOrder starts at 1000.
  IntColumn get sortOrder => integer().withDefault(const Constant(1000))();
  /// 1-based day number within the program (1 for single-day routines).
  IntColumn get dayNumber => integer().withDefault(const Constant(1))();
  /// Optional label for the day, e.g. "Push", "Pull", "Piernas".
  TextColumn get dayName => text().nullable().withLength(max: 30)();
  IntColumn get defaultSets => integer().withDefault(const Constant(3))();
  IntColumn get defaultReps => integer().withDefault(const Constant(10))();
  RealColumn get defaultWeightKg => real().nullable()();
  IntColumn get restSeconds => integer().withDefault(const Constant(90))();
  DateTimeColumn get createdAt => dateTime()();
}

class Workouts extends Table {
  @override
  String get tableName => 'workouts';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get note => text().nullable().withLength(max: 200)();
  DateTimeColumn get createdAt => dateTime()();
}

class WorkoutSets extends Table {
  @override
  String get tableName => 'workout_sets';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get setNumber => integer()();
  IntColumn get reps => integer()();
  RealColumn get weightKg => real().nullable()();
  IntColumn get rir => integer().nullable()();
  BoolColumn get isWarmup =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

class BodyMeasurements extends Table {
  @override
  String get tableName => 'body_measurements';

  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  // Existing
  RealColumn get weightKg => real().nullable()();
  RealColumn get bodyFatPercent => real().nullable()();
  RealColumn get waistCm => real().nullable()();
  RealColumn get chestCm => real().nullable()();
  RealColumn get armCm => real().nullable()();
  // New body composition fields
  RealColumn get neckCm => real().nullable()();
  RealColumn get shouldersCm => real().nullable()();
  RealColumn get forearmCm => real().nullable()();
  RealColumn get thighCm => real().nullable()();
  RealColumn get calfCm => real().nullable()();
  RealColumn get hipCm => real().nullable()();
  RealColumn get muscleMassKg => real().nullable()();
  RealColumn get bodyWaterPercent => real().nullable()();
  // Height needed for BMI calculation
  RealColumn get heightCm => real().nullable()();
  // Progress photos stored as file paths
  TextColumn get photoFrontPath => text().nullable()();
  TextColumn get photoSidePath => text().nullable()();
  TextColumn get photoBackPath => text().nullable()();
  // Notes
  TextColumn get note => text().nullable().withLength(max: 200)();
  DateTimeColumn get createdAt => dateTime()();
}
