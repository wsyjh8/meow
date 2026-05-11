import 'package:flutter/foundation.dart';
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
///
/// 需求 23 Phase C PR-C-α (plan-023-C-v2 D1 + §4.0): schema 创建权完全
/// 让渡给 drift。这里的 `onCreate` 改为 no-op，drift 的 `m.createAll()`
/// 在 fresh install 路径上独占建表。strip 之后 drift 是唯一 schema owner.
///
/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.1): every method that
/// touches a user-scoped table now takes an explicit `String userId`
/// argument and filters with `WHERE user_id = ?`. The PR-C-α
/// transitional `AuthStorage.readBoundUserIdOrPlaceholder()` bridge is
/// gone — callers must thread userId from `AuthScope`. `markSynced`
/// also takes userId to defend against in-flight account-switch
/// writing to the wrong user's row (plan §4.1 review 1 P2).
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
  /// emits from the legacy table classes — keep in sync if those drift
  /// classes change.
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
  /// 完全 owned by drift onCreate.
  static Future<void> _createTables(Database db, int version) async {
    // intentionally empty — drift owns schema
  }

  // ==================== Word Records (核心) ====================

  /// Insert a study attempt record for [userId].
  ///
  /// [sessionId] (Need #8) is the local Sessions.id this attempt belongs to,
  /// or null when the attempt happens outside any active session
  /// (legacy / pre-migration data — backend falls back to time-window match).
  ///
  /// PR-C-β: the upsert search is now scoped to `(user_id, word_id, study_type)`
  /// so two users with the same word_id keep distinct rows. The composite
  /// UNIQUE is not enforced at the SQLite level for word_records, but the
  /// caller's WHERE makes it impossible to silently overwrite the other
  /// user's progress.
  Future<int> insertWordRecord({
    required String userId,
    required String wordId,
    required String bookId,
    required String studyType,
    required String actionResult,
    String? sessionId,
  }) async {
    final existing = await _db!.query(
      'word_records',
      where: 'user_id = ? AND word_id = ? AND study_type = ?',
      whereArgs: [userId, wordId, studyType],
    );

    if (existing.isNotEmpty) {
      final existingResult = existing.first['action_result'] as String;
      if (existingResult == actionResult) {
        return existing.first['id'] as int; // Already exists, same result
      }
      // Update: e.g., forgot → know. Belt-and-braces user_id check in
      // WHERE so an in-flight account switch can't flip the other
      // user's row (plan §4.1 review 1 P2 markSynced parity).
      final updateValues = <String, Object?>{
        'action_result': actionResult,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'synced': 0,
      };
      if (sessionId != null) updateValues['session_id'] = sessionId;
      await _db!.update(
        'word_records',
        updateValues,
        where: 'id = ? AND user_id = ?',
        whereArgs: [existing.first['id'], userId],
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

  /// Word IDs where this [userId] rated `know` on `study_type='new'`.
  Future<Set<String>> getMasteredWordIds(String userId) async {
    final rows = await _db!.query(
      'word_records',
      columns: ['word_id'],
      where:
          "user_id = ? AND action_result = 'know' AND study_type = 'new'",
      whereArgs: [userId],
    );
    return rows.map((r) => r['word_id'] as String).toSet();
  }

  /// All of [userId]'s unsynced records.
  Future<List<Map<String, dynamic>>> getUnsyncedRecords(String userId) async {
    return await _db!.query(
      'word_records',
      where: 'user_id = ? AND synced = 0',
      whereArgs: [userId],
    );
  }

  /// Mark record [id] as synced. The WHERE includes [userId] so an
  /// in-flight account switch can't flip the other user's row (plan
  /// §4.1 review 1 P2 evaluator采纳).
  Future<int> markSynced(int id, {required String userId}) async {
    return await _db!.update(
      'word_records',
      {'synced': 1},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// Bug 4 — Distinct `word_id` values [userId] has rated TODAY on
  /// `study_type='new'`, regardless of action_result.
  ///
  /// Used by StudyPage as the canonical "unique new words served today"
  /// gate so the daily goal cannot be exceeded by repeatedly tapping
  /// 不认识/模糊. The window is the user's LOCAL calendar day,
  /// converted to UTC bounds since `created_at` is stored as UTC ISO-8601.
  Future<Set<String>> getTodayServedNewWordIds(String userId) async {
    final now = DateTime.now();
    final localMidnight = DateTime(now.year, now.month, now.day);
    final nextLocalMidnight = localMidnight.add(const Duration(days: 1));
    final startUtcIso = localMidnight.toUtc().toIso8601String();
    final endUtcIso = nextLocalMidnight.toUtc().toIso8601String();
    final rows = await _db!.rawQuery(
      "SELECT DISTINCT word_id FROM word_records "
      "WHERE user_id = ? AND study_type = 'new' "
      "AND created_at >= ? AND created_at < ?",
      [userId, startUtcIso, endUtcIso],
    );
    return rows.map((r) => r['word_id'] as String).toSet();
  }

  /// Today's "stuck forgots" for [userId] — word_ids that have at least
  /// one `forgot` record today (`study_type='new'`) AND have NO 'know'
  /// record at any point in time. Used by StudyPage to rehydrate the
  /// consolidation queue at session start.
  Future<Set<String>> getTodayStuckForgotIds(String userId) async {
    final now = DateTime.now();
    final localMidnight = DateTime(now.year, now.month, now.day);
    final nextLocalMidnight = localMidnight.add(const Duration(days: 1));
    final startUtcIso = localMidnight.toUtc().toIso8601String();
    final endUtcIso = nextLocalMidnight.toUtc().toIso8601String();
    final rows = await _db!.rawQuery(
      "SELECT DISTINCT word_id FROM word_records "
      "WHERE user_id = ? AND study_type = 'new' AND action_result = 'forgot' "
      "AND created_at >= ? AND created_at < ? "
      "AND word_id NOT IN ("
      "  SELECT word_id FROM word_records "
      "  WHERE user_id = ? AND study_type = 'new' AND action_result = 'know'"
      ")",
      [userId, startUtcIso, endUtcIso, userId],
    );
    return rows.map((r) => r['word_id'] as String).toSet();
  }

  /// Count new words [userId] successfully studied today.
  /// Used as offline fallback for [TodayState.todayNewCompleted].
  Future<int> countTodayNewCompleted(String userId) async {
    final now = DateTime.now();
    final localMidnight = DateTime(now.year, now.month, now.day);
    final nextLocalMidnight = localMidnight.add(const Duration(days: 1));
    final startUtcIso = localMidnight.toUtc().toIso8601String();
    final endUtcIso = nextLocalMidnight.toUtc().toIso8601String();
    final rows = await _db!.rawQuery(
      "SELECT COUNT(*) AS cnt FROM word_records "
      "WHERE user_id = ? AND study_type = 'new' AND action_result = 'know' "
      "AND created_at >= ? AND created_at < ?",
      [userId, startUtcIso, endUtcIso],
    );
    return (rows.first['cnt'] as int?) ?? 0;
  }

  /// All of [userId]'s word records (for snapshot export, ordered).
  Future<List<Map<String, dynamic>>> getAllWordRecords(String userId) async {
    return await _db!.query(
      'word_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );
  }

  /// Replace [userId]'s word records with [records] (for restore).
  /// Transactional. Other users' rows are untouched — only this
  /// user's rows are deleted before insert. The snapshot may carry a
  /// `user_id` field per row; if absent we default to [userId].
  Future<void> replaceAllWordRecords(
    List<Map<String, dynamic>> records, {
    required String userId,
  }) async {
    await _db!.transaction((txn) async {
      await txn.delete(
        'word_records',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      for (final r in records) {
        await txn.insert('word_records', {
          'user_id': r['user_id'] ?? userId,
          'word_id': r['word_id'] ?? '',
          'book_id': r['book_id'] ?? '',
          'study_type': r['study_type'] ?? 'new',
          'action_result': r['action_result'] ?? 'forgot',
          'created_at':
              r['created_at'] ?? DateTime.now().toUtc().toIso8601String(),
          'synced': r['synced'] ?? 1, // Restored data considered synced
        });
      }
    });
  }

  // ==================== Stats raw queries (PR-C-β: now userId-scoped) ====================
  //
  // StatsService used to reach into [db] and run raw SQL on word_records.
  // PR-C-β moves those queries here so the WHERE user_id clause lives in
  // one place. StatsService consumes typed return values, not raw rows.

  /// Count distinct word_ids this user has touched (any action_result,
  /// any study_type). Stats "totalWordsLearned" hero number.
  Future<int> countDistinctLearnedWords(String userId) async {
    final rows = await _db!.rawQuery(
      'SELECT COUNT(DISTINCT word_id) AS cnt FROM word_records '
      'WHERE user_id = ?',
      [userId],
    );
    return (rows.first['cnt'] as int?) ?? 0;
  }

  /// Count distinct `know`/`new` word_ids since [sinceUtcIso] for this
  /// user. Stats "weeklyDelta" and forecast "近 7 天日均".
  Future<int> countDistinctNewKnowSince(
    String userId,
    String sinceUtcIso,
  ) async {
    final rows = await _db!.rawQuery(
      'SELECT COUNT(DISTINCT word_id) AS cnt FROM word_records '
      "WHERE user_id = ? AND study_type='new' AND action_result='know' "
      'AND created_at >= ?',
      [userId, sinceUtcIso],
    );
    return (rows.first['cnt'] as int?) ?? 0;
  }

  /// `created_at` strings for `know`/`new` records since [sinceUtcIso].
  /// Stats trend / heatmap / badges convert each to local-day buckets.
  Future<List<String>> listNewKnowCreatedAtSince(
    String userId,
    String sinceUtcIso,
  ) async {
    final rows = await _db!.rawQuery(
      'SELECT created_at FROM word_records '
      "WHERE user_id = ? AND study_type='new' AND action_result='know' "
      'AND created_at >= ?',
      [userId, sinceUtcIso],
    );
    return rows.map((r) => r['created_at'] as String).toList();
  }

  /// All-time `created_at` strings for this user's `know`/`new` records.
  /// Stats "百日斩" badge scans the histogram for max-daily ≥ 100.
  Future<List<String>> listAllNewKnowCreatedAt(String userId) async {
    final rows = await _db!.rawQuery(
      'SELECT created_at FROM word_records '
      "WHERE user_id = ? AND study_type='new' AND action_result='know'",
      [userId],
    );
    return rows.map((r) => r['created_at'] as String).toList();
  }

  // ==================== Generic table operations (for snapshot export) ====================

  /// All rows from [table] belonging to [userId]. Use for snapshot
  /// export of user-scoped tables (e.g. `card_states` directly via
  /// drift's sqflite file). Non-user-scoped tables (audio_file_cache,
  /// preset_wordbooks etc.) should NOT be called through here — those
  /// are shared catalog data and don't have a `user_id` column.
  Future<List<Map<String, dynamic>>> getAllFromTableForUser(
    String table,
    String userId,
  ) async {
    return await _db!.query(
      table,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Replace [userId]'s rows in [table] with [records]. Transactional.
  /// Other users' rows are not touched.
  Future<void> replaceUserRowsInTable(
    String table,
    List<Map<String, dynamic>> records, {
    required String userId,
  }) async {
    await _db!.transaction((txn) async {
      await txn.delete(table, where: 'user_id = ?', whereArgs: [userId]);
      for (final r in records) {
        await txn.insert(table, {
          ...r,
          'user_id': r['user_id'] ?? userId,
        });
      }
    });
  }

  /// Count [userId]'s rows in [table].
  Future<int> countRowsForUser(String table, String userId) async {
    final result = await _db!.rawQuery(
      'SELECT COUNT(*) AS cnt FROM $table WHERE user_id = ?',
      [userId],
    );
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
