import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:meow_mobile/core/api/api_client.dart';
import 'package:meow_mobile/core/gate/round_gates_and_guardrails.dart';
import 'package:meow_mobile/core/serving/local_review_queue_builder.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/serving/review_serving_seam.dart';
import 'package:meow_mobile/core/serving/rollback_hold_fallback_orchestration.dart';
import 'package:meow_mobile/core/serving/rollback_hold_fallback_runtime_watcher.dart';

// ============================================================================
// P3.3.16 — Real Cutover delivery tests
//
// This round: flag flipped true, seam Priority 3 wired to localNonContinuation,
// new POST /review-attempts/local-batch endpoint, ReviewPage local-session path.
//
// Test groups:
//   A. ReviewServingSeam — real cutover routing
//   B. ApiClient.submitLocalReviewBatch — serialization + HTTP
//   C. RollbackHoldFallbackRuntimeWatcher — watcher still correct after seam change
//   D. Feature guard + round anchor assertions
//   E. Cross-round regression
// ============================================================================

void main() {
  // ==========================================================================
  // Group A — ReviewServingSeam real cutover routing
  // ==========================================================================
  group('P3.3.16 Group A: ReviewServingSeam routes correctly after cutover', () {
    test('A1. flag=true + no continuation → localNonContinuation', () {
      final result = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: false,
      );
      expect(result.source, equals(ReviewServingSourceKind.localNonContinuation));
    });

    test('A2. reason string is cutover_flag_enabled_local_serving_active', () {
      final result = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: false,
      );
      expect(result.reason, equals('cutover_flag_enabled_local_serving_active'));
    });

    test('A3. isFallbackToRetainedAnchor is false for local path', () {
      final result = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: false,
      );
      expect(result.isFallbackToRetainedAnchor, isFalse);
    });

    test('A4. flag=true + active continuation → cloudReviewGroup (Priority 1 intact)', () {
      final result = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: true,
      );
      expect(result.source, equals(ReviewServingSourceKind.cloudReviewGroup));
      expect(result.reason, equals('retained_anchor_active_continuation'));
      expect(result.isFallbackToRetainedAnchor, isTrue);
    });

    test('A5. flag=false → cloudReviewGroup regardless (regression)', () {
      final result = ReviewServingSeam.selectSource(
        isCutoverEnabled: false,
        hasActiveContinuation: false,
      );
      expect(result.source, equals(ReviewServingSourceKind.cloudReviewGroup));
      expect(result.reason, equals('cutover_flag_disabled_default_cloud'));
    });

    test('A6. old fallback reason no longer produced', () {
      // P3.3.15 produced 'local_path_not_yet_wired_fallback_to_cloud' — gone now.
      final resultFlagOn = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: false,
      );
      final resultFlagOff = ReviewServingSeam.selectSource(
        isCutoverEnabled: false,
        hasActiveContinuation: false,
      );
      expect(
        resultFlagOn.reason,
        isNot(equals('local_path_not_yet_wired_fallback_to_cloud')),
      );
      expect(
        resultFlagOff.reason,
        isNot(equals('local_path_not_yet_wired_fallback_to_cloud')),
      );
    });
  });

  // ==========================================================================
  // Group B — ApiClient.submitLocalReviewBatch HTTP behaviour
  // ==========================================================================
  group('P3.3.16 Group B: ApiClient.submitLocalReviewBatch', () {
    Map<String, dynamic> _makeOkResponse({bool withSettlement = true}) => {
          'submit_status': 'accepted',
          'group_completed': true,
          'group_remaining': 0,
          'today_review_completed': 1,
          'daily_goal_status': 'completed',
          'already_exists': false,
          'settlement': withSettlement
              ? {
                  'source_event_id': 'se-local-001',
                  'reward_settlement_status': 'succeeded',
                  'reward_items': [
                    {
                      'reward_type': 'coins',
                      'amount': 5,
                      'reward_status': 'succeeded',
                    },
                  ],
                }
              : null,
        };

    test('B1. POSTs to /review-attempts/local-batch', () async {
      String? capturedPath;
      final client = MockClient((request) async {
        capturedPath = request.url.path;
        return http.Response(json.encode(_makeOkResponse()), 200);
      });

      final apiClient = ApiClient(client: client);
      await apiClient.submitLocalReviewBatch(
        attempts: [
          const LocalWordAttempt(wordId: 'w1', actionResult: 'correct'),
        ],
      );
      expect(capturedPath, equals('/api/v1/review-attempts/local-batch'));
      apiClient.dispose();
    });

    test('B2. serializes word_attempts array correctly', () async {
      Map<String, dynamic>? capturedBody;
      final client = MockClient((request) async {
        capturedBody = json.decode(request.body) as Map<String, dynamic>;
        return http.Response(json.encode(_makeOkResponse()), 200);
      });

      final apiClient = ApiClient(client: client);
      await apiClient.submitLocalReviewBatch(
        attempts: [
          const LocalWordAttempt(wordId: 'cet4-apple', actionResult: 'correct'),
          const LocalWordAttempt(wordId: 'cet4-book', actionResult: 'incorrect'),
        ],
      );

      expect(capturedBody, isNotNull);
      final attempts = capturedBody!['word_attempts'] as List;
      expect(attempts.length, equals(2));
      expect(attempts[0]['word_id'], equals('cet4-apple'));
      expect(attempts[0]['action_result'], equals('correct'));
      expect(attempts[1]['word_id'], equals('cet4-book'));
      expect(attempts[1]['action_result'], equals('incorrect'));
      apiClient.dispose();
    });

    test('B3. idempotency key sent as X-Idempotency-Key header', () async {
      String? capturedKey;
      final client = MockClient((request) async {
        capturedKey = request.headers['X-Idempotency-Key'];
        return http.Response(json.encode(_makeOkResponse()), 200);
      });

      final apiClient = ApiClient(client: client);
      await apiClient.submitLocalReviewBatch(
        attempts: [const LocalWordAttempt(wordId: 'w1', actionResult: 'correct')],
        idempotencyKey: 'local-batch-local_12345',
      );
      expect(capturedKey, equals('local-batch-local_12345'));
      apiClient.dispose();
    });

    test('B4. 200 response parses to ReviewAttemptResult correctly', () async {
      final client = MockClient((request) async {
        return http.Response(json.encode(_makeOkResponse()), 200);
      });

      final apiClient = ApiClient(client: client);
      final result = await apiClient.submitLocalReviewBatch(
        attempts: [const LocalWordAttempt(wordId: 'w1', actionResult: 'correct')],
        idempotencyKey: 'idem-key',
      );

      expect(result.submitStatus, equals('accepted'));
      expect(result.groupCompleted, isTrue);
      expect(result.groupRemaining, equals(0));
      expect(result.dailyGoalStatus, equals('completed'));
      expect(result.settlement, isNotNull);
      expect(result.settlement!.rewardSettlementStatus, equals('succeeded'));
      apiClient.dispose();
    });

    test('B5. non-200 response throws ApiException', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final apiClient = ApiClient(client: client);
      expect(
        () => apiClient.submitLocalReviewBatch(
          attempts: [const LocalWordAttempt(wordId: 'w1', actionResult: 'correct')],
        ),
        throwsA(isA<ApiException>()),
      );
      apiClient.dispose();
    });

    test('B6. no idempotency key → no X-Idempotency-Key header sent', () async {
      String? capturedKey;
      final client = MockClient((request) async {
        capturedKey = request.headers['X-Idempotency-Key'];
        return http.Response(json.encode(_makeOkResponse()), 200);
      });

      final apiClient = ApiClient(client: client);
      await apiClient.submitLocalReviewBatch(
        attempts: [const LocalWordAttempt(wordId: 'w1', actionResult: 'correct')],
      );
      expect(capturedKey, isNull);
      apiClient.dispose();
    });
  });

  // ==========================================================================
  // Group C — RollbackHoldFallbackRuntimeWatcher after seam change
  // ==========================================================================
  group('P3.3.16 Group C: Watcher still correct with new seam routing', () {
    test('C1. normalServing for local path (flag=true, no continuation, no failures)', () {
      final seamSelection = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: false,
      );
      // P3.3.16: local non-continuation path, no failures → normalServing
      final state = RollbackHoldFallbackRuntimeWatcher.detect(
        seamSelection: seamSelection,
      );
      expect(state, equals(RollbackHoldFallbackState.normalServing));
    });

    test('C2. rollback when localBuilderFailed=true', () {
      final seamSelection = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: false,
      );
      final state = RollbackHoldFallbackRuntimeWatcher.detect(
        seamSelection: seamSelection,
        localBuilderFailed: true,
      );
      expect(state, equals(RollbackHoldFallbackState.rollback));
    });

    test('C3. rollback when backendSubmitFailed on local session', () {
      final seamSelection = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: false,
      );
      final state = RollbackHoldFallbackRuntimeWatcher.detect(
        seamSelection: seamSelection,
        backendSubmitFailed: true,
      );
      expect(state, equals(RollbackHoldFallbackState.rollback));
    });

    test('C4. fallback for retained-anchor continuation path', () {
      final seamSelection = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: true,
      );
      // Active continuation → isFallbackToRetainedAnchor=true → fallback state
      final state = RollbackHoldFallbackRuntimeWatcher.detect(
        seamSelection: seamSelection,
      );
      expect(state, equals(RollbackHoldFallbackState.fallback));
    });
  });

  // ==========================================================================
  // Group D — Feature guard + round anchor assertions
  // ==========================================================================
  group('P3.3.16 Group D: Feature guard and round anchor', () {
    test('D1. isReviewPageNonContinuationCutoverEnabled is true', () {
      expect(
        P3FeatureGuard.isReviewPageNonContinuationCutoverEnabled,
        isTrue,
      );
    });

    test('D2. P3316 kStatus contains flag_flipped', () {
      expect(
        P3316RealCutoverRoundAnchor.kStatus,
        contains('flag_flipped'),
      );
    });

    test('D3. kS3Resolution is option_a_new_local_batch_endpoint', () {
      expect(
        P3316RealCutoverRoundAnchor.kS3Resolution,
        equals('option_a_new_local_batch_endpoint'),
      );
    });

    test('D4. kNewEndpoint is POST /review-attempts/local-batch', () {
      expect(
        P3316RealCutoverRoundAnchor.kNewEndpoint,
        equals('POST /review-attempts/local-batch'),
      );
    });

    test('D5. kRetainedAnchor references cloud active-continuation path', () {
      expect(
        P3316RealCutoverRoundAnchor.kRetainedAnchor,
        contains('active_continuation'),
      );
    });

    test('D6. kLandedComponents includes seam wiring and flag flip', () {
      expect(
        P3316RealCutoverRoundAnchor.kLandedComponents,
        contains('review_serving_seam_priority3_wired_to_local_non_continuation'),
      );
      expect(
        P3316RealCutoverRoundAnchor.kLandedComponents,
        contains('is_review_page_non_continuation_cutover_enabled_flipped_true'),
      );
    });

    test('D7. kCurrentStage chain links back to P3.3.15', () {
      expect(
        P3316RealCutoverRoundAnchor.kPreviousStage,
        contains('p3_3_15'),
      );
      expect(
        P3316RealCutoverRoundAnchor.kCurrentStage,
        contains('p3_3_16'),
      );
    });

    test('D8. P3.3.15 scaffolding marker still true (landmark preserved)', () {
      expect(P3FeatureGuard.isP3315DirectCutoverScaffoldingLanded, isTrue);
    });
  });

  // ==========================================================================
  // Group E — Cross-round regression
  // ==========================================================================
  group('P3.3.16 Group E: Cross-round regression', () {
    test('E1. ReviewServingSeam kRollbackTriggers unchanged (P3.3.14)', () {
      expect(ReviewServingSeam.kRollbackTriggers, isNotEmpty);
      expect(
        ReviewServingSeam.kRollbackTriggers,
        contains('requires_db_schema_or_api_core_semantics_change'),
      );
    });

    test('E2. kRollbackTarget still cloud_review_group path (P3.3.9)', () {
      expect(
        ReviewServingSeam.kRollbackTarget,
        equals('cloud_review_group_current_runtime_path'),
      );
    });

    test('E3. P3.3.15 kCurrentStage string preserved (chain integrity)', () {
      expect(
        P3315DirectCutoverScaffoldingRoundAnchor.kCurrentStage,
        contains('p3_3_15'),
      );
    });

    test('E4. P3316 kPreviousStage matches P3315 kCurrentStage exactly', () {
      expect(
        P3316RealCutoverRoundAnchor.kPreviousStage,
        equals(P3315DirectCutoverScaffoldingRoundAnchor.kCurrentStage),
      );
    });

    test('E5. LocalWordAttempt is a const-constructible value type', () {
      const attempt = LocalWordAttempt(wordId: 'w1', actionResult: 'correct');
      expect(attempt.wordId, equals('w1'));
      expect(attempt.actionResult, equals('correct'));
    });

    test('E6. isLocalOriginGroupId still detects local_ prefix', () {
      expect(
        LocalReviewQueueBuilder.isLocalOriginGroupId('local_12345'),
        isTrue,
      );
      expect(
        LocalReviewQueueBuilder.isLocalOriginGroupId('backend-uuid-abc'),
        isFalse,
      );
    });

    test('E7. RollbackHoldFallbackState enum has 4 values (contract unchanged)', () {
      expect(RollbackHoldFallbackState.values.length, equals(4));
      expect(
        RollbackHoldFallbackState.values.map((e) => e.name).toList(),
        containsAll(['normalServing', 'hold', 'rollback', 'fallback']),
      );
    });

    test('E8. P3316 kForbiddenClaims is non-empty (guardrail documented)', () {
      expect(P3316RealCutoverRoundAnchor.kForbiddenClaims, isNotEmpty);
      expect(
        P3316RealCutoverRoundAnchor.kForbiddenClaims,
        contains('review_group已退场'),
      );
    });

    test('E9. P3316 kNotDone still blocks review_group removal', () {
      expect(
        P3316RealCutoverRoundAnchor.kNotDone,
        contains('review_group_endpoint_removed_or_deprecated'),
      );
    });

    test('E10. ReviewAttemptResult.fromJson still parses settlement (regression)', () {
      final raw = {
        'submit_status': 'accepted',
        'group_completed': true,
        'group_remaining': 0,
        'today_review_completed': 2,
        'daily_goal_status': 'completed',
        'already_exists': false,
        'settlement': {
          'source_event_id': 'se-001',
          'reward_settlement_status': 'succeeded',
          'reward_items': [
            {'reward_type': 'coins', 'amount': 5, 'reward_status': 'succeeded'},
          ],
        },
      };
      final result = ReviewAttemptResult.fromJson(raw);
      expect(result.groupCompleted, isTrue);
      expect(result.settlement, isNotNull);
      expect(result.settlement!.rewardSettlementStatus, equals('succeeded'));
    });
  });
}
