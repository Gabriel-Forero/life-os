class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.amountCents,
    required this.month,
    required this.year,
    required this.autoRepeat,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String categoryId;
  final int amountCents;
  final int month;
  final int year;
  final bool autoRepeat;
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetModel copyWith({
    int? amountCents,
    bool? autoRepeat,
    DateTime? updatedAt,
  }) =>
      BudgetModel(
        id: id,
        categoryId: categoryId,
        amountCents: amountCents ?? this.amountCents,
        month: month,
        year: year,
        autoRepeat: autoRepeat ?? this.autoRepeat,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'categoryId': categoryId,
        'amountCents': amountCents,
        'month': month,
        'year': year,
        'autoRepeat': autoRepeat,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BudgetModel.fromMap(Map<String, dynamic> map) => BudgetModel(
        id: map['id'] as String,
        categoryId: map['categoryId'] as String,
        amountCents: map['amountCents'] as int,
        month: map['month'] as int,
        year: map['year'] as int,
        autoRepeat: map['autoRepeat'] as bool? ?? true,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
