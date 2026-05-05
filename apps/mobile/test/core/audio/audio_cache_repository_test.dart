// Unit tests for AudioCacheRepository (DB v0.3.0 §7.4.1).
//
// Covers the two eviction triggers + the simple read/write helpers:
//   - Trigger 1: capacity + LRU (evictByCapacity)
//   - Trigger 2: content_version orphan (evictByContentVersion)
//   - Read/write basics: findByAudioId / touchPlayedAt / deleteEntry /
//     totalCachedBytes / clearAll
//
// Constraints honored:
//   - In-memory drift DB (NativeDatabase.memory()) — no path_provider /
//     flutter binding required.
//   - Real filesystem usage is scoped to a per-test temp dir so the eviction
//     code's `File(...).delete()` path runs end-to-end without polluting
//     the dev environment.
//   - We do NOT exercise downloadAndCache here — that path needs HTTP
//     mocking + path_provider and is better tested at the integration level.
//
// What we deliberately don't assert (out of scope for unit-test layer):
//   - SHA-256 verification (DB §7.4.1 forbids client recompute; the repo
//     only does field-level matching).
//   - URL rewrite or audio_assets joining (those live elsewhere).

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/audio/audio_cache_repository.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

void main() {
  group('AudioCacheRepository', () {
    late AppDatabase db;
    late AudioCacheRepository repo;
    late Directory tmpDir;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = AudioCacheRepository(db: db);
      tmpDir = await Directory.systemTemp.createTemp('audio_cache_test_');
    });

    tearDown(() async {
      await db.close();
      try {
        if (await tmpDir.exists()) {
          await tmpDir.delete(recursive: true);
        }
      } catch (_) {/* OS may hold a handle briefly; ignore */}
    });

    /// Seeds one audio_file_cache row + optionally creates a backing file.
    /// Returns the absolute file path so tests can assert on it.
    Future<String> seedRow({
      required String audioId,
      required int bytes,
      int? lastPlayedAt,
      int? cachedAt,
      String? contentVersion,
      String? checksum,
      bool createFile = true,
    }) async {
      final filePath = '${tmpDir.path}/$audioId.mp3';
      if (createFile) {
        // Write `bytes`-many zero bytes — content doesn't matter, only size.
        await File(filePath).writeAsBytes(List<int>.filled(bytes, 0));
      }
      await db.into(db.audioFileCache).insert(
            AudioFileCacheCompanion.insert(
              audioId: audioId,
              localPath: filePath,
              bytes: bytes,
              cachedAt:
                  cachedAt ?? DateTime.now().toUtc().millisecondsSinceEpoch,
              lastPlayedAt: Value(lastPlayedAt),
              cachedChecksum: Value(checksum),
              cachedContentVersion: Value(contentVersion),
            ),
          );
      return filePath;
    }

    Future<int> rowCount() async =>
        (await db.select(db.audioFileCache).get()).length;

    // ── Lookup / touch / delete ─────────────────────────────────────────────

    group('findByAudioId', () {
      test('returns null when audio_id absent', () async {
        expect(await repo.findByAudioId('does-not-exist'), isNull);
      });

      test('returns the row when present', () async {
        await seedRow(audioId: 'abc123', bytes: 100);
        final row = await repo.findByAudioId('abc123');
        expect(row, isNotNull);
        expect(row!.audioId, 'abc123');
        expect(row.bytes, 100);
      });
    });

    group('touchPlayedAt', () {
      test('updates last_played_at to now', () async {
        await seedRow(audioId: 'abc', bytes: 10, lastPlayedAt: 1000);

        final before = DateTime.now().toUtc().millisecondsSinceEpoch;
        await repo.touchPlayedAt('abc');
        final after = DateTime.now().toUtc().millisecondsSinceEpoch;

        final row = await repo.findByAudioId('abc');
        expect(row, isNotNull);
        expect(row!.lastPlayedAt, isNotNull);
        expect(row.lastPlayedAt!, greaterThanOrEqualTo(before));
        expect(row.lastPlayedAt!, lessThanOrEqualTo(after));
      });

      test('is a no-op for missing audio_id (does not throw)', () async {
        // Should silently no-op; PG-style UPDATE matches 0 rows.
        await repo.touchPlayedAt('missing');
        expect(await rowCount(), 0);
      });
    });

    group('deleteEntry', () {
      test('removes the row but does not touch the file', () async {
        final path = await seedRow(audioId: 'abc', bytes: 10);

        await repo.deleteEntry('abc');

        expect(await repo.findByAudioId('abc'), isNull);
        // deleteEntry is row-only by design; capacity / orphan paths handle
        // the file separately. This pins the contract.
        expect(await File(path).exists(), isTrue);
      });
    });

    // ── Aggregates ──────────────────────────────────────────────────────────

    group('totalCachedBytes', () {
      test('returns 0 when empty', () async {
        expect(await repo.totalCachedBytes(), 0);
      });

      test('sums bytes across all rows', () async {
        await seedRow(audioId: 'a', bytes: 100);
        await seedRow(audioId: 'b', bytes: 250);
        await seedRow(audioId: 'c', bytes: 50);
        expect(await repo.totalCachedBytes(), 400);
      });
    });

    group('clearAll', () {
      test('deletes all rows + files', () async {
        final p1 = await seedRow(audioId: 'a', bytes: 10);
        final p2 = await seedRow(audioId: 'b', bytes: 20);

        await repo.clearAll();

        expect(await rowCount(), 0);
        expect(await File(p1).exists(), isFalse);
        expect(await File(p2).exists(), isFalse);
      });

      test('survives a missing backing file', () async {
        await seedRow(audioId: 'a', bytes: 10, createFile: false);
        // Should not throw even though the file path doesn't resolve.
        await repo.clearAll();
        expect(await rowCount(), 0);
      });
    });

    // ── Trigger 1: capacity + LRU ───────────────────────────────────────────

    group('evictByCapacity (trigger 1: LRU)', () {
      test('returns 0 (no eviction) when total ≤ cap', () async {
        await seedRow(audioId: 'a', bytes: 30, lastPlayedAt: 100);
        await seedRow(audioId: 'b', bytes: 30, lastPlayedAt: 200);

        final evicted = await repo.evictByCapacity(capacityBytes: 100);
        expect(evicted, 0);
        expect(await rowCount(), 2);
      });

      test('evicts oldest-played first until total ≤ cap × 0.8', () async {
        // cap=100, target=80. Five 30-byte rows (total 150).
        // Eviction order by lastPlayedAt ASC: a → b → c → d → e.
        // After evicting a (120), b (90), c (60) → 60 ≤ 80, stop.
        // So we expect 3 evicted, rows {d, e} remaining.
        final pa = await seedRow(audioId: 'a', bytes: 30, lastPlayedAt: 100);
        final pb = await seedRow(audioId: 'b', bytes: 30, lastPlayedAt: 200);
        final pc = await seedRow(audioId: 'c', bytes: 30, lastPlayedAt: 300);
        final pd = await seedRow(audioId: 'd', bytes: 30, lastPlayedAt: 400);
        final pe = await seedRow(audioId: 'e', bytes: 30, lastPlayedAt: 500);

        final evicted = await repo.evictByCapacity(capacityBytes: 100);

        expect(evicted, 3);
        expect(await rowCount(), 2);
        expect(await repo.findByAudioId('a'), isNull);
        expect(await repo.findByAudioId('b'), isNull);
        expect(await repo.findByAudioId('c'), isNull);
        expect(await repo.findByAudioId('d'), isNotNull);
        expect(await repo.findByAudioId('e'), isNotNull);

        // Files of evicted rows are removed.
        expect(await File(pa).exists(), isFalse);
        expect(await File(pb).exists(), isFalse);
        expect(await File(pc).exists(), isFalse);
        // Surviving files still on disk.
        expect(await File(pd).exists(), isTrue);
        expect(await File(pe).exists(), isTrue);

        // Final total = 60 bytes ≤ 80 (target).
        expect(await repo.totalCachedBytes(), 60);
      });

      test('evicts NULL last_played_at rows before played rows', () async {
        // cap=100, target=80. Three rows; one never played (LP=NULL),
        // two played. Total 150. ORDER BY (last_played_at IS NULL) DESC,
        // last_played_at ASC: NULL row first, then LP=100, then LP=200.
        // After evicting NULL row (-50 → 100) → over target, evict next
        // (LP=100, -50 → 50) → ≤ 80, stop. So 2 evicted.
        await seedRow(
            audioId: 'never', bytes: 50, lastPlayedAt: null, cachedAt: 1);
        await seedRow(audioId: 'old', bytes: 50, lastPlayedAt: 100);
        await seedRow(audioId: 'new', bytes: 50, lastPlayedAt: 200);

        final evicted = await repo.evictByCapacity(capacityBytes: 100);

        expect(evicted, 2);
        expect(await repo.findByAudioId('never'), isNull);
        expect(await repo.findByAudioId('old'), isNull);
        expect(await repo.findByAudioId('new'), isNotNull);
      });

      test('tie-breaks equal last_played_at by cached_at ASC', () async {
        // Three rows all played at same time. cached_at differs.
        // Eviction should evict the earliest cached_at first.
        await seedRow(
            audioId: 'first', bytes: 40, lastPlayedAt: 500, cachedAt: 100);
        await seedRow(
            audioId: 'mid', bytes: 40, lastPlayedAt: 500, cachedAt: 200);
        await seedRow(
            audioId: 'last', bytes: 40, lastPlayedAt: 500, cachedAt: 300);

        // cap=100, target=80. Total=120. Evict 'first' (-40 → 80) → at target.
        final evicted = await repo.evictByCapacity(capacityBytes: 100);

        expect(evicted, 1);
        expect(await repo.findByAudioId('first'), isNull);
        expect(await repo.findByAudioId('mid'), isNotNull);
        expect(await repo.findByAudioId('last'), isNotNull);
      });

      test('does not crash if a backing file is already gone', () async {
        // Row exists but file doesn't — simulates user-side fs cleanup or
        // a partial-state crash. Eviction should still succeed.
        await seedRow(
            audioId: 'orphan',
            bytes: 60,
            lastPlayedAt: 100,
            createFile: false);
        await seedRow(audioId: 'normal', bytes: 60, lastPlayedAt: 200);

        // cap=80, target=64. Total=120. Evict orphan (-60 → 60) → at target.
        final evicted = await repo.evictByCapacity(capacityBytes: 80);

        expect(evicted, 1);
        expect(await repo.findByAudioId('orphan'), isNull);
        expect(await repo.findByAudioId('normal'), isNotNull);
      });
    });

    // ── Trigger 2: content_version orphan ───────────────────────────────────

    group('evictByContentVersion (trigger 2: orphan)', () {
      test('returns 0 (no-op) when active set is empty', () async {
        // Defensive guard: empty active set MUST NOT wipe the cache.
        // Without this short-circuit, every row would be evicted, which
        // would happen e.g. if a manifest fetch glitched and returned [].
        await seedRow(
            audioId: 'a', bytes: 10, contentVersion: 'v1');
        await seedRow(
            audioId: 'b', bytes: 10, contentVersion: 'v2');

        final evicted = await repo.evictByContentVersion(<String>{});

        expect(evicted, 0);
        expect(await rowCount(), 2);
      });

      test('keeps rows whose version is in the active set', () async {
        await seedRow(audioId: 'live', bytes: 10, contentVersion: 'v1');

        final evicted = await repo.evictByContentVersion({'v1'});

        expect(evicted, 0);
        expect(await repo.findByAudioId('live'), isNotNull);
      });

      test('evicts rows whose version is not in the active set', () async {
        final pStale = await seedRow(
            audioId: 'stale', bytes: 10, contentVersion: 'v1');
        final pCurrent = await seedRow(
            audioId: 'current', bytes: 10, contentVersion: 'v2');

        final evicted = await repo.evictByContentVersion({'v2'});

        expect(evicted, 1);
        expect(await repo.findByAudioId('stale'), isNull);
        expect(await repo.findByAudioId('current'), isNotNull);
        expect(await File(pStale).exists(), isFalse);
        expect(await File(pCurrent).exists(), isTrue);
      });

      test('leaves NULL-version rows untouched (defer to LRU)', () async {
        // Per repo doc: "v == null → pre-tagging row, leave to LRU".
        // Trigger 2 only evicts rows that have a version AND it's stale.
        await seedRow(audioId: 'unknown', bytes: 10, contentVersion: null);
        await seedRow(audioId: 'stale', bytes: 10, contentVersion: 'v1');

        final evicted = await repo.evictByContentVersion({'v2'});

        expect(evicted, 1);
        expect(await repo.findByAudioId('unknown'), isNotNull);
        expect(await repo.findByAudioId('stale'), isNull);
      });

      test('handles a missing backing file without crashing', () async {
        await seedRow(
            audioId: 'orphan',
            bytes: 10,
            contentVersion: 'v1',
            createFile: false);

        final evicted = await repo.evictByContentVersion({'v2'});

        expect(evicted, 1);
        expect(await repo.findByAudioId('orphan'), isNull);
      });
    });
  });
}
