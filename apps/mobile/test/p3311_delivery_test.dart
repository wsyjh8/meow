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
// P3.3.11 — Fuller-Cutover Execution / review_group Exit-Candidate /
// DB-API Uplift-Readiness Delivery Tests
//
// Six frozen contracts under test:
//   1. fuller_cutover_execution_subset_v1 (promotes P3.3.10 judgment)
//   2. review_group_exit_candidate_v1 (promotes P3.3.10 exit-gate v2)
//   3. db_api_uplift_readiness_v1 (promotes P3.3.10 uplift judgment)
//   4. cutover_vs_fact_owner_boundary_v3 (extends P3.3.10 v2)
//   5. retained_anchor_narrowing_guardrail_v1 (NEW)
//   6. phase5_writeback_order_v1 (NEW)
//
// Like P3.3.10, this round is PURE ANCHOR WORK — no runtime files are
// modified. All tests are markerContractOnly except one
// runtimeTruthRegression widget test in Group G.
// ============================================================================

void main() {
  // ==========================================================================
  // Group A: fuller_cutover_execution_subset_v1 (6 tests)
  // ==========================================================================
  group('P3.3.11 fuller_cutover_execution_subset_v1: execution-ready', () {
    test('ExecutionReadyLayer enum has exactly 5 values', () {
      expect(ExecutionReadyLayer.values.length, equals(5));
    });

    test('kAllowedLayers contains all 5 canonical execution-ready items', () {
      final layers = FullerCutoverExecutionSubset.kAllowedLayers;
      expect(layers.length, equals(5));
      expect(layers,
          contains('reviewpage_wider_serving_adapter_family_execution_ready'));
      expect(
          layers,
          contains(
              'first_page_review_helper_no_review_state_retained_anchor_aware_prep'));
      expect(layers,
          contains('rollback_hold_fallback_neutral_contract_execution_ready'));
      expect(layers,
          contains('stronger_ingest_candidate_execution_ready_binding_prep'));
      expect(
          layers,
          contains(
              'continuity_adjacent_helper_seam_no_active_continuation_switch'));
    });

    test('kForbiddenExpansions contains 8 canonical forbidden items', () {
      final forbidden = FullerCutoverExecutionSubset.kForbiddenExpansions;
      expect(forbidden.length, greaterThanOrEqualTo(8));
      expect(forbidden, contains('home_page_default_route_switch'));
      expect(forbidden, contains('active_continuation_source_switch'));
      expect(forbidden, contains('review_group_true_exit'));
      expect(forbidden, contains('final_fact_owner_shift'));
      expect(forbidden, contains('active_db_api_baseline_uplift_absorbed'));
      expect(forbidden, contains('cleanup_old_path_purge'));
      expect(forbidden, contains('auto_routing_runtime'));
      expect(forbidden, contains('user_visible_new_main_path_active_claim'));
    });

    test('kSemanticBoundary contains preflight_complete_not_production_active',
        () {
      expect(FullerCutoverExecutionSubset.kSemanticBoundary,
          contains('execution_ready_preflight_complete_not_production_active'));
    });

    test('stage progression: previous p3.3.10 judgment → current execution-ready',
        () {
      expect(FullerCutoverExecutionSubset.kPreviousStage,
          equals('p3_3_10_judgment_level'));
      expect(FullerCutoverExecutionSubset.kCurrentStage,
          contains('execution_ready_candidate'));
    });

    test('allowed layers and forbidden expansions do not overlap', () {
      for (final layer in FullerCutoverExecutionSubset.kAllowedLayers) {
        expect(FullerCutoverExecutionSubset.kForbiddenExpansions,
            isNot(contains(layer)));
      }
    });
  });

  // ==========================================================================
  // Group B: review_group_exit_candidate_v1 (6 tests)
  // ==========================================================================
  group('P3.3.11 review_group_exit_candidate_v1: qualified status', () {
    test('ExitCandidateClass enum has exactly 5 values', () {
      expect(ExitCandidateClass.values.length, equals(5));
      expect(ExitCandidateClass.values,
          contains(ExitCandidateClass.dependencyInventory));
      expect(ExitCandidateClass.values,
          contains(ExitCandidateClass.replacementReadinessMarker));
      expect(
          ExitCandidateClass.values,
          contains(
              ExitCandidateClass.retainedAnchorToExitCandidateConditions));
      expect(ExitCandidateClass.values,
          contains(ExitCandidateClass.fallbackScopeJudgment));
      expect(ExitCandidateClass.values,
          contains(ExitCandidateClass.noOverclaimNoCleanupAssertions));
    });

    test('kStatus contains "exit_candidate_qualified_not_true_exit"', () {
      expect(ReviewGroupExitCandidate.kStatus,
          contains('exit_candidate_qualified_not_true_exit'));
      // Anti-pattern
      expect(ReviewGroupExitCandidate.kStatus, isNot(contains('has_exited')));
      expect(ReviewGroupExitCandidate.kStatus, isNot(contains('retired')));
    });

    test('kFourLayersMustContinue has exactly 4 canonical roles', () {
      final layers = ReviewGroupExitCandidate.kFourLayersMustContinue;
      expect(layers.length, equals(4));
      expect(layers, contains('current_runtime_serving_owner'));
      expect(layers, contains('retained_fallback_anchor'));
      expect(layers, contains('compatibility_anchor'));
      expect(layers, contains('deprecated_candidate'));
    });

    test('kPathsStillDependingOnReviewGroup has 7 canonical paths', () {
      final paths = ReviewGroupExitCandidate.kPathsStillDependingOnReviewGroup;
      expect(paths.length, equals(7));
      expect(paths, contains('active_continuation_identity'));
      expect(paths, contains('current_completion_gating'));
      expect(paths, contains('current_settlement_trigger'));
      expect(paths, contains('rollback_target'));
      expect(paths, contains('baseline_compare_compatibility_anchor'));
      expect(paths, contains('widened_subset_failure_fallback_path'));
      expect(paths, contains('user_visible_main_queue_ultimate_fallback'));
    });

    test('kForbiddenClaims contains new P3.3.11 phrases', () {
      final forbidden = ReviewGroupExitCandidate.kForbiddenClaims;
      expect(forbidden, contains('review_group 已退场'));
      expect(forbidden, contains('true exit 已开始'));
      expect(forbidden, contains('现在已经可以清理旧 path'));
      expect(forbidden, contains('retained anchor 已不再需要'));
    });

    test(
        'P3.3.10 regression: ReviewGroupExitGateV2.kGateStatus still intact',
        () {
      expect(ReviewGroupExitGateV2.kGateStatus,
          contains('v2_prerequisites_not_yet_met'));
    });
  });

  // ==========================================================================
  // Group C: db_api_uplift_readiness_v1 (6 tests)
  // ==========================================================================
  group('P3.3.11 db_api_uplift_readiness_v1: readiness candidate', () {
    test('UpliftReadinessSeamFamily enum has exactly 5 values', () {
      expect(UpliftReadinessSeamFamily.values.length, equals(5));
      expect(
          UpliftReadinessSeamFamily.values,
          contains(
              UpliftReadinessSeamFamily.reviewServingSourceDescriptorSeam));
      expect(
          UpliftReadinessSeamFamily.values,
          contains(
              UpliftReadinessSeamFamily.retainedAnchorFallbackPostureSeam));
      expect(UpliftReadinessSeamFamily.values,
          contains(UpliftReadinessSeamFamily.strongerIngestPathMinimalSeam));
      expect(UpliftReadinessSeamFamily.values,
          contains(UpliftReadinessSeamFamily.rollbackHoldObservabilitySeam));
      expect(
          UpliftReadinessSeamFamily.values,
          contains(UpliftReadinessSeamFamily
              .sourceNeutralStateHelperSummaryContractSeam));
    });

    test('kStatus contains "uplift_readiness_qualified_not_active"', () {
      expect(DbApiUpliftReadiness.kStatus,
          contains('uplift_readiness_qualified_not_active'));
    });

    test('kActiveDbBaselineStillAt and kActiveApiBaselineStillAt are v0.2.1',
        () {
      expect(
          DbApiUpliftReadiness.kActiveDbBaselineStillAt, equals('v0.2.1'));
      expect(
          DbApiUpliftReadiness.kActiveApiBaselineStillAt, equals('v0.2.1'));
    });

    test('kUpliftReadinessSeamFamilies has 5 canonical seam families', () {
      final seams = DbApiUpliftReadiness.kUpliftReadinessSeamFamilies;
      expect(seams.length, equals(5));
      expect(seams, contains('review_serving_source_descriptor_seam'));
      expect(seams, contains('retained_anchor_fallback_posture_seam'));
      expect(seams, contains('stronger_ingest_path_minimal_seam'));
      expect(seams, contains('rollback_hold_observability_seam'));
      expect(
          seams, contains('source_neutral_state_helper_summary_contract_seam'));
    });

    test('kMustRemainAtMigrationHoldRollbackLevel contains canonical items',
        () {
      final items = DbApiUpliftReadiness.kMustRemainAtMigrationHoldRollbackLevel;
      expect(items, contains('db_schema_rewrite'));
      expect(items, contains('api_endpoint_core_semantics_rewrite'));
      expect(items, contains('final_fact_settlement_owner_fields'));
      expect(items, contains('home_page_route_auto_routing_result_fields'));
      expect(items, contains('review_group_exited_old_path_purge_indicators'));
      expect(items, contains('active_baseline_declarations'));
      expect(items, contains('cleanup_bundle_old_path_deletion_markers'));
    });

    test('kMustNotEnterActiveBaseline contains canonical items', () {
      final items = DbApiUpliftReadiness.kMustNotEnterActiveBaseline;
      expect(
          items,
          contains(
              'data_migration_history_refill_compatibility_patch_schema_moves'));
      expect(
          items,
          contains(
              'api_core_purpose_request_return_parameter_semantic_changes'));
      expect(
          items,
          contains(
              'any_field_copy_misleading_ui_br_test_into_thinking_uplift_absorbed'));
      expect(
          items,
          contains(
              'local_serving_stronger_ingest_miswritten_as_final_fact_owner'));
      expect(items, contains('review_group_runtime_exit_declarations'));
    });
  });

  // ==========================================================================
  // Group D: cutover_vs_fact_owner_boundary_v3 (6 tests)
  // ==========================================================================
  group('P3.3.11 cutover_vs_fact_owner_boundary_v3: execution-ready binding',
      () {
    test('kCanonicalRule contains final_fact_owner_must_remain_backend', () {
      expect(CutoverVsFactOwnerBoundaryV3.kCanonicalRule,
          contains('final_fact_owner_must_remain_backend'));
      expect(CutoverVsFactOwnerBoundaryV3.kCanonicalRule,
          contains('stronger_ingest_binding_may_solidify'));
      expect(CutoverVsFactOwnerBoundaryV3.kCanonicalRule,
          contains('serving_seam_may_widen'));
    });

    test('kFinalFactsRemainBackendAuthoritative has all 5 canonical facts',
        () {
      final facts =
          CutoverVsFactOwnerBoundaryV3.kFinalFactsRemainBackendAuthoritative;
      expect(facts.length, equals(5));
      expect(facts, contains('effective_review_final_fact'));
      expect(facts, contains('daily_goal_progress_and_completion_owner'));
      expect(facts, contains('reward_settlement_ledger_arrival_owner'));
      expect(facts, contains('check_in_learning_day_streak_owner'));
      expect(facts, contains('completion_arrival_main_feedback_final_truth_source'));
    });

    test('kStrongerIngestExecutionReadyBindingV3 has 5 canonical new advancements',
        () {
      final adv =
          CutoverVsFactOwnerBoundaryV3.kStrongerIngestExecutionReadyBindingV3;
      expect(adv.length, equals(5));
      expect(adv, contains('accept_reject_duplicate_binding_more_solid'));
      expect(
          adv,
          contains(
              'progress_candidate_completion_candidate_preconditions_postconditions_clearer'));
      expect(adv, contains('hold_reason_rollback_ownership_more_explicit'));
      expect(adv,
          contains('no_final_fact_owner_switch_assertion_more_stable'));
      expect(adv,
          contains('minimal_ingest_binding_aligned_with_widened_serving_subset'));
    });

    test('kStillForbiddenActions contains NEW v3 items', () {
      final forbidden = CutoverVsFactOwnerBoundaryV3.kStillForbiddenActions;
      expect(forbidden,
          contains('stronger_ingest_elevation_to_final_fact_write'));
      expect(forbidden, contains('completion_determined_by_local_stronger_path'));
      expect(forbidden, contains('today_goal_auto_advanced_via_new_seam'));
    });

    test('kForbiddenOverclaims contains ALL 6 NEW RF-P3.3.11-013 phrases',
        () {
      final forbidden = CutoverVsFactOwnerBoundaryV3.kForbiddenOverclaims;
      // NEW in v3 (RF-P3.3.11-013):
      expect(forbidden, contains('本地已确认完成'));
      expect(forbidden, contains('奖励已到账'));
      expect(forbidden, contains('今日目标已达成'));
      expect(forbidden, contains('连续学习已更新'));
      expect(forbidden, contains('复习事实已切到本地'));
      expect(forbidden, contains('新主链路已生效'));
      // Carryover from v2:
      expect(forbidden, contains('本地结果已写回最终事实'));
      expect(forbidden, contains('本地已直接记为有效复习'));
    });

    test('kCanonicalMeaning contains final_fact_owner_cannot_yet_switch', () {
      expect(CutoverVsFactOwnerBoundaryV3.kCanonicalMeaning,
          contains('final_fact_owner_cannot_yet_switch'));
    });
  });

  // ==========================================================================
  // Group E: retained_anchor_narrowing_guardrail_v1 (6 tests)
  // ==========================================================================
  group('P3.3.11 retained_anchor_narrowing_guardrail_v1: can/cannot narrow',
      () {
    test('kCanNarrowVeryNarrowly has exactly 5 canonical items', () {
      final can = RetainedAnchorNarrowingGuardrail.kCanNarrowVeryNarrowly;
      expect(can.length, equals(5));
      expect(can,
          contains('source_neutral_helper_summary_group_only_wording_coupling'));
      expect(
          can,
          contains(
              'first_page_review_helper_empty_state_no_review_state_retained_anchor_aware_rewrite'));
      expect(can,
          contains('rollback_fallback_explanation_historical_redundancy_removal'));
      expect(
          can,
          contains(
              'marker_posture_documentation_ui_docs_expression_layer_optimization'));
      expect(can,
          contains('future_narrowable_rollback_bucket_judgment_assessment'));
    });

    test('kCannotNarrow has exactly 7 canonical items', () {
      final cannot = RetainedAnchorNarrowingGuardrail.kCannotNarrow;
      expect(cannot.length, equals(7));
      expect(cannot,
          contains('rollback_target_cloud_review_group_current_runtime_path'));
      expect(cannot, contains('current_runtime_serving_owner_identity'));
      expect(cannot, contains('active_continuation_identity'));
      expect(cannot, contains('current_completion_gating'));
      expect(cannot, contains('current_settlement_trigger'));
      expect(cannot, contains('compatibility_anchor'));
      expect(cannot, contains('non_cutover_baseline_path'));
    });

    test(
        'kCannotNarrow always contains rollback_target (same as P3.3.9/P3.3.10)',
        () {
      expect(RetainedAnchorNarrowingGuardrail.kCannotNarrow,
          contains('rollback_target_cloud_review_group_current_runtime_path'));
    });

    test('kStopConditions has exactly 7 canonical triggers', () {
      final stops = RetainedAnchorNarrowingGuardrail.kStopConditions;
      expect(stops.length, equals(7));
      expect(stops, contains('active_continuation_mistakenly_cut_to_local_path'));
      expect(stops,
          contains('local_subset_written_as_current_reviewpage_full_truth'));
      expect(
          stops,
          contains(
              'local_evidence_directly_changes_final_ledger_daily_goal_streak_settlement'));
      expect(stops,
          contains('home_page_route_changed_to_planner_aware_auto_routing'));
      expect(
          stops, contains('user_visible_cutover_owner_shift_exit_uplift_overclaim'));
      expect(stops, contains('db_schema_api_core_semantics_change_required'));
      expect(stops, contains('rollback_path_nonexistent_unverifiable_unexplainable'));
    });

    test('kSemanticBoundary contains explanation_layer_helper_scope_may_narrow',
        () {
      expect(RetainedAnchorNarrowingGuardrail.kSemanticBoundary,
          contains('explanation_layer_helper_scope_may_narrow'));
      expect(
          RetainedAnchorNarrowingGuardrail.kSemanticBoundary,
          contains(
              'owner_identity_rollback_target_completion_gating_settlement_trigger_cannot'));
    });

    test('can-narrow and cannot-narrow lists do not overlap', () {
      for (final item in RetainedAnchorNarrowingGuardrail.kCanNarrowVeryNarrowly) {
        expect(RetainedAnchorNarrowingGuardrail.kCannotNarrow,
            isNot(contains(item)));
      }
    });
  });

  // ==========================================================================
  // Group F: phase5_writeback_order_v1 (6 tests)
  // ==========================================================================
  group('P3.3.11 phase5_writeback_order_v1: 4-layer immutable order', () {
    test('WritebackLayer enum has exactly 4 values (preflight/candidate/handoff/runtime)',
        () {
      expect(WritebackLayer.values.length, equals(4));
      expect(WritebackLayer.values, contains(WritebackLayer.preflight));
      expect(WritebackLayer.values, contains(WritebackLayer.candidate));
      expect(WritebackLayer.values, contains(WritebackLayer.handoff));
      expect(WritebackLayer.values, contains(WritebackLayer.runtime));
    });

    test('kWritebackSequence has 6 canonical steps in exact order', () {
      final seq = Phase5WritebackOrder.kWritebackSequence;
      expect(seq.length, equals(6));
      expect(seq[0], equals('r2_tech_note'));
      expect(seq[1], equals('r3_rules_note'));
      expect(seq[2], equals('r5_ui_preflight'));
      expect(seq[3], equals('r1_absorb_pin_judgment'));
      expect(seq[4],
          equals('db_api_writeback_to_uplift_readiness_candidate_layer_only'));
      expect(seq[5], equals('runtime_baseline_update_only_if_r1_separately_pins'));
    });

    test('kImmutableLayerOrder has 4 layers in canonical order', () {
      final order = Phase5WritebackOrder.kImmutableLayerOrder;
      expect(order.length, equals(4));
      expect(order[0], equals('layer_1_preflight_absorb'));
      expect(order[1], equals('layer_2_execution_ready_candidate_absorb'));
      expect(order[2],
          equals('layer_3_room_1_to_room_4_execution_handoff_absorb'));
      expect(order[3], equals('layer_4_runtime_truth_absorb'));
    });

    test('kMayBeWrittenAsCandidate has 5 canonical items', () {
      final items = Phase5WritebackOrder.kMayBeWrittenAsCandidate;
      expect(items.length, equals(5));
      expect(items, contains('widened_subset_cutover_layers'));
      expect(items, contains('review_group_exit_candidate_content_scope'));
      expect(items, contains('db_api_seams_at_uplift_readiness'));
      expect(items, contains('stronger_ingest_binding_current_max_layer'));
      expect(items, contains('retained_anchor_narrowable_ranges'));
    });

    test('kCannotBeUpgradedToRuntimeTruth contains canonical forbidden upgrades',
        () {
      final cannot = Phase5WritebackOrder.kCannotBeUpgradedToRuntimeTruth;
      expect(cannot, contains('full_cutover_completed'));
      expect(cannot, contains('review_group_true_exit'));
      expect(cannot, contains('active_db_api_uplift_absorbed'));
      expect(cannot, contains('final_fact_owner_shift'));
      expect(
          cannot,
          contains('home_page_route_or_active_continuation_source_switch'));
      expect(cannot, contains('cleanup_old_path_purge'));
    });

    test('kImmutableOrderingRule contains no_upward_skipping_allowed', () {
      expect(Phase5WritebackOrder.kImmutableOrderingRule,
          contains('no_upward_skipping_allowed'));
      expect(Phase5WritebackOrder.kImmutableOrderingRule,
          contains('preflight_to_candidate_to_execution_to_runtime'));
    });
  });

  // ==========================================================================
  // Group G: flags + regression (6 tests)
  // ==========================================================================
  group('P3.3.11 flags + regression', () {
    test('all 3 P3.3.11 flags are false', () {
      expect(P3FeatureGuard.isFullerCutoverExecutionReadyEnabled, isFalse);
      expect(P3FeatureGuard.isReviewGroupExitCandidateEnabled, isFalse);
      expect(P3FeatureGuard.isDbApiUpliftReadinessEnabled, isFalse);
    });

    test('P3.3.10 flags still false (regression)', () {
      expect(P3FeatureGuard.isFullerCutoverJudgmentCandidateEnabled, isFalse);
      expect(P3FeatureGuard.isReviewGroupExitGateJudgmentV2Enabled, isFalse);
      expect(P3FeatureGuard.isDbApiUpliftJudgmentEnabled, isFalse);
    });

    test('P3.3.5/6/7/8/9 flags still false (regression)', () {
      expect(P3FeatureGuard.isLocalServingShadowRunEnabled, isFalse);
      expect(P3FeatureGuard.isParityCheckRecordingEnabled, isFalse);
      expect(P3FeatureGuard.isFactIngestShadowEvaluationEnabled, isFalse);
      expect(P3FeatureGuard.isRoutingShadowComputationEnabled, isFalse);
      expect(P3FeatureGuard.isPhase3GateEvaluationEnabled, isFalse);
      expect(P3FeatureGuard.isLimitedCutoverExecutionEnabled, isFalse);
      expect(P3FeatureGuard.isDbApiCandidateMigrationEnabled, isFalse);
      expect(P3FeatureGuard.isReviewPageNonContinuationCutoverEnabled, isTrue); // P3.3.16 flipped
      expect(P3FeatureGuard.isStrongerIngestCandidatePathEnabled, isFalse);
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
      // Rollback target unchanged
      expect(ReviewServingSeam.kRollbackTarget,
          equals('cloud_review_group_current_runtime_path'));
    });
  });
}
