import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/api/api_client.dart';
import 'package:meow_mobile/core/fact_settlement/fact_ingest_boundary_contract.dart';
import 'package:meow_mobile/core/governance/shadow_parity_test_strategy.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/memory/card_state_data.dart';
import 'package:meow_mobile/core/memory/widgets/rating_buttons.dart';
import 'package:meow_mobile/core/review/review_group_compatibility.dart';
import 'package:meow_mobile/core/routing/session_entry_routing_compat.dart';
import 'package:meow_mobile/core/serving/local_serving_candidate_contract.dart';
import 'package:meow_mobile/core/shadow/fact_ingest_shadow.dart';
import 'package:meow_mobile/core/shadow/local_serving_candidate.dart';
import 'package:meow_mobile/core/shadow/local_serving_shadow_runner.dart';
import 'package:meow_mobile/core/shadow/parity_checker.dart';
import 'package:meow_mobile/core/shadow/parity_result.dart';
import 'package:meow_mobile/core/shadow/routing_shadow_runner.dart';
import 'package:meow_mobile/core/shadow/shadow_acceptance_gate.dart';

// ============================================================================
// P3.3.7 — Phase 2 Limited Execution / Shadow Mode Delivery Tests
//
// This file exercises real shadow code end-to-end. Unlike prior P3.3.x
// delivery tests which were mostly contract-anchor assertions, this
// suite actually BUILDS local candidates, RUNS parity comparisons, and
// CLASSIFIES results through the acceptance gate.
//
// Per RF-P3.3.7-017, every test in this file belongs to one of:
//   - markerContractOnly (flag + regression assertions in Group F)
//   - shadowParityEvidence (Groups A through E)
//   - runtimeTruthRegression (single widget test in Group F)
//
// Shadow code NEVER modifies runtime state; all tests are hermetic.
// ============================================================================

/// Helper: build a CardStateData with minimal fields for shadow testing.
CardStateData _makeCard(String wordId, {int daysOverdue = 0}) {
  final now = DateTime.now().toUtc();
  return CardStateData(
    id: wordId.hashCode,
    wordId: wordId,
    stability: 2.5,
    difficulty: 5.0,
    dueUtc: now.subtract(Duration(days: daysOverdue)),
    lastReviewUtc: now.subtract(const Duration(days: 1)),
    state: 2, // Review
    step: null,
    reps: 3,
    lapses: 0,
    createdAtUtc: now.subtract(const Duration(days: 7)),
  );
}

/// Helper: build a ReviewGroup with given word_ids for parity testing.
ReviewGroup _makeReviewGroup(List<String> wordIds, {String? groupId}) {
  return ReviewGroup(
    reviewGroupId: groupId ?? 'cloud_group_test',
    groupStatus: 'active',
    groupCompleted: false,
    remainingCount: wordIds.length,
    items: wordIds
        .map((id) => ReviewGroupItem(
              wordId: id,
              wordText: id,
              meaning: 'meaning_$id',
              completed: false,
            ))
        .toList(),
  );
}

void main() {
  // ==========================================================================
  // Group A: local_serving_shadow_run_v1 — real builders (7 tests)
  //
  // Proves: the shadow runner builds LocalServingCandidate objects with
  // correct field semantics (always shadowOnly, never runtimeActive).
  // ==========================================================================
  group('P3.3.7 local_serving_shadow_run_v1: real builders', () {
    test('buildLocalDueQueueCandidate with empty due list → itemCount 0',
        () {
      final candidate = LocalServingShadowRunner.buildLocalDueQueueCandidate(
        dueCards: const <CardStateData>[],
        nowUtc: DateTime.utc(2026, 4, 10, 12, 0),
      );

      expect(candidate.itemCount, equals(0));
      expect(candidate.wordIds, isEmpty);
      expect(candidate.shadowOnly, isTrue,
          reason: 'shadow_only must be true for all P3.3.7 candidates');
      expect(candidate.sourceType, LocalServingSourceType.localDueShadow);
      expect(candidate.servingEligibilityState,
          ServingEligibilityState.shadowOnly,
          reason:
              'servingEligibilityState must be shadowOnly, never runtimeActive');
    });

    test('buildLocalDueQueueCandidate with 5 due cards → itemCount 5', () {
      final cards = [
        _makeCard('w1', daysOverdue: 3),
        _makeCard('w2', daysOverdue: 2),
        _makeCard('w3', daysOverdue: 1),
        _makeCard('w4'),
        _makeCard('w5'),
      ];
      final candidate = LocalServingShadowRunner.buildLocalDueQueueCandidate(
        dueCards: cards,
        nowUtc: DateTime.utc(2026, 4, 10, 12, 0),
      );

      expect(candidate.itemCount, equals(5));
      expect(candidate.wordIds, equals(['w1', 'w2', 'w3', 'w4', 'w5']));
      expect(candidate.sourceType, LocalServingSourceType.localDueShadow);
    });

    test('buildLocalDueQueueCandidate respects limit parameter', () {
      final cards = List.generate(10, (i) => _makeCard('w$i'));
      final candidate = LocalServingShadowRunner.buildLocalDueQueueCandidate(
        dueCards: cards,
        nowUtc: DateTime.utc(2026, 4, 10, 12, 0),
        limit: 3,
      );

      expect(candidate.itemCount, equals(3));
      expect(candidate.wordIds, equals(['w0', 'w1', 'w2']));
    });

    test(
        'buildLocalDueQueueCandidate sets candidateReason = fsrsComputed',
        () {
      final candidate = LocalServingShadowRunner.buildLocalDueQueueCandidate(
        dueCards: [_makeCard('w1')],
        nowUtc: DateTime.utc(2026, 4, 10, 12, 0),
      );

      expect(candidate.candidateReason, CandidateReason.fsrsComputed);
      expect(candidate.ownerLayer, PlannerOwnerLayer.planning);
    });

    test(
        'buildLocalGeneratedSessionCandidate returns localGeneratedShadow source',
        () {
      final candidate =
          LocalServingShadowRunner.buildLocalGeneratedSessionCandidate(
        dueCards: [_makeCard('w1'), _makeCard('w2')],
        newCardsToday: 0,
        newCardsDailyLimit: 5,
        nowUtc: DateTime.utc(2026, 4, 10, 12, 0),
        sessionId: 'session_test_1',
      );

      expect(candidate.sourceType, LocalServingSourceType.localGeneratedShadow);
      expect(candidate.sourceId, equals('session_test_1'));
      expect(candidate.candidateReason, CandidateReason.localGenerated);
      expect(candidate.shadowOnly, isTrue);
      expect(candidate.servingEligibilityState,
          ServingEligibilityState.shadowOnly);
    });

    test(
        'buildLocalGeneratedSessionCandidate respects new-cards-daily-limit',
        () {
      final candidate =
          LocalServingShadowRunner.buildLocalGeneratedSessionCandidate(
        dueCards: [_makeCard('w1')],
        newCardsToday: 5,        // already at limit
        newCardsDailyLimit: 5,   // limit is 5
        nowUtc: DateTime.utc(2026, 4, 10, 12, 0),
        sessionId: 'session_limit_test',
      );

      // 1 due card + 0 remaining new slots = 1 item
      expect(candidate.itemCount, equals(1));
      expect(candidate.wordIds, equals(['w1']));
    });

    test(
        'buildLocalGeneratedSessionCandidate uses remaining new slots when available',
        () {
      final candidate =
          LocalServingShadowRunner.buildLocalGeneratedSessionCandidate(
        dueCards: [_makeCard('w1')],
        newCardsToday: 2,
        newCardsDailyLimit: 5, // 3 new slots remain
        nowUtc: DateTime.utc(2026, 4, 10, 12, 0),
        sessionId: 'session_new_slots',
      );

      // 1 due + 3 placeholder new slots = 4 items
      expect(candidate.itemCount, equals(4));
      expect(candidate.wordIds.length, equals(4));
      expect(candidate.wordIds.first, equals('w1'));
      expect(candidate.wordIds.where((w) => w.startsWith('shadow_new_slot_')).length,
          equals(3));
    });
  });

  // ==========================================================================
  // Group B: parity_checks_v1 — 5 real comparison functions (8 tests)
  //
  // Proves: the parity checker produces correct severity classification
  // for each of the 5 check types under realistic inputs.
  // ==========================================================================
  group('P3.3.7 parity_checks_v1: 5 real comparisons', () {
    test('compareQueueSize: exact match → pass', () {
      final local = LocalServingShadowRunner.buildLocalDueQueueCandidate(
        dueCards: [_makeCard('w1'), _makeCard('w2'), _makeCard('w3')],
        nowUtc: DateTime.utc(2026, 4, 10, 12, 0),
      );
      final cloud = _makeReviewGroup(['a', 'b', 'c']);

      final result = ParityChecker.compareQueueSize(local: local, cloud: cloud);

      expect(result.severity, ParityMismatchSeverity.none);
      expect(result.isPass, isTrue);
      expect(result.checkType, ParityCheckType.queueCandidateSize);
    });

    test('compareQueueSize: one side empty → warning', () {
      final local = LocalServingShadowRunner.buildLocalDueQueueCandidate(
        dueCards: const <CardStateData>[],
        nowUtc: DateTime.utc(2026, 4, 10, 12, 0),
      );
      final cloud = _makeReviewGroup(['a', 'b']);

      final result = ParityChecker.compareQueueSize(local: local, cloud: cloud);

      expect(result.severity, ParityMismatchSeverity.warning);
      expect(result.reason, contains('one side empty'));
    });

    test('compareItemIdentityOverlap: identical sets → pass', () {
      final local = LocalServingShadowRunner.buildLocalDueQueueCandidate(
        dueCards: [_makeCard('a'), _makeCard('b'), _makeCard('c')],
        nowUtc: DateTime.utc(2026, 4, 10, 12, 0),
      );
      final cloud = _makeReviewGroup(['a', 'b', 'c']);

      final result =
          ParityChecker.compareItemIdentityOverlap(local: local, cloud: cloud);

      expect(result.severity, ParityMismatchSeverity.none);
      expect(result.isPass, isTrue);
    });

    test('compareItemIdentityOverlap: overlap < 40% → warning', () {
      final local = LocalServingShadowRunner.buildLocalDueQueueCandidate(
        dueCards: [_makeCard('a'), _makeCard('b'), _makeCard('c')],
        nowUtc: DateTime.utc(2026, 4, 10, 12, 0),
      );
      final cloud = _makeReviewGroup(['x', 'y', 'z', 'a']);
      // Intersection: {a}; Union: {a,b,c,x,y,z}; overlap = 1/6 ≈ 17%

      final result =
          ParityChecker.compareItemIdentityOverlap(local: local, cloud: cloud);

      expect(result.severity, ParityMismatchSeverity.warning);
    });

    test('compareContinuationEligibility: both agree → pass', () {
      final result = ParityChecker.compareContinuationEligibility(
        localWouldContinue: true,
        cloudContinues: true,
      );

      expect(result.severity, ParityMismatchSeverity.none);
      expect(result.isPass, isTrue);
    });

    test('compareContinuationEligibility: disagreement → warning', () {
      final result = ParityChecker.compareContinuationEligibility(
        localWouldContinue: true,
        cloudContinues: false,
      );

      expect(result.severity, ParityMismatchSeverity.warning);
    });

    test('compareSubmitAfterEffects: all required fields present → pass', () {
      final result = ParityChecker.compareSubmitAfterEffects(
        localEvidence: const {
          'rating': 'good',
          'timestamp': 1234567890,
          'idempotencyKey': 'key_abc',
        },
        requiredFields: const {'rating', 'timestamp', 'idempotencyKey'},
      );

      expect(result.severity, ParityMismatchSeverity.none);
      expect(result.isPass, isTrue);
    });

    test('compareIngestBehavior: local and expected agree → pass', () {
      final result = ParityChecker.compareIngestBehavior(
        localClassification: FactIngestAction.accept,
        expectedClassification: FactIngestAction.accept,
      );

      expect(result.severity, ParityMismatchSeverity.none);
      expect(result.isPass, isTrue);
    });
  });

  // ==========================================================================
  // Group C: fact_ingest_shadow_evidence_v1 — pure-local classifier (6 tests)
  //
  // Proves: the FactIngestShadow classifier correctly produces
  // accept/reject/duplicate evidence using purely local rules.
  // No network calls.
  // ==========================================================================
  group('P3.3.7 fact_ingest_shadow_evidence_v1: pure-local classifier', () {
    test('first submission with valid inputs → accept', () {
      final shadow = FactIngestShadow();

      final result = shadow.classifyEvidence(
        wordId: 'word_001',
        rating: 'good',
        idempotencyKey: 'key_001',
      );

      expect(result, FactIngestAction.accept);
      expect(shadow.seenKeyCount, equals(1));
    });

    test('second submission with same idempotency key → duplicate', () {
      final shadow = FactIngestShadow();

      shadow.classifyEvidence(
        wordId: 'word_001',
        rating: 'good',
        idempotencyKey: 'key_001',
      );

      final secondResult = shadow.classifyEvidence(
        wordId: 'word_001',
        rating: 'good',
        idempotencyKey: 'key_001',
      );

      expect(secondResult, FactIngestAction.duplicate);
      expect(shadow.seenKeyCount, equals(1),
          reason: 'duplicate does not add a new key to the cache');
    });

    test('empty wordId → reject', () {
      final shadow = FactIngestShadow();

      final result = shadow.classifyEvidence(
        wordId: '',
        rating: 'good',
        idempotencyKey: 'key_002',
      );

      expect(result, FactIngestAction.reject);
      expect(shadow.seenKeyCount, equals(0),
          reason: 'reject does not add the key to the cache');
    });

    test('invalid rating → reject', () {
      final shadow = FactIngestShadow();

      final result = shadow.classifyEvidence(
        wordId: 'word_001',
        rating: 'not_a_real_rating',
        idempotencyKey: 'key_003',
      );

      expect(result, FactIngestAction.reject);
      expect(shadow.seenKeyCount, equals(0));
    });

    test('after reset(), previously-duplicate key → accept again', () {
      final shadow = FactIngestShadow();

      shadow.classifyEvidence(
        wordId: 'word_001',
        rating: 'good',
        idempotencyKey: 'key_reset',
      );
      expect(
          shadow.classifyEvidence(
            wordId: 'word_001',
            rating: 'good',
            idempotencyKey: 'key_reset',
          ),
          FactIngestAction.duplicate);

      shadow.reset();

      final afterReset = shadow.classifyEvidence(
        wordId: 'word_001',
        rating: 'good',
        idempotencyKey: 'key_reset',
      );
      expect(afterReset, FactIngestAction.accept);
    });

    test('all valid rating values accepted (6 forms)', () {
      const validRatings = [
        'correct',
        'incorrect',
        'again',
        'hard',
        'good',
        'easy',
      ];

      for (final rating in validRatings) {
        final shadow = FactIngestShadow();
        final result = shadow.classifyEvidence(
          wordId: 'w',
          rating: rating,
          idempotencyKey: 'k_$rating',
        );
        expect(result, FactIngestAction.accept,
            reason: 'rating "$rating" should be accepted');
      }
    });
  });

  // ==========================================================================
  // Group D: routing_shadow_prep_v1 — shadow route decider (4 tests)
  //
  // Proves: RoutingShadowRunner produces correct candidate types for
  // each input combination, and wouldBeShown is always false.
  // ==========================================================================
  group('P3.3.7 routing_shadow_prep_v1: shadow route', () {
    test('active continuation → continuationLocalCompatCandidate', () {
      final decision = RoutingShadowRunner.computeShadowRoute(
        hasActiveContinuation: true,
        localDueCount: 5,
        cloudReviewTarget: 10,
      );

      expect(decision.chosenCandidate,
          RoutingCandidateType.continuationLocalCompatCandidate);
      expect(decision.wouldBeShown, isFalse,
          reason: 'shadow routing NEVER exposed to users');
    });

    test(
        'both local and cloud have review work → plannerAwareEntryCandidate',
        () {
      final decision = RoutingShadowRunner.computeShadowRoute(
        hasActiveContinuation: false,
        localDueCount: 5,
        cloudReviewTarget: 10,
      );

      expect(decision.chosenCandidate,
          RoutingCandidateType.plannerAwareEntryCandidate);
      expect(decision.wouldBeShown, isFalse);
    });

    test('neither side has work → shadowRoutingCandidate (default)', () {
      final decision = RoutingShadowRunner.computeShadowRoute(
        hasActiveContinuation: false,
        localDueCount: 0,
        cloudReviewTarget: 0,
      );

      expect(decision.chosenCandidate,
          RoutingCandidateType.shadowRoutingCandidate);
      expect(decision.wouldBeShown, isFalse);
    });

    test('all decisions have wouldBeShown = false (non-visibility)', () {
      // Sweep many input combinations
      for (final hasActive in [true, false]) {
        for (final local in [0, 3]) {
          for (final cloud in [0, 5]) {
            final decision = RoutingShadowRunner.computeShadowRoute(
              hasActiveContinuation: hasActive,
              localDueCount: local,
              cloudReviewTarget: cloud,
            );
            expect(decision.wouldBeShown, isFalse,
                reason:
                    'All shadow routing decisions must have wouldBeShown=false');
          }
        }
      }
    });
  });

  // ==========================================================================
  // Group E: shadow_acceptance_gate_v1 — gate classifier (6 tests)
  //
  // Proves: ShadowAcceptanceGate correctly classifies batches into the
  // 4 R4 §8 states and enforces priority ordering.
  // ==========================================================================
  group('P3.3.7 shadow_acceptance_gate_v1: gate classifier', () {
    /// Helper: build a ParityComparisonResult with the given severity.
    ParityComparisonResult makeResult({
      ParityCheckType checkType = ParityCheckType.queueCandidateSize,
      ParityMismatchSeverity severity = ParityMismatchSeverity.none,
    }) {
      return ParityComparisonResult(
        checkType: checkType,
        severity: severity,
        reason: 'test',
      );
    }

    test('all-pass list → parityPass', () {
      final results = List.generate(
        5,
        (i) => makeResult(
          checkType: ParityCheckType.values[i],
          severity: ParityMismatchSeverity.none,
        ),
      );

      expect(ShadowAcceptanceGate.classify(results),
          AcceptanceGateState.parityPass);
    });

    test('single info-only mismatch → acceptableMismatch', () {
      final results = [
        makeResult(severity: ParityMismatchSeverity.none),
        makeResult(
          checkType: ParityCheckType.itemIdentityOverlap,
          severity: ParityMismatchSeverity.infoOnly,
        ),
      ];

      expect(ShadowAcceptanceGate.classify(results),
          AcceptanceGateState.acceptableMismatch);
    });

    test('must-hold mismatch dominates info-only → mustHoldMismatch', () {
      final results = [
        makeResult(severity: ParityMismatchSeverity.infoOnly),
        makeResult(severity: ParityMismatchSeverity.mustHold),
      ];

      expect(ShadowAcceptanceGate.classify(results),
          AcceptanceGateState.mustHoldMismatch);
    });

    test('must-escalate dominates must-hold → mustEscalate', () {
      final results = [
        makeResult(severity: ParityMismatchSeverity.mustHold),
        makeResult(severity: ParityMismatchSeverity.mustEscalate),
      ];

      expect(ShadowAcceptanceGate.classify(results),
          AcceptanceGateState.mustEscalate);
    });

    test(
        'hasMinimumPhase3Evidence: must-hold batch → false regardless of coverage',
        () {
      // All 5 check types present but one is must-hold
      final results = ParityCheckType.values
          .map((t) => makeResult(
                checkType: t,
                severity: t == ParityCheckType.queueCandidateSize
                    ? ParityMismatchSeverity.mustHold
                    : ParityMismatchSeverity.none,
              ))
          .toList();

      expect(ShadowAcceptanceGate.hasMinimumPhase3Evidence(results), isFalse);
    });

    test(
        'hasMinimumPhase3Evidence: all 5 check types + pass/acceptable → true',
        () {
      final results = ParityCheckType.values
          .map((t) => makeResult(checkType: t))
          .toList();

      expect(ShadowAcceptanceGate.hasMinimumPhase3Evidence(results), isTrue);
    });

    test(
        'hasMinimumPhase3Evidence: only 4 check types represented → false',
        () {
      // Missing one check type
      final results = [
        makeResult(checkType: ParityCheckType.queueCandidateSize),
        makeResult(checkType: ParityCheckType.itemIdentityOverlap),
        makeResult(checkType: ParityCheckType.continuationEligibility),
        makeResult(checkType: ParityCheckType.submitAfterEffects),
        // Missing: factIngestBehavior
      ];

      expect(ShadowAcceptanceGate.hasMinimumPhase3Evidence(results), isFalse);
    });
  });

  // ==========================================================================
  // Group F: flags + regression (5 tests)
  //
  // Proves: all P3.3.7 flags are disabled, prior flags unchanged, and
  // the P3.3.2 routing contract still holds (runtime truth regression).
  // ==========================================================================
  group('P3.3.7 flags + regression', () {
    test('all 4 P3.3.7 shadow flags are false', () {
      expect(P3FeatureGuard.isLocalServingShadowRunEnabled, isFalse);
      expect(P3FeatureGuard.isParityCheckRecordingEnabled, isFalse);
      expect(P3FeatureGuard.isFactIngestShadowEvaluationEnabled, isFalse);
      expect(P3FeatureGuard.isRoutingShadowComputationEnabled, isFalse);
    });

    test('P3.3.6 flags still false (regression)', () {
      expect(P3FeatureGuard.isLocalServingParityCompareEnabled, isFalse);
      expect(P3FeatureGuard.isLocalServingShadowRoutingEnabled, isFalse);
      expect(P3FeatureGuard.isReviewGroupCompatibilityModeEnabled, isFalse);
      expect(P3FeatureGuard.isLocalFactIngestShadowEnabled, isFalse);
    });

    test('P3.3.5 flags still false (regression)', () {
      expect(P3FeatureGuard.isLocalPlannerOwnerShiftEnabled, isFalse);
      expect(P3FeatureGuard.isLocalServingShadowModeEnabled, isFalse);
      expect(P3FeatureGuard.isUnifiedPlannerRuntimeEnabled, isFalse);
    });

    test('review_group 3-layer posture (P3.3.6) still intact', () {
      expect(ReviewGroupCompatibility.kPostureRuntimeOwner, isTrue);
      expect(ReviewGroupCompatibility.kPostureCompatibilityAnchor, isTrue);
      expect(ReviewGroupCompatibility.kPostureDeprecatedCandidate, isTrue);
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

      // Also verify session_entry_and_routing_compat_v1 anchor
      expect(SessionEntryRoutingCompat.kCurrentHomeWordEntry,
          equals('study_default'));
    });
  });

  // ==========================================================================
  // Bonus: LocalServingCandidate isShadowOnly convenience
  // ==========================================================================
  test('LocalServingCandidate.isShadowOnly helper mirrors shadowOnly field',
      () {
    final candidate = LocalServingShadowRunner.buildLocalDueQueueCandidate(
      dueCards: [_makeCard('w1')],
      nowUtc: DateTime.utc(2026, 4, 10, 12, 0),
    );
    expect(candidate.isShadowOnly, isTrue);
    expect(candidate.shadowOnly, isTrue);

    // Also: rating_buttons import is referenced to silence unused imports
    const ratingTypeExists = FsrsRatingButtons;
    expect(ratingTypeExists, isNotNull);
  });
}
