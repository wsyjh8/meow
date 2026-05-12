import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/api/api_client.dart';
import 'package:meow_mobile/core/services/review_log_service.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient();

  bool throwOnHistory = false;
  List<WordReviewHistoryItem> historyToReturn = const [];

  @override
  Future<List<WordReviewHistoryItem>> getWordReviewHistory({
    required String wordId,
    int limit = 20,
  }) async {
    if (throwOnHistory) throw Exception('offline');
    return historyToReturn;
  }

  @override
  void dispose() {}
}

void main() {
  group('ReviewLogService', () {
    late AppDatabase db;
    late _RecordingApiClient api;
    late ReviewLogService service;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      api = _RecordingApiClient();
      service = ReviewLogService.forUser(
        apiClient: api,
        driftDb: db,
        userId: 'test-user',
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('recordLocal inserts a row with synced=0 by default', () async {
      final id = await service.recordLocal(
        wordId: 'w1',
        reviewGroupId: 'g1',
        actionResult: 'correct',
        sessionId: 'sess-1',
        rating: 3,
      );
      expect(id, greaterThan(0));
      final rows = await db.select(db.reviewRecords).get();
      expect(rows.length, 1);
      expect(rows.first.wordId, 'w1');
      expect(rows.first.synced, 0);
      expect(rows.first.rating, 3);
      expect(rows.first.sessionId, 'sess-1');
    });

    test('markSynced flips a row to synced=1', () async {
      final id = await service.recordLocal(
        wordId: 'w1',
        reviewGroupId: 'g1',
        actionResult: 'correct',
        rating: 3,
      );
      await service.markSynced(id);
      final row = await (db.select(db.reviewRecords)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.synced, 1);
    });

    test('same word same day: multiple rows are kept independently', () async {
      for (int i = 0; i < 3; i++) {
        await service.recordLocal(
          wordId: 'ability',
          reviewGroupId: 'g1',
          actionResult: i.isEven ? 'correct' : 'incorrect',
          rating: 3,
          // Force a tiny gap so created_at differs.
          reviewedAt: DateTime.utc(2026, 5, 1, 9, 12 + i),
        );
      }
      final rows = await service.getLocalForWord('ability');
      expect(rows.length, 3);
      // Newest first.
      expect(rows[0].createdAt.compareTo(rows[1].createdAt), greaterThanOrEqualTo(0));
      expect(rows[1].createdAt.compareTo(rows[2].createdAt), greaterThanOrEqualTo(0));
    });

    test('getPendingForWord excludes synced rows', () async {
      final pendingId = await service.recordLocal(
        wordId: 'w1', reviewGroupId: 'g1', actionResult: 'correct',
        reviewedAt: DateTime.utc(2026, 5, 1, 10, 0),
      );
      final syncedId = await service.recordLocal(
        wordId: 'w1', reviewGroupId: 'g1', actionResult: 'correct',
        reviewedAt: DateTime.utc(2026, 5, 1, 11, 0),
      );
      await service.markSynced(syncedId);

      final pending = await service.getPendingForWord('w1');
      expect(pending.length, 1);
      expect(pending.first.id, pendingId);
    });

    test('getCloudForWord delegates to ApiClient', () async {
      api.historyToReturn = [
        WordReviewHistoryItem(
          attemptId: 'ra-1',
          wordId: 'w1',
          reviewGroupId: 'g1',
          actionResult: 'correct',
          reviewedAt: '2026-05-01T09:12:00Z',
          sessionId: 'sess-1',
        ),
      ];
      final res = await service.getCloudForWord('w1');
      expect(res.length, 1);
      expect(res.first.attemptId, 'ra-1');
    });

    test('cloud history failure does not crash service', () async {
      api.throwOnHistory = true;
      expect(() => service.getCloudForWord('w1'), throwsException);
    });
  });
}
