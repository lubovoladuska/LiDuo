import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/kazakh_phonetics.dart';
import '../../data/database/app_database.dart';
import '../../data/models/audio_drill.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';

/// Экран свободной тренировочной сессии практики речи
class DrillWorkoutScreen extends StatefulWidget {
  final List<AudioDrill> drills;
  final String workoutTitle;

  const DrillWorkoutScreen({
    super.key,
    required this.drills,
    required this.workoutTitle,
  });

  @override
  State<DrillWorkoutScreen> createState() => _DrillWorkoutScreenState();
}

class _DrillWorkoutScreenState extends State<DrillWorkoutScreen> {
  int _currentIndex = 0;
  bool _isListening = false;
  String _spokenText = '';
  double _similarityScore = 0.0;
  bool _isPassed = false;
  bool _showHint = false;
  int _correctCount = 0;
  bool _isFinished = false;

  AudioDrill get currentDrill => widget.drills[_currentIndex];

  Future<void> _playAudio() async {
    await TtsService.instance.speak(currentDrill.targetKk);
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
      _spokenText = '';
      _similarityScore = 0.0;
      _isPassed = false;
    });

    await SpeechService.instance.startListening(
      localeId: 'kk_KZ',
      onResult: (text) {
        setState(() {
          _spokenText = text;
          _evaluate(text);
        });
      },
    );
  }

  Future<void> _stopListening() async {
    await SpeechService.instance.stopListening();
    setState(() {
      _isListening = false;
      _evaluate(_spokenText);
    });
  }

  void _evaluate(String text) {
    if (text.trim().isEmpty) return;
    final score = KazakhPhonetics.similarity(text, currentDrill.targetKk);
    final match = KazakhPhonetics.isMatch(text, currentDrill.targetKk);

    setState(() {
      _similarityScore = score;
      _isPassed = match;
    });

    AppDatabase.instance.recordDrillAttempt(
      drillId: currentDrill.id,
      spokenText: text,
      targetText: currentDrill.targetKk,
      similarity: score,
      passed: match,
    );
  }

  void _manualPass() {
    setState(() {
      _isPassed = true;
      _similarityScore = 1.0;
    });

    AppDatabase.instance.recordDrillAttempt(
      drillId: currentDrill.id,
      spokenText: currentDrill.targetKk,
      targetText: currentDrill.targetKk,
      similarity: 1.0,
      passed: true,
    );
  }

  void _next() {
    if (_isPassed) {
      _correctCount++;
    }

    if (_currentIndex + 1 < widget.drills.length) {
      setState(() {
        _currentIndex++;
        _spokenText = '';
        _similarityScore = 0.0;
        _isPassed = false;
        _showHint = false;
      });
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      return _buildCompletionView();
    }

    final progress = (_currentIndex + 1) / widget.drills.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.workoutTitle} • ${_currentIndex + 1}/${widget.drills.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
              color: _showHint ? AppColors.gold : AppColors.textSecondary(context),
            ),
            onPressed: () => setState(() => _showHint = !_showHint),
            tooltip: 'Көмек / Подсказка',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearPercentIndicator(
              lineHeight: 6.0,
              percent: progress.clamp(0.0, 1.0),
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
                        children: [
                          if (currentDrill.type == DrillType.vocab) ...[
                            Text(
                              'СӨЗДІК БАЗА (СЛОВО ДНЯ):',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.tealAccent(context),
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              currentDrill.targetKk,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.goldAccent(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (currentDrill.phoneticTranscription != null || currentDrill.targetKk.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.transcriptionChip(context),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '[ ${currentDrill.phoneticTranscription ?? currentDrill.targetKk} ]',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Text(
                              currentDrill.promptRu,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else if (currentDrill.type == DrillType.slotSubstitution) ...[
                            Text(
                              'СӨЗДІ ҚАЛЫПҚА ҚОЙЫП АЙТЫҢЫЗ:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.goldAccent(context),
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              currentDrill.promptRu,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary(context),
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (currentDrill.slotTemplate != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.subtleContainer(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.gold.withAlpha(50)),
                                ),
                                child: Text(
                                  'Каркас: ${currentDrill.slotTemplate}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary(context),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            if (currentDrill.slotVariable != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.tealAccent(context)),
                                ),
                                child: Text(
                                  'Слот: «${currentDrill.slotVariable}»',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.tealAccent(context),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            // Всегда отображаем целевую фразу и транскрипцию
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.subtleContainer(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.gold.withAlpha(60),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    currentDrill.targetKk,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.goldAccent(context),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (currentDrill.phoneticTranscription != null || currentDrill.targetKk.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.transcriptionChip(context),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '[ ${currentDrill.phoneticTranscription ?? currentDrill.targetKk} ]',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ] else ...[
                            Text(
                              'АЙТЫҢЫЗ (СКАЖИТЕ ВСЛУХ):',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSecondary(context),
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currentDrill.promptRu,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary(context),
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            // Всегда отображаем целевую фразу и транскрипцию
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.subtleContainer(context),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.gold.withAlpha(60),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    currentDrill.targetKk,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.goldAccent(context),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (currentDrill.phoneticTranscription != null || currentDrill.targetKk.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.transcriptionChip(context),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '[ ${currentDrill.phoneticTranscription ?? currentDrill.targetKk} ]',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary(context),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: Icon(
                              Icons.volume_up_rounded,
                              color: AppColors.goldAccent(context),
                            ),
                            label: const Text('Үлгіні тыңдау (Эталон)'),
                            onPressed: _playAudio,
                          ),
                          if (_showHint && currentDrill.grammarNote != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.subtleContainer(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.tealAccent(context).withAlpha(80)),
                              ),
                              child: Text(
                                currentDrill.grammarNote!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.tealAccent(context),
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (_spokenText.isNotEmpty || _isListening)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isPassed
                                ? AppColors.success
                                : (_spokenText.isNotEmpty ? AppColors.warning : AppColors.gold),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isPassed
                                      ? Icons.check_circle_outline
                                      : (_spokenText.isNotEmpty ? Icons.refresh : Icons.graphic_eq),
                                  color: _isPassed
                                      ? AppColors.success
                                      : (_spokenText.isNotEmpty ? AppColors.warning : AppColors.gold),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isPassed
                                      ? 'Дұрыс! (${(_similarityScore * 100).toInt()}% сәйкестік)'
                                      : (_spokenText.isNotEmpty
                                          ? 'Қайталап көріңіз (${(_similarityScore * 100).toInt()}%)'
                                          : 'Тыңдап тұрмын... (Говорите)'),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: _isPassed
                                        ? AppColors.success
                                        : (_spokenText.isNotEmpty ? AppColors.warning : AppColors.gold),
                                  ),
                                ),
                              ],
                            ),
                            if (_spokenText.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '«$_spokenText»',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
                  ),
                ),
              ),
              child: _isPassed
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 24),
                        label: Text(
                          _currentIndex + 1 < widget.drills.length
                              ? 'Келесі сөйлем (Далее)'
                              : 'Жаттығуды аяқтау (Завершить)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        onPressed: _next,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_spokenText.isNotEmpty && !_isPassed)
                          TextButton(
                            onPressed: _manualPass,
                            child: Text(
                              'Дұрыс айттым\n(Засчитать)',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary(context)),
                            ),
                          ),

                        GestureDetector(
                          onTapDown: (_) => _startListening(),
                          onTapUp: (_) => _stopListening(),
                          onTapCancel: () => _stopListening(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _isListening ? 80 : 70,
                            height: _isListening ? 80 : 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isListening
                                    ? [AppColors.error, const Color(0xFFB91C1C)]
                                    : [AppColors.gold, AppColors.goldDark],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isListening ? AppColors.error : AppColors.gold).withAlpha(120),
                                  blurRadius: _isListening ? 24 : 12,
                                  spreadRadius: _isListening ? 4 : 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              size: 34,
                              color: AppColors.darkBackground,
                            ),
                          ),
                        ),

                        if (_spokenText.isNotEmpty && !_isPassed)
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: AppColors.gold),
                            onPressed: _startListening,
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

  Widget _buildCompletionView() {
    final percent = ((_correctCount / widget.drills.length) * 100).toInt();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 64), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                'Жаттығу аяқталды!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.goldAccent(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Нәтиже: $_correctCount / ${widget.drills.length} сөйлем ($percent% дәлдік).\nСіздің сөйлеу дағдыңыз белсенді түрде дамып жатыр!',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary(context), height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Жаттығуларға оралу', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
