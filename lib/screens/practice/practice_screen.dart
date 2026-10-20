import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../data/models/audio_drill.dart';
import '../../data/repositories/course_repository.dart';
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
        const SnackBar(content: Text('Бұл санатта жаттығулар табылмады')),
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
    _launchWorkout(drills, 'Спринт $count сөйлем');
  }

  Future<void> _startSlotMatrix() async {
    final stats = context.read<StatsProvider>();
    final drills = await CourseRepository.instance.getSlotMatrixDrills(
      completedDays: stats.completedDays,
      count: 12,
    );
    _launchWorkout(drills, 'Подстановочный тренажер (Slot Matrix)');
  }

  Future<void> _startVocabBlitz() async {
    final stats = context.read<StatsProvider>();
    final drills = await CourseRepository.instance.getVocabBlitzDrills(
      completedDays: stats.completedDays,
      count: 12,
    );
    _launchWorkout(drills, 'Словарный спринт (Vocab Blitz)');
  }

  Future<void> _startMistakeReview() async {
    final weakAttempts = await AppDatabase.instance.getWeakDrillAttempts();
    if (weakAttempts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Керемет! Сізде қате орындалған сөйлемдер жоқ.')),
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
            promptRu: 'Қайталап, дұрыс айтыңыз:',
            targetKk: target,
            grammarNote: 'Қателермен жұмыс',
          ),
        );
      }
    }

    _launchWorkout(weakDrills, 'Қателермен жұмыс');
  }

  Future<void> _startDayPractice(int dayNumber) async {
    final lesson = await CourseRepository.instance.getLessonForDay(dayNumber);
    _launchWorkout(lesson.drills, '$dayNumber-күн жаттығуы');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сөйлеу жаттығулары (Практика)'),
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
                            const Text(
                              'Еркін сөйлеу бұлшықеті',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.gold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Қосымша 10–15 минут еркін сөйлеу сөздік қор мен тілдік реакцияны 3 есе жылдамдатады.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Жылдам режимдер',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),

                // Карточка Экспресс-спринта 10 фраз
                _buildWorkoutCard(
                  context,
                  title: '⚡ Экспресс-спринт (10 сөйлем)',
                  subtitle: 'Жылдам 3–5 минуттық дауыстап сөйлеу жаттығуы',
                  badge: '3-5 мин',
                  badgeColor: AppColors.gold,
                  onTap: () => _startQuickSprint(10),
                ),

                const SizedBox(height: 12),

                // Карточка Словарного спринта
                _buildWorkoutCard(
                  context,
                  title: '📚 Словарный спринт (Vocab Blitz)',
                  subtitle: 'Быстрый речевой прогон активного запаса слов',
                  badge: '12 сөз',
                  badgeColor: AppColors.tealLight,
                  onTap: _startVocabBlitz,
                ),

                const SizedBox(height: 12),

                // Карточка Подстановочного тренажера
                _buildWorkoutCard(
                  context,
                  title: '🧩 Подстановочный тренажер (Slot Matrix)',
                  subtitle: 'Отработка быстрой подстановки в грамматические слоты',
                  badge: '12 слотов',
                  badgeColor: AppColors.goldAccent(context),
                  onTap: _startSlotMatrix,
                ),

                const SizedBox(height: 12),

                // Карточка Интенсивного марафона 25 фраз
                _buildWorkoutCard(
                  context,
                  title: '🔥 Интенсив-марафон (25 сөйлем)',
                  subtitle: 'Өтілген барлық материалды микс түрінде қайталау',
                  badge: '10 мин',
                  badgeColor: AppColors.tealLight,
                  onTap: () => _startQuickSprint(25),
                ),

                const SizedBox(height: 12),

                // Карточка работы над ошибками
                _buildWorkoutCard(
                  context,
                  title: '🎯 Қателермен жұмыс',
                  subtitle: _weakDrillsCount > 0
                      ? 'Түзелмеген $_weakDrillsCount сөйлем бар'
                      : 'Барлық сөйлемдер таза айтылды!',
                  badge: '$_weakDrillsCount қате',
                  badgeColor: _weakDrillsCount > 0 ? AppColors.warning : AppColors.success,
                  onTap: _startMistakeReview,
                ),

                const SizedBox(height: 28),

                const Text(
                  'Тақырыптар бойынша жаттығу',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
                        '10–12 речевых дрилов',
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
