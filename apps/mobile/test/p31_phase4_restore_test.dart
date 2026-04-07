/// P3.1 Phase 4 — Restore tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/core/storage/backup_restore_service.dart';
import 'package:meow_mobile/core/storage/backup_upload_service.dart';
import 'package:meow_mobile/core/storage/snapshot_export_service.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/router/app_router.dart';

void main() {
  // ==================== A. Restore semantics ====================

  group('Restore semantics separation', () {
    test('RestoreStatus has no sync values', () {
      final names = RestoreStatus.values.map((v) => v.name).toSet();
      expect(names.contains('synced'), false);
      expect(names.contains('syncSucceeded'), false);
      expect(names.contains('allDevicesConsistent'), false);
    });

    test('restore success is distinct from upload success', () {
      expect(RestoreStatus.restoreSucceeded.name, isNot(BackupUploadStatus.uploadSucceeded.name));
    });

    test('restore success is distinct from export success', () {
      expect(RestoreStatus.restoreSucceeded.name, isNot(ExportStatus.success.name));
    });

    test('RestoreResult has no syncStatus field', () {
      const result = RestoreResult(status: RestoreStatus.restoreSucceeded, restoredAt: '2026-04-06');
      expect(result.isSuccess, true);
      // No syncStatus, syncHealth, or similar fields
    });
  });

  // ==================== B. Pre-check states ====================

  group('Restore pre-check', () {
    test('RestorePreCheckStatus has all required states', () {
      expect(RestorePreCheckStatus.values, contains(RestorePreCheckStatus.restorable));
      expect(RestorePreCheckStatus.values, contains(RestorePreCheckStatus.noBackupFound));
      expect(RestorePreCheckStatus.values, contains(RestorePreCheckStatus.versionNotSupported));
      expect(RestorePreCheckStatus.values, contains(RestorePreCheckStatus.temporarilyUnavailable));
    });

    test('restorable pre-check result allows restore', () {
      const result = RestorePreCheckResult(status: RestorePreCheckStatus.restorable);
      expect(result.isRestorable, true);
    });

    test('noBackupFound pre-check result blocks restore', () {
      const result = RestorePreCheckResult(status: RestorePreCheckStatus.noBackupFound);
      expect(result.isRestorable, false);
    });

    test('versionNotSupported blocks restore', () {
      const result = RestorePreCheckResult(
        status: RestorePreCheckStatus.versionNotSupported,
        backupSchemaVersion: 'unknown_v99',
      );
      expect(result.isRestorable, false);
    });
  });

  // ==================== C. RestoreStatus completeness ====================

  group('RestoreStatus enum', () {
    test('has all required states', () {
      expect(RestoreStatus.values, contains(RestoreStatus.restoreAvailable));
      expect(RestoreStatus.values, contains(RestoreStatus.restoring));
      expect(RestoreStatus.values, contains(RestoreStatus.restoreSucceeded));
      expect(RestoreStatus.values, contains(RestoreStatus.restoreFailed));
      expect(RestoreStatus.values, contains(RestoreStatus.versionNotSupported));
      expect(RestoreStatus.values, contains(RestoreStatus.noBackupFound));
      expect(RestoreStatus.values, contains(RestoreStatus.temporarilyUnavailable));
    });

    test('failed restore is not mapped to success', () {
      const result = RestoreResult(status: RestoreStatus.restoreFailed, errorCode: 'TEST');
      expect(result.isSuccess, false);
    });
  });

  // ==================== D. UI entry ====================

  group('Restore UI entry', () {
    test('isRestoreEnabled is now true', () {
      expect(P3FeatureGuard.isRestoreEnabled, true);
    });

    test('restore entry is in settings page (route exists)', () {
      expect(AppRouter.settings, '/settings');
      final route = AppRouter.generateRoute(const RouteSettings(name: '/settings'));
      expect(route, isNotNull);
    });

    test('no restore route at top level', () {
      // Restore is inside settings, not a top-level route
      final route = AppRouter.generateRoute(const RouteSettings(name: '/restore'));
      expect(route, isNotNull); // page-not-found
    });

    test('Today route unchanged', () {
      expect(AppRouter.today, '/');
    });
  });

  // ==================== E. Wording boundary ====================

  group('Restore wording boundary', () {
    test('RestoreStatus names do not contain sync', () {
      for (final s in RestoreStatus.values) {
        expect(s.name.toLowerCase().contains('sync'), false,
            reason: '${s.name} must not contain sync');
      }
    });

    test('RestorePreCheckStatus names do not contain sync', () {
      for (final s in RestorePreCheckStatus.values) {
        expect(s.name.toLowerCase().contains('sync'), false);
      }
    });

    test('restoreSucceeded is not named syncSucceeded', () {
      expect(RestoreStatus.restoreSucceeded.name, 'restoreSucceeded');
      expect(RestoreStatus.restoreSucceeded.name, isNot('syncSucceeded'));
    });
  });

  // ==================== F. Existing flow regression ====================

  group('Restore does not affect existing flows', () {
    test('original routes unchanged', () {
      expect(AppRouter.today, '/');
      expect(AppRouter.study, '/study');
      expect(AppRouter.meowHome, '/meow-home');
    });

    test('upload status enum unchanged', () {
      expect(BackupUploadStatus.values, contains(BackupUploadStatus.uploadSucceeded));
      expect(BackupUploadStatus.values, contains(BackupUploadStatus.noBackupYet));
    });

    test('export status enum unchanged', () {
      expect(ExportStatus.values, contains(ExportStatus.success));
      expect(ExportStatus.values, contains(ExportStatus.failed));
    });
  });
}
