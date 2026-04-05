import 'package:drift/drift.dart';

class FoodItems extends Table {
  @override
  String get tableName => 'food_items';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get barcode => text().nullable().unique()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get brand => text().nullable()();
  IntColumn get caloriesPer100g => integer()();
  RealColumn get proteinPer100g => real().withDefault(const Constant(0.0))();
  RealColumn get carbsPer100g => real().withDefault(const Constant(0.0))();
  RealColumn get fatPer100g => real().withDefault(const Constant(0.0))();
  RealColumn get servingSizeG => real().withDefault(const Constant(100.0))();
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isCustom =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isFromApi =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
}

class MealLogs extends Table {
  @override
  String get tableName => 'meal_logs';

  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  TextColumn get mealType => text()(); // breakfast, lunch, dinner, snack
  TextColumn get note => text().nullable().withLength(max: 200)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class MealLogItems extends Table {
  @override
  String get tableName => 'meal_log_items';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get mealLogId => integer().references(MealLogs, #id)();
  IntColumn get foodItemId => integer().references(FoodItems, #id)();
  RealColumn get quantityG => real()();
  DateTimeColumn get createdAt => dateTime()();
}

class MealTemplates extends Table {
  @override
  String get tableName => 'meal_templates';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get mealType => text()();
  TextColumn get itemsJson => text()(); // JSON array of {foodItemId, quantityG}
  DateTimeColumn get createdAt => dateTime()();
}

class NutritionGoals extends Table {
  @override
  String get tableName => 'nutrition_goals';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get caloriesKcal => integer()();
  RealColumn get proteinG => real().withDefault(const Constant(0.0))();
  RealColumn get carbsG => real().withDefault(const Constant(0.0))();
  RealColumn get fatG => real().withDefault(const Constant(0.0))();
  IntColumn get waterMl => integer().withDefault(const Constant(2000))();
  DateTimeColumn get effectiveDate => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}

class WaterLogs extends Table {
  @override
  String get tableName => 'water_logs';

  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get amountMl => integer()();
  DateTimeColumn get time => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}
