# Functional Design Plan — Unit 6: Sleep + Mental Wellness

## Unit Context
- **Unit**: 6 — Sleep + Mental Wellness
- **Stories**: SLP-01 to SLP-09 + MNT-01 to MNT-08 (17 total, Phase 2)
- **Drift Tables**: 5 (sleep_logs, sleep_interruptions, energy_logs, mood_logs, breathing_sessions)
- **Notifiers**: SleepNotifier, MentalNotifier
- **Dependencies**: Unit 0 (Core Foundation)
- **EventBus**: Emits SleepLogSavedEvent, MoodLoggedEvent

## Steps
- [ ] Step 1-4: Domain entities, business rules, logic flows, PBT properties

## Questions

---

### Q1: Sleep Score Formula
How should the 0-100 sleep score be calculated?

A) **Simple weighted** — Duration weight 40% + Quality rating weight 40% + Interruptions penalty 20%. Duration score: hours/8 × 100 (capped at 100). Quality: rating/5 × 100. Interruptions: max(0, 100 - interruptions × 15).
B) **Research-based** — Use sleep efficiency (time asleep / time in bed × 100) as primary metric, with quality and interruption adjustments.
C) **Custom weights** — User configures which factors matter most.

[Answer]: A

**Rationale**: La fórmula simple weighted es transparente, predecible, y fácil de explicar al usuario ("tu score de sueño se basa en duración, calidad y despertares"). Los datos de entrada son los que el usuario ingresa manualmente: horas dormidas, rating subjetivo 1-5, y número de interrupciones — no requiere hardware. La fórmula: `sleepScore = durationScore × 0.4 + qualityScore × 0.4 + interruptionScore × 0.2`, donde `durationScore = min(100, (hours / 8) × 100)`, `qualityScore = (rating / 5) × 100`, `interruptionScore = max(0, 100 - interruptions × 15)`. La opción B requiere "time in bed" vs "time asleep" que es difícil de rastrear manualmente sin wearable. La opción C es over-engineering — los pesos 40/40/20 están respaldados por literatura de higiene del sueño y el usuario promedio no debería necesitar ajustarlos. Este score alimenta al DayScore de Unit 5.

---

### Q2: Breathing Exercise Techniques
What breathing techniques to include?

A) **Two techniques** — Box breathing (4-4-4-4) and 4-7-8 technique. Simple, MVP-friendly.
B) **Three techniques** — Box (4-4-4-4), 4-7-8, and Coherent breathing (5-5). Covers most needs.
C) **Custom technique builder** — User defines inhale/hold/exhale durations. Maximum flexibility.

[Answer]: B

**Rationale**: Tres técnicas cubren los tres casos de uso principales: Box breathing (4-4-4-4) para enfoque y calma general, 4-7-8 para conciliar el sueño (excelente sinergia con el módulo Sleep), y Coherent breathing (5-5 inhalar-exhalar) para regulación del sistema nervioso y reducción de estrés. Cada técnica se modela como un record inmutable: `BreathingTechnique(name, inhaleSeconds, holdSeconds, exhaleSeconds, holdAfterExhaleSeconds, description)`. La opción A deja fuera coherent breathing que es la más respaldada por investigación de variabilidad cardíaca (HRV). La opción C es innecesaria para MVP — si el usuario quiere tiempos custom, se puede agregar post-launch. Con 3 técnicas predefinidas, la UI es un simple selector de cards, y la `breathing_sessions` table registra la técnica usada + duración total para tracking.

---

### Q3: Mood Scale
MNT uses 1-5 mood scale. What do the levels represent?

A) **Emotion faces** — 1=Muy mal, 2=Mal, 3=Neutral, 4=Bien, 5=Muy bien. Simple valence scale.
B) **Energy-based** — 1=Agotado, 2=Bajo, 3=Normal, 4=Energetico, 5=Excelente. Energy focus.
C) **Dual axis** — Valence (1-5) + Energy (1-5) = 2D mood model. More nuanced but complex.

[Answer]: C

**Rationale**: El modelo dual axis (valence + energy) captura estados que una sola dimensión no puede distinguir: "estresado pero productivo" (valence 2, energy 5) vs "relajado pero aburrido" (valence 4, energy 1) vs "feliz y energético" (valence 5, energy 5). Esto es el modelo circumplejo de Russell, ampliamente usado en psicología. En la tabla `mood_logs`: `valence: IntColumn` (1-5) + `energy: IntColumn` (1-5). La UI muestra una grilla 5×5 con emoji/colores, o dos sliders verticales — es más expresivo con solo un tap extra vs la opción A. Para el DayScore, el mood score se calcula como: `moodScore = ((valence - 1) / 4 × 50) + ((energy - 1) / 4 × 50)` — promedio de ambos ejes normalizado a 0-100. La opción A pierde la dimensión de energía que es crucial para correlaciones con Sleep y Gym (dormir mal → baja energía, workout → alta energía). El `energy_logs` table queda como tracking separado de energía a lo largo del día, mientras que mood captura el estado emocional bidimensional.

---

### Q4: HealthKit/Health Connect Integration
Sleep data import from smartwatches. When to implement?

A) **Include in Unit 6** — Implement platform channels for sleep import now.
B) **Defer to Unit 8 (Integration)** — Keep Unit 6 manual-only. Add HealthKit in the integration unit.
C) **Skip entirely for now** — Mark as post-launch feature.

[Answer]: B

**Rationale**: Unit 6 debe enfocarse en la lógica de dominio pura (sleep score, mood tracking, breathing exercises) sin acoplarse a APIs de plataforma. HealthKit (iOS) y Health Connect (Android) requieren platform channels nativos, permisos del sistema, manejo de OAuth/scopes, y testing en dispositivos reales — es trabajo de integración, no de dominio. Diferir a Unit 8 (Integration + Intelligence) es el lugar correcto: para ese punto, todo el modelo de datos de Sleep ya existe y solo se agrega una fuente de datos alternativa. El `SleepNotifier` tendrá un método `importSleepData(SleepLogInput)` que funciona igual tanto para entrada manual como para datos importados — la abstracción es agnóstica de la fuente. La opción A mezcla responsabilidades y complica el testing de Unit 6 (necesitarías mocks de platform channels). La opción C es demasiado conservadora — HealthKit es un diferenciador importante para launch.

