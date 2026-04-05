# LifeOS — Unit of Work Dependency Map

## Purpose

Documents the build order dependencies between LifeOS's 9 development units, identifies the critical path, highlights parallelization opportunities, and defines integration testing checkpoints.

---

## 1. Dependency Matrix (9x9)

Rows depend on columns. An "X" means the row unit depends on the column unit. A "-" means no dependency.

|                              | Unit 0 | Unit 1 | Unit 2 | Unit 3 | Unit 4 | Unit 5 | Unit 6 | Unit 7 | Unit 8 |
|------------------------------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| **Unit 0: Core Foundation**  | -      | -      | -      | -      | -      | -      | -      | -      | -      |
| **Unit 1: Finance**          | X      | -      | -      | -      | -      | -      | -      | -      | -      |
| **Unit 2: Gym**              | X      | -      | -      | -      | -      | -      | -      | -      | -      |
| **Unit 3: Nutrition**        | X      | -      | -      | -      | -      | -      | -      | -      | -      |
| **Unit 4: Habits**           | X      | -      | -      | -      | -      | -      | -      | -      | -      |
| **Unit 5: Dashboard+DayScore** | X    | X      | X      | X      | X      | -      | -      | -      | -      |
| **Unit 6: Sleep+Mental**     | X      | -      | -      | -      | -      | -      | -      | -      | -      |
| **Unit 7: Goals**            | X      | X      | X      | X      | X      | X      | X      | -      | -      |
| **Unit 8: Integration+Intel**| X      | X      | X      | X      | X      | X      | X      | X      | -      |

### Dependency Counts

| Unit | Depends On (count) | Required By (count) |
|---|---|---|
| Unit 0: Core Foundation | 0 | 8 (all others) |
| Unit 1: Finance | 1 | 3 (Units 5, 7, 8) |
| Unit 2: Gym | 1 | 3 (Units 5, 7, 8) |
| Unit 3: Nutrition | 1 | 3 (Units 5, 7, 8) |
| Unit 4: Habits | 1 | 3 (Units 5, 7, 8) |
| Unit 5: Dashboard+DayScore | 5 | 2 (Units 7, 8) |
| Unit 6: Sleep+Mental | 1 | 2 (Units 7, 8) |
| Unit 7: Goals | 7 | 1 (Unit 8) |
| Unit 8: Integration+Intel | 8 | 0 (final unit) |

---

## 2. Build Order Diagram

The following diagram shows the build levels and parallelization opportunities. Units at the same level can be built in parallel.

```
                          BUILD ORDER
  ============================================================

  Level 0 (Foundation)
  +---------------------------------------------------+
  |               Unit 0: Core Foundation              |
  |  DB, router, theme, services, EventBus, widgets,  |
  |  error handling, onboarding, localization          |
  |  Tables: 1 | Stories: 7 (ONB) | Phase: MVP        |
  +---------------------------------------------------+
                            |
            +-------+-------+-------+-------+
            |       |       |       |       |
            v       v       v       v       v

  Level 1 (Feature Modules -- ALL PARALLEL)
  +----------+ +----------+ +----------+ +----------+ +---------------+
  | Unit 1   | | Unit 2   | | Unit 3   | | Unit 4   | | Unit 6        |
  | Finance  | | Gym      | | Nutrition| | Habits   | | Sleep+Mental  |
  | T:5 S:14 | | T:6 S:15 | | T:6 S:11 | | T:2 S:10 | | T:5 S:17      |
  | MVP      | | MVP      | | MVP      | | MVP      | | Phase 2       |
  +----------+ +----------+ +----------+ +----------+ +---------------+
       |            |            |            |
       +------+-----+------+----+            |
              |            |                 |
              v            v                 |

  Level 2 (Aggregators)                      |
  +------------------------------+           |
  | Unit 5: Dashboard + DayScore |           |
  | T:4 S:4 | Phase: MVP        |           |
  | Depends: Units 0,1,2,3,4    |           |
  +------------------------------+           |
              |                              |
              +----------+-------------------+
                         |
                         v

  Level 3 (Cross-Module Goals)
  +---------------------------------------------------+
  |               Unit 7: Goals                        |
  |  T:3 S:7 | Phase: Phase 2                         |
  |  Depends: Units 0,1,2,3,4,5,6                     |
  +---------------------------------------------------+
                            |
                            v

  Level 4 (Integration + Intelligence)
  +---------------------------------------------------+
  |        Unit 8: Integration + Intelligence          |
  |  T:3 S:7 | Phase: Post-modules                    |
  |  Depends: ALL units (0-7)                          |
  +---------------------------------------------------+

  Legend: T = Drift tables, S = Stories
  ============================================================
```

### Level Details

| Level | Units | Can Parallelize? | Prerequisites |
|---|---|---|---|
| Level 0 | Unit 0 | No (single unit, must be first) | None |
| Level 1 | Units 1, 2, 3, 4, 6 | Yes -- all 5 units can build in parallel | Unit 0 complete |
| Level 2 | Unit 5 | No (single unit, blocked on MVP features) | Units 0, 1, 2, 3, 4 complete |
| Level 3 | Unit 7 | No (single unit, blocked on all feature modules) | Units 0, 1, 2, 3, 4, 5, 6 complete |
| Level 4 | Unit 8 | No (single unit, must be last) | All units 0-7 complete |

---

## 3. Critical Path Analysis

The critical path is the longest dependency chain determining the minimum total build time.

### Critical Path

```
Unit 0 --> Unit 1* --> Unit 5 --> Unit 7 --> Unit 8
  (or)
Unit 0 --> Unit 2* --> Unit 5 --> Unit 7 --> Unit 8
  (or)
Unit 0 --> Unit 3* --> Unit 5 --> Unit 7 --> Unit 8
  (or)
Unit 0 --> Unit 4* --> Unit 5 --> Unit 7 --> Unit 8

* Any of Units 1-4 as the longest Level 1 unit determines the critical path.
  Unit 6 is OFF the critical path if it finishes before Unit 5 starts Level 3.
```

### Estimated Duration by Unit

| Unit | Stories | Estimated Effort | Rationale |
|---|---|---|---|
| Unit 0 | 7 | Large | Foundational: DB schema, router, all services, localization, onboarding |
| Unit 1 | 14 | Large | Many stories, charts, budget logic, recurring transactions |
| Unit 2 | 15 | Large | Most stories, exercise library download, real-time workout UI, PR algorithms |
| Unit 3 | 11 | Large | API integration, barcode scanning, macro calculations |
| Unit 4 | 10 | Medium | Simpler data model (2 tables), streak algorithm |
| Unit 5 | 4 | Medium | Few stories but complex cross-module reads |
| Unit 6 | 17 | Large | Most stories (2 modules), breathing animations, sleep timeline |
| Unit 7 | 7 | Medium | Weighted progress logic, cross-module event subscriptions |
| Unit 8 | 7 | Medium-Large | EventBus wiring, AI API integration, E2E testing |

### Critical Path Duration

The critical path runs through 5 units sequentially:

```
Unit 0 (Large) -> slowest of {Unit 1, 2, 3, 4} (Large) -> Unit 5 (Medium) -> Unit 7 (Medium) -> Unit 8 (Medium-Large)
```

The bottleneck at Level 1 is whichever of Units 1-4 takes longest. Unit 2 (Gym, 15 stories) is the likely bottleneck among MVP feature units.

### Off-Critical-Path

- **Unit 6 (Sleep+Mental)**: Only depends on Unit 0 and only blocks Unit 7. If it completes before Unit 5 finishes, it does not affect the critical path. Can be developed in parallel with Units 1-4 and even overlap with Unit 5 development.

---

## 4. Parallelization Opportunities

### Maximum Parallelism: Level 1 (5 units)

The greatest parallelization opportunity is at Level 1, where up to 5 units can be developed simultaneously:

```
                    Unit 0 complete
                          |
          +-------+-------+-------+-------+
          |       |       |       |       |
       Unit 1  Unit 2  Unit 3  Unit 4  Unit 6
       (MVP)   (MVP)   (MVP)   (MVP)  (Phase 2)
```

**Practical parallelization strategies:**

| Strategy | Developers | Parallel Work | Description |
|---|---|---|---|
| Solo developer | 1 | Sequential within levels | Build Unit 0, then Units 1-4 sequentially, then 5, 6, 7, 8 |
| Two developers | 2 | 2-3 units at Level 1 | Dev A: Units 1, 3; Dev B: Units 2, 4, 6 |
| Three developers | 3 | Full Level 1 parallelism | Dev A: Units 1, 5; Dev B: Units 2, 7; Dev C: Units 3, 4, 6, 8 |
| Full team (5) | 5 | All Level 1 simultaneously | Each developer owns one Level 1 unit, then collaborate on Levels 2-4 |

### Phase-Based Parallelism

If the team wants to ship MVP before Phase 2:

```
Sprint 1:  Unit 0 (Core Foundation)
Sprint 2:  Units 1, 2, 3, 4 in parallel (MVP features)
Sprint 3:  Unit 5 (Dashboard + DayScore) -- completes MVP
           Unit 6 (Sleep+Mental) can start in parallel
Sprint 4:  Unit 6 continues/completes, Unit 7 (Goals)
Sprint 5:  Unit 8 (Integration + Intelligence)
```

### EventBus Stub Strategy for Parallel Development

When building Level 1 units in parallel, each unit can emit events without subscribers. The event emission code is self-contained within each module. Subscription wiring happens later in Unit 8. This means:

- Unit 1 emits `ExpenseAddedEvent` and `BudgetThresholdEvent` -- no subscriber needed yet
- Unit 2 emits `WorkoutCompletedEvent` -- no subscriber needed yet
- Unit 4 emits `HabitCheckedInEvent` -- no subscriber needed yet
- Unit 6 emits `SleepLogSavedEvent` and `MoodLoggedEvent` -- no subscriber needed yet

Event subscriptions (Habits listening to WorkoutCompleted, Nutrition listening to ExpenseAdded, etc.) are wired in Unit 8.

---

## 5. Integration Testing Checkpoints

### Checkpoint 1: Post-Unit 0 (Core Validation)

**When**: After Unit 0 is complete, before starting Level 1 units.

**Validates**:
- Drift database initializes correctly with AppSettings table
- go_router configuration navigates to stub routes
- EventBus can emit and subscribe to all 7 event types
- NotificationService schedules and fires local notifications
- HapticService triggers vibration on both platforms
- SecureStorageService encrypts and retrieves values
- BackupService exports and imports an empty database
- ExerciseLibraryService download mechanism works
- Localization switches between ES and EN
- Onboarding flow completes end-to-end and persists settings
- AppSettings read/write cycle works correctly
- Theme applies to all shared widgets

### Checkpoint 2: Post-Level 1 Feature Integration (Per-Unit)

**When**: After each Level 1 unit completes. Run independently per unit.

**Unit 1 (Finance) Validates**:
- Transaction CRUD with all categories persists and reads correctly
- Budget threshold calculation fires `BudgetThresholdEvent` at 80% and 100%
- `ExpenseAddedEvent` emits on every expense transaction
- Recurring transactions create entries at scheduled intervals
- Financial charts render with real data
- Date range filter produces correct results

**Unit 2 (Gym) Validates**:
- Exercise library downloads and persists on first launch
- Routine builder creates routines with ordered exercises
- Active workout flow: start from routine, log sets, rest timer, warmup marking, finish with summary
- PR detection identifies new weight and rep PRs correctly
- 1RM Epley calculation matches expected formula results
- `WorkoutCompletedEvent` emits on workout finish
- Workout history displays correct data

**Unit 3 (Nutrition) Validates**:
- Open Food Facts API search returns and caches food items
- Offline mode returns cached items when API is unreachable
- Meal logging with multiple food items calculates macro totals correctly
- Macro progress bars reflect logged meals accurately
- Water tracking increments/decrements correctly
- Meal templates save and apply correctly
- Custom food items persist with manual nutritional data

**Unit 4 (Habits) Validates**:
- Habit CRUD with all frequency types (daily, weekly, custom days)
- Daily check-in records and updates streak correctly
- Quantitative check-in records value and computes partial vs. complete correctly
- Streak resets on missed day (daily) or missed week (weekly)
- Calendar view shows correct color coding for historical data
- Statistics percentages match actual completion data
- Activate/deactivate preserves history and resets streak on reactivation

**Unit 6 (Sleep+Mental) Validates**:
- Sleep logging: bedtime, wake time, quality, interruptions produce correct sleep duration
- Sleep score formula produces expected values
- Energy check-in 3x/day records independently
- Mood check-in with tags and mini journal persists correctly
- Breathing session timer runs correctly with technique-specific cadences
- `SleepLogSavedEvent` and `MoodLoggedEvent` emit correctly
- Calendar view displays mood data with correct color mapping

### Checkpoint 3: Post-Unit 5 (Dashboard + DayScore Cross-Module Integration)

**When**: After Unit 5 completes. This is the first true cross-module integration test.

**Validates**:
- Dashboard reads live data from FinanceNotifier, GymNotifier, NutritionNotifier, HabitsNotifier
- Dashboard adapts layout when modules are activated/deactivated
- Quick action buttons route correctly to each module's entry screen
- DayScore reads from all 4 MVP feature Notifiers and computes weighted score
- DayScore component breakdown shows correct per-module contributions
- Score history persists and displays trend correctly
- Life snapshots capture and serialize module metrics
- Notification summary shows pending habits and budget alerts
- Time-of-day greeting displays correctly
- Module activation/deactivation in settings immediately updates dashboard layout

### Checkpoint 4: Post-Unit 7 (Goals Cross-Module Integration)

**When**: After Unit 7 completes.

**Validates**:
- Goal creation with sub-goals linked to specific modules
- Sub-goal weights validate to 100% total
- Weighted progress calculation produces correct results
- Milestone tracking with completion and overdue detection
- Event-driven auto-progress: completing a habit updates habit-linked sub-goal progress
- Event-driven auto-progress: logging sleep updates sleep-linked sub-goal progress
- Event-driven auto-progress: logging mood updates wellness-linked sub-goal progress
- `GoalProgressUpdatedEvent` emits and DashboardNotifier refreshes
- Goal progress feeds into DayScore calculation

### Checkpoint 5: Post-Unit 8 (Full System Integration -- End-to-End)

**When**: After Unit 8 completes. Final integration validation.

**Validates**:
- **Workout -> Habits auto-check**: Complete a workout -> gym-related habit auto-checks -> `HabitCheckedInEvent` fires -> Goals updates if linked -> DayScore recalculates -> Dashboard refreshes
- **Expense -> Nutrition suggestion**: Add a food-category expense -> `ExpenseAddedEvent` fires -> Nutrition shows meal logging suggestion
- **Budget alert flow**: Add expense that crosses 80% threshold -> `BudgetThresholdEvent` fires -> Dashboard shows alert card -> push notification fires
- **Sleep -> Goals -> Dashboard**: Log sleep -> `SleepLogSavedEvent` fires -> Goals updates sleep-linked sub-goal -> `GoalProgressUpdatedEvent` fires -> Dashboard refreshes -> DayScore recalculates
- **Mood -> Goals -> Dashboard**: Log mood -> `MoodLoggedEvent` fires -> Goals updates wellness-linked sub-goal -> `GoalProgressUpdatedEvent` fires -> Dashboard refreshes -> DayScore recalculates
- **Full DayScore recalculation chain**: Any module event triggers DayScore recalculation -> new score persists -> Dashboard shows updated score
- **AI Intelligence**: Configure AI provider -> start conversation -> send prompt -> receive streamed response -> conversation persists in history
- **Data Export/Import**: Full JSON backup exports all module data -> backup restores correctly on empty database and with merge conflict resolution
- **No circular dependencies**: Verify the provider DAG has no cycles
- **Event deduplication**: Verify that rapid successive events do not cause duplicate processing

### End-to-End Smoke Test Scenarios

| # | Scenario | Modules Involved | Event Chain |
|---|---|---|---|
| 1 | Complete morning routine | Habits, Sleep, Mental, DayScore, Dashboard | SleepLog -> HabitCheckIn x3 -> MoodLog -> DayScore recalc x5 -> Dashboard refresh x5 |
| 2 | Training day | Gym, Habits, Nutrition, DayScore, Dashboard | Workout -> Auto-check habit -> Nutrition macros adjust -> DayScore recalc x3 |
| 3 | Budget overspend day | Finance, Nutrition, Dashboard | Expense x5 -> Budget 80% alert -> Budget 100% alert -> Meal suggestion x2 |
| 4 | Goal progress cascade | Goals, Habits, Finance, DayScore, Dashboard | Habit streak reaches sub-goal target -> Goal progress updates -> DayScore recalc -> Dashboard refresh |
| 5 | Full data lifecycle | All modules | Onboard -> Use all modules for 1 day -> Export backup -> Wipe data -> Import backup -> Verify all data intact |
