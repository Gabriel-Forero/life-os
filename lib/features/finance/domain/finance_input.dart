class TransactionInput {
  const TransactionInput({
    required this.type,
    required this.amountCents,
    this.categoryId,
    this.note,
    this.date,
  });

  final String type;
  final int amountCents;
  final String? categoryId;
  final String? note;
  final DateTime? date;
}

class CategoryInput {
  const CategoryInput({
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  final String name;
  final String icon;
  final int color;
  final String type;
}

class SavingsGoalInput {
  const SavingsGoalInput({
    required this.name,
    required this.targetCents,
    this.deadline,
  });

  final String name;
  final int targetCents;
  final DateTime? deadline;
}
