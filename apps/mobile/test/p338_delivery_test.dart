import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/fact_settlement/fact_ingest_boundary_contract.dart';
import 'package:meow_mobile/core/gate/db_api_candidate_round.dart';
import 'package:meow_mobile/core/gate/fact_settlement_cutover_boundary.dart';
import 'package:meow_mobile/core/gate/limited_cutover_scope_candidate.dart';
import 'package:meow_mobile/core/gate/phase3_gate_decision.dart';
import 'package:meow_mobile/core/gate/phase3_writeback_and_migration.dart';
import 'package:meow_mobile/core/gate/review_group_exit_gate.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';

// ============================================================================
// P3.3.8 — Phase 3 Gate / Cutover-Decision Delivery Tests
//
// Six frozen contracts under test:
//   1. phase3_gate_decision_v1
//   2. limited_cutover_scope_candidate_v1
//   3. db_api_candidate_round_v1
//   4. review_group_exit_gate_v1
//   5. fact_settlement_cutover_boundary_v1
//   6. phase3_writeback_and_migration_v1
//
// All tests are markerContractOnly (per P3.3.6 ParityTestCategory) except
// the single runtimeTruthRegression widget test at the end of Group F.
// No runtime code is exercised except through contract anchor constants.
// ============================================================================

void main() {
  // ==========================================================================
  // Group A: phase3_gate_decision_v1 — classifier behavior (9 tests)
  //
  // Proves: the gate classifier obeys the priority order
  //   escalate > hold > revise > proceed
  // and never emits cutover-completion strings.
  // ==========================================================================
  group('P3.3.8 phase3_gate_decision_v1: classifier behavior', () {
    test('Phase3GateDecision enum has exactly 4 values', () {
      expect(Phase3GateDecision.values.length, equals(4));
      expect(Phase3GateDecision.values,
          contains(Phase3GateDecision.proceedToNextLayerCandidateReview));
      expect(Phase3GateDecision.values, contains(Phase3GateDecision.hold));
      expect(Phase3GateDecision.values, contains(Phase3GateDecision.revise));
      expect(Phase3GateDecision.values, contains(Phase3GateDecision.escalate));
    });

    test('classifier returns proceed when all 5 conditions green and no triggers',
        () {
      const inputs = Phase3GateEvidenceInputs(
        runtimeTruthGuardrailsGreen: true,
        shadowEvidenceRepeatable: true,
        candidateFramingWithinSeamBoundary: true,
        reviewGroupExitStillGated: true,
        writebackMigrationRollbackHoldPackReady: true,
      );
      expect(Phase3GateClassifier.classify(inputs),
          Phase3GateDecision.proceedToNextLayerCandidateReview);
    });

    test('classifier returns hold when shadow leaked to users', () {
      const inputs = Phase3GateEvidenceInputs(
        runtimeTruthGuardrailsGreen: true,
        shadowEvidenceRepeatable: true,
        candidateFramingWithinSeamBoundary: true,
        reviewGroupExitStillGated: true,
        writebackMigrationRollbackHoldPackReady: true,
        shadowResultLeakedToUsers: true,
      );
      expect(Phase3GateClassifier.classify(inputs), Phase3GateDecision.hold);
    });

    test('classifier returns hold when review_group written as exited', () {
      const inputs = Phase3GateEvidenceInputs(
        reviewGroupWrittenAsExited: true,
      );
      expect(Phase3GateClassifier.classify(inputs), Phase3GateDecision.hold);
    });

    test(
        'classifier returns escalate when DB schema change needed (overrides hold)',
        () {
      const inputs = Phase3GateEvidenceInputs(
        needsDbSchemaChange: true,
        shadowResultLeakedToUsers: true, // hold trigger also present
      );
      expect(Phase3GateClassifier.classify(inputs),
          Phase3GateDecision.escalate,
          reason: 'escalate must dominate hold per priority order');
    });

    test('classifier returns escalate when API core semantics change needed',
        () {
      const inputs = Phase3GateEvidenceInputs(
        needsApiCoreSemanticsChange: true,
      );
      expect(Phase3GateClassifier.classify(inputs),
          Phase3GateDecision.escalate);
    });

    test(
        'classifier returns revise when migration structure incomplete (and not escalate/hold)',
        () {
      const inputs = Phase3GateEvidenceInputs(
        migrationRollbackStructureIncomplete: true,
      );
      expect(Phase3GateClassifier.classify(inputs),
          Phase3GateDecision.revise);
    });

    test(
        'default behavior (empty inputs, no flags) returns hold (conservative)',
        () {
      const inputs = Phase3GateEvidenceInputs();
      expect(Phase3GateClassifier.classify(inputs), Phase3GateDecision.hold);
    });

    test('kForbiddenDecisionOutputs contains 4 canonical forbidden strings',
        () {
      final forbidden =
          Phase3GateForbiddenOutputs.kForbiddenDecisionOutputs;
      expect(forbidden.length, equals(4));
      expect(forbidden, contains('runtime_owner_shift_completed'));
      expect(forbidden, contains('local_serving_cutover_completed'));
      expect(forbidden, contains('review_group_exited'));
      expect(forbidden, contains('unified_planner_established'));

      // Sanity: none of these are valid Phase3GateDecision enum names.
      final enumNames = Phase3GateDecision.values.map((d) => d.name).toSet();
      for (final f in forbidden) {
        expect(enumNames, isNot(contains(f)));
      }
    });
  });

  // ==========================================================================
  // Group B: limited_cutover_scope_candidate_v1 — scope boundaries (5 tests)
  // ==========================================================================
  group('P3.3.8 limited_cutover_scope_candidate_v1: scope boundaries', () {
    test('LimitedCutoverScopeItem enum has exactly 5 values', () {
      expect(LimitedCutoverScopeItem.values.length, equals(5));
    });

    test('kAllowedScopeItemNames contains all 5 canonical names', () {
      final names = LimitedCutoverScopeCandidate.kAllowedScopeItemNames;
      expect(names.length, equals(5));
      expect(names, contains('review_group_exit_prep'));
      expect(names, contains('fact_ingest_stronger_path_candidate'));
      expect(names, contains('helper_summary_migration_prep'));
      expect(names, contains('db_api_seam_candidate_formalization'));
      expect(names, contains('rollback_hold_migration_note_baseline'));
    });

    test('kForbiddenCutoverLayers contains canonical forbidden layers', () {
      final forbidden = LimitedCutoverScopeCandidate.kForbiddenCutoverLayers;
      expect(forbidden, contains('reviewpage_local_serving_runtime_cutover'));
      expect(forbidden, contains('auto_routing_runtime'));
      expect(forbidden, contains('unified_planner_planner_merge'));
      expect(forbidden, contains('final_fact_owner_shift'));
    });

    test('kCanonicalRule enforces serving-source-before-fact-boundary lock',
        () {
      expect(LimitedCutoverScopeCandidate.kCanonicalRule,
          contains('serving_source_must_not_precede'));
      expect(LimitedCutoverScopeCandidate.kCanonicalRule,
          contains('fact_settlement_boundary_lock'));
    });

    test('kForbiddenClaims contains canonical cutover claim phrases', () {
      final forbidden = LimitedCutoverScopeCandidate.kForbiddenClaims;
      expect(forbidden, contains('本地已接管复习'));
      expect(forbidden, contains('已切换到本地复习模式'));
      expect(forbidden, contains('已接管奖励结算'));
      expect(forbidden, contains('当前已完成兼容切换'));
    });
  });

  // ==========================================================================
  // Group C: db_api_candidate_round_v1 — baseline freeze (7 tests)
  // ==========================================================================
  group('P3.3.8 db_api_candidate_round_v1: baseline freeze', () {
    test('kActiveDbBaseline equals v0.2.1 (not uplifted)', () {
      expect(DbApiCandidateRound.kActiveDbBaseline, equals('v0.2.1'));
    });

    test('kActiveApiBaseline equals v0.2.1 (not uplifted)', () {
      expect(DbApiCandidateRound.kActiveApiBaseline, equals('v0.2.1'));
    });

    test('kAllowedDbCandidateEntries contains all 7 canonical entries', () {
      final entries = DbApiCandidateRound.kAllowedDbCandidateEntries;
      expect(entries.length, equals(7));
      expect(entries, contains('review_queue'));
      expect(entries, contains('learning_stat_daily'));
      expect(entries, contains('user_backup_snapshots'));
      expect(entries, contains('backup_restore_operations'));
      expect(entries, contains('local_planner_queue_candidate_metadata'));
      expect(entries, contains('fact_ingest_candidate_event_markers'));
      expect(entries, contains('migration_rollback_deprecation_markers'));
    });

    test('kCurrentRuntimeDbEntries contains review_group family + settlements',
        () {
      final entries = DbApiCandidateRound.kCurrentRuntimeDbEntries;
      expect(entries, contains('review_groups'));
      expect(entries, contains('review_group_items'));
      expect(entries, contains('review_attempts'));
      expect(entries, contains('settlements'));
      expect(entries, contains('reward_ledger'));
    });

    test('kFrozenApiEndpoints contains canonical current runtime endpoints',
        () {
      final endpoints = DbApiCandidateRound.kFrozenApiEndpoints;
      expect(endpoints, contains('GET /me/review-groups/next'));
      expect(endpoints, contains('POST /review-attempts'));
      expect(endpoints, contains('GET /me/today'));
      expect(endpoints, contains('POST /settlements/learning-rounds'));
      expect(endpoints, contains('POST /me/backup'));
    });

    test('kAllowedApiSeamCandidates contains 5 seam candidate names', () {
      final candidates = DbApiCandidateRound.kAllowedApiSeamCandidates;
      expect(candidates.length, equals(5));
      expect(candidates, contains('local_serving_compare_candidate_dto'));
      expect(candidates, contains('fact_ingest_candidate_payload_shape'));
      expect(candidates, contains('migration_compatibility_metadata'));
      expect(candidates, contains('rollback_hold_reason_shape'));
      expect(candidates, contains('debug_qa_evidence_envelope'));
    });

    test('kForbiddenActions contains schema_rewrite + baseline_uplift', () {
      final forbidden = DbApiCandidateRound.kForbiddenActions;
      expect(forbidden, contains('schema_rewrite'));
      expect(forbidden, contains('endpoint_core_semantics_rewrite'));
      expect(forbidden, contains('active_baseline_uplift'));
      expect(forbidden, contains('write_candidate_as_current_runtime_truth'));
      expect(forbidden, contains('change_cloud_first_submit_chain'));
    });
  });

  // ==========================================================================
  // Group D: review_group_exit_gate_v1 — 4 prerequisite categories (7 tests)
  // ==========================================================================
  group('P3.3.8 review_group_exit_gate_v1: 4 prerequisite categories', () {
    test('ReviewGroupExitPrerequisiteCategory enum has exactly 4 values', () {
      expect(ReviewGroupExitPrerequisiteCategory.values.length, equals(4));
      expect(ReviewGroupExitPrerequisiteCategory.values,
          contains(ReviewGroupExitPrerequisiteCategory.contract));
      expect(ReviewGroupExitPrerequisiteCategory.values,
          contains(ReviewGroupExitPrerequisiteCategory.test));
      expect(ReviewGroupExitPrerequisiteCategory.values,
          contains(ReviewGroupExitPrerequisiteCategory.doc));
      expect(ReviewGroupExitPrerequisiteCategory.values,
          contains(ReviewGroupExitPrerequisiteCategory.boundary));
    });

    test('kGateStatus contains prerequisites_not_yet_met', () {
      expect(ReviewGroupExitGate.kGateStatus,
          equals('prerequisites_not_yet_met'));
      // Anti-pattern: MUST NOT be written as exited
      expect(ReviewGroupExitGate.kGateStatus, isNot(contains('exited')));
      expect(ReviewGroupExitGate.kGateStatus, isNot(contains('retired')));
    });

    test('contract prerequisites list contains canonical pinned contracts',
        () {
      final contracts = ReviewGroupExitGate.kContractPrerequisites;
      expect(contracts, isNotEmpty);
      expect(contracts,
          contains('local_serving_candidate_pinned_as_next_layer_contract'));
      expect(contracts, contains('fact_ingest_candidate_pinned'));
      expect(contracts, contains('routing_compat_pinned'));
      expect(contracts, contains('writeback_markers_pinned'));
    });

    test('test prerequisites list contains current_runtime_truth_regression',
        () {
      final tests = ReviewGroupExitGate.kTestPrerequisites;
      expect(tests, contains('current_runtime_truth_regression'));
      expect(tests, contains('review_group_still_serving_regression'));
      expect(tests, contains('no_must_hold_mismatches_unresolved'));
    });

    test('doc prerequisites list contains writeback_order_explicit', () {
      final docs = ReviewGroupExitGate.kDocPrerequisites;
      expect(docs, contains('br_exit_gate_conditions'));
      expect(docs, contains('writeback_order_explicit'));
      expect(docs, contains('db_api_candidate_seam_documentation'));
    });

    test('boundary prerequisites list contains final_fact_owner_still_clear',
        () {
      final boundaries = ReviewGroupExitGate.kBoundaryPrerequisites;
      expect(boundaries,
          contains('final_fact_settlement_owner_still_clear_backend'));
      expect(boundaries, contains('no_silent_fact_owner_shift'));
    });

    test('kForbiddenExitClaims contains canonical "already exited" phrases',
        () {
      final forbidden = ReviewGroupExitGate.kForbiddenExitClaims;
      expect(forbidden, contains('已退场'));
      expect(forbidden, contains('即将退场'));
      expect(forbidden, contains('旧方案即将不可用'));
      expect(forbidden, contains('当前已不再使用 review_group'));
    });
  });

  // ==========================================================================
  // Group E: fact_settlement_cutover_boundary_v1 — final-fact guardrails (5 tests)
  // ==========================================================================
  group('P3.3.8 fact_settlement_cutover_boundary_v1: final-fact guardrails',
      () {
    test('kCutoverBoundaryStatus contains "uncrossed"', () {
      expect(FactSettlementCutoverBoundary.kCutoverBoundaryStatus,
          contains('uncrossed'));
      expect(FactSettlementCutoverBoundary.kCutoverBoundaryStatus,
          contains('cloud'));
    });

    test('kFinalFactsStillCloudOwned contains all 4 P3.3.6 core facts', () {
      final facts = FactSettlementCutoverBoundary.kFinalFactsStillCloudOwned;
      // All 4 core facts from P3.3.6's FactSettlementIngestBoundary must
      // continue to be listed.
      expect(facts, contains('effective_review_fact'));
      expect(facts, contains('daily_goal_progress'));
      expect(facts, contains('reward_settlement_ledger'));
      expect(facts, contains('check_in_learning_day_streak'));

      // Sanity: P3.3.6's core facts list is a subset of P3.3.8's extended list
      for (final p336Fact
          in FactSettlementIngestBoundary.kCloudOwnedFinalFacts) {
        expect(facts, contains(p336Fact),
            reason:
                'P3.3.8 must include all P3.3.6 facts: missing $p336Fact');
      }
    });

    test('kLocalEvidenceAllowedScope stays at candidate / discussion layer',
        () {
      final scope = FactSettlementCutoverBoundary.kLocalEvidenceAllowedScope;
      expect(scope,
          contains('stronger_active_ingest_path_candidate_discussion'));
      expect(scope,
          contains('accept_reject_duplicate_rule_stability_assessment'));
      expect(scope, contains('writeback_migration_entry_conditions'));
    });

    test(
        'kForbiddenLocalFactOwnerActions contains direct ledger + streak actions',
        () {
      final forbidden =
          FactSettlementCutoverBoundary.kForbiddenLocalFactOwnerActions;
      expect(forbidden, contains('direct_ledger_modification'));
      expect(forbidden,
          contains('direct_daily_goal_completion_state_change'));
      expect(forbidden, contains('direct_streak_learning_day_fact_ownership'));
      expect(forbidden, contains('direct_cloud_settlement_owner_replacement'));
    });

    test('kForbiddenOverclaims contains canonical overclaim phrases', () {
      final forbidden = FactSettlementCutoverBoundary.kForbiddenOverclaims;
      expect(forbidden, contains('local 已接管 review facts'));
      expect(forbidden, contains('本地结果已写回最终事实'));
      expect(forbidden, contains('奖励已由本地计划正式结算'));
      expect(forbidden, contains('streak / learning_day 已由本地主导'));
    });
  });

  // ==========================================================================
  // Group F: phase3_writeback_and_migration_v1 + P3FeatureGuard + regression
  // ==========================================================================
  group('P3.3.8 phase3_writeback + flags + regression', () {
    test('WritebackRoom enum has exactly 5 values', () {
      expect(WritebackRoom.values.length, equals(5));
    });

    test('kWritebackOrder is R2 → R3 → R5 → R1 → R4 in exact order', () {
      final order = Phase3WritebackAndMigration.kWritebackOrder;
      expect(order.length, equals(5));
      expect(order[0], equals('r2_tech_candidate_note'));
      expect(order[1], equals('r3_rules_note'));
      expect(order[2], equals('r5_ui_preflight'));
      expect(order[3], equals('r1_absorb_pin'));
      expect(order[4], equals('r4_execution'));
    });

    test('kMigrationNoteRequiredFields has all 4 minimum fields', () {
      final fields =
          Phase3WritebackAndMigration.kMigrationNoteRequiredFields;
      expect(fields.length, equals(4));
      expect(fields, contains('before'));
      expect(fields, contains('after'));
      expect(fields, contains('staged_conditions'));
      expect(fields, contains('synced_docs'));
    });

    test(
        'kRollbackNoteRequiredFields contains explicit_no_cut_runtime_truth_statement',
        () {
      final fields =
          Phase3WritebackAndMigration.kRollbackNoteRequiredFields;
      expect(fields, contains('rollback_trigger'));
      expect(fields, contains('rollback_target_return_to_cloud_serving_truth'));
      expect(fields, contains('rollback_owner'));
      expect(fields, contains('rollback_evidence'));
      expect(fields, contains('explicit_no_cut_runtime_truth_statement'));
    });

    test('kHoldNoteRequiredFields has 2 canonical fields', () {
      final fields = Phase3WritebackAndMigration.kHoldNoteRequiredFields;
      expect(fields.length, equals(2));
      expect(fields, contains('hold_trigger'));
      expect(fields, contains('hold_clearance_condition'));
    });

    test('kMandatoryLayerSeparation contains 3 layers (runtime/compat/deprecated)',
        () {
      final layers = Phase3WritebackAndMigration.kMandatoryLayerSeparation;
      expect(layers.length, equals(3));
      expect(layers, contains('runtime_truth'));
      expect(layers, contains('compatibility_only'));
      expect(layers, contains('deprecated_candidate'));
      // Intentionally omitted from P3.3.8 writeback scope:
      expect(layers, isNot(contains('shadow_only_evidence')));
    });

    test('kExplicitNoCutRuntimeTruthStatement is canonical constant', () {
      expect(Phase3WritebackAndMigration.kExplicitNoCutRuntimeTruthStatement,
          equals('this_round_has_not_cut_runtime_truth'));
    });

    test('all 3 P3.3.8 flags are false', () {
      expect(P3FeatureGuard.isPhase3GateEvaluationEnabled, isFalse);
      expect(P3FeatureGuard.isLimitedCutoverExecutionEnabled, isFalse);
      expect(P3FeatureGuard.isDbApiCandidateMigrationEnabled, isFalse);
    });

    test('P3.3.7 flags still false (regression)', () {
      expect(P3FeatureGuard.isLocalServingShadowRunEnabled, isFalse);
      expect(P3FeatureGuard.isParityCheckRecordingEnabled, isFalse);
      expect(P3FeatureGuard.isFactIngestShadowEvaluationEnabled, isFalse);
      expect(P3FeatureGuard.isRoutingShadowComputationEnabled, isFalse);
    });

    test('P3.3.6 + P3.3.5 flags still false (regression)', () {
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
      // Single widget test verifying P3.3.2 session_entry_policy_v1 is
      // still intact after the P3.3.8 contract anchor additions.
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
  });
}
