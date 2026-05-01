import 'package:drift/drift.dart';

import '../api/api_client.dart';
import '../storage/drift/app_database.dart';

/// Need #8 — Drains pending local sessions to the cloud.
///
/// synced semantics on the [Sessions] table:
///   0 = local only, server has not seen the start
///   1 = server confirmed start; finish not yet uploaded
///   2 = server confirmed finish; cached_validation_status reflects cloud
class SessionSyncService {
  SessionSyncService({required ApiClient apiClient, AppDatabase? driftDb})
      : _apiClient = apiClient,
        _db = driftDb ?? AppDatabase();

  final ApiClient _apiClient;
  final AppDatabase _db;

  /// Try to push every unfinished-on-cloud session forward.
  /// Returns the number of session row updates that succeeded.
  Future<int> drainPending() async {
    final pending = await (_db.select(_db.sessions)
          ..where((t) => t.synced.isSmallerThanValue(2)))
        .get();

    var pushed = 0;
    for (final row in pending) {
      try {
        if (row.synced == 0) {
          await _apiClient.startSession(
            sessionId: row.id,
            sessionMinutesTarget: row.sessionMinutesTarget,
            idempotencyKey: 'sess-start-${row.id}',
          );
          await (_db.update(_db.sessions)..where((t) => t.id.equals(row.id)))
              .write(const SessionsCompanion(synced: Value(1)));
        }

        if (row.endedAt != null) {
          final info = await _apiClient.finishSession(
            sessionId: row.id,
            idempotencyKey: 'sess-finish-${row.id}',
          );
          await (_db.update(_db.sessions)..where((t) => t.id.equals(row.id)))
              .write(SessionsCompanion(
            synced: const Value(2),
            cachedValidationStatus: Value(info.sessionValidationStatus),
          ));
          pushed++;
        }
      } catch (_) {
        // Stop draining on first failure — try again next time.
        break;
      }
    }
    return pushed;
  }
}
