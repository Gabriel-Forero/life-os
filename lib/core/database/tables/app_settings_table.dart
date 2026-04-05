import 'package:drift/drift.dart';

class AppSettingsTable extends Table {
  @override
  String get tableName => 'app_settings';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get userName => text().withLength(min: 1, max: 50)();
  TextColumn get language => text().withDefault(const Constant('es'))();
  TextColumn get currency => text().withDefault(const Constant('COP'))();
  TextColumn get primaryGoal => text()();
  TextColumn get enabledModules =>
      text().withDefault(const Constant('["finance"]'))();
  TextColumn get themeMode =>
      text().withDefault(const Constant('dark'))();
  BoolColumn get useBiometric =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
