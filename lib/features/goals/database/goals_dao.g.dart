// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goals_dao.dart';

// ignore_for_file: type=lint
mixin _$GoalsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LifeGoalsTable get lifeGoals => attachedDatabase.lifeGoals;
  $SubGoalsTable get subGoals => attachedDatabase.subGoals;
  $GoalMilestonesTable get goalMilestones => attachedDatabase.goalMilestones;
  GoalsDaoManager get managers => GoalsDaoManager(this);
}

class GoalsDaoManager {
  final _$GoalsDaoMixin _db;
  GoalsDaoManager(this._db);
  $$LifeGoalsTableTableManager get lifeGoals =>
      $$LifeGoalsTableTableManager(_db.attachedDatabase, _db.lifeGoals);
  $$SubGoalsTableTableManager get subGoals =>
      $$SubGoalsTableTableManager(_db.attachedDatabase, _db.subGoals);
  $$GoalMilestonesTableTableManager get goalMilestones =>
      $$GoalMilestonesTableTableManager(
        _db.attachedDatabase,
        _db.goalMilestones,
      );
}
