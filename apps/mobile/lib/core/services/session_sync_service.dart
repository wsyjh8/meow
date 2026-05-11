import 'package:drift/drift.dart';

import '../api/api_client.dart';
import '../storage/drift/app_database.dart';
import '../storage/repositories/session_repository.dart';

/// Need #8 — Drains pending local sessions to the cloud.
///
/// synced semantics on the [Sessions] table:
///   0 = local only, server has not seen the start
///   1 = server confirmed start; finish not yet uploaded
///   2 = server confirmed finish; cached_validation_status reflects cloud
///
/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.4): user-scoped via
/// [SessionRepository]. The drain only sees the bound user's pending
/// sessions, so a stale unsynced row from a previous user never gets
/// pushed under the current user's token.
class SessionSyncService {
  SessionSyncService({
    required ApiClient apiClient,
    required SessionRepository repository,
  })  : _apiClient = apiClient,
        _repo = repository;

  /// Convenience constructor when the caller has a userId but no repo.
  factory SessionSyncService.forUser({
    required ApiClient apiClient,
    required AppDatabase driftDb,
    required String userId,
  }) {
    return SessionSyncService(
      apiClient: apiClient,
      repository: SessionRepository(db: driftDb, userId: userId),
    );
  }

  final ApiClient _apiClient;
  final SessionRepository _repo;

  /// Try to push every unfinished-on-cloud session forward.
  /// Returns the number of session row updates that succeeded.
  Future<int> drainPending() async {
    final pending = await _repo.listUnsynced();

    var pushed = 0;
    for (final row in pending) {
      try {
        if (row.synced == 0) {
          await _apiClient.startSession(
            sessionId: row.id,
            sessionMinutesTarget: row.sessionMinutesTarget,
            idempotencyKey: 'sess-start-${row.id}',
          );
          await _repo.updateById(
            row.id,
            const SessionsCompanion(synced: Value(1)),
          );
        }

        if (row.endedAt != null) {
          final info = await _apiClient.finishSession(
            sessionId: row.id,
            idempotencyKey: 'sess-finish-${row.id}',
          );
          await _repo.updateById(
            row.id,
            SessionsCompanion(
              synced: const Value(2),
              cachedValidationStatus: Value(info.sessionValidationStatus),
            ),
          );
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
