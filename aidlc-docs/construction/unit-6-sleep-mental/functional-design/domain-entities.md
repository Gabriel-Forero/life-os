# Unit 6 — Sleep + Mental Wellness: Domain Entities

## Sleep Feature

### SleepLog
Represents a single night of sleep recorded by the user.

| Field | Type | Constraints |
|---|---|---|
| id | int | PK, auto-increment |
| date | DateTime | The date of the sleep record |
| bedTime | DateTime | When user went to bed |
| wakeTime | DateTime | When user woke up |
| qualityRating | int | 1–5 (1=poor, 5=excellent) |
| sleepScore | int | 0–100 (computed) |
| note | String? | Optional note, max 200 chars |
| createdAt | DateTime | Record creation timestamp |

**Computed property**: `hoursSlept = wakeTime.difference(bedTime).inMinutes / 60.0`

### SleepInterruption
A wake event during the night linked to a SleepLog.

| Field | Type | Constraints |
|---|---|---|
| id | int | PK, auto-increment |
| sleepLogId | int | FK → sleep_logs.id |
| time | DateTime | When the interruption occurred |
| durationMinutes | int | How long the interruption lasted (>0) |
| reason | String? | Optional reason text |
| createdAt | DateTime | Record creation timestamp |

### EnergyLog
Tracks user's energy level at 3 points during the day.

| Field | Type | Constraints |
|---|---|---|
| id | int | PK, auto-increment |
| date | DateTime | The date of the log |
| timeOfDay | String | Enum: morning / afternoon / evening |
| level | int | 1–10 energy scale |
| note | String? | Optional note |
| createdAt | DateTime | Record creation timestamp |

---

## Mental Feature

### MoodLog
Dual-axis mood entry using valence (pleasure) and energy (arousal).

| Field | Type | Constraints |
|---|---|---|
| id | int | PK, auto-increment |
| date | DateTime | The date/time of the log |
| valence | int | 1–5 (1=negative, 5=positive) |
| energy | int | 1–5 (1=low, 5=high) |
| tags | String | Comma-separated tags (e.g., "trabajo,familia") |
| journalNote | String? | Optional reflection, max 280 chars |
| createdAt | DateTime | Record creation timestamp |

**Computed property**: `moodScore = ((valence-1)/4 * 50) + ((energy-1)/4 * 50)` (0–100)

### BreathingSession
Records a completed or abandoned breathing exercise.

| Field | Type | Constraints |
|---|---|---|
| id | int | PK, auto-increment |
| techniqueName | String | box / 4-7-8 / coherent |
| durationSeconds | int | Actual seconds the user breathed |
| isCompleted | bool | Whether user finished full session |
| createdAt | DateTime | Record creation timestamp |

---

## Breathing Techniques (Immutable)

| Name | Pattern | Description |
|---|---|---|
| box | 4-4-4-4 | Inhale 4s, Hold 4s, Exhale 4s, Hold 4s |
| 4-7-8 | 4-7-8 | Inhale 4s, Hold 7s, Exhale 8s |
| coherent | 5-5 | Inhale 5s, Exhale 5s |
