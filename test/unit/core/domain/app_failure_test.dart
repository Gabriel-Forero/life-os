import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/domain/app_failure.dart';
import 'package:life_os/core/domain/result.dart';

void main() {
  group('AppFailure sealed classes', () {
    test('DatabaseFailure has both messages', () {
      const failure = DatabaseFailure(
        userMessage: 'Error al guardar',
        debugMessage: 'SQLite constraint violation',
      );
      expect(failure.userMessage, isNotEmpty);
      expect(failure.debugMessage, isNotEmpty);
    });

    test('ValidationFailure includes field', () {
      const failure = ValidationFailure(
        userMessage: 'Campo obligatorio',
        debugMessage: 'userName required',
        field: 'userName',
      );
      expect(failure.field, 'userName');
    });

    test('BackupFailure includes phase', () {
      const failure = BackupFailure(
        userMessage: 'Error exportando',
        debugMessage: 'ZIP failed',
        phase: 'export',
      );
      expect(failure.phase, 'export');
    });

    test('equality works for same values', () {
      const f1 = AuthFailure(
        userMessage: 'Auth failed',
        debugMessage: 'biometric error',
      );
      const f2 = AuthFailure(
        userMessage: 'Auth failed',
        debugMessage: 'biometric error',
      );
      expect(f1, equals(f2));
    });

    test('exhaustive pattern matching works', () {
      const AppFailure failure = DatabaseFailure(
        userMessage: 'Error',
        debugMessage: 'debug',
      );

      final message = switch (failure) {
        DatabaseFailure() => 'db',
        NetworkFailure() => 'net',
        ValidationFailure() => 'val',
        NotFoundFailure() => 'nf',
        PermissionFailure() => 'perm',
        BackupFailure() => 'bkp',
        AuthFailure() => 'auth',
      };
      expect(message, 'db');
    });
  });

  group('Result<T>', () {
    test('Success holds value', () {
      const result = Success(42);
      expect(result.isSuccess, true);
      expect(result.valueOrNull, 42);
    });

    test('Failure holds failure', () {
      const result = Failure<int>(
        ValidationFailure(
          userMessage: 'Error',
          debugMessage: 'debug',
        ),
      );
      expect(result.isFailure, true);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('when dispatches correctly', () {
      const Result<int> success = Success(10);
      final value = success.when(
        success: (v) => v * 2,
        failure: (_) => -1,
      );
      expect(value, 20);
    });

    test('map transforms success', () {
      const Result<int> success = Success(5);
      final mapped = success.map((v) => v.toString());
      expect(mapped.valueOrNull, '5');
    });

    test('map preserves failure', () {
      const Result<int> failure = Failure(
        ValidationFailure(
          userMessage: 'Error',
          debugMessage: 'debug',
        ),
      );
      final mapped = failure.map((v) => v.toString());
      expect(mapped.isFailure, true);
    });
  });
}
