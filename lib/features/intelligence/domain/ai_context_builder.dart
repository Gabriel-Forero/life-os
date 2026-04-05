/// Builds a Spanish-language system prompt for the AI provider
/// from the current state of all LifeOS modules.
///
/// Callers pass a [ModuleSummary] record; missing values are omitted
/// from the prompt (never rendered as "null").
class ModuleSummary {
  const ModuleSummary({
    this.dayScore,
    this.caloriesToday,
    this.caloriesGoal,
    this.budgetUsedPercent,
    this.activeStreaks = const [],
    this.lastSleepScore,
    this.lastMoodLevel,
  });

  /// Today's DayScore (0–100), or null if not yet computed.
  final int? dayScore;

  /// Calories consumed today (kcal), or null if unavailable.
  final int? caloriesToday;

  /// Daily calorie goal (kcal), or null if no goal set.
  final int? caloriesGoal;

  /// Fraction of monthly budget used (0.0–1.0), or null if unavailable.
  final double? budgetUsedPercent;

  /// Active habit streaks as (name, streak-days) pairs.
  final List<({String name, int days})> activeStreaks;

  /// Last recorded sleep score (0–100), or null.
  final int? lastSleepScore;

  /// Last recorded mood level (1–10), or null.
  final int? lastMoodLevel;
}

/// Returns the system prompt string to inject at the start of every
/// AI conversation.
String buildAIContext(ModuleSummary summary) {
  final lines = <String>[
    'Eres un asistente de vida inteligente integrado en LifeOS.',
    'Contexto actual del usuario:',
  ];

  if (summary.dayScore != null) {
    lines.add('- Puntuacion del dia: ${summary.dayScore}/100');
  }

  if (summary.caloriesToday != null && summary.caloriesGoal != null) {
    lines.add(
      '- Calorias: ${summary.caloriesToday} de ${summary.caloriesGoal} kcal consumidas hoy',
    );
  } else if (summary.caloriesToday != null) {
    lines.add('- Calorias consumidas hoy: ${summary.caloriesToday} kcal');
  }

  if (summary.budgetUsedPercent != null) {
    final pct = (summary.budgetUsedPercent! * 100).round();
    lines.add('- Presupuesto: $pct% utilizado este mes');
  }

  if (summary.activeStreaks.isNotEmpty) {
    final streakParts = summary.activeStreaks
        .map((s) => '${s.name} (${s.days} dias)')
        .join(', ');
    lines.add('- Rachas activas: $streakParts');
  }

  if (summary.lastSleepScore != null) {
    lines.add('- Ultimo puntaje de sueno: ${summary.lastSleepScore}/100');
  }

  if (summary.lastMoodLevel != null) {
    lines.add('- Ultimo estado de animo: ${summary.lastMoodLevel}/10');
  }

  lines.add('Responde siempre en espanol. Se conciso y motivador.');
  return lines.join('\n');
}
