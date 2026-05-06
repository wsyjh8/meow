// PR-B2 Day 2 v0.2: top-level orchestrator for manifest sync.
//
// Composes ManifestClient + DownloadManager + PackageInstaller. Day 2
// builds the service ready-to-go but does NOT wire it into the app
// startup sequence — that's PR-B3 (with feature flag) and PR-B4 (default
// on). Day 2 only verifies the SQL/HTTP/file-system contract via tests.
//
// Sync algorithm (master plan v0.4 D4 + R1#5 + Day 2 plan v0.2 #2 / #12):
//   1. fetchManifest() — full pull, no since_release (avoids the failed-
//      package-permanently-skipped bug). Failure → SyncResult.manifestError
//      populated, all other lists empty.
//   2. kind filter: package_kind != 'examples' → skipped[] (BEFORE download
//      to save bandwidth). PR-B3+ adds other kinds.
//   3. state diff (by packageName, not packageId): new / replace (rename
//      from "upgrade" — see #9 — covers rollback downgrade too) / skip.
//   4. download → install (via DownloadManager + PackageInstaller). On
//      failure: failed[] + failureReasons map; state NOT written; next
//      sync attempt re-downloads from scratch.

import 'dart:io';

import '../storage/drift/app_database.dart';
import 'download_manager.dart';
import 'manifest_client.dart';
import 'package_installer.dart';

class SyncResult {
  /// Newly installed (was absent locally).
  final List<String> installed;

  /// Version differs from local; manifest replaced the local snapshot.
  /// **Includes rollback downgrade** (server v8 → v7); the field is named
  /// `replaced` rather than `upgraded` to make this clear.
  final List<String> replaced;

  /// Either same content_version (no-op) or non-`examples` kind (PR-B2 v1
  /// only implements examples). The reason is in [failureReasons] for the
  /// kind-skip case.
  final List<String> skipped;

  /// Download or install failed. Reason in [failureReasons].
  /// `content_package_state` is NOT updated for these — next sync retries.
  final List<String> failed;

  /// packageId → human-readable error string. For non-examples kind
  /// the reason starts with "kind=".
  final Map<String, String> failureReasons;

  /// Top-level manifest fetch failure (network / parse). When non-null,
  /// the other lists are all empty. Allows callers to distinguish
  /// "sync failed entirely" from "sync ran, no changes needed".
  /// (Day 2 plan v0.2 #12 review-adopted)
  final String? manifestError;

  const SyncResult({
    required this.installed,
    required this.replaced,
    required this.skipped,
    required this.failed,
    required this.failureReasons,
    this.manifestError,
  });

  bool get hasChanges => installed.isNotEmpty || replaced.isNotEmpty;
  bool get hasFailure => failed.isNotEmpty || manifestError != null;

  @override
  String toString() => 'SyncResult(installed=${installed.length}, '
      'replaced=${replaced.length}, skipped=${skipped.length}, '
      'failed=${failed.length}, '
      'manifestError=${manifestError != null ? "yes" : "no"})';
}

class ContentPackageService {
  final ManifestClient _client;
  final DownloadManager _downloader;
  final PackageInstaller _installer;
  final AppDatabase _db;

  /// Both `cacheDir` and `db` are **required** (Day 2 plan v0.2 #8 / #16).
  /// No silent defaults to systemTemp / new AppDatabase() — those are
  /// PR-B4 footguns.
  ///
  /// `installer` defaults to `PackageInstaller(db: db)` so the default
  /// shares the SAME db instance — fixes the "service reads from injected
  /// db, default installer writes to a different db" bug (Day 2 v0.2 #2).
  ContentPackageService({
    required Directory cacheDir,
    required AppDatabase db,
    ManifestClient? manifestClient,
    DownloadManager? downloadManager,
    PackageInstaller? installer,
  })  : _client = manifestClient ?? ManifestClient(),
        _downloader =
            downloadManager ?? DownloadManager(cacheDir: cacheDir),
        _installer = installer ?? PackageInstaller(db: db),
        _db = db;

  Future<SyncResult> syncIfNeeded({String? appVersion}) async {
    // Step 1: fetch full manifest (D4: no since_release).
    final ManifestResponse manifest;
    try {
      manifest = await _client.fetchManifest(appVersion: appVersion);
    } catch (e) {
      // #12: top-level manifestError, lists empty. Caller can distinguish
      // hasFailure (true) from hasChanges (false) for retry decisions.
      return SyncResult(
        installed: const [],
        replaced: const [],
        skipped: const [],
        failed: const [],
        failureReasons: const {},
        manifestError: e.toString(),
      );
    }

    final installed = <String>[];
    final replaced = <String>[];
    final skipped = <String>[];
    final failed = <String>[];
    final reasons = <String, String>{};

    // Local state indexed by packageName (matches the diff dimension).
    // PackageInstaller's _upsertPackageState ensures ≤ 1 row per packageName,
    // so this map's value is unambiguous.
    final localStates = <String, ContentPackageState>{};
    for (final s in await _db.select(_db.contentPackageStates).get()) {
      localStates[s.packageName] = s;
    }

    for (final pkg in manifest.packages) {
      // Step 2: kind filter (R1#5) — done BEFORE download.
      if (pkg.packageKind != 'examples') {
        skipped.add(pkg.packageId);
        reasons[pkg.packageId] =
            'kind=${pkg.packageKind} not implemented in PR-B2';
        continue;
      }

      // Step 3: state diff by packageName.
      final local = localStates[pkg.packageName];
      final isNew = local == null;
      final isReplace =
          local != null && local.contentVersion != pkg.contentVersion;
      final isSame =
          local != null && local.contentVersion == pkg.contentVersion;

      if (isSame) {
        skipped.add(pkg.packageId);
        continue;
      }

      // Step 4: download + install.
      try {
        final gzFile = await _downloader.downloadPackage(pkg);
        await _installer.install(gzFile, pkg);
        if (isNew) installed.add(pkg.packageId);
        if (isReplace) replaced.add(pkg.packageId);
      } catch (e) {
        failed.add(pkg.packageId);
        reasons[pkg.packageId] = e.toString();
        // No state write on failure → next sync re-downloads.
      }
    }

    return SyncResult(
      installed: installed,
      replaced: replaced,
      skipped: skipped,
      failed: failed,
      failureReasons: reasons,
    );
  }
}
