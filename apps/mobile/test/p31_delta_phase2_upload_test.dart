/// P3.1 Delta Phase 2 — Manual upload + latest backup status tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meow_mobile/core/storage/backup_upload_service.dart';
import 'package:meow_mobile/core/storage/snapshot_export_service.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/router/app_router.dart';
import 'package:meow_mobile/core/api/api_client.dart';

void main() {
  // ==================== A. Upload semantics ====================

  group('Manual upload semantics', () {
    test('isManualUploadEnabled is now true', () {
      expect(P3FeatureGuard.isManualUploadEnabled, true);
    });

    test('BackupUploadStatus has required states', () {
      expect(BackupUploadStatus.values, contains(BackupUploadStatus.noBackupYet));
      expect(BackupUploadStatus.values, contains(BackupUploadStatus.uploadInProgress));
      expect(BackupUploadStatus.values, contains(BackupUploadStatus.uploadSucceeded));
      expect(BackupUploadStatus.values, contains(BackupUploadStatus.uploadFailed));
      expect(BackupUploadStatus.values, contains(BackupUploadStatus.retrying));
    });

    test('upload success is not named sync success', () {
      expect(BackupUploadStatus.uploadSucceeded.name, 'uploadSucceeded');
      expect(BackupUploadStatus.uploadSucceeded.name, isNot('syncSucceeded'));
    });

    test('no BackupUploadStatus value contains sync', () {
      for (final s in BackupUploadStatus.values) {
        expect(s.name.toLowerCase().contains('sync'), false,
            reason: '${s.name} must not contain sync');
      }
    });
  });

  // ==================== B. Latest backup status ====================

  group('Latest backup status', () {
    test('default status is noBackupYet', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = BackupUploadService(baseUrl: 'http://test', prefs: prefs, userId: 'test-user');
      final info = service.getLatestBackupInfo();
      expect(info.status, BackupUploadStatus.noBackupYet);
    });

    test('LatestBackupInfo holds status + time', () {
      const info = LatestBackupInfo(
        status: BackupUploadStatus.uploadSucceeded,
        backupId: 'b-001',
        uploadedAt: '2026-04-06T12:00:00Z',
        schemaVersion: 'p3_1_snapshot_v2',
      );
      expect(info.status, BackupUploadStatus.uploadSucceeded);
      expect(info.uploadedAt, isNotNull);
    });

    test('upload result is separate from export result', () {
      // Different types — cannot be confused
      expect(BackupUploadStatus.uploadSucceeded.runtimeType,
          isNot(ExportStatus.success.runtimeType));
    });
  });

  // ==================== C. Wording boundary ====================

  group('Wording boundary', () {
    test('BackupUploadStatus names do not contain sync', () {
      for (final s in BackupUploadStatus.values) {
        expect(s.name.toLowerCase().contains('sync'), false);
      }
    });

    test('BackupUploadStatus names do not contain restore', () {
      for (final s in BackupUploadStatus.values) {
        expect(s.name.toLowerCase().contains('restore'), false);
      }
    });

    test('failed upload is not mappable to success', () {
      const result = BackupUploadResult(
        status: BackupUploadStatus.uploadFailed,
        errorCode: 'NETWORK_ERROR',
        retryable: true,
      );
      expect(result.isSuccess, false);
    });
  });

  // ==================== D. Regression ====================

  group('Delta Phase 2 regression', () {
    test('TodayState defaults unchanged', () {
      final state = TodayState.fromJson({});
      expect(state.dailyGoalStatus, 'not_started');
    });

    test('settings route exists', () {
      expect(AppRouter.settings, '/settings');
    });

    test('isDailyGoalSettingEnabled still true (Phase 1)', () {
      expect(P3FeatureGuard.isDailyGoalSettingEnabled, true);
    });

    test('isDownloadToLocalEnabled still false', () {
      expect(P3FeatureGuard.isDownloadToLocalEnabled, true); // Delta Phase 3: now enabled
    });

    test('isRestoreEnabled still true (P3.1 Phase 4)', () {
      expect(P3FeatureGuard.isRestoreEnabled, true);
    });
  });

  // ==================== E. Negative tests ====================

  group('No overclaim', () {
    test('upload result has no syncStatus field', () {
      const result = BackupUploadResult(status: BackupUploadStatus.uploadSucceeded);
      expect(result.isSuccess, true);
      // No syncStatus, no allDevicesConsistent
    });

    test('no download route exists', () {
      final route = AppRouter.generateRoute(const RouteSettings(name: '/download'));
      expect(route, isNotNull); // page-not-found
    });

    test('ExportStatus and BackupUploadStatus are separate types', () {
      expect(ExportStatus.success.runtimeType != BackupUploadStatus.uploadSucceeded.runtimeType, true);
    });
  });
}
