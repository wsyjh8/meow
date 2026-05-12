/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.4): per-user repository for
/// the `daily_checkins` drift table.
///
/// v13 widened the UNIQUE constraint from `date` alone to
/// `(user_id, date)`, so two users on the same device can both check
/// in on the same calendar day. This repository encapsulates the
/// `user_id` clause every reader needs.
library;

import 'package:drift/drift.dart';

import '../drift/app_database.dart';

class DailyCheckinRepository {
  final AppDatabase _db;
  final String userId;

  DailyCheckinRepository({required AppDatabase db, required this.userId})
      : _db = db;

  /// Insert a check-in for this user on [date]. Returns the new row id.
  /// Caller MUST first verify no row exists (UNIQUE(user_id, date)
  /// guards against double insert at SQLite level, but throwing on
  /// conflict is uglier than the explicit lookup).
  Future<int> insertCheckin({
    required String date,
    int checkedIn = 1,
    required String createdAt,
  }) {
    return _db.into(_db.dailyCheckins).insert(
          DailyCheckinsCompanion.insert(
            userId: userId,
            date: date,
            checkedIn: Value(checkedIn),
            createdAt: createdAt,
          ),
        );
  }

  /// Find this user's check-in for [date]. Null if missing.
  Future<DailyCheckin?> findByDate(String date) {
    return (_db.select(_db.dailyCheckins)
          ..where((t) => t.userId.equals(userId) & t.date.equals(date)))
        .getSingleOrNull();
  }

  /// All of this user's check-ins ordered by date DESC.
  /// Used by streak computation: scan backwards from today/yesterday,
  /// stop at first gap.
  Future<List<DailyCheckin>> listByDateDesc() {
    return (_db.select(_db.dailyCheckins)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Stats only needs the date strings; pull them straight to avoid
  /// materializing full rows.
  Future<List<String>> listDatesDesc() async {
    final rows = await (_db.select(_db.dailyCheckins)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return rows.map((r) => r.date).toList();
  }
}
