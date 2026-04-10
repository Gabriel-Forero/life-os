class BreathingSessionModel {
  const BreathingSessionModel({
    required this.id,
    required this.techniqueName,
    required this.durationSeconds,
    required this.isCompleted,
    required this.createdAt,
  });

  final String id;
  final String techniqueName; // box / 4_7_8 / coherent / diaphragmatic
  final int durationSeconds;
  final bool isCompleted;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'techniqueName': techniqueName,
        'durationSeconds': durationSeconds,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BreathingSessionModel.fromMap(Map<String, dynamic> map) =>
      BreathingSessionModel(
        id: map['id'] as String,
        techniqueName: map['techniqueName'] as String,
        durationSeconds: map['durationSeconds'] as int,
        isCompleted: map['isCompleted'] as bool? ?? false,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
