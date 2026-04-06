import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/nutrition/database/bundled_foods.dart';
import 'package:life_os/features/nutrition/database/nutrition_dao.dart';

// Minimal food library used by tests so we don't depend on the real asset file.
const _testFoods = [
  {
    'name': 'Pechuga de pollo a la plancha',
    'brand': null,
    'caloriesPer100g': 165,
    'proteinPer100g': 31.0,
    'carbsPer100g': 0.0,
    'fatPer100g': 3.6,
    'servingSizeG': 200.0,
  },
  {
    'name': 'Arroz blanco cocido',
    'brand': 'Diana',
    'caloriesPer100g': 130,
    'proteinPer100g': 2.7,
    'carbsPer100g': 28.0,
    'fatPer100g': 0.3,
    'servingSizeG': 150.0,
  },
];

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

/// Registers a fake `assets/foods.json` asset so [rootBundle] can resolve it
/// during tests without needing the actual Flutter asset bundle.
void _registerFakeFoodsAsset(List<Map<String, Object?>> foods) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
    // The message contains the asset key as a UTF-8 string.
    final key = utf8.decode(message!.buffer.asUint8List());
    if (key == 'assets/foods.json') {
      final encoded = utf8.encode(jsonEncode(foods));
      final response = encoded.buffer.asByteData();
      return response;
    }
    return null;
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late NutritionDao dao;

  setUp(() {
    db = _createInMemoryDb();
    dao = db.nutritionDao;
    _registerFakeFoodsAsset(_testFoods);
  });

  tearDown(() async {
    // Restore the default handler so it doesn't leak into other tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    await db.close();
  });

  group('loadBundledFoods', () {
    test('inserts all items from the JSON asset on first call', () async {
      await loadBundledFoods(dao);

      final count = await dao.countFoodItems();
      expect(count, _testFoods.length);
    });

    test('stores name and nutritional data correctly', () async {
      await loadBundledFoods(dao);

      final results = await dao.searchFoodItems('Pechuga');
      expect(results, hasLength(1));
      expect(results.first.caloriesPer100g, 165);
      expect(results.first.proteinPer100g, 31.0);
      expect(results.first.isCustom, isFalse);
      expect(results.first.isFromApi, isFalse);
    });

    test('stores nullable brand correctly', () async {
      await loadBundledFoods(dao);

      final noLabel = await dao.searchFoodItems('Pechuga');
      expect(noLabel.first.brand, isNull);

      final withLabel = await dao.searchFoodItems('Arroz');
      expect(withLabel.first.brand, 'Diana');
    });

    test('is idempotent — skips insert when data already exists', () async {
      // First call seeds the DB.
      await loadBundledFoods(dao);
      final countAfterFirst = await dao.countFoodItems();
      expect(countAfterFirst, _testFoods.length);

      // Second call must NOT duplicate rows.
      await loadBundledFoods(dao);
      final countAfterSecond = await dao.countFoodItems();
      expect(countAfterSecond, _testFoods.length,
          reason: 'loadBundledFoods should skip insert when count > 0');
    });
  });
}
