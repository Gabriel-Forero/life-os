import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to get the user's next alarm time.
///
/// - Android: reads the system alarm via platform channel.
/// - iOS/fallback: reads the user-configured alarm time from SharedPreferences.
class AlarmService {
  static const _channel = MethodChannel('life_os/alarm');
  static const _prefKey = 'user_alarm_time_minutes';

  /// Returns the next alarm as a [DateTime], or null if unavailable.
  ///
  /// On Android, tries the system alarm first, falls back to saved preference.
  /// On iOS, always uses the saved preference.
  Future<DateTime?> getNextAlarm() async {
    if (Platform.isAndroid) {
      try {
        final int? millis = await _channel.invokeMethod<int>('getNextAlarm');
        if (millis != null) {
          return DateTime.fromMillisecondsSinceEpoch(millis);
        }
      } on PlatformException {
        // Fall through to saved preference.
      }
    }
    return _getSavedAlarmForTonight();
  }

  /// Returns the user-saved alarm time (hour:minute) as a DateTime for
  /// tonight/tomorrow morning. Returns null if not configured.
  Future<DateTime?> _getSavedAlarmForTonight() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt(_prefKey);
    if (minutes == null) return null;
    return _alarmDateTimeFromMinutes(minutes);
  }

  /// Converts stored minutes-since-midnight into the next occurrence of that
  /// time (tonight or tomorrow morning).
  DateTime _alarmDateTimeFromMinutes(int totalMinutes) {
    final now = DateTime.now();
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;

    // Build candidate for today
    var alarm = DateTime(now.year, now.month, now.day, hour, minute);

    // If that time already passed, it's tomorrow's alarm
    if (alarm.isBefore(now)) {
      alarm = alarm.add(const Duration(days: 1));
    }
    return alarm;
  }

  /// Saves the user's preferred alarm time (for iOS / fallback).
  /// [hour] 0-23, [minute] 0-59.
  Future<void> saveAlarmTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, hour * 60 + minute);
  }

  /// Returns the saved alarm as (hour, minute), or null if not set.
  Future<({int hour, int minute})?> getSavedAlarmTime() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt(_prefKey);
    if (minutes == null) return null;
    return (hour: minutes ~/ 60, minute: minutes % 60);
  }

  /// Clears the saved alarm time.
  Future<void> clearAlarmTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
