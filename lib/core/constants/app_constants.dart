abstract final class AppConstants {
  static const String appName = 'LifeOS';
  static const String defaultLanguage = 'es';
  static const String defaultCurrency = 'COP';
  static const String defaultPrimaryGoal = 'balance';
  static const String defaultThemeMode = 'dark';
  static const String defaultUserNameEs = 'Usuario';
  static const String defaultUserNameEn = 'User';

  static const List<String> allModuleIds = [
    'finance',
    'gym',
    'nutrition',
    'habits',
    'sleep',
    'mental',
    'goals',
  ];

  static const Duration biometricGracePeriod = Duration(seconds: 30);
  static const int maxBiometricAttempts = 3;
  static const int maxUserNameLength = 50;
}
