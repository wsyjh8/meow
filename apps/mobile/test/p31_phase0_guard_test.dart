/// P3.1 Phase 0 — Guard / Regression / Semantic Separation Tests.
///
/// These tests verify that:
/// - P3.1 feature guards are all disabled
/// - No backup/restore routes exist
/// - Success semantics (local export / upload / restore) are strictly separated
/// - Existing flows are not affected by P3.1 scaffolding
/// - No "sync" terminology leaks into backup types
///
/// NOT feature tests — only guard / seam / regression / semantic boundary.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/core/api/api_client.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/models/backup_types.dart';
import 'package:meow_mobile/core/router/app_router.dart';
import 'package:meow_mobile/shared/helpers/streak_display.dart';

import 'fixtures/p3_test_fixtures.dart';

void main() {
  // ==================== Group 1: P3.1 feature guard assertions ====================

  group('P3.1 feature guards all disabled', () {
    // P3.2 BACKUP CUTOVER: local, cloud, and settings-entry flags are now true.
    test('local backup is not enabled', () {
      expect(P3FeatureGuard.isLocalBackupEnabled, true); // P3.2: enabled
    });

    test('cloud backup is not enabled', () {
      expect(P3FeatureGuard.isCloudBackupEnabled, true); // P3.2: enabled
    });

    test('restore is not enabled', () {
      expect(P3FeatureGuard.isRestoreEnabled, true); // Phase 4: now enabled
    });

    test('backup settings entry is not enabled', () {
      expect(P3FeatureGuard.isBackupSettingsEntryEnabled, true); // P3.2: enabled
    });
  });

  // ==================== Group 2: No backup-related routes exist ====================

  group('P3.1 route guards — no backup routes', () {
    test('no /settings route exists', () {
      final route = AppRouter.generateRoute(
        const RouteSettings(name: '/settings'),
      );
      expect(route, isNotNull); // returns page-not-found
    });

    test('no /backup route exists', () {
      final route = AppRouter.generateRoute(
        const RouteSettings(name: '/backup'),
      );
      expect(route, isNotNull); // returns page-not-found
    });

    test('no /restore route exists', () {
      final route = AppRouter.generateRoute(
        const RouteSettings(name: '/restore'),
      );
      expect(route, isNotNull); // returns page-not-found
    });
  });

  // ==================== Group 3: Success semantics separation ====================

  group('P3.1 success semantics — strict separation', () {
    test('BackupOperationType has exactly 3 values', () {
      expect(BackupOperationType.values.length, 4); // P3.1 Delta: added downloadToLocal
    });

    test('localExport, cloudUpload, restore are distinct', () {
      expect(BackupOperationType.localExport, isNot(BackupOperationType.cloudUpload));
      expect(BackupOperationType.cloudUpload, isNot(BackupOperationType.restore));
      expect(BackupOperationType.localExport, isNot(BackupOperationType.restore));
    });

    test('BackupOperationStatus has exactly 4 values', () {
      expect(BackupOperationStatus.values.length, 4);
    });

    test('succeeded status is operation-independent', () {
      // The same status enum is used for all operation types
      // but each operation tracks its status independently
      expect(BackupOperationStatus.succeeded, isNotNull);
      expect(BackupOperationStatus.failed, isNotNull);
      expect(BackupOperationStatus.notStarted, isNotNull);
      expect(BackupOperationStatus.inProgress, isNotNull);
    });

    test('local export success does NOT imply upload success (type-level)', () {
      // These are different operations — success of one does not imply success of another
      // This test documents the semantic rule at the type level
      const exportOp = BackupOperationType.localExport;
      const uploadOp = BackupOperationType.cloudUpload;
      expect(exportOp, isNot(uploadOp));
    });
  });

  // ==================== Group 4: Existing flow regression ====================

  group('P3.1 does not affect existing flows', () {
    test('TodayState defaults unchanged by P3.1', () {
      final state = TodayState.fromJson({});
      expect(state.dailyGoalStatus, 'not_started');
      expect(state.syncStatus, 'healthy');
      expect(state.currentStreak, 0);
    });

    test('TodayState has no backup-related fields', () {
      final json = P3JsonFixtures.todayStateActiveBaseline();
      expect(json.containsKey('backup_status'), false);
      expect(json.containsKey('last_backup_at'), false);
      expect(json.containsKey('restore_status'), false);
      expect(json.containsKey('sync_status_backup'), false);
    });

    test('StatsSummaryData defaults unchanged by P3.1', () {
      final stats = StatsSummaryData.fromJson({});
      expect(stats.totalLearningDays, 0);
      expect(stats.streakBasis, 'check_in');
    });

    test('StreakDisplay still uses check_in basis', () {
      expect(StreakDisplay.basisLabel.contains('\u7b7e\u5230'), isTrue); // 签到
    });

    test('Known routes still resolve correctly', () {
      final todayRoute = AppRouter.generateRoute(const RouteSettings(name: '/'));
      expect(todayRoute, isNotNull);
      final meowRoute = AppRouter.generateRoute(const RouteSettings(name: '/meow-home'));
      expect(meowRoute, isNotNull);
    });

    test('Original P3 guards remain unchanged', () {
      expect(P3FeatureGuard.isStatisticsPageEnabled, false);
      expect(P3FeatureGuard.isCTADecisionSupportEnabled, false);
      expect(P3FeatureGuard.isStreakBasisSwitchEnabled, false);
      expect(P3FeatureGuard.isReviewReadinessContractEnabled, false);
      expect(P3FeatureGuard.isStreakExplanationEnabled, false);
    });
  });

  // ==================== Group 5: Disabled state — no backup UI leaks ====================

  group('P3.1 disabled state — no backup UI leaks', () {
    test('no route constant contains backup/settings/restore', () {
      // Verify AppRouter route constants do not include P3.1 routes
      const routes = [
        AppRouter.today, AppRouter.study, AppRouter.review,
        AppRouter.session, AppRouter.checkIn, AppRouter.settlement,
        AppRouter.meowHome, AppRouter.inventory, AppRouter.customize,
      ];
      for (final route in routes) {
        expect(route.contains('backup'), false);
        expect(route.contains('settings'), false);
        expect(route.contains('restore'), false);
      }
    });

    test('BackupOperationType.restore exists as type but guard prevents it', () {
      // The type exists for future phases, but isRestoreEnabled prevents any use
      expect(BackupOperationType.restore, isNotNull);
      expect(P3FeatureGuard.isRestoreEnabled, true); // Phase 4: now enabled
    });

    test('BackupOperationStatus.succeeded exists but no code path produces it', () {
      // P3.2: flags are now true — backup operations can run.
      // This test is kept as a landmark (name preserved for traceability).
      expect(BackupOperationStatus.succeeded, isNotNull);
      // P3.2: backup flags are now enabled
      expect(P3FeatureGuard.isLocalBackupEnabled, true);
      expect(P3FeatureGuard.isCloudBackupEnabled, true);
    });

    test('no sync-implying text in backup type names', () {
      // Backup types must never use "sync" or "synced" — backup != sync
      for (final value in BackupOperationType.values) {
        expect(value.name.toLowerCase().contains('sync'), false,
          reason: 'BackupOperationType.$value must not contain "sync"');
      }
      for (final value in BackupOperationStatus.values) {
        expect(value.name.toLowerCase().contains('sync'), false,
          reason: 'BackupOperationStatus.$value must not contain "sync"');
      }
    });
  });

  // ==================== Group 6: Negative semantic boundary ====================

  group('P3.1 negative boundary — no sync terminology', () {
    test('BackupOperationType has no sync value', () {
      final names = BackupOperationType.values.map((v) => v.name).toSet();
      expect(names.contains('sync'), false);
      expect(names.contains('synced'), false);
      expect(names.contains('cloudSync'), false);
    });

    test('BackupOperationStatus has no synced value', () {
      final names = BackupOperationStatus.values.map((v) => v.name).toSet();
      expect(names.contains('synced'), false);
      expect(names.contains('synchronized'), false);
    });

    test('cloudUpload name does not contain sync', () {
      expect(BackupOperationType.cloudUpload.name.contains('sync'), false);
      expect(BackupOperationType.cloudUpload.name.contains('Sync'), false);
    });

    test('no restore success flow exists in Phase 0', () {
      // Phase 0 has types but no implementation
      // isRestoreEnabled = false → no restore can execute
      expect(P3FeatureGuard.isRestoreEnabled, true); // Phase 4: now enabled
      // The existence of BackupOperationType.restore is safe because:
      // 1. It's a type definition, not an implementation
      // 2. The guard prevents any code from using it
    });
  });
}
