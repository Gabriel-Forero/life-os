# Functional Design Plan — Unit 1: Finance

## Unit Context
- **Unit**: 1 — Finance
- **Stories**: FIN-01 to FIN-15 (12 MVP + 2 Phase 2)
- **Drift Tables**: 5 (transactions, categories, budgets, savings_goals, recurring_transactions)
- **Notifier**: FinanceNotifier
- **DAO**: FinanceDao
- **Dependencies**: Unit 0 (Core Foundation)
- **EventBus**: Emits ExpenseAddedEvent, BudgetThresholdEvent

## Functional Design Steps

- [x] **Step 1**: Define domain entities with all fields, types, constraints, and defaults (5 Drift tables + input DTOs + FinanceState)
- [x] **Step 2**: Define business rules for transactions, categories, budgets, charts, and savings goals
- [x] **Step 3**: Define business logic flows (add transaction, budget threshold check, recurring processing, chart data computation)
- [x] **Step 4**: Define PBT testable properties for Finance domain

## Questions

The following questions need answers to produce a complete functional design. Please edit this file adding your answer after each `[Answer]:` tag.

---

### Q1: Transaction Amount Precision
Transactions involve currency amounts. How should amounts be stored internally?

A) **As `int` in cents** — Store COP as integers (e.g., $3.500.000 → 3500000). Avoids floating-point rounding errors. Display formats back to currency string.
B) **As `double`** — Store as Dart double. Simpler code but risk of floating-point precision issues for large amounts.
C) **As `int` in the smallest unit** — Same as A but using the currency's smallest unit (for COP that's 1 peso, so $3.500.000 → 3500000).

[Answer]: A

**Decision**: `int` en centavos. Almacenar $3.500.000 COP como `3500000`.

**Rationale**: Los errores de punto flotante (`0.1 + 0.2 = 0.30000000000000004`) son inaceptables en finanzas. `int` en centavos elimina el problema completamente. La UI formatea dividiendo entre 100 para monedas con decimales (USD, EUR) o directamente para COP. Todas las operaciones (sum, compare, budget threshold) son aritméticas enteras exactas. Para COP la unidad mínima es 1 peso, así que 1 centavo = 1 peso en la práctica.

**Alternatives Discarded**:
- B (double): Riesgo real de errores acumulados en sumas de cientos de transacciones. Inaceptable para un módulo financiero.
- C (smallest unit): Funcionalmente igual a A para COP. Se elige A porque "centavos" es el término estándar en la industria.

---

### Q2: Category Deletion with Existing Transactions
FIN-05 Scenario 3 says deleting a category with transactions requires reassignment. What happens to budgets linked to the deleted category?

A) **Budget also deleted** — Delete the budget for that category since the category no longer exists.
B) **Budget reassigned** — Ask the user to also reassign the budget to the same target category.
C) **Budget deleted, no reassignment** — Only transactions are reassigned. Budgets for deleted categories are simply removed.

[Answer]: A

**Decision**: Budget también se elimina cuando se borra la categoría.

**Rationale**: Un budget sin categoría no tiene sentido funcional — ¿contra qué transacciones se compararía? Al borrar la categoría y reasignar las transacciones a otra categoría, el budget de la categoría eliminada queda huérfano. Eliminarlo es lo más limpio. Si el usuario quiere presupuestar la nueva categoría destino, crea un nuevo budget. El flujo de confirmación muestra: "Esta categoría tiene X transacciones y 1 budget. Las transacciones se moverán a [categoría destino]. El budget se eliminará."

**Alternatives Discarded**:
- B (budget reasignado): Complica la UX — el usuario tendría que elegir destino para transacciones Y para el budget. Además, fusionar dos budgets (el existente del destino + el reasignado) genera confusión sobre montos.
- C (budget sin reassignment): Mismo resultado que A pero con nombre diferente.

---

### Q3: Predefined Categories — Editability
FIN-06 defines predefined categories (Alimentacion, Transporte, Entretenimiento, Salud, Hogar, Educacion, Ropa, Servicios, Otros). Can users modify predefined categories?

A) **Fully editable** — Users can rename, change icon/color, or delete predefined categories.
B) **Partially editable** — Users can change icon/color but cannot rename or delete predefined categories.
C) **Read-only** — Predefined categories cannot be modified or deleted. Users can only add custom ones.

[Answer]: B

**Decision**: Parcialmente editables — icono y color se pueden cambiar, nombre y borrado no.

**Rationale**: Las categorías predefinidas sirven como vocabulario estándar para reportes, budgets, y futuras features de Intelligence (ej: "gastas más en Alimentación que el promedio"). Permitir cambiar icono y color respeta la personalización visual sin romper la consistencia semántica. El nombre "Alimentación" siempre significa comida, lo que permite comparaciones entre periodos y eventuales benchmarks. Las categorías custom del usuario son completamente editables y borrables.

**Alternatives Discarded**:
- A (fully editable): Si el usuario renombra "Alimentación" a "Comida rápida", los reportes históricos pierden coherencia y las futuras sugerencias de AI se rompen.
- C (read-only): Demasiado restrictivo — los usuarios quieren personalizar al menos los iconos y colores para sentir la app como suya.

---

### Q4: Budget Period
FIN-07 mentions "monthly budget". Is the budget always calendar-month based?

A) **Calendar month only** — Budgets always run from the 1st to the last day of the month.
B) **Custom period** — User can set a budget start date (e.g., from the 15th to the 14th for users paid mid-month).

[Answer]: A

**Decision**: Mes calendario siempre (1ro al último día del mes).

**Rationale**: Alineado con cómo la mayoría de personas piensan en presupuestos ("este mes gasté X"). Simplifica las queries de agregación (`WHERE date >= firstOfMonth AND date <= lastOfMonth`), la UI de comparación mes a mes, y la lógica de threshold alerts. Las gráficas (Q6) también usan mes calendario como default, manteniendo consistencia. Custom periods agregan complejidad significativa (¿qué pasa con meses de diferente duración? ¿ciclos que cruzan año?) sin beneficio claro para el MVP.

**Alternatives Discarded**:
- B (custom period): Útil para quienes cobran quincenalmente, pero agrega complejidad en queries, UI de visualización, y edge cases (meses de 28-31 días). Puede agregarse como Post-MVP si hay demanda.

---

### Q5: Transaction Default Category
FIN-02 Scenario 3 says expenses without a category default to "Otros". What about income without a category?

A) **Same behavior** — Income without a category also defaults to "Otros".
B) **Separate default** — Income defaults to a different category like "General" or "Sin categoria".
C) **Category required for income** — Income transactions must have a category selected (no default).

[Answer]: B

**Decision**: Categoría default separada para ingresos — "Salario" como principal, con "Freelance", "Regalo", "Inversión", "Otro ingreso".

**Rationale**: Ingresos y gastos son conceptos distintos que merecen categorías separadas. Mostrar "Alimentación" o "Transporte" como opciones al registrar un ingreso confunde al usuario. La tabla `categories` usa un campo `type` (`income` vs `expense`) para separar los dos conjuntos. "Salario" como default de ingresos es más descriptivo que "Otros" — la mayoría de registros de ingreso de los 3 personas (Camila, Andrés, Laura) son salarios mensuales.

**Alternatives Discarded**:
- A (mismo "Otros"): Mezclar categorías de ingreso y gasto genera confusión en pickers y reportes.
- C (category required): Fricción innecesaria. El objetivo es registrar ingresos rápido; si el usuario no especifica, "Salario" es un default razonable.

---

### Q6: Chart Data Scope
FIN-10 to FIN-12 define three charts. What's the default time range when first opening the financial dashboard?

A) **Current month** — Show data for the current calendar month.
B) **Last 30 days** — Show a rolling 30-day window.
C) **Since first transaction** — Show all data since the user's first transaction.

[Answer]: A

**Decision**: Mes actual como rango default.

**Rationale**: Consistente con Q4 (periodo de presupuesto = mes calendario). El usuario abre el dashboard financiero y ve inmediatamente cómo va su gasto del mes actual vs su presupuesto. Esto es lo más accionable — "¿cuánto me queda este mes?". Opciones de cambio disponibles en un selector: mes actual, mes anterior, últimos 3 meses, rango custom. El selector es persistente por sesión (vuelve a mes actual al relanzar la app) para mantener simplicidad.

**Alternatives Discarded**:
- B (últimos 30 días): No se alinea con el periodo del presupuesto (mes calendario). Si el budget es enero, pero las gráficas muestran dic 15 - ene 14, la comparación no cuadra.
- C (todo el historial): Demasiada data para un vistazo rápido. Útil como opción explícita pero no como default.

---

### Q7: Savings Goals — Contribution Source
FIN-14 defines savings goals. How are contributions made?

A) **Manual contributions only** — User manually adds an amount to a goal (separate from regular transactions).
B) **Linked to transactions** — User can tag an expense/income as a savings goal contribution.
C) **Automatic from income** — A percentage of each income is automatically allocated (configurable per goal).

[Answer]: A

**Decision**: Contribuciones manuales solamente.

**Rationale**: El usuario agrega contribuciones manualmente ("Hoy aparté $100.000 para mi meta de emergencia"). La app calcula y muestra cuánto debería ahorrar mensualmente: `(meta - progreso) / meses_restantes`. Esto es lo más simple y transparente — el usuario tiene control total sobre cuándo y cuánto aporta. No hay ambigüedad sobre qué transacción es "ahorro" vs "gasto normal". La contribución se registra como un `SavingsContribution` separado de transacciones, con fecha, monto, y nota opcional.

**Alternatives Discarded**:
- B (linked to transactions): Agrega complejidad al flujo de registro de transacciones (¿cada gasto debería preguntar "¿es para una meta?"?). Contamina la UX del max-3-taps expense flow de FIN-02.
- C (automatic from income): Demasiado opinionado. No todos los ingresos son iguales, y auto-deducir sin contexto genera números confusos en el dashboard financiero.
