import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('es'),
    Locale('en'),
  ];

  /// App title
  ///
  /// In es, this message translates to:
  /// **'LifeOS'**
  String get appTitle;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a LifeOS'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu sistema personal de gestion de vida'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingStart.
  ///
  /// In es, this message translates to:
  /// **'Comenzar'**
  String get onboardingStart;

  /// No description provided for @onboardingSkipSetup.
  ///
  /// In es, this message translates to:
  /// **'Omitir configuracion'**
  String get onboardingSkipSetup;

  /// No description provided for @onboardingContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get onboardingContinue;

  /// No description provided for @onboardingBack.
  ///
  /// In es, this message translates to:
  /// **'Atras'**
  String get onboardingBack;

  /// No description provided for @onboardingSkipForNow.
  ///
  /// In es, this message translates to:
  /// **'Omitir por ahora'**
  String get onboardingSkipForNow;

  /// No description provided for @languageSelectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu idioma'**
  String get languageSelectionTitle;

  /// No description provided for @languageSpanish.
  ///
  /// In es, this message translates to:
  /// **'Espanol'**
  String get languageSpanish;

  /// No description provided for @languageEnglish.
  ///
  /// In es, this message translates to:
  /// **'Ingles'**
  String get languageEnglish;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu perfil'**
  String get profileTitle;

  /// No description provided for @profileNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get profileNameLabel;

  /// No description provided for @profileNameHint.
  ///
  /// In es, this message translates to:
  /// **'Como te llamas?'**
  String get profileNameHint;

  /// No description provided for @profileCurrencyLabel.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get profileCurrencyLabel;

  /// No description provided for @modulesTitle.
  ///
  /// In es, this message translates to:
  /// **'Modulos activos'**
  String get modulesTitle;

  /// No description provided for @modulesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos uno'**
  String get modulesSubtitle;

  /// No description provided for @moduleFinance.
  ///
  /// In es, this message translates to:
  /// **'Finanzas'**
  String get moduleFinance;

  /// No description provided for @moduleGym.
  ///
  /// In es, this message translates to:
  /// **'Gym'**
  String get moduleGym;

  /// No description provided for @moduleNutrition.
  ///
  /// In es, this message translates to:
  /// **'Nutricion'**
  String get moduleNutrition;

  /// No description provided for @moduleHabits.
  ///
  /// In es, this message translates to:
  /// **'Habitos'**
  String get moduleHabits;

  /// No description provided for @moduleSleep.
  ///
  /// In es, this message translates to:
  /// **'Sueno'**
  String get moduleSleep;

  /// No description provided for @moduleMental.
  ///
  /// In es, this message translates to:
  /// **'Mental'**
  String get moduleMental;

  /// No description provided for @moduleGoals.
  ///
  /// In es, this message translates to:
  /// **'Metas'**
  String get moduleGoals;

  /// No description provided for @goalTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu meta principal'**
  String get goalTitle;

  /// No description provided for @goalSaveMoney.
  ///
  /// In es, this message translates to:
  /// **'Ahorrar'**
  String get goalSaveMoney;

  /// No description provided for @goalGetFit.
  ///
  /// In es, this message translates to:
  /// **'Ponerme en forma'**
  String get goalGetFit;

  /// No description provided for @goalBeDisciplined.
  ///
  /// In es, this message translates to:
  /// **'Ser mas disciplinado'**
  String get goalBeDisciplined;

  /// No description provided for @goalBalance.
  ///
  /// In es, this message translates to:
  /// **'Equilibrio general'**
  String get goalBalance;

  /// No description provided for @firstDataTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu primer dato'**
  String get firstDataTitle;

  /// No description provided for @firstDataCreateBudget.
  ///
  /// In es, this message translates to:
  /// **'Crear tu primer presupuesto'**
  String get firstDataCreateBudget;

  /// No description provided for @firstDataCreateHabit.
  ///
  /// In es, this message translates to:
  /// **'Crear tu primer habito'**
  String get firstDataCreateHabit;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuracion'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get settingsThemeSystem;

  /// No description provided for @settingsBiometric.
  ///
  /// In es, this message translates to:
  /// **'Bloqueo biometrico'**
  String get settingsBiometric;

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @settingsCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get settingsCurrency;

  /// No description provided for @settingsBackup.
  ///
  /// In es, this message translates to:
  /// **'Respaldo'**
  String get settingsBackup;

  /// No description provided for @settingsExportBackup.
  ///
  /// In es, this message translates to:
  /// **'Exportar respaldo'**
  String get settingsExportBackup;

  /// No description provided for @settingsImportBackup.
  ///
  /// In es, this message translates to:
  /// **'Importar respaldo'**
  String get settingsImportBackup;

  /// No description provided for @settingsNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get settingsNotifications;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Algo salio mal'**
  String get errorGeneric;

  /// No description provided for @errorSavingData.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar datos'**
  String get errorSavingData;

  /// No description provided for @errorLoadingData.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar datos'**
  String get errorLoadingData;

  /// No description provided for @errorBackupExport.
  ///
  /// In es, this message translates to:
  /// **'Error al exportar respaldo'**
  String get errorBackupExport;

  /// No description provided for @errorBackupImport.
  ///
  /// In es, this message translates to:
  /// **'Error al importar respaldo'**
  String get errorBackupImport;

  /// No description provided for @errorBackupInvalid.
  ///
  /// In es, this message translates to:
  /// **'Archivo de respaldo invalido'**
  String get errorBackupInvalid;

  /// No description provided for @errorPermissionRequired.
  ///
  /// In es, this message translates to:
  /// **'Permiso requerido'**
  String get errorPermissionRequired;

  /// No description provided for @errorAuthFailed.
  ///
  /// In es, this message translates to:
  /// **'Autenticacion fallida'**
  String get errorAuthFailed;

  /// No description provided for @commonRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get commonDelete;

  /// No description provided for @commonLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get commonLoading;

  /// No description provided for @commonSuccess.
  ///
  /// In es, this message translates to:
  /// **'Listo!'**
  String get commonSuccess;

  /// No description provided for @validationRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get validationRequired;

  /// No description provided for @validationMaxLength.
  ///
  /// In es, this message translates to:
  /// **'Maximo {max} caracteres'**
  String validationMaxLength(int max);

  /// No description provided for @validationMinModules.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos un modulo'**
  String get validationMinModules;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
