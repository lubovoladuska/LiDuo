import 'package:flutter/foundation.dart';
import '../data/database/app_database.dart';
import '../data/models/user_stats.dart';

/// Провайдер статистики пользователя, прогресса и уровня владения речью
class StatsProvider extends ChangeNotifier {
  UserStats _stats = UserStats(
    lastActiveDate: DateTime.now().toIso8601String().substring(0, 10),
  );
  Set<int> _completedDays = {};
  bool _isLoading = true;

  UserStats get stats => _stats;
  Set<int> get completedDays => _completedDays;
  bool get isLoading => _isLoading;

  /// Процент готовности к разговорной речи (0.0 - 100.0)
  double get fluencyScore => _stats.fluencyScore;

  /// Номер текущего дня по плану (1 - 90)
  int get currentDay => _stats.currentDay;

  /// Дней в ударном режиме (Стрик)
  int get streakDays => _stats.streakDays;

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();

    _stats = await AppDatabase.instance.getUserStats();
    _completedDays = await AppDatabase.instance.getCompletedDays();

    _checkAndAdvanceStreak();

    _isLoading = false;
    notifyListeners();
  }

  void _checkAndAdvanceStreak() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_stats.lastActiveDate.isEmpty) {
      _stats = _stats.copyWith(lastActiveDate: today);
      AppDatabase.instance.updateUserStats(_stats);
      return;
    }

    final lastDate = DateTime.tryParse(_stats.lastActiveDate);
    if (lastDate != null) {
      final now = DateTime.now();
      final difference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;

      if (difference == 1) {
        // Занимается подряд на следующий день!
        _stats = _stats.copyWith(
          streakDays: _stats.streakDays + 1,
          lastActiveDate: today,
        );
        AppDatabase.instance.updateUserStats(_stats);
      } else if (difference > 1) {
        // Пропустил более 1 дня — стрик сбрасывается на 1
        _stats = _stats.copyWith(
          streakDays: 1,
          lastActiveDate: today,
        );
        AppDatabase.instance.updateUserStats(_stats);
      }
    }
  }

  Future<void> onDayCompleted(int dayNumber, int drillsCount, int minutes) async {
    await AppDatabase.instance.markDayCompleted(dayNumber);
    _completedDays.add(dayNumber);

    // Рассчитываем прирост уровня владения речью:
    // 90 дней дают 100% готовности, плюс бонус за количество пройденных дрилов
    final newDay = (dayNumber + 1).clamp(1, 90);
    final calculatedFluency = ((_completedDays.length / 90.0) * 100.0).clamp(1.0, 100.0);

    _stats = _stats.copyWith(
      currentDay: newDay,
      totalDrillsCompleted: _stats.totalDrillsCompleted + drillsCount,
      minutesPracticed: _stats.minutesPracticed + minutes,
      fluencyScore: double.parse(calculatedFluency.toStringAsFixed(1)),
      lastActiveDate: DateTime.now().toIso8601String().substring(0, 10),
    );

    await AppDatabase.instance.updateUserStats(_stats);
    notifyListeners();
  }

  Future<void> onReviewsCompleted(int count) async {
    _stats = _stats.copyWith(
      totalReviewsCompleted: _stats.totalReviewsCompleted + count,
    );
    await AppDatabase.instance.updateUserStats(_stats);
    notifyListeners();
  }
}
