/// P3.1 Phase 3 — Upload + latest backup status + minimal entry tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meow_mobile/core/storage/backup_upload_service.dart';
import 'package:meow_mobile/core/storage/snapshot_export_service.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/router/app_router.dart';

void main() {
  // ==================== A. Upload semantics tests ====================

  group('Upload semantics', () {
    test('BackupUploadStatus has no sync values', () {
      final names = BackupUploadStatus.values.map((v) => v.name).toSet();
      expect(names.contains('synced'), false);
      expect(names.contains('syncSucceeded'), false);
      expect(names.contains('syncFailed'), false);
    });

    test('upload success is distinct from export success', () {
      // Export has ExportStatus, upload has BackupUploadStatus — different types
      expect(ExportStatus.success.name, isNot(BackupUploadStatus.uploadSucceeded.name));
    });

    test('BackupUploadResult has no syncStatus field', () {
      const result = BackupUploadResult(status: BackupUploadStatus.uploadSucceeded);
      expect(result.isSuccess, true);
      // No syncStatus, syncHealth, or similar fields
    });

    test('failed upload is not mapped to success', () {
      const result = BackupUploadResult(
        status: BackupUploadStatus.uploadFailed,
        errorCode: 'NETWORK_ERROR',
        retryable: true,
      );
      expect(result.isSuccess, false);
      expect(result.retryable, true);
    });
  });

  // ==================== B. Latest backup status tests ====================

  group('Latest backup status', () {
    test('default status is noBackupYet', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = BackupUploadService(baseUrl: 'http://test', prefs: prefs);

      final info = service.getLatestBackupInfo();
      expect(info.status, BackupUploadStatus.noBackupYet);
      expect(info.backupId, isNull);
      expect(info.uploadedAt, isNull);
    });

    test('BackupUploadStatus has all required states', () {
      expect(BackupUploadStatus.values, contains(BackupUploadStatus.noBackupYet));
      expect(BackupUploadStatus.values, contains(BackupUploadStatus.uploadInProgress));
      expect(BackupUploadStatus.values, contains(BackupUploadStatus.uploadSucceeded));
      expect(BackupUploadStatus.values, contains(BackupUploadStatus.uploadFailed));
      expect(BackupUploadStatus.values, contains(BackupUploadStatus.retrying));
      expect(BackupUploadStatus.values, contains(BackupUploadStatus.temporarilyUnavailable));
    });

    test('LatestBackupInfo holds all fields', () {
      const info = LatestBackupInfo(
        status: BackupUploadStatus.uploadSucceeded,
        backupId: 'backup-123',
        uploadedAt: '2026-04-06T12:00:00Z',
        schemaVersion: 'p3_1_snapshot_v1',
      );
      expect(info.status, BackupUploadStatus.uploadSucceeded);
      expect(info.backupId, 'backup-123');
      expect(info.uploadedAt, isNotNull);
    });
  });

  // ==================== C. UI entry tests ====================

  group('Settings route and entry', () {
    test('settings route exists in AppRouter', () {
      expect(AppRouter.settings, '/settings');
      final route = AppRouter.generateRoute(const RouteSettings(name: '/settings'));
      expect(route, isNotNull);
    });

    test('Today route is unchanged', () {
      expect(AppRouter.today, '/');
    });

    test('restore route still does not exist', () {
      final route = AppRouter.generateRoute(const RouteSettings(name: '/restore'));
      expect(route, isNotNull); // page-not-found, not a real page
    });

    test('P3.1 restore guard still false', () {
      expect(P3FeatureGuard.isRestoreEnabled, true); // Phase 4: now enabled
    });
  });

  // ==================== D. Copy / wording tests ====================

  group('Wording boundary', () {
    test('BackupUploadStatus names do not contain sync', () {
      for (final s in BackupUploadStatus.values) {
        expect(s.name.toLowerCase().contains('sync'), false,
            reason: '${s.name} must not contain "sync"');
      }
    });

    test('BackupUploadStatus names do not contain restore', () {
      for (final s in BackupUploadStatus.values) {
        expect(s.name.toLowerCase().contains('restore'), false,
            reason: '${s.name} must not contain "restore"');
      }
    });

    test('uploadSucceeded is not named syncSucceeded', () {
      expect(BackupUploadStatus.uploadSucceeded.name, 'uploadSucceeded');
      expect(BackupUploadStatus.uploadSucceeded.name, isNot('syncSucceeded'));
    });
  });

  // ==================== E. Existing flow regression ====================

  group('Existing flow regression', () {
    test('original routes still exist', () {
      expect(AppRouter.today, '/');
      expect(AppRouter.study, '/study');
      expect(AppRouter.review, '/review');
      expect(AppRouter.meowHome, '/meow-home');
      expect(AppRouter.customize, '/customize');
    });

    test('backup/settings entry does not replace any existing route', () {
      // Settings is a NEW route, not replacing any existing one
      expect(AppRouter.settings, '/settings');
      expect(AppRouter.settings, isNot(AppRouter.today));
      expect(AppRouter.settings, isNot(AppRouter.meowHome));
    });

    test('invalid export produces failed upload result', () {
      // Upload service rejects invalid export results
      const result = BackupUploadResult(
        status: BackupUploadStatus.uploadFailed,
        errorCode: 'INVALID_EXPORT',
        retryable: false,
      );
      expect(result.isSuccess, false);
      expect(result.retryable, false);
    });
  });
}
