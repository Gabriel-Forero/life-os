import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/dashboard/database/dashboard_dao.dart';
import 'package:life_os/features/dashboard/providers/day_score_notifier.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// Data for a single module card on the main dashboard.
class ModuleCardData {
  const ModuleCardData({
    required this.moduleKey,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.isEnabled,
    required this.priority,
  });

  final String moduleKey;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool isEnabled;
  final int priority;
}

class DashboardState {
  const DashboardState({
    this.dayScore,
    this.cards = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final int? dayScore;
  final List<ModuleCardData> cards;
  final bool isLoading;
  final String? errorMessage;

  DashboardState copyWith({
    int? dayScore,
    List<ModuleCardData>? cards,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      dayScore: dayScore ?? this.dayScore,
      cards: cards ?? this.cards,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Module metadata constants
// ---------------------------------------------------------------------------

const _modulePriority = <String, int>{
  'finance': 1,
  'gym': 2,
  'nutrition': 3,
  'habits': 4,
};

const _moduleTitles = <String, String>{
  'finance': 'Finanzas',
  'gym': 'Gimnasio',
  'nutrition': 'Nutricion',
  'habits': 'Habitos',
};

const _moduleIcons = <String, IconData>{
  'finance': Icons.account_balance_wallet_outlined,
  'gym': Icons.fitness_center,
  'nutrition': Icons.restaurant_menu,
  'habits': Icons.check_circle_outline,
};

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Aggregates cross-module data for the main dashboard screen.
///
/// Reads from [DayScoreNotifier] for today's score and from [DashboardDao]
/// for module configs. Module metric subtitles are mocked until each module
/// exposes a score API.
class DashboardNotifier extends ChangeNotifier {
  DashboardNotifier({
    required this.dao,
    required this.dayScoreNotifier,
    required this.moduleSubtitleProvider,
  });

  final DashboardDao dao;
  final DayScoreNotifier dayScoreNotifier;

  /// Returns a human-readable subtitle for a module key (injected for testing).
  final String Function(String moduleKey) moduleSubtitleProvider;

  DashboardState _state = const DashboardState();
  DashboardState get state => _state;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    try {
      await dao.seedDefaultConfigsIfEmpty();
      await maybeGenerateYesterdaySnapshot();
      await refresh();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Error al inicializar dashboard: $e',
      );
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Refresh
  // ---------------------------------------------------------------------------

  /// Reloads dashboard state: dayScore + enabled module cards.
  Future<void> refresh() async {
    try {
      final configs = await dao.getScoreConfigs();
      final dayScore = dayScoreNotifier.state.todayScore;

      final enabledCards = configs
          .where((c) => c.isEnabled)
          .map((c) => ModuleCardData(
                moduleKey: c.moduleKey,
                title: _moduleTitles[c.moduleKey] ?? c.moduleKey,
                subtitle: moduleSubtitleProvider(c.moduleKey),
                color: AppColors.moduleColor(c.moduleKey),
                icon: _moduleIcons[c.moduleKey] ?? Icons.widgets_outlined,
                isEnabled: c.isEnabled,
                priority: _modulePriority[c.moduleKey] ?? 99,
              ))
          .toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));

      _state = _state.copyWith(
        dayScore: dayScore,
        cards: enabledCards,
        isLoading: false,
      );
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar dashboard: $e',
      );
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Greeting
  // ---------------------------------------------------------------------------

  /// Returns a time-appropriate Spanish greeting.
  String greeting({DateTime? now}) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour >= 5 && hour < 12) return 'Buenos dias';
    if (hour >= 12 && hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  // ---------------------------------------------------------------------------
  // Snapshot generation
  // ---------------------------------------------------------------------------

  /// Generates a life snapshot for yesterday if none exists (lazy generation).
  Future<void> maybeGenerateYesterdaySnapshot() async {
    final now = DateTime.now();
    final yesterday = DateTime.utc(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));

    final existing = await dao.getSnapshotForDate(yesterday);
    if (existing != null) return;

    // Collect mocked metrics (real integration wired by DI)
    final metrics = <String, dynamic>{
      'finance': {'balance': 0, 'budgetUsed': 0.0},
      'gym': {'workoutsThisWeek': 0, 'volumeKg': 0.0},
      'nutrition': {'avgCalories': 0, 'proteinGrams': 0.0},
      'habits': {'completionRate': 0.0, 'streak': 0},
    };

    final yesterdayScore =
        await dao.getDayScoreForDate(yesterday);
    final score = yesterdayScore?.totalScore ?? 0;

    await dao.insertLifeSnapshot(
      date: yesterday,
      totalScore: score,
      metrics: metrics,
    );
  }

  /// Returns all life snapshots (for analytics / history screens).
  Future<List<LifeSnapshot>> getSnapshots() => dao.getAllSnapshots();
}

// ---------------------------------------------------------------------------
// Default module subtitle provider (mock)
// ---------------------------------------------------------------------------

/// Default subtitle strings used in production when module notifiers
/// are not yet integrated.
String defaultModuleSubtitle(String moduleKey) => switch (moduleKey) {
      'finance' => 'Ver resumen',
      'gym' => 'Ver entrenamientos',
      'nutrition' => 'Ver nutricion',
      'habits' => 'Ver habitos',
      _ => 'Ver detalles',
    };
