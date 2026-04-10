import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/dashboard/data/dashboard_repository.dart';
import 'package:life_os/features/dashboard/database/dashboard_dao.dart';
import 'package:life_os/features/dashboard/domain/models/day_score_config_model.dart';
import 'package:life_os/features/dashboard/domain/models/day_score_model.dart';
import 'package:life_os/features/dashboard/domain/models/life_snapshot_model.dart';
import 'package:life_os/features/dashboard/domain/models/score_component_model.dart';

class DriftDashboardRepository implements DashboardRepository {
  DriftDashboardRepository({required this.dao});

  final DashboardDao dao;

  // ---------------------------------------------------------------------------
  // Mapping helpers
  // ---------------------------------------------------------------------------

  static DayScoreModel _toDayScoreModel(DayScore row) => DayScoreModel(
        id: row.id.toString(),
        date: row.date,
        totalScore: row.totalScore,
        calculatedAt: row.calculatedAt,
        createdAt: row.createdAt,
      );

  static DayScoreConfigModel _toConfigModel(DayScoreConfig row) =>
      DayScoreConfigModel(
        id: row.id.toString(),
        moduleKey: row.moduleKey,
        weight: row.weight,
        isEnabled: row.isEnabled,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static ScoreComponentModel _toComponentModel(ScoreComponent row) =>
      ScoreComponentModel(
        id: row.id.toString(),
        dayScoreId: row.dayScoreId.toString(),
        moduleKey: row.moduleKey,
        rawValue: row.rawValue,
        weight: row.weight,
        weightedScore: row.weightedScore,
        createdAt: row.createdAt,
      );

  static LifeSnapshotModel _toSnapshotModel(LifeSnapshot row) =>
      LifeSnapshotModel(
        id: row.id.toString(),
        date: row.date,
        totalScore: row.totalScore,
        metricsJson: row.metricsJson,
        createdAt: row.createdAt,
      );

  // ---------------------------------------------------------------------------
  // DayScoreConfigs
  // ---------------------------------------------------------------------------

  @override
  Future<void> seedDefaultConfigsIfEmpty() => dao.seedDefaultConfigsIfEmpty();

  @override
  Future<List<DayScoreConfigModel>> getScoreConfigs() async {
    final rows = await dao.getScoreConfigs();
    return rows.map(_toConfigModel).toList();
  }

  @override
  Stream<List<DayScoreConfigModel>> watchScoreConfigs() {
    return dao
        .watchScoreConfigs()
        .map((rows) => rows.map(_toConfigModel).toList());
  }

  @override
  Future<void> updateScoreConfig(
    String id, {
    required double weight,
    required bool isEnabled,
  }) {
    final intId = int.parse(id);
    return dao.updateScoreConfig(intId, weight: weight, isEnabled: isEnabled);
  }

  @override
  Future<void> updateWeightByKey(String moduleKey, double weight) =>
      dao.updateWeightByKey(moduleKey, weight);

  // ---------------------------------------------------------------------------
  // DayScores
  // ---------------------------------------------------------------------------

  @override
  Future<void> upsertDayScore({
    required DateTime date,
    required int totalScore,
    required DateTime calculatedAt,
    required List<ScoreComponentInput> components,
  }) =>
      dao.upsertDayScore(
        date: date,
        totalScore: totalScore,
        calculatedAt: calculatedAt,
        components: components,
      );

  @override
  Future<DayScoreModel?> getDayScoreForDate(DateTime date) async {
    final row = await dao.getDayScoreForDate(date);
    return row != null ? _toDayScoreModel(row) : null;
  }

  @override
  Future<List<ScoreComponentModel>> getComponentsForDayScore(
      String dayScoreId) async {
    final intId = int.parse(dayScoreId);
    final rows = await dao.getComponentsForDayScore(intId);
    return rows.map(_toComponentModel).toList();
  }

  @override
  Future<List<DayScoreModel>> getRecentDayScores({int limit = 30}) async {
    final rows = await dao.getRecentDayScores(limit: limit);
    return rows.map(_toDayScoreModel).toList();
  }

  @override
  Stream<List<DayScoreModel>> watchRecentDayScores({int limit = 30}) {
    return dao
        .watchRecentDayScores(limit: limit)
        .map((rows) => rows.map(_toDayScoreModel).toList());
  }

  // ---------------------------------------------------------------------------
  // LifeSnapshots
  // ---------------------------------------------------------------------------

  @override
  Future<void> insertLifeSnapshot({
    required DateTime date,
    required int totalScore,
    required Map<String, dynamic> metrics,
  }) =>
      dao.insertLifeSnapshot(
        date: date,
        totalScore: totalScore,
        metrics: metrics,
      );

  @override
  Future<LifeSnapshotModel?> getSnapshotForDate(DateTime date) async {
    final row = await dao.getSnapshotForDate(date);
    return row != null ? _toSnapshotModel(row) : null;
  }

  @override
  Future<List<LifeSnapshotModel>> getAllSnapshots() async {
    final rows = await dao.getAllSnapshots();
    return rows.map(_toSnapshotModel).toList();
  }

  @override
  Future<void> insertValuationSnapshot({
    required String moduleKey,
    required Map<String, dynamic> data,
  }) =>
      dao.insertValuationSnapshot(moduleKey: moduleKey, data: data);
}
