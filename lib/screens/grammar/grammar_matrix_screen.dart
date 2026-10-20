import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/course_repository.dart';
import '../../providers/settings_provider.dart';

/// Интерактивный справочник грамматической матрицы и сингармонизма
class GrammarMatrixScreen extends StatefulWidget {
  const GrammarMatrixScreen({super.key});

  @override
  State<GrammarMatrixScreen> createState() => _GrammarMatrixScreenState();
}

class _GrammarMatrixScreenState extends State<GrammarMatrixScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _matrixData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMatrix();
  }

  Future<void> _loadMatrix() async {
    final data = await CourseRepository.instance.getGrammarMatrix();
    if (mounted) {
      setState(() {
        _matrixData = data;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.label('Матрица грамматики', 'Грамматикалық матрица')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldAccent(context),
          labelColor: AppColors.goldAccent(context),
          unselectedLabelColor: AppColors.textSecondary(context),
          tabs: [
            Tab(text: settings.label('7 Падежей', '7 Септік')),
            Tab(text: settings.label('Сингармонизм', 'Үндестік')),
            Tab(text: settings.label('Личные окончания', 'Жіктік жалғау')),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCasesTab(settings),
                _buildHarmonyTab(settings),
                _buildPersonalEndingsTab(settings),
              ],
            ),
    );
  }

  Widget _buildCasesTab(SettingsProvider settings) {
    final List<dynamic> cases = _matrixData['cases'] as List<dynamic>? ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final item = cases[index] as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['name'] ?? '',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldAccent(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                settings.label('Вопросы: ${item['questions']}', 'Сұрақтары: ${item['questions']}'),
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: 4),
              Text(
                settings.label('Окончания: ${item['endings']}', 'Жалғаулары: ${item['endings']}'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tealAccent(context),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.subtleContainer(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  settings.label('Пример: ${item['example']}', 'Мысалы: ${item['example']}'),
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHarmonyTab(SettingsProvider settings) {
    final List<dynamic> rules = _matrixData['harmonyRules'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.gold.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settings.label('Закон сингармонизма', 'Үндестік заңы'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.goldAccent(context)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Казахский язык подчиняется железному закону созвучия: в одном слове и его аффиксах могут быть гласные ТОЛЬКО твердого ряда, либо ТОЛЬКО мягкого ряда.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...rules.map((rule) {
          final r = rule as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['type'] ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  settings.label('Звуки: ${r['vowels']}', 'Дыбыстар: ${r['vowels']}'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.tealAccent(context),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  r['rule'] ?? '',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary(context)),
                ),
                const SizedBox(height: 8),
                Text(
                  settings.label('Пример: ${r['example']}', 'Мысал: ${r['example']}'),
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.goldAccent(context)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPersonalEndingsTab(SettingsProvider settings) {
    final List<dynamic> endings = _matrixData['personalEndings'] as List<dynamic>? ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: endings.length,
      itemBuilder: (context, index) {
        final item = endings[index] as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerTheme.color ?? AppColors.darkBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['pronoun'] ?? '',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.goldAccent(context)),
              ),
              const SizedBox(height: 6),
              Text(
                settings.label('Окончания: ${item['endings']}', 'Жалғаулары: ${item['endings']}'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.subtleContainer(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  settings.label('Пример: ${item['example']}', 'Мысалы: ${item['example']}'),
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.tealAccent(context)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
