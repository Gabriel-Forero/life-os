// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_dao.dart';

// ignore_for_file: type=lint
mixin _$NutritionDaoMixin on DatabaseAccessor<AppDatabase> {
  $FoodItemsTable get foodItems => attachedDatabase.foodItems;
  $MealLogsTable get mealLogs => attachedDatabase.mealLogs;
  $MealLogItemsTable get mealLogItems => attachedDatabase.mealLogItems;
  $MealTemplatesTable get mealTemplates => attachedDatabase.mealTemplates;
  $NutritionGoalsTable get nutritionGoals => attachedDatabase.nutritionGoals;
  $WaterLogsTable get waterLogs => attachedDatabase.waterLogs;
  NutritionDaoManager get managers => NutritionDaoManager(this);
}

class NutritionDaoManager {
  final _$NutritionDaoMixin _db;
  NutritionDaoManager(this._db);
  $$FoodItemsTableTableManager get foodItems =>
      $$FoodItemsTableTableManager(_db.attachedDatabase, _db.foodItems);
  $$MealLogsTableTableManager get mealLogs =>
      $$MealLogsTableTableManager(_db.attachedDatabase, _db.mealLogs);
  $$MealLogItemsTableTableManager get mealLogItems =>
      $$MealLogItemsTableTableManager(_db.attachedDatabase, _db.mealLogItems);
  $$MealTemplatesTableTableManager get mealTemplates =>
      $$MealTemplatesTableTableManager(_db.attachedDatabase, _db.mealTemplates);
  $$NutritionGoalsTableTableManager get nutritionGoals =>
      $$NutritionGoalsTableTableManager(
        _db.attachedDatabase,
        _db.nutritionGoals,
      );
  $$WaterLogsTableTableManager get waterLogs =>
      $$WaterLogsTableTableManager(_db.attachedDatabase, _db.waterLogs);
}
