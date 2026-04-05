import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/features/nutrition/database/nutrition_dao.dart';
import 'package:life_os/features/nutrition/data/open_food_facts_client.dart';
import 'package:life_os/features/nutrition/data/nutrition_repository.dart';

class MockNutritionDao extends Mock implements NutritionDao {}

class MockOpenFoodFactsClient extends Mock implements OpenFoodFactsClient {}

// Helper to build FoodItem instances for tests
FoodItem _makeFoodItem({
  int id = 1,
  String name = 'Test Food',
  String? barcode,
  String? brand,
  int caloriesPer100g = 100,
  double proteinPer100g = 5.0,
  double carbsPer100g = 10.0,
  double fatPer100g = 2.0,
  double servingSizeG = 100.0,
  bool isFromApi = false,
}) {
  return FoodItem(
    id: id,
    name: name,
    barcode: barcode,
    brand: brand,
    caloriesPer100g: caloriesPer100g,
    proteinPer100g: proteinPer100g,
    carbsPer100g: carbsPer100g,
    fatPer100g: fatPer100g,
    servingSizeG: servingSizeG,
    isFavorite: false,
    isCustom: false,
    isFromApi: isFromApi,
    createdAt: DateTime(2024),
  );
}

FoodItemDto _makeDto({
  String name = 'API Food',
  String? barcode,
  String? brand,
  int caloriesPer100g = 200,
  double proteinPer100g = 8.0,
  double carbsPer100g = 20.0,
  double fatPer100g = 4.0,
  double servingSizeG = 100.0,
}) {
  return FoodItemDto(
    name: name,
    barcode: barcode,
    brand: brand,
    caloriesPer100g: caloriesPer100g,
    proteinPer100g: proteinPer100g,
    carbsPer100g: carbsPer100g,
    fatPer100g: fatPer100g,
    servingSizeG: servingSizeG,
  );
}

void main() {
  late MockNutritionDao mockDao;
  late MockOpenFoodFactsClient mockClient;
  late NutritionRepository sut;

  setUp(() {
    mockDao = MockNutritionDao();
    mockClient = MockOpenFoodFactsClient();
    sut = NutritionRepository(dao: mockDao, apiClient: mockClient);

    registerFallbackValue(
      FoodItemsCompanion(
        name: const Value('fallback'),
        caloriesPer100g: const Value(0),
        createdAt: Value(DateTime.now()),
      ),
    );
  });

  group('NutritionRepository.searchFood', () {
    test('returns merged local and API results', () async {
      final localItem = _makeFoodItem(id: 1, name: 'Local Food');
      final apiDto = _makeDto(name: 'API Food');

      when(() => mockDao.searchFoodItems(any()))
          .thenAnswer((_) async => [localItem]);
      when(() => mockClient.searchByName(any()))
          .thenAnswer((_) async => [apiDto]);
      when(() => mockDao.insertFoodItem(any())).thenAnswer((_) async => 2);
      when(() => mockDao.searchFoodItems(any()))
          .thenAnswer((_) async => [localItem, _makeFoodItem(id: 2, name: 'API Food', isFromApi: true)]);

      final results = await sut.searchFood('food');

      expect(results, hasLength(2));
    });

    test('caches API results to local DB', () async {
      final apiDto = _makeDto(name: 'API Food');

      when(() => mockDao.searchFoodItems(any()))
          .thenAnswer((_) async => []);
      when(() => mockClient.searchByName(any()))
          .thenAnswer((_) async => [apiDto]);
      when(() => mockDao.insertFoodItem(any())).thenAnswer((_) async => 1);

      await sut.searchFood('food');

      verify(() => mockDao.insertFoodItem(any())).called(1);
    });

    test('returns local results only when API throws', () async {
      final localItem = _makeFoodItem(id: 1, name: 'Local Food');

      when(() => mockDao.searchFoodItems(any()))
          .thenAnswer((_) async => [localItem]);
      when(() => mockClient.searchByName(any()))
          .thenThrow(Exception('network error'));

      final results = await sut.searchFood('food');

      expect(results, hasLength(1));
      expect(results.first.name, 'Local Food');
    });

    test('does not cache duplicate items when barcode matches', () async {
      final localItem = _makeFoodItem(id: 1, name: 'Existing', barcode: '12345');
      final apiDto = _makeDto(name: 'Existing', barcode: '12345');

      when(() => mockDao.searchFoodItems(any()))
          .thenAnswer((_) async => [localItem]);
      when(() => mockClient.searchByName(any()))
          .thenAnswer((_) async => [apiDto]);
      // InsertOrIgnore in DAO handles duplicates, but repository should
      // still call insert (DAO deduplicate by barcode unique constraint)
      when(() => mockDao.insertFoodItem(any())).thenAnswer((_) async => 0);

      await sut.searchFood('food');

      // Insert is attempted but DAO handles the deduplication
      verify(() => mockDao.insertFoodItem(any())).called(1);
    });
  });
}
