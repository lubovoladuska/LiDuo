import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/settings_provider.dart';

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
    final settings = context.watch<SettingsProvider>();

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            icon: '🔥',
            label: settings.label('Стрик', 'Күн'),
            value: '$streakDays д.',
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            icon: '🎙️',
            label: settings.label('Дриллы', 'Дрил'),
            value: '$drillsCompleted',
            color: AppColors.tealLight,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            icon: '🧠',
            label: settings.label('Память', 'Қайталау'),
            value: '$dueSrsCount',
            color: dueSrsCount > 0 ? AppColors.warning : AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            icon: '⏱️',
            label: settings.label('Минуты', 'Минут'),
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
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary(context),
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
