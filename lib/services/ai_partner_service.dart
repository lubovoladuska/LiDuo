import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Модель сообщения в диалоге с ИИ-партнером
class AiChatMessage {
  final String text;
  final bool isUser;
  final String? correction;
  final String? translationRu;
  final DateTime timestamp;

  const AiChatMessage({
    required this.text,
    required this.isUser,
    this.correction,
    this.translationRu,
    required this.timestamp,
  });
}

/// Сервис для интерактивных ролевых диалогов с ИИ-партнером (Gemini Flash)
class AiPartnerService {
  static final AiPartnerService instance = AiPartnerService._init();
  static const String _prefApiKey = 'gemini_api_key';

  GenerativeModel? _model;
  ChatSession? _chatSession;
  String? _currentApiKey;

  AiPartnerService._init();

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_prefApiKey);
      if (key != null && key.isNotEmpty && key != _currentApiKey) {
        _currentApiKey = key;
        _initModel(key);
      }
    } catch (_) {}
  }

  void _initModel(String apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system('''
Сен — мейірімді, шыдамды және көмектескісі келетін қазақ тілі мұғалімі мен доссың.
Тіл үйренуші саған қазақша жазады немесе сөйлейді.
Сенің міндетің:
1. Қазақша қысқа, анық және қарапайым (A1-B1) сөйлемдермен жауап беру.
2. Егер пайдаланушы грамматикалық немесе фонетикалық қате жіберсе, жауабыңның соңында жақшада сыпайы ғана дұрыс нұсқасын және орысша аудармасын көрсет:
Формат: [Түзету: ..., Аударма: ...]
3. Әңгімені жалғастыру үшін әрқашан қарапайым бір сұрақ қой.
'''),
    );
    _chatSession = _model!.startChat();
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefApiKey, key.trim());
    _currentApiKey = key.trim();
    if (key.trim().isNotEmpty) {
      _initModel(key.trim());
    } else {
      _model = null;
      _chatSession = null;
    }
  }

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefApiKey);
  }

  bool get hasApiKey => _model != null && _chatSession != null;

  Future<String> sendMessage(String userText) async {
    if (!hasApiKey) {
      // Имитационный режим для демонстрации без ключа API
      await Future.delayed(const Duration(milliseconds: 600));
      return 'Сәлеметсіз бе! Мен сізді жақсы түсіндім. Қазақ тілін бірге үйренейік! Бүгін күніңіз қалай өтті?';
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(userText));
      return response.text ?? 'Кешіріңіз, қайталап жібересіз бе?';
    } catch (e) {
      return 'Қате орын алды: Интернет байланысын немесе API кілтін тексеріңіз ($e)';
    }
  }
}
