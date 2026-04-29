import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart' show Word, WordExample;
import '../../core/audio/pronunciation_service.dart';
import '../../core/util/pos_label.dart';
import '../../core/memory/card_state_data.dart';
import '../../core/memory/fsrs_service.dart';
import '../../core/memory/review_rating.dart';
import '../../core/storage/drift/app_database.dart';

// ── Design tokens (mirrors study_page.dart exactly) ──────────────────────────
const _kBg = Color(0xFFF5F1EA);
const _kCardBg = Color(0xFFFFFFFF);
const _kPurple = Color(0xFF6B4FA8);
const _kSoftPurpleBg = Color(0xFFF2EFFA);
const _kPurpleBorder = Color(0xFFB8A8D4);
const _kOrangeBg = Color(0xFFFAECE7);
const _kOrangeBorder = Color(0xFFF0D4C0);
const _kOrangeText = Color(0xFFA68872);
const _kNeutralBg = Color(0xFFFDFBF7);
const _kNeutralBorder = Color(0xFFE8E2D8);
const _kNeutralText = Color(0xFF5C554C);
const _kTextDark = Color(0xFF2C2C2A);
const _kTextGray = Color(0xFF9C948A);
const _kTextMedium = Color(0xFF5C554C);
const _kBorderColor = Color(0xFFEFEBE4);
const _kProgressBg = Color(0xFFEFEBE4);
const _kGreenBg = Color(0xFFE8F2ED);
const _kGreenText = Color(0xFF3F7A5F);
const _kBarBg = Color(0xFFB8B0A4);

/// SPEC Review Page — same visual format as StudyPage, driven by FSRS due cards.
///
/// Data source  : [FsrsService.listDueCards] → word lookup via [AppDatabase]
/// Rating write : [FsrsService.rateCard] (local FSRS only — no cloud call)
/// Requeue      : again / hard → shown once more after a short delay (session_requeue_v1)
///
/// The old [ReviewPage] (features/review/review_page.dart) is intentionally
/// preserved but not routed to. This page replaces it at the /review route.
class SpecReviewPage extends StatefulWidget {
  const SpecReviewPage({super.key});

  @override
  State<SpecReviewPage> createState() => _SpecReviewPageState();
}

class _SpecReviewPageState extends State<SpecReviewPage> {
  // ── Services ──────────────────────────────────────────────────────────────
  late final AppDatabase _driftDb;
  late final FsrsService _fsrsService;
  late final PronunciationService _pronunciationService;
  StreamSubscription<PlayerState>? _audioSub;

  // ── Card state ─────────────────────────────────────────────────────────────
  bool _isPlayingAudio = false;
  Word? _currentWord;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  /// preview_durations_reentry_contract_v1 (FROZEN, P3.3.4):
  /// Source: local FSRS only. NOT cloud truth. Null when unavailable.
  Map<ReviewRating, Duration>? _previewDurations;

  // ── Review queue ───────────────────────────────────────────────────────────
  List<CardStateData> _queue = [];

  // ── Session requeue state (session_requeue_v1) ────────────────────────────
  final List<_RequeueEntry> _requeuedCards = [];
  final Set<String> _requeuedOnceIds = {};

  // ── Progress ───────────────────────────────────────────────────────────────
  int _totalDue = 0;
  int _reviewed = 0;

  /// Batch-resolved word_id → word_text mapping for pronunciation prefetch.
  /// Built once at queue load time to avoid repeated DB lookups.
  Map<String, String> _wordTextMap = {};

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _driftDb = AppDatabase();
    _fsrsService = FsrsService(db: _driftDb);
    _pronunciationService = PronunciationService();
    _audioSub = _pronunciationService.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlayingAudio = state == PlayerState.playing);
    });
    _loadQueue();
  }

  @override
  void dispose() {
    _audioSub?.cancel();
    _pronunciationService.dispose();
    super.dispose();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  Future<void> _loadQueue() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final cards = await _fsrsService.listDueCards(nowLocal: DateTime.now());
      _queue = cards;
      _totalDue = cards.length;

      // Batch-resolve word_id → word_text for pronunciation prefetch.
      if (cards.isNotEmpty) {
        _wordTextMap = await _driftDb.getWordTextsForIds(
          cards.map((c) => c.wordId).toList(),
        );
      }

      await _loadNextCard();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadNextCard() async {
    // Tick requeue counters — each card transition moves all pending entries
    // one step closer to being shown again.
    for (final entry in _requeuedCards) {
      entry.cardsSinceRequeue++;
    }

    // 1. Show earliest ready requeue card (delay served).
    final readyIdx = _requeuedCards.indexWhere((e) => e.isReady);
    if (readyIdx >= 0) {
      final entry = _requeuedCards.removeAt(readyIdx);
      if (mounted) {
        setState(() { _currentWord = entry.word; _isLoading = false; _isSubmitting = false; });
        _loadPreviewForWord(entry.word.wordId);
        _prefetchUpcoming();
      }
      return;
    }

    // 2. Next unseen due card.
    if (_queue.isNotEmpty) {
      final card = _queue.removeAt(0);
      final word = await _fetchWordForCard(card);
      if (word != null) {
        if (mounted) {
          setState(() { _currentWord = word; _isLoading = false; _isSubmitting = false; });
          _loadPreviewForWord(word.wordId);
          _prefetchUpcoming();
        }
        return;
      }
      // Word not found in DB (stale card_state row) — skip and continue.
      await _loadNextCard();
      return;
    }

    // 3. Force-show any remaining requeue cards even if not yet ready.
    if (_requeuedCards.isNotEmpty) {
      final entry = _requeuedCards.removeAt(0);
      if (mounted) {
        setState(() { _currentWord = entry.word; _isLoading = false; _isSubmitting = false; });
        _loadPreviewForWord(entry.word.wordId);
        _prefetchUpcoming();
      }
      return;
    }

    // 4. All done.
    if (mounted) setState(() { _currentWord = null; _isLoading = false; _isSubmitting = false; });
  }

  /// Resolve word details for a [CardStateData] row.
  /// Checks word_entries (ZK/GK) first, falls back to cached_words (CET-4).
  Future<Word?> _fetchWordForCard(CardStateData card) async {
    try {
      // ZK / GK path
      final entry = await _driftDb.getWordEntryById(card.wordId);
      if (entry != null) {
        final exRows = await _driftDb.getExamplesForWord(card.wordId, limit: 3);
        return Word(
          wordId: entry.wordId,
          wordText: entry.wordText,
          meaning: entry.meaning,
          phonetic: entry.phonetic,
          translation: entry.translation,
          definition: entry.definition,
          frequencyRank: entry.frequencyRank,
          wordForms: entry.wordForms,
          bookId: 'review',
          examples: exRows.isNotEmpty
              ? exRows.map((e) => WordExample(sense: e.sense, en: e.en, cn: e.cn)).toList()
              : null,
        );
      }
      // CET-4 path
      final cached = await _driftDb.getCachedWordById(card.wordId);
      if (cached != null) {
        final exRows = await _driftDb.getExamplesForWord(card.wordId, limit: 3);
        return Word(
          wordId: cached.wordId,
          wordText: cached.wordText,
          meaning: cached.meaning,
          phonetic: cached.phonetic,
          translation: cached.translation,
          bookId: cached.bookId,
          examples: exRows.isNotEmpty
              ? exRows.map((e) => WordExample(sense: e.sense, en: e.en, cn: e.cn)).toList()
              : null,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// preview_durations_reentry_contract_v1: local FSRS hint only.
  Future<void> _loadPreviewForWord(String wordId) async {
    try {
      await _fsrsService.initCardForWord(wordId);
      final preview = await _fsrsService.previewSchedule(wordId);
      if (mounted) setState(() => _previewDurations = preview);
    } catch (_) {
      if (mounted) setState(() => _previewDurations = null);
    }
  }

  /// Prefetch pronunciation audio for the next ~5 upcoming cards in the queue.
  ///
  /// Uses the pre-built [_wordTextMap] (word_id → word_text) to resolve
  /// word texts without additional DB lookups.
  void _prefetchUpcoming() {
    final upcoming = _queue
        .take(5)
        .map((c) => _wordTextMap[c.wordId])
        .whereType<String>()
        .toList();
    if (upcoming.isNotEmpty) {
      _pronunciationService.prefetch(upcoming);
    }
  }

  // ── Rating handler ─────────────────────────────────────────────────────────

  Future<void> _onRate(ReviewRating rating) async {
    if (_isSubmitting || _currentWord == null) return;
    if (mounted) setState(() { _isSubmitting = true; _error = null; _previewDurations = null; });

    try {
      // FSRS update (local only — no cloud call for review session page)
      await _fsrsService.initCardForWord(_currentWord!.wordId);
      await _fsrsService.rateCard(_currentWord!.wordId, rating);

      // session_requeue_v1: again / hard → requeue once before counting as reviewed
      if ((rating == ReviewRating.again || rating == ReviewRating.hard) &&
          !_requeuedOnceIds.contains(_currentWord!.wordId)) {
        _requeuedOnceIds.add(_currentWord!.wordId);
        final delay = rating == ReviewRating.again ? 3 : 2;
        _requeuedCards.add(_RequeueEntry(word: _currentWord!, cardsNeededBefore: delay));
      } else {
        _reviewed++;
      }

      await _loadNextCard();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isSubmitting = false; });
      return;
    }

    if (mounted) setState(() { _isSubmitting = false; });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 功能即将上线'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showMoreMeanings() {
    final word = _currentWord;
    final translation = word?.translation;
    if (translation == null || translation.isEmpty) {
      _showComingSoon('更多释义');
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  word!.wordText,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _kTextDark),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20, color: _kTextGray),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (word.phonetic != null && word.phonetic!.isNotEmpty)
              Text(word.phonetic!, style: const TextStyle(fontSize: 12, color: _kTextGray)),
            const SizedBox(height: 16),
            const Divider(color: _kBorderColor, thickness: 0.5, height: 1),
            const SizedBox(height: 12),
            ...translationLines(translation).map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(line, style: const TextStyle(fontSize: 14, color: _kTextMedium, height: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: _isLoading && _currentWord == null
            ? const Center(child: CircularProgressIndicator(color: _kPurple))
            : _error != null
                ? _buildErrorState()
                : _currentWord == null
                    ? _buildDoneState()
                    : _buildReviewContent(),
      ),
    );
  }

  Widget _buildReviewContent() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: _buildWordCard(),
          ),
        ),
        _buildActionButtons(),
        _buildBottomActions(),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final progress = _totalDue > 0
        ? (_reviewed / _totalDue).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _kBarBg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日复习 · $_reviewed / $_totalDue',
                  style: const TextStyle(fontSize: 10, color: _kTextGray),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: _kProgressBg,
                    valueColor: const AlwaysStoppedAnimation<Color>(_kPurple),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.settings_outlined, size: 18, color: _kBarBg),
        ],
      ),
    );
  }

  // ── Word card ──────────────────────────────────────────────────────────────

  Widget _buildWordCard() {
    final word = _currentWord!;
    final pos = posLabel(word.translation);
    final lines = translationLines(word.translation);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorderColor, width: 0.5),
        boxShadow: const [
          BoxShadow(color: Color(0x0A6B4FA8), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ReviewProgressBadge(reviewed: _reviewed, total: _totalDue),
              const _WordTypeBadge(label: '复习'),
            ],
          ),
          const SizedBox(height: 10),

          // Word + speaker
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.wordText,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                        color: _kTextDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (word.phonetic != null && word.phonetic!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          word.phonetic!,
                          style: const TextStyle(fontSize: 12, color: _kTextGray),
                        ),
                      ),
                  ],
                ),
              ),
              // Speaker button
              GestureDetector(
                onTap: _isPlayingAudio
                    ? null
                    : () async {
                        try {
                          await _pronunciationService.play(word.wordText);
                        } catch (_) {
                          if (mounted) {
                            setState(() => _isPlayingAudio = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('发音加载失败'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 11),
                  decoration: BoxDecoration(
                    color: _kOrangeBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: _isPlayingAudio
                      ? const SizedBox(
                          width: 38,
                          height: 14,
                          child: Center(
                            child: SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: _kOrangeText,
                              ),
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.volume_up_outlined, size: 14, color: _kOrangeText),
                            SizedBox(width: 4),
                            Text('发音', style: TextStyle(fontSize: 10, color: _kOrangeText)),
                          ],
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // POS pill + primary meaning
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (pos.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kSoftPurpleBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(pos, style: const TextStyle(fontSize: 10, color: _kPurple)),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  word.meaning,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kTextDark),
                ),
              ),
            ],
          ),

          // Translation lines
          if (lines.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Color(0xFFF4EFE5), thickness: 0.5, height: 1),
            ),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(line, style: const TextStyle(fontSize: 12, color: _kTextMedium, height: 1.45)),
              ),
            ),
          ],

          // Example sentences
          if (word.examples != null && word.examples!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 8),
              child: Divider(color: Color(0xFFF4EFE5), thickness: 0.5, height: 1),
            ),
            _buildExamplesSection(word.examples!),
          ],
        ],
      ),
    );
  }

  Widget _buildExamplesSection(List<WordExample> examples) {
    final shown = examples.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '例句',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _kTextGray, letterSpacing: 0.4),
        ),
        const SizedBox(height: 6),
        ...shown.map((ex) {
          final enPlain = ex.en.replaceAll(RegExp(r'\[|\]'), '');
          final cnPlain = ex.cn.replaceAll(RegExp(r'\[|\]'), '');
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(enPlain, style: const TextStyle(fontSize: 11, color: _kTextDark, height: 1.5)),
                const SizedBox(height: 2),
                Text(cnPlain, style: const TextStyle(fontSize: 10, color: _kTextGray, height: 1.45)),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Rating buttons ─────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    const configs = [
      _ReviewBtn(label: '熟悉', rating: ReviewRating.easy, bgColor: _kPurple, borderColor: _kPurple, textColor: Colors.white, hasTick: true),
      _ReviewBtn(label: '认识', rating: ReviewRating.good, bgColor: _kSoftPurpleBg, borderColor: _kPurpleBorder, textColor: _kPurple),
      _ReviewBtn(label: '模糊', rating: ReviewRating.hard, bgColor: _kOrangeBg, borderColor: _kOrangeBorder, textColor: _kOrangeText),
      _ReviewBtn(label: '不认识', rating: ReviewRating.again, bgColor: _kNeutralBg, borderColor: _kNeutralBorder, textColor: _kNeutralText),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          Row(
            children: configs.asMap().entries.map((e) {
              final i = e.key;
              final cfg = e.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  child: _RatingButton(
                    config: cfg,
                    enabled: !_isSubmitting,
                    onTap: () => _onRate(cfg.rating),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_previewDurations != null)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '预计间隔（仅供参考）',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Bottom pills ───────────────────────────────────────────────────────────

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PillBtn(label: '♡ 收藏', onTap: () => _showComingSoon('收藏')),
          const SizedBox(width: 6),
          _PillBtn(label: '⚑ 困难词', onTap: () => _showComingSoon('困难词')),
          const SizedBox(width: 6),
          _PillBtn(label: '更多释义', onTap: _showMoreMeanings),
        ],
      ),
    );
  }

  // ── Terminal states ────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: _kOrangeText, size: 48),
            const SizedBox(height: 16),
            const Text('加载失败', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: _kTextDark)),
            const SizedBox(height: 8),
            Text(_error ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: _kTextGray)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadQueue,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoneState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text(
            '复习完成',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: _kTextDark),
          ),
          const SizedBox(height: 8),
          Text(
            '今日共复习 $_reviewed 个单词',
            style: const TextStyle(fontSize: 14, color: _kTextGray),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}

// ── Private data classes ──────────────────────────────────────────────────────

class _ReviewBtn {
  final String label;
  final ReviewRating rating;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final bool hasTick;

  const _ReviewBtn({
    required this.label,
    required this.rating,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    this.hasTick = false,
  });
}

class _RequeueEntry {
  final Word word;
  final int cardsNeededBefore;
  int cardsSinceRequeue = 0;

  _RequeueEntry({required this.word, required this.cardsNeededBefore});

  bool get isReady => cardsSinceRequeue >= cardsNeededBefore;
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _RatingButton extends StatelessWidget {
  final _ReviewBtn config;
  final bool enabled;
  final VoidCallback onTap;

  const _RatingButton({required this.config, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: config.bgColor,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: config.borderColor, width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                config.label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: config.textColor),
              ),
              if (config.hasTick) ...[
                const SizedBox(width: 3),
                Icon(Icons.check_rounded, size: 12, color: config.textColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Progress badge — shows cat emoji + review progress text.
class _ReviewProgressBadge extends StatelessWidget {
  final int reviewed;
  final int total;

  const _ReviewProgressBadge({required this.reviewed, required this.total});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? reviewed / total : 0.0;
    final (emoji, mood) = ratio >= 0.7
        ? ('😸', '快完成啦')
        : ratio >= 0.3
            ? ('😺', '继续加油')
            : ('🐱', '开始复习');

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 10, 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFAECE7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(mood, style: const TextStyle(fontSize: 10, color: Color(0xFFA68872))),
        ],
      ),
    );
  }
}

/// Word type badge — "复习".
class _WordTypeBadge extends StatelessWidget {
  final String label;
  const _WordTypeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _kGreenBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: _kGreenText)),
    );
  }
}

/// Pill-shaped tappable button for bottom actions.
class _PillBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PillBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFBF7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFEFEBE4), width: 0.5),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF8B8178))),
      ),
    );
  }
}
