# NFR Requirements — Unit 2: Gym

## Baseline
Inherits all NFRs from Unit 0. This document defines **Gym-specific** additions only.

---

## Performance

### PERF-GYM-01: Exercise Library Bulk Insert
- Loading 200+ exercises from bundled JSON must complete in < 3 seconds
- Use Drift batch insert, run in isolate if needed
- Show progress indicator during load

### PERF-GYM-02: Active Workout Real-Time UI
- Set logging must persist in < 50ms (instant feel)
- Rest timer countdown must render at 60fps (no jank)
- Workout duration counter updates every second without rebuilding entire widget tree

### PERF-GYM-03: Exercise Search
- Search/filter across 200+ exercises must return results in < 100ms
- Use indexed columns (name, primaryMuscle, equipment) in Drift

---

## Testing (PBT)

### PBT-GYM-01: Properties
- RT: exercise insert/query, routine insert/query, workout set insert/query
- INV: volume excludes warmups, PR only from non-warmup sets, 1RM Epley formula consistency
- IDP: finishing workout twice = same summary, logging same set twice = one row

---

## Accessibility

### A11Y-GYM-01: Active Workout Screen
- Each set row: Semantics "{exercise}: {weight}kg × {reps} reps{warmup indicator}"
- Rest timer: live region announcing remaining seconds every 15s
- Haptic feedback respects reduce motion setting

### A11Y-GYM-02: Exercise Library
- Each exercise card: Semantics "{name}, {primaryMuscle}, {equipment}"
- Search field with clear button accessible

---

## New Dependencies
None — fl_chart already added in Unit 1 for progress charts.
