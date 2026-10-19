/// Модель статистики пользователя и прогресса по 90-дневному марафону
class UserStats {
  final int currentDay;
  final int streakDays;
  final String lastActiveDate; // YYYY-MM-DD
  final int totalDrillsCompleted;
  final int totalReviewsCompleted;
  final int minutesPracticed;
  final double fluencyScore; // 0.0 - 100.0%

  const UserStats({
    this.currentDay = 1,
    this.streakDays = 1,
    required this.lastActiveDate,
    this.totalDrillsCompleted = 0,
    this.totalReviewsCompleted = 0,
    this.minutesPracticed = 0,
    this.fluencyScore = 1.0,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      currentDay: map['current_day'] as int? ?? 1,
      streakDays: map['streak_days'] as int? ?? 1,
      lastActiveDate: map['last_active_date'] as String? ?? '',
      totalDrillsCompleted: map['total_drills_completed'] as int? ?? 0,
      totalReviewsCompleted: map['total_reviews_completed'] as int? ?? 0,
      minutesPracticed: map['minutes_practiced'] as int? ?? 0,
      fluencyScore: (map['fluency_score'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'current_day': currentDay,
      'streak_days': streakDays,
      'last_active_date': lastActiveDate,
      'total_drills_completed': totalDrillsCompleted,
      'total_reviews_completed': totalReviewsCompleted,
      'minutes_practiced': minutesPracticed,
      'fluency_score': fluencyScore,
    };
  }

  UserStats copyWith({
    int? currentDay,
    int? streakDays,
    String? lastActiveDate,
    int? totalDrillsCompleted,
    int? totalReviewsCompleted,
    int? minutesPracticed,
    double? fluencyScore,
  }) {
    return UserStats(
      currentDay: currentDay ?? this.currentDay,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      totalDrillsCompleted: totalDrillsCompleted ?? this.totalDrillsCompleted,
      totalReviewsCompleted: totalReviewsCompleted ?? this.totalReviewsCompleted,
      minutesPracticed: minutesPracticed ?? this.minutesPracticed,
      fluencyScore: fluencyScore ?? this.fluencyScore,
    );
  }
}
