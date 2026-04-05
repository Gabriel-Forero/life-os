import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// Table: day_scores
// ---------------------------------------------------------------------------

/// Stores the computed daily total score (0–100) for a given calendar day.
class DayScores extends Table {
  @override
  String get tableName => 'day_scores';

  IntColumn get id => integer().autoIncrement()();

  /// Stored as midnight UTC of the given day.
  DateTimeColumn get date => dateTime()();

  /// Weighted-average score, clamped to [0, 100].
  IntColumn get totalScore => integer()();

  /// Timestamp of the last calculation run.
  DateTimeColumn get calculatedAt => dateTime()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date},
      ];
}

// ---------------------------------------------------------------------------
// Table: score_components
// ---------------------------------------------------------------------------

/// Per-module breakdown row for a `DayScores` entry.
class ScoreComponents extends Table {
  @override
  String get tableName => 'score_components';

  IntColumn get id => integer().autoIncrement()();

  /// Foreign key → day_scores.id
  IntColumn get dayScoreId => integer().references(DayScores, #id)();

  /// Module identifier: 'finance' | 'gym' | 'nutrition' | 'habits'
  TextColumn get moduleKey => text()();

  /// Module's normalized score in [0.0, 100.0].
  RealColumn get rawValue => real()();

  /// Weight used in the calculation (> 0).
  RealColumn get weight => real()();

  /// rawValue × weight.
  RealColumn get weightedScore => real()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {dayScoreId, moduleKey},
      ];
}

// ---------------------------------------------------------------------------
// Table: day_score_configs
// ---------------------------------------------------------------------------

/// User-configurable weight and enable/disable per module.
class DayScoreConfigs extends Table {
  @override
  String get tableName => 'day_score_configs';

  IntColumn get id => integer().autoIncrement()();

  /// Unique module identifier.
  TextColumn get moduleKey => text().unique()();

  /// Relative weight in the score formula. Default = 1.0.
  RealColumn get weight => real().withDefault(const Constant(1.0))();

  /// Whether the module participates in score calculation.
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// ---------------------------------------------------------------------------
// Table: life_snapshots
// ---------------------------------------------------------------------------

/// Immutable daily snapshot of all module metrics for historical review.
/// Generated lazily on first app open of a new day (for the previous day).
class LifeSnapshots extends Table {
  @override
  String get tableName => 'life_snapshots';

  IntColumn get id => integer().autoIncrement()();

  /// Snapshot date (midnight UTC of the captured day).
  DateTimeColumn get date => dateTime()();

  /// Total DayScore on that day.
  IntColumn get totalScore => integer()();

  /// JSON blob: { "finance": {...}, "gym": {...}, ... }
  TextColumn get metricsJson => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date},
      ];
}
