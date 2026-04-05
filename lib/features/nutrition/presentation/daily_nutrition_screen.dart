import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Modelos mock
// ---------------------------------------------------------------------------

class _MockMacro {
  const _MockMacro({
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.color,
  });

  final String label;
  final double current;
  final double goal;
  final String unit;
  final Color color;

  double get progress => goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
}

const _mockMacros = [
  _MockMacro(
    label: 'Calorias',
    current: 1420,
    goal: 2000,
    unit: 'kcal',
    color: AppColors.nutrition,
  ),
  _MockMacro(
    label: 'Proteina',
    current: 82,
    goal: 150,
    unit: 'g',
    color: Color(0xFF3B82F6),
  ),
  _MockMacro(
    label: 'Carbos',
    current: 168,
    goal: 250,
    unit: 'g',
    color: Color(0xFF10B981),
  ),
  _MockMacro(
    label: 'Grasa',
    current: 45,
    goal: 65,
    unit: 'g',
    color: Color(0xFFEC4899),
  ),
];

enum _MealType { desayuno, almuerzo, cena, snack }

extension _MealTypeLabel on _MealType {
  String get label => switch (this) {
        _MealType.desayuno => 'Desayuno',
        _MealType.almuerzo => 'Almuerzo',
        _MealType.cena => 'Cena',
        _MealType.snack => 'Snack',
      };

  IconData get icon => switch (this) {
        _MealType.desayuno => Icons.wb_sunny_outlined,
        _MealType.almuerzo => Icons.restaurant_outlined,
        _MealType.cena => Icons.nightlight_outlined,
        _MealType.snack => Icons.apple_outlined,
      };
}

class _MockFoodItem {
  const _MockFoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.serving,
  });

  final int id;
  final String name;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String serving;
}

class _MockMealEntry {
  const _MockMealEntry({
    required this.type,
    required this.items,
  });

  final _MealType type;
  final List<_MockFoodItem> items;

  double get totalCalories =>
      items.fold(0.0, (sum, i) => sum + i.calories);
}

const _mockMeals = [
  _MockMealEntry(
    type: _MealType.desayuno,
    items: [
      _MockFoodItem(
        id: 1,
        name: 'Avena con leche',
        calories: 320,
        proteinG: 12,
        carbsG: 52,
        fatG: 6,
        serving: '1 taza (240 ml)',
      ),
      _MockFoodItem(
        id: 2,
        name: 'Platano',
        calories: 105,
        proteinG: 1.3,
        carbsG: 27,
        fatG: 0.4,
        serving: '1 unidad (120 g)',
      ),
    ],
  ),
  _MockMealEntry(
    type: _MealType.almuerzo,
    items: [
      _MockFoodItem(
        id: 3,
        name: 'Pechuga de pollo a la plancha',
        calories: 280,
        proteinG: 42,
        carbsG: 0,
        fatG: 10,
        serving: '150 g',
      ),
      _MockFoodItem(
        id: 4,
        name: 'Arroz blanco cocido',
        calories: 200,
        proteinG: 4,
        carbsG: 44,
        fatG: 0.5,
        serving: '1 taza (180 g)',
      ),
      _MockFoodItem(
        id: 5,
        name: 'Ensalada mixta',
        calories: 45,
        proteinG: 2,
        carbsG: 8,
        fatG: 1,
        serving: '1 porcion (100 g)',
      ),
    ],
  ),
  _MockMealEntry(
    type: _MealType.cena,
    items: [
      _MockFoodItem(
        id: 6,
        name: 'Salmon al horno',
        calories: 350,
        proteinG: 38,
        carbsG: 0,
        fatG: 21,
        serving: '180 g',
      ),
      _MockFoodItem(
        id: 7,
        name: 'Brocoli al vapor',
        calories: 55,
        proteinG: 4,
        carbsG: 11,
        fatG: 0.6,
        serving: '1 taza (156 g)',
      ),
    ],
  ),
  _MockMealEntry(
    type: _MealType.snack,
    items: [
      _MockFoodItem(
        id: 8,
        name: 'Yogur griego natural',
        calories: 100,
        proteinG: 17,
        carbsG: 6,
        fatG: 0.7,
        serving: '170 g',
      ),
    ],
  ),
];

// ---------------------------------------------------------------------------
// Pantalla principal de nutricion diaria
// ---------------------------------------------------------------------------

/// Pantalla de nutricion diaria con anillos de macros, lista de comidas por
/// tipo y rastreador de agua.
///
/// Shell de presentacion — la integracion con Riverpod se realizara en un
/// paso posterior.
///
/// Accesibilidad: A11Y-NUT-01 — todos los controles e indicadores tienen
/// etiquetas semanticas.
class DailyNutritionScreen extends StatefulWidget {
  const DailyNutritionScreen({super.key});

  @override
  State<DailyNutritionScreen> createState() => _DailyNutritionScreenState();
}

class _DailyNutritionScreenState extends State<DailyNutritionScreen> {
  final Set<_MealType> _expandedMeals = {_MealType.desayuno, _MealType.almuerzo};

  // Agua: vasos de 250 ml hacia meta de 8 vasos (2000 ml)
  int _waterGlasses = 5;
  static const int _waterGoalGlasses = 8;
  static const double _mlPerGlass = 250;

  void _incrementWater() {
    if (_waterGlasses < _waterGoalGlasses + 4) {
      setState(() => _waterGlasses++);
    }
  }

  void _decrementWater() {
    if (_waterGlasses > 0) {
      setState(() => _waterGlasses--);
    }
  }

  void _toggleMeal(_MealType type) {
    setState(() {
      if (_expandedMeals.contains(type)) {
        _expandedMeals.remove(type);
      } else {
        _expandedMeals.add(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('daily-nutrition-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: const Text('Nutricion'),
        ),
        actions: [
          Semantics(
            label: 'Ver historial de nutricion',
            button: true,
            child: IconButton(
              key: const ValueKey('nutrition-history-button'),
              icon: const Icon(Icons.history_outlined),
              onPressed: () {
                // TODO: navegar a historial cuando se conecte
              },
              tooltip: 'Historial',
            ),
          ),
          Semantics(
            label: 'Configurar metas nutricionales',
            button: true,
            child: IconButton(
              key: const ValueKey('nutrition-goals-nav-button'),
              icon: const Icon(Icons.tune_outlined),
              onPressed: () {
                // TODO: navegar a NutritionGoalsScreen cuando se conecte
              },
              tooltip: 'Metas',
            ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Agregar comida al registro de hoy',
        button: true,
        child: FloatingActionButton(
          key: const ValueKey('nutrition-add-meal-fab'),
          onPressed: () {
            // TODO: navegar a MealLogScreen cuando se conecte
          },
          backgroundColor: AppColors.nutrition,
          foregroundColor: Colors.white,
          tooltip: 'Agregar comida',
          child: const Icon(Icons.add),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.nutrition,
        onRefresh: () async {
          // TODO: llamar a provider.refresh() cuando se conecte
          await Future<void>.delayed(const Duration(milliseconds: 600));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            // --- Anillos de macros ---
            Semantics(
              label:
                  'Resumen de macros: ${_mockMacros.map((m) => '${m.label} ${m.current.toStringAsFixed(0)} de ${m.goal.toStringAsFixed(0)} ${m.unit}').join(', ')}',
              child: _MacroRingsSection(
                key: const ValueKey('nutrition-macro-rings'),
                macros: _mockMacros,
              ),
            ),
            const SizedBox(height: 20),

            // --- Lista de comidas agrupadas por tipo ---
            Semantics(
              header: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Comidas de hoy',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            ..._mockMeals.map(
              (meal) => _MealSection(
                key: ValueKey('nutrition-meal-section-${meal.type.name}'),
                meal: meal,
                isExpanded: _expandedMeals.contains(meal.type),
                onToggle: () => _toggleMeal(meal.type),
              ),
            ),
            const SizedBox(height: 20),

            // --- Rastreador de agua ---
            Semantics(
              label:
                  'Rastreador de agua: $_waterGlasses de $_waterGoalGlasses vasos consumidos',
              child: _WaterTrackerCard(
                key: const ValueKey('nutrition-water-tracker'),
                glasses: _waterGlasses,
                goalGlasses: _waterGoalGlasses,
                mlPerGlass: _mlPerGlass,
                onIncrement: _incrementWater,
                onDecrement: _decrementWater,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: anillos de macros
// ---------------------------------------------------------------------------

class _MacroRingsSection extends StatelessWidget {
  const _MacroRingsSection({
    super.key,
    required this.macros,
  });

  final List<_MockMacro> macros;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: macros
              .map(
                (macro) => _MacroRing(
                  key: ValueKey('macro-ring-${macro.label}'),
                  macro: macro,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _MacroRing extends StatelessWidget {
  const _MacroRing({
    super.key,
    required this.macro,
  });

  final _MockMacro macro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label:
          '${macro.label}: ${macro.current.toStringAsFixed(0)} de ${macro.goal.toStringAsFixed(0)} ${macro.unit}, ${(macro.progress * 100).round()}%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 68,
            height: 68,
            child: CustomPaint(
              painter: _RingPainter(
                progress: macro.progress,
                color: macro.color,
                backgroundColor:
                    theme.dividerColor.withAlpha(60),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      macro.current.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: macro.color,
                      ),
                    ),
                    Text(
                      macro.unit,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            macro.label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'meta: ${macro.goal.toStringAsFixed(0)}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  final double progress;
  final Color color;
  final Color backgroundColor;

  static const double _strokeWidth = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - _strokeWidth / 2;
    const startAngle = -math.pi / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.backgroundColor != backgroundColor;
}

// ---------------------------------------------------------------------------
// Widget: seccion de comida expandible
// ---------------------------------------------------------------------------

class _MealSection extends StatelessWidget {
  const _MealSection({
    super.key,
    required this.meal,
    required this.isExpanded,
    required this.onToggle,
  });

  final _MockMealEntry meal;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCal = meal.totalCalories;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // Encabezado de comida
          Semantics(
            label:
                '${meal.type.label}: ${meal.items.length} alimentos, ${totalCal.toStringAsFixed(0)} kcal. '
                '${isExpanded ? 'Toca para colapsar' : 'Toca para expandir'}',
            button: true,
            child: InkWell(
              key: ValueKey(
                'nutrition-meal-header-${meal.type.name}',
              ),
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.nutrition.withAlpha(25),
                      child: Icon(
                        meal.type.icon,
                        color: AppColors.nutrition,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.type.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${meal.items.length} alimento${meal.items.length != 1 ? 's' : ''} · '
                            '${totalCal.toStringAsFixed(0)} kcal',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.nutrition,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      label: 'Agregar alimento a ${meal.type.label}',
                      button: true,
                      child: IconButton(
                        key: ValueKey(
                          'nutrition-add-to-meal-${meal.type.name}',
                        ),
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        color: AppColors.nutrition,
                        onPressed: () {
                          // TODO: navegar a FoodSearchScreen cuando se conecte
                        },
                        tooltip: 'Agregar a ${meal.type.label}',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Items de la comida
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                ...meal.items.map(
                  (item) => _FoodItemTile(
                    key: ValueKey('nutrition-food-item-${item.id}'),
                    item: item,
                  ),
                ),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: tile de alimento en la lista de comida
// ---------------------------------------------------------------------------

class _FoodItemTile extends StatelessWidget {
  const _FoodItemTile({
    super.key,
    required this.item,
  });

  final _MockFoodItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label:
          '${item.name}, ${item.serving}, ${item.calories.toStringAsFixed(0)} kcal, '
          'proteina ${item.proteinG.toStringAsFixed(0)} g, '
          'carbos ${item.carbsG.toStringAsFixed(0)} g, '
          'grasa ${item.fatG.toStringAsFixed(0)} g',
      child: ListTile(
        key: ValueKey('nutrition-food-tile-${item.id}'),
        dense: true,
        contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        title: Text(
          item.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          item.serving,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.calories.toStringAsFixed(0)} kcal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.nutrition,
                fontWeight: FontWeight.w600,
              ),
            ),
            Semantics(
              label: 'Eliminar ${item.name} de la comida',
              button: true,
              child: IconButton(
                key: ValueKey('nutrition-remove-food-${item.id}'),
                icon: const Icon(Icons.remove_circle_outline, size: 18),
                color: Colors.grey,
                onPressed: () {
                  // TODO: llamar a NutritionNotifier.removeFoodItem cuando se conecte
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: rastreador de agua
// ---------------------------------------------------------------------------

class _WaterTrackerCard extends StatelessWidget {
  const _WaterTrackerCard({
    super.key,
    required this.glasses,
    required this.goalGlasses,
    required this.mlPerGlass,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int glasses;
  final int goalGlasses;
  final double mlPerGlass;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (glasses / goalGlasses).clamp(0.0, 1.0);
    final totalMl = glasses * mlPerGlass;
    final goalMl = goalGlasses * mlPerGlass;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                const Icon(Icons.water_drop_outlined, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Semantics(
                  header: true,
                  child: Text(
                    'Agua',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${totalMl.toStringAsFixed(0)} / ${goalMl.toStringAsFixed(0)} ml',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF3B82F6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Vasos visuales
            Semantics(
              label: '$glasses de $goalGlasses vasos consumidos',
              child: Wrap(
                key: const ValueKey('nutrition-water-glasses'),
                spacing: 6,
                runSpacing: 6,
                children: List.generate(goalGlasses, (i) {
                  final filled = i < glasses;
                  return Semantics(
                    label: 'Vaso ${i + 1}: ${filled ? 'lleno' : 'vacio'}',
                    child: Icon(
                      filled ? Icons.water_drop : Icons.water_drop_outlined,
                      color: filled
                          ? const Color(0xFF3B82F6)
                          : theme.dividerColor,
                      size: 22,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),

            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                key: const ValueKey('nutrition-water-progress-bar'),
                value: progress,
                backgroundColor: theme.dividerColor,
                color: const Color(0xFF3B82F6),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),

            // Controles +/-
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Quitar un vaso de agua',
                  button: true,
                  child: IconButton(
                    key: const ValueKey('nutrition-water-decrement'),
                    onPressed: glasses > 0 ? onDecrement : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: glasses > 0
                        ? const Color(0xFF3B82F6)
                        : Colors.grey,
                    iconSize: 28,
                    tooltip: 'Quitar vaso',
                  ),
                ),
                const SizedBox(width: 16),
                Semantics(
                  label: '$glasses vasos',
                  child: Text(
                    '$glasses vasos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Semantics(
                  label: 'Agregar un vaso de agua',
                  button: true,
                  child: IconButton(
                    key: const ValueKey('nutrition-water-increment'),
                    onPressed: onIncrement,
                    icon: const Icon(Icons.add_circle_outline),
                    color: const Color(0xFF3B82F6),
                    iconSize: 28,
                    tooltip: 'Agregar vaso',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
