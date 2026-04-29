import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/gate/cutover_subset.dart';
import 'package:meow_mobile/core/gate/db_api_uplift.dart';
import 'package:meow_mobile/core/gate/fact_owner_boundary.dart';
import 'package:meow_mobile/core/gate/review_group_lifecycle.dart';
import 'package:meow_mobile/core/gate/round_gates_and_guardrails.dart';
import 'package:meow_mobile/core/gate/writeback_order.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/serving/home_review_helper_summary.dart';
import 'package:meow_mobile/core/serving/review_serving_adapter_family.dart';
import 'package:meow_mobile/core/serving/review_serving_seam.dart';
import 'package:meow_mobile/core/serving/rollback_hold_fallback_orchestration.dart';
import 'package:meow_mobile/core/serving/source_neutral_helper_copy.dart';
import 'package:meow_mobile/core/serving/stronger_ingest_minimal_binding_seam.dart';

// ============================================================================
// P3.3.14 - Final Cutover Program Round Delivery Tests (A / B / C)
//
// Six frozen contracts under test (all A checkpoint):
//   1. final_cutover_judgment_lock_v1        (A master lock)
//   2. real_cutover_execution_subset_v1      (B execution subset)
//   3. true_exit_absorb_gate_v1              (promotes P3.3.13 candidate)
//   4. db_api_uplift_absorb_gate_v1          (promotes P3.3.13 readiness)
//   5. fact_owner_cutover_guardrail_v1       (cross-cutting fact guardrail)
//   6. same_round_cleanup_gate_v1            (C entry gate)
//
// Plus B-checkpoint narrow real execution regression tests and full-round
// must-hold regression over prior rounds.
// ============================================================================

void main() {
  // ==========================================================================
  // Group A1: final_cutover_judgment_lock_v1 (A checkpoint master lock)
  // ==========================================================================
  group('P3.3.14 final_cutover_judgment_lock_v1: A checkpoint master lock',
      () {
    test('FinalCutoverJudgmentLockGroup enum has exactly 6 values', () {
      expect(FinalCutoverJudgmentLockGroup.values.length, equals(6));
    });

    test('kStatus pins A checkpoint judgment lock not runtime truth', () {
      expect(FinalCutoverJudgmentLock.kStatus,
          contains('a_checkpoint_final_judgment_lock_pinned'));
      expect(FinalCutoverJudgmentLock.kStatus,
          contains('not_runtime_truth_advanced'));
    });

    test('kSixHardPreconditionGroups has 6 canonical groups', () {
      const g = FinalCutoverJudgmentLock.kSixHardPreconditionGroups;
      expect(g.length, equals(6));
      expect(g, contains('runtime_truth_immovables'));
      expect(g, contains('rollback_immovables'));
      expect(g, contains('true_exit_preconditions_inventory'));
      expect(g, contains('db_api_uplift_absorb_inventory'));
      expect(g, contains('fact_owner_guardrail'));
      expect(g, contains('cleanup_gating'));
    });

    test('kRuntimeTruthImmovables has 4 canonical immovables', () {
      const im = FinalCutoverJudgmentLock.kRuntimeTruthImmovables;
      expect(im.length, equals(4));
      expect(im, contains('home_word_entry_remains_study_default'));
      expect(
          im,
          contains(
              'review_page_current_visible_serving_owner_remains_cloud_review_group'));
      expect(
          im,
          contains(
              'active_continuation_current_acceptance_path_must_not_be_silently_rewritten'));
      expect(
          im,
          contains(
              'final_fact_and_settlement_owner_does_not_shift_with_serving_seam_advancement'));
    });

    test('kRollbackImmovables has 3 canonical items', () {
      const rb = FinalCutoverJudgmentLock.kRollbackImmovables;
      expect(rb.length, equals(3));
      expect(
          rb,
          contains(
              'rollback_target_remains_cloud_review_group_current_runtime_path'));
      expect(
          rb,
          contains(
              'hold_fallback_must_return_stably_to_cloud_current_runtime_path'));
      expect(
          rb,
          contains(
              'rollback_and_hold_copy_must_not_be_written_as_historical_only'));
    });

    test('kCanonicalRollbackTarget matches ReviewServingSeam.kRollbackTarget',
        () {
      expect(FinalCutoverJudgmentLock.kCanonicalRollbackTarget,
          equals('cloud_review_group_current_runtime_path'));
      expect(FinalCutoverJudgmentLock.kCanonicalRollbackTarget,
          equals(ReviewServingSeam.kRollbackTarget));
    });

    test('kStillDependentPaths has 6 canonical paths', () {
      const p = FinalCutoverJudgmentLock.kStillDependentPaths;
      expect(p.length, equals(6));
      expect(p, contains('active_continuation_identity'));
      expect(p, contains('completion_gating'));
      expect(p, contains('settlement_trigger'));
      expect(p, contains('rollback_target'));
      expect(p, contains('non_cutover_non_upgraded_sessions_baseline_path'));
      expect(p, contains('compatibility_anchor_qa_baseline_reference'));
    });

    test('kLayerSeparationAssertions has 3 distinct separations', () {
      const s = FinalCutoverJudgmentLock.kLayerSeparationAssertions;
      expect(s.length, equals(3));
      expect(s, contains('true_exit_candidate_not_equal_true_exit_started'));
      expect(s, contains('true_exit_started_not_equal_true_exit_absorbed'));
      expect(
          s,
          contains(
              'uplift_absorb_readiness_not_equal_active_baseline_uplift_absorbed'));
    });

    test('kActiveDbApiBaseline is v0.2.1', () {
      expect(FinalCutoverJudgmentLock.kActiveDbApiBaseline, equals('v0.2.1'));
    });

    test('kAPassGateConditions has 5 canonical conditions', () {
      const c = FinalCutoverJudgmentLock.kAPassGateConditions;
      expect(c.length, equals(5));
      expect(c, contains('all_six_hard_precondition_groups_written_into_code'));
      expect(c, contains('six_still_dependent_paths_listed_explicitly'));
      expect(c, contains('thirty_two_overclaim_guardrails_in_place'));
      expect(c, contains('no_must_hold_mismatch_detected'));
      expect(c,
          contains('closeout_summary_sufficient_for_room_1_b_authorization'));
    });

    test('kForbiddenATransitions has 6 canonical forbidden transitions', () {
      const f = FinalCutoverJudgmentLock.kForbiddenATransitions;
      expect(f.length, equals(6));
      expect(f, contains('runtime_owner_shift_completed'));
      expect(f, contains('review_group_true_exit_started'));
      expect(f, contains('active_db_api_baseline_uplift_absorbed'));
      expect(f, contains('final_fact_owner_shift'));
      expect(f, contains('home_page_default_route_change'));
      expect(f, contains('cleanup_old_path_purge_completed'));
    });

    test('kCanonicalMeaning pins judgment layer meaning', () {
      expect(FinalCutoverJudgmentLock.kCanonicalMeaning,
          contains('pinned_not_runtime_truth_advanced'));
      expect(FinalCutoverJudgmentLock.kCanonicalMeaning,
          contains('does_not_equal_full_cutover_completed'));
    });
  });

  // ==========================================================================
  // Group A2: real_cutover_execution_subset_v1 (B execution subset)
  // ==========================================================================
  group('P3.3.14 real_cutover_execution_subset_v1: B execution subset', () {
    test('RealCutoverExecutionSubsetMember enum has exactly 5 values', () {
      expect(RealCutoverExecutionSubsetMember.values.length, equals(5));
    });

    test('kStatus pins B-checkpoint additive execution', () {
      expect(RealCutoverExecutionSubset.kStatus,
          contains('b_checkpoint_real_cutover_execution_subset_pinned'));
      expect(RealCutoverExecutionSubset.kStatus, contains('additively'));
      expect(RealCutoverExecutionSubset.kStatus,
          contains('not_full_cutover_completed'));
    });

    test('kAllowedMembers has 5 canonical members', () {
      const m = RealCutoverExecutionSubset.kAllowedMembers;
      expect(m.length, equals(5));
      expect(m,
          contains('review_page_continuity_adjacent_serving_adapter_family'));
      expect(
          m,
          contains(
              'review_page_helper_summary_empty_state_completion_pre_explanation_layer'));
      expect(
          m,
          contains(
              'home_page_review_helper_summary_no_review_state_retained_anchor_aware_layer'));
      expect(
          m, contains('rollback_hold_fallback_neutral_orchestration_layer'));
      expect(m,
          contains('stronger_ingest_absorb_readiness_minimal_binding_seam'));
    });

    test('kForbiddenBMembers has 8 canonical forbidden items', () {
      const f = RealCutoverExecutionSubset.kForbiddenBMembers;
      expect(f.length, equals(8));
      expect(f, contains('home_page_default_main_route_switch'));
      expect(f, contains('active_continuation_source_switch'));
      expect(f, contains('review_group_current_visible_owner_identity_switch'));
      expect(f, contains('final_fact_and_settlement_owner_switch'));
      expect(f, contains('db_schema_rewrite'));
      expect(f, contains('api_core_semantics_rewrite'));
      expect(f, contains('cleanup_old_path_purge'));
      expect(f, contains('user_visible_auto_routing_or_planner_aware_route'));
    });

    test('kCoDeliveredProtectionLayers has 5 canonical layers', () {
      const p = RealCutoverExecutionSubset.kCoDeliveredProtectionLayers;
      expect(p.length, equals(5));
      expect(
          p,
          contains(
              'rollback_hold_fallback_neutral_copy_and_state_contract_complete'));
      expect(p, contains('observability_evidence_capture_in_place'));
      expect(p, contains('runtime_truth_regression_passes'));
      expect(
          p, contains('stop_condition_and_hold_condition_machinery_in_place'));
      expect(p, contains('user_visible_overclaim_guardrails_in_place'));
    });

    test('kBPassGateConditions has 5 canonical conditions', () {
      const b = RealCutoverExecutionSubset.kBPassGateConditions;
      expect(b.length, equals(5));
      expect(b, contains('runtime_truth_regression_passes'));
      expect(
          b, contains('rollback_hold_observability_evidence_package_passes'));
      expect(b, contains('no_major_change_statement_continues_to_hold'));
      expect(b, contains('no_must_hold_mismatch_remaining_open'));
      expect(
          b,
          contains(
              'no_home_page_route_active_continuation_final_fact_owner_touch'));
    });

    test('kBlastRadiusConstraint pins ReviewPage + home acceptance layer', () {
      expect(RealCutoverExecutionSubset.kBlastRadiusConstraint,
          contains('review_page'));
      expect(RealCutoverExecutionSubset.kBlastRadiusConstraint,
          contains('home_page_review_acceptance_layer'));
    });

    test('kSemanticBoundary pins additive not replacement', () {
      expect(RealCutoverExecutionSubset.kSemanticBoundary,
          contains('additive_not_replacement'));
      expect(RealCutoverExecutionSubset.kSemanticBoundary,
          contains('does_not_equal_full_cutover'));
    });

    test('stage progression pins P3.3.13 to P3.3.14', () {
      expect(RealCutoverExecutionSubset.kPreviousStage,
          contains('p3_3_13_fuller_cutover_execution_subset_v2_preflight'));
      expect(RealCutoverExecutionSubset.kCurrentStage,
          contains('p3_3_14_real_cutover_execution_subset_v1_additive'));
    });
  });

  // ==========================================================================
  // Group A3: true_exit_absorb_gate_v1 (promotes P3.3.13 candidate)
  // ==========================================================================
  group('P3.3.14 true_exit_absorb_gate_v1: review_group absorb-gate', () {
    test('kStatus pins absorb-gate qualification discussion', () {
      expect(ReviewGroupTrueExitAbsorbGate.kStatus,
          contains('true_exit_absorb_gate_qualification_discussion'));
      expect(ReviewGroupTrueExitAbsorbGate.kStatus,
          contains('not_absorption_started'));
    });

    test('kFourRolesMustContinue pins 4 parallel roles', () {
      const r = ReviewGroupTrueExitAbsorbGate.kFourRolesMustContinue;
      expect(r.length, equals(4));
      expect(r, contains('current_runtime_serving_owner'));
      expect(r, contains('retained_fallback_anchor'));
      expect(r, contains('compatibility_anchor'));
      expect(r, contains('deprecated_candidate'));
    });

    test('kSixStillDependentPaths matches judgment lock paths', () {
      const p = ReviewGroupTrueExitAbsorbGate.kSixStillDependentPaths;
      expect(p.length, equals(6));
      for (final item in FinalCutoverJudgmentLock.kStillDependentPaths) {
        expect(p, contains(item));
      }
    });

    test('kSevenAbsorbGateEntryConditions has 7 canonical conditions', () {
      const c = ReviewGroupTrueExitAbsorbGate.kSevenAbsorbGateEntryConditions;
      expect(c.length, equals(7));
      expect(c, contains('active_continuation_has_stable_replacement_path'));
      expect(c, contains('completion_gating_has_clear_replacement_path'));
      expect(c, contains('settlement_trigger_has_clear_replacement_path'));
      expect(c, contains('rollback_target_has_future_safe_replacement_proof'));
      expect(
          c,
          contains(
              'non_cutover_non_upgraded_sessions_baseline_path_has_alternative_explanation'));
      expect(
          c,
          contains(
              'compatibility_anchor_qa_baseline_reference_can_be_migrated'));
      expect(
          c,
          contains(
              'br_ui_db_api_test_exit_impact_scope_already_synchronized'));
    });

    test('kSevenStopAtBConditions has 7 canonical stop conditions', () {
      const s = ReviewGroupTrueExitAbsorbGate.kSevenStopAtBConditions;
      expect(s.length, equals(7));
      expect(s, contains('current_runtime_truth_silently_altered'));
      expect(s, contains('active_continuation_switched_to_local_path'));
      expect(s, contains('review_group_true_exit_evidence_incomplete'));
      expect(s, contains('absorb_evidence_incomplete'));
      expect(s, contains('final_fact_owner_boundary_broken'));
      expect(s, contains('rollback_hold_fallback_copy_incomplete'));
      expect(
          s,
          contains(
              'user_side_overclaim_of_exited_or_absorbed_or_cleaned_up'));
    });

    test('kForbiddenClaims has 8 canonical forbidden claims', () {
      const f = ReviewGroupTrueExitAbsorbGate.kForbiddenClaims;
      expect(f.length, equals(8));
      expect(f, contains('review_group_already_exited'));
      expect(f, contains('review_group_true_exit_started'));
      expect(f, contains('rollback_target_has_changed'));
    });

    test('kSemanticBoundary pins judgment layer not execution flip', () {
      expect(ReviewGroupTrueExitAbsorbGate.kSemanticBoundary,
          contains('judgment_layer_not_execution_flip'));
    });

    test('stage progression pins P3.3.13 to P3.3.14', () {
      expect(ReviewGroupTrueExitAbsorbGate.kPreviousStage,
          contains('p3_3_13_review_group_true_exit_candidate'));
      expect(ReviewGroupTrueExitAbsorbGate.kCurrentStage,
          contains('p3_3_14_true_exit_absorb_gate_qualification_discussion'));
    });
  });

  // ==========================================================================
  // Group A4: db_api_uplift_absorb_gate_v1 (promotes P3.3.13 readiness)
  // ==========================================================================
  group('P3.3.14 db_api_uplift_absorb_gate_v1: DB/API absorb-gate', () {
    test('UpliftAbsorbGateSeamFamily enum has exactly 5 values', () {
      expect(UpliftAbsorbGateSeamFamily.values.length, equals(5));
    });

    test('kStatus pins absorb-gate qualification discussion', () {
      expect(DbApiUpliftAbsorbGate.kStatus,
          contains('uplift_absorb_gate_qualification_discussion'));
      expect(DbApiUpliftAbsorbGate.kStatus,
          contains('not_active_baseline_uplift_absorbed'));
    });

    test('kActiveDbBaselineStillAt is v0.2.1', () {
      expect(DbApiUpliftAbsorbGate.kActiveDbBaselineStillAt, equals('v0.2.1'));
    });

    test('kActiveApiBaselineStillAt is v0.2.1', () {
      expect(DbApiUpliftAbsorbGate.kActiveApiBaselineStillAt, equals('v0.2.1'));
    });

    test('kAbsorbGateReadySeamFamilies has 5 canonical families', () {
      const s = DbApiUpliftAbsorbGate.kAbsorbGateReadySeamFamilies;
      expect(s.length, equals(5));
      expect(s, contains('review_serving_source_descriptor_seam'));
      expect(s, contains('retained_anchor_fallback_posture_seam'));
      expect(s, contains('stronger_ingest_minimal_binding_seam'));
      expect(s, contains('rollback_hold_observability_seam'));
      expect(
          s, contains('source_neutral_state_helper_summary_contract_seam'));
    });

    test('kMustRemainAtMarkerMigrationRollbackHoldLayer has 7 items', () {
      const m =
          DbApiUpliftAbsorbGate.kMustRemainAtMarkerMigrationRollbackHoldLayer;
      expect(m.length, equals(7));
      expect(m, contains('db_schema_rewrite'));
      expect(m, contains('api_core_semantics_rewrite'));
      expect(m, contains('fact_ledger_structural_change'));
      expect(m, contains('settlement_pipeline_structural_change'));
      expect(m, contains('streak_learning_day_canonical_storage_change'));
      expect(m, contains('daily_goal_completion_canonical_storage_change'));
      expect(m, contains('reward_settlement_canonical_storage_change'));
    });

    test('kCAbsorptionPreEntryConditions has 3 canonical conditions', () {
      const c = DbApiUpliftAbsorbGate.kCAbsorptionPreEntryConditions;
      expect(c.length, equals(3));
      expect(c, contains('seam_family_readiness_evidence_complete'));
      expect(c, contains('marker_migration_rollback_hold_note_complete_set'));
      expect(c, contains('room_1_explicit_pin_for_absorbed_decision'));
    });

    test('kForbiddenClaims has 8 canonical forbidden claims', () {
      const f = DbApiUpliftAbsorbGate.kForbiddenClaims;
      expect(f.length, equals(8));
      expect(f, contains('active_db_api_baseline_already_uplifted'));
      expect(f, contains('uplift_already_absorbed'));
      expect(f, contains('schema_already_rewritten'));
    });

    test('kSemanticBoundary pins judgment layer + v0.2.1 baselines', () {
      expect(DbApiUpliftAbsorbGate.kSemanticBoundary,
          contains('judgment_layer_baselines_stay_v0_2_1'));
    });
  });

  // ==========================================================================
  // Group A5: fact_owner_cutover_guardrail_v1 (cross-cutting)
  // ==========================================================================
  group(
      'P3.3.14 fact_owner_cutover_guardrail_v1: cross-cutting fact guardrail',
      () {
    test('kCanonicalRule pins serving-vs-fact-owner separation', () {
      expect(
          FactOwnerCutoverGuardrail.kCanonicalRule,
          contains(
              'serving_seam_and_execution_subset_advancement_does_not_bring_final_fact_ownership_advancement'));
    });

    test('kFinalFactsRemainBackendAuthoritative has 5 canonical final facts',
        () {
      const f =
          FactOwnerCutoverGuardrail.kFinalFactsRemainBackendAuthoritative;
      expect(f.length, equals(5));
      expect(f, contains('effective_review_fact'));
      expect(f, contains('daily_goal_progress_and_completion_owner'));
      expect(f, contains('reward_settlement_ledger_arrival_owner'));
      expect(f, contains('check_in_learning_day_streak_owner'));
      expect(f,
          contains('completion_arrival_class_primary_feedback_truth_source'));
    });

    test(
        'kFinalFactsRemainBackendAuthoritative matches v5 boundary (regression)',
        () {
      for (final fact
          in FactOwnerCutoverGuardrail.kFinalFactsRemainBackendAuthoritative) {
        expect(
            CutoverVsFactOwnerBoundaryV5.kFinalFactsRemainBackendAuthoritative,
            contains(fact));
      }
    });

    test('kStrongerIngestForbiddenLayers has 4 canonical layers', () {
      const s = FactOwnerCutoverGuardrail.kStrongerIngestForbiddenLayers;
      expect(s.length, equals(4));
      expect(s, contains('review_fact_ownership'));
      expect(s, contains('daily_completion_and_settlement_ownership'));
      expect(s, contains('streak_learning_day_ownership'));
      expect(s, contains('reward_ledger_arrival_ownership'));
    });

    test('kForbiddenOverclaimPhrases has 6 canonical Chinese phrases', () {
      const f = FactOwnerCutoverGuardrail.kForbiddenOverclaimPhrases;
      expect(f.length, equals(6));
      expect(f, contains('本地已直接记为有效复习'));
      expect(f, contains('今日进度已因本地方案更新'));
      expect(f, contains('奖励已因新主链路到账'));
      expect(f, contains('streak 已因 final cutover 续上'));
      expect(f, contains('学习事实已正式更新'));
      expect(f, contains('现在你刚刚的结果已写入最终事实'));
    });

    test('kStrongerIngestAllowedLayers has 3 judgment-level layers', () {
      const a = FactOwnerCutoverGuardrail.kStrongerIngestAllowedLayers;
      expect(a.length, equals(3));
      expect(a, contains('candidate_discussion'));
      expect(a, contains('readiness_discussion'));
      expect(a, contains('absorbed_judgment_discussion'));
    });

    test('kCanonicalMeaning pins fact_owner_shift_forbidden_this_round', () {
      expect(FactOwnerCutoverGuardrail.kCanonicalMeaning,
          contains('fact_owner_shift_forbidden_this_round'));
    });

    test('kCrossRoundLinkage references v5 boundary from P3.3.13', () {
      expect(FactOwnerCutoverGuardrail.kCrossRoundLinkage,
          contains('cutover_vs_fact_owner_boundary_v5'));
      expect(
          FactOwnerCutoverGuardrail.kCrossRoundLinkage, contains('p3_3_13'));
    });
  });

  // ==========================================================================
  // Group A6: same_round_cleanup_gate_v1 (C entry gate)
  // ==========================================================================
  group('P3.3.14 same_round_cleanup_gate_v1: C entry gate', () {
    test('SameRoundCleanupGateState enum has exactly 3 values', () {
      expect(SameRoundCleanupGateState.values.length, equals(3));
      expect(SameRoundCleanupGateState.values,
          contains(SameRoundCleanupGateState.notReady));
      expect(SameRoundCleanupGateState.values,
          contains(SameRoundCleanupGateState.readyForC));
      expect(SameRoundCleanupGateState.values,
          contains(SameRoundCleanupGateState.cleanupAbsorbed));
    });

    test('kStatus pins gate pinned but not absorbed', () {
      expect(SameRoundCleanupGate.kStatus,
          contains('same_round_cleanup_gate_pinned'));
      expect(SameRoundCleanupGate.kStatus, contains('not_cleanup_absorbed'));
    });

    test('kSixCEntryConditions has 6 canonical entry conditions', () {
      const c = SameRoundCleanupGate.kSixCEntryConditions;
      expect(c.length, equals(6));
      expect(c, contains('a_checkpoint_passed'));
      expect(
          c,
          contains(
              'b_checkpoint_runtime_truth_regression_and_rollback_evidence_package_passed'));
      expect(c, contains('review_group_true_exit_absorb_gate_passed'));
      expect(c, contains('db_api_uplift_absorb_gate_passed'));
      expect(
          c,
          contains(
              'no_overclaim_no_major_change_no_fact_owner_shift_still_holds'));
      expect(c,
          contains('room_1_explicit_pin_for_same_round_cleanup_allowed'));
    });

    test('kSixStopAtBConditions has 6 canonical stop conditions', () {
      const s = SameRoundCleanupGate.kSixStopAtBConditions;
      expect(s.length, equals(6));
      expect(s, contains('current_runtime_truth_silently_altered'));
      expect(s, contains('active_continuation_switched_to_local_path'));
      expect(s, contains('final_fact_owner_boundary_broken'));
    });

    test('kSixStepWritebackOrder has 6 steps in EXACT order', () {
      const o = SameRoundCleanupGate.kSixStepWritebackOrder;
      expect(o.length, equals(6));
      expect(o[0], equals('step_1_r2_tech_note_closeout'));
      expect(o[1], equals('step_2_r3_rules_note_closeout'));
      expect(o[2], equals('step_3_r5_ui_preflight_closeout'));
      expect(o[3], equals('step_4_r1_same_round_closeout_pin'));
      expect(
          o[4], equals('step_5_db_api_writeback_to_seam_marker_layer_only'));
      expect(
          o[5],
          equals(
              'step_6_runtime_baseline_update_only_if_r1_separately_pins_post_true_closeout'));
    });

    test('kCDiscussionScope has 4 canonical discussion items', () {
      const d = SameRoundCleanupGate.kCDiscussionScope;
      expect(d.length, equals(4));
      expect(d, contains('review_group_true_exit_absorb_qualification'));
      expect(d, contains('db_api_uplift_absorbed_decision_readiness'));
      expect(
          d,
          contains(
              'cleanup_old_path_purge_same_round_tail_absorption_qualification'));
      expect(d, contains('same_round_closeout_writeback_order_application'));
    });

    test('kForbiddenClaims has 6 canonical forbidden claims', () {
      const f = SameRoundCleanupGate.kForbiddenClaims;
      expect(f.length, equals(6));
      expect(f, contains('cleanup_already_completed'));
      expect(f, contains('true_exit_already_absorbed'));
      expect(f, contains('uplift_already_absorbed'));
      expect(f, contains('old_path_already_purged'));
      expect(f, contains('full_cutover_closeout_already_pinned'));
      expect(f, contains('runtime_truth_already_upgraded'));
    });

    test('kDefaultStateThisRound is notReady', () {
      expect(SameRoundCleanupGate.kDefaultStateThisRound, equals('notReady'));
    });

    test('kSemanticBoundary pins gate_pin_not_equal_gate_open', () {
      expect(SameRoundCleanupGate.kSemanticBoundary,
          contains('gate_pin_not_equal_gate_open'));
    });
  });

  // ==========================================================================
  // Group G: flags + regression + runtime truth
  // ==========================================================================
  group('P3.3.14 flags + regression + runtime truth', () {
    test('all 3 P3.3.14 flags are false', () {
      expect(P3FeatureGuard.isFinalCutoverJudgmentLockEnabled, isFalse);
      expect(P3FeatureGuard.isRealCutoverExecutionSubsetEnabled, isFalse);
      expect(P3FeatureGuard.isSameRoundCleanupGateEnabled, isFalse);
    });

    test('P3.3.13 flags still false (regression)', () {
      expect(P3FeatureGuard.isFullerCutoverExecutionSubsetV2Enabled, isFalse);
      expect(P3FeatureGuard.isReviewGroupTrueExitCandidateEnabled, isFalse);
      expect(P3FeatureGuard.isDbApiUpliftAbsorbReadinessEnabled, isFalse);
    });

    test('P3.3.5 through P3.3.12 flags still false (regression)', () {
      expect(P3FeatureGuard.isFullerCutoverAbsorbCandidateJudgmentEnabled,
          isFalse);
      expect(P3FeatureGuard.isReviewGroupTrueExitGateJudgmentEnabled, isFalse);
      expect(P3FeatureGuard.isDbApiUpliftAbsorbJudgmentEnabled, isFalse);
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

    test('P3.3.13 true-exit-candidate anchor still intact (regression)', () {
      expect(ReviewGroupTrueExitCandidate.kStatus,
          contains('true_exit_candidate_qualified'));
    });

    test('P3.3.13 uplift-absorb-readiness anchor still intact (regression)',
        () {
      expect(DbApiUpliftAbsorbReadiness.kActiveDbBaselineStillAt,
          equals('v0.2.1'));
      expect(DbApiUpliftAbsorbReadiness.kActiveApiBaselineStillAt,
          equals('v0.2.1'));
    });

    test('P3.3.13 execution-subset-v2 anchor still intact (regression)', () {
      expect(FullerCutoverExecutionSubsetV2.kCurrentStage,
          contains('execution_subset_v2'));
    });

    test('P3.3.13 phase7 writeback order still intact (regression)', () {
      expect(Phase7WritebackOrder.kWritebackSequence.length, equals(6));
      expect(Phase7WritebackOrder.kImmutableLayerSeparation,
          contains('jumping_forbidden'));
    });

    testWidgets(
        'runtime truth regression: bei-dan-ci still navigates to /study (P3.3.14)',
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
        'runtime code regression: ReviewServingSeam still returns cloud when flag OFF (P3.3.14)',
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

    test(
        'cross-contract invariant: all contracts agree rollback_target is the canonical path',
        () {
      const canonical = 'cloud_review_group_current_runtime_path';
      expect(FinalCutoverJudgmentLock.kCanonicalRollbackTarget,
          equals(canonical));
      expect(ReviewServingSeam.kRollbackTarget, equals(canonical));
      expect(FinalCutoverJudgmentLock.kStillDependentPaths,
          contains('rollback_target'));
      expect(ReviewGroupTrueExitAbsorbGate.kSixStillDependentPaths,
          contains('rollback_target'));
    });

    test(
        'cross-contract invariant: all final-fact lists align (5 items, same set)',
        () {
      expect(
          FactOwnerCutoverGuardrail.kFinalFactsRemainBackendAuthoritative
              .toSet(),
          equals(CutoverVsFactOwnerBoundaryV5
              .kFinalFactsRemainBackendAuthoritative
              .toSet()));
    });
  });

  // ==========================================================================
  // Group B1: review_serving_adapter_family (B Member 1 — additive)
  // ==========================================================================
  group('P3.3.14 B Member 1: review_serving_adapter_family', () {
    test('ReviewServingAdapterKind enum has exactly 4 values', () {
      expect(ReviewServingAdapterKind.values.length, equals(4));
    });

    test('kSupportedKinds has 4 canonical adapters', () {
      expect(ReviewServingAdapterFamily.kSupportedKinds.length, equals(4));
      expect(ReviewServingAdapterFamily.kSupportedKinds,
          contains(ReviewServingAdapterKind.continuationPriority));
      expect(ReviewServingAdapterFamily.kSupportedKinds,
          contains(ReviewServingAdapterKind.firstLoad));
      expect(ReviewServingAdapterFamily.kSupportedKinds,
          contains(ReviewServingAdapterKind.postCompletionRefresh));
      expect(ReviewServingAdapterFamily.kSupportedKinds,
          contains(ReviewServingAdapterKind.fallback));
    });

    test('continuation-priority adapter returns cloud with retained anchor',
        () {
      final r = ReviewServingAdapterFamily.consultContinuationPriority(
        isCutoverEnabled: false,
        hasActiveContinuation: true,
      );
      expect(r.kind, equals(ReviewServingAdapterKind.continuationPriority));
      expect(r.selection.source,
          equals(ReviewServingSourceKind.cloudReviewGroup));
      expect(r.selection.isFallbackToRetainedAnchor, isTrue);
      expect(r.additiveTag, contains('continuation_priority'));
    });

    test(
        'continuation-priority returns cloud even when flag would enable cutover',
        () {
      // Even with cutover flag true (not this round), active continuation
      // still routes to cloud retained anchor.
      final r = ReviewServingAdapterFamily.consultContinuationPriority(
        isCutoverEnabled: true,
        hasActiveContinuation: true,
      );
      expect(r.selection.source,
          equals(ReviewServingSourceKind.cloudReviewGroup));
      expect(r.selection.isFallbackToRetainedAnchor, isTrue);
    });

    test('first-load adapter returns cloud default when flag off', () {
      final r = ReviewServingAdapterFamily.consultFirstLoad(
        isCutoverEnabled: false,
      );
      expect(r.kind, equals(ReviewServingAdapterKind.firstLoad));
      expect(r.selection.source,
          equals(ReviewServingSourceKind.cloudReviewGroup));
      expect(r.additiveTag, contains('first_load'));
    });

    test('post-completion refresh adapter returns cloud', () {
      final r = ReviewServingAdapterFamily.consultPostCompletionRefresh(
        isCutoverEnabled: false,
      );
      expect(r.kind, equals(ReviewServingAdapterKind.postCompletionRefresh));
      expect(r.selection.source,
          equals(ReviewServingSourceKind.cloudReviewGroup));
      expect(r.additiveTag, contains('post_completion_refresh'));
    });

    test('fallback adapter always returns cloud with fallback marker', () {
      final r = ReviewServingAdapterFamily.consultFallback();
      expect(r.kind, equals(ReviewServingAdapterKind.fallback));
      expect(r.selection.source,
          equals(ReviewServingSourceKind.cloudReviewGroup));
      expect(r.selection.isFallbackToRetainedAnchor, isTrue);
      expect(r.additiveTag, contains('fallback'));
    });

    test('kRollbackTarget matches ReviewServingSeam.kRollbackTarget', () {
      expect(ReviewServingAdapterFamily.kRollbackTarget,
          equals(ReviewServingSeam.kRollbackTarget));
      expect(ReviewServingAdapterFamily.kRollbackTarget,
          equals('cloud_review_group_current_runtime_path'));
    });

    test('kSemanticBoundary marks additive + no runtime truth switch', () {
      expect(ReviewServingAdapterFamily.kSemanticBoundary,
          contains('additive_'));
      expect(ReviewServingAdapterFamily.kSemanticBoundary,
          contains('no_runtime_truth_switch'));
      expect(ReviewServingAdapterFamily.kSemanticBoundary,
          contains('no_final_fact_owner_shift'));
    });
  });

  // ==========================================================================
  // Group B2: source_neutral_helper_copy (B Member 2 — additive)
  // ==========================================================================
  group('P3.3.14 B Member 2: source_neutral_helper_copy', () {
    test('all captions are non-empty strings', () {
      expect(SourceNeutralHelperCopy.kEmptyStateNeutralCaption, isNotEmpty);
      expect(SourceNeutralHelperCopy.kEmptyStateSecondaryCaption, isNotEmpty);
      expect(SourceNeutralHelperCopy.kCompletionNeutralCaption, isNotEmpty);
      expect(SourceNeutralHelperCopy.kCompletionNextGroupCaption, isNotEmpty);
      expect(SourceNeutralHelperCopy.kSummaryNeutralCaption, isNotEmpty);
    });

    test('kAllCaptions has exactly 5 captions', () {
      expect(SourceNeutralHelperCopy.kAllCaptions.length, equals(5));
    });

    test('kForbiddenClaimSubstrings has exactly 32 items', () {
      expect(SourceNeutralHelperCopy.kForbiddenClaimSubstrings.length,
          equals(32));
    });

    test('no caption contains any forbidden substring (runtime guardrail)',
        () {
      for (final caption in SourceNeutralHelperCopy.kAllCaptions) {
        for (final forbidden
            in SourceNeutralHelperCopy.kForbiddenClaimSubstrings) {
          expect(caption.contains(forbidden), isFalse,
              reason:
                  'caption "$caption" must not contain forbidden substring "$forbidden"');
        }
      }
    });

    test('kSemanticBoundary marks source-neutral + no switch claim', () {
      expect(SourceNeutralHelperCopy.kSemanticBoundary,
          contains('source_neutral'));
      expect(SourceNeutralHelperCopy.kSemanticBoundary,
          contains('does_not_claim_serving_truth_switch'));
    });
  });

  // ==========================================================================
  // Group B3: home_review_helper_summary (B Member 3 — additive)
  // ==========================================================================
  group('P3.3.14 B Member 3: home_review_helper_summary', () {
    test('HomeReviewHelperSummaryState enum has exactly 4 values', () {
      expect(HomeReviewHelperSummaryState.values.length, equals(4));
    });

    test('kCaptionByState has 4 entries, one per state', () {
      expect(HomeReviewHelperSummary.kCaptionByState.length, equals(4));
      for (final state in HomeReviewHelperSummaryState.values) {
        expect(HomeReviewHelperSummary.kCaptionByState.containsKey(state),
            isTrue);
        expect(HomeReviewHelperSummary.kCaptionByState[state], isNotEmpty);
      }
    });

    test('kAllCaptions has exactly 4 captions', () {
      expect(HomeReviewHelperSummary.kAllCaptions.length, equals(4));
    });

    test(
        'no home-helper caption contains any forbidden substring (runtime guardrail)',
        () {
      for (final caption in HomeReviewHelperSummary.kAllCaptions) {
        for (final forbidden
            in SourceNeutralHelperCopy.kForbiddenClaimSubstrings) {
          expect(caption.contains(forbidden), isFalse,
              reason:
                  'home caption "$caption" must not contain forbidden substring "$forbidden"');
        }
      }
    });

    test(
        'kCanonicalRule preserves home_word_entry = study_default invariant',
        () {
      expect(HomeReviewHelperSummary.kCanonicalRule,
          contains('home_word_entry_remains_study_default'));
    });

    test('kSemanticBoundary marks additive caption + not primary route change',
        () {
      expect(HomeReviewHelperSummary.kSemanticBoundary,
          contains('additive_caption'));
      expect(HomeReviewHelperSummary.kSemanticBoundary,
          contains('does_not_equal_primary_route_change'));
    });

    testWidgets('HomeReviewHelperSummaryCaption renders the canonical caption',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: HomeReviewHelperSummaryCaption(
            state: HomeReviewHelperSummaryState.reviewAvailable,
          ),
        ),
      ));
      expect(
          find.text(HomeReviewHelperSummary.kCaptionReviewAvailable),
          findsOneWidget);
    });
  });

  // ==========================================================================
  // Group B4: rollback_hold_fallback_orchestration (B Member 4 — additive)
  // ==========================================================================
  group('P3.3.14 B Member 4: rollback_hold_fallback_orchestration', () {
    test('RollbackHoldFallbackState enum has exactly 4 values', () {
      expect(RollbackHoldFallbackState.values.length, equals(4));
    });

    test('kStates has 4 canonical states', () {
      expect(RollbackHoldFallbackOrchestration.kStates.length, equals(4));
      expect(RollbackHoldFallbackOrchestration.kStates,
          contains(RollbackHoldFallbackState.normalServing));
      expect(RollbackHoldFallbackOrchestration.kStates,
          contains(RollbackHoldFallbackState.hold));
      expect(RollbackHoldFallbackOrchestration.kStates,
          contains(RollbackHoldFallbackState.rollback));
      expect(RollbackHoldFallbackOrchestration.kStates,
          contains(RollbackHoldFallbackState.fallback));
    });

    test('kDefaultState is normalServing', () {
      expect(RollbackHoldFallbackOrchestration.kDefaultState,
          equals(RollbackHoldFallbackState.normalServing));
    });

    test('kCanonicalCopy matrix has 4 non-null captions', () {
      expect(RollbackHoldFallbackOrchestration.kCanonicalCopy.holdCaption,
          isNotEmpty);
      expect(RollbackHoldFallbackOrchestration.kCanonicalCopy.rollbackCaption,
          isNotEmpty);
      expect(RollbackHoldFallbackOrchestration.kCanonicalCopy.fallbackCaption,
          isNotEmpty);
      // normalCaption is empty by design
      expect(RollbackHoldFallbackOrchestration.kCanonicalCopy.normalCaption,
          equals(''));
    });

    test(
        'no orchestration copy contains any forbidden substring (runtime guardrail)',
        () {
      const copy = RollbackHoldFallbackOrchestration.kCanonicalCopy;
      final captions = [
        copy.holdCaption,
        copy.rollbackCaption,
        copy.fallbackCaption,
      ];
      for (final caption in captions) {
        for (final forbidden
            in SourceNeutralHelperCopy.kForbiddenClaimSubstrings) {
          expect(caption.contains(forbidden), isFalse,
              reason:
                  'orchestration caption "$caption" must not contain forbidden "$forbidden"');
        }
      }
    });

    test('kRollbackTarget is locked', () {
      expect(RollbackHoldFallbackOrchestration.kRollbackTarget,
          equals('cloud_review_group_current_runtime_path'));
    });

    test('kRollbackTriggers has 8 canonical triggers', () {
      expect(RollbackHoldFallbackOrchestration.kRollbackTriggers.length,
          equals(8));
      // Match ReviewServingSeam.kRollbackTriggers exactly.
      expect(
          RollbackHoldFallbackOrchestration.kRollbackTriggers.toSet(),
          equals(ReviewServingSeam.kRollbackTriggers.toSet()));
    });

    test('kHoldTriggers has 4 canonical triggers', () {
      expect(RollbackHoldFallbackOrchestration.kHoldTriggers.length, equals(4));
      expect(RollbackHoldFallbackOrchestration.kHoldTriggers.toSet(),
          equals(ReviewServingSeam.kHoldTriggers.toSet()));
    });

    test('kReturnToNormalRule pins cloud reachability', () {
      expect(RollbackHoldFallbackOrchestration.kReturnToNormalRule,
          contains('cloud_review_group_reachable_and_trigger_cleared'));
    });

    test('kForbiddenTransitions has 5 canonical forbidden items', () {
      expect(RollbackHoldFallbackOrchestration.kForbiddenTransitions.length,
          equals(5));
      expect(RollbackHoldFallbackOrchestration.kForbiddenTransitions,
          contains('normal_to_direct_local_serving'));
      expect(RollbackHoldFallbackOrchestration.kForbiddenTransitions,
          contains('rollback_to_local_serving'));
      expect(RollbackHoldFallbackOrchestration.kForbiddenTransitions,
          contains('fallback_into_final_fact_owner_shift'));
    });

    test('kSemanticBoundary marks protective + no advance', () {
      expect(RollbackHoldFallbackOrchestration.kSemanticBoundary,
          contains('protective_layer_does_not_advance'));
    });
  });

  // ==========================================================================
  // Group B5: stronger_ingest_minimal_binding_seam (B Member 5 — additive)
  // ==========================================================================
  group('P3.3.14 B Member 5: stronger_ingest_minimal_binding_seam', () {
    test('kAllowedDiscussionLayers has 2 allowed layers', () {
      expect(
          StrongerIngestMinimalBindingSeam.kAllowedDiscussionLayers.length,
          equals(2));
      expect(StrongerIngestMinimalBindingSeam.kAllowedDiscussionLayers,
          contains('candidate_discussion'));
      expect(StrongerIngestMinimalBindingSeam.kAllowedDiscussionLayers,
          contains('readiness_discussion'));
    });

    test('kForbiddenDiscussionLayers has 3 forbidden layers', () {
      expect(
          StrongerIngestMinimalBindingSeam.kForbiddenDiscussionLayers.length,
          equals(3));
      expect(StrongerIngestMinimalBindingSeam.kForbiddenDiscussionLayers,
          contains('absorbed_decision'));
      expect(StrongerIngestMinimalBindingSeam.kForbiddenDiscussionLayers,
          contains('final_owner_shift'));
      expect(StrongerIngestMinimalBindingSeam.kForbiddenDiscussionLayers,
          contains('runtime_truth_shift'));
    });

    test('allowed and forbidden layers are disjoint sets', () {
      final allowed =
          StrongerIngestMinimalBindingSeam.kAllowedDiscussionLayers.toSet();
      final forbidden =
          StrongerIngestMinimalBindingSeam.kForbiddenDiscussionLayers.toSet();
      expect(allowed.intersection(forbidden), isEmpty);
    });

    test(
        'consultMinimalBinding (post-cloud-commit) returns discussion-only at candidate layer',
        () {
      final r = StrongerIngestMinimalBindingSeam.consultMinimalBinding(
        precondition: const StrongerIngestBindingPrecondition(
          wordId: 'test-word-id',
          cloudReviewGroupAlreadyCommitted: true,
          backendFactLayerConsultedAsAuthoritative: true,
        ),
      );
      expect(r.bindingDiscussedOnly, isTrue);
      expect(r.allowedDiscussionLayer, equals('candidate_discussion'));
      expect(r.consultationTag, contains('post_cloud_commit'));
    });

    test(
        'consultMinimalBinding (pre-cloud-commit) still discussion-only with guard tag',
        () {
      final r = StrongerIngestMinimalBindingSeam.consultMinimalBinding(
        precondition: const StrongerIngestBindingPrecondition(
          wordId: 'test-word-id',
          cloudReviewGroupAlreadyCommitted: false,
          backendFactLayerConsultedAsAuthoritative: true,
        ),
      );
      expect(r.bindingDiscussedOnly, isTrue);
      expect(r.allowedDiscussionLayer, equals('candidate_discussion'));
      expect(r.consultationTag, contains('precondition_unmet_no_write'));
    });

    test('kCanonicalRule pins no final fact write', () {
      expect(StrongerIngestMinimalBindingSeam.kCanonicalRule,
          contains('no_final_fact_write'));
      expect(StrongerIngestMinimalBindingSeam.kCanonicalRule,
          contains('no_owner_shift'));
    });

    test('kSemanticBoundary pins discussion not write', () {
      expect(StrongerIngestMinimalBindingSeam.kSemanticBoundary,
          contains('binding_is_discussion_not_write'));
    });

    test('kLinkageToAbsorbGate references absorb gate qualification', () {
      expect(StrongerIngestMinimalBindingSeam.kLinkageToAbsorbGate,
          contains('absorb_gate_qualification_discussion'));
    });
  });

  // ==========================================================================
  // Group H: must-hold guardrails (B checkpoint pass gate regression)
  // ==========================================================================
  group('P3.3.14 must-hold guardrails: no B overclaim, no owner shift', () {
    test(
        'fact_owner_cutover_guardrail forbidden phrases all ABSENT from B captions',
        () {
      final allBCaptions = <String>[
        ...SourceNeutralHelperCopy.kAllCaptions,
        ...HomeReviewHelperSummary.kAllCaptions,
        RollbackHoldFallbackOrchestration.kCanonicalCopy.holdCaption,
        RollbackHoldFallbackOrchestration.kCanonicalCopy.rollbackCaption,
        RollbackHoldFallbackOrchestration.kCanonicalCopy.fallbackCaption,
      ];
      for (final caption in allBCaptions) {
        for (final forbidden
            in FactOwnerCutoverGuardrail.kForbiddenOverclaimPhrases) {
          expect(caption.contains(forbidden), isFalse,
              reason:
                  'B caption "$caption" must not contain fact-owner forbidden phrase "$forbidden"');
        }
      }
    });

    test('B additive seams preserve cloud as sole runtime source', () {
      // Every consult path returns cloudReviewGroup.
      final selections = [
        ReviewServingAdapterFamily.consultContinuationPriority(
                isCutoverEnabled: false, hasActiveContinuation: false)
            .selection,
        ReviewServingAdapterFamily.consultContinuationPriority(
                isCutoverEnabled: false, hasActiveContinuation: true)
            .selection,
        ReviewServingAdapterFamily.consultFirstLoad(isCutoverEnabled: false)
            .selection,
        ReviewServingAdapterFamily.consultPostCompletionRefresh(
                isCutoverEnabled: false)
            .selection,
        ReviewServingAdapterFamily.consultFallback().selection,
      ];
      for (final sel in selections) {
        expect(sel.source, equals(ReviewServingSourceKind.cloudReviewGroup));
      }
    });

    test('stronger-ingest seam NEVER reports a forbidden discussion layer',
        () {
      final r1 = StrongerIngestMinimalBindingSeam.consultMinimalBinding(
        precondition: const StrongerIngestBindingPrecondition(
          wordId: 'a',
          cloudReviewGroupAlreadyCommitted: true,
          backendFactLayerConsultedAsAuthoritative: true,
        ),
      );
      final r2 = StrongerIngestMinimalBindingSeam.consultMinimalBinding(
        precondition: const StrongerIngestBindingPrecondition(
          wordId: 'b',
          cloudReviewGroupAlreadyCommitted: false,
          backendFactLayerConsultedAsAuthoritative: true,
        ),
      );
      for (final layer in [
        r1.allowedDiscussionLayer,
        r2.allowedDiscussionLayer,
      ]) {
        expect(
            StrongerIngestMinimalBindingSeam.kForbiddenDiscussionLayers
                .contains(layer),
            isFalse);
      }
    });

    test('all B members still reference the canonical rollback target', () {
      const canonical = 'cloud_review_group_current_runtime_path';
      expect(
          ReviewServingAdapterFamily.kRollbackTarget, equals(canonical));
      expect(
          RollbackHoldFallbackOrchestration.kRollbackTarget, equals(canonical));
      expect(ReviewServingSeam.kRollbackTarget, equals(canonical));
    });
  });
}
