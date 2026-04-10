class DayScoreConfigModel {
  const DayScoreConfigModel({
    required this.id,
    required this.moduleKey,
    required this.weight,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String moduleKey;
  final double weight;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'moduleKey': moduleKey,
        'weight': weight,
        'isEnabled': isEnabled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DayScoreConfigModel.fromMap(Map<String, dynamic> map) =>
      DayScoreConfigModel(
        id: map['id'] as String,
        moduleKey: map['moduleKey'] as String,
        weight: (map['weight'] as num).toDouble(),
        isEnabled: map['isEnabled'] as bool,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
