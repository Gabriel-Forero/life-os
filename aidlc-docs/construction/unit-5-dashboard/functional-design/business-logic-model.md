# Business Logic Model — Unit 5: Dashboard + DayScore

## 1. Score Calculation Flow

```
DayScoreNotifier.calculateDayScore(date)
  │
  ├─ 1. Load configs from DashboardDao.getScoreConfigs()
  │       → List<DayScoreConfig> (moduleKey, weight, isEnabled)
  │
  ├─ 2. For each ENABLED module, fetch raw score (0.0–100.0)
  │       │  finance   → FinanceNotifier.currentBudgetScore()  (mocked: 75.0)
  │       │  gym       → GymNotifier.currentFitnessScore()     (mocked: 80.0)
  │       │  nutrition → NutritionNotifier.todayNutritionScore()(mocked: 70.0)
  │       └─ habits    → HabitsNotifier.todayCompletionScore() (mocked: 90.0)
  │
  ├─ 3. Compute weighted sum
  │       weightedSum = Σ(rawValue_i × weight_i)
  │       totalWeight = Σ(weight_i)   [enabled only]
  │       totalScore  = ROUND(weightedSum / totalWeight).clamp(0, 100)
  │
  ├─ 4. Persist to database (upsert day_scores, replace score_components)
  │       → DashboardDao.upsertDayScore(date, totalScore, components)
  │
  └─ 5. Update DayScoreState
          → state = state.copyWith(todayScore: totalScore, components: ...)
```

---

## 2. Dashboard Aggregation Flow

```
DashboardNotifier.refresh()
  │
  ├─ 1. Read today's DayScore from DayScoreNotifier.state.todayScore
  │
  ├─ 2. Load enabled module configs from DashboardDao.getScoreConfigs()
  │
  ├─ 3. For each enabled module, build ModuleCardData
  │       │  moduleKey  → from config
  │       │  title      → localized module name (Spanish)
  │       │  subtitle   → primary metric string from notifier state (mocked)
  │       │  color      → AppColors.moduleColor(moduleKey)
  │       │  icon       → module icon constant
  │       │  isEnabled  → config.isEnabled
  │       └─ priority   → fixed order map
  │
  ├─ 4. Sort cards by priority ASC
  │
  └─ 5. Update DashboardState
          → state = state.copyWith(dayScore: score, cards: sorted)
```

---

## 3. Snapshot Generation Flow

```
DashboardNotifier._maybeGenerateYesterdaySnapshot()
  │
  ├─ 1. Compute yesterday = today − 1 day (normalized to midnight)
  │
  ├─ 2. Query DashboardDao.getSnapshotForDate(yesterday)
  │       IF snapshot EXISTS → return (idempotent, no-op)
  │
  ├─ 3. Collect current module metrics (from notifier states / mocked)
  │       metrics = {
  │         'finance':   { 'balance': ..., 'budgetUsed': ... },
  │         'gym':       { 'workoutsThisWeek': ..., 'volumeKg': ... },
  │         'nutrition': { 'avgCalories': ..., 'proteinGrams': ... },
  │         'habits':    { 'completionRate': ..., 'streak': ... },
  │       }
  │
  ├─ 4. Fetch yesterday's totalScore from DashboardDao.getDayScoreForDate(yesterday)
  │       IF no score → use 0 as fallback
  │
  └─ 5. Insert snapshot → DashboardDao.insertLifeSnapshot(yesterday, score, metricsJson)
```

---

## 4. EventBus Subscription Flow

```
DayScoreNotifier (init)
  │
  ├─ eventBus.on<BudgetThresholdEvent>()
  │     .listen((_) => calculateDayScore(DateTime.now()))
  │
  ├─ eventBus.on<HabitCheckedInEvent>()
  │     .listen((_) => calculateDayScore(DateTime.now()))
  │
  └─ eventBus.on<GoalProgressUpdatedEvent>()
        .listen((_) => calculateDayScore(DateTime.now()))
```

Subscriptions are stored in a list and cancelled in `dispose()`.

---

## 5. Config Seeding Flow

```
DashboardDao.seedDefaultConfigsIfEmpty()
  │
  ├─ Query: SELECT COUNT(*) FROM day_score_configs
  │
  ├─ IF count == 0:
  │     INSERT INTO day_score_configs for each module:
  │       ['finance', 'gym', 'nutrition', 'habits']
  │       with weight = 1.0, is_enabled = true
  │
  └─ ELSE: no-op (configs already seeded)
```

Called once during AppDatabase migration / DAO initialization.
