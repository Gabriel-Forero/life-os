import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/features/nutrition/domain/nutrition_validators.dart';

void main() {
  group('validateFoodItemName', () {
    test('rejects empty', () => expect(validateFoodItemName(''), isA<Failure<String>>()));
    test('rejects over 100', () => expect(validateFoodItemName('a' * 101), isA<Failure<String>>()));
    test('accepts valid', () => expect(validateFoodItemName('Arroz blanco'), isA<Success<String>>()));
    test('trims', () => expect(validateFoodItemName('  Arroz  ').valueOrNull, 'Arroz'));
  });

  group('validateCalories', () {
    test('rejects negative', () => expect(validateCalories(-1), isA<Failure<int>>()));
    test('accepts zero', () => expect(validateCalories(0), isA<Success<int>>()));
    test('accepts positive', () => expect(validateCalories(330), isA<Success<int>>()));
  });

  group('validateQuantityG', () {
    test('rejects zero', () => expect(validateQuantityG(0), isA<Failure<double>>()));
    test('rejects negative', () => expect(validateQuantityG(-10), isA<Failure<double>>()));
    test('accepts positive', () => expect(validateQuantityG(200.0), isA<Success<double>>()));
  });

  group('validateWaterAmount', () {
    test('rejects zero', () => expect(validateWaterAmount(0), isA<Failure<int>>()));
    test('accepts positive', () => expect(validateWaterAmount(250), isA<Success<int>>()));
  });

  group('validateMealType', () {
    test('accepts breakfast', () => expect(validateMealType('breakfast'), isA<Success<String>>()));
    test('accepts lunch', () => expect(validateMealType('lunch'), isA<Success<String>>()));
    test('accepts dinner', () => expect(validateMealType('dinner'), isA<Success<String>>()));
    test('accepts snack', () => expect(validateMealType('snack'), isA<Success<String>>()));
    test('rejects invalid', () => expect(validateMealType('brunch'), isA<Failure<String>>()));
  });

  group('suggestMealType', () {
    test('7:00 → breakfast', () => expect(suggestMealType(DateTime(2026, 4, 4, 7)), 'breakfast'));
    test('12:00 → lunch', () => expect(suggestMealType(DateTime(2026, 4, 4, 12)), 'lunch'));
    test('19:00 → dinner', () => expect(suggestMealType(DateTime(2026, 4, 4, 19)), 'dinner'));
    test('15:00 → snack', () => expect(suggestMealType(DateTime(2026, 4, 4, 15)), 'snack'));
    test('3:00 → snack', () => expect(suggestMealType(DateTime(2026, 4, 4, 3)), 'snack'));
  });

  group('calculateMacroCalories', () {
    test('correct formula P*4 + C*4 + F*9', () {
      expect(
        calculateMacroCalories(proteinG: 180, carbsG: 280, fatG: 80),
        closeTo(2560, 0.01), // 720 + 1120 + 720
      );
    });
    test('zero macros = 0', () {
      expect(calculateMacroCalories(proteinG: 0, carbsG: 0, fatG: 0), 0);
    });
  });

  group('MacroResult.fromFood', () {
    test('scales proportionally from per-100g', () {
      final result = MacroResult.fromFood(
        caloriesPer100g: 165,
        proteinPer100g: 31.0,
        carbsPer100g: 0.0,
        fatPer100g: 3.6,
        quantityG: 200.0,
      );
      expect(result.calories, 330); // 165 * 2
      expect(result.proteinG, closeTo(62.0, 0.01)); // 31 * 2
      expect(result.fatG, closeTo(7.2, 0.01)); // 3.6 * 2
    });

    test('50g serving', () {
      final result = MacroResult.fromFood(
        caloriesPer100g: 200,
        proteinPer100g: 10.0,
        carbsPer100g: 30.0,
        fatPer100g: 5.0,
        quantityG: 50.0,
      );
      expect(result.calories, 100);
      expect(result.proteinG, closeTo(5.0, 0.01));
    });
  });

  group('MacroResult addition', () {
    test('sums correctly', () {
      const a = MacroResult(calories: 300, proteinG: 30, carbsG: 40, fatG: 10);
      const b = MacroResult(calories: 200, proteinG: 20, carbsG: 20, fatG: 5);
      final sum = a + b;
      expect(sum.calories, 500);
      expect(sum.proteinG, 50);
      expect(sum.carbsG, 60);
      expect(sum.fatG, 15);
    });
  });
}
