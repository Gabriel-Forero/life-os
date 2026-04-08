# Budget System Improvement Design

## Overview

Mejora integral del sistema de presupuestos de LifeOS: automatización, visibilidad, análisis, flexibilidad (3 niveles), alertas inteligentes, y layout responsive para web y móvil.

## Enfoque: Incremental (3 Fases)

---

## Modelo de Datos

### Nuevas tablas

**`BudgetTemplates`** — Plantillas reutilizables
- `id` (int, auto-increment)
- `name` (string, 1-50 chars) — ej: "Mes normal", "Vacaciones"
- `createdAt`, `updatedAt` (DateTime)

**`BudgetTemplateItems`** — Items dentro de una plantilla
- `id` (int, auto-increment)
- `templateId` (int, FK → BudgetTemplates)
- `categoryId` (int, FK → Categories)
- `amountCents` (int)

**`CategoryGroups`** — Agrupación de categorías
- `id` (int, auto-increment)
- `name` (string, 1-30 chars) — ej: "Necesidades", "Ocio"
- `color` (int, hex color)
- `sortOrder` (int)
- `createdAt` (DateTime)

**`CategoryGroupMembers`** — Relación N:N categoría-grupo
- `id` (int, auto-increment)
- `groupId` (int, FK → CategoryGroups)
- `categoryId` (int, FK → Categories)

**`GroupBudgets`** — Presupuesto por grupo por mes
- `id` (int, auto-increment)
- `groupId` (int, FK → CategoryGroups)
- `amountCents` (int)
- `month` (int, 1-12)
- `year` (int)
- unique(`groupId`, `month`, `year`)
- `createdAt`, `updatedAt` (DateTime)

**`MonthlyBudgetConfig`** — Configuración global del mes
- `id` (int, auto-increment)
- `globalBudgetCents` (int, nullable)
- `month` (int, 1-12)
- `year` (int)
- unique(`month`, `year`)
- `createdAt`, `updatedAt` (DateTime)

### Modificaciones a tabla existente

**`Budgets`**: agregar campo `autoRepeat` (bool, default true)

---

## Fase 1: Automatización + Visibilidad

### Auto-repetir presupuestos
- Al detectar nuevo mes sin presupuestos → copiar del mes anterior (donde `autoRepeat = true`)
- Copiar también `GroupBudgets` y `globalBudgetCents`
- Emitir `BudgetsAutoCreatedEvent` → snackbar informativo
- El usuario puede desactivar auto-repeat por categoría individual

### Plantillas de presupuesto
- **Guardar como plantilla**: captura presupuestos actuales (categoría + grupo + global)
- **Aplicar plantilla**: sobreescribe presupuestos del mes actual
- **Gestión**: editar nombre, eliminar plantillas

### Prioridad de aplicación
1. Auto-repeat copia del mes anterior (automático)
2. Plantilla aplicada sobreescribe lo auto-generado
3. Ediciones manuales siempre tienen la última palabra

### Rediseño BudgetOverviewScreen

**Tarjeta resumen global (parte superior):**
- Presupuesto global del mes (si está definido) con barra de progreso circular
- Total presupuestado (suma categorías)
- Total gastado del mes
- Disponible restante
- % utilización con color dinámico (verde <60%, amarillo 60-85%, rojo >85%)
- Días restantes + promedio diario disponible ("Te quedan $X/día")

**Grupos de categorías (colapsables):**
- Nombre del grupo, presupuesto, gastado, barra de progreso
- Al expandir → categorías individuales del grupo
- Categorías sin grupo en sección "Sin agrupar"

**Semáforo por categoría:**
- Verde: <60% utilizado
- Amarillo: 60-85% utilizado
- Rojo: >85% utilizado
- Gris: excedido (>100%)
- Dot de color + barra de progreso coloreada
- Texto: "Categoría — $gastado / $presupuesto"
- Tap → editar presupuesto

**Interacciones:**
- Pull-to-refresh
- Selector de mes (navegar entre meses)
- FAB: agregar presupuesto, aplicar plantilla, guardar como plantilla

---

## Fase 2: Grupos de Categorías (3 niveles)

### Estructura de 3 niveles
1. **Global**: tope general del mes
2. **Grupo**: límite por grupo de categorías (ej: "Necesidades")
3. **Categoría**: presupuesto individual por categoría

### Funcionalidad
- CRUD de grupos
- Asignar/desasignar categorías a grupos
- Presupuesto por grupo por mes
- Validación: gasto del grupo = suma de gastos de sus categorías
- Semáforo aplica a los 3 niveles

---

## Fase 3: Análisis + Alertas

### BudgetAnalyticsScreen (3 tabs)

**Tab 1 — Mes actual vs anterior:**
- Tabla comparativa por categoría
- Flechas con % de cambio (rojo si subió, verde si bajó)
- Resumen: "Este mes gastas X% menos/más"
- Comparación a nivel de grupos y global

**Tab 2 — Tendencias (3-6 meses):**
- Gráfico de líneas por categoría (toggle mostrar/ocultar)
- Selector: 3 meses, 6 meses
- Vista por grupo
- Tabla: promedio mensual + desviación

**Tab 3 — Proyección de fin de mes:**
- Ritmo diario: gastoActual / díasTranscurridos
- Proyección: ritmo × díasDelMes
- Por categoría: proyección vs presupuesto
- Semáforo predictivo: "A este ritmo, X excederá el día Y"
- Gráfico: gasto acumulado real + proyección punteada + línea de presupuesto

### Alertas granulares
- Umbrales: 50%, 75%, 90%, 100%
- EventBus con `BudgetThresholdEvent` extendido (campo `threshold`)
- Mensajes contextuales por umbral
- Aplica a nivel categoría, grupo y global

### Resumen diario inteligente
- Banner in-app al abrir pantalla de presupuestos
- "Hoy llevas $X. Te quedan $Y para Z días ($W/día)"
- Menciona categorías en rojo

### Alerta predictiva
- Se recalcula al registrar gasto
- Snackbar/banner si proyección supera presupuesto
- Una vez por categoría por umbral (anti-spam con flag en memoria)

---

## Layout Responsivo

### Breakpoints existentes (AppBreakpoints)
- Phone: <600dp
- Tablet: 600-1199dp
- Desktop: >=1200dp

### Shell existente (ya implementado)
- Phone: bottom nav + drawer
- Tablet: nav rail + drawer
- Desktop: sidebar permanente (260dp)

### Contenido interno de pantallas de presupuesto

**Desktop (>=1200dp) — Sidebar interno + panel:**
- Sidebar izquierdo (~300dp): tarjeta resumen, lista grupos/categorías con semáforo
- Panel derecho: detalle, gráficos, edición — cambia según selección
- Max-width: AppBreakpoints.maxContentWidth (960dp)

**Tablet (600-1199dp) — Dos columnas reducidas:**
- Misma estructura, sidebar más estrecho (~250dp)
- Gráficos adaptados al ancho

**Phone (<600dp) — Stack vertical responsive:**
- Tarjeta resumen arriba
- Lista grupos/categorías con semáforo
- Tap navega a detalle (push)
- Analytics como pantalla separada
- Responsive dentro de móvil: adaptar cards y grids según ancho real

### Componente
- `BudgetResponsiveLayout` con `LayoutBuilder` (patrón de WellnessHubScreen)
- Usar `AppBreakpoints.gridColumns()` para grids adaptativos
- `ConstrainedBox` para max-width en desktop/tablet
