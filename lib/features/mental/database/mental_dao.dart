import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/mental/database/mental_tables.dart';

part 'mental_dao.g.dart';

@DriftAccessor(tables: [MoodLogs, BreathingSessions])
class MentalDao extends DatabaseAccessor<AppDatabase> with _$MentalDaoMixin {
  MentalDao(super.db);

  // --- MoodLogs ---

  Future<int> insertMoodLog(MoodLogsCompanion entry) =>
      into(moodLogs).insert(entry);

  Future<List<MoodLog>> getMoodLogs(DateTime from, DateTime to) =>
      (select(moodLogs)
            ..where(
              (m) =>
                  m.date.isBiggerOrEqualValue(from) &
                  m.date.isSmallerOrEqualValue(to),
            )
            ..orderBy([(m) => OrderingTerm.desc(m.date)]))
          .get();

  Stream<List<MoodLog>> watchMoodLogs(DateTime from, DateTime to) =>
      (select(moodLogs)
            ..where(
              (m) =>
                  m.date.isBiggerOrEqualValue(from) &
                  m.date.isSmallerOrEqualValue(to),
            )
            ..orderBy([(m) => OrderingTerm.desc(m.date)]))
          .watch();

  Future<MoodLog?> getMoodLogById(int id) =>
      (select(moodLogs)..where((m) => m.id.equals(id))).getSingleOrNull();

  Future<void> deleteMoodLog(int id) =>
      (delete(moodLogs)..where((m) => m.id.equals(id))).go();

  // --- BreathingSessions ---

  Future<int> insertBreathingSession(BreathingSessionsCompanion entry) =>
      into(breathingSessions).insert(entry);

  Stream<List<BreathingSession>> watchBreathingSessions(
    DateTime from,
    DateTime to,
  ) =>
      (select(breathingSessions)
            ..where(
              (b) =>
                  b.createdAt.isBiggerOrEqualValue(from) &
                  b.createdAt.isSmallerOrEqualValue(to),
            )
            ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
          .watch();

  Future<List<BreathingSession>> getBreathingSessions(
    DateTime from,
    DateTime to,
  ) =>
      (select(breathingSessions)
            ..where(
              (b) =>
                  b.createdAt.isBiggerOrEqualValue(from) &
                  b.createdAt.isSmallerOrEqualValue(to),
            )
            ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
          .get();

  Future<int> countCompletedSessions() async {
    final all = await (select(breathingSessions)
          ..where((b) => b.isCompleted.equals(true)))
        .get();
    return all.length;
  }
}
