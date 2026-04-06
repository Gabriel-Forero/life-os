import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/nutrition/domain/nutrition_input.dart';
import 'package:life_os/features/nutrition/domain/nutrition_validators.dart';

class ManualFoodEntryScreen extends ConsumerStatefulWidget {
  const ManualFoodEntryScreen({super.key});

  @override
  ConsumerState<ManualFoodEntryScreen> createState() =>
      _ManualFoodEntryScreenState();
}

class _ManualFoodEntryScreenState
    extends ConsumerState<ManualFoodEntryScreen> {
  final _nameController = TextEditingController();
  final _gramsController = TextEditingController(text: '100');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  String _mealType = suggestMealType(DateTime.now());
  bool _saveToLibrary = true;

  @override
  void dispose() {
    _nameController.dispose();
    _gramsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el nombre de la comida')),
      );
      return;
    }

    final grams = double.tryParse(_gramsController.text) ?? 100;
    final calories = int.tryParse(_caloriesController.text) ?? 0;
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;

    // Calculate per-100g values from the entered portion
    final factor = grams > 0 ? 100 / grams : 1.0;
    final calPer100 = (calories * factor).round();
    final protPer100 = protein * factor;
    final carbsPer100 = carbs * factor;
    final fatPer100 = fat * factor;

    final notifier = ref.read(nutritionNotifierProvider);

    // Create custom food item
    final foodResult = await notifier.addCustomFood(CustomFoodInput(
      name: name,
      caloriesPer100g: calPer100,
      proteinPer100g: protPer100,
      carbsPer100g: carbsPer100,
      fatPer100g: fatPer100,
      servingSizeG: grams,
    ));

    if (!mounted) return;

    if (foodResult.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(foodResult.failureOrNull?.userMessage ?? 'Error')),
      );
      return;
    }

    final foodId = foodResult.valueOrNull!;

    // Log the meal immediately
    final mealResult = await notifier.logMeal(MealLogInput(
      mealType: _mealType,
      items: [MealItemInput(foodItemId: foodId, quantityG: grams)],
    ));

    if (!mounted) return;

    if (mealResult.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name registrado! ${calories} cal, ${protein}g proteina'),
          backgroundColor: AppColors.nutrition,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mealResult.failureOrNull?.userMessage ?? 'Error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Manual'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.nutrition,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Meal type chips
          Wrap(
            spacing: 8,
            children: ['breakfast', 'lunch', 'dinner', 'snack'].map((type) {
              final label = switch (type) {
                'breakfast' => 'Desayuno',
                'lunch' => 'Almuerzo',
                'dinner' => 'Cena',
                _ => 'Snack',
              };
              final icon = switch (type) {
                'breakfast' => Icons.wb_sunny_outlined,
                'lunch' => Icons.restaurant,
                'dinner' => Icons.nights_stay_outlined,
                _ => Icons.cookie_outlined,
              };
              return ChoiceChip(
                key: ValueKey('meal-type-$type'),
                label: Text(label),
                avatar: Icon(icon, size: 16),
                selected: _mealType == type,
                selectedColor: AppColors.nutrition.withAlpha(50),
                onSelected: (_) => setState(() => _mealType = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Name
          TextField(
            key: const ValueKey('manual-food-name'),
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la comida *',
              hintText: 'Ej: Arroz con pollo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.restaurant_menu),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          // Grams
          TextField(
            key: const ValueKey('manual-food-grams'),
            controller: _gramsController,
            decoration: const InputDecoration(
              labelText: 'Porcion (gramos)',
              hintText: '100',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.scale),
              suffixText: 'g',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
          ),
          const SizedBox(height: 24),

          // Macros header
          Text('Valores nutricionales (de la porcion)',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.nutrition,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 12),

          // Calories
          TextField(
            key: const ValueKey('manual-food-calories'),
            controller: _caloriesController,
            decoration: InputDecoration(
              labelText: 'Calorias',
              hintText: '0',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.local_fire_department),
              suffixText: 'kcal',
              filled: true,
              fillColor: AppColors.nutrition.withAlpha(10),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),

          // Protein, Carbs, Fat in a row
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('manual-food-protein'),
                  controller: _proteinController,
                  decoration: const InputDecoration(
                    labelText: 'Proteina',
                    hintText: '0',
                    border: OutlineInputBorder(),
                    suffixText: 'g',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const ValueKey('manual-food-carbs'),
                  controller: _carbsController,
                  decoration: const InputDecoration(
                    labelText: 'Carbos',
                    hintText: '0',
                    border: OutlineInputBorder(),
                    suffixText: 'g',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const ValueKey('manual-food-fat'),
                  controller: _fatController,
                  decoration: const InputDecoration(
                    labelText: 'Grasa',
                    hintText: '0',
                    border: OutlineInputBorder(),
                    suffixText: 'g',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Save to library toggle
          SwitchListTile(
            key: const ValueKey('manual-food-save-toggle'),
            title: const Text('Guardar en mi biblioteca'),
            subtitle: const Text('Para usar de nuevo sin reingresar datos'),
            value: _saveToLibrary,
            activeColor: AppColors.nutrition,
            onChanged: (v) => setState(() => _saveToLibrary = v),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              key: const ValueKey('manual-food-save-button'),
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Registrar Comida'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.nutrition,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
