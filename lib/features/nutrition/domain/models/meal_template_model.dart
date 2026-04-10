class MealTemplateModel {
  const MealTemplateModel({
    required this.id,
    required this.name,
    required this.mealType,
    required this.itemsJson,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String mealType;
  final String itemsJson;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'mealType': mealType,
        'itemsJson': itemsJson,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MealTemplateModel.fromMap(Map<String, dynamic> map) =>
      MealTemplateModel(
        id: map['id'] as String,
        name: map['name'] as String,
        mealType: map['mealType'] as String,
        itemsJson: map['itemsJson'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
