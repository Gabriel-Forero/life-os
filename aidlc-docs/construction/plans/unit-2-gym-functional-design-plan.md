# Functional Design Plan — Unit 2: Gym

## Unit Context
- **Unit**: 2 — Gym
- **Stories**: GYM-01 to GYM-15 (14 MVP + 1 Phase 2)
- **Drift Tables**: 6 (exercises, routines, routine_exercises, workouts, workout_sets, body_measurements)
- **Notifier**: GymNotifier
- **DAO**: GymDao
- **Dependencies**: Unit 0 (Core Foundation)
- **EventBus**: Emits WorkoutCompletedEvent

## Functional Design Steps

- [x] **Step 1**: Define domain entities (6 Drift tables, 4 DTOs, GymState, PRRecord, WorkoutSummary, enums)
- [x] **Step 2**: Define business rules (32 rules across 6 categories)
- [x] **Step 3**: Define business logic flows (11 flows with pseudocode)
- [x] **Step 4**: Define PBT properties (4 RT, 8 INV, 4 IDP, 2 COM)

## Questions

---

### Q1: Exercise Library Source
GYM-01 mentions a library of 200+ exercises downloaded on first launch. Where does this data come from?

A) **Bundled JSON asset** — Ship a JSON file in `assets/` with the app. No network call needed. Updated with app updates.
B) **Remote API download** — Download from a remote endpoint on first launch. Requires network.
C) **Hybrid** — Bundle a base set (~50 popular exercises) in assets, download the full library on first network availability.

[Answer]: A

**Rationale**: LifeOS es una app offline-first con almacenamiento local (Drift/SQLite). Bundlear el JSON completo en assets elimina la dependencia de red en el primer launch, garantiza disponibilidad inmediata de los 200+ ejercicios, y simplifica enormemente la lógica (sin manejo de errores de red, sin estados parciales). La biblioteca se actualiza con cada release de la app, lo cual es aceptable dado que los ejercicios de gimnasio son un catálogo estable que no cambia frecuentemente. Un JSON de ~200 ejercicios pesa menos de 100KB — impacto despreciable en el tamaño del APK.

---

### Q2: Weight Unit System
GYM-07 records weight in kg. Should the app support pounds (lbs) as well?

A) **Kg only** — All weights in kilograms. Simpler data model and display.
B) **User-selectable (kg/lbs)** — User chooses unit in settings. Stored internally always as kg, displayed in user's preference.
C) **Per-exercise configurable** — Some exercises in kg, others in lbs. Maximum flexibility.

[Answer]: B

**Rationale**: Almacenar siempre en kg internamente (como int en gramos o double en kg) y convertir para display sigue el mismo patrón que Finance usa con centavos — una fuente de verdad interna con formateo en la capa de presentación. La preferencia de unidad ya puede vivir en AppSettings (Unit 0), consistente con el campo `currencyCode`. La opción C es sobre-ingeniería innecesaria — nadie mezcla kg y lbs en la misma rutina. Con B, la conversión kg↔lbs es una función pura trivial (×2.20462 / ÷2.20462), los PRs se comparan siempre en kg, y el display respeta la preferencia del usuario.

---

### Q3: Rest Timer Default Duration
GYM-08 mentions configurable rest timer. What should the default rest time be, and where is it configured?

A) **Global default 90s** — One default for all exercises. User can change during workout with +30s/-30s buttons.
B) **Per-exercise in routine** — Each exercise in a routine has its own default rest time. Falls back to 90s for empty workouts.
C) **Per-exercise-type** — Compound exercises (squat, bench) default 120s, isolation exercises default 60s.

[Answer]: B

**Rationale**: Los tiempos de descanso varían significativamente por ejercicio dentro de una misma rutina — por ejemplo, 3 minutos en sentadilla pesada pero 60 segundos en curl de bíceps. La opción B permite que el usuario configure esto una vez al armar la rutina y luego el timer se ajusta automáticamente durante el workout. El fallback a 90s para ejercicios sueltos (fuera de rutina) es un default sensato. El campo `restSeconds` iría en la tabla `routine_exercises` (la tabla pivote), lo que es limpio porque el descanso depende del contexto de la rutina, no del ejercicio en sí. La opción C suena elegante pero requiere clasificar los 200+ ejercicios como compuestos/aislamiento, lo cual es trabajo extra con beneficio marginal vs dejar que el usuario defina sus propios tiempos.

---

### Q4: PR Detection Scope
GYM-13 defines weight PR and rep PR. How granular should PR tracking be?

A) **Absolute weight PR only** — Track the heaviest weight lifted for each exercise, regardless of reps.
B) **Weight PR + Rep PR per weight** — Track max weight AND max reps at each weight (e.g., PR at 80kg = 10 reps, PR at 85kg = 6 reps).
C) **Weight PR + Volume PR** — Track max weight and max single-set volume (weight × reps).

[Answer]: C

**Rationale**: Weight PR + Volume PR captura las dos métricas que más importan para progresión: fuerza máxima (peso más pesado levantado, 1RM estimado) y rendimiento por set (peso × reps = volumen). La opción B es demasiado granular — rastrear PRs "por cada peso" genera una explosión de registros (PR a 60kg, PR a 62.5kg, PR a 65kg...) que es ruido más que señal. Con C, el usuario ve claramente: "tu PR de peso en Bench Press es 100kg" y "tu PR de volumen en un solo set es 80kg × 12 = 960kg". Volume PR también sirve como proxy para el 1RM estimado (Epley/Brzycki). Además, el volume PR motiva al usuario a subir reps O peso, no solo peso.

---

### Q5: Active Workout Persistence
If the app is killed during an active workout, what happens?

A) **Auto-save every set** — Each logged set is persisted immediately. Workout can be resumed after app restart.
B) **Periodic auto-save** — Save every 30 seconds. May lose the last few seconds of data.
C) **Only save on finish** — All data lost if app is killed before "Finish Workout".

[Answer]: A

**Rationale**: Un workout puede durar 60-90 minutos. Perder datos porque la app fue cerrada por el OS (baja memoria), una llamada telefónica, o un crash sería devastador para la experiencia del usuario. Auto-save por set es la única opción aceptable. Cada vez que el usuario registra un set, se persiste inmediatamente en Drift. Al reabrir la app, se detecta si hay un workout con status 'in_progress' y se ofrece retomarlo. Esto es consistente con la filosofía offline-first de LifeOS. El costo de una escritura SQLite por set es insignificante (~1ms), y con Drift reactivo, la UI se actualiza automáticamente. La opción B introduce un timer innecesario y la opción C es inaceptable desde UX.

---

### Q6: Bodyweight Exercise Handling
GYM-07 Scenario 3 mentions bodyweight exercises (no weight field). How should the data model handle this?

A) **Weight = 0 means bodyweight** — Store 0 in the weight field for bodyweight exercises. Display as "Peso corporal × reps".
B) **Nullable weight** — Weight field is nullable. Null = bodyweight.
C) **Weight = user's body weight** — Optionally use the latest body measurement as the weight value for volume calculations.

[Answer]: B

**Rationale**: Nullable weight es semánticamente correcto — un ejercicio de peso corporal (pull-ups, dips, push-ups) no tiene un peso externo asociado. Usar 0 (opción A) es ambiguo: ¿es bodyweight o se olvidó de ingresar el peso? Con nullable, la lógica es clara: `if (weightKg == null)` → bodyweight exercise → display "Peso corporal × reps". Para cálculo de volumen en PRs, si el usuario tiene mediciones corporales (tabla `body_measurements`), se puede opcionalmente usar el peso corporal más reciente, pero esto es una optimización de display, no de almacenamiento. En el modelo Drift, `weightKg` sería `RealColumn` nullable, lo cual Drift maneja limpiamente. La opción C mezcla responsabilidades — el peso corporal puede cambiar entre sesiones, lo cual corrompería PRs históricos.

---

### Q7: Muscle Groups Taxonomy
GYM-01 mentions filtering by muscle group. What muscle group categories should be used?

A) **Simple (8 groups)** — Pecho, Espalda, Hombros, Biceps, Triceps, Piernas, Core, Cardio.
B) **Detailed (12 groups)** — Pecho, Espalda alta, Espalda baja, Hombros, Biceps, Triceps, Cuadriceps, Isquiotibiales, Gluteos, Pantorrillas, Core, Cardio.
C) **Primary + Secondary muscles** — Each exercise has a primary muscle group and optional secondary muscles (e.g., Bench Press: primary Pecho, secondary Triceps + Hombros).

[Answer]: C

**Rationale**: Primary + Secondary es el estándar de apps de gym serias (Strong, Hevy, JEFIT). Permite: (1) filtrar por grupo muscular principal para encontrar ejercicios rápido, (2) visualizar en Unit 8 (Integration/Intelligence) qué músculos se trabajaron en la semana con un heatmap corporal, (3) detectar desbalances musculares (e.g., mucho pecho pero poca espalda). En el modelo de datos, el ejercicio tiene un campo `primaryMuscle` (string enum) y una lista `secondaryMuscles` (texto JSON o tabla relacional). Para la taxonomía de grupos, usar los 12 detallados de la opción B como vocabulario de músculos — es decir, C con el catálogo de B. Así "Bench Press" tiene primary=Pecho, secondary=[Triceps, Hombros], y "Sentadilla" tiene primary=Cuadriceps, secondary=[Gluteos, Isquiotibiales, Core]. Los 12 grupos dan la granularidad correcta para piernas (que la opción A agrupa todo en "Piernas", lo cual es inútil para análisis).

