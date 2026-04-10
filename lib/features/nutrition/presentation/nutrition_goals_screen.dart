import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/nutrition/domain/nutrition_input.dart';

// Default values when no goal is set
const _defaultCalories = 2000;
const _defaultProteinG = 150.0;
const _defaultCarbsG = 250.0;
const _defaultFatG = 65.0;
const _defaultWaterMl = 2000;

// ---------------------------------------------------------------------------
// Pantalla: configuracion de metas nutricionales
// ---------------------------------------------------------------------------

/// Formulario para establecer las metas nutricionales: calorias, macros y agua.
/// Muestra un aviso si los macros no coinciden con el objetivo de calorias.
///
/// Shell de presentacion — la integracion con Riverpod se realizara en un
/// paso posterior.
///
/// Accesibilidad: A11Y-NUT-04 — todos los campos y avisos tienen etiquetas
/// semanticas.
class NutritionGoalsScreen extends ConsumerStatefulWidget {
  const NutritionGoalsScreen({super.key});

  @override
  ConsumerState<NutritionGoalsScreen> createState() =>
      _NutritionGoalsScreenState();
}

class _NutritionGoalsScreenState
    extends ConsumerState<NutritionGoalsScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _waterController;

  // Valores en tiempo real para la validacion de macros
  int _calories = _defaultCalories;
  double _protein = _defaultProteinG;
  double _carbs = _defaultCarbsG;
  double _fat = _defaultFatG;
  int _water = _defaultWaterMl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _caloriesController = TextEditingController(
      text: _defaultCalories.toString(),
    );
    _proteinController = TextEditingController(
      text: _defaultProteinG.toStringAsFixed(1),
    );
    _carbsController = TextEditingController(
      text: _defaultCarbsG.toStringAsFixed(1),
    );
    _fatController = TextEditingController(
      text: _defaultFatG.toStringAsFixed(1),
    );
    _waterController = TextEditingController(
      text: _defaultWaterMl.toString(),
    );
    _loadCurrentGoal();
  }

  Future<void> _loadCurrentGoal() async {
    final repo = ref.read(nutritionDataRepositoryProvider);
    final goal = await repo.getActiveGoal(DateTime.now());
    if (goal == null || !mounted) return;
    setState(() {
      _calories = goal.caloriesKcal;
      _protein = goal.proteinG;
      _carbs = goal.carbsG;
      _fat = goal.fatG;
      _water = goal.waterMl;
    });
    _caloriesController.text = _calories.toString();
    _proteinController.text = _protein.toStringAsFixed(1);
    _carbsController.text = _carbs.toStringAsFixed(1);
    _fatController.text = _fat.toStringAsFixed(1);
    _waterController.text = _water.toString();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  double get _caloriesFromMacros => _protein * 4 + _carbs * 4 + _fat * 9;

  bool get _macrosMismatch =>
      (_calories - _caloriesFromMacros).abs() > 50;

  void _updateCalories(String v) {
    setState(() => _calories = int.tryParse(v) ?? _calories);
  }

  void _updateProtein(String v) {
    setState(() => _protein = double.tryParse(v) ?? _protein);
  }

  void _updateCarbs(String v) {
    setState(() => _carbs = double.tryParse(v) ?? _carbs);
  }

  void _updateFat(String v) {
    setState(() => _fat = double.tryParse(v) ?? _fat);
  }

  void _updateWater(String v) {
    setState(() => _water = int.tryParse(v) ?? _water);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(nutritionNotifierProvider);
    final result = await notifier.setNutritionGoal(
      NutritionGoalInput(
        caloriesKcal: _calories,
        proteinG: _protein,
        carbsG: _carbs,
        fatG: _fat,
        waterMl: _water,
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
      key: const ValueKey('nutrition-goals-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.nutrition,
        title: Semantics(
          header: true,
          child: const Text('Metas nutricionales'),
        ),
        leading: Semantics(
          label: 'Volver sin guardar',
          button: true,
          child: IconButton(
            key: const ValueKey('nutrition-goals-back-button'),
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver',
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            // --- Aviso de discordancia de macros ---
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _MacrosMismatchBanner(
                key: const ValueKey('nutrition-goals-mismatch-banner'),
                caloriesTarget: _calories,
                caloriesFromMacros: _caloriesFromMacros,
              ),
              crossFadeState: _macrosMismatch
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
            if (_macrosMismatch) const SizedBox(height: 16),

            // --- Seccion: Energia ---
            const _SectionHeader(label: 'Energia diaria'),
            const SizedBox(height: 12),

            Semantics(
              label: 'Objetivo de calorias diarias en kcal',
              textField: true,
              child: TextFormField(
                key: const ValueKey('nutrition-goals-calories-field'),
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Calorias objetivo',
                  suffixText: 'kcal',
                  prefixIcon: const Icon(
                    Icons.local_fire_department_outlined,
                    color: AppColors.nutrition,
                  ),
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.nutrition,
                      width: 2,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                onChanged: _updateCalories,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Campo requerido';
                  }
                  final parsed = int.tryParse(v);
                  if (parsed == null || parsed < 500 || parsed > 10000) {
                    return 'Ingresa un valor entre 500 y 10.000 kcal';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),

            // --- Seccion: Macronutrientes ---
            const _SectionHeader(label: 'Macronutrientes'),
            const SizedBox(height: 4),
            Text(
              'P × 4 + C × 4 + G × 9 = calorias. Se mostrara aviso si la '
              'diferencia supera 50 kcal.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),

            // Proteina
            Semantics(
              label: 'Objetivo de proteina en gramos',
              textField: true,
              child: TextFormField(
                key: const ValueKey('nutrition-goals-protein-field'),
                controller: _proteinController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Proteina',
                  suffixText: 'g',
                  prefixIcon: Icon(
                    Icons.egg_outlined,
                    color: Color(0xFF3B82F6),
                  ),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: _updateProtein,
                validator: _validateMacroGrams,
              ),
            ),
            const SizedBox(height: 12),

            // Carbohidratos
            Semantics(
              label: 'Objetivo de carbohidratos en gramos',
              textField: true,
              child: TextFormField(
                key: const ValueKey('nutrition-goals-carbs-field'),
                controller: _carbsController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Carbohidratos',
                  suffixText: 'g',
                  prefixIcon: Icon(
                    Icons.grain_outlined,
                    color: Color(0xFF10B981),
                  ),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF10B981),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: _updateCarbs,
                validator: _validateMacroGrams,
              ),
            ),
            const SizedBox(height: 12),

            // Grasa
            Semantics(
              label: 'Objetivo de grasa en gramos',
              textField: true,
              child: TextFormField(
                key: const ValueKey('nutrition-goals-fat-field'),
                controller: _fatController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Grasa',
                  suffixText: 'g',
                  prefixIcon: Icon(
                    Icons.water_drop_outlined,
                    color: Color(0xFFEC4899),
                  ),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFFEC4899),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: _updateFat,
                validator: _validateMacroGrams,
              ),
            ),
            const SizedBox(height: 24),

            // --- Seccion: Hidratacion ---
            const _SectionHeader(label: 'Hidratacion'),
            const SizedBox(height: 12),

            Semantics(
              label: 'Objetivo de agua diaria en mililitros',
              textField: true,
              child: TextFormField(
                key: const ValueKey('nutrition-goals-water-field'),
                controller: _waterController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Agua objetivo',
                  suffixText: 'ml',
                  prefixIcon: Icon(
                    Icons.local_drink_outlined,
                    color: Color(0xFF3B82F6),
                  ),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: _updateWater,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Campo requerido';
                  }
                  final parsed = int.tryParse(v);
                  if (parsed == null || parsed < 500 || parsed > 8000) {
                    return 'Ingresa un valor entre 500 y 8.000 ml';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),

            // Hint de vasos
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.info,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Un vaso standard equivale a 250 ml. '
                    '${(_water / 250).toStringAsFixed(1)} vasos por dia.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- Boton guardar ---
            Semantics(
              label: 'Guardar metas nutricionales',
              button: true,
              child: FilledButton.icon(
                key: const ValueKey('nutrition-goals-save-button'),
                onPressed: _isSaving ? null : _handleSave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.nutrition,
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text(
                  'Guardar metas',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateMacroGrams(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo requerido';
    final parsed = double.tryParse(v);
    if (parsed == null || parsed < 0 || parsed > 1000) {
      return 'Ingresa un valor entre 0 y 1.000 g';
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Widget: aviso de discordancia de macros
// ---------------------------------------------------------------------------

class _MacrosMismatchBanner extends StatelessWidget {
  const _MacrosMismatchBanner({
    super.key,
    required this.caloriesTarget,
    required this.caloriesFromMacros,
  });

  final int caloriesTarget;
  final double caloriesFromMacros;

  @override
  Widget build(BuildContext context) {
    final diff = (caloriesTarget - caloriesFromMacros).round();
    final overOrUnder = diff > 0 ? 'por debajo' : 'por encima';
    final absDiff = diff.abs();

    return Semantics(
      label:
          'Aviso: los macros suman ${caloriesFromMacros.toStringAsFixed(0)} kcal, '
          '$absDiff kcal $overOrUnder del objetivo de $caloriesTarget kcal.',
      child: Container(
        key: const ValueKey('nutrition-goals-mismatch-banner'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withAlpha(80)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Los macros no coinciden con las calorias',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Los macros suman ${caloriesFromMacros.toStringAsFixed(0)} kcal '
                    '(P × 4 + C × 4 + G × 9), mientras que el objetivo es '
                    '$caloriesTarget kcal. Diferencia: $absDiff kcal $overOrUnder.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: encabezado de seccion del formulario
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.nutrition,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.nutrition,
                ),
          ),
        ],
      ),
    );
  }
}
