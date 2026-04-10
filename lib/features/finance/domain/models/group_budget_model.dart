class GroupBudgetModel {
  const GroupBudgetModel({
    required this.id,
    required this.groupId,
    required this.amountCents,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String groupId;
  final int amountCents;
  final int month;
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupBudgetModel copyWith({
    int? amountCents,
    DateTime? updatedAt,
  }) =>
      GroupBudgetModel(
        id: id,
        groupId: groupId,
        amountCents: amountCents ?? this.amountCents,
        month: month,
        year: year,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'groupId': groupId,
        'amountCents': amountCents,
        'month': month,
        'year': year,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory GroupBudgetModel.fromMap(Map<String, dynamic> map) =>
      GroupBudgetModel(
        id: map['id'] as String,
        groupId: map['groupId'] as String,
        amountCents: map['amountCents'] as int,
        month: map['month'] as int,
        year: map['year'] as int,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
