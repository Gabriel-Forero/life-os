import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/nutrition/domain/nutrition_input.dart';
import 'package:life_os/features/nutrition/presentation/food_search_screen.dart';

// ---------------------------------------------------------------------------
// Helpers de tipo de comida
// ---------------------------------------------------------------------------

const _mealTypeValues = ['breakfast', 'lunch', 'dinner', 'snack'];

String _mealLabel(String type) => switch (type) {
      'breakfast' => 'Desayuno',
      'lunch' => 'Almuerzo',
      'dinner' => 'Cena',
      'snack' => 'Snack',
      _ => type,
    };

IconData _mealIcon(String type) => switch (type) {
      'breakfast' => Icons.wb_sunny_outlined,
      'lunch' => Icons.restaurant_outlined,
      'dinner' => Icons.nightlight_outlined,
      'snack' => Icons.apple_outlined,
      _ => Icons.restaurant_menu_outlined,
    };

String _suggestMealType() {
  final hour = DateTime.now().hour;
  if (hour < 10) return 'breakfast';
  if (hour < 14) return 'lunch';
  if (hour < 19) return 'dinner';
  return 'snack';
}

// Local model: a food item selected for the meal with mutable quantity
class _LoggedFoodItem {
  _LoggedFoodItem({required this.food, required this.quantityG});

  final FoodItem food;
  double quantityG;

  // Convenience delegates
  int get id => food.id;
  String get name => food.name;

  double get calories => food.caloriesPer100g * quantityG / 100;
  double get proteinG => food.proteinPer100g * quantityG / 100;
  double get carbsG => food.carbsPer100g * quantityG / 100;
  double get fatG => food.fatPer100g * quantityG / 100;
}

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
class MealLogScreen extends ConsumerStatefulWidget {
  const MealLogScreen({super.key});

  @override
  ConsumerState<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends ConsumerState<MealLogScreen> {
  late String _selectedMealType;
  final List<_LoggedFoodItem> _items = [];
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMealType = _suggestMealType();
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

  Future<void> _openFoodSearch() async {
    final result = await Navigator.of(context).push<FoodItem>(
      MaterialPageRoute(
        builder: (_) => const FoodSearchScreen(returnFood: true),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _items.add(
          _LoggedFoodItem(
            food: result,
            quantityG: result.servingSizeG,
          ),
        );
      });
    }
  }

  Future<void> _handleSave() async {
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

    setState(() => _isSaving = true);

    final notifier = ref.read(nutritionNotifierProvider);
    final result = await notifier.logMeal(
      MealLogInput(
        mealType: _selectedMealType,
        items: _items
            .map((i) => MealItemInput(
                  foodItemId: i.food.id,
                  quantityG: i.quantityG,
                ))
            .toList(),
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      ),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guardado!')),
        );
        Navigator.of(context).pop();
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(f.userMessage)),
        );
      },
    );
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
              onPressed: _isSaving ? null : _handleSave,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.nutrition,
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.nutrition,
                      ),
                    )
                  : const Icon(Icons.check),
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
                      'Seleccionar tipo de comida, actualmente: ${_mealLabel(_selectedMealType)}',
                  child: Wrap(
                    key: const ValueKey('meal-log-type-chips'),
                    spacing: 8,
                    children: _mealTypeValues.map((type) {
                      final isSelected = type == _selectedMealType;
                      return Semantics(
                        label:
                            '${_mealLabel(type)}${isSelected ? ', seleccionado' : ''}',
                        button: true,
                        child: FilterChip(
                          key: ValueKey('meal-log-type-chip-$type'),
                          label: Text(_mealLabel(type)),
                          avatar: Icon(
                            _mealIcon(type),
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
                        onPressed: _openFoodSearch,
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
                    onAdd: _openFoodSearch,
                  )
                else
                  ..._items.asMap().entries.map(
                    (entry) => _LoggedFoodRow(
                      key: ValueKey(
                        'meal-log-food-row-${entry.value.food.id}-${entry.key}',
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
// TODO: Extract to separate widget file
// ---------------------------------------------------------------------------

class _LoggedFoodRow extends StatefulWidget {
  const _LoggedFoodRow({
    super.key,
    required this.food,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  final _LoggedFoodItem food;
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
                    food.food.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
                  label: 'Eliminar ${food.food.name} de la comida',
                  button: true,
                  child: IconButton(
                    key: ValueKey('meal-log-remove-food-${food.food.id}'),
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
