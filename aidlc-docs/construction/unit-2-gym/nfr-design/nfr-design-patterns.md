# NFR Design Patterns — Unit 2: Gym

## Baseline
Inherits all patterns from Unit 0 (Result<T>, AppLogger, validation, global error handler).

---

## 1. Exercise Library Bulk Load (PERF-GYM-01)

```
Future<void> loadExerciseLibrary() async {
  final count = await gymDao.countExercises();
  if (count > 0) return; // Already loaded

  final jsonStr = await rootBundle.loadString('assets/exercises.json');
  final list = jsonDecode(jsonStr) as List;
  final companions = list.map(ExercisesCompanion.fromJson).toList();
  
  await gymDao.bulkInsertExercises(companions); // Drift batch
}
```

## 2. Auto-Save Per Set (PERF-GYM-02 / Q5:A)

Each call to `logSet()` does `gymDao.insertWorkoutSet()` immediately. No in-memory buffering. Drift transaction ensures atomicity. On app resume, `getActiveWorkout()` finds in-progress workout.

## 3. PR Detection (BR-GYM-21/22)

```
Future<List<PRRecord>> detectPRs(int workoutId) async {
  final sets = await gymDao.watchWorkoutSets(workoutId).first;
  final workSets = sets.where((s) => !s.isWarmup && s.weightKg != null);
  
  final prs = <PRRecord>[];
  for (final exerciseId in workSets.map((s) => s.exerciseId).toSet()) {
    final exerciseSets = workSets.where((s) => s.exerciseId == exerciseId);
    
    // Weight PR: max weight
    final maxWeight = exerciseSets.map((s) => s.weightKg!).reduce(max);
    final prevWeightPR = await gymDao.getWeightPR(exerciseId);
    if (prevWeightPR == null || maxWeight > prevWeightPR) {
      prs.add(PRRecord(exerciseId: exerciseId, type: PRType.weight, value: maxWeight));
    }
    
    // Volume PR: max (weight × reps)
    final maxVolume = exerciseSets.map((s) => s.weightKg! * s.reps).reduce(max);
    final prevVolumePR = await gymDao.getVolumePR(exerciseId);
    if (prevVolumePR == null || maxVolume > prevVolumePR) {
      prs.add(PRRecord(exerciseId: exerciseId, type: PRType.volume, value: maxVolume));
    }
  }
  return prs;
}
```

## 4. Rest Timer State Machine

```
States: idle → running → paused → expired
Events: startTimer(seconds), tick(), addTime(30), skip(), reset()

- On set completion: auto-start with routine's restSeconds (or 90s fallback)
- tick() every second decrements counter
- At 0: transition to expired, trigger haptic via HapticService
- +30s: add 30 to remaining counter
- skip: transition to idle immediately
```

## 5. Weight Unit Conversion

```
extension WeightConversion on double {
  double toDisplayUnit(String unit) =>
      unit == 'lbs' ? this * 2.20462 : this;
  
  double toStorageKg(String unit) =>
      unit == 'lbs' ? this / 2.20462 : this;
}
```

Applied at presentation layer only. All storage, PRs, calculations in kg.

## 6. 1RM Epley Formula

```
double? calculate1RM(double weightKg, int reps) {
  if (reps <= 0) return null;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30.0);
}
```
