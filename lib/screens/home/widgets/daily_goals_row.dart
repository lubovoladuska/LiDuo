import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Виджет панели ежедневных целей и прогресса
class DailyGoalsRow extends StatelessWidget {
  final int streakDays;
  final int drillsCompleted;
  final int dueSrsCount;
  final int minutesPracticed;

  const DailyGoalsRow({
    super.key,
    required this.streakDays,
    required this.drillsCompleted,
    required this.dueSrsCount,
    required this.minutesPracticed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            icon: '🔥',
            label: 'Стрик',
            value: '$streakDays к.',
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            context,
            icon: '🎙️',
            label: 'Дриллы',
            value: '$drillsCompleted',
            color: AppColors.tealLight,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            context,
            icon: '🧠',
            label: 'Повторить',
            value: '$dueSrsCount',
            color: dueSrsCount > 0 ? AppColors.warning : AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            context,
            icon: '⏱️',
            label: 'Минуты',
            value: '$minutesPracticed м.',
            color: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondaryDark,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
