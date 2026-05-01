import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
import '../storage/drift/app_database.dart';

/// Need #8 — Local-first Session lifecycle.
///
/// Architecture invariant: this store NEVER computes or writes
/// session_validation_status. It mirrors the cloud's verdict into
/// `cached_validation_status` after `finishSession` succeeds, and only the
/// sync path may write that column. Code paths that show valid/invalid
/// must read either the latest cloud GET or this cached column — never
/// derive from local timing or attempt counts.
///
/// Session id is generated locally as UUID v4 and reused as the server
/// session id, so offline-then-online replay needs no id mapping and
/// attempts already carry the same session_id all the way through.
class SessionStore {
  SessionStore({required ApiClient apiClient, AppDatabase? driftDb})
      : _apiClient = apiClient,
        _db = driftDb ?? AppDatabase();

  final ApiClient _apiClient;
  final AppDatabase _db;
  static const _uuid = Uuid();
  static const _defaultMinutesTarget = 15;

  String? _activeSessionId;
  String? get activeSessionId => _activeSessionId;

  /// Status for this attempt: 0 = not yet started/posted, 1 = start
  /// confirmed by server, 2 = finish confirmed by server.

  Future<String> startForStudy() => _start('study');
  Future<String> startForReview() => _start('review');

  Future<String> _start(String kind) async {
    // If a session is already active locally (e.g. user navigated review→study
    // without going through dispose), close it first so each page gets its
    // own session per Need #8.
    if (_activeSessionId != null) {
      await finish();
    }

    final id = _uuid.v4();
    final startedAt = DateTime.now().toUtc().toIso8601String();
    await _db.into(_db.sessions).insert(
          SessionsCompanion.insert(
            id: id,
            kind: kind,
            startedAt: startedAt,
            sessionMinutesTarget: const Value(_defaultMinutesTarget),
          ),
        );
    _activeSessionId = id;

    // Fire-and-forget upload of the start.
    unawaited(_postStart(id));
    return id;
  }

  Future<void> _postStart(String sessionId) async {
    try {
      await _apiClient.startSession(
        sessionId: sessionId,
        sessionMinutesTarget: _defaultMinutesTarget,
        idempotencyKey: 'sess-start-$sessionId',
      );
      await (_db.update(_db.sessions)..where((t) => t.id.equals(sessionId)))
          .write(const SessionsCompanion(synced: Value(1)));
    } catch (_) {
      // Stay synced=0; SessionSyncService will retry.
    }
  }

  Future<void> finish() async {
    final id = _activeSessionId;
    if (id == null) return;
    _activeSessionId = null;

    final row = await (_db.select(_db.sessions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    if (row.endedAt != null) return; // already finished locally

    final now = DateTime.now().toUtc();
    final startedAtMs = DateTime.parse(row.startedAt).millisecondsSinceEpoch;
    final durationSeconds =
        ((now.millisecondsSinceEpoch - startedAtMs) / 1000).round();

    await (_db.update(_db.sessions)..where((t) => t.id.equals(id))).write(
      SessionsCompanion(
        endedAt: Value(now.toIso8601String()),
        durationSeconds: Value(durationSeconds < 0 ? 0 : durationSeconds),
      ),
    );

    unawaited(_postFinish(id));
  }

  Future<void> _postFinish(String sessionId) async {
    try {
      final info = await _apiClient.finishSession(
        sessionId: sessionId,
        idempotencyKey: 'sess-finish-$sessionId',
      );
      // Mirror the cloud's verdict into the local cache. This is the ONLY
      // place that writes cached_validation_status.
      await (_db.update(_db.sessions)..where((t) => t.id.equals(sessionId)))
          .write(SessionsCompanion(
        synced: const Value(2),
        cachedValidationStatus: Value(info.sessionValidationStatus),
      ));
    } catch (_) {
      // Leave at synced=1 (or 0 if start never confirmed) — the sync service
      // will retry. Never invent a validation status locally.
    }
  }

  /// Best-effort: refresh `cached_validation_status` from the cloud for one
  /// session. Used after sync runs, to pick up any post-finish validation
  /// transitions the server made independently.
  Future<void> refreshCachedValidation(String sessionId) async {
    try {
      final info = await _apiClient.getSession(sessionId);
      await (_db.update(_db.sessions)..where((t) => t.id.equals(sessionId)))
          .write(SessionsCompanion(
        cachedValidationStatus: Value(info.sessionValidationStatus),
      ));
    } catch (_) {
      // Silent — UI falls back to whatever cache already has.
    }
  }
}
