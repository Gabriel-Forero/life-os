import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/core/database/app_database.dart';
import 'package:life_os/core/database/daos/app_settings_dao.dart';
import 'package:life_os/core/services/accessibility_service.dart';
import 'package:life_os/core/services/app_logger.dart';
import 'package:life_os/core/services/backup_engine.dart';
import 'package:life_os/core/services/biometric_service.dart';
import 'package:life_os/core/services/event_bus.dart';
import 'package:life_os/core/services/haptic_service.dart';
import 'package:life_os/core/services/notification_scheduler.dart';
import 'package:life_os/core/services/secure_storage_service.dart';
import 'package:path_provider/path_provider.dart';

// Database
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(
    LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}${Platform.pathSeparator}life_os.sqlite';
      return NativeDatabase.createInBackground(File(path));
    }),
  );
  ref.onDispose(db.close);
  return db;
});

final appSettingsDaoProvider = Provider<AppSettingsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.appSettingsDao;
});

// Services
final eventBusProvider = Provider<EventBus>((ref) {
  final eventBus = EventBus();
  ref.onDispose(eventBus.dispose);
  return eventBus;
});

final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger());

final biometricServiceProvider =
    Provider<BiometricService>((ref) => BiometricService());

final secureStorageServiceProvider =
    Provider<SecureStorageService>((ref) => SecureStorageService());

final notificationSchedulerProvider =
    Provider<NotificationScheduler>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return NotificationScheduler(logger: logger);
});

final accessibilityServiceProvider =
    Provider<AccessibilityService>((ref) => AccessibilityService());

final hapticServiceProvider =
    Provider<HapticService>((ref) => HapticService());

final backupEngineProvider = Provider<BackupEngine>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return BackupEngine(logger: logger);
});
