import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/nutrition/database/nutrition_dao.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late NutritionDao dao;

  setUp(() async {
    db = _createInMemoryDb();
    dao = db.nutritionDao;
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> _insertFoodItem({String name = 'Pechuga de pollo'}) async {
    return dao.insertFoodItem(FoodItemsCompanion.insert(
      name: name,
      caloriesPer100g: 165,
      proteinPer100g: const Value(31.0),
      carbsPer100g: const Value(0.0),
      fatPer100g: const Value(3.6),
      servingSizeG: const Value(200.0),
      isFavorite: const Value(false),
      isCustom: const Value(false),
      isFromApi: const Value(false),
      createdAt: DateTime.now(),
    ));
  }

  group('NutritionDao — Food Items', () {
    test('insertFoodItem returns id', () async {
      final id = await _insertFoodItem();
      expect(id, greaterThan(0));
    });

    test('getFoodItemByBarcode returns cached item', () async {
      await dao.insertFoodItem(FoodItemsCompanion.insert(
        name: 'Yogur Alpina',
        barcode: const Value('7702001148'),
        caloriesPer100g: 95,
        proteinPer100g: const Value(3.5),
        carbsPer100g: const Value(15.0),
        fatPer100g: const Value(2.5),
        isFromApi: const Value(true),
        isCustom: const Value(false),
        isFavorite: const Value(false),
        createdAt: DateTime.now(),
      ));

      final item = await dao.getFoodItemByBarcode('7702001148');
      expect(item, isNotNull);
      expect(item!.name, 'Yogur Alpina');
    });

    test('watchFavorites returns only favorites', () async {
      await _insertFoodItem(name: 'Item1');
      final id2 = await _insertFoodItem(name: 'Item2');
      await dao.toggleFavorite(id2, true);

      final favs = await dao.watchFavorites().first;
      expect(favs, hasLength(1));
      expect(favs.first.name, 'Item2');
    });

    test('searchFoodItems finds by name', () async {
      await _insertFoodItem(name: 'Arroz blanco');
      await _insertFoodItem(name: 'Arroz integral');
      await _insertFoodItem(name: 'Pechuga de pollo');

      final results = await dao.searchFoodItems('arroz');
      expect(results, hasLength(2));
    });
  });

  group('NutritionDao — Meal Logs', () {
    test('insertMealLog and watchMealLogs', () async {
      final today = DateTime.now();
      final id = await dao.insertMealLog(MealLogsCompanion.insert(
        date: DateTime(today.year, today.month, today.day),
        mealType: 'lunch',
        createdAt: today,
        updatedAt: today,
      ));
      expect(id, greaterThan(0));

      final meals = await dao.watchMealLogs(
        DateTime(today.year, today.month, today.day),
      ).first;
      expect(meals, hasLength(1));
      expect(meals.first.mealType, 'lunch');
    });

    test('deleteMealLog removes meal and its items', () async {
      final today = DateTime.now();
      final mealId = await dao.insertMealLog(MealLogsCompanion.insert(
        date: DateTime(today.year, today.month, today.day),
        mealType: 'breakfast',
        createdAt: today,
        updatedAt: today,
      ));

      final foodId = await _insertFoodItem();
      await dao.insertMealLogItem(MealLogItemsCompanion.insert(
        mealLogId: mealId,
        foodItemId: foodId,
        quantityG: 150.0,
        createdAt: today,
      ));

      await dao.deleteMealLog(mealId);

      final meals = await dao.watchMealLogs(
        DateTime(today.year, today.month, today.day),
      ).first;
      expect(meals, isEmpty);
    });
  });

  group('NutritionDao — Water Logs', () {
    test('insertWaterLog and totalWater', () async {
      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);

      await dao.insertWaterLog(WaterLogsCompanion.insert(
        date: date,
        amountMl: 250,
        time: today,
        createdAt: today,
      ));
      await dao.insertWaterLog(WaterLogsCompanion.insert(
        date: date,
        amountMl: 250,
        time: today,
        createdAt: today,
      ));
      await dao.insertWaterLog(WaterLogsCompanion.insert(
        date: date,
        amountMl: 500,
        time: today,
        createdAt: today,
      ));

      final total = await dao.totalWater(date);
      expect(total, 1000);
    });

    test('watchWaterLogs returns logs for date', () async {
      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);

      await dao.insertWaterLog(WaterLogsCompanion.insert(
        date: date,
        amountMl: 250,
        time: today,
        createdAt: today,
      ));

      final logs = await dao.watchWaterLogs(date).first;
      expect(logs, hasLength(1));
      expect(logs.first.amountMl, 250);
    });
  });

  group('NutritionDao — Nutrition Goals', () {
    test('insertNutritionGoal and getActiveGoal', () async {
      final today = DateTime.now();
      await dao.insertNutritionGoal(NutritionGoalsCompanion.insert(
        caloriesKcal: 2500,
        proteinG: const Value(180.0),
        carbsG: const Value(280.0),
        fatG: const Value(80.0),
        waterMl: const Value(2000),
        effectiveDate: today,
        createdAt: today,
      ));

      final goal = await dao.getActiveGoal(today);
      expect(goal, isNotNull);
      expect(goal!.caloriesKcal, 2500);
      expect(goal.proteinG, 180.0);
    });
  });

  group('NutritionDao — Meal Templates', () {
    test('insertMealTemplate and watchMealTemplates', () async {
      await dao.insertMealTemplate(MealTemplatesCompanion.insert(
        name: 'Almuerzo gym',
        mealType: 'lunch',
        itemsJson: '[]',
        createdAt: DateTime.now(),
      ));

      final templates = await dao.watchMealTemplates().first;
      expect(templates, hasLength(1));
      expect(templates.first.name, 'Almuerzo gym');
    });
  });
}
