import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../../services/tts_service.dart';

/// Экран настроек приложения
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _apiKeyController = TextEditingController(text: settings.geminiApiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Баптаулар (Настройки)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Интерфейс және визуал'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.palette_outlined, color: AppColors.gold),
            title: const Text('Қараңғы стиль (Nomad Dark)'),
            subtitle: const Text('Степной модерн в графитовых тонах'),
            trailing: Switch(
              value: settings.isDark,
              activeThumbColor: AppColors.gold,
              onChanged: (_) => settings.toggleTheme(),
            ),
          ),

          const Divider(height: 32),

          _buildSectionHeader('Дыбыс және синтез (TTS)'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.speed, color: AppColors.gold),
            title: const Text('Сөйлеу жылдамдығы (Темп речи)'),
            subtitle: Text('${(settings.speechRate * 100).toInt()}% қалыпты жылдамдықтан'),
          ),
          Slider(
            value: settings.speechRate,
            min: 0.6,
            max: 1.2,
            divisions: 6,
            activeColor: AppColors.gold,
            label: '${settings.speechRate.toStringAsFixed(2)}x',
            onChanged: (val) => settings.setSpeechRate(val),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.play_circle_outline, color: AppColors.gold),
              label: const Text('Сөйлеуді тексеру: «Сәлеметсіз бе, қалың қалай?»'),
              onPressed: () {
                TtsService.instance.speak('Сәлеметсіз бе, қалың қалай?');
              },
            ),
          ),

          const Divider(height: 32),

          _buildSectionHeader('ИИ-Серіктес (Gemini API / Опционально)'),
          const Text(
            'Приложение полностью автономно и работает оффлайн. Если вы хотите вести свободные диалоги с ИИ-партнером, укажите бесплатный ключ Gemini API.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Gemini API Key',
              hintText: 'AIzaSy...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save, color: AppColors.gold),
                onPressed: () {
                  settings.setGeminiApiKey(_apiKeyController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API кілті сақталды!')),
                  );
                },
              ),
            ),
          ),

          const Divider(height: 32),

          _buildSectionHeader('Жоба туралы (О проекте LiDuo)'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LiDuo v1.0.0',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.gold),
                ),
                SizedBox(height: 6),
                Text(
                  'Бескомпромиссно эффективная открытая система обучения казахскому языку.\nСоздано с заботой о развитии разговорной речи.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondaryDark, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.gold,
        ),
      ),
    );
  }
}
