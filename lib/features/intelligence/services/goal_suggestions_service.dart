import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/providers/providers.dart';

// ---------------------------------------------------------------------------
// GoalSuggestion model
// ---------------------------------------------------------------------------

class GoalSuggestion { // Why this was suggested

  factory GoalSuggestion.fromJson(Map<String, dynamic> json) {
    return GoalSuggestion(
      name: (json['nombre'] as String?) ?? (json['name'] as String?) ?? '',
      description:
          (json['descripcion'] as String?) ??
          (json['description'] as String?) ??
          '',
      category:
          (json['categoria'] as String?) ??
          (json['category'] as String?) ??
          'salud',
      rationale:
          (json['razon'] as String?) ??
          (json['rationale'] as String?) ??
          '',
    );
  }
  const GoalSuggestion({
    required this.name,
    required this.description,
    required this.category,
    required this.rationale,
  });

  final String name;
  final String description;
  final String category; // salud, finanzas, habitos, gym, etc.
  final String rationale;
}

// ---------------------------------------------------------------------------
// GoalSuggestionsService
// ---------------------------------------------------------------------------

class GoalSuggestionsService {
  GoalSuggestionsService({required this.ref});

  final Ref ref;

  Future<List<GoalSuggestion>> generateSuggestions() async {
    final context = await _buildAnalysisContext();
    if (context.isEmpty) return _fallbackSuggestions();

    try {
      final aiNotifier = ref.read(aiNotifierProvider);
      final config = await aiNotifier.repository.getDefaultConfiguration();
      if (config == null) return _fallbackSuggestions();

      const systemPrompt =
          'Eres un coach de bienestar personal. '
          'Analiza los datos del usuario y sugiere metas SMART concretas. '
          'Responde SOLO con JSON valido.';

      final userPrompt =
          'Basandote en estos datos del usuario:\n\n$context\n\n'
          'Sugiere exactamente 3 metas personalizadas. '
          'Responde SOLO con este JSON (sin markdown):\n'
          '{"sugerencias":['
          '{"nombre":"...","descripcion":"...","categoria":"finanzas|salud|habitos|gym|sueno|bienestar","razon":"..."}'
          ']}';

      final provider = aiNotifier.providerFactory(config);
      final buffer = StringBuffer();

      await for (final chunk in provider.sendMessage(
        userPrompt,
        systemContext: systemPrompt,
      )) {
        buffer.write(chunk);
      }

      return _parseSuggestions(buffer.toString().trim());
    } on Exception {
      return _fallbackSuggestions();
    }
  }

  Future<String> _buildAnalysisContext() async {
    final lines = <String>[];
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    // Finance trend
    try {
      final financeRepo = ref.read(financeRepositoryProvider);
      final thisMonthExpenses =
          await financeRepo.sumByType('expense', monthAgo, now);
      final prevMonthExpenses = await financeRepo.sumByType(
        'expense',
        now.subtract(const Duration(days: 60)),
        monthAgo,
      );

      if (thisMonthExpenses > 0) {
        lines.add(
            'Gastos ultimo mes: \$${(thisMonthExpenses / 100).toStringAsFixed(2)}');
        if (prevMonthExpenses > 0) {
          final change =
              (thisMonthExpenses - prevMonthExpenses) / prevMonthExpenses;
          if (change > 0.3) {
            lines.add(
                'ALERTA: Gastos aumentaron ${(change * 100).toStringAsFixed(0)}% vs mes anterior');
          }
        }
      }
    } on Exception {
      // ignore
    }

    // Gym frequency
    try {
      final gymRepo = ref.read(gymRepositoryProvider);
      final workouts = await gymRepo.watchWorkouts(limit: 30).first;
      final recentWorkouts = workouts.where((w) {
        if (w.finishedAt == null) return false;
        return w.finishedAt!.isAfter(weekAgo);
      }).length;
      lines.add('Entrenamientos esta semana: $recentWorkouts');
      if (recentWorkouts >= 4) {
        lines.add('Usuario muy consistente en el gym (4+ por semana)');
      }
    } on Exception {
      // ignore
    }

    // Sleep patterns
    try {
      final sleepDao = ref.read(sleepRepositoryProvider);
      final sleepLogs = await sleepDao.watchSleepLogs(weekAgo, now).first;
      if (sleepLogs.isNotEmpty) {
        final withTimes = sleepLogs.where((l) =>
            l.bedTime != null).toList();
        if (withTimes.isNotEmpty) {
          // Check if sleep times are irregular
          final bedHours = withTimes
              .map((l) => l.bedTime.hour + l.bedTime.minute / 60.0)
              .toList();
          final maxHour = bedHours.reduce((a, b) => a > b ? a : b);
          final minHour = bedHours.reduce((a, b) => a < b ? a : b);
          final spread = maxHour - minHour;
          if (spread > 2.5) {
            lines.add(
                'Horario de sueno irregular (diferencia de ${spread.toStringAsFixed(1)}h entre dias)');
          }

          final avgScore = sleepLogs
                  .where((l) => l.sleepScore != null)
                  .map((l) => l.sleepScore)
                  .fold(0, (a, b) => a + b) /
              sleepLogs.where((l) => l.sleepScore != null).length;
          lines.add('Calidad de sueno promedio: ${avgScore.toStringAsFixed(0)}/100');
        }
      }
    } on Exception {
      // ignore
    }

    // Habit completion
    try {
      final habitsDao = ref.read(habitsRepositoryProvider);
      final activeHabits = await habitsDao.watchActiveHabits().first;
      if (activeHabits.isNotEmpty) {
        double totalRate = 0;
        for (final h in activeHabits) {
          totalRate +=
              await habitsDao.completionRate(h.id, weekAgo, now);
        }
        final avgRate = totalRate / activeHabits.length;
        lines.add(
            'Cumplimiento de habitos esta semana: ${(avgRate * 100).toStringAsFixed(0)}%');
        if (avgRate < 0.5) {
          lines.add('Usuario con baja adherencia a habitos (menos del 50%)');
        }
      } else {
        lines.add('Usuario sin habitos configurados');
      }
    } on Exception {
      // ignore
    }

    // Active goals
    try {
      final goalsDao = ref.read(goalsRepositoryProvider);
      final goals = await goalsDao.getAllGoals();
      final active = goals.where((g) => g.status == 'active').toList();
      lines.add('Objetivos activos: ${active.length}');
      if (active.isNotEmpty) {
        final avgProgress =
            active.map((g) => g.progress).fold(0, (a, b) => a + b) /
                active.length;
        lines.add('Progreso promedio de objetivos: ${avgProgress.toStringAsFixed(0)}%');
      }
    } on Exception {
      // ignore
    }

    return lines.join('\n');
  }

  List<GoalSuggestion> _parseSuggestions(String raw) {
    try {
      // Remove code fences
      var s = raw.replaceAll(RegExp(r'```json\s*'), '');
      s = s.replaceAll(RegExp(r'```\s*'), '');

      // Find JSON object
      final start = s.indexOf('{');
      final end = s.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) {
        return _fallbackSuggestions();
      }

      final jsonStr = s.substring(start, end + 1);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawList = decoded['sugerencias'] as List?;
      if (rawList == null) return _fallbackSuggestions();

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(GoalSuggestion.fromJson)
          .where((s) => s.name.isNotEmpty)
          .take(3)
          .toList();
    } on Exception {
      return _fallbackSuggestions();
    }
  }

  List<GoalSuggestion> _fallbackSuggestions() {
    return const [
      GoalSuggestion(
        name: 'Reducir gastos hormiga',
        description:
            'Registrar y reducir gastos menores diarios en un 20% durante 30 dias',
        category: 'finanzas',
        rationale: 'Los gastos pequenos frecuentes impactan el presupuesto sin notarse',
      ),
      GoalSuggestion(
        name: 'Habito de sueno consistente',
        description:
            'Acostarse a la misma hora (+/- 30 min) durante 21 dias consecutivos',
        category: 'sueno',
        rationale: 'Un horario regular mejora la calidad del sueno y la energia diaria',
      ),
      GoalSuggestion(
        name: 'Actividad fisica minima',
        description:
            'Completar al menos 3 entrenamientos por semana durante 4 semanas',
        category: 'gym',
        rationale: 'La consistencia es mas importante que la intensidad para crear el habito',
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

class GoalSuggestionsState {
  const GoalSuggestionsState({
    this.suggestions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastGenerated,
  });

  final List<GoalSuggestion> suggestions;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastGenerated;

  /// Only regenerate if older than 1 day
  bool get needsRefresh {
    if (lastGenerated == null) return true;
    return DateTime.now().difference(lastGenerated!).inHours > 24;
  }

  GoalSuggestionsState copyWith({
    List<GoalSuggestion>? suggestions,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastGenerated,
  }) =>
      GoalSuggestionsState(
        suggestions: suggestions ?? this.suggestions,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        lastGenerated: lastGenerated ?? this.lastGenerated,
      );
}

class GoalSuggestionsNotifier
    extends StateNotifier<GoalSuggestionsState> {
  GoalSuggestionsNotifier(this._ref) : super(const GoalSuggestionsState());

  final Ref _ref;

  Future<void> generateIfNeeded() async {
    if (!state.needsRefresh) return;
    await generate();
  }

  Future<void> generate() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final service = GoalSuggestionsService(ref: _ref);
      final suggestions = await service.generateSuggestions();
      state = state.copyWith(
        suggestions: suggestions,
        isLoading: false,
        lastGenerated: DateTime.now(),
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al generar sugerencias: $e',
      );
    }
  }
}

final goalSuggestionsProvider = StateNotifierProvider<GoalSuggestionsNotifier,
    GoalSuggestionsState>((ref) {
  return GoalSuggestionsNotifier(ref);
});
