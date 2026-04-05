// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LifeOS';

  @override
  String get onboardingWelcomeTitle => 'Welcome to LifeOS';

  @override
  String get onboardingWelcomeSubtitle =>
      'Your personal life management system';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get onboardingSkipSetup => 'Skip setup';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingSkipForNow => 'Skip for now';

  @override
  String get languageSelectionTitle => 'Select your language';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageEnglish => 'English';

  @override
  String get profileTitle => 'Your profile';

  @override
  String get profileNameLabel => 'Name';

  @override
  String get profileNameHint => 'What\'s your name?';

  @override
  String get profileCurrencyLabel => 'Currency';

  @override
  String get modulesTitle => 'Active modules';

  @override
  String get modulesSubtitle => 'Select at least one';

  @override
  String get moduleFinance => 'Finance';

  @override
  String get moduleGym => 'Gym';

  @override
  String get moduleNutrition => 'Nutrition';

  @override
  String get moduleHabits => 'Habits';

  @override
  String get moduleSleep => 'Sleep';

  @override
  String get moduleMental => 'Mental';

  @override
  String get moduleGoals => 'Goals';

  @override
  String get goalTitle => 'Your primary goal';

  @override
  String get goalSaveMoney => 'Save Money';

  @override
  String get goalGetFit => 'Get Fit';

  @override
  String get goalBeDisciplined => 'Be Disciplined';

  @override
  String get goalBalance => 'Life Balance';

  @override
  String get firstDataTitle => 'Your first entry';

  @override
  String get firstDataCreateBudget => 'Create your first budget';

  @override
  String get firstDataCreateHabit => 'Create your first habit';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsBiometric => 'Biometric lock';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsBackup => 'Backup';

  @override
  String get settingsExportBackup => 'Export backup';

  @override
  String get settingsImportBackup => 'Import backup';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get errorSavingData => 'Error saving data';

  @override
  String get errorLoadingData => 'Error loading data';

  @override
  String get errorBackupExport => 'Backup export failed';

  @override
  String get errorBackupImport => 'Backup import failed';

  @override
  String get errorBackupInvalid => 'Invalid backup file';

  @override
  String get errorPermissionRequired => 'Permission required';

  @override
  String get errorAuthFailed => 'Authentication failed';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonSuccess => 'Done!';

  @override
  String get validationRequired => 'This field is required';

  @override
  String validationMaxLength(int max) {
    return 'Maximum $max characters';
  }

  @override
  String get validationMinModules => 'Select at least one module';
}
