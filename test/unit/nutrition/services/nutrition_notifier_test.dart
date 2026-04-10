import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/features/nutrition/data/drift_nutrition_data_repository.dart';
import 'package:life_os/features/nutrition/data/nutrition_data_repository.dart';
import 'package:life_os/features/nutrition/database/nutrition_dao.dart';
import 'package:life_os/features/nutrition/domain/nutrition_input.dart';
import 'package:life_os/features/nutrition/providers/nutrition_notifier.dart';

void main() {
  late AppDatabase db;
  late NutritionDao dao;
  late NutritionDataRepository repository;
  late NutritionNotifier notifier;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.nutritionDao;
    repository = DriftNutritionDataRepository(dao: dao);
    notifier = NutritionNotifier(repository: repository);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> insertFood({String name = 'Arroz blanco'}) async {
    return repository.insertFoodItem(
      name: name,
      caloriesPer100g: 130,
      proteinPer100g: 2.7,
      carbsPer100g: 28.0,
      fatPer100g: 0.3,
      servingSizeG: 150.0,
      isCustom: false,
      isFromApi: false,
      isFavorite: false,
      createdAt: DateTime.now(),
    );
  }

  group('NutritionNotifier — logMeal', () {
    test('logs meal with items', () async {
      final foodId = await insertFood();
      final result = await notifier.logMeal(MealLogInput(
        mealType: 'lunch',
        items: [MealItemInput(foodItemId: foodId, quantityG: 200)],
      ));
      expect(result, isA<Success<String>>());
    });

    test('rejects meal with no items', () async {
      final result = await notifier.logMeal(const MealLogInput(
        mealType: 'lunch',
        items: [],
      ));
      expect(result, isA<Failure<String>>());
    });

    test('rejects invalid meal type', () async {
      final foodId = await insertFood();
      final result = await notifier.logMeal(MealLogInput(
        mealType: 'brunch',
        items: [MealItemInput(foodItemId: foodId, quantityG: 100)],
      ));
      expect(result, isA<Failure<String>>());
    });

    test('rejects zero quantity', () async {
      final foodId = await insertFood();
      final result = await notifier.logMeal(MealLogInput(
        mealType: 'lunch',
        items: [MealItemInput(foodItemId: foodId, quantityG: 0)],
      ));
      expect(result, isA<Failure<String>>());
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
      expect(result, isA<Success<String>>());
    });

    test('rejects empty name', () async {
      final result = await notifier.addCustomFood(const CustomFoodInput(
        name: '',
        caloriesPer100g: 100,
      ));
      expect(result, isA<Failure<String>>());
    });

    test('rejects negative calories', () async {
      final result = await notifier.addCustomFood(const CustomFoodInput(
        name: 'Invalid',
        caloriesPer100g: -10,
      ));
      expect(result, isA<Failure<String>>());
    });
  });

  group('NutritionNotifier — water', () {
    test('logs water', () async {
      final result = await notifier.logWater(250);
      expect(result, isA<Success<String>>());

      final today = DateTime.now();
      final total = await repository.totalWater(
        DateTime(today.year, today.month, today.day),
      );
      expect(total, 250);
    });

    test('logs multiple glasses', () async {
      await notifier.logWater(250);
      await notifier.logWater(250);
      await notifier.logWater(500);

      final today = DateTime.now();
      final total = await repository.totalWater(
        DateTime(today.year, today.month, today.day),
      );
      expect(total, 1000);
    });

    test('rejects zero ml', () async {
      final result = await notifier.logWater(0);
      expect(result, isA<Failure<String>>());
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
      expect(result, isA<Success<String>>());

      final goal = await repository.getActiveGoal(DateTime.now());
      expect(goal!.caloriesKcal, 2500);
    });

    test('rejects zero calories', () async {
      final result = await notifier.setNutritionGoal(const NutritionGoalInput(
        caloriesKcal: 0,
      ));
      expect(result, isA<Failure<String>>());
    });
  });

  group('NutritionNotifier — favorites', () {
    test('toggles favorite on', () async {
      final foodId = await insertFood();
      await notifier.toggleFavorite(foodId, true);

      final favs = await repository.watchFavorites().first;
      expect(favs, hasLength(1));
    });

    test('toggles favorite off', () async {
      final foodId = await insertFood();
      await notifier.toggleFavorite(foodId, true);
      await notifier.toggleFavorite(foodId, false);

      final favs = await repository.watchFavorites().first;
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
      expect(result, isA<Success<String>>());
    });

    test('rejects empty template name', () async {
      final result = await notifier.saveAsTemplate(
        name: '',
        mealType: 'lunch',
        itemsJson: '[]',
      );
      expect(result, isA<Failure<String>>());
    });
  });
}
