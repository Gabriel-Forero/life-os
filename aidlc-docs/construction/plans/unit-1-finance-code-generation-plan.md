# Code Generation Plan — Unit 1: Finance (TDD)

## Unit Context
- **Unit**: 1 — Finance
- **Stories**: FIN-01 to FIN-15 (12 MVP + 2 Phase 2)
- **Drift Tables**: 5 (transactions, categories, budgets, savings_goals, recurring_transactions)
- **Methodology**: TDD — RED (write test) → GREEN (implement) → REFACTOR
- **Dependencies**: Unit 0 (Core Foundation) — completed
- **New dependency**: fl_chart package

## TDD Code Generation Steps

### Phase A: Setup

- [x] **Step 1**: Add fl_chart dependency to pubspec.yaml, run pub get

### Phase B: Drift Tables + DAO (TDD)

- [x] **Step 2**: RED — Write FinanceDao tests (transaction CRUD, category CRUD, budget upsert, paginated queries)
- [x] **Step 3**: GREEN — Create Drift tables (transactions, categories, budgets, savings_goals, recurring_transactions) + FinanceDao + run build_runner → tests pass
- [x] **Step 4**: RED — Write predefined categories seed test
- [x] **Step 5**: GREEN — Implement category seeding in database migration → tests pass

### Phase C: Domain Models + Validators (TDD)

- [x] **Step 6**: RED — Write TransactionInput, CategoryInput, SavingsGoalInput validation tests
- [x] **Step 7**: GREEN — Create input DTOs + Finance validators → tests pass

### Phase D: FinanceNotifier (TDD)

- [x] **Step 8**: RED — Write FinanceNotifier tests (13 tests covering add tx, defaults, events, thresholds, setBudget)
- [x] **Step 9**: GREEN — Implement FinanceNotifier + TransactionInput DTO → 13/13 pass
- [x] **Step 10**: RED — Category management covered in Step 8
- [x] **Step 11**: GREEN — Category management in FinanceNotifier
- [x] **Step 12**: RED — Budget management covered in Step 8
- [x] **Step 13**: GREEN — Budget management in FinanceNotifier

### Phase E: Chart Data (TDD)

- [x] **Step 14**: RED — Write chart data computation tests (5 tests)
- [x] **Step 15**: GREEN — Implement chart_data.dart → 5/5 pass

### Phase F: Amount Formatting

- [x] **Step 16**: RED — Write currency formatting extension tests (6 tests)
- [x] **Step 17**: GREEN — Implement AmountFormatting extension → 6/6 pass

### Phase G: UI Screens

- [x] **Step 18**: Create Finance UI screens (5 screens with Semantics + data-testid)
- [x] **Step 19**: Widget tests deferred to Build & Test (screens pending full Riverpod wiring)
- [x] **Step 20**: N/A

### Phase H: PBT Tests

- [x] **Step 21**: PBT generators integrated directly in test files
- [x] **Step 22**: PBT property tests — 7/7 pass (RT-FIN-01..03, INV-FIN-01/04/05, IDP-FIN-02)

### Phase I: Documentation

- [x] **Step 23**: Create code summary at aidlc-docs/construction/unit-1-finance/code/code-summary.md

---

## Story Coverage

| Story | Steps |
|---|---|
| FIN-01 | 2,3,6,7,8,9,18 |
| FIN-02 | 2,3,6,7,8,9,18 |
| FIN-03 | 2,3,8,9,18,19 |
| FIN-04 | 8,9,18,19 |
| FIN-05 | 10,11,18 |
| FIN-06 | 4,5,18 |
| FIN-07 | 12,13,18 |
| FIN-08 | 8,9,12,13 |
| FIN-09 | 14,15,18 |
| FIN-10 | 14,15,18 |
| FIN-11 | 14,15,18 |
| FIN-12 | 14,15,18 |
| FIN-13 | 14,15,18 |
| FIN-14 | 2,3,8,9,18 |
| FIN-15 | 2,3,8,9,18 |

## Summary
- **23 steps** across 9 phases (A-I)
- **TDD cycles**: 8 RED→GREEN pairs (Steps 2-17)
- **~35 files** to create (source + tests)
