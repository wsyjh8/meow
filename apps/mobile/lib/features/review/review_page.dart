// DEPRECATED: review functionality lives in StudyPage; this file is no longer routed.
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/guards/p3_feature_guard.dart';
import '../../core/memory/fsrs_service.dart';
import '../../core/services/review_log_service.dart';
import '../../core/services/session_store.dart';
import '../../core/services/session_sync_service.dart';
import '../../core/memory/review_rating.dart';
import '../../core/memory/widgets/rating_buttons.dart';
import '../../core/review/review_readiness_state.dart';
import '../../core/serving/local_review_queue_builder.dart';
import '../../core/serving/review_serving_adapter_family.dart';
import '../../core/serving/review_serving_seam.dart';
import '../../core/serving/rollback_hold_fallback_orchestration.dart';
import '../../core/serving/rollback_hold_fallback_runtime_watcher.dart';
import '../../core/serving/source_neutral_helper_copy.dart';
import '../../core/serving/stronger_ingest_minimal_binding_seam.dart';
import '../../core/storage/drift/app_database.dart';

/// ReviewPage - 复习
///
/// planner_owner_split_v1 (FROZEN, P3.3.2):
///   Cloud review_group = serving truth owner
///     (queue serving / group continuation / group completion / settlement)
///   Local FSRS = device-side scheduling owner (side-effect only)
///   Order: cloud submit first → local FSRS side-effect second → local failure non-blocking
///
/// review_readiness_policy_v1 (FROZEN, P3.3.3):
///   Readiness state is derived from cloud response ONLY — not from local FSRS.
///   4 states: readyNow / notReadyNow / nextGroupEligible / temporarilyUnservable
///
/// schedule_source_contract_v1 (FROZEN, P3.3.3):
///   Cloud review_group = serving truth (queue / continuation / completion / settlement)
///   Local FSRS = scheduling candidate signals (card state / interval / review logs)
///   owner split ≠ planner merge
///
/// stronger_bridge_contract_v1 (FROZEN, P3.3.4):
///   3-step bridge: pre-submit ensure → cloud submit → post-submit ensure + apply.
///   All bridge steps are non-blocking. Cloud chain proceeds regardless of
///   bridge outcome. reviewBridgeFallbackCount is observable for dev/test.
///
/// review_group_compatibility_contract_v1 (FROZEN, P3.3.5):
///   Current runtime: cloud `review_group` IS the ReviewPage serving truth.
///   Future target-state candidate: local planner owner shift (NOT active).
///   `review_group` is a DEPRECATION CANDIDATE — NOT deprecated, NOT removed.
///   Runtime MUST continue consuming cloud `review_group` paths.
///
///   MUST NOT claim:
///     "本地 planner 已接管复习主链路"
///     "ReviewPage 已由本地 planner 驱动"
///     "当前复习主真相源已切换到本地"
///     "review_group 已退出运行态"
///     "unified planner 已成立"
///     "auto-routing 已开启"
///
///   See `lib/core/review/review_group_compatibility.dart` for full contract.
///
/// MUST NOT write local FSRS success/failure as user-visible planner facts.
/// MUST NOT make local due cards the main review queue source.
/// MUST NOT present "规划已更新 / 已自动切换 / 已统一规划" to the user.
class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final ApiClient _apiClient = ApiClient();
  late final FsrsService _fsrsService;
  late final SessionStore _sessionStore;
  late final SessionSyncService _sessionSyncService;
  late final ReviewLogService _reviewLog;

  // Need #8 — Local id for the current review session, threaded into every
  // submitReviewAttempt / submitLocalReviewBatch this page makes.
  String? _sessionId;

  ReviewGroup? _reviewGroup;
  ReviewGroupItem? _currentItem;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;
  bool _groupCompleted = false;

  /// review_readiness_policy_v1 (P3.3.3):
  /// True when the cloud layer returned 404 — maps to `notReadyNow`.
  /// This is distinct from `temporarilyUnservable` (network/server errors).
  bool _noGroupAvailable = false;

  /// Dev/test observable bridge fallback counter.
  /// Incremented each time the FSRS bridge catch block fires.
  /// Cloud result is already committed before this block — this counter does NOT
  /// indicate review_group failure. Non-blocking residual per RF-P3.3.1-003.
  @visibleForTesting
  int reviewBridgeFallbackCount = 0;

  /// Dev/test observable seam hit counter (P3.3.9).
  /// Incremented each time `_loadReviewGroup()` consults the serving seam.
  /// first_cutover_subset_v1 (FROZEN, P3.3.9): the seam is consulted
  /// purely for observability. This counter has NO effect on user
  /// behavior — every path still goes through cloud `review_group`.
  @visibleForTesting
  int reviewServingSeamHitCount = 0;

  /// Dev/test observable adapter-family hit counter (P3.3.14 B additive).
  /// Incremented each time `_loadReviewGroup()` consults the adapter
  /// family. The family ALWAYS routes to cloud; this counter is
  /// observability-only. real_cutover_execution_subset_v1 Member 1.
  @visibleForTesting
  int reviewServingAdapterFamilyHitCount = 0;

  /// Dev/test observable stronger-ingest minimal binding consultation
  /// counter (P3.3.14 B additive). Incremented each time `_onRate()`
  /// consults the minimal binding seam post-cloud-commit. No final
  /// fact write is performed. real_cutover_execution_subset_v1 Member 5.
  @visibleForTesting
  int strongerIngestMinimalBindingHitCount = 0;

  /// Dev/test observable local-review-queue-builder hit counter
  /// (P3.3.15 — dormant scaffolding). Incremented each time
  /// `_loadReviewGroup()` actually invokes
  /// `LocalReviewQueueBuilder.build()`. In prod this stays at 0
  /// because `isReviewPageNonContinuationCutoverEnabled` is false and
  /// the branch is never taken.
  @visibleForTesting
  int localReviewQueueBuilderHitCount = 0;

  /// Dev/test observable rollback/hold/fallback runtime watcher
  /// counter (P3.3.15 — first runtime consumer of the P3.3.14
  /// orchestration contract). Incremented each time
  /// `_loadReviewGroup()` consults the watcher. In prod the watcher
  /// always returns `normalServing` or `fallback` (under active
  /// continuation); rollback transitions only happen in test.
  @visibleForTesting
  int rollbackHoldFallbackWatcherHitCount = 0;

  /// Dev/test observable last watcher state (P3.3.15). Captures the
  /// most recent `RollbackHoldFallbackState` returned by the watcher
  /// so tests can assert on it without reflection.
  @visibleForTesting
  RollbackHoldFallbackState? lastRollbackHoldFallbackState;

  /// Test-only injection point for `AppDatabase` used by the local
  /// review queue builder. When null, the builder uses its own
  /// `AppDatabase()` instance. Tests set this to a fake drift DB.
  @visibleForTesting
  AppDatabase? debugDatabaseOverride;

  /// Accumulated ratings for the current local-origin session.
  /// Populated word-by-word in [_handleLocalSessionRating()] and
  /// submitted as a batch when all items are completed.
  /// Cleared at the start of each [_loadReviewGroup()] call. P3.3.16.
  final List<LocalWordAttempt> _localSessionAttempts = [];
  // Need #10 — local review_records row ids that correspond 1:1 to entries
  // in _localSessionAttempts, in the same order. When the batch cloud sync
  // succeeds these rows get bulk-marked synced.
  final List<int> _localBatchRowIds = [];

  // ── Intra-session requeue (session_requeue_v1) ───────────────────────────
  // Works for both local-origin and cloud-origin review sessions.
  //
  // _sessionQueue: ordered list of items still to be shown in the current
  //   session. Words rated 'incorrect'/'hard' for the FIRST time are moved
  //   to the END of this list; on their second showing they are finalised.
  // _sessionRequeued: word IDs already requeued once this session, so the
  //   re-show is handled at most once per word (no infinite loop).
  //
  // For LOCAL sessions: items are finalised into _localSessionAttempts;
  //   the batch is submitted when _sessionQueue is empty.
  // For CLOUD sessions: items are submitted to the cloud only on final
  //   rating (correct OR second incorrect). _loadReviewGroup() is called
  //   only when _sessionQueue is empty.
  List<ReviewGroupItem> _sessionQueue = [];
  Set<String> _sessionRequeued = {};

  @override
  void initState() {
    super.initState();
    final appDb = AppDatabase();
    _fsrsService = FsrsService(db: appDb);
    _sessionStore = SessionStore(apiClient: _apiClient, driftDb: appDb);
    _sessionSyncService =
        SessionSyncService(apiClient: _apiClient, driftDb: appDb);
    _reviewLog = ReviewLogService(apiClient: _apiClient, driftDb: appDb);
    // Drain any unfinished sessions from prior runs first, then open one
    // for this review page (independent from any study-page session).
    _sessionSyncService.drainPending();
    _startSession();
    _loadReviewGroup();
  }

  Future<void> _startSession() async {
    try {
      final id = await _sessionStore.startForReview();
      if (mounted) setState(() => _sessionId = id);
    } catch (_) {
      // Session creation failure is non-fatal — submissions will fall back
      // to the backend's time-window matching.
    }
  }

  @override
  void dispose() {
    // Need #8 — record session end (covers normal pop / back / explicit exit).
    _sessionStore.finish();
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadReviewGroup() async {
    // first_cutover_subset_v1 (FROZEN, P3.3.9):
    // Consult the serving seam for decision/observability. This round:
    // the seam ALWAYS returns cloudReviewGroup because
    // P3FeatureGuard.isReviewPageNonContinuationCutoverEnabled is false.
    // Runtime behavior is IDENTICAL to pre-P3.3.9 — every path still
    // delegates to apiClient.getNextReviewGroup() regardless of the
    // seam's decision. The seam exists for observability + future wiring.
    //
    // Retained anchor: when there's an active continuation, the seam
    // reports that path as fallback-to-retained-anchor so rollback
    // evidence is preserved.
    final hasActiveContinuation =
        _reviewGroup != null && !_groupCompleted;
    final servingSelection = ReviewServingSeam.selectSource(
      isCutoverEnabled:
          P3FeatureGuard.isReviewPageNonContinuationCutoverEnabled,
      hasActiveContinuation: hasActiveContinuation,
    );
    reviewServingSeamHitCount++;
    debugPrint('[ReviewPage] serving seam hit #$reviewServingSeamHitCount: '
        'source=${servingSelection.source.name}, '
        'reason=${servingSelection.reason}, '
        'fallbackToAnchor=${servingSelection.isFallbackToRetainedAnchor}');

    // real_cutover_execution_subset_v1 Member 1 (FROZEN, P3.3.14):
    // Additively consult the continuity-adjacent serving-adapter family.
    // The family ALWAYS routes to cloud this round. This call is
    // observability-only and does NOT change which source is used —
    // the delegate to apiClient.getNextReviewGroup() below is still
    // the only runtime-truth path.
    final adapterResult = hasActiveContinuation
        ? ReviewServingAdapterFamily.consultContinuationPriority(
            isCutoverEnabled:
                P3FeatureGuard.isReviewPageNonContinuationCutoverEnabled,
            hasActiveContinuation: true,
          )
        : ReviewServingAdapterFamily.consultFirstLoad(
            isCutoverEnabled:
                P3FeatureGuard.isReviewPageNonContinuationCutoverEnabled,
          );
    reviewServingAdapterFamilyHitCount++;
    debugPrint('[ReviewPage] adapter family hit '
        '#$reviewServingAdapterFamilyHitCount: '
        'kind=${adapterResult.kind.name}, '
        'tag=${adapterResult.additiveTag}, '
        'source=${adapterResult.selection.source.name}');

    // P3.3.16: clear local session accumulator on every load (fresh session).
    _localSessionAttempts.clear();
    _localBatchRowIds.clear();

    setState(() {
      _isLoading = true;
      _error = null;
      _noGroupAvailable = false;   // reset on every load attempt
    });

    // P3.3.15 — dormant scaffolding:
    // Flag-gated branching. In prod the flag is false, so
    // servingSelection.source is always cloudReviewGroup and we take
    // the cloud path. Tests may flip the flag (via an override path
    // or by re-running the seam's decision themselves) to exercise
    // the local-origin branch.
    //
    // The RollbackHoldFallbackRuntimeWatcher is consulted once per
    // load; its result is recorded for observability and does not
    // affect routing this round (rollback is only acted on
    // implicitly via the cloud fallback below).
    bool localBuilderFailed = false;
    try {
      if (servingSelection.source ==
          ReviewServingSourceKind.localNonContinuation) {
        // P3.3.15 — LOCAL-ORIGIN BRANCH (dormant in prod).
        // Reached only when the cutover flag is true AND no active
        // continuation exists. The builder reads local FSRS due
        // cards + joins cached_words.
        ReviewGroup group;
        try {
          group = await LocalReviewQueueBuilder.build(
            db: debugDatabaseOverride ?? AppDatabase(),
            fsrs: _fsrsService,
            nowLocal: DateTime.now(),
          );
          localReviewQueueBuilderHitCount++;
          debugPrint(
              '[ReviewPage] local review queue builder hit '
              '#$localReviewQueueBuilderHitCount: '
              'groupId=${group.reviewGroupId}, '
              'itemCount=${group.items.length}');
        } on LocalReviewQueueEmptyException {
          // No local due cards — map to notReadyNow, same as the
          // cloud 404 path.
          setState(() {
            _noGroupAvailable = true;
            _isLoading = false;
          });
          _consultRollbackWatcher(
            seamSelection: servingSelection,
            localBuilderFailed: false,
          );
          return;
        } catch (e) {
          // Local builder failure — show error (no cloud fallback in local-first mode).
          // future: cloud verification — cloud rollback path retained in cloud-origin branch.
          localBuilderFailed = true;
          debugPrint('[ReviewPage] local builder failed: $e');
          if (mounted) {
            setState(() { _error = e.toString(); _isLoading = false; });
          }
          _consultRollbackWatcher(
            seamSelection: servingSelection,
            localBuilderFailed: true,
          );
          return;
        }
        setState(() {
          _reviewGroup = group;
          _currentItem = group.items.where((i) => !i.completed).firstOrNull;
          _groupCompleted = group.groupCompleted;
          _isLoading = false;
        });
        // session_requeue_v1: initialise session queue for this group.
        _sessionQueue = group.items.where((i) => !i.completed).toList();
        _sessionRequeued = {};
      } else {
        // runtime_truth_switch_boundary_v1 (FROZEN, P3.3.9):
        // Cloud path. This is the only branch that runs in prod this
        // round — every selection path returns cloudReviewGroup
        // because the cutover flag is false.
        final group = await _apiClient.getNextReviewGroup();
        setState(() {
          _reviewGroup = group;
          _currentItem = group.items.where((i) => !i.completed).firstOrNull;
          _groupCompleted = group.groupCompleted;
          _isLoading = false;
        });
        // session_requeue_v1: initialise session queue for this group.
        _sessionQueue = group.items.where((i) => !i.completed).toList();
        _sessionRequeued = {};
      }
      _consultRollbackWatcher(
        seamSelection: servingSelection,
        localBuilderFailed: localBuilderFailed,
      );
    } catch (e) {
      // review_readiness_policy_v1 (P3.3.3):
      // Distinguish not_ready_now (404) from temporarily_unservable (other errors).
      // 404 = cloud serving layer has no review work right now — neutral state.
      // Other = transient server/network problem — show retry.
      final is404 = e is ApiException && e.statusCode == 404;
      setState(() {
        _error = is404 ? null : e.toString();
        _noGroupAvailable = is404;
        _isLoading = false;
      });
    }
  }

  /// P3.3.15 — consults the `RollbackHoldFallbackRuntimeWatcher` and
  /// records the result. Pure-observability this round: the result
  /// does not alter routing. Rollback detection in prod is still
  /// implicitly handled by the cloud fallback inside `_loadReviewGroup`.
  void _consultRollbackWatcher({
    required ServingSourceSelection seamSelection,
    required bool localBuilderFailed,
  }) {
    final state = RollbackHoldFallbackRuntimeWatcher.detect(
      seamSelection: seamSelection,
      localBuilderFailed: localBuilderFailed,
    );
    rollbackHoldFallbackWatcherHitCount++;
    lastRollbackHoldFallbackState = state;
    debugPrint(
      '[ReviewPage] rollback/hold/fallback watcher hit '
      '#$rollbackHoldFallbackWatcherHitCount: state=${state.name}, '
      'seamSource=${seamSelection.source.name}, '
      'seamReason=${seamSelection.reason}, '
      'localBuilderFailed=$localBuilderFailed',
    );
  }

  /// P3.3.16 — Handles one word rating for a local-origin session.
  ///
  /// Local sessions do not call `submitReviewAttempt` per word.
  /// Instead, ratings are accumulated in `_localSessionAttempts`.
  /// FSRS is updated locally per word (primary FSRS update for local sessions).
  /// When all items in the current group have been rated, the full batch
  /// is submitted via `POST /review-attempts/local-batch` to trigger
  /// settlement + daily_goal + learning_day updates on the backend.
  Future<void> _handleLocalSessionRating(ReviewRating rating) async {
    if (mounted) setState(() { _isSubmitting = true; _error = null; });
    try {
      final wordId = _currentItem!.wordId;
      final binaryResult =
          (rating == ReviewRating.good || rating == ReviewRating.easy)
              ? 'correct'
              : 'incorrect';

      // 1. Update local FSRS state (primary FSRS update for local sessions).
      // Non-blocking: session continues even if FSRS fails.
      try {
        await _fsrsService.initCardForWord(wordId);
        await _fsrsService.rateCard(wordId, rating);
      } catch (e) {
        reviewBridgeFallbackCount++;
        debugPrint('[ReviewPage] local FSRS update fallback '
            '#$reviewBridgeFallbackCount: wordId=$wordId, error=$e');
      }

      // 2. session_requeue_v1: 'incorrect' words get one re-showing with
      //    other cards in between. Remove current from queue first.
      _sessionQueue.removeWhere((i) => i.wordId == wordId);

      if (binaryResult == 'incorrect' && !_sessionRequeued.contains(wordId)) {
        // First incorrect this session — requeue at end, defer batch recording.
        _sessionRequeued.add(wordId);
        _sessionQueue.add(_currentItem!);
        debugPrint('[ReviewPage] local session: requeued $wordId '
            '(queue size: ${_sessionQueue.length})');

        if (mounted) {
          setState(() { _currentItem = _sessionQueue.firstOrNull; _isSubmitting = false; });
        }
        return;
      }

      // 3. Final rating — record for batch submission.
      _localSessionAttempts.add(LocalWordAttempt(wordId: wordId, actionResult: binaryResult));
      debugPrint('[ReviewPage] local session: recorded final attempt '
          '${_localSessionAttempts.length} wordId=$wordId, result=$binaryResult');

      // 3a. Need #10 — persist this attempt locally as a review log entry
      // (synced=0, will be marked synced once the batch cloud sync below
      // confirms acceptance). Best-effort: a local-write failure here
      // does not stop the review flow.
      try {
        final localId = await _reviewLog.recordLocal(
          wordId: wordId,
          reviewGroupId: _reviewGroup!.reviewGroupId,
          actionResult: binaryResult,
          sessionId: _sessionId,
          rating: _ratingToFsrsInt(rating),
        );
        _localBatchRowIds.add(localId);
      } catch (e) {
        debugPrint('[ReviewPage] review-log local insert failed (non-blocking): $e');
      }

      // 4. More items in session queue?
      if (_sessionQueue.isNotEmpty) {
        if (mounted) {
          setState(() { _currentItem = _sessionQueue.first; _isSubmitting = false; });
        }
        return;
      }

      // 5. All items finalised — mark group completed locally.
      if (mounted) setState(() { _groupCompleted = true; });

      // 6. Background cloud sync (fire-and-forget).
      // future: cloud verification — submitLocalReviewBatch retained for
      // future cloud+local hybrid mode. Currently non-blocking.
      final idempotencyKey = 'local-batch-${_reviewGroup!.reviewGroupId}';
      // Snapshot the local row ids that correspond to this batch BEFORE
      // _loadReviewGroup() clears the buffers below.
      final batchRowIds = List<int>.from(_localBatchRowIds);
      _apiClient.submitLocalReviewBatch(
        attempts: _localSessionAttempts,
        idempotencyKey: idempotencyKey,
        sessionId: _sessionId,
      ).then((result) async {
        // Need #10 — flag corresponding local review_records rows as synced.
        for (final id in batchRowIds) {
          try {
            await _reviewLog.markSynced(id);
          } catch (_) {/* best-effort */}
        }
        if (result.groupCompleted && result.settlement != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '本组完成！奖励状态：${result.settlement!.rewardSettlementStatus}',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }).catchError((_) {
        debugPrint('[ReviewPage] local batch cloud sync failed (non-blocking)');
      });

      // 7. Load next session.
      await _loadReviewGroup();
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _isSubmitting = false; });
      }
    }
  }

  /// schedule_source_contract_v1 (FROZEN, P3.3.3):
  /// Readiness is derived from cloud response signals ONLY.
  /// Local FSRS state / local due count MUST NOT influence this derivation.
  ReviewReadinessState _deriveReadinessState() {
    if (_noGroupAvailable) return ReviewReadinessState.notReadyNow;
    if (_error != null) return ReviewReadinessState.temporarilyUnservable;
    if (_reviewGroup == null) return ReviewReadinessState.temporarilyUnservable;
    // review_group_generation_policy_v1 (P3.3.3) RF-P3.3.3-011:
    // Group completed → next_group_eligible (eligibility only, not generated).
    if (_groupCompleted) return ReviewReadinessState.nextGroupEligible;
    return ReviewReadinessState.readyNow;
  }

  // stronger_bridge_contract_v1 (FROZEN, P3.3.4):
  // Cloud submit is primary (review_group contract preserved).
  // Bridge is 3-step: pre-submit ensure → cloud submit → post-submit ensure + apply.
  // All bridge steps are non-blocking. Cloud chain proceeds regardless of bridge outcome.
  // Final wording frozen: 不认识/模糊/记得/秒答.
  Future<void> _onRate(ReviewRating rating) async {
    if (_isSubmitting || _currentItem == null || _reviewGroup == null) return;

    // P3.3.16 — Route local-origin sessions to the batch path.
    // S3 resolved: local sessions submit via POST /review-attempts/local-batch.
    if (LocalReviewQueueBuilder.isLocalOriginGroupId(
        _reviewGroup!.reviewGroupId)) {
      await _handleLocalSessionRating(rating);
      return;
    }

    if (mounted) setState(() { _isSubmitting = true; _error = null; });

    try {
      final wordId = _currentItem!.wordId;

      // Step 1: Binary mapping for cloud API (contract unchanged)
      // again/hard → 'incorrect' | good/easy → 'correct'
      final binaryResult = (rating == ReviewRating.good || rating == ReviewRating.easy)
          ? 'correct'
          : 'incorrect';

      // Step 2 (session_requeue_v1): first 'incorrect' rating — update FSRS
      // locally but defer cloud submit and re-show the card after other items.
      // stronger_bridge_contract_v1 (P3.3.4): bridge runs now as side-effect.
      _sessionQueue.removeWhere((i) => i.wordId == wordId);

      if (binaryResult == 'incorrect' && !_sessionRequeued.contains(wordId)) {
        // First incorrect — requeue, no cloud submit yet.
        _sessionRequeued.add(wordId);
        _sessionQueue.add(_currentItem!);

        try {
          await _fsrsService.initCardForWord(wordId);
          await _fsrsService.rateCard(wordId, rating);
        } catch (e) {
          reviewBridgeFallbackCount++;
          debugPrint('[ReviewPage] FSRS bridge fallback (requeue) '
              '#$reviewBridgeFallbackCount: wordId=$wordId, error=$e');
        }

        debugPrint('[ReviewPage] cloud session: requeued $wordId '
            '(queue size: ${_sessionQueue.length})');

        if (_sessionQueue.isNotEmpty) {
          if (mounted) setState(() { _currentItem = _sessionQueue.first; _isSubmitting = false; });
          return;
        }
        // Only item in session and it was incorrect — fall through to submit.
      }

      // Step 3: Final rating path — submit to cloud.
      // Idempotency key (existing pattern preserved exactly)
      final idempotencyKey = 'review-${_reviewGroup!.reviewGroupId}-$wordId';

      // Step 3.5: Pre-submit bridge ensure (stronger_bridge_contract_v1, P3.3.4).
      try {
        await _fsrsService.initCardForWord(wordId);
      } catch (e) {
        reviewBridgeFallbackCount++;
        debugPrint('[ReviewPage] pre-submit ensure fallback '
            '#$reviewBridgeFallbackCount: wordId=$wordId, error=$e');
      }

      // Step 4: Cloud submit — PRIMARY; must succeed before bridge apply runs.
      //
      // Need #10: write a local review_records row first (synced=0). On
      // cloud success we mark it synced; on failure it stays unsynced and
      // surfaces in the debug page as pending — no data is lost.
      int? localLogId;
      try {
        localLogId = await _reviewLog.recordLocal(
          wordId: wordId,
          reviewGroupId: _reviewGroup!.reviewGroupId,
          actionResult: binaryResult,
          sessionId: _sessionId,
          rating: _ratingToFsrsInt(rating),
        );
      } catch (e) {
        debugPrint('[ReviewPage] review-log local insert failed (non-blocking): $e');
      }

      final result = await _apiClient.submitReviewAttempt(
        reviewGroupId: _reviewGroup!.reviewGroupId,
        wordId: wordId,
        actionResult: binaryResult,
        idempotencyKey: idempotencyKey,
        sessionId: _sessionId,
      );

      if (localLogId != null) {
        try {
          await _reviewLog.markSynced(localLogId);
        } catch (_) {/* best-effort */}
      }
      if (mounted) setState(() { _groupCompleted = result.groupCompleted; });

      // Step 5: Post-cloud-submit bridge ensure + apply (stronger_bridge_contract_v1).
      try {
        await _fsrsService.initCardForWord(wordId);
        await _fsrsService.rateCard(wordId, rating);
      } catch (e) {
        reviewBridgeFallbackCount++;
        debugPrint('[ReviewPage] FSRS bridge fallback '
            '#$reviewBridgeFallbackCount: wordId=$wordId, error=$e');
      }

      // real_cutover_execution_subset_v1 Member 5 (FROZEN, P3.3.14):
      final bindingResult = StrongerIngestMinimalBindingSeam
          .consultMinimalBinding(
        precondition: StrongerIngestBindingPrecondition(
          wordId: wordId,
          cloudReviewGroupAlreadyCommitted: true,
          backendFactLayerConsultedAsAuthoritative: true,
        ),
      );
      strongerIngestMinimalBindingHitCount++;
      debugPrint('[ReviewPage] stronger-ingest minimal binding hit '
          '#$strongerIngestMinimalBindingHitCount: '
          'discussionOnly=${bindingResult.bindingDiscussedOnly}, '
          'layer=${bindingResult.allowedDiscussionLayer}, '
          'tag=${bindingResult.consultationTag}');

      // Step 6: Settlement handling (existing logic, preserved exactly)
      if (result.groupCompleted && result.settlement != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '本组完成！奖励状态：${result.settlement!.rewardSettlementStatus}',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      // Step 7 (session_requeue_v1): advance in session or load next group.
      // Only call _loadReviewGroup() when the session queue is exhausted,
      // so requeued cards get their re-showing before a fresh group arrives.
      if (_sessionQueue.isNotEmpty) {
        if (mounted) setState(() { _currentItem = _sessionQueue.first; _isSubmitting = false; });
        return;
      }

      await _loadReviewGroup();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isSubmitting = false; });
      return;
    }

    if (mounted) setState(() { _isSubmitting = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('复习'),
      ),
      body: _isLoading && _reviewGroup == null && !_noGroupAvailable
          ? const Center(child: CircularProgressIndicator())
          : _buildBodyForState(_deriveReadinessState()),
    );
  }

  /// Routes to the appropriate body widget based on derived readiness state.
  /// State derivation is cloud-only per schedule_source_contract_v1 (P3.3.3).
  Widget _buildBodyForState(ReviewReadinessState state) {
    switch (state) {
      case ReviewReadinessState.notReadyNow:
        return _buildNotReadyNow();
      case ReviewReadinessState.temporarilyUnservable:
        return _buildTemporarilyUnservable();
      case ReviewReadinessState.nextGroupEligible:
      case ReviewReadinessState.readyNow:
        if (_reviewGroup == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildContent();
    }
  }

  // ==================== Readiness state UI ====================

  /// review_readiness_policy_v1: temporarily_unservable
  /// Transient cloud/network failure — show retry. NOT a permanent denial.
  Widget _buildTemporarilyUnservable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('加载失败：$_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReviewGroup,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// review_readiness_policy_v1: not_ready_now
  /// Cloud serving layer has no immediate review work (404).
  /// MUST NOT say "no review quota", "today done", or "system judged no review".
  /// Neutral phrasing only — this is a transient, non-permanent state.
  ///
  /// real_cutover_execution_subset_v1 Member 2 (FROZEN, P3.3.14):
  /// The additive neutral caption at the bottom is sourced from
  /// SourceNeutralHelperCopy.kEmptyStateNeutralCaption. It is a
  /// source-neutral pre-explanation that does NOT claim any serving-
  /// truth switch or fact-owner shift. Delivered additively alongside
  /// the existing copy above.
  Widget _buildNotReadyNow() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            const Text('当前暂无待复习内容'),
            const SizedBox(height: 8),
            Text(
              '可以先去背单词，或稍后再来',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 4),
            // P3.3.14 B Member 2: additive source-neutral pre-explanation.
            Text(
              SourceNeutralHelperCopy.kEmptyStateNeutralCaption,
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Active group UI ====================

  Widget _buildContent() {
    if (_groupCompleted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 24),
              Text(
                '本组复习完成',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              // P3 Phase 2: Explicit three-layer boundary messaging
              // Layer 1: Group progress (completed)
              Text(
                '✅ 本组已完成',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              // Layer 2: Daily progress boundary (group ≠ daily)
              Text(
                '今日复习进度已更新。是否还有后续任务，以今日目标为准。',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              // Layer 3: Next group readiness caveat
              // review_group_generation_policy_v1 (FROZEN, P3.3.3):
              // RF-P3.3.3-011: next_group_eligible ≠ next_group_generated
              // "以后端判断为准" correctly expresses eligibility-only semantics —
              // the next group may or may not exist; the cloud layer decides.
              Text(
                SourceNeutralHelperCopy.kCompletionNextGroupCaption,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 4),
              // P3.3.14 B Member 2: additive neutral completion caption.
              Text(
                SourceNeutralHelperCopy.kCompletionNeutralCaption,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400], fontSize: 11),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回今日'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentItem == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载中...'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // Progress indicator (session_requeue_v1: based on session queue)
          Builder(builder: (context) {
            final total = _reviewGroup!.items.length;
            // Unique word IDs still pending in session queue (some may appear
            // twice if requeued; count each word once).
            final pendingIds = _sessionQueue.map((i) => i.wordId).toSet();
            final done = total - pendingIds.length;
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '本组剩余：${pendingIds.length} 词',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$done / $total',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: total > 0 ? done / total : 0,
                ),
              ],
            );
          }),

          const SizedBox(height: 32),

          // Word card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _currentItem!.wordText,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _currentItem!.meaning,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // P3.3.1: 4-button rating. Final wording frozen: 不认识/模糊/记得/秒答.
          // Bridge: again/hard → 'incorrect', good/easy → 'correct' (cloud contract unchanged).
          FsrsRatingButtons(
            onRate: _onRate,
            enabled: !_isSubmitting,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


/// Need #10 — Map [ReviewRating] to the FSRS canonical 1..4 integer
/// (1=again, 2=hard, 3=good, 4=easy). Used when persisting a review
/// attempt to the local review log.
int _ratingToFsrsInt(ReviewRating rating) {
  switch (rating) {
    case ReviewRating.again:
      return 1;
    case ReviewRating.hard:
      return 2;
    case ReviewRating.good:
      return 3;
    case ReviewRating.easy:
      return 4;
  }
}
