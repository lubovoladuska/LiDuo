import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/srs_card.dart';
import '../models/user_stats.dart';

/// Локальная база данных SQLite для LiDuo
/// Полностью автономная (Offline-First), поддерживает Android, iOS, Windows, Linux, macOS.
class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('liduo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String basePath;
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      basePath = appDocDir.path;
    } catch (_) {
      final userProfile = Platform.environment['USERPROFILE'] ??
          Platform.environment['APPDATA'] ??
          '.';
      basePath = p.join(userProfile, 'Documents');
    }

    final path = p.join(basePath, 'LiDuo', filePath);
    final dir = Directory(p.dirname(path));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
      ),
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Таблица статистики пользователя
    await db.execute('''
      CREATE TABLE user_stats (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        current_day INTEGER NOT NULL DEFAULT 1,
        streak_days INTEGER NOT NULL DEFAULT 1,
        last_active_date TEXT NOT NULL,
        total_drills_completed INTEGER NOT NULL DEFAULT 0,
        total_reviews_completed INTEGER NOT NULL DEFAULT 0,
        minutes_practiced INTEGER NOT NULL DEFAULT 0,
        fluency_score REAL NOT NULL DEFAULT 1.0
      )
    ''');

    // Таблица карточек интервального повторения (SRS)
    await db.execute('''
      CREATE TABLE srs_cards (
        id TEXT PRIMARY KEY,
        front_prompt TEXT NOT NULL,
        back_target TEXT NOT NULL,
        note TEXT,
        repetition INTEGER NOT NULL DEFAULT 0,
        interval_days INTEGER NOT NULL DEFAULT 0,
        ease_factor REAL NOT NULL DEFAULT 2.5,
        next_review_date TEXT NOT NULL,
        last_reviewed_date TEXT
      )
    ''');

    // Таблица завершенных дней курса
    await db.execute('''
      CREATE TABLE completed_days (
        day_number INTEGER PRIMARY KEY,
        completed_at TEXT NOT NULL,
        score REAL NOT NULL DEFAULT 1.0
      )
    ''');

    // Таблица истории речевых дрилов
    await db.execute('''
      CREATE TABLE drill_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        drill_id TEXT NOT NULL,
        spoken_text TEXT NOT NULL,
        target_text TEXT NOT NULL,
        similarity REAL NOT NULL,
        passed INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Инициализация начальной строки статистики
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await db.insert('user_stats', {
      'id': 1,
      'current_day': 1,
      'streak_days': 1,
      'last_active_date': today,
      'total_drills_completed': 0,
      'total_reviews_completed': 0,
      'minutes_practiced': 0,
      'fluency_score': 1.0,
    });
  }

  // --- Методы статистики пользователя ---

  Future<UserStats> getUserStats() async {
    final db = await database;
    final maps = await db.query('user_stats', where: 'id = ?', whereArgs: [1]);
    if (maps.isNotEmpty) {
      return UserStats.fromMap(maps.first);
    }
    return UserStats(
      lastActiveDate: DateTime.now().toIso8601String().substring(0, 10),
    );
  }

  Future<void> updateUserStats(UserStats stats) async {
    final db = await database;
    await db.update(
      'user_stats',
      stats.toMap(),
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  // --- Методы карточек SRS ---

  Future<void> upsertSrsCard(SrsCard card) async {
    final db = await database;
    await db.insert(
      'srs_cards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SrsCard>> getDueSrsCards(DateTime now) async {
    final db = await database;
    final nowIso = now.toIso8601String();
    final maps = await db.query(
      'srs_cards',
      where: 'next_review_date <= ?',
      whereArgs: [nowIso],
      orderBy: 'next_review_date ASC',
    );
    return maps.map((m) => SrsCard.fromMap(m)).toList();
  }

  Future<int> getTotalSrsCardsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM srs_cards');
    if (result.isNotEmpty && result.first.values.isNotEmpty) {
      return (result.first.values.first as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  // --- Методы завершенных дней ---

  Future<void> markDayCompleted(int dayNumber, {double score = 1.0}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'completed_days',
      {
        'day_number': dayNumber,
        'completed_at': now,
        'score': score,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Set<int>> getCompletedDays() async {
    final db = await database;
    final maps = await db.query('completed_days');
    return maps.map((m) => m['day_number'] as int).toSet();
  }

  // --- Запись попытки дрила ---

  Future<void> recordDrillAttempt({
    required String drillId,
    required String spokenText,
    required String targetText,
    required double similarity,
    required bool passed,
  }) async {
    final db = await database;
    await db.insert('drill_history', {
      'drill_id': drillId,
      'spoken_text': spokenText,
      'target_text': targetText,
      'similarity': similarity,
      'passed': passed ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
