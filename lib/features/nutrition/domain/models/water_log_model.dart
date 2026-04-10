class WaterLogModel {
  const WaterLogModel({
    required this.id,
    required this.date,
    required this.amountMl,
    required this.time,
    required this.createdAt,
  });

  final String id;
  final DateTime date;
  final int amountMl;
  final DateTime time;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'amountMl': amountMl,
        'time': time.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory WaterLogModel.fromMap(Map<String, dynamic> map) => WaterLogModel(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        amountMl: map['amountMl'] as int,
        time: DateTime.parse(map['time'] as String),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
