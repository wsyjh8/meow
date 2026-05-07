import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/manifest/content_package_service.dart';
import 'core/memory/wordbook_loader.dart';
import 'core/services/enrichment_bootstrap.dart';
import 'core/storage/drift/app_database.dart';
import 'core/storage/local_database.dart';
import 'core/storage/local_settings_service.dart';

/// Factory used to construct a [ContentPackageService] inside the manifest
/// sync hook. Production callers omit this and the hook builds the real
/// service with the given [Directory] + [AppDatabase]. Unit tests inject
/// a fake to verify wire-up without touching network / disk.
typedef ContentPackageServiceFactory = ContentPackageService Function(
    Directory cacheDir, AppDatabase db);

/// PR-B3 Day 3 v0.2: manifest sync 启动异步 hook (test-friendly top-level
/// helper). Three-layer guard, any failure returns silently:
///
///   Layer 1 (kDebugMode, v0.2 #2 R2#P1 #1 review-adopted)
///     release/profile build dead-code-eliminate; defends against the
///     case where a debug build sets the SharedPreferences flag to true
///     and the user later installs a same-package release/profile build —
///     without this guard the stored flag would still trigger sync,
///     violating the "debug-only / release behavior unchanged" boundary.
///
///   Layer 2 (LocalSettingsService.manifestSyncEnabled, default false)
///     PR-B3 feature flag. Until the user opts in via the debug settings
///     page, this is false → return.
///
///   Layer 3 (ContentPackageService.syncIfNeeded, fire-and-forget)
///     `appVersion: PackageInfo.fromPlatform().version` is the real
///     pubspec version (v0.2 #3 R2#P1 #2: server's min_app_version
///     filter actually engages, vs v0.1's appVersion=null which silently
///     bypassed it).
///
/// Failure handling: hasFailure / hasChanges may both be true (mixed
/// state — some packages installed, others failed). Output a single mixed
/// log line containing all counts (v0.2 #6 R1#4: never drop the
/// installed/replaced numbers in the failed branch).
///
/// Caller usage (main.dart):
///   `unawaited(runManifestSyncIfEnabled(db: appDb));` — runApp() is
///   called immediately afterward. flag=false / non-debug build paths
///   exit without any I/O before runApp, so the startup sequence is
///   truly identical to PR-B2 in those cases (v0.2 #1 R1#1 + R2#P2:
///   v0.1 mistakenly awaited prefs.getInstance() in front of runApp,
///   incurring ~10–50 ms shared_prefs platform-channel cost on every
///   cold start regardless of flag value).
Future<void> runManifestSyncIfEnabled({
  required AppDatabase db,
  ContentPackageServiceFactory? serviceFactory,
}) async {
  // Layer 1: release/profile dead-code-eliminate
  if (!kDebugMode) return;

  try {
    // Layer 2: feature flag
    final prefs = await SharedPreferences.getInstance();
    if (!LocalSettingsService(prefs).manifestSyncEnabled) return;

    // Layer 3: actually run sync
    final cacheDir = await getApplicationDocumentsDirectory();
    final info = await PackageInfo.fromPlatform();
    final factory = serviceFactory ??
        ((cd, d) => ContentPackageService(cacheDir: cd, db: d));
    final service = factory(cacheDir, db);
    final result = await service.syncIfNeeded(appVersion: info.version);

    // v0.2 #6 R1#4 review-adopted: hasFailure and hasChanges may co-exist
    // (mixed: some installed, some failed). A single combined log keeps
    // the installed/replaced counts visible alongside the failure detail —
    // an if/elif split would have hidden them in the hasFailure branch.
    if (result.hasFailure || result.hasChanges) {
      debugPrint('[main] manifest sync result: '
          'installed=${result.installed.length} '
          'replaced=${result.replaced.length} '
          'skipped=${result.skipped.length} '
          'failed=${result.failed.length} '
          'failureReasons=${result.failureReasons} '
          'manifestError=${result.manifestError ?? "(null)"}');
    }
  } catch (e, st) {
    debugPrint('[main] manifest sync threw: $e\n$st');
  }
}

/// App entry point with local database initialization.
///
/// v0.3.0 P1: WordbookLoader populates word_entries / word_book_assignments /
/// example_sentences for ALL bundled books (CET-4 / ZK / GK). The legacy
/// `AssetWordLoader → cached_words` path is gone (drift v10 dropped
/// `cached_words`); CET-4 now flows through the same canonical content
/// layer as ZK / GK.
///
/// All loaders are idempotent — safe to call every launch (gated on
/// `preset_wordbooks.content_version`).
///
/// Need #11 (build-time): EnrichmentBootstrap runs in the BACKGROUND
/// (fire-and-forget) after the first frame paints. It checks word_forms
/// count and, if essentially empty, streams `assets/forms/*.jsonl` into
/// the 3 enrichment tables. The user sees the app load instantly; the
/// 其他形式 / 近反义词 / 常见词组 modules light up as soon as the import
/// catches up. Failures are silent — UI just shows empty modules.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.initialize();

  final appDb = AppDatabase();

  // v0.3.0 P1: unified content layer for all preset books.
  // Each loadIfNeeded check skips work when content_version matches.
  final wordbookLoader = WordbookLoader(db: appDb);
  await wordbookLoader.loadIfNeeded('book-001'); // CET-4
  await wordbookLoader.loadIfNeeded('zk');       // 中考
  await wordbookLoader.loadIfNeeded('gk');       // 高考

  // Need #11/#12 (Bug 1 follow-up) — bootstrap is now AWAITED, not
  // fire-and-forget. The seed is a tiny, fast SQLite copy (~9 MB →
  // ATTACH + INSERT-SELECT) and finishes in well under a second on
  // real hardware. Awaiting guarantees the very first frame of
  // StudyPage already has the 4 enrichment modules' data — users
  // never have to manually trigger anything.
  //
  // We bound the wait at 5s with a timeout so a corrupted seed file
  // can't lock the app at splash; on timeout we fall through to
  // launching the UI and the catch-all inside ensurePopulated already
  // logs the failure for diagnosis.
  try {
    await EnrichmentBootstrap(driftDb: appDb)
        .ensurePopulated()
        .timeout(const Duration(seconds: 5));
  } on TimeoutException {
    debugPrint('[main] enrichment bootstrap timed out after 5s — '
        'launching UI anyway; check for slow disk / corrupt seed.');
  } catch (e, st) {
    debugPrint('[main] enrichment bootstrap threw: $e\n$st');
  }

  // PR-B3 Day 3 v0.2: manifest sync — three-layer guard (kDebugMode +
  // flag + sync) all run inside the helper as a fire-and-forget. runApp
  // is called immediately; flag=false / non-debug → helper returns
  // without touching prefs/disk → startup sequence is truly identical to
  // PR-B2 in those cases (v0.2 #1 R1#1 + R2#P2 review-adopted).
  unawaited(runManifestSyncIfEnabled(db: appDb));

  runApp(const MeowApp());
}
