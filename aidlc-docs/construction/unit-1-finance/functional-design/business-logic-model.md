# Business Logic Model — Unit 1: Finance

## Purpose

Defines the step-by-step business logic flows for Unit 1. Each flow describes operations, decision points, error paths, and expected outcomes.

---

## 1. Add Transaction Flow

### Flow Steps

1. User taps "+" on the Finance screen. A form appears with type toggle (income/expense), amount input, category picker, optional note, and date picker.
2. **Validate input**:
   - 2a. `amountCents > 0` per BR-FIN-01. If invalid → inline error.
   - 2b. `note.length <= 200` per BR-FIN-04. If invalid → inline error.
   - 2c. `date <= DateTime.now()` per BR-FIN-03. If invalid → inline error.
3. **Resolve category**:
   - 3a. If `categoryId != null`: use it.
   - 3b. If `categoryId == null && type == 'expense'`: assign "Otros" category ID per BR-FIN-02.
   - 3c. If `categoryId == null && type == 'income'`: assign "General" category ID per BR-FIN-02.
4. **Insert transaction** via `FinanceDao.insertTransaction()`.
5. **Post-insert logic**:
   - 5a. If `type == 'expense'`: emit `ExpenseAddedEvent(transactionId, categoryName, amountCents)` per BR-FIN-05.
   - 5b. If `type == 'expense'` and category has a budget for this month: check budget utilization per BR-FIN-13.
     - If utilization crossed 80% → emit `BudgetThresholdEvent(budgetId, categoryName, percentage)`.
     - If utilization crossed 100% → emit `BudgetThresholdEvent(budgetId, categoryName, percentage)`.
6. **Update state**: Refresh transaction list, recalculate `MonthSummary`.
7. **Navigate back** to transaction list. Show success feedback.

### Error Paths

- **Validation failure**: Inline error on the form field. User corrects and retries.
- **Database failure**: `DatabaseFailure` with user message "Error al guardar transaccion". Snackbar with retry.

---

## 2. Edit Transaction Flow

### Flow Steps

1. User swipes right on a transaction (FIN-04 Scenario 2) → opens edit form pre-filled with current values.
2. User modifies fields. Same validations as Add Transaction (step 2).
3. **Update transaction** via `FinanceDao.updateTransaction()`.
4. **Recalculate**: If category or amount changed, recalculate `MonthSummary` and budget utilizations.
5. **No EventBus events** on edit (BR-FIN-05 — only new expense creation emits).
6. Navigate back with success feedback.

---

## 3. Delete Transaction Flow (with Undo)

### Flow Steps

1. User swipes left on a transaction (FIN-04 Scenario 1).
2. Show confirmation dialog: "Eliminar transaccion de $X en [category]?"
3. User confirms.
4. **Optimistic removal**: Remove from in-memory list immediately. Update UI and balance.
5. Show snackbar: "Transaccion eliminada" with "Deshacer" button, 5-second timer.
6. **Timer running**:
   - 6a. If user taps "Deshacer" within 5s: restore transaction to list, cancel timer. No DB change.
   - 6b. If 5s pass without undo: commit `FinanceDao.deleteTransaction(id)` to database.
7. **Recalculate** MonthSummary and budget utilizations.

---

## 4. Category Management Flow

### Create Custom Category

1. User navigates to category management. Taps "Create category".
2. Enter name, pick icon (from Material icons grid), pick color (from palette).
3. **Validate**:
   - 3a. Name 1-30 chars after trim per BR-FIN-10.
   - 3b. Name uniqueness (case-insensitive) per BR-FIN-07.
4. Insert via `FinanceDao.insertCategory()` with `isPredefined = false`.
5. Category appears in the picker list.

### Edit Predefined Category (Q3:B)

1. User selects a predefined category.
2. Icon and color fields are editable. Name field is read-only (grayed out).
3. Save updates icon/color only. Name unchanged.

### Delete Custom Category

1. User taps delete on a custom category.
2. **Check transactions**: query count of transactions with this categoryId.
   - 2a. If count == 0: delete category and its budgets. Done.
   - 2b. If count > 0: show reassignment dialog.
3. **Reassignment dialog**: "Esta categoria tiene {count} transacciones. Reasignar a:" + category picker (excluding the one being deleted).
4. User selects target category. Confirm.
5. **Execute in transaction**:
   - Update all transactions with old categoryId to new categoryId.
   - Delete all budgets with old categoryId (Q2:A).
   - Delete the category.
6. Refresh category list and transaction list.

---

## 5. Budget Management Flow

### Set Budget

1. User navigates to Budget Overview (FIN-07).
2. Sees list of categories with current month's budgets (or "Sin presupuesto").
3. Taps a category → enters amount.
4. **Validate**: `amountCents > 0` per BR-FIN-12.
5. **Upsert** via `FinanceDao`: if budget exists for (categoryId, month, year) → update. Else → insert (BR-FIN-11).
6. Show updated budget bar with utilization percentage.

### Budget Threshold Check (called after every expense)

1. After expense insert, look up budget for (expense.categoryId, currentMonth, currentYear).
2. If no budget exists → skip.
3. Calculate `spentCents = sum(expenses for this category this month)`.
4. Calculate `utilization = spentCents / budgetAmountCents`.
5. **Check 80% threshold**:
   - Calculate previous utilization (before this expense): `(spentCents - expense.amountCents) / budgetAmountCents`.
   - If previous < 0.8 AND current >= 0.8 → emit `BudgetThresholdEvent`.
6. **Check 100% threshold**:
   - If previous < 1.0 AND current >= 1.0 → emit `BudgetThresholdEvent`.
7. Thresholds are per category per month. Each threshold level emits at most once per month (dedup via checking previous utilization).

---

## 6. Financial Dashboard Flow

### Flow Steps

1. User opens Finance tab → Financial Dashboard (FIN-09).
2. **Default range**: Current calendar month (Q6:A).
3. **Query data** for the range:
   - Total income, total expenses, net balance (MonthSummary).
   - Transactions grouped by category (for pie chart).
   - Transactions grouped by day/week (for bar chart).
   - Cumulative net balance per day (for line chart).
4. **Display**:
   - Summary card: income (green), expenses (red), balance.
   - Pie chart: expense distribution by category (FIN-10).
   - Bar chart: income vs expenses by day/week (FIN-11).
   - Line chart: savings trend (FIN-12).
5. **Date range selector** (FIN-13): user picks "Este mes", "Mes pasado", or custom range → re-query.

---

## 7. Savings Goal Flow (Phase 2)

### Create Goal

1. User navigates to Savings Goals screen (FIN-14).
2. Taps "Create goal". Enter name, target amount, optional deadline.
3. **Validate** per BR-FIN-21 (target > 0) and BR-FIN-22 (deadline in future if set).
4. Insert via `FinanceDao.insertSavingsGoal()`.
5. Goal appears as a card with progress bar at 0%.

### Contribute to Goal

1. User taps on a goal → "Add contribution".
2. Enter amount in cents. Must be positive (BR-FIN-19).
3. `currentCents += amountCents`.
4. Update progress bar and percentage.
5. Check completion per BR-FIN-20: if `currentCents >= targetCents` → mark `isCompleted = true`.
6. Show confetti/celebration animation if just completed.

---

## 8. Recurring Transaction Processing (Phase 2)

### Flow Steps

1. On app launch (or periodic check), call `processRecurringTransactions()`.
2. Query all recurring where `isActive == true AND nextOccurrence <= DateTime.now()`.
3. For each due recurring:
   - 3a. Create a Transaction from the template (type, amount, category, note + " (recurrente)").
   - 3b. Set `transaction.recurringId = recurring.id`.
   - 3c. Advance `nextOccurrence` based on frequency (BR-FIN-23).
   - 3d. If the new `nextOccurrence` is still in the past (app was closed for days), repeat step 3a-3c.
4. Save all created transactions in a batch.
5. Post-insert: emit events for any expense transactions (same as flow 1, step 5).

---

## Testable Properties (PBT-01 Compliance)

### Round-Trip Properties

| Property | Description |
|---|---|
| RT-FIN-01 | Transaction insert → query by id returns identical fields |
| RT-FIN-02 | Category insert → query returns identical fields |
| RT-FIN-03 | Budget upsert → query returns latest amount |

### Invariant Properties

| Property | Description |
|---|---|
| INV-FIN-01 | For any set of transactions: `totalIncome - totalExpenses == netBalance` |
| INV-FIN-02 | Budget utilization is always `spentCents / budgetCents` (non-negative) |
| INV-FIN-03 | After category deletion, zero transactions reference the deleted categoryId |
| INV-FIN-04 | All transaction amounts are strictly positive |
| INV-FIN-05 | Every transaction has a valid categoryId that exists in the categories table |

### Idempotence Properties

| Property | Description |
|---|---|
| IDP-FIN-01 | Processing recurring transactions twice in the same minute produces the same number of new transactions as once |
| IDP-FIN-02 | Setting the same budget amount twice for the same category/month results in one budget row |
