import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/audio/pronunciation_service.dart';
import '../../core/util/pos_label.dart';
import '../../core/memory/fsrs_service.dart';
import '../../core/memory/review_rating.dart';
import '../../core/memory/word_cache_service.dart';
import '../../core/services/session_store.dart';
import '../../core/services/session_sync_service.dart';
import '../../core/services/study_service.dart';
import '../../core/services/word_enrichment_service.dart';
import '../../core/storage/drift/app_database.dart';
import '../../core/storage/local_database.dart';
import '../../core/storage/local_settings_service.dart';
import 'widgets/cat_companion_strip.dart';
import 'widgets/example_sentence_section.dart';
import 'widgets/meaning_section.dart';
import 'widgets/review_buttons_section.dart';
import 'widgets/study_tokens.dart';
import 'widgets/word_forms_section.dart';
import 'widgets/word_header_section.dart';
import 'widgets/word_morphemes_section.dart';
import 'widgets/word_phrases_section.dart';
import 'widgets/word_relations_section.dart';

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
  late final SessionStore _sessionStore;
  late final SessionSyncService _sessionSyncService;
  late final WordEnrichmentService _enrichmentService;
  StreamSubscription<PlayerState>? _audioSub;

  // Need #8 — Local id for the current study session, threaded into every
  // submitStudyAttempt this page makes. Null until session starts (rare race).
  String? _sessionId;

  // Need #11 — Optional enrichment payload for the current word.
  // Empty payload (or null while loading) renders nothing. Always
  // matches the in-flight word_id below to avoid race-induced
  // mismatches when the user rates rapidly.
  WordEnrichment? _enrichment;
  String? _enrichmentLoadingForWordId;

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
  //
  // Bug 2 follow-up: there used to be a `_requeuedOnceIds` set that
  // capped a card to a single requeue cycle — second 不认识 would
  // bypass the requeue and end the card. This caused the completion
  // screen to fire after roughly 2N taps even if the user mastered
  // zero. New behaviour: forgot ALWAYS requeues. The done gate moved
  // from "_todayServedIds full + queue empty" to "_todayCompleted ≥
  // _dailyGoal" so the user can only finish the day by mastering N
  // cards (i.e. N taps of 认识/熟悉), not by tapping 不认识 enough times.
  final Set<String> _sessionSeenIds = {};
  final List<_RequeueEntry> _requeuedWords = [];

  // ── Today progress ─────────────────────────────────────────────────────────
  /// Number of new words mastered today (cumulative across sessions).
  /// Loaded from LocalDatabase.countTodayNewCompleted() on init,
  /// then incremented on each binaryResult == 'know'. Drives the top
  /// progress text (`今日新词 · X / Y`) — mastered/goal semantics.
  int _todayCompleted = 0;

  /// Bug 4 — Unique new word_ids served today, regardless of
  /// action_result (know AND forgot both count). Hydrated from SQLite
  /// on init via [LocalDatabase.getTodayServedNewWordIds] and grown
  /// in-memory each time [_loadNextWord] hands out a fresh new card.
  /// Used as the canonical daily-goal gate so 不认识/模糊 cannot
  /// inflate the served count past _dailyGoal.
  ///
  /// Distinct from [_sessionSeenIds] (which is session-scoped and
  /// drives StudyService.getNextWord exclusion). This set is
  /// calendar-day-scoped and survives app restarts.
  final Set<String> _todayServedIds = {};

  /// Daily goal loaded from LocalSettingsService. Default 20 until loaded.
  int _dailyGoal = 20;

  // ── Cream-Café UI placeholders (Need #18 visual revamp) ─────────────────
  // Star and fish-counter live in the top app bar but are not yet wired
  // to backend state — they show a "coming soon" snackbar on tap and
  // toggle local visual state only. Real wiring (favourites table + cat
  // fish reward) lands in a later need.
  bool _isStarred = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final appDb = AppDatabase();
    final apiClient = ApiClient();
    _studyService = StudyService(
      apiClient: apiClient,
      db: LocalDatabase.instance,
      driftDb: appDb,
    );
    _fsrsService = FsrsService(db: appDb);
    _wordCacheService = WordCacheService(db: appDb);
    _pronunciationService = PronunciationService();
    _sessionStore = SessionStore(apiClient: apiClient, driftDb: appDb);
    _sessionSyncService =
        SessionSyncService(apiClient: apiClient, driftDb: appDb);
    _enrichmentService = WordEnrichmentService(driftDb: appDb);
    _audioSub = _pronunciationService.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlayingAudio = state == PlayerState.playing);
    });
    // Need #8 — drain any unfinished sessions from prior runs first, then
    // open a new one for this study page.
    _sessionSyncService.drainPending();
    _studyService.syncPendingAttempts();
    _startSession();
    _loadDailyGoal();
    _loadNextWord();
  }

  Future<void> _startSession() async {
    try {
      final id = await _sessionStore.startForStudy();
      if (mounted) setState(() => _sessionId = id);
    } catch (_) {
      // Local insert failure is non-fatal for the study flow — attempts will
      // simply submit without a session_id and rely on the backend's
      // time-window fallback.
    }
  }

  @override
  void dispose() {
    // Need #8 — close the local session row + post finish to cloud.
    // dispose() runs on Navigator.pop, the Android back button, and app
    // backgrounding via the framework, so this covers the three required
    // exit paths (normal completion / manual end / explicit exit).
    _sessionStore.finish();
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
    try {
      // Bug 4 — Hydrate the served-id gate from SQLite so the daily goal
      // limit survives app restarts within the same calendar day.
      final served = await LocalDatabase.instance.getTodayServedNewWordIds();
      if (mounted) setState(() => _todayServedIds.addAll(served));
    } catch (_) {
      // Stay at empty set — non-blocking
    }
  }

  // ── Business logic (FROZEN — do not modify without governance review) ─────

  Future<void> _loadNextWord() async {
    setState(() { _isLoading = true; _error = null; });

    // ── "Today is done" gate (Bug 2 follow-up: mastered, not served) ──
    // Mastered count reaching the daily goal = today is complete.
    // Whether the requeue still holds cards or not is irrelevant —
    // the user has internalised _dailyGoal new words today.
    if (_todayCompleted >= _dailyGoal) {
      if (mounted) setState(() { _currentWord = null; _isLoading = false; _isSubmitting = false; });
      return;
    }

    // ── "Don't pull more new words" cap (Bug 4 — kept) ──
    // Even though completion is now driven by mastered count, we still
    // refuse to enqueue NEW words past _dailyGoal unique seen-today.
    // This bounds the queue size so a forever-不认识 user can't
    // accidentally inflate the served pool. Requeue cycle keeps
    // running; user must master existing cards to drain it.
    //
    // Edge case (probably unreachable now that forgot always requeues):
    // served cap hit AND queue empty AND mastered < goal. We still
    // declare today done so the page doesn't get stuck on a blank card.
    if (_todayServedIds.length >= _dailyGoal && _requeuedWords.isEmpty) {
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
        _loadEnrichmentForWord(entry.word);
        _prefetchUpcoming();
      }
      return;
    }

    // 2. Get next unseen word, excluding all session-seen words.
    try {
      final word = await _studyService.getNextWord(extraExclude: _sessionSeenIds);
      if (word != null) {
        _sessionSeenIds.add(word.wordId);
        // Bug 4 — count this card against today's served-set so the
        // gate above will trigger when goal is reached, even if the
        // user only rates 不认识/模糊 (which never bumps _todayCompleted).
        _todayServedIds.add(word.wordId);
        if (mounted) {
          setState(() { _currentWord = word; _isLoading = false; _isSubmitting = false; });
          _loadPreviewForWord(word.wordId);
          _loadEnrichmentForWord(word);
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
          _loadEnrichmentForWord(entry.word);
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

  /// Need #11 — Load optional enrichment (forms / synonyms+antonyms /
  /// phrases) for [word]. Always overwrites in-flight load so a fast
  /// rate sequence can't show stale data; if the user moves on before
  /// the query returns, we drop the result. Failures clear to empty —
  /// the UI hides the section, never shows an error.
  Future<void> _loadEnrichmentForWord(Word word) async {
    _enrichmentLoadingForWordId = word.wordId;
    if (mounted) setState(() => _enrichment = null);
    try {
      final result = await _enrichmentService.getFor(word.wordText);
      if (!mounted) return;
      // Drop if the user already moved on.
      if (_enrichmentLoadingForWordId != word.wordId) return;
      setState(() => _enrichment = result);
    } catch (_) {
      if (!mounted) return;
      if (_enrichmentLoadingForWordId != word.wordId) return;
      setState(() => _enrichment = WordEnrichment.empty);
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
        sessionId: _sessionId,
      );

      // Step 5 (session_requeue_v1, Bug 2 follow-up):
      // On 'forgot' (不认识 / 模糊), ALWAYS requeue the card with the
      // configured short delay — even if we've already requeued it
      // before. This is intentional: today is "complete" only when
      // _todayCompleted (mastered) reaches _dailyGoal, so a card the
      // user can't recall must keep coming back until they finally
      // tap 认识/熟悉.
      //
      // The previous implementation capped each card to a single
      // requeue cycle via `_requeuedOnceIds`; that caused completion
      // to fire after roughly 2 × _dailyGoal taps even with mastered
      // = 0. Removed.
      if (binaryResult == 'forgot') {
        // again (不认识) = 3 cards; hard (模糊) = 2 cards.
        final delay = rating == ReviewRating.again ? 3 : 2;
        _sessionSeenIds.add(_currentWord!.wordId); // exclude from new-word picks
        _requeuedWords.add(_RequeueEntry(word: _currentWord!, cardsNeededBefore: delay));
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StudyTokens.bg,
      body: SafeArea(
        child: _isLoading && _currentWord == null
            ? const Center(child: CircularProgressIndicator(color: StudyTokens.purple))
            : _error != null
                ? _buildErrorState()
                : _currentWord == null
                    ? _buildDoneState()
                    : _buildStudyContent(),
      ),
    );
  }

  Widget _buildStudyContent() {
    // Cream-Café composition (Memo1, May 2026):
    //   1. Fixed top bar — back + fish-counter pill + star (placeholders)
    //   2. Slim progress bar
    //   3. Scrollable column — WordTitleCard + per-section cards (each its
    //      own card with cream gap between, no longer a single mega-card)
    //   4. Fixed bottom — cat companion strip + 4 rating buttons + bottom
    //      action pills
    return Column(
      children: [
        _buildTopBar(),
        _buildProgressBar(),
        Expanded(child: _buildScrollColumn()),
        const CatCompanionStrip(),
        ReviewButtonsSection(
          enabled: !_isSubmitting,
          previewDurations: _previewDurations,
          onRate: _onRate,
        ),
        _buildBottomActions(),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.chevron_left_rounded,
              size: 24,
              color: StudyTokens.ink,
            ),
          ),
          const Spacer(),
          // Fish counter pill — placeholder. Shows today's progress as the
          // proxy number until the cat-fish reward system wires up.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: StudyTokens.cream,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🐟', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Text(
                  'Momo · $_todayCompleted / $_dailyGoal',
                  style: StudyTokens.round(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: StudyTokens.main,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Star button — placeholder, toggles local state only.
          GestureDetector(
            onTap: () {
              setState(() => _isStarred = !_isStarred);
              _showComingSoon('收藏');
            },
            child: Icon(
              _isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 22,
              color: StudyTokens.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = _dailyGoal > 0
        ? (_todayCompleted / _dailyGoal).clamp(0.0, 1.0)
        : 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 5,
          backgroundColor: StudyTokens.cream,
          valueColor: const AlwaysStoppedAnimation<Color>(StudyTokens.main),
        ),
      ),
    );
  }

  // ── Scrollable column (Cream-Café revamp) ───────────────────────────────
  //
  // The legacy "one big white card" composition has been replaced with a
  // stack of independent cards (WordTitleCard + per-section cards) sitting
  // on the page's cream background, with 12px gaps between them. Memo1
  // calls this the "café receipt stack" feel — each card looks like a
  // separate slip of paper rather than one giant pane.
  //
  // The whole column scrolls together (the header no longer needs to be
  // pinned because it's much shorter and the body is shorter too — the
  // PRD #14 fixed-header constraint was tied to the single-card layout).
  Widget _buildScrollColumn() {
    final word = _currentWord!;
    final lines = translationLines(word.translation);

    final modules = <Widget>[
      WordHeaderSection(
        word: word,
        isPlayingAudio: _isPlayingAudio,
        todayCompleted: _todayCompleted,
        dailyGoal: _dailyGoal,
        onSpeakerTap: _playPronunciation,
      ),
    ];

    if (lines.isNotEmpty) {
      modules.add(MeaningSection(lines: lines));
    }
    if (word.examples != null && word.examples!.isNotEmpty) {
      modules.add(ExampleSentenceSection(examples: word.examples!));
    }
    final e = _enrichment;
    if (e != null) {
      if (e.hasRelations) {
        modules.add(WordRelationsSection(
          synonyms: e.synonyms,
          antonyms: e.antonyms,
        ));
      }
      if (e.hasPhrases) modules.add(WordPhrasesSection(phrases: e.phrases));
      if (e.hasForms) modules.add(WordFormsSection(forms: e.forms));
      if (e.hasMorphemes) {
        modules.add(WordMorphemesSection(morphemes: e.morphemes));
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < modules.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            modules[i],
          ],
        ],
      ),
    );
  }

  /// Speaker button handler — extracted so [WordHeaderSection] can stay
  /// purely presentational. Mirrors the previous inline GestureDetector
  /// onTap body (catch + SnackBar on failure).
  Future<void> _playPronunciation() async {
    final word = _currentWord;
    if (word == null) return;
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
  }

  // ── Bottom action pills ───────────────────────────────────────────────────
  // (4-rating row + preview disclaimer moved to ReviewButtonsSection.)

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                    color: StudyTokens.textDark,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20, color: StudyTokens.textGray),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (word.phonetic != null && word.phonetic!.isNotEmpty)
              Text(
                word.phonetic!,
                style: const TextStyle(fontSize: 12, color: StudyTokens.textGray),
              ),
            const SizedBox(height: 16),
            const Divider(color: StudyTokens.borderColor, thickness: 0.5, height: 1),
            const SizedBox(height: 12),
            // All translation lines
            ...translationLines(translation).map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  line,
                  style: const TextStyle(
                    fontSize: 14,
                    color: StudyTokens.textMedium,
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
            const Icon(Icons.error_outline, color: StudyTokens.orangeText, size: 48),
            const SizedBox(height: 16),
            const Text(
              '加载失败',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: StudyTokens.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: StudyTokens.textGray),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadNextWord,
              style: ElevatedButton.styleFrom(
                backgroundColor: StudyTokens.purple,
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
    // Bug 2 follow-up: show mastered/goal explicitly. The earlier
    // copy "今日已学 0 个单词" was misleading after a session of all-
    // forgot taps. Now mastered count is the actual completion driver
    // (_todayCompleted >= _dailyGoal) so the displayed value is also
    // the truth-of-completion. The edge case where served=N but
    // mastered<N is reachable only via the legacy fallback gate; we
    // detect it and add a softer second line so the user understands.
    final reachedTarget = _todayCompleted >= _dailyGoal;
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
              color: StudyTokens.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '今日掌握 $_todayCompleted / $_dailyGoal 个',
            style: const TextStyle(fontSize: 14, color: StudyTokens.textGray),
          ),
          if (!reachedTarget) ...[
            const SizedBox(height: 4),
            const Text(
              '今天可学的词都过了一遍，明天 FSRS 会再排你复习',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: StudyTokens.textGray),
            ),
          ],
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: StudyTokens.purple,
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

// ── Private helper widgets ────────────────────────────────────────────────────
// (4-rating row + _CatMoodBadge + _WordTypeBadge + _StudyBtn moved to
//  widgets/review_buttons_section.dart and widgets/word_header_section.dart.)

/// Cream-Café pill button for the bottom secondary-action row.
class _PillBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PillBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: StudyTokens.cream,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: StudyTokens.main,
          ),
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
