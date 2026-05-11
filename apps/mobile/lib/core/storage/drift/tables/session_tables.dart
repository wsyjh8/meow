/// Session + ReviewRecords table definitions (drift schema v5).
///
/// Local raw fact for Need #8. session_validation_status is NEVER computed
/// locally — `cached_validation_status` only mirrors what the cloud returned.
///
/// v13 (need 23 Phase C PR-C-α): both tables gain `user_id` for partition
/// (plan-023-C-v2 §4.2). UNIQUE not changed — sessions.id is uuid and
/// review_records.id is autoincrement, both already user-unique.
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_sessions_user', columns: {#userId})
class Sessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get kind => text()();
  TextColumn get startedAt => text().named('started_at')();
  TextColumn get endedAt => text().named('ended_at').nullable()();
  IntColumn get durationSeconds =>
      integer().named('duration_seconds').nullable()();
  IntColumn get sessionMinutesTarget =>
      integer().named('session_minutes_target').withDefault(const Constant(15))();
  TextColumn get cachedValidationStatus =>
      text().named('cached_validation_status').nullable()();
  IntColumn get synced => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_review_records_user', columns: {#userId})
class ReviewRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get reviewGroupId => text().named('review_group_id')();
  TextColumn get wordId => text().named('word_id')();
  TextColumn get actionResult => text().named('action_result')();
  TextColumn get sessionId => text().named('session_id').nullable()();
  TextColumn get createdAt => text().named('created_at')();
  IntColumn get synced => integer().withDefault(const Constant(0))();
  // Need #10 — Optional FSRS rating (1=again 2=hard 3=good 4=easy).
  // Nullable because legacy attempts and the local-batch path may not carry it.
  IntColumn get rating => integer().nullable()();
}
