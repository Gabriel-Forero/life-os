class SleepInterruptionModel {
  const SleepInterruptionModel({
    required this.id,
    required this.sleepLogId,
    required this.time,
    required this.durationMinutes,
    this.reason,
    required this.createdAt,
  });

  final String id;
  final String sleepLogId;
  final DateTime time;
  final int durationMinutes;
  final String? reason;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'sleepLogId': sleepLogId,
        'time': time.toIso8601String(),
        'durationMinutes': durationMinutes,
        'reason': reason,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SleepInterruptionModel.fromMap(Map<String, dynamic> map) =>
      SleepInterruptionModel(
        id: map['id'] as String,
        sleepLogId: map['sleepLogId'] as String,
        time: DateTime.parse(map['time'] as String),
        durationMinutes: map['durationMinutes'] as int,
        reason: map['reason'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
