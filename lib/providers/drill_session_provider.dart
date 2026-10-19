import 'package:flutter/foundation.dart';
import '../core/utils/kazakh_phonetics.dart';
import '../data/models/audio_drill.dart';
import '../data/models/day_lesson.dart';
import '../data/repositories/course_repository.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import 'stats_provider.dart';

enum DrillStatus {
  idle,       // Ожидание действия пользователя
  listening,  // Запись голоса с микрофона
  evaluating, // Анализ ответа
  passed,     // Ответ принят успешно
  retry,      // Требуется повторить
  finished,   // Все дриллы урока завершены
}

/// Управление активной речевой сессией аудио-дрила
class DrillSessionProvider extends ChangeNotifier {
  DayLesson? _lesson;
  int _currentDrillIndex = 0;
  DrillStatus _status = DrillStatus.idle;
  String _spokenText = '';
  double _similarityScore = 0.0;
  bool _showHint = false;
  final Stopwatch _sessionTimer = Stopwatch();

  DayLesson? get lesson => _lesson;
  int get currentDrillIndex => _currentDrillIndex;
  DrillStatus get status => _status;
  String get spokenText => _spokenText;
  double get similarityScore => _similarityScore;
  bool get showHint => _showHint;

  AudioDrill? get currentDrill {
    if (_lesson == null || _lesson!.drills.isEmpty) return null;
    if (_currentDrillIndex >= _lesson!.drills.length) return null;
    return _lesson!.drills[_currentDrillIndex];
  }

  int get totalDrills => _lesson?.drills.length ?? 0;
  double get progress => totalDrills == 0 ? 0 : (_currentDrillIndex / totalDrills);

  void startSession(DayLesson lesson) {
    _lesson = lesson;
    _currentDrillIndex = 0;
    _status = DrillStatus.idle;
    _spokenText = '';
    _similarityScore = 0.0;
    _showHint = false;
    _sessionTimer.reset();
    _sessionTimer.start();
    notifyListeners();
  }

  void toggleHint() {
    _showHint = !_showHint;
    notifyListeners();
  }

  Future<void> playTargetAudio() async {
    final drill = currentDrill;
    if (drill != null) {
      await TtsService.instance.speak(drill.targetKk);
    }
  }

  Future<void> startListening() async {
    final drill = currentDrill;
    if (drill == null) return;

    _status = DrillStatus.listening;
    _spokenText = '';
    notifyListeners();

    await SpeechService.instance.startListening(
      localeId: 'kk_KZ',
      onResult: (text) {
        _spokenText = text;
        notifyListeners();
        _evaluateSpeech(text, drill.targetKk);
      },
    );
  }

  Future<void> stopListening() async {
    await SpeechService.instance.stopListening();
    if (_status == DrillStatus.listening) {
      final drill = currentDrill;
      if (drill != null) {
        _evaluateSpeech(_spokenText, drill.targetKk);
      }
    }
  }

  void _evaluateSpeech(String spoken, String target) {
    if (spoken.trim().isEmpty) {
      _status = DrillStatus.retry;
      _similarityScore = 0.0;
      notifyListeners();
      return;
    }

    _similarityScore = KazakhPhonetics.similarity(spoken, target);
    if (KazakhPhonetics.isMatch(spoken, target)) {
      _status = DrillStatus.passed;
    } else {
      _status = DrillStatus.retry;
    }
    notifyListeners();
  }

  /// Ручное подтверждение ответа («Я сказал правильно»)
  void manualPass() {
    _status = DrillStatus.passed;
    _similarityScore = 1.0;
    notifyListeners();
  }

  /// Переход к следующему дрилу или завершение дня
  Future<void> nextDrill(StatsProvider statsProvider) async {
    if (_currentDrillIndex + 1 < totalDrills) {
      _currentDrillIndex++;
      _status = DrillStatus.idle;
      _spokenText = '';
      _similarityScore = 0.0;
      _showHint = false;
      notifyListeners();
    } else {
      // Все дриллы завершены!
      _status = DrillStatus.finished;
      _sessionTimer.stop();
      final minutesSpent = (_sessionTimer.elapsedMilliseconds / 60000).ceil().clamp(5, 60);

      if (_lesson != null) {
        // Занесение карточек в SRS
        await CourseRepository.instance.seedSrsCardsFromLesson(_lesson!);
        // Обновление статистики
        await statsProvider.onDayCompleted(
          _lesson!.dayNumber,
          totalDrills,
          minutesSpent,
        );
      }
      notifyListeners();
    }
  }
}
