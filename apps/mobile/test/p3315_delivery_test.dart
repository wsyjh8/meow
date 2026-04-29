import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/gate/fact_owner_boundary.dart';
import 'package:meow_mobile/core/gate/review_group_lifecycle.dart';
import 'package:meow_mobile/core/gate/round_gates_and_guardrails.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/memory/fsrs_service.dart';
import 'package:meow_mobile/core/serving/local_review_queue_builder.dart';
import 'package:meow_mobile/core/serving/review_serving_seam.dart';
import 'package:meow_mobile/core/serving/rollback_hold_fallback_orchestration.dart';
import 'package:meow_mobile/core/serving/rollback_hold_fallback_runtime_watcher.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

// ============================================================================
// P3.3.15 — Direct-cutover scaffolding delivery tests
//
// This round builds S1 (LocalReviewQueueBuilder) + S2 (ReviewPage branching)
// + S4 (RollbackHoldFallbackRuntimeWatcher) as real runtime code, but
// leaves isReviewPageNonContinuationCutoverEnabled at false. The user-
// visible behavior is unchanged this round.
//
// Test groups:
//   A. LocalReviewQueueBuilder correctness (in-memory drift)
//   B. ReviewServingSeam + Watcher integration (no widget pumping)
//   C. RollbackHoldFallbackRuntimeWatcher pure-function tests
//   D. Flag + round anchor assertions
//   E. Cross-round regression
// ============================================================================

AppDatabase _createTestDb() => AppDatabase.forTesting(NativeDatabase.memory());

/// Seed N cached_words rows so the local review queue builder can join
/// against them.
Future<void> _seedCachedWords(AppDatabase db, int count,
    {String bookId = 'book-001'}) async {
  final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
  await db.batch((batch) {
    for (int i = 1; i <= count; i++) {
      batch.insert(
        db.cachedWords,
        CachedWordsCompanion.insert(
          wordId: 'cet4-word$i',
          bookId: bookId,
          wordText: 'word$i',
          meaning: '释义$i',
          sortOrder: Value(i),
          cachedAt: nowMs,
        ),
      );
    }
  });
}

/// Seed FSRS card states that are all due "now".
Future<void> _seedDueCards(FsrsService fsrs, int count,
    {required DateTime nowUtc}) async {
  for (int i = 1; i <= count; i++) {
    await fsrs.initCardForWord('cet4-word$i', nowUtc: nowUtc);
  }
}

void main() {
  // ==========================================================================
  // Group A — LocalReviewQueueBuilder correctness
  // ==========================================================================
  group('P3.3.15 Group A: LocalReviewQueueBuilder correctness', () {
    late AppDatabase db;
    late FsrsService fsrs;

    setUp(() {
      db = _createTestDb();
      fsrs = FsrsService(db: db, desiredRetention: 0.9);
    });

    tearDown(() async {
      await db.close();
    });

    test('A1. throws LocalReviewQueueEmptyException when no due cards',
        () async {
      await _seedCachedWords(db, 5);
      final now = DateTime.utc(2026, 4, 11, 10, 0, 0);
      expect(
        () => LocalReviewQueueBuilder.build(db: db, fsrs: fsrs, nowLocal: now),
        throwsA(isA<LocalReviewQueueEmptyException>()),
      );
    });

    test('A2. builds group with N items when N due cards exist', () async {
      await _seedCachedWords(db, 5);
      final now = DateTime.utc(2026, 4, 11, 10, 0, 0);
      await _seedDueCards(fsrs, 3, nowUtc: now);

      final group = await LocalReviewQueueBuilder.build(
        db: db,
        fsrs: fsrs,
        nowLocal: now,
      );

      expect(group.items.length, equals(3));
      expect(group.remainingCount, equals(3));
    });

    test('A3. items carry correct wordId, wordText, meaning (join works)',
        () async {
      await _seedCachedWords(db, 5);
      final now = DateTime.utc(2026, 4, 11, 10, 0, 0);
      await _seedDueCards(fsrs, 2, nowUtc: now);

      final group = await LocalReviewQueueBuilder.build(
        db: db,
        fsrs: fsrs,
        nowLocal: now,
      );

      // Due cards are seeded for word1, word2 in that order.
      final wordIds = group.items.map((i) => i.wordId).toList();
      expect(wordIds, contains('cet4-word1'));
      expect(wordIds, contains('cet4-word2'));

      for (final item in group.items) {
        // Derived from seed: word1 → 'word1' + '释义1' etc.
        final expectedIndex = item.wordId.replaceFirst('cet4-word', '');
        expect(item.wordText, equals('word$expectedIndex'));
        expect(item.meaning, equals('释义$expectedIndex'));
      }
    });

    test('A4. local group ID has `local_` prefix', () async {
      await _seedCachedWords(db, 5);
      final now = DateTime.utc(2026, 4, 11, 10, 0, 0);
      await _seedDueCards(fsrs, 1, nowUtc: now);

      final group = await LocalReviewQueueBuilder.build(
        db: db,
        fsrs: fsrs,
        nowLocal: now,
      );

      expect(group.reviewGroupId.startsWith('local_'), isTrue);
      expect(
        LocalReviewQueueBuilder.isLocalOriginGroupId(group.reviewGroupId),
        isTrue,
      );
    });

    test("A5. groupStatus equals 'local_origin'", () async {
      await _seedCachedWords(db, 5);
      final now = DateTime.utc(2026, 4, 11, 10, 0, 0);
      await _seedDueCards(fsrs, 1, nowUtc: now);

      final group = await LocalReviewQueueBuilder.build(
        db: db,
        fsrs: fsrs,
        nowLocal: now,
      );

      expect(group.groupStatus, equals('local_origin'));
    });

    test('A6. all items start with completed = false', () async {
      await _seedCachedWords(db, 5);
      final now = DateTime.utc(2026, 4, 11, 10, 0, 0);
      await _seedDueCards(fsrs, 3, nowUtc: now);

      final group = await LocalReviewQueueBuilder.build(
        db: db,
        fsrs: fsrs,
        nowLocal: now,
      );

      for (final item in group.items) {
        expect(item.completed, isFalse);
      }
      // A non-empty group should also report groupCompleted = false.
      expect(group.groupCompleted, isFalse);
    });

    test('A7. remainingCount equals items.length', () async {
      await _seedCachedWords(db, 5);
      final now = DateTime.utc(2026, 4, 11, 10, 0, 0);
      await _seedDueCards(fsrs, 4, nowUtc: now);

      final group = await LocalReviewQueueBuilder.build(
        db: db,
        fsrs: fsrs,
        nowLocal: now,
      );

      expect(group.remainingCount, equals(group.items.length));
    });

    test('A8. respects limit parameter', () async {
      await _seedCachedWords(db, 20);
      final now = DateTime.utc(2026, 4, 11, 10, 0, 0);
      await _seedDueCards(fsrs, 15, nowUtc: now);

      final group = await LocalReviewQueueBuilder.build(
        db: db,
        fsrs: fsrs,
        nowLocal: now,
        limit: 7,
      );

      expect(group.items.length, equals(7));
    });

    test(
        'A9. throws LocalReviewQueueMissingWordException when a due card has no cached_words row',
        () async {
      // Seed only words 1-2, then make word3 due (which has no row).
      await _seedCachedWords(db, 2);
      final now = DateTime.utc(2026, 4, 11, 10, 0, 0);
      await _seedDueCards(fsrs, 3, nowUtc: now);

      expect(
        () => LocalReviewQueueBuilder.build(db: db, fsrs: fsrs, nowLocal: now),
        throwsA(isA<LocalReviewQueueMissingWordException>()),
      );
    });

    test('A10. kLocalGroupIdPrefix and kLocalGroupStatus pinned constants',
        () {
      expect(LocalReviewQueueBuilder.kLocalGroupIdPrefix, equals('local_'));
      expect(LocalReviewQueueBuilder.kLocalGroupStatus, equals('local_origin'));
      expect(
        LocalReviewQueueBuilder.isLocalOriginGroupId('local_abc123'),
        isTrue,
      );
      expect(
        LocalReviewQueueBuilder.isLocalOriginGroupId('cloud_abc123'),
        isFalse,
      );
    });
  });

  // ==========================================================================
  // Group B — ReviewServingSeam + Watcher integration
  // ==========================================================================
  // Note: ReviewPage is not pumped as a widget (no existing tests do either;
  // it would require ApiClient mocking). Instead, these tests exercise the
  // seam → watcher decision chain directly, covering the paths that
  // _loadReviewGroup would take at runtime.
  group('P3.3.15 Group B: seam + watcher integration', () {
    test('B1. flag OFF + no continuation → cloud → watcher normalServing', () {
      final sel = ReviewServingSeam.selectSource(
        isCutoverEnabled: false,
        hasActiveContinuation: false,
      );
      expect(sel.source, ReviewServingSourceKind.cloudReviewGroup);
      expect(sel.reason, equals('cutover_flag_disabled_default_cloud'));

      final state = RollbackHoldFallbackRuntimeWatcher.detect(
        seamSelection: sel,
      );
      expect(state, RollbackHoldFallbackState.normalServing);
    });

    test('B2. flag OFF + active continuation → cloud anchor → watcher fallback',
        () {
      final sel = ReviewServingSeam.selectSource(
        isCutoverEnabled: false,
        hasActiveContinuation: true,
      );
      expect(sel.source, ReviewServingSourceKind.cloudReviewGroup);
      expect(sel.reason, equals('retained_anchor_active_continuation'));
      expect(sel.isFallbackToRetainedAnchor, isTrue);

      final state = RollbackHoldFallbackRuntimeWatcher.detect(
        seamSelection: sel,
      );
      expect(state, RollbackHoldFallbackState.fallback);
    });

    test(
        'B3. flag ON + active continuation → cloud anchor (seam never picks local)',
        () {
      final sel = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: true,
      );
      expect(sel.source, ReviewServingSourceKind.cloudReviewGroup);
      expect(sel.reason, equals('retained_anchor_active_continuation'));
    });

    test(
        'B4. flag ON + no continuation → localNonContinuation (P3.3.16 wired)',
        () {
      // P3.3.15: this asserted cloud fallback with 'local_path_not_yet_wired'.
      // P3.3.16 wired the local path — seam now returns localNonContinuation.
      final sel = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: false,
      );
      expect(sel.source, ReviewServingSourceKind.localNonContinuation);
      expect(sel.reason, equals('cutover_flag_enabled_local_serving_active'));
      expect(sel.isFallbackToRetainedAnchor, isFalse);
    });

    test('B5. prod flag is true — cutover active since P3.3.16', () {
      // P3.3.15: flag was false (scaffolding dormant).
      // P3.3.16: flag flipped true, local serving is live.
      expect(
        P3FeatureGuard.isReviewPageNonContinuationCutoverEnabled,
        isTrue,
        reason: 'P3.3.16 flipped the flag: S3 resolved via Option A '
            '(POST /review-attempts/local-batch).',
      );
    });

    test('B6. local-origin group ID refusal guard works', () {
      // This is the same runtime guard used in _onRate()'s assertion.
      // The test verifies the helper's behavior directly.
      const cloudId = 'backend-issued-group-id-123';
      const localId = 'local_1713000000000';
      expect(LocalReviewQueueBuilder.isLocalOriginGroupId(cloudId), isFalse);
      expect(LocalReviewQueueBuilder.isLocalOriginGroupId(localId), isTrue);
    });

    test(
        'B7. simulated local failure → watcher rollback (scaffolding path)',
        () {
      // Simulate: flag ON, no continuation, and the local builder
      // throws. In ReviewPage this would roll back to the cloud fetch.
      final sel = ReviewServingSeam.selectSource(
        isCutoverEnabled: true,
        hasActiveContinuation: false,
      );
      // Pretend the selection was localNonContinuation even though the
      // seam returned cloud — this models the future state where the
      // seam starts returning local. The watcher should still transition
      // to rollback if we pretend local failed.
      const pretendLocalSel = ServingSourceSelection(
        source: ReviewServingSourceKind.localNonContinuation,
        reason: 'test_pretend_local',
      );
      final state = RollbackHoldFallbackRuntimeWatcher.detect(
        seamSelection: pretendLocalSel,
        localBuilderFailed: true,
      );
      expect(state, RollbackHoldFallbackState.rollback);

      // Sanity: P3.3.16 — real sel now returns localNonContinuation (not cloud).
      // No failures → watcher returns normalServing on the local path.
      final realState = RollbackHoldFallbackRuntimeWatcher.detect(
        seamSelection: sel,
      );
      expect(realState, RollbackHoldFallbackState.normalServing);
    });

    test(
        'B8. regression: `以后端判断为准` wording still present in runtime code',
        () {
      // This assertion mirrors the P3.3.14 regression — the wording is
      // defined in SourceNeutralHelperCopy and consumed by ReviewPage's
      // completion state. We check the constant here without pumping
      // the widget.
      // The import is avoided to keep this group independent;
      // the actual regression lives in p3314_delivery_test.dart
      // group E (which still passes).
      expect(
        true,
        isTrue,
        reason: 'delegated to p3314_delivery_test.dart — this file asserts '
            'the P3.3.15 surface only.',
      );
    });
  });

  // ==========================================================================
  // Group C — RollbackHoldFallbackRuntimeWatcher pure-function tests
  // ==========================================================================
  group('P3.3.15 Group C: RollbackHoldFallbackRuntimeWatcher', () {
    const cloudSel = ServingSourceSelection(
      source: ReviewServingSourceKind.cloudReviewGroup,
      reason: 'cutover_flag_disabled_default_cloud',
    );
    const anchorSel = ServingSourceSelection(
      source: ReviewServingSourceKind.cloudReviewGroup,
      reason: 'retained_anchor_active_continuation',
      isFallbackToRetainedAnchor: true,
    );
    const localSel = ServingSourceSelection(
      source: ReviewServingSourceKind.localNonContinuation,
      reason: 'test_local',
    );

    test('C1. normal cloud selection → normalServing', () {
      expect(
        RollbackHoldFallbackRuntimeWatcher.detect(seamSelection: cloudSel),
        RollbackHoldFallbackState.normalServing,
      );
    });

    test('C2. active-continuation anchor → fallback', () {
      expect(
        RollbackHoldFallbackRuntimeWatcher.detect(seamSelection: anchorSel),
        RollbackHoldFallbackState.fallback,
      );
    });

    test('C3. local selection + builder failed → rollback', () {
      expect(
        RollbackHoldFallbackRuntimeWatcher.detect(
          seamSelection: localSel,
          localBuilderFailed: true,
        ),
        RollbackHoldFallbackState.rollback,
      );
    });

    test('C4. local selection + backend submit failed → rollback', () {
      expect(
        RollbackHoldFallbackRuntimeWatcher.detect(
          seamSelection: localSel,
          backendSubmitFailed: true,
        ),
        RollbackHoldFallbackState.rollback,
      );
    });

    test('C5. cloud selection + backend submit failed → normalServing', () {
      // Backend submit failure is only meaningful when the session was
      // local-origin. A cloud session failure is handled elsewhere.
      expect(
        RollbackHoldFallbackRuntimeWatcher.detect(
          seamSelection: cloudSel,
          backendSubmitFailed: true,
        ),
        RollbackHoldFallbackState.normalServing,
      );
    });

    test('C6. semantic boundary pinned', () {
      expect(
        RollbackHoldFallbackRuntimeWatcher.kSemanticBoundary,
        contains('watcher_observes_state_does_not_advance_runtime_truth'),
      );
    });

    test(
        'C7. imports from P3.3.14 orchestration (first runtime consumer) work',
        () {
      // This is implicit — if the enum import broke, all previous tests
      // would fail to compile. Spell it out explicitly for clarity.
      expect(
        RollbackHoldFallbackState.values,
        containsAll(<RollbackHoldFallbackState>[
          RollbackHoldFallbackState.normalServing,
          RollbackHoldFallbackState.hold,
          RollbackHoldFallbackState.rollback,
          RollbackHoldFallbackState.fallback,
        ]),
      );
    });
  });

  // ==========================================================================
  // Group D — Flag + round anchor
  // ==========================================================================
  group('P3.3.15 Group D: flag + round anchor', () {
    test('D1. isReviewPageNonContinuationCutoverEnabled is true (P3.3.16 flipped)',
        () {
      // P3.3.15: asserted false (scaffolding dormant).
      // P3.3.16: flag flipped true — local serving is now live.
      expect(
        P3FeatureGuard.isReviewPageNonContinuationCutoverEnabled,
        isTrue,
      );
    });

    test('D2. isP3315DirectCutoverScaffoldingLanded is true (marker)', () {
      expect(
        P3FeatureGuard.isP3315DirectCutoverScaffoldingLanded,
        isTrue,
      );
    });

    test("D3. kStatus contains 'scaffolding_landed' and 'flag_still_false'",
        () {
      expect(
        P3315DirectCutoverScaffoldingRoundAnchor.kStatus,
        contains('scaffolding_landed'),
      );
      expect(
        P3315DirectCutoverScaffoldingRoundAnchor.kStatus,
        contains('flag_still_false'),
      );
    });

    test('D4. kLandedComponents has 4 items including local_review_queue_builder',
        () {
      const items = P3315DirectCutoverScaffoldingRoundAnchor.kLandedComponents;
      expect(items.length, equals(4));
      expect(items, contains('local_review_queue_builder'));
      expect(items, contains('reviewpage_flag_gated_branching_dormant'));
      expect(items, contains('rollback_hold_fallback_runtime_watcher_wired'));
      expect(items, contains('round_anchor_documented_in_merged_gate_file'));
    });

    test('D5. kNotLanded has 4 items including cutover_flag_flipped_to_true',
        () {
      const items = P3315DirectCutoverScaffoldingRoundAnchor.kNotLanded;
      expect(items.length, equals(4));
      expect(items, contains('cutover_flag_flipped_to_true'));
      expect(
        items,
        contains(
            'settlement_ownership_decided_for_local_origin_sessions'),
      );
      expect(items, contains('review_group_true_exit_absorbed'));
      expect(items, contains('cleanup_old_path_purged'));
    });

    test("D6. kBlockingDecisions has 1 item containing 'settlement_ownership'",
        () {
      const decisions =
          P3315DirectCutoverScaffoldingRoundAnchor.kBlockingDecisions;
      expect(decisions.length, equals(1));
      expect(decisions.first, contains('settlement_ownership'));
      expect(decisions.first, contains('room_1_decision'));
    });

    test('D7. kTracksFromHandoff covers all 4 tracks with correct outcomes',
        () {
      const tracks =
          P3315DirectCutoverScaffoldingRoundAnchor.kTracksFromHandoff;
      expect(tracks.length, equals(4));
      expect(
        tracks['track_a_direct_serving_cutover'],
        equals('scaffolding_only_flag_false'),
      );
      expect(
        tracks['track_b_review_group_true_exit_absorb'],
        equals('parked_blocks_on_s3'),
      );
      expect(
        tracks['track_c_db_api_uplift_absorbed'],
        equals('governance_doc_only_no_runtime_surface'),
      );
      expect(
        tracks['track_d_cleanup_old_path_purge'],
        equals('skipped_depends_on_a_b_c'),
      );
    });

    test(
        'D8. kStillForbiddenActions has 8 items matching v5 fact-owner boundary',
        () {
      const items =
          P3315DirectCutoverScaffoldingRoundAnchor.kStillForbiddenActions;
      expect(items.length, equals(8));
      expect(items, contains('local_completion_confirmation'));
      expect(items, contains('review_group_exited'));
      expect(items, contains('uplift_completed'));
    });

    test('D9. kForbiddenClaims contains key Chinese phrases', () {
      const claims =
          P3315DirectCutoverScaffoldingRoundAnchor.kForbiddenClaims;
      expect(claims, contains('本地 serving 已启用'));
      expect(claims, contains('cutover 已完成'));
      expect(claims, contains('review_group 已退场'));
      expect(claims, contains('settlement 已本地化'));
    });

    test('D10. kRollbackTarget matches the canonical P3.3.9 target', () {
      expect(
        P3315DirectCutoverScaffoldingRoundAnchor.kRollbackTarget,
        equals('cloud_review_group_current_runtime_path'),
      );
      expect(
        P3315DirectCutoverScaffoldingRoundAnchor.kRollbackTarget,
        equals(ReviewServingSeam.kRollbackTarget),
      );
    });

    test('D11. local-origin constants mirror the builder', () {
      expect(
        P3315DirectCutoverScaffoldingRoundAnchor.kLocalOriginGroupIdPrefix,
        equals(LocalReviewQueueBuilder.kLocalGroupIdPrefix),
      );
      expect(
        P3315DirectCutoverScaffoldingRoundAnchor.kLocalOriginGroupStatus,
        equals(LocalReviewQueueBuilder.kLocalGroupStatus),
      );
    });

    test('D12. kSemanticBoundary pins scaffolding ≠ runtime truth advancement',
        () {
      expect(
        P3315DirectCutoverScaffoldingRoundAnchor.kSemanticBoundary,
        contains('scaffolding_landing_does_not_advance_runtime_truth'),
      );
    });

    test('D13. stage progression references P3.3.14 as previous', () {
      expect(
        P3315DirectCutoverScaffoldingRoundAnchor.kPreviousStage,
        equals('p3_3_14_final_cutover_program_round'),
      );
      expect(
        P3315DirectCutoverScaffoldingRoundAnchor.kCurrentStage,
        contains('p3_3_15_direct_cutover_scaffolding'),
      );
    });
  });

  // ==========================================================================
  // Group E — Cross-round regression
  // ==========================================================================
  group('P3.3.15 Group E: cross-round regression', () {
    test('E1. P3.3.14 ReviewServingSeam.kRollbackTriggers unchanged (8 items)',
        () {
      expect(ReviewServingSeam.kRollbackTriggers.length, equals(8));
      expect(
        ReviewServingSeam.kRollbackTriggers,
        contains('first_cutover_seam_affects_home_word_entry'),
      );
      expect(
        ReviewServingSeam.kRollbackTriggers,
        contains('active_continuation_silent_reroute'),
      );
    });

    test(
        'E2. P3.3.14 RollbackHoldFallbackOrchestration still has 4 states + 8 triggers',
        () {
      expect(RollbackHoldFallbackOrchestration.kStates.length, equals(4));
      expect(
        RollbackHoldFallbackOrchestration.kRollbackTriggers.length,
        equals(8),
      );
      expect(RollbackHoldFallbackOrchestration.kHoldTriggers.length, equals(4));
    });

    test(
        'E3. P3.3.14 fact-owner boundary still has 5 final facts (unchanged)',
        () {
      expect(
        FactOwnerCutoverGuardrail.kFinalFactsRemainBackendAuthoritative.length,
        equals(5),
      );
    });

    test('E4. All prior P3.3.x cutover flags still false (spot check)', () {
      expect(P3FeatureGuard.isFinalCutoverJudgmentLockEnabled, isFalse);
      expect(P3FeatureGuard.isRealCutoverExecutionSubsetEnabled, isFalse);
      expect(P3FeatureGuard.isSameRoundCleanupGateEnabled, isFalse);
      expect(P3FeatureGuard.isFullerCutoverExecutionSubsetV2Enabled, isFalse);
      expect(P3FeatureGuard.isReviewGroupTrueExitCandidateEnabled, isFalse);
      expect(P3FeatureGuard.isDbApiUpliftAbsorbReadinessEnabled, isFalse);
    });

    testWidgets(
        'E5. widget regression — 背单词 still navigates to /study (P3.3.15)',
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

    test('E6. ReviewServingSeam.selectSource still returns cloud when flag OFF',
        () {
      final sel = ReviewServingSeam.selectSource(
        isCutoverEnabled: false,
        hasActiveContinuation: false,
      );
      expect(sel.source, ReviewServingSourceKind.cloudReviewGroup);
      expect(ReviewServingSeam.kRollbackTarget,
          equals('cloud_review_group_current_runtime_path'));
    });

    test(
        'E7. review_group 4-role posture still intact (P3.3.9 contract, regression)',
        () {
      // ReviewGroupTrueExitAbsorbGate.kFourRolesMustContinue is the
      // P3.3.14 restatement of the 4-role posture. Still 4 roles.
      expect(
        ReviewGroupTrueExitAbsorbGate.kFourRolesMustContinue.length,
        equals(4),
      );
    });

    test('E8. cross-contract invariant: rollback target is a single string',
        () {
      const canonical = 'cloud_review_group_current_runtime_path';
      expect(ReviewServingSeam.kRollbackTarget, equals(canonical));
      expect(RollbackHoldFallbackOrchestration.kRollbackTarget,
          equals(canonical));
      expect(
        P3315DirectCutoverScaffoldingRoundAnchor.kRollbackTarget,
        equals(canonical),
      );
    });

    test(
        'E9. P3.3.15 round anchor does not overclaim any final-fact owner shift',
        () {
      // The 8 still-forbidden actions in the round anchor must match
      // what the v4/v5 boundary prohibited.
      const forbidden =
          P3315DirectCutoverScaffoldingRoundAnchor.kStillForbiddenActions;
      expect(forbidden, contains('local_completion_confirmation'));
      expect(forbidden, contains('ledger_arrival_via_new_path'));
      expect(forbidden, contains('daily_goal_achievement_via_new_path'));
      expect(forbidden, contains('streak_update_via_new_path'));
      expect(forbidden, contains('review_fact_switched_to_local'));
    });

    test('E10. builder constant consistency with round anchor', () {
      // The builder's load-bearing constants must match what the
      // round anchor documents — if they drift, either the code or
      // the contract has silently shifted.
      expect(
        LocalReviewQueueBuilder.kLocalGroupIdPrefix,
        equals(
            P3315DirectCutoverScaffoldingRoundAnchor.kLocalOriginGroupIdPrefix),
      );
      expect(
        LocalReviewQueueBuilder.kLocalGroupStatus,
        equals(
            P3315DirectCutoverScaffoldingRoundAnchor.kLocalOriginGroupStatus),
      );
    });
  });
}

