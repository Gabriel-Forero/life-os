class HabitModel {
  const HabitModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.frequencyType,
    required this.weeklyTarget,
    this.customDays,
    required this.isQuantitative,
    this.quantitativeTarget,
    this.quantitativeUnit,
    this.reminderTime,
    this.linkedEvent,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String icon;
  final int color;
  final String frequencyType; // daily, weekly, custom
  final int weeklyTarget;
  final String? customDays; // JSON list of weekday ints
  final bool isQuantitative;
  final double? quantitativeTarget;
  final String? quantitativeUnit;
  final String? reminderTime; // "HH:mm"
  final String? linkedEvent;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'frequencyType': frequencyType,
        'weeklyTarget': weeklyTarget,
        'customDays': customDays,
        'isQuantitative': isQuantitative,
        'quantitativeTarget': quantitativeTarget,
        'quantitativeUnit': quantitativeUnit,
        'reminderTime': reminderTime,
        'linkedEvent': linkedEvent,
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory HabitModel.fromMap(Map<String, dynamic> map) => HabitModel(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String? ?? 'check_circle',
        color: map['color'] as int? ?? 0xFF8B5CF6,
        frequencyType: map['frequencyType'] as String,
        weeklyTarget: map['weeklyTarget'] as int? ?? 1,
        customDays: map['customDays'] as String?,
        isQuantitative: map['isQuantitative'] as bool? ?? false,
        quantitativeTarget: (map['quantitativeTarget'] as num?)?.toDouble(),
        quantitativeUnit: map['quantitativeUnit'] as String?,
        reminderTime: map['reminderTime'] as String?,
        linkedEvent: map['linkedEvent'] as String?,
        isArchived: map['isArchived'] as bool? ?? false,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}
