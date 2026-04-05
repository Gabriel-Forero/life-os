import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/core/domain/validators.dart';

void main() {
  group('validateRequired', () {
    test('rejects null', () {
      final result = validateRequired(null, field: 'test');
      expect(result, isA<Failure<String>>());
    });

    test('rejects empty string', () {
      final result = validateRequired('', field: 'test');
      expect(result, isA<Failure<String>>());
    });

    test('rejects whitespace only', () {
      final result = validateRequired('   ', field: 'test');
      expect(result, isA<Failure<String>>());
    });

    test('accepts valid string and trims it', () {
      final result = validateRequired('  hello  ', field: 'test');
      expect(result, isA<Success<String>>());
      expect(result.valueOrNull, 'hello');
    });
  });

  group('validateMaxLength', () {
    test('rejects string over max', () {
      final result = validateMaxLength(
        'a' * 51,
        maxLength: 50,
        field: 'test',
      );
      expect(result, isA<Failure<String>>());
    });

    test('accepts string at max length', () {
      final result = validateMaxLength(
        'a' * 50,
        maxLength: 50,
        field: 'test',
      );
      expect(result, isA<Success<String>>());
    });
  });

  group('validateUserName', () {
    test('rejects null', () {
      expect(validateUserName(null), isA<Failure<String>>());
    });

    test('rejects empty', () {
      expect(validateUserName(''), isA<Failure<String>>());
    });

    test('rejects over 50 chars', () {
      expect(validateUserName('a' * 51), isA<Failure<String>>());
    });

    test('accepts valid name', () {
      final result = validateUserName('Camila');
      expect(result, isA<Success<String>>());
      expect(result.valueOrNull, 'Camila');
    });

    test('trims whitespace', () {
      final result = validateUserName('  Maria Jose  ');
      expect(result.valueOrNull, 'Maria Jose');
    });

    test('accepts accented characters', () {
      final result = validateUserName('Andres');
      expect(result, isA<Success<String>>());
    });
  });

  group('validateLanguage', () {
    test('accepts es', () {
      expect(validateLanguage('es'), isA<Success<String>>());
    });

    test('accepts en', () {
      expect(validateLanguage('en'), isA<Success<String>>());
    });

    test('rejects other', () {
      expect(validateLanguage('fr'), isA<Failure<String>>());
    });
  });

  group('validateCurrencyCode', () {
    test('accepts COP', () {
      expect(validateCurrencyCode('COP'), isA<Success<String>>());
    });

    test('accepts lowercase and converts', () {
      final result = validateCurrencyCode('usd');
      expect(result, isA<Success<String>>());
      expect(result.valueOrNull, 'USD');
    });

    test('rejects unknown currency', () {
      expect(validateCurrencyCode('XYZ'), isA<Failure<String>>());
    });
  });

  group('validatePrimaryGoal', () {
    test('accepts save_money', () {
      expect(validatePrimaryGoal('save_money'), isA<Success<String>>());
    });

    test('rejects invalid goal', () {
      expect(validatePrimaryGoal('win_lottery'), isA<Failure<String>>());
    });
  });

  group('validateEnabledModules', () {
    test('rejects empty list', () {
      expect(validateEnabledModules([]), isA<Failure<List<String>>>());
    });

    test('rejects invalid module id', () {
      expect(
        validateEnabledModules(['finance', 'invalid']),
        isA<Failure<List<String>>>(),
      );
    });

    test('accepts valid module list', () {
      final result = validateEnabledModules(['finance', 'gym']);
      expect(result, isA<Success<List<String>>>());
    });
  });

  group('validateNumericRange', () {
    test('accepts value in range', () {
      expect(
        validateNumericRange(50, min: 0, max: 100, field: 'test'),
        isA<Success<num>>(),
      );
    });

    test('rejects below min', () {
      expect(
        validateNumericRange(-1, min: 0, max: 100, field: 'test'),
        isA<Failure<num>>(),
      );
    });

    test('rejects above max', () {
      expect(
        validateNumericRange(101, min: 0, max: 100, field: 'test'),
        isA<Failure<num>>(),
      );
    });
  });

  group('validateCurrency', () {
    test('rejects zero', () {
      expect(validateCurrency(0, field: 'amount'), isA<Failure<double>>());
    });

    test('rejects negative', () {
      expect(
        validateCurrency(-5.0, field: 'amount'),
        isA<Failure<double>>(),
      );
    });

    test('accepts positive value', () {
      expect(
        validateCurrency(100.5, field: 'amount'),
        isA<Success<double>>(),
      );
    });
  });
}
