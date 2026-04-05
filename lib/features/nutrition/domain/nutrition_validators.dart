import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';

const validMealTypes = {'breakfast', 'lunch', 'dinner', 'snack'};

Result<String> validateFoodItemName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return const Failure(ValidationFailure(
      userMessage: 'El nombre del alimento es obligatorio',
      debugMessage: 'food item name is empty',
      field: 'name',
    ));
  }
  if (trimmed.length > 100) {
    return const Failure(ValidationFailure(
      userMessage: 'Maximo 100 caracteres',
      debugMessage: 'food item name exceeds 100 chars',
      field: 'name',
    ));
  }
  return Success(trimmed);
}

Result<int> validateCalories(int calories) {
  if (calories < 0) {
    return const Failure(ValidationFailure(
      userMessage: 'Las calorias deben ser 0 o mayor',
      debugMessage: 'calories must be non-negative',
      field: 'caloriesPer100g',
    ));
  }
  return Success(calories);
}

Result<double> validateQuantityG(double quantityG) {
  if (quantityG <= 0) {
    return const Failure(ValidationFailure(
      userMessage: 'La cantidad debe ser mayor a 0',
      debugMessage: 'quantityG must be positive',
      field: 'quantityG',
    ));
  }
  return Success(quantityG);
}

Result<int> validateWaterAmount(int amountMl) {
  if (amountMl <= 0) {
    return const Failure(ValidationFailure(
      userMessage: 'La cantidad de agua debe ser mayor a 0',
      debugMessage: 'water amountMl must be positive',
      field: 'amountMl',
    ));
  }
  return Success(amountMl);
}

Result<String> validateMealType(String type) {
  if (!validMealTypes.contains(type)) {
    return Failure(ValidationFailure(
      userMessage: 'Tipo de comida no valido',
      debugMessage: 'mealType "$type" not in $validMealTypes',
      field: 'mealType',
      value: type,
    ));
  }
  return Success(type);
}

String suggestMealType(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 10) return 'breakfast';
  if (hour >= 11 && hour < 14) return 'lunch';
  if (hour >= 18 && hour < 21) return 'dinner';
  return 'snack';
}

double calculateMacroCalories({
  required double proteinG,
  required double carbsG,
  required double fatG,
}) =>
    proteinG * 4 + carbsG * 4 + fatG * 9;

class MacroResult {
  const MacroResult({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  MacroResult operator +(MacroResult other) => MacroResult(
        calories: calories + other.calories,
        proteinG: proteinG + other.proteinG,
        carbsG: carbsG + other.carbsG,
        fatG: fatG + other.fatG,
      );

  static MacroResult fromFood({
    required int caloriesPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    required double quantityG,
  }) {
    final factor = quantityG / 100;
    return MacroResult(
      calories: (caloriesPer100g * factor).round(),
      proteinG: proteinPer100g * factor,
      carbsG: carbsPer100g * factor,
      fatG: fatPer100g * factor,
    );
  }
}
