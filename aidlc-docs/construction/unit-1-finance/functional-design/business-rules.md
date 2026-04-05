# Business Rules — Unit 1: Finance

## Purpose

Defines all business rules for Unit 1 covering transactions, categories, budgets, charts, savings goals, and recurring transactions.

---

## Transaction Rules

### BR-FIN-01: Amount Must Be Positive

**Description**: Transaction amount (in cents) must be strictly greater than zero. Zero and negative values are rejected.

**Validation Criteria**:
- `amountCents <= 0` returns `ValidationFailure(field: 'amountCents')`
- User message: "El monto debe ser mayor a $0"
- Applies to both income and expense

---

### BR-FIN-02: Default Category Assignment

**Description**: If no category is selected, expenses default to "Otros" and income defaults to "General" (Q5:B).

**Validation Criteria**:
- Expense with `categoryId == null` → assign predefined "Otros" category ID
- Income with `categoryId == null` → assign predefined "General" category ID
- The default category IDs are resolved at runtime from the categories table (not hardcoded)

---

### BR-FIN-03: Transaction Date Constraint

**Description**: Transaction date cannot be in the future. Users can backdate transactions to any past date.

**Validation Criteria**:
- `date > DateTime.now()` returns `ValidationFailure(field: 'date')`
- `date <= DateTime.now()` is accepted (any past date valid)

---

### BR-FIN-04: Note Length Limit

**Description**: Transaction notes are optional and limited to 200 characters.

**Validation Criteria**:
- `note == null` is valid
- `note.length > 200` returns `ValidationFailure(field: 'note')`
- Empty string is treated as null (no note)

---

### BR-FIN-05: Expense Emits Event

**Description**: Every time a new expense transaction is created, an `ExpenseAddedEvent` is emitted on the EventBus with the transaction ID, category name, and amount.

**Validation Criteria**:
- `addTransaction()` with `type == 'expense'` emits `ExpenseAddedEvent` after successful insert
- Income transactions do NOT emit `ExpenseAddedEvent`
- Edit and delete do NOT emit events (only new expense creation)

---

### BR-FIN-06: Undo Delete (5-Second Buffer)

**Description**: When a transaction is deleted (via swipe), the deletion is shown in UI immediately but the actual database delete is deferred by 5 seconds. An "Undo" snackbar is shown. If user taps "Undo", the transaction is restored.

**Validation Criteria**:
- Transaction is removed from the in-memory list immediately
- Database delete is scheduled after 5 seconds
- "Undo" within 5 seconds cancels the scheduled delete and restores the transaction in the list
- After 5 seconds, the delete is committed and undo is no longer available
- Balance updates reflect the pending delete immediately

---

## Category Rules

### BR-FIN-07: Category Name Uniqueness

**Description**: Category names must be unique (case-insensitive). No two categories can have the same name.

**Validation Criteria**:
- Creating a category with an existing name (case-insensitive match) returns `ValidationFailure`
- User message: "Ya existe una categoria con ese nombre"

---

### BR-FIN-08: Predefined Category Protection (Q3:B)

**Description**: Predefined categories (`isPredefined = true`) can have their icon and color changed, but cannot be renamed or deleted.

**Validation Criteria**:
- Attempting to rename a predefined category returns `ValidationFailure`
- Attempting to delete a predefined category returns `ValidationFailure`
- Updating icon or color on a predefined category succeeds
- User message for rename/delete: "Las categorias predefinidas no se pueden modificar"

---

### BR-FIN-09: Category Deletion Requires Reassignment

**Description**: A custom category with existing transactions cannot be deleted until all its transactions are reassigned to another category. Budgets for the deleted category are also deleted (Q2:A).

**Validation Criteria**:
- `deleteCategory(id)` first checks if transactions exist for this category
- If transactions exist: return list of transaction count and prompt user for target category
- After reassignment: all transactions updated to new categoryId, all budgets for old categoryId deleted, then category deleted
- If no transactions: category and its budgets are deleted directly
- Predefined categories cannot be deleted (BR-FIN-08 takes precedence)

---

### BR-FIN-10: Category Name Length

**Description**: Category names must be 1-30 characters after trimming.

**Validation Criteria**:
- Empty name after trim → `ValidationFailure`
- Name > 30 chars → `ValidationFailure`

---

## Budget Rules

### BR-FIN-11: One Budget Per Category Per Month

**Description**: Each category can have at most one budget per (month, year) combination. Setting a budget for an existing combination updates the amount (upsert).

**Validation Criteria**:
- `setBudget(categoryId, amount, month, year)` checks if a budget exists for this triple
- If exists: update `amountCents`
- If not: insert new budget row

---

### BR-FIN-12: Budget Amount Must Be Positive

**Description**: Budget amount must be strictly greater than zero.

**Validation Criteria**:
- `amountCents <= 0` returns `ValidationFailure(field: 'amountCents')`

---

### BR-FIN-13: Budget Threshold Alerts

**Description**: After every expense transaction, budget utilization is recalculated. When utilization crosses 80% or 100%, a `BudgetThresholdEvent` is emitted.

**Validation Criteria**:
- Utilization = `sum(expenses in category for month) / budgetAmountCents`
- Crossing 80% (was < 0.8, now >= 0.8): emit `BudgetThresholdEvent(percentage: utilization)`
- Crossing 100% (was < 1.0, now >= 1.0): emit `BudgetThresholdEvent(percentage: utilization)`
- Already above threshold before the new expense: do NOT re-emit (deduplication per threshold level per month)
- Budget without expenses: utilization = 0.0

---

### BR-FIN-14: Calendar Month Period (Q4:A)

**Description**: Budget periods are always calendar months (1st to last day). No custom periods.

**Validation Criteria**:
- `month` is 1-12, `year` is valid
- Budget queries filter transactions by `date >= firstDayOfMonth AND date < firstDayOfNextMonth`

---

## Chart Rules

### BR-FIN-15: Default Chart Range (Q6:A)

**Description**: When opening the financial dashboard, the default date range is the current calendar month.

**Validation Criteria**:
- Initial `DateRange` = 1st of current month to today
- User can change via date range selector (FIN-13) to: this month, last month, custom range

---

### BR-FIN-16: Pie Chart by Category

**Description**: Pie chart shows expense distribution by category for the selected date range. Only categories with expenses > 0 are shown.

**Validation Criteria**:
- Each slice = sum of expenses in that category / total expenses
- Categories with 0 expenses are excluded
- Colors match category colors
- If no expenses in range: show empty state

---

### BR-FIN-17: Bar Chart Income vs Expenses

**Description**: Bar chart compares daily or weekly income vs expenses for the selected date range.

**Validation Criteria**:
- If range <= 31 days: daily bars
- If range > 31 days: weekly bars
- Green bars for income, red bars for expenses
- If no data for a day/week: bar height = 0

---

### BR-FIN-18: Line Chart Savings Trend

**Description**: Line chart shows cumulative net balance (income - expenses) over time for the selected range.

**Validation Criteria**:
- Y-axis = cumulative net balance starting from 0 at range start
- Each day adds (income - expenses) for that day
- Line goes up on net-positive days, down on net-negative days

---

## Savings Goal Rules

### BR-FIN-19: Manual Contributions Only (Q7:A)

**Description**: Savings goal contributions are manual. User explicitly adds an amount to a goal. Not linked to transactions.

**Validation Criteria**:
- `contributeToGoal(goalId, amountCents)` adds to `currentCents`
- `amountCents` must be positive
- `currentCents` can exceed `targetCents` (overshoot allowed)

---

### BR-FIN-20: Goal Completion

**Description**: When `currentCents >= targetCents`, the goal is marked as completed.

**Validation Criteria**:
- After each contribution, check if `currentCents >= targetCents`
- If yes: set `isCompleted = true`
- Completed goals remain visible (not hidden) but visually distinct

---

### BR-FIN-21: Goal Target Must Be Positive

**Description**: Savings goal target amount must be strictly greater than zero.

**Validation Criteria**:
- `targetCents <= 0` returns `ValidationFailure`

---

### BR-FIN-22: Goal Deadline Must Be Future

**Description**: If a deadline is set, it must be in the future at creation time.

**Validation Criteria**:
- `deadline != null && deadline <= DateTime.now()` returns `ValidationFailure`
- `deadline == null` is valid (no deadline)

---

## Recurring Transaction Rules

### BR-FIN-23: Recurring Processing

**Description**: On app launch and periodically, all active recurring transactions with `nextOccurrence <= now` are processed by creating actual transactions and advancing `nextOccurrence`.

**Validation Criteria**:
- For each active recurring where `nextOccurrence <= DateTime.now()`:
  - Create a Transaction with the template's values and `recurringId` set
  - Advance `nextOccurrence` based on `frequency`
- Frequency advancement: daily (+1 day), weekly (+7 days), biweekly (+14 days), monthly (+1 month), yearly (+1 year)
- If multiple occurrences are overdue (app was closed for days), create all missed transactions

---

### BR-FIN-24: Recurring Deactivation

**Description**: A recurring transaction can be deactivated (paused) without deletion. Deactivated templates are not processed.

**Validation Criteria**:
- `isActive = false` skips the recurring during processing
- Reactivating sets `nextOccurrence` to the next valid date from today
