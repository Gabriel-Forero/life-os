import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger({this.tag = 'LifeOS'});

  final String tag;

  static final _piiPatterns = [
    RegExp(r'\b[\w.+-]+@[\w-]+\.[\w.-]+\b'),
    RegExp(r'\b\d{10,}\b'),
  ];

  void debug(String message) => _log(LogLevel.debug, message);
  void info(String message) => _log(LogLevel.info, message);
  void warning(String message) => _log(LogLevel.warning, message);

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message);
    if (kDebugMode && stackTrace != null) {
      developer.log(
        'STACK: $stackTrace',
        name: tag,
        level: 1000,
      );
    }
  }

  void security(String message) {
    _log(LogLevel.info, '[SECURITY] $message');
  }

  void _log(LogLevel level, String message) {
    if (!kDebugMode && (level == LogLevel.debug || level == LogLevel.info)) {
      return;
    }

    final sanitized = _scrubPii(message);
    final timestamp = DateTime.now().toIso8601String();
    final logLine = '[$timestamp] [${level.name.toUpperCase()}] [$tag] $sanitized';

    developer.log(
      logLine,
      name: tag,
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      },
    );
  }

  static String _scrubPii(String message) {
    var result = message;
    for (final pattern in _piiPatterns) {
      result = result.replaceAll(pattern, '[REDACTED]');
    }
    return result;
  }
}
