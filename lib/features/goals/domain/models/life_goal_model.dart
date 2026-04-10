class LifeGoalModel {
  const LifeGoalModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.icon,
    required this.color,
    this.targetDate,
    required this.status,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String category; // salud/finanzas/carrera/personal/educacion/relaciones
  final String icon;
  final int color;
  final DateTime? targetDate;
  final String status; // active/completed/paused/abandoned
  final int progress; // 0–100
  final DateTime createdAt;
  final DateTime updatedAt;

  LifeGoalModel copyWith({
    String? name,
    Object? description = _sentinel,
    String? category,
    String? icon,
    int? color,
    Object? targetDate = _sentinel,
    String? status,
    int? progress,
    DateTime? updatedAt,
  }) =>
      LifeGoalModel(
        id: id,
        name: name ?? this.name,
        description:
            identical(description, _sentinel) ? this.description : description as String?,
        category: category ?? this.category,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        targetDate:
            identical(targetDate, _sentinel) ? this.targetDate : targetDate as DateTime?,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category,
        'icon': icon,
        'color': color,
        'targetDate': targetDate?.toIso8601String(),
        'status': status,
        'progress': progress,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory LifeGoalModel.fromMap(Map<String, dynamic> map) => LifeGoalModel(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        category: map['category'] as String,
        icon: map['icon'] as String,
        color: map['color'] as int? ?? 0xFF06B6D4,
        targetDate: map['targetDate'] != null
            ? DateTime.parse(map['targetDate'] as String)
            : null,
        status: map['status'] as String? ?? 'active',
        progress: map['progress'] as int? ?? 0,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}

const _sentinel = Object();
