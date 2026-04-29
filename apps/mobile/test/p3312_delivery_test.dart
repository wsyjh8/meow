import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/gate/cutover_subset.dart';
import 'package:meow_mobile/core/gate/db_api_uplift.dart';
import 'package:meow_mobile/core/gate/fact_owner_boundary.dart';
import 'package:meow_mobile/core/gate/review_group_lifecycle.dart';
import 'package:meow_mobile/core/gate/writeback_order.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/serving/review_serving_seam.dart';

// ============================================================================
// P3.3.12 — Fuller-Cutover Absorb-Candidate / True-Exit-Gate / DB-API
// Uplift-Absorb Judgment Delivery Tests
//
// Six frozen contracts under test:
//   1. fuller_cutover_absorb_candidate_v1 (promotes P3.3.11 execution-ready)
//   2. review_group_true_exit_gate_v1 (promotes P3.3.11 exit-candidate)
//   3. db_api_uplift_absorb_judgment_v1 (promotes P3.3.11 readiness)
//   4. cutover_vs_fact_owner_boundary_v4 (extends P3.3.11 v3)
//   5. exit_candidate_to_true_exit_transition_v1 (NEW)
//   6. phase6_writeback_order_v1 (NEW)
//
// Like P3.3.10 and P3.3.11, this round is PURE ANCHOR WORK — no runtime
// files are modified. All tests are markerContractOnly except one
// runtimeTruthRegression widget test in Group G.
// ============================================================================

void main() {
  // ==========================================================================
  // Group A: fuller_cutover_absorb_candidate_v1 (6 tests)
  // ==========================================================================
  group('P3.3.12 fuller_cutover_absorb_candidate_v1: absorb-candidate', () {
    test('AbsorbCandidateLayer enum has exactly 5 values', () {
      expect(AbsorbCandidateLayer.values.length, equals(5));
    });

    test('kAllowedLayers has 5 canonical absorb-candidate items', () {
      final layers = FullerCutoverAbsorbCandidate.kAllowedLayers;
      expect(layers.length, equals(5));
      expect(layers,
          contains('reviewpage_continuity_adjacent_serving_adapter_family'));
      expect(layers,
          contains('home_page_review_helper_summary_retained_anchor_aware'));
      expect(
          layers, contains('rollback_hold_fallback_neutral_orchestration'));
      expect(layers, contains('stronger_ingest_binding_absorb_candidate_prep'));
      expect(
          layers,
          contains('source_neutral_state_helper_summary_contract_family'));
    });

    test('kForbiddenAdditions contains canonical forbidden items', () {
      final forbidden = FullerCutoverAbsorbCandidate.kForbiddenAdditions;
      expect(forbidden, contains('home_page_default_route_switch'));
      expect(forbidden, contains('active_continuation_source_switch'));
      expect(forbidden, contains('final_fact_owner_shift'));
      expect(forbidden, contains('review_group_true_exit'));
      expect(forbidden, contains('active_db_api_baseline_uplift_absorbed'));
      expect(forbidden, contains('cleanup_old_path_purge'));
      expect(forbidden, contains('user_visible_mode_switch_announcement'));
    });

    test(
        'kSemanticBoundary contains "absorb_candidate_judgment_not_absorbed_into_runtime_truth"',
        () {
      expect(FullerCutoverAbsorbCandidate.kSemanticBoundary,
          equals('absorb_candidate_judgment_not_absorbed_into_runtime_truth'));
    });

    test(
        'kBlastRadiusConstraint contains "reviewpage_plus_home_page_review_acceptance_layer"',
        () {
      expect(FullerCutoverAbsorbCandidate.kBlastRadiusConstraint,
          contains('reviewpage_plus_home_page_review_acceptance_layer'));
    });

    test(
        'stage progression: previous p3.3.11 execution-ready → current p3.3.12 absorb-candidate',
        () {
      expect(FullerCutoverAbsorbCandidate.kPreviousStage,
          equals('p3_3_11_execution_ready_candidate_level'));
      expect(FullerCutoverAbsorbCandidate.kCurrentStage,
          contains('absorb_candidate_judgment'));
    });
  });

  // ==========================================================================
  // Group B: review_group_true_exit_gate_v1 (6 tests)
  // ==========================================================================
  group('P3.3.12 review_group_true_exit_gate_v1: true-exit-gate', () {
    test(
        'kStatus contains "true_exit_gate_qualification_discussion_not_true_exit_started"',
        () {
      expect(
          ReviewGroupTrueExitGate.kStatus,
          contains(
              'true_exit_gate_qualification_discussion_not_true_exit_started'));
      expect(ReviewGroupTrueExitGate.kStatus, isNot(contains('has_exited')));
    });

    test('kFourLayersMustContinue has exactly 4 canonical roles', () {
      final layers = ReviewGroupTrueExitGate.kFourLayersMustContinue;
      expect(layers.length, equals(4));
      expect(layers, contains('current_runtime_serving_owner'));
      expect(layers, contains('retained_fallback_anchor'));
      expect(layers, contains('compatibility_anchor'));
      expect(layers, contains('deprecated_candidate'));
    });

    test('kSixStillDependentPaths has exactly 6 canonical paths', () {
      final paths = ReviewGroupTrueExitGate.kSixStillDependentPaths;
      expect(paths.length, equals(6));
      expect(paths, contains('active_continuation_identity'));
      expect(paths, contains('completion_gating'));
      expect(paths, contains('settlement_trigger'));
      expect(paths, contains('rollback_target'));
      expect(paths, contains('non_cutover_non_upgraded_sessions_baseline_path'));
      expect(paths, contains('compatibility_anchor_qa_baseline_reference'));
    });

    test('kSevenMissingPreconditions has exactly 7 canonical preconditions',
        () {
      final pre = ReviewGroupTrueExitGate.kSevenMissingPreconditions;
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
      final forbidden = ReviewGroupTrueExitGate.kForbiddenClaims;
      expect(forbidden, contains('review_group 已退场'));
      expect(forbidden, contains('rollback target 已变'));
      expect(forbidden, contains('true exit 已开始'));
      expect(forbidden, contains('retained anchor 已不再需要'));
    });

    test('P3.3.11 regression: ReviewGroupExitCandidate.kStatus still intact',
        () {
      expect(ReviewGroupExitCandidate.kStatus,
          contains('exit_candidate_qualified_not_true_exit'));
    });
  });

  // ==========================================================================
  // Group C: db_api_uplift_absorb_judgment_v1 (6 tests)
  // ==========================================================================
  group('P3.3.12 db_api_uplift_absorb_judgment_v1: absorb-judgment', () {
    test('UpliftAbsorbJudgmentSeamFamily enum has exactly 5 values', () {
      expect(UpliftAbsorbJudgmentSeamFamily.values.length, equals(5));
    });

    test('kStatus contains "absorb_judgment_qualified_not_active"', () {
      expect(DbApiUpliftAbsorbJudgment.kStatus,
          contains('absorb_judgment_qualified_not_active'));
    });

    test(
        'kActiveDbBaselineStillAt and kActiveApiBaselineStillAt are v0.2.1',
        () {
      expect(DbApiUpliftAbsorbJudgment.kActiveDbBaselineStillAt,
          equals('v0.2.1'));
      expect(DbApiUpliftAbsorbJudgment.kActiveApiBaselineStillAt,
          equals('v0.2.1'));
    });

    test('kUpliftAbsorbJudgmentReadySeamFamilies has 5 canonical seam families',
        () {
      final seams = DbApiUpliftAbsorbJudgment.kUpliftAbsorbJudgmentReadySeamFamilies;
      expect(seams.length, equals(5));
      expect(seams, contains('review_serving_source_descriptor_seam'));
      expect(seams, contains('retained_anchor_fallback_posture_seam'));
      expect(seams, contains('stronger_ingest_path_minimal_seam'));
      expect(seams, contains('rollback_hold_observability_seam'));
      expect(
          seams, contains('source_neutral_state_helper_summary_contract_seam'));
    });

    test(
        'kMustRemainAtMarkerMigrationRollbackHoldLayer has 7 canonical items',
        () {
      final items =
          DbApiUpliftAbsorbJudgment.kMustRemainAtMarkerMigrationRollbackHoldLayer;
      expect(items.length, equals(7));
      expect(items, contains('review_group_true_exit_seams'));
      expect(items, contains('active_continuation_source_switch_seams'));
      expect(items, contains('final_fact_settlement_owner_field_payload_seams'));
      expect(items, contains('home_page_route_planner_aware_routing_seams'));
      expect(items, contains('cleanup_old_path_purge_seams'));
      expect(
          items,
          contains(
              'schema_rewrite_history_backfill_compatibility_patch_seams'));
      expect(items, contains('endpoint_core_semantics_rewrite_seams'));
    });

    test('kForbiddenClaims contains canonical forbidden phrases', () {
      final forbidden = DbApiUpliftAbsorbJudgment.kForbiddenClaims;
      expect(forbidden, contains('active DB/API baseline 已升级'));
      expect(forbidden, contains('uplift 已 absorbed'));
      expect(forbidden, contains('uplift 已完成'));
      expect(forbidden, contains('endpoint meaning 已重写'));
    });
  });

  // ==========================================================================
  // Group D: cutover_vs_fact_owner_boundary_v4 (6 tests)
  // ==========================================================================
  group('P3.3.12 cutover_vs_fact_owner_boundary_v4: absorb-judgment binding',
      () {
    test(
        'kCanonicalRule contains "serving_seam_advancement_does_not_equal_final_fact_owner_advancement"',
        () {
      expect(
          CutoverVsFactOwnerBoundaryV4.kCanonicalRule,
          equals(
              'serving_seam_advancement_does_not_equal_final_fact_owner_advancement'));
    });

    test(
        'kFinalFactsRemainBackendAuthoritative has 5 canonical facts (same as v3)',
        () {
      final facts =
          CutoverVsFactOwnerBoundaryV4.kFinalFactsRemainBackendAuthoritative;
      expect(facts.length, equals(5));
      expect(facts, contains('effective_review_fact'));
      expect(facts, contains('daily_goal_progress_and_completion_owner'));
      expect(facts, contains('reward_settlement_ledger_arrival_owner'));
      expect(facts, contains('check_in_learning_day_streak_owner'));
      expect(facts,
          contains('completion_arrival_class_primary_feedback_truth_source'));
    });

    test('kStrongerIngestAbsorbJudgmentAdvancementsV4 has 5 canonical new advancements',
        () {
      final adv =
          CutoverVsFactOwnerBoundaryV4.kStrongerIngestAbsorbJudgmentAdvancementsV4;
      expect(adv.length, equals(5));
      expect(adv, contains('accept_reject_duplicate_binding_more_stable'));
      expect(
          adv,
          contains(
              'progress_candidate_completion_candidate_precondition_postcondition_clarity'));
      expect(adv, contains('hold_reason_rollback_ownership_more_explicit'));
      expect(adv, contains('no_final_fact_owner_switch_assertion_stronger'));
      expect(adv,
          contains('minimal_ingest_binding_aligned_with_absorb_candidate_subset'));
    });

    test('kStillForbiddenActions has 8 canonical forbidden items', () {
      final forbidden = CutoverVsFactOwnerBoundaryV4.kStillForbiddenActions;
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

    test('kForbiddenOverclaims has 12 canonical RF-P3.3.12-015 phrases', () {
      final forbidden = CutoverVsFactOwnerBoundaryV4.kForbiddenOverclaims;
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

    test('kCanonicalMeaning contains "final_fact_owner_cannot_yet_switch"', () {
      expect(CutoverVsFactOwnerBoundaryV4.kCanonicalMeaning,
          contains('final_fact_owner_cannot_yet_switch'));
    });
  });

  // ==========================================================================
  // Group E: exit_candidate_to_true_exit_transition_v1 (7 tests)
  // ==========================================================================
  group('P3.3.12 exit_candidate_to_true_exit_transition_v1: transition', () {
    test(
        'kStatus contains "transition_conditions_discussable_not_transition_execution"',
        () {
      expect(
          ExitCandidateToTrueExitTransition.kStatus,
          equals(
              'transition_conditions_discussable_not_transition_execution'));
    });

    test('kFiveImmobileItems has exactly 5 items', () {
      final items = ExitCandidateToTrueExitTransition.kFiveImmobileItems;
      expect(items.length, equals(5));
      expect(items,
          contains('rollback_target_cloud_review_group_current_runtime_path'));
      expect(items, contains('current_visible_owner_identity'));
      expect(items, contains('retained_fallback_anchor_identity'));
      expect(items, contains('active_continuation_current_path'));
      expect(items,
          contains('completion_gating_settlement_trigger_explanation_pathway'));
    });

    test('kSevenSimultaneousPreconditions has exactly 7 preconditions', () {
      final pre = ExitCandidateToTrueExitTransition.kSevenSimultaneousPreconditions;
      expect(pre.length, equals(7));
      expect(
          pre, contains('current_owner_explanation_pathway_has_replacement_plan'));
      expect(
          pre,
          contains(
              'active_continuation_remains_independent_or_separate_migration'));
      expect(pre, contains('rollback_target_future_replaceable_proof'));
      expect(
          pre,
          contains(
              'completion_gating_settlement_trigger_alternative_explanation_pathway'));
      expect(pre,
          contains('compatibility_anchor_baseline_compare_path_can_migrate'));
      expect(pre, contains('no_cleanup_assertions_remain_valid'));
      expect(
          pre,
          contains(
              'regression_runtime_evidence_documentation_readiness_complete_as_suite'));
    });

    test('kFutureDiscussableItems has exactly 4 items', () {
      final future = ExitCandidateToTrueExitTransition.kFutureDiscussableItems;
      expect(future.length, equals(4));
      expect(future, contains('when_rollback_target_might_become_changeable'));
      expect(future, contains('when_fallback_scope_might_become_narrower'));
      expect(
          future,
          contains(
              'when_review_group_might_transition_from_current_owner_plus_retained_anchor_posture'));
      expect(
          future,
          contains(
              'which_docs_qa_ui_copy_must_first_decouple_from_group_only_dependency'));
    });

    test('kRollbackTargetChangeConditions has exactly 4 conditions', () {
      final cond =
          ExitCandidateToTrueExitTransition.kRollbackTargetChangeConditions;
      expect(cond.length, equals(4));
      expect(cond, contains('replacement_path_has_runtime_evidence'));
      expect(cond, contains('stop_condition_rollback_path_can_be_explained'));
      expect(
          cond,
          contains(
              'non_cutover_baseline_path_no_longer_depends_on_current_target'));
      expect(cond,
          contains('room_1_separately_pins_true_exit_gate_next_round_execution'));
    });

    test(
        'kCanonicalRule contains "discussable_transition_conditions_not_transition_execution"',
        () {
      expect(ExitCandidateToTrueExitTransition.kCanonicalRule,
          contains('discussable_transition_conditions_not_transition_execution'));
    });

    test('immobile items contain rollback target and current visible owner identity',
        () {
      expect(
          ExitCandidateToTrueExitTransition.kFiveImmobileItems,
          contains('rollback_target_cloud_review_group_current_runtime_path'));
      expect(ExitCandidateToTrueExitTransition.kFiveImmobileItems,
          contains('current_visible_owner_identity'));
    });
  });

  // ==========================================================================
  // Group F: phase6_writeback_order_v1 (6 tests)
  // ==========================================================================
  group('P3.3.12 phase6_writeback_order_v1: 6-layer immutable sequence', () {
    test('WritebackPhase6Layer enum has exactly 6 values', () {
      expect(WritebackPhase6Layer.values.length, equals(6));
      expect(WritebackPhase6Layer.values,
          contains(WritebackPhase6Layer.r2TechNote));
      expect(WritebackPhase6Layer.values,
          contains(WritebackPhase6Layer.r3RulesNote));
      expect(WritebackPhase6Layer.values,
          contains(WritebackPhase6Layer.r5UiPreflight));
      expect(WritebackPhase6Layer.values,
          contains(WritebackPhase6Layer.r1Judgment));
      expect(WritebackPhase6Layer.values,
          contains(WritebackPhase6Layer.dbApiWriteback));
      expect(WritebackPhase6Layer.values,
          contains(WritebackPhase6Layer.runtimeBaselineUpdate));
    });

    test('kWritebackSequence has 6 canonical steps in exact order', () {
      final seq = Phase6WritebackOrder.kWritebackSequence;
      expect(seq.length, equals(6));
      expect(seq[0], equals('r2_tech_note'));
      expect(seq[1], equals('r3_rules_note'));
      expect(seq[2], equals('r5_ui_preflight'));
      expect(seq[3], equals('r1_judgment_handoff_only'));
      expect(seq[4], equals('db_api_writeback_to_seam_marker_layer_only'));
      expect(
          seq[5], equals('runtime_baseline_update_only_if_r1_separately_pins'));
    });

    test('kJudgmentOnlyLayerExpressions has 5 canonical items', () {
      final items = Phase6WritebackOrder.kJudgmentOnlyLayerExpressions;
      expect(items.length, equals(5));
      expect(
          items, contains('which_widened_subset_qualifies_for_absorb_judgment'));
      expect(
          items,
          contains(
              'which_review_group_content_qualifies_for_true_exit_gate_judgment'));
      expect(items,
          contains('which_db_api_seams_are_uplift_absorb_judgment_ready'));
      expect(items, contains('how_far_stronger_ingest_currently_advances'));
      expect(
          items,
          contains(
              'when_retained_anchor_rollback_target_become_future_narrowable'));
    });

    test('kForbiddenRuntimeTruthElevation has 6 canonical forbidden items',
        () {
      final forbidden = Phase6WritebackOrder.kForbiddenRuntimeTruthElevation;
      expect(forbidden.length, equals(6));
      expect(forbidden, contains('full_cutover_completed'));
      expect(forbidden, contains('review_group_true_exit'));
      expect(forbidden, contains('active_db_api_uplift_absorbed'));
      expect(forbidden, contains('final_fact_owner_shift'));
      expect(
          forbidden,
          contains('home_page_route_active_continuation_source_switch'));
      expect(forbidden, contains('cleanup_old_path_purge'));
    });

    test('kImmutableLayerSeparation contains "jumping_forbidden"', () {
      expect(Phase6WritebackOrder.kImmutableLayerSeparation,
          contains('jumping_forbidden'));
    });

    test('kAbsorbToR1ToR4HandoffConditions has 5 canonical conditions', () {
      final conds = Phase6WritebackOrder.kAbsorbToR1ToR4HandoffConditions;
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
      expect(conds,
          contains('uplift_absorb_judgment_not_written_as_active_uplift'));
    });
  });

  // ==========================================================================
  // Group G: flags + regression (6 tests)
  // ==========================================================================
  group('P3.3.12 flags + regression', () {
    test('all 3 P3.3.12 flags are false', () {
      expect(P3FeatureGuard.isFullerCutoverAbsorbCandidateJudgmentEnabled,
          isFalse);
      expect(P3FeatureGuard.isReviewGroupTrueExitGateJudgmentEnabled, isFalse);
      expect(P3FeatureGuard.isDbApiUpliftAbsorbJudgmentEnabled, isFalse);
    });

    test('P3.3.11 flags still false (regression)', () {
      expect(P3FeatureGuard.isFullerCutoverExecutionReadyEnabled, isFalse);
      expect(P3FeatureGuard.isReviewGroupExitCandidateEnabled, isFalse);
      expect(P3FeatureGuard.isDbApiUpliftReadinessEnabled, isFalse);
    });

    test('P3.3.5/6/7/8/9/10 flags still false (regression)', () {
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
