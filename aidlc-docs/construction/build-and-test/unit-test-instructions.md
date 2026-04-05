# Unit Test Execution — LifeOS

## Run All Unit + PBT Tests

```bash
flutter test test/unit/ test/pbt/
```

**Expected**: 619 tests pass, 0 failures.

## Run Per-Unit Tests

### Unit 0: Core Foundation (88 tests)
```bash
flutter test test/unit/core/ test/pbt/core/
```

### Unit 1: Finance (71 tests)
```bash
flutter test test/unit/finance/ test/pbt/finance/
```

### Unit 2: Gym (60 tests)
```bash
flutter test test/unit/gym/ test/pbt/gym/
```

### Unit 3: Nutrition (59 tests)
```bash
flutter test test/unit/nutrition/ test/pbt/nutrition/
```

### Unit 4: Habits (25 tests)
```bash
flutter test test/unit/habits/
```

### Unit 5: Dashboard + DayScore (57 tests)
```bash
flutter test test/unit/dashboard/ test/pbt/dashboard/
```

### Unit 6: Sleep + Mental (100 tests)
```bash
flutter test test/unit/sleep/ test/unit/mental/ test/pbt/sleep_mental/
```

### Unit 7: Goals (89 tests)
```bash
flutter test test/unit/goals/ test/pbt/goals/
```

### Unit 8: Integration + Intelligence (70 tests)
```bash
flutter test test/unit/intelligence/ test/unit/integration/ test/pbt/integration/
```

## Run with Coverage

```bash
flutter test --coverage test/unit/ test/pbt/
# Generate HTML report (requires lcov):
# genhtml coverage/lcov.info -o coverage/html
```

**Coverage targets**:
- Core services/DAOs/notifiers: ≥80%
- Validators: ≥95%
- Presentation: not measured (UI shells with mock data)

## Test Categories

| Category | Location | Count | Description |
|---|---|---|---|
| DAO tests | `test/unit/*/database/` | ~120 | Drift CRUD with in-memory DB |
| Validator tests | `test/unit/*/domain/` | ~130 | Pure function validation |
| Notifier tests | `test/unit/*/services/` | ~200 | Business logic with mocked/real DB |
| PBT tests | `test/pbt/` | ~80 | Property-based: round-trip, invariant, idempotence |
| Widget tests | `test/widget/` | ~5 | Onboarding screen tests |

## Fix Failing Tests

1. Run failing test in isolation: `flutter test <file> --name "<test name>"`
2. Check error output for assertion failures vs compilation errors
3. Compilation errors: run `dart run build_runner build` (Drift codegen)
4. google_fonts errors: add `GoogleFonts.config.allowRuntimeFetching = false;` in test setUp
5. Drift `isNull`/`isNotNull` conflicts: add `hide isNull, isNotNull` to Drift import
