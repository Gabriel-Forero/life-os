import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to get the user's next alarm time.
///
/// - Android: reads the system alarm via platform channel.
/// - iOS/Web/fallback: reads the user-configured alarm time from SharedPreferences.
class AlarmService {
  static const _channel = MethodChannel('life_os/alarm');
  static const _prefKey = 'user_alarm_time_minutes';

  /// Returns the next alarm as a [DateTime], or null if unavailable.
  Future<DateTime?> getNextAlarm() async {
    if (!kIsWeb) {
      try {
        final int? millis = await _channel.invokeMethod<int>('getNextAlarm');
        if (millis != null) {
          return DateTime.fromMillisecondsSinceEpoch(millis);
        }
      } on PlatformException {
        // Fall through to saved preference.
      } on MissingPluginException {
        // Platform channel not available (e.g. iOS).
      }
    }
    return _getSavedAlarmForTonight();
  }

  Future<DateTime?> _getSavedAlarmForTonight() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt(_prefKey);
    if (minutes == null) return null;
    return _alarmDateTimeFromMinutes(minutes);
  }

  DateTime _alarmDateTimeFromMinutes(int totalMinutes) {
    final now = DateTime.now();
    final hour = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    var alarm = DateTime(now.year, now.month, now.day, hour, minute);
    if (alarm.isBefore(now)) {
      alarm = alarm.add(const Duration(days: 1));
    }
    return alarm;
  }

  Future<void> saveAlarmTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, hour * 60 + minute);
  }

  Future<({int hour, int minute})?> getSavedAlarmTime() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt(_prefKey);
    if (minutes == null) return null;
    return (hour: minutes ~/ 60, minute: minutes % 60);
  }

  Future<void> clearAlarmTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
