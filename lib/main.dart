import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/drill_session_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/srs_provider.dart';
import 'providers/stats_provider.dart';
import 'screens/home/home_screen.dart';
import 'services/ai_partner_service.dart';
import 'services/tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация базовых сервисов
  await TtsService.instance.init();
  await AiPartnerService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        ChangeNotifierProvider(create: (_) => StatsProvider()..loadStats()),
        ChangeNotifierProvider(create: (_) => SrsProvider()),
        ChangeNotifierProvider(create: (_) => DrillSessionProvider()),
      ],
      child: const LiDuoApp(),
    ),
  );
}

class LiDuoApp extends StatelessWidget {
  const LiDuoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'LiDuo — Қазақ тілі',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const HomeScreen(),
    );
  }
}
