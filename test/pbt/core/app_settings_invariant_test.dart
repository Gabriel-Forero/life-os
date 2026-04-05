import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/domain/app_event.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/validators.dart';

import '../generators/app_event_generator.dart';
import '../generators/app_settings_generator.dart';

void main() {
  group('INV-01: AppSettings field constraints', () {
    test('all generated settings have valid fields for 200 samples', () {
      for (final settings in AppSettingsGen.generateMany(200)) {
        final language = settings['language'] as String;
        expect(
          validLanguages.contains(language),
          isTrue,
          reason: 'Invalid language: $language',
        );

        final currency = settings['currency'] as String;
        expect(
          supportedCurrencies.contains(currency),
          isTrue,
          reason: 'Invalid currency: $currency',
        );

        final modules = settings['enabledModules'] as List<String>;
        expect(
          modules.isNotEmpty,
          isTrue,
          reason: 'enabledModules must not be empty',
        );
        for (final m in modules) {
          expect(
            validModuleIds.contains(m),
            isTrue,
            reason: 'Invalid module: $m',
          );
        }

        final goal = settings['primaryGoal'] as String;
        expect(
          validPrimaryGoals.contains(goal),
          isTrue,
          reason: 'Invalid goal: $goal',
        );
      }
    });
  });

  group('INV-03: AppEvent.timestamp is never in the future', () {
    test('for 200 generated events', () {
      for (final event in AppEventGen.generateMany(200)) {
        final now = DateTime.now();
        expect(
          event.timestamp.isBefore(now) ||
              event.timestamp.isAtSameMomentAs(now) ||
              event.timestamp.difference(now).inMilliseconds < 100,
          isTrue,
          reason:
              'Event timestamp ${event.timestamp} should not be in the future',
        );
      }
    });
  });

  group('INV-04: Every AppFailure has non-empty messages', () {
    test('DatabaseFailure', () {
      const f = DatabaseFailure(
        userMessage: 'Error',
        debugMessage: 'debug',
      );
      expect(f.userMessage.isNotEmpty, isTrue);
      expect(f.debugMessage.isNotEmpty, isTrue);
    });

    test('NetworkFailure', () {
      const f = NetworkFailure(
        userMessage: 'Sin conexion',
        debugMessage: 'timeout',
      );
      expect(f.userMessage.isNotEmpty, isTrue);
      expect(f.debugMessage.isNotEmpty, isTrue);
    });

    test('ValidationFailure', () {
      const f = ValidationFailure(
        userMessage: 'Campo requerido',
        debugMessage: 'field was null',
      );
      expect(f.userMessage.isNotEmpty, isTrue);
      expect(f.debugMessage.isNotEmpty, isTrue);
    });

    test('NotFoundFailure', () {
      const f = NotFoundFailure(
        userMessage: 'No encontrado',
        debugMessage: 'id=42',
        entityType: 'Transaction',
        entityId: 42,
      );
      expect(f.userMessage.isNotEmpty, isTrue);
      expect(f.debugMessage.isNotEmpty, isTrue);
    });

    test('PermissionFailure', () {
      const f = PermissionFailure(
        userMessage: 'Permiso requerido',
        debugMessage: 'notification denied',
        permission: 'notification',
      );
      expect(f.userMessage.isNotEmpty, isTrue);
      expect(f.debugMessage.isNotEmpty, isTrue);
    });

    test('BackupFailure', () {
      const f = BackupFailure(
        userMessage: 'Error exportando',
        debugMessage: 'OOM',
        phase: 'export',
      );
      expect(f.userMessage.isNotEmpty, isTrue);
      expect(f.debugMessage.isNotEmpty, isTrue);
    });

    test('AuthFailure', () {
      const f = AuthFailure(
        userMessage: 'Auth fallida',
        debugMessage: 'biometric error',
      );
      expect(f.userMessage.isNotEmpty, isTrue);
      expect(f.debugMessage.isNotEmpty, isTrue);
    });
  });
}
