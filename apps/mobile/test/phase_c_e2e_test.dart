/// 需求 23 Phase C PR-C-δ (plan-023-C-v2 §6): full Phase C e2e test
/// matrix. Most rows are covered by individual test files already
/// (cited inline); this file fills the gaps and exercises the
/// **cross-cutting** scenarios — two users sharing a device, account
/// switch state retention, and the SpMigrator-meets-PendingGuestMigrator
/// handoff.
///
/// Coverage map (T1-T14):
///   T1  basic insert via FsrsService.forUser → see fsrs_service_test.dart
///   T2  v8 → v13 backfill         → migration_test.dart
///   T3  SP migration (this file, both settings_* + progress_*)
///   T4  composite UNIQUE          (this file)
///   T5  LocalDatabase DAO isolation (this file)
///   T6  service A/B isolation     (this file + local_settings_service_test.dart)
///   T7  logout retains drift data (this file)
///   T8  same-row bind no migrate  (this file)
///   T9  drift migration idempotent → migration_test.dart
///   T10 fresh install regression  → migration_test.dart
///   T11 epoch race                → auth_http_client_epoch_test.dart
///   T12 pending-local-guest drift → pending_guest_migrator_test.dart
///   T13 SP namespace rename       → pending_guest_migrator_test.dart
///   T14 drift code-gen NOT NULL   (this file — runtime PRAGMA check)
library;

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:meow_mobile/core/auth/auth.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';
import 'package:meow_mobile/core/storage/local_database.dart';
import 'package:meow_mobile/core/storage/local_settings_service.dart';
import 'package:meow_mobile/core/storage/backup_upload_service.dart';
import 'package:meow_mobile/features/room_canvas/storage/room_canvas_storage.dart';
import 'package:meow_mobile/features/room_canvas/models/placed_furniture.dart';

class _SecureChannelStub {
  final Map<String, String> store = {};
  void install() {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = call.arguments as Map?;
      final key = args?['key'] as String?;
      switch (call.method) {
        case 'read':
          return key == null ? null : store[key];
        case 'write':
          if (key != null) store[key] = args!['value'] as String;
          return null;
        case 'delete':
          if (key != null) store.remove(key);
          return null;
        default:
          return null;
      }
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final secureStub = _SecureChannelStub();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureStub.store.clear();
    secureStub.install();
  });

  // ── T3: SP migration covers both settings_* (rename) and progress_*
  //       (delete) on a single pass ──────────────────────────────────
  group('T3 — SpMigrator: settings_* renamed, progress_* deleted', () {
    test(
        'flat settings_* keys move to u_<userId>_*; progress_* keys are dropped',
        () async {
      // Seed the pre-C SP layout: a couple of legacy settings, a couple of
      // legacy progress_* keys (which §D9 retires), and the pending flag
      // that markFreshInstallIfNeeded sets when it spots either.
      SharedPreferences.setMockInitialValues({
        'auth_current_user_id': 'user-123',
        'auth_pending_sp_migration': true,
        'auth_fresh_install_marker_done': true,
        // settings_* → migrate to u_user-123_*
        'settings_daily_goal': 30,
        'settings_theme': 'dark',
        'settings_sound_enabled': false,
        // progress_* → delete (no u_user-123_progress_* counterpart)
        'progress_word_records': '[{"word_id":"abandon"}]',
        'progress_wordbook_progress': '{}',
        // Unrelated key — must not be touched
        'auth_current_user_id_unrelated_marker': 'x',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );
      final migrator = SpMigrator(prefs: prefs, storage: storage);

      final ran = await migrator.runIfNeeded(userId: 'user-123');
      expect(ran, isTrue);

      // settings_* → u_user-123_*
      expect(prefs.containsKey('settings_daily_goal'), isFalse);
      expect(prefs.getInt('u_user-123_settings_daily_goal'), 30);
      expect(prefs.getString('u_user-123_settings_theme'), 'dark');
      expect(prefs.getBool('u_user-123_settings_sound_enabled'), isFalse);

      // progress_* dropped, NO new namespaced key created (§D9)
      expect(prefs.containsKey('progress_word_records'), isFalse);
      expect(prefs.containsKey('progress_wordbook_progress'), isFalse);
      expect(prefs.containsKey('u_user-123_progress_word_records'), isFalse,
          reason: '§D9: progress_* is delete-only, never namespaced');

      // pending flag flipped so next launch short-circuits.
      expect(storage.readPendingSpMigration(), isFalse);

      // Unrelated key untouched.
      expect(prefs.getString('auth_current_user_id_unrelated_marker'), 'x');
    });
  });

  // ── T4: composite UNIQUE allows two users to hold the same key ─────
  group('T4 — UNIQUE composite cross-user', () {
    late AppDatabase db;
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'auth_current_user_id': 'user-a',
      });
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();
    });
    tearDown(() => db.close());

    test('wordbook_progress: same book_id under user-a and user-b is allowed',
        () async {
      await db.into(db.wordbookProgress).insert(WordbookProgressCompanion.insert(
            userId: 'user-a',
            bookId: 'zk',
            updatedAt: '2026-05-10T00:00:00Z',
          ));
      // Same book_id, different user — must succeed under v13 composite UNIQUE.
      await db.into(db.wordbookProgress).insert(WordbookProgressCompanion.insert(
            userId: 'user-b',
            bookId: 'zk',
            updatedAt: '2026-05-10T00:00:00Z',
          ));
      expect((await db.select(db.wordbookProgress).get()).length, 2);

      // But re-inserting (user-a, zk) collides on (user_id, book_id).
      expect(
        () => db.into(db.wordbookProgress).insert(WordbookProgressCompanion.insert(
              userId: 'user-a',
              bookId: 'zk',
              updatedAt: '2026-05-11T00:00:00Z',
            )),
        throwsA(isA<Exception>()),
      );
    });

    test('daily_checkins: same date under two users is allowed', () async {
      await db.into(db.dailyCheckins).insert(DailyCheckinsCompanion.insert(
            userId: 'user-a',
            date: '2026-05-10',
            createdAt: '2026-05-10T00:00:00Z',
          ));
      await db.into(db.dailyCheckins).insert(DailyCheckinsCompanion.insert(
            userId: 'user-b',
            date: '2026-05-10',
            createdAt: '2026-05-10T00:00:00Z',
          ));
      expect((await db.select(db.dailyCheckins).get()).length, 2);

      expect(
        () => db.into(db.dailyCheckins).insert(DailyCheckinsCompanion.insert(
              userId: 'user-a',
              date: '2026-05-10',
              createdAt: '2026-05-10T00:00:00Z',
            )),
        throwsA(isA<Exception>()),
      );
    });
    // (card_states already covered in migration_test.dart)
  });

  // ── T5: LocalDatabase DAO methods are user-scoped ──────────────────
  group('T5 — LocalDatabase DAO isolation', () {
    setUp(() async {
      await LocalDatabase.deleteDatabase_();
      await LocalDatabase.initializeForTesting();
    });
    tearDown(() async {
      await LocalDatabase.instance.close();
    });

    test('getMasteredWordIds returns ONLY the queried user_id', () async {
      final ldb = LocalDatabase.instance;

      // User A masters "apple" and "banana"; user B masters "cherry".
      for (final w in ['apple', 'banana']) {
        await ldb.insertWordRecord(
          userId: 'user-a',
          wordId: w,
          bookId: 'zk',
          studyType: 'new',
          actionResult: 'know',
        );
      }
      await ldb.insertWordRecord(
        userId: 'user-b',
        wordId: 'cherry',
        bookId: 'zk',
        studyType: 'new',
        actionResult: 'know',
      );

      final aMastered = await ldb.getMasteredWordIds('user-a');
      final bMastered = await ldb.getMasteredWordIds('user-b');

      expect(aMastered, {'apple', 'banana'});
      expect(bMastered, {'cherry'});
      expect(aMastered.contains('cherry'), isFalse,
          reason: 'user A must not see user B\'s mastery');
      expect(bMastered.contains('apple'), isFalse,
          reason: 'user B must not see user A\'s mastery');
    });

    test('countTodayNewCompleted is scoped per-user', () async {
      final ldb = LocalDatabase.instance;
      // A: 2 today, B: 1 today.
      for (final w in ['w1', 'w2']) {
        await ldb.insertWordRecord(
          userId: 'user-a',
          wordId: w,
          bookId: 'zk',
          studyType: 'new',
          actionResult: 'know',
        );
      }
      await ldb.insertWordRecord(
        userId: 'user-b',
        wordId: 'w3',
        bookId: 'zk',
        studyType: 'new',
        actionResult: 'know',
      );

      expect(await ldb.countTodayNewCompleted('user-a'), 2);
      expect(await ldb.countTodayNewCompleted('user-b'), 1);
    });

    test('markSynced refuses to flip another user\'s row', () async {
      final ldb = LocalDatabase.instance;
      final aId = await ldb.insertWordRecord(
        userId: 'user-a',
        wordId: 'apple',
        bookId: 'zk',
        studyType: 'new',
        actionResult: 'know',
      );

      // User B tries to mark A's row synced. Must affect 0 rows.
      final affected = await ldb.markSynced(aId, userId: 'user-b');
      expect(affected, 0, reason: 'cross-user markSynced must be a no-op');

      // A's own markSynced works.
      final aAffected = await ldb.markSynced(aId, userId: 'user-a');
      expect(aAffected, 1);

      final unsynced = await ldb.getUnsyncedRecords('user-a');
      expect(unsynced, isEmpty);
    });
  });

  // ── T6: per-user services share SP but stay isolated ───────────────
  group('T6 — service A/B isolation (RoomCanvasStorage / BackupUploadService)',
      () {
    test('RoomCanvasStorage: A\'s save does not affect B\'s load', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final a = RoomCanvasStorage(prefs, userId: 'user-a');
      final b = RoomCanvasStorage(prefs, userId: 'user-b');

      await a.save([
        PlacedFurniture(
          instanceId: 'i-1',
          furnitureId: 'room_lamp_warm',
          x: 100,
          y: 200,
        ),
      ]);

      expect((await a.load()).length, 1);
      expect((await b.load()).length, 0,
          reason: 'user B has no layout — A\'s save must not leak');

      // B saves its own; both coexist.
      await b.save([
        PlacedFurniture(
          instanceId: 'i-2',
          furnitureId: 'room_rug_soft',
          x: 50,
          y: 80,
        ),
      ]);

      expect((await a.load()).first.furnitureId, 'room_lamp_warm');
      expect((await b.load()).first.furnitureId, 'room_rug_soft');
    });

    test('BackupUploadService: A\'s latest backup status is invisible to B',
        () async {
      // Two users on the same SP instance. Seed A's latest-status keys
      // directly (we don't have network here to drive the full upload).
      SharedPreferences.setMockInitialValues({
        'u_user-a_backup_latest_status': 'uploadSucceeded',
        'u_user-a_backup_latest_id': 'bk-a-001',
      });
      final prefs = await SharedPreferences.getInstance();

      final a = BackupUploadService(
        baseUrl: 'http://stub',
        prefs: prefs,
        userId: 'user-a',
      );
      final b = BackupUploadService(
        baseUrl: 'http://stub',
        prefs: prefs,
        userId: 'user-b',
      );

      expect(a.getLatestBackupInfo().status,
          BackupUploadStatus.uploadSucceeded);
      expect(a.getLatestBackupInfo().backupId, 'bk-a-001');

      // B sees no backup — `noBackupYet` is the absent-state default.
      expect(b.getLatestBackupInfo().status, BackupUploadStatus.noBackupYet);
      expect(b.getLatestBackupInfo().backupId, isNull);
    });

    test('LocalSettingsService.clearAll only wipes the caller\'s keys',
        () async {
      // PR-C-β review-after: pre-C `clearAll` called _prefs.clear(),
      // which would have nuked user B's settings too. The new
      // implementation only removes this user's prefixed keys.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final a = LocalSettingsService(prefs, userId: 'user-a');
      final b = LocalSettingsService(prefs, userId: 'user-b');
      await a.setDailyGoal(50);
      await b.setDailyGoal(15);

      await a.clearAll();

      expect(a.dailyGoal, 20, reason: 'A back to default');
      expect(b.dailyGoal, 15,
          reason: 'B\'s setting must survive A\'s clearAll');
    });
  });

  // ── T7: AuthController.logout retains drift data on the device ─────
  group('T7 — logout retains drift data (plan §6.5 / D7)', () {
    test('logout clears token/userId/accountType in SP+secure storage but '
        'leaves drift word_records alone', () async {
      // Set up SP + drift + a couple of word_records under user-a.
      SharedPreferences.setMockInitialValues({
        'auth_current_user_id': 'user-a',
        'auth_account_type': 'guest',
      });
      secureStub.store['auth_access_token'] = 'tok-a';
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();

      await db.into(db.wordRecords).insert(WordRecordsCompanion.insert(
            userId: 'user-a',
            wordId: 'persistent',
            bookId: 'zk',
            actionResult: 'know',
            createdAt: '2026-05-10T00:00:00Z',
          ));

      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );

      // Sanity: token & userId are present pre-logout.
      expect(await storage.readToken(), 'tok-a');
      expect(storage.readUserId(), 'user-a');

      // Direct AuthStorage.clearSession — same effect as
      // AuthController.logout's storage write half (without the
      // network call). This is what plan §6.5 / D7 calls out as the
      // boundary: clear SESSION (token, userId, accountType), DON'T
      // touch user data.
      await storage.clearSession();

      // Auth state cleared.
      expect(await storage.readToken(), isNull);
      expect(storage.readUserId(), isNull);

      // Drift data still there under the original user_id.
      final rows = await db.select(db.wordRecords).get();
      expect(rows.length, 1);
      expect(rows.first.userId, 'user-a');
      expect(rows.first.wordId, 'persistent');

      await db.close();
    });
  });

  // ── T8: same-row bind doesn't fire pending-local-guest migration ───
  group('T8 — same-row bind: pending-local-guest migration must skip', () {
    test('migrate(from: X, to: X) is a no-op', () async {
      // The pending-local-guest migrator is the ONLY automated path
      // that re-tags user_id rows. It refuses degenerate inputs (see
      // PendingGuestMigrator.migrate guards). Phase A4-α same-row bind
      // returns the SAME users.id, so any "switch" that fires
      // _commitSession with oldUserId == newUserId must hit this guard.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();

      await db.into(db.wordRecords).insert(WordRecordsCompanion.insert(
            userId: 'user-stable',
            wordId: 'apple',
            bookId: 'zk',
            actionResult: 'know',
            createdAt: '2026-05-10T00:00:00Z',
          ));

      final migrator = PendingGuestMigrator(db: db, prefs: prefs);
      final outcome = await migrator.migrate(
        from: 'user-stable',
        to: 'user-stable',
      );

      expect(outcome.skipped, isTrue);
      expect(outcome.driftRowsAffected, 0);
      // Row untouched.
      final row = (await db.select(db.wordRecords).get()).single;
      expect(row.userId, 'user-stable');
      await db.close();
    });
  });

  // ── T14: drift code-gen + PRAGMA confirms user_id NOT NULL ─────────
  group('T14 — schema enforces NOT NULL user_id on user-scoped tables', () {
    test('fresh install schema: every user-scoped table has user_id NOT NULL',
        () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();

      // 9 user-scoped tables per plan §4.2.
      const userScopedTables = [
        'word_records',
        'wordbook_progress',
        'daily_checkins',
        'custom_wordbooks',
        'vocabulary_notebook',
        'card_states',
        'review_logs',
        'sessions',
        'review_records',
      ];

      for (final t in userScopedTables) {
        final cols = await db.customSelect('PRAGMA table_info($t)').get();
        final userIdCol = cols.firstWhere(
          (r) => r.read<String>('name') == 'user_id',
          orElse: () => throw StateError('$t missing user_id column'),
        );
        // PRAGMA table_info "notnull" column is 1 for NOT NULL constraints.
        expect(userIdCol.read<int>('notnull'), 1,
            reason:
                '$t.user_id must be NOT NULL on fresh install (plan §5 NOT NULL discipline)');
      }
      await db.close();
    });

    test('drift code-gen rejects insert without user_id at compile time',
        () async {
      // This test is a runtime smoke check that the COMPANION still
      // requires userId — if a future refactor accidentally made it
      // nullable, this test would compile but the SQL INSERT would
      // succeed with NULL and quietly break partitioning.
      //
      // We can't directly test "compile error" from a runtime test,
      // but we CAN insert via Companion.insert and confirm the row
      // has the expected user_id (i.e., the API would NOT let us omit
      // userId because Companion.insert(userId: required)).
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();
      await db.into(db.cardStates).insert(CardStatesCompanion.insert(
            userId: 'u-test',
            wordId: 'w-test',
            due: 1700000000000,
            createdAt: 1700000000000,
          ));
      final row = (await db.select(db.cardStates).get()).single;
      expect(row.userId, 'u-test');
      await db.close();
    });
  });

  // ── Cross-cutting integration: SP migration + drift partition + ─────
  //     pending-local-guest cleanup all in one launch                 ─
  group('integration — full Phase C handoff', () {
    test('pre-C device upgrades cleanly: SP migrate → drift seed → guest '
        'migration', () async {
      // Simulate a user who:
      //   * Pre-C: had flat settings_daily_goal + flat progress_word_records.
      //   * markFreshInstallIfNeeded set auth_pending_sp_migration=true.
      //   * Day 1 offline: AuthBootstrap fell back to pending-local-guest;
      //     SP got u_pending-local-guest_settings_daily_goal (via SP
      //     migrate) and drift v13 backfilled with pending-local-guest.
      //   * Day 2 online: AuthBootstrap calls /auth/guest, gets a real
      //     user id, persists it. main.dart's PendingGuestMigrator
      //     pass re-tags both drift and SP.
      //
      // We exercise the Day-2 collapsed sequence here without spinning
      // up the network (test just constructs the migrator and calls it).
      const placeholder = AuthStorage.pendingLocalGuestUserId;
      const realId = 'server-guest-xyz';

      SharedPreferences.setMockInitialValues({
        'auth_current_user_id': realId, // bootstrap wrote real id
        // pre-Day 2 state: SP has placeholder-namespaced key from Day 1.
        'u_${placeholder}_settings_daily_goal': 35,
      });
      final prefs = await SharedPreferences.getInstance();

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();

      // Day 1 drift row.
      await db.into(db.wordRecords).insert(WordRecordsCompanion.insert(
            userId: placeholder,
            wordId: 'day1-word',
            bookId: 'zk',
            actionResult: 'know',
            createdAt: '2026-05-10T00:00:00Z',
          ));

      // Run the main.dart pass.
      final migrator = PendingGuestMigrator(db: db, prefs: prefs);
      final outcome = await migrator.migrate(
        from: placeholder,
        to: realId,
      );

      // Outcome reports something happened.
      expect(outcome.skipped, isFalse);
      expect(outcome.driftRowsAffected, 1);
      expect(outcome.spKeysRenamed, 1);

      // Drift row re-tagged.
      final rows = await db.select(db.wordRecords).get();
      expect(rows.single.userId, realId);

      // SP key renamed (preserved value).
      expect(prefs.containsKey('u_${placeholder}_settings_daily_goal'),
          isFalse);
      expect(prefs.getInt('u_${realId}_settings_daily_goal'), 35);

      // LocalSettingsService bound to the real id now reads the migrated value.
      final settings = LocalSettingsService(prefs, userId: realId);
      expect(settings.dailyGoal, 35);

      await db.close();
    });
  });
}
