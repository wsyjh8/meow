/// P3.1 Phase 2 — Snapshot export tests (updated for SQLite-first).
///
/// 需求 23 Phase C PR-C-β D9: LocalProgressRepository has been deleted —
/// SnapshotExportService reads progress directly from SQLite, scoped by
/// userId. The `progress:` field is gone from the constructor; the
/// snapshot Map still has a `progress` section but its rows come from
/// `LocalDatabase.getAllWordRecords(userId)` etc.
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:meow_mobile/core/storage/local_settings_service.dart';
import 'package:meow_mobile/core/storage/local_database.dart';
import 'package:meow_mobile/core/storage/snapshot_export_service.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';

void main() {
  const testUserId = 'test-user';

  // Use FFI for SQLite in tests (desktop)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late LocalSettingsService settings;
  late SnapshotExportService exportService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settings = LocalSettingsService(prefs, userId: testUserId);

    // Initialize fresh SQLite for each test. PR-C-α: drift owns schema,
    // so this test uses [initializeForTesting] to emit the v13 legacy
    // schema in the sqflite file directly (no drift here).
    await LocalDatabase.deleteDatabase_();
    await LocalDatabase.initializeForTesting();

    exportService = SnapshotExportService(
      settings: settings,
      db: LocalDatabase.instance,
      userId: testUserId,
    );
  });

  tearDown(() async {
    await LocalDatabase.instance.close();
  });

  group('Snapshot shape', () {
    test('has schema_version at top level', () async {
      final result = await exportService.export();
      expect(result.isSuccess, true);
      // P3.2: schema bumped to p3_2_snapshot_v1 (includes card_states + device info)
      expect(result.snapshotMap!['schema_version'], 'p3_2_snapshot_v1');
    });

    test('has exported_at at top level', () async {
      final result = await exportService.export();
      expect(result.snapshotMap!['exported_at'], isNotNull);
    });

    test('has settings and progress sections', () async {
      final result = await exportService.export();
      expect(result.snapshotMap!['settings'], isA<Map>());
      expect(result.snapshotMap!['progress'], isA<Map>());
    });

    test('snapshot JSON is valid', () async {
      final result = await exportService.export();
      expect(result.snapshotJson, isNotNull);
      final parsed = json.decode(result.snapshotJson!);
      expect(parsed, isA<Map>());
    });
  });

  group('Snapshot includes SQLite word_records', () {
    test('word_records from SQLite appear in snapshot', () async {
      // Insert a record into SQLite
      await LocalDatabase.instance.insertWordRecord(
        userId: testUserId,
        wordId: 'w-001',
        bookId: 'cet4',
        studyType: 'new',
        actionResult: 'know',
      );

      final result = await exportService.export();
      final records = result.snapshotMap!['progress']['word_records'] as List;
      expect(records.length, 1);
      expect(records[0]['word_id'], 'w-001');
      expect(records[0]['action_result'], 'know');
    });

    test('empty SQLite produces empty word_records', () async {
      final result = await exportService.export();
      final records = result.snapshotMap!['progress']['word_records'] as List;
      expect(records, isEmpty);
    });
  });

  group('Export semantics', () {
    test('export success only means local export', () async {
      final result = await exportService.export();
      expect(result.isSuccess, true);
      expect(result.status, ExportStatus.success);
    });

    test('ExportStatus has no sync values', () {
      final names = ExportStatus.values.map((v) => v.name).toSet();
      expect(names.contains('synced'), false);
    });

    test('schema version is v2', () {
      // P3.2: schema version bumped to include card_states + device info
      expect(SnapshotExportService.schemaVersion, 'p3_2_snapshot_v1');
    });
  });

  group('Empty and failure handling', () {
    test('empty local data produces valid minimal snapshot', () async {
      final result = await exportService.export();
      expect(result.isSuccess, true);
      expect(result.byteLength, greaterThan(0));
    });

    test('failed export does not return success', () {
      const failedResult = SnapshotExportResult(
        status: ExportStatus.failed,
        errorCode: 'TEST',
      );
      expect(failedResult.isSuccess, false);
    });
  });

  group('Existing flow regression', () {
    test('P3.1 cloud backup guard still false', () {
      // P3.2: cloud backup is now enabled
      expect(P3FeatureGuard.isCloudBackupEnabled, true);
    });

    test('export is read-only (does not modify data)', () async {
      await LocalDatabase.instance.insertWordRecord(
        userId: testUserId,
        wordId: 'w-001', bookId: 'cet4', studyType: 'new', actionResult: 'know',
      );
      final before =
          await LocalDatabase.instance.getAllWordRecords(testUserId);

      await exportService.export();

      final after =
          await LocalDatabase.instance.getAllWordRecords(testUserId);
      expect(after.length, before.length);
    });
  });
}
