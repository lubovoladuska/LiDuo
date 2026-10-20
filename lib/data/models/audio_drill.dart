/// Типы практических упражнений в спринте
enum DrillType {
  /// Изучение нового ключевого слова с транскрипцией и аудио
  vocab,

  /// Быстрая подстановка переменного слова в грамматический каркас
  slotSubstitution,

  /// Восприятие на слух с маскированным текстом и повторением эхом
  listening,

  /// Полноценный ситуативный речевой дрил
  speech,
}

/// Модель единицы речевого аудио-дрила
class AudioDrill {
  final String id;
  final int step;
  final String promptRu;
  final String targetKk;
  final DrillType type;
  final String? slotVariable;
  final String? slotTemplate;
  final String? phoneticTranscription;
  final String? grammarNote;
  final String? audioKey;

  const AudioDrill({
    required this.id,
    required this.step,
    required this.promptRu,
    required this.targetKk,
    this.type = DrillType.speech,
    this.slotVariable,
    this.slotTemplate,
    this.phoneticTranscription,
    this.grammarNote,
    this.audioKey,
  });

  factory AudioDrill.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final drillType = DrillType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => DrillType.speech,
    );

    return AudioDrill(
      id: json['id'] as String,
      step: json['step'] as int? ?? 1,
      promptRu: json['promptRu'] as String,
      targetKk: json['targetKk'] as String,
      type: drillType,
      slotVariable: json['slotVariable'] as String?,
      slotTemplate: json['slotTemplate'] as String?,
      phoneticTranscription: json['phoneticTranscription'] as String?,
      grammarNote: json['grammarNote'] as String?,
      audioKey: json['audioKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'step': step,
      'promptRu': promptRu,
      'targetKk': targetKk,
      'type': type.name,
      'slotVariable': slotVariable,
      'slotTemplate': slotTemplate,
      'phoneticTranscription': phoneticTranscription,
      'grammarNote': grammarNote,
      'audioKey': audioKey,
    };
  }
}
