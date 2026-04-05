// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_dao.dart';

// ignore_for_file: type=lint
mixin _$DashboardDaoMixin on DatabaseAccessor<AppDatabase> {
  $DayScoresTable get dayScores => attachedDatabase.dayScores;
  $ScoreComponentsTable get scoreComponents => attachedDatabase.scoreComponents;
  $DayScoreConfigsTable get dayScoreConfigs => attachedDatabase.dayScoreConfigs;
  $LifeSnapshotsTable get lifeSnapshots => attachedDatabase.lifeSnapshots;
  DashboardDaoManager get managers => DashboardDaoManager(this);
}

class DashboardDaoManager {
  final _$DashboardDaoMixin _db;
  DashboardDaoManager(this._db);
  $$DayScoresTableTableManager get dayScores =>
      $$DayScoresTableTableManager(_db.attachedDatabase, _db.dayScores);
  $$ScoreComponentsTableTableManager get scoreComponents =>
      $$ScoreComponentsTableTableManager(
        _db.attachedDatabase,
        _db.scoreComponents,
      );
  $$DayScoreConfigsTableTableManager get dayScoreConfigs =>
      $$DayScoreConfigsTableTableManager(
        _db.attachedDatabase,
        _db.dayScoreConfigs,
      );
  $$LifeSnapshotsTableTableManager get lifeSnapshots =>
      $$LifeSnapshotsTableTableManager(_db.attachedDatabase, _db.lifeSnapshots);
}
