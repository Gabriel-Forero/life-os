class SleepInput {
  const SleepInput({
    required this.date,
    required this.bedTime,
    required this.wakeTime,
    required this.qualityRating,
    this.note,
  });

  final DateTime date;
  final DateTime bedTime;
  final DateTime wakeTime;
  final int qualityRating;
  final String? note;
}

class SleepInterruptionInput {
  const SleepInterruptionInput({
    required this.sleepLogId,
    required this.time,
    required this.durationMinutes,
    this.reason,
  });

  final String sleepLogId;
  final DateTime time;
  final int durationMinutes;
  final String? reason;
}

class EnergyInput {
  const EnergyInput({
    required this.date,
    required this.timeOfDay,
    required this.level,
    this.note,
  });

  final DateTime date;
  final String timeOfDay; // morning / afternoon / evening
  final int level; // 1–10
  final String? note;
}
