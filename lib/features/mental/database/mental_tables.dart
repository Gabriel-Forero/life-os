import 'package:drift/drift.dart';

class MoodLogs extends Table {
  @override
  String get tableName => 'mood_logs';

  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get valence => integer()(); // 1–5 (negative→positive)
  IntColumn get energy => integer()(); // 1–5 (low→high)
  TextColumn get tags => text().withDefault(const Constant(''))(); // comma-separated
  TextColumn get journalNote => text().withLength(max: 280).nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class BreathingSessions extends Table {
  @override
  String get tableName => 'breathing_sessions';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get techniqueName => text()(); // box / 4_7_8 / coherent
  IntColumn get durationSeconds => integer()(); // actual seconds breathed
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}
