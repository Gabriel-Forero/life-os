import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/app.dart';
import 'package:life_os/core/services/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = AppLogger(tag: 'Main');

  FlutterError.onError = (details) {
    logger.error(
      'Flutter framework error: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error(
      'Unhandled platform error: $error',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  runApp(
    const ProviderScope(
      child: LifeOsApp(),
    ),
  );
}
