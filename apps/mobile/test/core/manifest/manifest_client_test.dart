// PR-B2 Day 1: ManifestClient unit tests, 6 cases.
//
// Per master plan v0.4 R1#2: pubspec has no mocktail/mockito; we use a
// hand-written `_FakeHttpClient extends http.BaseClient`. ~10 lines, zero
// new dependencies.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:meow_mobile/core/manifest/manifest_client.dart';

class _FakeHttpClient extends http.BaseClient {
  final FutureOr<http.StreamedResponse> Function(http.BaseRequest req) handler;
  _FakeHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest req) async =>
      await handler(req);
}

http.StreamedResponse _streamResp(int status, String body) =>
    http.StreamedResponse(Stream.value(utf8.encode(body)), status);

const _samplePackageJson = {
  'package_id': 'examples-zk@v5',
  'package_name': 'examples-zk',
  'package_kind': 'examples',
  'book_id': 'zk',
  'content_version': 'v5',
  'file_url': 'http://localhost:3000/cdn/staging/examples-zk@v5.jsonl.gz',
  'checksum_sha256': 'abc123',
  'size_bytes': 102400,
  'compression': 'gzip',
  'min_app_version': '0.0.0',
  'release_id': 'rel-2026-05-06-001',
};

void main() {
  group('ManifestClient', () {
    test('200 happy path returns parsed ManifestResponse', () async {
      final client = _FakeHttpClient(
        (req) => _streamResp(
          200,
          jsonEncode({
            'release_ids': ['rel-2026-05-06-001'],
            'packages': [_samplePackageJson],
          }),
        ),
      );
      final m = ManifestClient(client: client);
      final resp = await m.fetchManifest();
      expect(resp.releaseIds, ['rel-2026-05-06-001']);
      expect(resp.packages, hasLength(1));
      final p = resp.packages.first;
      expect(p.packageId, 'examples-zk@v5');
      expect(p.packageName, 'examples-zk');
      expect(p.packageKind, 'examples');
      expect(p.bookId, 'zk');
      expect(p.contentVersion, 'v5');
      expect(p.checksumSha256, 'abc123');
      expect(p.sizeBytes, 102400);
      expect(p.compression, 'gzip');
      expect(p.minAppVersion, '0.0.0');
      expect(p.releaseId, 'rel-2026-05-06-001');
    });

    test('400 → ManifestNetworkError(statusCode=400)', () async {
      final client = _FakeHttpClient((_) => _streamResp(400, 'bad request'));
      final m = ManifestClient(client: client);
      await expectLater(
        m.fetchManifest(),
        throwsA(isA<ManifestNetworkError>().having(
          (e) => e.statusCode,
          'statusCode',
          400,
        )),
      );
    });

    test('500 → ManifestNetworkError(statusCode=500)', () async {
      final client = _FakeHttpClient((_) => _streamResp(500, 'oops'));
      final m = ManifestClient(client: client);
      await expectLater(
        m.fetchManifest(),
        throwsA(isA<ManifestNetworkError>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );
    });

    test('network error → ManifestNetworkError without statusCode', () async {
      final client = _FakeHttpClient(
        (_) => throw const SocketException('connection refused'),
      );
      final m = ManifestClient(client: client);
      await expectLater(
        m.fetchManifest(),
        throwsA(isA<ManifestNetworkError>().having(
          (e) => e.statusCode,
          'statusCode',
          isNull,
        )),
      );
    });

    test('200 but body is not JSON → ManifestParseError', () async {
      final client = _FakeHttpClient((_) => _streamResp(200, 'not-json{{{'));
      final m = ManifestClient(client: client);
      await expectLater(
        m.fetchManifest(),
        throwsA(isA<ManifestParseError>()),
      );
    });

    test('timeout → ManifestNetworkError "timed out" (R1#4)', () async {
      final client = _FakeHttpClient((_) async {
        // Sleep longer than the configured timeout
        await Future.delayed(const Duration(seconds: 5));
        return _streamResp(200, '{}');
      });
      final m = ManifestClient(
        client: client,
        timeout: const Duration(milliseconds: 100),
      );
      await expectLater(
        m.fetchManifest(),
        throwsA(isA<ManifestNetworkError>().having(
          (e) => e.message,
          'message',
          contains('timed out'),
        )),
      );
    });
  });
}

// Local re-export to avoid importing dart:io for SocketException in test
class SocketException implements Exception {
  final String message;
  const SocketException(this.message);
  @override
  String toString() => 'SocketException: $message';
}
