import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// P3.1 SQLite-first — Local database for user progress.
///
/// This is the device-side truth for learning data.
/// Data is written here FIRST, then synced to API in background.
/// Backup/restore reads/writes this database.
///
/// Tables: word_records, wordbook_progress, daily_checkins,
///         custom_wordbooks, vocabulary_notebook
class LocalDatabase {
  static LocalDatabase? _instance;
  static Database? _db;

  LocalDatabase._();

  /// Initialize the database. Must be called before runApp.
  static Future<LocalDatabase> initialize() async {
    if (_instance != null) return _instance!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'meow_progress.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );

    _instance = LocalDatabase._();
    return _instance!;
  }

  /// Get the singleton instance. Must call initialize() first.
  static LocalDatabase get instance {
    assert(_instance != null, 'LocalDatabase not initialized. Call initialize() first.');
    return _instance!;
  }

  /// Get the raw database (for testing or advanced queries).
  Database get db {
    assert(_db != null, 'Database not opened.');
    return _db!;
  }

  static Future<void> _createTables(Database db, int version) async {
    // 学习记录（核心）
    await db.execute('''
      CREATE TABLE word_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        study_type TEXT NOT NULL DEFAULT 'new',
        action_result TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_wr_word_id ON word_records(word_id)');
    await db.execute('CREATE INDEX idx_wr_synced ON word_records(synced)');

    // 词书进度（核心）
    await db.execute('''
      CREATE TABLE wordbook_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id TEXT NOT NULL UNIQUE,
        total_words INTEGER NOT NULL DEFAULT 0,
        completed_words INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // 签到记录
    await db.execute('''
      CREATE TABLE daily_checkins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        checked_in INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // 自定义词书
    await db.execute('''
      CREATE TABLE custom_wordbooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        word_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 生词本
    await db.execute('''
      CREATE TABLE vocabulary_notebook (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        meaning TEXT,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ==================== Word Records (核心) ====================

  /// Insert a study attempt record.
  ///
  /// [sessionId] (Need #8) is the local Sessions.id this attempt belongs to,
  /// or null when the attempt happens outside any active session
  /// (legacy / pre-migration data — backend falls back to time-window match).
  Future<int> insertWordRecord({
    required String wordId,
    required String bookId,
    required String studyType,
    required String actionResult,
    String? sessionId,
  }) async {
    // If this word already has a record, update it (forgot → know upgrade)
    final existing = await _db!.query(
      'word_records',
      where: 'word_id = ? AND study_type = ?',
      whereArgs: [wordId, studyType],
    );

    if (existing.isNotEmpty) {
      final existingResult = existing.first['action_result'] as String;
      if (existingResult == actionResult) {
        return existing.first['id'] as int; // Already exists, same result
      }
      // Update: e.g., forgot → know
      final updateValues = <String, Object?>{
        'action_result': actionResult,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'synced': 0,
      };
      if (sessionId != null) updateValues['session_id'] = sessionId;
      await _db!.update(
        'word_records',
        updateValues,
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      return existing.first['id'] as int;
    }

    return await _db!.insert('word_records', {
      'word_id': wordId,
      'book_id': bookId,
      'study_type': studyType,
      'action_result': actionResult,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'synced': 0,
      if (sessionId != null) 'session_id': sessionId,
    });
  }

  /// Get word IDs where action_result = 'know' (mastered).
  Future<Set<String>> getMasteredWordIds() async {
    final rows = await _db!.query(
      'word_records',
      columns: ['word_id'],
      where: "action_result = 'know' AND study_type = 'new'",
    );
    return rows.map((r) => r['word_id'] as String).toSet();
  }

  /// Get all unsynced records.
  Future<List<Map<String, dynamic>>> getUnsyncedRecords() async {
    return await _db!.query('word_records', where: 'synced = 0');
  }

  /// Mark a record as synced.
  Future<void> markSynced(int id) async {
    await _db!.update('word_records', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  /// Bug 4 — Distinct word_id values for `study_type='new'` rated TODAY,
  /// regardless of action_result (`know` or `forgot` both count).
  ///
  /// Used by StudyPage as the canonical "unique new words served today"
  /// gate so the daily goal cannot be exceeded by repeatedly tapping
  /// 不认识/模糊. The window is the user's LOCAL calendar day,
  /// converted to UTC bounds since `created_at` is stored as UTC ISO-8601
  /// (matches [countTodayNewCompleted]'s timezone handling).
  Future<Set<String>> getTodayServedNewWordIds() async {
    final now = DateTime.now();
    final localMidnight = DateTime(now.year, now.month, now.day);
    final nextLocalMidnight = localMidnight.add(const Duration(days: 1));
    final startUtcIso = localMidnight.toUtc().toIso8601String();
    final endUtcIso = nextLocalMidnight.toUtc().toIso8601String();
    final rows = await _db!.rawQuery(
      "SELECT DISTINCT word_id FROM word_records "
      "WHERE study_type = 'new' "
      "AND created_at >= ? AND created_at < ?",
      [startUtcIso, endUtcIso],
    );
    return rows.map((r) => r['word_id'] as String).toSet();
  }

  /// Count new words successfully studied today.
  /// Used as offline fallback for [TodayState.todayNewCompleted].
  ///
  /// "Today" means the user's LOCAL calendar day. Since [created_at] is stored
  /// as UTC ISO-8601 strings, we convert local midnight boundaries to UTC and
  /// do a range query — this is correct for every timezone.
  ///
  /// Using a LIKE '{localDate}%' pattern here is WRONG: in UTC+8, records
  /// written during local 00:00–07:59 have UTC dates of the previous day,
  /// so a LIKE match against the local date misses them and progress
  /// silently resets to 0 for several hours each morning.
  Future<int> countTodayNewCompleted() async {
    final now = DateTime.now();
    final localMidnight = DateTime(now.year, now.month, now.day);
    final nextLocalMidnight = localMidnight.add(const Duration(days: 1));
    final startUtcIso = localMidnight.toUtc().toIso8601String();
    final endUtcIso = nextLocalMidnight.toUtc().toIso8601String();
    final rows = await _db!.rawQuery(
      "SELECT COUNT(*) AS cnt FROM word_records "
      "WHERE study_type = 'new' AND action_result = 'know' "
      "AND created_at >= ? AND created_at < ?",
      [startUtcIso, endUtcIso],
    );
    return (rows.first['cnt'] as int?) ?? 0;
  }

  /// Get all word records (for export).
  Future<List<Map<String, dynamic>>> getAllWordRecords() async {
    return await _db!.query('word_records', orderBy: 'created_at ASC');
  }

  /// Replace all word records (for restore). Transactional.
  Future<void> replaceAllWordRecords(List<Map<String, dynamic>> records) async {
    await _db!.transaction((txn) async {
      await txn.delete('word_records');
      for (final r in records) {
        await txn.insert('word_records', {
          'word_id': r['word_id'] ?? '',
          'book_id': r['book_id'] ?? '',
          'study_type': r['study_type'] ?? 'new',
          'action_result': r['action_result'] ?? 'forgot',
          'created_at': r['created_at'] ?? DateTime.now().toUtc().toIso8601String(),
          'synced': r['synced'] ?? 1, // Restored data considered synced
        });
      }
    });
  }

  // ==================== Generic table operations (for other tables) ====================

  /// Get all rows from a table (for export).
  Future<List<Map<String, dynamic>>> getAllFromTable(String table) async {
    return await _db!.query(table);
  }

  /// Replace all rows in a table (for restore). Transactional.
  Future<void> replaceAllInTable(String table, List<Map<String, dynamic>> records) async {
    await _db!.transaction((txn) async {
      await txn.delete(table);
      for (final r in records) {
        await txn.insert(table, r);
      }
    });
  }

  /// Count rows in a table.
  Future<int> countRows(String table) async {
    final result = await _db!.rawQuery('SELECT COUNT(*) as cnt FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== Lifecycle ====================

  /// Close the database.
  Future<void> close() async {
    await _db?.close();
    _db = null;
    _instance = null;
  }

  /// Delete the database file (for testing).
  static Future<void> deleteDatabase_() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'meow_progress.db');
    await deleteDatabase(path);
    _db = null;
    _instance = null;
  }
}
