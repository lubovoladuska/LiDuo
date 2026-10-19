/// Модель карточки для интервального повторения фраз и чанков
class SrsCard {
  final String id;
  final String frontPrompt; // Вопрос или фраза на русском ("Здравствуйте")
  final String backTarget;  // Целевая фраза на казахском ("Сәлеметсіз бе")
  final String? note;       // Пояснение или формула
  final int repetition;     // Количество успешных повторений подряд
  final int intervalDays;   // Текущий интервал в днях
  final double easeFactor;  // Коэффициент сложности (по умолчанию 2.5)
  final DateTime nextReviewDate; // Дата следующего повторения
  final DateTime? lastReviewedDate;

  const SrsCard({
    required this.id,
    required this.frontPrompt,
    required this.backTarget,
    this.note,
    this.repetition = 0,
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    required this.nextReviewDate,
    this.lastReviewedDate,
  });

  factory SrsCard.fromMap(Map<String, dynamic> map) {
    return SrsCard(
      id: map['id'] as String,
      frontPrompt: map['front_prompt'] as String,
      backTarget: map['back_target'] as String,
      note: map['note'] as String?,
      repetition: map['repetition'] as int? ?? 0,
      intervalDays: map['interval_days'] as int? ?? 0,
      easeFactor: (map['ease_factor'] as num?)?.toDouble() ?? 2.5,
      nextReviewDate: DateTime.parse(map['next_review_date'] as String),
      lastReviewedDate: map['last_reviewed_date'] != null
          ? DateTime.parse(map['last_reviewed_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'front_prompt': frontPrompt,
      'back_target': backTarget,
      'note': note,
      'repetition': repetition,
      'interval_days': intervalDays,
      'ease_factor': easeFactor,
      'next_review_date': nextReviewDate.toIso8601String(),
      'last_reviewed_date': lastReviewedDate?.toIso8601String(),
    };
  }

  SrsCard copyWith({
    String? id,
    String? frontPrompt,
    String? backTarget,
    String? note,
    int? repetition,
    int? intervalDays,
    double? easeFactor,
    DateTime? nextReviewDate,
    DateTime? lastReviewedDate,
  }) {
    return SrsCard(
      id: id ?? this.id,
      frontPrompt: frontPrompt ?? this.frontPrompt,
      backTarget: backTarget ?? this.backTarget,
      note: note ?? this.note,
      repetition: repetition ?? this.repetition,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewedDate: lastReviewedDate ?? this.lastReviewedDate,
    );
  }
}
