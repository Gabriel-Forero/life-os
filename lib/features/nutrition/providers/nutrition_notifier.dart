import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/features/nutrition/data/nutrition_data_repository.dart';
import 'package:life_os/features/nutrition/domain/models/meal_log_item_model.dart';
import 'package:life_os/features/nutrition/domain/nutrition_input.dart';
import 'package:life_os/features/nutrition/domain/nutrition_validators.dart';

class NutritionNotifier {
  NutritionNotifier({required this.repository});

  final NutritionDataRepository repository;

  // --- Meal Logging ---

  Future<Result<String>> logMeal(MealLogInput input) async {
    final typeResult = validateMealType(input.mealType);
    if (typeResult.isFailure) return Failure(typeResult.failureOrNull!);

    if (input.items.isEmpty) {
      return const Failure(ValidationFailure(
        userMessage: 'Agrega al menos un alimento',
        debugMessage: 'Meal must have at least 1 item',
        field: 'items',
      ));
    }

    for (final item in input.items) {
      final qResult = validateQuantityG(item.quantityG);
      if (qResult.isFailure) return Failure(qResult.failureOrNull!);
    }

    try {
      final now = DateTime.now();
      final date = input.date ?? now;

      final mealId = await repository.insertMealLog(
        date: DateTime(date.year, date.month, date.day),
        mealType: input.mealType,
        note: input.note,
        createdAt: now,
        updatedAt: now,
      );

      final companions = input.items
          .map(
            (item) => MealLogItemModel(
              id: '', // ignored by setMealLogItems
              mealLogId: mealId,
              foodItemId: item.foodItemId.toString(),
              quantityG: item.quantityG,
              createdAt: now,
            ),
          )
          .toList();
      await repository.setMealLogItems(mealId, companions);

      return Success(mealId);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al registrar comida',
        debugMessage: 'logMeal failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> deleteMeal(String mealId) async {
    try {
      await repository.deleteMealLog(mealId);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al eliminar comida',
        debugMessage: 'deleteMeal failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Custom Food ---

  Future<Result<String>> addCustomFood(CustomFoodInput input) async {
    final nameResult = validateFoodItemName(input.name);
    if (nameResult.isFailure) return Failure(nameResult.failureOrNull!);

    final calResult = validateCalories(input.caloriesPer100g);
    if (calResult.isFailure) return Failure(calResult.failureOrNull!);

    try {
      final id = await repository.insertFoodItem(
        name: nameResult.valueOrNull!,
        brand: input.brand,
        caloriesPer100g: input.caloriesPer100g,
        proteinPer100g: input.proteinPer100g,
        carbsPer100g: input.carbsPer100g,
        fatPer100g: input.fatPer100g,
        servingSizeG: input.servingSizeG,
        isFavorite: false,
        isCustom: true,
        isFromApi: false,
        createdAt: DateTime.now(),
      );
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al crear alimento',
        debugMessage: 'addCustomFood failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Favorites ---

  Future<Result<void>> toggleFavorite(String foodItemId, bool isFavorite) async {
    try {
      await repository.toggleFavorite(foodItemId, isFavorite);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al actualizar favorito',
        debugMessage: 'toggleFavorite failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Water ---

  Future<Result<String>> logWater(int amountMl) async {
    final result = validateWaterAmount(amountMl);
    if (result.isFailure) return Failure(result.failureOrNull!);

    try {
      final now = DateTime.now();
      final id = await repository.insertWaterLog(
        date: DateTime(now.year, now.month, now.day),
        amountMl: amountMl,
        time: now,
        createdAt: now,
      );
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al registrar agua',
        debugMessage: 'logWater failed: $e',
        originalError: e,
      ));
    }
  }

  Future<Result<void>> removeWaterLog(String id) async {
    try {
      await repository.deleteWaterLog(id);
      return const Success(null);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al eliminar registro de agua',
        debugMessage: 'removeWaterLog failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Nutrition Goals ---

  Future<Result<String>> setNutritionGoal(NutritionGoalInput input) async {
    if (input.caloriesKcal <= 0) {
      return const Failure(ValidationFailure(
        userMessage: 'Las calorias deben ser mayor a 0',
        debugMessage: 'caloriesKcal must be positive',
        field: 'caloriesKcal',
      ));
    }

    try {
      final now = DateTime.now();
      final id = await repository.insertNutritionGoal(
        caloriesKcal: input.caloriesKcal,
        proteinG: input.proteinG,
        carbsG: input.carbsG,
        fatG: input.fatG,
        waterMl: input.waterMl,
        effectiveDate: now,
        createdAt: now,
      );
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al guardar meta nutricional',
        debugMessage: 'setNutritionGoal failed: $e',
        originalError: e,
      ));
    }
  }

  // --- Templates ---

  Future<Result<String>> saveAsTemplate({
    required String name,
    required String mealType,
    required String itemsJson,
  }) async {
    if (name.trim().isEmpty) {
      return const Failure(ValidationFailure(
        userMessage: 'El nombre de la plantilla es obligatorio',
        debugMessage: 'template name is empty',
        field: 'name',
      ));
    }

    try {
      final id = await repository.insertMealTemplate(
        name: name.trim(),
        mealType: mealType,
        itemsJson: itemsJson,
        createdAt: DateTime.now(),
      );
      return Success(id);
    } on Exception catch (e) {
      return Failure(DatabaseFailure(
        userMessage: 'Error al guardar plantilla',
        debugMessage: 'saveAsTemplate failed: $e',
        originalError: e,
      ));
    }
  }
}
