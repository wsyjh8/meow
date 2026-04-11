import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/guards/p3_feature_guard.dart';
import '../../core/memory/fsrs_service.dart';
import '../../core/memory/review_rating.dart';
import '../../core/memory/widgets/rating_buttons.dart';
import '../../core/review/review_readiness_state.dart';
import '../../core/serving/review_serving_seam.dart';
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

  @override
  void initState() {
    super.initState();
    _fsrsService = FsrsService(db: AppDatabase());
    _loadReviewGroup();
  }

  @override
  void dispose() {
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

    setState(() {
      _isLoading = true;
      _error = null;
      _noGroupAvailable = false;   // reset on every load attempt
    });

    try {
      // runtime_truth_switch_boundary_v1 (FROZEN, P3.3.9):
      // Regardless of the seam's selection above, this round always
      // delegates to the cloud `review_group` path — the seam flag is
      // OFF and the local path is not yet wired.
      final group = await _apiClient.getNextReviewGroup();
      setState(() {
        _reviewGroup = group;
        _currentItem = group.items.where((i) => !i.completed).firstOrNull;
        _groupCompleted = group.groupCompleted;
        _isLoading = false;
      });
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
    if (mounted) setState(() { _isSubmitting = true; _error = null; });

    try {
      // Step 1: Idempotency key (existing pattern preserved exactly)
      final idempotencyKey =
          'review-${_reviewGroup!.reviewGroupId}-${_currentItem!.wordId}';

      // Step 2: Binary mapping for cloud API (contract unchanged)
      // again/hard → 'incorrect' | good/easy → 'correct'
      final binaryResult = (rating == ReviewRating.good || rating == ReviewRating.easy)
          ? 'correct'
          : 'incorrect';

      // Step 2.5: Pre-submit bridge ensure (stronger_bridge_contract_v1, P3.3.4).
      // Idempotent local card init before cloud submit — reduces miss rate for words
      // that never passed through StudyPage. Non-blocking: cloud submit runs regardless.
      // This is step 1 of the minimal repair path:
      //   pre-submit ensure → cloud submit → post-submit ensure + apply → observable fallback.
      try {
        await _fsrsService.initCardForWord(_currentItem!.wordId);
      } catch (e) {
        reviewBridgeFallbackCount++;
        debugPrint('[ReviewPage] pre-submit ensure fallback '
            '#$reviewBridgeFallbackCount: wordId=${_currentItem?.wordId}, error=$e');
      }

      // Step 3: Cloud submit — PRIMARY; must succeed before bridge apply runs
      final result = await _apiClient.submitReviewAttempt(
        reviewGroupId: _reviewGroup!.reviewGroupId,
        wordId: _currentItem!.wordId,
        actionResult: binaryResult,
        idempotencyKey: idempotencyKey,
      );
      if (mounted) setState(() { _groupCompleted = result.groupCompleted; });

      // Step 4: Post-cloud-submit bridge ensure + apply (stronger_bridge_contract_v1).
      // initCardForWord() is idempotent: no-op if pre-submit ensure already succeeded.
      // If pre-submit failed, this is a second-chance attempt.
      // rateCard() is the local FSRS state update — non-blocking side-effect only.
      // Does NOT affect review_group continuation, group completion, or settlement.
      // Observable via debugPrint + reviewBridgeFallbackCount for dev/test.
      try {
        await _fsrsService.initCardForWord(_currentItem!.wordId);
        await _fsrsService.rateCard(_currentItem!.wordId, rating);
      } catch (e) {
        reviewBridgeFallbackCount++;
        debugPrint('[ReviewPage] FSRS bridge fallback '
            '#$reviewBridgeFallbackCount: wordId=${_currentItem?.wordId}, error=$e');
      }

      // Step 5: Settlement handling (existing logic, preserved exactly)
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

      // Step 6: Refresh group
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
                '下一组是否可用，以后端判断为准',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400], fontSize: 12),
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

          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '本组剩余：${_reviewGroup!.remainingCount} 词',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${_reviewGroup!.items.where((i) => i.completed).length} / ${_reviewGroup!.items.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _reviewGroup!.items.where((i) => i.completed).length /
                _reviewGroup!.items.length,
          ),

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
