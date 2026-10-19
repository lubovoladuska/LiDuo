import 'package:flutter_test/flutter_test.dart';
import 'package:liduo/core/utils/srs_calculator.dart';

void main() {
  group('SrsCalculator SM-2', () {
    final baseDate = DateTime(2026, 1, 1);

    test('initial first good review gives 1 day interval', () {
      final result = SrsCalculator.calculateNextReview(
        currentRepetition: 0,
        currentIntervalDays: 0,
        currentEaseFactor: 2.5,
        grade: SrsGrade.good,
        fromDate: baseDate,
      );

      expect(result.repetition, equals(1));
      expect(result.intervalDays, equals(1));
      expect(result.nextReviewDate, equals(DateTime(2026, 1, 2)));
    });

    test('second good review gives 6 days interval', () {
      final result = SrsCalculator.calculateNextReview(
        currentRepetition: 1,
        currentIntervalDays: 1,
        currentEaseFactor: 2.5,
        grade: SrsGrade.good,
        fromDate: baseDate,
      );

      expect(result.repetition, equals(2));
      expect(result.intervalDays, equals(6));
      expect(result.nextReviewDate, equals(DateTime(2026, 1, 7)));
    });

    test('third good review scales by easeFactor', () {
      final result = SrsCalculator.calculateNextReview(
        currentRepetition: 2,
        currentIntervalDays: 6,
        currentEaseFactor: 2.5,
        grade: SrsGrade.good,
        fromDate: baseDate,
      );

      expect(result.repetition, equals(3));
      expect(result.intervalDays, equals(15)); // 6 * 2.5 = 15
    });

    test('again grade resets repetition and sets interval to 1 day', () {
      final result = SrsCalculator.calculateNextReview(
        currentRepetition: 4,
        currentIntervalDays: 30,
        currentEaseFactor: 2.5,
        grade: SrsGrade.again,
        fromDate: baseDate,
      );

      expect(result.repetition, equals(0));
      expect(result.intervalDays, equals(1));
      expect(result.easeFactor, equals(2.3));
    });

    test('easy grade boosts ease factor and interval', () {
      final result = SrsCalculator.calculateNextReview(
        currentRepetition: 2,
        currentIntervalDays: 6,
        currentEaseFactor: 2.5,
        grade: SrsGrade.easy,
        fromDate: baseDate,
      );

      expect(result.repetition, equals(3));
      expect(result.easeFactor, greaterThan(2.5));
      expect(result.intervalDays, greaterThan(15));
    });
  });
}
