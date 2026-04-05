# Business Logic Model — Unit 8: Integration + Intelligence

## Event Flow Overview

```
App Startup
  |
  v
wireEventBus(ref)
  |
  +-- subscribes: WorkoutCompletedEvent  --> [HabitsNotifier, NutritionNotifier, DayScoreNotifier]
  +-- subscribes: ExpenseAddedEvent      --> [suggestion stub]
  +-- subscribes: BudgetThresholdEvent   --> [DashboardNotifier, NotificationScheduler]
  +-- subscribes: HabitCheckedInEvent    --> [DashboardNotifier, DayScoreNotifier]
  +-- subscribes: SleepLogSavedEvent     --> [DashboardNotifier, DayScoreNotifier]
  +-- subscribes: MoodLoggedEvent        --> [DashboardNotifier, DayScoreNotifier]
  +-- subscribes: GoalProgressUpdatedEvent --> [DashboardNotifier]
```

## Training Day Nutrition Adjustment Flow

```
WorkoutCompletedEvent received
  |
  v
NutritionDao.getActiveGoal(today)
  |
  +-- [no active goal] --> log warning, return
  |
  +-- [goal found]
        |
        v
        adjusted = NutritionGoal(
          caloriesKcal: (goal.caloriesKcal * 1.15).round(),
          proteinG:     goal.proteinG * 1.20,
          carbsG:       goal.carbsG   * 1.10,
          fatG:         goal.fatG,          // unchanged
          waterMl:      goal.waterMl,
          effectiveDate: today,
        )
        |
        v
        NutritionDao.insertNutritionGoal(adjusted)
```

## AI Chat Flow

```
User taps "Enviar" in ChatScreen
  |
  v
AINotifier.sendMessage(conversationId, userText)
  |
  v
AIDao.insertMessage(role='user', content=userText)
  |
  v
buildAIContext() --> system prompt string (Spanish)
  |
  v
AIProvider.sendMessage(prompt=userText, systemContext=systemPrompt)
  |
  v
Stream<String> chunks --> accumulated into fullResponse
  |
  v
AIDao.insertMessage(role='assistant', content=fullResponse)
  |
  v
UI updates via stream (each chunk emitted to UI)
```

## Backup / Import Flow

```
Export:
  BackupEngine.createZip(
    manifest: { modules: ['intelligence', ...] },
    moduleJsons: {
      'intelligence': AIBackupHandler.exportRecords()  --> JSON array
    }
  )

Import:
  BackupEngine.extractModuleData(zipBytes, ['intelligence'])
  |
  v
  AIBackupHandler.importRecords(records)
  |
  +-- for each record:
        try insert --> Success: inserted++
        duplicate key --> skipped++
        other error  --> failed++
  |
  v
  return BackupImportModuleResult
```

## Context Builder Output Example (Spanish)

```
Eres un asistente de vida inteligente integrado en LifeOS.
Contexto actual del usuario:
- Puntuacion del dia: 78/100
- Calorias: 1,850 de 2,200 kcal consumidas hoy
- Presupuesto: 65% utilizado este mes
- Rachas activas: Ejercicio (12 dias), Meditacion (5 dias)
- Ultimo puntaje de sueno: 82/100
- Ultimo estado de animo: 7/10
Responde siempre en espanol. Se conciso y motivador.
```
