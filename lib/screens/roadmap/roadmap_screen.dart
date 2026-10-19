import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/course_repository.dart';
import '../../providers/drill_session_provider.dart';
import '../../providers/stats_provider.dart';
import '../drill/drill_screen.dart';

/// Интерактивная дорожная карта 90 дней и 12 недель курса
class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Жол картасы (90 Күн)'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildPhaseHeader(
            context,
            phaseNumber: 'I',
            title: 'Фундамент және Падеждер (A0 -> A1)',
            weeks: '1–4 Апталар (1–28 Күндер)',
            color: AppColors.gold,
          ),
          ...List.generate(4, (index) => _buildWeekSection(context, stats, weekNum: index + 1)),

          const SizedBox(height: 24),
          _buildPhaseHeader(
            context,
            phaseNumber: 'II',
            title: 'Шақтар және Күнделікті өмір (A1 -> A2)',
            weeks: '5–8 Апталар (29–56 Күндер)',
            color: AppColors.tealLight,
          ),
          ...List.generate(4, (index) => _buildWeekSection(context, stats, weekNum: index + 5)),

          const SizedBox(height: 24),
          _buildPhaseHeader(
            context,
            phaseNumber: 'III',
            title: 'Еркін сөйлеу және Тереңдік (A2 -> B1/B2)',
            weeks: '9–12 Апталар (57–90 Күндер)',
            color: Colors.purpleAccent,
          ),
          ...List.generate(4, (index) => _buildWeekSection(context, stats, weekNum: index + 9)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPhaseHeader(
    BuildContext context, {
    required String phaseNumber,
    required String title,
    required String weeks,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              phaseNumber,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.darkBackground,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  weeks,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSection(
    BuildContext context,
    StatsProvider stats, {
    required int weekNum,
  }) {
    final startDay = (weekNum - 1) * 7 + 1;
    final endDay = (weekNum == 12) ? 90 : (weekNum * 7);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: weekNum == 1 || stats.currentDay >= startDay && stats.currentDay <= endDay,
        shape: const Border(),
        title: Text(
          '$weekNum-Апта ($startDay–$endDay күндер)',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          _getWeekTopic(weekNum),
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
        ),
        children: [
          const Divider(height: 1),
          for (int d = startDay; d <= endDay; d++)
            _buildDayTile(context, stats, dayNumber: d),
        ],
      ),
    );
  }

  Widget _buildDayTile(
    BuildContext context,
    StatsProvider stats, {
    required int dayNumber,
  }) {
    final isCompleted = stats.completedDays.contains(dayNumber);
    final isCurrent = stats.currentDay == dayNumber;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success.withAlpha(30)
              : (isCurrent ? AppColors.gold.withAlpha(30) : Colors.transparent),
          shape: BoxShape.circle,
          border: Border.all(
            color: isCompleted
                ? AppColors.success
                : (isCurrent ? AppColors.gold : AppColors.darkBorder),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: isCompleted
            ? const Icon(Icons.check, size: 18, color: AppColors.success)
            : Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isCurrent ? AppColors.gold : AppColors.textSecondaryDark,
                ),
              ),
      ),
      title: Text(
        'Күн $dayNumber: ${_getDayTitle(dayNumber)}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
          color: isCurrent ? AppColors.gold : null,
        ),
      ),
      trailing: isCurrent
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Бүгін',
                style: TextStyle(
                  color: AppColors.darkBackground,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondaryDark),
      onTap: () async {
        final lesson = await CourseRepository.instance.getLessonForDay(dayNumber);
        if (context.mounted) {
          context.read<DrillSessionProvider>().startSession(lesson);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DrillScreen()),
          );
        }
      },
    );
  }

  String _getWeekTopic(int week) {
    switch (week) {
      case 1:
        return 'Дыбыстар, сингармонизм және байланыстар';
      case 2:
        return 'Тәуелдік және көптік жалғаулары (-лар/-лер)';
      case 3:
        return 'Қимыл септіктері (Барыс, Жатыс, Табыс)';
      case 4:
        return 'Шығыс және Көмектес септіктері';
      case 5:
        return 'Осы шақ және Келер шақ (-а/-е/-й)';
      case 6:
        return 'Өткен шақ және қалау рай (-ғым келеді)';
      case 7:
        return 'Қалалық сценарийлер: такси, базар, дүкен';
      case 8:
        return 'Іскерлік және медициналық диалогтар';
      case 9:
        return 'Мүмкіндік модальділігі (-а аламын)';
      case 10:
        return 'Көмекші етістіктер (-п көру, -п қою)';
      case 11:
        return 'Шартты рай және логикалық себептер';
      case 12:
        return 'Еркін спонтанды сөйлеу және идиомалар';
      default:
        return 'Сөйлеу тәжірибесі';
    }
  }

  String _getDayTitle(int day) {
    if (day == 1) return 'Первое приветствие и самочувствие';
    if (day == 2) return 'Личные окончания сказуемости';
    if (day == 3) return 'Фразы выживания и помощь';
    if (day == 4) return 'Знакомство: имя и откуда вы';
    if (day == 5) return 'Наличие и отсутствие: Бар / Жоқ';
    if (day == 6) return 'Числа, счет и цена: Қанша?';
    if (day == 7) return 'Разговорный спринт Недели 1';
    return 'Практический речевой дрил (День $day)';
  }
}
