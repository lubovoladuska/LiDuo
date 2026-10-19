import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/drill_session_provider.dart';
import '../../providers/stats_provider.dart';

/// Экран активного речевого дрила (говорение вслух в микрофон)
class DrillScreen extends StatelessWidget {
  const DrillScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DrillSessionProvider>();
    final statsProvider = context.read<StatsProvider>();
    final drill = session.currentDrill;

    if (session.status == DrillStatus.finished) {
      return _buildCelebrationScreen(context, session);
    }

    if (drill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Сабақ')),
        body: const Center(child: Text('Деректер табылмады')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Күн ${session.lesson?.dayNumber ?? 1} • Қадам ${session.currentDrillIndex + 1}/${session.totalDrills}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              session.showHint ? Icons.lightbulb : Icons.lightbulb_outline,
              color: session.showHint ? AppColors.gold : AppColors.textSecondaryDark,
            ),
            onPressed: session.toggleHint,
            tooltip: 'Көмек / Подсказка',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Линейная шкала прогресса по шагам дня
            LinearPercentIndicator(
              lineHeight: 6.0,
              percent: session.progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.gold.withAlpha(30),
              progressColor: AppColors.gold,
              barRadius: const Radius.circular(3),
              padding: EdgeInsets.zero,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Карточка формулы урока (свернутая)
                    if (session.lesson != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.gold.withAlpha(60)),
                        ),
                        child: Text(
                          'Формула: ${session.lesson!.grammarFormula}',
                          style: const TextStyle(
                            color: AppColors.goldLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Основная карточка задания
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'АЙТЫҢЫЗ (СКАЖИТЕ ВСЛУХ):',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondaryDark,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            drill.promptRu,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Кнопка прослушивания эталона TTS
                          OutlinedButton.icon(
                            icon: const Icon(Icons.volume_up_rounded, color: AppColors.gold),
                            label: const Text('Үлгіні тыңдау (Послушать эталон)'),
                            onPressed: session.playTargetAudio,
                          ),

                          // Блок подсказки (показывается по тапу на лампочку)
                          if (session.showHint) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(60),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.teal.withAlpha(80)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    drill.targetKk,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.tealLight,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (drill.grammarNote != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      drill.grammarNote!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondaryDark,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Поле распознанной речи
                    if (session.spokenText.isNotEmpty || session.status == DrillStatus.listening)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: session.status == DrillStatus.passed
                                ? AppColors.success
                                : (session.status == DrillStatus.retry
                                    ? AppColors.warning
                                    : AppColors.gold),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  session.status == DrillStatus.passed
                                      ? Icons.check_circle_outline
                                      : (session.status == DrillStatus.retry
                                          ? Icons.refresh
                                          : Icons.graphic_eq),
                                  color: session.status == DrillStatus.passed
                                      ? AppColors.success
                                      : (session.status == DrillStatus.retry
                                          ? AppColors.warning
                                          : AppColors.gold),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  session.status == DrillStatus.passed
                                      ? 'Дұрыс! (${(session.similarityScore * 100).toInt()}% сәйкестік)'
                                      : (session.status == DrillStatus.retry
                                          ? 'Қайталап көріңіз (${(session.similarityScore * 100).toInt()}%)'
                                          : 'Тыңдап тұрмын... (Говорите)'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: session.status == DrillStatus.passed
                                        ? AppColors.success
                                        : (session.status == DrillStatus.retry
                                            ? AppColors.warning
                                            : AppColors.gold),
                                  ),
                                ),
                              ],
                            ),
                            if (session.spokenText.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '«${session.spokenText}»',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Нижняя панель действий с большой кнопкой микрофона
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
                    width: 1,
                  ),
                ),
              ),
              child: session.status == DrillStatus.passed
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 24),
                        label: Text(
                          session.currentDrillIndex + 1 < session.totalDrills
                              ? 'Келесі қадам (Следующий)'
                              : 'Аяқтау (Завершить день)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        onPressed: () => session.nextDrill(statsProvider),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Кнопка ручной сдачи («Я сказал правильно»)
                        if (session.status == DrillStatus.retry)
                          TextButton(
                            onPressed: session.manualPass,
                            child: const Text(
                              'Дұрыс айттым\n(Засчитать)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryDark,
                              ),
                            ),
                          ),

                        // Большая центральная кнопка микрофона
                        GestureDetector(
                          onTapDown: (_) => session.startListening(),
                          onTapUp: (_) => session.stopListening(),
                          onTapCancel: () => session.stopListening(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: session.status == DrillStatus.listening ? 80 : 70,
                            height: session.status == DrillStatus.listening ? 80 : 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: session.status == DrillStatus.listening
                                    ? [AppColors.error, const Color(0xFFB91C1C)]
                                    : [AppColors.gold, AppColors.goldDark],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (session.status == DrillStatus.listening
                                          ? AppColors.error
                                          : AppColors.gold)
                                      .withAlpha(120),
                                  blurRadius: session.status == DrillStatus.listening ? 24 : 12,
                                  spreadRadius: session.status == DrillStatus.listening ? 4 : 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              session.status == DrillStatus.listening ? Icons.mic : Icons.mic_none,
                              size: 34,
                              color: AppColors.darkBackground,
                            ),
                          ),
                        ),

                        // Кнопка очистки / повтора
                        if (session.status == DrillStatus.retry)
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: AppColors.gold),
                            onPressed: session.startListening,
                            tooltip: 'Қайталау',
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationScreen(BuildContext context, DrillSessionProvider session) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '🎉',
                style: TextStyle(fontSize: 64),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Керемет! Күн аяқталды!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Сіз ${session.totalDrills} сөйлемді сәтті айтып шықтыңыз.\nЖаңа карточкалар интервалды қайталауға қосылды.',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondaryDark,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Басты бетке оралу (Отлично)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
