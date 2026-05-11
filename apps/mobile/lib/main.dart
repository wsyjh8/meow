import 'dart:async';
import 'dart:io';

// PR-C/PR-B5: removed `import 'package:flutter/foundation.dart'` — was for
// kDebugMode in the Layer 1 guard which is now removed. debugPrint is
// re-exported by flutter/material.dart.
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/api/api_client.dart';
import 'core/auth/auth.dart';
import 'core/device/device_info_service.dart';
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

/// PR-B3 Day 3 v0.2 / PR-C v0.3 PR-B5 merged: manifest sync 启动异步 hook.
/// Two-layer guard, any failure returns silently:
///
///   Layer 1 (LocalSettingsService.manifestSyncEnabled; was Layer 2 before
///            PR-C/PR-B5 removed the kDebugMode Layer 1)
///     PR-B4: default true since real CDN (Tencent COS) + S1=β mobile
///     baseUrl env-aware via dart-define. Users can opt out via the
///     settings page switch.
///
///   Layer 2 (ContentPackageService.syncIfNeeded, fire-and-forget; was
///            Layer 3 before PR-C/PR-B5)
///     `appVersion: PackageInfo.fromPlatform().version` is the real
///     pubspec version so server's `min_app_version` filter engages.
///
/// PR-C/PR-B5 removed the original Layer 1 `if (!kDebugMode) return;` guard
/// because: (a) real CDN URLs reach production clients via pipeline.py +
/// COS, (b) S1=β makes 4 mobile services env-aware via apiV1Base, so
/// release builds also auto-sync on startup. Existing dev users who opted
/// out keep their `false` SharedPreferences value (Layer 1 still respects
/// it).
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
  // PR-C/PR-B5: PR-B3 Day 3 Layer 1 `if (!kDebugMode) return;` guard removed.
  // Real CDN (Tencent COS) is in place + S1=β makes 4 mobile service
  // `apiV1Base` env-aware via dart-define, so release/profile builds also
  // auto-sync. Release 用户整链路 (manifest + api + audio + pronunciation)
  // 走 production 真域名 (subject to scope §0.5.1 R4-2/R4-3 caveat for
  // audio asset bytes — still 留 PR-D).

  try {
    // Layer 2 (was Layer 2; renumbered to Layer 1 in PR-C): feature flag
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

  // 需求 23 Phase B/C: bootstrap auth BEFORE database init.
  // plan-023-C-v2 §4.0 target startup order:
  //   1. SharedPreferences
  //   2. AuthBootstrap (resolves current user_id; may call /auth/guest)
  //   3. ApiClient.setDefaultHttpClient
  //   4. AuthStorage.markFreshInstallIfNeeded  (Phase C PR-C-α)
  //   5. LocalDatabase.initialize() (now no-op for schema, drift owns it)
  //   6. AppDatabase() + force drift to run onCreate / onUpgrade
  //   7. PRAGMA assert: word_records.user_id column exists (fail-fast)
  //   8. WordbookLoader / EnrichmentBootstrap / manifest sync / runApp
  //
  // The reordering is required because Phase C makes drift the SOLE
  // schema owner (plan-023-C-v2 D1 + §4.0). Before C, LocalDatabase's
  // `_createTables` raced ahead of drift on fresh install, creating the
  // 5 legacy tables WITHOUT user_id; drift's `IF NOT EXISTS` then
  // skipped them and the device permanently ran on the wrong schema.
  // Now `_createTables` is a no-op and drift's `m.createAll()` /
  // `onUpgrade` is the single source of truth — but we must trigger it
  // here in main() before any DAO is exercised so the assert holds.
  final prefs = await SharedPreferences.getInstance();
  final authBoot = await AuthBootstrap.run(
    prefs: prefs,
    deviceInfoService: DeviceInfoService(),
  );

  // 需求 23 Phase B fix-1: install the auth-aware http.Client as the
  // process-wide default. Every existing `ApiClient()` zero-arg call site
  // (~18 locations) now auto-injects Authorization headers and reports
  // 401s back to AuthController. AUTH_ENFORCE=true切流前置.
  ApiClient.setDefaultHttpClient(authBoot.httpClient);

  // 需求 23 Phase C PR-C-α (plan-023-C-v2 §4.0 / D3): classify this
  // device as fresh install vs upgrade, seed pending-migration flags
  // exactly once. Idempotent — subsequent launches short-circuit. Must
  // run BEFORE drift opens because drift v13 onUpgrade reads the same
  // `auth_current_user_id` SP key for backfill (plan §5).
  await authBoot.storage.markFreshInstallIfNeeded();

  await LocalDatabase.initialize();

  final appDb = AppDatabase();

  // 需求 23 Phase C PR-C-α (plan-023-C-v2 §4.0): drift's onCreate /
  // onUpgrade is normally lazy — it fires on the first real query. We
  // force it eagerly now so:
  //   1. fresh install: drift's `m.createAll()` builds all 20 tables
  //      including the 5 legacy tables WITH user_id (LocalDatabase no
  //      longer pre-creates them sans user_id).
  //   2. v12 → v13 upgrade path: backfill runs against the current
  //      `auth_current_user_id` AuthBootstrap just resolved, NOT against
  //      a stale value an earlier query might have read.
  //   3. PRAGMA assert below has something to assert against.
  await appDb.customSelect('SELECT 1').get();

  // Fail-fast: after drift open, every user-scoped legacy table must
  // carry the `user_id` column. If this assert trips, schema migration
  // silently broke and continuing would write rows that never partition
  // properly. Detecting at boot turns a subtle data bug into a loud crash.
  await _assertUserIdColumns(appDb);

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

  runApp(MeowApp(authController: authBoot.controller));
}

/// 需求 23 Phase C PR-C-α (plan-023-C-v2 §4.0): fail-fast schema
/// assert. After drift's onCreate / onUpgrade has run, every
/// user-scoped legacy table MUST carry a `user_id` column — otherwise
/// the v13 migration broke (or someone re-introduced the pre-C race
/// where raw sqflite built the table before drift). Throwing here turns
/// what would be a quiet "writes go to a table without user_id"
/// data-loss bug into an immediate crash.
///
/// Probes `word_records` because it's the most-written table; if its
/// schema is right the migration completed correctly for the rest
/// (the v13 onUpgrade processes all 9 user-scoped tables in the same
/// `if (from < 13)` block).
Future<void> _assertUserIdColumns(AppDatabase db) async {
  final cols = await db
      .customSelect('PRAGMA table_info(word_records)')
      .get();
  final hasUserId = cols.any((r) => r.read<String>('name') == 'user_id');
  if (!hasUserId) {
    throw StateError(
      '[main] schema invariant violated: word_records.user_id missing. '
      'drift v13 migration likely failed silently — refuse to continue '
      'or per-user data will be written without partition tag.',
    );
  }
}
