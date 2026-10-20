import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liduo/core/theme/app_theme.dart';
import 'package:liduo/providers/drill_session_provider.dart';
import 'package:liduo/providers/settings_provider.dart';
import 'package:liduo/providers/srs_provider.dart';
import 'package:liduo/providers/stats_provider.dart';
import 'package:liduo/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('HomeScreen smoke test renders branding and sprint card', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => StatsProvider()),
          ChangeNotifierProvider(create: (_) => SrsProvider()),
          ChangeNotifierProvider(create: (_) => DrillSessionProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pump();

    // Проверяем наличие логотипа LiDuo и девиза
    expect(find.text('LiDuo'), findsOneWidget);
    expect(find.textContaining('90 күнде еркін сөйлеу'), findsOneWidget);
  });
}
