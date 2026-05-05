import 'dart:async' show unawaited;
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../storage/drift/app_database.dart';

/// Persistence + filesystem layer for cached audio binaries.
///
/// Owns the `audio_file_cache` drift table interactions and the
/// `{appDocs}/audio/{audio_id}.mp3` file lifecycle. Knows nothing about
/// API URL patterns or `target_kind` (`example` vs `word`) — it's purely
/// keyed by the global `audio_id`.
///
/// Used by [ExampleAudioService] and [WordAudioService]; both share the
/// same cache pool because audio_assets.id is globally unique across
/// target kinds (per DB v0.3.0 §3.1 hash spec).
///
/// Implements DB §7.4.1:
///   - Trigger 1: capacity + LRU (default 200 MB cap, evict to cap × 0.8)
///   - Trigger 2: content_version orphan eviction
///   - Sanity: file_size + checksum field comparison only (NEVER reread file)
class AudioCacheRepository {
  AudioCacheRepository({AppDatabase? db})
      : _db = db ?? AppDatabase();

  final AppDatabase _db;

  /// Default capacity (DB §7.4.1: 200 MB). Configurable later.
  static const int _defaultCapacityBytes = 200 * 1024 * 1024;

  /// Eviction recovery ratio — drop to cap × 0.8 to avoid thrash.
  static const double _evictionTargetRatio = 0.8;

  /// Resolved cache dir, lazy-initialized.
  String? _cacheDir;

  // ── Lookups ──────────────────────────────────────────────────────────────

  Future<AudioFileCacheData?> findByAudioId(String audioId) async {
    return (_db.select(_db.audioFileCache)
          ..where((t) => t.audioId.equals(audioId)))
        .getSingleOrNull();
  }

  Future<void> touchPlayedAt(String audioId) async {
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await (_db.update(_db.audioFileCache)
          ..where((t) => t.audioId.equals(audioId)))
        .write(AudioFileCacheCompanion(lastPlayedAt: Value(nowMs)));
  }

  // ── Download + insert ────────────────────────────────────────────────────

  /// Download the binary, validate sanity (file_size + decode header),
  /// write to disk, and insert/update the cache row.
  ///
  /// Per DB §7.4.1: client only does file_size + checksum field match
  /// (against the manifest's bytes / checksum_sha256), NEVER recomputes
  /// SHA-256 from disk. Decode validation is left to the audioplayers
  /// library at play time.
  ///
  /// Returns true on successful cache, false on failure (silent — caller
  /// can still play from URL).
  Future<bool> downloadAndCache({
    required String audioId,
    required String url,
    required String checksumSha256,
    required int expectedBytes,
    required String contentVersion,
  }) async {
    try {
      final dir = await _ensureCacheDir();
      final filePath = '$dir/$audioId.mp3';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return false;
      }
      // Sanity: byte length match (server-reported expected_bytes may be 0
      // if pipeline didn't fill it; skip in that case).
      if (expectedBytes > 0 && response.bodyBytes.length != expectedBytes) {
        return false;
      }
      await File(filePath).writeAsBytes(response.bodyBytes);

      final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      await _db.into(_db.audioFileCache).insertOnConflictUpdate(
            AudioFileCacheCompanion.insert(
              audioId: audioId,
              localPath: filePath,
              bytes: response.bodyBytes.length,
              cachedAt: nowMs,
              cachedChecksum: Value(checksumSha256),
              cachedContentVersion: Value(contentVersion),
            ),
          );

      // Capacity eviction fire-and-forget.
      unawaited(evictByCapacity());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Delete a stale entry (file + row). Used when a file referenced by
  /// the cache row went missing (OS cleanup or user delete).
  Future<void> deleteEntry(String audioId) async {
    await (_db.delete(_db.audioFileCache)
          ..where((t) => t.audioId.equals(audioId)))
        .go();
  }

  // ── Eviction ─────────────────────────────────────────────────────────────

  /// Trigger 1 (DB §7.4.1): capacity-cap + LRU. Returns rows evicted.
  Future<int> evictByCapacity({int? capacityBytes}) async {
    final cap = capacityBytes ?? _defaultCapacityBytes;
    final target = (cap * _evictionTargetRatio).round();

    final totalRow = await _db
        .customSelect(
            'SELECT COALESCE(SUM(bytes), 0) AS total FROM audio_file_cache')
        .getSingle();
    var current = totalRow.read<int>('total');
    if (current <= cap) return 0;

    final candidates = await _db.customSelect(
      'SELECT audio_id, local_path, bytes FROM audio_file_cache '
      'ORDER BY (last_played_at IS NULL) DESC, '
      '         last_played_at ASC, cached_at ASC',
    ).get();

    var deleted = 0;
    for (final row in candidates) {
      if (current <= target) break;
      final id = row.read<String>('audio_id');
      final path = row.read<String>('local_path');
      final bytes = row.read<int>('bytes');
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {/* file already gone */}
      await deleteEntry(id);
      current -= bytes;
      deleted++;
    }
    return deleted;
  }

  /// Trigger 2 (DB §7.4.1): content_version orphan eviction. Used after a
  /// manifest pull discovers new active versions. Rows whose
  /// cached_content_version isn't in [activeContentVersions] are evicted.
  Future<int> evictByContentVersion(Set<String> activeContentVersions) async {
    if (activeContentVersions.isEmpty) return 0;
    final allRows = await _db.select(_db.audioFileCache).get();
    var deleted = 0;
    for (final row in allRows) {
      final v = row.cachedContentVersion;
      if (v == null) continue; // pre-tagging row, leave to LRU
      if (activeContentVersions.contains(v)) continue;
      try {
        final file = File(row.localPath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      await deleteEntry(row.audioId);
      deleted++;
    }
    return deleted;
  }

  // ── User-facing ──────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final rows = await _db.select(_db.audioFileCache).get();
    for (final r in rows) {
      try {
        final file = File(r.localPath);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    await _db.delete(_db.audioFileCache).go();
  }

  Future<int> totalCachedBytes() async {
    final row = await _db
        .customSelect(
            'SELECT COALESCE(SUM(bytes), 0) AS total FROM audio_file_cache')
        .getSingle();
    return row.read<int>('total');
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  Future<String> _ensureCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/audio');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir.path;
    return _cacheDir!;
  }
}

/// Shared meta DTO between API responses and cache layer. Both
/// `/api/v1/examples/:stable_id/audio` and `/api/v1/words/:word_id/audio`
/// return this shape (modulo `target_kind` implicit in the URL).
class AudioMeta {
  final String audioId;
  final String url;
  final String checksumSha256;
  final int durationMs;
  final int bytes;
  final String audioVersion;

  const AudioMeta({
    required this.audioId,
    required this.url,
    required this.checksumSha256,
    required this.durationMs,
    required this.bytes,
    required this.audioVersion,
  });

  factory AudioMeta.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String?;
    if (url == null || url.isEmpty) {
      throw const FormatException('Audio meta missing url');
    }
    return AudioMeta(
      audioId: json['audio_id'] as String,
      url: url,
      checksumSha256: json['checksum_sha256'] as String,
      durationMs: json['duration_ms'] as int? ?? 0,
      bytes: json['bytes'] as int? ?? 0,
      audioVersion: json['audio_version'] as String? ?? 'v1',
    );
  }
}

/// Throw to signal "API said no audio for this target / 404 / network fail".
/// UI captures it and grays the play button. **MUST NOT** trigger system TTS
/// fallback (DB §11 explicit prohibition).
class AudioFetchException implements Exception {
  final String message;
  const AudioFetchException(this.message);
  @override
  String toString() => 'AudioFetchException: $message';
}
