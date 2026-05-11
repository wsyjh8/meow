/// 需求 23 Phase C PR-C-γ §4.6: PendingGuestMigrator behaviour matrix.
///
/// Verifies the cross-storage migration:
///   1. Drift rows tagged `user_id = pending-local-guest` get
///      re-tagged to a freshly issued server user_id.
///   2. SP keys with the `u_pending-local-guest_*` namespace get
///      renamed to `u_<server_id>_*`.
///   3. Idempotent — second run is a no-op.
///   4. Refuses degenerate inputs (empty / same id).
library;

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meow_mobile/core/auth/auth_storage.dart';
import 'package:meow_mobile/core/auth/pending_guest_migrator.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // PR-C-α v13 migration backfills with `auth_current_user_id` from SP.
    // Seed it to the placeholder so any rows we INSERT via the v13
    // codegen path get tagged with `pending-local-guest`.
    SharedPreferences.setMockInitialValues({
      'auth_current_user_id': AuthStorage.pendingLocalGuestUserId,
    });
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Force drift to open (onCreate runs).
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async {
    await db.close();
  });

  test('migrate moves drift rows from pending-local-guest to server id',
      () async {
    // Seed one row in each of 3 representative user-scoped tables.
    const placeholder = AuthStorage.pendingLocalGuestUserId;
    await db.into(db.wordRecords).insert(WordRecordsCompanion.insert(
          userId: placeholder,
          wordId: 'apple',
          bookId: 'zk',
          actionResult: 'know',
          createdAt: '2026-05-10T00:00:00Z',
        ));
    await db.into(db.cardStates).insert(CardStatesCompanion.insert(
          userId: placeholder,
          wordId: 'apple',
          due: 1700000000000,
          createdAt: 1700000000000,
        ));
    await db.into(db.dailyCheckins).insert(DailyCheckinsCompanion.insert(
          userId: placeholder,
          date: '2026-05-10',
          createdAt: '2026-05-10T00:00:00Z',
        ));

    final prefs = await SharedPreferences.getInstance();
    final migrator = PendingGuestMigrator(db: db, prefs: prefs);

    final outcome = await migrator.migrate(
      from: placeholder,
      to: 'server-guest-001',
    );

    expect(outcome.skipped, isFalse);
    expect(outcome.hasError, isFalse);
    expect(outcome.driftRowsAffected, 3,
        reason: '3 seeded rows across 3 tables should be re-tagged');

    // Verify each row is now under the real id.
    final wr = (await db.select(db.wordRecords).get()).single;
    expect(wr.userId, 'server-guest-001');
    final cs = (await db.select(db.cardStates).get()).single;
    expect(cs.userId, 'server-guest-001');
    final dc = (await db.select(db.dailyCheckins).get()).single;
    expect(dc.userId, 'server-guest-001');

    // And no rows remain under the placeholder.
    final stillPlaceholderCount = await db
        .customSelect(
          'SELECT (SELECT COUNT(*) FROM word_records WHERE user_id = ?) '
          '+ (SELECT COUNT(*) FROM card_states WHERE user_id = ?) '
          '+ (SELECT COUNT(*) FROM daily_checkins WHERE user_id = ?) '
          'AS n',
          variables: List.filled(3, Variable.withString(placeholder)),
        )
        .getSingle();
    expect(stillPlaceholderCount.read<int>('n'), 0);
  });

  test('migrate renames u_<from>_* SP keys to u_<to>_*', () async {
    SharedPreferences.setMockInitialValues({
      'auth_current_user_id': AuthStorage.pendingLocalGuestUserId,
      // Three sample per-user keys under the pending namespace.
      'u_${AuthStorage.pendingLocalGuestUserId}_settings_daily_goal': 25,
      'u_${AuthStorage.pendingLocalGuestUserId}_settings_theme': 'dark',
      'u_${AuthStorage.pendingLocalGuestUserId}_settings_sound_enabled':
          false,
      // A key under a DIFFERENT user — must NOT be touched.
      'u_other-user_settings_daily_goal': 99,
    });
    final prefs = await SharedPreferences.getInstance();
    final migrator = PendingGuestMigrator(db: db, prefs: prefs);

    final outcome = await migrator.migrate(
      from: AuthStorage.pendingLocalGuestUserId,
      to: 'server-guest-002',
    );

    expect(outcome.spKeysRenamed, 3);

    // Old keys gone, new keys present with same values.
    expect(
        prefs.containsKey(
            'u_${AuthStorage.pendingLocalGuestUserId}_settings_daily_goal'),
        isFalse);
    expect(prefs.getInt('u_server-guest-002_settings_daily_goal'), 25);
    expect(prefs.getString('u_server-guest-002_settings_theme'), 'dark');
    expect(prefs.getBool('u_server-guest-002_settings_sound_enabled'),
        isFalse);

    // The unrelated user's keys are untouched.
    expect(prefs.getInt('u_other-user_settings_daily_goal'), 99);
  });

  test('migrate is idempotent — second run is a no-op', () async {
    const placeholder = AuthStorage.pendingLocalGuestUserId;
    await db.into(db.wordRecords).insert(WordRecordsCompanion.insert(
          userId: placeholder,
          wordId: 'banana',
          bookId: 'zk',
          actionResult: 'know',
          createdAt: '2026-05-10T00:00:00Z',
        ));

    final prefs = await SharedPreferences.getInstance();
    final migrator = PendingGuestMigrator(db: db, prefs: prefs);

    final first = await migrator.migrate(
      from: placeholder,
      to: 'server-guest-003',
    );
    expect(first.driftRowsAffected, 1);

    final second = await migrator.migrate(
      from: placeholder,
      to: 'server-guest-003',
    );
    expect(second.driftRowsAffected, 0,
        reason: 'no rows remain tagged with the placeholder');
    expect(second.spKeysRenamed, 0);
    expect(second.isNoop, isTrue);

    // Row still belongs to the real id (didn't get accidentally cleared).
    final wr = (await db.select(db.wordRecords).get()).single;
    expect(wr.userId, 'server-guest-003');
  });

  test('migrate skips when from == to or empty', () async {
    final prefs = await SharedPreferences.getInstance();
    final migrator = PendingGuestMigrator(db: db, prefs: prefs);

    final same =
        await migrator.migrate(from: 'abc', to: 'abc');
    expect(same.skipped, isTrue);
    expect(same.driftRowsAffected, 0);

    final emptyFrom =
        await migrator.migrate(from: '', to: 'abc');
    expect(emptyFrom.skipped, isTrue);

    final emptyTo =
        await migrator.migrate(from: 'abc', to: '');
    expect(emptyTo.skipped, isTrue);
  });

  test('migrate does NOT overwrite an already-present target SP key',
      () async {
    SharedPreferences.setMockInitialValues({
      'auth_current_user_id': AuthStorage.pendingLocalGuestUserId,
      // Source has goal=10, target ALREADY has goal=42 (e.g., user
      // configured something while bound to server-guest-004 in a
      // previous session). The migrator must preserve the target
      // value and just drop the source.
      'u_${AuthStorage.pendingLocalGuestUserId}_settings_daily_goal': 10,
      'u_server-guest-004_settings_daily_goal': 42,
    });
    final prefs = await SharedPreferences.getInstance();
    final migrator = PendingGuestMigrator(db: db, prefs: prefs);

    final outcome = await migrator.migrate(
      from: AuthStorage.pendingLocalGuestUserId,
      to: 'server-guest-004',
    );

    expect(outcome.spKeysRenamed, 1,
        reason: 'we still report the rename even though we drop the source');
    expect(prefs.getInt('u_server-guest-004_settings_daily_goal'), 42,
        reason: 'pre-existing target value preserved');
    expect(
        prefs.containsKey(
            'u_${AuthStorage.pendingLocalGuestUserId}_settings_daily_goal'),
        isFalse);
  });
}
