# LifeOS — Especificación Completa para iOS

> **App Todo-en-1: Finanzas + Gimnasio + Nutrición + Hábitos + Sueño + Bienestar Mental**
> Documento de referencia para desarrollo con Claude Code

---

## 1. Visión General

**Nombre:** LifeOS
**Plataformas:** iOS 16+ / Android API 26+ (Android 8.0+)
**Framework:** Flutter (Dart)
**State Management:** Riverpod
**Patrón:** MVVM (Notifiers = ViewModels)
**Almacenamiento:** Drift (SQLite, local) + Export/Import JSON backup
**Costo de infra:** $0/mes (todo local)

### Objetivo
Una app cross-platform (iOS + Android) con Flutter que centralice el control de finanzas personales, rutinas de gimnasio, nutrición, seguimiento de hábitos, calidad de sueño y bienestar mental en una sola interfaz limpia y rápida. Con capa de IA opcional (BYOK — Bring Your Own Key), metas unificadas cross-módulo, integraciones externas y widgets inteligentes. Sin servidores propios, sin suscripciones, los datos viven en el dispositivo del usuario.

### Prioridad de Módulos
1. **Finanzas Personales** (P1 — Máxima)
2. **Gimnasio & Fitness** (P2 — Alta)
3. **Nutrición** (P2.5 — Alta)
4. **Hábitos & Productividad** (P3 — Normal)
5. **Sueño + Energía** (P3 — Normal)
6. **Bienestar Mental** (P3.5 — Normal)
7. **Life Goals (Metas Unificadas)** (P3 — Normal)
8. **LifeOS Intelligence (IA)** (P4 — Baja)
9. **Connect (Integraciones)** (P4 — Baja)
10. **Widgets + Live Activities** (P4 — Baja)
11. **Day Score + Life Review + Time Machine** (P5 — Futura)

---

## 2. Stack Tecnológico

| Componente | Tecnología | Justificación |
|---|---|---|
| Framework | Flutter (Dart) | Cross-platform iOS + Android desde un solo codebase |
| State Management | Riverpod | Type-safe, compile-checked, Notifiers = ViewModels |
| Base de datos | Drift (SQLite) | Type-safe SQL, reactive streams, migraciones robustas |
| Navegación | go_router | Declarativo, deep linking, navegación anidada |
| Gráficas | fl_chart | Charts ricos y personalizables (pie, bar, line) |
| Notificaciones | flutter_local_notifications | Notificaciones locales en ambas plataformas |
| Biometría | local_auth | Face ID / Touch ID (iOS) + Fingerprint / Face Unlock (Android) |
| OCR | google_mlkit_text_recognition | Reconocimiento de texto (Vision iOS + ML Kit Android) |
| Salud | health | Apple Health (iOS) + Health Connect (Android) |
| Backup | Export/Import JSON local | Backup manual exportable, $0 costo |
| Barcode | mobile_scanner | Escaneo de códigos de barras en ambas plataformas |
| Secure Storage | flutter_secure_storage | API keys (iOS Keychain / Android Keystore) |
| Home Widgets | home_widget | Widgets de home screen en ambas plataformas |
| Watch | Platform channels | Apple Watch / Wear OS (post-MVP) |
| Localización | intl + ARB files | Español + Inglés desde v1.0 |
| Target iOS | 16.0+ | Amplio soporte de dispositivos |
| Target Android | API 26+ (8.0+) | Cubre 95%+ de dispositivos Android activos |

---

## 3. Arquitectura

### 3.1 Patrón MVVM con Riverpod

```
┌──────────────────────────────────────────────────┐
│              📱 Flutter Widgets (UI)              │
│  BottomNav → Dashboard | Finanzas | Gym | Más    │
└──────────────────────┬───────────────────────────┘
                       │ Riverpod providers (watch/read)
┌──────────────────────▼───────────────────────────┐
│          ⚡ Notifiers (ViewModels)                 │
│  FinanceNotifier | GymNotifier | NutritionNotifier│
│  HabitsNotifier | SleepNotifier | MentalNotifier  │
│  GoalsNotifier | DayScoreNotifier | AINotifier    │
└──────────────────────┬───────────────────────────┘
                       │ Drift queries (reactive streams)
┌──────────────────────▼───────────────────────────┐
│           🗄️ Drift Tables (SQLite)                │
│  Transactions | Workouts | Exercises | Habits    │
│  FoodItems | MealLogs | SleepLogs | MoodLogs    │
│  LifeGoals | DayScores | AIConversations         │
└──────────┬───────────┬───────────────┬───────────┘
           │           │               │
    ┌──────▼──┐  ┌─────▼──────┐  ┌────▼──────┐
    │💾 SQLite │  │📦 JSON     │  │❤️ Health   │
    │ (local)  │  │ (backup)   │  │ (sync)    │
    └─────────┘  └────────────┘  └───────────┘
```

### 3.2 Estructura de Carpetas

```
life_os/
├── lib/
│   ├── main.dart                       # Entry point
│   ├── app.dart                        # MaterialApp / tema / router
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart         # Paleta de colores custom
│   │   │   ├── app_typography.dart     # Tipografía (Inter, JetBrains Mono)
│   │   │   └── app_constants.dart      # Constantes globales
│   │   ├── database/
│   │   │   ├── app_database.dart       # Drift database definition
│   │   │   ├── app_database.g.dart     # Generated code
│   │   │   └── tables/                 # Drift table definitions
│   │   ├── extensions/
│   │   │   ├── date_extensions.dart
│   │   │   ├── double_currency.dart
│   │   │   └── context_extensions.dart
│   │   ├── router/
│   │   │   └── app_router.dart         # go_router configuration
│   │   ├── services/
│   │   │   ├── notification_service.dart
│   │   │   ├── haptic_service.dart
│   │   │   ├── secure_storage_service.dart
│   │   │   └── backup_service.dart     # JSON export/import
│   │   └── widgets/
│   │       ├── stat_card.dart
│   │       ├── progress_ring.dart
│   │       ├── chart_card.dart
│   │       └── empty_state_view.dart
│
│   ├── features/
│   │   ├── dashboard/
│   │   │   ├── presentation/           # Screens + widgets
│   │   │   └── providers/              # Riverpod notifiers
│   │   │
│   │   ├── finance/
│   │   │   ├── data/                   # Drift DAOs, repositories
│   │   │   ├── domain/                 # Enums, value objects
│   │   │   ├── presentation/           # Screens + widgets
│   │   │   └── providers/              # Riverpod notifiers
│   │   │
│   │   ├── gym/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   ├── presentation/
│   │   │   └── providers/
│   │   │
│   │   ├── nutrition/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   ├── presentation/
│   │   │   └── providers/
│   │   │
│   │   ├── habits/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   ├── presentation/
│   │   │   └── providers/
│   │   │
│   │   ├── sleep/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   ├── presentation/
│   │   │   └── providers/
│   │   │
│   │   ├── mental/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   ├── presentation/
│   │   │   └── providers/
│   │   │
│   │   ├── goals/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   ├── presentation/
│   │   │   └── providers/
│   │   │
│   │   ├── intelligence/
│   │   │   ├── data/
│   │   │   │   ├── ai_service.dart
│   │   │   │   ├── openai_provider.dart
│   │   │   │   ├── anthropic_provider.dart
│   │   │   │   └── gemini_provider.dart
│   │   │   ├── domain/
│   │   │   ├── presentation/
│   │   │   └── providers/
│   │   │
│   │   ├── day_score/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   ├── presentation/
│   │   │   └── providers/
│   │   │
│   │   └── onboarding/
│   │       ├── presentation/
│   │       └── providers/
│   │
│   └── l10n/                           # Localization ARB files
│       ├── app_es.arb                  # Spanish
│       └── app_en.arb                  # English
│
├── assets/
│   ├── fonts/                          # Inter, JetBrains Mono
│   ├── icons/                          # Custom SVG icons
│   ├── exercise_data.json              # Downloaded on first launch
│   └── default_categories.json         # Default finance categories
│
├── android/                            # Android native (widgets, platform channels)
├── ios/                                # iOS native (widgets, platform channels)
├── test/                               # Unit + widget tests
├── integration_test/                   # Integration tests
│
├── pubspec.yaml                        # Dependencies
└── analysis_options.yaml               # Lint rules
```

### 3.3 Navegación

```dart
// app_router.dart — go_router con BottomNavigationBar
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),
    BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Finanzas'),
    BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Gym'),
    BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Nutrición'),
    BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Hábitos'),
  ],
)
// Módulos adicionales accesibles desde Dashboard o menú "Más"
```

---

## 4. Modelos de Datos (SwiftData)

### 4.1 Módulo Finanzas

```swift
import SwiftData

@Model
class Transaction {
    var id: UUID
    var amount: Double
    var type: TransactionType        // .income | .expense
    var category: Category?
    var note: String
    var date: Date
    var isRecurring: Bool
    var createdAt: Date

    init(amount: Double, type: TransactionType, category: Category? = nil,
         note: String = "", date: Date = .now) {
        self.id = UUID()
        self.amount = amount
        self.type = type
        self.category = category
        self.note = note
        self.date = date
        self.isRecurring = false
        self.createdAt = .now
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case income = "Ingreso"
    case expense = "Gasto"
}

@Model
class Category {
    var id: UUID
    var name: String
    var icon: String               // SF Symbol name
    var color: String              // Hex color
    var isDefault: Bool
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]

    init(name: String, icon: String, color: String, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.isDefault = isDefault
        self.transactions = []
    }
}

@Model
class Budget {
    var id: UUID
    var category: Category?
    var limit: Double
    var period: BudgetPeriod        // .monthly | .weekly
    var alertThreshold: Double      // 0.8 = alert at 80%

    init(category: Category?, limit: Double, period: BudgetPeriod = .monthly) {
        self.id = UUID()
        self.category = category
        self.limit = limit
        self.period = period
        self.alertThreshold = 0.8
    }
}

enum BudgetPeriod: String, Codable {
    case weekly = "Semanal"
    case monthly = "Mensual"
}

@Model
class SavingsGoal {
    var id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?
    var icon: String
    var createdAt: Date

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }

    init(name: String, targetAmount: Double, deadline: Date? = nil, icon: String = "star") {
        self.id = UUID()
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = 0
        self.deadline = deadline
        self.icon = icon
        self.createdAt = .now
    }
}

@Model
class RecurringTransaction {
    var id: UUID
    var amount: Double
    var type: TransactionType
    var category: Category?
    var note: String
    var frequency: RecurrenceFrequency  // .monthly | .weekly | .biweekly
    var dayOfMonth: Int?                // 1-31 para monthly
    var isActive: Bool
    var lastProcessed: Date?

    init(amount: Double, type: TransactionType, category: Category? = nil,
         note: String = "", frequency: RecurrenceFrequency = .monthly, dayOfMonth: Int? = 1) {
        self.id = UUID()
        self.amount = amount
        self.type = type
        self.category = category
        self.note = note
        self.frequency = frequency
        self.dayOfMonth = dayOfMonth
        self.isActive = true
        self.lastProcessed = nil
    }
}

enum RecurrenceFrequency: String, Codable {
    case weekly = "Semanal"
    case biweekly = "Quincenal"
    case monthly = "Mensual"
}
```

### 4.2 Módulo Gimnasio

```swift
@Model
class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var secondaryMuscles: [MuscleGroup]
    var equipment: Equipment
    var instructions: String
    var isCustom: Bool

    init(name: String, muscleGroup: MuscleGroup, secondaryMuscles: [MuscleGroup] = [],
         equipment: Equipment = .barbell, instructions: String = "", isCustom: Bool = false) {
        self.id = UUID()
        self.name = name
        self.muscleGroup = muscleGroup
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.instructions = instructions
        self.isCustom = isCustom
    }
}

enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "Pecho"
    case back = "Espalda"
    case shoulders = "Hombros"
    case biceps = "Bíceps"
    case triceps = "Tríceps"
    case forearms = "Antebrazos"
    case quadriceps = "Cuádriceps"
    case hamstrings = "Isquiotibiales"
    case glutes = "Glúteos"
    case calves = "Pantorrillas"
    case abs = "Abdominales"
    case cardio = "Cardio"
    case fullBody = "Cuerpo Completo"
}

enum Equipment: String, Codable, CaseIterable {
    case barbell = "Barra"
    case dumbbell = "Mancuernas"
    case machine = "Máquina"
    case cable = "Cable"
    case bodyweight = "Peso Corporal"
    case kettlebell = "Kettlebell"
    case band = "Banda"
    case other = "Otro"
}

@Model
class Routine {
    var id: UUID
    var name: String
    var exercises: [RoutineExercise]
    var createdAt: Date
    var lastUsed: Date?

    init(name: String, exercises: [RoutineExercise] = []) {
        self.id = UUID()
        self.name = name
        self.exercises = exercises
        self.createdAt = .now
    }
}

@Model
class RoutineExercise {
    var id: UUID
    var exercise: Exercise?
    var targetSets: Int
    var targetReps: Int
    var restSeconds: Int
    var order: Int

    init(exercise: Exercise, targetSets: Int = 3, targetReps: Int = 10,
         restSeconds: Int = 90, order: Int = 0) {
        self.id = UUID()
        self.exercise = exercise
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.restSeconds = restSeconds
        self.order = order
    }
}

@Model
class Workout {
    var id: UUID
    var routine: Routine?
    var date: Date
    var duration: TimeInterval      // En segundos
    var sets: [WorkoutSet]
    var notes: String
    var isCompleted: Bool

    var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    init(routine: Routine? = nil, date: Date = .now) {
        self.id = UUID()
        self.routine = routine
        self.date = date
        self.duration = 0
        self.sets = []
        self.notes = ""
        self.isCompleted = false
    }
}

@Model
class WorkoutSet {
    var id: UUID
    var exercise: Exercise?
    var setNumber: Int
    var weight: Double             // En kg
    var reps: Int
    var isPersonalRecord: Bool
    var isWarmup: Bool
    var completedAt: Date?

    init(exercise: Exercise? = nil, setNumber: Int, weight: Double = 0,
         reps: Int = 0, isWarmup: Bool = false) {
        self.id = UUID()
        self.exercise = exercise
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.isPersonalRecord = false
        self.isWarmup = isWarmup
    }
}

@Model
class BodyMeasurement {
    var id: UUID
    var date: Date
    var weight: Double?            // kg
    var chest: Double?             // cm
    var waist: Double?
    var hips: Double?
    var leftArm: Double?
    var rightArm: Double?
    var leftThigh: Double?
    var rightThigh: Double?
    var bodyFat: Double?           // porcentaje
    var note: String

    init(date: Date = .now) {
        self.id = UUID()
        self.date = date
        self.note = ""
    }
}
```

### 4.3 Módulo Hábitos

```swift
@Model
class Habit {
    var id: UUID
    var name: String
    var icon: String               // SF Symbol
    var color: String              // Hex
    var frequency: HabitFrequency
    var targetDays: [Int]          // 1=Lun...7=Dom (para weekly)
    var reminderTime: Date?
    var isQuantitative: Bool
    var targetQuantity: Double?    // Ej: 8 vasos, 30 minutos
    var unit: String?              // "vasos", "minutos", "páginas"
    var isActive: Bool
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \HabitLog.habit)
    var logs: [HabitLog]

    var currentStreak: Int {
        // Calcular racha actual iterando logs hacia atrás
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: .now)
        let sortedLogs = logs.filter { $0.isCompleted }
            .sorted { $0.date > $1.date }

        for log in sortedLogs {
            let logDate = Calendar.current.startOfDay(for: log.date)
            if logDate == checkDate {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    init(name: String, icon: String = "circle.fill", color: String = "#10B981",
         frequency: HabitFrequency = .daily) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.frequency = frequency
        self.targetDays = [1, 2, 3, 4, 5, 6, 7]
        self.isQuantitative = false
        self.isActive = true
        self.createdAt = .now
        self.logs = []
    }
}

enum HabitFrequency: String, Codable {
    case daily = "Diario"
    case weekly = "Semanal"
    case custom = "Personalizado"
}

@Model
class HabitLog {
    var id: UUID
    var habit: Habit?
    var date: Date
    var isCompleted: Bool
    var quantity: Double?          // Para hábitos cuantitativos
    var note: String

    init(habit: Habit, date: Date = .now, isCompleted: Bool = true) {
        self.id = UUID()
        self.habit = habit
        self.date = date
        self.isCompleted = isCompleted
        self.note = ""
    }
}
```

### 4.4 Módulo Nutrición

```swift
@Model
class FoodItem {
    var id: UUID
    var name: String
    var calories: Double          // por porción
    var protein: Double           // gramos
    var carbs: Double             // gramos
    var fat: Double               // gramos
    var servingSize: Double       // gramos
    var servingUnit: String       // "g", "ml", "unidad"
    var barcode: String?
    var isCustom: Bool
    var isFavorite: Bool

    init(name: String, calories: Double, protein: Double,
         carbs: Double, fat: Double, servingSize: Double = 100,
         servingUnit: String = "g") {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.isCustom = false
        self.isFavorite = false
    }
}

@Model
class MealLog {
    var id: UUID
    var date: Date
    var mealType: MealType        // .breakfast | .lunch | .dinner | .snack
    var items: [MealLogItem]
    var photoData: Data?          // Foto del plato (opcional)
    var aiEstimated: Bool         // Si los macros fueron estimados por IA
    var note: String

    var totalCalories: Double {
        items.reduce(0) { $0 + $1.calories }
    }
    var totalProtein: Double {
        items.reduce(0) { $0 + $1.protein }
    }
    var totalCarbs: Double {
        items.reduce(0) { $0 + $1.carbs }
    }
    var totalFat: Double {
        items.reduce(0) { $0 + $1.fat }
    }

    init(date: Date = .now, mealType: MealType = .lunch) {
        self.id = UUID()
        self.date = date
        self.mealType = mealType
        self.items = []
        self.aiEstimated = false
        self.note = ""
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Desayuno"
    case lunch = "Almuerzo"
    case dinner = "Cena"
    case snack = "Snack"
}

@Model
class MealLogItem {
    var id: UUID
    var foodItem: FoodItem?
    var quantity: Double           // Cantidad de porciones
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double

    init(foodItem: FoodItem, quantity: Double = 1.0) {
        self.id = UUID()
        self.foodItem = foodItem
        self.quantity = quantity
        self.calories = foodItem.calories * quantity
        self.protein = foodItem.protein * quantity
        self.carbs = foodItem.carbs * quantity
        self.fat = foodItem.fat * quantity
    }
}

@Model
class MealTemplate {
    var id: UUID
    var name: String              // "Mi desayuno de siempre"
    var items: [MealTemplateItem]
    var lastUsed: Date?

    init(name: String, items: [MealTemplateItem] = []) {
        self.id = UUID()
        self.name = name
        self.items = items
    }
}

@Model
class MealTemplateItem {
    var id: UUID
    var foodItem: FoodItem?
    var quantity: Double

    init(foodItem: FoodItem, quantity: Double = 1.0) {
        self.id = UUID()
        self.foodItem = foodItem
        self.quantity = quantity
    }
}

@Model
class NutritionGoal {
    var id: UUID
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var water: Int                // Vasos por día
    var isTrainingDay: Bool
    var trainingCalorieBoost: Double

    init(calories: Double = 2000, protein: Double = 150,
         carbs: Double = 250, fat: Double = 65, water: Int = 8) {
        self.id = UUID()
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.water = water
        self.isTrainingDay = false
        self.trainingCalorieBoost = 300
    }
}

@Model
class WaterLog {
    var id: UUID
    var date: Date
    var glasses: Int

    init(date: Date = .now, glasses: Int = 0) {
        self.id = UUID()
        self.date = date
        self.glasses = glasses
    }
}
```

### 4.5 Módulo Sueño + Energía

```swift
@Model
class SleepLog {
    var id: UUID
    var date: Date                    // Fecha del día
    var bedTime: Date                 // Hora de acostarse
    var estimatedFallAsleep: Int      // Minutos estimados en dormirse
    var wakeUpTime: Date              // Hora de levantarse definitivamente
    var interruptions: [SleepInterruption]
    var qualityRating: Int            // 1-5 estrellas
    var note: String
    var isFromHealthKit: Bool

    var totalSleepMinutes: Int {
        let totalBedMinutes = Int(wakeUpTime.timeIntervalSince(bedTime) / 60)
        let awakeMinutes = interruptions.reduce(0) { $0 + $1.durationMinutes }
        return totalBedMinutes - estimatedFallAsleep - awakeMinutes
    }

    var sleepScore: Double {
        var score = 0.0
        let hoursSlept = Double(totalSleepMinutes) / 60.0
        let durationScore = min(hoursSlept / 8.0, 1.0) * 40
        let interruptionPenalty = min(Double(interruptions.count) * 8.0, 25.0)
        let interruptionScore = 25.0 - interruptionPenalty
        let qualityScore = (Double(qualityRating) / 5.0) * 20
        let fallAsleepScore = max(15.0 - Double(estimatedFallAsleep) * 0.5, 0)
        score = durationScore + interruptionScore + qualityScore + fallAsleepScore
        return min(max(score, 0), 100)
    }

    init(date: Date = .now) {
        self.id = UUID()
        self.date = date
        self.bedTime = date
        self.estimatedFallAsleep = 15
        self.wakeUpTime = date
        self.interruptions = []
        self.qualityRating = 3
        self.note = ""
        self.isFromHealthKit = false
    }
}

@Model
class SleepInterruption {
    var id: UUID
    var wakeUpTime: Date
    var backToSleepTime: Date?
    var reason: String                // "Baño", "Ruido", "Sin razón"
    var wasAutoDetected: Bool

    var durationMinutes: Int {
        guard let backToSleep = backToSleepTime else { return 0 }
        return Int(backToSleep.timeIntervalSince(wakeUpTime) / 60)
    }

    init(wakeUpTime: Date = .now) {
        self.id = UUID()
        self.wakeUpTime = wakeUpTime
        self.wasAutoDetected = false
        self.reason = ""
    }
}

@Model
class EnergyLog {
    var id: UUID
    var date: Date
    var timeOfDay: TimeOfDay          // .morning | .afternoon | .night
    var level: Int                    // 1-5
    var note: String

    init(date: Date = .now, timeOfDay: TimeOfDay, level: Int = 3) {
        self.id = UUID()
        self.date = date
        self.timeOfDay = timeOfDay
        self.level = level
        self.note = ""
    }
}

enum TimeOfDay: String, Codable, CaseIterable {
    case morning = "Mañana"
    case afternoon = "Tarde"
    case night = "Noche"
}
```

#### Flujo de Registro de Sueño

```
NOCHE:
1. Usuario abre app → tap "Me voy a dormir" (registra hora)
2. Opcional: "Me tardo ~15 min en dormirme" (slider)
3. App entra en modo nocturno (pantalla oscura)

INTERRUPCIÓN (vía notificación):
4. Usuario desbloquea teléfono a las 3am
5. Notificación: "¿Te despertaste?" → [Sí] [No, solo revisé el teléfono]
6. Si "Sí" → queda registrado
7. Cuando vuelve a dormir → notificación o tap en widget

MAÑANA (registro retroactivo):
8. Usuario abre app → "¡Buenos días! Registra tu noche"
9. Timeline visual editable de la noche
10. Puede agregar interrupciones que no registró
11. Calidad subjetiva: 1-5 estrellas
12. Se calcula sleep score
```

### 4.6 Módulo Bienestar Mental

```swift
@Model
class MoodLog {
    var id: UUID
    var date: Date
    var level: Int                    // 1-5 (1=muy mal, 5=excelente)
    var tags: [String]                // ["estresado", "motivado", etc.]
    var journalEntry: String          // Mini diario opcional
    var gratitude: [String]           // Hasta 3 items de gratitud
    var note: String

    init(date: Date = .now, level: Int = 3) {
        self.id = UUID()
        self.date = date
        self.level = level
        self.tags = []
        self.journalEntry = ""
        self.gratitude = []
        self.note = ""
    }
}

@Model
class BreathingSession {
    var id: UUID
    var date: Date
    var type: BreathingType
    var durationSeconds: Int
    var completed: Bool

    init(type: BreathingType, durationSeconds: Int = 0) {
        self.id = UUID()
        self.date = .now
        self.type = type
        self.durationSeconds = durationSeconds
        self.completed = false
    }
}

enum BreathingType: String, Codable, CaseIterable {
    case boxBreathing = "Box Breathing"       // 4-4-4-4
    case breathing478 = "4-7-8"               // 4-7-8
    case calmBreathing = "Respiración Calmada" // 4-6
    case energizing = "Energizante"           // 2-2 rápida
}
```

#### Tags de Mood Predefinidos
```json
[
    "Motivado", "Enfocado", "Tranquilo", "Agradecido", "Energético",
    "Estresado", "Ansioso", "Cansado", "Triste", "Frustrado",
    "Productivo", "Creativo", "Social", "Solitario", "Aburrido"
]
```

### 4.7 Life Goals (Metas Unificadas)

```swift
@Model
class LifeGoal {
    var id: UUID
    var name: String
    var description: String
    var icon: String                  // SF Symbol
    var color: String                 // Hex
    var deadline: Date?
    var subGoals: [SubGoal]
    var isCompleted: Bool
    var createdAt: Date

    var progress: Double {
        guard !subGoals.isEmpty else { return 0 }
        let totalWeight = subGoals.reduce(0.0) { $0 + $1.weight }
        guard totalWeight > 0 else { return 0 }
        let weightedProgress = subGoals.reduce(0.0) { $0 + ($1.progress * $1.weight) }
        return weightedProgress / totalWeight
    }

    init(name: String, description: String = "", icon: String = "star",
         color: String = "#10B981", deadline: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.deadline = deadline
        self.subGoals = []
        self.isCompleted = false
        self.createdAt = .now
    }
}

@Model
class SubGoal {
    var id: UUID
    var name: String
    var module: LifeModule
    var targetType: GoalTargetType
    var targetValue: Double
    var currentValue: Double
    var weight: Double                // 0.0 - 1.0
    var linkedEntityId: UUID?

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1.0)
    }

    init(name: String, module: LifeModule, targetType: GoalTargetType,
         targetValue: Double, weight: Double = 1.0) {
        self.id = UUID()
        self.name = name
        self.module = module
        self.targetType = targetType
        self.targetValue = targetValue
        self.currentValue = 0
        self.weight = weight
    }
}

enum LifeModule: String, Codable, CaseIterable {
    case finance = "Finanzas"
    case gym = "Gym"
    case habits = "Hábitos"
    case nutrition = "Nutrición"
    case sleep = "Sueño"
    case mental = "Bienestar"
}

enum GoalTargetType: String, Codable {
    case amount = "Monto"
    case weight = "Peso"
    case bodyWeight = "Peso Corporal"
    case streak = "Racha"
    case count = "Cantidad"
    case percentage = "Porcentaje"
    case custom = "Personalizado"
}

@Model
class GoalMilestone {
    var id: UUID
    var goal: LifeGoal?
    var name: String
    var targetDate: Date?
    var isCompleted: Bool
    var completedAt: Date?

    init(name: String, targetDate: Date? = nil) {
        self.id = UUID()
        self.name = name
        self.targetDate = targetDate
        self.isCompleted = false
    }
}
```

### 4.8 LifeOS Intelligence (IA)

```swift
@Model
class AIConfiguration {
    var id: UUID
    var provider: AIProvider
    var apiKeyRef: String             // Referencia a Keychain, NUNCA el key directo
    var preferredModel: String        // "gpt-4o", "claude-sonnet", "gemini-pro"
    var isActive: Bool

    init(provider: AIProvider) {
        self.id = UUID()
        self.provider = provider
        self.apiKeyRef = ""
        self.preferredModel = ""
        self.isActive = false
    }
}

enum AIProvider: String, Codable, CaseIterable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case google = "Google Gemini"
}

@Model
class AIConversation {
    var id: UUID
    var date: Date
    var messages: [AIMessage]
    var module: String?

    init(module: String? = nil) {
        self.id = UUID()
        self.date = .now
        self.messages = []
        self.module = module
    }
}

@Model
class AIMessage {
    var id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date

    init(role: MessageRole, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = .now
    }
}

enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
}
```

#### Arquitectura de IA — Privacidad

- API Key almacenado en iOS Keychain (encriptado por hardware)
- Datos se envían SOLO cuando el usuario lo solicita explícitamente
- Opción de ver exactamente qué datos se enviarán antes de confirmar
- Historial de conversaciones almacenado localmente
- Botón "Borrar historial de IA" en configuración
- Proveedores soportados: OpenAI, Anthropic, Google Gemini

### 4.9 Day Score + Time Machine

```swift
@Model
class DayScore {
    var id: UUID
    var date: Date
    var score: Double                 // 0-100
    var breakdown: [ScoreComponent]

    init(date: Date = .now) {
        self.id = UUID()
        self.date = date
        self.score = 0
        self.breakdown = []
    }
}

@Model
class ScoreComponent {
    var id: UUID
    var module: LifeModule
    var weight: Double
    var score: Double
    var details: String

    init(module: LifeModule, weight: Double, score: Double = 0) {
        self.id = UUID()
        self.module = module
        self.weight = weight
        self.score = score
        self.details = ""
    }
}

@Model
class DayScoreConfig {
    var id: UUID
    var weights: [String: Double]     // LifeModule.rawValue : peso

    init() {
        self.id = UUID()
        self.weights = [
            "Finanzas": 0.2,
            "Gym": 0.2,
            "Hábitos": 0.2,
            "Nutrición": 0.15,
            "Sueño": 0.15,
            "Bienestar": 0.1
        ]
    }
}

@Model
class LifeSnapshot {
    var id: UUID
    var date: Date
    var period: SnapshotPeriod

    // Finanzas
    var totalIncome: Double
    var totalExpenses: Double
    var savingsRate: Double

    // Gym
    var totalWorkouts: Int
    var totalVolume: Double
    var personalRecords: Int

    // Hábitos
    var completionRate: Double
    var longestStreak: Int

    // Nutrición
    var avgCalories: Double
    var avgProtein: Double

    // Sueño
    var avgSleepHours: Double
    var avgSleepScore: Double

    // Mental
    var avgMoodLevel: Double

    // Global
    var avgDayScore: Double

    init(date: Date = .now, period: SnapshotPeriod = .monthly) {
        self.id = UUID()
        self.date = date
        self.period = period
        self.totalIncome = 0; self.totalExpenses = 0; self.savingsRate = 0
        self.totalWorkouts = 0; self.totalVolume = 0; self.personalRecords = 0
        self.completionRate = 0; self.longestStreak = 0
        self.avgCalories = 0; self.avgProtein = 0
        self.avgSleepHours = 0; self.avgSleepScore = 0
        self.avgMoodLevel = 0; self.avgDayScore = 0
    }
}

enum SnapshotPeriod: String, Codable {
    case monthly = "Mensual"
    case quarterly = "Trimestral"
    case yearly = "Anual"
}
```

---

## 5. Funcionalidades por Módulo

### 5.1 Módulo Finanzas (P1) — 12 Features

#### MVP (Fase 1)
| Feature | Descripción | Complejidad |
|---|---|---|
| Dashboard financiero | Balance total, ingresos vs gastos del mes, tendencia | Media |
| Registro de transacciones | Agregar ingresos/gastos con categoría, monto, fecha, nota. Interfaz swipe rápida | Baja |
| Categorías inteligentes | Predefinidas (comida, transporte, salud, gym) + custom. Iconos y colores | Baja |
| Presupuestos mensuales | Límites por categoría, alertas al 80% y 100%, barra de progreso visual | Media |
| Gráficas y reportes | Pie chart gastos/categoría, barras ingresos vs gastos/mes, línea de ahorro | Media |

#### Post-MVP
| Feature | Descripción | Complejidad |
|---|---|---|
| Metas de ahorro | Crear metas con nombre, monto objetivo y fecha. Progreso visual | Media |
| Transacciones recurrentes | Gastos fijos (renta, Netflix, gym) que se registran automáticamente | Media |
| Multi-moneda | Múltiples divisas con conversión USD/EUR/MXN | Alta |
| Deudas y préstamos | Tracker: a quién, cuánto, tasa de interés, plan de pagos | Alta |
| Exportar datos | CSV/PDF para análisis externo o impuestos | Baja |
| Widgets de iOS | Widget en home screen con balance, gasto del día, progreso presupuesto | Media |
| Escaneo de tickets | Cámara + Vision framework OCR para auto-llenar transacciones | Alta |

#### Categorías Financieras Default
```json
[
  { "name": "Comida", "icon": "fork.knife", "color": "#F59E0B" },
  { "name": "Transporte", "icon": "car.fill", "color": "#3B82F6" },
  { "name": "Entretenimiento", "icon": "film", "color": "#8B5CF6" },
  { "name": "Salud", "icon": "heart.fill", "color": "#EF4444" },
  { "name": "Gym", "icon": "dumbbell.fill", "color": "#10B981" },
  { "name": "Ropa", "icon": "tshirt.fill", "color": "#EC4899" },
  { "name": "Educación", "icon": "book.fill", "color": "#6366F1" },
  { "name": "Hogar", "icon": "house.fill", "color": "#F97316" },
  { "name": "Suscripciones", "icon": "repeat", "color": "#14B8A6" },
  { "name": "Ahorro", "icon": "banknote.fill", "color": "#22C55E" },
  { "name": "Regalos", "icon": "gift.fill", "color": "#D946EF" },
  { "name": "Otro", "icon": "ellipsis.circle.fill", "color": "#6B7280" }
]
```

---

### 5.2 Módulo Gimnasio (P2) — 12 Features

#### MVP (Fase 1)
| Feature | Descripción | Complejidad |
|---|---|---|
| Biblioteca de ejercicios | 200+ ejercicios por grupo muscular. Nombre, descripción, músculos | Media |
| Crear rutinas | Rutina personalizada: ejercicios, sets, reps, peso, descanso. Templates PPL, Upper/Lower, Full Body | Media |
| Registro de entrenamiento | Workout activo: timer descanso, registrar peso/reps/set, marcar completado | Media |
| Historial de entrenamientos | Log completo de todos los workouts por fecha | Baja |
| Progreso y PRs | Gráficas por ejercicio en el tiempo. Detección automática de récords personales | Media |
| Timer de descanso | Cronómetro configurable entre sets. Vibración al terminar. Auto-inicio al completar set | Baja |

#### Post-MVP
| Feature | Descripción | Complejidad |
|---|---|---|
| Calculadora de 1RM | Repetición máxima estimada (fórmula Epley/Brzycki) | Baja |
| Plantillas de rutinas | Templates: 5/3/1, Starting Strength, PPL, PHUL con progresión | Alta |
| Body tracking | Peso corporal, medidas, fotos de progreso side-by-side | Media |
| Integración HealthKit | Sincronizar calorías, frecuencia cardíaca, pasos con Apple Health | Media |
| Superset / Circuit mode | Modo para supersets, drop sets y circuitos con timer continuo | Media |
| Animaciones de ejercicios | GIFs o animaciones de ejecución correcta por ejercicio | Alta |

#### Fórmula 1RM (Epley)
```swift
func estimatedOneRepMax(weight: Double, reps: Int) -> Double {
    guard reps > 1 else { return weight }
    return weight * (1 + Double(reps) / 30.0)
}
```

---

### 5.3 Módulo Hábitos (P3) — 12 Features

#### MVP (Fase 1)
| Feature | Descripción | Complejidad |
|---|---|---|
| Crear hábitos | Nombre, frecuencia (diario/semanal), hora, recordatorio | Baja |
| Check-in diario | Pantalla simple para marcar hábitos completados. Un tap = hecho | Baja |
| Racha (Streak) | Contador de días consecutivos. Motivación tipo Duolingo | Baja |
| Calendario visual | Vista calendario con colores: verde/rojo/gris. Tipo GitHub contributions | Media |
| Estadísticas | Porcentaje cumplimiento semanal/mensual, mejor racha, más consistente | Media |
| Notificaciones locales | Recordatorios configurables por hábito a hora elegida | Baja |

#### Post-MVP
| Feature | Descripción | Complejidad |
|---|---|---|
| Hábitos cuantitativos | Registrar cantidad: 8 vasos agua, 30 min lectura, 10k pasos | Media |
| Modo Focus (Pomodoro) | Timer 25/5 con estadísticas de sesiones | Media |
| Journaling rápido | Mini diario: 1-3 frases, mood tracker con emojis | Media |
| Hábitos vinculados | Vincular "Ir al gym" con módulo gym. Auto-check si registraste workout | Media |
| Morning/Night routine | Secuencia ordenada de hábitos. Modo step-by-step enfocado | Media |
| Gamificación | Puntos, niveles, badges por consistencia. Logros desbloqueables | Alta |

---

### 5.4 Módulo Nutrición (P2.5) — 8 Features

**Filosofía:** Es un tracker, no un nutricionista. Sin planes de dieta ni recetas.

#### MVP (Fase 1)
| Feature | Descripción | Complejidad |
|---|---|---|
| Food log rápido | Registrar comidas en 2 taps. Biblioteca de alimentos con macros. Búsqueda + favoritos + frecuentes | Media |
| Meal templates | Plantilla reutilizable ("Mi desayuno de siempre"). Un tap y queda registrado | Baja |
| Objetivos de macros | Configurar gramos de proteína/carbs/grasa diarios. Barras de progreso visuales | Media |
| Tracker de hidratación | Registro de vasos de agua diario con recordatorios | Baja |

#### Post-MVP
| Feature | Descripción | Complejidad |
|---|---|---|
| Escaneo de código de barras | Open Food Facts API (gratuita) para auto-completar macros | Media |
| Análisis de foto con IA | Tomar foto del plato, modelo de visión estima calorías y macros. El usuario corrige y la app aprende | Alta |
| Conexión con Finanzas | Al registrar gasto en "Comida", sugiere registrar qué comiste. Dato cruzado: costo por gramo de proteína | Media |
| Objetivos adaptativos por Gym | Días de entrenamiento vs descanso con diferentes objetivos calóricos. Ajuste automático | Media |

---

### 5.5 Módulo Sueño + Energía (P3) — 7 Features

**Filosofía:** No es una app de sueño dedicada. Es un data point que alimenta insights cruzados.

#### MVP (Fase 2)
| Feature | Descripción | Complejidad |
|---|---|---|
| Sleep log detallado | Hora de acostarse, tiempo estimado en dormirse, interrupciones con timestamps, hora de levantarse | Media |
| Detección automática | Si desbloquea teléfono en horario de sueño, notificación pregunta "¿Te despertaste?" | Media |
| Registro retroactivo | Por la mañana, reconstruir la noche completa en timeline visual editable | Baja |
| Sleep score | Puntuación diaria: duración, interrupciones, consistencia horario, calidad subjetiva | Media |

#### Post-MVP
| Feature | Descripción | Complejidad |
|---|---|---|
| Energy check-ins | 3 registros rápidos al día (mañana, tarde, noche). Slider de 5 niveles | Baja |
| Ritmo circadiano | Visualización del horario de sueño en el tiempo. Detecta consistencia/irregularidad | Media |
| Integración HealthKit | Importar datos de sueño automáticamente desde Apple Watch | Media |

---

### 5.6 Módulo Bienestar Mental (P3.5) — 6 Features

**Filosofía:** Registro ligero de estado emocional. No es app de meditación.

#### MVP (Fase 2)
| Feature | Descripción | Complejidad |
|---|---|---|
| Mood check-in | 5 niveles con emojis + tags opcionales: "estresado", "motivado", "ansioso", "enfocado" | Baja |
| Mini journaling | 1 a 3 frases opcionales. Nota rápida del día | Baja |
| Gratitud rápida | 3 cosas buenas del día. Un tap para cada una | Baja |

#### Post-MVP
| Feature | Descripción | Complejidad |
|---|---|---|
| Ejercicios de respiración | 3-4 ejercicios guiados con animación (box breathing, 4-7-8). Timer visual | Media |
| Calendario emocional | Vista calendario con colores de mood. Tipo GitHub contributions emocional | Media |
| Detección de patrones con IA | Correlaciones mood vs sueño, gym, gastos, hábitos | Alta |

---

### 5.7 Life Goals — Metas Unificadas (P3) — 5 Features

| Feature | Descripción | Complejidad |
|---|---|---|
| Meta compuesta | Meta grande con sub-metas de diferentes módulos. Progreso = promedio ponderado | Alta |
| Timeline visual | Línea de tiempo con milestones tipo roadmap personal | Media |
| Deadline inteligente | IA analiza ritmo actual y predice si llegarás a tiempo | Media |
| Dashboard de metas | Todas las metas activas con porcentaje y qué falta | Media |
| Metas sugeridas por IA | Basándose en datos y patrones, sugerir metas relevantes | Media |

---

### 5.8 LifeOS Intelligence — Capa de IA (P4) — 7 Features

**Requisito:** Usuario proporciona su propia API Key (BYOK)
**Proveedores:** OpenAI, Anthropic, Google Gemini
**Principio:** Sin key la app funciona al 100%. Con key se vuelve inteligente.

| Feature | Descripción | Complejidad |
|---|---|---|
| Análisis de fotos de comida | Modelo de visión estima calorías y macros de una foto del plato | Alta |
| OCR de tickets | Foto del ticket → categoriza gastos + sugiere alimentos comprados | Alta |
| Insights automáticos | Correlaciones cruzadas entre todos los módulos. Alertas inteligentes | Alta |
| Resumen semanal (Life Review) | Mini-reporte generado con lo más relevante de la semana | Media |
| Asistente conversacional | Chat en lenguaje natural sobre tus datos: "¿Cuánto gasté en Uber?" | Alta |
| Sugerencias de metas | Basándose en patrones: "Tu gasto en comida subió, ¿quieres crear una meta?" | Media |
| Predicción de deadline | Analiza ritmo actual de metas y predice si llegarás a tiempo | Media |

---

### 5.9 Connect — Integraciones Externas (P4) — 11 Features

#### Registro Automático de Pagos
| Feature | Descripción | Complejidad |
|---|---|---|
| Notificaciones bancarias | Interceptar push del banco, extraer monto y comercio, crear transacción automática | Alta |
| Apple Pay | Detectar pago completado, capturar datos disponibles | Alta |
| Shortcuts automático | Atajo de iOS que se dispara al detectar pago, abre LifeOS pre-llenado | Media |

#### Otras Integraciones
| Feature | Dirección | Complejidad |
|---|---|---|
| HealthKit bidireccional | Importar sueño, pasos, FC. Exportar workouts | Media |
| Strava / Apple Fitness | Importar actividades de cardio | Media |
| Open Food Facts API | Escaneo código de barras → macros | Media |
| Apple Calendar | Vincular eventos con hábitos/metas | Baja |
| Siri Shortcuts | Comandos de voz para registrar datos | Media |
| Exchangerate API | Conversión de moneda en tiempo real | Baja |
| Exportar CSV/PDF/JSON | Exportar cualquier dato en cualquier momento | Baja |
| Importar desde otras apps | Migración: MyFitnessPal, YNAB, Habitica (CSV) | Media |

---

### 5.10 Widgets + Live Activities (P4) — Features Ambient

#### Widgets Home Screen
| Widget | Tamaño | Contenido |
|---|---|---|
| Balance financiero | Pequeño | Gasto del día, presupuesto restante |
| Hábitos del día | Mediano | Checkboxes interactivos desde widget |
| Próximo workout | Pequeño | Nombre de rutina, días desde último entreno |
| Sueño anoche | Pequeño | Horas dormidas, sleep score |
| Macros del día | Mediano | Barras de progreso de calorías/proteína/carbs/grasa |
| Resumen LifeOS | Grande | Un dato clave de cada módulo |

#### Live Activities (Dynamic Island)
| Actividad | Trigger | Contenido |
|---|---|---|
| Workout activo | Iniciar entrenamiento | Timer de descanso entre sets |
| Respiración | Iniciar ejercicio | Animación de respiración |
| Meta cercana | Progreso >= 90% | Porcentaje en tiempo real |

#### Lock Screen Widgets
- Gasto acumulado del día
- Hábitos pendientes (X de Y)
- Sleep score de anoche

#### Apple Watch
| Complicación | Contenido |
|---|---|
| Calorías restantes | Objetivo - consumidas hoy |
| Hábitos | Completados vs pendientes |
| Timer gym | Descanso entre sets |
| Mood | Check-in rápido desde la muñeca |

---

### 5.11 Day Score + Time Machine (P5) — 3 Features

| Feature | Descripción | Complejidad |
|---|---|---|
| Day Score | Puntuación diaria 0-100 con pesos personalizables por módulo. Timeline de tendencia | Media |
| Life Review | Resumen semanal/mensual generado por IA: logros, caídas, patrones, sugerencias | Media |
| Time Machine | Compararte con tu yo de 1/3/6/12 meses atrás. Vista lado a lado con resumen de IA | Alta |

---

### 5.12 Funcionalidades Transversales — 10 Features

#### MVP (Fase 1)
| Feature | Descripción | Complejidad |
|---|---|---|
| Onboarding guiado | Flujo bienvenida: nombre, objetivos, módulos de interés | Media |
| Dashboard unificado | Pantalla principal con resumen de 3 módulos | Media |
| Tema oscuro / claro | Dark Mode nativo con toggle manual + auto sistema | Baja |
| Datos 100% locales | SwiftData/Core Data. Sin servidor = sin costo | Media |

#### Post-MVP
| Feature | Descripción | Complejidad |
|---|---|---|
| Backup iCloud | Sincronización automática + multi-dispositivo Apple | Media |
| Face ID / Touch ID | Proteger app (especialmente finanzas) con biometría | Baja |
| Siri Shortcuts | "Hey Siri, registra gasto de $200 en comida" | Media |
| Apple Watch companion | Timer gym, check-in hábitos, balance del día | Alta |
| Insights con IA | Análisis: "Gastas 40% más en comida los viernes" | Alta |
| Sistema de logros | Badges cross-módulo: "Semana perfecta" | Media |

---

## 6. Diseño UI/UX

### 6.1 Paleta de Colores

```swift
extension Color {
    // Módulos
    static let financeGreen = Color(hex: "#10B981")
    static let gymAmber = Color(hex: "#F59E0B")
    static let habitsPurple = Color(hex: "#8B5CF6")
    static let crossPink = Color(hex: "#EC4899")

    // Fondos
    static let bgPrimary = Color(hex: "#0A0A0F")     // Dark mode
    static let bgSecondary = Color(hex: "#111122")
    static let bgCard = Color(hex: "#1A1A2E")

    // Texto
    static let textPrimary = Color(hex: "#E5E5E5")
    static let textSecondary = Color(hex: "#9CA3AF")
    static let textMuted = Color(hex: "#6B7280")

    // Semánticos
    static let success = Color(hex: "#22C55E")
    static let warning = Color(hex: "#F59E0B")
    static let danger = Color(hex: "#EF4444")
    static let info = Color(hex: "#3B82F6")
}
```

### 6.2 Tipografía
- **Títulos:** SF Pro Display Bold / Heavy
- **Cuerpo:** SF Pro Text Regular
- **Números/Montos:** SF Mono (para alineación de dígitos)
- **Tamaños:** 28pt (títulos), 17pt (body), 13pt (caption), 11pt (overline)

### 6.3 Principios de UX
1. **Una mano:** Todo alcanzable con el pulgar (Bottom sheet > Modal)
2. **Feedback háptico:** Vibraciones sutiles en acciones importantes
3. **Swipe actions:** Deslizar para editar/eliminar transacciones
4. **Minimal taps:** Registrar gasto en máximo 3 taps
5. **Animaciones nativas:** Spring animations de SwiftUI
6. **Accesibilidad:** VoiceOver, Dynamic Type, Reduce Motion

### 6.4 Iconografía
Usar exclusivamente **SF Symbols** para iconos — se adaptan automáticamente a todos los tamaños, pesos y modos de accesibilidad.

---

## 7. Roadmap de Desarrollo

### Fase 1 — MVP Core (Semanas 1-8)
**Objetivo:** App funcional con los módulos core

| Semana | Entregable |
|---|---|
| 1 | Setup proyecto Xcode, arquitectura MVVM, SwiftData config, TabView, tema de colores |
| 2 | Finanzas: Transaction model, AddTransactionView, TransactionListView |
| 3 | Finanzas: Dashboard, categorías, presupuestos, gráficas básicas |
| 4 | Gym: Exercise model + JSON data, ExerciseLibraryView, RoutineBuilderView |
| 5 | Gym: ActiveWorkoutView con timer, WorkoutHistoryView, ProgressView |
| 6 | Nutrición: FoodItem model, AddMealView, MacrosDashboardView, WaterTracker |
| 7 | Hábitos: Habit model, check-in, streaks, calendario |
| 8 | Dashboard unificado, navegación entre módulos |

### Fase 2 — Módulos Secundarios (Semanas 9-12)
**Objetivo:** Sueño, bienestar mental, metas y pulido

| Semana | Entregable |
|---|---|
| 9 | Sueño: SleepLog, timeline de interrupciones, registro retroactivo, sleep score |
| 10 | Bienestar Mental: MoodLog, check-in, journaling, gratitud, calendario emocional |
| 11 | Life Goals: metas compuestas cross-módulo, sub-metas, timeline, dashboard |
| 12 | Gráficas avanzadas (Swift Charts), reportes financieros, PRs gym, estadísticas |

### Fase 3 — Power Features (Semanas 13-18)
**Objetivo:** IA, integraciones y features avanzados

| Semana | Entregable |
|---|---|
| 13 | Notificaciones locales, onboarding guiado, pulido UI/UX, animaciones, haptics |
| 14 | Metas de ahorro, transacciones recurrentes, escaneo código de barras (nutrición) |
| 15 | LifeOS Intelligence: configuración API key, análisis de fotos de comida, OCR tickets |
| 16 | LifeOS Intelligence: insights automáticos, asistente conversacional, Life Review |
| 17 | Connect: registro automático de pagos (notificaciones bancarias, Apple Pay, Shortcuts) |
| 18 | Connect: HealthKit bidireccional, importar/exportar CSV, Siri Shortcuts |

### Fase 4 — Experiencia Ambient (Semanas 19-22)
**Objetivo:** Widgets, Watch, Day Score

| Semana | Entregable |
|---|---|
| 19 | Widgets iOS: home screen + lock screen (finanzas, hábitos, sueño, nutrición, resumen) |
| 20 | Live Activities: Dynamic Island para workout timer, respiración, meta cercana |
| 21 | Day Score + Time Machine + Life Snapshots |
| 22 | Apple Watch: timer gym, check-in hábitos, mood, complicaciones |

### Fase 5 — Publicación (Semanas 23-24)
| Semana | Entregable |
|---|---|
| 23 | iCloud backup, Face ID, testing completo, App Store assets, screenshots |
| 24 | TestFlight beta, Submit App Store Review, plan post-launch |

---

## 8. Instrucciones para Claude Code

### Cómo usar este documento
1. Abrir Claude Code en terminal
2. Referenciar este archivo: `@LifeOS-Spec.md`
3. Pedir feature por feature siguiendo el roadmap
4. Ejemplo: "Crea el modelo Transaction y la vista AddTransactionView según la spec"

### Convenciones de código
- **Naming:** camelCase para variables, PascalCase para tipos
- **Idioma del código:** inglés (nombres de variables, funciones, tipos)
- **Idioma de UI:** español (textos visibles al usuario)
- **Comentarios:** español, breves
- **Commits:** Conventional Commits en español (`feat: agregar dashboard financiero`)

### Dependencias externas (Paquetes Flutter)
**Filosofía pragmática:** Usar paquetes bien mantenidos cuando ahorren tiempo significativo.

**Paquetes core:**
- flutter_riverpod (state management)
- drift + sqlite3_flutter_libs (base de datos)
- go_router (navegación)
- fl_chart (gráficas)
- flutter_local_notifications (notificaciones)
- local_auth (biometría)
- google_mlkit_text_recognition (OCR)
- health (Apple Health + Health Connect)
- mobile_scanner (códigos de barras)
- flutter_secure_storage (almacenamiento seguro)
- home_widget (widgets de home screen)
- intl (internacionalización)
- google_fonts (Inter, JetBrains Mono)

**APIs externas opcionales (el usuario las configura):**
- OpenAI / Anthropic / Google Gemini (IA — BYOK)
- Open Food Facts (códigos de barras — gratuita, sin key)
- Exchangerate API (conversión de moneda — gratuita)

---

## 9. Costo Total

| Concepto | Costo |
|---|---|
| Servidor | $0 (local) |
| Base de datos | $0 (Drift/SQLite local) |
| Backup | $0 (export/import JSON local) |
| Push notifications | $0 (locales) |
| Dependencias | $0 (paquetes open source) |
| **Apple Developer Program** | **$99 USD/año** (App Store) |
| **Google Play Console** | **$25 USD** (pago único, Play Store) |
| **Total mensual desarrollo** | **$0** |
| **Total primer año publicación** | **$124 USD** |
| **Total años siguientes** | **$99 USD/año** |

---

---

## 10. Integraciones — Detalle Técnico

### 10.1 Registro Automático de Pagos

| Método | Mecanismo | Datos Capturados |
|---|---|---|
| Notificaciones bancarias | `UNUserNotificationCenter` intercepta push del banco, parsea monto y comercio | Monto, comercio, fecha |
| Apple Pay | Detectar evento de pago completado vía `PassKit` | Monto, comercio (limitado por Apple) |
| Shortcuts automático | `Shortcuts.app` Automation al detectar pago → abre LifeOS pre-llenado | Monto (usuario confirma) |

### 10.2 Flujo de Análisis con IA

```
1. Usuario solicita insight / toma foto / abre chat
2. LifeOS recopila datos relevantes (queries SwiftData locales)
3. Construye prompt con datos + instrucción
4. Envía a API del proveedor (key desde Keychain)
5. Respuesta parseada y presentada
6. Datos NUNCA se envían sin acción explícita del usuario
```

### 10.3 Integraciones por Dirección

| Integración | Importar | Exportar |
|---|---|---|
| HealthKit | Sueño, pasos, FC, calorías | Workouts |
| Strava / Apple Fitness | Cardio | — |
| Open Food Facts | Datos nutricionales por barcode | — |
| Apple Calendar | Eventos | — |
| Bancos (notificaciones) | Transacciones | — |
| CSV/PDF/JSON | MyFitnessPal, YNAB, Habitica | Todos los datos |
| Markdown | — | Resúmenes a Obsidian/Notion |

---

*Documento generado por el Departamento de TI (Claude) — Abril 2026*
*Actualizado con expansión de módulos — Abril 2026*
*Para uso con Claude Code en el desarrollo de LifeOS*
