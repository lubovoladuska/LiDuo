import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/settings_provider.dart';

/// Круговой индикатор готовности к разговорной речи
class FluencyMeter extends StatelessWidget {
  final double score; // 0.0 - 100.0%
  final int completedDays;
  final int totalDays;

  const FluencyMeter({
    super.key,
    required this.score,
    required this.completedDays,
    this.totalDays = 90,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (score / 100.0).clamp(0.0, 1.0);
    final settings = context.watch<SettingsProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withAlpha(40),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          CircularPercentIndicator(
            radius: 46.0,
            lineWidth: 8.0,
            animation: true,
            percent: percent,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${score.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.gold,
                  ),
                ),
                Text(
                  'B1/B2',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: AppColors.gold,
            backgroundColor: AppColors.gold.withAlpha(30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.label('Разговорная готовность', 'Сөйлеу деңгейі'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getFluencyDescription(score, settings),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  settings.label(
                    'Пройдено дней: $completedDays / $totalDays',
                    'Өтілген күндер: $completedDays / $totalDays',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.tealLight,
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

  String _getFluencyDescription(double score, SettingsProvider settings) {
    if (score < 15) {
      return settings.label('A0: Первые фразы и звуки', 'A0: Алғашқы дыбыстар мен связкалар');
    }
    if (score < 35) {
      return settings.label('A1: Базовые вопросы и падежи', 'A1: Негізгі сұрақтар мен падеждер');
    }
    if (score < 65) {
      return settings.label('A2: Уверенное бытовое общение', 'A2: Күнделікті еркін қарым-қатынас');
    }
    if (score < 85) {
      return settings.label('B1: Свободная речь без барьера', 'B1: Сенімді спонтанды сөйлеу');
    }
    return settings.label('B2: Продвинутый уровень', 'B2: Еркін және терең пікір алмасу');
  }
}
