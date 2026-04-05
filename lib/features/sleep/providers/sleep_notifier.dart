import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/sleep/database/sleep_dao.dart';
import 'package:life_os/features/sleep/domain/sleep_input.dart';
import 'package:life_os/features/sleep/domain/sleep_validators.dart';

class SleepNotifier {
  SleepNotifier({required this.dao, required this.eventBus});

  final SleepDao dao;
  final EventBus eventBus;

  Future<Result<int>> logSleep(SleepInput input) async {
    // Validate times
    final timesResult = validateSleepTimes(
      bedTime: input.bedTime,
      wakeTime: input.wakeTime,
    );
    if (timesResult.isFailure) return Failure(timesResult.failureOrNull!);

    // Validate quality rating
    final qualityResult = validateQualityRating(input.qualityRating);
    if (qualityResult.isFailure) return Failure(qualityResult.failureOrNull!);

    // Validate note
    final noteResult = validateSleepNote(input.note);
    if (noteResult.isFailure) return Failure(noteResult.failureOrNull!);

    // Compute score (no interruptions at log time — added separately)
    final hoursSlept =
        input.wakeTime.difference(input.bedTime).inMinutes / 60.0;
    final score = calculateSleepScore(
      hoursSlept: hoursSlept,
      qualityRating: input.qualityRating,
      interruptionCount: 0,
    );

    try {
      final now = DateTime.now();
      final id = await dao.insertSleepLog(SleepLogsCompanion.insert(
        date: input.date,
        bedTime: input.bedTime,
        wakeTime: input.wakeTime,
        qualityRating: input.qualityRating,
        sleepScore: score,
        note: Value(input.note),
        createdAt: now,
      ));

      eventBus.emit(SleepLogSavedEvent(
        sleepLogId: id,
        sleepScore: score,
        hoursSlept: hoursSlept,
      ));

      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al registrar sueno',
        debugMessage: 'insertSleepLog failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<int>> addInterruption(SleepInterruptionInput input) async {
    final durationResult = validateInterruptionDuration(input.durationMinutes);
    if (durationResult.isFailure) return Failure(durationResult.failureOrNull!);

    try {
      final now = DateTime.now();
      final id = await dao.insertInterruption(SleepInterruptionsCompanion.insert(
        sleepLogId: input.sleepLogId,
        time: input.time,
        durationMinutes: input.durationMinutes,
        reason: Value(input.reason),
        createdAt: now,
      ));
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al registrar interrupcion',
        debugMessage: 'insertInterruption failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<int>> logEnergy(EnergyInput input) async {
    final timeResult = validateTimeOfDay(input.timeOfDay);
    if (timeResult.isFailure) return Failure(timeResult.failureOrNull!);

    final levelResult = validateEnergyLevel(input.level);
    if (levelResult.isFailure) return Failure(levelResult.failureOrNull!);

    try {
      final now = DateTime.now();
      final id = await dao.insertEnergyLog(EnergyLogsCompanion.insert(
        date: input.date,
        timeOfDay: input.timeOfDay,
        level: input.level,
        note: Value(input.note),
        createdAt: now,
      ));
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al registrar energia',
        debugMessage: 'insertEnergyLog failed: $e',
        originalError: e,
      ));
    }
  }
}
