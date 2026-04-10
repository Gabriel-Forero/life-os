class SleepLogModel {
  const SleepLogModel({
    required this.id,
    required this.date,
    required this.bedTime,
    required this.wakeTime,
    required this.qualityRating,
    required this.sleepScore,
    this.note,
    required this.createdAt,
  });

  final String id;
  final DateTime date;
  final DateTime bedTime;
  final DateTime wakeTime;
  final int qualityRating; // 1–5
  final int sleepScore; // 0–100
  final String? note;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'bedTime': bedTime.toIso8601String(),
        'wakeTime': wakeTime.toIso8601String(),
        'qualityRating': qualityRating,
        'sleepScore': sleepScore,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SleepLogModel.fromMap(Map<String, dynamic> map) => SleepLogModel(
        id: map['id'] as String,
        date: DateTime.parse(map['date'] as String),
        bedTime: DateTime.parse(map['bedTime'] as String),
        wakeTime: DateTime.parse(map['wakeTime'] as String),
        qualityRating: map['qualityRating'] as int,
        sleepScore: map['sleepScore'] as int,
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
