import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/sleep/database/sleep_tables.dart';

part 'sleep_dao.g.dart';

@DriftAccessor(tables: [SleepLogs, SleepInterruptions, EnergyLogs])
class SleepDao extends DatabaseAccessor<AppDatabase> with _$SleepDaoMixin {
  SleepDao(super.db);

  // --- SleepLogs CRUD ---

  Future<int> insertSleepLog(SleepLogsCompanion entry) =>
      into(sleepLogs).insert(entry);

  Future<void> updateSleepLog(SleepLog entry) =>
      (update(sleepLogs)..where((s) => s.id.equals(entry.id))).write(
        SleepLogsCompanion(
          date: Value(entry.date),
          bedTime: Value(entry.bedTime),
          wakeTime: Value(entry.wakeTime),
          qualityRating: Value(entry.qualityRating),
          sleepScore: Value(entry.sleepScore),
          note: Value(entry.note),
        ),
      );

  Future<void> deleteSleepLog(int id) =>
      (delete(sleepLogs)..where((s) => s.id.equals(id))).go();

  Future<SleepLog?> getSleepLogById(int id) =>
      (select(sleepLogs)..where((s) => s.id.equals(id))).getSingleOrNull();

  Stream<List<SleepLog>> watchSleepLogs(DateTime from, DateTime to) =>
      (select(sleepLogs)
            ..where(
              (s) =>
                  s.date.isBiggerOrEqualValue(from) &
                  s.date.isSmallerOrEqualValue(to),
            )
            ..orderBy([(s) => OrderingTerm.desc(s.date)]))
          .watch();

  Future<SleepLog?> getSleepLogForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(sleepLogs)
          ..where(
            (s) =>
                s.date.isBiggerOrEqualValue(start) &
                s.date.isSmallerThanValue(end),
          ))
        .getSingleOrNull();
  }

  // --- SleepInterruptions ---

  Future<int> insertInterruption(SleepInterruptionsCompanion entry) =>
      into(sleepInterruptions).insert(entry);

  Future<List<SleepInterruption>> getInterruptionsForLog(int sleepLogId) =>
      (select(sleepInterruptions)
            ..where((i) => i.sleepLogId.equals(sleepLogId))
            ..orderBy([(i) => OrderingTerm.asc(i.time)]))
          .get();

  Stream<List<SleepInterruption>> watchInterruptionsForLog(int sleepLogId) =>
      (select(sleepInterruptions)
            ..where((i) => i.sleepLogId.equals(sleepLogId))
            ..orderBy([(i) => OrderingTerm.asc(i.time)]))
          .watch();

  Future<void> deleteInterruption(int id) =>
      (delete(sleepInterruptions)..where((i) => i.id.equals(id))).go();

  // --- EnergyLogs ---

  Future<int> insertEnergyLog(EnergyLogsCompanion entry) =>
      into(energyLogs).insert(entry, mode: InsertMode.insertOrReplace);

  Stream<List<EnergyLog>> watchEnergyLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(energyLogs)
          ..where(
            (e) =>
                e.date.isBiggerOrEqualValue(start) &
                e.date.isSmallerThanValue(end),
          )
          ..orderBy([(e) => OrderingTerm.asc(e.timeOfDay)]))
        .watch();
  }

  Stream<List<EnergyLog>> watchEnergyLogs(DateTime from, DateTime to) =>
      (select(energyLogs)
            ..where(
              (e) =>
                  e.date.isBiggerOrEqualValue(from) &
                  e.date.isSmallerOrEqualValue(to),
            )
            ..orderBy([(e) => OrderingTerm.desc(e.date)]))
          .watch();

  Future<EnergyLog?> getEnergyLogForTimeOfDay(
    DateTime date,
    String timeOfDay,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(energyLogs)
          ..where(
            (e) =>
                e.date.isBiggerOrEqualValue(start) &
                e.date.isSmallerThanValue(end) &
                e.timeOfDay.equals(timeOfDay),
          ))
        .getSingleOrNull();
  }
}
