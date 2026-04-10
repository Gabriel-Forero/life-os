import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/habits/data/habits_repository.dart';
import 'package:life_os/features/habits/database/habits_dao.dart';
import 'package:life_os/features/habits/domain/models/habit_log_model.dart';
import 'package:life_os/features/habits/domain/models/habit_model.dart';

class DriftHabitsRepository implements HabitsRepository {
  DriftHabitsRepository({required this.dao});

  final HabitsDao dao;

  // --- Mapping helpers ---

  static HabitModel _toHabitModel(Habit row) => HabitModel(
        id: row.id.toString(),
        name: row.name,
        icon: row.icon,
        color: row.color,
        frequencyType: row.frequencyType,
        weeklyTarget: row.weeklyTarget,
        customDays: row.customDays,
        isQuantitative: row.isQuantitative,
        quantitativeTarget: row.quantitativeTarget,
        quantitativeUnit: row.quantitativeUnit,
        reminderTime: row.reminderTime,
        linkedEvent: row.linkedEvent,
        isArchived: row.isArchived,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static HabitLogModel _toHabitLogModel(HabitLog row) => HabitLogModel(
        id: row.id.toString(),
        habitId: row.habitId.toString(),
        date: row.date,
        completedAt: row.completedAt,
        value: row.value,
        createdAt: row.createdAt,
      );

  // --- Habits CRUD ---

  @override
  Future<String> insertHabit({
    required String name,
    required String icon,
    required int color,
    required String frequencyType,
    required int weeklyTarget,
    String? customDays,
    required bool isQuantitative,
    double? quantitativeTarget,
    String? quantitativeUnit,
    String? reminderTime,
    String? linkedEvent,
    required bool isArchived,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final id = await dao.insertHabit(HabitsCompanion.insert(
      name: name,
      icon: Value(icon),
      color: Value(color),
      frequencyType: frequencyType,
      weeklyTarget: Value(weeklyTarget),
      customDays: Value(customDays),
      isQuantitative: Value(isQuantitative),
      quantitativeTarget: Value(quantitativeTarget),
      quantitativeUnit: Value(quantitativeUnit),
      reminderTime: Value(reminderTime),
      linkedEvent: Value(linkedEvent),
      isArchived: Value(isArchived),
      createdAt: createdAt,
      updatedAt: updatedAt,
    ));
    return id.toString();
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    final intId = int.tryParse(habit.id);
    if (intId == null) return;
    final driftHabit = Habit(
      id: intId,
      name: habit.name,
      icon: habit.icon,
      color: habit.color,
      frequencyType: habit.frequencyType,
      weeklyTarget: habit.weeklyTarget,
      customDays: habit.customDays,
      isQuantitative: habit.isQuantitative,
      quantitativeTarget: habit.quantitativeTarget,
      quantitativeUnit: habit.quantitativeUnit,
      reminderTime: habit.reminderTime,
      linkedEvent: habit.linkedEvent,
      isArchived: habit.isArchived,
      createdAt: habit.createdAt,
      updatedAt: habit.updatedAt,
    );
    await dao.updateHabit(driftHabit);
  }

  @override
  Future<void> archiveHabit(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.archiveHabit(intId);
  }

  @override
  Future<void> restoreHabit(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.restoreHabit(intId);
  }

  @override
  Stream<List<HabitModel>> watchActiveHabits() {
    return dao
        .watchActiveHabits()
        .map((rows) => rows.map(_toHabitModel).toList());
  }

  @override
  Stream<List<HabitModel>> watchArchivedHabits() {
    return dao
        .watchArchivedHabits()
        .map((rows) => rows.map(_toHabitModel).toList());
  }

  // --- Habit Logs ---

  @override
  Future<void> insertHabitLog({
    required String habitId,
    required DateTime date,
    required DateTime completedAt,
    double? value,
    required DateTime createdAt,
  }) async {
    final intHabitId = int.parse(habitId);
    await dao.insertHabitLog(HabitLogsCompanion.insert(
      habitId: intHabitId,
      date: date,
      completedAt: completedAt,
      value: Value(value),
      createdAt: createdAt,
    ));
  }

  @override
  Future<void> deleteHabitLog(String habitId, DateTime date) async {
    final intId = int.tryParse(habitId);
    if (intId == null) return;
    await dao.deleteHabitLog(intId, date);
  }

  @override
  Future<HabitLogModel?> getLogForDate(String habitId, DateTime date) async {
    final intId = int.tryParse(habitId);
    if (intId == null) return null;
    final row = await dao.getLogForDate(intId, date);
    return row != null ? _toHabitLogModel(row) : null;
  }

  @override
  Stream<List<HabitLogModel>> watchHabitLogs(
    String habitId,
    DateTime from,
    DateTime to,
  ) {
    final intId = int.tryParse(habitId);
    if (intId == null) return Stream.value([]);
    return dao
        .watchHabitLogs(intId, from, to)
        .map((rows) => rows.map(_toHabitLogModel).toList());
  }

  // --- Streak / Stats ---

  @override
  Future<int> streakCount(String habitId, DateTime asOf) async {
    final intId = int.tryParse(habitId);
    if (intId == null) return 0;
    return dao.streakCount(intId, asOf);
  }

  @override
  Future<int> longestStreak(String habitId) async {
    final intId = int.tryParse(habitId);
    if (intId == null) return 0;
    return dao.longestStreak(intId);
  }

  @override
  Future<double> completionRate(
    String habitId,
    DateTime from,
    DateTime to,
  ) async {
    final intId = int.tryParse(habitId);
    if (intId == null) return 0;
    return dao.completionRate(intId, from, to);
  }
}
