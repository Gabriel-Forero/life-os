# Functional Design Plan — Unit 5: Dashboard + DayScore

## Unit Context
- **Unit**: 5 — Dashboard + DayScore
- **Stories**: DASH-01 to DASH-04 (all MVP)
- **Drift Tables**: 4 (day_scores, score_components, day_score_configs, life_snapshots)
- **Notifiers**: DayScoreNotifier, DashboardNotifier
- **Dependencies**: Units 0-4 (all complete)
- **EventBus**: Subscribes to BudgetThresholdEvent, HabitCheckedInEvent, GoalProgressUpdatedEvent

## Steps
- [ ] Step 1-4: Domain entities, business rules, logic flows, PBT properties

## Questions

---

### Q1: DayScore Calculation Formula
How should the composite 0-100 DayScore be calculated from module data?

A) **Weighted average** — Each module has a configurable weight (default equal). Score = sum(module_score × weight) / sum(weights). Missing modules excluded.
B) **Fixed formula** — Predefined formula: 25% finance + 25% gym + 25% nutrition + 25% habits. Adjusts if modules are disabled.
C) **Percentage-based** — Each module contributes a percentage of its daily goal completion. Average of all active modules.

[Answer]: A

**Rationale**: Weighted average con pesos configurables es la opción más flexible y escalable. Cada usuario prioriza áreas distintas — alguien enfocado en fitness querrá que Gym pese 40% y Finance 10%, otro al revés. Los pesos default son iguales (1.0 por módulo), lo cual produce un promedio simple si el usuario no toca nada. Los módulos deshabilitados se excluyen del denominador: `score = Σ(moduleScore × weight) / Σ(weights)` donde solo se suman módulos activos. Esto se almacena en `day_score_configs` (moduleKey → weight). La opción B es un caso particular de A (todos los pesos iguales) pero sin flexibilidad. La opción C es casi idéntica a A con pesos iguales — la diferencia semántica no justifica una fórmula separada. Cada `module_score` individual (0-100) se calcula con lógica propia dentro de cada módulo y se reporta via `score_components`.

---

### Q2: Dashboard Module Cards
The dashboard shows metric cards from active modules. How dynamic should this be?

A) **Fully dynamic** — Only show cards for enabled modules. Card order follows module priority from AppSettings.
B) **Fixed layout with empty states** — Always show all possible cards, disabled modules show "Activate this module" placeholder.
C) **User-reorderable** — User can drag-and-drop to reorder dashboard cards.

[Answer]: A

**Rationale**: Un dashboard limpio muestra solo lo relevante. Si el usuario no usa Sleep, no debería ver una card vacía ocupando espacio. El orden sigue la prioridad de módulos ya definida en AppSettings (se puede agregar un campo `modulePriority: List<String>` o usar sortOrder). Esto también escala naturalmente: al habilitar un módulo nuevo, su card aparece automáticamente. La opción B genera un dashboard lleno de placeholders que se siente incompleto en lugar de minimalista. La opción C (drag-and-drop) es deseable UX pero agrega complejidad significativa para MVP — requiere persistir el orden custom, manejar drag en un ListView, y reconciliar cuando se habilita/deshabilita un módulo. Se puede agregar reorder como mejora post-launch. Para MVP: dinámico con orden por prioridad.

---

### Q3: Life Snapshots Frequency
life_snapshots table stores periodic summaries. How often?

A) **Daily automatic** — Auto-generate a snapshot at end of day (midnight or on first app open next day).
B) **Weekly** — Auto-generate every Sunday night.
C) **Manual + weekly** — User can trigger a snapshot anytime, plus auto-weekly.

[Answer]: A

**Rationale**: El DayScore ya es diario — generar un snapshot diario automático es la extensión natural. El snapshot captura el estado consolidado del día: DayScore total, score por módulo, métricas clave (calorías, pasos, hábitos completados, etc.). Se genera al primer app open del día siguiente (lazy evaluation) o a medianoche si la app está abierta. Almacenar un snapshot diario permite: (1) gráficas de tendencia de DayScore en el tiempo, (2) comparaciones semana-a-semana, (3) detección de patrones en Unit 8. El costo de almacenamiento es mínimo (~200 bytes por snapshot). La opción B pierde granularidad diaria que es valiosa para los gráficos de tendencia. La opción C agrega un botón manual que casi nadie usará — si el snapshot es automático, no hay razón para dispararlo manualmente.

