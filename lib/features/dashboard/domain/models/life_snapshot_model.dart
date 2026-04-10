class LifeSnapshotModel {
  const LifeSnapshotModel({
    required this.id,
    required this.date,
    required this.totalScore,
    required this.metricsJson,
    required this.createdAt,
  });

  final String id;
  final DateTime date;
  final int totalScore;
  final String metricsJson;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'totalScore': totalScore,
        'metricsJson': metricsJson,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LifeSnapshotModel.fromMap(Map<String, dynamic> map) =>
      LifeSnapshotModel(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        totalScore: map['totalScore'] as int,
        metricsJson: map['metricsJson'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
