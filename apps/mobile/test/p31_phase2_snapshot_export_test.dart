/// P3.1 Phase 2 — Snapshot export tests (updated for SQLite-first).
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:meow_mobile/core/storage/local_settings_service.dart';
import 'package:meow_mobile/core/storage/local_progress_repository.dart';
import 'package:meow_mobile/core/storage/local_database.dart';
import 'package:meow_mobile/core/storage/snapshot_export_service.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';

void main() {
  // Use FFI for SQLite in tests (desktop)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late LocalSettingsService settings;
  late LocalProgressRepository progress;
  late SnapshotExportService exportService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settings = LocalSettingsService(prefs);
    progress = LocalProgressRepository(prefs);

    // Initialize fresh in-memory SQLite for each test
    await LocalDatabase.deleteDatabase_();
    await LocalDatabase.initialize();

    exportService = SnapshotExportService(
      settings: settings,
      progress: progress,
      db: LocalDatabase.instance,
    );
  });

  tearDown(() async {
    await LocalDatabase.instance.close();
  });

  group('Snapshot shape', () {
    test('has schema_version at top level', () async {
      final result = await exportService.export();
      expect(result.isSuccess, true);
      expect(result.snapshotMap!['schema_version'], 'p3_1_snapshot_v2');
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
      expect(SnapshotExportService.schemaVersion, 'p3_1_snapshot_v2');
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
      expect(P3FeatureGuard.isCloudBackupEnabled, false);
    });

    test('export is read-only (does not modify data)', () async {
      await LocalDatabase.instance.insertWordRecord(
        wordId: 'w-001', bookId: 'cet4', studyType: 'new', actionResult: 'know',
      );
      final before = await LocalDatabase.instance.getAllWordRecords();

      await exportService.export();

      final after = await LocalDatabase.instance.getAllWordRecords();
      expect(after.length, before.length);
    });
  });
}
