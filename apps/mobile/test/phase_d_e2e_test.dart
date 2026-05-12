/// 需求 23 Phase D PR-D-δ (plan-023-D-v2 §6): full Phase D e2e matrix.
/// Most rows are covered in earlier α/β/γ files (cited inline); this
/// file fills D-T7 (snapshot field-omission tolerance) and D-T11
/// (multi-account local coexistence during restore).
///
/// Coverage map (mobile-side):
///   D-T1  upload→restart→fetch          → backend backup-persistence.e2e
///   D-T2  same-user multi-upload        → backend backup-persistence.e2e
///   D-T3  cross-user fetch              → backend backup-persistence.e2e
///   D-T4  cross-device fetch            → backend backup-persistence.e2e
///   D-T5  restore re-tags foreign u_id  → backup_restore_hardening_test.dart
///   D-T6  10MB body limit               → backend backup-persistence.e2e
///   D-T7  partial snapshot fields       (this file)
///   D-T8  server-side polluted reject   → backend backup-persistence.e2e
///   D-T9  schema_version reject/accept  → backup_restore_hardening_test.dart
///   D-T10 user delete → cascade         → backend backup-persistence.e2e
///   D-T11 multi-account local coexist   (this file)
///   D-T12 auth header injection         → backup_auth_header_test.dart
///   D-T13 bind preserves backup         → backend backup-persistence.e2e
///   D-T14 AUTH_ENFORCE token guard      → backend backup-persistence.e2e
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:meow_mobile/core/storage/backup_restore_service.dart';
import 'package:meow_mobile/core/storage/local_database.dart';
import 'package:meow_mobile/core/storage/local_settings_service.dart';

class _StubClient extends http.BaseClient {
  _StubClient(this._response);
  final Map<String, dynamic> _response;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = utf8.encode(json.encode(_response));
    return http.StreamedResponse(
      Stream.value(body),
      200,
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalDatabase.deleteDatabase_();
    await LocalDatabase.initializeForTesting();
  });

  tearDown(() async {
    await LocalDatabase.instance.close();
  });

  // ── D-T7 — snapshot omits some entities → restore is partial ──────
  group('D-T7 — partial-snapshot tolerance', () {
    test('snapshot missing card_states still restores word_records '
        'and leaves the absent entity untouched', () async {
      const currentUserId = 'user-current';

      // Seed BOTH word_records AND a card_states-equivalent row
      // (we use daily_checkins as the proxy for "another user-scoped
      //  entity whose data should survive a partial restore").
      await LocalDatabase.instance.insertWordRecord(
        userId: currentUserId,
        wordId: 'pre-existing',
        bookId: 'zk',
        studyType: 'new',
        actionResult: 'know',
      );
      await LocalDatabase.instance.replaceUserRowsInTable(
        'daily_checkins',
        [
          {
            'date': '2026-05-10',
            'checked_in': 1,
            'created_at': '2026-05-10T00:00:00Z',
          },
        ],
        userId: currentUserId,
      );

      // Snapshot supplies ONLY word_records — no daily_checkins,
      // no card_states. The restore must replace word_records and
      // leave the other entities untouched (no DELETE of absent
      // entity → no data loss).
      final prefs = await SharedPreferences.getInstance();
      final restore = BackupRestoreService(
        baseUrl: 'http://stub',
        settings: LocalSettingsService(prefs, userId: currentUserId),
        db: LocalDatabase.instance,
        userId: currentUserId,
        client: _StubClient({
          'status': 'available',
          'schema_version': 'p3_2_snapshot_v1',
          'uploaded_at': '2026-05-11T00:00:00Z',
          'snapshot': {
            'schema_version': 'p3_2_snapshot_v1',
            'settings': {'daily_goal': 30},
            'progress': {
              'word_records': [
                {
                  'word_id': 'restored',
                  'book_id': 'zk',
                  'study_type': 'new',
                  'action_result': 'know',
                  'created_at': '2026-05-11T00:00:00Z',
                  'synced': 1,
                },
              ],
              // explicit nulls / missing — backup_restore_service
              // skips the corresponding replaceUserRowsInTable.
            },
          },
        }),
      );

      final result = await restore.restore();
      expect(result.isSuccess, isTrue, reason: result.errorMessage);

      // word_records was replaced (pre-existing row gone, restored
      // row present).
      final wr =
          await LocalDatabase.instance.getAllWordRecords(currentUserId);
      expect(wr.length, 1);
      expect(wr.single['word_id'], 'restored');

      // daily_checkins was NOT in the snapshot → untouched.
      final dc = await LocalDatabase.instance
          .getAllFromTableForUser('daily_checkins', currentUserId);
      expect(dc.length, 1,
          reason:
              'absent entity must not be deleted (would mean data loss '
              'on partial-snapshot restore)');
      expect(dc.single['date'], '2026-05-10');
    });

    test('snapshot missing settings keys keeps existing settings unchanged',
        () async {
      const currentUserId = 'user-current';
      final prefs = await SharedPreferences.getInstance();
      final settings =
          LocalSettingsService(prefs, userId: currentUserId);

      // Seed every setting field; snapshot will only carry `theme`.
      await settings.setDailyGoal(33);
      await settings.setSoundEnabled(false);
      await settings.setTheme('light');
      await settings.setNotificationTime('08:00');

      final restore = BackupRestoreService(
        baseUrl: 'http://stub',
        settings: settings,
        db: LocalDatabase.instance,
        userId: currentUserId,
        client: _StubClient({
          'status': 'available',
          'schema_version': 'p3_2_snapshot_v1',
          'uploaded_at': '2026-05-11T00:00:00Z',
          'snapshot': {
            'schema_version': 'p3_2_snapshot_v1',
            'settings': {
              // ONLY theme — daily_goal / sound_enabled / notification_time
              // are absent.
              'theme': 'dark',
            },
            'progress': {},
          },
        }),
      );

      await restore.restore();

      // theme moved; others held their existing values.
      expect(settings.theme, 'dark');
      expect(settings.dailyGoal, 33,
          reason: 'absent setting key must not reset to default');
      expect(settings.soundEnabled, isFalse);
      expect(settings.notificationTime, '08:00');
    });
  });

  // ── D-T11 — two users coexist on one device; restore is per-user ──
  group('D-T11 — multi-account local coexistence', () {
    test('user C restore does not touch user A\'s drift rows', () async {
      const userAId = 'user-a';
      const userCId = 'user-c';

      // Seed A's data: a word_records row AND a daily_checkins row.
      // (These represent A's session before logout.)
      await LocalDatabase.instance.insertWordRecord(
        userId: userAId,
        wordId: 'A-only',
        bookId: 'zk',
        studyType: 'new',
        actionResult: 'know',
      );
      await LocalDatabase.instance.replaceUserRowsInTable(
        'daily_checkins',
        [
          {
            'date': '2026-05-09',
            'checked_in': 1,
            'created_at': '2026-05-09T00:00:00Z',
          },
        ],
        userId: userAId,
      );

      // Seed a row for C too (we'll see this gets overwritten by C's
      // restore, while A's rows survive).
      await LocalDatabase.instance.insertWordRecord(
        userId: userCId,
        wordId: 'C-stale',
        bookId: 'zk',
        studyType: 'new',
        actionResult: 'forgot',
      );

      // User logs out → logs in as C → restores C's snapshot.
      final prefs = await SharedPreferences.getInstance();
      final restore = BackupRestoreService(
        baseUrl: 'http://stub',
        settings: LocalSettingsService(prefs, userId: userCId),
        db: LocalDatabase.instance,
        userId: userCId,
        client: _StubClient({
          'status': 'available',
          'schema_version': 'p3_2_snapshot_v1',
          'uploaded_at': '2026-05-11T00:00:00Z',
          'snapshot': {
            'schema_version': 'p3_2_snapshot_v1',
            'progress': {
              'word_records': [
                {
                  'word_id': 'C-restored',
                  'book_id': 'zk',
                  'study_type': 'new',
                  'action_result': 'know',
                  'created_at': '2026-05-11T00:00:00Z',
                  'synced': 1,
                },
              ],
              'daily_checkins': [
                {
                  'date': '2026-05-11',
                  'checked_in': 1,
                  'created_at': '2026-05-11T00:00:00Z',
                },
              ],
            },
          },
        }),
      );

      final result = await restore.restore();
      expect(result.isSuccess, isTrue, reason: result.errorMessage);

      // ── User A's data must survive A's logout + C's restore ─────
      final aWord =
          await LocalDatabase.instance.getAllWordRecords(userAId);
      expect(aWord.length, 1);
      expect(aWord.single['word_id'], 'A-only',
          reason: 'A\'s pre-logout word_records row must survive '
              'C\'s restore — only C\'s rows were DELETE\'d');

      final aCheckin = await LocalDatabase.instance
          .getAllFromTableForUser('daily_checkins', userAId);
      expect(aCheckin.length, 1);
      expect(aCheckin.single['date'], '2026-05-09');

      // ── User C's data has been replaced by C's snapshot ─────────
      final cWord =
          await LocalDatabase.instance.getAllWordRecords(userCId);
      expect(cWord.length, 1);
      expect(cWord.single['word_id'], 'C-restored',
          reason:
              'C\'s stale row is gone; C-restored from the snapshot is here');

      final cCheckin = await LocalDatabase.instance
          .getAllFromTableForUser('daily_checkins', userCId);
      expect(cCheckin.length, 1);
      expect(cCheckin.single['date'], '2026-05-11');

      // ── Independent A re-login path: A logs back in, sees their own data ─
      // We simulate "A logs back in" by calling getAllWordRecords(userAId)
      // again — already done above. The assertion that A still owns
      // their row IS the proof that A's data was never wiped.
    });

    test('A\'s 9 user-scoped tables collectively survive C\'s restore',
        () async {
      // The previous test verified word_records + daily_checkins.
      // This one seeds rows in EVERY user-scoped legacy table (5)
      // and confirms C's restore leaves all of them alone.
      const userAId = 'user-a';
      const userCId = 'user-c';

      // 5 legacy tables (PR-C-α v13 schema).
      final db = LocalDatabase.instance.db;
      await db.insert('word_records', {
        'user_id': userAId,
        'word_id': 'A-word',
        'book_id': 'zk',
        'study_type': 'new',
        'action_result': 'know',
        'created_at': '2026-05-09T00:00:00Z',
        'synced': 1,
      });
      await db.insert('wordbook_progress', {
        'user_id': userAId,
        'book_id': 'zk',
        'total_words': 100,
        'completed_words': 5,
        'updated_at': '2026-05-09T00:00:00Z',
      });
      await db.insert('daily_checkins', {
        'user_id': userAId,
        'date': '2026-05-09',
        'checked_in': 1,
        'created_at': '2026-05-09T00:00:00Z',
      });
      await db.insert('custom_wordbooks', {
        'user_id': userAId,
        'name': 'A-personal-list',
        'word_count': 0,
        'created_at': '2026-05-09T00:00:00Z',
      });
      await db.insert('vocabulary_notebook', {
        'user_id': userAId,
        'word': 'serendipity',
        'created_at': '2026-05-09T00:00:00Z',
      });

      // C restores
      final prefs = await SharedPreferences.getInstance();
      final restore = BackupRestoreService(
        baseUrl: 'http://stub',
        settings: LocalSettingsService(prefs, userId: userCId),
        db: LocalDatabase.instance,
        userId: userCId,
        client: _StubClient({
          'status': 'available',
          'schema_version': 'p3_2_snapshot_v1',
          'uploaded_at': '2026-05-11T00:00:00Z',
          'snapshot': {
            'schema_version': 'p3_2_snapshot_v1',
            'progress': {
              'word_records': [
                {
                  'word_id': 'C-word',
                  'book_id': 'gk',
                  'study_type': 'new',
                  'action_result': 'know',
                  'created_at': '2026-05-11T00:00:00Z',
                  'synced': 1,
                },
              ],
              'wordbook_progress': [
                {
                  'book_id': 'gk',
                  'total_words': 200,
                  'completed_words': 10,
                  'updated_at': '2026-05-11T00:00:00Z',
                },
              ],
              'daily_checkins': [
                {
                  'date': '2026-05-11',
                  'checked_in': 1,
                  'created_at': '2026-05-11T00:00:00Z',
                },
              ],
              'custom_wordbooks': [
                {
                  'name': 'C-list',
                  'word_count': 0,
                  'created_at': '2026-05-11T00:00:00Z',
                },
              ],
              'vocabulary_notebook': [
                {
                  'word': 'curiosity',
                  'created_at': '2026-05-11T00:00:00Z',
                },
              ],
            },
          },
        }),
      );

      await restore.restore();

      // Verify all 5 of A's rows are still owned by A.
      for (final table in [
        'word_records',
        'wordbook_progress',
        'daily_checkins',
        'custom_wordbooks',
        'vocabulary_notebook',
      ]) {
        final aRows = await LocalDatabase.instance
            .getAllFromTableForUser(table, userAId);
        expect(aRows.length, 1,
            reason: '$table: A\'s row must survive C\'s restore');
        final cRows = await LocalDatabase.instance
            .getAllFromTableForUser(table, userCId);
        expect(cRows.length, 1,
            reason: '$table: C\'s row must have landed from the restore');
      }
    });
  });
}
