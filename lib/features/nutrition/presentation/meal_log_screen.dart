import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_os/core/constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Modelos mock
// ---------------------------------------------------------------------------

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

/// Detecta el tipo de comida sugerido segun la hora del dia.
_MealType _suggestMealType() {
  final hour = DateTime.now().hour;
  if (hour < 10) return _MealType.desayuno;
  if (hour < 14) return _MealType.almuerzo;
  if (hour < 19) return _MealType.cena;
  return _MealType.snack;
}

class _MockLoggedFood {
  _MockLoggedFood({
    required this.id,
    required this.name,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.quantityG,
  });

  final int id;
  final String name;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  double quantityG;

  double get calories => caloriesPer100g * quantityG / 100;
  double get proteinG => proteinPer100g * quantityG / 100;
  double get carbsG => carbsPer100g * quantityG / 100;
  double get fatG => fatPer100g * quantityG / 100;
}

List<_MockLoggedFood> _buildMockItems() => [
      _MockLoggedFood(
        id: 1,
        name: 'Pechuga de pollo',
        caloriesPer100g: 165,
        proteinPer100g: 31,
        carbsPer100g: 0,
        fatPer100g: 3.6,
        quantityG: 150,
      ),
      _MockLoggedFood(
        id: 2,
        name: 'Arroz blanco cocido',
        caloriesPer100g: 130,
        proteinPer100g: 2.7,
        carbsPer100g: 28,
        fatPer100g: 0.3,
        quantityG: 200,
      ),
      _MockLoggedFood(
        id: 3,
        name: 'Ensalada mixta',
        caloriesPer100g: 15,
        proteinPer100g: 1.2,
        carbsPer100g: 2.5,
        fatPer100g: 0.2,
        quantityG: 100,
      ),
    ];

// ---------------------------------------------------------------------------
// Pantalla: registro de comida
// ---------------------------------------------------------------------------

/// Formulario para registrar una comida con selector de tipo, lista de
/// alimentos con ajuste de cantidad, nota y total de macros corriente.
///
/// Shell de presentacion — la integracion con Riverpod se realizara en un
/// paso posterior.
///
/// Accesibilidad: A11Y-NUT-03 — todos los campos tienen etiquetas semanticas.
class MealLogScreen extends StatefulWidget {
  const MealLogScreen({super.key});

  @override
  State<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends State<MealLogScreen> {
  late _MealType _selectedMealType;
  late final List<_MockLoggedFood> _items;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMealType = _suggestMealType();
    _items = _buildMockItems();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  double get _totalCalories =>
      _items.fold(0.0, (sum, i) => sum + i.calories);

  double get _totalProtein =>
      _items.fold(0.0, (sum, i) => sum + i.proteinG);

  double get _totalCarbs =>
      _items.fold(0.0, (sum, i) => sum + i.carbsG);

  double get _totalFat =>
      _items.fold(0.0, (sum, i) => sum + i.fatG);

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _updateQuantity(int index, double newQty) {
    if (newQty > 0) {
      setState(() => _items[index].quantityG = newQty);
    }
  }

  void _handleSave() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Agrega al menos un alimento para registrar la comida'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    // TODO: llamar a NutritionNotifier.logMeal cuando se conecte
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('meal-log-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: const Text('Registrar comida'),
        ),
        leading: Semantics(
          label: 'Volver sin guardar',
          button: true,
          child: IconButton(
            key: const ValueKey('meal-log-back-button'),
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver',
          ),
        ),
        actions: [
          Semantics(
            label: 'Guardar comida registrada',
            button: true,
            child: TextButton.icon(
              key: const ValueKey('meal-log-save-button'),
              onPressed: _handleSave,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.nutrition,
              ),
              icon: const Icon(Icons.check),
              label: const Text(
                'Guardar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                // --- Selector de tipo de comida ---
                Semantics(
                  header: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Tipo de comida',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  label:
                      'Seleccionar tipo de comida, actualmente: ${_selectedMealType.label}',
                  child: Wrap(
                    key: const ValueKey('meal-log-type-chips'),
                    spacing: 8,
                    children: _MealType.values.map((type) {
                      final isSelected = type == _selectedMealType;
                      return Semantics(
                        label:
                            '${type.label}${isSelected ? ', seleccionado' : ''}',
                        button: true,
                        child: FilterChip(
                          key: ValueKey(
                            'meal-log-type-chip-${type.name}',
                          ),
                          label: Text(type.label),
                          avatar: Icon(
                            type.icon,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppColors.nutrition,
                          ),
                          selected: isSelected,
                          onSelected: (_) =>
                              setState(() => _selectedMealType = type),
                          selectedColor: AppColors.nutrition,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.nutrition
                                : theme.dividerColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // --- Lista de alimentos ---
                Row(
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Alimentos (${_items.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Semantics(
                      label: 'Buscar y agregar alimento',
                      button: true,
                      child: TextButton.icon(
                        key: const ValueKey('meal-log-add-food-button'),
                        onPressed: () {
                          // TODO: navegar a FoodSearchScreen cuando se conecte
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.nutrition,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_items.isEmpty)
                  _EmptyFoodList(
                    key: const ValueKey('meal-log-empty-food'),
                    onAdd: () {
                      // TODO: navegar a FoodSearchScreen cuando se conecte
                    },
                  )
                else
                  ..._items.asMap().entries.map(
                    (entry) => _LoggedFoodRow(
                      key: ValueKey(
                        'meal-log-food-row-${entry.value.id}',
                      ),
                      food: entry.value,
                      onRemove: () => _removeItem(entry.key),
                      onQuantityChanged: (qty) =>
                          _updateQuantity(entry.key, qty),
                    ),
                  ),
                const SizedBox(height: 20),

                // --- Campo de nota ---
                Semantics(
                  label: 'Nota para esta comida (opcional)',
                  textField: true,
                  child: TextField(
                    key: const ValueKey('meal-log-note-field'),
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                      hintText: 'Ej. Comida en restaurante, sin sal...',
                      prefixIcon: Icon(Icons.notes_outlined),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.nutrition,
                          width: 2,
                        ),
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    maxLength: 300,
                  ),
                ),
              ],
            ),
          ),

          // --- Total de macros corriente ---
          _MacroTotalBar(
            key: const ValueKey('meal-log-macro-total'),
            calories: _totalCalories,
            proteinG: _totalProtein,
            carbsG: _totalCarbs,
            fatG: _totalFat,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: fila de alimento con ajuste de cantidad
// ---------------------------------------------------------------------------

class _LoggedFoodRow extends StatefulWidget {
  const _LoggedFoodRow({
    super.key,
    required this.food,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  final _MockLoggedFood food;
  final VoidCallback onRemove;
  final ValueChanged<double> onQuantityChanged;

  @override
  State<_LoggedFoodRow> createState() => _LoggedFoodRowState();
}

class _LoggedFoodRowState extends State<_LoggedFoodRow> {
  late final TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.food.quantityG.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final food = widget.food;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado del alimento
            Row(
              children: [
                Expanded(
                  child: Text(
                    food.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${food.calories.toStringAsFixed(0)} kcal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.nutrition,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Semantics(
                  label: 'Eliminar ${food.name} de la comida',
                  button: true,
                  child: IconButton(
                    key: ValueKey('meal-log-remove-food-${food.id}'),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: AppColors.error,
                    onPressed: widget.onRemove,
                    tooltip: 'Eliminar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Ajuste de cantidad y macros
            Row(
              children: [
                // Campo de cantidad
                SizedBox(
                  width: 90,
                  child: Semantics(
                    label: 'Cantidad en gramos de ${food.name}',
                    textField: true,
                    child: TextField(
                      key: ValueKey('meal-log-qty-${food.id}'),
                      controller: _qtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        suffixText: 'g',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.nutrition,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null && parsed > 0) {
                          widget.onQuantityChanged(parsed);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Macros calculados
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MacroChip(
                        label: 'P',
                        value: food.proteinG,
                        color: const Color(0xFF3B82F6),
                      ),
                      _MacroChip(
                        label: 'C',
                        value: food.carbsG,
                        color: const Color(0xFF10B981),
                      ),
                      _MacroChip(
                        label: 'G',
                        value: food.fatG,
                        color: const Color(0xFFEC4899),
                      ),
                    ],
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

// ---------------------------------------------------------------------------
// Widget: indicador compacto de macro
// ---------------------------------------------------------------------------

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${value.toStringAsFixed(1)}g',
          style: TextStyle(
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: estado vacio de alimentos
// ---------------------------------------------------------------------------

class _EmptyFoodList extends StatelessWidget {
  const _EmptyFoodList({
    super.key,
    required this.onAdd,
  });

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.no_food_outlined,
            size: 48,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin alimentos',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Agregar primer alimento',
            button: true,
            child: FilledButton.icon(
              key: const ValueKey('meal-log-add-first-food'),
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.nutrition,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar alimento'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: barra de totales de macros
// ---------------------------------------------------------------------------

class _MacroTotalBar extends StatelessWidget {
  const _MacroTotalBar({
    super.key,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label:
          'Total de la comida: ${calories.toStringAsFixed(0)} kcal, '
          'proteina ${proteinG.toStringAsFixed(1)} g, '
          'carbos ${carbsG.toStringAsFixed(1)} g, '
          'grasa ${fatG.toStringAsFixed(1)} g',
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total de la comida',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TotalMacroItem(
                  label: 'Calorias',
                  value: '${calories.toStringAsFixed(0)} kcal',
                  color: AppColors.nutrition,
                ),
                _TotalMacroItem(
                  label: 'Proteina',
                  value: '${proteinG.toStringAsFixed(1)} g',
                  color: const Color(0xFF3B82F6),
                ),
                _TotalMacroItem(
                  label: 'Carbos',
                  value: '${carbsG.toStringAsFixed(1)} g',
                  color: const Color(0xFF10B981),
                ),
                _TotalMacroItem(
                  label: 'Grasa',
                  value: '${fatG.toStringAsFixed(1)} g',
                  color: const Color(0xFFEC4899),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalMacroItem extends StatelessWidget {
  const _TotalMacroItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}
