import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:life_os/core/domain/notification_config.dart';
import 'package:life_os/core/services/app_logger.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationScheduler {
  NotificationScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    AppLogger? logger,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _logger = logger ?? AppLogger(tag: 'NotificationScheduler');

  final FlutterLocalNotificationsPlugin _plugin;
  final AppLogger _logger;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    _initialized = true;
    _logger.info('Notification scheduler initialized');
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lifeos_reminders',
          'LifeOS Reminders',
          channelDescription: 'Recordatorios y alertas de LifeOS',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    _logger.info('Scheduled notification $id for $tzDate');
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
    _logger.info('Cancelled notification $id');
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    _logger.info('Cancelled all notifications');
  }

  Future<void> showImmediate({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lifeos_reminders',
          'LifeOS Reminders',
          channelDescription: 'Recordatorios y alertas de LifeOS',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  int notificationId(NotificationType type, [int offset = 0]) =>
      type.index * 100 + offset;
}
