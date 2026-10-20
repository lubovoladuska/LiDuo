import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/audio_drill.dart';
import '../../providers/drill_session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/stats_provider.dart';

/// Экран активного речевого дрила с адаптивным UI под разные типы заданий
class DrillScreen extends StatefulWidget {
  const DrillScreen({super.key});

  @override
  State<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends State<DrillScreen> {
  int _lastDrillIndex = -1;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DrillSessionProvider>();
    final statsProvider = context.read<StatsProvider>();
    final settings = context.watch<SettingsProvider>();
    final drill = session.currentDrill;

    if (session.status == DrillStatus.finished) {
      return _buildCelebrationScreen(context, session, settings);
    }

    if (drill == null) {
      return Scaffold(
        appBar: AppBar(title: Text(settings.label('Урок', 'Сабақ'))),
        body: Center(child: Text(settings.label('Данные не найдены', 'Деректер табылмады'))),
      );
    }

    if (_lastDrillIndex != session.currentDrillIndex) {
      _lastDrillIndex = session.currentDrillIndex;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          settings.label(
            'День ${session.lesson?.dayNumber ?? 1} • Шаг ${session.currentDrillIndex + 1}/${session.totalDrills}',
            'Күн ${session.lesson?.dayNumber ?? 1} • Қадам ${session.currentDrillIndex + 1}/${session.totalDrills}',
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              session.showHint ? Icons.lightbulb : Icons.lightbulb_outline,
              color: session.showHint ? AppColors.gold : AppColors.textSecondary(context),
            ),
            onPressed: session.toggleHint,
            tooltip: settings.label('Подсказка', 'Көмек'),
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
                    _buildTypeBadge(drill.type, settings),
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
                          style: TextStyle(
                            color: AppColors.goldAccent(context),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Карточка задания
                    _buildDrillCard(context, drill, session, settings),

                    const SizedBox(height: 24),

                    // Блок статуса распознавания речи
                    if (session.status != DrillStatus.idle)
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
                            width: 1.2,
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
                                      ? settings.label(
                                          'Правильно! (${(session.similarityScore * 100).toInt()}% совпадение)',
                                          'Дұрыс! (${(session.similarityScore * 100).toInt()}%)',
                                        )
                                      : (session.status == DrillStatus.retry
                                          ? settings.label(
                                              'Повторите еще раз (${(session.similarityScore * 100).toInt()}%)',
                                              'Қайталап көріңіз (${(session.similarityScore * 100).toInt()}%)',
                                            )
                                          : settings.label(
                                              'Слушаю вас... (Говорите)',
                                              'Тыңдап тұрмын... (Говорите)',
                                            )),
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
                              ? settings.label('Следующий шаг (Далее)', 'Келесі қадам')
                              : settings.label('Завершить день', 'Аяқтау'),
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
                                  ? settings.label('Запомнил', 'Жаттадым')
                                  : settings.label('Сказал правильно\n(Засчитать)', 'Дұрыс айттым'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary(context),
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

                        // Кнопка повтора
                        if (session.status == DrillStatus.retry)
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: AppColors.gold),
                            onPressed: session.startListening,
                            tooltip: settings.label('Повторить', 'Қайталау'),
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
  Widget _buildTypeBadge(DrillType type, SettingsProvider settings) {
    String label;
    IconData icon;
    Color color;

    switch (type) {
      case DrillType.vocab:
        label = settings.label('1/4 СЛОВАРЬ (СЛОВО ДНЯ)', '1/4 СӨЗДІК БАЗА');
        icon = Icons.auto_stories_rounded;
        color = AppColors.tealLight;
        break;
      case DrillType.slotSubstitution:
        label = settings.label('2/4 КОНСТРУКТОР ФРАЗ', '2/4 СӨЙЛЕУ ҚАЛЫБЫ');
        icon = Icons.dashboard_customize_rounded;
        color = AppColors.gold;
        break;
      case DrillType.listening:
        label = settings.label('3/4 ЭКСПРЕСС-ЧТЕНИЕ (SHADOWING)', '3/4 ОҚУ ЖӘНЕ АЙТУ');
        icon = Icons.record_voice_over_rounded;
        color = const Color(0xFFA78BFA);
        break;
      case DrillType.speech:
        label = settings.label('4/4 РЕЧЕВОЙ ДРИЛ', '4/4 СӨЙЛЕУ ЖАТТЫҒУЫ');
        icon = Icons.mic_rounded;
        color = AppColors.goldAccent(context);
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
  Widget _buildDrillCard(
    BuildContext context,
    AudioDrill drill,
    DrillSessionProvider session,
    SettingsProvider settings,
  ) {
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
        DrillType.vocab => _buildVocabCard(drill, session, settings),
        DrillType.slotSubstitution => _buildSlotCard(drill, session, settings),
        DrillType.listening => _buildListeningCard(drill, session, settings),
        DrillType.speech => _buildSpeechCard(drill, session, settings),
      },
    );
  }

  /// Карточка словарного праймера (Vocab)
  Widget _buildVocabCard(AudioDrill drill, DrillSessionProvider session, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          settings.label('НОВОЕ СЛОВО (ПРОЧТИТЕ И ПОВТОРИТЕ):', 'ЖАҢА СӨЗДІ ОҚЫП, ҚАЙТАЛАҢЫЗ:'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.tealAccent(context),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          drill.targetKk,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            color: isDark ? AppColors.goldLight : AppColors.goldDark,
          ),
          textAlign: TextAlign.center,
        ),
        if (drill.phoneticTranscription != null || drill.targetKk.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withAlpha(12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '[ ${drill.phoneticTranscription ?? drill.targetKk} ]',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.tealLight : AppColors.tealDark,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          drill.promptRu,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        if (drill.grammarNote != null) ...[
          const SizedBox(height: 16),
          Text(
            drill.grammarNote!,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary(context),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Карточка речевого конструктора (подстановка слова в каркас)
  Widget _buildSlotCard(AudioDrill drill, DrillSessionProvider session, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawTemplate = drill.slotTemplate ?? drill.targetKk;
    final template = rawTemplate.replaceAll(RegExp(r'\[(слот|slot)\]', caseSensitive: false), '[ ... ]');
    final variable = drill.slotVariable ?? drill.targetKk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          settings.label('ВСТАВЬТЕ СЛОВО В РЕЧЕВОЙ КАРКАС:', 'СӨЗДІ ҚАЛЫПҚА ҚОЙЫП АЙТЫҢЫЗ:'),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.goldAccent(context),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          drill.promptRu,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Рамка грамматического каркаса с акцентированным словом
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withAlpha(50) : AppColors.gold.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.gold.withAlpha(80) : AppColors.goldDark.withAlpha(60),
            ),
          ),
          child: Column(
            children: [
              Text(
                settings.label('Речевой каркас: $template', 'Сөйлеу қалыбы: $template'),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.teal.withAlpha(isDark ? 30 : 25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.tealLight),
                ),
                child: Text(
                  '${settings.label('Вставьте слово', 'Қойылатын сөз')}: «$variable»',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.tealLight : AppColors.tealDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Полная целевая фраза и транскрипция (ВИДИМЫ ВСЕГДА)
        Text(
          drill.targetKk,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isDark ? AppColors.goldLight : AppColors.goldDark,
          ),
          textAlign: TextAlign.center,
        ),
        if (drill.phoneticTranscription != null || drill.targetKk.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '[ ${drill.phoneticTranscription ?? drill.targetKk} ]',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.tealLight : AppColors.tealDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Карточка экспресс-чтения и проговаривания (Shadowing / Reading)
  Widget _buildListeningCard(AudioDrill drill, DrillSessionProvider session, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          settings.label('ПРОЧТИТЕ И ПРОИЗНЕСИТЕ ВСЛУХ (SHADOWING):', 'ОҚЫП, ДАУЫСТАП АЙТЫҢЫЗ:'),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFFA78BFA),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          drill.promptRu,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary(context),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Поле казахской фразы и транскрипции
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.teal.withAlpha(isDark ? 20 : 15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.tealLight),
          ),
          child: Column(
            children: [
              Text(
                drill.targetKk,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.tealLight : AppColors.tealDark,
                ),
                textAlign: TextAlign.center,
              ),
              if (drill.phoneticTranscription != null || drill.targetKk.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withAlpha(10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '[ ${drill.phoneticTranscription ?? drill.targetKk} ]',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.goldLight : AppColors.goldDark,
                    ),
                  ),
                ),
              ],
              if (drill.grammarNote != null) ...[
                const SizedBox(height: 10),
                Text(
                  drill.grammarNote!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Стандартная карточка речевого коммуникативного задания (Speech)
  Widget _buildSpeechCard(AudioDrill drill, DrillSessionProvider session, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          settings.label('СКАЖИТЕ ВСЛУХ (РЕЧЕВОЙ ДРИЛ):', 'ДАУЫСТАП АЙТЫҢЫЗ:'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.goldAccent(context),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          drill.promptRu,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.3,
            color: isDark ? Colors.white : AppColors.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Блок с казахской фразой и транскрипцией (ВИДИМ ВСЕГДА ДЛЯ ЧТЕНИЯ И САМОПРОВЕРКИ)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.gold.withAlpha(80) : AppColors.goldDark.withAlpha(60),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Text(
                drill.targetKk,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.goldLight : AppColors.goldDark,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
              if (drill.phoneticTranscription != null || drill.targetKk.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '[ ${drill.phoneticTranscription ?? drill.targetKk} ]',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.tealLight : AppColors.tealDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              if (drill.grammarNote != null) ...[
                const SizedBox(height: 8),
                Text(
                  drill.grammarNote!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary(context),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCelebrationScreen(
    BuildContext context,
    DrillSessionProvider session,
    SettingsProvider settings,
  ) {
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
              Text(
                settings.label('Отлично! Урок дня завершен!', 'Керемет! Күн аяқталды!'),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldAccent(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                settings.label(
                  'Вы успешно отработали ${session.totalDrills} фраз вслух.\nНовые слова и фразы добавлены в интервальное повторение.',
                  'Сіз ${session.totalDrills} сөйлемді сәтті айтып шықтыңыз.\nЖаңа сөздер мен сөйлемдер интервалды қайталауға қосылды.',
                ),
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary(context),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  settings.label('Вернуться на главную', 'Басты бетке оралу'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
