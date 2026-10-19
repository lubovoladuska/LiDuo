import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/audio_drill.dart';
import '../models/day_lesson.dart';
import '../models/srs_card.dart';
import '../database/app_database.dart';

/// Репозиторий для загрузки и управления курсами (Course Packs)
class CourseRepository {
  static final CourseRepository instance = CourseRepository._init();
  final Map<int, DayLesson> _cachedLessons = {};
  Map<String, dynamic>? _grammarMatrix;

  CourseRepository._init();

  /// Загрузка урока для конкретного дня
  Future<DayLesson> getLessonForDay(int dayNumber) async {
    if (_cachedLessons.containsKey(dayNumber)) {
      return _cachedLessons[dayNumber]!;
    }

    final weekNumber = ((dayNumber - 1) ~/ 7) + 1;
    try {
      if (weekNumber == 1) {
        final jsonString = await rootBundle.loadString(
          'assets/courses/kazakh_90_days/weeks/week_01.json',
        );
        final Map<String, dynamic> data = jsonDecode(jsonString);
        final List<dynamic> daysList = data['days'] as List<dynamic>;

        for (final item in daysList) {
          final lesson = DayLesson.fromJson(item as Map<String, dynamic>);
          _cachedLessons[lesson.dayNumber] = lesson;
        }

        if (_cachedLessons.containsKey(dayNumber)) {
          return _cachedLessons[dayNumber]!;
        }
      }
    } catch (_) {
      // Использовать процедурный генератор уроков, если JSON не найден
    }

    // Процедурный генератор уроков для оставшихся дней 90-дневного силлабуса
    final lesson = _generateMilestoneLesson(dayNumber, weekNumber);
    _cachedLessons[dayNumber] = lesson;
    return lesson;
  }

  /// Загрузка грамматической матрицы (справочника окончаний и сингармонизма)
  Future<Map<String, dynamic>> getGrammarMatrix() async {
    if (_grammarMatrix != null) return _grammarMatrix!;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/courses/kazakh_90_days/grammar_matrix.json',
      );
      _grammarMatrix = jsonDecode(jsonString) as Map<String, dynamic>;
      return _grammarMatrix!;
    } catch (_) {
      return {};
    }
  }

  /// Автоматическое создание карточек интервального повторения (SRS) из урока
  Future<void> seedSrsCardsFromLesson(DayLesson lesson) async {
    final now = DateTime.now();
    for (final drill in lesson.drills) {
      final card = SrsCard(
        id: drill.id,
        frontPrompt: drill.promptRu,
        backTarget: drill.targetKk,
        note: drill.grammarNote,
        repetition: 0,
        intervalDays: 1,
        easeFactor: 2.5,
        nextReviewDate: now.add(const Duration(days: 1)),
      );
      await AppDatabase.instance.upsertSrsCard(card);
    }
  }

  /// Генерация уроков программы для фаз II и III (дорожная карта 90 дней)
  DayLesson _generateMilestoneLesson(int day, int week) {
    if (day <= 14) {
      return DayLesson(
        dayNumber: day,
        weekNumber: week,
        title: 'Притяжательность и множественность: -лар/-лер (День $day)',
        grammarFormula: 'Менің кітабым + Олардың үйлері',
        grammarExplanation:
            'Окончания множественности: -лар/-лер, -дар/-дер, -тар/-тер. Притяжательные аффиксы выражают принадлежность.',
        keyVocabulary: {
          'Кітап': 'Книга',
          'Үй': 'Дом',
          'Дос': 'Друг',
          'Жұмыс': 'Работа',
        },
        drills: [
          AudioDrill(
            id: 'd${day}_01',
            step: 1,
            promptRu: 'Скажите: «Мой друг»',
            targetKk: 'Менің досым',
            grammarNote: 'Дос + ым = мой друг.',
          ),
          AudioDrill(
            id: 'd${day}_02',
            step: 2,
            promptRu: 'Скажите: «Наш дом»',
            targetKk: 'Біздің үйіміз',
            grammarNote: 'Үй + іміз = наш дом.',
          ),
          AudioDrill(
            id: 'd${day}_03',
            step: 3,
            promptRu: 'Скажите: «Много друзей»',
            targetKk: 'Көп достар',
            grammarNote: 'После сонорной «с» окончание «-тар/-тер».',
          ),
        ],
      );
    } else if (day <= 28) {
      return DayLesson(
        dayNumber: day,
        weekNumber: week,
        title: 'Падежи действия в реальной речи (День $day)',
        grammarFormula: 'Дүкенге барамын + Үйден келдім',
        grammarExplanation:
            'Практическое применение Барыс септік (-ға/-ге) и Шығыс септік (-дан/-ден) в маршрутах по городу.',
        keyVocabulary: {
          'Дүкен': 'Магазин',
          'Базар': 'Рынок',
          'Қала': 'Город',
        },
        drills: [
          AudioDrill(
            id: 'd${day}_01',
            step: 1,
            promptRu: 'Скажите: «Я иду в магазин»',
            targetKk: 'Мен дүкенге барамын',
            grammarNote: 'Дүкен + ге (куда?).',
          ),
          AudioDrill(
            id: 'd${day}_02',
            step: 2,
            promptRu: 'Скажите: «Я пришел с работы»',
            targetKk: 'Мен жұмыстан келдім',
            grammarNote: 'Жұмыс + тан (откуда?).',
          ),
        ],
      );
    } else if (day <= 60) {
      return DayLesson(
        dayNumber: day,
        weekNumber: week,
        title: 'Времена, желания и бытовые ситуации (День $day)',
        grammarFormula: 'Шай ішкім келеді + Қазақша сөйлесе аламын',
        grammarExplanation:
            'Конструкция желания: основа глагола + -ғым/-гім келеді. Модальность возможности: -а аламын.',
        keyVocabulary: {
          'Шай': 'Чай',
          'Ішу': 'Пить',
          'Сөйлесу': 'Разговаривать',
        },
        drills: [
          AudioDrill(
            id: 'd${day}_01',
            step: 1,
            promptRu: 'Скажите: «Я хочу выпить чаю»',
            targetKk: 'Менің шай ішкім келеді',
            grammarNote: 'Іш + кім келеді = хочу пить.',
          ),
          AudioDrill(
            id: 'd${day}_02',
            step: 2,
            promptRu: 'Скажите: «Я хочу говорить по-казахски»',
            targetKk: 'Менің қазақша сөйлескім келеді',
            grammarNote: 'Сөйлес + кім келеді.',
          ),
        ],
      );
    } else {
      return DayLesson(
        dayNumber: day,
        weekNumber: week,
        title: 'Свободная речь, дискуссии и идиомы B1/B2 (День $day)',
        grammarFormula: 'Менің ойымша + Өйткені + Сондықтан',
        grammarExplanation:
            'Аргументация, выражение личной позиции и беглая спонтанная речь без языкового барьера.',
        keyVocabulary: {
          'Ой': 'Мысль',
          'Менің ойымша': 'По моему мнению',
          'Өйткені': 'Потому что',
        },
        drills: [
          AudioDrill(
            id: 'd${day}_01',
            step: 1,
            promptRu: 'Скажите: «По моему мнению, это очень важно»',
            targetKk: 'Менің ойымша, бұл өте маңызды',
            grammarNote: 'Конструкция выражения мнения.',
          ),
        ],
      );
    }
  }
}
