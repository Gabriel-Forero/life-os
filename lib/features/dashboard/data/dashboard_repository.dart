import 'package:life_os/features/dashboard/database/dashboard_dao.dart';
import 'package:life_os/features/dashboard/domain/models/day_score_config_model.dart';
import 'package:life_os/features/dashboard/domain/models/day_score_model.dart';
import 'package:life_os/features/dashboard/domain/models/life_snapshot_model.dart';
import 'package:life_os/features/dashboard/domain/models/score_component_model.dart';

abstract class DashboardRepository {
  // ---------------------------------------------------------------------------
  // DayScoreConfigs
  // ---------------------------------------------------------------------------

  Future<void> seedDefaultConfigsIfEmpty();

  Future<List<DayScoreConfigModel>> getScoreConfigs();

  Stream<List<DayScoreConfigModel>> watchScoreConfigs();

  Future<void> updateScoreConfig(
    String id, {
    required double weight,
    required bool isEnabled,
  });

  Future<void> updateWeightByKey(String moduleKey, double weight);

  // ---------------------------------------------------------------------------
  // DayScores
  // ---------------------------------------------------------------------------

  Future<void> upsertDayScore({
    required DateTime date,
    required int totalScore,
    required DateTime calculatedAt,
    required List<ScoreComponentInput> components,
  });

  Future<DayScoreModel?> getDayScoreForDate(DateTime date);

  Future<List<ScoreComponentModel>> getComponentsForDayScore(String dayScoreId);

  Future<List<DayScoreModel>> getRecentDayScores({int limit = 30});

  Stream<List<DayScoreModel>> watchRecentDayScores({int limit = 30});

  // ---------------------------------------------------------------------------
  // LifeSnapshots
  // ---------------------------------------------------------------------------

  Future<void> insertLifeSnapshot({
    required DateTime date,
    required int totalScore,
    required Map<String, dynamic> metrics,
  });

  Future<LifeSnapshotModel?> getSnapshotForDate(DateTime date);

  Future<List<LifeSnapshotModel>> getAllSnapshots();

  Future<void> insertValuationSnapshot({
    required String moduleKey,
    required Map<String, dynamic> data,
  });
}
