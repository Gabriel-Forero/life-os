import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/core/domain/result.dart';
import 'package:life_os/features/gym/domain/gym_validators.dart';

void main() {
  group('validateExerciseName', () {
    test('rejects empty', () {
      expect(validateExerciseName(''), isA<Failure<String>>());
    });
    test('rejects over 100 chars', () {
      expect(validateExerciseName('a' * 101), isA<Failure<String>>());
    });
    test('accepts valid', () {
      expect(validateExerciseName('Press de banca'), isA<Success<String>>());
    });
    test('trims whitespace', () {
      expect(validateExerciseName('  Curl  ').valueOrNull, 'Curl');
    });
  });

  group('validateReps', () {
    test('rejects zero', () {
      expect(validateReps(0), isA<Failure<int>>());
    });
    test('rejects negative', () {
      expect(validateReps(-1), isA<Failure<int>>());
    });
    test('accepts positive', () {
      expect(validateReps(10), isA<Success<int>>());
    });
  });

  group('validateWeight', () {
    test('accepts null (bodyweight)', () {
      expect(validateWeight(null), isA<Success<double?>>());
    });
    test('rejects negative', () {
      expect(validateWeight(-5.0), isA<Failure<double?>>());
    });
    test('rejects zero', () {
      expect(validateWeight(0.0), isA<Failure<double?>>());
    });
    test('accepts positive', () {
      expect(validateWeight(80.0), isA<Success<double?>>());
    });
  });

  group('validateRIR', () {
    test('accepts null', () {
      expect(validateRIR(null), isA<Success<int?>>());
    });
    test('rejects negative', () {
      expect(validateRIR(-1), isA<Failure<int?>>());
    });
    test('rejects above 5', () {
      expect(validateRIR(6), isA<Failure<int?>>());
    });
    test('accepts 0-5', () {
      for (var i = 0; i <= 5; i++) {
        expect(validateRIR(i), isA<Success<int?>>());
      }
    });
  });

  group('validateRoutineName', () {
    test('rejects empty', () {
      expect(validateRoutineName(''), isA<Failure<String>>());
    });
    test('rejects over 50 chars', () {
      expect(validateRoutineName('a' * 51), isA<Failure<String>>());
    });
    test('accepts valid', () {
      expect(validateRoutineName('Push Day'), isA<Success<String>>());
    });
  });

  group('calculate1RM', () {
    test('returns weight for 1 rep', () {
      expect(calculate1RM(100.0, 1), 100.0);
    });
    test('applies Epley for multiple reps', () {
      // 80 * (1 + 10/30) = 80 * 1.333 = 106.67
      expect(calculate1RM(80.0, 10), closeTo(106.67, 0.01));
    });
    test('returns null for 0 reps', () {
      expect(calculate1RM(80.0, 0), isNull);
    });
    test('returns null for null weight', () {
      expect(calculate1RM(null, 10), isNull);
    });
  });

  group('convertWeight', () {
    test('kg to lbs', () {
      expect(kgToLbs(100.0), closeTo(220.46, 0.01));
    });
    test('lbs to kg', () {
      expect(lbsToKg(220.46), closeTo(100.0, 0.01));
    });
    test('round trip kg→lbs→kg', () {
      expect(lbsToKg(kgToLbs(75.5)), closeTo(75.5, 0.01));
    });
  });
}
