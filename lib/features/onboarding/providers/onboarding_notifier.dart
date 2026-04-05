import 'dart:convert';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_constants.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/database/daos/app_settings_dao.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/domain/validators.dart';
import 'package:life_os/core/providers/providers.dart';

enum OnboardingStep {
  welcome,
  language,
  profile,
  modules,
  goal,
  firstData,
  complete,
}

class OnboardingState {
  const OnboardingState({
    this.currentStep = OnboardingStep.welcome,
    this.language = 'es',
    this.userName = '',
    this.currency = 'COP',
    this.enabledModules = const ['finance', 'gym', 'nutrition', 'habits', 'sleep', 'mental', 'goals'],
    this.primaryGoal,
    this.error,
    this.isLoading = false,
  });

  final OnboardingStep currentStep;
  final String language;
  final String userName;
  final String currency;
  final List<String> enabledModules;
  final String? primaryGoal;
  final String? error;
  final bool isLoading;

  OnboardingState copyWith({
    OnboardingStep? currentStep,
    String? language,
    String? userName,
    String? currency,
    List<String>? enabledModules,
    String? primaryGoal,
    String? error,
    bool? isLoading,
  }) =>
      OnboardingState(
        currentStep: currentStep ?? this.currentStep,
        language: language ?? this.language,
        userName: userName ?? this.userName,
        currency: currency ?? this.currency,
        enabledModules: enabledModules ?? this.enabledModules,
        primaryGoal: primaryGoal ?? this.primaryGoal,
        error: error,
        isLoading: isLoading ?? this.isLoading,
      );

  int get stepIndex => currentStep.index;
  int get totalSteps => OnboardingStep.values.length - 1; // exclude 'complete'
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._dao) : super(const OnboardingState());

  final AppSettingsDao _dao;

  void detectSystemLanguage() {
    final locale = PlatformDispatcher.instance.locale;
    final lang = locale.languageCode.startsWith('en') ? 'en' : 'es';
    state = state.copyWith(language: lang);
  }

  void nextStep() {
    final next = OnboardingStep.values[state.currentStep.index + 1];
    state = state.copyWith(currentStep: next, error: null);
  }

  void previousStep() {
    if (state.currentStep.index > 0) {
      final prev = OnboardingStep.values[state.currentStep.index - 1];
      state = state.copyWith(currentStep: prev, error: null);
    }
  }

  void setLanguage(String language) {
    final result = validateLanguage(language);
    result.when(
      success: (value) => state = state.copyWith(language: value, error: null),
      failure: (f) => state = state.copyWith(error: f.userMessage),
    );
  }

  void setName(String name) {
    state = state.copyWith(userName: name, error: null);
  }

  Result<String> validateName() => validateUserName(state.userName);

  void setCurrency(String currency) {
    final result = validateCurrencyCode(currency);
    result.when(
      success: (value) => state = state.copyWith(currency: value, error: null),
      failure: (f) => state = state.copyWith(error: f.userMessage),
    );
  }

  void toggleModule(String moduleId) {
    final current = List<String>.from(state.enabledModules);
    if (current.contains(moduleId)) {
      if (current.length > 1) {
        current.remove(moduleId);
      } else {
        state = state.copyWith(error: 'Selecciona al menos un modulo');
        return;
      }
    } else {
      current.add(moduleId);
    }
    state = state.copyWith(enabledModules: current, error: null);
  }

  void setGoal(String goal) {
    final result = validatePrimaryGoal(goal);
    result.when(
      success: (value) =>
          state = state.copyWith(primaryGoal: value, error: null),
      failure: (f) => state = state.copyWith(error: f.userMessage),
    );
  }

  Future<Result<void>> skip() async {
    final defaultName = state.language == 'en'
        ? AppConstants.defaultUserNameEn
        : AppConstants.defaultUserNameEs;

    state = state.copyWith(
      userName: defaultName,
      currency: AppConstants.defaultCurrency,
      primaryGoal: AppConstants.defaultPrimaryGoal,
      enabledModules: AppConstants.allModuleIds,
      isLoading: true,
    );

    return _persistSettings();
  }

  Future<Result<void>> completeOnboarding() async {
    state = state.copyWith(isLoading: true);
    return _persistSettings();
  }

  Future<Result<void>> _persistSettings() async {
    try {
      final settings = AppSettingsTableCompanion.insert(
        userName: state.userName.trim(),
        language: Value(state.language),
        currency: Value(state.currency),
        primaryGoal: state.primaryGoal ?? AppConstants.defaultPrimaryGoal,
        enabledModules: Value(jsonEncode(state.enabledModules)),
        themeMode: const Value('dark'),
        useBiometric: const Value(false),
        onboardingCompleted: const Value(true),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dao.createSettings(settings);
      state = state.copyWith(
        currentStep: OnboardingStep.complete,
        isLoading: false,
      );
      return const Success(null);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false);
      return Failure(
        DatabaseFailure(
          userMessage: 'Error al guardar datos',
          debugMessage: 'Failed to persist onboarding settings: $e',
          originalError: e,
        ),
      );
    }
  }
}

final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final dao = ref.watch(appSettingsDaoProvider);
  return OnboardingNotifier(dao);
});
