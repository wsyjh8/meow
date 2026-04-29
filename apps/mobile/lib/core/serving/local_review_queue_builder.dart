/// local_review_queue_builder (P3.3.15 — dormant scaffolding)
///
/// Builds a `ReviewGroup`-compatible DTO from local FSRS state. This is
/// the S1 component of the P3.3.15 direct-cutover scaffolding. It is
/// real runtime code, but it is DORMANT in production because the gate
/// flag `P3FeatureGuard.isReviewPageNonContinuationCutoverEnabled`
/// remains false. When that flag flips in a future round, ReviewPage's
/// branching will start calling this builder.
///
/// ============================================================================
/// Architectural boundary
/// ============================================================================
///
/// - The builder produces a ReviewGroup whose `reviewGroupId` is
///   prefixed with `'local_'`. This prefix is load-bearing: it marks
///   the group as local-origin so downstream code can detect (and
///   refuse) accidental round-trips to `submitReviewAttempt`, which
///   only accepts backend-issued group IDs.
/// - `groupStatus` is always `'local_origin'`. Same purpose.
/// - `groupCompleted` is computed from `items.isEmpty`. There is no
///   concept of "previously completed" at build time — the builder
///   produces a fresh session.
/// - Items carry `completed: false` initially. ReviewPage tracks
///   per-item completion in its own state; the builder does not
///   persist it.
///
/// ============================================================================
/// Settlement ownership (S3 — unresolved)
/// ============================================================================
///
/// This builder does NOT resolve the open question of how a
/// local-origin session reports back to the backend's final-fact layer
/// (settlement, dailyGoalStatus, streak, learning_day, reward). That
/// decision is parked for a future Room 1 pin. Until then, the builder
/// is only ever exercised in tests, because the cutover flag stays
/// false and ReviewPage's branching never takes the local path in prod.
///
/// See `round_gates_and_guardrails.dart`
/// `P3_3_15_DirectCutoverScaffoldingRoundAnchor.kBlockingDecisions`.
library;

import '../api/api_client.dart' show ReviewGroup, ReviewGroupItem;
import '../guards/p3_feature_guard.dart';
import '../memory/fsrs_service.dart';
import '../storage/drift/app_database.dart';

/// Thrown when the local due-cards query yields zero results.
///
/// Callers (ReviewPage branching) are expected to catch this and map
/// it to `ReviewReadinessState.notReadyNow` — the same state shown
/// when the cloud layer returns 404.
class LocalReviewQueueEmptyException implements Exception {
  final String message;
  const LocalReviewQueueEmptyException([
    this.message = 'No local due cards available for review',
  ]);

  @override
  String toString() => 'LocalReviewQueueEmptyException: $message';
}

/// Thrown when a due-card's `wordId` has no matching row in
/// `cached_words`. This is defensive — the builder does NOT swallow
/// database inconsistency. If this fires in a test, the test data is
/// broken; if it ever fires in prod, the DB is broken.
class LocalReviewQueueMissingWordException implements Exception {
  final String wordId;
  const LocalReviewQueueMissingWordException(this.wordId);

  @override
  String toString() =>
      'LocalReviewQueueMissingWordException: no cached_words row for '
      'wordId="$wordId"';
}

/// Builds a `ReviewGroup`-compatible DTO from local FSRS state.
///
/// Pure, stateless. All methods are static. No caching, no side
/// effects — every `build()` call re-queries the DB.
abstract final class LocalReviewQueueBuilder {
  /// Load-bearing prefix for local-origin group IDs. Consumers (e.g.
  /// `ReviewPage._onRate()`) assert on this prefix to detect accidental
  /// cross-routing to the backend submit API.
  static const String kLocalGroupIdPrefix = 'local_';

  /// Load-bearing group status string for local-origin groups. The
  /// cloud-origin equivalent is any of `active` / `completed` etc.
  /// This distinct value makes debug logs + tests unambiguous.
  static const String kLocalGroupStatus = 'local_origin';

  /// Build a `ReviewGroup` from the local FSRS due queue.
  ///
  /// Parameters:
  ///   - [db]: the drift database (for the cached_words join).
  ///   - [fsrs]: the FSRS service (used to query due cards).
  ///   - [nowLocal]: the local clock time used to select due cards.
  ///     Passed through to `FsrsService.listDueCards`.
  ///   - [limit]: maximum number of items in the returned group.
  ///     Defaults to 10, matching the typical backend `review_group`
  ///     session size.
  ///
  /// Throws [LocalReviewQueueEmptyException] when there are no due
  /// cards. Throws [LocalReviewQueueMissingWordException] when a due
  /// card's wordId has no cached_words row.
  ///
  /// Defensive flag check: in release mode, the cutover flag MUST be
  /// true before this function is called. If the flag is false in
  /// release mode, an assertion fires — this guards against the
  /// builder being accidentally wired into a production code path
  /// before Room 1 has pinned the cutover.
  static Future<ReviewGroup> build({
    required AppDatabase db,
    required FsrsService fsrs,
    required DateTime nowLocal,
    int limit = 10,
  }) async {
    // P3.3.16: flag is now true. Assertion retained as documentation
    // that this method must only be called when the cutover is enabled.
    assert(
      P3FeatureGuard.isReviewPageNonContinuationCutoverEnabled,
      'LocalReviewQueueBuilder.build() called while '
      'isReviewPageNonContinuationCutoverEnabled is false.',
    );

    // 1. Query due cards.
    final dueCards = await fsrs.listDueCards(
      nowLocal: nowLocal,
      limit: limit,
    );

    if (dueCards.isEmpty) {
      throw const LocalReviewQueueEmptyException();
    }

    // 2. Batch-join against cached_words to hydrate wordText + meaning.
    final wordIds = dueCards.map((c) => c.wordId).toList(growable: false);
    final wordRows = await (db.select(db.cachedWords)
          ..where((t) => t.wordId.isIn(wordIds)))
        .get();
    final wordRowByWordId = <String, CachedWord>{
      for (final row in wordRows) row.wordId: row,
    };

    // 3. Assemble items in the same order as the due cards (due ASC).
    final items = <ReviewGroupItem>[];
    for (final card in dueCards) {
      final row = wordRowByWordId[card.wordId];
      if (row == null) {
        throw LocalReviewQueueMissingWordException(card.wordId);
      }
      items.add(ReviewGroupItem(
        wordId: row.wordId,
        wordText: row.wordText,
        meaning: row.meaning,
        completed: false,
      ));
    }

    // 4. Build the DTO with a local-origin group ID + status.
    final localGroupId =
        '$kLocalGroupIdPrefix${DateTime.now().toUtc().microsecondsSinceEpoch}';
    return ReviewGroup(
      reviewGroupId: localGroupId,
      groupStatus: kLocalGroupStatus,
      groupCompleted: items.isEmpty,
      remainingCount: items.length,
      items: items,
    );
  }

  /// True iff [groupId] was produced by this builder (local-origin).
  /// Callers (e.g. `_onRate()`) use this to detect accidental backend
  /// round-trips.
  static bool isLocalOriginGroupId(String groupId) =>
      groupId.startsWith(kLocalGroupIdPrefix);
}
