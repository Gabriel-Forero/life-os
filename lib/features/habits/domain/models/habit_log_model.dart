class HabitLogModel {
  const HabitLogModel({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completedAt,
    this.value,
    required this.createdAt,
  });

  final String id;
  final String habitId;
  final DateTime date;
  final DateTime completedAt;
  final double? value;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'habitId': habitId,
        'date': date.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'value': value,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HabitLogModel.fromMap(Map<String, dynamic> map) => HabitLogModel(
        id: map['id'] as String,
        habitId: map['habitId'] as String,
        date: DateTime.parse(map['date'] as String),
        completedAt: DateTime.parse(map['completedAt'] as String),
        value: (map['value'] as num?)?.toDouble(),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
