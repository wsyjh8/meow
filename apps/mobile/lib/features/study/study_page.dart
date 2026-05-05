import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app.dart' show studyPageRouteObserver;
import '../../core/api/api_client.dart';
import '../../core/audio/audio_cache_repository.dart' show AudioFetchException;
import '../../core/audio/example_audio_service.dart';
import '../../core/audio/pronunciation_service.dart';
import '../../core/audio/word_audio_service.dart';
import '../../core/util/stable_id.dart' show normalizeWord;
import '../../core/util/pos_label.dart';
import '../../core/memory/fsrs_service.dart';
import '../../core/memory/review_rating.dart';
import '../../core/services/session_store.dart';
import '../../core/services/session_sync_service.dart';
import '../../core/services/study_service.dart';
import '../../core/services/word_enrichment_service.dart';
import '../../core/storage/drift/app_database.dart';
import '../../core/storage/local_database.dart';
import '../../core/storage/local_settings_service.dart';
import 'widgets/cat_companion_strip.dart';
import 'widgets/example_sentence_section.dart';
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

class _StudyPageState extends State<StudyPage> with RouteAware {
  // ── Services ──────────────────────────────────────────────────────────────
  late final StudyService _studyService;
  late final FsrsService _fsrsService;
  late final PronunciationService _pronunciationService;
  late final ExampleAudioService _exampleAudioService;
  late final WordAudioService _wordAudioService;
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
  // Start as true so the first frame (before initState's hydrate chain
  // resolves) shows the loader rather than briefly flashing the done state
  // — _currentWord is also null at that moment and the build branches
  // would otherwise hit _buildDoneState().
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  /// preview_durations_reentry_contract_v1 (FROZEN, P3.3.4):
  /// Source: local FSRS candidate only (FsrsService.previewSchedule).
  /// NOT cloud serving truth. NOT a stable plan fact.
  /// Null when: word not yet loaded, during submission, or FSRS card absent/error.
  Map<ReviewRating, Duration>? _previewDurations;

  // ── Session consolidation state (session_consolidation_v1) ─────────────
  // _sessionSeenIds: all words shown this session (mastered + in consolidation).
  //   Used as extraExclude so getNextWord() never returns a word already
  //   handled as the "next new" word.
  // _shownIndex: monotonically increasing counter, +1 each time a word card
  //   is actually displayed (NOT bumped on done / error states).
  // _consolidation: wordId -> _ConsolidationState. A word enters here on its
  //   FIRST forgot rating; subsequent appearances are pure local consolidation
  //   (no FSRS rateCard, no cloud submitStudyAttempt, no entry into
  //   formal attempt history). Rationale: avoid repeated wrong cards
  //   polluting FSRS due/stability and cloud attempt history. The very first
  //   real recall result is the only one that hits the official channels.
  // _lastConsolidationShownIndex: the _shownIndex when a consolidation card
  //   was last displayed. Used to enforce the global "≥4 normal cards
  //   between any two consolidation insertions" throttle (rule 7) while
  //   normalRemaining > 0. Init to a sentinel below 0 so the first
  //   consolidation insertion is unrestricted.
  final Set<String> _sessionSeenIds = {};
  int _shownIndex = 0;
  final Map<String, _ConsolidationState> _consolidation = {};
  int _lastConsolidationShownIndex = -1000;

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
    _pronunciationService = PronunciationService();
    _exampleAudioService = ExampleAudioService();
    _wordAudioService = WordAudioService();
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
    // _loadDailyGoal MUST complete before _loadNextWord, otherwise the first
    // pick runs against unhydrated _todayServedIds (= empty set) and Path B
    // bypasses the daily-goal cap, allowing one extra serve per StudyPage
    // entry. Repeating that across sessions pushes _todayCompleted past
    // _dailyGoal.
    //
    // _hydrateStuckForgots ALSO runs before _loadNextWord so today's
    // forgot-but-never-recovered words are present in _consolidation
    // and Path A / Path C can show them.
    () async {
      await _loadDailyGoal();
      await _hydrateStuckForgots();
      await _loadNextWord();
    }();
  }

  /// Seed [_consolidation] with today's "stuck forgots" — words that
  /// have a forgot record today but no know record (cross-session).
  /// Without this, those words sit in [_todayServedIds] (consuming
  /// dailyGoal budget) but never reappear because consolidation
  /// state is in-memory and dies when the previous session ended.
  ///
  /// Each entry seeds with cooldownUntilIndex = 0 (immediately ready),
  /// failCount = 1, and is also added to [_sessionSeenIds] so Path B
  /// won't try to re-serve them as fresh new words.
  ///
  /// need #21 amendment (option B): if today's submitted-FSRS count
  /// already meets/exceeds the (possibly just-reduced) dailyGoal,
  /// SKIP hydration entirely. The first-time ratings stay in
  /// word_records / FSRS tables (no rollback per spec red line) — we
  /// just don't re-show them today. FSRS handles future scheduling.
  Future<void> _hydrateStuckForgots() async {
    if (_todayServedIds.length >= _dailyGoal) return;
    try {
      final words = await _studyService.loadStuckForgotWords();
      if (!mounted || words.isEmpty) return;
      for (final word in words) {
        _consolidation[word.wordId] = _ConsolidationState(
          word: word,
          cooldownUntilIndex: 0,
          lastShownIndex: 0,
          failCount: 1,
        );
        _sessionSeenIds.add(word.wordId);
      }
    } catch (_) {
      // Hydration is best-effort — failure leaves _consolidation empty,
      // which matches pre-fix behavior.
    }
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route-pop events. When user pushes the settings page
    // and pops back, didPopNext() fires — that's where dailyGoal is
    // re-read so a mid-session change in settings is picked up
    // immediately. RouteObserver.subscribe is idempotent for repeat
    // calls with the same (subscriber, route) pair.
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      studyPageRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    studyPageRouteObserver.unsubscribe(this);
    // Need #8 — close the local session row + post finish to cloud.
    // dispose() runs on Navigator.pop, the Android back button, and app
    // backgrounding via the framework, so this covers the three required
    // exit paths (normal completion / manual end / explicit exit).
    _sessionStore.finish();
    _audioSub?.cancel();
    _pronunciationService.dispose();
    _exampleAudioService.dispose();
    _wordAudioService.dispose();
    _studyService.dispose();
    super.dispose();
  }

  // ── Daily goal change propagation (need #21) ──────────────────────────────
  //
  // When user pushes the settings page and changes dailyGoal then pops
  // back, didPopNext fires. We re-read the persisted value and, if it
  // differs from what we have, kick a single _loadNextWord() so the
  // existing normalRemaining gate at the top of that function picks the
  // right path (continue pulling / consolidate / done).
  //
  // This is the only place the new dailyGoal can flow into a live
  // StudyPage — outside of fresh initState. We deliberately do NOT
  // truncate any queue manually:
  //   - Already-rated words are persisted in word_records / FSRS tables;
  //     never touched here per spec.
  //   - The "pre-fetched but unrated" set in this architecture is at
  //     most 1 (the currently-shown card before user taps a rating).
  //     If the new dailyGoal makes that slot illegal, _loadNextWord
  //     replaces _currentWord with the next legitimate candidate (or
  //     done state). The discarded card never wrote to FSRS / cloud,
  //     so it's free to reappear later as a fresh new word.

  @override
  void didPopNext() {
    super.didPopNext();
    _refreshDailyGoalFromPrefs();
  }

  Future<void> _refreshDailyGoalFromPrefs() async {
    int newGoal;
    try {
      final prefs = await SharedPreferences.getInstance();
      newGoal = LocalSettingsService(prefs).dailyGoal;
    } catch (_) {
      return;
    }
    if (!mounted || newGoal == _dailyGoal) return;
    setState(() => _dailyGoal = newGoal);
    // need #21 amendment (option B): when the new cap is already
    // breached by today's submitted-FSRS count, also drop the
    // consolidation queue so today's stuck forgots stop re-appearing.
    // Records / FSRS state are NOT touched — only the in-session
    // re-show loop is silenced. FSRS handles future scheduling.
    if (_todayServedIds.length >= _dailyGoal) {
      _consolidation.clear();
    }
    await _loadNextWord();
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

    // session_consolidation_v1 — pick order:
    //   A. consolidation queue ready item (cooldownUntilIndex <= _shownIndex)
    //      — only when normalRemaining > 0 AND the global "≥4 normal cards
    //      between consolidation insertions" throttle is satisfied.
    //   B. fresh new word from getNextWord — gated by _todayServedIds.length
    //      < _dailyGoal (bug006 口径: dailyGoal only restricts pulling new
    //      words; mastered count is no longer an early-return gate).
    //   C. fallback: queue is genuinely out of fresh content but
    //      consolidation has entries — show the longest-untouched one,
    //      ignore cooldown and throttle. "Anti-loop" only applies when
    //      there is fresh content to protect; once the queue is down to
    //      consolidation, cycling the remaining wrong words is desired.
    //   D. truly done (no consolidation, no new words available).
    //
    // _shownIndex is incremented ONLY when a word card is actually
    // displayed (paths A, B, C). Path D does not bump it.
    final normalRemaining = (_dailyGoal - _todayServedIds.length).clamp(0, 1 << 30);
    final throttleSatisfied =
        _shownIndex - _lastConsolidationShownIndex >= 4;

    // ── Path A: ready consolidation item (gated by normalRemaining > 0
    // AND ≥4 normal cards since last consolidation insertion) ────────
    // Pick eligible (cooldownUntilIndex <= _shownIndex), preferring the
    // entry whose lastShownIndex is smallest (i.e. shown longest ago).
    if (normalRemaining > 0 && throttleSatisfied) {
      _ConsolidationState? readyEntry;
      for (final entry in _consolidation.values) {
        if (entry.cooldownUntilIndex <= _shownIndex) {
          if (readyEntry == null ||
              entry.lastShownIndex < readyEntry.lastShownIndex) {
            readyEntry = entry;
          }
        }
      }
      if (readyEntry != null) {
        _shownIndex++;
        readyEntry.lastShownIndex = _shownIndex;
        _lastConsolidationShownIndex = _shownIndex;
        final word = readyEntry.word;
        if (mounted) {
          setState(() { _currentWord = word; _isLoading = false; _isSubmitting = false; });
          _loadPreviewForWord(word.wordId);
          _loadEnrichmentForWord(word);
          _prefetchUpcoming();
        }
        return;
      }
    }

    // ── Path B: fresh new word (gated by daily-goal served cap) ───────
    try {
      if (normalRemaining > 0) {
        final word = await _studyService.getNextWord(extraExclude: _sessionSeenIds);
        if (word != null) {
          _sessionSeenIds.add(word.wordId);
          _todayServedIds.add(word.wordId);
          _shownIndex++;
          if (mounted) {
            setState(() { _currentWord = word; _isLoading = false; _isSubmitting = false; });
            _loadPreviewForWord(word.wordId);
            _loadEnrichmentForWord(word);
            _prefetchUpcoming();

            // v0.3.0 P1: WordCacheService removed — words are already in
            // word_entries (loaded by WordbookLoader from bundled assets).
            // No API-served word cache step anymore. (Was P3.3.17's
            // _wordCacheService.insertWord(...) call here.)
          }
          return;
        }
      }

      // ── Path C: fallback to consolidation, ignoring cooldown ──────
      // Reached only when no fresh new word is available. With nothing
      // else to interleave, the spacing rule serves no purpose — just
      // show the longest-untouched consolidation entry.
      if (_consolidation.isNotEmpty) {
        _ConsolidationState? fallback;
        for (final entry in _consolidation.values) {
          if (fallback == null ||
              entry.lastShownIndex < fallback.lastShownIndex) {
            fallback = entry;
          }
        }
        _shownIndex++;
        fallback!.lastShownIndex = _shownIndex;
        _lastConsolidationShownIndex = _shownIndex;
        final word = fallback.word;
        if (mounted) {
          setState(() { _currentWord = word; _isLoading = false; _isSubmitting = false; });
          _loadPreviewForWord(word.wordId);
          _loadEnrichmentForWord(word);
          _prefetchUpcoming();
        }
        return;
      }

      // ── Path D: truly done for this session ───────────────────────
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

  /// Prefetch pronunciation audio + example audio + enrichment SQL for
  /// the next ~5 upcoming words. All paths fire off the same
  /// `peekNextWordTexts` result so we only ask the DB once. All errors
  /// silently swallowed at every layer (peek, prefetch, warmUp) — best-effort.
  ///
  /// v0.3.0 P2.1/P2.2 prefetches:
  ///   1. Word audio via WordAudioService (new MP3 path; canonical wordId
  ///      via normalize_word — allowed at runtime, string normalization
  ///      not a hash).
  ///   2. Word audio via PronunciationService (legacy WAV; wordText as-is)
  ///      —— transitional fallback while Codex finishes new word audio
  ///      pipeline; remove once /api/v1/words/:id/audio covers all words.
  ///   3. Enrichment SQL warm-up (so 其他形式 / 近反义词 / 常见词组 /
  ///      词根词缀 don't visibly load when the user advances).
  ///   4. Example audio for the *current* word's examples (DB §7.4.2 进
  ///      词书时预下载策略 — render-time variant). The play button next
  ///      to each example finds the mp3 already in audio_file_cache.
  void _prefetchUpcoming() {
    final exclude = Set<String>.from(_sessionSeenIds);
    if (_currentWord != null) exclude.add(_currentWord!.wordId);
    unawaited(
      _studyService
          .peekNextWordTexts(5, extraExclude: exclude)
          .then((wordTexts) {
            final wordIds = wordTexts
                .map(normalizeWord)
                .where((id) => id.isNotEmpty)
                .toList(growable: false);
            if (wordIds.isNotEmpty) _wordAudioService.prefetch(wordIds);
            _pronunciationService.prefetch(wordTexts);
            unawaited(_studyService.warmUpWordTexts(wordTexts));
          })
          .catchError((_) {}),
    );

    // Example audio prefetch for the current word's examples.
    final examples = _currentWord?.examples;
    if (examples != null && examples.isNotEmpty) {
      final stableIds = examples
          .map((e) => e.stableId)
          .whereType<String>()
          .toList(growable: false);
      if (stableIds.isNotEmpty) {
        _exampleAudioService.prefetch(stableIds);
      }
    }
  }

  // session_consolidation_v1: 4-button rating handler.
  //
  // Two distinct paths based on whether this is the FIRST appearance of the
  // word or a same-session consolidation re-show:
  //
  //   FIRST appearance (word NOT in _consolidation):
  //     - Official FSRS rating (rateCard) + official cloud attempt.
  //     - On forgot → seed _consolidation with cooldownUntilIndex driven by
  //       _computeCooldownGap (dynamic spacing scaled to remaining new-word
  //       budget; see helpers at the bottom of this state class).
  //     - On know → bump _todayCompleted (mastered progress).
  //
  //   CONSOLIDATION appearance (word IS in _consolidation):
  //     - NO FSRS rateCard, NO cloud submitStudyAttempt — pure local state.
  //     - know: consecutiveCorrect++; ≥2 → exit consolidation; on exit,
  //       write a LOCAL-only know record to word_records (so cross-session
  //       rehydration won't re-seed it) and bump _todayCompleted.
  //     - forgot: failCount++; consecutiveCorrect reset; dynamic cooldown.
  //
  // Rationale: avoid repeated wrong cards polluting FSRS due/stability and
  // cloud attempt history. The first real recall is the only one that hits
  // the official channels.
  Future<void> _onRate(ReviewRating rating) async {
    if (_isSubmitting || _currentWord == null) return;
    if (mounted) setState(() { _isSubmitting = true; _error = null; _previewDurations = null; });

    final wordId = _currentWord!.wordId;
    final isConsolidation = _consolidation.containsKey(wordId);
    final isForgot = rating == ReviewRating.again || rating == ReviewRating.hard;

    try {
      if (!isConsolidation) {
        // ── FIRST appearance ──────────────────────────────────────────
        await _fsrsService.initCardForWord(wordId);
        await _fsrsService.rateCard(wordId, rating);

        final binaryResult = isForgot ? 'forgot' : 'know';
        await _studyService.submitStudyAttempt(
          wordId: wordId,
          bookId: _currentWord!.bookId,
          studyType: 'new',
          actionResult: binaryResult,
          sessionId: _sessionId,
        );

        if (isForgot) {
          _sessionSeenIds.add(wordId);
          _consolidation[wordId] = _ConsolidationState(
            word: _currentWord!,
            cooldownUntilIndex: _shownIndex + _computeCooldownGap(wordId, 1),
            lastShownIndex: _shownIndex,
            failCount: 1,
          );
        } else {
          if (mounted) setState(() => _todayCompleted++);
        }
      } else {
        // ── CONSOLIDATION appearance — local state only ───────────────
        final state = _consolidation[wordId]!;
        if (isForgot) {
          state.consecutiveCorrect = 0;
          state.failCount++;
          state.cooldownUntilIndex =
              _shownIndex + _computeCooldownGap(wordId, state.failCount);
        } else {
          state.consecutiveCorrect++;
          if (state.consecutiveCorrect >= 2) {
            // Consolidation graduation — persist a LOCAL-ONLY know record
            // so future sessions today don't re-seed this word into
            // _consolidation, and bump mastered progress. Cloud / FSRS
            // are intentionally untouched per session_consolidation_v1.
            await _studyService.recordLocalConsolidationRecovery(
              wordId: wordId,
              bookId: _currentWord!.bookId,
              sessionId: _sessionId,
            );
            _consolidation.remove(wordId);
            if (mounted) setState(() => _todayCompleted++);
          } else {
            state.cooldownUntilIndex =
                _shownIndex + _computeCooldownGap(wordId, state.failCount);
          }
        }
      }

      await _loadNextWord();
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isSubmitting = false; });
      return;
    }

    if (mounted) setState(() { _isSubmitting = false; });
  }

  // ── Dynamic spacing (session_consolidation_v1 spec) ───────────────────────
  //
  // gap = baseGap + failBoost + jitter, where the tier of (baseGap, jitterMax)
  // is decided by normalRemaining = dailyGoal - todayServedIds.length:
  //
  //   normalRemaining        baseGap            jitterMax
  //   ≥ 15                   8                  4
  //   8–14                   6                  3
  //   4–7                    4                  2
  //   1–3                    normalRemaining+1  1
  //   0                      0                  0   (集中巩固 phase)
  //
  // failBoost = clamp(failCount - 1, 0, 2) * 3, so:
  //   1st forgot → 0, 2nd → 3, 3rd+ → 6 (capped).
  //
  // jitter is stable per (wordId, failCount) so test runs are deterministic
  // and the same word doesn't drift between consecutive _loadNextWord calls.
  int _computeCooldownGap(String wordId, int failCount) {
    final normalRemaining =
        (_dailyGoal - _todayServedIds.length).clamp(0, 1 << 30);
    final int baseGap;
    final int jitterMax;
    if (normalRemaining >= 15) {
      baseGap = 8;
      jitterMax = 4;
    } else if (normalRemaining >= 8) {
      baseGap = 6;
      jitterMax = 3;
    } else if (normalRemaining >= 4) {
      baseGap = 4;
      jitterMax = 2;
    } else if (normalRemaining >= 1) {
      baseGap = normalRemaining + 1;
      jitterMax = 1;
    } else {
      // 集中巩固 phase: cooldown effectively disabled. Path C handles
      // round-robin display once normal queue is exhausted.
      baseGap = 0;
      jitterMax = 0;
    }
    final failBoost = (failCount - 1).clamp(0, 2) * 3;
    final jitter = _stableJitter('$wordId|$failCount', jitterMax);
    return baseGap + failBoost + jitter;
  }

  /// Deterministic jitter in [0, max] derived from [key]. Returns 0 if
  /// [max] ≤ 0. Uses a simple polynomial rolling hash so the result is
  /// stable across runs and platforms (no dependency on Object.hashCode).
  int _stableJitter(String key, int max) {
    if (max <= 0) return 0;
    int h = 0;
    for (var i = 0; i < key.length; i++) {
      h = (h * 31 + key.codeUnitAt(i)) & 0x7fffffff;
    }
    return h % (max + 1);
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
        meaningLines: lines,
        isPlayingAudio: _isPlayingAudio,
        todayCompleted: _todayCompleted,
        dailyGoal: _dailyGoal,
        onSpeakerTap: _playPronunciation,
      ),
    ];

    if (word.examples != null && word.examples!.isNotEmpty) {
      modules.add(ExampleSentenceSection(
        examples: word.examples!,
        audioService: _exampleAudioService,
      ));
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
  ///
  /// v0.3.0 P2.2: tries the new [WordAudioService] (audio_assets table → MP3
  /// in cdn-mock) first. If the API returns 404 (Codex hasn't generated this
  /// word's audio yet), falls back to legacy [PronunciationService] (WAV
  /// served from `/api/v1/pronunciation/{word}.wav`). Once Codex finishes
  /// the word audio pipeline, the fallback path will become unused and
  /// PronunciationService can be deprecated.
  Future<void> _playPronunciation() async {
    final word = _currentWord;
    if (word == null) return;
    try {
      await _wordAudioService.play(word.wordId);
    } on AudioFetchException {
      // Word audio not yet in audio_assets — fall back to legacy WAV path.
      try {
        await _pronunciationService.play(word.wordText);
      } catch (_) {
        _showPronunciationFailedSnackBar();
      }
    } catch (_) {
      _showPronunciationFailedSnackBar();
    }
  }

  void _showPronunciationFailedSnackBar() {
    if (!mounted) return;
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

// ── Session consolidation entry (session_consolidation_v1) ─────────────────

/// Per-word state for the same-session consolidation queue.
///
/// A word lands here when it is rated `forgot` for the FIRST time this
/// session. While in consolidation, all subsequent ratings are processed
/// locally only — they do NOT touch FSRS or the cloud attempt history.
///
/// - [cooldownUntilIndex]: the page-level `_shownIndex` must be ≥ this
///   value before the word may appear again. Initial value of
///   `_shownIndex + 4` guarantees at least 3 other cards intervene.
/// - [lastShownIndex]: the `_shownIndex` value at the most recent display.
///   Used to choose the longest-untouched ready entry when several are eligible.
/// - [consecutiveCorrect]: number of consecutive `know` ratings in
///   consolidation. ≥ 2 evicts the entry (consolidation complete).
/// - [failCount]: cumulative `forgot` ratings (including the first). Each
///   subsequent forgot extends the cooldown to `_shownIndex + 3 + failCount`.
class _ConsolidationState {
  final Word word;
  int cooldownUntilIndex;
  int lastShownIndex;
  int consecutiveCorrect = 0;
  int failCount;

  _ConsolidationState({
    required this.word,
    required this.cooldownUntilIndex,
    required this.lastShownIndex,
    this.failCount = 0,
  });
}
