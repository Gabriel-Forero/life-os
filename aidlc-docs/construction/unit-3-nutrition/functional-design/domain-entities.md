# Domain Entities — Unit 3: Nutrition

## Purpose

Defines every domain entity for Unit 3 with complete field specifications, Dart types, constraints, defaults, and descriptions. These definitions drive Drift table generation, input DTOs, value objects, and API response mappings used by the Nutrition module across the entire LifeOS application. Calories are stored as `int` (whole kcal, Q2:B). Macros (protein, carbs, fat) are stored as `double` (`RealColumn`). All nutritional values are stored per 100g (Q2:B). Water volume is stored in millilitres as `int` (Q3:C).

---

## 1. MealType Enum

The four fixed meal types used by `meal_logs` and `meal_templates`. Auto-suggestion is time-based (Q4:A).

| Enum Value | Spanish Label | Auto-Suggest Time Window |
|---|---|---|
| `breakfast` | Desayuno | 05:00–09:59 |
| `lunch` | Almuerzo | 11:00–13:59 |
| `dinner` | Cena | 18:00–20:59 |
| `snack` | Snack | All other times |

### Dart Enum Definition

```
enum MealType {
  breakfast, lunch, dinner, snack
}
```

Stored in Drift as a `TextColumn` using a `TypeConverter<MealType, String>` that maps the enum name to its string value. Unknown values during deserialization fall back to `MealType.snack` (safe default, logged as warning).

---

## 2. FoodItems (Drift Table)

The food item library. Contains bundled Colombian/Latin foods (loaded from `assets/foods.json` on first launch), user-created custom foods, and items fetched from the Open Food Facts API and cached locally (Q1:C).

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `barcode` | `String?` | `TextColumn` | Optional, unique when non-null (enforced at app layer) | `null` | EAN/UPC barcode from product packaging or API. Null for foods without a barcode |
| `name` | `String` | `TextColumn` | Required, minLength: 1, maxLength: 100, trimmed; unique among custom foods (case-insensitive) | None (required) | Food display name (e.g., "Arroz blanco cocido", "Arepas de maiz") |
| `brand` | `String?` | `TextColumn` | Optional, maxLength: 100 | `null` | Brand or manufacturer name. Null for generic foods |
| `caloriesPer100g` | `int` | `IntColumn` | Required, non-negative | None (required) | Energy value in kcal per 100g of food |
| `proteinPer100g` | `double` | `RealColumn` | Required, non-negative | None (required) | Protein content in grams per 100g |
| `carbsPer100g` | `double` | `RealColumn` | Required, non-negative | None (required) | Carbohydrate content in grams per 100g |
| `fatPer100g` | `double` | `RealColumn` | Required, non-negative | None (required) | Fat content in grams per 100g |
| `servingSizeG` | `double` | `RealColumn` | Required, positive (> 0) | `100.0` | Reference serving size in grams. Used to compute macros for one serving (Q5:B) |
| `isFavorite` | `bool` | `BoolColumn` | Required | `false` | Whether the user has starred this food for quick access |
| `isCustom` | `bool` | `BoolColumn` | Required | `false` | `true` for user-created foods. Custom foods are freely editable and deletable |
| `isFromApi` | `bool` | `BoolColumn` | Required | `false` | `true` if this food was fetched from Open Food Facts and cached locally (Q1:C) |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp of record creation |

### FoodItems Notes

- **Bundled foods**: Approximately 500 common Colombian/Latin foods loaded from `assets/foods.json` on first launch. `isCustom = false`, `isFromApi = false`.
- **API cache (Q1:C)**: Foods retrieved from Open Food Facts are inserted with `isFromApi = true`. Subsequent searches check the local table before making a network call.
- **Barcode uniqueness**: Enforced at the application layer. A barcode scan that matches an existing row returns the cached food instead of inserting a duplicate. The Drift schema does not enforce a unique index on `barcode` because null values would violate a standard unique constraint.
- **Name uniqueness**: For custom foods (`isCustom = true`), names must be unique case-insensitively within the set of custom foods. Bundled and API-cached foods may share a name (different brand variants of the same product).
- **Macro storage**: All values are per 100g. Actual macro amounts for a logged quantity are computed at read time: `macroForQuantity = (quantityG / 100.0) * macroPer100g` (Q5:B).

---

## 3. MealLogs (Drift Table)

Records each meal session. A meal log groups one or more food items under a meal type and date.

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `date` | `DateTime` | `DateTimeColumn` | Required, date portion used for daily queries | `DateTime.now()` date part | The calendar date of the meal |
| `mealType` | `MealType` | `TextColumn` | Required, stored via TypeConverter | Auto-suggested from time of day (Q4:A) | Breakfast, lunch, dinner, or snack |
| `note` | `String?` | `TextColumn` | Optional, maxLength: 200 | `null` | User note about the meal (e.g., "Cena en restaurante") |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp when the meal log was created |
| `updatedAt` | `DateTime` | `DateTimeColumn` | Required, updated on every write | `DateTime.now()` at insert and update | Timestamp of last modification |

### MealLogs Notes

- **Date vs. timestamp**: `date` stores the calendar date (midnight-normalized). `createdAt` stores the precise creation timestamp. Daily macro queries filter by `date`, not `createdAt`.
- **Meal type suggestion**: When creating a new meal log, `mealType` is pre-populated based on `DateTime.now()` using the time windows defined in the `MealType` enum (Q4:A). The user can override the suggestion.
- **Cascade delete**: Deleting a meal log cascades to all of its `meal_log_items` rows.

---

## 4. MealLogItems (Drift Table)

Each food item within a meal log. Stores the quantity consumed and links to the food item for nutritional data.

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `mealLogId` | `int` | `IntColumn` | Required, FK → meal_logs.id (CASCADE DELETE) | None (required) | The owning meal log |
| `foodItemId` | `int` | `IntColumn` | Required, FK → food_items.id | None (required) | The food item consumed |
| `quantityG` | `double` | `RealColumn` | Required, positive (> 0) | None (required) | Quantity consumed in grams. Computed from servings: `quantityG = servings * foodItem.servingSizeG` (Q5:B) |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp of row creation |

### MealLogItems Notes

- **Quantity model (Q5:B)**: The UI allows the user to enter either a number of servings or a gram amount. When servings are entered: `quantityG = servings × foodItem.servingSizeG`. When grams are entered: `quantityG` is set directly. Only `quantityG` is stored.
- **Macro calculation**: All macros for a meal log item are derived at read time: `calories = round((quantityG / 100.0) * foodItem.caloriesPer100g)`, `proteinG = (quantityG / 100.0) * foodItem.proteinPer100g`, etc.
- **Dangling FK behaviour**: If a `food_items` row is deleted, `meal_log_items` rows referencing it retain the `foodItemId` but the food data is unavailable. The UI displays "Alimento eliminado" in this edge case. This is acceptable because custom food deletion is rare and historical records should be preserved.

---

## 5. MealTemplates (Drift Table)

Reusable meal templates that the user can save and apply to quickly log a common meal (e.g., "Desayuno habitual").

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `name` | `String` | `TextColumn` | Required, minLength: 1, maxLength: 50, trimmed | None (required) | Template display name (e.g., "Desayuno proteico", "Almuerzo standard") |
| `mealType` | `MealType` | `TextColumn` | Required, stored via TypeConverter | None (required) | Default meal type applied when this template is used |
| `items` | `String` | `TextColumn` | Required, JSON-encoded list | None (required) | JSON array of `{foodItemId: int, quantityG: double}` objects |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp of template creation |

### MealTemplates Notes

- **items JSON format**: Stored as a JSON string, e.g., `'[{"foodItemId":1,"quantityG":100.0},{"foodItemId":5,"quantityG":30.0}]'`. Decoded via a Dart extension method or `TypeConverter`. Minimum one item per template (BR-NUT-23).
- **Apply template**: Applying a template creates a new `MealLog` row with the template's `mealType` and inserts one `MealLogItem` row per entry in `items`. The template itself is not modified.
- **Missing foods on apply**: If a `foodItemId` in the template's JSON no longer exists in `food_items`, that item is skipped and the user is notified ("1 alimento no encontrado y fue omitido").

---

## 6. NutritionGoals (Drift Table)

Daily nutritional targets set by the user. Supports a history of goals (one per effective date). The most recent row where `effectiveDate <= today` is the active goal.

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `caloriesKcal` | `int` | `IntColumn` | Required, positive (> 0) | None (required) | Daily calorie target in kcal |
| `proteinG` | `double` | `RealColumn` | Required, non-negative | None (required) | Daily protein target in grams |
| `carbsG` | `double` | `RealColumn` | Required, non-negative | None (required) | Daily carbohydrate target in grams |
| `fatG` | `double` | `RealColumn` | Required, non-negative | None (required) | Daily fat target in grams |
| `waterMl` | `int` | `IntColumn` | Required, positive (> 0) | `2000` | Daily water intake target in millilitres (default 2,000 ml = 2 L) |
| `effectiveDate` | `DateTime` | `DateTimeColumn` | Required, date portion only | `DateTime.now()` date part | The date from which this goal applies |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp of row creation |

### NutritionGoals Notes

- **Active goal resolution**: `SELECT * FROM nutrition_goals WHERE effectiveDate <= :today ORDER BY effectiveDate DESC LIMIT 1`. If no row exists, the user has not set goals yet and progress bars are hidden.
- **Macro consistency warning (Q6:A)**: After saving a goal, the system computes `macroCalories = proteinG * 4 + carbsG * 4 + fatG * 9`. If `|macroCalories - caloriesKcal| > 100`, an informational warning is displayed ("Las calorias de los macros no coinciden con el objetivo calórico"). This is not a validation failure — the goal is saved regardless.
- **Zero macros**: If all three macro goals (`proteinG`, `carbsG`, `fatG`) are 0.0, macro progress bars are hidden. Only calorie progress is shown.

---

## 7. WaterLogs (Drift Table)

Records each water intake event. Multiple logs per day are expected (one per glass or bottle consumed).

| Field | Dart Type | Drift Column Type | Constraints | Default | Description |
|---|---|---|---|---|---|
| `id` | `int` | `IntColumn` | Primary key, autoIncrement | Auto | Row identifier |
| `date` | `DateTime` | `DateTimeColumn` | Required, date portion used for daily totals | `DateTime.now()` date part | The calendar date of the water intake |
| `amountMl` | `int` | `IntColumn` | Required, positive (> 0) | None (required) | Volume consumed in millilitres (Q3:C) |
| `time` | `DateTime` | `DateTimeColumn` | Required | `DateTime.now()` | Precise timestamp of when the water was logged. Used for smart reminder postpone logic |
| `createdAt` | `DateTime` | `DateTimeColumn` | Required, immutable after creation | `DateTime.now()` at insert | Timestamp of row creation |

### WaterLogs Notes

- **Glass size (Q3:C)**: The default glass size is 250 ml. This is stored in `AppSettings.waterGlassSizeMl` (default: 250). Tapping "Agregar vaso" logs `amountMl = AppSettings.waterGlassSizeMl`. Custom amounts are also supported.
- **Daily total**: Computed by summing `amountMl` for all rows where `date = today`: `SELECT SUM(amountMl) FROM water_logs WHERE date = :today`.
- **Display format (Q3:C)**: "6 vasos (1.500 ml)" — number of glasses = `totalMl / glassSizeMl` (floor division for display). Always shows both glasses and ml.
- **Smart reminder**: The `time` field enables the smart postpone rule: if the most recent water log's `time` was within the last 30 minutes, skip the scheduled reminder.

---

## Input DTOs (Value Objects)

### MealLogInput

Carries data from the UI to `NutritionNotifier.logMeal()`.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `date` | `DateTime` | Required, date portion only | The day this meal is logged for |
| `mealType` | `MealType` | Required | Meal type (may be pre-suggested, user can override) |
| `note` | `String?` | Optional, maxLength: 200 | Optional meal note |
| `items` | `List<MealLogItemInput>` | Required, length >= 1 | Foods and quantities to log |

### MealLogItemInput

Nested within `MealLogInput`. Defines a single food entry.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `foodItemId` | `int` | Required, must exist in food_items | The food to log |
| `quantityG` | `double` | Required, > 0.0 | Quantity in grams |

### NutritionGoalInput

Carries data from the UI to `NutritionNotifier.setNutritionGoal()`.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `caloriesKcal` | `int` | Required, > 0 | Daily calorie target |
| `proteinG` | `double` | Required, >= 0.0 | Daily protein target |
| `carbsG` | `double` | Required, >= 0.0 | Daily carbs target |
| `fatG` | `double` | Required, >= 0.0 | Daily fat target |
| `waterMl` | `int` | Required, > 0 | Daily water target |
| `effectiveDate` | `DateTime` | Required | Date from which goal applies (defaults to today) |

### FoodItemInput

Carries data for creating a custom food item.

| Field | Dart Type | Constraints | Description |
|---|---|---|---|
| `name` | `String` | Required, 1-100 chars after trim, unique among custom foods (case-insensitive) | Food name |
| `brand` | `String?` | Optional, maxLength: 100 | Brand name |
| `caloriesPer100g` | `int` | Required, >= 0 | Calories per 100g |
| `proteinPer100g` | `double` | Required, >= 0.0 | Protein per 100g |
| `carbsPer100g` | `double` | Required, >= 0.0 | Carbs per 100g |
| `fatPer100g` | `double` | Required, >= 0.0 | Fat per 100g |
| `servingSizeG` | `double` | Required, > 0.0, defaults 100.0 | Serving size in grams |

---

## NutritionState (Notifier State Value Object)

The state exposed by `NutritionNotifier` to the UI layer via Riverpod's `AsyncNotifier`.

```
class NutritionState {
  // Daily summary (recalculated on every meal log mutation)
  DateTime selectedDate;                  // Date being viewed (defaults to today)
  DailyMacroSummary dailySummary;         // Aggregated macros for selectedDate
  List<MealLogWithItems> mealLogs;        // All meal logs for selectedDate, with items

  // Nutrition goals
  NutritionGoal? activeGoal;             // Most recent goal for selectedDate (null if unset)

  // Water tracking
  int dailyWaterMl;                       // Total ml logged for selectedDate
  int waterGoalMl;                        // From activeGoal.waterMl (or 2000 default)
  List<WaterLog> waterLogs;              // All water log entries for selectedDate

  // Search state (for food picker)
  List<FoodItem> searchResults;           // Current food search results (merged local + API)
  bool isSearchingApi;                    // True while an API call is in flight
}
```

---

## DailyMacroSummary (Value Object)

Computed from all `meal_log_items` for a given day.

```
class DailyMacroSummary {
  int totalCalories;          // Sum of round((quantityG / 100) * caloriesPer100g) per item
  double totalProteinG;       // Sum of (quantityG / 100) * proteinPer100g
  double totalCarbsG;         // Sum of (quantityG / 100) * carbsPer100g
  double totalFatG;           // Sum of (quantityG / 100) * fatPer100g
}
```

---

## MealLogWithItems (Join Result Value Object)

Returned by `NutritionDao.watchMealLogsWithItems(date)`. Combines `meal_logs` and its child `meal_log_items`, each joined with their `food_items` row.

| Field | Dart Type | Source | Description |
|---|---|---|---|
| `mealLog` | `MealLog` | meal_logs row | The meal log header (date, mealType, note) |
| `items` | `List<MealLogItemWithFood>` | meal_log_items + food_items | All items in this meal, with food data joined |

### MealLogItemWithFood

| Field | Dart Type | Source | Description |
|---|---|---|---|
| `mealLogItem` | `MealLogItem` | meal_log_items row | The quantity and FK references |
| `foodItem` | `FoodItem?` | food_items row | The food data. Nullable in case food was deleted |

Convenience getters on `MealLogItemWithFood`:
- `calories` → `round((mealLogItem.quantityG / 100.0) * (foodItem?.caloriesPer100g ?? 0))`
- `proteinG` → `(mealLogItem.quantityG / 100.0) * (foodItem?.proteinPer100g ?? 0.0)`
- `carbsG` → `(mealLogItem.quantityG / 100.0) * (foodItem?.carbsPer100g ?? 0.0)`
- `fatG` → `(mealLogItem.quantityG / 100.0) * (foodItem?.fatPer100g ?? 0.0)`

---

## FoodItemDto (API Response Mapping)

Intermediate DTO produced by `OpenFoodFactsClient.searchByName()` and `OpenFoodFactsClient.lookupByBarcode()`. Converted to `FoodItemsCompanion` before database insert.

| Field | Dart Type | Source Field (Open Food Facts) | Description |
|---|---|---|---|
| `barcode` | `String?` | `code` | Product barcode |
| `name` | `String` | `product_name` or `product_name_es` | Product name |
| `brand` | `String?` | `brands` | Brand name |
| `caloriesPer100g` | `int` | `nutriments.energy-kcal_100g` (rounded) | Calories per 100g |
| `proteinPer100g` | `double` | `nutriments.proteins_100g` | Protein per 100g |
| `carbsPer100g` | `double` | `nutriments.carbohydrates_100g` | Carbs per 100g |
| `fatPer100g` | `double` | `nutriments.fat_100g` | Fat per 100g |
| `servingSizeG` | `double` | `serving_quantity` (default 100.0 if absent) | Serving size in grams |

API responses with missing `product_name` or null `energy-kcal_100g` are discarded and not cached.

---

## AppSettings Extension (New Fields for Unit 3)

Two new fields are added to the existing `AppSettings` Drift table as part of Unit 3.

| Field | Dart Type | Drift Column Type | Default | Description |
|---|---|---|---|---|
| `waterGlassSizeMl` | `int` | `IntColumn` | `250` | User's configured glass size in ml (Q3:C). Used as the default volume per "Agregar vaso" tap |

---

## Entity Relationship Summary

```
FoodItem (many rows)
  |-- isCustom (user-created, fully editable)
  |-- isFromApi (cached from Open Food Facts)
  |-- isFavorite (quick access toggle)
  |
  └──< MealLogItem (many)
        |-- quantityG: stored in grams
        |-- macros: computed at read time from (quantityG / 100) * macroPer100g
        |
        └── MealLog (1 per group)
              |-- date, mealType, note
              └── (cascade delete → MealLogItem rows)

MealTemplate (many rows)
  |-- items: JSON [{foodItemId, quantityG}]
  └── applyTemplate() creates a new MealLog + MealLogItems

NutritionGoal (many rows — versioned by effectiveDate)
  |-- active goal = most recent where effectiveDate <= today
  └── waterMl: daily water target

WaterLog (many rows)
  |-- date: for daily totals
  |-- time: for smart reminder postpone (BR-NUT-24)
  └── amountMl: volume in ml

AppSettings (1 row)
  └── waterGlassSizeMl: int (default 250)

EventBus subscriptions in NutritionNotifier:
  |-- ExpenseAddedEvent  → (reserved for future cross-module features)
  └── WorkoutCompletedEvent → (reserved for future calorie adjustment features)
```
