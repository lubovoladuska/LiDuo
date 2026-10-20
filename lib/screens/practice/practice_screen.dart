import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../data/models/audio_drill.dart';
import '../../data/repositories/course_repository.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stats_provider.dart';
import 'drill_workout_screen.dart';

/// Центр свободной практики речи и тренировок
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  int _weakDrillsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final weak = await AppDatabase.instance.getWeakDrillAttempts();
    if (mounted) {
      setState(() {
        _weakDrillsCount = weak.length;
        _isLoading = false;
      });
    }
  }

  void _launchWorkout(List<AudioDrill> drills, String title) {
    if (drills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('В этой категории упражнений пока нет')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DrillWorkoutScreen(
          drills: drills,
          workoutTitle: title,
        ),
      ),
    ).then((_) => _loadStats());
  }

  Future<void> _startQuickSprint(int count) async {
    final stats = context.read<StatsProvider>();
    final drills = await CourseRepository.instance.getQuickWorkoutDrills(
      completedDays: stats.completedDays,
      count: count,
    );
    _launchWorkout(drills, 'Спринт ($count фраз)');
  }

  Future<void> _startSlotMatrix() async {
    final stats = context.read<StatsProvider>();
    final settings = context.read<SettingsProvider>();
    final drills = await CourseRepository.instance.getSlotMatrixDrills(
      completedDays: stats.completedDays,
      count: 12,
    );
    _launchWorkout(
      drills,
      settings.label('Конструктор речевых фраз', 'Сөйлеу қалыбы тренажері'),
    );
  }

  Future<void> _startVocabBlitz() async {
    final stats = context.read<StatsProvider>();
    final settings = context.read<SettingsProvider>();
    final drills = await CourseRepository.instance.getVocabBlitzDrills(
      completedDays: stats.completedDays,
      count: 12,
    );
    _launchWorkout(
      drills,
      settings.label('Словарный спринт', 'Сөздік спринт'),
    );
  }

  Future<void> _startMistakeReview() async {
    final weakAttempts = await AppDatabase.instance.getWeakDrillAttempts();
    if (weakAttempts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отлично! У вас нет неисправленных ошибок.')),
        );
      }
      return;
    }

    final List<AudioDrill> weakDrills = [];
    final seen = <String>{};

    for (final item in weakAttempts) {
      final drillId = item['drill_id'] as String;
      final target = item['target_text'] as String;
      if (!seen.contains(target)) {
        seen.add(target);
        weakDrills.add(
          AudioDrill(
            id: drillId,
            step: 1,
            promptRu: 'Повторите и произнесите чисто:',
            targetKk: target,
            grammarNote: 'Работа над ошибками',
          ),
        );
      }
    }

    _launchWorkout(weakDrills, 'Работа над ошибками');
  }

  Future<void> _startDayPractice(int dayNumber) async {
    final lesson = await CourseRepository.instance.getLessonForDay(dayNumber);
    _launchWorkout(lesson.drills, 'Практика: День $dayNumber');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.label('Практика и тренажеры', 'Сөйлеу жаттығулары')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Баннер важности практики
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF231D12), Color(0xFF161920)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withAlpha(80), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fitness_center_rounded, color: AppColors.gold, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              settings.label('Мышца свободной речи', 'Еркін сөйлеу бұлшықеті'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.gold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              settings.label(
                                'Дополнительные 10–15 минут практики ускоряют словарный запас и реакцию речи в 3 раза.',
                                'Қосымша 10–15 минут еркін сөйлеу тілдік реакцияны 3 есе жылдамдатады.',
                              ),
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  settings.label('Быстрые режимы', 'Жылдам режимдер'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),

                // Карточка Экспресс-спринта 10 фраз
                _buildWorkoutCard(
                  context,
                  title: settings.label('⚡ Экспресс-спринт (10 фраз)', '⚡ Экспресс-спринт (10 сөйлем)'),
                  subtitle: settings.label('Быстрая 3–5 минутная разминка речи вслух', 'Жылдам 3–5 минуттық дауыстап сөйлеу'),
                  badge: '3-5 мин',
                  badgeColor: AppColors.gold,
                  onTap: () => _startQuickSprint(10),
                ),

                const SizedBox(height: 12),

                // Карточка Словарного спринта
                _buildWorkoutCard(
                  context,
                  title: settings.label('📚 Словарный спринт (Vocab Blitz)', '📚 Сөздік спринт'),
                  subtitle: settings.label('Быстрый прогон активного словарного запаса', 'Сөздік қорды дауыстап бекіту'),
                  badge: settings.label('12 слов', '12 сөз'),
                  badgeColor: AppColors.tealLight,
                  onTap: _startVocabBlitz,
                ),

                const SizedBox(height: 12),

                // Карточка Подстановочного тренажера (Конструктор фраз)
                _buildWorkoutCard(
                  context,
                  title: settings.label('🧩 Конструктор речевых фраз', '🧩 Сөйлеу қалыбы тренажері'),
                  subtitle: settings.label('Отработка быстрой подстановки слов в речевые каркасы', 'Дайын үлгілерге сөздерді жылдам қою'),
                  badge: settings.label('12 шаблонов', '12 үлгі'),
                  badgeColor: AppColors.goldAccent(context),
                  onTap: _startSlotMatrix,
                ),

                const SizedBox(height: 12),

                // Карточка Интенсивного марафона 25 фраз
                _buildWorkoutCard(
                  context,
                  title: settings.label('🔥 Интенсив-марафон (25 фраз)', '🔥 Интенсив-марафон (25 сөйлем)'),
                  subtitle: settings.label('Микс-тренировка всего пройденного материала', 'Өтілген материалды аралас қайталау'),
                  badge: '10 мин',
                  badgeColor: AppColors.tealLight,
                  onTap: () => _startQuickSprint(25),
                ),

                const SizedBox(height: 12),

                // Карточка работы над ошибками
                _buildWorkoutCard(
                  context,
                  title: settings.label('🎯 Работа над ошибками', '🎯 Қателермен жұмыс'),
                  subtitle: _weakDrillsCount > 0
                      ? settings.label('Фраз для исправления: $_weakDrillsCount', 'Түзелмеген $_weakDrillsCount сөйлем бар')
                      : settings.label('Все фразы произнесены чисто!', 'Барлық сөйлемдер таза айтылды!'),
                  badge: settings.label('$_weakDrillsCount ошибок', '$_weakDrillsCount қате'),
                  badgeColor: _weakDrillsCount > 0 ? AppColors.warning : AppColors.success,
                  onTap: _startMistakeReview,
                ),

                const SizedBox(height: 28),

                Text(
                  settings.label('Тренировка по урокам недели', 'Тақырыптар бойынша жаттығу'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),

                // Список уроков Недели 1 для точечной отработки
                for (int day = 1; day <= 7; day++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$day',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                      title: Text(
                        _getDayPracticeTitle(day),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        settings.label('10–12 речевых дрилов', '10–12 сөйлем'),
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary(context)),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.gold),
                      onTap: () => _startDayPractice(day),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: badgeColor, width: 1),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayPracticeTitle(int day) {
    switch (day) {
      case 1:
        return 'Приветствия и вежливые вопросы';
      case 2:
        return 'Личные окончания: кто я? (-мын/-сіз)';
      case 3:
        return 'Фразы выживания и понимание';
      case 4:
        return 'Знакомство, имя и города';
      case 5:
        return 'Владение и наличие: Бар / Жоқ';
      case 6:
        return 'Числа, цены, счет и заказ';
      case 7:
        return 'Консолидация недели (12 дрилов)';
      default:
        return 'Практика дня $day';
    }
  }
}
