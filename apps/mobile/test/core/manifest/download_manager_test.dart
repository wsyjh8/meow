// PR-B2 Day 1: DownloadManager unit tests, 6 cases (R1#4 + R1#1 + R1#3).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:meow_mobile/core/manifest/download_manager.dart';
import 'package:meow_mobile/core/manifest/manifest_client.dart';

class _FakeHttpClient extends http.BaseClient {
  final FutureOr<http.StreamedResponse> Function(http.BaseRequest req) handler;
  _FakeHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest req) async =>
      await handler(req);
}

http.StreamedResponse _stream(int status, List<int> bytes) =>
    http.StreamedResponse(Stream.value(bytes), status);

ManifestPackage _pkg({
  required String checksum,
  String? compression = 'gzip',
}) =>
    ManifestPackage(
      packageId: 'examples-zk@v1',
      packageName: 'examples-zk',
      packageKind: 'examples',
      bookId: 'zk',
      contentVersion: 'v1',
      fileUrl: 'http://localhost:3000/cdn/staging/examples-zk@v1.jsonl.gz',
      checksumSha256: checksum,
      sizeBytes: 100,
      compression: compression,
      minAppVersion: '0.0.0',
      releaseId: 'rel-test',
    );

void main() {
  late Directory tmpCache;

  setUp(() async {
    tmpCache = await Directory.systemTemp.createTemp('dl_test_');
  });
  tearDown(() async {
    if (await tmpCache.exists()) await tmpCache.delete(recursive: true);
  });

  group('DownloadManager', () {
    test('happy: download + sha256 match returns final File', () async {
      final bytes = utf8.encode('hello world');
      final hash = sha256.convert(bytes).toString();
      final pkg = _pkg(checksum: hash);
      final dl = DownloadManager(
        cacheDir: tmpCache,
        client: _FakeHttpClient((_) => _stream(200, bytes)),
      );
      final file = await dl.downloadPackage(pkg);
      expect(await file.exists(), isTrue);
      final read = await file.readAsBytes();
      expect(read, bytes);
      expect(file.path, contains('manifest_packages/examples-zk@v1.gz'));
      // .partial cleaned (renamed to final)
      final partial = File(
        '${tmpCache.path}/manifest_packages/.tmp/examples-zk@v1.partial',
      );
      expect(await partial.exists(), isFalse);
    });

    test('checksum mismatch → ChecksumMismatchError + .partial cleaned',
        () async {
      final bytes = utf8.encode('hello world');
      final wrongHash = sha256.convert(utf8.encode('different')).toString();
      final pkg = _pkg(checksum: wrongHash);
      final dl = DownloadManager(
        cacheDir: tmpCache,
        client: _FakeHttpClient((_) => _stream(200, bytes)),
      );
      await expectLater(
        dl.downloadPackage(pkg),
        throwsA(isA<ChecksumMismatchError>()),
      );
      final partial = File(
        '${tmpCache.path}/manifest_packages/.tmp/examples-zk@v1.partial',
      );
      expect(await partial.exists(), isFalse);
    });

    test('brotli compression → UnsupportedCompressionError (R1#3)', () async {
      final pkg = _pkg(checksum: 'irrelevant', compression: 'brotli');
      final dl = DownloadManager(
        cacheDir: tmpCache,
        client: _FakeHttpClient(
          (_) => fail('client should not be called for brotli'),
        ),
      );
      await expectLater(
        dl.downloadPackage(pkg),
        throwsA(isA<UnsupportedCompressionError>()),
      );
    });

    test('网络错误后第3次成功 → returns File', () async {
      final bytes = utf8.encode('payload');
      final hash = sha256.convert(bytes).toString();
      final pkg = _pkg(checksum: hash);
      var calls = 0;
      final dl = DownloadManager(
        cacheDir: tmpCache,
        client: _FakeHttpClient((_) {
          calls++;
          if (calls < 3) {
            return Future<http.StreamedResponse>.error(
              const HttpException('transient'),
            );
          }
          return _stream(200, bytes);
        }),
      );
      // Test takes ~3s due to backoff (1s + 2s); acceptable for unit test.
      final file = await dl.downloadPackage(pkg);
      expect(await file.exists(), isTrue);
      expect(calls, 3);
    });

    test('重试上限 3 次都失败 → DownloadFailedError(attempts=3)', () async {
      final pkg = _pkg(checksum: 'irrelevant');
      var calls = 0;
      final dl = DownloadManager(
        cacheDir: tmpCache,
        client: _FakeHttpClient((_) {
          calls++;
          return Future<http.StreamedResponse>.error(
            const HttpException('always fails'),
          );
        }),
      );
      await expectLater(
        dl.downloadPackage(pkg),
        throwsA(isA<DownloadFailedError>().having(
          (e) => e.attempts,
          'attempts',
          3,
        )),
      );
      expect(calls, 3);
    });

    test('send timeout → DownloadFailedError after retries (R1#4)',
        () async {
      final pkg = _pkg(checksum: 'irrelevant');
      final dl = DownloadManager(
        cacheDir: tmpCache,
        client: _FakeHttpClient((_) async {
          // Sleep longer than configured sendTimeout to trigger the timeout.
          await Future.delayed(const Duration(seconds: 5));
          return _stream(200, []);
        }),
        sendTimeout: const Duration(milliseconds: 50),
      );
      await expectLater(
        dl.downloadPackage(pkg),
        throwsA(isA<DownloadFailedError>()),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
