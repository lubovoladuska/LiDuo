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
            const Text(
              '90 күнде еркін сөйлеу',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryDark,
                fontWeight: FontWeight.w600,
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
                    const Text(
                      'Модули обучения',
                      style: TextStyle(
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
                            title: 'Дорожная карта',
                            subtitle: '90 дней • 12 недель',
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
                            title: 'Повторение SRS',
                            subtitle: 'Интервальная память',
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
                            title: 'Матрица грамматики',
                            subtitle: 'Сингармонизм • 7 падежей',
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
                            title: 'ИИ-собеседник',
                            subtitle: 'Ролевые диалоги',
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Сөйлеу жаттығулары (Тренажер речи)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Экспресс-спринты, работа над ошибками и практика по темам',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryDark,
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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF262015),
            Color(0xFF1B1E26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withAlpha(25),
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
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'КҮН ${lesson.dayNumber} • АПТА ${lesson.weekNumber}',
                  style: const TextStyle(
                    color: AppColors.darkBackground,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.mic, size: 16, color: AppColors.goldLight),
                  SizedBox(width: 4),
                  Text(
                    '20 мин • Говорение вслух',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            lesson.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(80),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Формула: ${lesson.grammarFormula}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.goldLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: const Text(
                'Бастау (Начать речевой спринт)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryDark,
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
