# NFR Requirements — Unit 1: Finance

## Baseline

Unit 1 inherits all NFR requirements from Unit 0 (security, accessibility, maintainability, reliability). This document defines **Finance-specific** additions only.

---

## Performance

### PERF-FIN-01: Transaction List Scroll Performance
- Transaction list with 1000+ items must scroll at 60fps
- Use paginated queries (limit/offset or keyset pagination)
- Load 50 transactions per page, prefetch next page

### PERF-FIN-02: Chart Rendering
- Pie, bar, and line charts must render in < 500ms for up to 500 transactions
- Chart data computation runs in the Notifier (pre-computed), not in the widget build

### PERF-FIN-03: Budget Utilization Calculation
- Budget threshold check after each expense must complete in < 100ms
- Use indexed query on (categoryId, month, year) for fast aggregation

---

## Testing (PBT Extension)

### PBT-FIN-01: Custom Generators
- `Arbitrary<TransactionInput>` — valid amounts, types, category IDs, dates
- `Arbitrary<CategoryInput>` — valid names, icons, colors, types
- `Arbitrary<BudgetInput>` — valid amounts, months, years

### PBT-FIN-02: Properties to Test
- Round-trip: RT-FIN-01 to RT-FIN-03 (insert/query symmetry)
- Invariant: INV-FIN-01 to INV-FIN-05 (balance equation, utilization, referential integrity)
- Idempotence: IDP-FIN-01 to IDP-FIN-02 (recurring processing, budget upsert)

---

## Security (Extension — Finance-Specific)

### SEC-FIN-01: Financial Data Sensitivity
- Transaction amounts and categories are personal financial data
- Included in backup export (encrypted at OS level per SECURITY-01)
- No financial data in logs (AppLogger PII scrubber covers numeric patterns)

### SEC-FIN-02: Input Validation for Amounts
- All amount inputs validated as positive integers before persistence (BR-FIN-01)
- No SQL injection risk — Drift uses parameterized queries
- Integer overflow check: amounts capped at `2^53 - 1` (Dart int max on JS targets)

---

## Accessibility

### A11Y-FIN-01: Transaction List
- Each transaction row has Semantics label: "{type}: ${amount} en {category}, {date}"
- Swipe actions have accessible alternatives (long-press menu)

### A11Y-FIN-02: Charts
- All charts have text alternative descriptions
- Pie chart: "Distribución de gastos: {category} {percentage}%"
- Color is not the only differentiator (patterns or labels on chart segments)

### A11Y-FIN-03: Budget Alerts
- Budget threshold alerts include Semantics announcement
- Progress bars have value labels: "{category}: {spent} de {budget} ({percentage}%)"

---

## Tech Stack (Finance-Specific Additions)

| Component | Package | Already in pubspec | Purpose |
|---|---|---|---|
| Charts | `fl_chart` | No — add to pubspec | Pie, bar, line charts for financial dashboard |
| Currency formatting | `intl` | Yes | NumberFormat for COP, USD, etc. |

**Action**: Add `fl_chart` to pubspec.yaml during Code Generation.
