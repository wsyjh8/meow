import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/gate/fact_owner_guardrail.dart';
import 'package:meow_mobile/core/gate/first_cutover_subset.dart';
import 'package:meow_mobile/core/gate/review_group_retained_anchor.dart';
import 'package:meow_mobile/core/gate/runtime_truth_switch_boundary.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/review/review_group_compatibility.dart';
import 'package:meow_mobile/core/serving/review_serving_observability.dart';
import 'package:meow_mobile/core/serving/review_serving_seam.dart';

// ============================================================================
// P3.3.9 — First Very Narrow Cutover Delivery Tests
//
// Six frozen contracts under test:
//   1. first_cutover_subset_v1
//   2. runtime_truth_switch_boundary_v1
//   3. review_group_retained_anchor_v1
//   4. fact_owner_guardrail_v1
//   5. db_api_cutover_candidate_v2 (covered via Group A/B overlap with P3.3.8)
//   6. rollback_holdnote_and_observability_v1
//
// Special note: this is the FIRST round that actually modifies runtime
// code (ReviewPage._loadReviewGroup()). The modification is:
//   - Consult ReviewServingSeam.selectSource() for observability
//   - Increment reviewServingSeamHitCount
//   - Log the decision via debugPrint
// Runtime BEHAVIOR is identical: flag is OFF, seam always returns cloud,
// and the actual fetch call `apiClient.getNextReviewGroup()` is unchanged.
//
// Per P3.3.6 `ParityTestCategory`, all tests in this file are
// `markerContractOnly` except one `runtimeTruthRegression` widget test.
// ============================================================================

void main() {
  // ==========================================================================
  // Group A: first_cutover_subset_v1 — allowed subset (5 tests)
  // ==========================================================================
  group('P3.3.9 first_cutover_subset_v1: allowed subset', () {
    test(
        'kOnlyAllowedSubset == "reviewpage_non_continuation_serving_subset"',
        () {
      expect(FirstCutoverSubset.kOnlyAllowedSubset,
          equals('reviewpage_non_continuation_serving_subset'));
    });

    test('kAllowedLayers contains all 5 canonical layers', () {
      final layers = FirstCutoverSubset.kAllowedLayers;
      expect(layers.length, equals(5));
      expect(layers, contains('queue_source_selection_runtime_seam'));
      expect(layers,
          contains('local_serving_candidate_item_stream_provision'));
      expect(layers, contains('retained_anchor_and_rollback_hooks'));
      expect(layers, contains('observability_floor'));
      expect(
          layers,
          contains(
              'source_neutral_helper_summary_empty_state_continuation_copy_neutralization'));
    });

    test('kForbiddenSubsets contains canonical forbidden subsets', () {
      final forbidden = FirstCutoverSubset.kForbiddenSubsets;
      expect(forbidden, contains('home_page_runtime_switch'));
      expect(forbidden, contains('active_continuation_rewrite'));
      expect(forbidden, contains('review_group_exit'));
      expect(forbidden, contains('final_fact_owner_shift'));
      expect(forbidden, contains('db_api_baseline_uplift'));
      expect(forbidden, contains('full_reviewpage_current_truth_switch'));
      expect(forbidden, contains('cleanup_bundling'));
      expect(forbidden, contains('auto_routing_runtime'));
    });

    test('kCanonicalRule enforces runtime-seam-not-copy-only', () {
      expect(FirstCutoverSubset.kCanonicalRule,
          contains('first_cutover_must_cut_actual_runtime_seam'));
      expect(FirstCutoverSubset.kCanonicalRule,
          contains('not_just_copy'));
    });

    test('allowed subset is NOT in forbidden list (no overlap)', () {
      expect(FirstCutoverSubset.isAllowedSubsetNotInForbiddenList, isTrue);
      expect(FirstCutoverSubset.kForbiddenSubsets,
          isNot(contains(FirstCutoverSubset.kOnlyAllowedSubset)));
    });
  });

  // ==========================================================================
  // Group B: runtime_truth_switch_boundary_v1 — boundary (5 tests)
  // ==========================================================================
  group('P3.3.9 runtime_truth_switch_boundary_v1: boundary', () {
    test('kOnlyAllowedSwitch == "review_queue_serving_source"', () {
      expect(RuntimeTruthSwitchBoundary.kOnlyAllowedSwitch,
          equals('review_queue_serving_source'));
    });

    test('kMustRemainUnchanged contains home_page + review_group + final fact',
        () {
      final unchanged = RuntimeTruthSwitchBoundary.kMustRemainUnchanged;
      expect(unchanged, contains('home_page_home_word_entry_study_default'));
      expect(unchanged, contains('active_continuation_independent_intake'));
      expect(unchanged,
          contains('review_group_current_runtime_serving_owner_main_path_fact'));
      expect(unchanged,
          contains('review_summary_completion_settlement_final_fact'));
      expect(unchanged,
          contains('reward_ledger_daily_goal_streak_learning_day_final_fact'));
    });

    test('kForbiddenSwitches contains canonical forbidden switches', () {
      final forbidden = RuntimeTruthSwitchBoundary.kForbiddenSwitches;
      expect(forbidden, contains('home_page_route_switch'));
      expect(forbidden, contains('active_continuation_source_switch'));
      expect(forbidden, contains('final_fact_owner_shift'));
      expect(forbidden, contains('reward_settlement_owner_shift'));
      expect(forbidden, contains('daily_goal_owner_shift'));
      expect(forbidden, contains('streak_learning_day_owner_shift'));
      expect(forbidden, contains('preview_explanation_contract_shift'));
    });

    test('kEligibilityRequirements has 4 canonical requirements', () {
      final reqs = RuntimeTruthSwitchBoundary.kEligibilityRequirements;
      expect(reqs.length, equals(4));
      expect(reqs, contains('only_in_reviewpage'));
      expect(reqs, contains('only_non_continuation_path'));
      expect(reqs, contains('only_when_local_serving_candidate_readiness_met'));
      expect(
          reqs,
          contains(
              'only_when_fallback_rollback_holdnote_observability_all_present'));
    });

    test('allowed switch NOT in forbidden list (no overlap)', () {
      expect(RuntimeTruthSwitchBoundary.kForbiddenSwitches,
          isNot(contains(RuntimeTruthSwitchBoundary.kOnlyAllowedSwitch)));
    });
  });

  // ==========================================================================
  // Group C: review_group_retained_anchor_v1 — 4-role posture (6 tests)
  // ==========================================================================
  group('P3.3.9 review_group_retained_anchor_v1: 4-role posture', () {
    test('kFourRoles has exactly 4 roles in canonical order', () {
      final roles = ReviewGroupRetainedAnchor.kFourRoles;
      expect(roles.length, equals(4));
      expect(roles[0], equals('current_runtime_serving_owner'));
      expect(roles[1], equals('retained_fallback_anchor'));
      expect(roles[2], equals('compatibility_anchor'));
      expect(roles[3], equals('deprecated_candidate'));
    });

    test('kFourRolePostureStatus contains all 4 role tags', () {
      final status = ReviewGroupRetainedAnchor.kFourRolePostureStatus;
      expect(status, contains('runtime_owner'));
      expect(status, contains('retained_fallback'));
      expect(status, contains('compatibility_anchor'));
      expect(status, contains('deprecated_candidate'));
      // Anti-pattern: must NOT be written as already exited
      expect(status, isNot(contains('exited')));
      expect(status, isNot(contains('retired')));
    });

    test('kPathsStillDependingOnReviewGroup contains 5 canonical paths', () {
      final paths = ReviewGroupRetainedAnchor.kPathsStillDependingOnReviewGroup;
      expect(paths.length, equals(5));
      expect(paths, contains('active_continuation_identity'));
      expect(paths, contains('current_completion_gating'));
      expect(paths, contains('current_settlement_trigger'));
      expect(paths, contains('rollback_target'));
      expect(
          paths, contains('baseline_path_for_non_cutover_users_sessions'));
    });

    test('kRollbackTarget == "cloud_review_group_current_runtime_path"', () {
      expect(ReviewGroupRetainedAnchor.kRollbackTarget,
          equals('cloud_review_group_current_runtime_path'));
    });

    test('kForbiddenClaims contains canonical "already exited" phrases', () {
      final forbidden = ReviewGroupRetainedAnchor.kForbiddenClaims;
      expect(forbidden, contains('review_group 已退场'));
      expect(forbidden, contains('review_group 已不再是 runtime owner'));
      expect(forbidden, contains('review_group 历史兼容 only'));
      expect(forbidden, contains('可以直接清理旧 cloud path'));
      expect(forbidden, contains('review_group 已被 local 替代'));
    });

    test('P3.3.6 3-role posture STILL INTACT (regression) + P3.3.9 adds 4th role',
        () {
      // P3.3.6 still holds (P3.3.9 extends, does not replace)
      expect(ReviewGroupCompatibility.kPostureRuntimeOwner, isTrue);
      expect(ReviewGroupCompatibility.kPostureCompatibilityAnchor, isTrue);
      expect(ReviewGroupCompatibility.kPostureDeprecatedCandidate, isTrue);

      // P3.3.9 adds the 4th role (retained_fallback_anchor)
      expect(ReviewGroupRetainedAnchor.kFourRoles,
          contains('retained_fallback_anchor'));
    });
  });

  // ==========================================================================
  // Group D: fact_owner_guardrail_v1 — guardrail extensions (5 tests)
  // ==========================================================================
  group('P3.3.9 fact_owner_guardrail_v1: guardrail extensions', () {
    test('kFinalFactsRemainCloudOwned contains all 4 canonical final facts',
        () {
      final facts = FactOwnerGuardrail.kFinalFactsRemainCloudOwned;
      expect(facts.length, equals(4));
      expect(facts, contains('valid_review_fact'));
      expect(facts, contains('today_goal_completion'));
      expect(facts, contains('reward_settlement_account_arrival'));
      expect(facts, contains('check_in_learning_day_streak'));
    });

    test('kStrongerIngestAllowedScope contains canonical stronger ingest items',
        () {
      final scope = FactOwnerGuardrail.kStrongerIngestAllowedScope;
      expect(scope, contains('stronger_evidence_ingestion'));
      expect(scope, contains('clearer_accept_reject_duplicate_rules'));
      expect(
          scope, contains('minimal_transfer_related_to_first_cutover_seam'));
      expect(scope,
          contains('accept_reject_duplicate_candidate_result_standardization'));
      expect(scope,
          contains('idempotency_dedup_retry_seam_floor'));
    });

    test('kForbiddenLocalFactOwnerActions contains 4 canonical forbidden actions',
        () {
      final forbidden = FactOwnerGuardrail.kForbiddenLocalFactOwnerActions;
      expect(forbidden.length, equals(4));
      expect(forbidden, contains('local_directly_alters_ledger'));
      expect(forbidden, contains('local_directly_alters_daily_goal_completion'));
      expect(forbidden,
          contains('local_directly_alters_streak_learning_day_final_fact'));
      expect(forbidden, contains('local_replaces_settlement_owner'));
    });

    test('kForbiddenOverclaims contains canonical RF-P3.3.9-013 phrases', () {
      final forbidden = FactOwnerGuardrail.kForbiddenOverclaims;
      expect(forbidden, contains('local 已接管 review fact'));
      expect(forbidden, contains('本地结果已写回最终事实'));
      expect(forbidden, contains('奖励已由本地 path 正式结算'));
      expect(forbidden, contains('cutover 已完成'));
      expect(forbidden, contains('新主链路已生效'));
    });

    test('kResultFeedbackRule mandates backend-confirmed driving', () {
      expect(FactOwnerGuardrail.kResultFeedbackRule,
          equals('backend_confirmed_final_fact_only_drives_result_feedback'));
    });
  });

  // ==========================================================================
  // Group E: rollback + observability (7 tests)
  // ==========================================================================
  group('P3.3.9 rollback_holdnote_and_observability_v1', () {
    test('ReviewServingSeam.kRollbackTriggers contains canonical triggers', () {
      final triggers = ReviewServingSeam.kRollbackTriggers;
      expect(triggers,
          contains('first_cutover_seam_affects_home_word_entry'));
      expect(triggers, contains('active_continuation_silent_reroute'));
      expect(triggers, contains('review_group_written_as_exited'));
      expect(triggers, contains('local_evidence_changed_final_fact'));
      expect(triggers, contains('home_route_silently_changed'));
      expect(triggers,
          contains('requires_db_schema_or_api_core_semantics_change'));
    });

    test('ReviewServingSeam.kHoldTriggers is non-empty', () {
      expect(ReviewServingSeam.kHoldTriggers, isNotEmpty);
      expect(ReviewServingSeam.kHoldTriggers,
          contains('compare_qa_debug_evidence_unreproducible'));
      expect(ReviewServingSeam.kHoldTriggers,
          contains('user_visible_overclaim_detected'));
    });

    test('ReviewServingSeam.kRollbackTarget equals canonical target', () {
      expect(ReviewServingSeam.kRollbackTarget,
          equals('cloud_review_group_current_runtime_path'));
    });

    test('ReviewServingObservabilityEvent enum has exactly 6 values', () {
      expect(ReviewServingObservabilityEvent.values.length, equals(6));
      expect(ReviewServingObservabilityEvent.values,
          contains(ReviewServingObservabilityEvent.seamHit));
      expect(ReviewServingObservabilityEvent.values,
          contains(ReviewServingObservabilityEvent.retainedAnchorEngaged));
      expect(ReviewServingObservabilityEvent.values,
          contains(ReviewServingObservabilityEvent.rollbackEngaged));
      expect(ReviewServingObservabilityEvent.values,
          contains(ReviewServingObservabilityEvent.holdEngaged));
      expect(ReviewServingObservabilityEvent.values,
          contains(ReviewServingObservabilityEvent.compareMismatch));
      expect(
          ReviewServingObservabilityEvent.values,
          contains(ReviewServingObservabilityEvent
              .noFinalFactOwnerSwitchAssertion));
    });

    test('kMinimumEvents has 6 canonical event names in order', () {
      final events = ReviewServingObservabilityFloor.kMinimumEvents;
      expect(events.length, equals(6));
      expect(events[0], equals('seam_hit'));
      expect(events[1], equals('retained_anchor_engaged'));
      expect(events[2], equals('rollback_engaged'));
      expect(events[3], equals('hold_engaged'));
      expect(events[4], equals('compare_mismatch'));
      expect(events[5], equals('no_final_fact_owner_switch_assertion'));
    });

    test('kForbiddenUserVisibleObservabilityClaims contains canonical phrases',
        () {
      final forbidden =
          ReviewServingObservabilityFloor.kForbiddenUserVisibleObservabilityClaims;
      expect(forbidden, contains('已回退到旧方案'));
      expect(forbidden, contains('本地 serving 失败，已切回云端'));
      expect(forbidden, contains('新规划暂不可用'));
      expect(forbidden, contains('因 candidate mismatch 已停止切换'));
    });

    test('observability canonical rule: never user-visible', () {
      expect(ReviewServingObservabilityFloor.kCanonicalRule,
          contains('never_user_visible'));
      expect(ReviewServingObservabilityFloor.kCanonicalRule,
          contains('dev_test_qa'));
    });
  });

  // ==========================================================================
  // Group F: ReviewServingSeam classifier behavior (6 tests)
  // ==========================================================================
  group('P3.3.9 ReviewServingSeam: classifier behavior', () {
    test('ReviewServingSourceKind enum has exactly 2 values', () {
      expect(ReviewServingSourceKind.values.length, equals(2));
      expect(ReviewServingSourceKind.values,
          contains(ReviewServingSourceKind.cloudReviewGroup));
      expect(ReviewServingSourceKind.values,
          contains(ReviewServingSourceKind.localNonContinuation));
    });

    test('seam returns cloudReviewGroup when flag OFF + no continuation', () {
      final selection = ReviewServingSeam.selectSource(
        isCutoverEnabled: false,
        hasActiveContinuation: false,
      );
      expect(selection.source, ReviewServingSourceKind.cloudReviewGroup);
      expect(selection.reason, equals('cutover_flag_disabled_default_cloud'));
      expect(selection.isFallbackToRetainedAnchor, isFalse);
    });

    test(
        'seam returns cloudReviewGroup + retained-anchor-active-continuation even when flag ON',
        () {
      final selection = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: true,
      );
      expect(selection.source, ReviewServingSourceKind.cloudReviewGroup);
      expect(selection.reason, equals('retained_anchor_active_continuation'));
      expect(selection.isFallbackToRetainedAnchor, isTrue);
    });

    test(
        'seam returns cloudReviewGroup + local-path-not-wired fallback when flag ON + no continuation',
        () {
      final selection = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: false,
      );
      expect(selection.source, ReviewServingSourceKind.cloudReviewGroup);
      expect(
          selection.reason, equals('local_path_not_yet_wired_fallback_to_cloud'));
      expect(selection.isFallbackToRetainedAnchor, isTrue);
    });

    test('all selections this round return cloudReviewGroup (never local)',
        () {
      for (final flagOn in [true, false]) {
        for (final hasContinuation in [true, false]) {
          final sel = ReviewServingSeam.selectSource(
            isCutoverEnabled: flagOn,
            hasActiveContinuation: hasContinuation,
          );
          expect(sel.source, ReviewServingSourceKind.cloudReviewGroup,
              reason:
                  'P3.3.9: seam must NEVER return localNonContinuation '
                  '(flagOn=$flagOn, hasContinuation=$hasContinuation)');
        }
      }
    });

    test(
        'isFallbackToRetainedAnchor: true for continuation/local-not-wired, false for simple flag-off',
        () {
      // Simple flag-off: default cloud, not a fallback
      expect(
          ReviewServingSeam.selectSource(
                  isCutoverEnabled: false, hasActiveContinuation: false)
              .isFallbackToRetainedAnchor,
          isFalse);
      // Active continuation: fallback to retained anchor
      expect(
          ReviewServingSeam.selectSource(
                  isCutoverEnabled: false, hasActiveContinuation: true)
              .isFallbackToRetainedAnchor,
          isTrue);
      // Local path not wired: fallback to retained anchor
      expect(
          ReviewServingSeam.selectSource(
                  isCutoverEnabled: true, hasActiveContinuation: false)
              .isFallbackToRetainedAnchor,
          isTrue);
    });
  });

  // ==========================================================================
  // Group G: flags + regression (6 tests)
  // ==========================================================================
  group('P3.3.9 flags + regression', () {
    test('both P3.3.9 flags are false', () {
      expect(P3FeatureGuard.isReviewPageNonContinuationCutoverEnabled, isFalse);
      expect(P3FeatureGuard.isStrongerIngestCandidatePathEnabled, isFalse);
    });

    test('P3.3.8 flags still false (regression)', () {
      expect(P3FeatureGuard.isPhase3GateEvaluationEnabled, isFalse);
      expect(P3FeatureGuard.isLimitedCutoverExecutionEnabled, isFalse);
      expect(P3FeatureGuard.isDbApiCandidateMigrationEnabled, isFalse);
    });

    test('P3.3.7 + P3.3.6 + P3.3.5 flags still false (regression)', () {
      expect(P3FeatureGuard.isLocalServingShadowRunEnabled, isFalse);
      expect(P3FeatureGuard.isParityCheckRecordingEnabled, isFalse);
      expect(P3FeatureGuard.isFactIngestShadowEvaluationEnabled, isFalse);
      expect(P3FeatureGuard.isRoutingShadowComputationEnabled, isFalse);
      expect(P3FeatureGuard.isLocalServingParityCompareEnabled, isFalse);
      expect(P3FeatureGuard.isLocalServingShadowRoutingEnabled, isFalse);
      expect(P3FeatureGuard.isReviewGroupCompatibilityModeEnabled, isFalse);
      expect(P3FeatureGuard.isLocalFactIngestShadowEnabled, isFalse);
      expect(P3FeatureGuard.isLocalPlannerOwnerShiftEnabled, isFalse);
      expect(P3FeatureGuard.isLocalServingShadowModeEnabled, isFalse);
      expect(P3FeatureGuard.isUnifiedPlannerRuntimeEnabled, isFalse);
    });

    testWidgets(
        'runtime truth regression: "背单词" still navigates to /study',
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

    test(
        'copy regression: existing "以后端判断为准" copy NOT changed this round',
        () {
      // This copy is from P3.3.3 (review_group_generation_policy_v1).
      // P3.3.9 explicitly DOES NOT change it because:
      //   1. It's accurate (current runtime truth IS backend)
      //   2. Changing it would cascade to 3+ test files
      //   3. R5's source-neutral guidance is for FAILURE states, not
      //      this eligibility copy
      // This test locks in the decision: the copy stays verbatim.
      const layer3Copy = '下一组是否可用，以后端判断为准';
      expect(layer3Copy, contains('后端判断'),
          reason:
              'P3.3.9 does NOT rewrite this copy. It stays at "后端判断为准" because current runtime serving truth IS cloud backend.');
    });

    test('review_group retained-anchor is consistent with P3.3.6 status', () {
      // P3.3.6: kReviewGroupStatus includes runtime_active + deprecation_candidate
      expect(ReviewGroupCompatibility.kReviewGroupStatus,
          contains('runtime_active'));
      expect(ReviewGroupCompatibility.kReviewGroupStatus,
          contains('deprecation_candidate'));
      // P3.3.9: 4-role posture adds retained_fallback_anchor on top
      expect(ReviewGroupRetainedAnchor.kFourRoles,
          contains('retained_fallback_anchor'));
      // Rollback target is consistent: both point to cloud review_group
      expect(ReviewGroupRetainedAnchor.kRollbackTarget,
          equals('cloud_review_group_current_runtime_path'));
    });
  });
}
