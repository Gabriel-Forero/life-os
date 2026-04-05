# Unit 7 — Goals: Domain Entities

## 1. GoalCategory Enum

| Value        | Display Text | Icon Suggestion      |
|-------------|--------------|----------------------|
| salud        | Salud         | favorite             |
| finanzas     | Finanzas      | account_balance      |
| carrera      | Carrera       | work                 |
| personal     | Personal      | person               |
| educacion    | Educacion     | school               |
| relaciones   | Relaciones    | group                |

Stored as lowercase text in the database.

---

## 2. Drift Tables

### 2.1 `life_goals`

| Column       | Type            | Constraints                                  | Notes                            |
|-------------|-----------------|----------------------------------------------|----------------------------------|
| id           | INTEGER PK AI   |                                              | Auto-increment                   |
| name         | TEXT            | length 1–100, NOT NULL                       |                                  |
| description  | TEXT            | nullable, max 500                            |                                  |
| category     | TEXT            | NOT NULL                                     | salud/finanzas/carrera/personal/educacion/relaciones |
| icon         | TEXT            | NOT NULL                                     | Material icon name               |
| color        | INTEGER         | NOT NULL, default 0xFF06B6D4                 | ARGB int                         |
| targetDate   | DATETIME        | nullable                                     | Deadline                         |
| status       | TEXT            | NOT NULL, default 'active'                   | active/completed/paused/abandoned |
| progress     | INTEGER         | NOT NULL, default 0, range 0–100             | Derived or manual                |
| createdAt    | DATETIME        | NOT NULL                                     |                                  |
| updatedAt    | DATETIME        | NOT NULL                                     |                                  |

### 2.2 `sub_goals`

| Column         | Type       | Constraints                                | Notes                                                    |
|---------------|------------|--------------------------------------------|----------------------------------------------------------|
| id             | INTEGER PK AI |                                          |                                                          |
| goalId         | INTEGER    | FK → life_goals.id, NOT NULL               |                                                          |
| name           | TEXT        | length 1–100, NOT NULL                    |                                                          |
| description    | TEXT        | nullable, max 200                          |                                                          |
| weight         | REAL        | NOT NULL                                   | 0.0–1.0; all weights per goal must sum to 1.0            |
| progress       | INTEGER     | NOT NULL, default 0, range 0–100          |                                                          |
| linkedModule   | TEXT        | nullable                                   | e.g. 'habits', 'sleep', 'mental'                         |
| linkedEntityId | INTEGER     | nullable                                   | FK to entity in linked module                            |
| isOverridden   | BOOLEAN     | NOT NULL, default false                    | When true, manual slider overrides auto-progress         |
| sortOrder      | INTEGER     | NOT NULL, default 0                        |                                                          |
| status         | TEXT        | NOT NULL, default 'active'                 | active/completed                                         |
| createdAt      | DATETIME    | NOT NULL                                   |                                                          |
| updatedAt      | DATETIME    | NOT NULL                                   |                                                          |

### 2.3 `goal_milestones`

| Column          | Type       | Constraints                    | Notes                                      |
|----------------|------------|--------------------------------|--------------------------------------------|
| id              | INTEGER PK AI |                             |                                            |
| goalId          | INTEGER    | FK → life_goals.id, NOT NULL   |                                            |
| name            | TEXT       | length 1–100, NOT NULL         |                                            |
| targetDate      | DATETIME   | nullable                       | Shown on timeline                          |
| targetProgress  | INTEGER    | NOT NULL, range 0–100          | Progress value at which milestone is reached |
| isCompleted     | BOOLEAN    | NOT NULL, default false        |                                            |
| completedAt     | DATETIME   | nullable                       | Set when isCompleted = true                |
| sortOrder       | INTEGER    | NOT NULL, default 0            |                                            |
| createdAt       | DATETIME   | NOT NULL                       |                                            |

---

## 3. DTOs (Input Objects)

### 3.1 GoalInput
```dart
class GoalInput {
  final String name;               // 1–100
  final String? description;       // nullable, max 500
  final String category;           // GoalCategory value
  final String icon;               // Material icon name
  final int color;                 // ARGB int, default 0xFF06B6D4
  final DateTime? targetDate;      // nullable deadline
}
```

### 3.2 SubGoalInput
```dart
class SubGoalInput {
  final int goalId;
  final String name;               // 1–100
  final String? description;       // nullable, max 200
  final double weight;             // 0.0–1.0
  final String? linkedModule;      // nullable
  final int? linkedEntityId;       // nullable
  final int sortOrder;
}
```

### 3.3 MilestoneInput
```dart
class MilestoneInput {
  final int goalId;
  final String name;               // 1–100
  final DateTime? targetDate;      // nullable
  final int targetProgress;        // 0–100
  final int sortOrder;
}
```

---

## 4. GoalsState

```dart
class GoalsState {
  final List<LifeGoal> goals;          // All active goals
  final Map<int, List<SubGoal>> subGoals;     // goalId → sub-goals
  final Map<int, List<GoalMilestone>> milestones; // goalId → milestones
  final bool isLoading;
  final String? error;
  final String? categoryFilter;       // nullable GoalCategory value
}
```

---

## 5. Progress Model

- **Weighted progress** = sum(subGoal.weight × subGoal.progress) for all sub-goals of a goal
- If a sub-goal has `linkedModule` set and `isOverridden = false`, progress is auto-derived from linked module events
- If `isOverridden = true`, manual 0–100 slider value takes precedence
- Parent goal `progress` field is updated after any sub-goal progress change
