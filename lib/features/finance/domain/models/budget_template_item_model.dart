class BudgetTemplateItemModel {
  const BudgetTemplateItemModel({
    required this.id,
    required this.templateId,
    required this.categoryId,
    required this.amountCents,
  });

  final String id;
  final String templateId;
  final String categoryId;
  final int amountCents;

  Map<String, dynamic> toMap() => {
        'id': id,
        'templateId': templateId,
        'categoryId': categoryId,
        'amountCents': amountCents,
      };

  factory BudgetTemplateItemModel.fromMap(Map<String, dynamic> map) =>
      BudgetTemplateItemModel(
        id: map['id'] as String,
        templateId: map['templateId'] as String,
        categoryId: map['categoryId'] as String,
        amountCents: map['amountCents'] as int,
      );
}
