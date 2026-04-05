# LifeOS

**App Todo-en-1 para iOS + Android: Finanzas + Gym + Nutricion + Habitos + Sueno + Bienestar Mental**

Una app cross-platform con Flutter que centraliza el control de tu vida en una sola interfaz. Con capa de IA opcional (BYOK), metas unificadas cross-modulo, integraciones externas y widgets inteligentes.

---

## Modulos

| Modulo | Descripcion | Prioridad |
|---|---|---|
| Finanzas Personales | Transacciones, presupuestos, categorias, reportes, metas de ahorro | P1 |
| Gimnasio & Fitness | Biblioteca 200+ ejercicios, rutinas, workout activo, timer, PRs | P2 |
| Nutricion | Food log, macros, meal templates, escaneo barras, analisis foto con IA | P2.5 |
| Habitos | Check-in diario, streaks, calendario visual, estadisticas | P3 |
| Sueno + Energia | Sleep log detallado con interrupciones, sleep score, energy check-ins | P3 |
| Bienestar Mental | Mood check-in, journaling, gratitud, ejercicios de respiracion | P3.5 |

## Capas Transversales

| Capa | Descripcion | Prioridad |
|---|---|---|
| Life Goals | Metas compuestas cross-modulo con timeline y milestones | P3 |
| LifeOS Intelligence | IA con BYOK (OpenAI, Anthropic, Gemini): insights, chat, analisis de fotos | P4 |
| Connect | Auto-registro de pagos, Health data, voice assistant, importar/exportar datos | P4 |
| Widgets | Home screen widgets en ambas plataformas | P4 |
| Day Score + Time Machine | Puntuacion diaria, Life Review semanal, comparacion historica | P5 |

## Stack Tecnologico

| Componente | Tecnologia |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Base de datos | Drift (SQLite, local) |
| Navegacion | go_router |
| Graficas | fl_chart |
| Biometria | local_auth (Face ID / Fingerprint) |
| Notificaciones | flutter_local_notifications |
| Salud | health (Apple Health + Health Connect) |
| Barcode | mobile_scanner |
| OCR | google_mlkit_text_recognition |
| Widgets | home_widget |
| Secure Storage | flutter_secure_storage |
| Localizacion | intl + ARB files (ES + EN) |

**Plataformas:** iOS 16+ / Android API 26+
**Patron:** MVVM con Riverpod (Notifiers = ViewModels)
**Design:** Custom dark theme (identidad propia, no Material ni Cupertino)
**Tipografia:** Inter + JetBrains Mono
**APIs opcionales:** OpenAI/Anthropic/Gemini (IA), Open Food Facts (barras), Exchangerate (moneda)

## Estructura del Proyecto

```
life_os/
├── lib/
│   ├── core/               # Constants, database, router, services, shared widgets
│   ├── features/
│   │   ├── dashboard/       # Pantalla principal unificada
│   │   ├── finance/         # Modulo finanzas
│   │   ├── gym/             # Modulo gimnasio
│   │   ├── nutrition/       # Modulo nutricion
│   │   ├── habits/          # Modulo habitos
│   │   ├── sleep/           # Modulo sueno
│   │   ├── mental/          # Modulo bienestar mental
│   │   ├── goals/           # Metas unificadas
│   │   ├── intelligence/    # Capa de IA (BYOK)
│   │   ├── day_score/       # Day Score + Time Machine
│   │   └── onboarding/      # Flujo de bienvenida
│   └── l10n/                # Localization (ES + EN)
├── assets/                  # Fonts, icons, JSON data
├── android/                 # Android native (widgets, platform channels)
├── ios/                     # iOS native (widgets, platform channels)
├── test/                    # Unit + widget tests
└── integration_test/        # Integration tests
```

## Costo

| Concepto | Costo |
|---|---|
| Infraestructura | $0 (todo local) |
| Dependencias | $0 (paquetes open source) |
| Apple Developer Program | $99 USD/ano |
| Google Play Console | $25 USD (pago unico) |

## Documentacion

- [`LifeOS-Spec.md`](LifeOS-Spec.md) — Especificacion completa (modelos, features, UI, roadmap)
- [`docs/plans/`](docs/plans/) — Documentos de diseno y brainstorming
- [`aidlc-docs/`](aidlc-docs/) — AI-DLC workflow documentation (PRD, requirements, audit)
