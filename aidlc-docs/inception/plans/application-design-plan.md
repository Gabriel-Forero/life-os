# Application Design Plan — LifeOS

## Plan Overview
Define the component architecture, service layer, provider dependency graph, and cross-module communication for a Flutter/Riverpod/Drift app with 6 modules + transversal layers.

---

## Questions

### Question 1
Should there be a repository layer between Drift DAOs and Riverpod Notifiers?

A) Yes — Repository pattern: Drift DAO -> Repository -> Notifier -> UI. Repositories abstract data access, making it easy to swap data sources or add caching
B) No — Direct access: Drift DAO -> Notifier -> UI. Simpler, fewer files, Drift already provides a clean abstraction
C) Hybrid — Repository for modules that talk to external APIs (Nutrition with Open Food Facts, Intelligence with AI providers), direct DAO access for purely local modules
X) Other (please describe after [Answer]: tag below)

[Answer]: C

**Decision**: Híbrido — Repository solo donde hay APIs externas

**Rationale**: Los módulos puramente locales (Finanzas, Gym, Hábitos, Sueño, Mental, Goals, Dashboard) acceden a Drift directamente desde el Notifier, evitando boilerplate innecesario. Los módulos que interactúan con APIs externas (Nutrición→Open Food Facts para barcode, Intelligence→OpenAI/Anthropic/Gemini, Connect→Health/Calendar) usan un Repository que abstrae si los datos vienen de la DB local o de una API. Esto permite:

- Módulos locales: `Drift DAO → Notifier → UI` (simple, menos archivos)
- Módulos con API: `Drift DAO + API Client → Repository → Notifier → UI` (flexible, testeable)

**Módulos con Repository**:
| Módulo | API Externa | Repository |
|---|---|---|
| Nutrición | Open Food Facts (barcode) | NutritionRepository |
| Intelligence | OpenAI / Anthropic / Gemini | AIRepository |
| Connect | Health, Calendar, Exchange Rate | HealthRepository, CalendarRepository |

**Módulos sin Repository (DAO directo)**:
| Módulo | Acceso |
|---|---|
| Finanzas | FinanceDao → FinanceNotifier |
| Gimnasio | GymDao → GymNotifier |
| Hábitos | HabitsDao → HabitsNotifier |
| Sueño | SleepDao → SleepNotifier |
| Mental | MentalDao → MentalNotifier |
| Goals | GoalsDao → GoalsNotifier |
| Dashboard | Lee de otros Notifiers (no tiene DAO propio) |

---

### Question 2
How should modules communicate with each other (e.g., Gym completing a workout triggers Habits check-in)?

A) Shared Riverpod providers — modules watch each other's providers directly (tight coupling but simple)
B) Event/Stream bus — modules emit events, others subscribe (loose coupling, more setup)
C) Service layer — a cross-module service (e.g., IntegrationService) orchestrates cross-module logic
X) Other (please describe after [Answer]: tag below)

[Answer]: B

**Decision**: Event/Stream bus — acoplamiento bajo entre módulos

**Rationale**: Cada módulo emite eventos tipados cuando ocurre algo relevante (WorkoutCompleted, ExpenseAdded, HabitCheckedIn, SleepLogSaved, etc.) a un bus central. Otros módulos se suscriben a los eventos que les interesan. Esto logra acoplamiento bajo: Gym no sabe que Hábitos existe, solo emite `WorkoutCompletedEvent`. Hábitos escucha ese evento y decide si auto-marcar un hábito. Agregar nuevas integraciones cross-módulo no requiere modificar módulos existentes.

**Eventos cross-módulo identificados**:
| Evento | Emisor | Suscriptor(es) | Acción |
|---|---|---|---|
| `WorkoutCompletedEvent` | Gym | Hábitos, Nutrición | Auto-check hábito gym, ajustar macros |
| `ExpenseAddedEvent(category)` | Finanzas | Nutrición | Si categoría=Comida, sugerir log de comida |
| `BudgetThresholdEvent(%)` | Finanzas | Dashboard, Notifications | Mostrar alerta, enviar notificación |
| `HabitCheckedInEvent` | Hábitos | Goals, Dashboard | Actualizar progreso de sub-meta, actualizar dashboard |
| `SleepLogSavedEvent` | Sueño | Goals, Dashboard | Actualizar métricas, recalcular Day Score |
| `MoodLoggedEvent` | Mental | Goals, Dashboard | Actualizar métricas |
| `GoalProgressUpdatedEvent` | Goals | Dashboard | Actualizar vista de metas |

**Implementación**: Clase `EventBus` como Riverpod provider singleton con `StreamController` tipado. Cada módulo inyecta el EventBus via Riverpod y emite/escucha eventos.

```dart
// Ejemplo conceptual
class EventBus {
  final _controller = StreamController<AppEvent>.broadcast();
  Stream<T> on<T extends AppEvent>() => _controller.stream.whereType<T>();
  void emit(AppEvent event) => _controller.add(event);
  void dispose() => _controller.close();
}
```

---

### Question 3
How should errors be handled across the app?

A) Result type pattern — functions return Result<Success, Failure> instead of throwing exceptions. UI handles both cases explicitly
B) Try/catch with custom exceptions — throw typed exceptions (DatabaseException, NetworkException, ValidationException), catch in Notifiers, expose error state to UI
C) AsyncValue (Riverpod built-in) — use Riverpod's AsyncValue which has data/loading/error states natively. Combine with typed exceptions for specific error handling
X) Other (please describe after [Answer]: tag below)

[Answer]: C (AsyncValue + Result)

**Decision**: AsyncValue (Riverpod) para UI + Result type para lógica de negocio

**Rationale**: Dos capas de error handling que se complementan:

1. **Capa de negocio (DAOs, Repositories, Services)**: Retornan `Result<T, AppFailure>` — un sealed class que obliga a manejar ambos casos (éxito o fallo). Los fallos son tipados: `DatabaseFailure`, `NetworkFailure`, `ValidationFailure`, `NotFoundFailure`. Nunca se lanzan excepciones en la capa de negocio.

2. **Capa de UI (Notifiers → Widgets)**: Los Notifiers convierten `Result` en `AsyncValue` de Riverpod, que tiene estados `data`, `loading`, y `error` nativos. Los widgets usan `.when(data:, loading:, error:)` para renderizar cada estado. Los errores se muestran al usuario con mensajes localizados, nunca stack traces.

**Ejemplo conceptual**:
```dart
// Capa de negocio
sealed class AppFailure {
  String get userMessage;
}
class ValidationFailure extends AppFailure { ... }
class DatabaseFailure extends AppFailure { ... }
class NetworkFailure extends AppFailure { ... }

typedef Result<T> = ({T? data, AppFailure? failure});

// DAO retorna Result
Future<Result<Transaction>> saveTransaction(TransactionData data) { ... }

// Notifier convierte Result → AsyncValue
class FinanceNotifier extends AsyncNotifier<FinanceState> {
  Future<void> addTransaction(TransactionData data) async {
    state = const AsyncLoading();
    final result = await ref.read(financeDaoProvider).saveTransaction(data);
    if (result.failure != null) {
      state = AsyncError(result.failure!, StackTrace.current);
    } else {
      state = AsyncData(updatedState);
    }
  }
}

// Widget usa .when()
ref.watch(financeProvider).when(
  data: (state) => TransactionList(state.transactions),
  loading: () => LoadingSpinner(),
  error: (err, _) => ErrorCard(message: (err as AppFailure).userMessage),
);
```

**Beneficios**:
- Errores de negocio son explícitos y tipados (no se pierden en `catch(e)` genérico)
- UI siempre muestra loading/error/data de forma consistente vía AsyncValue
- Mensajes de error son user-friendly y localizables
- Stack traces nunca llegan al usuario (NFR-08 compliance)

---

## Execution Steps (after answers)

- [x] Step 1: Answer 3 architecture questions ✅
- [x] Step 2: Define component architecture (modules, core, shared) ✅
- [x] Step 3: Define Drift database schema and table relationships ✅ — 35 tables
- [x] Step 4: Define Riverpod provider hierarchy and dependencies ✅ — 31 providers
- [x] Step 5: Define EventBus and cross-module communication ✅ — 7 events
- [x] Step 6: Define error handling patterns (Result + AsyncValue) ✅
- [x] Step 7: Define component methods and interfaces ✅ — 150+ methods
- [x] Step 8: Create dependency matrix ✅ — 12x12 matrix
- [x] Step 9: Generate all design artifacts ✅ — 5 files
- [x] Step 10: Consolidate into application-design.md ✅

---

*Plan updated: 2026-04-03*
*Decisions: Hybrid repository, Event bus, AsyncValue + Result*
