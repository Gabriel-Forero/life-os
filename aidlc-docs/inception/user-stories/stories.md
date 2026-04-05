# LifeOS — User Stories

## Table of Contents

| # | Epic | Code | Phase | Stories |
|---|------|------|-------|---------|
| 1 | [Onboarding & Setup](#epic-1-onb--onboarding--setup) | ONB | MVP | 7 |
| 2 | [Finanzas Personales](#epic-2-fin--finanzas-personales) | FIN | MVP | 14 |
| 3 | [Gimnasio & Fitness](#epic-3-gym--gimnasio--fitness) | GYM | MVP | 15 |
| 4 | [Nutricion](#epic-4-nut--nutricion) | NUT | MVP | 11 |
| 5 | [Habitos](#epic-5-hab--habitos) | HAB | MVP | 10 |
| 6 | [Dashboard Unificado](#epic-6-dash--dashboard-unificado) | DASH | MVP | 4 |
| 7 | [Sueno + Energia](#epic-7-slp--sueno--energia) | SLP | Phase 2 | 10 |
| 8 | [Bienestar Mental](#epic-8-mnt--bienestar-mental) | MNT | Phase 2 | 7 |
| 9 | [Life Goals](#epic-9-goal--life-goals) | GOAL | Phase 2 | 7 |
| 10 | [Integraciones Cross-Modulo](#epic-10-int--integraciones-cross-modulo) | INT | Cross-cutting | 7 |
| | **Total** | | | **92** |

---

## Personas Reference

| Persona | Age | Platform | Priorities |
|---------|-----|----------|------------|
| **Camila** | 23 | Android | Finance > Habits > Gym |
| **Andres** | 28 | iPhone | Gym > Nutrition > Sleep |
| **Laura** | 32 | Android | Finance > Mental > Habits |

---

## Epic 1: ONB — Onboarding & Setup

### ONB-01: First Launch Welcome Screen
**As a** new user (Camila), **I want to** see a welcoming screen when I open the app for the first time, **So that** I understand what LifeOS is and feel motivated to set it up.
**Priority**: MVP | **Epic**: Onboarding | **Persona**: Camila | **FR**: FR-39

**Scenario 1: First-time launch**
- Given la app se ha instalado y nunca se ha abierto antes
- When abro LifeOS por primera vez
- Then veo una pantalla de bienvenida con el logo de LifeOS, un mensaje motivacional y un boton "Comenzar"

**Scenario 2: App already configured**
- Given ya complete el onboarding anteriormente
- When abro LifeOS
- Then voy directamente al dashboard sin ver la pantalla de bienvenida

**Scenario 3: App reinstalled without backup**
- Given desinstale y reinstale la app sin hacer backup
- When abro LifeOS
- Then veo la pantalla de bienvenida como si fuera la primera vez

---

### ONB-02: Language Selection
**As a** new user (Camila), **I want to** select my preferred language (Spanish or English) during setup, **So that** the entire app appears in my language.
**Priority**: MVP | **Epic**: Onboarding | **Persona**: Camila | **FR**: FR-39

**Scenario 1: Select Spanish**
- Given estoy en la pantalla de seleccion de idioma
- When selecciono "Espanol"
- Then toda la interfaz de la app cambia a espanol y el idioma se guarda en mis preferencias

**Scenario 2: Select English**
- Given estoy en la pantalla de seleccion de idioma
- When selecciono "English"
- Then toda la interfaz de la app cambia a ingles y el idioma se guarda en mis preferencias

**Scenario 3: System language detection**
- Given mi dispositivo esta configurado en espanol
- When llego a la pantalla de seleccion de idioma
- Then "Espanol" aparece preseleccionado pero puedo cambiarlo

---

### ONB-03: Name Input
**As a** new user (Andres), **I want to** enter my name during setup, **So that** the app can personalize greetings and messages for me.
**Priority**: MVP | **Epic**: Onboarding | **Persona**: Andres | **FR**: FR-39

**Scenario 1: Enter valid name**
- Given estoy en la pantalla de ingreso de nombre
- When escribo "Andres" y presiono "Continuar"
- Then mi nombre se guarda y la app me muestra "Hola, Andres" en la siguiente pantalla

**Scenario 2: Empty name**
- Given estoy en la pantalla de ingreso de nombre
- When dejo el campo vacio y presiono "Continuar"
- Then veo un mensaje "Por favor ingresa tu nombre" y no puedo avanzar

**Scenario 3: Name with special characters**
- Given estoy en la pantalla de ingreso de nombre
- When escribo "Maria Jose" con espacio o "Andres" con tilde
- Then el nombre se acepta correctamente sin errores

---

### ONB-04: Module Selection
**As a** new user (Laura), **I want to** choose which modules I want to use during setup, **So that** I only see features relevant to my goals.
**Priority**: MVP | **Epic**: Onboarding | **Persona**: Laura | **FR**: FR-39

**Scenario 1: Select multiple modules**
- Given estoy en la pantalla de seleccion de modulos con opciones: Finanzas, Gimnasio, Nutricion, Habitos, Sueno, Bienestar Mental
- When selecciono "Finanzas", "Bienestar Mental" y "Habitos"
- Then esos tres modulos se activan y los demas quedan ocultos en el dashboard

**Scenario 2: Select no modules**
- Given estoy en la pantalla de seleccion de modulos
- When no selecciono ningun modulo y presiono "Continuar"
- Then veo un mensaje "Selecciona al menos un modulo para comenzar"

**Scenario 3: Change module selection later**
- Given complete el onboarding con solo "Finanzas" activo
- When voy a Configuracion > Modulos y activo "Habitos"
- Then el modulo de Habitos aparece en mi dashboard y menu de navegacion

---

### ONB-05: Currency Selection
**As a** new user (Camila), **I want to** select my currency with COP as the default, **So that** all financial data uses my local currency.
**Priority**: MVP | **Epic**: Onboarding | **Persona**: Camila | **FR**: FR-39

**Scenario 1: Accept default currency**
- Given estoy en la pantalla de seleccion de moneda y COP (Peso Colombiano) esta preseleccionado
- When presiono "Continuar" sin cambiar nada
- Then COP se guarda como mi moneda y todos los valores financieros se muestran con el simbolo $

**Scenario 2: Change to different currency**
- Given estoy en la pantalla de seleccion de moneda
- When busco "USD" y lo selecciono
- Then USD se guarda como mi moneda y los valores financieros se muestran con el formato USD correspondiente

**Scenario 3: Search for currency**
- Given estoy en la pantalla de seleccion de moneda
- When escribo "Euro" en el campo de busqueda
- Then veo EUR (Euro) en los resultados y puedo seleccionarlo

---

### ONB-06: Onboarding Tour
**As a** new user (Laura), **I want to** see a brief guided tour of the main features, **So that** I know how to navigate and use the app.
**Priority**: MVP | **Epic**: Onboarding | **Persona**: Laura | **FR**: FR-39

**Scenario 1: Complete tour**
- Given termine la configuracion inicial y tengo 3 modulos activos
- When la app me muestra el tour guiado
- Then veo 3-5 pantallas con explicaciones breves de cada funcion principal y puedo avanzar con "Siguiente"

**Scenario 2: Skip tour**
- Given la app me muestra la primera pantalla del tour
- When presiono "Omitir"
- Then voy directamente al dashboard sin ver el resto del tour

**Scenario 3: Tour adapts to selected modules**
- Given seleccione solo los modulos "Finanzas" y "Habitos"
- When la app me muestra el tour
- Then solo veo informacion relevante a Finanzas y Habitos, no de modulos que no seleccione

---

### ONB-07: First Empty States
**As a** new user (Camila), **I want to** see helpful empty states when I open each module for the first time, **So that** I understand what to do and feel guided.
**Priority**: MVP | **Epic**: Onboarding | **Persona**: Camila | **FR**: FR-39

**Scenario 1: Empty finance module**
- Given acabo de completar el onboarding y abro el modulo de Finanzas
- When veo la pantalla sin transacciones
- Then veo una ilustracion, un mensaje "Aun no tienes transacciones" y un boton destacado "Agregar primera transaccion"

**Scenario 2: Empty gym module**
- Given abro el modulo de Gimnasio por primera vez
- When no tengo rutinas creadas
- Then veo un mensaje "Crea tu primera rutina" con un boton para empezar y una sugerencia de explorar la biblioteca de ejercicios

**Scenario 3: After first entry**
- Given estoy en el empty state del modulo de Finanzas
- When agrego mi primera transaccion
- Then el empty state desaparece y veo mi transaccion en la lista

---

## Epic 2: FIN — Finanzas Personales

### FIN-01: Add Income
**As a** user focused on finances (Laura), **I want to** register an income transaction, **So that** I can track all money I receive.
**Priority**: MVP | **Epic**: Finanzas | **Persona**: Laura | **FR**: FR-02

**Scenario 1: Add income with category**
- Given estoy en el modulo de Finanzas
- When presiono "+", selecciono "Ingreso", escribo $3.500.000, selecciono categoria "Salario" y confirmo
- Then el ingreso se guarda, el balance se actualiza sumando $3.500.000 y veo la transaccion en la lista

**Scenario 2: Add income with note**
- Given estoy registrando un ingreso de $500.000
- When agrego la nota "Freelance diseno web" y confirmo
- Then el ingreso se guarda con la nota visible en el detalle de la transaccion

**Scenario 3: Add income with zero amount**
- Given estoy registrando un nuevo ingreso
- When dejo el monto en $0 y presiono guardar
- Then veo un mensaje "El monto debe ser mayor a $0" y no se guarda la transaccion

---

### FIN-02: Add Expense (Max 3 Taps)
**As a** user who tracks spending daily (Camila), **I want to** register an expense in maximum 3 taps, **So that** the process is fast and I maintain the habit.
**Priority**: MVP | **Epic**: Finanzas | **Persona**: Camila | **FR**: FR-03

**Scenario 1: Quick expense (3 taps)**
- Given estoy en el modulo de Finanzas
- When presiono "+", ingreso $25.000, selecciono categoria "Transporte" y presiono "Guardar"
- Then el gasto se registra en 3 taps y el balance se actualiza restando $25.000

**Scenario 2: Expense with predefined category**
- Given las categorias predefinidas incluyen Alimentacion, Transporte, Entretenimiento, Salud, Hogar
- When registro un gasto y selecciono "Alimentacion"
- Then el gasto se guarda con la categoria "Alimentacion" y su icono correspondiente

**Scenario 3: Add expense without selecting category**
- Given estoy registrando un gasto de $15.000
- When no selecciono ninguna categoria y presiono "Guardar"
- Then el gasto se guarda en la categoria "Otros" por defecto

---

### FIN-03: View Transaction List
**As a** user (Laura), **I want to** see a chronological list of all my transactions, **So that** I can review my financial activity.
**Priority**: MVP | **Epic**: Finanzas | **Persona**: Laura | **FR**: FR-04

**Scenario 1: View transactions grouped by date**
- Given tengo 10 transacciones registradas en la ultima semana
- When abro la lista de transacciones
- Then veo las transacciones agrupadas por dia, con las mas recientes primero, mostrando monto, categoria e icono

**Scenario 2: Empty transaction list**
- Given no tengo transacciones registradas
- When abro la lista de transacciones
- Then veo el empty state con mensaje "Aun no tienes transacciones" y boton para agregar

**Scenario 3: Scroll and load more**
- Given tengo 100+ transacciones registradas
- When hago scroll hacia abajo en la lista
- Then se cargan mas transacciones de forma fluida sin lag ni pantalla de carga visible

---

### FIN-04: Edit and Delete Transaction (Swipe)
**As a** user (Laura), **I want to** edit or delete a transaction with un gesto de swipe, **So that** I can correct errors quickly.
**Priority**: MVP | **Epic**: Finanzas | **Persona**: Laura | **FR**: FR-04

**Scenario 1: Swipe to delete**
- Given tengo una transaccion de $50.000 en "Entretenimiento"
- When hago swipe a la izquierda sobre la transaccion y confirmo "Eliminar"
- Then la transaccion se elimina, el balance se actualiza y veo una notificacion "Transaccion eliminada" con opcion "Deshacer"

**Scenario 2: Swipe to edit**
- Given tengo una transaccion de $30.000 en "Transporte"
- When hago swipe a la derecha y se abre el formulario de edicion
- Then puedo cambiar el monto a $35.000, la categoria o la nota y guardar los cambios

**Scenario 3: Undo delete**
- Given acabo de eliminar una transaccion
- When presiono "Deshacer" dentro de los 5 segundos siguientes
- Then la transaccion se restaura con todos sus datos originales y el balance se corrige

---

### FIN-05: Create Custom Category
**As a** user (Camila), **I want to** create categorias personalizadas para mis gastos, **So that** puedo organizar mis finanzas segun mi estilo de vida.
**Priority**: MVP | **Epic**: Finanzas | **Persona**: Camila | **FR**: FR-05

**Scenario 1: Create new category**
- Given estoy en la seccion de categorias
- When presiono "Crear categoria", escribo "Mascota", selecciono un icono de huella y un color verde
- Then la categoria "Mascota" aparece en mi lista de categorias disponibles al registrar transacciones

**Scenario 2: Duplicate category name**
- Given ya existe una categoria llamada "Transporte"
- When intento crear una nueva categoria con el nombre "Transporte"
- Then veo un mensaje "Ya existe una categoria con ese nombre"

**Scenario 3: Delete custom category with transactions**
- Given tengo 5 transacciones en la categoria "Mascota"
- When elimino la categoria "Mascota"
- Then se me pide reasignar las 5 transacciones a otra categoria antes de confirmar la eliminacion

---

### FIN-06: Predefined Categories
**As a** new user (Camila), **I want to** tener categorias predefinidas listas para usar, **So that** puedo empezar a registrar gastos inmediatamente sin configurar nada.
**Priority**: MVP | **Epic**: Finanzas | **Persona**: Camila | **FR**: FR-05

**Scenario 1: View predefined categories**
- Given acabo de activar el modulo de Finanzas
- When voy a registrar mi primer gasto
- Then veo categorias predefinidas: Alimentacion, Transporte, Entretenimiento, Salud, Hogar, Educacion, Ropa, Servicios, Otros — cada una con icono y color

**Scenario 2: Predefined categories coexist with custom**
- Given cree la categoria personalizada "Mascota"
- When voy a registrar un gasto y veo la lista de categorias
- Then veo las categorias predefinidas Y mi categoria "Mascota" en la misma lista

---

### FIN-07: Set Monthly Budget
**As a** user (Laura), **I want to** establecer un presupuesto mensual, **So that** puedo controlar mis gastos y no exceder mis limites.
**Priority**: MVP | **Epic**: Finanzas | **Persona**: Laura | **FR**: FR-06

**Scenario 1: Set global monthly budget**
- Given estoy en Finanzas > Presupuesto
- When establezco un presupuesto mensual de $2.000.000 y guardo
- Then el presupuesto se activa y veo una barra de progreso mostrando cuanto he gastado del total

**Scenario 2: Set budget per category**
- Given estoy configurando mi presupuesto mensual
- When asigno $500.000 a "Alimentacion" y $300.000 a "Transporte"
- Then cada categoria muestra su propia barra de progreso individual

**Scenario 3: Budget resets monthly**
- Given es 1 de abril y mi presupuesto de marzo estaba al 95%
- When abro el modulo de Finanzas el 1 de abril
- Then el progreso del presupuesto se reinicia a $0 gastado de $2.000.000 para el nuevo mes

---

### FIN-08: Budget Alerts
**As a** user (Laura), **I want to** recibir alertas cuando llego al 80% y 100% de mi presupuesto, **So that** puedo ajustar mis gastos a tiempo.
**Priority**: MVP | **Epic**: Finanzas | **Persona**: Laura | **FR**: FR-07

**Scenario 1: Alert at 80%**
- Given mi presupuesto mensual es $2.000.000 y he gastado $1.590.000
- When registro un gasto de $15.000 que lleva mi total a $1.605.000 (80.25%)
- Then recibo una notificacion "Has alcanzado el 80% de tu presupuesto mensual. Te quedan $395.000"

**Scenario 2: Alert at 100%**
- Given mi presupuesto mensual es $2.000.000 y he gastado $1.995.000
- When registro un gasto de $10.000 que lleva mi total a $2.005.000
- Then recibo una notificacion "Has excedido tu presupuesto mensual" y la barra de progreso cambia a color rojo

**Scenario 3: Alert per category budget**
- Given tengo un presupuesto de $500.000 para "Alimentacion" y he gastado $400.000
- When registro un gasto de $5.000 en "Alimentacion" (81%)
- Then recibo una alerta especifica "Has alcanzado el 80% de tu presupuesto de Alimentacion"

---

### FIN-09: Financial Dashboard
**As a** user (Laura), **I want to** ver un resumen financiero con balance, ingresos vs gastos, **So that** tengo una vista rapida de mi situacion financiera.
**Priority**: MVP | **Epic**: Finanzas | **Persona**: Laura | **FR**: FR-08

**Scenario 1: View dashboard with data**
- Given tengo ingresos de $3.500.000 y gastos de $2.100.000 este mes
- When abro el dashboard financiero
- Then veo: Balance $1.400.000, Ingresos $3.500.000 (verde), Gastos $2.100.000 (rojo) y barra de progreso del presupuesto

**Scenario 2: Dashboard with no data this month**
- Given no tengo transacciones en el mes actual
- When abro el dashboard financiero
- Then veo Balance $0, Ingresos $0, Gastos $0 con un mensaje motivacional "Empieza a registrar tus transacciones"

**Scenario 3: Balance updates in real time**
- Given el dashboard muestra Balance $1.400.000
- When registro un gasto de $50.000 y vuelvo al dashboard
- Then el balance se actualiza a $1.350.000 sin necesidad de refrescar manualmente

---

### FIN-10: Charts — Pie by Category
**As a** user (Laura), **I want to** ver un grafico de torta con mis gastos por categoria, **So that** entiendo en que estoy gastando mas.
**Priority**: MVP | **Epic**: Finanzas | **Persona**: Laura | **FR**: FR-09

**Scenario 1: View pie chart**
- Given tengo gastos en 5 categorias este mes
- When abro la seccion de graficos y selecciono "Gastos por Categoria"
- Then veo un grafico de torta con colores por categoria, porcentajes y montos

**Scenario 2: Tap on chart segment**
- Given estoy viendo el grafico de torta
- When toco el segmento de "Alimentacion" (35%)
- Then veo el detalle: "Alimentacion: $735.000 — 35%" y opcionalmente la lista de transacciones de esa categoria

**Scenario 3: Single category dominates**
- Given el 90% de mis gastos estan en "Alimentacion"
- When veo el grafico de torta
- Then las categorias menores al 3% se agrupan como "Otros" para mantener el grafico legible

---

### FIN-11: Charts — Bar Income vs Expenses
**As a** user (Laura), **I want to** ver un grafico de barras comparando ingresos vs gastos mensualmente, **So that** puedo evaluar mi tendencia financiera.
**Priority**: MVP | **Epic**: Finanzas | **Persona**: Laura | **FR**: FR-09

**Scenario 1: View bar chart**
- Given tengo datos de los ultimos 3 meses
- When abro la seccion de graficos y selecciono "Ingresos vs Gastos"
- Then veo barras verdes (ingresos) y rojas (gastos) para cada mes con los montos

**Scenario 2: Month with deficit**
- Given en febrero mis gastos ($2.500.000) superaron mis ingresos ($2.000.000)
- When veo el grafico de barras
- Then la barra roja de febrero es mas alta que la verde y el diferencial se resalta visualmente

---

### FIN-12: Charts — Line Savings
**As a** user (Laura), **I want to** ver un grafico de linea con mi ahorro acumulado, **So that** puedo ver mi progreso de ahorro en el tiempo.
**Priority**: MVP | **Epic**: Finanzas | **Persona**: Laura | **FR**: FR-09

**Scenario 1: Positive savings trend**
- Given he ahorrado $500.000/mes durante 4 meses
- When abro el grafico de linea de ahorro
- Then veo una linea ascendente mostrando el ahorro acumulado de $500K a $2M

**Scenario 2: Month with negative savings**
- Given en marzo gaste mas de lo que ingrese
- When veo el grafico de linea de ahorro
- Then la linea desciende en marzo mostrando la reduccion del ahorro acumulado

---

### FIN-13: Date Range Selector
**As a** user (Laura), **I want to** filtrar mis datos financieros por rango de fecha, **So that** puedo analizar periodos especificos.
**Priority**: MVP | **Epic**: Finanzas | **Persona**: Laura | **FR**: FR-09

**Scenario 1: Select predefined range**
- Given estoy en el dashboard financiero
- When selecciono "Este mes" del selector de rango
- Then todos los datos, graficos y totales se filtran al mes actual

**Scenario 2: Custom date range**
- Given quiero ver datos de un trimestre especifico
- When selecciono "Personalizado" y elijo del 1 de enero al 31 de marzo
- Then todos los datos se filtran a ese rango y las etiquetas muestran "1 Ene - 31 Mar"

**Scenario 3: Range with no data**
- Given selecciono un rango de fechas donde no tengo transacciones
- When aplico el filtro
- Then veo el mensaje "No hay datos para el periodo seleccionado" en lugar de graficos vacios

---

### FIN-14: Savings Goals (Post-MVP)
**As a** user (Laura), **I want to** crear metas de ahorro con monto objetivo y fecha limite, **So that** puedo planificar compras grandes o fondos de emergencia.
**Priority**: Phase 2 | **Epic**: Finanzas | **Persona**: Laura | **FR**: FR-06

**Scenario 1: Create savings goal**
- Given estoy en Finanzas > Metas de Ahorro
- When creo la meta "Fondo de emergencia" con objetivo $5.000.000 y fecha limite diciembre 2026
- Then la meta aparece con barra de progreso en $0 de $5.000.000 y una sugerencia de ahorro mensual

**Scenario 2: Add money to goal**
- Given tengo la meta "Fondo de emergencia" con $1.000.000 ahorrados
- When agrego $500.000 a la meta
- Then el progreso se actualiza a $1.500.000 (30%) y la barra de progreso avanza

**Scenario 3: Goal deadline approaching**
- Given mi meta vence en 30 dias y estoy al 60% del objetivo
- When abro la meta
- Then veo una alerta "Te quedan 30 dias. Necesitas ahorrar $333.333/semana para cumplir tu meta"

---

### FIN-15: Recurring Transactions (Post-MVP)
**As a** user (Laura), **I want to** configurar transacciones recurrentes, **So that** mis gastos fijos se registran automaticamente.
**Priority**: Phase 2 | **Epic**: Finanzas | **Persona**: Laura | **FR**: FR-07

**Scenario 1: Create recurring expense**
- Given estoy creando una nueva transaccion
- When activo "Recurrente", selecciono frecuencia "Mensual" y dia "1"
- Then la transaccion se registra automaticamente el dia 1 de cada mes y se marca como "Recurrente" en la lista

**Scenario 2: Edit recurring transaction**
- Given tengo un gasto recurrente de $150.000 para "Netflix"
- When edito el monto a $180.000
- Then puedo elegir "Solo esta" o "Esta y futuras" y la proxima recurrencia usara el nuevo monto

**Scenario 3: Notification of upcoming recurring**
- Given tengo un gasto recurrente programado para manana
- When recibo la notificacion
- Then dice "Manana se registrara: Netflix $180.000. Toca para ajustar o cancelar"

---

## Epic 3: GYM — Gimnasio & Fitness

### GYM-01: Browse Exercise Library
**As a** fitness enthusiast (Andres), **I want to** explorar una biblioteca con mas de 200 ejercicios, **So that** puedo descubrir nuevos ejercicios para mis rutinas.
**Priority**: MVP | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-10

**Scenario 1: Browse by muscle group**
- Given abro la biblioteca de ejercicios
- When selecciono el grupo muscular "Pecho"
- Then veo todos los ejercicios de pecho con nombre, imagen/animacion y musculos trabajados

**Scenario 2: First launch download**
- Given es la primera vez que abro el modulo de Gimnasio
- When la app detecta que no tengo la biblioteca descargada
- Then se descarga automaticamente la biblioteca de 200+ ejercicios con un indicador de progreso y se almacena localmente

**Scenario 3: Offline access**
- Given ya descargue la biblioteca de ejercicios
- When abro la biblioteca sin conexion a internet
- Then puedo navegar todos los ejercicios normalmente porque estan almacenados localmente

---

### GYM-02: Search and Filter Exercises
**As a** user (Andres), **I want to** buscar y filtrar ejercicios por grupo muscular y equipamiento, **So that** encuentro rapidamente el ejercicio que necesito.
**Priority**: MVP | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-10

**Scenario 1: Search by name**
- Given estoy en la biblioteca de ejercicios
- When escribo "press" en el buscador
- Then veo resultados como "Press de banca", "Press militar", "Press inclinado"

**Scenario 2: Filter by equipment**
- Given quiero entrenar solo con mancuernas
- When aplico el filtro de equipamiento "Mancuernas"
- Then solo veo ejercicios que se realizan con mancuernas

**Scenario 3: No results found**
- Given escribo "zxywqr" en el buscador
- When la busqueda no encuentra coincidencias
- Then veo el mensaje "No se encontraron ejercicios. Intenta con otro termino o crea un ejercicio personalizado"

---

### GYM-03: Create Custom Exercise
**As a** user (Andres), **I want to** crear ejercicios personalizados, **So that** puedo agregar ejercicios que no estan en la biblioteca.
**Priority**: MVP | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-10

**Scenario 1: Create exercise with all fields**
- Given estoy en la biblioteca de ejercicios
- When presiono "Crear ejercicio", ingreso nombre "Sentadilla Bulgara con Mancuerna", selecciono grupo muscular "Piernas" y equipamiento "Mancuernas"
- Then el ejercicio personalizado aparece en la biblioteca con un indicador de "Personalizado"

**Scenario 2: Duplicate exercise name**
- Given ya existe "Press de banca" en la biblioteca
- When intento crear un ejercicio con el mismo nombre
- Then veo un mensaje "Ya existe un ejercicio con ese nombre"

**Scenario 3: Custom exercise in search results**
- Given cree el ejercicio personalizado "Sentadilla Bulgara con Mancuerna"
- When busco "Sentadilla" en la biblioteca
- Then mi ejercicio personalizado aparece junto a los ejercicios predefinidos de sentadilla

---

### GYM-04: Create Routine
**As a** user (Andres), **I want to** crear una rutina con nombre, ejercicios, series, repeticiones y descanso, **So that** puedo planificar mis entrenamientos.
**Priority**: MVP | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-11

**Scenario 1: Create full routine**
- Given estoy en la seccion de rutinas
- When creo una rutina "Push Day", agrego Press de banca (4x10, 90s descanso), Aperturas (3x12, 60s descanso), Fondos (3x15, 60s descanso)
- Then la rutina se guarda y aparece en mi lista de rutinas con el resumen de ejercicios

**Scenario 2: Reorder exercises**
- Given estoy editando mi rutina "Push Day" con 5 ejercicios
- When mantengo presionado "Fondos" y lo arrastro a la primera posicion
- Then el orden de los ejercicios se actualiza y se guarda

**Scenario 3: Create routine without exercises**
- Given estoy creando una nueva rutina
- When ingreso el nombre "Leg Day" pero no agrego ejercicios y presiono guardar
- Then veo el mensaje "Agrega al menos un ejercicio a tu rutina"

---

### GYM-05: Start Workout from Routine
**As a** user (Andres), **I want to** iniciar un entrenamiento desde una rutina guardada, **So that** tengo la estructura lista y solo registro pesos y repeticiones.
**Priority**: MVP | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-12

**Scenario 1: Start routine workout**
- Given tengo la rutina "Push Day" con 3 ejercicios
- When presiono "Iniciar Entrenamiento" en la rutina
- Then se abre la vista de entrenamiento activo con el primer ejercicio, las series preplaneadas y los pesos de la ultima sesion como referencia

**Scenario 2: Previous weights shown**
- Given la ultima vez hice Press de banca con 60kg x 10
- When inicio "Push Day" y veo Press de banca
- Then veo "Ultima vez: 60kg x 10" como referencia para cada serie

**Scenario 3: Modify during workout**
- Given estoy en un entrenamiento basado en la rutina "Push Day"
- When agrego un ejercicio extra que no estaba en la rutina
- Then el ejercicio se registra en este entrenamiento sin modificar la rutina original

---

### GYM-06: Start Empty Workout
**As a** user (Andres), **I want to** iniciar un entrenamiento vacio sin rutina predefinida, **So that** puedo improvisar mi entrenamiento segun como me sienta.
**Priority**: MVP | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-12

**Scenario 1: Start empty workout**
- Given estoy en la pantalla principal de Gimnasio
- When presiono "Entrenamiento Vacio"
- Then se abre la vista de entrenamiento activo con un cronometro, sin ejercicios, y un boton "Agregar Ejercicio"

**Scenario 2: Add exercises on the fly**
- Given estoy en un entrenamiento vacio
- When presiono "Agregar Ejercicio" y selecciono "Curl de biceps"
- Then el ejercicio aparece en mi entrenamiento con campos para registrar series

**Scenario 3: Cancel empty workout**
- Given inicie un entrenamiento vacio y no he registrado nada
- When presiono "Cancelar" y confirmo
- Then el entrenamiento se descarta sin guardar nada en el historial

---

### GYM-07: Record Set (Weight and Reps)
**As a** user (Andres), **I want to** registrar el peso en kg y repeticiones de cada serie, **So that** tengo un registro preciso de mi progreso.
**Priority**: MVP | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-12

**Scenario 1: Record a set**
- Given estoy en un entrenamiento activo con Press de banca
- When ingreso 80kg y 10 reps en la primera serie y presiono el check
- Then la serie se marca como completada con "80kg x 10" y se habilita la siguiente serie

**Scenario 2: Edit a recorded set**
- Given marque la serie 1 como 80kg x 10 pero me equivoque
- When toco la serie completada y cambio a 80kg x 8
- Then la serie se actualiza a "80kg x 8"

**Scenario 3: Record bodyweight exercise**
- Given el ejercicio es "Fondos" (peso corporal)
- When registro la serie con solo repeticiones: 15 reps
- Then la serie se guarda como "Peso corporal x 15" sin campo de peso

---

### GYM-08: Rest Timer with Haptic Feedback
**As a** user (Andres), **I want to** tener un temporizador de descanso con vibracion al terminar, **So that** mantengo mis descansos consistentes sin mirar la pantalla.
**Priority**: MVP | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-12

**Scenario 1: Auto-start timer after set**
- Given complete una serie y el descanso configurado es 90 segundos
- When marco la serie como completada
- Then el temporizador de 90s inicia automaticamente con cuenta regresiva visible

**Scenario 2: Haptic feedback on timer end**
- Given el temporizador esta en los ultimos 3 segundos
- When llega a 0
- Then el telefono vibra con un patron de haptic feedback distintivo y muestra una alerta visual "Descanso terminado" (en iOS usa Taptic Engine, en Android usa Vibration API)

**Scenario 3: Adjust timer during rest**
- Given el temporizador esta corriendo con 45s restantes
- When presiono "+30s"
- Then el temporizador se extiende a 75s restantes

---

### GYM-09: Mark Set as Warmup
**As a** user (Andres), **I want to** marcar una serie como calentamiento, **So that** no se mezcle con mis series de trabajo en las estadisticas.
**Priority**: MVP | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-12

**Scenario 1: Mark as warmup**
- Given estoy registrando la primera serie de Press de banca con 40kg x 10
- When activo la opcion "Calentamiento" (toggle o etiqueta "W")
- Then la serie se marca visualmente como calentamiento y se excluye del calculo de volumen de trabajo

**Scenario 2: Warmup not in PR calculations**
- Given hice 40kg x 15 como calentamiento y 80kg x 8 como serie de trabajo
- When la app calcula mi PR de Press de banca
- Then solo considera 80kg x 8, no la serie de calentamiento

---

### GYM-10: Complete Workout
**As a** user (Andres), **I want to** finalizar mi entrenamiento y ver un resumen, **So that** puedo revisar lo que hice y sentir satisfaccion.
**Priority**: MVP | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-12

**Scenario 1: Complete workout**
- Given he registrado todas las series de mi entrenamiento de 45 minutos
- When presiono "Finalizar Entrenamiento"
- Then veo un resumen con: duracion total (45 min), numero de ejercicios (5), series totales (20), volumen total (8.500 kg) y puedo guardar

**Scenario 2: New PRs detected**
- Given hice 85kg x 8 en Press de banca y mi record anterior era 80kg x 8
- When finalizo el entrenamiento
- Then el resumen muestra un badge "Nuevo PR! Press de banca: 85kg x 8" con una animacion celebratoria

**Scenario 3: Discard incomplete workout**
- Given inicie un entrenamiento pero solo complete 1 de 5 ejercicios
- When presiono "Finalizar" y la app detecta que faltan ejercicios
- Then me pregunta "Tienes ejercicios sin completar. Guardar entrenamiento parcial o descartar?"

---

### GYM-11: View Workout History
**As a** user (Andres), **I want to** ver mi historial de entrenamientos, **So that** puedo revisar que hice en sesiones anteriores.
**Priority**: MVP | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-13

**Scenario 1: View history list**
- Given he completado 15 entrenamientos en el ultimo mes
- When abro el historial de entrenamientos
- Then veo una lista cronologica con fecha, nombre de rutina (o "Entrenamiento libre"), duracion y numero de ejercicios

**Scenario 2: View workout detail**
- Given veo mi historial y selecciono el entrenamiento del 15 de marzo
- When se abre el detalle
- Then veo cada ejercicio con todas sus series, pesos, repeticiones y cuales fueron de calentamiento

**Scenario 3: History with no workouts**
- Given no he completado ningun entrenamiento
- When abro el historial
- Then veo el empty state "Aun no tienes entrenamientos. Crea una rutina o inicia un entrenamiento vacio"

---

### GYM-12: View Exercise Progress Chart
**As a** user (Andres), **I want to** ver un grafico de progreso por ejercicio, **So that** puedo visualizar mi mejora en el tiempo.
**Priority**: MVP | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-14

**Scenario 1: View progress chart**
- Given he registrado Press de banca en 10 sesiones diferentes
- When abro la pantalla de progreso de Press de banca
- Then veo un grafico de linea con el peso maximo por sesion a lo largo del tiempo

**Scenario 2: Toggle between metrics**
- Given estoy viendo el progreso de Sentadilla
- When cambio la metrica de "Peso maximo" a "Volumen total"
- Then el grafico se actualiza para mostrar el volumen total (peso x reps x series) por sesion

**Scenario 3: Exercise with insufficient data**
- Given solo he hecho "Peso muerto" una vez
- When abro el progreso de Peso muerto
- Then veo un mensaje "Necesitas al menos 2 sesiones para ver el grafico de progreso" con el dato de la unica sesion

---

### GYM-13: Automatic PR Detection
**As a** user (Andres), **I want to** que la app detecte automaticamente mis records personales, **So that** celebro mis logros y monitoreo mi fuerza.
**Priority**: MVP | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-14

**Scenario 1: New weight PR**
- Given mi PR de Press de banca es 80kg x 8
- When en un entrenamiento registro 85kg x 8
- Then la app marca la serie con un icono de PR y al finalizar muestra "Nuevo PR! Press de banca: 85kg x 8"

**Scenario 2: New rep PR**
- Given mi PR de Press de banca con 80kg es 8 reps
- When registro 80kg x 10
- Then la app detecta un nuevo PR de repeticiones para ese peso

**Scenario 3: PR only counts work sets**
- Given marco una serie de 100kg x 5 como calentamiento en Sentadilla
- When mi PR actual es 90kg x 8
- Then la app no registra la serie de calentamiento como nuevo PR

---

### GYM-14: 1RM Calculation (Epley)
**As a** user (Andres), **I want to** ver mi 1RM estimado usando la formula de Epley, **So that** puedo planificar mis cargas de entrenamiento.
**Priority**: MVP | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-14

**Scenario 1: View estimated 1RM**
- Given mi mejor serie de Press de banca es 80kg x 10
- When abro las estadisticas de Press de banca
- Then veo "1RM Estimado: 107kg" calculado con la formula de Epley (80 x (1 + 10/30) = 106.67 redondeado)

**Scenario 2: 1RM updates with new data**
- Given mi 1RM estimado de Sentadilla es 120kg
- When registro una nueva sesion con 100kg x 8
- Then si el nuevo calculo (100 x (1 + 8/30) = 126.67) es mayor, el 1RM se actualiza a 127kg

**Scenario 3: Single rep max (no estimation needed)**
- Given registro una serie de 100kg x 1 en Peso muerto
- When calculo el 1RM
- Then el 1RM real es 100kg (no se aplica formula si las reps son 1)

---

### GYM-15: Body Measurements (Post-MVP)
**As a** user (Andres), **I want to** registrar medidas corporales como peso, porcentaje de grasa, y circunferencias, **So that** puedo seguir mis cambios fisicos.
**Priority**: Phase 2 | **Epic**: Gimnasio | **Persona**: Andres | **FR**: FR-14

**Scenario 1: Record body weight**
- Given estoy en la seccion de medidas corporales
- When ingreso mi peso actual como 78.5kg y la fecha de hoy
- Then la medida se guarda y puedo ver mi historial de peso en un grafico de linea

**Scenario 2: Record multiple measurements**
- Given quiero registrar mis medidas completas
- When ingreso: peso 78.5kg, grasa corporal 15%, cintura 82cm, pecho 100cm, brazo 36cm
- Then todas las medidas se guardan con la fecha y puedo ver cada una en su propio grafico

**Scenario 3: Weight trend analysis**
- Given tengo 8 registros de peso en los ultimos 2 meses
- When abro el grafico de peso
- Then veo la tendencia (subiendo, bajando, estable) y el cambio total desde el primer registro

---

## Epic 4: NUT — Nutricion

### NUT-01: Log Meal (2 Taps)
**As a** user who tracks nutrition (Andres), **I want to** registrar una comida en 2 taps, **So that** el proceso es rapido y no interrumpe mi dia.
**Priority**: MVP | **Epic**: Nutricion | **Persona**: Andres | **FR**: FR-15

**Scenario 1: Quick log from favorites**
- Given tengo "Pechuga de pollo 200g" en mis favoritos
- When presiono "+" y selecciono "Pechuga de pollo 200g" de favoritos
- Then la comida se registra con 2 taps: Proteina 46g, Calorias 330, y se asigna al tipo de comida segun la hora del dia

**Scenario 2: Quick log with portion adjustment**
- Given selecciono "Arroz blanco" de mis favoritos (porcion default 150g)
- When ajusto la porcion a 200g y confirmo
- Then los macros se recalculan proporcionalmente y la comida se registra

**Scenario 3: Log meal without search**
- Given es hora del almuerzo y presiono "+" en Nutricion
- When la app sugiere mis comidas frecuentes para almuerzo
- Then puedo seleccionar una comida reciente con un solo tap adicional

---

### NUT-02: Search Food Item
**As a** user (Andres), **I want to** buscar alimentos por nombre, **So that** puedo encontrar la informacion nutricional correcta.
**Priority**: MVP | **Epic**: Nutricion | **Persona**: Andres | **FR**: FR-15

**Scenario 1: Search and find**
- Given estoy en la pantalla de agregar comida
- When escribo "banana" en el buscador
- Then veo resultados como "Banana (mediana, 118g)", "Banana (grande, 136g)" con calorias y macros resumidos

**Scenario 2: Search with no results**
- Given escribo "xyzfoodnon" en el buscador
- When no se encuentran coincidencias
- Then veo "No se encontraron resultados. Crea un alimento personalizado" con un boton para crear

**Scenario 3: Search shows recent items first**
- Given registre "Pechuga de pollo" 3 veces esta semana
- When escribo "pech" en el buscador
- Then "Pechuga de pollo" aparece como primer resultado por ser un alimento reciente/frecuente

---

### NUT-03: Add Food to Favorites
**As a** user (Andres), **I want to** marcar alimentos como favoritos, **So that** puedo acceder rapidamente a lo que como frecuentemente.
**Priority**: MVP | **Epic**: Nutricion | **Persona**: Andres | **FR**: FR-16

**Scenario 1: Add to favorites**
- Given estoy viendo el detalle de "Pechuga de pollo 200g"
- When presiono el icono de corazon/estrella
- Then el alimento se agrega a mis favoritos y el icono cambia a estado activo

**Scenario 2: View favorites list**
- Given tengo 8 alimentos favoritos guardados
- When abro la seccion de favoritos en Nutricion
- Then veo la lista de mis 8 alimentos favoritos con nombre, calorias y macros resumidos

**Scenario 3: Remove from favorites**
- Given "Arroz blanco" esta en mis favoritos
- When presiono el icono de corazon/estrella activo
- Then el alimento se elimina de favoritos

---

### NUT-04: Create Custom Food Item
**As a** user (Andres), **I want to** crear alimentos personalizados con su informacion nutricional, **So that** puedo registrar comidas que no estan en la base de datos.
**Priority**: MVP | **Epic**: Nutricion | **Persona**: Andres | **FR**: FR-16

**Scenario 1: Create custom food**
- Given presiono "Crear alimento personalizado"
- When ingreso: nombre "Arepa de maiz", porcion 80g, calorias 160, proteina 3g, carbohidratos 30g, grasa 3g
- Then el alimento se guarda y aparece en mis busquedas futuras con un indicador "Personalizado"

**Scenario 2: Missing required fields**
- Given estoy creando un alimento personalizado
- When ingreso el nombre pero no las calorias y presiono guardar
- Then veo "Las calorias son obligatorias" y no se guarda

**Scenario 3: Edit custom food**
- Given cree "Arepa de maiz" con 160 calorias
- When edito el alimento y cambio calorias a 170
- Then las comidas futuras usan los datos actualizados pero las ya registradas mantienen los datos originales

---

### NUT-05: Select Meal Type
**As a** user (Andres), **I want to** clasificar mis comidas por tipo (desayuno, almuerzo, cena, snack), **So that** puedo ver mi distribucion de nutrientes por comida.
**Priority**: MVP | **Epic**: Nutricion | **Persona**: Andres | **FR**: FR-17

**Scenario 1: Auto-suggest meal type**
- Given son las 7:30 AM y estoy registrando una comida
- When la app me muestra el selector de tipo de comida
- Then "Desayuno" aparece preseleccionado porque es horario de desayuno

**Scenario 2: Override meal type**
- Given son las 3:00 PM y la app sugiere "Snack"
- When cambio el tipo a "Almuerzo" porque almorce tarde
- Then la comida se registra como "Almuerzo"

**Scenario 3: View meals by type**
- Given he registrado comidas todo el dia
- When abro el resumen diario de nutricion
- Then veo las comidas agrupadas por tipo: Desayuno, Almuerzo, Cena, Snack con subtotales de macros por grupo

---

### NUT-06: Set Daily Macro Goals
**As a** user (Andres), **I want to** establecer mis metas diarias de calorias, proteina, carbohidratos y grasa, **So that** puedo seguir un plan nutricional.
**Priority**: MVP | **Epic**: Nutricion | **Persona**: Andres | **FR**: FR-18

**Scenario 1: Set all macro goals**
- Given estoy en Nutricion > Configuracion > Metas
- When establezco: Calorias 2.500, Proteina 180g, Carbohidratos 280g, Grasa 80g
- Then las metas se guardan y las barras de progreso usan estos valores como 100%

**Scenario 2: Only set calories**
- Given solo quiero rastrear calorias por ahora
- When establezco Calorias 2.000 y dejo los macros en 0
- Then solo se muestra la barra de progreso de calorias, los macros se registran pero sin barra de meta

**Scenario 3: Goals validation**
- Given ingreso Calorias 2.500 pero la suma de macros (proteina 200g x 4 + carbos 300g x 4 + grasa 80g x 9 = 2.720 cal) no coincide
- When guardo las metas
- Then veo un aviso informativo "Tus macros suman 2.720 cal, diferente a tu meta de 2.500 cal" pero puedo guardar de todas formas

---

### NUT-07: View Macro Progress Bars
**As a** user (Andres), **I want to** ver barras de progreso de mis macros del dia, **So that** se de un vistazo cuanto me falta para cumplir mis metas.
**Priority**: MVP | **Epic**: Nutricion | **Persona**: Andres | **FR**: FR-18

**Scenario 1: View progress during the day**
- Given mi meta es 2.500 cal y he consumido 1.800 cal
- When abro el dashboard de Nutricion
- Then veo la barra de calorias al 72% con "1.800 / 2.500 cal" y barras similares para proteina, carbos y grasa

**Scenario 2: Exceeded daily goal**
- Given mi meta de proteina es 180g y he consumido 195g
- When veo la barra de progreso de proteina
- Then la barra muestra 108% en un color diferente (amarillo/naranja) indicando que excedi la meta

**Scenario 3: No meals logged today**
- Given no he registrado ninguna comida hoy
- When abro el dashboard de Nutricion
- Then veo las 4 barras en 0% con "0 / [meta]" para cada macro

---

### NUT-08: Water Tracking
**As a** user (Andres), **I want to** registrar mi consumo de agua en vasos, **So that** puedo asegurarme de mantenerme hidratado.
**Priority**: MVP | **Epic**: Nutricion | **Persona**: Andres | **FR**: FR-19

**Scenario 1: Log a glass of water**
- Given estoy en el dashboard de Nutricion y he tomado 3 vasos hoy
- When presiono el boton de "+" en la seccion de agua
- Then el contador sube a 4 vasos con una animacion fluida y la meta diaria muestra "4/8 vasos"

**Scenario 2: Complete daily water goal**
- Given he tomado 7 de 8 vasos meta
- When registro el vaso numero 8
- Then veo una animacion de celebracion y el mensaje "Meta de hidratacion cumplida!"

**Scenario 3: Remove accidentally logged glass**
- Given registre un vaso de mas (muestra 6 vasos pero solo he tomado 5)
- When presiono "-" en la seccion de agua
- Then el contador baja a 5 vasos

---

### NUT-09: Water Reminders
**As a** user (Andres), **I want to** recibir recordatorios para tomar agua, **So that** no se me olvide hidratarme durante el dia.
**Priority**: MVP | **Epic**: Nutricion | **Persona**: Andres | **FR**: FR-19

**Scenario 1: Enable water reminders**
- Given estoy en Nutricion > Configuracion > Recordatorios de Agua
- When activo recordatorios cada 2 horas de 8:00 a 20:00
- Then recibo notificaciones cada 2 horas con el mensaje "Es hora de tomar agua. Llevas [X] de [Y] vasos"

**Scenario 2: Smart reminder (already logged)**
- Given ya registre un vaso de agua hace 15 minutos
- When llega la hora del recordatorio
- Then el recordatorio se pospone 30 minutos porque ya registre agua recientemente

**Scenario 3: Disable reminders**
- Given tengo recordatorios de agua activos
- When desactivo los recordatorios
- Then no recibo mas notificaciones de agua

---

### NUT-10: Meal Templates
**As a** user (Andres), **I want to** guardar combinaciones de alimentos como plantillas, **So that** puedo registrar comidas repetitivas en un solo paso.
**Priority**: MVP | **Epic**: Nutricion | **Persona**: Andres | **FR**: FR-20

**Scenario 1: Save meal as template**
- Given acabo de registrar mi almuerzo con "Arroz 200g + Pechuga 200g + Ensalada 100g"
- When presiono "Guardar como plantilla" y le doy el nombre "Almuerzo gym"
- Then la plantilla se guarda con los 3 alimentos y sus porciones

**Scenario 2: Use template**
- Given tengo la plantilla "Almuerzo gym" guardada
- When presiono "+" > "Plantillas" > "Almuerzo gym"
- Then los 3 alimentos se registran automaticamente con sus porciones y puedo ajustar antes de confirmar

**Scenario 3: Edit template**
- Given quiero modificar la plantilla "Almuerzo gym"
- When abro la plantilla, cambio la porcion de arroz a 250g y guardo
- Then los proximos usos de la plantilla tendran 250g de arroz

---

### NUT-11: Barcode Scanning (Post-MVP)
**As a** user (Andres), **I want to** escanear el codigo de barras de un producto para obtener su informacion nutricional, **So that** no tengo que buscar ni ingresar datos manualmente.
**Priority**: Phase 2 | **Epic**: Nutricion | **Persona**: Andres | **FR**: FR-20

**Scenario 1: Scan product barcode**
- Given presiono el icono de camara/barcode en la pantalla de agregar comida
- When escaneo el codigo de barras de una barra de proteina
- Then la app busca en Open Food Facts y muestra el producto con nombre, calorias y macros listos para registrar

**Scenario 2: Product not found**
- Given escaneo el codigo de barras de un producto local colombiano
- When el producto no esta en Open Food Facts
- Then veo "Producto no encontrado. Puedes crear un alimento personalizado" con opcion de contribuir los datos

**Scenario 3: Camera permission denied**
- Given intento escanear un codigo de barras por primera vez
- When el sistema me pide permiso de camara y lo deniego
- Then veo un mensaje "Se necesita acceso a la camara para escanear codigos. Puedes habilitarlo en Configuracion" con un enlace a los ajustes del dispositivo

---

## Epic 5: HAB — Habitos

### HAB-01: Create Habit
**As a** user (Camila), **I want to** crear un habito con nombre, icono, color y frecuencia, **So that** puedo hacer seguimiento de mis rutinas diarias.
**Priority**: MVP | **Epic**: Habitos | **Persona**: Camila | **FR**: FR-21

**Scenario 1: Create daily habit**
- Given estoy en el modulo de Habitos
- When presiono "Crear habito", ingreso nombre "Leer 30 min", selecciono icono de libro, color azul, frecuencia "Diario"
- Then el habito aparece en mi lista diaria con su icono y color, listo para hacer check-in

**Scenario 2: Create habit with all fields**
- Given presiono "Crear habito"
- When lleno todos los campos: nombre "Meditar", icono de loto, color morado, frecuencia "Diario", hora de recordatorio 7:00 AM
- Then el habito se crea con recordatorio configurado a las 7:00 AM

**Scenario 3: Create habit without name**
- Given estoy creando un nuevo habito
- When dejo el nombre vacio y presiono guardar
- Then veo el mensaje "El nombre del habito es obligatorio"

---

### HAB-02: Set Frequency (Daily/Weekly/Custom)
**As a** user (Camila), **I want to** elegir la frecuencia de mi habito (diaria, semanal, personalizada), **So that** se adapte a mi rutina real.
**Priority**: MVP | **Epic**: Habitos | **Persona**: Camila | **FR**: FR-22

**Scenario 1: Set daily frequency**
- Given estoy creando el habito "Tomar vitaminas"
- When selecciono frecuencia "Diario"
- Then el habito aparece todos los dias en mi lista de habitos pendientes

**Scenario 2: Set weekly frequency**
- Given estoy creando el habito "Ir al gym"
- When selecciono frecuencia "Semanal" con meta de 4 veces por semana
- Then el habito muestra "0/4 esta semana" y puedo hacer check-in cualquier dia

**Scenario 3: Set custom frequency**
- Given estoy creando el habito "Limpiar la casa"
- When selecciono frecuencia "Personalizada" y elijo Lunes, Miercoles y Viernes
- Then el habito solo aparece en mi lista los lunes, miercoles y viernes

---

### HAB-03: Set Reminder Notification
**As a** user (Camila), **I want to** configurar una notificacion de recordatorio para mi habito, **So that** no se me olvide cumplirlo.
**Priority**: MVP | **Epic**: Habitos | **Persona**: Camila | **FR**: FR-22

**Scenario 1: Set reminder**
- Given estoy editando el habito "Meditar"
- When configuro un recordatorio a las 6:30 AM
- Then recibo una notificacion a las 6:30 AM cada dia (o los dias de frecuencia) diciendo "Hora de: Meditar"

**Scenario 2: Multiple reminders for different habits**
- Given tengo "Meditar" con recordatorio a las 6:30 AM y "Leer" con recordatorio a las 9:00 PM
- When llega cada hora configurada
- Then recibo la notificacion correspondiente a cada habito

**Scenario 3: Reminder after check-in**
- Given ya hice check-in de "Meditar" a las 6:00 AM
- When llega la hora del recordatorio (6:30 AM)
- Then no recibo la notificacion porque ya cumpli el habito hoy

---

### HAB-04: Daily Check-in (One Tap)
**As a** user (Camila), **I want to** marcar un habito como completado con un solo tap, **So that** el registro sea instantaneo.
**Priority**: MVP | **Epic**: Habitos | **Persona**: Camila | **FR**: FR-23

**Scenario 1: Complete habit**
- Given veo mi lista de habitos del dia con "Meditar" pendiente
- When toco el circulo/checkbox junto a "Meditar"
- Then el habito se marca como completado con una animacion satisfactoria (check verde) y el streak se actualiza

**Scenario 2: Undo check-in**
- Given acabo de marcar "Meditar" como completado por error
- When toco nuevamente el checkbox completado
- Then el check-in se deshace y el habito vuelve a estado pendiente

**Scenario 3: All habits completed**
- Given tengo 5 habitos para hoy y ya complete 4
- When completo el quinto habito
- Then veo una animacion de celebracion "Completaste todos tus habitos de hoy!" y un mensaje motivacional

---

### HAB-05: Quantitative Check-in
**As a** user (Camila), **I want to** registrar una cantidad para habitos cuantitativos, **So that** puedo hacer seguimiento de habitos como "leer X paginas" o "caminar X pasos".
**Priority**: MVP | **Epic**: Habitos | **Persona**: Camila | **FR**: FR-23

**Scenario 1: Log quantity**
- Given tengo el habito "Leer" configurado como cuantitativo con meta de 30 paginas
- When presiono el habito y ingreso "35" paginas
- Then se registra como completado (35/30) con el icono de meta cumplida

**Scenario 2: Partial progress**
- Given tengo el habito "Caminar" con meta de 10.000 pasos
- When registro 6.000 pasos
- Then el habito muestra "6.000/10.000" con la barra de progreso al 60% pero no se marca como completado

**Scenario 3: Zero quantity**
- Given intento registrar el habito cuantitativo "Leer"
- When ingreso 0 paginas
- Then veo el mensaje "Ingresa una cantidad mayor a 0" y no se registra

---

### HAB-06: View Streak Counter
**As a** user (Camila), **I want to** ver mi racha actual de dias consecutivos cumplidos, **So that** me motive a no romper la cadena.
**Priority**: MVP | **Epic**: Habitos | **Persona**: Camila | **FR**: FR-24

**Scenario 1: Active streak**
- Given he completado "Meditar" durante 15 dias consecutivos
- When veo el detalle del habito "Meditar"
- Then veo "Racha actual: 15 dias" con un icono de fuego/llama

**Scenario 2: Broken streak**
- Given tenia una racha de 15 dias en "Meditar" y ayer no lo hice
- When veo el detalle del habito hoy
- Then veo "Racha actual: 0 dias" y "Mejor racha: 15 dias"

**Scenario 3: Streak for weekly habit**
- Given tengo un habito semanal "Ir al gym" con meta 4 veces/semana
- When he cumplido 4+ veces/semana durante 3 semanas consecutivas
- Then veo "Racha actual: 3 semanas"

---

### HAB-07: View Habit Calendar
**As a** user (Camila), **I want to** ver un calendario visual con colores por dia (verde=cumplido, rojo=no cumplido, gris=no aplica), **So that** puedo ver mis patrones de cumplimiento.
**Priority**: MVP | **Epic**: Habitos | **Persona**: Camila | **FR**: FR-24

**Scenario 1: View monthly calendar**
- Given abro el detalle del habito "Meditar"
- When veo el calendario del mes actual
- Then los dias completados estan en verde, los no completados en rojo, y los dias futuros o sin habito en gris

**Scenario 2: Navigate between months**
- Given estoy viendo el calendario de abril
- When deslizo hacia la izquierda
- Then veo el calendario de marzo con su historial de cumplimiento

**Scenario 3: Today not yet completed**
- Given hoy no he hecho check-in de "Meditar" y son las 2:00 PM
- When veo el calendario
- Then el dia de hoy aparece en un color neutro/amarillo (pendiente) diferente a verde (completado) y rojo (no cumplido)

---

### HAB-08: View Statistics
**As a** user (Camila), **I want to** ver estadisticas de mis habitos como porcentaje de cumplimiento y mejor racha, **So that** puedo evaluar mi progreso general.
**Priority**: MVP | **Epic**: Habitos | **Persona**: Camila | **FR**: FR-25

**Scenario 1: View completion percentage**
- Given he completado "Meditar" 25 de 30 dias este mes
- When abro las estadisticas del habito
- Then veo "Cumplimiento: 83%" con un grafico de progreso

**Scenario 2: View best streak**
- Given mi mejor racha de "Leer" fue 45 dias y la actual es 12
- When veo las estadisticas
- Then veo "Mejor racha: 45 dias" y "Racha actual: 12 dias"

**Scenario 3: New habit with no data**
- Given acabo de crear el habito "Yoga" hoy
- When abro sus estadisticas
- Then veo "Cumplimiento: 0%" y "Mejor racha: 0 dias" con mensaje "Empieza hoy tu nueva racha!"

---

### HAB-09: Edit and Delete Habit
**As a** user (Camila), **I want to** editar o eliminar un habito, **So that** puedo ajustar mis habitos cuando mis necesidades cambian.
**Priority**: MVP | **Epic**: Habitos | **Persona**: Camila | **FR**: FR-21

**Scenario 1: Edit habit**
- Given tengo el habito "Leer 20 min" y quiero aumentar la meta
- When edito el habito, cambio el nombre a "Leer 30 min" y guardo
- Then el habito se actualiza y los datos historicos se mantienen

**Scenario 2: Delete habit**
- Given quiero eliminar el habito "Correr" que ya no practico
- When presiono eliminar y veo la confirmacion "Eliminar habito? Se perdera todo el historial"
- Then al confirmar, el habito y su historial se eliminan permanentemente

**Scenario 3: Delete habit with long streak**
- Given tengo el habito "Meditar" con una racha de 60 dias
- When intento eliminar el habito
- Then veo una advertencia especial "Este habito tiene una racha de 60 dias. Considera desactivarlo en lugar de eliminarlo"

---

### HAB-10: Activate and Deactivate Habit
**As a** user (Laura), **I want to** desactivar un habito temporalmente sin perder el historial, **So that** puedo pausar habitos durante vacaciones o periodos especiales.
**Priority**: MVP | **Epic**: Habitos | **Persona**: Laura | **FR**: FR-21

**Scenario 1: Deactivate habit**
- Given tengo el habito "Ir al gym" activo
- When lo desactivo desde la edicion del habito
- Then el habito desaparece de mi lista diaria pero mantiene todo el historial y estadisticas

**Scenario 2: Reactivate habit**
- Given desactive "Ir al gym" hace 2 semanas
- When lo reactivo
- Then el habito vuelve a mi lista diaria con su historial intacto y la racha inicia desde 0

**Scenario 3: View inactive habits**
- Given tengo 2 habitos desactivados
- When voy a Habitos > Inactivos
- Then veo la lista de habitos desactivados con opcion de reactivar cada uno

---

## Epic 6: DASH — Dashboard Unificado

### DASH-01: View Unified Dashboard
**As a** user (Camila), **I want to** ver un dashboard unificado con metricas de todos mis modulos activos, **So that** tengo una vision completa de mi progreso en un solo lugar.
**Priority**: MVP | **Epic**: Dashboard | **Persona**: Camila | **FR**: FR-01

**Scenario 1: Dashboard with all modules**
- Given tengo activos Finanzas, Habitos y Gimnasio
- When abro el dashboard
- Then veo: balance financiero del mes, habitos completados hoy (3/5), ultimo entrenamiento "Push Day hace 1 dia" — cada seccion con un resumen compacto

**Scenario 2: Dashboard with single module**
- Given solo tengo el modulo de Finanzas activo
- When abro el dashboard
- Then veo solo las metricas financieras ocupando el espacio completo sin secciones vacias

**Scenario 3: Dashboard greeting**
- Given mi nombre es "Camila" y son las 8:00 AM
- When abro el dashboard
- Then veo "Buenos dias, Camila" con la fecha actual y mis metricas debajo

---

### DASH-02: Quick Action Buttons
**As a** user (Camila), **I want to** tener botones de accion rapida en el dashboard, **So that** puedo agregar datos a cualquier modulo sin navegar.
**Priority**: MVP | **Epic**: Dashboard | **Persona**: Camila | **FR**: FR-01

**Scenario 1: Quick add transaction**
- Given estoy en el dashboard y tengo Finanzas activo
- When presiono el boton rapido "Agregar transaccion"
- Then se abre directamente el formulario de nueva transaccion

**Scenario 2: Quick start workout**
- Given estoy en el dashboard y tengo Gimnasio activo
- When presiono el boton rapido "Iniciar entrenamiento"
- Then veo la opcion de elegir una rutina o iniciar entrenamiento vacio

**Scenario 3: Only active modules show buttons**
- Given solo tengo activos Finanzas y Habitos
- When veo los botones de accion rapida
- Then solo veo "Agregar transaccion" y "Check-in habito", no botones de modulos inactivos

---

### DASH-03: Dashboard Adapts to Active Modules
**As a** user (Andres), **I want to** que el dashboard se adapte automaticamente a los modulos que tengo activos, **So that** no veo informacion irrelevante.
**Priority**: MVP | **Epic**: Dashboard | **Persona**: Andres | **FR**: FR-40

**Scenario 1: Activate new module**
- Given tengo activos Gimnasio y Nutricion
- When activo el modulo de Habitos desde Configuracion
- Then el dashboard agrega automaticamente la seccion de Habitos con su resumen

**Scenario 2: Deactivate module**
- Given tengo activos Finanzas, Habitos y Gimnasio
- When desactivo Finanzas desde Configuracion
- Then la seccion de Finanzas desaparece del dashboard y las otras secciones ocupan el espacio

**Scenario 3: Layout adapts to module count**
- Given tengo 5 modulos activos
- When abro el dashboard
- Then las secciones se organizan de forma compacta y puedo hacer scroll para ver todas las metricas sin que se vea saturado

---

### DASH-04: Notifications Summary
**As a** user (Laura), **I want to** ver un resumen de notificaciones pendientes en el dashboard, **So that** no me pierda alertas importantes.
**Priority**: MVP | **Epic**: Dashboard | **Persona**: Laura | **FR**: FR-40

**Scenario 1: View pending notifications**
- Given tengo una alerta de presupuesto al 80% y 2 habitos pendientes
- When abro el dashboard
- Then veo un area de notificaciones mostrando "Presupuesto al 80%" y "2 habitos pendientes hoy"

**Scenario 2: No pending notifications**
- Given complete todos mis habitos y no tengo alertas
- When abro el dashboard
- Then el area de notificaciones muestra "Todo al dia!" o no aparece para ahorrar espacio

**Scenario 3: Dismiss notification**
- Given veo la notificacion "Presupuesto al 80%"
- When deslizo la notificacion para descartarla
- Then la notificacion desaparece del resumen pero la alerta sigue activa en el modulo de Finanzas

---

## Epic 7: SLP — Sueno + Energia

### SLP-01: Record Bedtime
**As a** user who tracks sleep (Andres), **I want to** tocar "Me voy a dormir" para registrar mi hora de acostarse, **So that** tengo un registro preciso de cuando empiezo a descansar.
**Priority**: Phase 2 | **Epic**: Sueno | **Persona**: Andres | **FR**: FR-26

**Scenario 1: Tap going to bed**
- Given abro el modulo de Sueno a las 10:30 PM
- When presiono el boton "Me voy a dormir"
- Then se registra la hora 10:30 PM como hora de acostarse y se muestra una animacion de luna/estrellas con "Buenas noches"

**Scenario 2: Already in bed from earlier**
- Given presione "Me voy a dormir" a las 10:00 PM y son las 10:15 PM
- When intento presionar el boton nuevamente
- Then veo "Ya registraste tu hora de dormir a las 10:00 PM. Deseas actualizar?"

**Scenario 3: Record bedtime retroactively**
- Given me olvide de tocar el boton anoche
- When abro el modulo de Sueno a la manana siguiente
- Then puedo registrar manualmente la hora de acostarse de anoche

---

### SLP-02: Set Estimated Fall-Asleep Time
**As a** user (Andres), **I want to** establecer mi tiempo estimado para quedarme dormido, **So that** el calculo de horas de sueno sea mas preciso.
**Priority**: Phase 2 | **Epic**: Sueno | **Persona**: Andres | **FR**: FR-26

**Scenario 1: Set fall-asleep time**
- Given registre que me fui a dormir a las 10:30 PM
- When configuro "Tiempo para dormirme: 15 minutos"
- Then la app calcula que me dormi a las 10:45 PM para los calculos de duracion

**Scenario 2: Change default fall-asleep time**
- Given mi configuracion default es 15 minutos
- When cambio a 30 minutos en Configuracion > Sueno
- Then todas las noches futuras usaran 30 minutos como estimado por defecto

---

### SLP-03: Wake-Up Auto-Detection
**As a** user (Andres), **I want to** que la app detecte cuando desbloqueo el telefono en la manana y me pregunte si ya desperte, **So that** el registro de despertar sea semiautomatico.
**Priority**: Phase 2 | **Epic**: Sueno | **Persona**: Andres | **FR**: FR-26

**Scenario 1: Notification on phone unlock**
- Given registre "Me voy a dormir" anoche a las 10:30 PM
- When desbloqueo el telefono a las 6:30 AM
- Then recibo una notificacion "Buenos dias! Te despertaste a las 6:30 AM?"

**Scenario 2: Confirm wake time**
- Given veo la notificacion "Te despertaste a las 6:30 AM?"
- When confirmo "Si"
- Then se registra 6:30 AM como hora de despertar y se calcula la duracion del sueno

**Scenario 3: Adjust wake time**
- Given veo la notificacion a las 6:30 AM pero desperte a las 6:00 AM
- When presiono "Ajustar" y cambio la hora a 6:00 AM
- Then se registra 6:00 AM como hora de despertar

---

### SLP-04: Record Sleep Interruption
**As a** user (Andres), **I want to** registrar interrupciones de sueno (hora de despertar, hora de volver a dormir, razon), **So that** tengo un registro completo de la calidad de mi sueno.
**Priority**: Phase 2 | **Epic**: Sueno | **Persona**: Andres | **FR**: FR-26

**Scenario 1: Record interruption in the moment**
- Given me desperte a las 3:00 AM y abro la app
- When presiono "Registrar interrupcion" e ingreso razon "Ruido"
- Then se registra la interrupcion a las 3:00 AM con razon "Ruido" y cuando vuelva a presionar "Dormir" se registra el regreso

**Scenario 2: Record interruption retroactively**
- Given en la revision matutina recuerdo que me desperte en la noche
- When agrego una interrupcion manual: 3:00 AM - 3:20 AM, razon "Bano"
- Then la interrupcion se agrega a mi registro y se descuentan 20 minutos de sueno efectivo

---

### SLP-05: Morning Retroactive Review
**As a** user (Andres), **I want to** hacer una revision retroactiva de mi noche con una linea de tiempo editable, **So that** puedo corregir cualquier dato antes de cerrar el registro.
**Priority**: Phase 2 | **Epic**: Sueno | **Persona**: Andres | **FR**: FR-26

**Scenario 1: Review and confirm**
- Given desperte y la app tiene: acostarse 10:30 PM, dormirse 10:45 PM, interrupcion 3:00-3:20 AM, despertar 6:30 AM
- When abro la revision matutina
- Then veo una linea de tiempo visual con todos los eventos y puedo confirmar o editar cada punto

**Scenario 2: Edit timeline**
- Given la linea de tiempo muestra despertar a las 6:30 AM pero fue a las 6:15 AM
- When toco el punto "Despertar" y ajusto a 6:15 AM
- Then la duracion se recalcula automaticamente

**Scenario 3: Add forgotten interruption**
- Given la linea de tiempo no muestra una interrupcion que tuve
- When presiono "Agregar interrupcion" en la linea de tiempo
- Then puedo ingresar la hora y razon, y la linea de tiempo se actualiza

---

### SLP-06: Sleep Quality Rating
**As a** user (Andres), **I want to** calificar la calidad de mi sueno de 1 a 5 estrellas, **So that** tengo una medida subjetiva adicional.
**Priority**: Phase 2 | **Epic**: Sueno | **Persona**: Andres | **FR**: FR-27

**Scenario 1: Rate sleep quality**
- Given estoy en la revision matutina despues de confirmar los datos
- When selecciono 4 de 5 estrellas
- Then la calificacion se guarda y se muestra en el resumen de la noche junto a las metricas objetivas

**Scenario 2: Skip rating**
- Given no quiero calificar mi sueno hoy
- When presiono "Omitir" en la pantalla de calificacion
- Then el registro se guarda sin calificacion subjetiva

---

### SLP-07: Sleep Score Calculation
**As a** user (Andres), **I want to** ver un puntaje de sueno calculado automaticamente, **So that** puedo entender la calidad de mi descanso en un solo numero.
**Priority**: Phase 2 | **Epic**: Sueno | **Persona**: Andres | **FR**: FR-27

**Scenario 1: Good sleep score**
- Given dormi 7.5 horas, sin interrupciones, calidad 4/5
- When veo el resumen de la noche
- Then veo "Puntaje de sueno: 88/100" con un indicador verde y desglose de factores

**Scenario 2: Poor sleep score**
- Given dormi 5 horas, 2 interrupciones de 20 min cada una, calidad 2/5
- When veo el resumen de la noche
- Then veo "Puntaje de sueno: 42/100" con un indicador rojo y sugerencias de mejora

**Scenario 3: Incomplete data**
- Given solo registre hora de acostarse y despertar (sin calificacion ni interrupciones)
- When veo el puntaje
- Then veo un puntaje parcial basado en duracion con nota "Agrega mas datos para un puntaje mas preciso"

---

### SLP-08: Sleep History
**As a** user (Andres), **I want to** ver mi historial de sueno con graficos de duracion y calidad, **So that** puedo identificar patrones y mejorar.
**Priority**: Phase 2 | **Epic**: Sueno | **Persona**: Andres | **FR**: FR-27

**Scenario 1: View weekly history**
- Given tengo datos de sueno de la ultima semana
- When abro el historial de sueno y selecciono "Semanal"
- Then veo un grafico de barras con duracion de sueno por noche y una linea de promedio

**Scenario 2: View monthly trends**
- Given tengo datos de sueno de un mes completo
- When selecciono "Mensual"
- Then veo promedios de duracion, calidad, numero de interrupciones y tendencia (mejorando/empeorando)

---

### SLP-09: Energy Check-in
**As a** user (Andres), **I want to** registrar mi nivel de energia 3 veces al dia (manana, tarde, noche) en escala 1-5, **So that** puedo correlacionar mi sueno con mi energia diurna.
**Priority**: Phase 2 | **Epic**: Sueno | **Persona**: Andres | **FR**: FR-27

**Scenario 1: Morning energy check-in**
- Given son las 9:00 AM y recibo un recordatorio
- When presiono la notificacion y selecciono energia nivel 4 (de 5)
- Then se registra "Energia manana: 4/5" con timestamp

**Scenario 2: View energy pattern**
- Given tengo registros de energia de 2 semanas
- When abro la seccion de energia
- Then veo un grafico que muestra mi energia promedio por hora del dia y como se correlaciona con la duracion del sueno

**Scenario 3: Missed check-in**
- Given no hice check-in de energia en la manana
- When abro la app a las 2:00 PM
- Then puedo registrar retroactivamente mi energia de la manana antes de registrar la de la tarde

---

### SLP-10: HealthKit/Health Connect Import
**As a** user (Andres), **I want to** importar datos de sueno desde Apple Health (iOS) o Health Connect (Android), **So that** puedo usar datos de mi reloj inteligente.
**Priority**: Phase 2 | **Epic**: Sueno | **Persona**: Andres | **FR**: FR-26

**Scenario 1: Connect Health data (iOS)**
- Given tengo un Apple Watch que registra mi sueno
- When voy a Configuracion > Integraciones > Apple Health y autorizo
- Then los datos de sueno del Apple Watch se importan automaticamente cada manana

**Scenario 2: Connect Health data (Android)**
- Given tengo un reloj Samsung/Fitbit conectado a Health Connect
- When voy a Configuracion > Integraciones > Health Connect y autorizo
- Then los datos de sueno se importan automaticamente

**Scenario 3: Conflict between manual and imported data**
- Given ya registre mi sueno manualmente y luego se importan datos de Health
- When hay conflicto entre los datos
- Then la app me pregunta "Se detectaron datos de Apple Health para esta noche. Deseas reemplazar tu registro manual?"

---

## Epic 8: MNT — Bienestar Mental

### MNT-01: Mood Check-in
**As a** user (Laura), **I want to** registrar mi estado de animo en una escala de 1 a 5, **So that** puedo monitorear mi bienestar emocional.
**Priority**: Phase 2 | **Epic**: Bienestar Mental | **Persona**: Laura | **FR**: FR-28

**Scenario 1: Quick mood check-in**
- Given abro el modulo de Bienestar Mental
- When selecciono la carita nivel 4 (Bien)
- Then se registra mi estado de animo como 4/5 con fecha y hora

**Scenario 2: Mood with tags**
- Given seleccione mi estado de animo como 3 (Regular)
- When la app me muestra opciones de tags y selecciono "Estresado" y "Cansado"
- Then el registro incluye animo 3/5 con tags "Estresado", "Cansado"

**Scenario 3: Multiple check-ins same day**
- Given ya hice un check-in a las 9:00 AM (animo 3)
- When hago otro a las 6:00 PM (animo 4)
- Then ambos registros se guardan y el promedio del dia se calcula como 3.5

---

### MNT-02: Select Mood Tags
**As a** user (Laura), **I want to** seleccionar tags emocionales como Motivado, Estresado, Ansioso, Tranquilo, etc., **So that** puedo entender los factores que afectan mi animo.
**Priority**: Phase 2 | **Epic**: Bienestar Mental | **Persona**: Laura | **FR**: FR-28

**Scenario 1: Select predefined tags**
- Given estoy haciendo un check-in de animo
- When veo los tags disponibles: Motivado, Estresado, Ansioso, Tranquilo, Feliz, Triste, Enojado, Agradecido, Energetico, Agotado
- Then puedo seleccionar multiples tags (ej. "Motivado" y "Energetico") y se asocian a mi registro

**Scenario 2: No tags selected**
- Given no quiero seleccionar tags
- When presiono "Omitir" o "Continuar" sin seleccionar
- Then el registro se guarda solo con el nivel de animo numerico

**Scenario 3: View most frequent tags**
- Given he usado "Estresado" 15 veces y "Motivado" 12 veces este mes
- When veo las estadisticas de bienestar mental
- Then veo un ranking de tags mas frecuentes con conteo

---

### MNT-03: Mini Journaling
**As a** user (Laura), **I want to** escribir 1-3 oraciones sobre como me siento, **So that** puedo reflexionar brevemente sin que sea abrumador.
**Priority**: Phase 2 | **Epic**: Bienestar Mental | **Persona**: Laura | **FR**: FR-29

**Scenario 1: Write mini journal entry**
- Given hice check-in de animo y seleccione tags
- When la app muestra un campo de texto con placeholder "Como te sientes hoy? (1-3 oraciones)"
- Then escribo "Hoy fue un dia productivo, termine el proyecto a tiempo. Me siento aliviada." y se guarda con el check-in

**Scenario 2: Skip journaling**
- Given no quiero escribir nada
- When presiono "Omitir"
- Then el check-in se guarda sin nota de journal

**Scenario 3: Character limit guidance**
- Given estoy escribiendo una entrada larga
- When excedo las 280 caracteres
- Then veo un contador "280/280" en amarillo sugiriendo mantenerlo breve pero sin bloquear la escritura

---

### MNT-04: Gratitude Entry
**As a** user (Laura), **I want to** registrar 3 cosas por las que estoy agradecida, **So that** puedo practicar la gratitud diariamente.
**Priority**: Phase 2 | **Epic**: Bienestar Mental | **Persona**: Laura | **FR**: FR-30

**Scenario 1: Add three gratitude items**
- Given abro la seccion de gratitud
- When ingreso: 1) "Mi familia", 2) "Tener salud", 3) "Mi trabajo"
- Then los 3 items se guardan con la fecha y veo un mensaje "Gracias por practicar la gratitud hoy"

**Scenario 2: Add partial gratitude**
- Given solo quiero registrar 1 item hoy
- When ingreso "El cafe de la manana" y dejo los otros 2 campos vacios
- Then se guarda con 1 item sin obligarme a llenar los 3

**Scenario 3: View gratitude history**
- Given he registrado gratitud durante 2 semanas
- When abro el historial de gratitud
- Then veo una lista cronologica de mis entradas de gratitud por dia

---

### MNT-05: Breathing Exercises
**As a** user (Laura), **I want to** hacer ejercicios de respiracion guiados (box breathing, 4-7-8, calma, energizante), **So that** puedo manejar mi estres en el momento.
**Priority**: Phase 2 | **Epic**: Bienestar Mental | **Persona**: Laura | **FR**: FR-31

**Scenario 1: Start box breathing**
- Given selecciono "Respiracion Cuadrada" (4-4-4-4)
- When inicio la sesion
- Then veo una animacion visual que guia inhalar 4s, sostener 4s, exhalar 4s, sostener 4s con vibracion haptica en cada transicion

**Scenario 2: Choose 4-7-8 breathing**
- Given selecciono "Tecnica 4-7-8"
- When inicio la sesion
- Then la animacion guia inhalar 4s, sostener 7s, exhalar 8s con un contador de ciclos

**Scenario 3: Customize session duration**
- Given selecciono cualquier tecnica de respiracion
- When ajusto la duracion a "5 minutos" (default 3 minutos)
- Then la sesion dura 5 minutos repitiendo los ciclos necesarios

---

### MNT-06: Mood Calendar View
**As a** user (Laura), **I want to** ver un calendario con mi estado de animo por dia representado con colores, **So that** puedo identificar patrones emocionales en el mes.
**Priority**: Phase 2 | **Epic**: Bienestar Mental | **Persona**: Laura | **FR**: FR-28

**Scenario 1: View mood calendar**
- Given tengo registros de animo de todo el mes
- When abro el calendario de animo
- Then veo cada dia coloreado segun el promedio: verde (4-5), amarillo (3), naranja (2), rojo (1) con dias sin registro en gris

**Scenario 2: Tap on specific day**
- Given veo el calendario y noto un dia rojo
- When toco ese dia
- Then veo el detalle: animo 1/5, tags "Ansioso, Triste", nota del mini journal y hora del registro

**Scenario 3: Month with no data**
- Given no tengo registros de animo en febrero
- When navego al calendario de febrero
- Then veo todos los dias en gris con mensaje "No hay registros de animo para este mes"

---

### MNT-07: Breathing Session History
**As a** user (Laura), **I want to** ver mi historial de sesiones de respiracion, **So that** puedo mantener consistencia en la practica.
**Priority**: Phase 2 | **Epic**: Bienestar Mental | **Persona**: Laura | **FR**: FR-31

**Scenario 1: View session history**
- Given he completado 10 sesiones de respiracion este mes
- When abro el historial de sesiones
- Then veo la lista con fecha, tipo de tecnica, duracion y si la complete o la cancele

**Scenario 2: Streak tracking**
- Given he hecho al menos 1 sesion de respiracion diaria por 7 dias
- When veo el historial
- Then veo "Racha de respiracion: 7 dias" motivandome a continuar

**Scenario 3: No sessions yet**
- Given no he hecho ninguna sesion de respiracion
- When abro el historial
- Then veo "Aun no has hecho sesiones de respiracion. Prueba una ahora" con acceso directo a las tecnicas

---

## Epic 9: GOAL — Life Goals

### GOAL-01: Create Goal
**As a** user (Laura), **I want to** crear una meta de vida con nombre, icono, color y fecha limite, **So that** puedo definir y visualizar mis objetivos a largo plazo.
**Priority**: Phase 2 | **Epic**: Life Goals | **Persona**: Laura | **FR**: FR-32

**Scenario 1: Create goal with deadline**
- Given abro el modulo de Life Goals
- When creo la meta "Independencia Financiera", selecciono icono de billete, color dorado, fecha limite diciembre 2027
- Then la meta se crea con progreso 0% y aparece en mi dashboard de metas

**Scenario 2: Create goal without deadline**
- Given estoy creando una meta a largo plazo sin fecha clara
- When dejo el campo de fecha limite vacio
- Then la meta se crea sin deadline y no muestra alertas de tiempo

**Scenario 3: Duplicate goal name**
- Given ya existe la meta "Independencia Financiera"
- When intento crear otra meta con el mismo nombre
- Then veo "Ya tienes una meta con ese nombre. Deseas continuar de todas formas?" y puedo confirmar

---

### GOAL-02: Add Sub-Goal Linked to Module
**As a** user (Laura), **I want to** agregar sub-metas vinculadas a modulos especificos, **So that** mis metas se descomponen en acciones concretas dentro de cada area.
**Priority**: Phase 2 | **Epic**: Life Goals | **Persona**: Laura | **FR**: FR-32

**Scenario 1: Add finance sub-goal**
- Given tengo la meta "Independencia Financiera"
- When agrego sub-meta "Ahorrar $10.000.000" vinculada al modulo de Finanzas
- Then la sub-meta se conecta al modulo de Finanzas y su progreso puede alimentarse de los datos financieros

**Scenario 2: Add habit sub-goal**
- Given tengo la meta "Vida Saludable"
- When agrego sub-meta "Meditar 30 dias seguidos" vinculada al modulo de Habitos
- Then la sub-meta trackea automaticamente la racha del habito "Meditar"

**Scenario 3: Add unlinked sub-goal**
- Given quiero una sub-meta que no corresponde a ningun modulo
- When agrego sub-meta "Leer 12 libros al ano" sin vincular a modulo
- Then la sub-meta se crea con seguimiento manual (puedo marcar progreso yo mismo)

---

### GOAL-03: Set Sub-Goal Weight
**As a** user (Laura), **I want to** asignar un peso/ponderacion a cada sub-meta, **So that** las sub-metas mas importantes afecten mas el progreso total.
**Priority**: Phase 2 | **Epic**: Life Goals | **Persona**: Laura | **FR**: FR-32

**Scenario 1: Set weights**
- Given mi meta "Vida Saludable" tiene 3 sub-metas
- When asigno: "Gym 4x/semana" peso 50%, "Dieta balanceada" peso 30%, "Dormir 7h" peso 20%
- Then los pesos suman 100% y el progreso total se calcula como promedio ponderado

**Scenario 2: Weights don't sum to 100%**
- Given asigno pesos que suman 80%
- When intento guardar
- Then veo "Los pesos deben sumar 100%. Actualmente suman 80%"

**Scenario 3: Equal weights by default**
- Given creo 4 sub-metas sin asignar pesos
- When veo los pesos
- Then cada sub-meta tiene 25% por defecto

---

### GOAL-04: View Goal Progress
**As a** user (Laura), **I want to** ver el progreso de mi meta como promedio ponderado de sub-metas, **So that** se de un vistazo como voy.
**Priority**: Phase 2 | **Epic**: Life Goals | **Persona**: Laura | **FR**: FR-32

**Scenario 1: View progress bar**
- Given mi meta "Vida Saludable" tiene sub-metas con progreso: Gym 80% (peso 50%), Dieta 60% (peso 30%), Sueno 40% (peso 20%)
- When abro la meta
- Then veo progreso total: (80x0.5 + 60x0.3 + 40x0.2) = 66% con barra de progreso

**Scenario 2: No progress yet**
- Given acabo de crear la meta con 3 sub-metas todas en 0%
- When veo el progreso
- Then veo 0% con mensaje "Empieza a trabajar en tus sub-metas para ver progreso"

---

### GOAL-05: Add Milestone
**As a** user (Laura), **I want to** agregar hitos a mis metas, **So that** puedo celebrar logros intermedios.
**Priority**: Phase 2 | **Epic**: Life Goals | **Persona**: Laura | **FR**: FR-32

**Scenario 1: Create milestone**
- Given tengo la meta "Independencia Financiera"
- When agrego hito "Primer millon ahorrado" con fecha objetivo junio 2026
- Then el hito aparece en la linea de tiempo de la meta

**Scenario 2: Complete milestone**
- Given alcanzo el hito "Primer millon ahorrado"
- When lo marco como completado
- Then veo una animacion de celebracion y el hito se marca con check verde en la linea de tiempo

**Scenario 3: Milestone overdue**
- Given el hito "Primer millon" tenia fecha junio 2026 y estamos en julio 2026
- When la fecha pasa sin completar el hito
- Then el hito se marca en rojo como "Vencido" pero no se elimina

---

### GOAL-06: Goal Detail View
**As a** user (Laura), **I want to** ver la vista detallada de una meta con sub-metas, hitos y progreso, **So that** puedo gestionar cada meta de forma integral.
**Priority**: Phase 2 | **Epic**: Life Goals | **Persona**: Laura | **FR**: FR-32

**Scenario 1: View goal detail**
- Given abro la meta "Vida Saludable"
- When se muestra la vista detallada
- Then veo: progreso total 66%, lista de sub-metas con progreso individual, hitos en linea de tiempo, y grafico de progreso en el tiempo

**Scenario 2: Edit goal from detail**
- Given estoy en la vista detallada de una meta
- When presiono "Editar"
- Then puedo cambiar nombre, icono, color, fecha limite y sub-metas

---

### GOAL-07: Goal Dashboard
**As a** user (Laura), **I want to** ver un dashboard con todas mis metas activas y su progreso, **So that** tengo una vista panoramica de mis objetivos de vida.
**Priority**: Phase 2 | **Epic**: Life Goals | **Persona**: Laura | **FR**: FR-32

**Scenario 1: View all active goals**
- Given tengo 4 metas activas
- When abro el dashboard de Life Goals
- Then veo las 4 metas como tarjetas con nombre, icono, porcentaje de progreso y barra visual

**Scenario 2: Sort goals**
- Given tengo multiples metas
- When selecciono ordenar por "Deadline mas cercano"
- Then las metas se reordenan con la mas urgente primero

**Scenario 3: No goals created**
- Given no he creado ninguna meta
- When abro Life Goals
- Then veo empty state "Define tus metas de vida. Que quieres lograr?" con boton "Crear primera meta"

---

## Epic 10: INT — Integraciones Cross-Modulo

### INT-01: Auto-Check Gym Habit
**As a** user (Andres), **I want to** que el habito "Ir al gym" se marque automaticamente cuando completo un entrenamiento, **So that** no tengo que hacer doble registro.
**Priority**: MVP | **Epic**: Integraciones | **Persona**: Andres | **FR**: Cross-cutting

**Scenario 1: Auto-check on workout complete**
- Given tengo el habito "Ir al gym" activo y hoy no lo he marcado
- When completo un entrenamiento en el modulo de Gimnasio
- Then el habito "Ir al gym" se marca automaticamente como completado con nota "Completado via entrenamiento"

**Scenario 2: No matching habit**
- Given no tengo un habito relacionado con gym
- When completo un entrenamiento
- Then no se auto-marca ningun habito (comportamiento normal)

**Scenario 3: Habit already checked manually**
- Given ya marque "Ir al gym" manualmente antes de entrenar
- When completo un entrenamiento
- Then no se duplica el check-in, el habito permanece marcado una sola vez

---

### INT-02: Nutrition Adjusts on Training Day
**As a** user (Andres), **I want to** que mis metas de nutricion se ajusten automaticamente los dias de entrenamiento, **So that** como mas cuando entreno y menos cuando descanso.
**Priority**: MVP | **Epic**: Integraciones | **Persona**: Andres | **FR**: Cross-cutting

**Scenario 1: Increased goals on training day**
- Given configure "Dia de entreno: +300 cal, +30g proteina" y hoy complete un entrenamiento
- When abro el modulo de Nutricion
- Then mis metas del dia muestran 2.800 cal (en vez de 2.500) y 210g proteina (en vez de 180)

**Scenario 2: Rest day goals**
- Given hoy no tengo entrenamiento registrado
- When abro Nutricion
- Then mis metas muestran los valores base: 2.500 cal, 180g proteina

**Scenario 3: Adjust setting disabled**
- Given no configure ajustes de nutricion por entrenamiento
- When completo un entrenamiento
- Then las metas de nutricion no cambian (comportamiento default)

---

### INT-03: Finance Expense Suggests Meal Log
**As a** user (Camila), **I want to** que al registrar un gasto en "Comida/Restaurante" la app me sugiera registrar una comida en Nutricion, **So that** ambos registros se mantengan sincronizados.
**Priority**: MVP | **Epic**: Integraciones | **Persona**: Camila | **FR**: Cross-cutting

**Scenario 1: Suggestion after food expense**
- Given registro un gasto de $25.000 en categoria "Alimentacion"
- When se guarda la transaccion
- Then veo una sugerencia no intrusiva "Registrar esta comida en Nutricion?" con opcion "Si" / "No, gracias"

**Scenario 2: Accept suggestion**
- Given veo la sugerencia de registrar comida
- When presiono "Si"
- Then se abre el formulario de registro de comida en Nutricion prellenado con el tipo de comida sugerido por la hora

**Scenario 3: Dismiss suggestion**
- Given veo la sugerencia de registrar comida
- When presiono "No, gracias"
- Then la sugerencia desaparece y la transaccion financiera se mantiene sin cambios

---

### INT-04: Dashboard Shows All Active Module Metrics
**As a** user (Camila), **I want to** ver metricas clave de todos mis modulos activos en el dashboard principal, **So that** no tengo que abrir cada modulo para ver mi progreso.
**Priority**: MVP | **Epic**: Integraciones | **Persona**: Camila | **FR**: Cross-cutting

**Scenario 1: All modules active**
- Given tengo activos: Finanzas, Gimnasio, Nutricion, Habitos
- When abro el dashboard
- Then veo: balance del mes, ultimo entrenamiento + dias desde ultimo, calorias hoy vs meta, habitos completados hoy — todo en una sola pantalla

**Scenario 2: Module data updates**
- Given el dashboard muestra "Habitos: 3/5 completados"
- When completo un habito mas desde el dashboard (via boton rapido)
- Then inmediatamente se actualiza a "Habitos: 4/5 completados"

---

### INT-05: Goals Link to Module Entities
**As a** user (Laura), **I want to** vincular sub-metas de Life Goals a entidades de cualquier modulo, **So that** el progreso se trackea automaticamente desde el modulo correspondiente.
**Priority**: Phase 2 | **Epic**: Integraciones | **Persona**: Laura | **FR**: Cross-cutting

**Scenario 1: Link to savings goal**
- Given tengo la meta "Viaje a Europa" con sub-meta "Ahorrar $8.000.000"
- When vinculo la sub-meta a una meta de ahorro en Finanzas
- Then el progreso de la sub-meta se actualiza automaticamente cuando ahorro dinero en esa meta

**Scenario 2: Link to habit streak**
- Given tengo la meta "Bienestar" con sub-meta "90 dias de meditacion"
- When vinculo la sub-meta al habito "Meditar"
- Then el progreso refleja automaticamente la racha del habito: 45/90 dias = 50%

**Scenario 3: Module not active**
- Given intento vincular una sub-meta al modulo de Sueno pero no lo tengo activo
- When selecciono el modulo
- Then veo "El modulo de Sueno no esta activo. Deseas activarlo?" con opcion de activar

---

### INT-06: Export Data (JSON Backup)
**As a** user (Laura), **I want to** exportar todos mis datos como backup en formato JSON, **So that** tengo una copia de seguridad de mi informacion.
**Priority**: MVP | **Epic**: Integraciones | **Persona**: Laura | **FR**: Cross-cutting

**Scenario 1: Full export**
- Given voy a Configuracion > Datos > Exportar
- When presiono "Exportar todo" y selecciono ubicacion
- Then se genera un archivo JSON con todos mis datos de todos los modulos y se guarda en la ubicacion seleccionada (en Android via Storage Access Framework, en iOS via Files app)

**Scenario 2: Export specific module**
- Given quiero exportar solo mis datos de Finanzas
- When selecciono "Solo Finanzas" y exporto
- Then se genera un JSON solo con transacciones, categorias, presupuestos y datos financieros

**Scenario 3: Large dataset export**
- Given tengo 2 anos de datos con miles de registros
- When inicio la exportacion
- Then veo una barra de progreso y al completar, el archivo se guarda correctamente sin truncar datos

---

### INT-07: Import Data (Restore from Backup)
**As a** user (Laura), **I want to** importar un backup JSON para restaurar mis datos, **So that** puedo recuperar mi informacion en un nuevo dispositivo.
**Priority**: MVP | **Epic**: Integraciones | **Persona**: Laura | **FR**: Cross-cutting

**Scenario 1: Successful import**
- Given tengo un archivo JSON de backup valido
- When voy a Configuracion > Datos > Importar y selecciono el archivo
- Then veo un resumen "Se importaran: 350 transacciones, 5 rutinas, 8 habitos..." y al confirmar todos los datos se restauran

**Scenario 2: Import with existing data**
- Given ya tengo datos en la app y quiero importar un backup
- When selecciono el archivo de backup
- Then la app pregunta "Ya tienes datos existentes. Deseas: A) Reemplazar todo, B) Fusionar con datos existentes, C) Cancelar"

**Scenario 3: Invalid file format**
- Given selecciono un archivo que no es JSON valido de LifeOS
- When intento importar
- Then veo "El archivo seleccionado no es un backup valido de LifeOS. Verifica el archivo e intenta de nuevo"

---

## Traceability Matrix

| FR | Stories |
|----|---------|
| FR-01 | DASH-01, DASH-02, DASH-03 |
| FR-02 | FIN-01 |
| FR-03 | FIN-02 |
| FR-04 | FIN-03, FIN-04 |
| FR-05 | FIN-05, FIN-06 |
| FR-06 | FIN-07, FIN-14 |
| FR-07 | FIN-08, FIN-15 |
| FR-08 | FIN-09 |
| FR-09 | FIN-10, FIN-11, FIN-12, FIN-13 |
| FR-10 | GYM-01, GYM-02, GYM-03 |
| FR-11 | GYM-04 |
| FR-12 | GYM-05, GYM-06, GYM-07, GYM-08, GYM-09, GYM-10 |
| FR-13 | GYM-11 |
| FR-14 | GYM-12, GYM-13, GYM-14, GYM-15 |
| FR-15 | NUT-01, NUT-02 |
| FR-16 | NUT-03, NUT-04 |
| FR-17 | NUT-05 |
| FR-18 | NUT-06, NUT-07 |
| FR-19 | NUT-08, NUT-09 |
| FR-20 | NUT-10, NUT-11 |
| FR-21 | HAB-01, HAB-09, HAB-10 |
| FR-22 | HAB-02, HAB-03 |
| FR-23 | HAB-04, HAB-05 |
| FR-24 | HAB-06, HAB-07 |
| FR-25 | HAB-08 |
| FR-26 | SLP-01, SLP-02, SLP-03, SLP-04, SLP-05, SLP-10 |
| FR-27 | SLP-06, SLP-07, SLP-08, SLP-09 |
| FR-28 | MNT-01, MNT-02, MNT-06 |
| FR-29 | MNT-03 |
| FR-30 | MNT-04 |
| FR-31 | MNT-05, MNT-07 |
| FR-32 | GOAL-01, GOAL-02, GOAL-03, GOAL-04, GOAL-05, GOAL-06, GOAL-07 |
| FR-39 | ONB-01, ONB-02, ONB-03, ONB-04, ONB-05, ONB-06, ONB-07 |
| FR-40 | DASH-03, DASH-04 |
| Cross-cutting | INT-01, INT-02, INT-03, INT-04, INT-05, INT-06, INT-07 |
