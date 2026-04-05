import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/features/nutrition/data/open_food_facts_client.dart';
import 'package:life_os/features/nutrition/domain/nutrition_input.dart';

String _suggestMealType() {
  final hour = DateTime.now().hour;
  if (hour < 10) return 'breakfast';
  if (hour < 14) return 'lunch';
  if (hour < 19) return 'dinner';
  return 'snack';
}

// ---------------------------------------------------------------------------
// Pantalla de busqueda de alimentos (Registro rapido: 2 taps)
// ---------------------------------------------------------------------------

/// Pantalla de busqueda de alimentos con pestanas Buscar / Favoritos / Recientes.
///
/// Flujo de 2 taps:
/// 1. Tap FAB en DailyNutritionScreen -> abre esta pantalla
/// 2. Tap en cualquier alimento -> lo registra inmediatamente con el tipo de
///    comida sugerido por la hora y la porcion por defecto del alimento.
///
/// Retorno:
/// - Si returnFood=true (desde MealLogScreen), hace pop<FoodItem>.
/// - Si returnFood=false (desde DailyNutritionScreen), registra directo.
///
/// Accesibilidad: A11Y-NUT-02
class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({
    super.key,
    this.targetMealType,
    this.returnFood = false,
  });

  /// Tipo de comida al cual se agregara el alimento seleccionado.
  final String? targetMealType;

  /// Si es true, hace pop<FoodItem> en lugar de registrar directamente.
  /// Usado por MealLogScreen.
  final bool returnFood;

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';
  List<FoodItem> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final results = await repo.searchFood(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      final dao = ref.read(nutritionDaoProvider);
      final results = await dao.searchFoodItems(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    }
  }

  /// Handle food tap: either return to caller or quick-log immediately.
  Future<void> _handleFoodTap(FoodItem food) async {
    if (widget.returnFood) {
      Navigator.of(context).pop(food);
      return;
    }

    // Quick-log: 2-tap flow
    final mealType = widget.targetMealType ?? _suggestMealType();
    final notifier = ref.read(nutritionNotifierProvider);

    final result = await notifier.logMeal(
      MealLogInput(
        mealType: mealType,
        items: [
          MealItemInput(
            foodItemId: food.id,
            quantityG: food.servingSizeG,
          ),
        ],
      ),
    );

    if (!mounted) return;

    result.when(
      success: (mealId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrado! ${food.name}'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Guardar plantilla',
              onPressed: () => _showSaveTemplateDialog(
                mealType: mealType,
                foodItemId: food.id,
                quantityG: food.servingSizeG,
                foodName: food.name,
              ),
            ),
          ),
        );
        Navigator.of(context).pop();
      },
      failure: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(f.userMessage),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Future<void> _showSaveTemplateDialog({
    required String mealType,
    required int foodItemId,
    required double quantityG,
    required String foodName,
  }) async {
    final controller = TextEditingController(text: foodName);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar como plantilla'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre de la plantilla',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.nutrition,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    // Capture text before disposing
    final templateName =
        controller.text.trim().isNotEmpty ? controller.text.trim() : foodName;
    controller.dispose();

    if (saved == true && mounted) {
      final itemsJson = jsonEncode([
        {'foodItemId': foodItemId, 'quantityG': quantityG}
      ]);
      final notifier = ref.read(nutritionNotifierProvider);
      await notifier.saveAsTemplate(
        name: templateName,
        mealType: mealType,
        itemsJson: itemsJson,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plantilla guardada!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleFavorite(FoodItem food) async {
    await ref
        .read(nutritionNotifierProvider)
        .toggleFavorite(food.id, !food.isFavorite);
  }

  Future<void> _handleBarcodeResult(FoodItemDto result) async {
    final dao = ref.read(nutritionDaoProvider);

    // Check if already in DB by barcode
    FoodItem? existing;
    if (result.barcode != null) {
      existing = await dao.getFoodItemByBarcode(result.barcode!);
    }

    if (existing == null) {
      // Insert into DB
      final id = await dao.insertFoodItem(
        FoodItemsCompanion(
          name: drift.Value(result.name),
          barcode: drift.Value(result.barcode),
          brand: drift.Value(result.brand),
          caloriesPer100g: drift.Value(result.caloriesPer100g),
          proteinPer100g: drift.Value(result.proteinPer100g),
          carbsPer100g: drift.Value(result.carbsPer100g),
          fatPer100g: drift.Value(result.fatPer100g),
          servingSizeG: drift.Value(result.servingSizeG),
          isFromApi: const drift.Value(true),
          createdAt: drift.Value(DateTime.now()),
        ),
      );
      // Find in DB by ID
      final items = await dao.searchFoodItems(result.name);
      existing = items.where((f) => f.id == id).firstOrNull ??
          items.firstOrNull;
    }

    if (!mounted) return;

    if (existing != null) {
      await _handleFoodTap(existing);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Encontrado: ${result.name} (${result.caloriesPer100g} kcal/100g)',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('food-search-screen'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          header: true,
          child: Text(
            widget.targetMealType != null
                ? 'Agregar a ${widget.targetMealType}'
                : 'Registro rapido',
          ),
        ),
        leading: Semantics(
          label: 'Volver',
          button: true,
          child: IconButton(
            key: const ValueKey('food-search-back-button'),
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              // SearchBar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Semantics(
                  label: 'Buscar alimentos por nombre o marca',
                  textField: true,
                  child: TextField(
                    key: const ValueKey('food-search-bar'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Nombre del alimento o marca...',
                      prefixIcon: const Icon(Icons.search_outlined),
                      suffixIcon: _query.isNotEmpty
                          ? Semantics(
                              label: 'Limpiar busqueda',
                              button: true,
                              child: IconButton(
                                key: const ValueKey('food-search-clear-button'),
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _query = '';
                                    _searchResults = [];
                                  });
                                },
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.nutrition,
                          width: 2,
                        ),
                      ),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      setState(() => _query = v);
                      if (_tabController.index == 0) {
                        _runSearch(v);
                      }
                    },
                  ),
                ),
              ),

              // Pestanas
              TabBar(
                controller: _tabController,
                labelColor: AppColors.nutrition,
                unselectedLabelColor: theme.textTheme.bodySmall?.color,
                indicatorColor: AppColors.nutrition,
                tabs: const [
                  Tab(text: 'Buscar'),
                  Tab(text: 'Favoritos'),
                  Tab(text: 'Recientes'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Action buttons row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                // Barcode scanner button
                Semantics(
                  label: 'Escanear codigo de barras',
                  button: true,
                  child: OutlinedButton.icon(
                    key: const ValueKey('food-search-scan-button'),
                    onPressed: () async {
                      final result = await context.push<FoodItemDto>(
                        AppRoutes.barcodeScanner,
                      );
                      if (!mounted || result == null) return;
                      await _handleBarcodeResult(result);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.nutrition,
                      side: const BorderSide(color: AppColors.nutrition),
                    ),
                    icon: const Icon(Icons.qr_code_scanner_outlined, size: 18),
                    label: const Text('Escanear'),
                  ),
                ),
                const SizedBox(width: 8),
                // AI Photo analysis
                Expanded(
                  child: Semantics(
                    label: 'Analizar comida con foto AI',
                    button: true,
                    child: OutlinedButton.icon(
                      key: const ValueKey('food-search-photo-button'),
                      onPressed: () =>
                          GoRouter.of(context).push(AppRoutes.photoAnalysis),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.nutrition,
                        side: const BorderSide(color: AppColors.nutrition),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Analizar foto'),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator for search
          if (_isSearching)
            const LinearProgressIndicator(color: AppColors.nutrition),

          // Contenido por pestana
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pestana Buscar
                _FoodResultList(
                  key: const ValueKey('food-search-results-list'),
                  items: _searchResults,
                  emptyMessage: _query.isNotEmpty
                      ? 'Sin resultados para "$_query"'
                      : 'Escribe para buscar alimentos',
                  onTap: _handleFoodTap,
                  onToggleFavorite: _toggleFavorite,
                ),

                // Pestana Favoritos
                StreamBuilder<List<FoodItem>>(
                  stream: ref.watch(nutritionDaoProvider).watchFavorites(),
                  builder: (context, snapshot) => _FoodResultList(
                    key: const ValueKey('food-search-favorites-list'),
                    items: snapshot.data ?? [],
                    emptyMessage: 'No tienes alimentos favoritos aun',
                    onTap: _handleFoodTap,
                    onToggleFavorite: _toggleFavorite,
                  ),
                ),

                // Pestana Recientes
                StreamBuilder<List<FoodItem>>(
                  stream: ref
                      .watch(nutritionDaoProvider)
                      .watchRecentFoodItems(count: 20),
                  builder: (context, snapshot) => _FoodResultList(
                    key: const ValueKey('food-search-recents-list'),
                    items: snapshot.data ?? [],
                    emptyMessage: 'No hay alimentos recientes',
                    onTap: _handleFoodTap,
                    onToggleFavorite: _toggleFavorite,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: lista de resultados de alimentos
// ---------------------------------------------------------------------------

class _FoodResultList extends StatelessWidget {
  const _FoodResultList({
    super.key,
    required this.items,
    required this.emptyMessage,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final List<FoodItem> items;
  final String emptyMessage;
  final ValueChanged<FoodItem> onTap;
  final ValueChanged<FoodItem> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_outlined,
                size: 56,
                color: theme.disabledColor,
              ),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        final food = items[index];
        final servingCal =
            food.caloriesPer100g * food.servingSizeG / 100;
        final brand = food.brand ?? 'Generico';
        final servingLabel = '${food.servingSizeG.toStringAsFixed(0)} g';
        return Semantics(
          label:
              '${food.name}, $brand, ${servingCal.toStringAsFixed(0)} kcal por $servingLabel. Toca para registrar.',
          button: true,
          child: ListTile(
            key: ValueKey('food-result-item-${food.id}'),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.nutrition.withAlpha(20),
              child: const Icon(
                Icons.lunch_dining_outlined,
                color: AppColors.nutrition,
                size: 20,
              ),
            ),
            title: Text(
              food.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Text(
              '$brand · $servingLabel',
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${servingCal.toStringAsFixed(0)} kcal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.nutrition,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'por $servingLabel',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                // Heart / favorite icon
                Semantics(
                  label: food.isFavorite
                      ? 'Quitar de favoritos'
                      : 'Agregar a favoritos',
                  button: true,
                  child: IconButton(
                    key: ValueKey('food-favorite-${food.id}'),
                    icon: Icon(
                      food.isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                    ),
                    color: food.isFavorite
                        ? AppColors.nutrition
                        : Colors.grey,
                    onPressed: () => onToggleFavorite(food),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Semantics(
                  label: 'Registrar ${food.name}',
                  button: true,
                  child: IconButton(
                    key: ValueKey('food-result-add-${food.id}'),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.nutrition,
                    onPressed: () => onTap(food),
                    tooltip: 'Registrar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ],
            ),
            onTap: () => onTap(food),
          ),
        );
      },
    );
  }
}
