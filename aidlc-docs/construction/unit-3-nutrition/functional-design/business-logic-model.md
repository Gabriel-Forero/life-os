# Business Logic Model — Unit 3: Nutrition

## Purpose

Defines the step-by-step business logic flows for Unit 3. Each flow describes operations, decision points, error paths, and expected outcomes. Pseudocode is used for algorithmic sections. All flows execute within the `NutritionNotifier` and `NutritionDao` layers, with network calls delegated to `OpenFoodFactsClient`.

---

## 1. Food Search Flow (Local First + API + Deduplication)

The food search pipeline runs every time the user types in the food picker's search field. Local results are returned immediately; an API call supplements the results when local coverage is thin.

### Flow Steps

1. User types a query in the food picker's search field (minimum 2 characters).
2. **Debounce**: 100 ms timer starts. Resets on each new keystroke. After 100 ms with no input:
3. **Local query**: `NutritionDao.searchFoods(query)` — `SELECT * FROM food_items WHERE LOWER(name) LIKE LOWER('%query%') ORDER BY isFavorite DESC, name ASC LIMIT 30`.
4. Return local results to the UI immediately. UI renders the list.
5. **Conditional API call**:
   - 5a. If `localResults.length >= 5` OR device is offline: skip API call. Done.
   - 5b. If `localResults.length < 5` AND online: continue.
6. Wait for full 400 ms debounce from last keystroke. Cancel any in-flight API call.
7. Set `NutritionState.isSearchingApi = true`. Show loading indicator in the search bar.
8. Call `OpenFoodFactsClient.searchByName(query)`.
   - 8a. On `NetworkFailure`: set `isSearchingApi = false`. Keep local results. Show subtle "Solo resultados locales" indicator.
   - 8b. On success: receive `List<FoodItemDto>`.
9. **Filter API results** (BR-NUT-28):
   ```
   validDtos = apiDtos.where((dto) =>
     dto.name.trim().isNotEmpty &&
     dto.caloriesPer100g != null
   )
   ```
10. **Deduplicate** by barcode:
    ```
    localBarcodes = localResults.map((f) => f.barcode).whereNotNull().toSet()
    newDtos = validDtos.where((dto) =>
      dto.barcode == null || !localBarcodes.contains(dto.barcode)
    )
    ```
11. **Cache new API results**:
    ```
    for dto in newDtos:
      companion = dto.toFoodItemsCompanion(isFromApi: true, isCustom: false)
      await NutritionDao.insertOrIgnoreFoodItem(companion)
      // insertOrIgnore: if barcode already exists (race condition), skip
    ```
12. **Merge and return**:
    - `mergedResults = localResults + newDtos.map((dto) => FoodItem.fromDto(dto))`
    - Preserve local-first ordering: local results at the top, API results appended.
13. Set `isSearchingApi = false`. Update `NutritionState.searchResults = mergedResults`.

### Error Paths

- **Empty query (< 2 chars)**: Do not query. Show "Busca un alimento o escanea su codigo de barras."
- **All offline**: Return local results only. No API call attempted.
- **API timeout**: Treat as `NetworkFailure`. Local results remain visible.

### Expected Outcomes

- **Online, thin local results**: Merged list with local items first and API items appended. New API items cached for future offline use.
- **Online, rich local results**: Local results only. No API call.
- **Offline**: Local results only. No error state unless query returns 0 results.

---

## 2. Log Meal Flow (Select Foods, Quantities, Save)

The primary meal logging flow. The user selects one or more food items, sets quantities (servings or grams), reviews macros, and saves the meal.

### Flow Steps

1. User taps "Registrar comida" on the Nutrition screen.
2. `MealLogFormScreen` opens with an empty food list and the auto-suggested `mealType` (BR-NUT-09):
   ```
   now = DateTime.now()
   suggestedMealType = switch (now.hour) {
     >= 5 && < 10  => MealType.breakfast,
     >= 11 && < 14 => MealType.lunch,
     >= 18 && < 21 => MealType.dinner,
     _             => MealType.snack,
   }
   ```
3. User searches for a food and selects it (Flow 1 provides the search results).
4. **Quantity entry**:
   - 4a. User enters the number of servings: `quantityG = servings × foodItem.servingSizeG`.
   - 4b. Or user enters grams directly: `quantityG = enteredGrams`.
   - 4c. `quantityG` must be > 0.0 per BR-NUT-08.
5. **Live macro preview**: As the user adjusts the quantity, compute and display:
   ```
   calories = round((quantityG / 100.0) * foodItem.caloriesPer100g)
   proteinG = (quantityG / 100.0) * foodItem.proteinPer100g
   carbsG   = (quantityG / 100.0) * foodItem.carbsPer100g
   fatG     = (quantityG / 100.0) * foodItem.fatPer100g
   ```
6. User adds more foods (repeat steps 3-5) or proceeds to save.
7. User optionally changes the `mealType` or adds a note (maxLength: 200 per BR-NUT-10).
8. User taps "Guardar".
9. **Validate `MealLogInput`** (BR-NUT-07, BR-NUT-08, BR-NUT-10):
   - 9a. `items.length >= 1`
   - 9b. Each `item.quantityG > 0.0`
   - 9c. `note.length <= 200` (if provided)
   - If any fails: show inline error. Stay on form.
10. Call `NutritionNotifier.logMeal(input)`:
    - 10a. Insert `MealLog` row via `NutritionDao.insertMealLog()`. Obtain `mealLogId`.
    - 10b. Insert one `MealLogItem` row per item via `NutritionDao.insertMealLogItems(mealLogId, items)`.
    - 10c. Wrap both inserts in a single Drift transaction (BR-NUT-24 atomicity principle applied here too).
11. On success: navigate back to Nutrition home. `DailyMacroSummary` refreshes automatically via Drift watch stream.

### Error Paths

- **Validation failure**: Inline error on offending field. Form stays open.
- **Database failure**: `DatabaseFailure`. Snackbar "Error al guardar la comida". Retry available.

### Expected Outcomes

- **Success**: One `meal_logs` row + N `meal_log_items` rows. Daily macro summary updates.
- **Failure**: No rows inserted. User informed.

---

## 3. Quick Log from Favorites (2-Tap Flow)

A streamlined flow for logging a favorite food item with a single default-quantity confirmation.

### Flow Steps

1. User navigates to the food picker's Favorites section (foods with `isFavorite = true`, sorted by name).
2. User taps a favorite food item card. A bottom sheet appears showing:
   - Food name and brand
   - Default quantity: `foodItem.servingSizeG` grams (e.g., "100 g — 1 porcion")
   - Computed macros for the default quantity (live preview per step 5 of Flow 2)
   - The auto-suggested `mealType`
3. User reviews the preview. Two actions available:
   - "Registrar" (confirm with default quantity) → step 4
   - "Ajustar" (tap to expand full form) → transitions to full Flow 2 with the food pre-loaded
4. User taps "Registrar".
5. `NutritionNotifier.logMeal()` is called with:
   - `date = DateTime.now()` (today)
   - `mealType = autoSuggestedMealType`
   - `items = [{foodItemId: foodItem.id, quantityG: foodItem.servingSizeG}]`
6. On success: show a confirmation snackbar "Comida registrada" with an "Editar" shortcut. Return to the previous screen.

### Error Paths

- **Database failure**: `DatabaseFailure`. Snackbar. Bottom sheet stays open for retry.

### Expected Outcomes

- **Normal**: 2 taps (tap food → tap Registrar). One `meal_logs` row + one `meal_log_items` row created.
- **Modified quantity**: User taps "Ajustar" → standard Flow 2 with pre-populated food.

---

## 4. Create Custom Food Item Flow

The user creates a food item from scratch when the food is not found in the bundled library or API.

### Flow Steps

1. User taps "Crear alimento personalizado" in the food picker (appears when search returns 0 results, or via a dedicated menu).
2. `CustomFoodFormScreen` opens. Fields: name, brand (optional), calories per 100g, protein, carbs, fat, serving size.
3. User fills in at least name and calories. Saves the form.
4. **Validate `FoodItemInput`** (BR-NUT-01 through BR-NUT-04):
   - 4a. `name.trim().length` in 1-100 (BR-NUT-03 — name is required)
   - 4b. Name is unique among custom foods (case-insensitive) (BR-NUT-01)
   - 4c. `caloriesPer100g >= 0` (BR-NUT-03)
   - 4d. `proteinPer100g`, `carbsPer100g`, `fatPer100g` >= 0.0 (BR-NUT-04)
   - 4e. `servingSizeG > 0.0` (BR-NUT-04)
   - If any fails: show inline error. Stay on form.
5. Call `NutritionNotifier.createCustomFood(input)`:
   - Build `FoodItemsCompanion` with `isCustom = true`, `isFromApi = false`, `isFavorite = false`.
   - Insert via `NutritionDao.insertFoodItem()`.
6. On success: navigate back to the food picker with the new food selected and quantity pre-set to `servingSizeG`.

### Error Paths

- **Name already taken**: `ValidationFailure`. Inline error "Ya existe un alimento personalizado con ese nombre".
- **Database failure**: `DatabaseFailure`. Snackbar. Form stays open.

### Expected Outcomes

- **Success**: New row in `food_items` with `isCustom = true`. Food is immediately available in search.
- **Failure**: No row inserted. User corrects and retries.

---

## 5. Set Nutrition Goals Flow

The user sets or updates their daily nutritional targets.

### Flow Steps

1. User navigates to "Objetivos nutricionales" in Settings or the Nutrition screen.
2. `NutritionGoalsFormScreen` opens pre-filled with the current `activeGoal` (or blank if none exists).
3. User fills in calories, protein, carbs, fat (grams), and water (ml).
4. **Validate `NutritionGoalInput`** (BR-NUT-13, BR-NUT-14, BR-NUT-16):
   - 4a. `caloriesKcal > 0` (BR-NUT-13 prerequisite)
   - 4b. If any macro > 0: `caloriesKcal > 0` (BR-NUT-13)
   - 4c. All macro values >= 0.0 (BR-NUT-04)
   - 4d. `waterMl > 0` (BR-NUT-16)
   - If any fails: show inline error. Stay on form.
5. Call `NutritionNotifier.setNutritionGoal(input)`:
   - Build `NutritionGoalsCompanion` with `effectiveDate = DateTime.now()` (today).
   - Insert via `NutritionDao.insertNutritionGoal()`. A new row is always inserted (goal versioning); old rows are kept for historical queries.
6. **Macro consistency warning** (BR-NUT-14):
   ```
   macroCalories = (input.proteinG * 4) + (input.carbsG * 4) + (input.fatG * 9)
   diff = (macroCalories - input.caloriesKcal).abs()
   if diff > 100:
     show informational dialog:
       "Los macros equivalen a {macroCalories} kcal pero tu objetivo es {caloriesKcal} kcal.
        Considera ajustar los valores."
   ```
   Goal is already saved. Dialog is post-save and informational only.
7. Refresh `NutritionState.activeGoal`. Update all progress bars in the Nutrition home.

### Error Paths

- **Validation failure**: Inline error on offending field.
- **Database failure**: `DatabaseFailure`. Snackbar. Goal not saved.

### Expected Outcomes

- **Success**: New row in `nutrition_goals`. Active goal updated. Daily macro progress bars reflect new targets.
- **With warning**: Goal saved. User sees informational warning about macro-calorie mismatch. Can dismiss and optionally adjust.

---

## 6. View Daily Macro Progress Flow

The main Nutrition home screen view. Aggregates all meals logged for the selected date and compares totals to the active nutrition goal.

### Flow Steps

1. User opens the Nutrition tab (or navigates within it via a date picker).
2. `NutritionNotifier` watches `NutritionDao.watchMealLogsWithItems(date)` — a Drift `Stream` that emits on any change to `meal_logs` or `meal_log_items` for the selected date.
3. On each emission, compute `DailyMacroSummary`:
   ```
   summary = DailyMacroSummary(
     totalCalories: allItems.fold(0, (sum, item) =>
       sum + round((item.quantityG / 100.0) * (item.foodItem?.caloriesPer100g ?? 0))),
     totalProteinG: allItems.fold(0.0, (sum, item) =>
       sum + (item.quantityG / 100.0) * (item.foodItem?.proteinPer100g ?? 0.0)),
     totalCarbsG:   allItems.fold(0.0, (sum, item) =>
       sum + (item.quantityG / 100.0) * (item.foodItem?.carbsPer100g ?? 0.0)),
     totalFatG:     allItems.fold(0.0, (sum, item) =>
       sum + (item.quantityG / 100.0) * (item.foodItem?.fatPer100g ?? 0.0)),
   )
   ```
4. Resolve the active nutrition goal: `activeGoal = NutritionDao.getActiveGoalForDate(date)`.
   - `SELECT * FROM nutrition_goals WHERE effectiveDate <= :date ORDER BY effectiveDate DESC LIMIT 1`
5. **Compute progress fractions** (for progress bars):
   - `calorieFraction = summary.totalCalories / activeGoal.caloriesKcal` (clamped to display, not to value)
   - `proteinFraction = summary.totalProteinG / activeGoal.proteinG` (only if `proteinG > 0`)
   - `carbsFraction = summary.totalCarbsG / activeGoal.carbsG` (only if `carbsG > 0`)
   - `fatFraction = summary.totalFatG / activeGoal.fatG` (only if `fatG > 0`)
   - If any goal macro is 0.0: that progress bar is hidden (BR-NUT-15)
6. Display:
   - Calorie ring or bar: consumed / target
   - Macro bars: protein, carbs, fat consumed vs. target (if goals set)
   - Meal log list grouped by `mealType` (breakfast, lunch, dinner, snack), each showing constituent foods and their calories
7. Date navigation: tapping forward/back arrows changes `selectedDate`. All queries are re-run for the new date.

### Error Paths

- **No meals logged**: `DailyMacroSummary` with all zeroes. Show "No has registrado comidas hoy." placeholder.
- **No active goal**: Progress bars hidden. Show "Establece tus objetivos" CTA (BR-NUT-15).

### Expected Outcomes

- **Goal set, meals logged**: Live updating progress bars. Grouped meal list below.
- **Goal set, no meals**: Progress bars at 0%. Placeholder shown.
- **No goal**: Plain macro totals shown without progress bars.

---

## 7. Water Tracking Flow (Log Glass, Daily Total, Goal Progress)

Handles incrementing the daily water intake and displaying progress.

### Flow Steps

1. User taps "Agregar vaso" on the water tracking card.
2. Call `NutritionNotifier.logWater(amountMl: settings.waterGlassSizeMl)` (BR-NUT-18):
   - `amountMl` = `AppSettings.waterGlassSizeMl` (default 250 ml)
   - `date` = today (date portion of `DateTime.now()`)
   - `time` = `DateTime.now()` (precise timestamp for smart postpone)
3. **Validate**: `amountMl > 0` (BR-NUT-17). Always passes for glass tap (settings validation ensures glass size > 0).
4. Insert `WaterLog` row via `NutritionDao.insertWaterLog()`.
5. **Refresh daily total**: `dailyWaterMl = SUM(amountMl) WHERE date = today`.
6. **Display format** (BR-NUT-19):
   ```
   glassCount = (dailyWaterMl / glassSizeMl).floor()
   display = "{glassCount} vasos ({formatNumber(dailyWaterMl)} ml)"
   // e.g., "6 vasos (1.500 ml)"
   ```
7. **Goal progress** (BR-NUT-20):
   - `progressFraction = dailyWaterMl / waterGoalMl`
   - If `progressFraction >= 1.0`: show completion indicator (green checkmark or full bar)
8. **Custom amount entry** (alternative to "Agregar vaso"):
   - User taps "Ingresar cantidad" → text field for custom ml value.
   - Validate: `amountMl > 0`. Insert normally.
9. **Decrement/undo** (via long-press on the water card):
   - Show the most recent `WaterLog` entry. Option to delete it.
   - Delete the row → recalculate `dailyWaterMl`.

### Error Paths

- **Database failure**: `DatabaseFailure`. Snackbar. Daily total unchanged.

### Expected Outcomes

- **Normal**: Water log inserted. Daily total increments. Progress bar updates.
- **Goal reached**: Progress bar fills, completion indicator shown.
- **Undo**: Last log entry deleted. Total decrements.

---

## 8. Water Reminder Smart Postpone Flow

Determines whether a scheduled water reminder should fire or be suppressed.

### Flow Steps

1. The OS or app scheduler triggers the water reminder check at the configured interval (e.g., every 2 hours).
2. Call `NutritionNotifier.shouldShowWaterReminder()`:
   - 2a. Query `SELECT MAX(time) FROM water_logs WHERE date = :today`. Result: `lastLogTime`.
   - 2b. Query daily total: `SELECT SUM(amountMl) FROM water_logs WHERE date = :today`. Result: `dailyTotalMl`.
3. **Goal already reached**: If `dailyTotalMl >= waterGoalMl`:
   - Return `false` (suppress reminder). All reminders for the day are cancelled.
4. **Recent log check** (BR-NUT-21):
   - If `lastLogTime != null AND DateTime.now() - lastLogTime < 30 minutes`:
     - Return `false` (suppress reminder). User already hydrated recently.
5. **Show reminder**:
   - Return `true`. Display the in-app water reminder nudge.
   - Reminder message: "Recuerda tomar agua. Llevas {glassCount} vasos hoy."
6. After displaying: schedule the next check for the configured interval later.

### Decision Table

| Condition | Action |
|---|---|
| `dailyTotal >= waterGoal` | Suppress — goal achieved |
| `lastLog < 30 min ago` | Suppress — recently hydrated |
| `lastLog >= 30 min ago` OR `no logs today` | Show reminder |

### Error Paths

- **Database query failure**: Default to showing the reminder (fail open — better to remind unnecessarily than miss it).

---

## 9. Save and Apply Meal Template Flow

### Part A — Save Template

1. User taps "Guardar como plantilla" after building a meal in the meal log form (or via a dedicated Templates screen).
2. `SaveTemplateBottomSheet` opens. User enters a template name (1-50 chars).
3. The current food items and quantities from the form are serialised into the template's `items` JSON.
4. **Validate** (BR-NUT-22, BR-NUT-23):
   - `name.trim().length` in 1-50
   - `items.length >= 1`
5. Call `NutritionNotifier.saveMealTemplate(name, mealType, items)`:
   - Build `items` JSON: `[{"foodItemId": id, "quantityG": qty}, ...]`
   - Insert `MealTemplate` row via `NutritionDao.insertMealTemplate()`.
6. Show confirmation: "Plantilla '{name}' guardada."

### Part B — Apply Template

1. User navigates to the Templates section. Selects a template.
2. Template detail card shows: name, mealType, food items list, total estimated calories.
3. User taps "Aplicar".
4. **Resolve items** (BR-NUT-24):
   ```
   resolvedItems = []
   missingFoods  = []
   for entry in template.decodedItems:
     food = NutritionDao.getFoodItemById(entry.foodItemId)
     if food != null:
       resolvedItems.add(MealLogItemInput(foodItemId: food.id, quantityG: entry.quantityG))
     else:
       missingFoods.add(entry.foodItemId)
   ```
5. If `missingFoods.isNotEmpty`: show banner "1 alimento no encontrado y fue omitido."
6. If `resolvedItems.isEmpty`: return `NotFoundFailure("Todos los alimentos de la plantilla han sido eliminados")`. Do not create meal log.
7. Call `NutritionNotifier.logMeal(MealLogInput(date: today, mealType: template.mealType, items: resolvedItems))` — same as Flow 2 step 10 (atomic insert).
8. Navigate to the meal log view for today.

### Error Paths

- **Name too long or empty**: `ValidationFailure`. Inline error.
- **All items missing on apply**: `NotFoundFailure`. Show error. Template can be deleted by the user.
- **Database failure**: `DatabaseFailure`. Snackbar. No rows inserted.

---

## 10. Property-Based Testing Properties (PBT-01 Compliance)

Properties identified for property-based testing in Unit 3.

### Round-Trip Properties

| Property ID | Component | Description |
|---|---|---|
| RT-NUT-01 | Macro calculation | For any `quantityG > 0` and `macroPer100g >= 0`: `(quantityG / 100.0) * macroPer100g` computed on insert data and re-derived on read yields the same value (within `double` epsilon). |
| RT-NUT-02 | Food item persistence | `insertFoodItem(companion)` then `getFoodItemById(id)` returns all fields equal to the input companion. |
| RT-NUT-03 | Servings conversion | For any `servings > 0` and `servingSizeG > 0`: `quantityG = servings × servingSizeG`; `servings = quantityG / servingSizeG` recovers the original value within floating-point precision. |
| RT-NUT-04 | Template encode-decode | `decodedItems = jsonDecode(jsonEncode(items))` produces the same list of `{foodItemId, quantityG}` pairs. |

### Invariant Properties

| Property ID | Component | Description |
|---|---|---|
| INV-NUT-01 | Daily calorie sum non-negativity | For any set of meal log items: `DailyMacroSummary.totalCalories >= 0`. |
| INV-NUT-02 | Macro calorie formula | For any food item: `macroCalories = proteinPer100g * 4 + carbsPer100g * 4 + fatPer100g * 9`. The warning threshold check uses this formula consistently (Q6:A). |
| INV-NUT-03 | Water daily total non-negativity | `dailyWaterMl = SUM(amountMl) >= 0` for any set of water log rows. |
| INV-NUT-04 | Active goal resolution uniqueness | `getActiveGoalForDate(date)` returns at most one row (the most recent `effectiveDate <= date`). Never returns two conflicting goals for the same date. |
| INV-NUT-05 | Meal log atomicity | After a failed `logMeal()` call, the count of `meal_logs` rows is unchanged AND the count of `meal_log_items` rows is unchanged. No partial inserts. |
| INV-NUT-06 | Quantity positivity | Every `meal_log_items` row in the database has `quantityG > 0.0`. No zero or negative quantities are ever stored. |

### Idempotence Properties

| Property ID | Component | Description |
|---|---|---|
| IDP-NUT-01 | Food library seeding | Calling the bundled food seeding flow twice when `countFoodItems() == 0` for both calls produces the same final set of rows as calling it once. |
| IDP-NUT-02 | Apply template (no side effects on template) | Calling `applyTemplate(templateId)` twice on the same day creates two separate `meal_logs` rows, but the `meal_templates` row is unchanged after both calls. |
| IDP-NUT-03 | Favorites toggle idempotence | Toggling `isFavorite` off and back on returns the food to its original `isFavorite = true` state with no other field changes. |
| IDP-NUT-04 | Water smart postpone | Calling `shouldShowWaterReminder()` twice within the same second returns the same boolean without creating or deleting any rows. |

### Commutativity Properties

| Property ID | Component | Description |
|---|---|---|
| COM-NUT-01 | Daily macro summation order | `DailyMacroSummary.totalCalories` is the same regardless of the order in which `meal_log_items` are summed. (Summation is commutative over non-negative integers.) |
| COM-NUT-02 | Food search merge | The merged food search result (local + API) contains the same set of food items regardless of which subset came from local storage and which came from the API, as long as the deduplication by barcode is applied consistently. |
