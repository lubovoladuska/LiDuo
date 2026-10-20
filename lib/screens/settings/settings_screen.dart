import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';

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
        title: Text(settings.label('Настройки', 'Баптаулар')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(context, settings.label('Внешний вид и язык', 'Сыртқы түрі мен тіл')),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.palette_outlined, color: AppColors.goldAccent(context)),
            title: Text(settings.label('Темная тема', 'Қараңғы стиль')),
            subtitle: const Text('Стиль Nomad Luxe (графит и золото)'),
            trailing: Switch(
              value: settings.isDark,
              activeThumbColor: AppColors.gold,
              onChanged: (_) => settings.toggleTheme(),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.translate_rounded, color: AppColors.goldAccent(context)),
            title: Text(settings.label('Казахские названия в скобках', 'Қазақша атауларды көрсету')),
            subtitle: Text(
              settings.showKazakhSubtitles
                  ? 'Включено: пункты меню дублируются, например «Главная (Басты бет)»'
                  : 'Отключено: только на русском языке («Главная», «Практика»)',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
            ),
            trailing: Switch(
              value: settings.showKazakhSubtitles,
              activeThumbColor: AppColors.gold,
              onChanged: (val) => settings.setShowKazakhSubtitles(val),
            ),
          ),

          const Divider(height: 32),

          _buildSectionHeader(context, settings.label('Синтез речи (Озвучка)', 'Дыбыс және синтез')),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              settings.ttsEnabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
              color: settings.ttsEnabled ? AppColors.goldAccent(context) : AppColors.textSecondary(context),
            ),
            title: Text(settings.label('Озвучивание текста (TTS)', 'Мәтінді дыбыстау')),
            subtitle: Text(
              settings.ttsEnabled
                  ? 'Включено (системный синтезатор речи)'
                  : 'Отключено (рекомендуется ориентироваться на транскрипцию [ ... ])',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
            ),
            trailing: Switch(
              value: settings.ttsEnabled,
              activeThumbColor: AppColors.gold,
              onChanged: (val) => settings.setTtsEnabled(val),
            ),
          ),
          if (settings.ttsEnabled) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.speed, color: AppColors.goldAccent(context)),
              title: Text(settings.label('Темп речи', 'Сөйлеу жылдамдығы')),
              subtitle: Text('${(settings.speechRate * 100).toInt()}% от нормы'),
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
          ],

          const Divider(height: 32),

          _buildSectionHeader(context, settings.label('ИИ-Собеседник (Gemini API)', 'ИИ-Серіктес')),
          Text(
            'Приложение полностью автономно и работает 100% оффлайн. Если вы хотите вести свободные диалоги с ИИ-партнером, укажите бесплатный ключ Gemini API.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context), height: 1.4),
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
                borderSide: BorderSide(color: AppColors.goldAccent(context), width: 1.5),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.save, color: AppColors.goldAccent(context)),
                onPressed: () {
                  settings.setGeminiApiKey(_apiKeyController.text);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(settings.label('API ключ сохранен!', 'API кілті сақталды!'))),
                  );
                },
              ),
            ),
          ),

          const Divider(height: 32),

          _buildSectionHeader(context, settings.label('О проекте LiDuo', 'Жоба туралы')),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LiDuo v1.0.0',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.goldAccent(context)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Бескомпромиссно эффективная открытая система обучения казахскому языку.\nСоздано с заботой о развитии активной разговорной речи.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.goldAccent(context),
        ),
      ),
    );
  }
}
