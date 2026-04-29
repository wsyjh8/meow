import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/audio/pronunciation_service.dart';
import '../../core/memory/fsrs_service.dart';
import '../../core/memory/review_rating.dart';
import '../../core/memory/word_cache_service.dart';
import '../../core/services/study_service.dart';
import '../../core/storage/drift/app_database.dart';
import '../../core/storage/local_database.dart';
import '../../core/storage/local_settings_service.dart';

// ── Design tokens (local to this file) ──────────────────────────────────────
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

/// StudyPage — 新词学习 (SQLite-first)
///
/// Flow: 点击评级 → 立即写入 SQLite → UI 即时反馈 → 后台同步 API
///
/// Intra-session spaced repetition (session_requeue_v1):
///   "不认识" / "模糊" → card re-queued with a short delay (3 or 2 other
///   cards between showings). Each card can be requeued at most once per
///   session. On the second showing, regardless of rating, the card is
///   done for the session (FSRS handles the next due date).
class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  // ── Services ──────────────────────────────────────────────────────────────
  late final StudyService _studyService;
  late final FsrsService _fsrsService;
  late final WordCacheService _wordCacheService;
  late final PronunciationService _pronunciationService;
  StreamSubscription<PlayerState>? _audioSub;

  // ── Word state ────────────────────────────────────────────────────────────
  bool _isPlayingAudio = false;
  Word? _currentWord;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  /// preview_durations_reentry_contract_v1 (FROZEN, P3.3.4):
  /// Source: local FSRS candidate only (FsrsService.previewSchedule).
  /// NOT cloud serving truth. NOT a stable plan fact.
  /// Null when: word not yet loaded, during submission, or FSRS card absent/error.
  Map<ReviewRating, Duration>? _previewDurations;

  // ── Session requeue state (session_requeue_v1) ──────────────────────────
  // _sessionSeenIds: all words shown this session (mastered + requeued).
  //   Used as extraExclude so getNextWord() never returns a word already
  //   handled (or currently in the requeue) as the "next new" word.
  // _requeuedWords: words pending re-show, ordered by insertion time.
  //   Each entry carries a counter; the word is shown again once enough
  //   other cards have been displayed.
  // _requeuedOnceIds: tracks words that have already been requeued once
  //   so a second "forgot" rating simply moves on (no infinite loop).
  final Set<String> _sessionSeenIds = {};
  final List<_RequeueEntry> _requeuedWords = [];
  final Set<String> _requeuedOnceIds = {};

  // ── Today progress ─────────────────────────────────────────────────────────
  /// Number of new words mastered today (cumulative across sessions).
  /// Loaded from LocalDatabase.countTodayNewCompleted() on init,
  /// then incremented on each binaryResult == 'know'.
  int _todayCompleted = 0;

  /// Daily goal loaded from LocalSettingsService. Default 20 until loaded.
  int _dailyGoal = 20;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final appDb = AppDatabase();
    _studyService = StudyService(
      apiClient: ApiClient(),
      db: LocalDatabase.instance,
      driftDb: appDb,
    );
    _fsrsService = FsrsService(db: appDb);
    _wordCacheService = WordCacheService(db: appDb);
    _pronunciationService = PronunciationService();
    _audioSub = _pronunciationService.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlayingAudio = state == PlayerState.playing);
    });
    // Sync any pending records from previous session
    _studyService.syncPendingAttempts();
    _loadDailyGoal();
    _loadNextWord();
  }

  @override
  void dispose() {
    _audioSub?.cancel();
    _pronunciationService.dispose();
    _studyService.dispose();
    super.dispose();
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> _loadDailyGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goal = LocalSettingsService(prefs).dailyGoal;
      if (mounted) setState(() => _dailyGoal = goal);
    } catch (_) {
      // Stay at default 20 — non-blocking
    }
    try {
      final completed = await LocalDatabase.instance.countTodayNewCompleted();
      if (mounted) setState(() => _todayCompleted = completed);
    } catch (_) {
      // Stay at 0 — non-blocking
    }
  }

  // ── Business logic (FROZEN — do not modify without governance review) ─────

  Future<void> _loadNextWord() async {
    setState(() { _isLoading = true; _error = null; });

    // Daily goal enforcement: stop serving new words once goal is met,
    // but allow pending requeue cards to finish (user already saw them).
    if (_todayCompleted >= _dailyGoal && _requeuedWords.isEmpty) {
      if (mounted) setState(() { _currentWord = null; _isLoading = false; _isSubmitting = false; });
      return;
    }

    // Tick requeue counters — each call to _loadNextWord represents one card
    // transition, so every pending requeue entry moves one step closer.
    for (final entry in _requeuedWords) {
      entry.cardsSinceRequeue++;
    }

    // 1. Show earliest ready requeued word (delay has been served).
    final readyIdx = _requeuedWords.indexWhere((e) => e.isReady);
    if (readyIdx >= 0) {
      final entry = _requeuedWords.removeAt(readyIdx);
      if (mounted) {
        setState(() { _currentWord = entry.word; _isLoading = false; _isSubmitting = false; });
        _loadPreviewForWord(entry.word.wordId);
        _prefetchUpcoming();
      }
      return;
    }

    // 2. Get next unseen word, excluding all session-seen words.
    try {
      final word = await _studyService.getNextWord(extraExclude: _sessionSeenIds);
      if (word != null) {
        _sessionSeenIds.add(word.wordId);
        if (mounted) {
          setState(() { _currentWord = word; _isLoading = false; _isSubmitting = false; });
          _loadPreviewForWord(word.wordId);
          _prefetchUpcoming();

          // P3.3.17: Cache word locally for offline review queue — fire-and-forget.
          _wordCacheService.insertWord(
            wordId: word.wordId,
            bookId: word.bookId,
            wordText: word.wordText,
            meaning: word.meaning,
            phonetic: word.phonetic,
            translation: word.translation,
            frequencyRank: word.frequencyRank,
          ).catchError((_) {});
        }
        return;
      }

      // 3. No new unseen words — show earliest requeued word even if not ready yet.
      if (_requeuedWords.isNotEmpty) {
        final entry = _requeuedWords.removeAt(0);
        if (mounted) {
          setState(() { _currentWord = entry.word; _isLoading = false; _isSubmitting = false; });
          _loadPreviewForWord(entry.word.wordId);
          _prefetchUpcoming();
        }
        return;
      }

      // 4. Truly done for this session.
      if (mounted) setState(() { _currentWord = null; _isLoading = false; _isSubmitting = false; });
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

  /// Prefetch pronunciation audio for the next ~5 upcoming words.
  ///
  /// Queries the DB for unstudied words after the current one, then hands
  /// their word_text values to [PronunciationService.prefetch] which
  /// downloads WAV files in the background. Already-cached words are skipped.
  void _prefetchUpcoming() {
    // Build exclude set: mastered words are handled by the service;
    // we only need to add session-seen IDs + current word.
    final exclude = Set<String>.from(_sessionSeenIds);
    if (_currentWord != null) exclude.add(_currentWord!.wordId);
    _studyService
        .peekNextWordTexts(5, extraExclude: exclude)
        .then((wordTexts) => _pronunciationService.prefetch(wordTexts))
        .catchError((_) {}); // best-effort — silent on failure
  }

  // P3.3.1: 4-button rating handler.
  // Three-layer mapping: ReviewRating (semantic) → FSRS grade (local) + binary string (cloud).
  //
  // session_requeue_v1:
  //   again / hard → local-only write + requeue (first time) or advance (second time).
  //   good / easy  → mark mastered, advance to next new word.
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

      // Step 5 (session_requeue_v1): on 'forgot', requeue with spacing instead of
      // immediately fetching the next new word.
      if (binaryResult == 'forgot' && !_requeuedOnceIds.contains(_currentWord!.wordId)) {
        // First forgot this session — requeue with a short inter-card delay.
        // again (不认识) = 3 cards; hard (模糊) = 2 cards.
        final delay = rating == ReviewRating.again ? 3 : 2;
        _sessionSeenIds.add(_currentWord!.wordId); // exclude from new-word picks
        _requeuedWords.add(_RequeueEntry(word: _currentWord!, cardsNeededBefore: delay));
        _requeuedOnceIds.add(_currentWord!.wordId);
      }

      // Step 6: Track mastered words for session progress.
      if (binaryResult == 'know') {
        if (mounted) setState(() => _todayCompleted++);
      }

      // Step 7: Load next word (checks requeue list first, then new words)
      await _loadNextWord();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isSubmitting = false; });
      return;
    }

    if (mounted) setState(() { _isSubmitting = false; });
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  /// Splits translation into individual lines, stripping blanks.
  static List<String> _translationLines(String? translation) {
    if (translation == null || translation.trim().isEmpty) return [];
    return translation
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  /// Extracts the first POS abbreviation from translation and maps it to Chinese.
  static String _posLabel(String? translation) {
    if (translation == null || translation.isEmpty) return '';
    final first = _translationLines(translation).firstOrNull ?? '';
    const map = {
      'vt.': '及物动词', 'vi.': '不及物动词', 'v.': '动词',
      'n.': '名词',     'a.': '形容词',      'adj.': '形容词',
      'adv.': '副词',   'prep.': '介词',     'conj.': '连词',
      'pron.': '代词',  'num.': '数词',      'int.': '感叹词',
      'art.': '冠词',
    };
    for (final entry in map.entries) {
      if (first.startsWith(entry.key)) return entry.value;
    }
    return '';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
                    : _buildStudyContent(),
      ),
    );
  }

  Widget _buildStudyContent() {
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

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final progress = _dailyGoal > 0
        ? (_todayCompleted / _dailyGoal).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: _kBarBg,
            ),
          ),
          const SizedBox(width: 12),
          // Progress section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日新词 · $_todayCompleted / $_dailyGoal',
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
          // Settings icon (stub — navigates nowhere yet)
          const Icon(Icons.settings_outlined, size: 18, color: _kBarBg),
        ],
      ),
    );
  }

  // ── Word card ─────────────────────────────────────────────────────────────

  Widget _buildWordCard() {
    final word = _currentWord!;
    final pos = _posLabel(word.translation);
    final lines = _translationLines(word.translation);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorderColor, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A6B4FA8),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Badge row ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CatMoodBadge(completed: _todayCompleted, goal: _dailyGoal),
              const _WordTypeBadge(label: '新词'),
            ],
          ),
          const SizedBox(height: 10),

          // ── Word + speaker ───────────────────────────────────────────────
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

          // ── POS pill + primary meaning ───────────────────────────────────
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
                  child: Text(
                    pos,
                    style: const TextStyle(fontSize: 10, color: _kPurple),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  word.meaning,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _kTextDark,
                  ),
                ),
              ),
            ],
          ),

          // ── Translation lines (full breakdown) ───────────────────────────
          if (lines.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                color: Color(0xFFF4EFE5),
                thickness: 0.5,
                height: 1,
              ),
            ),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kTextMedium,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],

          // ── Example sentences (v3 content enhancement) ───────────────────
          if (word.examples != null && word.examples!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 10, bottom: 8),
              child: Divider(
                color: Color(0xFFF4EFE5),
                thickness: 0.5,
                height: 1,
              ),
            ),
            _buildExamplesSection(word.examples!),
          ],
        ],
      ),
    );
  }

  // ── Example sentences section ─────────────────────────────────────────────

  Widget _buildExamplesSection(List<WordExample> examples) {
    // Show up to 2 examples; strip [bracket] markers for clean plain display.
    final shown = examples.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '例句',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _kTextGray,
            letterSpacing: 0.4,
          ),
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
                Text(
                  enPlain,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kTextDark,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cnPlain,
                  style: const TextStyle(
                    fontSize: 10,
                    color: _kTextGray,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  /// P3.3.1: 4-button rating. Label update per v5 UI spec.
  /// Rating mapping (FROZEN): 熟悉→easy / 认识→good / 模糊→hard / 不认识→again.
  ///
  /// preview_durations_reentry_contract_v1 (FROZEN, P3.3.4):
  ///   previewDurations = local FSRS candidate hint — NOT cloud serving truth.
  ///   Disclaimer shown when preview is loaded.
  ///   MUST NOT say: "下次将在X天后复习" / "系统已安排" / "已更新计划".
  Widget _buildActionButtons() {
    const configs = [
      _StudyBtn(
        label: '熟悉',
        rating: ReviewRating.easy,
        bgColor: _kPurple,
        borderColor: _kPurple,
        textColor: Colors.white,
        hasTick: true,
      ),
      _StudyBtn(
        label: '认识',
        rating: ReviewRating.good,
        bgColor: _kSoftPurpleBg,
        borderColor: _kPurpleBorder,
        textColor: _kPurple,
      ),
      _StudyBtn(
        label: '模糊',
        rating: ReviewRating.hard,
        bgColor: _kOrangeBg,
        borderColor: _kOrangeBorder,
        textColor: _kOrangeText,
      ),
      _StudyBtn(
        label: '不认识',
        rating: ReviewRating.again,
        bgColor: _kNeutralBg,
        borderColor: _kNeutralBorder,
        textColor: _kNeutralText,
      ),
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
          // preview_durations_reentry_contract_v1 disclaimer (FROZEN, P3.3.4)
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

  // ── Bottom action pills ───────────────────────────────────────────────────

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PillBtn(
            label: '♡ 收藏',
            onTap: () => _showComingSoon('收藏'),
          ),
          const SizedBox(width: 6),
          _PillBtn(
            label: '⚑ 困难词',
            onTap: () => _showComingSoon('困难词'),
          ),
          const SizedBox(width: 6),
          _PillBtn(
            label: '更多释义',
            onTap: _showMoreMeanings,
          ),
        ],
      ),
    );
  }

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
            // Header
            Row(
              children: [
                Text(
                  word!.wordText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark,
                  ),
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
              Text(
                word.phonetic!,
                style: const TextStyle(fontSize: 12, color: _kTextGray),
              ),
            const SizedBox(height: 16),
            const Divider(color: _kBorderColor, thickness: 0.5, height: 1),
            const SizedBox(height: 12),
            // All translation lines
            ..._translationLines(translation).map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _kTextMedium,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Terminal states ───────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: _kOrangeText, size: 48),
            const SizedBox(height: 16),
            const Text(
              '加载失败',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _kTextDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _kTextGray),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadNextWord,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            '今日新词已学完',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '今日已学 $_todayCompleted 个单词',
            style: const TextStyle(fontSize: 14, color: _kTextGray),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }
}

// ── Private helper data classes ───────────────────────────────────────────────

/// Button config for the 4-button rating row.
class _StudyBtn {
  final String label;
  final ReviewRating rating;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final bool hasTick;

  const _StudyBtn({
    required this.label,
    required this.rating,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    this.hasTick = false,
  });
}

// ── Private helper widgets ────────────────────────────────────────────────────

/// A single rating button used in the horizontal 4-button row.
class _RatingButton extends StatelessWidget {
  final _StudyBtn config;
  final bool enabled;
  final VoidCallback onTap;

  const _RatingButton({
    required this.config,
    required this.enabled,
    required this.onTap,
  });

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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: config.textColor,
                ),
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

/// Cat mood badge — shows cat emoji + mood text based on session progress.
class _CatMoodBadge extends StatelessWidget {
  final int completed;
  final int goal;

  const _CatMoodBadge({required this.completed, required this.goal});

  @override
  Widget build(BuildContext context) {
    final ratio = goal > 0 ? completed / goal : 0.0;
    final (emoji, mood) = ratio >= 0.7
        ? ('😸', '状态很棒')
        : ratio >= 0.3
            ? ('😺', '不错加油')
            : ('🐱', '今日状态稳定');

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
          Text(
            mood,
            style: const TextStyle(fontSize: 10, color: Color(0xFFA68872)),
          ),
        ],
      ),
    );
  }
}

/// Word type badge — e.g. "新词" or "复习".
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
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: _kGreenText),
      ),
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
          border: Border.all(
            color: const Color(0xFFEFEBE4),
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF8B8178)),
        ),
      ),
    );
  }
}

// ── Session requeue entry (session_requeue_v1) ─────────────────────────────

/// Holds a word pending re-show after a short intra-session delay.
///
/// [cardsNeededBefore]: number of OTHER cards the user must see before
/// this word reappears. Decremented by _loadNextWord() on each transition.
class _RequeueEntry {
  final Word word;
  final int cardsNeededBefore;
  int cardsSinceRequeue = 0;

  _RequeueEntry({required this.word, required this.cardsNeededBefore});

  bool get isReady => cardsSinceRequeue >= cardsNeededBefore;
}
