import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// LifeGoals table
// ---------------------------------------------------------------------------

class LifeGoals extends Table {
  @override
  String get tableName => 'life_goals';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().withLength(max: 500).nullable()();
  // salud / finanzas / carrera / personal / educacion / relaciones
  TextColumn get category => text()();
  TextColumn get icon => text()();
  IntColumn get color => integer().withDefault(const Constant(0xFF06B6D4))();
  DateTimeColumn get targetDate => dateTime().nullable()();
  // active / completed / paused / abandoned
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// ---------------------------------------------------------------------------
// SubGoals table
// ---------------------------------------------------------------------------

class SubGoals extends Table {
  @override
  String get tableName => 'sub_goals';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(LifeGoals, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().withLength(max: 200).nullable()();
  // 0.0–1.0; all weights for a goal must sum to 1.0 (enforced at notifier level)
  RealColumn get weight => real()();
  IntColumn get progress => integer().withDefault(const Constant(0))();
  // nullable: 'habits' | 'sleep' | 'mental'
  TextColumn get linkedModule => text().nullable()();
  // nullable FK to the linked entity id in the linked module's table
  IntColumn get linkedEntityId => integer().nullable()();
  // When true, manual progress overrides auto-progress
  BoolColumn get isOverridden =>
      boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  // active / completed
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

// ---------------------------------------------------------------------------
// GoalMilestones table
// ---------------------------------------------------------------------------

class GoalMilestones extends Table {
  @override
  String get tableName => 'goal_milestones';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(LifeGoals, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get targetDate => dateTime().nullable()();
  // 0–100: progress at which this milestone is considered reachable
  IntColumn get targetProgress => integer().withDefault(const Constant(0))();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}
