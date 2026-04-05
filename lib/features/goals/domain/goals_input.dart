// ---------------------------------------------------------------------------
// Goal categories
// ---------------------------------------------------------------------------

/// Predefined goal categories (stored as lowercase text in the database).
enum GoalCategory {
  salud,
  finanzas,
  carrera,
  personal,
  educacion,
  relaciones;

  String get displayName => switch (this) {
        GoalCategory.salud => 'Salud',
        GoalCategory.finanzas => 'Finanzas',
        GoalCategory.carrera => 'Carrera',
        GoalCategory.personal => 'Personal',
        GoalCategory.educacion => 'Educacion',
        GoalCategory.relaciones => 'Relaciones',
      };

  String get iconName => switch (this) {
        GoalCategory.salud => 'favorite',
        GoalCategory.finanzas => 'account_balance',
        GoalCategory.carrera => 'work',
        GoalCategory.personal => 'person',
        GoalCategory.educacion => 'school',
        GoalCategory.relaciones => 'group',
      };

  static GoalCategory? fromString(String value) {
    for (final cat in GoalCategory.values) {
      if (cat.name == value.toLowerCase()) return cat;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// DTOs
// ---------------------------------------------------------------------------

class GoalInput {
  const GoalInput({
    required this.name,
    required this.category,
    required this.icon,
    this.description,
    this.color = 0xFF06B6D4,
    this.targetDate,
  });

  final String name;
  final String? description;
  final String category; // GoalCategory.name value
  final String icon;
  final int color;
  final DateTime? targetDate;
}

class SubGoalInput {
  const SubGoalInput({
    required this.goalId,
    required this.name,
    required this.weight,
    this.description,
    this.linkedModule,
    this.linkedEntityId,
    this.sortOrder = 0,
  });

  final int goalId;
  final String name;
  final String? description;
  final double weight; // 0.0–1.0
  final String? linkedModule; // 'habits' | 'sleep' | 'mental'
  final int? linkedEntityId;
  final int sortOrder;
}

class MilestoneInput {
  const MilestoneInput({
    required this.goalId,
    required this.name,
    required this.targetProgress,
    this.targetDate,
    this.sortOrder = 0,
  });

  final int goalId;
  final String name;
  final DateTime? targetDate;
  final int targetProgress; // 0–100
  final int sortOrder;
}
