import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../services/ai_partner_service.dart';
import '../../services/speech_service.dart';
import '../settings/settings_screen.dart';

/// Экран интерактивного ролевого диалога с ИИ-партнером (Gemini)
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];
  bool _isSending = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      AiChatMessage(
        text: 'Сәлеметсіз бе! Мен сіздің қазақ тіліндегі сөйлесу серігіңізбін. Қандай тақырыпта сөйлесеміз?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? textToSend]) async {
    final text = textToSend ?? _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        AiChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isSending = true;
      _textController.clear();
    });
    _scrollToBottom();

    final response = await AiPartnerService.instance.sendMessage(text);

    if (mounted) {
      setState(() {
        _messages.add(
          AiChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _toggleMic() async {
    if (_isListening) {
      await SpeechService.instance.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await SpeechService.instance.startListening(
        localeId: 'kk_KZ',
        onResult: (words) {
          _textController.text = words;
          setState(() {});
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = AiPartnerService.instance.hasApiKey;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.label('ИИ-Собеседник', 'ИИ-Сұхбаттас')),
        actions: [
          if (!hasKey)
            TextButton.icon(
              icon: const Icon(Icons.key, size: 16, color: AppColors.gold),
              label: Text(
                settings.label('API-ключ', 'API кілті'),
                style: const TextStyle(color: AppColors.gold, fontSize: 12),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Подсказка о бесплатных ролевых ситуациях
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.gold.withAlpha(20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildScenarioChip(settings.label('🚕 Такси'), 'Сәлеметсіз бе! Осы жерден тоқтаңызшы.'),
                    const SizedBox(width: 8),
                    _buildScenarioChip(settings.label('🍏 Рынок', 'Базар'), 'Бұл алма қанша тұрады? Біраз түсіріп бересіз бе?'),
                    const SizedBox(width: 8),
                    _buildScenarioChip(settings.label('☕ Кафе', 'Дәмхана'), 'Бір шай мен бауырсақ әкеліңізші.'),
                    const SizedBox(width: 8),
                    _buildScenarioChip(settings.label('🤝 Знакомство', 'Танысу'), 'Сәлеметсіз бе, сіздің атыңыз кім?'),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            if (_isSending)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              ),

            // Поле ввода сообщения и микрофон
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? AppColors.error : AppColors.gold,
                    ),
                    onPressed: _toggleMic,
                    tooltip: settings.label('Голосовой ввод', 'Дауыспен айту'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: settings.label('Напишите или продиктуйте по-казахски...', 'Қазақша жазыңыз немесе айтыңыз...'),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.gold),
                    onPressed: () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioChip(String label, String prompt) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: Theme.of(context).cardTheme.color,
      side: const BorderSide(color: AppColors.gold, width: 0.8),
      onPressed: () => _sendMessage(prompt),
    );
  }

  Widget _buildMessageBubble(AiChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppColors.gold
              : (Theme.of(context).cardTheme.color ?? AppColors.darkCard),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isUser ? AppColors.gold : AppColors.darkBorder,
            width: 1,
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            fontSize: 15,
            color: msg.isUser ? AppColors.darkBackground : null,
            fontWeight: msg.isUser ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
