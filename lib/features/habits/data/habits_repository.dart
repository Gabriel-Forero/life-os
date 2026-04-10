import 'package:life_os/features/habits/domain/models/habit_log_model.dart';
import 'package:life_os/features/habits/domain/models/habit_model.dart';

abstract class HabitsRepository {
  // --- Habits CRUD ---

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
  });

  Future<void> updateHabit(HabitModel habit);

  Future<void> archiveHabit(String id);

  Future<void> restoreHabit(String id);

  Stream<List<HabitModel>> watchActiveHabits();

  Stream<List<HabitModel>> watchArchivedHabits();

  // --- Habit Logs ---

  Future<void> insertHabitLog({
    required String habitId,
    required DateTime date,
    required DateTime completedAt,
    double? value,
    required DateTime createdAt,
  });

  Future<void> deleteHabitLog(String habitId, DateTime date);

  Future<HabitLogModel?> getLogForDate(String habitId, DateTime date);

  Stream<List<HabitLogModel>> watchHabitLogs(
    String habitId,
    DateTime from,
    DateTime to,
  );

  // --- Streak / Stats ---

  Future<int> streakCount(String habitId, DateTime asOf);

  Future<int> longestStreak(String habitId);

  Future<double> completionRate(String habitId, DateTime from, DateTime to);
}
