import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/features/finance/domain/finance_validators.dart';

void main() {
  group('validateTransactionAmount', () {
    test('rejects zero', () {
      expect(validateTransactionAmount(0), isA<Failure<int>>());
    });

    test('rejects negative', () {
      expect(validateTransactionAmount(-100), isA<Failure<int>>());
    });

    test('accepts positive', () {
      final result = validateTransactionAmount(25000);
      expect(result, isA<Success<int>>());
      expect(result.valueOrNull, 25000);
    });
  });

  group('validateTransactionType', () {
    test('accepts income', () {
      expect(validateTransactionType('income'), isA<Success<String>>());
    });

    test('accepts expense', () {
      expect(validateTransactionType('expense'), isA<Success<String>>());
    });

    test('rejects other', () {
      expect(validateTransactionType('transfer'), isA<Failure<String>>());
    });
  });

  group('validateTransactionNote', () {
    test('accepts null', () {
      expect(validateTransactionNote(null), isA<Success<String?>>());
    });

    test('accepts empty string as null', () {
      final result = validateTransactionNote('');
      expect(result, isA<Success<String?>>());
      expect(result.valueOrNull, isNull);
    });

    test('accepts valid note', () {
      final result = validateTransactionNote('Almuerzo');
      expect(result, isA<Success<String?>>());
      expect(result.valueOrNull, 'Almuerzo');
    });

    test('rejects note over 200 chars', () {
      expect(validateTransactionNote('a' * 201), isA<Failure<String?>>());
    });
  });

  group('validateTransactionDate', () {
    test('accepts past date', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(validateTransactionDate(past), isA<Success<DateTime>>());
    });

    test('accepts now', () {
      expect(validateTransactionDate(DateTime.now()), isA<Success<DateTime>>());
    });

    test('rejects future date', () {
      final future = DateTime.now().add(const Duration(days: 1));
      expect(validateTransactionDate(future), isA<Failure<DateTime>>());
    });
  });

  group('validateCategoryName', () {
    test('rejects empty', () {
      expect(validateCategoryName(''), isA<Failure<String>>());
    });

    test('rejects over 30 chars', () {
      expect(validateCategoryName('a' * 31), isA<Failure<String>>());
    });

    test('accepts valid name', () {
      final result = validateCategoryName('Mascota');
      expect(result, isA<Success<String>>());
      expect(result.valueOrNull, 'Mascota');
    });

    test('trims whitespace', () {
      final result = validateCategoryName('  Mascota  ');
      expect(result.valueOrNull, 'Mascota');
    });
  });

  group('validateBudgetAmount', () {
    test('rejects zero', () {
      expect(validateBudgetAmount(0), isA<Failure<int>>());
    });

    test('accepts positive', () {
      expect(validateBudgetAmount(500000), isA<Success<int>>());
    });
  });

  group('validateSavingsGoalTarget', () {
    test('rejects zero', () {
      expect(validateSavingsGoalTarget(0), isA<Failure<int>>());
    });

    test('accepts positive', () {
      expect(validateSavingsGoalTarget(10000000), isA<Success<int>>());
    });
  });

  group('validateSavingsGoalDeadline', () {
    test('accepts null', () {
      expect(validateSavingsGoalDeadline(null), isA<Success<DateTime?>>());
    });

    test('accepts future date', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(validateSavingsGoalDeadline(future), isA<Success<DateTime?>>());
    });

    test('rejects past date', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      expect(validateSavingsGoalDeadline(past), isA<Failure<DateTime?>>());
    });
  });
}
