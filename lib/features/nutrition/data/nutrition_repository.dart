import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/nutrition/database/nutrition_dao.dart';
import 'package:life_os/features/nutrition/data/open_food_facts_client.dart';

/// Repository that merges local DB results with Open Food Facts API results.
///
/// Search strategy:
/// 1. Query local DB immediately.
/// 2. Call the API concurrently.
/// 3. Cache API results to local DB (InsertOrIgnore, keyed on barcode uniqueness).
/// 4. Re-query local DB and return the unified list.
///
/// On network failure, only local results are returned (offline-first).
class NutritionRepository {
  const NutritionRepository({
    required this.dao,
    required this.apiClient,
  });

  final NutritionDao dao;
  final OpenFoodFactsClient apiClient;

  Future<List<FoodItem>> searchFood(String query) async {
    try {
      final apiResults = await apiClient.searchByName(query);

      for (final dto in apiResults) {
        await dao.insertFoodItem(
          FoodItemsCompanion(
            name: Value(dto.name),
            barcode: Value(dto.barcode),
            brand: Value(dto.brand),
            caloriesPer100g: Value(dto.caloriesPer100g),
            proteinPer100g: Value(dto.proteinPer100g),
            carbsPer100g: Value(dto.carbsPer100g),
            fatPer100g: Value(dto.fatPer100g),
            servingSizeG: Value(dto.servingSizeG),
            isFromApi: const Value(true),
            createdAt: Value(DateTime.now()),
          ),
        );
      }
    } catch (_) {
      // Offline — swallow and fall through to local-only results
    }

    return dao.searchFoodItems(query);
  }
}
