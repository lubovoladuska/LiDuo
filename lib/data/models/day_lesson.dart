import 'audio_drill.dart';
import 'vocab_item.dart';

export 'vocab_item.dart';

/// Модель урока конкретного дня из 90-дневной программы
class DayLesson {
  final int dayNumber;
  final int weekNumber;
  final String title;
  final String grammarFormula;
  final String grammarExplanation;
  final List<AudioDrill> drills;
  final List<VocabItem> vocabList;
  final Map<String, String> keyVocabulary;

  const DayLesson({
    required this.dayNumber,
    required this.weekNumber,
    required this.title,
    required this.grammarFormula,
    required this.grammarExplanation,
    required this.drills,
    this.vocabList = const [],
    this.keyVocabulary = const {},
  });

  factory DayLesson.fromJson(Map<String, dynamic> json) {
    // Безопасный парсинг списка слов
    List<VocabItem> parsedVocabList = [];
    if (json['vocabList'] != null && json['vocabList'] is List) {
      parsedVocabList = (json['vocabList'] as List<dynamic>)
          .map((v) => VocabItem.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    // Совместимость с keyVocabulary
    Map<String, String> parsedKeyVocab = {};
    if (json['keyVocabulary'] != null && json['keyVocabulary'] is Map) {
      parsedKeyVocab = (json['keyVocabulary'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v.toString()),
      );
    } else if (parsedVocabList.isNotEmpty) {
      for (final v in parsedVocabList) {
        parsedKeyVocab[v.wordKk] = v.translationRu;
      }
    }

    // Если vocabList был пуст, но был keyVocabulary, синтезируем vocabList
    if (parsedVocabList.isEmpty && parsedKeyVocab.isNotEmpty) {
      parsedVocabList = parsedKeyVocab.entries
          .map((e) => VocabItem(wordKk: e.key, translationRu: e.value))
          .toList();
    }

    return DayLesson(
      dayNumber: json['dayNumber'] as int,
      weekNumber: json['weekNumber'] as int,
      title: json['title'] as String,
      grammarFormula: json['grammarFormula'] as String,
      grammarExplanation: json['grammarExplanation'] as String,
      drills: (json['drills'] as List<dynamic>?)
              ?.map((d) => AudioDrill.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      vocabList: parsedVocabList,
      keyVocabulary: parsedKeyVocab,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayNumber': dayNumber,
      'weekNumber': weekNumber,
      'title': title,
      'grammarFormula': grammarFormula,
      'grammarExplanation': grammarExplanation,
      'drills': drills.map((d) => d.toJson()).toList(),
      'vocabList': vocabList.map((v) => v.toJson()).toList(),
      'keyVocabulary': keyVocabulary,
    };
  }
}
