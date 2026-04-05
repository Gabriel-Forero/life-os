import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';

const validTimeOfDay = {'morning', 'afternoon', 'evening'};

/// Calculates sleep score (0–100) using weighted formula:
/// - Duration: 40% — min(100, hoursSlept/8 * 100)
/// - Quality:  40% — (qualityRating/5) * 100
/// - Interruptions: 20% — max(0, 100 - interruptionCount * 15)
int calculateSleepScore({
  required double hoursSlept,
  required int qualityRating,
  required int interruptionCount,
}) {
  final durationScore = (hoursSlept / 8.0 * 100.0).clamp(0.0, 100.0);
  final qualityScore = (qualityRating / 5.0) * 100.0;
  final interruptionScore = (100 - interruptionCount * 15).clamp(0, 100).toDouble();

  final score =
      (durationScore * 0.40) + (qualityScore * 0.40) + (interruptionScore * 0.20);
  return score.round().clamp(0, 100);
}

Result<void> validateSleepTimes({
  required DateTime bedTime,
  required DateTime wakeTime,
}) {
  if (!wakeTime.isAfter(bedTime)) {
    return const Failure(ValidationFailure(
      userMessage: 'La hora de despertar debe ser posterior a la hora de dormir',
      debugMessage: 'wakeTime must be after bedTime',
      field: 'wakeTime',
    ));
  }
  final hours = wakeTime.difference(bedTime).inMinutes / 60.0;
  if (hours < 0.5) {
    return const Failure(ValidationFailure(
      userMessage: 'El tiempo de sueno minimo es 30 minutos',
      debugMessage: 'sleep duration too short (< 0.5h)',
      field: 'wakeTime',
    ));
  }
  if (hours > 24.0) {
    return const Failure(ValidationFailure(
      userMessage: 'El tiempo de sueno no puede superar 24 horas',
      debugMessage: 'sleep duration too long (> 24h)',
      field: 'wakeTime',
    ));
  }
  return const Success(null);
}

Result<int> validateQualityRating(int rating) {
  if (rating < 1 || rating > 5) {
    return Failure(ValidationFailure(
      userMessage: 'La calidad debe estar entre 1 y 5',
      debugMessage: 'qualityRating "$rating" out of range [1,5]',
      field: 'qualityRating',
      value: rating,
    ));
  }
  return Success(rating);
}

Result<String?> validateSleepNote(String? note) {
  if (note != null && note.length > 200) {
    return const Failure(ValidationFailure(
      userMessage: 'La nota no puede superar los 200 caracteres',
      debugMessage: 'sleep note exceeds 200 chars',
      field: 'note',
    ));
  }
  return Success(note);
}

Result<int> validateInterruptionDuration(int minutes) {
  if (minutes <= 0) {
    return const Failure(ValidationFailure(
      userMessage: 'La duracion debe ser mayor a 0 minutos',
      debugMessage: 'interruptionDuration must be > 0',
      field: 'durationMinutes',
    ));
  }
  return Success(minutes);
}

Result<String> validateTimeOfDay(String timeOfDay) {
  if (!validTimeOfDay.contains(timeOfDay)) {
    return Failure(ValidationFailure(
      userMessage: 'Momento del dia no valido',
      debugMessage: 'timeOfDay "$timeOfDay" not in $validTimeOfDay',
      field: 'timeOfDay',
      value: timeOfDay,
    ));
  }
  return Success(timeOfDay);
}

Result<int> validateEnergyLevel(int level) {
  if (level < 1 || level > 10) {
    return Failure(ValidationFailure(
      userMessage: 'El nivel de energia debe estar entre 1 y 10',
      debugMessage: 'energy level "$level" out of range [1,10]',
      field: 'level',
      value: level,
    ));
  }
  return Success(level);
}
