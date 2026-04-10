class MoodLogModel {
  const MoodLogModel({
    required this.id,
    required this.date,
    required this.valence,
    required this.energy,
    required this.tags,
    this.journalNote,
    required this.createdAt,
  });

  final String id;
  final DateTime date;
  final int valence; // 1–5 (negative→positive)
  final int energy; // 1–5 (low→high)
  final String tags; // comma-separated
  final String? journalNote;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'valence': valence,
        'energy': energy,
        'tags': tags,
        'journalNote': journalNote,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MoodLogModel.fromMap(Map<String, dynamic> map) => MoodLogModel(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        valence: map['valence'] as int,
        energy: map['energy'] as int,
        tags: map['tags'] as String? ?? '',
        journalNote: map['journalNote'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
