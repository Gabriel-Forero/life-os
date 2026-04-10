class AiConversationModel {
  const AiConversationModel({
    required this.id,
    this.configId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? configId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'configId': configId,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AiConversationModel.fromMap(Map<String, dynamic> map) =>
      AiConversationModel(
        id: map['id'] as String,
        configId: map['configId'] as String?,
        title: map['title'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
