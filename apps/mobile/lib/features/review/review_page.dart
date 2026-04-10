import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/memory/fsrs_service.dart';
import '../../core/memory/review_rating.dart';
import '../../core/memory/widgets/rating_buttons.dart';
import '../../core/storage/drift/app_database.dart';

/// ReviewPage - 复习
///
/// Handles review flow with review_group.
/// Phase 1 minimal implementation.
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
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final group = await _apiClient.getNextReviewGroup();
      setState(() {
        _reviewGroup = group;
        _currentItem = group.items.where((i) => !i.completed).firstOrNull;
        _groupCompleted = group.groupCompleted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReview(String actionResult) async {
    if (_currentItem == null || _reviewGroup == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Generate a simple idempotency key
      final idempotencyKey =
          'review-${_reviewGroup!.reviewGroupId}-${_currentItem!.wordId}';

      final result = await _apiClient.submitReviewAttempt(
        reviewGroupId: _reviewGroup!.reviewGroupId,
        wordId: _currentItem!.wordId,
        actionResult: actionResult,
        idempotencyKey: idempotencyKey,
      );

      setState(() {
        _groupCompleted = result.groupCompleted;
        _isLoading = false;
      });

      // Phase 2: Show settlement feedback when group is completed
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

      // Refresh to get next item
      await _loadReviewGroup();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // P3.3: 4-button rating handler — bridge-first pattern.
  // Cloud submit is primary (review_group contract preserved).
  // FSRS local write is a best-effort side-effect bridge.
  // CANDIDATE labels — final Chinese wording pending Room 3 + Room 5 freeze.
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

      // Step 3: Cloud submit — PRIMARY; must succeed before bridge runs
      final result = await _apiClient.submitReviewAttempt(
        reviewGroupId: _reviewGroup!.reviewGroupId,
        wordId: _currentItem!.wordId,
        actionResult: binaryResult,
        idempotencyKey: idempotencyKey,
      );
      if (mounted) setState(() { _groupCompleted = result.groupCompleted; });

      // Step 4: FSRS bridge — best-effort side-effect
      // Card may not exist in card_states if word was never studied in StudyPage.
      // Silent failure is acceptable; cloud result already committed above.
      try {
        await _fsrsService.rateCard(_currentItem!.wordId, rating);
      } catch (_) {}

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
      body: _isLoading && _reviewGroup == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                )
              : _reviewGroup == null
                  ? const Center(child: Text('无复习内容'))
                  : _buildContent(),
    );
  }

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
                '\u672c\u7ec4\u590d\u4e60\u5b8c\u6210', // 本组复习完成
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              // P3 Phase 2: Explicit three-layer boundary messaging
              // Layer 1: Group progress (completed)
              Text(
                '\u{2705} \u672c\u7ec4\u5df2\u5b8c\u6210', // ✅ 本组已完成
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              // Layer 2: Daily progress boundary (group ≠ daily)
              Text(
                '\u4eca\u65e5\u590d\u4e60\u8fdb\u5ea6\u5df2\u66f4\u65b0\u3002\u662f\u5426\u8fd8\u6709\u540e\u7eed\u4efb\u52a1\uff0c\u4ee5\u4eca\u65e5\u76ee\u6807\u4e3a\u51c6\u3002',
                // 今日复习进度已更新。是否还有后续任务，以今日目标为准。
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              // Layer 3: Next group readiness caveat
              Text(
                '\u4e0b\u4e00\u7ec4\u662f\u5426\u53ef\u7528\uff0c\u4ee5\u540e\u7aef\u5224\u65ad\u4e3a\u51c6',
                // 下一组是否可用，以后端判断为准
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('\u8fd4\u56de\u4eca\u65e5'), // 返回今日
              ),
            ],
          ),
        ),
      );
    }

    if (_currentItem == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('加载中...'),
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

          // P3.3: 4-button rating. CANDIDATE labels — final wording pending Room 3 + Room 5 freeze.
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
