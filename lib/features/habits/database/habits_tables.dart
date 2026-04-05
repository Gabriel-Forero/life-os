import 'package:drift/drift.dart';

class Habits extends Table {
  @override
  String get tableName => 'habits';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get icon => text().withDefault(const Constant('check_circle'))();
  IntColumn get color => integer().withDefault(const Constant(0xFF8B5CF6))();
  TextColumn get frequencyType => text()(); // daily, weekly, custom
  IntColumn get weeklyTarget => integer().withDefault(const Constant(1))();
  TextColumn get customDays => text().nullable()(); // JSON list of weekday ints
  BoolColumn get isQuantitative =>
      boolean().withDefault(const Constant(false))();
  RealColumn get quantitativeTarget => real().nullable()();
  TextColumn get quantitativeUnit => text().nullable()();
  TextColumn get reminderTime => text().nullable()(); // "HH:mm" format
  TextColumn get linkedEvent => text().nullable()(); // event type for auto-check
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class HabitLogs extends Table {
  @override
  String get tableName => 'habit_logs';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId => integer().references(Habits, #id)();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get completedAt => dateTime()();
  RealColumn get value => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {habitId, date},
      ];
}
