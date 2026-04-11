import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/gate/cutover_vs_fact_owner_boundary_v2.dart';
import 'package:meow_mobile/core/gate/db_api_uplift_judgment.dart';
import 'package:meow_mobile/core/gate/fuller_cutover_subset.dart';
import 'package:meow_mobile/core/gate/retained_anchor_to_exit_transition.dart';
import 'package:meow_mobile/core/gate/review_group_exit_gate.dart';
import 'package:meow_mobile/core/gate/review_group_exit_gate_v2.dart';
import 'package:meow_mobile/core/gate/review_group_retained_anchor.dart';
import 'package:meow_mobile/core/gate/stronger_ingest_judgment_ready.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/serving/review_serving_seam.dart';

// ============================================================================
// P3.3.10 — Fuller Cutover / review_group Exit-Gate / DB-API Uplift Judgment
// Delivery Tests
//
// Six frozen contracts under test:
//   1. fuller_cutover_subset_v1
//   2. review_group_exit_gate_v2 (extends P3.3.8 v1 + P3.3.9 retained anchor)
//   3. db_api_uplift_judgment_v1
//   4. cutover_vs_fact_owner_boundary_v2 (extends P3.3.9 v1)
//   5. retained_anchor_to_exit_transition_v1
//   6. stronger_ingest_judgment_ready_v1
//
// Unlike P3.3.9 (which added a ReviewPage runtime modification),
// P3.3.10 is PURE ANCHOR WORK — no runtime files are touched. All
// tests are markerContractOnly except one runtimeTruthRegression
// widget test in Group G.
// ============================================================================

void main() {
  // ==========================================================================
  // Group A: fuller_cutover_subset_v1 — allowed subset (6 tests)
  // ==========================================================================
  group('P3.3.10 fuller_cutover_subset_v1: allowed subset', () {
    test('FullerCutoverLayer enum has exactly 5 values', () {
      expect(FullerCutoverLayer.values.length, equals(5));
    });

    test('kAllowedLayers contains all 5 canonical continuity-adjacent layers',
        () {
      final layers = FullerCutoverSubset.kAllowedLayers;
      expect(layers.length, equals(5));
      expect(layers, contains('continuity_adjacent_serving_adapter_family'));
      expect(
          layers,
          contains(
              'source_neutral_helper_summary_empty_state_completion_prep'));
      expect(
          layers,
          contains(
              'home_page_review_helper_summary_retained_anchor_aware_prep'));
      expect(
          layers,
          contains(
              'rollback_hold_fallback_neutral_copy_state_contract_prep'));
      expect(layers, contains('stronger_ingest_candidate_handoff_prep'));
    });

    test('kForbiddenExpansions contains canonical forbidden items', () {
      final forbidden = FullerCutoverSubset.kForbiddenExpansions;
      expect(forbidden, contains('home_page_default_route_switch'));
      expect(forbidden, contains('active_continuation_source_switch'));
      expect(forbidden, contains('review_group_true_exit'));
      expect(forbidden, contains('final_fact_owner_shift'));
      expect(forbidden, contains('active_db_api_baseline_uplift'));
      expect(forbidden, contains('cleanup_old_path_purge'));
      expect(forbidden, contains('auto_routing_runtime'));
    });

    test('kCanonicalRule enforces judgment-ready not execution-ready', () {
      expect(FullerCutoverSubset.kCanonicalRule,
          contains('fuller_cutover_judgment'));
      expect(FullerCutoverSubset.kCanonicalRule,
          contains('not_equivalent_to_execution_ready'));
    });

    test('kForbiddenClaims contains canonical cutover claim phrases', () {
      final forbidden = FullerCutoverSubset.kForbiddenClaims;
      expect(forbidden, contains('当前已完成 fuller cutover'));
      expect(forbidden, contains('新主链路已生效'));
      expect(forbidden, contains('cutover 已完成'));
      expect(forbidden, contains('已切到本地规划'));
      expect(forbidden, contains('本地 serving 已启用'));
    });

    test('allowed layers and forbidden expansions do not overlap', () {
      for (final layer in FullerCutoverSubset.kAllowedLayers) {
        expect(FullerCutoverSubset.kForbiddenExpansions,
            isNot(contains(layer)));
      }
    });
  });

  // ==========================================================================
  // Group B: review_group_exit_gate_v2 (7 tests)
  // ==========================================================================
  group('P3.3.10 review_group_exit_gate_v2: 5 prerequisite categories', () {
    test('ExitGateV2PrerequisiteCategory enum has exactly 5 values', () {
      expect(ExitGateV2PrerequisiteCategory.values.length, equals(5));
      expect(ExitGateV2PrerequisiteCategory.values,
          contains(ExitGateV2PrerequisiteCategory.contract));
      expect(ExitGateV2PrerequisiteCategory.values,
          contains(ExitGateV2PrerequisiteCategory.test));
      expect(ExitGateV2PrerequisiteCategory.values,
          contains(ExitGateV2PrerequisiteCategory.doc));
      expect(ExitGateV2PrerequisiteCategory.values,
          contains(ExitGateV2PrerequisiteCategory.runtime),
          reason: 'P3.3.10 adds the new `runtime` category');
      expect(ExitGateV2PrerequisiteCategory.values,
          contains(ExitGateV2PrerequisiteCategory.boundary));
    });

    test('kGateStatus contains "v2_prerequisites_not_yet_met"', () {
      expect(ReviewGroupExitGateV2.kGateStatus,
          contains('v2_prerequisites_not_yet_met'));
      // Anti-pattern:
      expect(
          ReviewGroupExitGateV2.kGateStatus, isNot(contains('exited')));
      expect(
          ReviewGroupExitGateV2.kGateStatus, isNot(contains('retired')));
    });

    test(
        'kContractPrerequisitesV2 contains NEW P3.3.10 contracts + P3.3.8 v1 contracts',
        () {
      final contracts = ReviewGroupExitGateV2.kContractPrerequisitesV2;
      // NEW in P3.3.10:
      expect(contracts,
          contains('fuller_cutover_subset_pinned_as_next_layer_contract'));
      expect(contracts, contains('cutover_vs_fact_owner_boundary_v2_pinned'));
      expect(contracts, contains('retained_anchor_to_exit_transition_pinned'));
      expect(contracts, contains('db_api_uplift_judgment_pinned'));
      expect(contracts, contains('writeback_order_pinned_for_p3_3_10'));
      // P3.3.8 v1 still required:
      expect(contracts,
          contains('local_serving_candidate_pinned_as_next_layer_contract'));
      expect(contracts, contains('fact_ingest_candidate_pinned'));
    });

    test('kRuntimePrerequisitesNewInV2 has 4 canonical runtime prerequisites',
        () {
      final runtimePrereqs =
          ReviewGroupExitGateV2.kRuntimePrerequisitesNewInV2;
      expect(runtimePrereqs.length, equals(4));
      expect(runtimePrereqs,
          contains('active_continuation_unambiguous_replacement_path'));
      expect(runtimePrereqs,
          contains('completion_gating_unambiguous_replacement_path'));
      expect(runtimePrereqs,
          contains('settlement_trigger_unambiguous_replacement_path'));
      expect(
          runtimePrereqs,
          contains(
              'rollback_target_still_returnable_repeatable_verifiable'));
    });

    test(
        'kDocPrerequisitesV2 contains br_ui_db_api_test synchronization',
        () {
      final docs = ReviewGroupExitGateV2.kDocPrerequisitesV2;
      expect(docs,
          contains('br_ui_db_api_test_exit_impact_scope_synchronized'));
      expect(
          docs,
          contains(
              'rollback_target_hold_note_no_overclaim_copy_synchronized'));
      expect(docs, contains('writeback_order_explicit'));
    });

    test('P3.3.8 v1 regression: ReviewGroupExitGate.kGateStatus still intact',
        () {
      // P3.3.8 v1 status still holds unchanged
      expect(ReviewGroupExitGate.kGateStatus,
          contains('prerequisites_not_yet_met'));
      // P3.3.10 v2 extends it with a different status string
      expect(
          ReviewGroupExitGateV2.kGateStatus, isNot(equals(ReviewGroupExitGate.kGateStatus)),
          reason: 'v2 has a distinct status from v1');
    });

    test('kForbiddenClaims contains canonical exit overclaim phrases', () {
      final forbidden = ReviewGroupExitGateV2.kForbiddenClaims;
      expect(forbidden, contains('review_group 已退场'));
      expect(forbidden, contains('已不再使用 review_group'));
      expect(forbidden, contains('retained anchor 已不再需要'));
      expect(forbidden, contains('review_group 已变成 fallback-only'));
    });
  });

  // ==========================================================================
  // Group C: db_api_uplift_judgment_v1 (6 tests)
  // ==========================================================================
  group('P3.3.10 db_api_uplift_judgment_v1: uplift-judgment-ready', () {
    test('UpliftSeamFamily enum has exactly 5 values', () {
      expect(UpliftSeamFamily.values.length, equals(5));
      expect(UpliftSeamFamily.values,
          contains(UpliftSeamFamily.reviewServingSourceDescriptorSeam));
      expect(UpliftSeamFamily.values,
          contains(UpliftSeamFamily.retainedAnchorFallbackPostureSeam));
      expect(UpliftSeamFamily.values,
          contains(UpliftSeamFamily.strongerIngestPathMinimalSeam));
      expect(UpliftSeamFamily.values,
          contains(UpliftSeamFamily.rollbackHoldObservabilitySeam));
      expect(UpliftSeamFamily.values,
          contains(UpliftSeamFamily.continuationAdjacentHelperSeam));
    });

    test('kUpliftStatus contains "judgment_ready_not_active"', () {
      expect(DbApiUpliftJudgment.kUpliftStatus,
          contains('judgment_ready_not_active'));
      expect(DbApiUpliftJudgment.kUpliftStatus, isNot(contains('absorbed_now')));
    });

    test('kActiveDbBaselineStillAt and kActiveApiBaselineStillAt are v0.2.1',
        () {
      expect(DbApiUpliftJudgment.kActiveDbBaselineStillAt, equals('v0.2.1'));
      expect(DbApiUpliftJudgment.kActiveApiBaselineStillAt, equals('v0.2.1'));
    });

    test('kUpliftJudgmentReadySeamFamilies has 5 canonical seam families',
        () {
      final seams = DbApiUpliftJudgment.kUpliftJudgmentReadySeamFamilies;
      expect(seams.length, equals(5));
      expect(seams, contains('review_serving_source_descriptor_seam'));
      expect(seams, contains('retained_anchor_fallback_posture_seam'));
      expect(seams, contains('stronger_ingest_path_minimal_seam'));
      expect(seams, contains('rollback_hold_observability_seam'));
      expect(seams, contains('continuation_adjacent_helper_seam'));
    });

    test('kForbiddenLayers contains schema_rewrite + baseline_uplift', () {
      final forbidden = DbApiUpliftJudgment.kForbiddenLayers;
      expect(forbidden, contains('db_schema_rewrite'));
      expect(forbidden, contains('api_endpoint_core_semantics_rewrite'));
      expect(forbidden, contains('active_baseline_uplift_absorbed'));
      expect(forbidden, contains('final_fact_settlement_owner_fields_rewrite'));
    });

    test('kForbiddenUpliftClaims contains canonical uplift overclaim phrases',
        () {
      final forbidden = DbApiUpliftJudgment.kForbiddenUpliftClaims;
      expect(forbidden, contains('active DB/API baseline 已升级'));
      expect(forbidden, contains('uplift 已 absorbed'));
      expect(forbidden, contains('新基线已吸收进运行态'));
      expect(forbidden, contains('uplift 已完成'));
    });
  });

  // ==========================================================================
  // Group D: cutover_vs_fact_owner_boundary_v2 (5 tests)
  // ==========================================================================
  group('P3.3.10 cutover_vs_fact_owner_boundary_v2: boundary', () {
    test('kCanonicalRule enforces fuller-cutover vs final-fact-owner decoupling',
        () {
      expect(CutoverVsFactOwnerBoundaryV2.kCanonicalRule,
          contains('fuller_cutover_vs_final_fact_owner_decoupled'));
    });

    test('kFinalFactsRemainBackendAuthoritative contains all 4 P3.3.9 core facts',
        () {
      final facts =
          CutoverVsFactOwnerBoundaryV2.kFinalFactsRemainBackendAuthoritative;
      expect(facts, contains('effective_review_fact'));
      expect(facts, contains('daily_goal_progress_and_completion'));
      expect(facts, contains('reward_settlement_ledger_arrival'));
      expect(facts, contains('check_in_learning_day_streak'));
      expect(facts, contains('completion_arrival_class_main_feedback'));
    });

    test('kStrongerIngestAllowedAdvancementsV2 has 5 new advancements', () {
      final adv = CutoverVsFactOwnerBoundaryV2.kStrongerIngestAllowedAdvancementsV2;
      expect(adv.length, equals(5));
      expect(adv, contains('accept_reject_duplicate_result_standardization'));
      expect(adv,
          contains('attempt_progress_completion_candidate_clearer_naming'));
      expect(adv, contains('stronger_ingest_precondition_postcondition'));
      expect(adv,
          contains('hold_reason_reject_reason_mismatch_bucket_explicitness'));
      expect(
          adv,
          contains(
              'no_final_fact_owner_switch_assertion_more_stable_landing'));
    });

    test('kStillForbiddenActions contains stronger_ingest_elevation forbidden',
        () {
      final forbidden = CutoverVsFactOwnerBoundaryV2.kStillForbiddenActions;
      expect(forbidden,
          contains('stronger_ingest_elevation_to_final_fact_write'));
      expect(forbidden,
          contains('local_serving_result_directly_modifies_ledger'));
      expect(
          forbidden,
          contains(
              'local_serving_result_directly_advances_daily_goal_completion'));
    });

    test('kCanonicalMeaning contains final_fact_owner_cannot_yet_switch', () {
      expect(CutoverVsFactOwnerBoundaryV2.kCanonicalMeaning,
          contains('final_fact_owner_cannot_yet_switch'));
      expect(CutoverVsFactOwnerBoundaryV2.kCanonicalMeaning,
          contains('serving_subset_can_fuller'));
      expect(CutoverVsFactOwnerBoundaryV2.kCanonicalMeaning,
          contains('ingest_candidate_stronger'));
    });
  });

  // ==========================================================================
  // Group E: retained_anchor_to_exit_transition_v1 (7 tests)
  // ==========================================================================
  group('P3.3.10 retained_anchor_to_exit_transition_v1: classification', () {
    test('kCanonicalOrderingRule enforces replace_first_then_narrow', () {
      expect(RetainedAnchorToExitTransition.kCanonicalOrderingRule,
          contains('replace_first_then_narrow'));
      expect(RetainedAnchorToExitTransition.kCanonicalOrderingRule,
          contains('never_narrow_first_then_supplement'));
    });

    test(
        'kStillFixedRollbackTarget == canonical cloud_review_group rollback target',
        () {
      expect(RetainedAnchorToExitTransition.kStillFixedRollbackTarget,
          equals('cloud_review_group_current_runtime_path'));
    });

    test('kStillFixed has 8 items including rollback target', () {
      final fixed = RetainedAnchorToExitTransition.kStillFixed;
      expect(fixed.length, equals(8));
      expect(fixed,
          contains('rollback_target_cloud_review_group_current_runtime_path'));
      expect(fixed,
          contains('current_owner_identity_not_downgradable_to_fallback_only'));
      expect(fixed, contains('compatibility_anchor_unchanged'));
      expect(fixed, contains('deprecated_candidate_marker_unchanged'));
      expect(fixed, contains('active_continuation_identity_unchanged'));
      expect(fixed,
          contains('completion_gating_current_review_group_dependency'));
      expect(fixed,
          contains('settlement_trigger_current_review_group_dependency'));
      expect(fixed,
          contains('non_cutover_baseline_path_current_review_group_fallback'));
    });

    test('kFutureNarrowable has 5 canonical future candidates', () {
      final future = RetainedAnchorToExitTransition.kFutureNarrowable;
      expect(future.length, equals(5));
      expect(
          future,
          contains(
              'fallback_rollback_scope_only_after_replacement_paths_complete'));
      expect(future,
          contains('which_widened_subset_failure_must_return_to_primary_target'));
      expect(
          future,
          contains(
              'which_paths_can_be_separated_from_review_group_dependency'));
      expect(
          future,
          contains(
              'retained_anchor_responsibilities_narrowing_toward_exit_candidate'));
      expect(future,
          contains('secondary_fallback_routing_granularity_distinction'));
    });

    test('kPreconditionsBeforeNarrowing has 5 canonical preconditions', () {
      final pre = RetainedAnchorToExitTransition.kPreconditionsBeforeNarrowing;
      expect(pre.length, equals(5));
      expect(
          pre,
          contains(
              'active_continuation_replacement_contract_explicitly_declared'));
      expect(
          pre,
          contains(
              'completion_gating_replacement_contract_explicitly_declared'));
      expect(
          pre,
          contains(
              'settlement_trigger_replacement_contract_explicitly_declared'));
      expect(pre, contains('non_cutover_baseline_path_explicitly_declared'));
      expect(pre, contains('rollback_still_has_usable_target'));
    });

    test('kStopConditions contains canonical stop triggers', () {
      final stops = RetainedAnchorToExitTransition.kStopConditions;
      expect(stops, contains('active_continuation_silent_reroute_to_local_path'));
      expect(stops,
          contains('local_subset_written_as_current_reviewpage_full_truth'));
      expect(stops,
          contains('home_page_route_planner_aware_auto_routing_rewrite'));
      expect(
          stops,
          contains(
              'user_visible_cutover_completed_owner_shift_review_group_exited_overclaim'));
      expect(stops, contains('db_schema_api_core_semantics_change_requirement'));
    });

    test('still-fixed and future-narrowable lists do not overlap', () {
      for (final fixedItem in RetainedAnchorToExitTransition.kStillFixed) {
        expect(RetainedAnchorToExitTransition.kFutureNarrowable,
            isNot(contains(fixedItem)));
      }
    });
  });

  // ==========================================================================
  // Group F: stronger_ingest_judgment_ready_v1 (4 tests)
  // ==========================================================================
  group('P3.3.10 stronger_ingest_judgment_ready_v1: stage progression', () {
    test('kPreviousStage == evidence_path_only_p3_3_7', () {
      expect(StrongerIngestJudgmentReady.kPreviousStage,
          equals('evidence_path_only_p3_3_7'));
    });

    test('kCurrentStage contains validated_stronger_ingest_candidate_layer',
        () {
      expect(StrongerIngestJudgmentReady.kCurrentStage,
          contains('validated_stronger_ingest_candidate_layer'));
    });

    test('kAllowedAdvancements contains canonical rule clarifications', () {
      final adv = StrongerIngestJudgmentReady.kAllowedAdvancements;
      expect(adv, contains('clearer_accept_reject_duplicate_rule_semantics'));
      expect(adv,
          contains('attempt_progress_completion_candidate_clearer_naming'));
      expect(adv, contains('stronger_ingest_precondition_postcondition'));
      expect(
          adv,
          contains(
              'hold_reason_reject_reason_mismatch_bucket_explicit_statement'));
      expect(adv, contains('more_explicit_rollback_hold_evidence_ownership'));
      expect(adv, contains('minimal_ingest_contract_binding_to_serving_subset'));
    });

    test(
        'kStillForbidden contains elevation_to_final_fact_write + canonical rule',
        () {
      final forbidden = StrongerIngestJudgmentReady.kStillForbidden;
      expect(forbidden,
          contains('local_stronger_path_elevation_to_final_fact_write'));
      expect(forbidden, contains('direct_modification_of_reward_ledger'));
      expect(
          forbidden, contains('direct_modification_of_daily_goal_completion'));
      expect(
          forbidden,
          contains(
              'direct_modification_of_streak_learning_day_final_fact'));
      // Canonical rule
      expect(StrongerIngestJudgmentReady.kCanonicalRule,
          equals('stronger_candidate_layer_not_fact_owner_layer'));
    });
  });

  // ==========================================================================
  // Group G: flags + regression (6 tests)
  // ==========================================================================
  group('P3.3.10 flags + regression', () {
    test('all 3 P3.3.10 flags are false', () {
      expect(P3FeatureGuard.isFullerCutoverJudgmentCandidateEnabled, isFalse);
      expect(P3FeatureGuard.isReviewGroupExitGateJudgmentV2Enabled, isFalse);
      expect(P3FeatureGuard.isDbApiUpliftJudgmentEnabled, isFalse);
    });

    test('P3.3.9 flags still false (regression)', () {
      expect(P3FeatureGuard.isReviewPageNonContinuationCutoverEnabled, isFalse);
      expect(P3FeatureGuard.isStrongerIngestCandidatePathEnabled, isFalse);
    });

    test('P3.3.5/6/7/8 flags still false (regression)', () {
      expect(P3FeatureGuard.isLocalServingShadowRunEnabled, isFalse);
      expect(P3FeatureGuard.isParityCheckRecordingEnabled, isFalse);
      expect(P3FeatureGuard.isFactIngestShadowEvaluationEnabled, isFalse);
      expect(P3FeatureGuard.isRoutingShadowComputationEnabled, isFalse);
      expect(P3FeatureGuard.isLocalServingParityCompareEnabled, isFalse);
      expect(P3FeatureGuard.isLocalServingShadowRoutingEnabled, isFalse);
      expect(P3FeatureGuard.isPhase3GateEvaluationEnabled, isFalse);
      expect(P3FeatureGuard.isLimitedCutoverExecutionEnabled, isFalse);
      expect(P3FeatureGuard.isDbApiCandidateMigrationEnabled, isFalse);
    });

    test('review_group 4-role posture (P3.3.9) still intact', () {
      // P3.3.9's 4 roles are still correct this round
      expect(ReviewGroupRetainedAnchor.kFourRoles.length, equals(4));
      expect(ReviewGroupRetainedAnchor.kFourRoles,
          contains('current_runtime_serving_owner'));
      expect(ReviewGroupRetainedAnchor.kFourRoles,
          contains('retained_fallback_anchor'));
      expect(ReviewGroupRetainedAnchor.kFourRoles,
          contains('compatibility_anchor'));
      expect(ReviewGroupRetainedAnchor.kFourRoles,
          contains('deprecated_candidate'));
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
        'runtime code regression: ReviewServingSeam still returns cloud when flag OFF',
        () {
      // P3.3.9's seam classifier is untouched by P3.3.10
      final sel1 = ReviewServingSeam.selectSource(
        isCutoverEnabled: false,
        hasActiveContinuation: false,
      );
      expect(sel1.source, ReviewServingSourceKind.cloudReviewGroup);
      expect(sel1.reason, equals('cutover_flag_disabled_default_cloud'));

      final sel2 = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: true,
      );
      expect(sel2.source, ReviewServingSourceKind.cloudReviewGroup);
      expect(sel2.reason, equals('retained_anchor_active_continuation'));

      // Rollback target unchanged
      expect(ReviewServingSeam.kRollbackTarget,
          equals('cloud_review_group_current_runtime_path'));
    });
  });
}
