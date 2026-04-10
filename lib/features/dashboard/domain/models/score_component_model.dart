class ScoreComponentModel {
  const ScoreComponentModel({
    required this.id,
    required this.dayScoreId,
    required this.moduleKey,
    required this.rawValue,
    required this.weight,
    required this.weightedScore,
    required this.createdAt,
  });

  final String id;
  final String dayScoreId;
  final String moduleKey;
  final double rawValue;
  final double weight;
  final double weightedScore;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'dayScoreId': dayScoreId,
        'moduleKey': moduleKey,
        'rawValue': rawValue,
        'weight': weight,
        'weightedScore': weightedScore,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ScoreComponentModel.fromMap(Map<String, dynamic> map) =>
      ScoreComponentModel(
        id: map['id'] as String,
        dayScoreId: map['dayScoreId'] as String,
        moduleKey: map['moduleKey'] as String,
        rawValue: (map['rawValue'] as num).toDouble(),
        weight: (map['weight'] as num).toDouble(),
        weightedScore: (map['weightedScore'] as num).toDouble(),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
