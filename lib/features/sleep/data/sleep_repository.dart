import 'package:life_os/features/sleep/domain/models/energy_log_model.dart';
import 'package:life_os/features/sleep/domain/models/sleep_interruption_model.dart';
import 'package:life_os/features/sleep/domain/models/sleep_log_model.dart';

abstract class SleepRepository {
  // --- SleepLogs ---

  Future<String> insertSleepLog({
    required DateTime date,
    required DateTime bedTime,
    required DateTime wakeTime,
    required int qualityRating,
    required int sleepScore,
    String? note,
    required DateTime createdAt,
  });

  Future<void> updateSleepLog(SleepLogModel log);

  Future<void> deleteSleepLog(String id);

  Future<SleepLogModel?> getSleepLogById(String id);

  Stream<List<SleepLogModel>> watchSleepLogs(DateTime from, DateTime to);

  Future<SleepLogModel?> getSleepLogForDate(DateTime date);

  // --- SleepInterruptions ---

  Future<String> insertInterruption({
    required String sleepLogId,
    required DateTime time,
    required int durationMinutes,
    String? reason,
    required DateTime createdAt,
  });

  Future<List<SleepInterruptionModel>> getInterruptionsForLog(
    String sleepLogId,
  );

  Stream<List<SleepInterruptionModel>> watchInterruptionsForLog(
    String sleepLogId,
  );

  Future<void> deleteInterruption(String id);

  // --- EnergyLogs ---

  Future<String> insertEnergyLog({
    required DateTime date,
    required String timeOfDay,
    required int level,
    String? note,
    required DateTime createdAt,
  });

  Stream<List<EnergyLogModel>> watchEnergyLogsForDate(DateTime date);

  Stream<List<EnergyLogModel>> watchEnergyLogs(DateTime from, DateTime to);

  Future<EnergyLogModel?> getEnergyLogForTimeOfDay(
    DateTime date,
    String timeOfDay,
  );
}
