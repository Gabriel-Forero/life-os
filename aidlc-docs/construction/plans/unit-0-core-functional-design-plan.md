# Functional Design Plan — Unit 0: Core Foundation

## Unit Context
- **Stories**: 7 (ONB-01 to ONB-07 — Onboarding)
- **Drift Tables**: 1 (AppSettings)
- **Services**: EventBus, NotificationService, HapticService, SecureStorageService, BackupService, ExerciseLibraryService, ThemeNotifier
- **Dependencies**: None (this is the base unit)

---

## Questions

### Question 1
What information should the onboarding flow collect, and in what order?

A) Minimal — Name + language (ES/EN) + currency (COP default) + which modules to enable. 4 screens max.
B) Standard — Name + language + currency + modules + primary goal ("Ahorrar", "Ponerme en forma", "Ser mas disciplinado") + optional first budget or first habit. 5-6 screens.
C) Guided tour — same as B plus a quick tour of each enabled module with example data shown. 7-8 screens.
X) Other (please describe after [Answer]: tag below)

[Answer]: B

**Decision**: Standard — 5-6 pantallas recogiendo nombre, idioma, moneda, módulos activos, y objetivo principal con opción de primer dato.

**Rationale**:
- El onboarding necesita suficiente contexto para personalizar la experiencia desde el inicio (greeting con nombre, moneda correcta en Finance, módulos relevantes en Dashboard), pero sin ser tan largo que el usuario abandone antes de llegar a la app.
- Recoger el objetivo principal ("Ahorrar", "Ponerme en forma", "Ser más disciplinado", "Equilibrio general") permite que el Dashboard priorice los módulos relevantes y que Intelligence tenga contexto para futuras sugerencias.
- Ofrecer opcionalmente crear el primer dato (un presupuesto si eligió Finance, un hábito si eligió Habits) reduce la fricción del "pantalla vacía" sin obligar al usuario a hacerlo ahí mismo — ONB-07 (First Empty States) cubre el caso de que elija omitir.
- 5-6 pantallas es un sweet spot demostrado en apps de tracking: suficiente para personalizar, corto para no perder al usuario. Cada pantalla se completa en <10 segundos.

**Alternatives Discarded**:
- A (Minimal, 4 pantallas): Funcional pero pierde la oportunidad de personalizar el Dashboard y dar contexto al Intelligence module. El objetivo principal es dato valioso con costo mínimo de recolección.
- C (Guided tour, 7-8 pantallas): Demasiado largo para first-launch. Los usuarios quieren explorar por su cuenta. Un tour puede ofrecerse como tooltip contextual dentro de cada módulo la primera vez que se entra, no como pantallas bloqueantes durante onboarding.

### Question 2
How should the JSON backup/restore work?

A) Single file — one JSON file with ALL data from all modules. Simple but large file for users with lots of data.
B) Per-module files — separate JSON files per module in a ZIP archive. User can restore selectively.
C) SQLite file copy — export the raw Drift/SQLite database file directly. Most reliable, least human-readable.
X) Other (please describe after [Answer]: tag below)

[Answer]: B

**Decision**: Per-module files en ZIP — archivos JSON separados por módulo dentro de un archivo .zip, con restauración selectiva.

**Rationale**:
- Selectividad: el usuario puede exportar todo pero restaurar solo Finance, o solo Habits, sin sobreescribir datos de otros módulos. Esto es especialmente útil al migrar de dispositivo o al recuperar datos después de un problema en un módulo específico.
- Cada archivo JSON es legible y depurable: si un usuario reporta un bug de datos, puede compartir solo el módulo afectado sin exponer todos sus datos personales.
- El ZIP mantiene todo organizado como un solo archivo para compartir/guardar, pero internamente tiene estructura clara: `lifeos-backup-2026-04-04/finance.json`, `lifeos-backup-2026-04-04/gym.json`, `lifeos-backup-2026-04-04/settings.json`, etc.
- Incluye un `manifest.json` en la raíz del ZIP con: versión de la app, fecha de exportación, lista de módulos incluidos, y conteo de registros por módulo — permite validar integridad antes de importar.
- Tamaño manejable: cada archivo JSON contiene solo las tablas de su módulo, evitando un solo archivo masivo.

**Alternatives Discarded**:
- A (Single JSON): Funcional para apps pequeñas, pero a medida que crece la data (cientos de transacciones, workouts, meals) el archivo se vuelve grande y difícil de manejar. No permite restauración selectiva.
- C (SQLite copy): La más confiable técnicamente (copia exacta del DB), pero no es legible, no permite restauración selectiva por módulo, y hay riesgos de incompatibilidad si la versión de Drift/SQLite cambia entre versiones de la app. Requeriría migration logic adicional.

---

## Execution Steps

- [x] Step 1: Answer questions
- [x] Step 2: Design AppSettings entity (all fields, defaults, constraints)
- [x] Step 3: Design onboarding flow (screens, validation, state transitions)
- [x] Step 4: Design EventBus event types (sealed class hierarchy)
- [x] Step 5: Design Result/AppFailure error types
- [x] Step 6: Design BackupService business logic (export/import/validation)
- [x] Step 7: Design theme system (colors, typography, dark/light mode)
- [x] Step 8: Design notification scheduling rules
- [x] Step 9: Generate functional design artifacts
