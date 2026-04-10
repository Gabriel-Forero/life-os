class NutritionGoalModel {
  const NutritionGoalModel({
    required this.id,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.waterMl,
    required this.effectiveDate,
    required this.createdAt,
  });

  final String id;
  final int caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int waterMl;
  final DateTime effectiveDate;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'caloriesKcal': caloriesKcal,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'waterMl': waterMl,
        'effectiveDate': effectiveDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory NutritionGoalModel.fromMap(Map<String, dynamic> map) =>
      NutritionGoalModel(
        id: map['id'] as String,
        caloriesKcal: map['caloriesKcal'] as int,
        proteinG: (map['proteinG'] as num).toDouble(),
        carbsG: (map['carbsG'] as num).toDouble(),
        fatG: (map['fatG'] as num).toDouble(),
        waterMl: map['waterMl'] as int,
        effectiveDate: DateTime.parse(map['effectiveDate'] as String),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
