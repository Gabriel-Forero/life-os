import 'package:life_os/features/settings/domain/models/app_settings_model.dart';

abstract class SettingsRepository {
  Future<AppSettingsModel?> getSettings();

  Stream<AppSettingsModel?> watchSettings();

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
  });

  Future<bool> updateLanguage(String language);

  Future<bool> updateCurrency(String currency);

  Future<bool> updateUserName(String userName);

  Future<bool> updateThemeMode(String themeMode);

  Future<bool> updateBiometric(bool useBiometric);

  Future<bool> updatePrimaryGoal(String primaryGoal);

  Future<bool> updateEnabledModules(List<String> modules);

  Future<bool> markOnboardingCompleted();
}
