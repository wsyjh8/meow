import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../auth/auth_storage.dart';

/// P3.1 SQLite-first — Local database for user progress.
///
/// This is the device-side truth for learning data.
/// Data is written here FIRST, then synced to API in background.
/// Backup/restore reads/writes this database.
///
/// Tables: word_records, wordbook_progress, daily_checkins,
///         custom_wordbooks, vocabulary_notebook
///
/// 需求 23 Phase C PR-C-α (plan-023-C-v2 D1 + §4.0): schema 创建权完全
/// 让渡给 drift。这里的 `onCreate` 改为 no-op，drift 的 `m.createAll()`
/// 在 fresh install 路径上独占建表。原因：v1 D1 选 Option B 但没动
/// `_createTables`，导致 fresh install 启动时先由 raw sqflite 建出无
/// `user_id` 列的 5 张 legacy 表，drift onCreate 因 `IF NOT EXISTS` 跳
/// 过——结果 fresh install 永远拿不到 v13 schema。strip 之后 drift 是
/// 唯一 schema owner，PR-C-α main.dart 的强制 drift 初始化 + PRAGMA
/// assert 共同保证 fresh install 5 张 legacy 表也带 `user_id`。
class LocalDatabase {
  static LocalDatabase? _instance;
  static Database? _db;

  LocalDatabase._();

  /// Initialize the database. Must be called before runApp.
  static Future<LocalDatabase> initialize() async {
    if (_instance != null) return _instance!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'meow_progress.db');

    // 需求 23 Phase C PR-C-α: keep `version: 1` for compatibility with
    // existing devices (sqflite tracks user_version separately from
    // drift's PRAGMA user_version on the same file); the `onCreate` hook
    // is intentionally a no-op now — drift owns schema creation. The
    // file may not have any tables yet when this returns; main.dart MUST
    // force-init drift right after, before any DAO call.
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

  /// TEST-ONLY bridge for PR-C-α.
  ///
  /// In production [initialize] opens an empty file and main.dart
  /// immediately constructs [AppDatabase], whose drift onCreate creates
  /// the v13 schema (including the 5 legacy tables WITH `user_id`).
  /// Tests that exercise LocalDatabase methods WITHOUT also opening
  /// AppDatabase on the same file have no other source of the schema —
  /// drift owns it, but in-memory drift in tests is a separate DB.
  ///
  /// This helper plugs that gap by emitting the v13 schema for the 5
  /// legacy tables inline. The SQL mirrors what drift's `m.createAll()`
  /// emits from [WordRecords] / [WordbookProgress] / [DailyCheckins] /
  /// [CustomWordbooks] / [VocabularyNotebook] table definitions — keep
  /// in sync if those drift classes change.
  ///
  /// **PR-C-β will retire this method** by collapsing the affected tests
  /// onto the repository layer (plan-023-C-v2 §4.4). Grep callers via
  /// `initializeForTesting` to track migration progress.
  @visibleForTesting
  static Future<LocalDatabase> initializeForTesting() async {
    if (_instance != null) return _instance!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'meow_progress.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // v13 schema for the 5 legacy tables. NOT NULL on user_id
        // matches drift's fresh-install behavior; the composite UNIQUE
        // on wordbook_progress / daily_checkins mirrors @TableIndex.
        await db.execute('''
          CREATE TABLE word_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            word_id TEXT NOT NULL,
            book_id TEXT NOT NULL,
            study_type TEXT NOT NULL DEFAULT 'new',
            action_result TEXT NOT NULL,
            created_at TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0,
            session_id TEXT
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_wr_word_id ON word_records(word_id)');
        await db.execute(
            'CREATE INDEX idx_wr_synced ON word_records(synced)');
        await db.execute(
            'CREATE INDEX idx_word_records_user ON word_records(user_id)');

        await db.execute('''
          CREATE TABLE wordbook_progress (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            book_id TEXT NOT NULL,
            total_words INTEGER NOT NULL DEFAULT 0,
            completed_words INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute(
            'CREATE UNIQUE INDEX idx_wordbook_progress_user_book '
            'ON wordbook_progress(user_id, book_id)');

        await db.execute('''
          CREATE TABLE daily_checkins (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            date TEXT NOT NULL,
            checked_in INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
            'CREATE UNIQUE INDEX idx_daily_checkins_user_date '
            'ON daily_checkins(user_id, date)');

        await db.execute('''
          CREATE TABLE custom_wordbooks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            name TEXT NOT NULL,
            word_count INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_custom_wordbooks_user '
            'ON custom_wordbooks(user_id)');

        await db.execute('''
          CREATE TABLE vocabulary_notebook (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            word TEXT NOT NULL,
            meaning TEXT,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_vocabulary_notebook_user '
            'ON vocabulary_notebook(user_id)');
      },
    );

    _instance = LocalDatabase._();
    return _instance!;
  }

  /// Get the raw database (for testing or advanced queries).
  Database get db {
    assert(_db != null, 'Database not opened.');
    return _db!;
  }

  /// No-op on purpose. See class-level comment for context: schema 创建权
  /// 完全 owned by drift onCreate. 保留方法签名是为了让 `openDatabase` 仍
  /// 接受一个 `onCreate` callback（v1 → v1 没有 onUpgrade，omitting onCreate
  /// 会触发 "no onCreate or onUpgrade" 警告）。fresh install 时 sqflite
  /// 打开空文件后调用这里——drift 紧接着会调 `createAll()` 把所有 20 张
  /// 表（含 v13 user_id schema）建好。
  static Future<void> _createTables(Database db, int version) async {
    // intentionally empty — drift owns schema
  }

  // ==================== Word Records (核心) ====================

  /// Insert a study attempt record.
  ///
  /// [sessionId] (Need #8) is the local Sessions.id this attempt belongs to,
  /// or null when the attempt happens outside any active session
  /// (legacy / pre-migration data — backend falls back to time-window match).
  ///
  /// PR-C-α transitional bridge: user_id is read from AuthStorage SP. The
  /// SELECT/UPDATE path here does NOT yet filter by user_id (partition
  /// leak); PR-C-β refactors LocalDatabase into a user-scoped DAO that
  /// takes userId at construction time and adds `WHERE user_id = ?` to
  /// all queries (plan-023-C-v2 §4.1 + §4.4).
  Future<int> insertWordRecord({
    required String wordId,
    required String bookId,
    required String studyType,
    required String actionResult,
    String? sessionId,
  }) async {
    final userId = await AuthStorage.readBoundUserIdOrPlaceholder();

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
      'user_id': userId,
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

  /// Today's "stuck forgots" — word_ids that have at least one `forgot`
  /// record today (study_type='new') AND have NO 'know' record at any
  /// point in time. Used by StudyPage to rehydrate the consolidation
  /// queue at session start, so words the user forgot in earlier
  /// sessions today don't get permanently stranded by the daily-goal cap.
  Future<Set<String>> getTodayStuckForgotIds() async {
    final now = DateTime.now();
    final localMidnight = DateTime(now.year, now.month, now.day);
    final nextLocalMidnight = localMidnight.add(const Duration(days: 1));
    final startUtcIso = localMidnight.toUtc().toIso8601String();
    final endUtcIso = nextLocalMidnight.toUtc().toIso8601String();
    final rows = await _db!.rawQuery(
      "SELECT DISTINCT word_id FROM word_records "
      "WHERE study_type = 'new' AND action_result = 'forgot' "
      "AND created_at >= ? AND created_at < ? "
      "AND word_id NOT IN ("
      "  SELECT word_id FROM word_records "
      "  WHERE study_type = 'new' AND action_result = 'know'"
      ")",
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
  ///
  /// PR-C-α transitional: each restored row is tagged with user_id from
  /// the snapshot (if present) or the bound user (fallback). PR-C-β will
  /// scope this to per-user via repository pattern.
  Future<void> replaceAllWordRecords(List<Map<String, dynamic>> records) async {
    final fallbackUserId = await AuthStorage.readBoundUserIdOrPlaceholder();
    await _db!.transaction((txn) async {
      await txn.delete('word_records');
      for (final r in records) {
        await txn.insert('word_records', {
          'user_id': r['user_id'] ?? fallbackUserId,
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
