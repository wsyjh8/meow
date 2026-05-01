import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/api/api_client.dart';
import 'package:meow_mobile/core/services/session_store.dart';
import 'package:meow_mobile/core/services/session_sync_service.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient();

  final List<({String? sessionId, int minutesTarget})> startCalls = [];
  final List<({String sessionId})> finishCalls = [];

  bool throwOnStart = false;
  bool throwOnFinish = false;
  String validationStatusToReturn = 'invalid';

  @override
  Future<SessionInfo> startSession({
    int sessionMinutesTarget = 15,
    String? idempotencyKey,
    String? sessionId,
  }) async {
    if (throwOnStart) throw Exception('offline');
    startCalls.add((sessionId: sessionId, minutesTarget: sessionMinutesTarget));
    return SessionInfo(
      sessionId: sessionId ?? 'server-generated',
      sessionStatus: 'started',
      sessionValidationStatus: 'pending',
      sessionMinutesTarget: sessionMinutesTarget,
      startedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  @override
  Future<SessionInfo> finishSession({
    required String sessionId,
    String? idempotencyKey,
  }) async {
    if (throwOnFinish) throw Exception('offline');
    finishCalls.add((sessionId: sessionId));
    return SessionInfo(
      sessionId: sessionId,
      sessionStatus: validationStatusToReturn,
      sessionValidationStatus: validationStatusToReturn,
      sessionMinutesTarget: 15,
      startedAt: DateTime.now().toUtc().toIso8601String(),
      endedAt: DateTime.now().toUtc().toIso8601String(),
      durationSeconds: 1,
    );
  }

  @override
  void dispose() {}
}

void main() {
  group('SessionStore', () {
    late AppDatabase db;
    late _RecordingApiClient api;
    late SessionStore store;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      api = _RecordingApiClient();
      store = SessionStore(apiClient: api, driftDb: db);
    });

    tearDown(() async {
      await db.close();
    });

    test('startForStudy inserts a row with locally-generated id and posts to api', () async {
      final id = await store.startForStudy();

      expect(id.length, greaterThan(8));
      expect(store.activeSessionId, id);

      final rows = await db.select(db.sessions).get();
      expect(rows.length, 1);
      expect(rows.first.id, id);
      expect(rows.first.kind, 'study');
      expect(rows.first.endedAt, isNull);

      // Drain start side-effect.
      await Future<void>.delayed(Duration.zero);
      expect(api.startCalls.length, 1);
      expect(api.startCalls.first.sessionId, id);
    });

    test('finish writes ended_at + duration_seconds + caches cloud verdict', () async {
      final id = await store.startForStudy();
      await Future<void>.delayed(Duration.zero); // let post run

      api.validationStatusToReturn = 'invalid';
      await store.finish();
      // wait for post-finish to settle
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final row =
          await (db.select(db.sessions)..where((t) => t.id.equals(id))).getSingle();
      expect(row.endedAt, isNotNull);
      expect(row.durationSeconds, isNotNull);
      expect(row.cachedValidationStatus, 'invalid');
      expect(row.synced, 2);
      expect(api.finishCalls.length, 1);
      expect(api.finishCalls.first.sessionId, id);
    });

    test('offline start leaves synced=0; sync service drains it later', () async {
      api.throwOnStart = true;
      final id = await store.startForStudy();
      await Future<void>.delayed(Duration.zero);

      var row =
          await (db.select(db.sessions)..where((t) => t.id.equals(id))).getSingle();
      expect(row.synced, 0);
      expect(row.cachedValidationStatus, isNull);

      // Recover network and drain.
      api.throwOnStart = false;
      final sync = SessionSyncService(apiClient: api, driftDb: db);
      await sync.drainPending();

      row =
          await (db.select(db.sessions)..where((t) => t.id.equals(id))).getSingle();
      expect(row.synced, 1);
    });

    test('starting a new session when one is active finishes the old one first', () async {
      final first = await store.startForStudy();
      await Future<void>.delayed(Duration.zero);

      final second = await store.startForReview();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(second, isNot(equals(first)));
      final firstRow = await (db.select(db.sessions)..where((t) => t.id.equals(first))).getSingle();
      expect(firstRow.endedAt, isNotNull, reason: 'old session must be closed');

      final secondRow = await (db.select(db.sessions)..where((t) => t.id.equals(second))).getSingle();
      expect(secondRow.kind, 'review');
      expect(secondRow.endedAt, isNull);
    });

    test('cached_validation_status is never written before finish', () async {
      final id = await store.startForStudy();
      await Future<void>.delayed(Duration.zero);
      final row = await (db.select(db.sessions)..where((t) => t.id.equals(id))).getSingle();
      expect(row.cachedValidationStatus, isNull,
          reason: 'local must never invent a validation status');
    });
  });
}
