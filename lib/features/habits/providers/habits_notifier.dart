import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/features/habits/database/habits_dao.dart';
import 'package:life_os/features/habits/domain/habits_input.dart';
import 'package:life_os/features/habits/domain/habits_validators.dart';

class HabitsNotifier {
  HabitsNotifier({required this.dao, required this.eventBus});

  final HabitsDao dao;
  final EventBus eventBus;

  Future<Result<int>> addHabit(HabitInput input) async {
    final nameResult = validateHabitName(input.name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    final freqResult = validateFrequencyType(input.frequencyType);
    if (freqResult.isFailure) return Failure(freqResult.failureOrNull!);

    try {
      final now = DateTime.now();
      final id = await dao.insertHabit(HabitsCompanion.insert(
        name: nameResult.valueOrNull!,
        icon: Value(input.icon),
        color: Value(input.color),
        frequencyType: input.frequencyType,
        weeklyTarget: Value(input.weeklyTarget),
        customDays: Value(
          input.customDays != null ? jsonEncode(input.customDays) : null,
        ),
        isQuantitative: Value(input.isQuantitative),
        quantitativeTarget: Value(input.quantitativeTarget),
        quantitativeUnit: Value(input.quantitativeUnit),
        reminderTime: Value(input.reminderTime),
        linkedEvent: Value(input.linkedEvent),
        isArchived: const Value(false),
        createdAt: now,
        updatedAt: now,
      ));
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al crear habito',
        debugMessage: 'insertHabit failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> archiveHabit(int id) async {
    try {
      await dao.archiveHabit(id);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al archivar habito',
        debugMessage: 'archiveHabit failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> restoreHabit(int id) async {
    try {
      await dao.restoreHabit(id);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al restaurar habito',
        debugMessage: 'restoreHabit failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> checkIn(int habitId, {double? value}) async {
    if (value != null) {
      final valResult = validateQuantitativeValue(value);
      if (valResult.isFailure) return Failure(valResult.failureOrNull!);
    }

    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);

    // Check if already checked in today
    final existing = await dao.getLogForDate(habitId, date);
    if (existing != null) {
      return const Failure(ValidationFailure(
        userMessage: 'Ya completaste este habito hoy',
        debugMessage: 'Habit already checked in for today',
        field: 'habitId',
      ));
    }

    try {
      await dao.insertHabitLog(HabitLogsCompanion.insert(
        habitId: habitId,
        date: date,
        completedAt: now,
        value: Value(value),
        createdAt: now,
      ));

      // Determine completion for event
      final habits = await dao.watchActiveHabits().first;
      final habit = habits.where((h) => h.id == habitId).firstOrNull;
      final isCompleted = habit == null ||
          !habit.isQuantitative ||
          (value != null &&
              habit.quantitativeTarget != null &&
              value >= habit.quantitativeTarget!);

      eventBus.emit(HabitCheckedInEvent(
        habitId: habitId,
        habitName: habit?.name ?? '',
        isCompleted: isCompleted,
      ));

      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al registrar habito',
        debugMessage: 'checkIn failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> uncheckIn(int habitId, DateTime date) async {
    try {
      await dao.deleteHabitLog(habitId, date);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al deshacer registro',
        debugMessage: 'uncheckIn failed: $e',
        originalError: e,
      ));
    }
  }

  /// Auto-check habits linked to WorkoutCompletedEvent
  Future<void> onWorkoutCompleted(WorkoutCompletedEvent event) async {
    final habits = await dao.watchActiveHabits().first;
    final linked = habits.where(
      (h) => h.linkedEvent == 'WorkoutCompletedEvent',
    );

    for (final habit in linked) {
      await checkIn(habit.id);
    }
  }
}
