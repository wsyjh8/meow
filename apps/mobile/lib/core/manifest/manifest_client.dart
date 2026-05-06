// PR-B2 Day 1: HTTP client for /api/v1/content/manifest.
//
// Per master plan v0.4 D4 decision: every fetch pulls the FULL manifest
// (no since_release checkpoint). The manifest itself is small (a few
// hundred bytes typically); skipping the checkpoint optimization avoids
// the "failed package permanently dropped" bug (R2#3 review).
//
// Exception types are split between network and parse so callers
// (ContentPackageService) can decide retry policy per error class.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// 12-field DTO mirroring server controller response shape
/// (apps/api/src/controllers/content-manifest.controller.ts:31-46).
class ManifestPackage {
  final String packageId;       // "examples-zk@v5"
  final String packageName;     // "examples-zk"
  final String packageKind;     // "examples" / "audio_meta" / "wordbook" / "dictionary"
  final String? bookId;         // "zk" / "cet4" / null when kind=dictionary
  final String contentVersion;  // "v5"
  final String fileUrl;         // file:// (dev) or http:// (PR-B3 staging serve / PR-B3+ real CDN)
  final String checksumSha256;  // hex string, used by DownloadManager for verification
  final int sizeBytes;          // package size in bytes
  final String? compression;    // "gzip" / "brotli" / null
  final String minAppVersion;   // strict semver "X.Y.Z"
  final String releaseId;       // governance audit

  ManifestPackage({
    required this.packageId,
    required this.packageName,
    required this.packageKind,
    required this.bookId,
    required this.contentVersion,
    required this.fileUrl,
    required this.checksumSha256,
    required this.sizeBytes,
    required this.compression,
    required this.minAppVersion,
    required this.releaseId,
  });

  factory ManifestPackage.fromJson(Map<String, dynamic> j) => ManifestPackage(
        packageId: j['package_id'] as String,
        packageName: j['package_name'] as String,
        packageKind: j['package_kind'] as String,
        bookId: j['book_id'] as String?,
        contentVersion: j['content_version'] as String,
        fileUrl: j['file_url'] as String,
        checksumSha256: j['checksum_sha256'] as String,
        sizeBytes: j['size_bytes'] as int,
        compression: j['compression'] as String?,
        minAppVersion: j['min_app_version'] as String,
        releaseId: j['release_id'] as String,
      );

  @override
  String toString() => 'ManifestPackage($packageId, '
      'kind=$packageKind, version=$contentVersion, release=$releaseId)';
}

/// Top-level manifest response. `releaseIds` is the set of releases
/// contributing packages to this snapshot (typically size 1 for current
/// active state, larger when multiple packages span releases).
class ManifestResponse {
  final List<String> releaseIds;
  final List<ManifestPackage> packages;

  ManifestResponse({required this.releaseIds, required this.packages});

  factory ManifestResponse.fromJson(Map<String, dynamic> j) => ManifestResponse(
        releaseIds: (j['release_ids'] as List).cast<String>(),
        packages: (j['packages'] as List)
            .map((p) => ManifestPackage.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

/// Network-layer failure: connection refused, non-2xx status, timeout.
/// Caller may retry (e.g., next app foreground).
class ManifestNetworkError implements Exception {
  final int? statusCode;
  final String message;
  ManifestNetworkError(this.message, {this.statusCode});

  @override
  String toString() => 'ManifestNetworkError'
      '(${statusCode != null ? "status=$statusCode, " : ""}$message)';
}

/// Response decoded but shape unexpected. Likely indicates an
/// API contract drift between server and client. Do NOT retry —
/// fix the schema mismatch first.
class ManifestParseError implements Exception {
  final String message;
  ManifestParseError(this.message);

  @override
  String toString() => 'ManifestParseError($message)';
}

class ManifestClient {
  /// PR-B2 v0.4 R1#7: baseUrl currently hardcoded in line with
  /// `api_client.dart:14-18` — no shared config layer exists yet.
  /// Future PR (likely PR-C alongside observability) should extract a
  /// const + dev/prod toggle. Out of PR-B2 scope.
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  ManifestClient({
    this.baseUrl = 'http://10.0.2.2:3000/api/v1',
    http.Client? client,
    this.timeout = const Duration(seconds: 10),  // R1#4
  }) : _client = client ?? http.Client();

  /// Fetch the full content manifest. Per D4, we deliberately do NOT pass
  /// `since_release` — checkpoint optimization is unsafe when individual
  /// packages can fail mid-batch (failed package would be skipped forever).
  ///
  /// Returns parsed [ManifestResponse]. Throws [ManifestNetworkError] on
  /// network/HTTP failures, [ManifestParseError] on schema drift.
  Future<ManifestResponse> fetchManifest({String? appVersion}) async {
    final params = <String, String>{};
    if (appVersion != null) params['app_version'] = appVersion;
    final uri = Uri.parse('$baseUrl/content/manifest').replace(
      queryParameters: params.isEmpty ? null : params,
    );

    http.Response resp;
    try {
      resp = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw ManifestNetworkError(
        'GET $uri timed out after ${timeout.inSeconds}s',
      );
    } catch (e) {
      throw ManifestNetworkError('GET $uri failed: $e');
    }
    if (resp.statusCode != 200) {
      throw ManifestNetworkError(
        'GET $uri returned ${resp.statusCode}: ${resp.body}',
        statusCode: resp.statusCode,
      );
    }
    try {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return ManifestResponse.fromJson(json);
    } catch (e) {
      throw ManifestParseError('parse failed: $e');
    }
  }
}
