class RecurringTransactionModel {
  const RecurringTransactionModel({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.categoryId,
    this.note,
    required this.frequency,
    required this.nextOccurrence,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String type;
  final int amountCents;
  final String categoryId;
  final String? note;
  final String frequency;
  final DateTime nextOccurrence;
  final bool isActive;
  final DateTime createdAt;

  RecurringTransactionModel copyWith({
    String? type,
    int? amountCents,
    String? categoryId,
    Object? note = _sentinel,
    String? frequency,
    DateTime? nextOccurrence,
    bool? isActive,
  }) =>
      RecurringTransactionModel(
        id: id,
        type: type ?? this.type,
        amountCents: amountCents ?? this.amountCents,
        categoryId: categoryId ?? this.categoryId,
        note: identical(note, _sentinel) ? this.note : note as String?,
        frequency: frequency ?? this.frequency,
        nextOccurrence: nextOccurrence ?? this.nextOccurrence,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'amountCents': amountCents,
        'categoryId': categoryId,
        'note': note,
        'frequency': frequency,
        'nextOccurrence': nextOccurrence.toIso8601String(),
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map) =>
      RecurringTransactionModel(
        id: map['id'] as String,
        type: map['type'] as String,
        amountCents: map['amountCents'] as int,
        categoryId: map['categoryId'] as String,
        note: map['note'] as String?,
        frequency: map['frequency'] as String? ?? 'monthly',
        nextOccurrence: DateTime.parse(map['nextOccurrence'] as String),
        isActive: map['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

const _sentinel = Object();
