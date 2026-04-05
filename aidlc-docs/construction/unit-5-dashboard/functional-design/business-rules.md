# Business Rules — Unit 5: Dashboard + DayScore

## BR-DS-01: DayScore Calculation Formula

**Rule**: DayScore = weighted average of enabled module scores.

```
score = ROUND( Σ(moduleScore_i × weight_i) / Σ(weight_i) )
```

- Only modules with `is_enabled = true` in `day_score_configs` participate.
- If no modules are enabled, `totalScore = 0`.
- Result is clamped to integer range [0, 100].
- Weights must be positive (> 0). Zero-weight modules are treated as disabled.

---

## BR-DS-02: Module Score Normalization

**Rule**: Each module provides a raw score in [0.0, 100.0].

| Module    | Score Source                                | 0 = worst, 100 = best       |
|-----------|---------------------------------------------|-----------------------------|
| finance   | Budget usage: 100 − (spentPct × 100)       | Over-budget → 0             |
| gym       | Workouts completed vs. weekly target × 100 | No workouts → 0             |
| nutrition  | Calories within target ± 10% → 100         | Far off target → 0          |
| habits    | Daily completion rate × 100                | No habits checked in → 0    |

**Note**: In this unit, module scores are mocked (DashboardNotifier reads from other notifiers' state). The exact calculation per module is each module's responsibility.

---

## BR-DS-03: Default Weights

**Rule**: On first app run (or when a module has no config), seed `day_score_configs` with:

| Module    | Default Weight | Default Enabled |
|-----------|----------------|-----------------|
| finance   | 1.0            | true            |
| gym       | 1.0            | true            |
| nutrition | 1.0            | true            |
| habits    | 1.0            | true            |

Equal weights produce a simple arithmetic average.

---

## BR-DS-04: Score Recalculation Triggers

**Rule**: DayScore is recalculated when any of the following EventBus events are received:

- `BudgetThresholdEvent` → recalculate finance component
- `HabitCheckedInEvent` → recalculate habits component
- `GoalProgressUpdatedEvent` → recalculate all components (global progress update)

The notifier subscribes to these events and triggers `calculateDayScore()`.

---

## BR-DS-05: Dashboard Card Visibility

**Rule**: The dashboard shows one card per module, but only for enabled modules.

- **Enabled**: `is_enabled = true` in `day_score_configs`
- **Order**: cards are sorted by module priority (ascending). Priority is fixed:
  1. finance (priority 1)
  2. gym (priority 2)
  3. nutrition (priority 3)
  4. habits (priority 4)
- Disabled modules have their card hidden entirely (not greyed out).

---

## BR-DS-06: Greeting Logic

**Rule**: The dashboard greeting changes based on time of day (device local time):

| Time Range    | Greeting (Spanish)         |
|---------------|----------------------------|
| 05:00 – 11:59 | "Buenos dias"              |
| 12:00 – 17:59 | "Buenas tardes"            |
| 18:00 – 04:59 | "Buenas noches"            |

---

## BR-DS-07: Life Snapshot Generation

**Rule**: Life snapshots are generated lazily — on the first app open of a new day.

**Detection**:
1. On app startup, `DashboardNotifier` checks if a snapshot exists for `today − 1 day`.
2. If no snapshot exists for yesterday AND the current time > 00:00 of today → generate yesterday's snapshot.
3. A snapshot is never generated for the current day (metrics are still changing).

**Snapshot content**: Captured from the most recent cached state of each module notifier at the time of snapshot generation.

**Idempotency**: If a snapshot already exists for the target date, skip generation (no-op).

---

## BR-DS-08: Score History Window

**Rule**: Score history shown in `ScoreHistoryScreen` covers the last 30 calendar days.

- Missing days (no score computed) appear as gaps in charts, not zero.
- The trend line connects only days that have data.
- The heatmap shows all 30 days: days with no score are shown in a neutral (empty) color.

---

## BR-DS-09: Weight Update Constraints

**Rule**: When a user updates a module weight:

- New weight must be > 0.0 and <= 10.0.
- After update, DayScore is immediately recalculated for today.
- Weight change is persisted to `day_score_configs`.

---

## BR-DS-10: Score Component Persistence

**Rule**: Every time `calculateDayScore()` runs for a given date:

- If a `day_scores` row exists for that date → UPDATE `total_score` and `calculated_at`.
- If no row exists → INSERT new row.
- All `score_components` rows for that `day_score_id` are deleted and re-inserted (full replace).
