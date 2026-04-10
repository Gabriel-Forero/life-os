class ExerciseModel {
  const ExerciseModel({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles,
    this.equipment,
    this.instructions,
    required this.isCustom,
    required this.isDownloaded,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String primaryMuscle;
  final String? secondaryMuscles; // JSON list
  final String? equipment;
  final String? instructions;
  final bool isCustom;
  final bool isDownloaded;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'primaryMuscle': primaryMuscle,
        'secondaryMuscles': secondaryMuscles,
        'equipment': equipment,
        'instructions': instructions,
        'isCustom': isCustom,
        'isDownloaded': isDownloaded,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ExerciseModel.fromMap(Map<String, dynamic> map) => ExerciseModel(
        id: map['id'] as String,
        name: map['name'] as String,
        primaryMuscle: map['primaryMuscle'] as String,
        secondaryMuscles: map['secondaryMuscles'] as String?,
        equipment: map['equipment'] as String?,
        instructions: map['instructions'] as String?,
        isCustom: map['isCustom'] as bool,
        isDownloaded: map['isDownloaded'] as bool,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
