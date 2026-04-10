class CategoryGroupMemberModel {
  const CategoryGroupMemberModel({
    required this.id,
    required this.groupId,
    required this.categoryId,
  });

  final String id;
  final String groupId;
  final String categoryId;

  Map<String, dynamic> toMap() => {
        'id': id,
        'groupId': groupId,
        'categoryId': categoryId,
      };

  factory CategoryGroupMemberModel.fromMap(Map<String, dynamic> map) =>
      CategoryGroupMemberModel(
        id: map['id'] as String,
        groupId: map['groupId'] as String,
        categoryId: map['categoryId'] as String,
      );
}
