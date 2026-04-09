import 'package:drift/drift.dart';

import '../storage/drift/app_database.dart';
import 'fsrs_service.dart';

/// A study session containing interleaved review and new cards.
class ReviewSession {
  /// Ordered queue of word IDs for this session.
  /// Mix of due review cards and newly introduced cards.
  final List<SessionItem> queue;

  /// How many are review (due) cards.
  final int totalReview;

  /// How many are new cards introduced this session.
  final int totalNew;

  /// User's daily new card limit.
  final int dailyNewLimit;

  /// How many new card slots remain today after this session.
  final int newCardsRemainingToday;

  const ReviewSession({
    required this.queue,
    required this.totalReview,
    required this.totalNew,
    required this.dailyNewLimit,
    required this.newCardsRemainingToday,
  });

  /// Total items in the queue.
  int get totalItems => queue.length;

  /// Whether there's nothing to study.
  bool get isEmpty => queue.isEmpty;
}

/// A single item in the study session queue.
class SessionItem {
  final String wordId;

  /// Whether this is a new card (just introduced) or a review card (due).
  final bool isNew;

  const SessionItem({required this.wordId, required this.isNew});
}

/// Builds a study session by combining FSRS due cards with new words
/// from the local cached_words table.
///
/// Key contract (pinned in FSRS_DESIGN_DRAFT.md §5):
///   - newCardsDailyLimit only controls NEW words
///   - review cards (due) are unlimited unless reviewCardsDailyLimit is set
///   - initCardForWord makes a word non-"new" forever
///   - same-day idempotent: calling twice won't re-introduce new words
///   - day boundary: local midnight 00:00 (TODO: configurable 4:00 AM)
class SessionBuilder {
  final FsrsService _fsrsService;
  final AppDatabase _db;

  SessionBuilder({
    required FsrsService fsrsService,
    required AppDatabase db,
  })  : _fsrsService = fsrsService,
        _db = db;

  /// Build today's study session.
  ///
  /// [nowLocal]: current time in user's local timezone.
  /// [newCardsDailyLimit]: max new cards per day (from user settings).
  /// [reviewCardsDailyLimit]: optional cap on review cards (null = unlimited).
  Future<ReviewSession> buildTodaySession({
    required DateTime nowLocal,
    required int newCardsDailyLimit,
    int? reviewCardsDailyLimit,
  }) async {
    // === Step 1: Gather DUE review cards ===
    final dueCards = await _fsrsService.listDueCards(
      nowLocal: nowLocal,
      limit: reviewCardsDailyLimit,
    );

    // === Step 2: Calculate remaining new card slots for today ===
    final usedNew = await _fsrsService.countNewCardsToday(nowLocal: nowLocal);
    final remainingNew = (newCardsDailyLimit - usedNew).clamp(0, newCardsDailyLimit);

    // === Step 3: Find new word candidates from cached_words ===
    List<String> newWordIds = [];
    if (remainingNew > 0) {
      // Words in cached_words that do NOT yet have a card_states row
      final rows = await _db.customSelect(
        'SELECT cw.word_id FROM cached_words cw '
        'WHERE cw.word_id NOT IN (SELECT cs.word_id FROM card_states cs) '
        'ORDER BY cw.sort_order ASC '
        'LIMIT ?',
        variables: [Variable.withInt(remainingNew)],
      ).get();
      newWordIds = rows.map((r) => r.read<String>('word_id')).toList();

      // === Step 4: Initialize FSRS cards for new words ===
      for (final wordId in newWordIds) {
        await _fsrsService.initCardForWord(wordId,
            nowUtc: nowLocal.toUtc());
      }
    }

    // === Step 5: Interleave review and new cards (3:1 ratio) ===
    final queue = _interleave(
      reviewWordIds: dueCards.map((c) => c.wordId).toList(),
      newWordIds: newWordIds,
      ratio: 3,
    );

    return ReviewSession(
      queue: queue,
      totalReview: dueCards.length,
      totalNew: newWordIds.length,
      dailyNewLimit: newCardsDailyLimit,
      newCardsRemainingToday: remainingNew - newWordIds.length,
    );
  }

  /// Interleave review and new cards.
  ///
  /// Pattern with ratio=3: [R, R, R, N, R, R, R, N, ...]
  /// If one list runs out, append the remainder of the other.
  List<SessionItem> _interleave({
    required List<String> reviewWordIds,
    required List<String> newWordIds,
    required int ratio,
  }) {
    final result = <SessionItem>[];
    int ri = 0;
    int ni = 0;

    while (ri < reviewWordIds.length || ni < newWordIds.length) {
      // Insert up to `ratio` review cards
      for (int i = 0; i < ratio && ri < reviewWordIds.length; i++) {
        result.add(SessionItem(wordId: reviewWordIds[ri++], isNew: false));
      }
      // Insert 1 new card
      if (ni < newWordIds.length) {
        result.add(SessionItem(wordId: newWordIds[ni++], isNew: true));
      }
    }

    return result;
  }
}
