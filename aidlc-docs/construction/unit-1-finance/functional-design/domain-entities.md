# Domain Entities — Unit 1: Finance

## Purpose

Defines every domain entity for Unit 1 with complete field specifications, Dart types, constraints, defaults, and descriptions. Amounts stored as `int` in cents (Q1:A) to avoid floating-point precision issues.

---

## 1. Transaction (Drift Table)

Records all income and expense entries.

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `type` | `String` | `TextColumn` | Required, enum: `'income'`, `'expense'` | None (required) | Transaction type |
| `amountCents` | `int` | `IntColumn` | Required, positive (> 0) | None (required) | Amount in cents (e.g., COP $3.500.000 → 3500000). Display divides by 100 for currencies with decimals; COP has no decimals so 1 cent = 1 peso |
| `categoryId` | `int` | `IntColumn` | Required, FK → categories.id | None (required — auto-assigned if user skips) | Category reference |
| `note` | `String?` | `TextColumn` | Optional, maxLength: 200 | `null` | User note/description |
| `date` | `DateTime` | `DateTimeColumn` | Required | `DateTime.now()` | Transaction date (user can backdate) |
| `recurringId` | `int?` | `IntColumn` | Optional, FK → recurring_transactions.id | `null` | If generated from a recurring template, links to it |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable | `DateTime.now()` | Creation timestamp |
| `updatedAt` | `DateTime` | `DateTimeColumn` | Required, updated on every write | `DateTime.now()` | Last modification timestamp |

### Transaction Notes

- **Amount storage**: All amounts stored as integer cents. For COP (no decimal subunit), $25.000 → 25000. For USD $10.50 → 1050. Display logic reads user's currency to determine divisor.
- **Default category**: Expense defaults to "Otros" (id of predefined "Otros" category). Income defaults to "General" (id of predefined "General" category) per Q5:B.
- **Soft delete**: Transactions are hard-deleted. Undo is implemented via a 5-second in-memory buffer before commit (FIN-04 Scenario 3).

---

## 2. Category (Drift Table)

User-defined and predefined spending/income categories.

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `name` | `String` | `TextColumn` | Required, unique, minLength: 1, maxLength: 30 | None (required) | Category display name |
| `icon` | `String` | `TextColumn` | Required, Material icon name | `'category'` | Icon identifier (e.g., `'restaurant'`, `'directions_car'`) |
| `color` | `int` | `IntColumn` | Required, ARGB color value | `0xFF9CA3AF` (gray) | Color as 32-bit ARGB integer |
| `type` | `String` | `TextColumn` | Required, enum: `'expense'`, `'income'`, `'both'` | `'expense'` | Whether category is for expenses, income, or both |
| `isPredefined` | `bool` | `BoolColumn` | Required | `false` | Whether this is a system predefined category (Q3:B — icon/color editable, name/delete blocked) |
| `sortOrder` | `int` | `IntColumn` | Required | `0` | Display order (predefined first, then custom) |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required | `DateTime.now()` | Creation timestamp |

### Predefined Categories (seeded on first launch)

| Name | Icon | Color | Type | Sort |
|---|---|---|---|---|
| Alimentacion | `restaurant` | `0xFF10B981` (green) | expense | 0 |
| Transporte | `directions_car` | `0xFF3B82F6` (blue) | expense | 1 |
| Entretenimiento | `movie` | `0xFF8B5CF6` (purple) | expense | 2 |
| Salud | `local_hospital` | `0xFFEF4444` (red) | expense | 3 |
| Hogar | `home` | `0xFFF59E0B` (amber) | expense | 4 |
| Educacion | `school` | `0xFF06B6D4` (cyan) | expense | 5 |
| Ropa | `checkroom` | `0xFFEC4899` (pink) | expense | 6 |
| Servicios | `receipt_long` | `0xFF6366F1` (indigo) | expense | 7 |
| Otros | `more_horiz` | `0xFF9CA3AF` (gray) | both | 8 |
| General | `account_balance` | `0xFF6366F1` (indigo) | income | 9 |
| Salario | `payments` | `0xFF10B981` (green) | income | 10 |
| Freelance | `work` | `0xFF3B82F6` (blue) | income | 11 |

### Category Notes

- **Predefined protection (Q3:B)**: `isPredefined = true` categories allow icon/color changes but block name change and deletion.
- **Deletion with reassignment (Q2:A)**: Deleting a custom category requires reassigning its transactions to another category. The budget for that category is also deleted.
- **"Otros" and "General"**: These are the default categories for unassigned expenses and income respectively (Q5:B).

---

## 3. Budget (Drift Table)

Monthly budget amounts per category. Calendar-month based (Q4:A).

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `categoryId` | `int` | `IntColumn` | Required, FK → categories.id | None (required) | Category this budget applies to |
| `amountCents` | `int` | `IntColumn` | Required, positive (> 0) | None (required) | Budget limit in cents |
| `month` | `int` | `IntColumn` | Required, range 1-12 | None (required) | Calendar month |
| `year` | `int` | `IntColumn` | Required, range 2020-2099 | None (required) | Calendar year |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required | `DateTime.now()` | Creation timestamp |
| `updatedAt` | `DateTime` | `DateTimeColumn` | Required | `DateTime.now()` | Last modification |

### Budget Notes

- **Unique constraint**: One budget per (categoryId, month, year) combination. Upsert semantics — setting a budget for an existing category/month updates the amount.
- **Utilization**: Calculated as `sum(expenses in category for month) / amountCents`. Alerts at 80% and 100% (FIN-08).
- **Calendar-month (Q4:A)**: Budget period is always 1st to last day of the month.
- **Deleted with category (Q2:A)**: When a category is deleted, its budgets are also deleted.

---

## 4. SavingsGoal (Drift Table)

Named savings targets with manual contributions (Q7:A). Phase 2.

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `name` | `String` | `TextColumn` | Required, minLength: 1, maxLength: 50 | None (required) | Goal name (e.g., "Vacaciones", "Fondo de emergencia") |
| `targetCents` | `int` | `IntColumn` | Required, positive (> 0) | None (required) | Target amount in cents |
| `currentCents` | `int` | `IntColumn` | Required, non-negative | `0` | Current accumulated amount in cents |
| `deadline` | `DateTime?` | `DateTimeColumn` | Optional | `null` | Optional target date |
| `isCompleted` | `bool` | `BoolColumn` | Required | `false` | Whether goal has been reached |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required | `DateTime.now()` | Creation timestamp |
| `updatedAt` | `DateTime` | `DateTimeColumn` | Required | `DateTime.now()` | Last modification |

### SavingsGoal Notes

- **Manual contributions (Q7:A)**: User manually adds amounts via `contributeToGoal()`. Not linked to transactions.
- **Progress**: `currentCents / targetCents` as percentage. When `currentCents >= targetCents`, `isCompleted` is set to `true`.
- **Suggested monthly**: If deadline is set, `(targetCents - currentCents) / monthsRemaining` gives suggested monthly contribution.

---

## 5. RecurringTransaction (Drift Table)

Scheduled recurring transaction templates. Phase 2.

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `type` | `String` | `TextColumn` | Required, enum: `'income'`, `'expense'` | None (required) | Transaction type |
| `amountCents` | `int` | `IntColumn` | Required, positive (> 0) | None (required) | Amount in cents |
| `categoryId` | `int` | `IntColumn` | Required, FK → categories.id | None (required) | Category reference |
| `note` | `String?` | `TextColumn` | Optional, maxLength: 200 | `null` | Note template |
| `frequency` | `String` | `TextColumn` | Required, enum: `'daily'`, `'weekly'`, `'biweekly'`, `'monthly'`, `'yearly'` | `'monthly'` | Recurrence frequency |
| `nextOccurrence` | `DateTime` | `DateTimeColumn` | Required | None (required) | Next date this transaction should be auto-created |
| `isActive` | `bool` | `BoolColumn` | Required | `true` | Whether this recurring template is active |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required | `DateTime.now()` | Creation timestamp |

---

## Input DTOs (Value Objects)

### TransactionInput

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `type` | `String` | Required, `'income'` or `'expense'` | Transaction type |
| `amountCents` | `int` | Required, positive | Amount in cents |
| `categoryId` | `int?` | Optional (defaults applied if null) | Category ID |
| `note` | `String?` | Optional, maxLength: 200 | Note |
| `date` | `DateTime?` | Optional, defaults to now | Transaction date |

### CategoryInput

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `name` | `String` | Required, 1-30 chars, unique | Category name |
| `icon` | `String` | Required | Material icon name |
| `color` | `int` | Required | ARGB color value |
| `type` | `String` | Required, `'expense'`/`'income'`/`'both'` | Category type |

### SavingsGoalInput

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `name` | `String` | Required, 1-50 chars | Goal name |
| `targetCents` | `int` | Required, positive | Target amount |
| `deadline` | `DateTime?` | Optional, must be in the future if set | Target date |

---

## FinanceState (Notifier State)

```
class FinanceState {
  List<Transaction> transactions;        // Current filtered list
  List<Category> categories;             // All categories
  List<Budget> budgets;                  // Current month's budgets
  List<SavingsGoal> savingsGoals;        // All active goals
  MonthSummary monthSummary;             // Computed aggregates
  DateRange currentRange;                // Active filter range
}

class MonthSummary {
  int totalIncomeCents;                  // Sum of income for range
  int totalExpensesCents;                // Sum of expenses for range
  int netBalanceCents;                   // Income - expenses
  Map<int, BudgetUtilization> budgetUtilizations; // categoryId → utilization
}

class BudgetUtilization {
  int budgetCents;                       // Budget limit
  int spentCents;                        // Actual spent
  double percentage;                     // spentCents / budgetCents
  bool alert80;                          // >= 0.8
  bool alert100;                         // >= 1.0
}

class DateRange {
  DateTime from;
  DateTime to;
}
```

---

## Entity Relationship Summary

```
Category (1) ──< Transaction (many)
  |                     |
  |                     └── recurringId? ──> RecurringTransaction (optional)
  |
  └──< Budget (many, per month/year)

SavingsGoal (standalone, manual contributions)
```
