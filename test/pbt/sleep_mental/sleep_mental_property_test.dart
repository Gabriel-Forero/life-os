import 'package:flutter_test/flutter_test.dart';
import 'package:life_os/features/mental/domain/mental_validators.dart';
import 'package:life_os/features/sleep/domain/sleep_validators.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Property-based tests for sleep score
  // ---------------------------------------------------------------------------

  group('sleepScore — properties', () {
    test('score is always in [0, 100] for any valid inputs', () {
      // Exhaustively test all combinations in valid ranges
      for (var quality = 1; quality <= 5; quality++) {
        for (var interruptions = 0; interruptions <= 20; interruptions++) {
          for (final hours in [0.5, 1.0, 2.0, 4.0, 6.0, 7.5, 8.0, 9.0, 12.0]) {
            final score = calculateSleepScore(
              hoursSlept: hours,
              qualityRating: quality,
              interruptionCount: interruptions,
            );
            expect(
              score,
              inInclusiveRange(0, 100),
              reason:
                  'score=$score out of range for hours=$hours, quality=$quality, interruptions=$interruptions',
            );
          }
        }
      }
    });

    test('score is monotonically non-decreasing with quality rating', () {
      for (var q = 1; q < 5; q++) {
        final lower = calculateSleepScore(
          hoursSlept: 8,
          qualityRating: q,
          interruptionCount: 0,
        );
        final higher = calculateSleepScore(
          hoursSlept: 8,
          qualityRating: q + 1,
          interruptionCount: 0,
        );
        expect(
          higher,
          greaterThanOrEqualTo(lower),
          reason: 'quality $q → ${q + 1}: score should not decrease',
        );
      }
    });

    test('score is monotonically non-increasing with interruption count', () {
      for (var i = 0; i < 10; i++) {
        final lower = calculateSleepScore(
          hoursSlept: 8,
          qualityRating: 5,
          interruptionCount: i,
        );
        final higher = calculateSleepScore(
          hoursSlept: 8,
          qualityRating: 5,
          interruptionCount: i + 1,
        );
        expect(
          lower,
          greaterThanOrEqualTo(higher),
          reason: 'interruptions $i → ${i + 1}: score should not increase',
        );
      }
    });

    test('score is monotonically non-decreasing with sleep duration', () {
      final durations = [0.5, 1.0, 2.0, 4.0, 6.0, 7.0, 8.0, 9.0];
      for (var i = 0; i < durations.length - 1; i++) {
        final lower = calculateSleepScore(
          hoursSlept: durations[i],
          qualityRating: 3,
          interruptionCount: 0,
        );
        final higher = calculateSleepScore(
          hoursSlept: durations[i + 1],
          qualityRating: 3,
          interruptionCount: 0,
        );
        expect(
          higher,
          greaterThanOrEqualTo(lower),
          reason:
              'hours ${durations[i]} → ${durations[i + 1]}: score should not decrease',
        );
      }
    });

    test('perfect inputs yield score of 100', () {
      final score = calculateSleepScore(
        hoursSlept: 8,
        qualityRating: 5,
        interruptionCount: 0,
      );
      expect(score, 100);
    });

    test('capping duration at 8h: 10h and 8h yield same score', () {
      final at8 = calculateSleepScore(
        hoursSlept: 8,
        qualityRating: 3,
        interruptionCount: 0,
      );
      final at10 = calculateSleepScore(
        hoursSlept: 10,
        qualityRating: 3,
        interruptionCount: 0,
      );
      expect(at10, equals(at8));
    });
  });

  // ---------------------------------------------------------------------------
  // Property-based tests for mood score
  // ---------------------------------------------------------------------------

  group('moodScore — properties', () {
    test('score is always in [0, 100] for all valid inputs', () {
      for (var v = 1; v <= 5; v++) {
        for (var e = 1; e <= 5; e++) {
          final score = calculateMoodScore(valence: v, energy: e);
          expect(
            score,
            inInclusiveRange(0, 100),
            reason: 'moodScore=$score out of range for v=$v, e=$e',
          );
        }
      }
    });

    test('score increases with valence (energy constant)', () {
      for (var v = 1; v < 5; v++) {
        final lower = calculateMoodScore(valence: v, energy: 3);
        final higher = calculateMoodScore(valence: v + 1, energy: 3);
        expect(
          higher,
          greaterThanOrEqualTo(lower),
          reason: 'valence $v → ${v + 1}: mood score should not decrease',
        );
      }
    });

    test('score increases with energy (valence constant)', () {
      for (var e = 1; e < 5; e++) {
        final lower = calculateMoodScore(valence: 3, energy: e);
        final higher = calculateMoodScore(valence: 3, energy: e + 1);
        expect(
          higher,
          greaterThanOrEqualTo(lower),
          reason: 'energy $e → ${e + 1}: mood score should not decrease',
        );
      }
    });

    test('score is symmetric: swapping valence and energy yields same score', () {
      // Because formula is symmetric in v and e
      for (var v = 1; v <= 5; v++) {
        for (var e = 1; e <= 5; e++) {
          final score1 = calculateMoodScore(valence: v, energy: e);
          final score2 = calculateMoodScore(valence: e, energy: v);
          expect(
            score1,
            equals(score2),
            reason: 'score should be symmetric for v=$v, e=$e',
          );
        }
      }
    });

    test('minimum inputs (1,1) return 0', () {
      expect(calculateMoodScore(valence: 1, energy: 1), 0);
    });

    test('maximum inputs (5,5) return 100', () {
      expect(calculateMoodScore(valence: 5, energy: 5), 100);
    });
  });

  // ---------------------------------------------------------------------------
  // validateSleepTimes — properties
  // ---------------------------------------------------------------------------

  group('validateSleepTimes — properties', () {
    test('equal bedTime and wakeTime fails', () {
      final now = DateTime(2024, 1, 15, 22, 0);
      final result = validateSleepTimes(bedTime: now, wakeTime: now);
      expect(result.isFailure, isTrue);
    });

    test('wakeTime before bedTime always fails', () {
      final bed = DateTime(2024, 1, 16, 6, 0);
      final wake = DateTime(2024, 1, 15, 22, 0);
      final result = validateSleepTimes(bedTime: bed, wakeTime: wake);
      expect(result.isFailure, isTrue);
    });

    test('any duration >= 30min and <= 24h succeeds', () {
      final durations = [30, 60, 120, 480, 600, 720, 1440];
      for (final mins in durations) {
        final bed = DateTime(2024, 1, 15, 20, 0);
        final wake = bed.add(Duration(minutes: mins));
        final result = validateSleepTimes(bedTime: bed, wakeTime: wake);
        expect(
          result.isSuccess,
          isTrue,
          reason: '$mins minutes should be valid',
        );
      }
    });

    test('duration < 30min always fails', () {
      final bed = DateTime(2024, 1, 15, 22, 0);
      final wake = bed.add(const Duration(minutes: 20));
      final result = validateSleepTimes(bedTime: bed, wakeTime: wake);
      expect(result.isFailure, isTrue);
    });
  });
}
