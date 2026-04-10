class EnergyLogModel {
  const EnergyLogModel({
    required this.id,
    required this.date,
    required this.timeOfDay,
    required this.level,
    this.note,
    required this.createdAt,
  });

  final String id;
  final DateTime date;
  final String timeOfDay; // morning / afternoon / evening
  final int level; // 1–10
  final String? note;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'timeOfDay': timeOfDay,
        'level': level,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory EnergyLogModel.fromMap(Map<String, dynamic> map) => EnergyLogModel(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        timeOfDay: map['timeOfDay'] as String,
        level: map['level'] as int,
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
