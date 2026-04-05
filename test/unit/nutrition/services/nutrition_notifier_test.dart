import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/features/nutrition/database/nutrition_dao.dart';
import 'package:life_os/features/nutrition/domain/nutrition_input.dart';
import 'package:life_os/features/nutrition/providers/nutrition_notifier.dart';

void main() {
  late AppDatabase db;
  late NutritionDao dao;
  late NutritionNotifier notifier;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.nutritionDao;
    notifier = NutritionNotifier(dao: dao);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> _insertFood({String name = 'Arroz blanco'}) async {
    return dao.insertFoodItem(FoodItemsCompanion.insert(
      name: name,
      caloriesPer100g: 130,
      proteinPer100g: const Value(2.7),
      carbsPer100g: const Value(28.0),
      fatPer100g: const Value(0.3),
      servingSizeG: const Value(150.0),
      isCustom: const Value(false),
      isFromApi: const Value(false),
      isFavorite: const Value(false),
      createdAt: DateTime.now(),
    ));
  }

  group('NutritionNotifier — logMeal', () {
    test('logs meal with items', () async {
      final foodId = await _insertFood();
      final result = await notifier.logMeal(MealLogInput(
        mealType: 'lunch',
        items: [MealItemInput(foodItemId: foodId, quantityG: 200)],
      ));
      expect(result, isA<Success<int>>());
    });

    test('rejects meal with no items', () async {
      final result = await notifier.logMeal(const MealLogInput(
        mealType: 'lunch',
        items: [],
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects invalid meal type', () async {
      final foodId = await _insertFood();
      final result = await notifier.logMeal(MealLogInput(
        mealType: 'brunch',
        items: [MealItemInput(foodItemId: foodId, quantityG: 100)],
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects zero quantity', () async {
      final foodId = await _insertFood();
      final result = await notifier.logMeal(MealLogInput(
        mealType: 'lunch',
        items: [MealItemInput(foodItemId: foodId, quantityG: 0)],
      ));
      expect(result, isA<Failure<int>>());
    });
  });

  group('NutritionNotifier — addCustomFood', () {
    test('creates custom food item', () async {
      final result = await notifier.addCustomFood(const CustomFoodInput(
        name: 'Arepa de maiz',
        caloriesPer100g: 200,
        proteinPer100g: 4.0,
        carbsPer100g: 37.0,
        fatPer100g: 3.0,
        servingSizeG: 80.0,
      ));
      expect(result, isA<Success<int>>());
    });

    test('rejects empty name', () async {
      final result = await notifier.addCustomFood(const CustomFoodInput(
        name: '',
        caloriesPer100g: 100,
      ));
      expect(result, isA<Failure<int>>());
    });

    test('rejects negative calories', () async {
      final result = await notifier.addCustomFood(const CustomFoodInput(
        name: 'Invalid',
        caloriesPer100g: -10,
      ));
      expect(result, isA<Failure<int>>());
    });
  });

  group('NutritionNotifier — water', () {
    test('logs water', () async {
      final result = await notifier.logWater(250);
      expect(result, isA<Success<int>>());

      final today = DateTime.now();
      final total = await dao.totalWater(
        DateTime(today.year, today.month, today.day),
      );
      expect(total, 250);
    });

    test('logs multiple glasses', () async {
      await notifier.logWater(250);
      await notifier.logWater(250);
      await notifier.logWater(500);

      final today = DateTime.now();
      final total = await dao.totalWater(
        DateTime(today.year, today.month, today.day),
      );
      expect(total, 1000);
    });

    test('rejects zero ml', () async {
      final result = await notifier.logWater(0);
      expect(result, isA<Failure<int>>());
    });
  });

  group('NutritionNotifier — goals', () {
    test('sets nutrition goal', () async {
      final result = await notifier.setNutritionGoal(const NutritionGoalInput(
        caloriesKcal: 2500,
        proteinG: 180,
        carbsG: 280,
        fatG: 80,
      ));
      expect(result, isA<Success<int>>());

      final goal = await dao.getActiveGoal(DateTime.now());
      expect(goal!.caloriesKcal, 2500);
    });

    test('rejects zero calories', () async {
      final result = await notifier.setNutritionGoal(const NutritionGoalInput(
        caloriesKcal: 0,
      ));
      expect(result, isA<Failure<int>>());
    });
  });

  group('NutritionNotifier — favorites', () {
    test('toggles favorite on', () async {
      final foodId = await _insertFood();
      await notifier.toggleFavorite(foodId, true);

      final favs = await dao.watchFavorites().first;
      expect(favs, hasLength(1));
    });

    test('toggles favorite off', () async {
      final foodId = await _insertFood();
      await notifier.toggleFavorite(foodId, true);
      await notifier.toggleFavorite(foodId, false);

      final favs = await dao.watchFavorites().first;
      expect(favs, isEmpty);
    });
  });

  group('NutritionNotifier — templates', () {
    test('saves template', () async {
      final result = await notifier.saveAsTemplate(
        name: 'Almuerzo gym',
        mealType: 'lunch',
        itemsJson: '[{"foodItemId":1,"quantityG":200}]',
      );
      expect(result, isA<Success<int>>());
    });

    test('rejects empty template name', () async {
      final result = await notifier.saveAsTemplate(
        name: '',
        mealType: 'lunch',
        itemsJson: '[]',
      );
      expect(result, isA<Failure<int>>());
    });
  });
}
