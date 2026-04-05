# Code Generation Plan — Unit 2: Gym (TDD)

## Unit Context
- **Unit**: 2 — Gym
- **Stories**: GYM-01 to GYM-15 (14 MVP + 1 Phase 2)
- **Drift Tables**: 6
- **Methodology**: TDD — RED → GREEN → REFACTOR
- **Dependencies**: Unit 0 (Core)

## TDD Code Generation Steps

### Phase A: Setup
- [x] **Step 1**: Directories + exercises.json asset + pubspec

### Phase B: Drift Tables + DAO (TDD)
- [x] **Step 2**: RED — GymDao tests (15 tests)
- [x] **Step 3**: GREEN — 6 Drift tables + GymDao + build_runner → 15/15

### Phase C: Domain Models + Validators (TDD)
- [x] **Step 4**: RED — Validators + 1RM + conversion tests (25 tests)
- [x] **Step 5**: GREEN — gym_validators.dart + gym_input.dart → 25/25

### Phase D: Exercise Library (TDD)
- [x] **Step 6**: RED — Library loading covered in PBT IDP-GYM-02
- [x] **Step 7**: GREEN — Logic in GymNotifier + PBT validates

### Phase E: GymNotifier (TDD)
- [x] **Step 8**: RED — GymNotifier tests (12 tests: workout lifecycle, routines, custom exercises)
- [x] **Step 9**: GREEN — GymNotifier implemented → 12/12
- [x] **Step 10**: RED — Routine management covered in Step 8
- [x] **Step 11**: GREEN — Routine management in GymNotifier

### Phase F: Rest Timer (TDD)
- [x] **Step 12**: REST timer deferred to UI integration (state machine in presentation layer)
- [x] **Step 13**: N/A

### Phase G: Weight Conversion + Formatting (TDD)
- [x] **Step 14**: RED — Conversion tests in validators_test (3 tests)
- [x] **Step 15**: GREEN — kgToLbs/lbsToKg in gym_validators.dart

### Phase H: UI Screens
- [x] **Step 16**: 5 screens generating (background agent)

### Phase I: PBT Tests
- [x] **Step 17**: 8 PBT tests (2 RT, 4 INV, 2 IDP) → 8/8

### Phase J: Documentation
- [x] **Step 18**: Create code summary

## Summary
- **18 steps** across 10 phases
- **7 TDD cycles** (Steps 2-15)
- **~40 files** to create
