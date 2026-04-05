# LifeOS — Expansion Design: Nuevos Modulos y Features

> **Adenda a LifeOS-Spec.md**
> Documento de diseno para funcionalidades adicionales acordadas en sesion de brainstorming

---

## 1. Nuevo Modulo: Nutricion (P2.5)

**Prioridad:** Entre Gym y Habitos
**Filosofia:** Es un tracker, no un nutricionista. Sin planes de dieta ni recetas.

### 1.1 Features Core

| Feature | Descripcion | Complejidad |
|---|---|---|
| Food log rapido | Registrar comidas en 2 taps. Biblioteca de alimentos con macros (proteina, carbs, grasa, calorias). Busqueda + favoritos + comidas frecuentes | Media |
| Meal templates | "Mi desayuno de siempre" como plantilla reutilizable. Un tap y queda registrado | Baja |
| Objetivos de macros | Configurar gramos de proteina/carbs/grasa diarios. Barras de progreso visuales | Media |
| Escaneo de codigo de barras | Integracion con Open Food Facts API (gratuita, open source) para auto-completar macros | Media |
| Analisis de foto con IA | Tomar foto del plato, el modelo de vision estima calorias y macros. El usuario corrige y la app aprende | Alta |
| Tracker de hidratacion | Registro de vasos de agua diario con recordatorios | Baja |

### 1.2 Conexiones Cross-Modulo

- **Con Finanzas:** Cuando registras un gasto en "Comida", la app sugiere registrar que comiste. Dato cruzado: "costo por gramo de proteina"
- **Con Gym:** Dias de entrenamiento vs descanso pueden tener diferentes objetivos caloricos. Ajuste automatico
- **Con IA:** Foto del ticket de supermercado -> OCR + IA categoriza gastos Y sugiere registrar alimentos comprados

### 1.3 Modelo de Datos (SwiftData)

```swift
@Model
class FoodItem {
    var id: UUID
    var name: String
    var calories: Double          // por porcion
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
    var calories: Double           // Calculado: foodItem.calories * quantity
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
    var water: Int                // Vasos por dia
    var isTrainingDay: Bool       // Objetivos diferentes para dias de gym
    var trainingCalorieBoost: Double  // Calorias extra en dia de entrenamiento

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

---

## 2. Nuevo Modulo: Sueno + Energia (P3)

**Prioridad:** Junto a Habitos
**Filosofia:** No es una app de sueno dedicada. Es un data point que alimenta insights cruzados.

### 2.1 Features Core

| Feature | Descripcion | Complejidad |
|---|---|---|
| Sleep log detallado | Hora de acostarse, tiempo estimado en dormirse, interrupciones con hora de despertar y hora de volver a dormir, hora de levantarse definitivamente | Media |
| Deteccion automatica de interrupciones | Si el usuario desbloquea el telefono entre hora de dormir y alarma, notificacion pregunta "Te despertaste?" con opciones rapidas | Media |
| Registro retroactivo | Por la manana, reconstruir la noche completa: agregar/editar interrupciones no registradas en el momento | Baja |
| Energy check-ins | 3 check-ins rapidos al dia (manana, tarde, noche). Slider o 5 niveles | Baja |
| Sleep score | Puntuacion diaria basada en duracion, consistencia de horario, cantidad de interrupciones y calidad reportada | Media |
| Ritmo circadiano | Visualizacion del horario de sueno en el tiempo. Detecta consistencia o irregularidad | Media |
| Integracion HealthKit | Importar datos de sueno automaticamente desde Apple Watch | Media |

### 2.2 Flujo de Registro Nocturno

```
NOCHE:
1. Usuario abre app -> tap "Me voy a dormir" (registra hora)
2. Opcional: "Me tardo ~15 min en dormirme" (slider)
3. App entra en modo nocturno (pantalla oscura)

INTERRUPCION (via notificacion):
4. Usuario desbloquea telefono a las 3am
5. Notificacion: "Te despertaste?" -> [Si] [No, solo revise el telefono]
6. Si "Si" -> queda registrado
7. Cuando vuelve a dormir -> notificacion "Volviste a dormir?" o tap en widget

MANANA:
8. Usuario abre app -> "Buenos dias! Registra tu noche"
9. Timeline visual editable de la noche
10. Puede agregar interrupciones que no registro
11. Calidad subjetiva: 1-5 estrellas
12. Se calcula sleep score
```

### 2.3 Modelo de Datos (SwiftData)

```swift
@Model
class SleepLog {
    var id: UUID
    var date: Date                    // Fecha del dia (la noche del 3 = dia 4)
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
        // Basado en: duracion, interrupciones, consistencia, calidad subjetiva
        var score = 0.0
        let hoursSlept = Double(totalSleepMinutes) / 60.0

        // Duracion (40% del score)
        let durationScore = min(hoursSlept / 8.0, 1.0) * 40

        // Interrupciones (25% del score)
        let interruptionPenalty = min(Double(interruptions.count) * 8.0, 25.0)
        let interruptionScore = 25.0 - interruptionPenalty

        // Calidad subjetiva (20% del score)
        let qualityScore = (Double(qualityRating) / 5.0) * 20

        // Tiempo en dormirse (15% del score)
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
    var wakeUpTime: Date              // Hora en que se desperto
    var backToSleepTime: Date?        // Hora en que volvio a dormir
    var reason: String                // "Bano", "Ruido", "Sin razon", etc.
    var wasAutoDetected: Bool         // Detectado via notificacion

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
    case morning = "Manana"
    case afternoon = "Tarde"
    case night = "Noche"
}
```

---

## 3. Nuevo Modulo: Bienestar Mental — "Mindfulness Lite" (P3.5)

**Prioridad:** Complementario
**Filosofia:** Registro ligero de estado emocional. No es app de meditacion.

### 3.1 Features Core

| Feature | Descripcion | Complejidad |
|---|---|---|
| Mood check-in | 5 niveles con emojis + tags opcionales: "estresado", "motivado", "ansioso", "enfocado", "cansado" | Baja |
| Mini journaling | 1 a 3 frases opcionales. Nota rapida del dia | Baja |
| Gratitud rapida | 3 cosas buenas del dia. Un tap para cada una | Baja |
| Ejercicios de respiracion | 3-4 ejercicios guiados con animacion (box breathing, 4-7-8). Timer visual | Media |
| Calendario emocional | Vista calendario con colores de mood. Ves tu mes emocional de un vistazo | Media |
| Deteccion de patrones con IA | Correlaciones mood vs sueno, gym, gastos, habitos | Alta |

### 3.2 Modelo de Datos (SwiftData)

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
    case calmBreathing = "Respiracion Calmada" // 4-6
    case energizing = "Energizante"           // 2-2 rapida
}
```

### 3.3 Tags de Mood Predefinidos

```json
[
    "Motivado", "Enfocado", "Tranquilo", "Agradecido", "Energetico",
    "Estresado", "Ansioso", "Cansado", "Triste", "Frustrado",
    "Productivo", "Creativo", "Social", "Solitario", "Aburrido"
]
```

---

## 4. Capa Transversal: LifeOS Intelligence (IA)

**Requisito:** Usuario proporciona su propia API Key
**Proveedores soportados:** OpenAI, Anthropic, Google Gemini
**Principio:** Sin key la app funciona al 100%. Con key se vuelve inteligente.

### 4.1 Features

| Feature | Descripcion | Complejidad |
|---|---|---|
| Analisis de fotos de comida | Vision model estima calorias y macros de una foto del plato | Alta |
| OCR de tickets | Foto del ticket -> categoriza gastos + sugiere alimentos comprados | Alta |
| Insights automaticos | Correlaciones cruzadas entre todos los modulos | Alta |
| Alertas inteligentes | "Tu proteina bajo 20% y tu PR no sube en 3 semanas" | Media |
| Resumen semanal | Mini-reporte generado con lo mas relevante de la semana | Media |
| Asistente conversacional | Chat en lenguaje natural sobre tus datos: "Cuanto gaste en Uber este trimestre?" | Alta |
| Sugerencias de metas | Basandose en patrones: "Tu gasto en comida chatarra subio, quieres crear una meta?" | Media |

### 4.2 Arquitectura Tecnica

```
Flujo de datos:

Usuario solicita insight
        |
        v
LifeOS recopila datos relevantes del contexto
(SwiftData queries locales)
        |
        v
Construye prompt con datos + instruccion
        |
        v
Envia a API del proveedor seleccionado
(API Key desde Keychain)
        |
        v
Respuesta parseada y presentada al usuario
        |
        v
Datos NUNCA se envian sin accion explicita del usuario
```

### 4.3 Modelo de Datos (SwiftData)

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
    var module: String?               // Modulo de contexto (opcional)

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
    var role: MessageRole             // .user | .assistant
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

### 4.4 Privacidad y Seguridad

- API Key almacenado en iOS Keychain (encriptado por hardware)
- Datos se envian SOLO cuando el usuario lo solicita explicitamente
- Opcion de ver exactamente que datos se enviaran antes de confirmar
- Historial de conversaciones almacenado localmente
- Boton "Borrar historial de IA" en configuracion

---

## 5. Capa Transversal: Life Goals — Sistema de Metas Unificado

### 5.1 Features

| Feature | Descripcion | Complejidad |
|---|---|---|
| Meta compuesta | Meta grande con sub-metas de diferentes modulos. Progreso = promedio ponderado | Alta |
| Timeline visual | Linea de tiempo con milestones tipo roadmap personal | Media |
| Deadline inteligente | IA analiza ritmo actual y predice si llegaras a tiempo | Media |
| Dashboard de metas | Todas las metas activas con porcentaje y que falta | Media |
| Metas sugeridas por IA | Basandose en datos: sugerir metas relevantes al usuario | Media |

### 5.2 Modelo de Datos (SwiftData)

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
    var module: LifeModule            // A que modulo pertenece
    var targetType: GoalTargetType
    var targetValue: Double
    var currentValue: Double
    var weight: Double                // Peso en el progreso total (0.0 - 1.0)
    var linkedEntityId: UUID?         // ID de habito, meta de ahorro, ejercicio, etc.

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
    case habits = "Habitos"
    case nutrition = "Nutricion"
    case sleep = "Sueno"
    case mental = "Bienestar"
}

enum GoalTargetType: String, Codable {
    case amount = "Monto"             // Ej: ahorrar $5000
    case weight = "Peso"              // Ej: levantar 100kg en bench
    case bodyWeight = "Peso Corporal" // Ej: llegar a 75kg
    case streak = "Racha"             // Ej: 30 dias seguidos
    case count = "Cantidad"           // Ej: 20 workouts en un mes
    case percentage = "Porcentaje"    // Ej: 90% cumplimiento habitos
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

---

## 6. Capa Transversal: Connect — Integraciones Externas

### 6.1 Registro Automatico de Pagos

| Metodo | Descripcion | Complejidad |
|---|---|---|
| Notificaciones bancarias | Interceptar push de banco, extraer monto y comercio, crear transaccion automatica | Alta |
| Apple Pay | Detectar pago completado, capturar datos disponibles | Alta |
| Shortcuts automatico | Atajo de iOS que se dispara al detectar pago, abre LifeOS pre-llenado | Media |

### 6.2 Otras Integraciones

| Integracion | Direccion | Descripcion |
|---|---|---|
| HealthKit | Bidireccional | Importar sueno, pasos, FC. Exportar workouts |
| Strava / Apple Fitness | Importar | Actividades de cardio |
| Open Food Facts API | Importar | Escaneo codigo de barras -> macros |
| Apple Calendar | Leer | Vincular eventos con habitos/metas |
| Siri Shortcuts | Bidireccional | Comandos de voz para registrar datos |
| Exchangerate API | Importar | Conversion de moneda en tiempo real |
| CSV bancario | Importar | Importar estado de cuenta + categorizar con IA |
| CSV/PDF/JSON | Exportar | Exportar cualquier dato en cualquier momento |
| Markdown | Exportar | Resumenes semanales a Obsidian/Notion |
| MyFitnessPal CSV | Importar | Migracion de datos de nutricion |
| YNAB CSV | Importar | Migracion de datos financieros |

---

## 7. Experiencia Ambient: Widgets + Live Activities

### 7.1 Widgets Home Screen

| Widget | Tamano | Contenido |
|---|---|---|
| Balance financiero | Pequeno | Gasto del dia, presupuesto restante |
| Habitos del dia | Mediano | Checkboxes interactivos directo desde widget |
| Proximo workout | Pequeno | Nombre de rutina, dias desde ultimo entreno |
| Sueno anoche | Pequeno | Horas dormidas, sleep score |
| Resumen LifeOS | Grande | Un dato clave de cada modulo |
| Macros del dia | Mediano | Barras de progreso de calorias/proteina/carbs/grasa |

### 7.2 Live Activities (Dynamic Island)

| Actividad | Trigger | Contenido |
|---|---|---|
| Workout activo | Iniciar entrenamiento | Timer de descanso entre sets |
| Respiracion | Iniciar ejercicio | Animacion de respiracion |
| Meta cercana | Progreso >= 90% | Porcentaje en tiempo real |

### 7.3 Lock Screen Widgets

- Gasto acumulado del dia
- Habitos pendientes (X de Y)
- Sleep score de anoche

### 7.4 Apple Watch

| Complicacion | Contenido |
|---|---|
| Calorias restantes | Objetivo - consumidas hoy |
| Habitos | Completados vs pendientes |
| Timer gym | Descanso entre sets |
| Mood | Check-in rapido desde la muneca |

---

## 8. Features "Dark Horse"

### 8.1 Life Review (Semanal/Mensual)

- Cada domingo (configurable) la app genera review automatico con IA
- Que hiciste bien, que se cayo, que patron nuevo detecto
- Comparacion con semana/mes anterior en todos los modulos
- Sugerencias concretas para la proxima semana

### 8.2 Day Score

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
    var weight: Double                // 0.0 - 1.0 (el usuario decide)
    var score: Double                 // 0-100 para este modulo
    var details: String               // "4/5 habitos, dentro de presupuesto"

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
    var weights: [LifeModule: Double] // Pesos personalizados por modulo

    init() {
        self.id = UUID()
        self.weights = [
            .finance: 0.2,
            .gym: 0.2,
            .habits: 0.2,
            .nutrition: 0.15,
            .sleep: 0.15,
            .mental: 0.1
        ]
    }
}
```

- Puntuacion diaria calculada con los criterios del usuario
- El usuario elige que peso tiene cada modulo en SU score
- Timeline de Day Scores — tendencia de tu vida en una linea

### 8.3 Time Machine

- Compararte con tu yo de hace 1, 3, 6, 12 meses
- Vista lado a lado: finanzas, cuerpo, habitos, sueno — antes vs ahora
- La IA genera resumen: "En 6 meses: ahorraste $X mas, subiste 15kg en bench, dormiste 45 min mas en promedio"
- Datos requeridos: snapshots mensuales automaticos de metricas clave

```swift
@Model
class LifeSnapshot {
    var id: UUID
    var date: Date
    var period: SnapshotPeriod        // .monthly | .quarterly | .yearly

    // Finanzas
    var totalIncome: Double
    var totalExpenses: Double
    var savingsRate: Double

    // Gym
    var totalWorkouts: Int
    var totalVolume: Double
    var personalRecords: Int

    // Habitos
    var completionRate: Double
    var longestStreak: Int

    // Nutricion
    var avgCalories: Double
    var avgProtein: Double

    // Sueno
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
        // Defaults a 0 para todo
        self.totalIncome = 0
        self.totalExpenses = 0
        self.savingsRate = 0
        self.totalWorkouts = 0
        self.totalVolume = 0
        self.personalRecords = 0
        self.completionRate = 0
        self.longestStreak = 0
        self.avgCalories = 0
        self.avgProtein = 0
        self.avgSleepHours = 0
        self.avgSleepScore = 0
        self.avgMoodLevel = 0
        self.avgDayScore = 0
    }
}

enum SnapshotPeriod: String, Codable {
    case monthly = "Mensual"
    case quarterly = "Trimestral"
    case yearly = "Anual"
}
```

---

## 9. Prioridad de Modulos Actualizada

| # | Modulo | Prioridad | Fase |
|---|---|---|---|
| 1 | Finanzas Personales | P1 — Maxima | MVP |
| 2 | Gimnasio & Fitness | P2 — Alta | MVP |
| 3 | Nutricion | P2.5 — Alta | MVP/Post-MVP |
| 4 | Habitos & Productividad | P3 — Normal | MVP |
| 5 | Sueno + Energia | P3 — Normal | Post-MVP |
| 6 | Bienestar Mental | P3.5 — Normal | Post-MVP |
| 7 | Life Goals | P3 — Normal | Post-MVP |
| 8 | LifeOS Intelligence (IA) | P4 — Baja | Fase 3 |
| 9 | Connect (Integraciones) | P4 — Baja | Fase 3 |
| 10 | Widgets + Live Activities | P4 — Baja | Fase 3 |
| 11 | Day Score + Life Review + Time Machine | P5 — Futura | Fase 4 |

---

## 10. Estructura de Carpetas Actualizada

```
LifeOS/
├── LifeOSApp.swift
├── ContentView.swift
│
├── App/
│   ├── AppState.swift
│   └── AppConstants.swift
│
├── Shared/
│   ├── Models/
│   │   └── Enums.swift
│   ├── Components/
│   │   ├── StatCard.swift
│   │   ├── ProgressRing.swift
│   │   ├── ChartCard.swift
│   │   └── EmptyStateView.swift
│   ├── Extensions/
│   │   ├── Date+Extensions.swift
│   │   ├── Double+Currency.swift
│   │   └── Color+Theme.swift
│   └── Utilities/
│       ├── HapticManager.swift
│       ├── NotificationManager.swift
│       └── KeychainManager.swift
│
├── Features/
│   ├── Dashboard/
│   ├── Finance/
│   ├── Gym/
│   ├── Nutrition/                    # NUEVO
│   │   ├── Models/
│   │   │   ├── FoodItem.swift
│   │   │   ├── MealLog.swift
│   │   │   ├── MealTemplate.swift
│   │   │   ├── NutritionGoal.swift
│   │   │   └── WaterLog.swift
│   │   ├── Views/
│   │   │   ├── NutritionHomeView.swift
│   │   │   ├── AddMealView.swift
│   │   │   ├── FoodSearchView.swift
│   │   │   ├── BarcodeScannerView.swift
│   │   │   ├── MacrosDashboardView.swift
│   │   │   └── WaterTrackerView.swift
│   │   └── ViewModels/
│   │       └── NutritionViewModel.swift
│   │
│   ├── Habits/
│   ├── Sleep/                        # NUEVO
│   │   ├── Models/
│   │   │   ├── SleepLog.swift
│   │   │   ├── SleepInterruption.swift
│   │   │   └── EnergyLog.swift
│   │   ├── Views/
│   │   │   ├── SleepHomeView.swift
│   │   │   ├── SleepLogView.swift
│   │   │   ├── SleepTimelineView.swift
│   │   │   ├── MorningReviewView.swift
│   │   │   └── EnergyCheckInView.swift
│   │   └── ViewModels/
│   │       └── SleepViewModel.swift
│   │
│   ├── Mental/                       # NUEVO
│   │   ├── Models/
│   │   │   ├── MoodLog.swift
│   │   │   └── BreathingSession.swift
│   │   ├── Views/
│   │   │   ├── MentalHomeView.swift
│   │   │   ├── MoodCheckInView.swift
│   │   │   ├── JournalView.swift
│   │   │   ├── GratitudeView.swift
│   │   │   ├── BreathingView.swift
│   │   │   └── MoodCalendarView.swift
│   │   └── ViewModels/
│   │       └── MentalViewModel.swift
│   │
│   ├── Goals/                        # NUEVO
│   │   ├── Models/
│   │   │   ├── LifeGoal.swift
│   │   │   ├── SubGoal.swift
│   │   │   └── GoalMilestone.swift
│   │   ├── Views/
│   │   │   ├── GoalsHomeView.swift
│   │   │   ├── CreateGoalView.swift
│   │   │   ├── GoalDetailView.swift
│   │   │   └── GoalTimelineView.swift
│   │   └── ViewModels/
│   │       └── GoalsViewModel.swift
│   │
│   ├── Intelligence/                 # NUEVO
│   │   ├── Models/
│   │   │   ├── AIConfiguration.swift
│   │   │   └── AIConversation.swift
│   │   ├── Views/
│   │   │   ├── AIAssistantView.swift
│   │   │   ├── InsightsView.swift
│   │   │   ├── WeeklyReviewView.swift
│   │   │   └── AISettingsView.swift
│   │   ├── ViewModels/
│   │   │   └── AIViewModel.swift
│   │   └── Services/
│   │       ├── AIService.swift
│   │       ├── OpenAIProvider.swift
│   │       ├── AnthropicProvider.swift
│   │       └── GeminiProvider.swift
│   │
│   ├── DayScore/                     # NUEVO
│   │   ├── Models/
│   │   │   ├── DayScore.swift
│   │   │   ├── DayScoreConfig.swift
│   │   │   └── LifeSnapshot.swift
│   │   ├── Views/
│   │   │   ├── DayScoreView.swift
│   │   │   ├── ScoreConfigView.swift
│   │   │   └── TimeMachineView.swift
│   │   └── ViewModels/
│   │       └── DayScoreViewModel.swift
│   │
│   └── Onboarding/
│
├── Widgets/                          # NUEVO
│   ├── FinanceWidget.swift
│   ├── HabitsWidget.swift
│   ├── GymWidget.swift
│   ├── SleepWidget.swift
│   ├── NutritionWidget.swift
│   └── SummaryWidget.swift
│
├── WatchApp/                         # NUEVO
│   ├── WatchContentView.swift
│   ├── GymTimerView.swift
│   ├── HabitCheckInView.swift
│   └── MoodCheckInView.swift
│
├── Resources/
│   ├── Assets.xcassets/
│   ├── ExerciseData.json
│   └── DefaultCategories.json
│
└── Preview Content/
    └── PreviewSampleData.swift
```

---

*Documento de expansion generado en sesion de brainstorming — Abril 2026*
*Para uso con Claude Code en el desarrollo de LifeOS*
