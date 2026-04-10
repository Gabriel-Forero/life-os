class MonthlyBudgetConfigModel {
  const MonthlyBudgetConfigModel({
    required this.id,
    this.globalBudgetCents,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int? globalBudgetCents;
  final int month;
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyBudgetConfigModel copyWith({
    Object? globalBudgetCents = _sentinel,
    DateTime? updatedAt,
  }) =>
      MonthlyBudgetConfigModel(
        id: id,
        globalBudgetCents: identical(globalBudgetCents, _sentinel)
            ? this.globalBudgetCents
            : globalBudgetCents as int?,
        month: month,
        year: year,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'globalBudgetCents': globalBudgetCents,
        'month': month,
        'year': year,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MonthlyBudgetConfigModel.fromMap(Map<String, dynamic> map) =>
      MonthlyBudgetConfigModel(
        id: map['id'] as String,
        globalBudgetCents: map['globalBudgetCents'] as int?,
        month: map['month'] as int,
        year: map['year'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}

const _sentinel = Object();
