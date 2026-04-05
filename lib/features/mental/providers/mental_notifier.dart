import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/mental/database/mental_dao.dart';
import 'package:life_os/features/mental/domain/mental_input.dart';
import 'package:life_os/features/mental/domain/mental_validators.dart';

class MentalNotifier {
  MentalNotifier({required this.dao, required this.eventBus});

  final MentalDao dao;
  final EventBus eventBus;

  Future<Result<int>> logMood(MoodInput input) async {
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
      final id = await dao.insertMoodLog(MoodLogsCompanion.insert(
        date: input.date,
        valence: input.valence,
        energy: input.energy,
        tags: Value(tagsString),
        journalNote: Value(input.journalNote),
        createdAt: now,
      ));

      eventBus.emit(MoodLoggedEvent(
        moodLogId: id,
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

  Future<Result<int>> startBreathingSession(
    BreathingSessionInput input,
  ) async {
    final techniqueResult = validateBreathingTechnique(input.techniqueName);
    if (techniqueResult.isFailure)
      return Failure(techniqueResult.failureOrNull!);

    final durationResult = validateBreathingDuration(input.durationSeconds);
    if (durationResult.isFailure) return Failure(durationResult.failureOrNull!);

    try {
      final now = DateTime.now();
      final id = await dao.insertBreathingSession(
        BreathingSessionsCompanion.insert(
          techniqueName: input.techniqueName,
          durationSeconds: input.durationSeconds,
          isCompleted: Value(input.isCompleted),
          createdAt: now,
        ),
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
