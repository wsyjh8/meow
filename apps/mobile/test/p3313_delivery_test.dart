import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/gate/cutover_subset.dart';
import 'package:meow_mobile/core/gate/db_api_uplift.dart';
import 'package:meow_mobile/core/gate/fact_owner_boundary.dart';
import 'package:meow_mobile/core/gate/review_group_lifecycle.dart';
import 'package:meow_mobile/core/gate/round_gates_and_guardrails.dart';
import 'package:meow_mobile/core/gate/writeback_order.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/serving/review_serving_seam.dart';

// ============================================================================
// P3.3.13 — Fuller-Cutover Execution / True-Exit-Candidate / DB-API
// Uplift-Absorb-Readiness Delivery Tests
//
// Six frozen contracts under test:
//   1. fuller_cutover_execution_subset_v2 (promotes P3.3.12 absorb-candidate)
//   2. review_group_true_exit_candidate_v1 (promotes P3.3.12 true-exit-gate)
//   3. db_api_uplift_absorb_readiness_v1 (promotes P3.3.12 absorb-judgment)
//   4. cutover_vs_fact_owner_boundary_v5 (extends P3.3.12 v4)
//   5. true_exit_candidate_narrowing_guardrail_v1 (NEW)
//   6. phase7_writeback_order_v1 (NEW)
//
// Like P3.3.10 / P3.3.11 / P3.3.12, this round is PURE ANCHOR WORK — no
// runtime files are modified. All tests are markerContractOnly except
// one runtimeTruthRegression widget test in Group G.
// ============================================================================

void main() {
  // ==========================================================================
  // Group A: fuller_cutover_execution_subset_v2 (6 tests)
  // ==========================================================================
  group('P3.3.13 fuller_cutover_execution_subset_v2: execution-subset-v2', () {
    test('ExecutionSubsetV2Layer enum has exactly 5 values', () {
      expect(ExecutionSubsetV2Layer.values.length, equals(5));
    });

    test('kAllowedLayers has 5 canonical execution-subset-v2 items', () {
      final layers = FullerCutoverExecutionSubsetV2.kAllowedLayers;
      expect(layers.length, equals(5));
      expect(layers,
          contains('reviewpage_continuity_adjacent_serving_adapter_family'));
      expect(layers,
          contains('source_neutral_helper_summary_empty_state_completion_prefix'));
      expect(
          layers,
          contains(
              'home_page_review_helper_summary_no_review_state_retained_anchor_aware_prep'));
      expect(
          layers, contains('rollback_hold_fallback_neutral_orchestration'));
      expect(
          layers, contains('stronger_ingest_binding_absorb_readiness_prep'));
    });

    test('kForbiddenAdditions has 7 canonical forbidden items', () {
      final forbidden = FullerCutoverExecutionSubsetV2.kForbiddenAdditions;
      expect(forbidden.length, equals(7));
      expect(forbidden, contains('home_page_default_route_switch'));
      expect(forbidden, contains('active_continuation_source_switch'));
      expect(forbidden,
          contains('user_visible_planner_aware_or_auto_routing_runtime'));
      expect(forbidden, contains('review_group_true_exit'));
      expect(forbidden, contains('final_fact_owner_shift'));
      expect(forbidden, contains('active_db_api_baseline_uplift_absorbed'));
      expect(forbidden, contains('cleanup_old_path_purge'));
    });

    test(
        'kSemanticBoundary contains "execution_subset_configured_for_more_complete_execution"',
        () {
      expect(
          FullerCutoverExecutionSubsetV2.kSemanticBoundary,
          contains(
              'execution_subset_configured_for_more_complete_execution'));
      expect(FullerCutoverExecutionSubsetV2.kSemanticBoundary,
          contains('does_not_equal_runtime_truth_fully_switched'));
    });

    test(
        'kBlastRadiusConstraint contains "reviewpage_plus_home_page_review_acceptance_layer"',
        () {
      expect(FullerCutoverExecutionSubsetV2.kBlastRadiusConstraint,
          contains('reviewpage_plus_home_page_review_acceptance_layer'));
    });

    test(
        'stage progression: previous p3.3.12 absorb-candidate → current p3.3.13 execution-subset-v2',
        () {
      expect(FullerCutoverExecutionSubsetV2.kPreviousStage,
          equals('p3_3_12_absorb_candidate_judgment_level'));
      expect(FullerCutoverExecutionSubsetV2.kCurrentStage,
          contains('execution_subset_v2'));
    });
  });

  // ==========================================================================
  // Group B: review_group_true_exit_candidate_v1 (6 tests)
  // ==========================================================================
  group('P3.3.13 review_group_true_exit_candidate_v1: true-exit-candidate',
      () {
    test(
        'kStatus equals "true_exit_candidate_qualified_not_true_exit_started"',
        () {
      expect(
          ReviewGroupTrueExitCandidate.kStatus,
          equals(
              'true_exit_candidate_qualified_not_true_exit_started'));
      expect(ReviewGroupTrueExitCandidate.kStatus,
          isNot(contains('has_exited')));
    });

    test('kFourLayersMustContinue has exactly 4 canonical roles', () {
      final layers = ReviewGroupTrueExitCandidate.kFourLayersMustContinue;
      expect(layers.length, equals(4));
      expect(layers, contains('current_runtime_serving_owner'));
      expect(layers, contains('retained_fallback_anchor'));
      expect(layers, contains('compatibility_anchor'));
      expect(layers, contains('deprecated_candidate'));
    });

    test('kSixStillDependentPaths has exactly 6 canonical paths', () {
      final paths = ReviewGroupTrueExitCandidate.kSixStillDependentPaths;
      expect(paths.length, equals(6));
      expect(paths, contains('active_continuation_identity'));
      expect(paths, contains('completion_gating'));
      expect(paths, contains('settlement_trigger'));
      expect(paths, contains('rollback_target'));
      expect(paths,
          contains('non_cutover_non_upgraded_sessions_baseline_path'));
      expect(paths, contains('compatibility_anchor_qa_baseline_reference'));
    });

    test(
        'kSevenStillMissingPreconditions has exactly 7 canonical preconditions',
        () {
      final pre =
          ReviewGroupTrueExitCandidate.kSevenStillMissingPreconditions;
      expect(pre.length, equals(7));
      expect(pre, contains('replacement_path_completeness'));
      expect(pre, contains('active_continuation_independence'));
      expect(pre, contains('completion_settlement_trigger_decoupling'));
      expect(pre, contains('rollback_target_replacement_readiness'));
      expect(pre, contains('compatibility_anchor_retirement_readiness'));
      expect(pre, contains('non_cutover_baseline_path_safety'));
      expect(
          pre, contains('documentation_test_runtime_evidence_completeness'));
    });

    test('kForbiddenClaims contains canonical forbidden phrases', () {
      final forbidden = ReviewGroupTrueExitCandidate.kForbiddenClaims;
      expect(forbidden, contains('review_group 已退场'));
      expect(forbidden, contains('true exit 已开始'));
      expect(forbidden, contains('rollback target 已变'));
      expect(forbidden, contains('retained anchor 已不再需要'));
      expect(forbidden, contains('review_group 可直接清理'));
    });

    test('P3.3.12 regression: ReviewGroupTrueExitGate.kStatus still intact',
        () {
      expect(
          ReviewGroupTrueExitGate.kStatus,
          contains(
              'true_exit_gate_qualification_discussion_not_true_exit_started'));
    });
  });

  // ==========================================================================
  // Group C: db_api_uplift_absorb_readiness_v1 (6 tests)
  // ==========================================================================
  group('P3.3.13 db_api_uplift_absorb_readiness_v1: absorb-readiness', () {
    test('UpliftAbsorbReadinessSeamFamily enum has exactly 5 values', () {
      expect(UpliftAbsorbReadinessSeamFamily.values.length, equals(5));
    });

    test('kStatus contains "absorb_readiness_qualified_not_active"', () {
      expect(DbApiUpliftAbsorbReadiness.kStatus,
          contains('absorb_readiness_qualified_not_active'));
    });

    test('kActiveDbBaselineStillAt and kActiveApiBaselineStillAt are v0.2.1',
        () {
      expect(DbApiUpliftAbsorbReadiness.kActiveDbBaselineStillAt,
          equals('v0.2.1'));
      expect(DbApiUpliftAbsorbReadiness.kActiveApiBaselineStillAt,
          equals('v0.2.1'));
    });

    test(
        'kUpliftAbsorbReadinessSeamFamilies has 5 canonical seam families',
        () {
      final seams =
          DbApiUpliftAbsorbReadiness.kUpliftAbsorbReadinessSeamFamilies;
      expect(seams.length, equals(5));
      expect(seams, contains('review_serving_source_descriptor_seam'));
      expect(seams, contains('retained_anchor_fallback_posture_seam'));
      expect(seams, contains('stronger_ingest_path_minimal_seam'));
      expect(seams, contains('rollback_hold_observability_seam'));
      expect(seams,
          contains('source_neutral_state_helper_summary_contract_seam'));
    });

    test(
        'kMustRemainAtMarkerMigrationRollbackHoldLayer has 7 canonical items',
        () {
      final items = DbApiUpliftAbsorbReadiness
          .kMustRemainAtMarkerMigrationRollbackHoldLayer;
      expect(items.length, equals(7));
      expect(items, contains('review_group_true_exit_seams'));
      expect(items, contains('active_continuation_source_switch_seams'));
      expect(items,
          contains('final_fact_settlement_owner_field_payload_seams'));
      expect(items, contains('home_page_route_planner_aware_routing_seams'));
      expect(items, contains('cleanup_old_path_purge_seams'));
      expect(
          items,
          contains(
              'schema_rewrite_history_backfill_compatibility_patch_seams'));
      expect(items, contains('endpoint_core_semantics_rewrite_seams'));
    });

    test('kForbiddenClaims contains canonical forbidden phrases', () {
      final forbidden = DbApiUpliftAbsorbReadiness.kForbiddenClaims;
      expect(forbidden, contains('active DB/API baseline 已升级'));
      expect(forbidden, contains('uplift 已 absorbed'));
      expect(forbidden, contains('uplift 已完成'));
      expect(forbidden, contains('schema 已重写'));
      expect(forbidden, contains('endpoint meaning 已重写'));
    });
  });

  // ==========================================================================
  // Group D: cutover_vs_fact_owner_boundary_v5 (6 tests)
  // ==========================================================================
  group(
      'P3.3.13 cutover_vs_fact_owner_boundary_v5: absorb-readiness binding',
      () {
    test(
        'kCanonicalRule equals "serving_seam_advancement_does_not_equal_final_fact_owner_advancement"',
        () {
      expect(
          CutoverVsFactOwnerBoundaryV5.kCanonicalRule,
          equals(
              'serving_seam_advancement_does_not_equal_final_fact_owner_advancement'));
    });

    test(
        'kFinalFactsRemainBackendAuthoritative has 5 canonical facts (same as v3/v4)',
        () {
      final facts =
          CutoverVsFactOwnerBoundaryV5.kFinalFactsRemainBackendAuthoritative;
      expect(facts.length, equals(5));
      expect(facts, contains('effective_review_fact'));
      expect(facts, contains('daily_goal_progress_and_completion_owner'));
      expect(facts, contains('reward_settlement_ledger_arrival_owner'));
      expect(facts, contains('check_in_learning_day_streak_owner'));
      expect(facts,
          contains('completion_arrival_class_primary_feedback_truth_source'));
    });

    test(
        'kStrongerIngestAbsorbReadinessAdvancementsV5 has 5 canonical new advancements',
        () {
      final adv = CutoverVsFactOwnerBoundaryV5
          .kStrongerIngestAbsorbReadinessAdvancementsV5;
      expect(adv.length, equals(5));
      expect(adv,
          contains('accept_reject_duplicate_binding_absorb_readiness_ready'));
      expect(
          adv,
          contains(
              'progress_completion_candidate_absorb_readiness_orchestration'));
      expect(
          adv,
          contains(
              'observability_parity_rollback_hold_absorb_readiness_complete'));
      expect(
          adv, contains('no_final_fact_owner_switch_assertion_strongest'));
      expect(
          adv,
          contains(
              'minimal_ingest_binding_aligned_with_execution_subset_v2'));
    });

    test('kStillForbiddenActions has 8 canonical forbidden items', () {
      final forbidden = CutoverVsFactOwnerBoundaryV5.kStillForbiddenActions;
      expect(forbidden.length, equals(8));
      expect(forbidden, contains('local_completion_confirmation'));
      expect(forbidden, contains('ledger_arrival_via_new_path'));
      expect(forbidden, contains('daily_goal_achievement_via_new_path'));
      expect(forbidden, contains('streak_update_via_new_path'));
      expect(forbidden, contains('review_fact_switched_to_local'));
      expect(forbidden, contains('new_main_path_live'));
      expect(forbidden, contains('review_group_exited'));
      expect(forbidden, contains('uplift_completed'));
    });

    test('kForbiddenOverclaims has 12 canonical RF-P3.3.13-016 phrases', () {
      final forbidden = CutoverVsFactOwnerBoundaryV5.kForbiddenOverclaims;
      expect(forbidden.length, equals(12));
      expect(forbidden, contains('local 已接管 review fact'));
      expect(forbidden, contains('local 已接管 daily completion 判断'));
      expect(forbidden, contains('本地结果已写回最终事实'));
      expect(forbidden, contains('奖励已由新 path 正式结算'));
      expect(forbidden, contains('streak / learning_day 已由新 path 续上'));
      expect(forbidden, contains('daily goal 已由新 serving seam 自动推进'));
      expect(forbidden, contains('completion 已由 local stronger path 裁定'));
      expect(forbidden, contains('review_group 已退场'));
      expect(forbidden, contains('active DB/API baseline 已升级'));
      expect(forbidden, contains('uplift 已 absorbed'));
      expect(forbidden, contains('fuller cutover 已完成'));
      expect(forbidden, contains('新主链路已生效'));
    });

    test(
        'kCanonicalMeaning contains "final_fact_owner_cannot_yet_switch" and "execution_subset_v2"',
        () {
      expect(CutoverVsFactOwnerBoundaryV5.kCanonicalMeaning,
          contains('final_fact_owner_cannot_yet_switch'));
      expect(CutoverVsFactOwnerBoundaryV5.kCanonicalMeaning,
          contains('execution_subset_v2'));
    });
  });

  // ==========================================================================
  // Group E: true_exit_candidate_narrowing_guardrail_v1 (7 tests)
  // ==========================================================================
  group(
      'P3.3.13 true_exit_candidate_narrowing_guardrail_v1: narrowing guardrail',
      () {
    test(
        'kCanonicalRule contains "very_narrow_narrowing_only_on_dependency_expression"',
        () {
      expect(
          TrueExitCandidateNarrowingGuardrail.kCanonicalRule,
          contains(
              'very_narrow_narrowing_only_on_dependency_expression'));
    });

    test('kCanNarrowVeryNarrowly has exactly 5 items', () {
      final items = TrueExitCandidateNarrowingGuardrail.kCanNarrowVeryNarrowly;
      expect(items.length, equals(5));
      expect(
          items, contains('group_only_wording_dependency_scope_narrowing'));
      expect(
          items,
          contains(
              'source_neutral_helper_summary_empty_state_group_only_wording_dependency'));
      expect(
          items,
          contains(
              'retained_anchor_aware_fallback_copy_coverage_scope_optimization'));
      expect(
          items,
          contains(
              'qa_docs_judgment_about_ui_assets_no_longer_must_group_only'));
      expect(
          items,
          contains(
              'rollback_fallback_explanation_redundant_wording_historical_cleanup'));
    });

    test('kCannotNarrow has exactly 6 immobile items', () {
      final items = TrueExitCandidateNarrowingGuardrail.kCannotNarrow;
      expect(items.length, equals(6));
      expect(items,
          contains('rollback_target_cloud_review_group_current_runtime_path'));
      expect(items, contains('current_visible_owner_identity'));
      expect(items, contains('retained_fallback_anchor_identity'));
      expect(items, contains('active_continuation_current_acceptance_path'));
      expect(
          items,
          contains(
              'current_completion_gating_settlement_trigger_explanation_pathway'));
      expect(items, contains('compatibility_anchor_qa_baseline_reference'));
    });

    test('kStopConditions has exactly 7 items', () {
      final stops = TrueExitCandidateNarrowingGuardrail.kStopConditions;
      expect(stops.length, equals(7));
      expect(stops, contains('home_page_study_default_touched'));
      expect(stops, contains('active_continuation_silent_reroute'));
      expect(
          stops,
          contains(
              'review_group_written_as_true_exit_or_cleanable_or_fallback_only'));
      expect(
          stops,
          contains(
              'local_stronger_path_affects_final_fact_or_settlement_truth'));
      expect(
          stops,
          contains(
              'user_visible_switched_to_local_planning_or_main_chain_live_or_cutover_or_uplift_completed'));
      expect(
          stops,
          contains(
              'execution_subset_or_candidate_or_readiness_written_as_runtime_truth'));
      expect(
          stops,
          contains(
              'db_schema_or_api_core_semantics_rewrite_required_to_proceed'));
    });

    test('kSemanticBoundary contains "dependency_expression_layer_narrowable"',
        () {
      expect(TrueExitCandidateNarrowingGuardrail.kSemanticBoundary,
          contains('dependency_expression_layer_narrowable'));
      expect(TrueExitCandidateNarrowingGuardrail.kSemanticBoundary,
          contains('bone_structure_anchors_remain_immobile'));
    });

    test('immobile list contains rollback target anchor', () {
      expect(
          TrueExitCandidateNarrowingGuardrail.kCannotNarrow,
          contains(
              'rollback_target_cloud_review_group_current_runtime_path'));
    });

    test('canNarrow and cannotNarrow are disjoint (no overlap)', () {
      final can =
          TrueExitCandidateNarrowingGuardrail.kCanNarrowVeryNarrowly.toSet();
      final cannot =
          TrueExitCandidateNarrowingGuardrail.kCannotNarrow.toSet();
      expect(can.intersection(cannot), isEmpty);
    });
  });

  // ==========================================================================
  // Group F: phase7_writeback_order_v1 (6 tests)
  // ==========================================================================
  group('P3.3.13 phase7_writeback_order_v1: 6-layer immutable sequence', () {
    test('WritebackPhase7Layer enum has exactly 6 values', () {
      expect(WritebackPhase7Layer.values.length, equals(6));
      expect(WritebackPhase7Layer.values,
          contains(WritebackPhase7Layer.r2TechNote));
      expect(WritebackPhase7Layer.values,
          contains(WritebackPhase7Layer.r3RulesNote));
      expect(WritebackPhase7Layer.values,
          contains(WritebackPhase7Layer.r5UiPreflight));
      expect(WritebackPhase7Layer.values,
          contains(WritebackPhase7Layer.r1ExecutionHandoff));
      expect(
          WritebackPhase7Layer.values,
          contains(WritebackPhase7Layer.dbApiWritebackToSeamMarkerLayerOnly));
      expect(WritebackPhase7Layer.values,
          contains(WritebackPhase7Layer.runtimeBaselineUpdate));
    });

    test('kWritebackSequence has 6 canonical steps in exact order', () {
      final seq = Phase7WritebackOrder.kWritebackSequence;
      expect(seq.length, equals(6));
      expect(seq[0], equals('r2_tech_note'));
      expect(seq[1], equals('r3_rules_note'));
      expect(seq[2], equals('r5_ui_preflight'));
      expect(seq[3], equals('r1_execution_handoff_only'));
      expect(seq[4], equals('db_api_writeback_to_seam_marker_layer_only'));
      expect(
          seq[5],
          equals(
              'runtime_baseline_update_only_if_r1_separately_pins_post_true_closeout'));
    });

    test('kJudgmentOnlyLayerExpressions has 5 canonical items', () {
      final items = Phase7WritebackOrder.kJudgmentOnlyLayerExpressions;
      expect(items.length, equals(5));
      expect(
          items,
          contains(
              'which_widened_subset_qualifies_for_execution_subset_v2'));
      expect(
          items,
          contains(
              'which_review_group_content_qualifies_for_true_exit_candidate'));
      expect(
          items,
          contains(
              'which_db_api_seams_are_uplift_absorb_readiness_ready'));
      expect(
          items,
          contains(
              'how_far_stronger_ingest_currently_advances_toward_absorb_readiness'));
      expect(
          items,
          contains(
              'when_retained_anchor_rollback_target_become_future_narrowable'));
    });

    test('kForbiddenRuntimeTruthElevation has 7 canonical forbidden items',
        () {
      final forbidden = Phase7WritebackOrder.kForbiddenRuntimeTruthElevation;
      expect(forbidden.length, equals(7));
      expect(forbidden, contains('full_cutover_completed'));
      expect(forbidden, contains('review_group_true_exit'));
      expect(forbidden, contains('active_db_api_uplift_absorbed'));
      expect(forbidden, contains('final_fact_owner_shift'));
      expect(forbidden,
          contains('home_page_route_active_continuation_source_switch'));
      expect(forbidden, contains('cleanup_old_path_purge'));
      expect(forbidden, contains('runtime_owner_shift_completed'));
    });

    test('kImmutableLayerSeparation contains "jumping_forbidden"', () {
      expect(Phase7WritebackOrder.kImmutableLayerSeparation,
          contains('jumping_forbidden'));
    });

    test('kR1ToR4HandoffConditions has 5 canonical conditions', () {
      final conds = Phase7WritebackOrder.kR1ToR4HandoffConditions;
      expect(conds.length, equals(5));
      expect(conds, contains('no_overclaim'));
      expect(conds, contains('rollback_hold_fallback_observability_complete'));
      expect(
          conds,
          contains(
              'no_home_page_route_active_continuation_final_fact_owner_touch'));
      expect(
          conds,
          contains('review_group_remains_current_owner_plus_retained_anchor'));
      expect(
          conds,
          contains('uplift_absorb_readiness_not_written_as_active_uplift'));
    });
  });

  // ==========================================================================
  // Group G: flags + regression (6 tests)
  // ==========================================================================
  group('P3.3.13 flags + regression', () {
    test('all 3 P3.3.13 flags are false', () {
      expect(P3FeatureGuard.isFullerCutoverExecutionSubsetV2Enabled, isFalse);
      expect(P3FeatureGuard.isReviewGroupTrueExitCandidateEnabled, isFalse);
      expect(P3FeatureGuard.isDbApiUpliftAbsorbReadinessEnabled, isFalse);
    });

    test('P3.3.12 flags still false (regression)', () {
      expect(P3FeatureGuard.isFullerCutoverAbsorbCandidateJudgmentEnabled,
          isFalse);
      expect(P3FeatureGuard.isReviewGroupTrueExitGateJudgmentEnabled, isFalse);
      expect(P3FeatureGuard.isDbApiUpliftAbsorbJudgmentEnabled, isFalse);
    });

    test('P3.3.5/6/7/8/9/10/11 flags still false (regression)', () {
      expect(P3FeatureGuard.isFullerCutoverExecutionReadyEnabled, isFalse);
      expect(P3FeatureGuard.isReviewGroupExitCandidateEnabled, isFalse);
      expect(P3FeatureGuard.isDbApiUpliftReadinessEnabled, isFalse);
      expect(P3FeatureGuard.isFullerCutoverJudgmentCandidateEnabled, isFalse);
      expect(P3FeatureGuard.isReviewGroupExitGateJudgmentV2Enabled, isFalse);
      expect(P3FeatureGuard.isDbApiUpliftJudgmentEnabled, isFalse);
      expect(P3FeatureGuard.isReviewPageNonContinuationCutoverEnabled, isTrue); // P3.3.16 flipped
      expect(P3FeatureGuard.isPhase3GateEvaluationEnabled, isFalse);
      expect(P3FeatureGuard.isLocalServingShadowRunEnabled, isFalse);
    });

    test('review_group 4-role posture (P3.3.9) still intact', () {
      expect(ReviewGroupRetainedAnchor.kFourRoles.length, equals(4));
      expect(ReviewGroupRetainedAnchor.kFourRoles,
          contains('current_runtime_serving_owner'));
      expect(ReviewGroupRetainedAnchor.kFourRoles,
          contains('retained_fallback_anchor'));
    });

    test('P3.3.12 absorb-candidate anchor still intact (regression)', () {
      expect(FullerCutoverAbsorbCandidate.kCurrentStage,
          contains('absorb_candidate_judgment'));
      expect(FullerCutoverAbsorbCandidate.kAllowedLayers.length, equals(5));
    });

    testWidgets('runtime truth regression: "背单词" still navigates to /study',
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
      final sel = ReviewServingSeam.selectSource(
        isCutoverEnabled: false,
        hasActiveContinuation: false,
      );
      expect(sel.source, ReviewServingSourceKind.cloudReviewGroup);
      expect(sel.reason, equals('cutover_flag_disabled_default_cloud'));
      expect(ReviewServingSeam.kRollbackTarget,
          equals('cloud_review_group_current_runtime_path'));
    });
  });
}
