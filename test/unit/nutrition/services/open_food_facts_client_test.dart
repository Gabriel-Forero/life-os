import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:life_os/features/nutrition/data/open_food_facts_client.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late OpenFoodFactsClient sut;

  setUp(() {
    mockClient = MockHttpClient();
    sut = OpenFoodFactsClient(client: mockClient);
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  group('OpenFoodFactsClient.searchByName', () {
    test('returns list of FoodItemDto on success', () async {
      final responseBody = jsonEncode({
        'products': [
          {
            'product_name': 'Avena',
            'code': '123456',
            'brands': 'Quaker',
            'nutriments': {
              'energy-kcal_100g': 389,
              'proteins_100g': 13.5,
              'carbohydrates_100g': 67.0,
              'fat_100g': 6.9,
            },
            'serving_size': '40 g',
          },
        ],
      });

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final results = await sut.searchByName('avena');

      expect(results, hasLength(1));
      expect(results.first.name, 'Avena');
      expect(results.first.barcode, '123456');
      expect(results.first.brand, 'Quaker');
      expect(results.first.caloriesPer100g, 389);
      expect(results.first.proteinPer100g, 13.5);
      expect(results.first.carbsPer100g, 67.0);
      expect(results.first.fatPer100g, 6.9);
      expect(results.first.servingSizeG, 40.0);
    });

    test('returns empty list on network error', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(Exception('network error'));

      final results = await sut.searchByName('avena');

      expect(results, isEmpty);
    });

    test('returns empty list on non-200 response', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{}', 500));

      final results = await sut.searchByName('avena');

      expect(results, isEmpty);
    });

    test('uses product_name_es fallback when product_name is null', () async {
      final responseBody = jsonEncode({
        'products': [
          {
            'product_name': null,
            'product_name_es': 'Arroz',
            'nutriments': {
              'energy-kcal_100g': 130,
            },
          },
        ],
      });

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final results = await sut.searchByName('arroz');

      expect(results.first.name, 'Arroz');
    });

    test('defaults servingSizeG to 100 when serving_size is unparseable', () async {
      final responseBody = jsonEncode({
        'products': [
          {
            'product_name': 'Test',
            'nutriments': {
              'energy-kcal_100g': 100,
            },
            'serving_size': 'N/A',
          },
        ],
      });

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final results = await sut.searchByName('test');

      expect(results.first.servingSizeG, 100.0);
    });

    test('skips products with empty name', () async {
      final responseBody = jsonEncode({
        'products': [
          {
            'product_name': '',
            'nutriments': {'energy-kcal_100g': 100},
          },
          {
            'product_name': 'Valid Product',
            'nutriments': {'energy-kcal_100g': 200},
          },
        ],
      });

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final results = await sut.searchByName('test');

      expect(results, hasLength(1));
      expect(results.first.name, 'Valid Product');
    });
  });

  group('OpenFoodFactsClient.searchByBarcode', () {
    test('returns FoodItemDto when product found', () async {
      final responseBody = jsonEncode({
        'status': 1,
        'product': {
          'product_name': 'Leche Alpina',
          'code': '7702001000010',
          'brands': 'Alpina',
          'nutriments': {
            'energy-kcal_100g': 61,
            'proteins_100g': 3.2,
            'carbohydrates_100g': 4.8,
            'fat_100g': 3.5,
          },
          'serving_size': '200 ml',
        },
      });

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await sut.searchByBarcode('7702001000010');

      expect(result, isNotNull);
      expect(result!.name, 'Leche Alpina');
      expect(result.barcode, '7702001000010');
      expect(result.caloriesPer100g, 61);
    });

    test('returns null when product not found (status 0)', () async {
      final responseBody = jsonEncode({'status': 0, 'product': null});

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await sut.searchByBarcode('0000000000000');

      expect(result, isNull);
    });

    test('returns null on network error', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(Exception('network error'));

      final result = await sut.searchByBarcode('123456');

      expect(result, isNull);
    });
  });
}
