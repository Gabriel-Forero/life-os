// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'LifeOS';

  @override
  String get onboardingWelcomeTitle => 'Bienvenido a LifeOS';

  @override
  String get onboardingWelcomeSubtitle =>
      'Tu sistema personal de gestion de vida';

  @override
  String get onboardingStart => 'Comenzar';

  @override
  String get onboardingSkipSetup => 'Omitir configuracion';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingBack => 'Atras';

  @override
  String get onboardingSkipForNow => 'Omitir por ahora';

  @override
  String get languageSelectionTitle => 'Selecciona tu idioma';

  @override
  String get languageSpanish => 'Espanol';

  @override
  String get languageEnglish => 'Ingles';

  @override
  String get profileTitle => 'Tu perfil';

  @override
  String get profileNameLabel => 'Nombre';

  @override
  String get profileNameHint => 'Como te llamas?';

  @override
  String get profileCurrencyLabel => 'Moneda';

  @override
  String get modulesTitle => 'Modulos activos';

  @override
  String get modulesSubtitle => 'Selecciona al menos uno';

  @override
  String get moduleFinance => 'Finanzas';

  @override
  String get moduleGym => 'Gym';

  @override
  String get moduleNutrition => 'Nutricion';

  @override
  String get moduleHabits => 'Habitos';

  @override
  String get moduleSleep => 'Sueno';

  @override
  String get moduleMental => 'Mental';

  @override
  String get moduleGoals => 'Metas';

  @override
  String get goalTitle => 'Tu meta principal';

  @override
  String get goalSaveMoney => 'Ahorrar';

  @override
  String get goalGetFit => 'Ponerme en forma';

  @override
  String get goalBeDisciplined => 'Ser mas disciplinado';

  @override
  String get goalBalance => 'Equilibrio general';

  @override
  String get firstDataTitle => 'Tu primer dato';

  @override
  String get firstDataCreateBudget => 'Crear tu primer presupuesto';

  @override
  String get firstDataCreateHabit => 'Crear tu primer habito';

  @override
  String get settingsTitle => 'Configuracion';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsBiometric => 'Bloqueo biometrico';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsCurrency => 'Moneda';

  @override
  String get settingsBackup => 'Respaldo';

  @override
  String get settingsExportBackup => 'Exportar respaldo';

  @override
  String get settingsImportBackup => 'Importar respaldo';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get errorGeneric => 'Algo salio mal';

  @override
  String get errorSavingData => 'Error al guardar datos';

  @override
  String get errorLoadingData => 'Error al cargar datos';

  @override
  String get errorBackupExport => 'Error al exportar respaldo';

  @override
  String get errorBackupImport => 'Error al importar respaldo';

  @override
  String get errorBackupInvalid => 'Archivo de respaldo invalido';

  @override
  String get errorPermissionRequired => 'Permiso requerido';

  @override
  String get errorAuthFailed => 'Autenticacion fallida';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonLoading => 'Cargando...';

  @override
  String get commonSuccess => 'Listo!';

  @override
  String get validationRequired => 'Este campo es obligatorio';

  @override
  String validationMaxLength(int max) {
    return 'Maximo $max caracteres';
  }

  @override
  String get validationMinModules => 'Selecciona al menos un modulo';
}
