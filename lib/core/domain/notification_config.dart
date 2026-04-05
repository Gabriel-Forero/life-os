import 'package:flutter/material.dart';

enum NotificationType {
  habitReminder,
  budgetAlert,
  waterReminder,
  sleepBedtime,
  recurringTransaction,
}

enum RepeatRule { daily, interval, eventDriven }

class NotificationConfig {
  const NotificationConfig({
    required this.type,
    required this.enabled,
    this.time,
    required this.repeatRule,
  });

  factory NotificationConfig.fromJson(
    NotificationType type,
    Map<String, dynamic> json,
  ) {
    TimeOfDay? time;
    if (json['time'] != null && json['time'] is String) {
      final parts = (json['time'] as String).split(':');
      if (parts.length == 2) {
        time = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    return NotificationConfig(
      type: type,
      enabled: json['enabled'] as bool? ?? false,
      time: time,
      repeatRule: RepeatRule.values.firstWhere(
        (r) => r.name == json['repeatRule'],
        orElse: () => RepeatRule.daily,
      ),
    );
  }

  final NotificationType type;
  final bool enabled;
  final TimeOfDay? time;
  final RepeatRule repeatRule;

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'time': time != null
            ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
            : null,
        'repeatRule': repeatRule.name,
      };

  NotificationConfig copyWith({
    bool? enabled,
    TimeOfDay? time,
    RepeatRule? repeatRule,
  }) =>
      NotificationConfig(
        type: type,
        enabled: enabled ?? this.enabled,
        time: time ?? this.time,
        repeatRule: repeatRule ?? this.repeatRule,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationConfig &&
          other.type == type &&
          other.enabled == enabled &&
          other.time == time &&
          other.repeatRule == repeatRule;

  @override
  int get hashCode => Object.hash(type, enabled, time, repeatRule);

  static Map<NotificationType, NotificationConfig> get defaults => {
        NotificationType.habitReminder: const NotificationConfig(
          type: NotificationType.habitReminder,
          enabled: false,
          time: TimeOfDay(hour: 9, minute: 0),
          repeatRule: RepeatRule.daily,
        ),
        NotificationType.budgetAlert: const NotificationConfig(
          type: NotificationType.budgetAlert,
          enabled: false,
          repeatRule: RepeatRule.eventDriven,
        ),
        NotificationType.waterReminder: const NotificationConfig(
          type: NotificationType.waterReminder,
          enabled: false,
          time: TimeOfDay(hour: 8, minute: 0),
          repeatRule: RepeatRule.interval,
        ),
        NotificationType.sleepBedtime: const NotificationConfig(
          type: NotificationType.sleepBedtime,
          enabled: false,
          time: TimeOfDay(hour: 22, minute: 0),
          repeatRule: RepeatRule.daily,
        ),
        NotificationType.recurringTransaction: const NotificationConfig(
          type: NotificationType.recurringTransaction,
          enabled: false,
          time: TimeOfDay(hour: 8, minute: 0),
          repeatRule: RepeatRule.daily,
        ),
      };
}
