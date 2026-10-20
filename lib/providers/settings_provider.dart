import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_partner_service.dart';
import '../services/tts_service.dart';

/// Провайдер настроек приложения (тема, язык меню, озвучка, API-ключи)
class SettingsProvider extends ChangeNotifier {
  static const String _prefThemeMode = 'app_theme_mode';
  static const String _prefSpeechRate = 'app_speech_rate';
  static const String _prefShowKazakhSubtitles = 'app_show_kazakh_subtitles';
  static const String _prefTtsEnabled = 'app_tts_enabled';

  ThemeMode _themeMode = ThemeMode.dark;
  double _speechRate = 0.85;
  bool _showKazakhSubtitles = true;
  bool _ttsEnabled = false;
  String _geminiApiKey = '';
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  double get speechRate => _speechRate;
  bool get showKazakhSubtitles => _showKazakhSubtitles;
  bool get ttsEnabled => _ttsEnabled;
  String get geminiApiKey => _geminiApiKey;
  bool get isLoaded => _isLoaded;
  bool get isDark => _themeMode == ThemeMode.dark;

  /// Формирование двуязычного или одноязычного заголовка меню в зависимости от настроек
  String label(String ru, [String? kk]) {
    if (kk == null || !_showKazakhSubtitles || kk.trim().isEmpty) return ru;
    return '$ru ($kk)';
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final themeStr = prefs.getString(_prefThemeMode) ?? 'dark';
      if (themeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.dark;
      }

      _speechRate = prefs.getDouble(_prefSpeechRate) ?? 0.85;
      _showKazakhSubtitles = prefs.getBool(_prefShowKazakhSubtitles) ?? true;
      _ttsEnabled = prefs.getBool(_prefTtsEnabled) ?? false;
      TtsService.instance.setEnabled(_ttsEnabled);
      await TtsService.instance.setSpeechRate(_speechRate);

      _geminiApiKey = await AiPartnerService.instance.getApiKey() ?? '';
    } catch (_) {
      // Fallback defaults on desktop initialization issues
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefThemeMode,
      _themeMode == ThemeMode.light ? 'light' : 'dark',
    );
    notifyListeners();
  }

  Future<void> setShowKazakhSubtitles(bool value) async {
    _showKazakhSubtitles = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefShowKazakhSubtitles, value);
    notifyListeners();
  }

  Future<void> setTtsEnabled(bool value) async {
    _ttsEnabled = value;
    TtsService.instance.setEnabled(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefTtsEnabled, value);
    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefSpeechRate, rate);
    await TtsService.instance.setSpeechRate(rate);
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String key) async {
    _geminiApiKey = key;
    await AiPartnerService.instance.saveApiKey(key);
    notifyListeners();
  }
}
