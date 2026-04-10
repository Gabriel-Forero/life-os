import 'package:life_os/features/nutrition/domain/models/food_item_model.dart';
import 'package:life_os/features/nutrition/domain/models/meal_log_item_model.dart';
import 'package:life_os/features/nutrition/domain/models/meal_log_model.dart';
import 'package:life_os/features/nutrition/domain/models/meal_template_model.dart';
import 'package:life_os/features/nutrition/domain/models/nutrition_goal_model.dart';
import 'package:life_os/features/nutrition/domain/models/water_log_model.dart';

/// Abstract data repository for the Nutrition module.
///
/// Named [NutritionDataRepository] to avoid conflict with the existing
/// [NutritionRepository] which combines local DB + OpenFoodFacts API.
abstract class NutritionDataRepository {
  // --- Food Items ---

  Future<String> insertFoodItem({
    required String name,
    String? barcode,
    String? brand,
    required int caloriesPer100g,
    double proteinPer100g = 0.0,
    double carbsPer100g = 0.0,
    double fatPer100g = 0.0,
    double servingSizeG = 100.0,
    bool isFavorite = false,
    bool isCustom = false,
    bool isFromApi = false,
    required DateTime createdAt,
  });

  Future<void> updateFoodItem(FoodItemModel item);

  Future<FoodItemModel?> getFoodItemByBarcode(String barcode);

  Future<void> toggleFavorite(String id, bool isFavorite);

  Stream<List<FoodItemModel>> watchFavorites();

  Stream<List<FoodItemModel>> watchRecentFoodItems({int count = 20});

  Future<FoodItemModel?> getFoodItemById(String id);

  Future<List<FoodItemModel>> searchFoodItems(String query);

  Future<void> bulkInsertFoodItems(List<FoodItemModel> items);

  Future<int> countFoodItems();

  // --- Meal Logs ---

  Future<String> insertMealLog({
    required DateTime date,
    required String mealType,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
  });

  Future<void> deleteMealLog(String id);

  Stream<List<MealLogModel>> watchMealLogs(DateTime date);

  // --- Meal Log Items ---

  Future<String> insertMealLogItem({
    required String mealLogId,
    required String foodItemId,
    required double quantityG,
    required DateTime createdAt,
  });

  Future<void> setMealLogItems(
    String mealLogId,
    List<MealLogItemModel> items,
  );

  Stream<List<MealLogItemModel>> watchMealLogItems(String mealLogId);

  // --- Meal Templates ---

  Future<String> insertMealTemplate({
    required String name,
    required String mealType,
    required String itemsJson,
    required DateTime createdAt,
  });

  Future<void> deleteMealTemplate(String id);

  Stream<List<MealTemplateModel>> watchMealTemplates();

  // --- Nutrition Goals ---

  Future<String> insertNutritionGoal({
    required int caloriesKcal,
    double proteinG = 0.0,
    double carbsG = 0.0,
    double fatG = 0.0,
    int waterMl = 2000,
    required DateTime effectiveDate,
    required DateTime createdAt,
  });

  Future<NutritionGoalModel?> getActiveGoal(DateTime date);

  Stream<NutritionGoalModel?> watchActiveGoal();

  // --- Water Logs ---

  Future<String> insertWaterLog({
    required DateTime date,
    required int amountMl,
    required DateTime time,
    required DateTime createdAt,
  });

  Future<void> deleteWaterLog(String id);

  Stream<List<WaterLogModel>> watchWaterLogs(DateTime date);

  Future<int> totalWater(DateTime date);
}
