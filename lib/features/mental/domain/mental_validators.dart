import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';

// ---------------------------------------------------------------------------
// Breathing Technique Definitions (immutable)
// ---------------------------------------------------------------------------

class BreathingTechnique {
  const BreathingTechnique({
    required this.key,
    required this.displayName,
    required this.inhaleSeconds,
    required this.hold1Seconds,
    required this.exhaleSeconds,
    required this.hold2Seconds,
  });

  final String key;
  final String displayName;
  final int inhaleSeconds;
  final int hold1Seconds;
  final int exhaleSeconds;
  final int hold2Seconds;

  /// Total cycle duration in seconds.
  int get cycleDuration =>
      inhaleSeconds + hold1Seconds + exhaleSeconds + hold2Seconds;
}

const breathingTechniques = <String, BreathingTechnique>{
  'box': BreathingTechnique(
    key: 'box',
    displayName: 'Respiracion Cuadrada',
    inhaleSeconds: 4,
    hold1Seconds: 4,
    exhaleSeconds: 4,
    hold2Seconds: 4,
  ),
  '4_7_8': BreathingTechnique(
    key: '4_7_8',
    displayName: 'Tecnica 4-7-8',
    inhaleSeconds: 4,
    hold1Seconds: 7,
    exhaleSeconds: 8,
    hold2Seconds: 0,
  ),
  'coherent': BreathingTechnique(
    key: 'coherent',
    displayName: 'Respiracion Coherente',
    inhaleSeconds: 5,
    hold1Seconds: 0,
    exhaleSeconds: 5,
    hold2Seconds: 0,
  ),
  'diaphragmatic': BreathingTechnique(
    key: 'diaphragmatic',
    displayName: 'Respiracion Diafragmatica',
    inhaleSeconds: 4,
    hold1Seconds: 0,
    exhaleSeconds: 6,
    hold2Seconds: 0,
  ),
};

// ---------------------------------------------------------------------------
// Mood Score
// ---------------------------------------------------------------------------

/// moodScore = ((valence-1)/4 * 50) + ((energy-1)/4 * 50) → 0–100
int calculateMoodScore({required int valence, required int energy}) {
  final v = ((valence - 1) / 4.0 * 50.0);
  final e = ((energy - 1) / 4.0 * 50.0);
  return (v + e).round().clamp(0, 100);
}

// ---------------------------------------------------------------------------
// Validators
// ---------------------------------------------------------------------------

Result<int> validateValence(int valence) {
  if (valence < 1 || valence > 5) {
    return Failure(ValidationFailure(
      userMessage: 'La valencia debe estar entre 1 y 5',
      debugMessage: 'valence "$valence" out of range [1,5]',
      field: 'valence',
      value: valence,
    ));
  }
  return Success(valence);
}

Result<int> validateMoodEnergy(int energy) {
  if (energy < 1 || energy > 5) {
    return Failure(ValidationFailure(
      userMessage: 'La energia debe estar entre 1 y 5',
      debugMessage: 'mood energy "$energy" out of range [1,5]',
      field: 'energy',
      value: energy,
    ));
  }
  return Success(energy);
}

Result<String?> validateJournalNote(String? note) {
  if (note != null && note.length > 280) {
    return const Failure(ValidationFailure(
      userMessage: 'La nota no puede superar los 280 caracteres',
      debugMessage: 'journal note exceeds 280 chars',
      field: 'journalNote',
    ));
  }
  return Success(note);
}

Result<List<String>> validateTags(List<String> tags) {
  if (tags.length > 10) {
    return const Failure(ValidationFailure(
      userMessage: 'Maximo 10 etiquetas permitidas',
      debugMessage: 'tags count > 10',
      field: 'tags',
    ));
  }
  for (final tag in tags) {
    if (tag.length > 30) {
      return Failure(ValidationFailure(
        userMessage: 'Cada etiqueta puede tener maximo 30 caracteres',
        debugMessage: 'tag "$tag" exceeds 30 chars',
        field: 'tags',
        value: tag,
      ));
    }
  }
  return Success(tags);
}

Result<String> validateBreathingTechnique(String techniqueName) {
  if (!breathingTechniques.containsKey(techniqueName)) {
    return Failure(ValidationFailure(
      userMessage: 'Tecnica de respiracion no valida',
      debugMessage:
          'techniqueName "$techniqueName" not in ${breathingTechniques.keys}',
      field: 'techniqueName',
      value: techniqueName,
    ));
  }
  return Success(techniqueName);
}

Result<int> validateBreathingDuration(int seconds) {
  if (seconds <= 0) {
    return const Failure(ValidationFailure(
      userMessage: 'La duracion debe ser mayor a 0 segundos',
      debugMessage: 'durationSeconds must be > 0',
      field: 'durationSeconds',
    ));
  }
  return Success(seconds);
}
