import 'package:flutter_tts/flutter_tts.dart';

/// Сервис синтеза речи (TTS) для казахского языка
class TtsService {
  static final TtsService instance = TtsService._init();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _enabled = false;
  double _speechRate = 0.85;

  TtsService._init();

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (!enabled) {
      stop();
    }
  }

  bool get isEnabled => _enabled;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setLanguage('kk-KZ');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _isInitialized = true;
    } catch (_) {
      // Игнорируем ошибку инициализации на неподдерживаемых платформах (например в тестах)
    }
  }

  Future<void> speak(String text) async {
    if (!_enabled) return;
    if (!_isInitialized) await init();
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (_) {}
  }

  double get speechRate => _speechRate;
}
