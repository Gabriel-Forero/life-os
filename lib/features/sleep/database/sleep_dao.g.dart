// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_dao.dart';

// ignore_for_file: type=lint
mixin _$SleepDaoMixin on DatabaseAccessor<AppDatabase> {
  $SleepLogsTable get sleepLogs => attachedDatabase.sleepLogs;
  $SleepInterruptionsTable get sleepInterruptions =>
      attachedDatabase.sleepInterruptions;
  $EnergyLogsTable get energyLogs => attachedDatabase.energyLogs;
  SleepDaoManager get managers => SleepDaoManager(this);
}

class SleepDaoManager {
  final _$SleepDaoMixin _db;
  SleepDaoManager(this._db);
  $$SleepLogsTableTableManager get sleepLogs =>
      $$SleepLogsTableTableManager(_db.attachedDatabase, _db.sleepLogs);
  $$SleepInterruptionsTableTableManager get sleepInterruptions =>
      $$SleepInterruptionsTableTableManager(
        _db.attachedDatabase,
        _db.sleepInterruptions,
      );
  $$EnergyLogsTableTableManager get energyLogs =>
      $$EnergyLogsTableTableManager(_db.attachedDatabase, _db.energyLogs);
}
