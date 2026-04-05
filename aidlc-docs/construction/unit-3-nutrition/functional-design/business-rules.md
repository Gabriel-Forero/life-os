# Business Rules — Unit 3: Nutrition

## Purpose

Defines all business rules for Unit 3 covering food item management, meal logging, macro calculations, nutrition goal setting, water tracking, meal templates, and the food search pipeline. Each rule includes an ID, description, rationale, and validation criteria.

---

## Food Item Rules

### BR-NUT-01: Custom Food Name Uniqueness

**Description**: Custom food item names (`isCustom = true`) must be unique case-insensitively within the set of custom foods. Bundled and API-cached foods are excluded from this uniqueness check.

**Rationale**: Prevents the user from creating duplicate custom entries for the same food. Bundled and API foods may legitimately share a name (e.g., different brands of "Arroz blanco").

**Validation Criteria**:
- Before inserting a custom food: query `SELECT id FROM food_items WHERE LOWER(name) = LOWER(:name) AND isCustom = true`
- If a match is found: return `ValidationFailure(field: 'name', userMessage: "Ya existe un alimento personalizado con ese nombre")`
- Renaming an existing custom food applies the same check, excluding the food's own row

---

### BR-NUT-02: Barcode Uniqueness

**Description**: If a food item has a non-null barcode, it must be unique across all rows in `food_items`. A barcode scan that matches an existing row returns the cached food instead of creating a new one.

**Rationale**: Each physical product has a unique barcode. Allowing duplicate barcode entries would produce ambiguous scan results.

**Validation Criteria**:
- Before inserting a food with a non-null `barcode`: query `SELECT id FROM food_items WHERE barcode = :barcode`
- If a match is found: return the existing row (cache hit). Do not insert a duplicate
- If no match: proceed with insert
- `barcode == null` is exempt from uniqueness checks (multiple foods may have null barcode)

---

### BR-NUT-03: Calorie Field Is Required

**Description**: `caloriesPer100g` is a required field for every food item. Macro fields (protein, carbs, fat) default to 0.0 if not provided. Calorie data is the minimum required for any meaningful tracking.

**Rationale**: A food without calorie data cannot contribute to daily summaries and would silently corrupt the user's progress view.

**Validation Criteria**:
- `caloriesPer100g` must be present and non-negative for all food types (custom, bundled, API-cached)
- `caloriesPer100g < 0` → `ValidationFailure(field: 'caloriesPer100g', userMessage: "Las calorias no pueden ser negativas")`
- API responses missing `energy-kcal_100g` are discarded and not cached (BR-NUT-09)
- `proteinPer100g`, `carbsPer100g`, `fatPer100g` default to 0.0 if absent in API response

---

### BR-NUT-04: Macro Fields Must Be Non-Negative

**Description**: All nutritional values per 100g (`proteinPer100g`, `carbsPer100g`, `fatPer100g`) must be non-negative. Serving size (`servingSizeG`) must be strictly positive.

**Validation Criteria**:
- `proteinPer100g < 0` → `ValidationFailure(field: 'proteinPer100g', userMessage: "Los macros no pueden ser negativos")`
- `carbsPer100g < 0` → `ValidationFailure(field: 'carbsPer100g', userMessage: "Los macros no pueden ser negativos")`
- `fatPer100g < 0` → `ValidationFailure(field: 'fatPer100g', userMessage: "Los macros no pueden ser negativos")`
- `servingSizeG <= 0.0` → `ValidationFailure(field: 'servingSizeG', userMessage: "El tamaño de porcion debe ser mayor a 0")`

---

### BR-NUT-05: Favorites Toggle

**Description**: Any food item (bundled, API-cached, or custom) can be marked as a favorite. Favorites appear in a dedicated section of the food picker for quick access during meal logging.

**Rationale**: The 2-tap quick log flow (BR-NUT-11) is only available for favorites. Enabling favorites on any food item makes frequently consumed foods instantly accessible.

**Validation Criteria**:
- `toggleFavorite(foodItemId)` flips `isFavorite` between `true` and `false`. No preconditions.
- Favorite status is persisted immediately via `NutritionDao.updateFoodItem()`
- Deleting a custom food that is a favorite removes it from favorites (cascade via deletion)
- Bundled and API-cached foods can be favorited but not deleted

---

### BR-NUT-06: Custom Food CRUD

**Description**: Users can create, edit, and delete custom food items (`isCustom = true`). Bundled foods (`isCustom = false, isFromApi = false`) and API-cached foods (`isFromApi = true`) are read-only from the user's perspective.

**Validation Criteria**:
- Attempting to update or delete a non-custom food returns `ValidationFailure(userMessage: "Este alimento no se puede modificar")`
- Deleting a custom food that is referenced by existing `meal_log_items` is allowed. Historical meal data is preserved; the UI displays "Alimento eliminado" for those items
- Deleting a custom food removes it from any `meal_templates` that reference it (the template's JSON is updated, or the item is silently omitted on next apply)

---

## Meal Logging Rules

### BR-NUT-07: Meal Log Requires at Least One Food Item

**Description**: A meal log (`meal_logs` row) cannot be saved without at least one associated `meal_log_items` row.

**Rationale**: A meal with no food items contains no nutritional data and has no practical purpose.

**Validation Criteria**:
- `MealLogInput.items.isEmpty` → `ValidationFailure(userMessage: "Agrega al menos un alimento")`
- The `meal_logs` row is not inserted until the items list is validated

---

### BR-NUT-08: Quantity Must Be Positive

**Description**: The quantity logged for each food item (`quantityG`) must be strictly greater than zero.

**Validation Criteria**:
- `quantityG <= 0.0` → `ValidationFailure(field: 'quantityG', userMessage: "La cantidad debe ser mayor a 0")`
- Applies to both servings-based and gram-based entry (both resolve to `quantityG` before validation)

---

### BR-NUT-09: Meal Type Auto-Suggestion (Q4:A)

**Description**: When opening the meal log form, the `mealType` field is pre-populated based on the current time of day. The user can override the suggestion.

**Time windows**:
| Time Range | Suggested MealType |
|---|---|
| 05:00–09:59 | `breakfast` |
| 11:00–13:59 | `lunch` |
| 18:00–20:59 | `dinner` |
| All other times | `snack` |

**Validation Criteria**:
- Auto-suggestion is derived from `DateTime.now()` in the Notifier when initializing the log form
- Suggestion is informational only — any `MealType` value is valid regardless of the time

---

### BR-NUT-10: Meal Note Length Limit

**Description**: The optional note on a meal log is limited to 200 characters.

**Validation Criteria**:
- `note == null` or `note.trim().isEmpty` → stored as null
- `note.length > 200` → `ValidationFailure(field: 'note', userMessage: "La nota no puede superar los 200 caracteres")`

---

### BR-NUT-11: Quick Log from Favorites (2-Tap Flow)

**Description**: For food items marked as favorites, the user can log a meal with a default quantity in two taps: tap the food item in the Favorites section, then confirm. The quantity defaults to `foodItem.servingSizeG` (one serving).

**Rationale**: Frequently eaten foods should be loggable with minimal friction.

**Validation Criteria**:
- Quick log is only available from the Favorites section of the food picker
- Default `quantityG` = `foodItem.servingSizeG` (configurable per food, default 100g)
- The user can modify the quantity before confirming (turns the 2-tap into a standard log flow)
- Quick log creates a `MealLog` with the auto-suggested `mealType` and a single `MealLogItem`

---

### BR-NUT-12: Macro Calculation Formula (Q5:B)

**Description**: All macro amounts for a logged food item are derived from the stored per-100g values and the quantity consumed.

**Formula**:
- `calories = round((quantityG / 100.0) * caloriesPer100g)` — rounded to nearest whole kcal
- `proteinG = (quantityG / 100.0) * proteinPer100g`
- `carbsG = (quantityG / 100.0) * carbsPer100g`
- `fatG = (quantityG / 100.0) * fatPer100g`

**Validation Criteria**:
- Macros are never stored. They are computed at read time from `quantityG` and the food item's per-100g values
- Calorie display values are always integers (rounded). Macro gram values retain `double` precision for summation, then displayed to one decimal place
- Servings entry: `quantityG = servings × foodItem.servingSizeG`. Computed before insert. Only `quantityG` is stored (Q5:B)

---

## Nutrition Goal Rules

### BR-NUT-13: Calorie Target Is Required When Any Macro Is Set

**Description**: If any macro goal (`proteinG`, `carbsG`, `fatG`) is greater than zero, then `caloriesKcal` must also be greater than zero. A calorie goal cannot be zero when macros are tracked.

**Rationale**: Setting macro goals without a calorie target renders the consistency warning (BR-NUT-14) meaningless and produces an inconsistent UI state where macro progress bars display but the calorie progress bar does not.

**Validation Criteria**:
- If `proteinG > 0 OR carbsG > 0 OR fatG > 0` AND `caloriesKcal == 0` → `ValidationFailure(field: 'caloriesKcal', userMessage: "Establece un objetivo calórico si defines macros")`
- `caloriesKcal` may be set independently (no macro targets required)

---

### BR-NUT-14: Macro-Calorie Consistency Warning (Q6:A)

**Description**: After a valid `NutritionGoal` is saved, the system computes the caloric equivalent of the macro targets and warns the user if the total deviates from the calorie target by more than 100 kcal.

**Formula**: `macroCalories = (proteinG * 4) + (carbsG * 4) + (fatG * 9)`

**Warning condition**: `|macroCalories - caloriesKcal| > 100`

**Warning message (example)**: "Los macros suman 2,250 kcal pero tu objetivo es 2,000 kcal. Considera ajustar los valores."

**Validation Criteria**:
- Warning is informational only — the goal is saved regardless of the discrepancy
- Warning is shown as an in-app banner or dialog immediately after saving the goal
- Warning is not shown if all macro targets are 0.0 (calorie-only tracking)
- Warning is not shown if `|macroCalories - caloriesKcal| <= 100` (within acceptable tolerance)

---

### BR-NUT-15: Zero Macros Hides Progress Bars

**Description**: If all three macro goals (`proteinG`, `carbsG`, `fatG`) in the active `NutritionGoal` are 0.0, the macro progress bars (protein, carbs, fat) are hidden from the daily summary view. Only the calorie progress bar is shown.

**Rationale**: Displaying progress bars for a 0-gram goal is meaningless and confusing.

**Validation Criteria**:
- UI condition: show macro bars only if `activeGoal != null AND (proteinG > 0 OR carbsG > 0 OR fatG > 0)`
- If `activeGoal == null`: all progress bars (including calories) are hidden. Show "Establece tus objetivos" CTA

---

### BR-NUT-16: Nutrition Goal Water Target Default

**Description**: `waterMl` in `NutritionGoal` defaults to 2,000 ml (2 L) when the user does not explicitly set it. The value must be strictly positive.

**Validation Criteria**:
- `waterMl <= 0` → `ValidationFailure(field: 'waterMl', userMessage: "El objetivo de agua debe ser mayor a 0 ml")`
- If not provided in the form, `waterMl = 2000` is applied before insert

---

## Water Tracking Rules

### BR-NUT-17: Water Amount Must Be Positive

**Description**: Each water log entry must record a positive amount of water. Zero or negative amounts are rejected.

**Validation Criteria**:
- `amountMl <= 0` → `ValidationFailure(field: 'amountMl', userMessage: "La cantidad de agua debe ser mayor a 0 ml")`
- Applies to both the default glass tap and custom amount entry

---

### BR-NUT-18: Configurable Glass Size (Q3:C)

**Description**: The default volume logged when the user taps "Agregar vaso" is determined by `AppSettings.waterGlassSizeMl`. The default setting is 250 ml. The user can change the glass size in Settings.

**Validation Criteria**:
- `AppSettings.waterGlassSizeMl` must be positive (> 0). Storing 0 or a negative value is rejected
- Tapping "Agregar vaso" calls `NutritionNotifier.logWater(amountMl: settings.waterGlassSizeMl)`
- The custom amount input accepts any positive integer (not limited to the glass size)

---

### BR-NUT-19: Daily Water Display Format (Q3:C)

**Description**: The water tracking card displays the daily total in both glasses and millilitres: "X vasos (Y ml)". The glass count is the integer floor of `totalMl / glassSizeMl`.

**Example**: 1,500 ml with glass size 250 ml → "6 vasos (1.500 ml)"

**Validation Criteria**:
- `glassCount = (dailyWaterMl / glassSizeMl).floor()` — never rounds up
- Both glasses and ml are displayed simultaneously. Removing either value is a UI defect
- If `dailyWaterMl == 0`: display "0 vasos (0 ml)"

---

### BR-NUT-20: Water Daily Goal Progress

**Description**: The water tracking card shows a progress indicator comparing the daily total to `activeGoal.waterMl` (or 2,000 ml if no goal is set). The indicator does not cap at 100% — overachievement is allowed and displayed.

**Validation Criteria**:
- `progressFraction = dailyWaterMl / waterGoalMl` (a double, may exceed 1.0)
- Visual indicator (e.g., linear progress bar) fills completely at 100% and shows a distinct color or checkmark at >= 100%
- `waterGoalMl` source: `activeGoal?.waterMl ?? 2000`

---

### BR-NUT-21: Water Reminder Smart Postpone

**Description**: The scheduled water reminder is skipped if the user has already logged water within the last 30 minutes. This prevents nagging the user when they are actively hydrating.

**Rationale**: A rigid reminder interval ignores real user behaviour. The smart postpone avoids redundant nudges.

**Validation Criteria**:
- Before showing a scheduled water reminder: query `SELECT MAX(time) FROM water_logs WHERE date = :today`
- If `DateTime.now() - lastLogTime < 30 minutes`: suppress the reminder
- If `lastLogTime == null` (no water logged today): show the reminder normally
- If `dailyWaterMl >= waterGoalMl`: suppress all remaining reminders for the day

---

## Meal Template Rules

### BR-NUT-22: Template Name Is Required

**Description**: A meal template name is required and must be between 1 and 50 characters after trimming.

**Validation Criteria**:
- `name.trim().isEmpty` → `ValidationFailure(field: 'name', userMessage: "El nombre de la plantilla es obligatorio")`
- `name.trim().length > 50` → `ValidationFailure(field: 'name', userMessage: "El nombre no puede superar los 50 caracteres")`
- Name is stored trimmed

---

### BR-NUT-23: Template Requires at Least One Food Item

**Description**: A meal template must include at least one food item. An empty template cannot be saved.

**Rationale**: A template with no foods has no utility and would create empty meal logs when applied.

**Validation Criteria**:
- The decoded `items` JSON array must have length >= 1
- Attempting to save a template with 0 items returns `ValidationFailure(userMessage: "La plantilla debe tener al menos un alimento")`

---

### BR-NUT-24: Apply Template Creates Meal Log

**Description**: Applying a meal template creates a new `MealLog` row (with the template's `mealType` and today's date) and one `MealLogItem` row per item in the template's `items` JSON. The template is not modified.

**Validation Criteria**:
- Apply is atomic: either the meal log and all its items are inserted, or none are (wrapped in a Drift transaction)
- Foods in the template that no longer exist in `food_items` are skipped. The user is informed of each skip: "Alimento no encontrado: [name]"
- If all template items are missing, the apply operation fails with `NotFoundFailure`

---

## Food Search and API Rules

### BR-NUT-25: Local-First Food Search

**Description**: Food search always queries the local `food_items` table first. If local results are fewer than 5 items and the device is online, an Open Food Facts API search is triggered in parallel. Results are merged and deduplicated by barcode (preferring the local row when both match).

**Rationale**: Local search is instant and works offline. API search supplements the local library for obscure or regional products not in the bundled dataset (Q1:C).

**Validation Criteria**:
- Step 1: Query `food_items` where `LOWER(name) LIKE LOWER('%:query%')`. Return results immediately.
- Step 2 (conditional): If `localResults.length < 5` AND network is available: call `OpenFoodFactsClient.searchByName(query)`.
- Step 3: Merge API results into local results, deduplicating by barcode. API items with a barcode matching a local row are dropped (local wins).
- Step 4: Cache new API results by inserting them into `food_items` with `isFromApi = true`.
- Offline: if network unavailable, only local results are returned. No error shown unless local results are also empty.

---

### BR-NUT-26: Search Debounce

**Description**: Food search is debounced by 400 ms. The API call is not triggered until the user has stopped typing for 400 ms. Local search may run with shorter debounce (100 ms) for immediate feedback.

**Rationale**: Prevents flooding the Open Food Facts API with every keystroke. Reduces network usage and improves perceived performance.

**Validation Criteria**:
- Local DB query: debounced 100 ms after last keystroke
- API call: debounced 400 ms after last keystroke
- In-flight API calls are cancelled when a new search term is submitted before the previous call completes

---

### BR-NUT-27: Graceful Offline Degradation (Q1:C)

**Description**: When the device is offline, all food search is served from the local `food_items` table. No error message is shown unless the local results are empty. A subtle "Sin conexion — mostrando resultados locales" indicator may be displayed.

**Validation Criteria**:
- Network unavailability is detected before making the API call (not on request failure)
- `OpenFoodFactsClient` methods return `Result.failure(NetworkFailure)` when offline. The Notifier treats this as a non-fatal degradation, not an error state
- The bundled 500-item dataset ensures meaningful local results for common Colombian/Latin foods even when fully offline

---

### BR-NUT-28: API Response Filtering

**Description**: Food items returned by the Open Food Facts API must have a non-empty `product_name` and a non-null `energy-kcal_100g` value to be accepted. Items failing either check are silently discarded and not cached.

**Rationale**: Storing foods with missing names or no calorie data would produce broken entries in the food picker and corrupt daily macro summaries.

**Validation Criteria**:
- `FoodItemDto` with `name.trim().isEmpty` → discard
- `FoodItemDto` with `caloriesPer100g == null` → discard
- All other `FoodItemDto` fields default gracefully: missing macros → 0.0, missing `servingSizeG` → 100.0, missing `brand` → null
