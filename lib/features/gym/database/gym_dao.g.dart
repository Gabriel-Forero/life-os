// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gym_dao.dart';

// ignore_for_file: type=lint
mixin _$GymDaoMixin on DatabaseAccessor<AppDatabase> {
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $RoutinesTable get routines => attachedDatabase.routines;
  $RoutineExercisesTable get routineExercises =>
      attachedDatabase.routineExercises;
  $WorkoutsTable get workouts => attachedDatabase.workouts;
  $WorkoutSetsTable get workoutSets => attachedDatabase.workoutSets;
  $BodyMeasurementsTable get bodyMeasurements =>
      attachedDatabase.bodyMeasurements;
  GymDaoManager get managers => GymDaoManager(this);
}

class GymDaoManager {
  final _$GymDaoMixin _db;
  GymDaoManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$RoutinesTableTableManager get routines =>
      $$RoutinesTableTableManager(_db.attachedDatabase, _db.routines);
  $$RoutineExercisesTableTableManager get routineExercises =>
      $$RoutineExercisesTableTableManager(
        _db.attachedDatabase,
        _db.routineExercises,
      );
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db.attachedDatabase, _db.workouts);
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db.attachedDatabase, _db.workoutSets);
  $$BodyMeasurementsTableTableManager get bodyMeasurements =>
      $$BodyMeasurementsTableTableManager(
        _db.attachedDatabase,
        _db.bodyMeasurements,
      );
}
