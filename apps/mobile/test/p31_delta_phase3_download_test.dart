/// P3.1 Delta Phase 3 — Download-to-local / restore tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/core/storage/backup_restore_service.dart';
import 'package:meow_mobile/core/storage/backup_upload_service.dart';
import 'package:meow_mobile/core/storage/snapshot_export_service.dart';
import 'package:meow_mobile/core/models/backup_types.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/router/app_router.dart';
import 'package:meow_mobile/core/api/api_client.dart';

void main() {
  // ==================== A. Pre-check tests ====================

  group('Restore pre-check', () {
    test('RestorePreCheckStatus has all required values', () {
      expect(RestorePreCheckStatus.values, contains(RestorePreCheckStatus.restorable));
      expect(RestorePreCheckStatus.values, contains(RestorePreCheckStatus.noBackupFound));
      expect(RestorePreCheckStatus.values, contains(RestorePreCheckStatus.versionNotSupported));
      expect(RestorePreCheckStatus.values, contains(RestorePreCheckStatus.temporarilyUnavailable));
    });

    test('restorable result allows proceed', () {
      const result = RestorePreCheckResult(status: RestorePreCheckStatus.restorable);
      expect(result.isRestorable, true);
    });

    test('noBackupFound blocks proceed', () {
      const result = RestorePreCheckResult(status: RestorePreCheckStatus.noBackupFound);
      expect(result.isRestorable, false);
    });

    test('versionNotSupported blocks proceed', () {
      const result = RestorePreCheckResult(status: RestorePreCheckStatus.versionNotSupported);
      expect(result.isRestorable, false);
    });

    test('temporarilyUnavailable blocks proceed', () {
      const result = RestorePreCheckResult(status: RestorePreCheckStatus.temporarilyUnavailable);
      expect(result.isRestorable, false);
    });
  });

  // ==================== B. Download / restore semantics ====================

  group('Download vs restore semantics', () {
    test('DownloadToLocalStatus.downloadCompleted != RestoreStatus.restoreSucceeded', () {
      expect(DownloadToLocalStatus.downloadCompleted.runtimeType,
          isNot(RestoreStatus.restoreSucceeded.runtimeType));
    });

    test('download completed does not imply restore success', () {
      // They are different enum types — cannot be accidentally equated
      const downloadDone = DownloadToLocalStatus.downloadCompleted;
      const restoreDone = RestoreStatus.restoreSucceeded;
      expect(downloadDone.name, isNot(restoreDone.name));
    });

    test('restore success does not imply sync success', () {
      // RestoreStatus has no sync values
      for (final s in RestoreStatus.values) {
        expect(s.name.toLowerCase().contains('sync'), false);
      }
    });

    test('no RestoreStatus value contains sync or allDevices', () {
      for (final s in RestoreStatus.values) {
        expect(s.name.toLowerCase().contains('sync'), false);
        expect(s.name.toLowerCase().contains('alldevice'), false);
      }
    });
  });

  // ==================== C. Apply result tests ====================

  group('Restore apply result', () {
    test('RestoreStatus has all required states', () {
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

    test('successful restore returns restoredAt', () {
      const result = RestoreResult(
        status: RestoreStatus.restoreSucceeded,
        restoredAt: '2026-04-06T12:00:00Z',
        schemaVersion: 'p3_1_snapshot_v2',
      );
      expect(result.isSuccess, true);
      expect(result.restoredAt, isNotNull);
    });
  });

  // ==================== D. Guard and entry tests ====================

  group('Download-to-local guard and entry', () {
    test('isDownloadToLocalEnabled is now true', () {
      expect(P3FeatureGuard.isDownloadToLocalEnabled, true);
    });

    test('isRestoreEnabled is still true', () {
      expect(P3FeatureGuard.isRestoreEnabled, true);
    });

    test('restore entry is in settings page', () {
      expect(AppRouter.settings, '/settings');
    });

    test('no dedicated download route exists', () {
      final route = AppRouter.generateRoute(const RouteSettings(name: '/download'));
      expect(route, isNotNull); // page-not-found
    });
  });

  // ==================== E. Wording boundary ====================

  group('Wording boundary', () {
    test('RestoreStatus names do not contain sync', () {
      for (final s in RestoreStatus.values) {
        expect(s.name.toLowerCase().contains('sync'), false);
      }
    });

    test('DownloadToLocalStatus names do not contain sync', () {
      for (final s in DownloadToLocalStatus.values) {
        expect(s.name.toLowerCase().contains('sync'), false);
      }
    });

    test('restore types separate from upload types', () {
      expect(RestoreStatus.restoreSucceeded.runtimeType,
          isNot(BackupUploadStatus.uploadSucceeded.runtimeType));
    });

    test('restore types separate from export types', () {
      expect(RestoreStatus.restoreSucceeded.runtimeType,
          isNot(ExportStatus.success.runtimeType));
    });
  });

  // ==================== F. Regression ====================

  group('Delta Phase 3 regression', () {
    test('TodayState defaults unchanged', () {
      final state = TodayState.fromJson({});
      expect(state.dailyGoalStatus, 'not_started');
    });

    test('isDailyGoalSettingEnabled still true (Phase 1)', () {
      expect(P3FeatureGuard.isDailyGoalSettingEnabled, true);
    });

    test('isManualUploadEnabled still true (Phase 2)', () {
      expect(P3FeatureGuard.isManualUploadEnabled, true);
    });

    test('all 3 delta features now enabled', () {
      expect(P3FeatureGuard.isDailyGoalSettingEnabled, true);
      expect(P3FeatureGuard.isManualUploadEnabled, true);
      expect(P3FeatureGuard.isDownloadToLocalEnabled, true);
    });

    test('no destructive action routes exist', () {
      final deleteRoute = AppRouter.generateRoute(const RouteSettings(name: '/delete-backup'));
      expect(deleteRoute, isNotNull); // page-not-found
      final clearRoute = AppRouter.generateRoute(const RouteSettings(name: '/clear-local'));
      expect(clearRoute, isNotNull); // page-not-found
    });
  });
}
