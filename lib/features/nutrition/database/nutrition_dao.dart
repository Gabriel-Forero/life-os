import 'package:drift/drift.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/nutrition/database/nutrition_tables.dart';

part 'nutrition_dao.g.dart';

@DriftAccessor(tables: [
  FoodItems,
  MealLogs,
  MealLogItems,
  MealTemplates,
  NutritionGoals,
  WaterLogs,
])
class NutritionDao extends DatabaseAccessor<AppDatabase>
    with _$NutritionDaoMixin {
  NutritionDao(super.db);

  // --- Food Items ---

  Future<int> insertFoodItem(FoodItemsCompanion entry) =>
      into(foodItems).insert(entry);

  Future<void> updateFoodItem(FoodItem entry) =>
      (update(foodItems)..where((f) => f.id.equals(entry.id))).write(
        FoodItemsCompanion(
          name: Value(entry.name),
          caloriesPer100g: Value(entry.caloriesPer100g),
          proteinPer100g: Value(entry.proteinPer100g),
          carbsPer100g: Value(entry.carbsPer100g),
          fatPer100g: Value(entry.fatPer100g),
          servingSizeG: Value(entry.servingSizeG),
        ),
      );

  Future<FoodItem?> getFoodItemByBarcode(String barcode) =>
      (select(foodItems)..where((f) => f.barcode.equals(barcode)))
          .getSingleOrNull();

  Future<void> toggleFavorite(int id, bool isFavorite) =>
      (update(foodItems)..where((f) => f.id.equals(id)))
          .write(FoodItemsCompanion(isFavorite: Value(isFavorite)));

  Stream<List<FoodItem>> watchFavorites() =>
      (select(foodItems)
            ..where((f) => f.isFavorite.equals(true))
            ..orderBy([(f) => OrderingTerm.asc(f.name)]))
          .watch();

  Stream<List<FoodItem>> watchRecentFoodItems({int count = 20}) {
    final q = select(foodItems)
      ..orderBy([(f) => OrderingTerm.desc(f.createdAt)])
      ..limit(count);
    return q.watch();
  }

  Future<FoodItem?> getFoodItemById(int id) =>
      (select(foodItems)..where((f) => f.id.equals(id))).getSingleOrNull();

  Future<List<FoodItem>> searchFoodItems(String query) =>
      (select(foodItems)
            ..where((f) => f.name.like('%$query%'))
            ..orderBy([(f) => OrderingTerm.asc(f.name)]))
          .get();

  Future<void> bulkInsertFoodItems(List<FoodItemsCompanion> entries) =>
      batch((b) => b.insertAll(foodItems, entries,
          mode: InsertMode.insertOrIgnore));

  Future<int> countFoodItems() async {
    final query = selectOnly(foodItems)..addColumns([foodItems.id.count()]);
    final result = await query.getSingle();
    return result.read(foodItems.id.count()) ?? 0;
  }

  // --- Meal Logs ---

  Future<int> insertMealLog(MealLogsCompanion entry) =>
      into(mealLogs).insert(entry);

  Future<void> deleteMealLog(int id) async {
    await (delete(mealLogItems)..where((i) => i.mealLogId.equals(id))).go();
    await (delete(mealLogs)..where((m) => m.id.equals(id))).go();
  }

  Stream<List<MealLog>> watchMealLogs(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(mealLogs)
          ..where(
            (m) =>
                m.date.isBiggerOrEqualValue(start) &
                m.date.isSmallerThanValue(end),
          )
          ..orderBy([(m) => OrderingTerm.asc(m.mealType)]))
        .watch();
  }

  // --- Meal Log Items ---

  Future<int> insertMealLogItem(MealLogItemsCompanion entry) =>
      into(mealLogItems).insert(entry);

  Future<void> setMealLogItems(
    int mealLogId,
    List<MealLogItemsCompanion> items,
  ) async {
    await (delete(mealLogItems)
          ..where((i) => i.mealLogId.equals(mealLogId)))
        .go();
    await batch((b) => b.insertAll(mealLogItems, items));
  }

  Stream<List<MealLogItem>> watchMealLogItems(int mealLogId) =>
      (select(mealLogItems)
            ..where((i) => i.mealLogId.equals(mealLogId)))
          .watch();

  // --- Meal Templates ---

  Future<int> insertMealTemplate(MealTemplatesCompanion entry) =>
      into(mealTemplates).insert(entry);

  Future<void> deleteMealTemplate(int id) =>
      (delete(mealTemplates)..where((t) => t.id.equals(id))).go();

  Stream<List<MealTemplate>> watchMealTemplates() =>
      (select(mealTemplates)
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .watch();

  // --- Nutrition Goals ---

  Future<int> insertNutritionGoal(NutritionGoalsCompanion entry) =>
      into(nutritionGoals).insert(entry);

  Future<NutritionGoal?> getActiveGoal(DateTime date) =>
      (select(nutritionGoals)
            ..where((g) => g.effectiveDate.isSmallerOrEqualValue(date))
            ..orderBy([(g) => OrderingTerm.desc(g.effectiveDate)])
            ..limit(1))
          .getSingleOrNull();

  Stream<NutritionGoal?> watchActiveGoal() =>
      (select(nutritionGoals)
            ..orderBy([(g) => OrderingTerm.desc(g.effectiveDate)])
            ..limit(1))
          .watchSingleOrNull();

  // --- Water Logs ---

  Future<int> insertWaterLog(WaterLogsCompanion entry) =>
      into(waterLogs).insert(entry);

  Future<void> deleteWaterLog(int id) =>
      (delete(waterLogs)..where((w) => w.id.equals(id))).go();

  Stream<List<WaterLog>> watchWaterLogs(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(waterLogs)
          ..where(
            (w) =>
                w.date.isBiggerOrEqualValue(start) &
                w.date.isSmallerThanValue(end),
          )
          ..orderBy([(w) => OrderingTerm.desc(w.time)]))
        .watch();
  }

  Future<int> totalWater(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final query = selectOnly(waterLogs)
      ..addColumns([waterLogs.amountMl.sum()])
      ..where(
        waterLogs.date.isBiggerOrEqualValue(start) &
            waterLogs.date.isSmallerThanValue(end),
      );
    final result = await query.getSingle();
    return result.read(waterLogs.amountMl.sum()) ?? 0;
  }
}
