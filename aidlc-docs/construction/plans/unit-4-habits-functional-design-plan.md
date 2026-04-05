# Functional Design Plan — Unit 4: Habits

## Unit Context
- **Unit**: 4 — Habits
- **Stories**: HAB-01 to HAB-10 (all MVP)
- **Drift Tables**: 2 (habits, habit_logs)
- **Notifier**: HabitsNotifier
- **DAO**: HabitsDao
- **Dependencies**: Unit 0 (Core Foundation)
- **EventBus**: Emits HabitCheckedInEvent; Subscribes to WorkoutCompletedEvent
- **Complexity**: Medium (streak algorithm, calendar view, quantitative tracking)

## Functional Design Steps

- [ ] **Step 1**: Define domain entities (2 Drift tables + DTOs + HabitsState)
- [ ] **Step 2**: Define business rules (habits, check-ins, streaks, reminders)
- [ ] **Step 3**: Define business logic flows (check-in, streak calculation, calendar, auto-check)
- [ ] **Step 4**: Define PBT testable properties

## Questions

---

### Q1: Streak Calculation for Custom Frequency
HAB-06 defines streaks for daily and weekly habits. How should streaks work for custom-day habits (e.g., Mon/Wed/Fri)?

A) **Only count applicable days** — Streak counts consecutive applicable days completed. Missing Tuesday doesn't break a Mon/Wed/Fri streak.
B) **Ignore custom days for streak** — Only daily habits have meaningful streaks. Weekly/custom habits show completion count instead.
C) **Flexible streak** — For custom-day habits, streak = consecutive applicable days completed. For weekly, streak = consecutive weeks meeting the target.

[Answer]: C

**Rationale**: C es el superset de A y agrega la semántica correcta para weekly. Para custom-day (Lun/Mie/Vie), el streak solo evalúa los días aplicables — si el hábito es Lun/Mie/Vie y el usuario completa Lun y Mie, el martes y jueves no rompen la racha. Para weekly (e.g., "ir al gym 3 veces por semana"), el streak cuenta semanas consecutivas en las que se alcanzó el target. Para daily, streak = días consecutivos completados. Esto da tres algoritmos de streak según `frequency`: daily (cada día), weekly (cada semana calendario), custom (solo días marcados). El campo `frequency` en la tabla `habits` determina cuál algoritmo usar. La opción B descarta valor real — los streaks son el principal motivador psicológico para cualquier frecuencia.

---

### Q2: Quantitative Habit Completion Threshold
HAB-05 mentions partial progress (6000/10000 steps). When is a quantitative habit "completed" for streak purposes?

A) **Must meet or exceed target** — Only values >= target count as completed. Partial progress is tracked but doesn't count for streaks.
B) **Any positive value counts** — Any check-in > 0 counts as completed for streak, even if below target.
C) **Configurable threshold** — User sets a minimum % (default 100%) that counts as completed.

[Answer]: A

**Rationale**: Si el target es 10,000 pasos y el usuario camina 2,000, no debería contar como "completado" — eso desvirtúa el propósito del target y hace que los streaks pierdan significado. El progreso parcial (6,000/10,000) se muestra visualmente (barra de progreso, porcentaje) para motivar, pero el streak solo incrementa cuando `value >= target`. Para hábitos booleanos (check/no-check), cualquier check-in es completion. La opción C agrega complejidad de configuración por hábito sin beneficio claro — si el usuario quiere un umbral menor, simplemente baja el target. Mantener la semántica simple: target es target, streak requiere completarlo.

---

### Q3: Habit Deletion vs Archive
HAB-09/10 mention both delete and deactivate. What happens to historical data?

A) **Soft-delete only** — "Delete" actually archives. All history preserved. User can restore.
B) **Hard delete with warning** — Show warning with streak/log count. If confirmed, delete habit AND all logs permanently.
C) **Archive by default, hard-delete option** — "Deactivate" archives. A separate "Delete permanently" option (hidden in settings) does hard delete.

[Answer]: A

**Rationale**: Los datos de hábitos son valiosos a largo plazo — un usuario que dejó de meditar 6 meses y quiere retomar quiere ver su historial previo. Soft-delete con un campo `isArchived: BoolColumn` (default false) es simple de implementar y reversible. Los hábitos archivados no aparecen en la vista principal ni en los recordatorios, pero se pueden restaurar desde una sección "Archivados". Los `habit_logs` se preservan siempre. Esto es consistente con la filosofía de LifeOS de no perder datos históricos (mismo patrón que Finance donde workouts se preservan al borrar rutinas). Hard-delete permanente no es necesario para MVP — el almacenamiento de habit_logs es mínimo (unos pocos bytes por registro).

---

### Q4: Auto-Check from WorkoutCompletedEvent
HAB description mentions auto-checking gym-related habits when a workout is completed. How should this work?

A) **Tag-based matching** — Habits can optionally be tagged as "gym-linked". When WorkoutCompletedEvent fires, all gym-linked habits auto-check.
B) **Name-based matching** — If habit name contains "gym", "ejercicio", "workout", auto-check on workout event.
C) **Manual only** — No auto-check. The EventBus subscription is deferred to Integration unit (Unit 8).

[Answer]: A

**Rationale**: Tag-based es explícito, predecible, y no depende de heurísticas frágiles como matching por nombre (opción B: ¿qué pasa si el hábito se llama "Ejercitar mente"? falso positivo). Un campo `linkedEvent: TextColumn?` en la tabla `habits` permite asociar un hábito a un tipo de evento del EventBus (e.g., `'WorkoutCompletedEvent'`). Cuando el evento se emite, `HabitsNotifier` busca todos los hábitos con `linkedEvent = eventType` y `isArchived = false`, y auto-completa el check-in del día si no existe ya. La UI muestra un toggle "Completar automáticamente al terminar un entrenamiento" al crear/editar un hábito. Diferir a Unit 8 (opción C) pierde la oportunidad de usar el EventBus que ya está implementado en Unit 0 — el costo de implementación es mínimo aquí.

