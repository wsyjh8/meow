// PR-B2 Day 2 v0.2: integration test — full flow fetch → download →
// checksum → install → drift readback.
//
// Day 2 v0.2 #14 review-adopted: _FakeManifestCdnServer helper centralizes
// the dual-routing (manifest API + CDN file serving) used across all 5
// cases, removing ~50 lines of per-test boilerplate.
//
// Day 2 plan v0.4 R2#5: integration tests are the canonical regression
// guard for fetch → download → checksum → install → drift; do NOT cut
// these tests under time pressure.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:meow_mobile/core/manifest/content_package_service.dart';
import 'package:meow_mobile/core/manifest/download_manager.dart';
import 'package:meow_mobile/core/manifest/manifest_client.dart';
import 'package:meow_mobile/core/manifest/package_installer.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

/// Dual-route fake server: same instance handles `/content/manifest`
/// and CDN file URLs. Reusable across all integration cases.
class _FakeManifestCdnServer extends http.BaseClient {
  Map<String, dynamic>? manifestJson;
  final Map<String, List<int>> _files = {};
  final Map<String, int> _statusCodes = {};

  void registerPackage({required String url, required List<int> bytes}) {
    _files[url] = bytes;
  }

  /// Inject a non-200 response for a given URL (test error paths).
  void registerStatus(String url, int statusCode) {
    _statusCodes[url] = statusCode;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest req) async {
    final url = req.url.toString();
    if (req.url.path.endsWith('/content/manifest')) {
      if (manifestJson == null) {
        throw Exception('manifestJson not set on _FakeManifestCdnServer');
      }
      return http.StreamedResponse(
        Stream.value(utf8.encode(jsonEncode(manifestJson!))),
        200,
      );
    }
    final status = _statusCodes[url];
    if (status != null && status != 200) {
      return http.StreamedResponse(const Stream.empty(), status);
    }
    final bytes = _files[url];
    if (bytes != null) {
      return http.StreamedResponse(Stream.value(bytes), 200);
    }
    throw Exception('unexpected URL: $url');
  }
}

Map<String, dynamic> _row({
  required String stableId,
  required String wordId,
  int ordinal = 1,
  String en = 'sample',
  String cn = '示例',
}) =>
    {
      'stable_id': stableId,
      'word_id': wordId,
      'sense_label': '',
      'en': en,
      'cn': cn,
      'difficulty': 1.0,
      'ordinal': ordinal,
      'status': 'active',
      'content_hash': 'hash',
    };

({List<int> gzBytes, String hash}) _buildPackage(
    List<Map<String, dynamic>> rows) {
  final lines = rows.map(jsonEncode).join('\n');
  final gzBytes = gzip.encode(utf8.encode(lines));
  final hash = sha256.convert(gzBytes).toString();
  return (gzBytes: gzBytes, hash: hash);
}

Map<String, dynamic> _manifestPackage({
  required String packageId,
  required String packageName,
  required String packageKind,
  required String contentVersion,
  required String fileUrl,
  required String checksum,
  required int sizeBytes,
  String? bookId = 'zk',
  String releaseId = 'rel-test',
}) =>
    {
      'package_id': packageId,
      'package_name': packageName,
      'package_kind': packageKind,
      'book_id': bookId,
      'content_version': contentVersion,
      'file_url': fileUrl,
      'checksum_sha256': checksum,
      'size_bytes': sizeBytes,
      'compression': 'gzip',
      'min_app_version': '0.0.0',
      'release_id': releaseId,
    };

ContentPackageService _service({
  required AppDatabase db,
  required Directory cacheDir,
  required _FakeManifestCdnServer server,
}) =>
    ContentPackageService(
      cacheDir: cacheDir,
      db: db,
      manifestClient: ManifestClient(client: server),
      downloadManager: DownloadManager(client: server, cacheDir: cacheDir),
      installer: PackageInstaller(db: db),
    );

void main() {
  late AppDatabase db;
  late Directory tmpCache;
  late _FakeManifestCdnServer server;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tmpCache = await Directory.systemTemp.createTemp('integ_');
    server = _FakeManifestCdnServer();
  });
  tearDown(() async {
    await db.close();
    if (await tmpCache.exists()) await tmpCache.delete(recursive: true);
  });

  group('manifest sync integration', () {
    test('full flow: fetch → download → checksum → install → drift readback',
        () async {
      final pkg = _buildPackage([
        _row(stableId: 's1', wordId: 'apple', en: 'an apple'),
        _row(stableId: 's2', wordId: 'banana', en: 'a banana'),
      ]);
      const url = 'http://cdn.test/examples-zk@v1.gz';

      server.manifestJson = {
        'release_ids': ['rel-test'],
        'packages': [
          _manifestPackage(
            packageId: 'examples-zk@v1',
            packageName: 'examples-zk',
            packageKind: 'examples',
            contentVersion: 'v1',
            fileUrl: url,
            checksum: pkg.hash,
            sizeBytes: pkg.gzBytes.length,
          ),
        ],
      };
      server.registerPackage(url: url, bytes: pkg.gzBytes);

      final result =
          await _service(db: db, cacheDir: tmpCache, server: server)
              .syncIfNeeded();

      expect(result.installed, ['examples-zk@v1']);
      expect(result.failed, isEmpty);
      expect(result.manifestError, isNull);

      final exRows = await db.select(db.exampleSentences).get();
      expect(exRows, hasLength(2));
      expect(exRows.map((r) => r.stableId).toSet(), {'s1', 's2'});

      final stateRows = await db.select(db.contentPackageStates).get();
      expect(stateRows, hasLength(1));
      expect(stateRows.first.packageId, 'examples-zk@v1');
    });

    test('checksum mismatch: not installed, failed[], state not written',
        () async {
      final pkg = _buildPackage([_row(stableId: 's1', wordId: 'apple')]);
      const url = 'http://cdn.test/examples-zk@v1.gz';

      server.manifestJson = {
        'release_ids': ['rel-test'],
        'packages': [
          _manifestPackage(
            packageId: 'examples-zk@v1',
            packageName: 'examples-zk',
            packageKind: 'examples',
            contentVersion: 'v1',
            fileUrl: url,
            checksum: 'WRONG_HASH',
            sizeBytes: pkg.gzBytes.length,
          ),
        ],
      };
      server.registerPackage(url: url, bytes: pkg.gzBytes);

      final result =
          await _service(db: db, cacheDir: tmpCache, server: server)
              .syncIfNeeded();

      expect(result.failed, ['examples-zk@v1']);
      expect(result.installed, isEmpty);
      expect(result.failureReasons['examples-zk@v1'], contains('Checksum'));

      expect(await db.select(db.exampleSentences).get(), isEmpty);
      expect(await db.select(db.contentPackageStates).get(), isEmpty);
    });

    test('non-examples kind: skipped, not downloaded', () async {
      var fileServed = false;
      const url = 'http://cdn.test/audio-meta-zk@v1.gz';

      server.manifestJson = {
        'release_ids': ['rel-test'],
        'packages': [
          _manifestPackage(
            packageId: 'audio-meta-zk@v1',
            packageName: 'audio-meta-zk',
            packageKind: 'audio_meta',
            contentVersion: 'v1',
            fileUrl: url,
            checksum: 'irrelevant',
            sizeBytes: 100,
          ),
        ],
      };
      // We register no bytes intentionally — if download is attempted it
      // throws "unexpected URL", failing the test.

      final result =
          await _service(db: db, cacheDir: tmpCache, server: server)
              .syncIfNeeded();

      expect(result.skipped, ['audio-meta-zk@v1']);
      expect(result.installed, isEmpty);
      expect(result.failed, isEmpty);
      expect(fileServed, isFalse);
    });

    test('partial failure: 2 packages, 1 install ok, 1 download fails',
        () async {
      final ok = _buildPackage([_row(stableId: 's1', wordId: 'apple')]);
      const okUrl = 'http://cdn.test/examples-zk@v1.gz';
      const badUrl = 'http://cdn.test/examples-cet4@v1.gz';

      server.manifestJson = {
        'release_ids': ['rel-test'],
        'packages': [
          _manifestPackage(
            packageId: 'examples-zk@v1',
            packageName: 'examples-zk',
            packageKind: 'examples',
            contentVersion: 'v1',
            fileUrl: okUrl,
            checksum: ok.hash,
            sizeBytes: ok.gzBytes.length,
          ),
          _manifestPackage(
            packageId: 'examples-cet4@v1',
            packageName: 'examples-cet4',
            packageKind: 'examples',
            contentVersion: 'v1',
            fileUrl: badUrl,
            checksum: 'irrelevant',
            sizeBytes: 100,
            bookId: 'cet4',
          ),
        ],
      };
      server.registerPackage(url: okUrl, bytes: ok.gzBytes);
      server.registerStatus(badUrl, 500);

      final result =
          await _service(db: db, cacheDir: tmpCache, server: server)
              .syncIfNeeded();

      expect(result.installed, ['examples-zk@v1']);
      expect(result.failed, ['examples-cet4@v1']);

      // Only the successful package writes state.
      final stateRows = await db.select(db.contentPackageStates).get();
      expect(stateRows, hasLength(1));
      expect(stateRows.first.packageId, 'examples-zk@v1');
    });

    // Day 2 v0.2 #1 关键 case: replace 后 state 表仍 1 行 (no bloat)
    test(
        'replace: pre-existing v1 in drift, server v2 → drift updated, '
        'state still 1 row', () async {
      // 1. Seed v1 state in drift.
      await db.into(db.contentPackageStates).insert(
            ContentPackageStatesCompanion.insert(
              packageId: 'examples-zk@v1',
              packageName: 'examples-zk',
              packageKind: 'examples',
              contentVersion: 'v1',
              releaseId: 'rel-old',
              checksumSha256: 'old',
              installedAt: 1,
            ),
          );

      // 2. Server returns v2 of same packageName.
      final pkg = _buildPackage(
          [_row(stableId: 's-v2', wordId: 'apple', en: 'V2 example')]);
      const url = 'http://cdn.test/examples-zk@v2.gz';
      server.manifestJson = {
        'release_ids': ['rel-new'],
        'packages': [
          _manifestPackage(
            packageId: 'examples-zk@v2',
            packageName: 'examples-zk',
            packageKind: 'examples',
            contentVersion: 'v2',
            fileUrl: url,
            checksum: pkg.hash,
            sizeBytes: pkg.gzBytes.length,
            releaseId: 'rel-new',
          ),
        ],
      };
      server.registerPackage(url: url, bytes: pkg.gzBytes);

      // 3. Sync.
      final result =
          await _service(db: db, cacheDir: tmpCache, server: server)
              .syncIfNeeded();

      expect(result.replaced, ['examples-zk@v2']);

      // 4. State table holds exactly ONE row, the v2 one. No v1 leftover.
      final stateRows = await db.select(db.contentPackageStates).get();
      expect(stateRows, hasLength(1));
      expect(stateRows.first.packageId, 'examples-zk@v2');
      expect(stateRows.first.contentVersion, 'v2');
      expect(stateRows.first.releaseId, 'rel-new');
    });
  });
}
