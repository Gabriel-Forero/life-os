import 'package:drift/drift.dart';

class SleepLogs extends Table {
  @override
  String get tableName => 'sleep_logs';

  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get bedTime => dateTime()();
  DateTimeColumn get wakeTime => dateTime()();
  IntColumn get qualityRating => integer()(); // 1–5
  IntColumn get sleepScore => integer()(); // 0–100
  TextColumn get note => text().withLength(max: 200).nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class SleepInterruptions extends Table {
  @override
  String get tableName => 'sleep_interruptions';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get sleepLogId => integer().references(SleepLogs, #id)();
  DateTimeColumn get time => dateTime()();
  IntColumn get durationMinutes => integer()(); // >0
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class EnergyLogs extends Table {
  @override
  String get tableName => 'energy_logs';

  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get timeOfDay => text()(); // morning / afternoon / evening
  IntColumn get level => integer()(); // 1–10
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date, timeOfDay},
      ];
}
