class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.isPredefined,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String icon;
  final int color;
  final String type;
  final bool isPredefined;
  final int sortOrder;
  final DateTime createdAt;

  CategoryModel copyWith({
    String? name,
    String? icon,
    int? color,
    String? type,
    bool? isPredefined,
    int? sortOrder,
  }) =>
      CategoryModel(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        type: type ?? this.type,
        isPredefined: isPredefined ?? this.isPredefined,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'type': type,
        'isPredefined': isPredefined,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String? ?? 'category',
        color: map['color'] as int? ?? 0xFF9CA3AF,
        type: map['type'] as String? ?? 'expense',
        isPredefined: map['isPredefined'] as bool? ?? false,
        sortOrder: map['sortOrder'] as int? ?? 0,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
