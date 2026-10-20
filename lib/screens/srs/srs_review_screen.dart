import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/srs_calculator.dart';
import '../../providers/settings_provider.dart';
import '../../providers/srs_provider.dart';
import '../../providers/stats_provider.dart';

/// Экран интервального повторения фраз и чанков (SRS SuperMemo SM-2)
class SrsReviewScreen extends StatefulWidget {
  const SrsReviewScreen({super.key});

  @override
  State<SrsReviewScreen> createState() => _SrsReviewScreenState();
}

class _SrsReviewScreenState extends State<SrsReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SrsProvider>().loadDueCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final srs = context.watch<SrsProvider>();
    final stats = context.read<StatsProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.label('Интервальное повторение (SRS)', 'Интервалды қайталау')),
      ),
      body: srs.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : srs.dueCards.isEmpty || srs.currentCard == null
              ? _buildEmptyState(context, settings)
              : _buildReviewContent(context, srs, stats, settings),
    );
  }

  Widget _buildEmptyState(BuildContext context, SettingsProvider settings) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              settings.label('На сегодня нет карточек для повторения!', 'Бүгінге қайталайтын карточка жоқ!'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.goldAccent(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              settings.label(
                'Вы повторили все карточки. Новые слова и фразы добавятся автоматически после уроков дня.',
                'Сіз барлық карточкаларды жаттадыңыз. Жаңа карточкалар күнделікті сабақтардан кейін қосылады.',
              ),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary(context),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(settings.label('Вернуться на главную', 'Басты бетке оралу')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewContent(
    BuildContext context,
    SrsProvider srs,
    StatsProvider stats,
    SettingsProvider settings,
  ) {
    final card = srs.currentCard!;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Счетчик карточек в очереди
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  settings.label(
                    'Карточка: ${srs.currentIndex + 1} из ${srs.dueCount}',
                    'Карточка: ${srs.currentIndex + 1} / ${srs.dueCount}',
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    settings.label('Интервал: ${card.intervalDays} дн.', 'Интервал: ${card.intervalDays} к.'),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.goldAccent(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Основная интерактивная карточка (Front / Back)
            Expanded(
              child: GestureDetector(
                onTap: srs.flipCard,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: srs.isFlipped ? AppColors.goldAccent(context) : AppColors.cardBorder(context),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.dark ? 40 : 15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        settings.label('ВСПОМНИТЕ И СКАЖИТЕ ВСЛУХ:', 'ЕСКЕ ТҮСІРІҢІЗ ЖӘНЕ АЙТЫҢЫЗ:'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary(context),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        card.frontPrompt,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      if (!srs.isFlipped) ...[
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app, size: 18, color: AppColors.goldAccent(context)),
                            const SizedBox(width: 8),
                            Text(
                              settings.label('Нажмите для показа ответа', 'Төңкеру үшін басыңыз'),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.goldAccent(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (srs.isFlipped) ...[
                        const SizedBox(height: 30),
                        Divider(color: AppColors.cardBorder(context)),
                        const SizedBox(height: 20),
                        Text(
                          card.backTarget,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.goldAccent(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (card.note != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            card.note!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4 кнопки оценки качества ответа по алгоритму SM-2
            if (srs.isFlipped)
              Row(
                children: [
                  Expanded(
                    child: _buildGradeButton(
                      context,
                      label: settings.label('Забыл', 'Қайта'),
                      color: AppColors.error,
                      onTap: () => srs.rateCard(SrsGrade.again, stats),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildGradeButton(
                      context,
                      label: settings.label('Трудно', 'Қиын'),
                      color: AppColors.warning,
                      onTap: () => srs.rateCard(SrsGrade.hard, stats),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildGradeButton(
                      context,
                      label: settings.label('Хорошо', 'Жақсы'),
                      color: AppColors.tealLight,
                      onTap: () => srs.rateCard(SrsGrade.good, stats),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildGradeButton(
                      context,
                      label: settings.label('Легко', 'Оңай'),
                      color: AppColors.success,
                      onTap: () => srs.rateCard(SrsGrade.easy, stats),
                    ),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: srs.flipCard,
                child: Text(settings.label('Показать ответ (Проверить себя)', 'Жауабын тексеру')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeButton(
    BuildContext context, {
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withAlpha(30),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color, width: 1.2),
        ),
      ),
      onPressed: onTap,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
