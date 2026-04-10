import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/features/nutrition/domain/nutrition_input.dart';

// ---------------------------------------------------------------------------
// Photo Analysis Screen - Feature 5: AI Photo Analysis (MVP)
// ---------------------------------------------------------------------------

/// Pantalla de analisis de foto de comida con AI.
///
/// Flujo MVP:
/// 1. Usuario toma foto o elige de galeria (almacenada localmente).
/// 2. Usuario escribe descripcion de la comida.
/// 3. AI estima: nombre, calorias/100g, proteina, carbs, grasa, porcion.
/// 4. Usuario edita valores si es necesario.
/// 5. "Guardar" crea un FoodItem personalizado y registra la comida.
///
/// Accesibilidad: A11Y-NUT-05
class PhotoAnalysisScreen extends ConsumerStatefulWidget {
  const PhotoAnalysisScreen({super.key});

  @override
  ConsumerState<PhotoAnalysisScreen> createState() =>
      _PhotoAnalysisScreenState();
}

class _PhotoAnalysisScreenState extends ConsumerState<PhotoAnalysisScreen> {
  final _picker = ImagePicker();
  final _descriptionController = TextEditingController();

  // Form controllers for editing AI estimates
  final _nameController = TextEditingController();
  final _calController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _servingController = TextEditingController(text: '250');

  File? _imageFile;
  bool _isAnalyzing = false;
  bool _analysisComplete = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descriptionController.dispose();
    _nameController.dispose();
    _calController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _servingController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Image picking
  // ---------------------------------------------------------------------------

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;
      setState(() {
        _imageFile = File(picked.path);
        _analysisComplete = false;
        _errorMessage = null;
      });
    } on PlatformException catch (e) {
      setState(
          () => _errorMessage = 'Error al acceder a la camara: ${e.message}');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Seleccionar imagen',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de galeria'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AI Analysis
  // ---------------------------------------------------------------------------

  Future<void> _analyzeWithAI() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() =>
          _errorMessage = 'Escribe una descripcion de la comida para analizar');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final aiNotifier = ref.read(aiNotifierProvider);
      await aiNotifier.initialize();

      final config = await aiNotifier.repository.getDefaultConfiguration();
      if (config == null) {
        // No AI configured — use keyword-based fallback
        _applyFallbackEstimate(description);
        return;
      }

      const systemPrompt =
          'Eres un nutricionista experto. Responde SOLO con JSON valido, sin texto adicional.';

      final userPrompt =
          'Analiza esta comida y estima sus valores nutricionales.\n'
          'Descripcion: "$description"\n\n'
          'Responde SOLO con este JSON (sin codigo markdown, sin texto extra):\n'
          '{"nombre":"nombre del plato","caloriasP100g":150,"proteinaP100g":10.5,'
          '"carbosP100g":20.0,"grasaP100g":5.0,"porcionG":250}';

      final provider = aiNotifier.providerFactory(config);
      final buffer = StringBuffer();

      await for (final chunk in provider.sendMessage(
        userPrompt,
        systemContext: systemPrompt,
      )) {
        buffer.write(chunk);
      }

      _parseAndApplyResponse(buffer.toString().trim(), description);
    } catch (_) {
      _applyFallbackEstimate(description);
    }
  }

  void _parseAndApplyResponse(String response, String description) {
    try {
      // Extract JSON from response (AI might wrap it)
      final jsonMatch = RegExp(
        r'\{[^{}]*\}',
        dotAll: true,
      ).firstMatch(response);

      if (jsonMatch == null) {
        _applyFallbackEstimate(description);
        return;
      }

      final data = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _nameController.text =
              data['nombre']?.toString() ?? _descriptionController.text;
          _calController.text =
              (data['caloriasP100g'] as num?)?.round().toString() ?? '150';
          _proteinController.text =
              (data['proteinaP100g'] as num?)?.toStringAsFixed(1) ?? '8.0';
          _carbsController.text =
              (data['carbosP100g'] as num?)?.toStringAsFixed(1) ?? '20.0';
          _fatController.text =
              (data['grasaP100g'] as num?)?.toStringAsFixed(1) ?? '5.0';
          _servingController.text =
              (data['porcionG'] as num?)?.round().toString() ?? '250';
          _isAnalyzing = false;
          _analysisComplete = true;
          _errorMessage = null;
        });
      }
    } catch (_) {
      _applyFallbackEstimate(description);
    }
  }

  void _applyFallbackEstimate(String description) {
    // Simple keyword-based fallback when AI is not available
    final lower = description.toLowerCase();
    int cal = 150;
    double prot = 8.0, carbs = 20.0, fat = 5.0;
    int serving = 250;

    if (lower.contains('ensalada') ||
        lower.contains('verdura') ||
        lower.contains('vegetal')) {
      cal = 40; prot = 2.0; carbs = 6.0; fat = 1.5; serving = 200;
    } else if (lower.contains('pollo') || lower.contains('pechuga')) {
      cal = 165; prot = 31.0; carbs = 0.0; fat = 3.6; serving = 150;
    } else if (lower.contains('arroz')) {
      cal = 130; prot = 2.7; carbs = 28.0; fat = 0.3; serving = 200;
    } else if (lower.contains('pizza')) {
      cal = 266; prot = 11.0; carbs = 33.0; fat = 10.0; serving = 300;
    } else if (lower.contains('pasta') || lower.contains('espagueti')) {
      cal = 158; prot = 5.8; carbs = 31.0; fat = 0.9; serving = 250;
    } else if (lower.contains('hamburguesa') || lower.contains('burger')) {
      cal = 295; prot = 17.0; carbs = 24.0; fat = 14.0; serving = 200;
    } else if (lower.contains('fruta') ||
        lower.contains('manzana') ||
        lower.contains('platano')) {
      cal = 60; prot = 0.5; carbs = 15.0; fat = 0.2; serving = 150;
    } else if (lower.contains('huevo') || lower.contains('revuelto')) {
      cal = 155; prot = 13.0; carbs = 1.1; fat = 11.0; serving = 100;
    } else if (lower.contains('avena') || lower.contains('cereal')) {
      cal = 389; prot = 17.0; carbs = 66.0; fat = 7.0; serving = 80;
    }

    if (mounted) {
      setState(() {
        _nameController.text = description;
        _calController.text = cal.toString();
        _proteinController.text = prot.toStringAsFixed(1);
        _carbsController.text = carbs.toStringAsFixed(1);
        _fatController.text = fat.toStringAsFixed(1);
        _servingController.text = serving.toString();
        _isAnalyzing = false;
        _analysisComplete = true;
        _errorMessage = null;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Save: create custom food item + log meal
  // ---------------------------------------------------------------------------

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'El nombre del alimento es obligatorio');
      return;
    }

    final cal = int.tryParse(_calController.text);
    if (cal == null || cal <= 0) {
      setState(() => _errorMessage = 'Ingresa calorias validas (mayor a 0)');
      return;
    }

    final prot = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;
    final serving = double.tryParse(_servingController.text) ?? 100;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(nutritionNotifierProvider);

      // 1. Create custom food item
      final foodResult = await notifier.addCustomFood(
        CustomFoodInput(
          name: name,
          caloriesPer100g: cal,
          proteinPer100g: prot,
          carbsPer100g: carbs,
          fatPer100g: fat,
          servingSizeG: serving,
          brand: 'Analisis AI',
        ),
      );

      if (!mounted) return;

      if (foodResult.isFailure) {
        setState(() {
          _isSaving = false;
          _errorMessage = foodResult.failureOrNull!.userMessage;
        });
        return;
      }

      final foodId = foodResult.valueOrNull!;

      // 2. Log the meal
      final mealType = _suggestMealType();
      final mealResult = await notifier.logMeal(
        MealLogInput(
          mealType: mealType,
          items: [
            MealItemInput(
              foodItemId: foodId,
              quantityG: serving,
            ),
          ],
          note: 'Analisis de foto: ${_descriptionController.text.trim()}',
        ),
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      mealResult.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name registrado!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        },
        failure: (f) {
          setState(() => _errorMessage = f.userMessage);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Error al guardar: $e';
        });
      }
    }
  }

  String _suggestMealType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'breakfast';
    if (hour < 14) return 'lunch';
    if (hour < 19) return 'dinner';
    return 'snack';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('photo-analysis-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.nutrition,
        title: Semantics(
          header: true,
          child: const Text('Analizar comida con AI'),
        ),
        leading: Semantics(
          label: 'Volver',
          button: true,
          child: IconButton(
            key: const ValueKey('photo-analysis-back'),
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // --- Imagen ---
          _buildImageSection(theme),
          const SizedBox(height: 20),

          // --- Descripcion ---
          _buildDescriptionSection(theme),
          const SizedBox(height: 16),

          // --- Boton analizar (visible cuando no hay resultado aun) ---
          if (!_analysisComplete) _buildAnalyzeButton(),

          // --- Error ---
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            _buildErrorBanner(theme),
          ],

          // --- Resultados editables ---
          if (_analysisComplete) ...[
            const SizedBox(height: 20),
            _buildResultsSection(theme),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section builders
  // ---------------------------------------------------------------------------

  Widget _buildImageSection(ThemeData theme) {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Semantics(
        label: _imageFile != null
            ? 'Imagen seleccionada. Toca para cambiar.'
            : 'Toca para tomar o elegir una foto de tu comida.',
        button: true,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.nutrition.withAlpha(80),
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _imageFile != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_imageFile!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: FloatingActionButton.small(
                        heroTag: 'change-image-fab',
                        onPressed: _showImageSourceSheet,
                        backgroundColor: AppColors.nutrition,
                        child: const Icon(Icons.edit, size: 16),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 56,
                      color: AppColors.nutrition.withAlpha(150),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tomar foto o elegir de galeria',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.nutrition,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Opcional — la AI usa tu descripcion de texto',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
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
                'Describe la comida',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.nutrition,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          label: 'Descripcion de la comida para analisis AI',
          textField: true,
          child: TextField(
            key: const ValueKey('photo-analysis-description'),
            controller: _descriptionController,
            decoration: const InputDecoration(
              hintText: 'Ej: Arroz con pollo a la plancha y ensalada verde...',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.nutrition, width: 2),
              ),
              prefixIcon: Icon(Icons.description_outlined),
              helperText:
                  'La AI estimara los macros basandose en tu descripcion',
            ),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            maxLength: 300,
            onChanged: (_) {
              if (_analysisComplete) setState(() => _analysisComplete = false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton() {
    return Semantics(
      label: 'Analizar comida con inteligencia artificial',
      button: true,
      child: FilledButton.icon(
        key: const ValueKey('photo-analysis-analyze-button'),
        onPressed: _isAnalyzing ? null : _analyzeWithAI,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.nutrition,
          minimumSize: const Size.fromHeight(52),
        ),
        icon: _isAnalyzing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.auto_awesome_outlined),
        label: Text(
          _isAnalyzing ? 'Analizando...' : 'Analizar con AI',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            Semantics(
              header: true,
              child: Text(
                'Estimacion de macros',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.nutrition,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.nutrition.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 12, color: AppColors.nutrition),
                  const SizedBox(width: 4),
                  Text(
                    'AI',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.nutrition,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Valores por cada 100g. Edita si es necesario.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),

        // Nombre
        Semantics(
          label: 'Nombre del plato',
          textField: true,
          child: TextField(
            key: const ValueKey('photo-analysis-name'),
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre del plato',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.nutrition, width: 2),
              ),
              prefixIcon: Icon(Icons.restaurant_menu_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 12),

        // Calorias + Porcion
        Row(
          children: [
            Expanded(
              child: _buildNumericField(
                key: const ValueKey('photo-analysis-calories'),
                controller: _calController,
                label: 'Calorias/100g',
                suffix: 'kcal',
                color: AppColors.nutrition,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNumericField(
                key: const ValueKey('photo-analysis-serving'),
                controller: _servingController,
                label: 'Porcion',
                suffix: 'g',
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Proteina + Carbos
        Row(
          children: [
            Expanded(
              child: _buildNumericField(
                key: const ValueKey('photo-analysis-protein'),
                controller: _proteinController,
                label: 'Proteina/100g',
                suffix: 'g',
                color: const Color(0xFF3B82F6),
                decimal: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNumericField(
                key: const ValueKey('photo-analysis-carbs'),
                controller: _carbsController,
                label: 'Carbos/100g',
                suffix: 'g',
                color: const Color(0xFF10B981),
                decimal: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Grasa (half width)
        SizedBox(
          width: double.infinity,
          child: _buildNumericField(
            key: const ValueKey('photo-analysis-fat'),
            controller: _fatController,
            label: 'Grasa/100g',
            suffix: 'g',
            color: const Color(0xFFEC4899),
            decimal: true,
          ),
        ),

        const SizedBox(height: 16),

        // Macro summary card
        _buildMacroSummary(theme),
      ],
    );
  }

  Widget _buildNumericField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String suffix,
    required Color color,
    bool decimal = false,
  }) {
    return Semantics(
      label: label,
      textField: true,
      child: TextField(
        key: key,
        controller: controller,
        keyboardType: decimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            decimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
          ),
        ],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          labelStyle: TextStyle(color: color, fontSize: 12),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: color.withAlpha(100)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: color, width: 2),
          ),
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildMacroSummary(ThemeData theme) {
    final cal = int.tryParse(_calController.text) ?? 0;
    final prot = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;
    final serving = double.tryParse(_servingController.text) ?? 100;
    final factor = serving / 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.nutrition.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.nutrition.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por porcion (${serving.toStringAsFixed(0)} g)',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.nutrition,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroSummaryItem(
                  label: 'Kcal',
                  value: (cal * factor).round().toString(),
                  color: AppColors.nutrition),
              _MacroSummaryItem(
                  label: 'Prot',
                  value: '${(prot * factor).toStringAsFixed(1)}g',
                  color: const Color(0xFF3B82F6)),
              _MacroSummaryItem(
                  label: 'Carbs',
                  value: '${(carbs * factor).toStringAsFixed(1)}g',
                  color: const Color(0xFF10B981)),
              _MacroSummaryItem(
                  label: 'Grasa',
                  value: '${(fat * factor).toStringAsFixed(1)}g',
                  color: const Color(0xFFEC4899)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Semantics(
      label: 'Guardar alimento y registrar en el diario',
      button: true,
      child: FilledButton.icon(
        key: const ValueKey('photo-analysis-save-button'),
        onPressed: _isSaving ? null : _handleSave,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.nutrition,
          minimumSize: const Size.fromHeight(52),
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save_outlined),
        label: Text(
          _isSaving ? 'Guardando...' : 'Guardar y registrar',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widget: macro summary item
// ---------------------------------------------------------------------------

class _MacroSummaryItem extends StatelessWidget {
  const _MacroSummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color.withAlpha(180),
              ),
        ),
      ],
    );
  }
}
