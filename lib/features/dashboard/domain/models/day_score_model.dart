class DayScoreModel {
  const DayScoreModel({
    required this.id,
    required this.date,
    required this.totalScore,
    required this.calculatedAt,
    required this.createdAt,
  });

  final String id;
  final DateTime date;
  final int totalScore;
  final DateTime calculatedAt;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'totalScore': totalScore,
        'calculatedAt': calculatedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory DayScoreModel.fromMap(Map<String, dynamic> map) => DayScoreModel(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        totalScore: map['totalScore'] as int,
        calculatedAt: DateTime.parse(map['calculatedAt'] as String),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
