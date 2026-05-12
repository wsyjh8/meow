/// 需求 23 Phase D PR-D-γ (plan-023-D-v2 §4.3, Review 2 P1-2 / P2-1):
/// restore-side hardening.
///
/// Server-side `validateSnapshotUserIds` (PR-D-β) is the first defence
/// against snapshots that carry foreign `user_id` rows. PR-D-γ adds
/// the second:
///
///   1. `LocalDatabase.replaceAllWordRecords` and
///      `LocalDatabase.replaceUserRowsInTable` unconditionally rewrite
///      every restored row's `user_id` to the bound user — the
///      snapshot's `user_id` field is ignored. Even if a snapshot
///      somehow bypassed the server check (legacy backup, file replay),
///      the local DB only ever stores rows under the current user.
///   2. `BackupRestoreService._applySnapshot` walks the 6 user-scoped
///      entity collections and counts foreign-tag rows. The count is
///      logged but does NOT abort the restore (the write path
///      neutralizes the tag).
///
/// Tests:
///   * D-T5: snapshot rows with foreign `user_id` → after restore,
///     every stored row's `user_id` == currentUserId.
///   * schema_version unsupported → `RestoreResult.versionNotSupported`
///     before any storage write.
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

/// Tiny `http.BaseClient` stub that always returns the same canned
/// JSON. We don't need conditional routing for these tests — preCheck
/// and restore both hit `/me/backup/latest/snapshot` and both should
/// receive identical responses.
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

  const currentUserId = 'user-current';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalDatabase.deleteDatabase_();
    await LocalDatabase.initializeForTesting();
  });

  tearDown(() async {
    await LocalDatabase.instance.close();
  });

  group('D-T5 — restore re-tags foreign user_id rows to current user', () {
    test('replaceAllWordRecords rewrites user_id unconditionally', () async {
      // Snapshot row says it belongs to user-foreign; restore must
      // ignore that and write under user-current.
      await LocalDatabase.instance.replaceAllWordRecords(
        [
          {
            'user_id': 'user-foreign',
            'word_id': 'abandon',
            'book_id': 'zk',
            'study_type': 'new',
            'action_result': 'know',
            'created_at': '2026-05-11T00:00:00Z',
            'synced': 1,
          },
          {
            // Row without explicit user_id — also tagged with current.
            'word_id': 'ability',
            'book_id': 'zk',
            'study_type': 'new',
            'action_result': 'know',
            'created_at': '2026-05-11T00:01:00Z',
            'synced': 1,
          },
        ],
        userId: currentUserId,
      );

      final mine =
          await LocalDatabase.instance.getAllWordRecords(currentUserId);
      expect(mine.length, 2);
      expect(mine.every((r) => r['user_id'] == currentUserId), isTrue,
          reason: 'every row must be tagged with the bound user');

      // user-foreign sees nothing — proves the foreign tag was dropped,
      // not stored under that user.
      final foreignRows =
          await LocalDatabase.instance.getAllWordRecords('user-foreign');
      expect(foreignRows, isEmpty);
    });

    test('replaceUserRowsInTable rewrites user_id unconditionally', () async {
      // Same test against the generic helper. Use daily_checkins —
      // simplest composite-UNIQUE shape post-v13.
      await LocalDatabase.instance.replaceUserRowsInTable(
        'daily_checkins',
        [
          {
            'user_id': 'user-foreign',
            'date': '2026-05-11',
            'checked_in': 1,
            'created_at': '2026-05-11T00:00:00Z',
          },
        ],
        userId: currentUserId,
      );

      final mine = await LocalDatabase.instance
          .getAllFromTableForUser('daily_checkins', currentUserId);
      expect(mine.length, 1);
      expect(mine.single['user_id'], currentUserId);

      final foreignRows = await LocalDatabase.instance
          .getAllFromTableForUser('daily_checkins', 'user-foreign');
      expect(foreignRows, isEmpty);
    });

    test('full restore() neutralizes foreign user_id on every user-scoped entity',
        () async {
      // End-to-end through BackupRestoreService.restore. The stub
      // returns a snapshot containing foreign-tag rows in every
      // user-scoped collection; after restore() returns, every
      // stored row should be tagged with currentUserId.
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
            'settings': {'daily_goal': 25, 'theme': 'dark'},
            'progress': {
              'word_records': [
                {
                  'user_id': 'user-attacker',
                  'word_id': 'sneak',
                  'book_id': 'zk',
                  'study_type': 'new',
                  'action_result': 'know',
                  'created_at': '2026-05-11T00:00:00Z',
                  'synced': 1,
                },
              ],
              'daily_checkins': [
                {
                  'user_id': 'user-attacker',
                  'date': '2026-05-11',
                  'checked_in': 1,
                  'created_at': '2026-05-11T00:00:00Z',
                },
              ],
              'custom_wordbooks': [
                {
                  'user_id': 'user-attacker',
                  'name': 'malicious-list',
                  'word_count': 0,
                  'created_at': '2026-05-11T00:00:00Z',
                },
              ],
              'vocabulary_notebook': [
                {
                  'user_id': 'user-attacker',
                  'word': 'sneak',
                  'created_at': '2026-05-11T00:00:00Z',
                },
              ],
            },
          },
        }),
      );

      final result = await restore.restore();
      expect(result.isSuccess, isTrue, reason: result.errorMessage);

      // Verify each table is owned by the current user, not the
      // attacker tag.
      for (final table in [
        'word_records',
        'daily_checkins',
        'custom_wordbooks',
        'vocabulary_notebook',
      ]) {
        final mine = await LocalDatabase.instance
            .getAllFromTableForUser(table, currentUserId);
        final foreign = await LocalDatabase.instance
            .getAllFromTableForUser(table, 'user-attacker');
        expect(mine.length, 1, reason: '$table should have 1 row for current');
        expect(foreign, isEmpty, reason: '$table must NOT store attacker tag');
      }
    });
  });

  group('D6 — schema_version validation', () {
    test('unsupported schema_version aborts restore before any write',
        () async {
      // Seed the SP-backed setting so we can detect any rogue write.
      final prefs = await SharedPreferences.getInstance();
      await LocalSettingsService(prefs, userId: currentUserId)
          .setDailyGoal(42);

      final restore = BackupRestoreService(
        baseUrl: 'http://stub',
        settings: LocalSettingsService(prefs, userId: currentUserId),
        db: LocalDatabase.instance,
        userId: currentUserId,
        client: _StubClient({
          'status': 'available',
          'schema_version': 'p99_future_version',
          'uploaded_at': '2030-01-01T00:00:00Z',
          'snapshot': {
            'schema_version': 'p99_future_version',
            'settings': {'daily_goal': 999, 'sound_enabled': false},
            'progress': {
              'word_records': [
                {
                  'word_id': 'snuck_in',
                  'book_id': 'zk',
                  'study_type': 'new',
                  'action_result': 'know',
                  'created_at': '2030-01-01T00:00:00Z',
                },
              ],
            },
          },
        }),
      );

      final result = await restore.restore();
      expect(result.status, RestoreStatus.versionNotSupported);
      expect(result.errorCode, 'SCHEMA_MISMATCH');

      // Settings unchanged.
      expect(
          LocalSettingsService(prefs, userId: currentUserId).dailyGoal, 42);

      // No drift / sqflite writes happened either — table is empty.
      final rows =
          await LocalDatabase.instance.getAllWordRecords(currentUserId);
      expect(rows, isEmpty,
          reason: 'restore must NOT write anything on schema mismatch');
    });

    test(
        'preCheck rejects unsupported schema_version with versionNotSupported',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final restore = BackupRestoreService(
        baseUrl: 'http://stub',
        settings: LocalSettingsService(prefs, userId: currentUserId),
        db: LocalDatabase.instance,
        userId: currentUserId,
        client: _StubClient({
          'status': 'available',
          'schema_version': 'p99_future_version',
          'uploaded_at': '2030-01-01T00:00:00Z',
          'snapshot': {
            'schema_version': 'p99_future_version',
            'device': {'device_id': 'dx', 'device_model': 'My'},
          },
        }),
      );

      final pre = await restore.preCheck();
      expect(pre.status, RestorePreCheckStatus.versionNotSupported);
      expect(pre.backupSchemaVersion, 'p99_future_version');
    });

    test('preCheck accepts the legacy schema_version', () async {
      // p3_1_snapshot_v2 is still in `_acceptedSchemas` for
      // backward-compatibility (legacySchemaVersion). D6 decision:
      // accept and log — don't reject.
      final prefs = await SharedPreferences.getInstance();
      final restore = BackupRestoreService(
        baseUrl: 'http://stub',
        settings: LocalSettingsService(prefs, userId: currentUserId),
        db: LocalDatabase.instance,
        userId: currentUserId,
        client: _StubClient({
          'status': 'available',
          'schema_version': 'p3_1_snapshot_v2',
          'uploaded_at': '2026-05-11T00:00:00Z',
          'snapshot': {
            'schema_version': 'p3_1_snapshot_v2',
            'device': {'device_id': 'd1', 'device_model': 'M1'},
          },
        }),
      );
      final pre = await restore.preCheck();
      expect(pre.status, RestorePreCheckStatus.restorable);
    });
  });
}
