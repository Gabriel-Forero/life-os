class MealLogModel {
  const MealLogModel({
    required this.id,
    required this.date,
    required this.mealType,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final String mealType;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'mealType': mealType,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MealLogModel.fromMap(Map<String, dynamic> map) => MealLogModel(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        mealType: map['mealType'] as String,
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
