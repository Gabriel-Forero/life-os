import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/dashboard/database/dashboard_tables.dart';

part 'dashboard_dao.g.dart';

@DriftAccessor(tables: [DayScores, ScoreComponents, DayScoreConfigs, LifeSnapshots])
class DashboardDao extends DatabaseAccessor<AppDatabase>
    with _$DashboardDaoMixin {
  DashboardDao(super.db);

  // ---------------------------------------------------------------------------
  // DayScoreConfigs — seed & CRUD
  // ---------------------------------------------------------------------------

  /// Seeds default configs for all modules if the table is empty.
  Future<void> seedDefaultConfigsIfEmpty() async {
    final count = await (selectOnly(dayScoreConfigs)
          ..addColumns([dayScoreConfigs.id.count()]))
        .map((row) => row.read(dayScoreConfigs.id.count()))
        .getSingle();

    if ((count ?? 0) > 0) return;

    final now = DateTime.now();
    const defaultModules = ['finance', 'gym', 'nutrition', 'habits'];
    for (final key in defaultModules) {
      await into(dayScoreConfigs).insert(
        DayScoreConfigsCompanion.insert(
          moduleKey: key,
          weight: const Value(1.0),
          isEnabled: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  /// Returns all score configs ordered by module key.
  Future<List<DayScoreConfig>> getScoreConfigs() =>
      (select(dayScoreConfigs)
            ..orderBy([(c) => OrderingTerm.asc(c.moduleKey)]))
          .get();

  /// Watches all score configs.
  Stream<List<DayScoreConfig>> watchScoreConfigs() =>
      (select(dayScoreConfigs)
            ..orderBy([(c) => OrderingTerm.asc(c.moduleKey)]))
          .watch();

  /// Updates weight and isEnabled for a module config.
  Future<void> updateScoreConfig(
    int id, {
    required double weight,
    required bool isEnabled,
  }) =>
      (update(dayScoreConfigs)..where((c) => c.id.equals(id))).write(
        DayScoreConfigsCompanion(
          weight: Value(weight),
          isEnabled: Value(isEnabled),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Updates only the weight for a module by key.
  Future<void> updateWeightByKey(String moduleKey, double weight) =>
      (update(dayScoreConfigs)
            ..where((c) => c.moduleKey.equals(moduleKey)))
          .write(
        DayScoreConfigsCompanion(
          weight: Value(weight),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // ---------------------------------------------------------------------------
  // DayScores — upsert & queries
  // ---------------------------------------------------------------------------

  /// Upserts a DayScore for the given date along with its components.
  ///
  /// If a row already exists for [date], updates `total_score` and
  /// `calculated_at`, then replaces all component rows.
  Future<void> upsertDayScore({
    required DateTime date,
    required int totalScore,
    required DateTime calculatedAt,
    required List<ScoreComponentInput> components,
  }) async {
    final dayDate = _normalizeDate(date);

    // Upsert the day_scores row
    int dayScoreId;
    final existing = await (select(dayScores)
          ..where((s) => s.date.equals(dayDate)))
        .getSingleOrNull();

    if (existing != null) {
      dayScoreId = existing.id;
      await (update(dayScores)..where((s) => s.id.equals(dayScoreId))).write(
        DayScoresCompanion(
          totalScore: Value(totalScore),
          calculatedAt: Value(calculatedAt),
        ),
      );
    } else {
      dayScoreId = await into(dayScores).insert(
        DayScoresCompanion.insert(
          date: dayDate,
          totalScore: totalScore,
          calculatedAt: calculatedAt,
          createdAt: DateTime.now(),
        ),
      );
    }

    // Replace components
    await (delete(scoreComponents)
          ..where((c) => c.dayScoreId.equals(dayScoreId)))
        .go();

    final now = DateTime.now();
    for (final comp in components) {
      await into(scoreComponents).insert(
        ScoreComponentsCompanion.insert(
          dayScoreId: dayScoreId,
          moduleKey: comp.moduleKey,
          rawValue: comp.rawValue,
          weight: comp.weight,
          weightedScore: comp.weightedScore,
          createdAt: now,
        ),
      );
    }
  }

  /// Returns the DayScore for the given date, or null if none exists.
  Future<DayScore?> getDayScoreForDate(DateTime date) {
    final dayDate = _normalizeDate(date);
    return (select(dayScores)..where((s) => s.date.equals(dayDate)))
        .getSingleOrNull();
  }

  /// Returns the score components for a given day_score_id.
  Future<List<ScoreComponent>> getComponentsForDayScore(int dayScoreId) =>
      (select(scoreComponents)
            ..where((c) => c.dayScoreId.equals(dayScoreId)))
          .get();

  /// Returns the last [limit] DayScore rows ordered by date descending.
  Future<List<DayScore>> getRecentDayScores({int limit = 30}) =>
      (select(dayScores)
            ..orderBy([(s) => OrderingTerm.desc(s.date)])
            ..limit(limit))
          .get();

  /// Watches day scores ordered by date descending.
  Stream<List<DayScore>> watchRecentDayScores({int limit = 30}) =>
      (select(dayScores)
            ..orderBy([(s) => OrderingTerm.desc(s.date)])
            ..limit(limit))
          .watch();

  // ---------------------------------------------------------------------------
  // LifeSnapshots — insert & queries
  // ---------------------------------------------------------------------------

  /// Inserts a life snapshot for [date]. No-ops if one already exists.
  Future<void> insertLifeSnapshot({
    required DateTime date,
    required int totalScore,
    required Map<String, dynamic> metrics,
  }) async {
    final dayDate = _normalizeDate(date);
    final existing = await getSnapshotForDate(dayDate);
    if (existing != null) return; // idempotent

    await into(lifeSnapshots).insert(
      LifeSnapshotsCompanion.insert(
        date: dayDate,
        totalScore: totalScore,
        metricsJson: jsonEncode(metrics),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Returns the snapshot for [date], or null if none exists.
  Future<LifeSnapshot?> getSnapshotForDate(DateTime date) {
    final dayDate = _normalizeDate(date);
    return (select(lifeSnapshots)..where((s) => s.date.equals(dayDate)))
        .getSingleOrNull();
  }

  /// Returns all snapshots ordered by date descending.
  Future<List<LifeSnapshot>> getAllSnapshots() =>
      (select(lifeSnapshots)
            ..orderBy([(s) => OrderingTerm.desc(s.date)]))
          .get();

  /// Inserts a manual valuation snapshot for a specific module.
  ///
  /// Unlike [insertLifeSnapshot], this method does NOT normalize to midnight
  /// and does NOT enforce uniqueness — multiple valuations per day are allowed.
  /// The [moduleKey] and [data] are stored inside the JSON blob so that the
  /// screen can filter by module.
  Future<void> insertValuationSnapshot({
    required String moduleKey,
    required Map<String, dynamic> data,
  }) async {
    final now = DateTime.now();
    await into(lifeSnapshots).insert(
      LifeSnapshotsCompanion.insert(
        date: now,
        totalScore: 0,
        metricsJson: jsonEncode({'moduleKey': moduleKey, 'data': data}),
        createdAt: now,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Normalizes a DateTime to midnight UTC (day boundary key).
  DateTime _normalizeDate(DateTime dt) =>
      DateTime.utc(dt.year, dt.month, dt.day);
}

/// Input model for a score component row (used by [DashboardDao.upsertDayScore]).
class ScoreComponentInput {
  const ScoreComponentInput({
    required this.moduleKey,
    required this.rawValue,
    required this.weight,
    required this.weightedScore,
  });

  final String moduleKey;
  final double rawValue;
  final double weight;
  final double weightedScore;
}
