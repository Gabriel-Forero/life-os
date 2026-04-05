class MealLogInput {
  const MealLogInput({
    required this.mealType,
    required this.items,
    this.note,
    this.date,
  });

  final String mealType;
  final List<MealItemInput> items;
  final String? note;
  final DateTime? date;
}

class MealItemInput {
  const MealItemInput({
    required this.foodItemId,
    required this.quantityG,
  });

  final int foodItemId;
  final double quantityG;
}

class NutritionGoalInput {
  const NutritionGoalInput({
    required this.caloriesKcal,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.waterMl = 2000,
  });

  final int caloriesKcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int waterMl;
}

class CustomFoodInput {
  const CustomFoodInput({
    required this.name,
    required this.caloriesPer100g,
    this.proteinPer100g = 0,
    this.carbsPer100g = 0,
    this.fatPer100g = 0,
    this.servingSizeG = 100,
    this.brand,
  });

  final String name;
  final int caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double servingSizeG;
  final String? brand;
}
