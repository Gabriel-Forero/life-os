import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/habits/database/habits_tables.dart';

part 'habits_dao.g.dart';

@DriftAccessor(tables: [Habits, HabitLogs])
class HabitsDao extends DatabaseAccessor<AppDatabase>
    with _$HabitsDaoMixin {
  HabitsDao(super.db);

  // --- Habits CRUD ---

  Future<int> insertHabit(HabitsCompanion entry) =>
      into(habits).insert(entry);

  Future<void> updateHabit(Habit entry) =>
      (update(habits)..where((h) => h.id.equals(entry.id))).write(
        HabitsCompanion(
          name: Value(entry.name),
          icon: Value(entry.icon),
          color: Value(entry.color),
          frequencyType: Value(entry.frequencyType),
          weeklyTarget: Value(entry.weeklyTarget),
          customDays: Value(entry.customDays),
          isQuantitative: Value(entry.isQuantitative),
          quantitativeTarget: Value(entry.quantitativeTarget),
          quantitativeUnit: Value(entry.quantitativeUnit),
          reminderTime: Value(entry.reminderTime),
          linkedEvent: Value(entry.linkedEvent),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> archiveHabit(int id) =>
      (update(habits)..where((h) => h.id.equals(id)))
          .write(HabitsCompanion(
        isArchived: const Value(true),
        updatedAt: Value(DateTime.now()),
      ));

  Future<void> restoreHabit(int id) =>
      (update(habits)..where((h) => h.id.equals(id)))
          .write(HabitsCompanion(
        isArchived: const Value(false),
        updatedAt: Value(DateTime.now()),
      ));

  Stream<List<Habit>> watchActiveHabits() =>
      (select(habits)
            ..where((h) => h.isArchived.equals(false))
            ..orderBy([(h) => OrderingTerm.asc(h.name)]))
          .watch();

  Stream<List<Habit>> watchArchivedHabits() =>
      (select(habits)
            ..where((h) => h.isArchived.equals(true))
            ..orderBy([(h) => OrderingTerm.asc(h.name)]))
          .watch();

  // --- Habit Logs ---

  Future<void> insertHabitLog(HabitLogsCompanion entry) =>
      into(habitLogs).insert(entry);

  Future<void> deleteHabitLog(int habitId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (delete(habitLogs)
          ..where(
            (l) =>
                l.habitId.equals(habitId) &
                l.date.isBiggerOrEqualValue(start) &
                l.date.isSmallerThanValue(end),
          ))
        .go();
  }

  Future<HabitLog?> getLogForDate(int habitId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(habitLogs)
          ..where(
            (l) =>
                l.habitId.equals(habitId) &
                l.date.isBiggerOrEqualValue(start) &
                l.date.isSmallerThanValue(end),
          ))
        .getSingleOrNull();
  }

  Stream<List<HabitLog>> watchHabitLogs(
    int habitId,
    DateTime from,
    DateTime to,
  ) =>
      (select(habitLogs)
            ..where(
              (l) =>
                  l.habitId.equals(habitId) &
                  l.date.isBiggerOrEqualValue(from) &
                  l.date.isSmallerOrEqualValue(to),
            )
            ..orderBy([(l) => OrderingTerm.desc(l.date)]))
          .watch();

  // --- Streak Calculation (daily habits) ---

  Future<int> streakCount(int habitId, DateTime asOf) async {
    final today = DateTime(asOf.year, asOf.month, asOf.day);
    var streak = 0;
    var checkDate = today;

    while (true) {
      final log = await getLogForDate(habitId, checkDate);
      if (log == null) break;
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  Future<int> longestStreak(int habitId) async {
    final logs = await (select(habitLogs)
          ..where((l) => l.habitId.equals(habitId))
          ..orderBy([(l) => OrderingTerm.asc(l.date)]))
        .get();

    if (logs.isEmpty) return 0;

    var longest = 1;
    var current = 1;

    for (var i = 1; i < logs.length; i++) {
      final prevDate = DateTime(
        logs[i - 1].date.year,
        logs[i - 1].date.month,
        logs[i - 1].date.day,
      );
      final currDate = DateTime(
        logs[i].date.year,
        logs[i].date.month,
        logs[i].date.day,
      );
      final diff = currDate.difference(prevDate).inDays;

      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else if (diff > 1) {
        current = 1;
      }
      // diff == 0 means same day (duplicate), skip
    }

    return longest;
  }

  Future<double> completionRate(
    int habitId,
    DateTime from,
    DateTime to,
  ) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    final totalDays = end.difference(start).inDays + 1;
    if (totalDays <= 0) return 0;

    final logs = await (select(habitLogs)
          ..where(
            (l) =>
                l.habitId.equals(habitId) &
                l.date.isBiggerOrEqualValue(start) &
                l.date.isSmallerOrEqualValue(end),
          ))
        .get();

    return logs.length / totalDays;
  }
}
