/// 需求 23 Phase E1 PR-E0.1 (plan-023-E1-v2 §3.1): regression test that
/// pins backup-related services to the centralised [apiV1Base] instead
/// of the Android-emulator-only hardcoded `http://10.0.2.2:3000/api/v1`.
///
/// Pre-PR-E0.1 the backup paths in `settings_page.dart` (3 call sites)
/// and `auto_backup_service.dart` (1 call site) hardcoded the dev
/// emulator address, so release builds with `--dart-define=API_BASE=
/// https://api.<domain>/api/v1` would still talk to the dev IP and
/// fail to upload / restore backups in production. PR-E0.1 routes all
/// four sites through `apiV1Base`.
///
/// The tests below assert two things:
///   (a) `BackupUploadService` / `BackupRestoreService` accept
///       `apiV1Base` as a constructor arg and expose it via `baseUrl`.
///   (b) The two source files no longer contain a string-literal
///       `'http://10.0.2.2:3000/api/v1'`, so future edits can't
///       silently re-introduce the hardcode.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:meow_mobile/core/config/api_base.dart';
import 'package:meow_mobile/core/storage/backup_restore_service.dart';
import 'package:meow_mobile/core/storage/backup_upload_service.dart';
import 'package:meow_mobile/core/storage/local_database.dart';
import 'package:meow_mobile/core/storage/local_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('PR-E0.1 — backup baseUrl wired to apiV1Base', () {
    test('apiV1Base is non-empty (dev fallback or --dart-define injection)',
        () {
      expect(apiV1Base, isNotEmpty);
      // Must end with /api/v1 because call sites concatenate
      // '$baseUrl/me/backup' etc.
      expect(apiV1Base.endsWith('/api/v1'), isTrue,
          reason: 'apiV1Base must include the /api/v1 prefix so concat '
              "with '/me/backup' produces a valid route.");
    });

    test('BackupUploadService stores apiV1Base verbatim', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = BackupUploadService(
        baseUrl: apiV1Base,
        prefs: prefs,
        userId: 'user-A',
      );
      expect(svc.baseUrl, equals(apiV1Base));
    });

    test('BackupRestoreService stores apiV1Base verbatim', () async {
      SharedPreferences.setMockInitialValues({});
      await LocalDatabase.deleteDatabase_();
      await LocalDatabase.initializeForTesting();
      final prefs = await SharedPreferences.getInstance();
      final settings = LocalSettingsService(prefs, userId: 'user-A');
      final svc = BackupRestoreService(
        baseUrl: apiV1Base,
        settings: settings,
        db: LocalDatabase.instance,
        userId: 'user-A',
      );
      expect(svc.baseUrl, equals(apiV1Base));
      await LocalDatabase.instance.close();
    });

    test(
        'settings_page.dart contains no hardcoded 10.0.2.2 URL string '
        'and imports apiV1Base', () {
      final source = File('lib/features/settings/settings_page.dart')
          .readAsStringSync();
      expect(source.contains("'http://10.0.2.2"), isFalse,
          reason: 'baseUrl literal regressed — see PR-E0.1.');
      expect(source.contains('apiV1Base'), isTrue,
          reason: 'settings_page.dart must reference apiV1Base instead.');
      expect(source.contains("import '../../core/config/api_base.dart';"),
          isTrue);
    });

    test(
        'auto_backup_service.dart routes _baseUrl through apiV1Base '
        '(no hardcoded URL string)', () {
      final source =
          File('lib/core/storage/auto_backup_service.dart').readAsStringSync();
      // The string literal that pre-E0.1 used must be gone.
      expect(source.contains("'http://10.0.2.2:3000/api/v1'"), isFalse,
          reason: 'baseUrl literal regressed — see PR-E0.1.');
      // The doc-comment still references the address as explanation; only
      // the actual code expression should not.
      expect(source.contains('apiV1Base'), isTrue);
      expect(
          source.contains("import '../config/api_base.dart';"), isTrue);
    });
  });
}
