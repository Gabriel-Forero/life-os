import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/mental/data/mental_repository.dart';
import 'package:life_os/features/mental/domain/mental_input.dart';
import 'package:life_os/features/mental/domain/mental_validators.dart';

class MentalNotifier {
  MentalNotifier({required this.repository, required this.eventBus});

  final MentalRepository repository;
  final EventBus eventBus;

  Future<Result<String>> logMood(MoodInput input) async {
    final valenceResult = validateValence(input.valence);
    if (valenceResult.isFailure) return Failure(valenceResult.failureOrNull!);

    final energyResult = validateMoodEnergy(input.energy);
    if (energyResult.isFailure) return Failure(energyResult.failureOrNull!);

    final noteResult = validateJournalNote(input.journalNote);
    if (noteResult.isFailure) return Failure(noteResult.failureOrNull!);

    final tagsResult = validateTags(input.tags);
    if (tagsResult.isFailure) return Failure(tagsResult.failureOrNull!);

    final moodScore = calculateMoodScore(
      valence: input.valence,
      energy: input.energy,
    );
    final tagsString = input.tags.join(',');

    try {
      final now = DateTime.now();
      final id = await repository.insertMoodLog(
        date: input.date,
        valence: input.valence,
        energy: input.energy,
        tags: tagsString,
        journalNote: input.journalNote,
        createdAt: now,
      );

      eventBus.emit(MoodLoggedEvent(
        moodLogId: int.tryParse(id) ?? 0,
        level: moodScore,
        tags: input.tags,
      ));

      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al registrar estado de animo',
        debugMessage: 'insertMoodLog failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<String>> startBreathingSession(
    BreathingSessionInput input,
  ) async {
    final techniqueResult = validateBreathingTechnique(input.techniqueName);
    if (techniqueResult.isFailure) {
      return Failure(techniqueResult.failureOrNull!);
    }

    final durationResult = validateBreathingDuration(input.durationSeconds);
    if (durationResult.isFailure) return Failure(durationResult.failureOrNull!);

    try {
      final now = DateTime.now();
      final id = await repository.insertBreathingSession(
        techniqueName: input.techniqueName,
        durationSeconds: input.durationSeconds,
        isCompleted: input.isCompleted,
        createdAt: now,
      );
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al guardar sesion de respiracion',
        debugMessage: 'insertBreathingSession failed: $e',
        originalError: e,
      ));
    }
  }
}
