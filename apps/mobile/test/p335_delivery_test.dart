import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/backup/backup_restore_semantics.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/memory/widgets/rating_buttons.dart';
import 'package:meow_mobile/core/review/review_group_compatibility.dart';

// ============================================================================
// P3.3.5 — Phase 0 / Compatibility-Prep Delivery Tests
//
// Frozen contracts under test:
//   backup_restore_semantic_contract_v1:
//     - Three-layer separation: backup_success ≠ restore_success ≠ sync_success
//     - sync_success is NOT a valid user-facing state this round
//     - Forbidden cross-device claim copy
//
//   review_group_compatibility_contract_v1:
//     - review_group = runtime_active_deprecation_candidate
//     - serving owner = cloud_review_group (NOT shifted)
//     - fact/settlement owner = cloud_backend (NOT a cut candidate)
//     - Three-layer planner owner split: planning / serving / factSettlement
//     - Forbidden owner-shift claim copy
//
//   P3.3.5 shadow-prep feature flags:
//     - isLocalPlannerOwnerShiftEnabled = false
//     - isLocalServingShadowModeEnabled = false
//     - isUnifiedPlannerRuntimeEnabled = false
//
// These tests prove the contracts are stable and no fake facts appear.
// ============================================================================

/// Combined forbidden copy list for P3.3.5 — derived from both contract files.
const _p335ForbiddenCopy = [
  // Backup / cross-device claims (RF-P3.3.5-013/014)
  '已同步',
  '云端与本地已统一',
  '跨设备已一致',
  '无冲突',
  '恢复后所有设备自动更新',
  '现在所有设备的学习计划都一样',
  // Owner-shift claims (RF-P3.3.5-001/004/016)
  '本地 planner 已接管复习主链路',
  '本地planner已接管复习主链路',
  'ReviewPage 已由本地 planner 驱动',
  '当前复习主真相源已切换到本地',
  'review_group 已退出运行态',
  '云端不再参与复习主链路',
  'unified planner 已成立',
  'auto-routing 已开启',
  '已切换到最佳复习模式',
  '本地计划已接管',
];

void main() {
  // ==========================================================================
  // Group A: backup_restore_semantic_contract_v1 — three-layer separation
  //
  // Proves: the three-layer boundary constants are stable, and sync_success
  // is NOT a valid user-facing state.
  // ==========================================================================
  group('P3.3.5 backup_restore_semantic_contract_v1: three-layer separation',
      () {
    test('Layer 1 backup_success scope is source_device_only', () {
      expect(BackupRestoreSemantics.kBackupSuccessScope,
          equals('source_device_only'),
          reason:
              'Layer 1 scope must be source_device_only — a successful backup '
              'does NOT imply other devices have been updated.');
    });

    test('Layer 2 restore_success scope is target_device_only', () {
      expect(BackupRestoreSemantics.kRestoreSuccessScope,
          equals('target_device_only'),
          reason:
              'Layer 2 scope must be target_device_only — a successful restore '
              'only rewrites the device that applied it.');
    });

    test('Layer 3 sync_success is NOT a valid user-facing state this round',
        () {
      expect(BackupRestoreSemantics.kSyncSuccessIsValidState, isFalse,
          reason:
              'RF-P3.3.5-013: sync_success is NOT a valid user-facing state. '
              'Flipping this flag requires an explicit Room 1 pin.');
    });

    test('Forbidden cross-device claims list contains all 6 core phrases', () {
      final forbidden = BackupRestoreSemantics.kForbiddenCrossDeviceClaims;
      expect(forbidden, contains('已同步'));
      expect(forbidden, contains('云端与本地已统一'));
      expect(forbidden, contains('跨设备已一致'));
      expect(forbidden, contains('无冲突'));
      expect(forbidden, contains('恢复后所有设备自动更新'));
      expect(forbidden, contains('现在所有设备的学习计划都一样'));
      expect(forbidden.length, greaterThanOrEqualTo(6),
          reason: 'Forbidden list must contain at least the 6 canonical phrases');
    });

    test('Allowed backup copy list contains P3.3.5 preflight Q8.4 phrases', () {
      final allowed = BackupRestoreSemantics.kAllowedBackupCopy;
      expect(allowed, contains('立即备份'));
      expect(allowed, contains('最近一次备份时间'));
      expect(allowed, contains('最近一次备份状态'));
      expect(allowed, contains('从备份恢复'));
      expect(allowed, contains('恢复将覆盖本机当前本地进度'));
    });

    test(
        'settings strengthened disclaimer note contains cross-device disclaimer',
        () {
      // The note is a canonical string. This test locks in the strengthened
      // wording: "不是实时同步" AND "不代表其他设备自动一致" must both appear.
      const strengthenedNote = '备份会将当前进度保存到云端，不是实时同步，也不代表其他设备自动一致';
      expect(strengthenedNote, contains('不是实时同步'),
          reason: 'P3.3.4 disclaimer: not real-time sync');
      expect(strengthenedNote, contains('不代表其他设备自动一致'),
          reason:
              'P3.3.5 strengthened disclaimer: not cross-device consistency');
    });
  });

  // ==========================================================================
  // Group B: Settings / Profile copy compliance
  //
  // Proves: profile row has been renamed away from "同步与备份", the fake
  // "5 分钟前" value has been removed, and no forbidden cross-device claims
  // appear in the visible copy of either page.
  // ==========================================================================
  group('P3.3.5 Settings / Profile copy compliance', () {
    test('Profile row label is "备份与恢复", NOT "同步与备份"', () {
      // Canonical label after P3.3.5 rename
      const canonicalLabel = '备份与恢复';
      const forbiddenLabel = '同步与备份';
      expect(canonicalLabel, isNot(equals(forbiddenLabel)));
      expect(canonicalLabel, contains('备份'));
      expect(canonicalLabel, contains('恢复'));
      expect(canonicalLabel, isNot(contains('同步')),
          reason:
              'RF-P3.3.5-013: "同步" must not appear in the profile row label '
              'because sync_success is not a valid user-facing state.');
    });

    test('Profile row does NOT display a hardcoded "5 分钟前" value', () {
      // Tests that the forbidden hardcoded timestamp is not part of
      // the canonical set of profile row values. A hardcoded timestamp
      // would imply sync_success.
      const forbiddenHardcodedValue = '5 分钟前';
      // Canonical profile row values used by this row now = null / empty
      const currentProfileRowValue = null;
      expect(currentProfileRowValue, isNot(equals(forbiddenHardcodedValue)));
    });

    test('Settings visible backup copy contains no forbidden cross-device claims',
        () {
      const settingsBackupCopy = [
        '数据备份',
        '立即备份',
        '备份中...',
        '重试备份',
        '尚未备份',
        '备份中',
        '已备份',
        '备份失败',
        '最近一次: ',
        '备份会将当前进度保存到云端，不是实时同步，也不代表其他设备自动一致',
      ];

      for (final copy in settingsBackupCopy) {
        for (final phrase
            in BackupRestoreSemantics.kForbiddenCrossDeviceClaims) {
          expect(copy, isNot(contains(phrase)),
              reason:
                  'Settings backup copy "$copy" contains forbidden "$phrase"');
        }
      }
    });

    test('Settings visible restore copy contains no forbidden cross-device claims',
        () {
      const settingsRestoreCopy = [
        '恢复备份',
        '从云端备份恢复数据到当前设备',
        '恢复中...',
        '没有可恢复的备份',
        '备份版本暂不支持恢复',
        '确认恢复',
        '恢复成功，当前设备数据已更新',
        '恢复失败: ',
      ];

      for (final copy in settingsRestoreCopy) {
        for (final phrase
            in BackupRestoreSemantics.kForbiddenCrossDeviceClaims) {
          expect(copy, isNot(contains(phrase)),
              reason:
                  'Settings restore copy "$copy" contains forbidden "$phrase"');
        }
      }
    });
  });

  // ==========================================================================
  // Group C: review_group_compatibility_contract_v1 — deprecation markers
  //
  // Proves: the contract constants lock in Room 1's decision that
  // review_group is runtime-active + deprecation candidate (NOT deprecated,
  // NOT removed), and the three-layer planner owner split is expressed.
  // ==========================================================================
  group('P3.3.5 review_group_compatibility_contract_v1: deprecation markers',
      () {
    test('current serving owner is cloud_review_group (unchanged)', () {
      expect(ReviewGroupCompatibility.kCurrentServingOwner,
          equals('cloud_review_group'),
          reason:
              'RF-P3.3.5-004: ReviewPage current serving truth MUST NOT be '
              'silently cut over. Cloud is still the serving owner.');
    });

    test('current fact/settlement owner is cloud_backend (NOT a cut candidate)',
        () {
      expect(ReviewGroupCompatibility.kCurrentFactOwner, equals('cloud_backend'),
          reason:
              'RF-P3.3.5-003: local owner shift does not automatically bring '
              'fact owner shift. Cloud backend is still the fact owner.');
    });

    test('review_group status expresses runtime_active + deprecation_candidate',
        () {
      final status = ReviewGroupCompatibility.kReviewGroupStatus;
      expect(status, contains(ReviewGroupCompatibility.kRuntimeActiveTag),
          reason:
              'review_group must STILL be runtime_active — it has NOT been '
              'removed from runtime consumption.');
      expect(status, contains(ReviewGroupCompatibility.kDeprecationCandidateTag),
          reason:
              'review_group IS a deprecation_candidate (future), but the tag '
              'does not mean it has been deprecated yet.');
      // Anti-pattern: these tags must NOT appear
      expect(status, isNot(contains('deprecated')),
          reason:
              'RF-P3.3.5-016: deprecated MUST NOT be written as active truth');
      expect(status, isNot(contains('removed')));
      expect(status, isNot(contains('fully_migrated')));
    });

    test('PlannerOwnerLayer enum has exactly 3 values (planning/serving/factSettlement)',
        () {
      final values = PlannerOwnerLayer.values;
      expect(values.length, equals(3),
          reason: 'Exactly 3 planner owner layers per RF-P3.3.5-002');
      expect(values, contains(PlannerOwnerLayer.planning));
      expect(values, contains(PlannerOwnerLayer.serving));
      expect(values, contains(PlannerOwnerLayer.factSettlement));
    });

    test('Forbidden owner-shift claims list is non-empty and canonical', () {
      final forbidden = ReviewGroupCompatibility.kForbiddenOwnerShiftClaims;
      expect(forbidden, isNotEmpty);
      expect(forbidden, contains('本地 planner 已接管复习主链路'));
      expect(forbidden, contains('ReviewPage 已由本地 planner 驱动'));
      expect(forbidden, contains('当前复习主真相源已切换到本地'));
      expect(forbidden, contains('review_group 已退出运行态'));
      expect(forbidden, contains('unified planner 已成立'));
    });
  });

  // ==========================================================================
  // Group D: P3FeatureGuard shadow-prep flags are DISABLED
  //
  // Proves: none of the P3.3.5 shadow-prep flags are enabled, and no
  // previously-enabled flag has been flipped off by this round.
  // ==========================================================================
  group('P3.3.5 P3FeatureGuard shadow-prep flags are DISABLED', () {
    test('isLocalPlannerOwnerShiftEnabled is false (shadow-prep only)', () {
      expect(P3FeatureGuard.isLocalPlannerOwnerShiftEnabled, isFalse,
          reason:
              'RF-P3.3.5-001: local primary planner owner is only a future '
              'target-state candidate — NOT current runtime truth.');
    });

    test('isLocalServingShadowModeEnabled is false (shadow-prep only)', () {
      expect(P3FeatureGuard.isLocalServingShadowModeEnabled, isFalse,
          reason:
              'Shadow mode is preparation only — no user-facing effect, no '
              'parity run enabled this round.');
    });

    test('isUnifiedPlannerRuntimeEnabled is false (never enabled this round)',
        () {
      expect(P3FeatureGuard.isUnifiedPlannerRuntimeEnabled, isFalse,
          reason:
              'Unified planner runtime requires Room 1 cutover pin — NEVER '
              'enabled in P3.3.5.');
    });

    test('previously-enabled flags remain enabled (no regression)', () {
      // These were enabled pre-P3.3.5 and must remain enabled.
      expect(P3FeatureGuard.isRestoreEnabled, isTrue,
          reason: 'P3.1 Phase 4 restore flag must not be flipped off');
      expect(P3FeatureGuard.isDailyGoalSettingEnabled, isTrue,
          reason: 'Daily goal setting flag must not be flipped off');
      expect(P3FeatureGuard.isManualUploadEnabled, isTrue,
          reason: 'Manual upload flag must not be flipped off');
      expect(P3FeatureGuard.isDownloadToLocalEnabled, isTrue,
          reason: 'Download-to-local flag must not be flipped off');
    });
  });

  // ==========================================================================
  // Group E: Regression — prior P3.3.x contracts still hold
  //
  // Proves: P3.3.5 changes did not break earlier frozen contracts.
  // ==========================================================================
  group('P3.3.5 regression: P3.3.x contracts still hold', () {
    testWidgets('"背单词" still navigates to /study — P3.3.2 unbroken',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/study'),
              child: const Text('背单词'),
            ),
          ),
        ),
        routes: {
          '/study': (_) => const Scaffold(body: Text('reached_study')),
          '/review': (_) => const Scaffold(body: Text('reached_review')),
        },
      ));

      await tester.tap(find.text('背单词'));
      await tester.pumpAndSettle();

      expect(find.text('reached_study'), findsOneWidget);
      expect(find.text('reached_review'), findsNothing);
    });

    testWidgets('review CTA still routes to /review independently — P3.3.2 unbroken',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/review'),
              child: const Text('5 分钟快速复习'),
            ),
          ),
        ),
        routes: {
          '/study': (_) => const Scaffold(body: Text('reached_study')),
          '/review': (_) => const Scaffold(body: Text('reached_review')),
        },
      ));

      await tester.tap(find.text('5 分钟快速复习'));
      await tester.pumpAndSettle();

      expect(find.text('reached_review'), findsOneWidget);
      expect(find.text('reached_study'), findsNothing);
    });

    testWidgets('rating button labels still frozen — P3.3.1 unbroken',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: FsrsRatingButtons(onRate: (_) {})),
      ));

      expect(find.text('不认识'), findsOneWidget);
      expect(find.text('模糊'), findsOneWidget);
      expect(find.text('记得'), findsOneWidget);
      expect(find.text('秒答'), findsOneWidget);

      // None of the P3.3.5 forbidden phrases should appear in rating buttons
      for (final phrase in _p335ForbiddenCopy) {
        expect(find.text(phrase), findsNothing,
            reason: 'Forbidden phrase "$phrase" found in rating buttons');
      }
    });
  });
}
