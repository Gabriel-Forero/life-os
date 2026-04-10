import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/sleep/data/sleep_repository.dart';
import 'package:life_os/features/sleep/database/sleep_dao.dart';
import 'package:life_os/features/sleep/domain/models/energy_log_model.dart';
import 'package:life_os/features/sleep/domain/models/sleep_interruption_model.dart';
import 'package:life_os/features/sleep/domain/models/sleep_log_model.dart';

class DriftSleepRepository implements SleepRepository {
  DriftSleepRepository({required this.dao});

  final SleepDao dao;

  // --- Mapping helpers ---

  static SleepLogModel _toSleepLogModel(SleepLog row) => SleepLogModel(
        id: row.id.toString(),
        date: row.date,
        bedTime: row.bedTime,
        wakeTime: row.wakeTime,
        qualityRating: row.qualityRating,
        sleepScore: row.sleepScore,
        note: row.note,
        createdAt: row.createdAt,
      );

  static SleepInterruptionModel _toInterruptionModel(
    SleepInterruption row,
  ) =>
      SleepInterruptionModel(
        id: row.id.toString(),
        sleepLogId: row.sleepLogId.toString(),
        time: row.time,
        durationMinutes: row.durationMinutes,
        reason: row.reason,
        createdAt: row.createdAt,
      );

  static EnergyLogModel _toEnergyLogModel(EnergyLog row) => EnergyLogModel(
        id: row.id.toString(),
        date: row.date,
        timeOfDay: row.timeOfDay,
        level: row.level,
        note: row.note,
        createdAt: row.createdAt,
      );

  // --- SleepLogs ---

  @override
  Future<String> insertSleepLog({
    required DateTime date,
    required DateTime bedTime,
    required DateTime wakeTime,
    required int qualityRating,
    required int sleepScore,
    String? note,
    required DateTime createdAt,
  }) async {
    final id = await dao.insertSleepLog(SleepLogsCompanion.insert(
      date: date,
      bedTime: bedTime,
      wakeTime: wakeTime,
      qualityRating: qualityRating,
      sleepScore: sleepScore,
      note: Value(note),
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Future<void> updateSleepLog(SleepLogModel log) async {
    final intId = int.tryParse(log.id);
    if (intId == null) return;
    final driftLog = SleepLog(
      id: intId,
      date: log.date,
      bedTime: log.bedTime,
      wakeTime: log.wakeTime,
      qualityRating: log.qualityRating,
      sleepScore: log.sleepScore,
      note: log.note,
      createdAt: log.createdAt,
    );
    await dao.updateSleepLog(driftLog);
  }

  @override
  Future<void> deleteSleepLog(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.deleteSleepLog(intId);
  }

  @override
  Future<SleepLogModel?> getSleepLogById(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return null;
    final row = await dao.getSleepLogById(intId);
    return row != null ? _toSleepLogModel(row) : null;
  }

  @override
  Stream<List<SleepLogModel>> watchSleepLogs(DateTime from, DateTime to) {
    return dao
        .watchSleepLogs(from, to)
        .map((rows) => rows.map(_toSleepLogModel).toList());
  }

  @override
  Future<SleepLogModel?> getSleepLogForDate(DateTime date) async {
    final row = await dao.getSleepLogForDate(date);
    return row != null ? _toSleepLogModel(row) : null;
  }

  // --- SleepInterruptions ---

  @override
  Future<String> insertInterruption({
    required String sleepLogId,
    required DateTime time,
    required int durationMinutes,
    String? reason,
    required DateTime createdAt,
  }) async {
    final intSleepLogId = int.parse(sleepLogId);
    final id = await dao.insertInterruption(
      SleepInterruptionsCompanion.insert(
        sleepLogId: intSleepLogId,
        time: time,
        durationMinutes: durationMinutes,
        reason: Value(reason),
        createdAt: createdAt,
      ),
    );
    return id.toString();
  }

  @override
  Future<List<SleepInterruptionModel>> getInterruptionsForLog(
    String sleepLogId,
  ) async {
    final intId = int.tryParse(sleepLogId);
    if (intId == null) return [];
    final rows = await dao.getInterruptionsForLog(intId);
    return rows.map(_toInterruptionModel).toList();
  }

  @override
  Stream<List<SleepInterruptionModel>> watchInterruptionsForLog(
    String sleepLogId,
  ) {
    final intId = int.tryParse(sleepLogId);
    if (intId == null) return Stream.value([]);
    return dao
        .watchInterruptionsForLog(intId)
        .map((rows) => rows.map(_toInterruptionModel).toList());
  }

  @override
  Future<void> deleteInterruption(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.deleteInterruption(intId);
  }

  // --- EnergyLogs ---

  @override
  Future<String> insertEnergyLog({
    required DateTime date,
    required String timeOfDay,
    required int level,
    String? note,
    required DateTime createdAt,
  }) async {
    final id = await dao.insertEnergyLog(EnergyLogsCompanion.insert(
      date: date,
      timeOfDay: timeOfDay,
      level: level,
      note: Value(note),
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Stream<List<EnergyLogModel>> watchEnergyLogsForDate(DateTime date) {
    return dao
        .watchEnergyLogsForDate(date)
        .map((rows) => rows.map(_toEnergyLogModel).toList());
  }

  @override
  Stream<List<EnergyLogModel>> watchEnergyLogs(DateTime from, DateTime to) {
    return dao
        .watchEnergyLogs(from, to)
        .map((rows) => rows.map(_toEnergyLogModel).toList());
  }

  @override
  Future<EnergyLogModel?> getEnergyLogForTimeOfDay(
    DateTime date,
    String timeOfDay,
  ) async {
    final row = await dao.getEnergyLogForTimeOfDay(date, timeOfDay);
    return row != null ? _toEnergyLogModel(row) : null;
  }
}
