class FoodItemModel {
  const FoodItemModel({
    required this.id,
    this.barcode,
    required this.name,
    this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.servingSizeG,
    required this.isFavorite,
    required this.isCustom,
    required this.isFromApi,
    required this.createdAt,
  });

  final String id;
  final String? barcode;
  final String name;
  final String? brand;
  final int caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double servingSizeG;
  final bool isFavorite;
  final bool isCustom;
  final bool isFromApi;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'caloriesPer100g': caloriesPer100g,
        'proteinPer100g': proteinPer100g,
        'carbsPer100g': carbsPer100g,
        'fatPer100g': fatPer100g,
        'servingSizeG': servingSizeG,
        'isFavorite': isFavorite,
        'isCustom': isCustom,
        'isFromApi': isFromApi,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FoodItemModel.fromMap(Map<String, dynamic> map) => FoodItemModel(
        id: map['id'] as String,
        barcode: map['barcode'] as String?,
        name: map['name'] as String,
        brand: map['brand'] as String?,
        caloriesPer100g: map['caloriesPer100g'] as int,
        proteinPer100g: (map['proteinPer100g'] as num).toDouble(),
        carbsPer100g: (map['carbsPer100g'] as num).toDouble(),
        fatPer100g: (map['fatPer100g'] as num).toDouble(),
        servingSizeG: (map['servingSizeG'] as num).toDouble(),
        isFavorite: map['isFavorite'] as bool? ?? false,
        isCustom: map['isCustom'] as bool? ?? false,
        isFromApi: map['isFromApi'] as bool? ?? false,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
