import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/memory/fsrs_service.dart';
import '../../core/memory/review_rating.dart';
import '../../core/memory/widgets/rating_buttons.dart';
import '../../core/services/study_service.dart';
import '../../core/storage/drift/app_database.dart';
import '../../core/storage/local_database.dart';

/// StudyPage - 新词学习 (SQLite-first)
///
/// Flow: 点击掌握/模糊 → 立即写入 SQLite → UI 即时反馈 → 后台同步 API
class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  late final StudyService _studyService;
  late final FsrsService _fsrsService;
  Word? _currentWord;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  /// preview_durations_reentry_contract_v1 (FROZEN, P3.3.4):
  /// Source: local FSRS candidate only (FsrsService.previewSchedule).
  /// NOT cloud serving truth. NOT a stable plan fact.
  /// Null when: word not yet loaded, during submission, or FSRS card absent/error.
  Map<ReviewRating, Duration>? _previewDurations;

  @override
  void initState() {
    super.initState();
    _studyService = StudyService(
      apiClient: ApiClient(),
      db: LocalDatabase.instance,
    );
    _fsrsService = FsrsService(db: AppDatabase());
    // Sync any pending records from previous session
    _studyService.syncPendingAttempts();
    _loadNextWord();
  }

  @override
  void dispose() {
    _studyService.dispose();
    super.dispose();
  }

  Future<void> _loadNextWord() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final word = await _studyService.getNextWord();
      if (mounted) {
        setState(() { _currentWord = word; _isLoading = false; });
        // Load preview after word is set — non-blocking, best-effort.
        if (word != null) await _loadPreviewForWord(word.wordId);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  /// preview_durations_reentry_contract_v1 (FROZEN, P3.3.4):
  /// Loads local FSRS scheduling candidate durations for the current word.
  ///
  /// - Source: local FSRS only (NOT cloud serving truth)
  /// - Not a stable plan fact — just a rough interval hint
  /// - initCardForWord() is idempotent: no-op if card already exists
  /// - All errors silently ignored — preview is strictly optional
  Future<void> _loadPreviewForWord(String wordId) async {
    try {
      await _fsrsService.initCardForWord(wordId);
      final preview = await _fsrsService.previewSchedule(wordId);
      if (mounted) setState(() => _previewDurations = preview);
    } catch (_) {
      // Preview is best-effort / reference-only — silently clear on any error.
      if (mounted) setState(() => _previewDurations = null);
    }
  }

  // P3.3.1: 4-button rating handler.
  // Three-layer mapping: ReviewRating (semantic) → FSRS grade (local) + binary string (cloud).
  // Final wording frozen: 不认识/模糊/记得/秒答.
  Future<void> _onRate(ReviewRating rating) async {
    if (_isSubmitting || _currentWord == null) return;
    // Clear preview during submission — buttons are disabled anyway.
    if (mounted) setState(() { _isSubmitting = true; _error = null; _previewDurations = null; });

    try {
      // Step 1: Ensure FSRS card exists (idempotent — no-op if already initialized)
      await _fsrsService.initCardForWord(_currentWord!.wordId);

      // Step 2: Apply FSRS rating — atomic local write (review_logs INSERT + card_states UPDATE)
      await _fsrsService.rateCard(_currentWord!.wordId, rating);

      // Step 3: Binary mapping for StudyService / cloud sync
      // again/hard → 'forgot' | good/easy → 'know'
      final binaryResult = (rating == ReviewRating.good || rating == ReviewRating.easy)
          ? 'know'
          : 'forgot';

      // Step 4: StudyService — local-first write + async cloud sync
      await _studyService.submitStudyAttempt(
        wordId: _currentWord!.wordId,
        bookId: _currentWord!.bookId,
        studyType: 'new',
        actionResult: binaryResult,
      );

      // Step 5: Load next word
      await _loadNextWord();
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
        title: const Text('学习新词'),
      ),
      body: _isLoading && _currentWord == null
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
                        onPressed: _loadNextWord,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _currentWord == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(height: 16),
                          const Text('今日新词已学完'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('返回'),
                          ),
                        ],
                      ),
                    )
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),

          // Word card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _currentWord!.wordText,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  if (_currentWord!.phonetic != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _currentWord!.phonetic!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    _currentWord!.meaning,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // P3.3.1: 4-button rating. Final wording frozen: 不认识/模糊/记得/秒答.
          // preview_durations_reentry_contract_v1 (FROZEN, P3.3.4):
          //   previewDurations = local FSRS candidate hint — NOT cloud serving truth.
          //   Null during submission or when card state unavailable.
          FsrsRatingButtons(
            onRate: _onRate,
            enabled: !_isSubmitting,
            previewDurations: _previewDurations,
          ),
          // Disclaimer shown only when preview is loaded.
          // "仅供参考" is load-bearing: must not be changed to a confirmed-fact expression.
          // MUST NOT contain: "下次将在X天后复习", "系统已安排", "已更新计划".
          if (_previewDurations != null)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '预计间隔（仅供参考）',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
