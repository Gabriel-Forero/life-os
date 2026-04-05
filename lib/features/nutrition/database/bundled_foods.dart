import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/nutrition/database/nutrition_dao.dart';

/// Seeds the [NutritionDao] with the bundled food library from
/// `assets/foods.json` the first time the app launches.
///
/// The function is idempotent — it checks the row count before inserting and
/// returns immediately when data already exists, so calling it on every cold
/// start is safe.
Future<void> loadBundledFoods(NutritionDao dao) async {
  final count = await dao.countFoodItems();
  if (count > 0) return; // Already loaded

  final jsonStr = await rootBundle.loadString('assets/foods.json');
  final list = jsonDecode(jsonStr) as List<dynamic>;

  final companions = list.map((dynamic raw) {
    final item = raw as Map<String, dynamic>;
    return FoodItemsCompanion.insert(
      name: item['name'] as String,
      brand: Value(item['brand'] as String?),
      caloriesPer100g: item['caloriesPer100g'] as int,
      proteinPer100g: Value((item['proteinPer100g'] as num).toDouble()),
      carbsPer100g: Value((item['carbsPer100g'] as num).toDouble()),
      fatPer100g: Value((item['fatPer100g'] as num).toDouble()),
      servingSizeG: Value((item['servingSizeG'] as num).toDouble()),
      isFavorite: const Value(false),
      isCustom: const Value(false),
      isFromApi: const Value(false),
      createdAt: DateTime.now(),
    );
  }).toList();

  await dao.bulkInsertFoodItems(companions);
}
