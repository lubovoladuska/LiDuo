import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/theme/app_colors.dart';

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
                const Text(
                  'B1/B2',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondaryDark,
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
                const Text(
                  'Сөйлеу деңгейі (Разговорная готовность)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getFluencyDescription(score),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Өтілген күндер: $completedDays / $totalDays күн',
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

  String _getFluencyDescription(double score) {
    if (score < 15) return 'A0: Алғашқы дыбыстар мен связкалар';
    if (score < 35) return 'A1: Негізгі сұрақтар мен падеждер';
    if (score < 65) return 'A2: Күнделікті еркін қарым-қатынас';
    if (score < 85) return 'B1: Сенімді спонтанды сөйлеу';
    return 'B2: Еркін және терең пікір алмасу';
  }
}
