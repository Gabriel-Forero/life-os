import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/database/tables/app_settings_table.dart';

part 'app_settings_dao.g.dart';

@DriftAccessor(tables: [AppSettingsTable])
class AppSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$AppSettingsDaoMixin {
  AppSettingsDao(super.db);

  Future<AppSettingsTableData?> getSettings() =>
      (select(appSettingsTable)..where((t) => t.id.equals(1)))
          .getSingleOrNull();

  Stream<AppSettingsTableData?> watchSettings() =>
      (select(appSettingsTable)..where((t) => t.id.equals(1)))
          .watchSingleOrNull();

  Future<int> createSettings(AppSettingsTableCompanion settings) =>
      into(appSettingsTable).insert(
        settings.copyWith(
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<bool> updateSettings(AppSettingsTableCompanion settings) =>
      (update(appSettingsTable)..where((t) => t.id.equals(1))).write(
        settings.copyWith(updatedAt: Value(DateTime.now())),
      ).then((rows) => rows > 0);

  Future<void> updateLanguage(String language) =>
      updateSettings(AppSettingsTableCompanion(language: Value(language)));

  Future<void> updateCurrency(String currency) =>
      updateSettings(AppSettingsTableCompanion(currency: Value(currency)));

  Future<void> updateUserName(String userName) =>
      updateSettings(AppSettingsTableCompanion(userName: Value(userName)));

  Future<void> updateThemeMode(String themeMode) =>
      updateSettings(AppSettingsTableCompanion(themeMode: Value(themeMode)));

  Future<void> updateBiometric(bool useBiometric) =>
      updateSettings(
        AppSettingsTableCompanion(useBiometric: Value(useBiometric)),
      );

  Future<void> updatePrimaryGoal(String primaryGoal) =>
      updateSettings(
        AppSettingsTableCompanion(primaryGoal: Value(primaryGoal)),
      );

  Future<void> updateEnabledModules(List<String> modules) =>
      updateSettings(
        AppSettingsTableCompanion(
          enabledModules: Value(jsonEncode(modules)),
        ),
      );

  Future<void> markOnboardingCompleted() =>
      updateSettings(
        const AppSettingsTableCompanion(
          onboardingCompleted: Value(true),
        ),
      );
}
