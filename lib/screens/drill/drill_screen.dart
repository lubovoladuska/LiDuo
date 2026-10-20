import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/audio_drill.dart';
import '../../providers/drill_session_provider.dart';
import '../../providers/stats_provider.dart';

/// Экран активного речевого дрила с адаптивным UI под разные типы заданий
class DrillScreen extends StatefulWidget {
  const DrillScreen({super.key});

  @override
  State<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends State<DrillScreen> {
  int _lastDrillIndex = -1;
  bool _revealListening = false;

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

    // Автоматическое воспроизведение эталонного звука при переходе на vocab или listening
    if (_lastDrillIndex != session.currentDrillIndex) {
      _lastDrillIndex = session.currentDrillIndex;
      _revealListening = false;
      if (drill.type == DrillType.vocab || drill.type == DrillType.listening) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            session.playTargetAudio();
          }
        });
      }
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
                    // Бейдж типа упражнения
                    _buildTypeBadge(drill.type),
                    const SizedBox(height: 14),

                    // Карточка формулы урока (свернутая)
                    if (session.lesson != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.gold.withAlpha(40)),
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

                    const SizedBox(height: 20),

                    // Адаптивная карточка задания в зависимости от DrillType
                    _buildDrillCard(context, drill, session),

                    const SizedBox(height: 20),

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
                        if (session.status == DrillStatus.retry || drill.type == DrillType.vocab)
                          TextButton(
                            onPressed: session.manualPass,
                            child: Text(
                              drill.type == DrillType.vocab
                                  ? 'Жаттадым\n(Запомнил)'
                                  : 'Дұрыс айттым\n(Засчитать)',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
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

  /// Бейдж типа практики
  Widget _buildTypeBadge(DrillType type) {
    String label;
    IconData icon;
    Color color;

    switch (type) {
      case DrillType.vocab:
        label = '1/4 СӨЗДІК ЗАРЯД (СЛОВАРНЫЙ ПРАЙМЕР)';
        icon = Icons.auto_stories_rounded;
        color = AppColors.tealLight;
        break;
      case DrillType.slotSubstitution:
        label = '2/4 ПОДСТАНОВКА (SLOT MATRIX)';
        icon = Icons.dashboard_customize_rounded;
        color = AppColors.gold;
        break;
      case DrillType.listening:
        label = '3/4 АУДИРОВАНИЕ (SHADOWING)';
        icon = Icons.headphones_rounded;
        color = const Color(0xFFA78BFA);
        break;
      case DrillType.speech:
        label = '4/4 СӨЙЛЕУ ЖАТТЫҒУЫ (РЕЧЕВОЙ ДРИЛ)';
        icon = Icons.record_voice_over_rounded;
        color = AppColors.goldLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  /// Адаптивное наполнение карточки дрила
  Widget _buildDrillCard(BuildContext context, AudioDrill drill, DrillSessionProvider session) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
          width: 1.2,
        ),
      ),
      child: switch (drill.type) {
        DrillType.vocab => _buildVocabCard(drill, session),
        DrillType.slotSubstitution => _buildSlotCard(drill, session),
        DrillType.listening => _buildListeningCard(drill, session),
        DrillType.speech => _buildSpeechCard(drill, session),
      },
    );
  }

  /// Карточка словарного праймера (Vocab)
  Widget _buildVocabCard(AudioDrill drill, DrillSessionProvider session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'ЖАҢА СӨЗДІ ТЫҢДАП, ҚАЙТАЛАҢЫЗ:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.tealLight,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          drill.targetKk,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.goldLight,
          ),
          textAlign: TextAlign.center,
        ),
        if (drill.phoneticTranscription != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '[ ${drill.phoneticTranscription} ]',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: AppColors.textSecondaryDark,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          drill.promptRu,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          icon: const Icon(Icons.volume_up_rounded, color: AppColors.darkBackground),
          label: const Text('Үлгіні тыңдау (Слушать)'),
          onPressed: session.playTargetAudio,
        ),
        if (drill.grammarNote != null) ...[
          const SizedBox(height: 16),
          Text(
            drill.grammarNote!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryDark,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Карточка подстановочного тренажера (Slot Substitution)
  Widget _buildSlotCard(AudioDrill drill, DrillSessionProvider session) {
    final template = drill.slotTemplate ?? drill.targetKk;
    final variable = drill.slotVariable ?? drill.targetKk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'СӨЗДІ ҚАЛЫПҚА ҚОЙЫП АЙТЫҢЫЗ:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.gold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          drill.promptRu,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Рамка грамматического каркаса с акцентированным слотом
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withAlpha(80)),
          ),
          child: Column(
            children: [
              Text(
                'Үлгі / Каркас: $template',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.teal.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.tealLight),
                ),
                child: Text(
                  'Слот: «$variable»',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.tealLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          icon: const Icon(Icons.volume_up_rounded, color: AppColors.gold),
          label: const Text('Үлгіні тыңдау (Послушать фразу)'),
          onPressed: session.playTargetAudio,
        ),
      ],
    );
  }

  /// Карточка аудирования с маскированным текстом (Listening)
  Widget _buildListeningCard(AudioDrill drill, DrillSessionProvider session) {
    final isPassed = session.status == DrillStatus.passed;
    final isVisible = _revealListening || isPassed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'ТЫҢДАҢЫЗ ЖӘНЕ ҚАЙТАЛАҢЫЗ (АУДИРОВАНИЕ):',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFFA78BFA),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          drill.promptRu,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Большая центральная кнопка прослушивания
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            backgroundColor: const Color(0xFF7C3AED),
          ),
          icon: const Icon(Icons.volume_up_rounded, size: 24, color: Colors.white),
          label: const Text(
            'Қайта тыңдау (Слушать еще раз)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          onPressed: session.playTargetAudio,
        ),
        const SizedBox(height: 20),

        // Поле маскированного / раскрытого текста
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isVisible
              ? Container(
                  key: const ValueKey('revealed'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.tealLight),
                  ),
                  child: Column(
                    children: [
                      Text(
                        drill.targetKk,
                        style: const TextStyle(
                          fontSize: 22,
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
                )
              : OutlinedButton.icon(
                  key: const ValueKey('masked'),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('Мәтінді көру (Показать текст)'),
                  onPressed: () {
                    setState(() {
                      _revealListening = true;
                    });
                  },
                ),
        ),
      ],
    );
  }

  /// Стандартная карточка речевого коммуникативного задания (Speech)
  Widget _buildSpeechCard(AudioDrill drill, DrillSessionProvider session) {
    return Column(
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
        OutlinedButton.icon(
          icon: const Icon(Icons.volume_up_rounded, color: AppColors.gold),
          label: const Text('Үлгіні тыңдау (Послушать эталон)'),
          onPressed: session.playTargetAudio,
        ),
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
                'Сіз ${session.totalDrills} сөйлемді сәтті айтып шықтыңыз.\nЖаңа сөздер мен сөйлемдер интервалды қайталауға қосылды.',
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
