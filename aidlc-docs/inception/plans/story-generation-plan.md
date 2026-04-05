# Story Generation Plan — LifeOS

## Plan Overview
This plan defines the methodology for converting LifeOS requirements (40 FRs across 6 modules + 5 transversal layers) into user stories with acceptance criteria and personas. Updated to reflect Flutter cross-platform (iOS + Android) architecture.

---

## Questions

Please answer the following questions to guide story generation.

### Question 1
How should stories be organized and broken down?

A) Feature-Based — stories organized by module (Finance stories, Gym stories, etc.), each module is an epic
B) User Journey-Based — stories follow end-to-end user workflows (e.g., "My first day using LifeOS", "My morning routine", "Payday workflow")
C) Persona-Based — stories grouped by user type (beginner, fitness enthusiast, budget-conscious user)
D) Epic-Based — large epics (Onboarding, Daily Use, Weekly Review, Setup) with sub-stories spanning modules
X) Other (please describe after [Answer]: tag below)

[Answer]: A

**Decision**: Feature-Based — cada módulo es un epic

**Rationale**: Organizar por módulo (epic de Finanzas, epic de Gym, epic de Nutrición, etc.) se alinea directamente con la arquitectura de la app y permite priorizar y desarrollar incrementalmente. Los desarrolladores pueden tomar un epic completo y entregarlo como unidad funcional. También facilita el tracking de progreso por módulo.

**Estructura de epics**:
1. Epic: Onboarding & Setup
2. Epic: Finanzas Personales (P1)
3. Epic: Gimnasio & Fitness (P2)
4. Epic: Nutrición (P2.5)
5. Epic: Hábitos & Productividad (P3)
6. Epic: Dashboard Unificado
7. Epic: Sueño + Energía (P3, Phase 2)
8. Epic: Bienestar Mental (P3.5, Phase 2)
9. Epic: Life Goals (P3, Phase 2)
10. Epic: Integraciones Cross-Módulo

---

### Question 2
What level of granularity for acceptance criteria?

A) High-level — 2-3 criteria per story focused on the "what" (e.g., "User can save a transaction")
B) Detailed — 4-6 criteria per story including happy path + error cases (e.g., "User sees error if amount is empty")
C) BDD-style — Given/When/Then format with explicit scenarios (e.g., "Given I have no transactions, When I open Finance, Then I see an empty state")
X) Other (please describe after [Answer]: tag below)

[Answer]: C

**Decision**: BDD-style — formato Given/When/Then con escenarios explícitos

**Rationale**: El formato BDD proporciona escenarios claros y sin ambigüedad que sirven directamente como base para tests automatizados (widget tests e integration tests en Flutter). Cada story tendrá escenarios que cubren happy path, edge cases, y error handling. Esto facilita la verificación de que la implementación cumple exactamente con lo esperado.

**Formato de cada criterio**:
```
Scenario: [Nombre descriptivo]
  Given [precondición]
  When [acción del usuario]
  Then [resultado esperado]
```

**Ejemplo**:
```
Scenario: Registrar gasto exitosamente
  Given estoy en la pantalla de Finanzas
  And tengo al menos una categoría creada
  When ingreso monto "50000", selecciono categoría "Comida", y toco "Guardar"
  Then la transacción aparece en la lista con monto "$50,000" y categoría "Comida"
  And el balance del mes se actualiza restando $50,000
```

---

### Question 3
How many user personas should we define?

A) 2 personas — one "beginner" (first time tracking anything) and one "experienced" (already uses fitness/finance apps)
B) 3 personas — beginner + fitness-focused + finance-focused (different entry points to the app)
C) 4+ personas — detailed archetypes covering different motivations and usage patterns
D) Let me recommend based on the requirements
X) Other (please describe after [Answer]: tag below)

[Answer]: B

**Decision**: 3 personas — principiante + fitness-focused + finance-focused

**Rationale**: Tres personas capturan los tres puntos de entrada principales a la app. El principiante valida que la experiencia de onboarding y la UX sean intuitivas. El fitness-focused valida que el módulo de Gym y Nutrición sea lo suficientemente potente para usuarios que ya usan apps como Strong o MyFitnessPal. El finance-focused valida que Finanzas sea competitivo con apps como YNAB o Fintonic. Cada persona usa la app de forma diferente y prioriza módulos distintos.

**Personas preliminares**:
1. **Camila (23, Principiante)** — Nunca ha usado apps de tracking. Quiere empezar a organizar su vida. Usa Android.
2. **Andrés (28, Fitness-focused)** — Va al gym 5x/semana, usa Strong y MyFitnessPal. Quiere consolidar todo en una app. Usa iPhone.
3. **Laura (32, Finance-focused)** — Meticulosa con sus finanzas, usa Excel para presupuestar. Quiere automatizar el tracking. Usa Android.

**Nota**: Las personas cubren ambas plataformas (iOS y Android) para validar la experiencia cross-platform.

---

### Question 4
Should stories cover only MVP (Phase 1) or all phases?

A) MVP only (Phase 1: Finance + Gym + Nutrition + Habits) — keep focused
B) MVP + Phase 2 (add Sleep, Mental, Goals) — cover the full user experience vision
C) All phases including IA, Connect, Widgets, Day Score — comprehensive but large
X) Other (please describe after [Answer]: tag below)

[Answer]: B

**Decision**: MVP + Phase 2 — cubrir la visión completa de la experiencia sin IA/widgets

**Rationale**: Cubrir MVP (Finanzas + Gym + Nutrición + Hábitos) más Phase 2 (Sueño + Mental + Goals) permite ver la visión completa de la experiencia de usuario sin entrar en features muy futuros como IA, widgets, o Day Score. Esto da suficiente contexto para diseñar la arquitectura correctamente (por ejemplo, el modelo de Goals necesita saber de todos los módulos) sin generar stories que no se implementarán en meses.

**Alcance de stories**:
- MVP (Phase 1): FR-01 a FR-25, FR-39, FR-40 → ~60-80 stories
- Phase 2: FR-26 a FR-32 → ~20-30 stories
- Total estimado: ~80-110 stories

---

### Question 5
How should cross-module interactions be handled in stories?

A) Separate "integration" epic — dedicated stories for cross-module features (e.g., "Link gym habit to workout", "Nutrition goal adjusts on training days")
B) Inline within each module — cross-module behavior described as acceptance criteria within the originating module's stories
C) Both — dedicated integration epic AND references within module stories
X) Other (please describe after [Answer]: tag below)

[Answer]: C

**Decision**: Ambos — epic de integración dedicado + referencias inline

**Rationale**: Un epic dedicado de "Integraciones Cross-Módulo" agrupa todas las stories que cruzan módulos en un solo lugar para visibilidad. Adicionalmente, las stories de cada módulo individual incluyen referencias a las integraciones como criterios de aceptación. Esto asegura que nada se pierda: el desarrollador del módulo de Gym sabe que existe una integración con Hábitos, y el epic de integraciones tiene la story completa con todos los detalles.

**Integraciones cross-módulo identificadas (preliminar)**:
1. Gym ↔ Hábitos: auto-check hábito "Ir al gym" cuando se completa un workout
2. Gym ↔ Nutrición: objetivos de macros diferentes en día de entrenamiento vs descanso
3. Finanzas ↔ Nutrición: al registrar gasto en "Comida", sugerir registrar qué comiste
4. Sueño ↔ Todos: sleep score como factor en Day Score (Phase 2)
5. Goals ↔ Todos: sub-metas vinculadas a entidades de cualquier módulo
6. Dashboard ↔ Todos: resumen de métricas clave de cada módulo activo

---

## Execution Plan

After questions are answered, the following steps will be executed:

- [x] Step 1: Answer all 5 planning questions ✅
- [x] Step 2: Define 3 user personas with full profiles ✅
- [x] Step 3: Create epic structure (10 epics) ✅
- [x] Step 4: Generate Onboarding & Setup stories (MVP) ✅ — 7 stories
- [x] Step 5: Generate Finance module stories (MVP — FR-02 to FR-08) ✅ — 14 stories
- [x] Step 6: Generate Gym module stories (MVP — FR-10 to FR-14) ✅ — 15 stories
- [x] Step 7: Generate Nutrition module stories (MVP — FR-15 to FR-20) ✅ — 11 stories
- [x] Step 8: Generate Habits module stories (MVP — FR-21 to FR-25) ✅ — 10 stories
- [x] Step 9: Generate Dashboard stories (MVP — FR-01) ✅ — 4 stories
- [x] Step 10: Generate Sleep module stories (Phase 2 — FR-26, FR-27) ✅ — 10 stories
- [x] Step 11: Generate Mental module stories (Phase 2 — FR-28 to FR-31) ✅ — 7 stories
- [x] Step 12: Generate Life Goals stories (Phase 2 — FR-32) ✅ — 7 stories
- [x] Step 13: Generate cross-module integration stories ✅ — 7 stories
- [x] Step 14: Map personas to stories (primary persona per story) ✅
- [x] Step 15: Verify INVEST criteria compliance on all stories ✅
- [x] Step 16: Final review and save artifacts ✅

## Output Artifacts
- `aidlc-docs/inception/user-stories/personas.md` — 3 detailed persona profiles
- `aidlc-docs/inception/user-stories/stories.md` — all stories organized by epic, BDD format
- `aidlc-docs/inception/user-stories/story-map.md` — visual mapping of personas to stories

## Story Format Template

```markdown
### [EPIC-ID]-[STORY-NUMBER]: [Story Title]

**As a** [persona name / role],
**I want to** [action],
**So that** [benefit].

**Priority**: MVP / Phase 2
**Epic**: [Epic Name]
**Primary Persona**: [Camila / Andrés / Laura]
**Functional Requirement**: [FR-XX]

#### Acceptance Criteria (BDD)

**Scenario 1: [Happy path name]**
- Given [precondition]
- When [action]
- Then [expected result]

**Scenario 2: [Edge case / error name]**
- Given [precondition]
- When [action]
- Then [expected result]

#### Notes
- [Implementation notes, cross-module references, platform considerations]
```

---

*Plan created: 2026-04-03*
*Updated for Flutter cross-platform and user decisions*
