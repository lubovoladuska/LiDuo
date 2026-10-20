import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/day_lesson.dart';
import '../../data/repositories/course_repository.dart';
import '../../providers/drill_session_provider.dart';
import '../../providers/srs_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/settings_provider.dart';
import '../drill/drill_screen.dart';
import '../grammar/grammar_matrix_screen.dart';
import '../roadmap/roadmap_screen.dart';
import '../srs/srs_review_screen.dart';
import '../ai_dialogue/ai_chat_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/daily_goals_row.dart';
import 'widgets/fluency_meter.dart';
import '../practice/practice_screen.dart';

/// Главный экран LiDuo
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DayLesson? _todayLesson;
  bool _isLoadingLesson = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final statsProvider = context.read<StatsProvider>();
    final srsProvider = context.read<SrsProvider>();

    await statsProvider.loadStats();
    await srsProvider.loadDueCards();

    final lesson = await CourseRepository.instance.getLessonForDay(
      statsProvider.currentDay,
    );

    if (mounted) {
      setState(() {
        _todayLesson = lesson;
        _isLoadingLesson = false;
      });
    }
  }

  void _startSprint(DayLesson lesson) {
    context.read<DrillSessionProvider>().startSession(lesson);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DrillScreen(),
      ),
    ).then((_) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = context.watch<StatsProvider>();
    final srsProvider = context.watch<SrsProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gold, width: 1),
              ),
              child: const Text(
                'LiDuo',
                style: TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                settingsProvider.label('Свободная речь за 90 дней', '90 күнде еркін сөйлеу'),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              settingsProvider.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: AppColors.gold,
            ),
            onPressed: () {
              settingsProvider.toggleTheme();
            },
            tooltip: 'Переключить тему',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.gold),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Настройки',
          ),
        ],
      ),
      body: statsProvider.isLoading || _isLoadingLesson
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : RefreshIndicator(
              color: AppColors.gold,
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Шкала готовности к разговорной речи
                    FluencyMeter(
                      score: statsProvider.fluencyScore,
                      completedDays: statsProvider.completedDays.length,
                      totalDays: 90,
                    ),

                    const SizedBox(height: 16),

                    // Строка ежедневных метрик (Стрик, Дриллы, Повторения, Минуты)
                    DailyGoalsRow(
                      streakDays: statsProvider.streakDays,
                      drillsCompleted: statsProvider.stats.totalDrillsCompleted,
                      dueSrsCount: srsProvider.dueCount,
                      minutesPracticed: statsProvider.stats.minutesPracticed,
                    ),

                    const SizedBox(height: 24),

                    // Главная карточка сегодняшнего спринта
                    if (_todayLesson != null)
                      _buildSprintHeroCard(context, _todayLesson!),

                    const SizedBox(height: 16),

                    // Центр свободной практики речи
                    _buildPracticePromoCard(context),

                    const SizedBox(height: 24),

                    // Сетка быстрых модулей
                    Text(
                      settingsProvider.label('Модули обучения', 'Оқу модульдері'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildNavigationCard(
                            context,
                            title: settingsProvider.label('Дорожная карта', 'Бағдарлама'),
                            subtitle: settingsProvider.label('90 дней • 12 недель', '12 апталық жоспар'),
                            icon: Icons.map_outlined,
                            badge: '${statsProvider.completedDays.length}/90',
                            badgeColor: AppColors.gold,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RoadmapScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNavigationCard(
                            context,
                            title: settingsProvider.label('Повторение слов', 'Интервалды қайталау'),
                            subtitle: settingsProvider.label('Интервальная память', 'Жадтағы карточкалар'),
                            icon: Icons.psychology_outlined,
                            badge: '${srsProvider.dueCount}',
                            badgeColor: srsProvider.dueCount > 0
                                ? AppColors.warning
                                : AppColors.teal,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SrsReviewScreen(),
                                ),
                              ).then((_) => _loadData());
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildNavigationCard(
                            context,
                            title: settingsProvider.label('Матрица грамматики', 'Грамматикалық матрица'),
                            subtitle: settingsProvider.label('Сингармонизм • 7 падежей', '7 септік пен үндестік'),
                            icon: Icons.menu_book_outlined,
                            badge: '7 падежей',
                            badgeColor: AppColors.tealLight,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const GrammarMatrixScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNavigationCard(
                            context,
                            title: settingsProvider.label('ИИ-Собеседник', 'ИИ-Серіктес'),
                            subtitle: settingsProvider.label('Ролевые диалоги', 'Еркін сұхбаттасу'),
                            icon: Icons.smart_toy_outlined,
                            badge: 'Gemini',
                            badgeColor: AppColors.gold,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AiChatScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPracticePromoCard(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PracticeScreen()),
        ).then((_) => _loadData());
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.tealLight.withAlpha(80),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teal.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fitness_center_rounded, color: AppColors.tealLight, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.label('Тренажеры свободной речи', 'Сөйлеу жаттығулары'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    settings.label(
                      'Экспресс-спринты, матрица подстановок и работа над ошибками',
                      'Спринттер, қалыптар мен қатемен жұмыс',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.tealLight),
          ],
        ),
      ),
    );
  }

  Widget _buildSprintHeroCard(BuildContext context, DayLesson lesson) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF262015), Color(0xFF1B1E26)]
              : const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.gold : AppColors.goldDark,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.gold : AppColors.goldDark).withAlpha(isDark ? 25 : 45),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.gold : AppColors.goldDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  settings.label(
                    'ДЕНЬ ${lesson.dayNumber} • НЕДЕЛЯ ${lesson.weekNumber}',
                    'КҮН ${lesson.dayNumber} • АПТА ${lesson.weekNumber}',
                  ),
                  style: TextStyle(
                    color: isDark ? AppColors.darkBackground : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.mic,
                    size: 16,
                    color: isDark ? AppColors.goldLight : AppColors.goldDark,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    settings.label('20 мин • Говорение вслух', '20 мин • Дауыстап сөйлеу'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.goldLight : AppColors.goldDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            lesson.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withAlpha(80) : AppColors.gold.withAlpha(35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.gold.withAlpha(50) : AppColors.goldDark.withAlpha(70),
              ),
            ),
            child: Text(
              'Формула: ${lesson.grammarFormula}',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.goldLight : const Color(0xFF92400E),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: Text(
                settings.label('Начать речевой спринт', 'Речевой спринтті бастау'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              onPressed: () => _startSprint(lesson),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppColors.gold, size: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor, width: 0.8),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary(context),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
