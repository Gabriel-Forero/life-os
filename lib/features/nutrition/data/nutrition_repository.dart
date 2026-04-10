import 'package:life_os/features/nutrition/data/nutrition_data_repository.dart';
import 'package:life_os/features/nutrition/data/open_food_facts_client.dart';
import 'package:life_os/features/nutrition/domain/models/food_item_model.dart';

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
    required this.dataRepository,
    required this.apiClient,
  });

  final NutritionDataRepository dataRepository;
  final OpenFoodFactsClient apiClient;

  Future<List<FoodItemModel>> searchFood(String query) async {
    try {
      final apiResults = await apiClient.searchByName(query);

      for (final dto in apiResults) {
        await dataRepository.insertFoodItem(
          name: dto.name,
          barcode: dto.barcode,
          brand: dto.brand,
          caloriesPer100g: dto.caloriesPer100g,
          proteinPer100g: dto.proteinPer100g,
          carbsPer100g: dto.carbsPer100g,
          fatPer100g: dto.fatPer100g,
          servingSizeG: dto.servingSizeG,
          isFromApi: true,
          createdAt: DateTime.now(),
        );
      }
    } catch (_) {
      // Offline — swallow and fall through to local-only results
    }

    return dataRepository.searchFoodItems(query);
  }
}
