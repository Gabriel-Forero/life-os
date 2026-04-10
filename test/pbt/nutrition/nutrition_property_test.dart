import 'dart:math';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/nutrition/data/drift_nutrition_data_repository.dart';
import 'package:life_os/features/nutrition/data/nutrition_data_repository.dart';
import 'package:life_os/features/nutrition/database/nutrition_dao.dart';
import 'package:life_os/features/nutrition/domain/nutrition_input.dart';
import 'package:life_os/features/nutrition/domain/nutrition_validators.dart';
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

  group('RT-NUT: Round-trip properties', () {
    test('RT-NUT-01: FoodItem insert → search returns same data (30 samples)', () async {
      final random = Random(42);

      for (var i = 0; i < 30; i++) {
        final name = 'Food_${random.nextInt(100000)}';
        final cal = random.nextInt(500) + 10;
        final protein = random.nextDouble() * 50;

        final id = await dao.insertFoodItem(FoodItemsCompanion.insert(
          name: name,
          caloriesPer100g: cal,
          proteinPer100g: Value(protein),
          isCustom: const Value(true),
          isFromApi: const Value(false),
          isFavorite: const Value(false),
          createdAt: DateTime.now(),
        ));

        final results = await dao.searchFoodItems(name);
        final found = results.firstWhere((f) => f.id == id);
        expect(found.caloriesPer100g, cal);
        expect(found.proteinPer100g, closeTo(protein, 0.001));
      }
    });

    test('RT-NUT-02: Water log insert → totalWater sums correctly (20 samples)', () async {
      final random = Random(42);
      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);
      var expectedTotal = 0;

      for (var i = 0; i < 20; i++) {
        final amount = (random.nextInt(5) + 1) * 100; // 100-500ml
        await dao.insertWaterLog(WaterLogsCompanion.insert(
          date: date,
          amountMl: amount,
          time: today,
          createdAt: today,
        ));
        expectedTotal += amount;
      }

      final total = await dao.totalWater(date);
      expect(total, expectedTotal);
    });
  });

  group('INV-NUT: Invariant properties', () {
    test('INV-NUT-01: MacroResult.fromFood scales linearly (50 samples)', () {
      final random = Random(42);

      for (var i = 0; i < 50; i++) {
        final cal = random.nextInt(500) + 10;
        final protein = random.nextDouble() * 50;
        final carbs = random.nextDouble() * 80;
        final fat = random.nextDouble() * 30;
        final quantity = random.nextDouble() * 500 + 10;

        final result = MacroResult.fromFood(
          caloriesPer100g: cal,
          proteinPer100g: protein,
          carbsPer100g: carbs,
          fatPer100g: fat,
          quantityG: quantity,
        );

        final factor = quantity / 100;
        expect(result.calories, (cal * factor).round());
        expect(result.proteinG, closeTo(protein * factor, 0.001));
        expect(result.carbsG, closeTo(carbs * factor, 0.001));
        expect(result.fatG, closeTo(fat * factor, 0.001));
      }
    });

    test('INV-NUT-02: Macro calorie formula P*4+C*4+F*9 (50 samples)', () {
      final random = Random(42);

      for (var i = 0; i < 50; i++) {
        final p = random.nextDouble() * 200;
        final c = random.nextDouble() * 400;
        final f = random.nextDouble() * 100;

        final result = calculateMacroCalories(
          proteinG: p,
          carbsG: c,
          fatG: f,
        );
        expect(result, closeTo(p * 4 + c * 4 + f * 9, 0.001));
      }
    });

    test('INV-NUT-03: suggestMealType always returns valid type', () {
      for (var hour = 0; hour < 24; hour++) {
        final type = suggestMealType(DateTime(2026, 4, 4, hour));
        expect(
          validMealTypes.contains(type),
          isTrue,
          reason: 'Hour $hour produced invalid type: $type',
        );
      }
    });
  });

  group('IDP-NUT: Idempotence properties', () {
    test('IDP-NUT-01: Setting same nutrition goal twice = latest wins', () async {
      await notifier.setNutritionGoal(const NutritionGoalInput(
        caloriesKcal: 2500,
        proteinG: 180,
      ));
      await notifier.setNutritionGoal(const NutritionGoalInput(
        caloriesKcal: 2500,
        proteinG: 180,
      ));

      final goal = await repository.getActiveGoal(DateTime.now());
      expect(goal, isNotNull);
      expect(goal!.caloriesKcal, 2500);
    });
  });
}
