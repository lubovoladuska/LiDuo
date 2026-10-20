import 'package:flutter/foundation.dart';
import '../core/utils/srs_calculator.dart';
import '../data/database/app_database.dart';
import '../data/models/srs_card.dart';
import '../services/tts_service.dart';
import 'stats_provider.dart';

/// Провайдер сессии интервального повторения фраз (SRS)
class SrsProvider extends ChangeNotifier {
  List<SrsCard> _dueCards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = false;
  int _reviewedInThisSession = 0;

  List<SrsCard> get dueCards => _dueCards;
  int get currentIndex => _currentIndex;
  bool get isFlipped => _isFlipped;
  bool get isLoading => _isLoading;
  int get dueCount => _dueCards.length;

  SrsCard? get currentCard {
    if (_dueCards.isEmpty || _currentIndex >= _dueCards.length) return null;
    return _dueCards[_currentIndex];
  }

  Future<void> loadDueCards() async {
    _isLoading = true;
    notifyListeners();

    _dueCards = await AppDatabase.instance.getDueSrsCards(DateTime.now());
    _currentIndex = 0;
    _isFlipped = false;
    _reviewedInThisSession = 0;

    _isLoading = false;
    notifyListeners();
  }

  void flipCard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  Future<void> playAudio() async {
    if (currentCard != null) {
      await TtsService.instance.speak(currentCard!.backTarget);
    }
  }

  Future<void> rateCard(SrsGrade grade, StatsProvider statsProvider) async {
    final card = currentCard;
    if (card == null) return;

    final result = SrsCalculator.calculateNextReview(
      currentRepetition: card.repetition,
      currentIntervalDays: card.intervalDays,
      currentEaseFactor: card.easeFactor,
      grade: grade,
    );

    final updatedCard = card.copyWith(
      repetition: result.repetition,
      intervalDays: result.intervalDays,
      easeFactor: result.easeFactor,
      nextReviewDate: result.nextReviewDate,
      lastReviewedDate: DateTime.now(),
    );

    await AppDatabase.instance.upsertSrsCard(updatedCard);
    _reviewedInThisSession++;

    if (grade == SrsGrade.again) {
      // Поместить карточку в конец очереди сегодняшней сессии для закрепления
      _dueCards.add(updatedCard);
    }

    _currentIndex++;
    _isFlipped = false;

    if (_currentIndex >= _dueCards.length) {
      await statsProvider.onReviewsCompleted(_reviewedInThisSession);
    }

    notifyListeners();
  }
}
