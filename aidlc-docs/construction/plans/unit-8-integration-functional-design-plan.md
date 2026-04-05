# Functional Design Plan — Unit 8: Integration + Intelligence

## Unit Context
- **Unit**: 8 — Integration + Intelligence (FINAL UNIT)
- **Stories**: INT-01 to INT-07 (5 MVP + 2 Phase 2)
- **Drift Tables**: 3 (ai_configurations, ai_conversations, ai_messages)
- **Notifier**: AINotifier
- **DAO**: AIDao + AIRepository
- **Dependencies**: ALL prior units (0-7)
- **Scope**: Cross-module EventBus wiring + AI chat + Full backup export/import

## Three sub-scopes:
1. **EventBus Wiring** — Connect all module events end-to-end (INT-01 to INT-05)
2. **Backup/Import** — Full data export/import via BackupEngine (INT-06, INT-07)
3. **AI Intelligence** — Chat with AI providers (OpenAI, Anthropic)

## Steps
- [ ] Step 1-4: Domain entities, business rules, logic flows, PBT properties

## Questions

---

### Q1: AI Provider Support for MVP
Which AI providers should be supported at launch?

A) **OpenAI only** — GPT-4o/GPT-4o-mini. Single provider, simpler implementation.
B) **OpenAI + Anthropic** — Both providers. User chooses default. More choice.
C) **Provider-agnostic with plugin architecture** — Abstract provider interface. Ship with OpenAI, users can add more via settings.

[Answer]: C

**Rationale**: El mercado de LLMs evoluciona rápido — atarse a un solo provider es una deuda técnica segura. Una interfaz abstracta `AIProvider` con métodos `sendMessage(prompt, context) → Stream<String>` y `listModels()` permite shipear con OpenAI (GPT-4o-mini como default económico) y agregar Anthropic, Gemini, o modelos locales (Ollama) sin refactoring. El costo de la abstracción es mínimo: una clase abstracta, un factory, y un campo `providerKey` en `ai_configurations`. El usuario configura su API key por provider en settings. Para MVP se implementa solo el adapter de OpenAI (`OpenAIProvider implements AIProvider`), pero la arquitectura queda lista. Esto es consistente con la filosofía de LifeOS de extensibilidad — igual que el EventBus desacopla módulos, el provider interface desacopla la inteligencia del vendor.

---

### Q2: AI Chat Context
What data should be sent as context in AI conversations?

A) **No auto-context** — User manually describes their situation. AI has no access to app data.
B) **Summary context** — Each message includes a system prompt with today's summary (DayScore, macros, budget status, streak counts). No raw data.
C) **Full context on demand** — User can explicitly "share" specific module data with the AI (e.g., "share my finance data"). AI sees only what user shares.

[Answer]: B

**Rationale**: El valor del AI coach en LifeOS es que conoce tu contexto — sin eso, es solo otro ChatGPT. El summary context incluye datos agregados del día en el system prompt: DayScore actual, calorías consumidas vs meta, presupuesto gastado vs límite, hábitos completados, horas de sueño, mood. Son ~200-300 tokens de contexto, costo despreciable. No se envían datos raw (transacciones individuales, sets de gym) — solo resúmenes. Esto permite respuestas como "Veo que hoy llevas 70% de tu meta calórica y aún no entrenas — considera un snack alto en proteína antes del gym". La opción A convierte al AI en un chatbot genérico sin valor agregado. La opción C es buena idea para Phase 2 (deep-dive en datos específicos) pero agrega UX complejo para MVP. El summary se genera via una función pura `buildAIContext()` que lee los Notifiers actuales y produce un string para el system prompt.

---

### Q3: Training Day Nutrition Adjustment (INT-02)
How should nutrition goals auto-adjust on training days?

A) **Fixed offset** — User configures "+X calories, +Yg protein" for training days. Applied when WorkoutCompletedEvent is received.
B) **Percentage increase** — User configures "+15% calories, +20% protein" for training days.
C) **Defer to post-MVP** — Skip training day adjustment for now. Focus on manual goal management.

[Answer]: B

**Rationale**: Porcentaje es más robusto que offset fijo porque escala con las metas del usuario — si alguien come 2000 kcal, +15% = +300 kcal; si come 3000 kcal, +15% = +450 kcal. Un offset fijo de "+300 kcal" sería excesivo para el primero e insuficiente para el segundo. Defaults sensatos: +15% calorías, +20% proteína, +10% carbohidratos, +0% grasa. Se almacenan en `nutrition_goals` como campos `trainingDayCaloriesPct`, `trainingDayProteinPct`, etc. Cuando `WorkoutCompletedEvent` llega, `NutritionNotifier` recalcula las metas del día: `adjustedTarget = baseTarget × (1 + pct/100)`. La UI muestra un indicador "Día de entrenamiento" junto a las metas ajustadas. Si el usuario no quiere ajuste, pone 0% en todo. La opción C pierde una integración Gym↔Nutrition que es uno de los features más valiosos de LifeOS.

---

### Q4: Backup Format
INT-06/07 define export/import. The BackupEngine in Unit 0 already uses ZIP with per-module JSON. Should Unit 8 extend or replace it?

A) **Use existing BackupEngine** — Extend Unit 0's BackupEngine to include all module tables. Same ZIP+manifest format.
B) **New export format** — Single large JSON file instead of ZIP. Simpler but larger files.
C) **Both formats** — ZIP for full backup, individual JSON per module for selective export.

[Answer]: A

**Rationale**: El BackupEngine de Unit 0 ya implementa la arquitectura ZIP + manifest.json con JSON per-module — exactamente lo que se necesita. Extenderlo es trivial: cada módulo registra su `BackupHandler` con métodos `export() → Map<String, dynamic>` e `import(Map)`. Unit 8 simplemente agrega los handlers de los módulos 1-7 que aún no están registrados. El manifest.json ya contiene versión, timestamp, y lista de módulos incluidos, lo cual permite importación parcial (restaurar solo Finance sin tocar Gym). La opción B (JSON único) pierde la ventaja de compresión (ZIP) y la modularidad del backup selectivo. La opción C agrega un segundo formato de export que hay que mantener. Reusar y extender el engine existente sigue el principio DRY y valida que la arquitectura de Unit 0 fue bien diseñada.

---

### Q5: EventBus Wiring Testing
How should cross-module event flows be tested?

A) **Integration tests only** — Test full event flows in integration test suite (not unit tests).
B) **Unit tests with mocks** — Each notifier's event handler unit-tested with mocked dependencies.
C) **Both** — Unit tests for individual handlers + integration tests for end-to-end flows.

[Answer]: C

**Rationale**: Los event flows cross-module son el punto de integración más crítico de LifeOS — si `WorkoutCompletedEvent` no llega a `HabitsNotifier` o `NutritionNotifier`, features enteros se rompen silenciosamente. Con C: (1) Unit tests con mocks validan que cada handler individual reacciona correctamente al evento (rápidos, aislados, dentro del TDD cycle de cada módulo), (2) Integration tests con DB en memoria y EventBus real validan el flow completo: `GymNotifier.finishWorkout()` → EventBus → `HabitsNotifier` auto-checks habit → `NutritionNotifier` ajusta metas. Los integration tests usan `AppDatabase(NativeDatabase.memory())` con todos los DAOs reales — sin mocks de DB, solo de servicios externos (API calls). La opción A pierde la rapidez del feedback loop unitario. La opción B pierde la confianza de que los módulos realmente se conectan en runtime. Ambas capas son necesarias.

