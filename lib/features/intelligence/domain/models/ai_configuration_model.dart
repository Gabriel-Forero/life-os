class AiConfigurationModel {
  const AiConfigurationModel({
    required this.id,
    required this.providerKey,
    required this.modelName,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String providerKey;
  final String modelName;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'providerKey': providerKey,
        'modelName': modelName,
        'isDefault': isDefault,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AiConfigurationModel.fromMap(Map<String, dynamic> map) =>
      AiConfigurationModel(
        id: map['id'] as String,
        providerKey: map['providerKey'] as String,
        modelName: map['modelName'] as String,
        isDefault: map['isDefault'] as bool,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
