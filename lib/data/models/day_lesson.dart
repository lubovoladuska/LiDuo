import 'audio_drill.dart';

/// Модель урока конкретного дня из 90-дневной программы
class DayLesson {
  final int dayNumber;
  final int weekNumber;
  final String title;
  final String grammarFormula;
  final String grammarExplanation;
  final List<AudioDrill> drills;
  final Map<String, String> keyVocabulary;

  const DayLesson({
    required this.dayNumber,
    required this.weekNumber,
    required this.title,
    required this.grammarFormula,
    required this.grammarExplanation,
    required this.drills,
    this.keyVocabulary = const {},
  });

  factory DayLesson.fromJson(Map<String, dynamic> json) {
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
      keyVocabulary: (json['keyVocabulary'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
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
      'keyVocabulary': keyVocabulary,
    };
  }
}
