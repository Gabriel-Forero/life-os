# Functional Design Plan — Unit 3: Nutrition

## Unit Context
- **Unit**: 3 — Nutrition
- **Stories**: NUT-01 to NUT-11 (10 MVP + 1 Phase 2: barcode scanner)
- **Drift Tables**: 6 (food_items, meal_logs, meal_log_items, meal_templates, nutrition_goals, water_logs)
- **Notifier**: NutritionNotifier
- **DAO**: NutritionDao + NutritionRepository (wraps DAO + OpenFoodFactsClient)
- **Dependencies**: Unit 0 (Core Foundation)
- **EventBus**: Subscribes to ExpenseAddedEvent, WorkoutCompletedEvent

## Functional Design Steps

- [ ] **Step 1**: Define domain entities (6 Drift tables + DTOs + NutritionState)
- [ ] **Step 2**: Define business rules (food items, meals, macros, water, templates)
- [ ] **Step 3**: Define business logic flows (meal logging, food search, macro calculation, water tracking)
- [ ] **Step 4**: Define PBT testable properties

## Questions

---

### Q1: Open Food Facts API — MVP or Defer?
The spec mentions Open Food Facts API for food search. Given offline-first architecture, should we implement the API in MVP?

A) **Full API integration in MVP** — Search OFF API when online, cache results locally. Fallback to local cache when offline.
B) **Local-only MVP** — Ship a bundled JSON with ~500 common Colombian/Latin foods. API integration as Phase 2.
C) **Hybrid** — Bundle common foods + API search for anything else. Graceful degradation offline.

[Answer]: C

**Rationale**: El mismo patrón que Gym (JSON bundled) pero con la diferencia clave de que los alimentos son un catálogo mucho más amplio y variable — 500 alimentos locales no cubren ni el 5% de lo que un usuario puede comer. Bundlear ~500 alimentos colombianos/latinos comunes garantiza funcionalidad offline desde el día 1, y el API de Open Food Facts (gratuito, sin API key) complementa con millones de productos. Los resultados del API se cachean localmente en la tabla `food_items` con `isFromApi = true`, así se convierten en disponibles offline para búsquedas futuras. Degradación graceful: sin red → solo búsqueda local, con red → local + API. El NutritionRepository abstrae ambas fuentes detrás de una interfaz unificada.

---

### Q2: Nutritional Data Precision
How should macros (calories, protein, carbs, fat) be stored?

A) **All as `int`** — Calories as int, macros (protein/carbs/fat) as int grams. Simpler, no decimals.
B) **Calories `int`, macros `double`** — Calories whole number, macros allow decimals (e.g., protein 46.5g).
C) **All as `double`** — Maximum precision for everything.

[Answer]: B

**Rationale**: Las calorías siempre se muestran y piensan como enteros (nadie dice "comí 345.7 kcal"). Pero los macros sí necesitan decimales: Open Food Facts reporta "protein: 3.2g per 100g", y al calcular proporciones por gramos consumidos los resultados son fraccionarios. Almacenar macros como `double` preserva la precisión del API y de los cálculos proporcionales. Almacenar calorías como `int` es consistente con Finance (centavos como int) — valores discretos sin ambigüedad de redondeo. En la práctica: `caloriesKcal: IntColumn`, `proteinG: RealColumn`, `carbsG: RealColumn`, `fatG: RealColumn`. El display de macros se redondea a 1 decimal en la UI.

---

### Q3: Water Tracking Unit
NUT-08 mentions "glasses" as the unit. How should water be stored?

A) **Milliliters only** — Store in ml. Display can show glasses (1 glass = 250ml) or ml based on preference.
B) **Glass count** — Store as number of glasses. Simpler but less flexible.
C) **Configurable glass size** — Store in ml, user configures glass size (default 250ml).

[Answer]: C

**Rationale**: Almacenar en ml es la fuente de verdad correcta (unidad estándar, sin ambigüedad). Pero los usuarios piensan en "vasos" — el botón principal del UI será "+ 1 vaso" que suma el tamaño configurado (default 250ml). El tamaño de vaso configurable acomoda diferentes recipientes: un vaso pequeño (200ml), un vaso estándar (250ml), una botella (500ml). El campo `waterGlassSizeMl` iría en AppSettings (Unit 0), con default 250. Cada tap de "+ 1 vaso" inserta un `water_log` con `amountMl = glassSizeMl`. El usuario también puede ingresar ml manualmente para cantidades arbitrarias. El display muestra ambos: "6 vasos (1,500 ml)" y la barra de progreso hacia la meta diaria en ml.

---

### Q4: Meal Type Auto-Suggestion Time Ranges
NUT-05 mentions auto-suggesting meal type based on time. What are the time ranges?

A) **Fixed ranges** — Desayuno: 5:00-10:00, Almuerzo: 11:00-14:00, Cena: 18:00-21:00, Snack: everything else.
B) **User-configurable** — User sets their own time ranges in settings.
C) **Fixed with overlap** — Same as A but suggest the two closest options (e.g., at 10:30 suggest both Desayuno and Snack).

[Answer]: A

**Rationale**: Los rangos fijos son suficientes para MVP y eliminan complejidad innecesaria. Los horarios de comida en Colombia/Latinoamérica son bastante estándar: desayuno temprano, almuerzo al mediodía, cena en la noche. La opción B agrega una pantalla de configuración que casi nadie usará — es over-engineering para un auto-suggest que el usuario puede cambiar con un tap de todas formas (el meal type es un dropdown editable, no un valor bloqueado). La opción C es confusa UX — mostrar dos opciones ralentiza la acción más frecuente. Con A, el tipo se pre-selecciona automáticamente y el usuario solo lo cambia si no aplica. Los rangos son: Desayuno 5:00-10:00, Almuerzo 11:00-14:00, Cena 18:00-21:00, Snack para todo lo demás.

---

### Q5: Food Item Serving Size Handling
When logging a meal, how does the user specify the amount?

A) **Grams only** — User enters weight in grams. Macros calculated proportionally from per-100g data.
B) **Servings + grams** — Food items have a default serving size. User can enter number of servings OR grams.
C) **Multiple serving units** — Per-food custom units (e.g., "1 banana", "1 cup", "100g"). Most flexible but complex.

[Answer]: B

**Rationale**: La mayoría de los usuarios no pesan su comida — piensan en "1 porción de arroz", "2 huevos", no en "150 gramos". Con B, cada `food_item` tiene un `servingSizeG` (e.g., 1 huevo = 50g, 1 taza de arroz = 158g) y los datos nutricionales se almacenan por 100g (estándar de Open Food Facts). El usuario elige: ingresar # de porciones (se multiplica por servingSizeG) o ingresar gramos directamente. Los macros se calculan proporcionalmente: `macros = (cantidadG / 100) * macroPer100g`. Esto cubre el 95% de los casos. La opción C (unidades custom por alimento) es más flexible pero la complejidad no se justifica para MVP — requiere una tabla extra de unidades, UI de gestión, y más edge cases. Con B, el `servingSizeG` viene del JSON bundled o del API y el usuario puede editarlo.

---

### Q6: Macro Validation Warning
NUT-06 Scenario 3 mentions a warning when macros don't sum to calorie target. How strict?

A) **Informational only** — Show yellow warning, allow save regardless. Formula: protein*4 + carbs*4 + fat*9.
B) **Require acknowledgment** — Show warning dialog, user must tap "Save anyway" to proceed.
C) **Auto-calculate** — If user sets calories, auto-suggest macro split (e.g., 40/30/30 carbs/protein/fat).

[Answer]: A

**Rationale**: Las metas de macros son orientativas, no científicamente exactas — los usuarios ajustan basándose en sensación y progreso, no en precisión matemática. Forzar un acknowledgment (B) es fricción innecesaria que frustra al usuario cada vez que sus macros no cuadran exactamente (lo cual es muy frecuente). Auto-calculate (C) impone una distribución que puede no coincidir con la dieta del usuario (keto, high-protein, etc.). Con A, el warning informativo (banner amarillo: "Los macros suman ~X kcal, tu meta es Y kcal") educa sin bloquear. La fórmula estándar: `macroCalories = proteinG * 4 + carbsG * 4 + fatG * 9`. El warning se muestra si `|macroCalories - caloriesTarget| > 100kcal` (tolerancia razonable). El usuario puede guardar sus metas sin obstáculos.

