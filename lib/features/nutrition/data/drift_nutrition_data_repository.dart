import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/nutrition/data/nutrition_data_repository.dart';
import 'package:life_os/features/nutrition/database/nutrition_dao.dart';
import 'package:life_os/features/nutrition/domain/models/food_item_model.dart';
import 'package:life_os/features/nutrition/domain/models/meal_log_item_model.dart';
import 'package:life_os/features/nutrition/domain/models/meal_log_model.dart';
import 'package:life_os/features/nutrition/domain/models/meal_template_model.dart';
import 'package:life_os/features/nutrition/domain/models/nutrition_goal_model.dart';
import 'package:life_os/features/nutrition/domain/models/water_log_model.dart';

class DriftNutritionDataRepository implements NutritionDataRepository {
  DriftNutritionDataRepository({required this.dao});

  final NutritionDao dao;

  // --- Mapping helpers ---

  static FoodItemModel _toFoodItemModel(FoodItem row) => FoodItemModel(
        id: row.id.toString(),
        barcode: row.barcode,
        name: row.name,
        brand: row.brand,
        caloriesPer100g: row.caloriesPer100g,
        proteinPer100g: row.proteinPer100g,
        carbsPer100g: row.carbsPer100g,
        fatPer100g: row.fatPer100g,
        servingSizeG: row.servingSizeG,
        isFavorite: row.isFavorite,
        isCustom: row.isCustom,
        isFromApi: row.isFromApi,
        createdAt: row.createdAt,
      );

  static MealLogModel _toMealLogModel(MealLog row) => MealLogModel(
        id: row.id.toString(),
        date: row.date,
        mealType: row.mealType,
        note: row.note,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  static MealLogItemModel _toMealLogItemModel(MealLogItem row) =>
      MealLogItemModel(
        id: row.id.toString(),
        mealLogId: row.mealLogId.toString(),
        foodItemId: row.foodItemId.toString(),
        quantityG: row.quantityG,
        createdAt: row.createdAt,
      );

  static MealTemplateModel _toMealTemplateModel(MealTemplate row) =>
      MealTemplateModel(
        id: row.id.toString(),
        name: row.name,
        mealType: row.mealType,
        itemsJson: row.itemsJson,
        createdAt: row.createdAt,
      );

  static NutritionGoalModel _toNutritionGoalModel(NutritionGoal row) =>
      NutritionGoalModel(
        id: row.id.toString(),
        caloriesKcal: row.caloriesKcal,
        proteinG: row.proteinG,
        carbsG: row.carbsG,
        fatG: row.fatG,
        waterMl: row.waterMl,
        effectiveDate: row.effectiveDate,
        createdAt: row.createdAt,
      );

  static WaterLogModel _toWaterLogModel(WaterLog row) => WaterLogModel(
        id: row.id.toString(),
        date: row.date,
        amountMl: row.amountMl,
        time: row.time,
        createdAt: row.createdAt,
      );

  // --- Food Items ---

  @override
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
  }) async {
    final id = await dao.insertFoodItem(FoodItemsCompanion(
      name: Value(name),
      barcode: Value(barcode),
      brand: Value(brand),
      caloriesPer100g: Value(caloriesPer100g),
      proteinPer100g: Value(proteinPer100g),
      carbsPer100g: Value(carbsPer100g),
      fatPer100g: Value(fatPer100g),
      servingSizeG: Value(servingSizeG),
      isFavorite: Value(isFavorite),
      isCustom: Value(isCustom),
      isFromApi: Value(isFromApi),
      createdAt: Value(createdAt),
    ));
    return id.toString();
  }

  @override
  Future<void> updateFoodItem(FoodItemModel item) async {
    final intId = int.tryParse(item.id);
    if (intId == null) return;
    final row = FoodItem(
      id: intId,
      barcode: item.barcode,
      name: item.name,
      brand: item.brand,
      caloriesPer100g: item.caloriesPer100g,
      proteinPer100g: item.proteinPer100g,
      carbsPer100g: item.carbsPer100g,
      fatPer100g: item.fatPer100g,
      servingSizeG: item.servingSizeG,
      isFavorite: item.isFavorite,
      isCustom: item.isCustom,
      isFromApi: item.isFromApi,
      createdAt: item.createdAt,
    );
    await dao.updateFoodItem(row);
  }

  @override
  Future<FoodItemModel?> getFoodItemByBarcode(String barcode) async {
    final row = await dao.getFoodItemByBarcode(barcode);
    return row != null ? _toFoodItemModel(row) : null;
  }

  @override
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.toggleFavorite(intId, isFavorite);
  }

  @override
  Stream<List<FoodItemModel>> watchFavorites() {
    return dao.watchFavorites().map(
          (rows) => rows.map(_toFoodItemModel).toList(),
        );
  }

  @override
  Stream<List<FoodItemModel>> watchRecentFoodItems({int count = 20}) {
    return dao.watchRecentFoodItems(count: count).map(
          (rows) => rows.map(_toFoodItemModel).toList(),
        );
  }

  @override
  Future<FoodItemModel?> getFoodItemById(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return null;
    final row = await dao.getFoodItemById(intId);
    return row != null ? _toFoodItemModel(row) : null;
  }

  @override
  Future<List<FoodItemModel>> searchFoodItems(String query) async {
    final rows = await dao.searchFoodItems(query);
    return rows.map(_toFoodItemModel).toList();
  }

  @override
  Future<void> bulkInsertFoodItems(List<FoodItemModel> items) async {
    final companions = items
        .map((item) => FoodItemsCompanion(
              name: Value(item.name),
              barcode: Value(item.barcode),
              brand: Value(item.brand),
              caloriesPer100g: Value(item.caloriesPer100g),
              proteinPer100g: Value(item.proteinPer100g),
              carbsPer100g: Value(item.carbsPer100g),
              fatPer100g: Value(item.fatPer100g),
              servingSizeG: Value(item.servingSizeG),
              isFavorite: Value(item.isFavorite),
              isCustom: Value(item.isCustom),
              isFromApi: Value(item.isFromApi),
              createdAt: Value(item.createdAt),
            ))
        .toList();
    await dao.bulkInsertFoodItems(companions);
  }

  @override
  Future<int> countFoodItems() => dao.countFoodItems();

  // --- Meal Logs ---

  @override
  Future<String> insertMealLog({
    required DateTime date,
    required String mealType,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final id = await dao.insertMealLog(MealLogsCompanion.insert(
      date: date,
      mealType: mealType,
      note: Value(note),
      createdAt: createdAt,
      updatedAt: updatedAt,
    ));
    return id.toString();
  }

  @override
  Future<void> deleteMealLog(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.deleteMealLog(intId);
  }

  @override
  Stream<List<MealLogModel>> watchMealLogs(DateTime date) {
    return dao.watchMealLogs(date).map(
          (rows) => rows.map(_toMealLogModel).toList(),
        );
  }

  // --- Meal Log Items ---

  @override
  Future<String> insertMealLogItem({
    required String mealLogId,
    required String foodItemId,
    required double quantityG,
    required DateTime createdAt,
  }) async {
    final id = await dao.insertMealLogItem(MealLogItemsCompanion.insert(
      mealLogId: int.parse(mealLogId),
      foodItemId: int.parse(foodItemId),
      quantityG: quantityG,
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Future<void> setMealLogItems(
    String mealLogId,
    List<MealLogItemModel> items,
  ) async {
    final intMealLogId = int.parse(mealLogId);
    final companions = items
        .map((item) => MealLogItemsCompanion.insert(
              mealLogId: intMealLogId,
              foodItemId: int.parse(item.foodItemId),
              quantityG: item.quantityG,
              createdAt: item.createdAt,
            ))
        .toList();
    await dao.setMealLogItems(intMealLogId, companions);
  }

  @override
  Stream<List<MealLogItemModel>> watchMealLogItems(String mealLogId) {
    final intId = int.tryParse(mealLogId);
    if (intId == null) return Stream.value([]);
    return dao.watchMealLogItems(intId).map(
          (rows) => rows.map(_toMealLogItemModel).toList(),
        );
  }

  // --- Meal Templates ---

  @override
  Future<String> insertMealTemplate({
    required String name,
    required String mealType,
    required String itemsJson,
    required DateTime createdAt,
  }) async {
    final id = await dao.insertMealTemplate(MealTemplatesCompanion.insert(
      name: name,
      mealType: mealType,
      itemsJson: itemsJson,
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Future<void> deleteMealTemplate(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.deleteMealTemplate(intId);
  }

  @override
  Stream<List<MealTemplateModel>> watchMealTemplates() {
    return dao.watchMealTemplates().map(
          (rows) => rows.map(_toMealTemplateModel).toList(),
        );
  }

  // --- Nutrition Goals ---

  @override
  Future<String> insertNutritionGoal({
    required int caloriesKcal,
    double proteinG = 0.0,
    double carbsG = 0.0,
    double fatG = 0.0,
    int waterMl = 2000,
    required DateTime effectiveDate,
    required DateTime createdAt,
  }) async {
    final id = await dao.insertNutritionGoal(NutritionGoalsCompanion.insert(
      caloriesKcal: caloriesKcal,
      proteinG: Value(proteinG),
      carbsG: Value(carbsG),
      fatG: Value(fatG),
      waterMl: Value(waterMl),
      effectiveDate: effectiveDate,
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Future<NutritionGoalModel?> getActiveGoal(DateTime date) async {
    final row = await dao.getActiveGoal(date);
    return row != null ? _toNutritionGoalModel(row) : null;
  }

  @override
  Stream<NutritionGoalModel?> watchActiveGoal() {
    return dao.watchActiveGoal().map(
          (row) => row != null ? _toNutritionGoalModel(row) : null,
        );
  }

  // --- Water Logs ---

  @override
  Future<String> insertWaterLog({
    required DateTime date,
    required int amountMl,
    required DateTime time,
    required DateTime createdAt,
  }) async {
    final id = await dao.insertWaterLog(WaterLogsCompanion.insert(
      date: date,
      amountMl: amountMl,
      time: time,
      createdAt: createdAt,
    ));
    return id.toString();
  }

  @override
  Future<void> deleteWaterLog(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) return;
    await dao.deleteWaterLog(intId);
  }

  @override
  Stream<List<WaterLogModel>> watchWaterLogs(DateTime date) {
    return dao.watchWaterLogs(date).map(
          (rows) => rows.map(_toWaterLogModel).toList(),
        );
  }

  @override
  Future<int> totalWater(DateTime date) => dao.totalWater(date);
}
