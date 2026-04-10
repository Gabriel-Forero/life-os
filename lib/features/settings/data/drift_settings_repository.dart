import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/database/daos/app_settings_dao.dart';
import 'package:life_os/features/settings/data/settings_repository.dart';
import 'package:life_os/features/settings/domain/models/app_settings_model.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository({required this.dao});

  final AppSettingsDao dao;

  // --- Mapping helpers ---

  static AppSettingsModel _toModel(AppSettingsTableData row) =>
      AppSettingsModel(
        id: row.id.toString(),
        userName: row.userName,
        language: row.language,
        currency: row.currency,
        primaryGoal: row.primaryGoal,
        enabledModules: row.enabledModules,
        themeMode: row.themeMode,
        useBiometric: row.useBiometric,
        onboardingCompleted: row.onboardingCompleted,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  // --- SettingsRepository implementation ---

  @override
  Future<AppSettingsModel?> getSettings() async {
    final row = await dao.getSettings();
    return row != null ? _toModel(row) : null;
  }

  @override
  Stream<AppSettingsModel?> watchSettings() {
    return dao
        .watchSettings()
        .map((row) => row != null ? _toModel(row) : null);
  }

  @override
  Future<String> createSettings({
    required String userName,
    required String language,
    required String currency,
    required String primaryGoal,
    required String enabledModules,
    required String themeMode,
    required bool useBiometric,
    required bool onboardingCompleted,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final id = await dao.createSettings(
      AppSettingsTableCompanion.insert(
        userName: userName,
        language: Value(language),
        currency: Value(currency),
        primaryGoal: primaryGoal,
        enabledModules: Value(enabledModules),
        themeMode: Value(themeMode),
        useBiometric: Value(useBiometric),
        onboardingCompleted: Value(onboardingCompleted),
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
    return id.toString();
  }

  @override
  Future<bool> updateLanguage(String language) =>
      dao.updateLanguage(language).then((_) => true);

  @override
  Future<bool> updateCurrency(String currency) =>
      dao.updateCurrency(currency).then((_) => true);

  @override
  Future<bool> updateUserName(String userName) =>
      dao.updateUserName(userName).then((_) => true);

  @override
  Future<bool> updateThemeMode(String themeMode) =>
      dao.updateThemeMode(themeMode).then((_) => true);

  @override
  Future<bool> updateBiometric(bool useBiometric) =>
      dao.updateBiometric(useBiometric).then((_) => true);

  @override
  Future<bool> updatePrimaryGoal(String primaryGoal) =>
      dao.updatePrimaryGoal(primaryGoal).then((_) => true);

  @override
  Future<bool> updateEnabledModules(List<String> modules) =>
      dao.updateEnabledModules(modules).then((_) => true);

  @override
  Future<bool> markOnboardingCompleted() =>
      dao.markOnboardingCompleted().then((_) => true);
}
