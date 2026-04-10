class CategoryGroupModel {
  const CategoryGroupModel({
    required this.id,
    required this.name,
    required this.color,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int color;
  final int sortOrder;
  final DateTime createdAt;

  CategoryGroupModel copyWith({
    String? name,
    int? color,
    int? sortOrder,
  }) =>
      CategoryGroupModel(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CategoryGroupModel.fromMap(Map<String, dynamic> map) =>
      CategoryGroupModel(
        id: map['id'] as String,
        name: map['name'] as String,
        color: map['color'] as int? ?? 0xFF9CA3AF,
        sortOrder: map['sortOrder'] as int? ?? 0,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
