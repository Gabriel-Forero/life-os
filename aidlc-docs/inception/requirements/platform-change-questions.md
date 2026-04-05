# Platform Change — Clarification Questions

The switch to Flutter impacts several decisions. Please answer these to update the requirements correctly.

---

## Question 1
What state management approach do you prefer for Flutter?

A) Riverpod — modern, compile-safe, testable, recommended by Flutter community
B) BLoC/Cubit — event-driven, strict separation, widely adopted in enterprise
C) Provider — simpler, official Flutter recommendation, lighter weight
D) No preference — let me recommend based on the project complexity
X) Other (please describe after [Answer]: tag below)

[Answer]: A

**Decision**: Riverpod

**Rationale**: Riverpod es la evolución natural del patrón MVVM que ya se tenía definido. Los ViewModels de SwiftUI (@Observable) se mapean directamente a Notifiers de Riverpod. Es type-safe (el compilador detecta errores), maneja dependencias entre módulos limpiamente (crucial para 11 módulos interconectados como Goals que lee de Finanzas, Gym, Hábitos, etc.), y tiene excelente soporte para operaciones async. La comunidad y documentación son muy activas.

**Alternativas descartadas**:
- BLoC/Cubit: Muy robusto pero demasiado verbose (clases de evento + estado por cada feature). Para 11 módulos sería mucho boilerplate.
- Provider: Antecesor de Riverpod, más limitado en escalabilidad y testing.
- GetX: Controversial por mezclar responsabilidades, no recomendado para proyectos grandes.

---

## Question 2
What local database for Flutter?

A) Drift (formerly Moor) — SQL-based, type-safe, reactive queries, closest to SwiftData experience
B) Isar — NoSQL, very fast, Flutter-native, supports complex queries
C) Hive — lightweight key-value store, very fast, simple API
D) sqflite — raw SQLite, maximum control, most packages compatible with it
E) No preference — let me recommend
X) Other (please describe after [Answer]: tag below)

[Answer]: A

**Decision**: Drift (SQLite)

**Rationale**: Drift es el equivalente más cercano a SwiftData/Core Data en el ecosistema Flutter. Ofrece queries type-safe en Dart, soporte reactivo (streams que actualizan la UI automáticamente cuando cambian los datos), migraciones de esquema robustas, y relaciones complejas entre tablas. LifeOS tiene ~25 modelos con relaciones many-to-one y cascade deletes, lo cual Drift maneja nativamente con SQL. Es maduro, bien mantenido, y la comunidad es activa.

**Alternativas descartadas**:
- Isar: NoSQL rápido pero el proyecto ha tenido mantenimiento irregular. Riesgo para un proyecto a largo plazo.
- Hive: Key-value store, demasiado simple para las relaciones complejas de LifeOS (Transaction → Category, Workout → Sets → Exercise).
- sqflite: SQL crudo sin type-safety. Más propenso a errores y requiere más código manual.

---

## Question 3
For cloud sync (replacing iCloud/CloudKit which is Apple-only), what approach?

A) Firebase (Firestore + Auth) — Google-owned, free tier generous, real-time sync, works on both platforms
B) Supabase — open-source Firebase alternative, PostgreSQL, generous free tier
C) Local-only with manual export/import (JSON backup) — simplest, zero cloud cost
D) Appwrite — open-source backend, self-hostable
E) No preference — let me recommend
X) Other (please describe after [Answer]: tag below)

[Answer]: C

**Decision**: Local-only con backup exportable (export/import manual en JSON)

**Rationale**: Mantiene la filosofía original de $0 de infraestructura y privacidad total — los datos nunca salen del dispositivo a menos que el usuario lo decida explícitamente. El usuario puede exportar un backup completo (archivo JSON o SQLite) y restaurarlo en otro dispositivo manualmente. Esto elimina dependencia a cualquier servicio cloud, no requiere cuentas de usuario, y simplifica enormemente la arquitectura. Cloud sync (Firebase o Supabase) queda como feature futura opcional para post-MVP.

**Alternativas descartadas (para MVP)**:
- Firebase: Introduce dependencia a Google y rompe el principio de $0 infraestructura si la app escala.
- Supabase: Excelente opción pero agrega complejidad innecesaria para v1.0.
- Sin backup: Demasiado riesgo de pérdida de datos para el usuario.

---

## Question 4
The original spec had "zero external dependencies". With Flutter, packages are essential. What's your philosophy?

A) Minimize packages — use only well-maintained, popular packages. Prefer writing custom code for simple features
B) Pragmatic — use packages when they save significant time, avoid obscure or unmaintained ones
C) Package-friendly — use the best package for each job, regardless of count
X) Other (please describe after [Answer]: tag below)

[Answer]: B

**Decision**: Pragmático

**Rationale**: En Flutter, a diferencia de iOS nativo, los paquetes son parte esencial del ecosistema. La filosofía pragmática significa: usar paquetes cuando ahorren tiempo significativo y estén bien mantenidos (>500 likes en pub.dev, actualizaciones recientes, buen número de contributors), pero escribir código custom para features simples que no justifiquen una dependencia externa. Se evitan paquetes obscuros, abandonados, o que introduzcan vulnerabilidades. Cada paquete debe justificar su inclusión.

**Paquetes core esperados**:
- flutter_riverpod (estado)
- drift + sqlite3_flutter_libs (base de datos)
- fl_chart o syncfusion_flutter_charts (gráficas)
- local_auth (biometría)
- health (HealthKit + Health Connect)
- mobile_scanner (códigos de barras)
- google_mlkit_text_recognition (OCR)
- flutter_local_notifications (notificaciones locales)
- flutter_secure_storage (almacenamiento seguro de API keys)
- home_widget (widgets de pantalla de inicio)
- go_router (navegación)
- intl (internacionalización)

---

## Question 5
Some iOS-specific features become harder or impossible in Flutter. Which should we keep, adapt, or drop?

A) Keep all features, use platform channels for iOS-specific ones (Dynamic Island, Apple Watch, bank notification interception). Android gets equivalent where possible (widgets via home_widget, Wear OS for watch)
B) Drop platform-specific features (Dynamic Island, Apple Watch, Wear OS) and focus on cross-platform features only. Widgets still included via home_widget
C) Keep iOS-specific features as iOS-only (via platform channels), Android gets the core app without those extras
X) Other (please describe after [Answer]: tag below)

[Answer]: A

**Decision**: Mantener equivalentes en ambas plataformas

**Rationale**: La experiencia debe ser lo más completa posible en ambas plataformas. Para features que no tienen equivalente directo, se usan platform channels o paquetes especializados.

**Mapeo de features iOS → Android**:
| Feature iOS | Equivalente Android | Mecanismo |
|---|---|---|
| HealthKit | Google Health Connect | Paquete `health` |
| Face ID / Touch ID | Fingerprint / Face Unlock | Paquete `local_auth` |
| iCloud sync | Backup local exportable | Export/Import JSON |
| Widgets (WidgetKit) | Home screen widgets | Paquete `home_widget` |
| Dynamic Island / Live Activities | Notificación persistente + foreground service | Platform channels |
| Apple Watch | Wear OS | Platform channels (post-MVP) |
| Siri Shortcuts | Google Assistant Routines | Platform channels (post-MVP) |
| Vision OCR | Google ML Kit | Paquete `google_mlkit_text_recognition` |
| AVFoundation (barcode) | ML Kit / ZXing | Paquete `mobile_scanner` |
| Keychain | Android Keystore | Paquete `flutter_secure_storage` |
| Apple Calendar | Google Calendar | Paquete `device_calendar` |
| SF Symbols (iconos) | Material Icons + custom | Paquete `flutter_iconpicker` o iconos propios |

**Nota**: Apple Watch y Wear OS quedan como post-MVP debido a la complejidad de mantener dos companion apps nativas.

---

## Question 6
What design language for the app?

A) Material Design 3 — Google's design system, feels native on Android, acceptable on iOS
B) Cupertino (iOS-style) everywhere — looks great on iOS, feels slightly foreign on Android
C) Adaptive — Material on Android, Cupertino on iOS (more work, best native feel on both)
D) Custom design system — unique look that doesn't follow either platform convention (like the dark theme in the original spec)
X) Other (please describe after [Answer]: tag below)

[Answer]: D

**Decision**: Custom design system (dark theme del spec original)

**Rationale**: Mantener la identidad visual única de LifeOS con el tema oscuro definido en la especificación original. La app se ve idéntica en iOS y Android, creando una marca reconocible. Esto simplifica el desarrollo (una sola UI) y evita que la app se sienta "genérica" como cualquier app Material o Cupertino.

**Paleta mantenida del spec original**:
- Background primary: #0A0A0F
- Background secondary: #111122
- Card background: #1A1A2E
- Finance module: #10B981 (green)
- Gym module: #F59E0B (amber)
- Habits module: #8B5CF6 (purple)
- Cross features: #EC4899 (pink)

**Tipografía**: Se reemplaza SF Pro (Apple-only) por Google Fonts equivalentes:
- Títulos: Inter Bold/Heavy (reemplazo de SF Pro Display)
- Cuerpo: Inter Regular (reemplazo de SF Pro Text)
- Números/Montos: JetBrains Mono o Fira Code (reemplazo de SF Mono)

**Iconografía**: Se reemplazan SF Symbols por:
- Material Icons (incluidos en Flutter)
- Lucide Icons o Phosphor Icons para iconos adicionales
- Iconos custom SVG donde sea necesario

---

## Question 7
For health data integration (replacing HealthKit-only), what approach?

A) health package — supports both Apple Health (iOS) and Google Fit / Health Connect (Android)
B) Skip health integration entirely for v1.0, add later
X) Other (please describe after [Answer]: tag below)

[Answer]: A

**Decision**: Paquete `health` para ambas plataformas

**Rationale**: El paquete `health` de Flutter soporta tanto Apple Health (iOS) como Google Health Connect (Android) con una API unificada. Esto permite sincronizar datos de sueño, pasos, frecuencia cardíaca, y calorías quemadas en ambas plataformas sin escribir código nativo separado. La integración es post-MVP (Phase 2) junto con el módulo de Sueño, pero la arquitectura debe contemplarla desde el diseño inicial.

**Datos a sincronizar**:
- Importar: sueño, pasos, frecuencia cardíaca, calorías quemadas
- Exportar: workouts completados
- Permisos: solicitar solo los necesarios, explicar al usuario por qué se necesita cada uno

---

## Summary of Decisions

| Decision | Choice |
|---|---|
| **Framework** | Flutter (Dart) — iOS + Android |
| **State Management** | Riverpod |
| **Database** | Drift (SQLite) |
| **Cloud Sync** | Local-only + backup exportable (cloud sync post-MVP) |
| **Package Philosophy** | Pragmático — paquetes bien mantenidos cuando ahorren tiempo |
| **Platform Features** | Equivalentes en ambas plataformas |
| **Design Language** | Custom dark theme (identidad propia) |
| **Health Integration** | Paquete `health` (Apple Health + Health Connect) |
| **Typography** | Inter + JetBrains Mono (reemplazando SF Pro) |
| **Icons** | Material Icons + Lucide/Phosphor (reemplazando SF Symbols) |
| **Architecture** | MVVM con Riverpod (Notifiers = ViewModels) |
| **Target Platforms** | iOS 16+ / Android API 26+ (Android 8.0+) |
| **Cost** | $0 infraestructura + $99/año Apple + $25 one-time Google Play |

---

*Decisions captured: 2026-04-03*
*Based on user responses during Requirements Analysis platform change review*
