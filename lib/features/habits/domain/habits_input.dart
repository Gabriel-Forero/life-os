class HabitInput {
  const HabitInput({
    required this.name,
    this.icon = 'check_circle',
    this.color = 0xFF8B5CF6,
    required this.frequencyType,
    this.weeklyTarget = 1,
    this.customDays,
    this.isQuantitative = false,
    this.quantitativeTarget,
    this.quantitativeUnit,
    this.reminderTime,
    this.linkedEvent,
  });

  final String name;
  final String icon;
  final int color;
  final String frequencyType;
  final int weeklyTarget;
  final List<int>? customDays;
  final bool isQuantitative;
  final double? quantitativeTarget;
  final String? quantitativeUnit;
  final String? reminderTime;
  final String? linkedEvent;
}
