import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fsrs/fsrs.dart' as fsrs;

import '../storage/drift/app_database.dart';
import '../storage/repositories/card_state_repository.dart';
import '../storage/repositories/review_log_repository.dart';
import 'card_state_data.dart';
import 'review_rating.dart';

/// Core FSRS service — wraps the fsrs pub.dev library.
///
/// FSRS library types (Card, Rating, State, Scheduler) do NOT leak
/// past this class. UI layer only sees [ReviewRating], [CardStateData].
///
/// All time fields are stored as UTC epoch milliseconds.
/// "Today" calculations accept nowLocal and convert internally.
///
/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.4): FsrsService is now
/// user-scoped. Construction takes a [CardStateRepository] and a
/// [ReviewLogRepository] (or builds them from a [userId]) so every
/// read/write goes through the partition guard. The PR-C-α
/// SP-bridge fallback is gone.
class FsrsService {
  final AppDatabase _db;
  final CardStateRepository _cards;
  final ReviewLogRepository _logs;
  fsrs.Scheduler _scheduler;

  /// Primary constructor — caller (main.dart) injects already-bound
  /// repositories. Recommended in production: it keeps the
  /// AppDatabase / userId resolution in one place and makes test
  /// fixtures trivial to substitute.
  FsrsService({
    required AppDatabase db,
    required CardStateRepository cards,
    required ReviewLogRepository logs,
    double desiredRetention = 0.9,
  })  : _db = db,
        _cards = cards,
        _logs = logs,
        _scheduler = fsrs.Scheduler(
          desiredRetention: desiredRetention,
          // 保留 learning steps 是因为背单词场景需要短期巩固，不要关
          learningSteps: const [Duration(minutes: 1), Duration(minutes: 10)],
          relearningSteps: const [Duration(minutes: 10)],
        );

  /// Convenience constructor for call sites that have a [userId] but
  /// haven't built the repositories themselves. Wires both repositories
  /// against [db] + [userId] so every query is partition-safe.
  factory FsrsService.forUser({
    required AppDatabase db,
    required String userId,
    double desiredRetention = 0.9,
  }) {
    return FsrsService(
      db: db,
      cards: CardStateRepository(db: db, userId: userId),
      logs: ReviewLogRepository(db: db, userId: userId),
      desiredRetention: desiredRetention,
    );
  }

  // ==================== Public API ====================

  /// Create a fresh FSRS card for a word that has never been seen.
  ///
  /// Idempotent: if card_states already has this word_id for the bound
  /// user, returns the existing card.
  /// New card: state=1(Learning), due=now, stability/difficulty=null.
  Future<CardStateData> initCardForWord(String wordId,
      {DateTime? nowUtc}) async {
    final now = nowUtc ?? DateTime.now().toUtc();

    // Check if already exists (idempotent, user-scoped via repo).
    final existing = await _cards.findByWordId(wordId);
    if (existing != null) {
      return _rowToCardStateData(existing);
    }

    // Create new fsrs Card to get default values
    final card = fsrs.Card(cardId: now.millisecondsSinceEpoch);

    final id = await _cards.insertCard(
      wordId: wordId,
      stability: card.stability,
      difficulty: card.difficulty,
      dueMs: now.millisecondsSinceEpoch,
      lastReviewMs: null,
      state: card.state.value,
      step: card.step,
      reps: 0,
      lapses: 0,
      createdAtMs: now.millisecondsSinceEpoch,
    );

    return CardStateData(
      id: id,
      wordId: wordId,
      stability: card.stability,
      difficulty: card.difficulty,
      dueUtc: now,
      lastReviewUtc: null,
      state: card.state.value,
      step: card.step,
      reps: 0,
      lapses: 0,
      createdAtUtc: now,
    );
  }

  /// Rate a card after the user sees it.
  ///
  /// Atomic transaction (Task 3):
  ///   1. Read current card_state
  ///   2. Snapshot state-before for review_log
  ///   3. Compute FSRS scheduling
  ///   4. INSERT review_log (immutable — never update/delete)
  ///   5. UPDATE card_state with new FSRS values
  ///
  /// Throws if the card does not exist for this user. UI must first
  /// call [initCardForWord] before any rating.
  Future<CardStateData> rateCard(
    String wordId,
    ReviewRating rating, {
    DateTime? nowUtc,
  }) async {
    final now = nowUtc ?? DateTime.now().toUtc();

    return _db.transaction(() async {
      // 1. Read current card state (user-scoped via repo).
      final row = await _cards.findByWordId(wordId);
      if (row == null) {
        throw StateError(
          '[FsrsService] rateCard: no card_state for $wordId — '
          'initCardForWord must be called first.',
        );
      }

      // 2. Snapshot state-before (for review_log)
      final stateBefore = row.state;
      final stabilityBefore = row.stability;
      final difficultyBefore = row.difficulty;

      // 3. Reconstruct fsrs Card and compute scheduling
      final card = _rowToFsrsCard(row);
      final fsrsRating = _toFsrsRating(rating);
      final result =
          _scheduler.reviewCard(card, fsrsRating, reviewDateTime: now);
      final newCard = result.card;

      // 4. Compute elapsed_days and scheduled_days for review_log
      final elapsedDays = row.lastReview != null
          ? now
                  .difference(DateTime.fromMillisecondsSinceEpoch(
                      row.lastReview!,
                      isUtc: true))
                  .inHours /
              24.0
          : 0.0;
      // scheduled_days: how many days FSRS had scheduled before this review
      // For a new card (never reviewed), this is 0
      final scheduledDays = row.lastReview != null
          ? (row.due - row.lastReview!) / (1000 * 60 * 60 * 24.0)
          : 0.0;

      // 5. INSERT review_log (INSERT-ONLY, sacred, never update/delete)
      await _logs.insertLog(
        cardStateId: row.id,
        wordId: wordId,
        rating: fsrsRating.value,
        reviewTimeUtc: now.millisecondsSinceEpoch,
        elapsedDays: elapsedDays,
        scheduledDays: scheduledDays,
        stateBefore: stateBefore,
        stabilityBefore: stabilityBefore,
        difficultyBefore: difficultyBefore,
        clientVersion: '0.0.1',
      );

      // 6. Compute reps/lapses (fsrs Card doesn't track these; we maintain them)
      int newReps = row.reps;
      int newLapses = row.lapses;
      if (rating == ReviewRating.again) {
        newLapses++;
        newReps = 0;
      } else {
        newReps++;
      }

      // 7. UPDATE card_states (user-scoped via repo).
      await _cards.updateByWordId(
        wordId,
        CardStatesCompanion(
          stability: Value(newCard.stability),
          difficulty: Value(newCard.difficulty),
          due: Value(newCard.due.millisecondsSinceEpoch),
          lastReview: Value(now.millisecondsSinceEpoch),
          state: Value(newCard.state.value),
          step: Value(newCard.step),
          reps: Value(newReps),
          lapses: Value(newLapses),
        ),
      );

      // 8. Return updated state
      return CardStateData(
        id: row.id,
        wordId: wordId,
        stability: newCard.stability,
        difficulty: newCard.difficulty,
        dueUtc: newCard.due,
        lastReviewUtc: now,
        state: newCard.state.value,
        step: newCard.step,
        reps: newReps,
        lapses: newLapses,
        createdAtUtc:
            DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
      );
    });
  }

  /// List all cards due for review at or before [nowLocal] (this user only).
  ///
  /// Converts nowLocal to UTC internally. Results ordered by due ASC
  /// (most overdue first).
  Future<List<CardStateData>> listDueCards({
    required DateTime nowLocal,
    int? limit,
  }) async {
    final nowUtcMs = nowLocal.toUtc().millisecondsSinceEpoch;
    final rows = await _cards.listDueAtOrBefore(dueMs: nowUtcMs, limit: limit);
    return rows.map(_rowToCardStateData).toList();
  }

  /// Count how many new cards were introduced today (this user only).
  ///
  /// "Today" is the calendar day of [nowLocal] (00:00 ~ 23:59:59 local).
  Future<int> countNewCardsToday({required DateTime nowLocal}) async {
    final todayStart = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    return _cards.countCreatedBetween(
      startMs: todayStart.toUtc().millisecondsSinceEpoch,
      endMs: todayEnd.toUtc().millisecondsSinceEpoch,
    );
  }

  /// Count distinct words this user reviewed today (from local review_logs).
  ///
  /// "Today" is the calendar day of [nowLocal] (00:00 ~ 23:59:59 local).
  /// Used as offline fallback for todayReviewCompleted.
  Future<int> countTodayReviewCompleted({DateTime? nowLocal}) async {
    final now = nowLocal ?? DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _logs
        .countDistinctWordsAfter(todayStart.toUtc().millisecondsSinceEpoch);
  }

  /// Preview scheduling for all 4 ratings without persisting.
  ///
  /// Returns a map of rating → duration until next review.
  /// Used by UI to show "下次：X 天后" below each button.
  Future<Map<ReviewRating, Duration>> previewSchedule(String wordId,
      {DateTime? nowUtc}) async {
    final now = nowUtc ?? DateTime.now().toUtc();

    final row = await _cards.findByWordId(wordId);
    if (row == null) {
      throw StateError(
        '[FsrsService] previewSchedule: no card_state for $wordId',
      );
    }

    final card = _rowToFsrsCard(row);
    final result = <ReviewRating, Duration>{};

    for (final rating in ReviewRating.values) {
      final preview =
          _scheduler.reviewCard(card, _toFsrsRating(rating), reviewDateTime: now);
      result[rating] = preview.card.due.difference(now);
    }

    return result;
  }

  /// Export all review_logs as JSONL (one JSON object per line).
  /// For feeding into fsrs-optimizer. Only this user's rows.
  Future<String> exportReviewLogsAsJsonl() async {
    final rows = await _logs.listAllByTimeAsc();
    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.writeln(jsonEncode({
        'card_state_id': row.cardStateId,
        'word_id': row.wordId,
        'rating': row.rating,
        'review_time_utc': row.reviewTimeUtc,
        'elapsed_days': row.elapsedDays,
        'scheduled_days': row.scheduledDays,
        'state_before': row.stateBefore,
        'stability_before': row.stabilityBefore,
        'difficulty_before': row.difficultyBefore,
        'client_version': row.clientVersion,
      }));
    }
    return buffer.toString();
  }

  /// Update desired_retention at runtime.
  /// Rebuilds the internal Scheduler with the new value.
  void updateDesiredRetention(double value) {
    _scheduler = fsrs.Scheduler(
      desiredRetention: value,
      learningSteps: const [Duration(minutes: 1), Duration(minutes: 10)],
      relearningSteps: const [Duration(minutes: 10)],
    );
  }

  // ==================== Internal conversions ====================

  /// Convert a drift CardState row to a fsrs Card.
  fsrs.Card _rowToFsrsCard(CardState row) {
    return fsrs.Card(
      cardId: row.id,
      stability: row.stability,
      difficulty: row.difficulty,
      due: DateTime.fromMillisecondsSinceEpoch(row.due, isUtc: true),
      lastReview: row.lastReview != null
          ? DateTime.fromMillisecondsSinceEpoch(row.lastReview!, isUtc: true)
          : null,
      state: fsrs.State.fromValue(row.state),
      step: row.step,
    );
  }

  /// Convert project ReviewRating to fsrs Rating.
  fsrs.Rating _toFsrsRating(ReviewRating r) {
    switch (r) {
      case ReviewRating.again:
        return fsrs.Rating.again;
      case ReviewRating.hard:
        return fsrs.Rating.hard;
      case ReviewRating.good:
        return fsrs.Rating.good;
      case ReviewRating.easy:
        return fsrs.Rating.easy;
    }
  }

  /// Convert a drift CardState row to CardStateData DTO.
  CardStateData _rowToCardStateData(CardState row) {
    return CardStateData(
      id: row.id,
      wordId: row.wordId,
      stability: row.stability,
      difficulty: row.difficulty,
      dueUtc: DateTime.fromMillisecondsSinceEpoch(row.due, isUtc: true),
      lastReviewUtc: row.lastReview != null
          ? DateTime.fromMillisecondsSinceEpoch(row.lastReview!, isUtc: true)
          : null,
      state: row.state,
      step: row.step,
      reps: row.reps,
      lapses: row.lapses,
      createdAtUtc:
          DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    );
  }
}
