// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mental_dao.dart';

// ignore_for_file: type=lint
mixin _$MentalDaoMixin on DatabaseAccessor<AppDatabase> {
  $MoodLogsTable get moodLogs => attachedDatabase.moodLogs;
  $BreathingSessionsTable get breathingSessions =>
      attachedDatabase.breathingSessions;
  MentalDaoManager get managers => MentalDaoManager(this);
}

class MentalDaoManager {
  final _$MentalDaoMixin _db;
  MentalDaoManager(this._db);
  $$MoodLogsTableTableManager get moodLogs =>
      $$MoodLogsTableTableManager(_db.attachedDatabase, _db.moodLogs);
  $$BreathingSessionsTableTableManager get breathingSessions =>
      $$BreathingSessionsTableTableManager(
        _db.attachedDatabase,
        _db.breathingSessions,
      );
}
