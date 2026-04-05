import 'package:flutter/foundation.dart';

sealed class AppEvent {
  AppEvent({DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @visibleForTesting
  AppEvent.withTimestamp(this.timestamp);

  final DateTime timestamp;
}

final class WorkoutCompletedEvent extends AppEvent {
  WorkoutCompletedEvent({
    required this.workoutId,
    required this.duration,
    required this.totalVolume,
    super.timestamp,
  });

  final int workoutId;
  final Duration duration;
  final double totalVolume;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutCompletedEvent && other.workoutId == workoutId;

  @override
  int get hashCode => workoutId.hashCode;
}

final class ExpenseAddedEvent extends AppEvent {
  ExpenseAddedEvent({
    required this.transactionId,
    required this.categoryName,
    required this.amount,
    super.timestamp,
  });

  final int transactionId;
  final String categoryName;
  final double amount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAddedEvent && other.transactionId == transactionId;

  @override
  int get hashCode => transactionId.hashCode;
}

final class BudgetThresholdEvent extends AppEvent {
  BudgetThresholdEvent({
    required this.budgetId,
    required this.categoryName,
    required this.percentage,
    super.timestamp,
  });

  final int budgetId;
  final String categoryName;
  final double percentage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetThresholdEvent &&
          other.budgetId == budgetId &&
          other.percentage == percentage;

  @override
  int get hashCode => Object.hash(budgetId, percentage);
}

final class HabitCheckedInEvent extends AppEvent {
  HabitCheckedInEvent({
    required this.habitId,
    required this.habitName,
    required this.isCompleted,
    super.timestamp,
  });

  final int habitId;
  final String habitName;
  final bool isCompleted;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitCheckedInEvent && other.habitId == habitId;

  @override
  int get hashCode => habitId.hashCode;
}

final class SleepLogSavedEvent extends AppEvent {
  SleepLogSavedEvent({
    required this.sleepLogId,
    required this.sleepScore,
    required this.hoursSlept,
    super.timestamp,
  });

  final int sleepLogId;
  final int sleepScore;
  final double hoursSlept;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepLogSavedEvent && other.sleepLogId == sleepLogId;

  @override
  int get hashCode => sleepLogId.hashCode;
}

final class MoodLoggedEvent extends AppEvent {
  MoodLoggedEvent({
    required this.moodLogId,
    required this.level,
    required this.tags,
    super.timestamp,
  });

  final int moodLogId;
  final int level;
  final List<String> tags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodLoggedEvent && other.moodLogId == moodLogId;

  @override
  int get hashCode => moodLogId.hashCode;
}

final class GoalProgressUpdatedEvent extends AppEvent {
  GoalProgressUpdatedEvent({
    required this.goalId,
    required this.progress,
    super.timestamp,
  });

  final int goalId;
  final int progress;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalProgressUpdatedEvent && other.goalId == goalId;

  @override
  int get hashCode => goalId.hashCode;
}

final class SettingsChangedEvent extends AppEvent {
  SettingsChangedEvent({super.timestamp});
}
