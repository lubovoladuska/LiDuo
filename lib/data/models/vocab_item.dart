/// Модель элемента активного словарного запаса урока
class VocabItem {
  final String wordKk;
  final String translationRu;
  final String? phonetic;
  final String? exampleSentence;
  final String? audioKey;

  const VocabItem({
    required this.wordKk,
    required this.translationRu,
    this.phonetic,
    this.exampleSentence,
    this.audioKey,
  });

  factory VocabItem.fromJson(Map<String, dynamic> json) {
    return VocabItem(
      wordKk: json['wordKk'] as String,
      translationRu: json['translationRu'] as String,
      phonetic: json['phonetic'] as String?,
      exampleSentence: json['exampleSentence'] as String?,
      audioKey: json['audioKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wordKk': wordKk,
      'translationRu': translationRu,
      'phonetic': phonetic,
      'exampleSentence': exampleSentence,
      'audioKey': audioKey,
    };
  }
}
