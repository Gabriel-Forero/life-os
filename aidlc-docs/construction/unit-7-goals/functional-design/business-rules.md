# Unit 7 — Goals: Business Rules

## BR-01 Goal CRUD

| Rule | Description |
|------|-------------|
| BR-01-1 | Goal name must be 1–100 characters (trimmed). Blank names are rejected. |
| BR-01-2 | Goal description, if provided, must not exceed 500 characters. |
| BR-01-3 | Category must be one of: salud, finanzas, carrera, personal, educacion, relaciones. |
| BR-01-4 | targetDate, if set, must be a future date (after current date at time of creation). |
| BR-01-5 | Initial status is 'active'. |
| BR-01-6 | Initial progress is 0. |
| BR-01-7 | Editing a goal updates updatedAt to now. |
| BR-01-8 | Deleting a goal cascades to sub_goals and goal_milestones. |
| BR-01-9 | A goal can be paused, abandoned, or completed via status change only. |
| BR-01-10 | A goal's progress is automatically recalculated after any sub-goal progress update. |

---

## BR-02 Sub-Goal Weights

| Rule | Description |
|------|-------------|
| BR-02-1 | Each sub-goal has a weight in range (0.0, 1.0] exclusive of 0. |
| BR-02-2 | All sub-goal weights for a given goal must sum to exactly 1.0 (tolerance: ±0.001). |
| BR-02-3 | When adding a sub-goal, validate that new total weight = 1.0. If not, return validation error. |
| BR-02-4 | When removing a sub-goal, the remaining weights no longer need to sum to 1.0 (user must rebalance). |
| BR-02-5 | A goal with no sub-goals has progress = 0 unless manually overridden at goal level. |
| BR-02-6 | Sub-goal progress is 0–100 inclusive. |

---

## BR-03 Milestone Validation

| Rule | Description |
|------|-------------|
| BR-03-1 | Milestone name must be 1–100 characters. |
| BR-03-2 | Milestone targetProgress must be 0–100 inclusive. |
| BR-03-3 | If targetDate is set, it must not be in the past at the time of creation. |
| BR-03-4 | Completing a milestone sets isCompleted = true and completedAt = now. |
| BR-03-5 | An already-completed milestone cannot be completed again. |
| BR-03-6 | Milestones are sorted by sortOrder ascending on display. |

---

## BR-04 Auto-Progress Rules (Hybrid Model)

| Rule | Description |
|------|-------------|
| BR-04-1 | A sub-goal with linkedModule = null: progress is always manual (0–100 slider). |
| BR-04-2 | A sub-goal with linkedModule set and isOverridden = false: progress is auto-derived from EventBus events. |
| BR-04-3 | A sub-goal with linkedModule set and isOverridden = true: manual slider value takes precedence; auto-events are ignored for this sub-goal. |
| BR-04-4 | HabitCheckedInEvent: if linkedModule = 'habits' and linkedEntityId matches habitId, increment sub-goal progress (capped at 100). |
| BR-04-5 | SleepLogSavedEvent: if linkedModule = 'sleep', recalculate sub-goal progress based on sleepScore (0–100 mapped directly). |
| BR-04-6 | MoodLoggedEvent: if linkedModule = 'mental', update sub-goal progress based on mood level (0–100). |
| BR-04-7 | After any auto-progress update, recalculate and persist parent goal's weighted progress. |
| BR-04-8 | Emits GoalProgressUpdatedEvent after parent goal progress is updated. |

---

## BR-05 Status Transitions

```
active --> completed  (when progress = 100 OR manual status change)
active --> paused     (manual)
active --> abandoned  (manual)
paused --> active     (manual resume)
completed --> active  (manual reopen)
abandoned --> active  (manual reopen)
```

- Completed/abandoned/paused goals are still visible but sorted below active goals.
- Sub-goal status is independent: active or completed.
