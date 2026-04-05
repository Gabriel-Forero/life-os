# Integration Test Instructions — LifeOS

## Purpose

Test cross-module EventBus flows, database migrations, and end-to-end user workflows on real devices/emulators.

## Setup

```bash
# Ensure Flutter integration test driver is available (bundled with SDK)
# Connect Android emulator or iOS simulator
flutter devices  # Verify device is connected
```

## Integration Test Scenarios

### Scenario 1: EventBus — Workout → Habit Auto-Check (INT-01)

**Description**: Completing a workout auto-checks linked gym habits.

**Test Steps**:
1. Create habit "Ir al gym" with `linkedEvent = 'WorkoutCompletedEvent'`
2. Start workout, log sets, finish workout
3. Verify habit is auto-checked for today
4. Verify HabitCheckedInEvent was emitted
5. Verify DayScore recalculated

**Expected**: Habit shows as completed without manual check-in.

### Scenario 2: EventBus — Expense → Budget Alert (INT-03)

**Description**: Adding an expense that crosses budget threshold triggers notification.

**Test Steps**:
1. Create budget: $100,000 for "Alimentacion"
2. Add expense: $85,000 in "Alimentacion" (crosses 80%)
3. Verify BudgetThresholdEvent emitted with percentage ≥ 0.8
4. Verify dashboard shows budget alert card

**Expected**: Budget alert appears in dashboard.

### Scenario 3: EventBus — Training Day Nutrition Adjustment (INT-02)

**Description**: Completing a workout adjusts nutrition goals by configured percentages.

**Test Steps**:
1. Set nutrition goals: 2500 cal, 180g protein
2. Configure training day: +15% cal, +20% protein
3. Complete a workout (emit WorkoutCompletedEvent)
4. Verify nutrition goals adjusted: 2875 cal, 216g protein

**Expected**: Nutrition dashboard shows adjusted goals with "Dia de entrenamiento" indicator.

### Scenario 4: Full Onboarding → First Data Flow

**Description**: Complete onboarding and verify all modules initialize correctly.

**Test Steps**:
1. Launch app (fresh install)
2. Complete onboarding: language ES, name "Camila", currency COP, all modules enabled, goal "balance"
3. Verify AppSettings persisted
4. Navigate to each module: Finance, Gym, Nutrition, Habits
5. Verify predefined categories seeded (Finance)
6. Verify exercise library loaded (Gym)
7. Verify empty states shown in each module

**Expected**: All modules functional from first launch.

### Scenario 5: Backup Export → Import Round-Trip (INT-06/07)

**Description**: Export all data, clear app, import backup, verify data integrity.

**Test Steps**:
1. Add test data: 5 transactions, 1 workout with sets, 3 meals, 2 habits with check-ins
2. Export full backup (ZIP)
3. Verify manifest contains all modules with correct record counts
4. Import backup into clean database
5. Verify all data restored: transaction amounts, workout sets, meal items, habit logs

**Expected**: Zero data loss after round-trip.

### Scenario 6: DayScore End-to-End

**Description**: Actions across modules update DayScore in real-time.

**Test Steps**:
1. Set DayScore weights: Finance 25%, Gym 25%, Nutrition 25%, Habits 25%
2. Complete habit → verify DayScore increases
3. Add expense within budget → verify Finance score
4. Log meal meeting 80% of calorie goal → verify Nutrition score
5. Verify dashboard DayScore ring updates

**Expected**: DayScore reflects composite of all module scores.

## Running Integration Tests

```bash
# Run on connected device/emulator
flutter test integration_test/
```

**Note**: Integration test files (`test/integration/`) currently contain stubs. Full integration tests require Riverpod provider wiring which is pending. The scenarios above serve as the test plan for manual or automated testing once wiring is complete.

## Performance Test Scenarios

### PERF-01: Transaction List Scroll (1000+ items)
- Insert 1000 transactions programmatically
- Scroll transaction list
- **Expected**: 60fps, no jank

### PERF-02: Exercise Library Load
- Clear exercise data, trigger library load
- **Expected**: 200+ exercises loaded in < 3 seconds

### PERF-03: Chart Rendering
- Load Finance dashboard with 500 transactions
- **Expected**: Charts render in < 500ms

### PERF-04: Backup Export (large dataset)
- Insert 5000 records across all modules
- Export full backup
- **Expected**: Complete in < 10 seconds
