# Unit of Work Plan — LifeOS

## Plan Overview
Decompose LifeOS (Flutter monolith) into logical development units that can be designed, built, and tested incrementally. Each unit goes through the full Construction phase (Functional Design → NFR → Code Generation).

---

## Questions

### Question 1
How should Phase 2 modules (Sleep, Mental, Goals) be grouped into units?

A) One unit per module — Unit 6: Sleep, Unit 7: Mental, Unit 8: Goals. More granular, easier to review individually
B) Single Phase 2 unit — all three in one unit. Faster, fewer review cycles, but larger single delivery
C) Two units — Unit 6: Sleep + Mental (both daily tracking), Unit 7: Goals (cross-module, depends on all others)
X) Other (please describe after [Answer]: tag below)

[Answer]: C

**Decision**: Dos units — Sleep + Mental juntos (Unit 6) y Goals separado (Unit 7).

**Rationale**:
- Sleep y Mental Wellness son ambos módulos de tracking diario de bienestar con patrones casi idénticos: registro diario, mood/quality ratings, factores contribuyentes, y visualización de tendencias. Comparten la misma cadencia de uso (una vez al día, típicamente noche/mañana) y tienen tablas Drift estructuralmente similares (entries + factors/techniques). Desarrollarlos juntos permite reutilizar patrones de UI y lógica.
- Goals es fundamentalmente diferente: es un módulo cross-module que depende de datos de Finance, Gym, Nutrition, Habits, Sleep y Mental para trackear progreso automático. Necesita que todos los demás módulos existan primero. Separarlo permite que se construya último con acceso a todos los providers ya implementados.
- Dos units de review es manejable vs tres (opción A) sin sacrificar claridad vs uno solo (opción B) que sería demasiado grande (24 stories).

**Alternatives Discarded**:
- A (uno por módulo): Tres ciclos de review para 24 stories es overhead innecesario dado que Sleep y Mental son tan similares.
- B (todo junto): 24 stories + 8 tablas + 3 módulos con lógica distinta en un solo unit dificulta el review y testing.

### Question 2
Should cross-module integrations (EventBus wiring, auto-check habits from gym, expense→meal suggestion) be a separate unit or integrated into each module's unit?

A) Separate integration unit at the end — Unit after all modules, wires everything together
B) Integrated into each module — each module implements its own event emissions and subscriptions as part of its unit
C) Hybrid — basic EventBus infrastructure in Core unit, event emissions in each module, a final integration unit for cross-module subscription wiring and testing
X) Other (please describe after [Answer]: tag below)

[Answer]: C

**Decision**: Híbrido — infraestructura EventBus en Core, emisiones en cada módulo, unit final de integración para wiring y testing end-to-end.

**Rationale**:
- La clase EventBus y los tipos de evento (sealed class AppEvent + 7 subclases) ya están diseñados como parte de Core services. Es natural que Unit 0 (Core Foundation) incluya esta infraestructura base.
- Cada módulo ya sabe qué eventos emite (ej: Gym emite WorkoutCompletedEvent al terminar un workout). Incluir la emisión en el unit del módulo es coherente — el módulo es dueño de su lógica y sus side-effects.
- Las suscripciones cross-module (ej: Habits escucha WorkoutCompletedEvent para auto-check, DayScore escucha todos los eventos para recalcular) requieren que ambos lados existan. Un unit de integración final permite: (1) wiring de todas las suscripciones, (2) testing end-to-end de los flujos cross-module, (3) DayScore + Intelligence que son inherentemente integradores.
- Esto se alinea con el provider DAG de 4 niveles ya diseñado: Level 0 (Core) → Level 1 (Features) → Level 2 (DayScore) → Level 3 (Dashboard).

**Alternatives Discarded**:
- A (unit separado para todo): Duplica trabajo — cada módulo tendría que revisitarse para agregar emisiones que ya son parte natural de su lógica.
- B (todo integrado): No permite testing end-to-end de flujos cross-module. Las suscripciones quedarían dispersas sin un punto central de validación. DayScore e Intelligence no tienen un "hogar" claro.

---

## Final Unit Structure

| Unit | Name | Modules | Drift Tables | Stories | Phase |
|---|---|---|---|---|---|
| 0 | Core Foundation | Core (DB, router, theme, services, EventBus, error handling) | 1 (AppSettings) | 7 (ONB) | MVP |
| 1 | Finance | Finance (Transactions, Categories, Budgets, Recurrings) | 5 | 14 (FIN) | MVP |
| 2 | Gym | Gym (Exercises, Routines, Workouts, Sets, Body) | 6 | 15 (GYM) | MVP |
| 3 | Nutrition | Nutrition (Foods, Meals, Templates, Macros, Water) + OpenFoodFacts | 6 | 11 (NUT) | MVP |
| 4 | Habits | Habits (Habits, Logs) | 2 | 10 (HAB) | MVP |
| 5 | Dashboard + DayScore | Dashboard, DayScore, Notifications | 4 (DayScore tables) | 4 (DASH) | MVP |
| 6 | Sleep + Mental Wellness | Sleep (entries, factors, goals) + Mental (entries, techniques) | 5 | 17 (SLP + MNT) | Phase 2 |
| 7 | Goals | Goals (goals, milestones, progress) | 3 | 7 (GOAL) | Phase 2 |
| 8 | Integration + Intelligence | Cross-module EventBus wiring, DayScore subscriptions, Intelligence (AI insights) | 3 (Intelligence tables) | 7 (INT) | Post-modules |

**Totals**: 9 units, 35 Drift tables, 92 stories

## Execution Steps

- [x] Step 1: Answer 2 decomposition questions
- [x] Step 2: Finalize unit definitions with boundaries and responsibilities
- [x] Step 3: Create dependency matrix between units (build order)
- [x] Step 4: Map all 92 stories to units
- [x] Step 5: Generate unit-of-work.md
- [x] Step 6: Generate unit-of-work-dependency.md
- [x] Step 7: Generate unit-of-work-story-map.md
- [x] Step 8: Validate all stories assigned, no orphans
