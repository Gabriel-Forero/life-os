import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/dashboard/data/dashboard_repository.dart';
import 'package:life_os/features/dashboard/database/dashboard_dao.dart';
import 'package:life_os/features/dashboard/domain/models/day_score_config_model.dart';
import 'package:life_os/features/dashboard/domain/models/day_score_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ScoreComponentData {
  const ScoreComponentData({
    required this.moduleKey,
    required this.rawValue,
    required this.weight,
    required this.weightedScore,
  });

  final String moduleKey;
  final double rawValue;
  final double weight;
  final double weightedScore;
}

class DayScoreState {
  const DayScoreState({
    this.todayScore,
    this.components = const [],
    this.configs = const [],
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final int? todayScore;
  final List<ScoreComponentData> components;
  final List<DayScoreConfigModel> configs;
  final List<DayScoreModel> history;
  final bool isLoading;
  final String? errorMessage;

  DayScoreState copyWith({
    int? todayScore,
    List<ScoreComponentData>? components,
    List<DayScoreConfigModel>? configs,
    List<DayScoreModel>? history,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DayScoreState(
      todayScore: todayScore ?? this.todayScore,
      components: components ?? this.components,
      configs: configs ?? this.configs,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages DayScore computation, persistence, and configuration.
///
/// Subscribes to EventBus events to trigger score recalculation:
/// - [BudgetThresholdEvent]
/// - [HabitCheckedInEvent]
/// - [GoalProgressUpdatedEvent]
class DayScoreNotifier extends ChangeNotifier {
  DayScoreNotifier({
    required this.repository,
    required this.eventBus,
    required this.moduleScoreProvider,
  }) {
    _subscribeToEvents();
  }

  final DashboardRepository repository;
  final EventBus eventBus;

  /// Callback that returns the raw score [0.0–100.0] for a given module key.
  /// Injected so this notifier remains testable without other notifiers.
  /// May be async — returns a [Future<double>].
  final Future<double> Function(String moduleKey) moduleScoreProvider;

  DayScoreState _state = const DayScoreState();
  DayScoreState get state => _state;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    try {
      await repository.seedDefaultConfigsIfEmpty();
      final configs = await repository.getScoreConfigs();
      final history = await repository.getRecentDayScores();
      _state = _state.copyWith(
        configs: configs,
        history: history,
        isLoading: false,
      );
      notifyListeners();
      await calculateDayScore(DateTime.now());
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Error al inicializar puntuacion: $e',
      );
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Score Calculation
  // ---------------------------------------------------------------------------

  /// Computes and persists the DayScore for [date].
  ///
  /// Formula: score = ROUND(Σ(rawValue_i × weight_i) / Σ(weight_i))
  /// Only enabled modules (is_enabled = true, weight > 0) participate.
  Future<Result<int>> calculateDayScore(DateTime date) async {
    try {
      final configs = await repository.getScoreConfigs();
      final enabledConfigs = configs.where((c) => c.isEnabled && c.weight > 0);

      if (enabledConfigs.isEmpty) {
        _state = _state.copyWith(todayScore: 0, components: []);
    notifyListeners();
        return const Success(0);
      }

      final components = <ScoreComponentData>[];
      double weightedSum = 0;
      double totalWeight = 0;

      for (final config in enabledConfigs) {
        final rawValue = (await moduleScoreProvider(config.moduleKey))
            .clamp(0.0, 100.0);
        final weightedScore = rawValue * config.weight;
        components.add(ScoreComponentData(
          moduleKey: config.moduleKey,
          rawValue: rawValue,
          weight: config.weight,
          weightedScore: weightedScore,
        ));
        weightedSum += weightedScore;
        totalWeight += config.weight;
      }

      final totalScore =
          (weightedSum / totalWeight).round().clamp(0, 100);

      final now = DateTime.now();
      await repository.upsertDayScore(
        date: date,
        totalScore: totalScore,
        calculatedAt: now,
        components: components
            .map((c) => ScoreComponentInput(
                  moduleKey: c.moduleKey,
                  rawValue: c.rawValue,
                  weight: c.weight,
                  weightedScore: c.weightedScore,
                ))
            .toList(),
      );

      final history = await repository.getRecentDayScores();
      _state = _state.copyWith(
        todayScore: totalScore,
        components: components,
        configs: configs,
        history: history,
      );
      notifyListeners();

      return Success(totalScore);
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: 'Error al calcular DayScore: $e',
      );
      notifyListeners();
      return Failure(DatabaseFailure(
        userMessage: 'Error al calcular la puntuacion del dia',
        debugMessage: 'calculateDayScore failed: $e',
        originalError: e,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Config Management
  // ---------------------------------------------------------------------------

  /// Returns current score configurations.
  Future<List<DayScoreConfigModel>> getScoreConfigs() => repository.getScoreConfigs();

  /// Updates the weight for a module. Weight must be in (0.0, 10.0].
  Future<Result<void>> updateWeight(String moduleKey, double weight) async {
    if (weight <= 0 || weight > 10.0) {
      return const Failure(ValidationFailure(
        userMessage: 'El peso debe estar entre 0.01 y 10.0',
        debugMessage: 'Weight out of range',
        field: 'weight',
      ));
    }

    try {
      await repository.updateWeightByKey(moduleKey, weight);
      final configs = await repository.getScoreConfigs();
      _state = _state.copyWith(configs: configs);
    notifyListeners();
      await calculateDayScore(DateTime.now());
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al actualizar el peso del modulo',
        debugMessage: 'updateWeight failed: $e',
        originalError: e,
      ));
    }
  }

  /// Enables or disables a module in the score config.
  Future<Result<void>> setModuleEnabled(String configId, {required bool isEnabled, required double weight}) async {
    try {
      await repository.updateScoreConfig(configId, weight: weight, isEnabled: isEnabled);
      final configs = await repository.getScoreConfigs();
      _state = _state.copyWith(configs: configs);
    notifyListeners();
      await calculateDayScore(DateTime.now());
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al actualizar la configuracion del modulo',
        debugMessage: 'setModuleEnabled failed: $e',
        originalError: e,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // EventBus subscriptions
  // ---------------------------------------------------------------------------

  void _subscribeToEvents() {
    _subscriptions.addAll([
      eventBus.on<BudgetThresholdEvent>().listen(
            (_) => calculateDayScore(DateTime.now()),
          ),
      eventBus.on<HabitCheckedInEvent>().listen(
            (_) => calculateDayScore(DateTime.now()),
          ),
      eventBus.on<GoalProgressUpdatedEvent>().listen(
            (_) => calculateDayScore(DateTime.now()),
          ),
    ]);
  }

  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}

