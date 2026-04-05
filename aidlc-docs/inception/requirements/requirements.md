# LifeOS — Product Requirements Document (PRD)

## Intent Analysis

| Attribute | Value |
|---|---|
| **User Request** | Build a comprehensive PRD for LifeOS using the existing specification and expansion design documents |
| **Request Type** | New Project (Greenfield) |
| **Scope** | System-wide — 6 core modules + 5 transversal layers |
| **Complexity** | Complex — multi-module cross-platform app (Flutter) with IA integration, external integrations, widgets, wearable companions |
| **Depth** | Comprehensive |

---

## 1. Product Overview

### 1.1 Product Name
**LifeOS**

### 1.2 Vision Statement
A cross-platform mobile application (Flutter — iOS + Android) that centralizes personal finance control, gym routines, nutrition tracking, habit monitoring, sleep quality, and mental well-being into a single, fast, clean interface. Powered by an optional AI layer (BYOK — Bring Your Own Key), unified cross-module goals, external integrations, and intelligent widgets. No proprietary servers, no subscriptions — data lives on the user's device with optional manual backup export.

### 1.3 Target Audience
Any person who wants to improve their life — no assumed prior knowledge of fitness, finance, or productivity. The app must be intuitive for first-time users while powerful enough for experienced users.

### 1.4 Platform and Device
- **Platforms**: iOS 16+ and Android API 26+ (Android 8.0+)
- **Device**: Smartphones (iPhone + Android phones)
- **Framework**: Flutter (Dart)
- **Architecture Pattern**: MVVM with Riverpod (Notifiers = ViewModels)
- **Local Database**: Drift (SQLite, type-safe, reactive)
- **State Management**: Riverpod

### 1.5 Localization
- **Bilingual from day one**: Spanish (primary) + English
- **Code language**: English (variable names, functions, types)
- **UI language**: Spanish and English, user-selectable
- **Localization framework**: Flutter intl / ARB files

### 1.6 Monetization
- **Completely free** — no ads, no in-app purchases, no subscriptions
- **Cost to user**: $0
- **Cost to developer**: $99 USD/year (Apple Developer Program) + $25 USD one-time (Google Play Console)

---

## 2. Module Priority and MVP Scope

### 2.1 MVP (v1.0) — Ship with all 4 core modules

| Module | Priority | MVP Scope |
|---|---|---|
| Finanzas Personales | P1 — Maximum | Full MVP features |
| Gimnasio & Fitness | P2 — High | Full MVP features |
| Nutricion | P2.5 — High | Full MVP features |
| Habitos & Productividad | P3 — Normal | Full MVP features |

### 2.2 Post-MVP Modules

| Module | Priority | Phase |
|---|---|---|
| Sueno + Energia | P3 | Phase 2 |
| Bienestar Mental | P3.5 | Phase 2 |
| Life Goals (Metas Unificadas) | P3 | Phase 2 |
| LifeOS Intelligence (IA) | P4 | Phase 3 |
| Connect (Integraciones) | P4 | Phase 3 |
| Widgets + Live Activities | P4 | Phase 4 |
| Day Score + Life Review + Time Machine | P5 | Phase 4 |

---

## 3. Functional Requirements

### FR-01: Dashboard Unificado
- **Description**: Main screen showing a summary of all active modules
- **Priority**: MVP
- **Details**:
  - Display key metrics from each enabled module
  - Quick-action buttons for most common tasks (add transaction, start workout, check-in habit, log meal)
  - Responsive to the number of active modules
  - Bilingual support (ES/EN)

### FR-02: Modulo Finanzas — Transacciones
- **Description**: Record income and expenses with category, amount, date, and note
- **Priority**: MVP
- **Details**:
  - Register transactions in maximum 3 taps
  - Swipe actions for edit/delete
  - Default currency: COP (Colombian Peso)
  - Multi-currency support in post-MVP
  - Transaction types: Income (.income) and Expense (.expense)
  - Category assignment with Material/Lucide icons and hex colors
  - Optional note per transaction
  - Date selector (defaults to today)

### FR-03: Modulo Finanzas — Categorias
- **Description**: Predefined and custom categories for transactions
- **Priority**: MVP
- **Details**:
  - 12 predefined categories: Comida, Transporte, Entretenimiento, Salud, Gym, Ropa, Educacion, Hogar, Suscripciones, Ahorro, Regalos, Otro
  - User can create custom categories with name, Material/Lucide icon, and hex color
  - Categories are not deletable if transactions reference them (nullify relationship)

### FR-04: Modulo Finanzas — Presupuestos
- **Description**: Monthly/weekly budget limits per category with alerts
- **Priority**: MVP
- **Details**:
  - Set spending limit per category
  - Budget period: monthly or weekly
  - Alert threshold configurable (default 80%)
  - Visual progress bar per category
  - Alert notification at threshold and at 100%

### FR-05: Modulo Finanzas — Graficas y Reportes
- **Description**: Visual reports of financial data
- **Priority**: MVP
- **Details**:
  - Pie chart: expenses by category
  - Bar chart: income vs expenses per month
  - Line chart: savings trend over time
  - Built with fl_chart package (rich, customizable charts for Flutter)
  - Date range selector (week, month, quarter, year, custom)

### FR-06: Modulo Finanzas — Dashboard Financiero
- **Description**: Financial overview with total balance, income vs expenses, and trend
- **Priority**: MVP
- **Details**:
  - Total balance (income - expenses for selected period)
  - Month-to-date income and expenses
  - Comparison with previous period
  - Budget utilization summary

### FR-07: Modulo Finanzas — Metas de Ahorro
- **Description**: Savings goals with name, target amount, deadline, and progress
- **Priority**: Post-MVP
- **Details**:
  - Create goals with name, target amount, optional deadline, and icon
  - Manual contribution tracking (currentAmount)
  - Progress percentage: min(currentAmount / targetAmount, 1.0)
  - Visual progress ring

### FR-08: Modulo Finanzas — Transacciones Recurrentes
- **Description**: Recurring fixed expenses/income that auto-register
- **Priority**: Post-MVP
- **Details**:
  - Frequency: weekly, biweekly, monthly
  - Day of month for monthly recurrence (1-31)
  - Active/inactive toggle
  - Auto-create transaction on schedule
  - Track last processed date

### FR-09: Modulo Finanzas — Registro Automatico de Pagos
- **Description**: Automatic transaction registration when paying with phone
- **Priority**: Post-MVP (Phase 3)
- **Details**:
  - **Method 1: Bank notifications** — intercept push notifications from banking apps, parse amount and merchant, auto-create transaction (platform-specific via NotificationListenerService on Android, limited on iOS)
  - **Method 2: NFC/Tap payments** — detect completed tap payment where platform APIs allow, capture available data
  - **Method 3: Platform automation** — iOS Shortcuts / Android Tasker integration triggered on payment detection, opens LifeOS pre-filled
  - **Behavior**: Auto-create the transaction immediately and notify the user to review/categorize
  - User receives a local notification to review and categorize the auto-created transaction

### FR-10: Modulo Gimnasio — Biblioteca de Ejercicios
- **Description**: Library of 200+ exercises by muscle group
- **Priority**: MVP
- **Details**:
  - Downloaded on first launch from remote source (not bundled in binary)
  - Search and filter by muscle group, equipment
  - Each exercise: name, primary muscle group, secondary muscles, equipment, instructions
  - 13 muscle groups: Pecho, Espalda, Hombros, Biceps, Triceps, Antebrazos, Cuadriceps, Isquiotibiales, Gluteos, Pantorrillas, Abdominales, Cardio, Cuerpo Completo
  - 8 equipment types: Barra, Mancuernas, Maquina, Cable, Peso Corporal, Kettlebell, Banda, Otro
  - User can create custom exercises (isCustom = true)

### FR-11: Modulo Gimnasio — Rutinas
- **Description**: Create custom workout routines
- **Priority**: MVP
- **Details**:
  - Routine: name + ordered list of exercises
  - Each exercise in routine: target sets, target reps, rest seconds, order
  - Track last used date
  - Templates (post-MVP): PPL, Upper/Lower, Full Body, 5/3/1, Starting Strength

### FR-12: Modulo Gimnasio — Workout Activo
- **Description**: Active workout recording with rest timer
- **Priority**: MVP
- **Details**:
  - Start workout from routine or empty
  - Record each set: exercise, set number, weight (kg), reps
  - Mark sets as warmup or working
  - Configurable rest timer with haptic vibration on completion
  - Auto-start timer when marking set complete
  - Duration tracking
  - Total volume calculation: sum(weight * reps)
  - Mark workout as completed

### FR-13: Modulo Gimnasio — Historial y PRs
- **Description**: Workout history and personal record detection
- **Priority**: MVP
- **Details**:
  - Complete log of all workouts by date
  - Per-exercise progress charts over time
  - Automatic PR detection (isPersonalRecord flag on WorkoutSet)
  - 1RM estimation using Epley formula: weight * (1 + reps/30)

### FR-14: Modulo Gimnasio — Body Tracking
- **Description**: Body measurements and progress
- **Priority**: Post-MVP
- **Details**:
  - Weight, chest, waist, hips, left/right arm, left/right thigh, body fat %
  - Date-stamped measurements
  - Progress charts over time

### FR-15: Modulo Nutricion — Food Log
- **Description**: Quick meal logging with macros
- **Priority**: MVP
- **Details**:
  - Register meals in 2 taps
  - Food item library with calories, protein, carbs, fat per serving
  - Meal types: Desayuno, Almuerzo, Cena, Snack
  - Quantity multiplier per item
  - Totals calculated: totalCalories, totalProtein, totalCarbs, totalFat
  - Search + favorites + frequent items

### FR-16: Modulo Nutricion — Meal Templates
- **Description**: Reusable meal templates for quick logging
- **Priority**: MVP
- **Details**:
  - Save any meal as template with name
  - One-tap logging from template
  - Track last used date

### FR-17: Modulo Nutricion — Objetivos de Macros
- **Description**: Daily macro goals with progress tracking
- **Priority**: MVP
- **Details**:
  - Set daily targets: calories, protein, carbs, fat
  - Water tracking: glasses per day target
  - Visual progress bars per macro
  - Optional: different targets for training vs rest days (trainingCalorieBoost)

### FR-18: Modulo Nutricion — Escaneo de Codigo de Barras
- **Description**: Scan food barcodes to auto-fill nutritional data
- **Priority**: Post-MVP
- **Details**:
  - Use mobile_scanner package for barcode scanning (AVFoundation on iOS, CameraX/ML Kit on Android)
  - Look up nutritional data via Open Food Facts API (free, open source)
  - Auto-fill FoodItem fields from API response

### FR-19: Modulo Nutricion — Analisis de Foto con IA
- **Description**: Take photo of food, AI estimates calories and macros
- **Priority**: Post-MVP (Phase 3)
- **Details**:
  - Requires user-configured API key (BYOK)
  - Send photo to vision-capable AI model
  - Parse response into estimated calories, protein, carbs, fat
  - User can correct estimates (aiEstimated flag on MealLog)
  - Photo stored locally (photoData on MealLog)

### FR-20: Modulo Nutricion — Hidratacion
- **Description**: Daily water intake tracker
- **Priority**: MVP
- **Details**:
  - Count glasses of water per day
  - Target configurable (default 8)
  - Reminders via local notifications

### FR-21: Modulo Habitos — Crear y Gestionar
- **Description**: Create habits with frequency, reminders, and tracking type
- **Priority**: MVP
- **Details**:
  - Name, Material/Lucide icon, hex color
  - Frequency: daily, weekly, custom (select specific days)
  - Target days: array of 1-7 (Mon-Sun)
  - Optional reminder time (local notification)
  - Binary or quantitative tracking (isQuantitative)
  - For quantitative: target quantity and unit (vasos, minutos, paginas)
  - Active/inactive toggle

### FR-22: Modulo Habitos — Check-in Diario
- **Description**: Simple daily check-in screen
- **Priority**: MVP
- **Details**:
  - List of today's habits
  - One tap = completed
  - For quantitative habits: enter quantity
  - Optional note per check-in

### FR-23: Modulo Habitos — Rachas (Streaks)
- **Description**: Consecutive day counter for habit consistency
- **Priority**: MVP
- **Details**:
  - Calculated property iterating completed logs backwards from today
  - Visual streak counter (Duolingo-style motivation)
  - Best streak tracking in statistics

### FR-24: Modulo Habitos — Calendario Visual
- **Description**: Calendar view showing habit completion
- **Priority**: MVP
- **Details**:
  - Color-coded: green (completed), red (missed), gray (not scheduled)
  - GitHub-contributions style visualization
  - Monthly view with day-by-day status

### FR-25: Modulo Habitos — Estadisticas
- **Description**: Habit performance statistics
- **Priority**: MVP
- **Details**:
  - Weekly/monthly completion percentage
  - Best streak
  - Most consistent habit
  - Completion trend over time

### FR-26: Modulo Sueno — Sleep Log Detallado
- **Description**: Detailed sleep tracking with interruption timeline
- **Priority**: Post-MVP (Phase 2)
- **Details**:
  - Record bedtime, estimated time to fall asleep (slider), wake-up time
  - Record interruptions: wake-up time, back-to-sleep time, reason
  - **Auto-detection**: If user unlocks phone during sleep hours, send notification asking "Te despertaste?" with quick-response options
  - **Retroactive logging**: Morning review screen with editable night timeline to add/edit interruptions not recorded in real-time
  - Sleep score (0-100): based on duration (40%), interruptions (25%), subjective quality (20%), time to fall asleep (15%)
  - Quality rating: 1-5 stars
  - Calculate total sleep minutes: bed time minus fall-asleep time minus awake interruption time
  - Health data import: auto-import sleep data from Apple Health (iOS) or Health Connect (Android) via `health` package (isFromHealthPlatform flag)

### FR-27: Modulo Sueno — Energy Check-ins
- **Description**: Quick energy level tracking throughout the day
- **Priority**: Post-MVP (Phase 2)
- **Details**:
  - 3 check-ins per day: morning, afternoon, night
  - 5-level scale (1-5)
  - Optional note
  - Correlations with sleep and other modules (via IA layer)

### FR-28: Modulo Bienestar Mental — Mood Check-in
- **Description**: Daily mood tracking with tags
- **Priority**: Post-MVP (Phase 2)
- **Details**:
  - 5 levels (1=muy mal, 5=excelente)
  - Predefined tags: Motivado, Enfocado, Tranquilo, Agradecido, Energetico, Estresado, Ansioso, Cansado, Triste, Frustrado, Productivo, Creativo, Social, Solitario, Aburrido
  - Multi-select tags
  - Visual mood calendar (color-coded by level, monthly view)

### FR-29: Modulo Bienestar Mental — Mini Journaling
- **Description**: Quick daily journal entry
- **Priority**: Post-MVP (Phase 2)
- **Details**:
  - 1-3 sentences, free text
  - Linked to the day's mood check-in
  - Searchable history

### FR-30: Modulo Bienestar Mental — Gratitud Rapida
- **Description**: Daily gratitude practice
- **Priority**: Post-MVP (Phase 2)
- **Details**:
  - Up to 3 gratitude items per day
  - Quick entry, one tap per item
  - History viewable

### FR-31: Modulo Bienestar Mental — Ejercicios de Respiracion
- **Description**: Guided breathing exercises with visual timer
- **Priority**: Post-MVP
- **Details**:
  - 4 types: Box Breathing (4-4-4-4), 4-7-8, Respiracion Calmada (4-6), Energizante (2-2)
  - Animated visual timer
  - Session duration tracking
  - Completion flag

### FR-32: Life Goals — Metas Unificadas
- **Description**: Cross-module goals with weighted sub-goals and milestones
- **Priority**: Post-MVP (Phase 2)
- **Details**:
  - Create goal with name, description, icon, color, optional deadline
  - Add sub-goals linked to any module (LifeModule enum)
  - Sub-goal types: amount, weight, body weight, streak, count, percentage, custom
  - Each sub-goal has a weight (0.0-1.0) — total progress is weighted average
  - Milestones with optional target dates
  - Link sub-goals to existing entities (habit ID, savings goal ID, exercise ID, etc.)
  - Dashboard showing all active goals with progress

### FR-33: LifeOS Intelligence — Capa de IA
- **Description**: AI-powered insights, photo analysis, and conversational assistant
- **Priority**: Post-MVP (Phase 3)
- **Details**:
  - **BYOK model**: User provides their own API key (OpenAI, Anthropic, Google Gemini)
  - API key stored securely via flutter_secure_storage (iOS Keychain / Android Keystore)
  - Data sent ONLY on explicit user action — never automatic
  - **When no API key configured**: IA features visible but grayed out with message "Configura tu API key para desbloquear"
  - **Features with API key**:
    - Photo analysis of food (vision model estimates macros)
    - OCR of receipts (categorize expenses + suggest food items purchased)
    - Automatic cross-module insights and correlations
    - Weekly/monthly Life Review (AI-generated summary)
    - Conversational assistant (natural language queries about user's data)
    - Goal suggestions based on patterns
    - Deadline predictions for active goals
  - Option to preview exactly what data will be sent before confirming
  - "Delete IA history" button in settings
  - Conversation history stored locally

### FR-34: Connect — Integraciones Externas
- **Description**: External service integrations
- **Priority**: Post-MVP (Phase 3)
- **Details**:
  - **Health data (bidirectional)**: Import sleep, steps, heart rate. Export workouts. Via `health` package (Apple Health on iOS, Health Connect on Android)
  - **Strava / fitness platforms**: Import cardio activities
  - **Open Food Facts API**: Barcode scanning for nutritional data
  - **Device calendar**: Read events, link with habits/goals. Via `device_calendar` package (Apple Calendar on iOS, Google Calendar on Android)
  - **Voice assistants**: Siri Shortcuts (iOS) / Google Assistant Routines (Android) for voice data entry (platform channels, post-MVP)
  - **Exchangerate API**: Real-time currency conversion (post-MVP multi-currency)
  - **Export**: CSV/PDF/JSON for any module's data + full database backup (JSON)
  - **Import**: Migration from MyFitnessPal, YNAB, Habitica (CSV) + restore from JSON backup
  - **Markdown export**: Weekly summaries to Obsidian/Notion

### FR-35: Widgets + Live Activities
- **Description**: Home screen widgets, persistent notifications, wearable companions
- **Priority**: Post-MVP (Phase 4)
- **Details**:
  - **Home screen widgets (both platforms via `home_widget`)**: Balance financiero (small), Habitos del dia (medium, interactive checkboxes), Proximo workout (small), Sueno anoche (small), Macros del dia (medium), Resumen LifeOS (large)
  - **iOS Lock screen widgets**: Gasto del dia, Habitos pendientes, Sleep score (via platform channel to WidgetKit)
  - **Active session indicators**: Workout timer (iOS: Dynamic Island/Live Activity via platform channel; Android: persistent foreground notification), Breathing exercise, Goal near completion (>=90%)
  - **Wearable companions (post-MVP)**: Apple Watch (iOS, via platform channel to WatchKit) / Wear OS (Android, via platform channel). Features: Gym timer, habit check-in, mood check-in

### FR-36: Day Score
- **Description**: Daily life score with customizable module weights
- **Priority**: Post-MVP (Phase 4)
- **Details**:
  - Score 0-100, calculated from all active modules
  - User configures weight per module (default: Finanzas 20%, Gym 20%, Habitos 20%, Nutricion 15%, Sueno 15%, Bienestar 10%)
  - Breakdown per module with details
  - Timeline of daily scores for trend visualization

### FR-37: Life Review
- **Description**: AI-generated weekly/monthly review
- **Priority**: Post-MVP (Phase 4)
- **Details**:
  - Configurable schedule (default: every Sunday)
  - What went well, what dropped, new patterns detected
  - Comparison with previous period across all modules
  - Concrete suggestions for next period
  - Requires IA layer (API key)

### FR-38: Time Machine
- **Description**: Compare current self with past self
- **Priority**: Post-MVP (Phase 4)
- **Details**:
  - Compare at 1, 3, 6, 12 month intervals
  - Side-by-side view: finances, body, habits, sleep
  - LifeSnapshot model: monthly/quarterly/yearly automated snapshots of key metrics
  - AI-generated comparison summary (requires API key)

### FR-39: Onboarding
- **Description**: Guided welcome flow for new users
- **Priority**: MVP
- **Details**:
  - Collect: user name, primary objectives, modules of interest
  - Language selection (Spanish/English)
  - Currency selection (default COP)
  - Brief tour of main features
  - Optionally configure first habit, first budget category

### FR-40: Notificaciones Locales
- **Description**: Local push notifications for reminders and alerts
- **Priority**: MVP
- **Details**:
  - Habit reminders at user-selected times
  - Budget threshold alerts (80% and 100%)
  - Water intake reminders
  - Recurring transaction notifications
  - Sleep interruption detection notifications
  - All notifications local — no server required

---

## 4. Non-Functional Requirements

### NFR-01: Performance
- App launch time: < 2 seconds on mid-range devices (iPhone 12+ / Pixel 6+ equivalent)
- Transaction recording: < 500ms from tap to saved
- Drift query response: < 100ms for common queries
- Chart rendering: < 1 second for up to 1 year of data
- Memory usage: < 200MB in active use (Flutter baseline is higher than native)

### NFR-02: Data Storage
- **Primary**: Drift (SQLite-backed, local, type-safe, reactive)
- **Sync**: Local-only for v1.0 with manual export/import (JSON backup). Cloud sync (Firebase/Supabase) as post-MVP optional feature
- **Security**: Biometric lock (Face ID / Touch ID on iOS, Fingerprint / Face Unlock on Android) via local_auth package
- **API keys**: Stored securely via flutter_secure_storage (iOS Keychain / Android Keystore)
- **Data deletion**: When app is uninstalled, all local data is permanently removed. Exported backups persist wherever the user saved them

### NFR-03: Accessibility (WCAG 2.1 AA)
- Full VoiceOver support for all screens
- Dynamic Type support (all text scales)
- Reduce Motion support (disable animations)
- High contrast color alternatives
- Minimum touch target size: 44x44 points
- Meaningful accessibility labels on all interactive elements
- Color not used as sole means of conveying information
- Focus management for modal sheets and navigation

### NFR-04: Localization
- Spanish and English from v1.0
- All user-facing strings in ARB files (Flutter intl)
- Date, currency, and number formatting respects device locale via intl package
- Right-to-left (RTL) layout support not required for v1.0

### NFR-05: Offline Support
- App is fully functional offline (local Drift database)
- No cloud sync in v1.0 — fully local
- Exercise library download requires one-time internet connection on first launch
- IA features require internet connection (API calls)
- Barcode scanning (Open Food Facts) requires internet
- Export/import backup works offline (file-based)

### NFR-06: Battery and Resources
- Background processing limited to:
  - Recurring transaction generation (via background task scheduling)
  - Local notification scheduling
  - Active workout foreground service (Android) / background audio session (iOS)
- No cloud sync in v1.0 — no background network usage
- No continuous background location tracking
- No continuous network polling

### NFR-07: Data Integrity
- Drift database transactions for all write operations
- Cascade and nullify delete rules per model relationships (defined in Drift table definitions)
- No orphaned records
- JSON backup export includes schema version for forward compatibility

### NFR-08: Security (See Extension Rules for Full Details)
- Biometric authentication via local_auth package (Face ID / Touch ID on iOS, Fingerprint / Face Unlock on Android)
- Secure storage for API keys via flutter_secure_storage (iOS Keychain / Android Keystore)
- No PII in logs
- Input validation on all user inputs
- No hardcoded credentials
- Structured error handling — no stack traces to users
- See Security Extension (SECURITY-01 through SECURITY-15) for comprehensive rules

### NFR-09: Testing (See Extension Rules for Full Details)
- Unit tests for all ViewModels and business logic
- Property-based tests for data transformations, serialization, and invariants
- UI tests for critical user flows (add transaction, start workout, check-in habit)
- See PBT Extension (PBT-01 through PBT-10) for comprehensive testing rules

---

## 5. Technology Stack

### Core Framework
| Component | Technology | Justification |
|---|---|---|
| Framework | Flutter (Dart) | Cross-platform iOS + Android from single codebase |
| State Management | Riverpod | Type-safe, compile-checked, excellent async support, Notifiers map to MVVM ViewModels |
| Database | Drift (SQLite) | Type-safe SQL, reactive streams, complex relations, migrations |
| Navigation | go_router | Declarative routing, deep linking, nested navigation |
| Localization | intl + ARB files | Flutter standard i18n, ICU message format |

### Feature Packages
| Component | Package | Purpose |
|---|---|---|
| Charts | fl_chart | Rich, customizable charts (pie, bar, line) |
| Notifications | flutter_local_notifications | Local push notifications on both platforms |
| Biometrics | local_auth | Face ID, Touch ID, fingerprint, face unlock |
| OCR | google_mlkit_text_recognition | Receipt text recognition (iOS Vision + Android ML Kit) |
| Health | health | Apple Health (iOS) + Health Connect (Android) |
| Barcode | mobile_scanner | Camera-based barcode scanning |
| Secure Storage | flutter_secure_storage | API keys (iOS Keychain / Android Keystore) |
| Home Widgets | home_widget | Home screen widgets on both platforms |

### Design System
| Component | Choice | Replaces |
|---|---|---|
| Design Language | Custom dark theme (LifeOS identity) | N/A — not Material or Cupertino |
| Titles font | Inter Bold/Heavy | SF Pro Display |
| Body font | Inter Regular | SF Pro Text |
| Mono font | JetBrains Mono | SF Mono |
| Icons | Material Icons + Lucide/Phosphor | SF Symbols |

### Platform Targets
| Platform | Minimum Version |
|---|---|
| iOS | 16.0+ |
| Android | API 26+ (Android 8.0+) |

### Platform Feature Mapping
| Feature | iOS | Android | Mechanism |
|---|---|---|---|
| Health Data | Apple Health | Health Connect | `health` package |
| Biometrics | Face ID / Touch ID | Fingerprint / Face Unlock | `local_auth` package |
| Secure Storage | Keychain | Android Keystore | `flutter_secure_storage` |
| Home Widgets | WidgetKit | Android Widgets | `home_widget` package |
| Live Activity | Dynamic Island | Persistent notification + foreground service | Platform channels |
| Watch | Apple Watch | Wear OS | Platform channels (post-MVP) |
| Voice Assistant | Siri Shortcuts | Google Assistant | Platform channels (post-MVP) |
| OCR | Vision framework | ML Kit | `google_mlkit_text_recognition` |
| Barcode | AVFoundation | CameraX/ML Kit | `mobile_scanner` |
| Calendar | Apple Calendar | Google Calendar | `device_calendar` package |

### External APIs (Optional, user-configured)
| API | Purpose | Cost |
|---|---|---|
| OpenAI / Anthropic / Google Gemini | IA layer (BYOK) | User pays their own usage |
| Open Food Facts | Barcode nutritional data | Free, open source |
| Exchangerate API | Currency conversion | Free tier available |

### Package Philosophy
**Pragmatic**: Use well-maintained, popular packages (>500 likes on pub.dev, recent updates) when they save significant time. Write custom code for simple features. Avoid obscure or unmaintained packages.

---

## 6. Data Architecture

### 6.1 Drift Tables Summary

| Module | Models |
|---|---|
| Finance | Transaction, Category, Budget, SavingsGoal, RecurringTransaction |
| Gym | Exercise, Routine, RoutineExercise, Workout, WorkoutSet, BodyMeasurement |
| Nutrition | FoodItem, MealLog, MealLogItem, MealTemplate, MealTemplateItem, NutritionGoal, WaterLog |
| Habits | Habit, HabitLog |
| Sleep | SleepLog, SleepInterruption, EnergyLog |
| Mental | MoodLog, BreathingSession |
| Goals | LifeGoal, SubGoal, GoalMilestone |
| Intelligence | AIConfiguration, AIConversation, AIMessage |
| Day Score | DayScore, ScoreComponent, DayScoreConfig, LifeSnapshot |

### 6.2 Data Sync Strategy
- Local-only for v1.0 (Drift/SQLite)
- Manual export/import via JSON backup files
- Cloud sync (Firebase/Supabase) planned as post-MVP optional feature

### 6.3 Default Currency
- **COP (Colombian Peso)** as default
- User can change during onboarding
- Multi-currency with exchange rate API in post-MVP

---

## 7. Design Requirements

### 7.1 Color Palette
| Purpose | Color | Hex |
|---|---|---|
| Finance module | Green | #10B981 |
| Gym module | Amber | #F59E0B |
| Habits module | Purple | #8B5CF6 |
| Cross features | Pink | #EC4899 |
| Background primary (dark) | Dark navy | #0A0A0F |
| Background secondary | Dark blue | #111122 |
| Card background | Dark purple | #1A1A2E |
| Text primary | Light gray | #E5E5E5 |
| Text secondary | Medium gray | #9CA3AF |
| Success | Green | #22C55E |
| Warning | Amber | #F59E0B |
| Danger | Red | #EF4444 |
| Info | Blue | #3B82F6 |

### 7.2 Typography
- Titles: Inter Bold/Heavy (replaces SF Pro Display)
- Body: Inter Regular (replaces SF Pro Text)
- Numbers/Amounts: JetBrains Mono (replaces SF Mono, digit alignment)
- Sizes: 28pt (titles), 17pt (body), 13pt (caption), 11pt (overline)

### 7.3 UX Principles
1. **One-handed use**: Everything reachable with thumb (bottom sheet > modal)
2. **Haptic feedback**: Subtle vibrations on important actions
3. **Swipe actions**: Swipe to edit/delete
4. **Minimal taps**: Record expense in max 3 taps
5. **Smooth animations**: Flutter implicit/explicit animations with spring curves
6. **Accessibility**: Full WCAG 2.1 AA compliance

### 7.4 Iconography
- **Material Icons** (bundled with Flutter) as primary icon set
- **Lucide Icons** or **Phosphor Icons** for additional/custom icons
- Custom SVG icons where needed
- Replaces SF Symbols (Apple-only)

### 7.5 Theme Support
- Dark mode (primary) and light mode
- Toggle: manual + auto (system setting)

---

## 8. Constraints and Assumptions

### 8.1 Constraints
- Flutter (Dart) cross-platform — single codebase for iOS and Android
- Pragmatic package usage — well-maintained packages only
- iOS 16+ / Android API 26+
- $0 infrastructure cost (all local, no cloud services in v1.0)
- No server-side components
- No user accounts or authentication server — biometric lock only
- Custom design system (not Material or Cupertino)

### 8.2 Assumptions
- User has iPhone (iOS 16+) or Android phone (API 26+)
- Exercise library hosted at a stable URL for first-launch download
- Open Food Facts API remains free and available
- AI providers (OpenAI, Anthropic, Gemini) maintain current API compatibility
- Flutter and key packages (Riverpod, Drift, fl_chart, etc.) remain actively maintained
- Google Fonts (Inter, JetBrains Mono) remain freely available

---

## 9. Success Criteria

### 9.1 Technical
- App runs without crashes on iOS 16+ and Android API 26+
- All Drift tables persist and query correctly on both platforms
- All 4 MVP modules functional and tested on both iOS and Android
- Full WCAG 2.1 AA accessibility compliance
- All security extension rules (SECURITY-01 to SECURITY-15) satisfied where applicable
- All PBT extension rules (PBT-01 to PBT-10) satisfied where applicable
- JSON backup export/import works correctly on both platforms

### 9.2 User Experience
- New user can register first transaction in < 30 seconds after onboarding
- New user can start first workout in < 1 minute
- Habit check-in takes < 5 seconds
- Meal logging takes < 15 seconds with templates
- UI looks and behaves identically on iOS and Android (custom design system)

### 9.3 Quality
- Unit test coverage: > 80% on Notifiers (ViewModels) and business logic
- Widget tests for critical UI components
- Integration tests for critical user flows
- Zero critical bugs at store submission
- App Store and Google Play approval on first submission

---

## 10. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Flutter package abandonment (Drift, Riverpod, etc.) | High | Choose packages with active maintainers, large community, and corporate backing. Pin versions |
| Exercise library download fails on first launch | Medium | Bundle minimal set locally, download full library as enhancement |
| Bank notification parsing varies by bank and platform | High | Start with 2-3 major Colombian banks, make parser configurable. Android has better notification access than iOS |
| AI API costs may surprise users (BYOK) | Low | Show estimated cost before sending request, set token limits |
| Platform-specific features diverge over time | Medium | Abstract platform features behind interfaces, use platform channels cleanly |
| Google Play and App Store policy differences | Medium | Review both store policies during design, avoid features that violate either |
| Flutter performance on low-end Android devices | Medium | Profile on budget devices, optimize list rendering with lazy builders, minimize rebuilds |
| Drift migration complexity as schema evolves | Medium | Design migration strategy from v1, test migrations thoroughly, include schema version in backups |

---

## 11. Extension Configuration

### Security Extension
- **Status**: Enabled (Full enforcement)
- **Rules**: SECURITY-01 through SECURITY-15
- **Applicability**: Rules involving network infrastructure (SECURITY-02, SECURITY-04, SECURITY-07) are N/A for this local-first app but will apply when IA API calls and external integrations are implemented. Security rules apply equally to both iOS and Android via cross-platform packages (flutter_secure_storage, local_auth)

### Property-Based Testing Extension
- **Status**: Enabled (Full enforcement)
- **Rules**: PBT-01 through PBT-10
- **Framework**: Dart `test` package + `glados` or `randomized_testing` for property-based testing in Dart (to be determined in NFR Requirements stage)

---

*Document generated as part of AI-DLC workflow — 2026-04-03*
*Updated for Flutter cross-platform migration — 2026-04-03*
*Based on LifeOS-Spec.md, platform-change-questions.md decisions, and docs/plans/2026-04-03-lifeos-expansion-design.md*