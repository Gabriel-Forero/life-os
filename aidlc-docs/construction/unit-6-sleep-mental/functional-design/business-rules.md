# Unit 6 — Sleep + Mental Wellness: Business Rules

## Sleep Score Calculation (Decision Q1:A)

Sleep score is a weighted composite of three factors, each scored 0–100, then combined:

```
sleepScore = (durationScore * 0.40) + (qualityScore * 0.40) + (interruptionScore * 0.20)
```

### Component Formulas

| Component | Formula | Rationale |
|---|---|---|
| Duration Score | `min(100, (hoursSlept / 8.0) * 100)` | 8 hours = 100, capped at 100 |
| Quality Score | `(qualityRating / 5.0) * 100` | Linear 1–5 mapping |
| Interruption Score | `max(0, 100 - interruptionCount * 15)` | Each interruption costs 15 points |

### Examples

| Duration | Quality | Interruptions | Score |
|---|---|---|---|
| 8h, rating 5, 0 interruptions | 100 | 100 | 100 → 100 |
| 6h, rating 4, 2 interruptions | 75 | 80 | 70 → 75 |
| 4h, rating 2, 5 interruptions | 50 | 40 | 0 → 38 |

---

## Sleep Validation Rules

- `bedTime` must be before `wakeTime`
- `hoursSlept` must be between 0.5 and 24.0 hours
- `qualityRating` must be in [1, 5]
- `note` max 200 characters

## Sleep Interruption Rules

- `durationMinutes` must be > 0
- `time` must be within the sleep window (between bedTime and wakeTime)

## Energy Log Rules

- `timeOfDay` must be one of: `morning`, `afternoon`, `evening`
- `level` must be in [1, 10]
- One log per timeOfDay per date (uniqueness)

---

## Mood Score Calculation (Decision Q3:C)

Dual-axis model (valence × energy). Both axes are 1–5 integers.

```
moodScore = ((valence - 1) / 4.0 * 50) + ((energy - 1) / 4.0 * 50)
```

Result range: 0–100 (both at minimum → 0, both at maximum → 100)

### Mood Quadrants

| Valence | Energy | Quadrant | Example |
|---|---|---|---|
| High | High | Energized & Happy | Excited, Joyful |
| High | Low | Calm & Positive | Relaxed, Content |
| Low | High | Distressed | Anxious, Stressed |
| Low | Low | Depleted | Sad, Tired |

## Mood Validation Rules

- `valence` must be in [1, 5]
- `energy` must be in [1, 5]
- `journalNote` max 280 characters
- `tags` is comma-separated; each tag max 30 chars; max 10 tags

---

## Breathing Technique Definitions (Decision Q2:B)

Three immutable techniques stored as code constants:

| Key | Display Name | Inhale | Hold1 | Exhale | Hold2 |
|---|---|---|---|---|---|
| box | Respiracion Cuadrada | 4s | 4s | 4s | 4s |
| 4_7_8 | Tecnica 4-7-8 | 4s | 7s | 8s | 0s |
| coherent | Respiracion Coherente | 5s | 0s | 5s | 0s |

- `techniqueName` must be one of the three keys above
- `durationSeconds` must be > 0

---

## Event Emissions

| Trigger | Event | Payload |
|---|---|---|
| `SleepNotifier.logSleep` success | `SleepLogSavedEvent` | sleepLogId, sleepScore, hoursSlept |
| `MentalNotifier.logMood` success | `MoodLoggedEvent` | moodLogId, moodScore (as level), tags list |

---

## HealthKit (Decision Q4:B)

HealthKit integration deferred to Unit 8. All sleep input is manual in this unit.
