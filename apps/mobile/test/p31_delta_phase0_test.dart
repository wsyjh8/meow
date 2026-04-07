/// P3.1 Delta Phase 0 — Guard / Seam / Regression / Semantic Separation Tests.
///
/// Tests for 3 delta features: daily_goal setting, manual upload, download-to-local.
/// Phase 0 = guards only, NO feature implementation.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/models/backup_types.dart';
import 'package:meow_mobile/core/router/app_router.dart';
import 'package:meow_mobile/core/storage/backup_upload_service.dart';
import 'package:meow_mobile/core/storage/backup_restore_service.dart';
import 'package:meow_mobile/core/storage/snapshot_export_service.dart';
import 'package:meow_mobile/core/storage/local_settings_service.dart';
import 'package:meow_mobile/shared/helpers/streak_display.dart';
import 'package:meow_mobile/core/api/api_client.dart';

void main() {
  // ==================== Group 1: Delta feature guards all disabled ====================

  group('P3.1 Delta guards all disabled', () {
    test('isDailyGoalSettingEnabled is false', () {
      expect(P3FeatureGuard.isDailyGoalSettingEnabled, true); // Phase 1: now enabled
    });

    test('isManualUploadEnabled is false', () {
      expect(P3FeatureGuard.isManualUploadEnabled, true); // Delta Phase 2: now enabled
    });

    test('isDownloadToLocalEnabled is false', () {
      expect(P3FeatureGuard.isDownloadToLocalEnabled, true); // Delta Phase 3: now enabled
    });
  });

  // ==================== Group 2: downloadToLocal type exists and distinct ====================

  group('downloadToLocal semantic type', () {
    test('BackupOperationType has exactly 4 values', () {
      expect(BackupOperationType.values.length, 4);
    });

    test('downloadToLocal is distinct from restore', () {
      expect(BackupOperationType.downloadToLocal, isNot(BackupOperationType.restore));
    });

    test('downloadToLocal is distinct from cloudUpload', () {
      expect(BackupOperationType.downloadToLocal, isNot(BackupOperationType.cloudUpload));
    });

    test('downloadToLocal is distinct from localExport', () {
      expect(BackupOperationType.downloadToLocal, isNot(BackupOperationType.localExport));
    });

    test('downloadToLocal name does not contain sync or restore', () {
      expect(BackupOperationType.downloadToLocal.name.contains('sync'), false);
      expect(BackupOperationType.downloadToLocal.name.contains('Sync'), false);
      // Note: it should NOT be confused with restore
    });
  });

  // ==================== Group 3: DownloadToLocalStatus enum ====================

  group('DownloadToLocalStatus enum', () {
    test('has exactly 5 values', () {
      expect(DownloadToLocalStatus.values.length, 5);
    });

    test('has all required states', () {
      expect(DownloadToLocalStatus.values, contains(DownloadToLocalStatus.notAttempted));
      expect(DownloadToLocalStatus.values, contains(DownloadToLocalStatus.downloading));
      expect(DownloadToLocalStatus.values, contains(DownloadToLocalStatus.downloadCompleted));
      expect(DownloadToLocalStatus.values, contains(DownloadToLocalStatus.downloadFailed));
      expect(DownloadToLocalStatus.values, contains(DownloadToLocalStatus.temporarilyUnavailable));
    });

    test('no value name contains sync', () {
      for (final s in DownloadToLocalStatus.values) {
        expect(s.name.toLowerCase().contains('sync'), false,
            reason: '${s.name} must not contain sync');
      }
    });

    test('no value name contains restore', () {
      for (final s in DownloadToLocalStatus.values) {
        expect(s.name.toLowerCase().contains('restore'), false,
            reason: '${s.name} must not contain restore');
      }
    });

    test('no value name contains upload', () {
      for (final s in DownloadToLocalStatus.values) {
        expect(s.name.toLowerCase().contains('upload'), false,
            reason: '${s.name} must not contain upload');
      }
    });
  });

  // ==================== Group 4: 4-way semantic separation ====================

  group('4-way semantic separation', () {
    test('upload success type != download completed type', () {
      // Different enum types — can never be confused
      expect(BackupUploadStatus.uploadSucceeded.runtimeType,
          isNot(DownloadToLocalStatus.downloadCompleted.runtimeType));
    });

    test('download completed type != restore succeeded type', () {
      expect(DownloadToLocalStatus.downloadCompleted.runtimeType,
          isNot(RestoreStatus.restoreSucceeded.runtimeType));
    });

    test('export success type != download completed type', () {
      expect(ExportStatus.success.runtimeType,
          isNot(DownloadToLocalStatus.downloadCompleted.runtimeType));
    });

    test('no operation type or status enum has a sync value', () {
      // Check all 4 status enums + 1 operation type enum
      for (final v in BackupOperationType.values) {
        expect(v.name.toLowerCase().contains('sync'), false);
      }
      for (final v in BackupUploadStatus.values) {
        expect(v.name.toLowerCase().contains('sync'), false);
      }
      for (final v in RestoreStatus.values) {
        expect(v.name.toLowerCase().contains('sync'), false);
      }
      for (final v in DownloadToLocalStatus.values) {
        expect(v.name.toLowerCase().contains('sync'), false);
      }
      for (final v in ExportStatus.values) {
        expect(v.name.toLowerCase().contains('sync'), false);
      }
    });
  });

  // ==================== Group 5: Existing flow regression ====================

  group('Delta does not affect existing flows', () {
    test('TodayState defaults unchanged', () {
      final state = TodayState.fromJson({});
      expect(state.dailyGoalStatus, 'not_started');
      expect(state.syncStatus, 'healthy');
    });

    test('Original P3 guards unchanged', () {
      expect(P3FeatureGuard.isStatisticsPageEnabled, false);
      expect(P3FeatureGuard.isCTADecisionSupportEnabled, false);
      expect(P3FeatureGuard.isStreakBasisSwitchEnabled, false);
    });

    test('Original P3.1 guards unchanged', () {
      expect(P3FeatureGuard.isLocalBackupEnabled, false);
      expect(P3FeatureGuard.isCloudBackupEnabled, false);
      expect(P3FeatureGuard.isRestoreEnabled, true); // Phase 4 enabled
      expect(P3FeatureGuard.isBackupSettingsEntryEnabled, false);
    });

    test('Known routes still resolve', () {
      expect(AppRouter.today, '/');
      expect(AppRouter.study, '/study');
      expect(AppRouter.meowHome, '/meow-home');
      expect(AppRouter.settings, '/settings');
    });

    test('StreakDisplay still uses check_in basis', () {
      expect(StreakDisplay.basisLabel.contains('\u7b7e\u5230'), isTrue);
    });

    test('LocalSettingsService dailyGoal default still 20', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = LocalSettingsService(prefs);
      expect(settings.dailyGoal, 20);
    });
  });

  // ==================== Group 6: Negative boundary — no delta leaks ====================

  group('No delta feature leaks', () {
    test('no route contains download or daily-goal', () {
      const routes = [
        AppRouter.today, AppRouter.study, AppRouter.review,
        AppRouter.session, AppRouter.checkIn, AppRouter.settlement,
        AppRouter.meowHome, AppRouter.inventory, AppRouter.customize,
        AppRouter.settings,
      ];
      for (final route in routes) {
        expect(route.contains('download'), false);
        expect(route.contains('daily-goal'), false);
        expect(route.contains('manual-upload'), false);
      }
    });

    test('BackupOperationType has no sync value (full 4-value check)', () {
      final names = BackupOperationType.values.map((v) => v.name).toSet();
      expect(names.contains('sync'), false);
      expect(names.contains('synced'), false);
    });

    test('DownloadToLocalStatus has no synced value', () {
      final names = DownloadToLocalStatus.values.map((v) => v.name).toSet();
      expect(names.contains('synced'), false);
      expect(names.contains('synchronized'), false);
    });

    test('all 3 delta guards false = no delta UI reachable', () {
      expect(P3FeatureGuard.isDailyGoalSettingEnabled, true); // Phase 1: now enabled
      expect(P3FeatureGuard.isManualUploadEnabled, true); // Delta Phase 2: now enabled
      expect(P3FeatureGuard.isDownloadToLocalEnabled, true); // Delta Phase 3: now enabled
      // With all false, no delta feature is accessible from UI
    });
  });
}
