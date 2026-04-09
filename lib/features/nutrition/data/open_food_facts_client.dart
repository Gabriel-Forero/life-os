import 'dart:convert';

import 'package:http/http.dart' as http;

/// DTO representing a food item returned from the Open Food Facts API.
class FoodItemDto {

  factory FoodItemDto.fromProductJson(Map<String, dynamic> product) {
    final name = (product['product_name'] as String?)?.trim().isNotEmpty == true
        ? product['product_name'] as String
        : (product['product_name_es'] as String?)?.trim() ?? '';

    final nutriments =
        (product['nutriments'] as Map<String, dynamic>?) ?? {};

    final calories = _parseInt(nutriments['energy-kcal_100g']);
    final protein = _parseDouble(nutriments['proteins_100g']);
    final carbs = _parseDouble(nutriments['carbohydrates_100g']);
    final fat = _parseDouble(nutriments['fat_100g']);
    final serving = _parseServingSize(product['serving_size'] as String?);

    return FoodItemDto(
      name: name,
      barcode: product['code'] as String?,
      brand: (product['brands'] as String?)?.trim(),
      caloriesPer100g: calories,
      proteinPer100g: protein,
      carbsPer100g: carbs,
      fatPer100g: fat,
      servingSizeG: serving,
    );
  }
  const FoodItemDto({
    required this.name,
    this.barcode,
    this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.servingSizeG,
  });

  final String name;
  final String? barcode;
  final String? brand;
  final int caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double servingSizeG;

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Parses serving size from a string like "40 g", "200 ml", "1 piece".
  /// Defaults to 100.0 when unparseable.
  static double _parseServingSize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 100.0;
    // Extract leading numeric part (including decimals)
    final match = RegExp(r'^\s*(\d+(?:[.,]\d+)?)').firstMatch(raw);
    if (match == null) return 100.0;
    final numStr = match.group(1)!.replaceAll(',', '.');
    return double.tryParse(numStr) ?? 100.0;
  }
}

/// HTTP client for the Open Food Facts public API.
///
/// All methods return empty/null results on any network or parsing error to
/// enable graceful offline degradation.
class OpenFoodFactsClient {
  OpenFoodFactsClient({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://world.openfoodfacts.org';
  static const _headers = {'User-Agent': 'LifeOS/1.0 (flutter; contact@lifeos.app)'};

  /// Searches products by name.
  ///
  /// Returns up to 20 matches. Returns an empty list on any error.
  Future<List<FoodItemDto>> searchByName(String query, {int page = 1}) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/cgi/search.pl').replace(
        queryParameters: {
          'search_terms': query,
          'search_simple': '1',
          'action': 'process',
          'json': '1',
          'page_size': '20',
          'page': '$page',
        },
      );

      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final products = body['products'];
      if (products is! List) return [];

      final results = <FoodItemDto>[];
      for (final raw in products) {
        if (raw is! Map<String, dynamic>) continue;
        final dto = FoodItemDto.fromProductJson(raw);
        if (dto.name.isEmpty) continue;
        results.add(dto);
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Looks up a product by barcode (EAN / UPC).
  ///
  /// Returns null when the product is not found or on any error.
  Future<FoodItemDto?> searchByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return null;

    try {
      final uri = Uri.parse('$_baseUrl/api/v0/product/$barcode.json');
      final response = await _client.get(uri, headers: _headers);
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final status = body['status'];
      if (status != 1) return null;

      final product = body['product'];
      if (product is! Map<String, dynamic>) return null;

      final dto = FoodItemDto.fromProductJson(product);
      if (dto.name.isEmpty) return null;
      return dto;
    } catch (_) {
      return null;
    }
  }
}
