import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/course_repository.dart';
import '../../services/tts_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Грамматикалық матрица'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: AppColors.textSecondaryDark,
          tabs: const [
            Tab(text: '7 Падеж'),
            Tab(text: 'Сингармонизм'),
            Tab(text: 'Личные окончания'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCasesTab(),
                _buildHarmonyTab(),
                _buildPersonalEndingsTab(),
              ],
            ),
    );
  }

  Widget _buildCasesTab() {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up, size: 20, color: AppColors.gold),
                    onPressed: () {
                      final ex = item['example']?.toString() ?? '';
                      if (ex.isNotEmpty) TtsService.instance.speak(ex);
                    },
                    tooltip: 'Тыңдау',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Сұрақтары: ${item['questions']}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Жалғаулары: ${item['endings']}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tealLight,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Мысалы: ${item['example']}',
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHarmonyTab() {
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
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Закон сингармонизма (Үндестік заңы)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.gold),
              ),
              SizedBox(height: 6),
              Text(
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
                  'Дыбыстар: ${r['vowels']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.tealLight,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  r['rule'] ?? '',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Мысал: ${r['example']}',
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.gold),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPersonalEndingsTab() {
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.gold),
              ),
              const SizedBox(height: 6),
              Text(
                'Жалғаулары: ${item['endings']}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Мысалы: ${item['example']}',
                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.tealLight),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
