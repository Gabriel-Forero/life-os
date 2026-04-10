class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.categoryId,
    this.note,
    required this.date,
    this.recurringId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final int amountCents;
  final String categoryId;
  final String? note;
  final DateTime date;
  final String? recurringId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel copyWith({
    String? type,
    int? amountCents,
    String? categoryId,
    Object? note = _sentinel,
    DateTime? date,
    Object? recurringId = _sentinel,
    DateTime? updatedAt,
  }) =>
      TransactionModel(
        id: id,
        type: type ?? this.type,
        amountCents: amountCents ?? this.amountCents,
        categoryId: categoryId ?? this.categoryId,
        note: identical(note, _sentinel) ? this.note : note as String?,
        date: date ?? this.date,
        recurringId: identical(recurringId, _sentinel)
            ? this.recurringId
            : recurringId as String?,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'amountCents': amountCents,
        'categoryId': categoryId,
        'note': note,
        'date': date.toIso8601String(),
        'recurringId': recurringId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) =>
      TransactionModel(
        id: map['id'] as String,
        type: map['type'] as String,
        amountCents: map['amountCents'] as int,
        categoryId: map['categoryId'] as String,
        note: map['note'] as String?,
        date: DateTime.parse(map['date'] as String),
        recurringId: map['recurringId'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}

const _sentinel = Object();
