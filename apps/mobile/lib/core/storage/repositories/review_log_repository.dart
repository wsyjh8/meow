/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.4): per-user repository for
/// the `review_logs` drift table.
///
/// review_logs is INSERT-ONLY and feeds fsrs-optimizer training; every
/// query carries `WHERE user_id = ?` so one user's review stream can't
/// pollute another's optimizer output.
library;

import 'package:drift/drift.dart';

import '../drift/app_database.dart';

class ReviewLogRepository {
  final AppDatabase _db;
  final String userId;

  ReviewLogRepository({required AppDatabase db, required this.userId})
      : _db = db;

  /// Insert a review event for this user. Returns the new row id.
  Future<int> insertLog({
    required int cardStateId,
    required String wordId,
    required int rating,
    required int reviewTimeUtc,
    required double elapsedDays,
    required double scheduledDays,
    required int stateBefore,
    double? stabilityBefore,
    double? difficultyBefore,
    String? clientVersion,
  }) {
    return _db.into(_db.reviewLogs).insert(
          ReviewLogsCompanion.insert(
            userId: userId,
            cardStateId: cardStateId,
            wordId: wordId,
            rating: rating,
            reviewTimeUtc: reviewTimeUtc,
            elapsedDays: elapsedDays,
            scheduledDays: scheduledDays,
            stateBefore: stateBefore,
            stabilityBefore: Value(stabilityBefore),
            difficultyBefore: Value(difficultyBefore),
            clientVersion: Value(clientVersion),
          ),
        );
  }

  /// All of this user's review logs ordered by review_time_utc ASC.
  /// Used by FsrsService to export JSONL for the optimizer.
  Future<List<ReviewLog>> listAllByTimeAsc() {
    return (_db.select(_db.reviewLogs)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.asc(t.reviewTimeUtc)]))
        .get();
  }

  /// Count distinct words this user reviewed at or after [startMs].
  /// Used as offline fallback for `today_review_completed`.
  Future<int> countDistinctWordsAfter(int startMs) async {
    final result = await _db.customSelect(
      'SELECT COUNT(DISTINCT word_id) AS cnt FROM review_logs '
      'WHERE user_id = ? AND review_time_utc >= ?',
      variables: [Variable.withString(userId), Variable.withInt(startMs)],
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// Count this user's reviews in `[startMs, endMs)`.
  Future<int> countInRange({required int startMs, required int endMs}) async {
    final result = await _db.customSelect(
      'SELECT COUNT(*) AS cnt FROM review_logs '
      'WHERE user_id = ? AND review_time_utc >= ? AND review_time_utc < ?',
      variables: [
        Variable.withString(userId),
        Variable.withInt(startMs),
        Variable.withInt(endMs),
      ],
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// `(review_time_utc)` rows for this user since [startMs] — used by
  /// StatsService trend charts to bucket reviews by local day.
  Future<List<int>> listReviewTimesAfter(int startMs) async {
    final rows = await _db.customSelect(
      'SELECT review_time_utc FROM review_logs '
      'WHERE user_id = ? AND review_time_utc >= ?',
      variables: [Variable.withString(userId), Variable.withInt(startMs)],
    ).get();
    return rows.map((r) => r.read<int>('review_time_utc')).toList();
  }

  /// `(review_time_utc, rating)` rows for this user since [startMs] —
  /// used by StatsService accuracy/badges where rating matters.
  Future<List<TimedRating>> listTimedRatingsAfter(int startMs) async {
    final rows = await _db.customSelect(
      'SELECT review_time_utc, rating FROM review_logs '
      'WHERE user_id = ? AND review_time_utc >= ?',
      variables: [Variable.withString(userId), Variable.withInt(startMs)],
    ).get();
    return rows
        .map((r) => TimedRating(
              reviewTimeUtc: r.read<int>('review_time_utc'),
              rating: r.read<int>('rating'),
            ))
        .toList();
  }

  /// `(elapsed_days, rating)` rows for this user where elapsed_days > 0.
  /// Used by StatsService.getRetentionCurve.
  Future<List<RetentionRow>> listForRetentionCurve() async {
    final rows = await _db.customSelect(
      'SELECT elapsed_days, rating FROM review_logs '
      'WHERE user_id = ? AND elapsed_days > 0',
      variables: [Variable.withString(userId)],
    ).get();
    return rows
        .map((r) => RetentionRow(
              elapsedDays: r.read<double>('elapsed_days'),
              rating: r.read<int>('rating'),
            ))
        .toList();
  }
}

class TimedRating {
  final int reviewTimeUtc;
  final int rating;
  const TimedRating({required this.reviewTimeUtc, required this.rating});
}

class RetentionRow {
  final double elapsedDays;
  final int rating;
  const RetentionRow({required this.elapsedDays, required this.rating});
}
