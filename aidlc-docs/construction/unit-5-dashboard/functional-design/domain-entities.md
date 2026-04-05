# Domain Entities — Unit 5: Dashboard + DayScore

## Drift Tables

### 1. `day_scores`

Stores the computed daily total score for a given date.

| Column         | Type       | Constraints                     | Description                         |
|----------------|------------|---------------------------------|-------------------------------------|
| id             | INTEGER    | PRIMARY KEY AUTOINCREMENT       | Surrogate key                       |
| date           | DATETIME   | NOT NULL, UNIQUE                | Date of the score (day boundary)    |
| total_score    | INTEGER    | NOT NULL, 0 <= x <= 100        | Weighted average score (0–100)      |
| calculated_at  | DATETIME   | NOT NULL                        | When the score was last computed    |
| created_at     | DATETIME   | NOT NULL                        | Row creation timestamp              |

**Unique constraint**: `(date)` — one score per calendar day.

---

### 2. `score_components`

Breakdown of each module's contribution to a DayScore row.

| Column          | Type    | Constraints                        | Description                                      |
|-----------------|---------|------------------------------------|--------------------------------------------------|
| id              | INTEGER | PRIMARY KEY AUTOINCREMENT          | Surrogate key                                    |
| day_score_id    | INTEGER | NOT NULL, FK → day_scores(id)      | Parent DayScore                                  |
| module_key      | TEXT    | NOT NULL                           | Identifier: finance, gym, nutrition, habits      |
| raw_value       | REAL    | NOT NULL, 0.0 <= x <= 100.0       | Module's normalized score (0–100)               |
| weight          | REAL    | NOT NULL, > 0                      | Weight used during computation                  |
| weighted_score  | REAL    | NOT NULL                           | raw_value × weight                              |
| created_at      | DATETIME| NOT NULL                           | Row creation timestamp                           |

**Unique constraint**: `(day_score_id, module_key)` — one component per module per day.

---

### 3. `day_score_configs`

User-configurable weights and enable/disable per module.

| Column      | Type     | Constraints                    | Description                           |
|-------------|----------|--------------------------------|---------------------------------------|
| id          | INTEGER  | PRIMARY KEY AUTOINCREMENT      | Surrogate key                         |
| module_key  | TEXT     | NOT NULL, UNIQUE               | Module identifier                     |
| weight      | REAL     | NOT NULL, DEFAULT 1.0          | Relative weight in score formula      |
| is_enabled  | BOOLEAN  | NOT NULL, DEFAULT true         | Whether module contributes to score   |
| created_at  | DATETIME | NOT NULL                       | Row creation timestamp                |
| updated_at  | DATETIME | NOT NULL                       | Last update timestamp                 |

**Default data**: Seeded on first run with equal weights (1.0) for: finance, gym, nutrition, habits.

---

### 4. `life_snapshots`

Daily immutable snapshot of all module metrics for historical review.

| Column       | Type     | Constraints               | Description                                |
|--------------|----------|---------------------------|--------------------------------------------|
| id           | INTEGER  | PRIMARY KEY AUTOINCREMENT | Surrogate key                              |
| date         | DATETIME | NOT NULL, UNIQUE          | Snapshot date (day boundary)               |
| total_score  | INTEGER  | NOT NULL                  | DayScore total on that day                 |
| metrics_json | TEXT     | NOT NULL                  | JSON blob of module metrics                |
| created_at   | DATETIME | NOT NULL                  | Creation timestamp (lazy generation time)  |

**Unique constraint**: `(date)` — one snapshot per day.

**JSON structure** for `metrics_json`:
```json
{
  "finance": { "balance": 1234567, "budgetUsed": 0.72 },
  "gym": { "workoutsThisWeek": 3, "volumeKg": 4500 },
  "nutrition": { "avgCalories": 2100, "proteinGrams": 150 },
  "habits": { "completionRate": 0.85, "streak": 7 }
}
```

---

## DTOs

### `DayScoreConfigDto`
```dart
class DayScoreConfigDto {
  final int id;
  final String moduleKey;
  final double weight;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### `ScoreComponentDto`
```dart
class ScoreComponentDto {
  final String moduleKey;
  final double rawValue;
  final double weight;
  final double weightedScore;
}
```

### `DayScoreDto`
```dart
class DayScoreDto {
  final int id;
  final DateTime date;
  final int totalScore;
  final DateTime calculatedAt;
  final List<ScoreComponentDto> components;
}
```

### `LifeSnapshotDto`
```dart
class LifeSnapshotDto {
  final int id;
  final DateTime date;
  final int totalScore;
  final Map<String, dynamic> metrics;
  final DateTime createdAt;
}
```

---

## DayScoreState

State held by `DayScoreNotifier`:

```dart
class DayScoreState {
  final int? todayScore;                        // null = not yet computed
  final List<ScoreComponentDto> components;    // breakdown by module
  final List<DayScoreConfigDto> configs;       // weight config per module
  final List<DayScoreDto> history;             // last 30 days
  final bool isLoading;
  final String? errorMessage;
}
```

---

## DashboardState

State held by `DashboardNotifier`:

```dart
class DashboardState {
  final int? dayScore;              // today's total score
  final List<ModuleCardData> cards; // ordered by module priority
  final bool isLoading;
  final String? errorMessage;
}

class ModuleCardData {
  final String moduleKey;
  final String title;
  final String subtitle;   // primary metric displayed
  final Color color;
  final IconData icon;
  final bool isEnabled;
  final int priority;
}
```
