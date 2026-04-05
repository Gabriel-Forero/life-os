import 'dart:math';

import 'package:life_os/core/domain/app_event.dart';

class AppEventGen {
  static final _random = Random(42);

  static AppEvent generate() {
    final type = _random.nextInt(8);
    return switch (type) {
      0 => WorkoutCompletedEvent(
          workoutId: _random.nextInt(1000) + 1,
          duration: Duration(minutes: _random.nextInt(120) + 10),
          totalVolume: _random.nextDouble() * 50000,
        ),
      1 => ExpenseAddedEvent(
          transactionId: _random.nextInt(1000) + 1,
          categoryName: ['Comida', 'Transporte', 'Salud'][_random.nextInt(3)],
          amount: _random.nextDouble() * 500000 + 1,
        ),
      2 => BudgetThresholdEvent(
          budgetId: _random.nextInt(100) + 1,
          categoryName: ['Comida', 'Transporte'][_random.nextInt(2)],
          percentage: _random.nextDouble() * 1.5,
        ),
      3 => HabitCheckedInEvent(
          habitId: _random.nextInt(100) + 1,
          habitName: ['Ejercicio', 'Lectura', 'Meditacion'][_random.nextInt(3)],
          isCompleted: _random.nextBool(),
        ),
      4 => SleepLogSavedEvent(
          sleepLogId: _random.nextInt(1000) + 1,
          sleepScore: _random.nextInt(101),
          hoursSlept: _random.nextDouble() * 12,
        ),
      5 => MoodLoggedEvent(
          moodLogId: _random.nextInt(1000) + 1,
          level: _random.nextInt(5) + 1,
          tags: ['calm', 'stressed', 'happy']
              .where((_) => _random.nextBool())
              .toList(),
        ),
      6 => GoalProgressUpdatedEvent(
          goalId: _random.nextInt(100) + 1,
          progress: _random.nextInt(101),
        ),
      _ => SettingsChangedEvent(),
    };
  }

  static List<AppEvent> generateMany(int count) =>
      List.generate(count, (_) => generate());
}
