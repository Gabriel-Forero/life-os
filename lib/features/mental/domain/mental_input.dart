class MoodInput {
  const MoodInput({
    required this.date,
    required this.valence,
    required this.energy,
    this.tags = const [],
    this.journalNote,
  });

  final DateTime date;
  final int valence; // 1–5
  final int energy; // 1–5
  final List<String> tags;
  final String? journalNote;
}

class BreathingSessionInput {
  const BreathingSessionInput({
    required this.techniqueName,
    required this.durationSeconds,
    required this.isCompleted,
  });

  final String techniqueName; // box / 4_7_8 / coherent
  final int durationSeconds;
  final bool isCompleted;
}
