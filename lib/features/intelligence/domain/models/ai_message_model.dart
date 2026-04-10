class AiMessageModel {
  const AiMessageModel({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.tokenCount,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String role;
  final String content;
  final int? tokenCount;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'conversationId': conversationId,
        'role': role,
        'content': content,
        'tokenCount': tokenCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AiMessageModel.fromMap(Map<String, dynamic> map) => AiMessageModel(
        id: map['id'] as String,
        conversationId: map['conversationId'] as String,
        role: map['role'] as String,
        content: map['content'] as String,
        tokenCount: map['tokenCount'] as int?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
