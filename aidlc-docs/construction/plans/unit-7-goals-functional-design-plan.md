# Functional Design Plan — Unit 7: Goals

## Unit Context
- **Unit**: 7 — Goals
- **Stories**: GOAL-01 to GOAL-07 (Phase 2)
- **Drift Tables**: 3 (life_goals, sub_goals, goal_milestones)
- **Notifier**: GoalsNotifier
- **DAO**: GoalsDao
- **Dependencies**: Units 0-6 (all complete)
- **EventBus**: Emits GoalProgressUpdatedEvent; Subscribes to HabitCheckedInEvent, SleepLogSavedEvent, MoodLoggedEvent

## Steps
- [ ] Step 1-4: Domain entities, business rules, logic flows, PBT properties

## Questions

---

### Q1: Sub-Goal Module Linkage
Sub-goals can link to specific modules (Finance savings, Habits streak, etc.). How should this linkage work?

A) **Manual progress only** — Sub-goals track progress manually (0-100 slider). Module linkage is informational label only.
B) **Auto-progress from events** — Linked sub-goals auto-update progress based on EventBus events. E.g., habit-linked sub-goal = streak days / target days × 100.
C) **Hybrid** — Auto-progress when linked, manual when not linked. User can override auto-calculated progress.

[Answer]: C

**Rationale**: El valor diferenciador de LifeOS es que los módulos se conectan entre sí. Un sub-goal "Ahorrar $5M para fondo de emergencia" vinculado a Finance debe auto-actualizar su progreso cuando `SavingsGoal.currentCents` cambia — obligar al usuario a actualizar manualmente anula el propósito de tener los datos ya en la app. Pero no todos los sub-goals son vinculables ("Aprender francés" no tiene módulo), así que manual debe seguir siendo opción. Con C: `sub_goals` tiene un campo `linkedModule: TextColumn?` y `linkedEntityId: IntColumn?`. Si están populados, el progreso se calcula automáticamente desde el módulo fuente vía EventBus. Si son null, el usuario actualiza con slider 0-100. El override manual (`isOverridden: BoolColumn`) permite que el usuario corrija el auto-cálculo si no refleja su percepción real. La opción B sin override es rígida — a veces el auto-cálculo no captura el progreso real.

---

### Q2: Goal Categories
Should goals have predefined categories?

A) **Free-form** — No categories. User just names their goal.
B) **Predefined categories** — Health, Finance, Career, Personal, Education, Relationships. Used for grouping and icon suggestion.
C) **Optional tags** — User can optionally add tags from a predefined set. No mandatory categorization.

[Answer]: B

**Rationale**: Las categorías predefinidas (Salud, Finanzas, Carrera, Personal, Educación, Relaciones) mapean directamente a los módulos de LifeOS y permiten: (1) agrupar goals visualmente con iconos y colores por categoría, (2) sugerir automáticamente el `linkedModule` al crear sub-goals (si categoría = Finanzas → sugerir vincular a Finance), (3) filtrar goals por área de vida en la UI. El campo `category` sería un enum en Drift con un TextColumn converter. La opción A deja la lista de goals como un caos sin estructura. La opción C (tags) es más flexible pero introduce complejidad de UI (multi-select, tag management) sin beneficio claro sobre 6 categorías bien definidas. Si el usuario necesita más granularidad, el nombre y descripción del goal ya cubren eso. Las 6 categorías son suficientes para el 95% de los goals de vida.

---

### Q3: Goal Progress Visualization
How should goal progress be displayed over time?

A) **Simple progress bar** — Current progress percentage only. No historical trend.
B) **Progress + trend line** — Progress bar plus a line chart showing progress over time (weekly snapshots).
C) **Progress + milestones timeline** — Progress bar with milestone markers on a horizontal timeline showing past/upcoming milestones.

[Answer]: C

**Rationale**: La tabla `goal_milestones` ya existe en el diseño — tiene sentido usarla como eje visual principal. Un timeline horizontal con la barra de progreso y los milestones marcados (pasados ✓, actual ●, futuros ○) es más motivador y accionable que una simple barra o un gráfico de línea. El usuario ve dónde está, qué logró, y qué viene — eso genera momentum psicológico. Cada milestone tiene `targetDate` y `targetProgress`, así que se ubican naturalmente en un eje temporal. Los milestones completados se marcan con fecha real de completion. Para goals auto-linked (C de Q1), la línea de progreso se actualiza en tiempo real. La opción B (trend line) requiere snapshots semanales del progreso que agregan complejidad de almacenamiento y cron. La opción A es demasiado espartana para un módulo de Goals que debe inspirar. El timeline con milestones es el patrón estándar de apps de goals (Strides, Way of Life).

