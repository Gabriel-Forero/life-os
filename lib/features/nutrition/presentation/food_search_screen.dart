import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_os/core/constants/app_colors.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/providers/providers.dart';
import 'package:life_os/core/router/app_router.dart';
import 'package:life_os/features/nutrition/data/open_food_facts_client.dart';

enum _SearchTab { buscar, favoritos, recientes }

// ---------------------------------------------------------------------------
// Pantalla de busqueda de alimentos
// ---------------------------------------------------------------------------

/// Pantalla de busqueda de alimentos con pestanas Buscar / Favoritos /
/// Recientes, resultados con nombre, marca y calorias por porcion.
///
/// Shell de presentacion — la integracion con Riverpod se realizara en un
/// paso posterior.
///
/// Accesibilidad: A11Y-NUT-02 — barra de busqueda y resultados tienen
/// etiquetas semanticas apropiadas.
class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({
    super.key,
    this.targetMealType,
  });

  /// Tipo de comida al cual se agregara el alimento seleccionado.
  final String? targetMealType;

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';
  List<FoodItem> _searchResults = [];

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
    final dao = ref.read(nutritionDaoProvider);
    final results = await dao.searchFoodItems(query.trim());
    if (mounted) {
      setState(() => _searchResults = results);
    }
  }

  void _handleFoodTap(FoodItem food) {
    Navigator.of(context).pop(food);
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
                : 'Buscar alimento',
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
                                  setState(() => _query = '');
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
                      _runSearch(v);
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
                      final result =
                          await context.push<FoodItemDto>(AppRoutes.barcodeScanner);
                      if (!mounted) return;
                      if (result != null) {
                        // Show the product that was scanned
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Encontrado: ${result.name} '
                              '(${result.caloriesPer100g} kcal/100g)',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
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
                // Create custom food button
                Expanded(
                  child: Semantics(
                    label: 'Crear alimento personalizado',
                    button: true,
                    child: OutlinedButton.icon(
                      key: const ValueKey('food-search-create-custom-button'),
                      onPressed: () {
                        // TODO: abrir formulario de alimento personalizado
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.nutrition,
                        side: const BorderSide(color: AppColors.nutrition),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Crear alimento'),
                    ),
                  ),
                ),
              ],
            ),
          ),

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
                ),

                // Pestana Favoritos
                StreamBuilder<List<FoodItem>>(
                  stream: ref.watch(nutritionDaoProvider).watchFavorites(),
                  builder: (context, snapshot) => _FoodResultList(
                    key: const ValueKey('food-search-favorites-list'),
                    items: snapshot.data ?? [],
                    emptyMessage: 'No tienes alimentos favoritos aun',
                    onTap: _handleFoodTap,
                    showFavoriteIcon: true,
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
    this.showFavoriteIcon = false,
  });

  final List<FoodItem> items;
  final String emptyMessage;
  final ValueChanged<FoodItem> onTap;
  final bool showFavoriteIcon;

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
              '${food.name}, $brand, ${servingCal.toStringAsFixed(0)} kcal por $servingLabel. Toca para agregar.',
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
            ),
            subtitle: Text(
              '$brand · $servingLabel',
              style: theme.textTheme.bodySmall,
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
                if (showFavoriteIcon) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.favorite,
                    color: AppColors.nutrition,
                    size: 16,
                  ),
                ],
                const SizedBox(width: 4),
                Semantics(
                  label: 'Agregar ${food.name}',
                  button: true,
                  child: IconButton(
                    key: ValueKey('food-result-add-${food.id}'),
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.nutrition,
                    onPressed: () => onTap(food),
                    tooltip: 'Agregar',
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
