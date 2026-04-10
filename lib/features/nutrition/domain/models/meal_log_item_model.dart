class MealLogItemModel {
  const MealLogItemModel({
    required this.id,
    required this.mealLogId,
    required this.foodItemId,
    required this.quantityG,
    required this.createdAt,
  });

  final String id;
  final String mealLogId;
  final String foodItemId;
  final double quantityG;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'mealLogId': mealLogId,
        'foodItemId': foodItemId,
        'quantityG': quantityG,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MealLogItemModel.fromMap(Map<String, dynamic> map) =>
      MealLogItemModel(
        id: map['id'] as String,
        mealLogId: map['mealLogId'] as String,
        foodItemId: map['foodItemId'] as String,
        quantityG: (map['quantityG'] as num).toDouble(),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
