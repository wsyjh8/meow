// PR-B2 Day 1: streaming package download with sha256 verification.
//
// Per master plan v0.4 + Day 1 plan v0.2 review-adopted decisions:
//   R1#1 (方案 B): use dart:convert ChunkedConversionSink — zero new
//                   dependencies. AccumulatorSink (package:convert) NOT used.
//   R1#3:           wipe .partial at every retry entry to prevent old-byte
//                   contamination; sha256 sink in finally for clean shutdown.
//   R1#4:           explicit 30s timeout on _client.send().
//   master v0.4 R1#3 brotli guard: only "gzip" or null compression accepted.
//
// Failure model:
//   - ChecksumMismatchError / UnsupportedCompressionError: rethrown, NOT
//     retried (data error or contract error — retry won't help).
//   - Network error: retried with exponential backoff 1s/2s/4s, max 3
//     attempts. Final failure throws DownloadFailedError.
//   - On final failure, content_package_state is NOT written (PackageInstaller
//     responsibility); next sync attempt re-downloads from scratch.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'manifest_client.dart' show ManifestPackage;

class ChecksumMismatchError implements Exception {
  final String packageId;
  final String expected;
  final String actual;
  ChecksumMismatchError(this.packageId, this.expected, this.actual);

  @override
  String toString() =>
      'ChecksumMismatchError($packageId, expected=$expected, actual=$actual)';
}

class UnsupportedCompressionError implements Exception {
  final String compression;
  UnsupportedCompressionError(this.compression);

  @override
  String toString() => 'UnsupportedCompressionError($compression)';
}

class DownloadFailedError implements Exception {
  final String packageId;
  final String message;
  final int attempts;
  DownloadFailedError(this.packageId, this.message, this.attempts);

  @override
  String toString() =>
      'DownloadFailedError($packageId, attempts=$attempts, $message)';
}

class DownloadManager {
  final http.Client _client;
  final Directory _cacheDir;
  final Directory _tmpDir;
  final Duration sendTimeout;

  DownloadManager({
    http.Client? client,
    required Directory cacheDir,
    this.sendTimeout = const Duration(seconds: 30),  // R1#4
  })  : _client = client ?? http.Client(),
        _cacheDir = cacheDir,
        _tmpDir = Directory('${cacheDir.path}/manifest_packages/.tmp');

  /// Streaming download of [pkg.fileUrl] with sha256 verification.
  ///
  /// Layout:
  ///   {cacheDir}/manifest_packages/.tmp/{packageId}.partial  (in-flight)
  ///   {cacheDir}/manifest_packages/{packageId}.gz            (verified)
  ///
  /// Returns the verified file. Throws on any of:
  ///   - [UnsupportedCompressionError] (brotli or other non-gzip)
  ///   - [ChecksumMismatchError] (sha256 mismatch — corrupt or wrong file)
  ///   - [DownloadFailedError] (network exhausted retries)
  Future<File> downloadPackage(ManifestPackage pkg) async {
    // Brotli guard (R1#3 review): PR-B2 v1 only supports gzip. Brotli
    // packages would silently install corrupt data — refuse early.
    if (pkg.compression != null && pkg.compression != 'gzip') {
      throw UnsupportedCompressionError(pkg.compression!);
    }

    await _tmpDir.create(recursive: true);
    final partialFile = File('${_tmpDir.path}/${pkg.packageId}.partial');
    final finalFile = File(
      '${_cacheDir.path}/manifest_packages/${pkg.packageId}.gz',
    );

    int attempt = 0;
    Object? lastError;
    while (attempt < 3) {
      attempt++;
      // R1#3: wipe .partial at every retry entry. Default openWrite() mode
      // also truncates, but explicit delete makes the invariant clear and
      // catches the "file exists from prior crash" edge case.
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
      try {
        final hash = await _downloadAndHash(pkg.fileUrl, partialFile);
        if (hash != pkg.checksumSha256) {
          // Cleanup .partial before raising — it's contaminated and we
          // should NOT keep it around for next retry (this exception path
          // does not loop).
          await partialFile.delete().catchError((_) => partialFile);
          throw ChecksumMismatchError(
            pkg.packageId,
            pkg.checksumSha256,
            hash,
          );
        }
        await finalFile.parent.create(recursive: true);
        await partialFile.rename(finalFile.path);
        return finalFile;
      } on ChecksumMismatchError {
        rethrow;  // data error: do not retry
      } on UnsupportedCompressionError {
        rethrow;  // contract error: do not retry
      } catch (e) {
        lastError = e;
        if (attempt >= 3) {
          throw DownloadFailedError(pkg.packageId, e.toString(), attempt);
        }
        // Exponential backoff: 1s / 2s / 4s
        await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
      }
    }
    // Defensive: while-loop should always exit via return or throw.
    throw DownloadFailedError(
      pkg.packageId,
      'unreachable: ${lastError ?? "unknown"}',
      attempt,
    );
  }

  /// Streams [url] into [partial] while accumulating a sha256 digest.
  ///
  /// Implementation note (R1#1 方案 B): uses dart:convert
  /// `ChunkedConversionSink.withCallback` to avoid pulling in
  /// `package:convert` for AccumulatorSink. The completer pattern ensures
  /// the digest is captured exactly once when [inputSink.close()] fires the
  /// callback.
  Future<String> _downloadAndHash(String url, File partial) async {
    final fileSink = partial.openWrite();
    final digestCompleter = Completer<Digest>();
    final inputSink = sha256.startChunkedConversion(
      ChunkedConversionSink<Digest>.withCallback((digests) {
        // sha256 emits exactly one Digest on close().
        if (!digestCompleter.isCompleted) {
          digestCompleter.complete(digests.single);
        }
      }),
    );
    try {
      final req = http.Request('GET', Uri.parse(url));
      final resp = await _client.send(req).timeout(sendTimeout);  // R1#4
      if (resp.statusCode != 200) {
        throw HttpException('GET $url returned ${resp.statusCode}');
      }
      await for (final chunk in resp.stream) {
        fileSink.add(chunk);
        inputSink.add(chunk);
      }
      inputSink.close();
      await fileSink.flush();
      final digest = await digestCompleter.future;
      return digest.toString();
    } finally {
      // fileSink must close to release the file handle even on error path.
      // inputSink: if not closed yet (error before close()), the callback
      // never fires; the digestCompleter is abandoned (no leak — no file
      // handle held).
      await fileSink.close();
    }
  }
}
