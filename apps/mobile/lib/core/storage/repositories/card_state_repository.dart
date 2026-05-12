/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.4): per-user repository for
/// the `card_states` drift table.
///
/// All public methods automatically constrain queries to the bound
/// [userId]. Construct one repository per (database, user) pair —
/// `FsrsService` instantiates one in its constructor; tests inject a
/// fixture user. Two repositories with different users on the same
/// `AppDatabase` are safe because every query carries
/// `WHERE user_id = ?`.
///
/// This is **not** an exhaustive API — it covers exactly what FsrsService
/// and StatsService need today. Adding a new query? Wrap it here rather
/// than dropping a raw `customSelect` into the consuming service: the
/// partition guarantee only holds if every reader/writer goes through a
/// userId-aware repository.
library;

import 'package:drift/drift.dart';

import '../drift/app_database.dart';

class CardStateRepository {
  final AppDatabase _db;
  final String userId;

  CardStateRepository({required AppDatabase db, required this.userId})
      : _db = db;

  /// Look up this user's card by [wordId]. Null if not yet studied.
  Future<CardState?> findByWordId(String wordId) {
    return (_db.select(_db.cardStates)
          ..where((t) => t.userId.equals(userId) & t.wordId.equals(wordId)))
        .getSingleOrNull();
  }

  /// Insert a new card scoped to this user. Returns the new row id.
  Future<int> insertCard({
    required String wordId,
    double? stability,
    double? difficulty,
    required int dueMs,
    int? lastReviewMs,
    int state = 1,
    int? step,
    int reps = 0,
    int lapses = 0,
    required int createdAtMs,
  }) {
    return _db.into(_db.cardStates).insert(
          CardStatesCompanion.insert(
            userId: userId,
            wordId: wordId,
            stability: Value(stability),
            difficulty: Value(difficulty),
            due: dueMs,
            lastReview: Value(lastReviewMs),
            state: Value(state),
            step: Value(step),
            reps: Value(reps),
            lapses: Value(lapses),
            createdAt: createdAtMs,
          ),
        );
  }

  /// Update this user's card identified by [wordId]. Returns rows affected.
  ///
  /// The WHERE explicitly carries both `user_id` and `word_id`; the
  /// composite UNIQUE on `(user_id, word_id)` means at most 1 row matches.
  Future<int> updateByWordId(
    String wordId,
    CardStatesCompanion updates,
  ) {
    return (_db.update(_db.cardStates)
          ..where((t) => t.userId.equals(userId) & t.wordId.equals(wordId)))
        .write(updates);
  }

  /// All of this user's cards due at or before [dueMs], ordered by due ASC.
  Future<List<CardState>> listDueAtOrBefore({
    required int dueMs,
    int? limit,
  }) async {
    final query = _db.select(_db.cardStates)
      ..where((t) =>
          t.userId.equals(userId) & t.due.isSmallerOrEqualValue(dueMs))
      ..orderBy([(t) => OrderingTerm.asc(t.due)]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  /// Count this user's cards whose `created_at` falls in [startMs, endMs).
  Future<int> countCreatedBetween({
    required int startMs,
    required int endMs,
  }) async {
    final result = await _db.customSelect(
      'SELECT COUNT(*) AS cnt FROM card_states '
      'WHERE user_id = ? AND created_at >= ? AND created_at < ?',
      variables: [
        Variable.withString(userId),
        Variable.withInt(startMs),
        Variable.withInt(endMs),
      ],
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// Count this user's cards currently due (`due <= nowMs`).
  Future<int> countDueAtOrBefore(int nowMs) async {
    final result = await _db.customSelect(
      'SELECT COUNT(*) AS cnt FROM card_states '
      'WHERE user_id = ? AND due <= ?',
      variables: [Variable.withString(userId), Variable.withInt(nowMs)],
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// Count this user's cards with `stability >= threshold`.
  /// Used by stats badges (e.g. "记忆大师" / "memory master" at 1000).
  Future<int> countWithStabilityAtLeast(double threshold) async {
    final result = await _db.customSelect(
      'SELECT COUNT(*) AS cnt FROM card_states '
      'WHERE user_id = ? AND stability >= ?',
      variables: [
        Variable.withString(userId),
        Variable.withReal(threshold),
      ],
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// `(word_id, state, stability)` rows for this user — used by
  /// StatsService.getMasteryDistribution to bucket cards in memory.
  Future<List<MasteryRow>> listForMastery() async {
    final rows = await _db.customSelect(
      'SELECT word_id, state, stability FROM card_states WHERE user_id = ?',
      variables: [Variable.withString(userId)],
    ).get();
    return rows
        .map((r) => MasteryRow(
              wordId: r.read<String>('word_id'),
              state: r.read<int>('state'),
              stability: r.readNullable<double>('stability'),
            ))
        .toList();
  }

  /// Top `lapses > 0` cards for this user, sorted by lapses DESC then
  /// reps ASC. Used by StatsService.getTopStubbornWords.
  Future<List<StubbornRow>> listTopStubborn({int limit = 10}) async {
    final rows = await _db.customSelect(
      'SELECT word_id, lapses, reps FROM card_states '
      'WHERE user_id = ? AND lapses > 0 '
      'ORDER BY lapses DESC, reps ASC LIMIT ?',
      variables: [
        Variable.withString(userId),
        Variable.withInt(limit),
      ],
    ).get();
    return rows
        .map((r) => StubbornRow(
              wordId: r.read<String>('word_id'),
              lapses: r.read<int>('lapses'),
              reps: r.read<int>('reps'),
            ))
        .toList();
  }
}

/// Lightweight DTO for [CardStateRepository.listForMastery].
class MasteryRow {
  final String wordId;
  final int state;
  final double? stability;
  const MasteryRow({
    required this.wordId,
    required this.state,
    required this.stability,
  });
}

/// Lightweight DTO for [CardStateRepository.listTopStubborn].
class StubbornRow {
  final String wordId;
  final int lapses;
  final int reps;
  const StubbornRow({
    required this.wordId,
    required this.lapses,
    required this.reps,
  });
}
