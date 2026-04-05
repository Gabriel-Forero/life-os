# NFR Design Patterns — Unit 1: Finance

## Baseline

Inherits all patterns from Unit 0 (Result<T>, AppLogger, input validation, global error handler). This document defines **Finance-specific** patterns only.

---

## 1. Paginated Transaction Loading (PERF-FIN-01)

**Pattern**: Keyset pagination with Drift streams

```
FinanceDao.watchTransactions(from, to, {int limit = 50, int? afterId})
  → Stream<List<Transaction>>
  → WHERE date BETWEEN from AND to
    AND (afterId IS NULL OR id < afterId)
    ORDER BY date DESC, id DESC
    LIMIT limit
```

- FinanceNotifier maintains `_lastLoadedId` for next page trigger
- UI triggers `loadMore()` when scroll reaches 80% of current list
- Drift stream auto-updates when new transactions are added

---

## 2. Optimistic Delete with Undo (BR-FIN-06)

**Pattern**: Timer-based deferred commit

```
class PendingDelete {
  final Transaction transaction;
  final Timer timer;
}

// In FinanceNotifier:
PendingDelete? _pendingDelete;

void deleteTransaction(int id) {
  // 1. Remove from state immediately
  // 2. Start 5-second timer
  // 3. On timer complete: commit to DB
}

void undoDelete() {
  // 1. Cancel timer
  // 2. Restore transaction to state
  // 3. Clear _pendingDelete
}
```

---

## 3. Budget Threshold Deduplication (BR-FIN-13)

**Pattern**: Previous-vs-current comparison

```
// After expense insert:
previousUtil = (spentBefore) / budgetAmount
currentUtil = (spentBefore + expenseAmount) / budgetAmount

if (previousUtil < 0.8 && currentUtil >= 0.8) → emit 80% alert
if (previousUtil < 1.0 && currentUtil >= 1.0) → emit 100% alert
```

- No persistent tracking needed — dedup is computed from current data
- Each threshold fires at most once per budget per month by definition

---

## 4. Chart Data Pre-computation (PERF-FIN-02)

**Pattern**: Notifier-level computation, widget reads

```
// FinanceNotifier computed getters:
List<CategoryExpenseSlice> get pieChartData;     // Pre-computed from transactions
List<DailyBar> get barChartData;                  // Pre-computed grouped by day/week
List<CumulativePoint> get lineChartData;          // Pre-computed running total

// Recomputed when: transactions change OR dateRange changes
// Widget just reads the getter, no heavy computation in build()
```

---

## 5. Category Deletion Transaction (BR-FIN-09)

**Pattern**: Drift transaction for atomic multi-table operation

```
Future<Result<void>> deleteCategory(int id, int targetCategoryId) {
  return db.transaction(() async {
    // 1. Update all transactions: categoryId = targetCategoryId
    // 2. Delete all budgets for this categoryId
    // 3. Delete the category
    // All or nothing — if any step fails, entire operation rolls back
  });
}
```

---

## 6. Amount Display Formatting (SEC-FIN-01 / A11Y-FIN-01)

**Pattern**: Extension method on int

```
extension AmountFormatting on int {
  String toCurrency(String currencyCode) {
    final format = NumberFormat.currency(
      locale: currencyCode == 'COP' ? 'es_CO' : 'en_US',
      symbol: _currencySymbol(currencyCode),
      decimalDigits: _hasDecimals(currencyCode) ? 2 : 0,
    );
    return format.format(_hasDecimals(currencyCode) ? this / 100 : this);
  }
}
```

- COP: no decimals, `$3.500.000`
- USD: 2 decimals, `$35,000.00`
- Accessible: Semantics uses plain text "3 millones 500 mil pesos"

---

## Compliance Summary

| NFR | Status | Implementation |
|---|---|---|
| PERF-FIN-01 | Designed | Keyset pagination, 50/page |
| PERF-FIN-02 | Designed | Notifier pre-computation |
| PERF-FIN-03 | Designed | Indexed query, comparison dedup |
| PBT-FIN-01 | Designed | Custom generators for 3 types |
| PBT-FIN-02 | Designed | 10 properties (3 RT, 5 INV, 2 IDP) |
| SEC-FIN-01 | Compliant | OS encryption, no PII in logs |
| SEC-FIN-02 | Compliant | Positive int validation, parameterized queries |
| A11Y-FIN-01 | Designed | Semantics on transactions |
| A11Y-FIN-02 | Designed | Chart text alternatives |
| A11Y-FIN-03 | Designed | Budget progress labels |
