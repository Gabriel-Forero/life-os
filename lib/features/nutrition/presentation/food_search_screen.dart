import 'package:flutter/material.dart';
import 'package:life_os/core/constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Modelos mock
// ---------------------------------------------------------------------------

class _MockFoodResult {
  const _MockFoodResult({
    required this.id,
    required this.name,
    required this.brand,
    required this.caloriesPer100g,
    required this.servingLabel,
    required this.servingCalories,
    this.isFavorite = false,
  });

  final int id;
  final String name;
  final String brand;
  final double caloriesPer100g;
  final String servingLabel;
  final double servingCalories;
  final bool isFavorite;
}

const _mockSearchResults = [
  _MockFoodResult(
    id: 1,
    name: 'Avena en hojuelas',
    brand: 'Quaker',
    caloriesPer100g: 389,
    servingLabel: '40 g',
    servingCalories: 156,
  ),
  _MockFoodResult(
    id: 2,
    name: 'Pechuga de pollo',
    brand: 'Generico',
    caloriesPer100g: 165,
    servingLabel: '100 g',
    servingCalories: 165,
  ),
  _MockFoodResult(
    id: 3,
    name: 'Arroz blanco cocido',
    brand: 'Generico',
    caloriesPer100g: 130,
    servingLabel: '180 g',
    servingCalories: 234,
  ),
  _MockFoodResult(
    id: 4,
    name: 'Leche entera',
    brand: 'Alpina',
    caloriesPer100g: 61,
    servingLabel: '200 ml',
    servingCalories: 122,
  ),
  _MockFoodResult(
    id: 5,
    name: 'Platano maduro',
    brand: 'Generico',
    caloriesPer100g: 89,
    servingLabel: '120 g',
    servingCalories: 107,
  ),
];

const _mockFavorites = [
  _MockFoodResult(
    id: 2,
    name: 'Pechuga de pollo',
    brand: 'Generico',
    caloriesPer100g: 165,
    servingLabel: '100 g',
    servingCalories: 165,
    isFavorite: true,
  ),
  _MockFoodResult(
    id: 6,
    name: 'Yogur griego natural',
    brand: 'Alpina',
    caloriesPer100g: 59,
    servingLabel: '170 g',
    servingCalories: 100,
    isFavorite: true,
  ),
  _MockFoodResult(
    id: 7,
    name: 'Salmon atlantico',
    brand: 'Generico',
    caloriesPer100g: 208,
    servingLabel: '180 g',
    servingCalories: 374,
    isFavorite: true,
  ),
];

const _mockRecents = [
  _MockFoodResult(
    id: 1,
    name: 'Avena en hojuelas',
    brand: 'Quaker',
    caloriesPer100g: 389,
    servingLabel: '40 g',
    servingCalories: 156,
  ),
  _MockFoodResult(
    id: 8,
    name: 'Brocoli',
    brand: 'Generico',
    caloriesPer100g: 34,
    servingLabel: '150 g',
    servingCalories: 51,
  ),
  _MockFoodResult(
    id: 9,
    name: 'Huevo entero cocido',
    brand: 'Generico',
    caloriesPer100g: 155,
    servingLabel: '50 g',
    servingCalories: 78,
  ),
  _MockFoodResult(
    id: 5,
    name: 'Platano maduro',
    brand: 'Generico',
    caloriesPer100g: 89,
    servingLabel: '120 g',
    servingCalories: 107,
  ),
];

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
class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({
    super.key,
    this.targetMealType,
  });

  /// Tipo de comida al cual se agregara el alimento seleccionado.
  final String? targetMealType;

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = SearchController();
  String _query = '';

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

  List<_MockFoodResult> get _filteredResults {
    if (_query.trim().isEmpty) return _mockSearchResults;
    final q = _query.toLowerCase();
    return _mockSearchResults
        .where(
          (f) =>
              f.name.toLowerCase().contains(q) ||
              f.brand.toLowerCase().contains(q),
        )
        .toList();
  }

  void _handleFoodTap(_MockFoodResult food) {
    // TODO: agregar alimento a la comida seleccionada cuando se conecte
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
                    onChanged: (v) => setState(() => _query = v),
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
          // Boton para crear alimento personalizado
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Semantics(
              label: 'Crear alimento personalizado',
              button: true,
              child: OutlinedButton.icon(
                key: const ValueKey('food-search-create-custom-button'),
                onPressed: () {
                  // TODO: abrir formulario de alimento personalizado cuando se conecte
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.nutrition,
                  side: const BorderSide(color: AppColors.nutrition),
                  minimumSize: const Size.fromHeight(40),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Crear alimento personalizado'),
              ),
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
                  items: _filteredResults,
                  emptyMessage: _query.isNotEmpty
                      ? 'Sin resultados para "$_query"'
                      : 'Escribe para buscar alimentos',
                  onTap: _handleFoodTap,
                ),

                // Pestana Favoritos
                _FoodResultList(
                  key: const ValueKey('food-search-favorites-list'),
                  items: _mockFavorites,
                  emptyMessage: 'No tienes alimentos favoritos aun',
                  onTap: _handleFoodTap,
                  showFavoriteIcon: true,
                ),

                // Pestana Recientes
                _FoodResultList(
                  key: const ValueKey('food-search-recents-list'),
                  items: _mockRecents,
                  emptyMessage: 'No hay alimentos recientes',
                  onTap: _handleFoodTap,
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

  final List<_MockFoodResult> items;
  final String emptyMessage;
  final ValueChanged<_MockFoodResult> onTap;
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
        return Semantics(
          label:
              '${food.name}, ${food.brand}, ${food.servingCalories.toStringAsFixed(0)} kcal por ${food.servingLabel}. Toca para agregar.',
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
              '${food.brand} · ${food.servingLabel}',
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
                      '${food.servingCalories.toStringAsFixed(0)} kcal',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.nutrition,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'por ${food.servingLabel}',
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
