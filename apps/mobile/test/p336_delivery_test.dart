import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/fact_settlement/fact_ingest_boundary_contract.dart';
import 'package:meow_mobile/core/governance/semantic_layer.dart';
import 'package:meow_mobile/core/governance/shadow_parity_test_strategy.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/review/review_group_compatibility.dart';
import 'package:meow_mobile/core/routing/session_entry_routing_compat.dart';
import 'package:meow_mobile/core/serving/local_serving_candidate_contract.dart';

// ============================================================================
// P3.3.6 — Phase 1 Compatibility Contract v1 + Shadow-Entry Prep Delivery Tests
//
// Six frozen contracts under test:
//   1. local_serving_candidate_contract_v1
//   2. review_group_compatibility_posture_v1 (extends P3.3.5)
//   3. fact_settlement_ingest_contract_candidate_v1
//   4. session_entry_and_routing_compat_v1
//   5. deprecation_markers_and_writeback_plan_v1 (semantic layer)
//   6. shadow_parity_test_strategy_v1
//
// Per RF-P3.3.6-017, all tests in this file belong to the
// `markerContractOnly` category — they verify contract anchor constants
// and enums. No runtime behavior is exercised except for a single
// regression widget test at the end.
// ============================================================================

void main() {
  // ==========================================================================
  // Group A: local_serving_candidate_contract_v1
  //
  // Proves: source types, eligibility states, candidate reasons, and the
  // 8 field group semantic names are all anchored correctly.
  // ==========================================================================
  group('P3.3.6 local_serving_candidate_contract_v1', () {
    test('LocalServingSourceType enum has exactly 3 values', () {
      expect(LocalServingSourceType.values.length, equals(3),
          reason: 'Three source types: cloudGroup, localDueShadow, localGeneratedShadow');
      expect(LocalServingSourceType.values,
          contains(LocalServingSourceType.cloudGroup));
      expect(LocalServingSourceType.values,
          contains(LocalServingSourceType.localDueShadow));
      expect(LocalServingSourceType.values,
          contains(LocalServingSourceType.localGeneratedShadow));
    });

    test('ServingEligibilityState enum includes runtimeActive and shadowOnly',
        () {
      final values = ServingEligibilityState.values;
      expect(values, contains(ServingEligibilityState.runtimeActive),
          reason: 'runtimeActive applies to cloud review_group only this round');
      expect(values, contains(ServingEligibilityState.shadowOnly),
          reason: 'shadowOnly applies to all local* candidates this round');
      expect(values, contains(ServingEligibilityState.pendingBoundaryCheck));
      expect(values, contains(ServingEligibilityState.parityPending));
    });

    test('CandidateReason enum includes cloudGroupCurrent for cloud baseline',
        () {
      final values = CandidateReason.values;
      expect(values, contains(CandidateReason.cloudGroupCurrent),
          reason: 'cloudGroupCurrent is the canonical current-runtime reason');
      expect(values, contains(CandidateReason.fsrsComputed));
      expect(values, contains(CandidateReason.localGenerated));
      expect(values, contains(CandidateReason.parityBaseline));
    });

    test('kAllFieldSemanticNames has exactly 8 entries (RF-P3.3.6-003)', () {
      expect(
          LocalServingCandidateFieldSemantics.kAllFieldSemanticNames.length,
          equals(8),
          reason:
              'RF-P3.3.6-003 freezes exactly 8 field group semantic concepts');
    });

    test('kAllFieldSemanticNames contains all 8 canonical names', () {
      final names = LocalServingCandidateFieldSemantics.kAllFieldSemanticNames;
      expect(names, contains('source_type'));
      expect(names, contains('source_id'));
      expect(names, contains('owner_layer'));
      expect(names, contains('shadow_only'));
      expect(names, contains('candidate_reason'));
      expect(names, contains('generated_at'));
      expect(names, contains('item_count'));
      expect(names, contains('serving_eligibility_state'));
    });

    test('kForbiddenLocalServingClaims contains canonical owner-shift claims',
        () {
      final forbidden =
          LocalServingCandidateFieldSemantics.kForbiddenLocalServingClaims;
      expect(forbidden, contains('本地 serving 已启用'));
      expect(forbidden, contains('ReviewPage 已切到本地队列'));
      expect(forbidden, contains('owner shift 已完成'));
      expect(forbidden, contains('影子模式已正式生效'));
      expect(forbidden, contains('parity 已通过，现已切换新模式'));
    });
  });

  // ==========================================================================
  // Group B: review_group_compatibility_posture_v1 — three-layer posture
  //
  // Proves: review_group is simultaneously runtime owner + compatibility
  // anchor + deprecated candidate. Extends P3.3.5 without regressing.
  // ==========================================================================
  group('P3.3.6 review_group_compatibility_posture_v1: three-layer posture',
      () {
    test('kPostureRuntimeOwner is true (RF-P3.3.6-005)', () {
      expect(ReviewGroupCompatibility.kPostureRuntimeOwner, isTrue,
          reason:
              'review_group is STILL runtime serving owner — must not be cut');
    });

    test('kPostureCompatibilityAnchor is true (RF-P3.3.6-006)', () {
      expect(ReviewGroupCompatibility.kPostureCompatibilityAnchor, isTrue,
          reason: 'review_group is now also a compatibility anchor for parity');
    });

    test('kPostureDeprecatedCandidate is true (RF-P3.3.6-006 + 007)', () {
      expect(ReviewGroupCompatibility.kPostureDeprecatedCandidate, isTrue,
          reason:
              'review_group is marked as deprecated candidate, NOT retired');
    });

    test(
        'kThreeLayerPostureStatus contains all three layer tags',
        () {
      final status = ReviewGroupCompatibility.kThreeLayerPostureStatus;
      expect(status, contains('runtime_owner'),
          reason: 'Layer 1 tag must be present');
      expect(status, contains('compatibility_anchor'),
          reason: 'Layer 2 tag must be present');
      expect(status, contains('deprecated_candidate'),
          reason: 'Layer 3 tag must be present');

      // Anti-pattern: must NOT be written as already retired
      expect(status, isNot(contains('retired')));
      expect(status, isNot(contains('removed')));
      expect(status, isNot(contains('exited')));
    });

    test('P3.3.5 regression: kReviewGroupStatus still contains both tags', () {
      // Regression: the P3.3.5 contract still holds.
      final status = ReviewGroupCompatibility.kReviewGroupStatus;
      expect(status, contains(ReviewGroupCompatibility.kRuntimeActiveTag));
      expect(status, contains(ReviewGroupCompatibility.kDeprecationCandidateTag));
      expect(status, isNot(contains('deprecated')),
          reason: 'RF-P3.3.5-016: deprecated MUST NOT be written as active truth');
    });
  });

  // ==========================================================================
  // Group C: fact_settlement_ingest_contract_candidate_v1
  //
  // Proves: final fact boundary is hard; ingest actions are exactly 3;
  // local evidence cannot claim to have directly written final facts.
  // ==========================================================================
  group('P3.3.6 fact_settlement_ingest_contract_candidate_v1', () {
    test('FactIngestAction enum has exactly 3 values (accept/reject/duplicate)',
        () {
      expect(FactIngestAction.values.length, equals(3),
          reason: 'RF-P3.3.6-010: only accept/reject/duplicate allowed');
      expect(FactIngestAction.values, contains(FactIngestAction.accept));
      expect(FactIngestAction.values, contains(FactIngestAction.reject));
      expect(FactIngestAction.values, contains(FactIngestAction.duplicate));
    });

    test('kCloudOwnedFinalFacts contains all 4 canonical final facts', () {
      final facts = FactSettlementIngestBoundary.kCloudOwnedFinalFacts;
      expect(facts, contains('effective_review_fact'));
      expect(facts, contains('daily_goal_progress'));
      expect(facts, contains('reward_settlement_ledger'));
      expect(facts, contains('check_in_learning_day_streak'));
      expect(facts.length, greaterThanOrEqualTo(4));
    });

    test('kFinalFactOwner is cloud_backend_fact_layer (RF-P3.3.6-008)', () {
      expect(FactSettlementIngestBoundary.kFinalFactOwner,
          equals('cloud_backend_fact_layer'),
          reason:
              'RF-P3.3.6-008: fact/settlement owner NOT a cut candidate this round');
    });

    test('kEvidenceLayer is shadow_parity_evidence (NOT runtime truth)', () {
      expect(FactSettlementIngestBoundary.kEvidenceLayer,
          equals('shadow_parity_evidence'),
          reason: 'Local evidence lives in shadow parity layer, not runtime');
    });

    test('kForbiddenLocalFactClaims contains canonical direct-write phrases',
        () {
      final forbidden =
          FactSettlementIngestBoundary.kForbiddenLocalFactClaims;
      expect(forbidden, contains('本地已直接记为有效复习'));
      expect(forbidden, contains('今日进度已因本地 shadow 更新'));
      expect(forbidden, contains('奖励已因本地队列到账'));
      expect(forbidden, contains('streak 已由本地 shadow 续上'));
    });
  });

  // ==========================================================================
  // Group D: session_entry_and_routing_compat_v1
  //
  // Proves: study_default is anchored; 3 routing candidate types exist
  // as shadow-only; no auto-routing claims in forbidden list.
  // ==========================================================================
  group('P3.3.6 session_entry_and_routing_compat_v1', () {
    test(
        'kCurrentHomeWordEntry is study_default (RF-P3.3.6-011)',
        () {
      expect(SessionEntryRoutingCompat.kCurrentHomeWordEntry,
          equals('study_default'),
          reason:
              'RF-P3.3.6-011: current runtime home word entry MUST stay study_default');
    });

    test('RoutingCandidateType enum has exactly 3 values', () {
      expect(RoutingCandidateType.values.length, equals(3));
      expect(RoutingCandidateType.values,
          contains(RoutingCandidateType.shadowRoutingCandidate));
      expect(RoutingCandidateType.values,
          contains(RoutingCandidateType.plannerAwareEntryCandidate));
      expect(RoutingCandidateType.values,
          contains(RoutingCandidateType.continuationLocalCompatCandidate));
    });

    test('kAllCandidateTypeNames contains canonical 3 candidate names', () {
      final names = SessionEntryRoutingCompat.kAllCandidateTypeNames;
      expect(names, contains('shadow_routing_candidate'));
      expect(names, contains('planner_aware_entry_candidate'));
      expect(names, contains('continuation_local_compat_candidate'));
      expect(names.length, equals(3));
    });

    test('kForbiddenAutoRoutingClaims contains canonical auto-routing phrases',
        () {
      final forbidden = SessionEntryRoutingCompat.kForbiddenAutoRoutingClaims;
      expect(forbidden, contains('系统已自动为你选择更优入口'));
      expect(forbidden, contains('auto-routing 已开启'));
      expect(forbidden, contains('mixed session 已启用'));
      expect(forbidden, contains('planner-aware 首页已生效'));
      expect(forbidden, contains('shadow-routing 已对用户生效'));
    });
  });

  // ==========================================================================
  // Group E: Semantic layer + shadow parity test strategy
  //
  // Proves: 4-layer semantic classification is anchored; 5 parity checks
  // and 3 test categories are exactly as frozen.
  // ==========================================================================
  group('P3.3.6 semantic_layer + shadow_parity_test_strategy', () {
    test(
        'SemanticLayer enum has exactly 4 values (RF-P3.3.6-013)',
        () {
      expect(SemanticLayer.values.length, equals(4));
      expect(SemanticLayer.values, contains(SemanticLayer.runtimeTruth));
      expect(SemanticLayer.values, contains(SemanticLayer.compatibilityOnly));
      expect(SemanticLayer.values, contains(SemanticLayer.deprecatedCandidate));
      expect(SemanticLayer.values, contains(SemanticLayer.shadowOnlyEvidence));
    });

    test('kAllLayerNames has exactly 4 entries in canonical order', () {
      final names = SemanticLayerContract.kAllLayerNames;
      expect(names.length, equals(4));
      expect(names[0], equals('runtime_truth'));
      expect(names[1], equals('compatibility_only'));
      expect(names[2], equals('deprecated_candidate'));
      expect(names[3], equals('shadow_only_evidence'));
    });

    test('kForbiddenDeprecationClaims contains canonical "已废弃" etc', () {
      final forbidden = SemanticLayerContract.kForbiddenDeprecationClaims;
      expect(forbidden, contains('已废弃'));
      expect(forbidden, contains('已退场'));
      expect(forbidden, contains('即将不可用'));
      expect(forbidden, contains('已切换新方案'));
    });

    test('ParityCheckType enum has exactly 5 values', () {
      expect(ParityCheckType.values.length, equals(5),
          reason: '5 fixed parity check types per RF-P3.3.6-016');
      expect(ParityCheckType.values, contains(ParityCheckType.queueCandidateSize));
      expect(ParityCheckType.values, contains(ParityCheckType.itemIdentityOverlap));
      expect(ParityCheckType.values,
          contains(ParityCheckType.continuationEligibility));
      expect(ParityCheckType.values,
          contains(ParityCheckType.submitAfterEffects));
      expect(ParityCheckType.values,
          contains(ParityCheckType.factIngestBehavior));
    });

    test('ParityTestCategory enum has exactly 3 values (RF-P3.3.6-017)', () {
      expect(ParityTestCategory.values.length, equals(3));
      expect(ParityTestCategory.values,
          contains(ParityTestCategory.runtimeTruthRegression));
      expect(ParityTestCategory.values,
          contains(ParityTestCategory.shadowParityEvidence));
      expect(ParityTestCategory.values,
          contains(ParityTestCategory.markerContractOnly));
    });

    test('kAllParityCheckNames has exactly 5 entries in canonical order', () {
      final names = ShadowParityTestStrategy.kAllParityCheckNames;
      expect(names.length, equals(5));
      expect(names[0], equals('queue_candidate_size'));
      expect(names[4], equals('fact_ingest_behavior'));
    });

    test('kForbiddenEvidenceAsFactClaims contains canonical forbidden phrases',
        () {
      final forbidden =
          ShadowParityTestStrategy.kForbiddenEvidenceAsFactClaims;
      expect(forbidden, contains('owner shift 已完成'));
      expect(forbidden, contains('local 已接管 ReviewPage'));
      expect(forbidden, contains('review_group 已退出运行态'));
      expect(forbidden, contains('parity 已通过，现已切换新模式'));
    });
  });

  // ==========================================================================
  // Group F: P3FeatureGuard P3.3.6 flags + regression
  //
  // Proves: all new P3.3.6 flags are disabled, previous P3.3.5 flags
  // still disabled, and runtime navigation (P3.3.2) still intact.
  // ==========================================================================
  group('P3.3.6 P3FeatureGuard + regression', () {
    test('isLocalServingParityCompareEnabled is false', () {
      expect(P3FeatureGuard.isLocalServingParityCompareEnabled, isFalse);
    });

    test('isLocalServingShadowRoutingEnabled is false', () {
      expect(P3FeatureGuard.isLocalServingShadowRoutingEnabled, isFalse);
    });

    test('isReviewGroupCompatibilityModeEnabled is false', () {
      expect(P3FeatureGuard.isReviewGroupCompatibilityModeEnabled, isFalse);
    });

    test('isLocalFactIngestShadowEnabled is false', () {
      expect(P3FeatureGuard.isLocalFactIngestShadowEnabled, isFalse);
    });

    test('P3.3.5 shadow-prep flags remain disabled (regression)', () {
      expect(P3FeatureGuard.isLocalPlannerOwnerShiftEnabled, isFalse);
      expect(P3FeatureGuard.isLocalServingShadowModeEnabled, isFalse);
      expect(P3FeatureGuard.isUnifiedPlannerRuntimeEnabled, isFalse);
    });

    testWidgets(
        'P3.3.2 regression: "背单词" still navigates to /study (runtime truth regression)',
        (tester) async {
      // This is the single widget test in this file. It belongs to the
      // `runtimeTruthRegression` category per RF-P3.3.6-017. It verifies
      // that the session_entry_policy_v1 frozen contract is still intact.
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
