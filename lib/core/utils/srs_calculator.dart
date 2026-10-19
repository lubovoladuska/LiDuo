import 'dart:math';

/// Оценка качества ответа при интервальном повторении (SRS)
enum SrsGrade {
  again, // 1: Забыл, повторить сегодня
  hard,  // 2: Вспомнил с трудом
  good,  // 3: Вспомнил нормально (стандарт)
  easy,  // 4: Ответил мгновенно и легко
}

/// Результат пересчета интервала повторения карточки
class SrsCalculationResult {
  final int repetition;
  final int intervalDays;
  final double easeFactor;
  final DateTime nextReviewDate;

  const SrsCalculationResult({
    required this.repetition,
    required this.intervalDays,
    required this.easeFactor,
    required this.nextReviewDate,
  });
}

/// Калькулятор интервальных повторений на базе алгоритма SuperMemo SM-2
class SrsCalculator {
  static const double initialEaseFactor = 2.5;
  static const double minEaseFactor = 1.3;

  /// Рассчитывает следующий интервал карточки на основе предыдущего состояния и оценки
  static SrsCalculationResult calculateNextReview({
    required int currentRepetition,
    required int currentIntervalDays,
    required double currentEaseFactor,
    required SrsGrade grade,
    DateTime? fromDate,
  }) {
    final now = fromDate ?? DateTime.now();

    int nextRepetition = currentRepetition;
    int nextInterval = currentIntervalDays;
    double nextEaseFactor = currentEaseFactor;

    switch (grade) {
      case SrsGrade.again:
        // Сброс прогресса
        nextRepetition = 0;
        nextInterval = 1;
        nextEaseFactor = max(minEaseFactor, currentEaseFactor - 0.2);
        break;

      case SrsGrade.hard:
        // Вспомнил с трудом: интервал растет медленно
        nextRepetition = currentRepetition + 1;
        nextInterval = (currentIntervalDays * 1.2).round().clamp(1, 9999);
        nextEaseFactor = max(minEaseFactor, currentEaseFactor - 0.15);
        break;

      case SrsGrade.good:
        // Нормальный ответ
        if (currentRepetition == 0) {
          nextInterval = 1;
        } else if (currentRepetition == 1) {
          nextInterval = 6;
        } else {
          nextInterval = (currentIntervalDays * currentEaseFactor).round();
        }
        nextRepetition = currentRepetition + 1;
        // Ease factor слегка корректируется
        nextEaseFactor = max(minEaseFactor, currentEaseFactor);
        break;

      case SrsGrade.easy:
        // Легкий ответ
        if (currentRepetition == 0) {
          nextInterval = 4;
        } else if (currentRepetition == 1) {
          nextInterval = 8;
        } else {
          nextInterval = (currentIntervalDays * currentEaseFactor * 1.3).round();
        }
        nextRepetition = currentRepetition + 1;
        nextEaseFactor = currentEaseFactor + 0.15;
        break;
    }

    final nextReviewDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: nextInterval));

    return SrsCalculationResult(
      repetition: nextRepetition,
      intervalDays: nextInterval,
      easeFactor: nextEaseFactor,
      nextReviewDate: nextReviewDate,
    );
  }
}
