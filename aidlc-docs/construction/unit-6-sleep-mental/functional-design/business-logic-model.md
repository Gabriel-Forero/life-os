# Unit 6 — Sleep + Mental Wellness: Business Logic Model

## Sleep Feature Flow

```
User Input (bedTime, wakeTime, qualityRating, note?)
    |
    v
SleepValidators.validateSleepInput()
    |— Fails → Return ValidationFailure
    |
    v
calculateSleepScore(hoursSlept, qualityRating, interruptionCount)
    |
    v
SleepDao.insertSleepLog(SleepLogsCompanion)
    |
    v
EventBus.emit(SleepLogSavedEvent)
    |
    v
Return Success(sleepLogId)
```

## Energy Tracking Flow

```
User Input (timeOfDay, level, note?)
    |
    v
SleepValidators.validateEnergyInput()
    |
    v
SleepDao.insertEnergyLog(EnergyLogsCompanion)
    |
    v
Return Success(energyLogId)
```

## Mood Logging Flow

```
User Input (valence, energy, tags, journalNote?)
    |
    v
MentalValidators.validateMoodInput()
    |
    v
calculateMoodScore(valence, energy)
    |
    v
MentalDao.insertMoodLog(MoodLogsCompanion)
    |
    v
EventBus.emit(MoodLoggedEvent(level: moodScore, tags: tagList))
    |
    v
Return Success(moodLogId)
```

## Breathing Session Flow

```
User selects technique (box / 4_7_8 / coherent)
    |
    v
UI: Animated breathing circle runs timer
    |
    v
User completes or abandons session
    |
    v
MentalNotifier.startBreathingSession(techniqueName, durationSeconds, isCompleted)
    |
    v
MentalValidators.validateBreathingInput()
    |
    v
MentalDao.insertBreathingSession(BreathingSessionsCompanion)
    |
    v
Return Success(sessionId)
```

## Data Query Patterns

### Sleep
- `watchSleepLogs(from, to)` — stream of logs for date range (weekly/monthly charts)
- `watchSleepLogWithInterruptions(id)` — single log with its interruptions
- `watchEnergyLogs(date)` — all 3 time-of-day entries for a date

### Mental
- `watchMoodLogs(from, to)` — stream of mood logs for calendar/trend views
- `watchBreathingSessions(from, to)` — session history

## Score Ranges for UI

| Score | Label | Color hint |
|---|---|---|
| 0–39 | Bajo | error/red |
| 40–69 | Regular | warning/amber |
| 70–89 | Bueno | success/green |
| 90–100 | Excelente | indigo/pink accent |

## Dependencies

- Unit 0: AppDatabase, EventBus, AppColors, Result, AppFailure types
- HealthKit: Deferred (Unit 8)
- No dependency on other feature units
