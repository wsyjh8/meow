// PR-B3 Day 3 v0.2 #13 (R2#P2 #5) review-adopted: helper unit test
// covering the manifest sync wire-up.
//
// `runManifestSyncIfEnabled` has three guards:
//   Layer 1: kDebugMode  — test environment runs as debug build, so this
//                          is true; we cannot exercise the false branch
//                          here (it's a Dart compile-time const). That
//                          path is verified by sub-smoke A on a real
//                          release/profile build.
//   Layer 2: manifestSyncEnabled flag (default false)
//   Layer 3: ContentPackageService.syncIfNeeded
//
// These tests cover Layer 2 (flag short-circuit) and Layer 3 (service is
// invoked + receives the real appVersion from PackageInfo) — the
// regressions we worry about are "switch added but didn't wire to flag"
// and "appVersion silently null again".

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meow_mobile/core/manifest/content_package_service.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';
import 'package:meow_mobile/core/storage/local_settings_service.dart';
import 'package:meow_mobile/main.dart' show runManifestSyncIfEnabled;

/// Mock for path_provider so `getApplicationDocumentsDirectory()` resolves
/// in headless tests without the platform channel. Same pattern used by
/// `test/enrichment_bootstrap_test.dart`.
class _StubPathProvider extends PathProviderPlatform {
  _StubPathProvider(this.docsPath);
  final String docsPath;
  @override
  Future<String?> getApplicationDocumentsPath() async => docsPath;
}

class _RecordingService implements ContentPackageService {
  int syncCalls = 0;
  String? lastAppVersion;

  @override
  Future<SyncResult> syncIfNeeded({String? appVersion}) async {
    syncCalls++;
    lastAppVersion = appVersion;
    return const SyncResult(
      installed: [],
      replaced: [],
      skipped: [],
      failed: [],
      failureReasons: {},
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late _RecordingService fakeService;
  late Directory tempDocs;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fakeService = _RecordingService();
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'meow_mobile',
      packageName: 'com.example.meow_mobile',
      version: '0.0.1',
      buildNumber: '1',
      buildSignature: '',
    );
    // Stub path_provider so getApplicationDocumentsDirectory() resolves
    // in headless tests (real plugin needs a platform channel).
    tempDocs = await Directory.systemTemp.createTemp('manifest_hook_test_');
    PathProviderPlatform.instance = _StubPathProvider(tempDocs.path);
  });
  tearDown(() async {
    await db.close();
    if (await tempDocs.exists()) await tempDocs.delete(recursive: true);
  });

  group('runManifestSyncIfEnabled (PR-B3 Day 3 + PR-B4)', () {
    test(
        'flag=false (explicit, post-PR-B4): short-circuits before invoking service',
        () async {
      // PR-B4: default flipped from false to true. To exercise the
      // short-circuit branch we must EXPLICITLY persist false now —
      // setMockInitialValues({}) (the setUp default) would yield true
      // and trip the syncIfNeeded path.
      SharedPreferences.setMockInitialValues({
        'settings_manifest_sync_enabled': false,
      });

      await runManifestSyncIfEnabled(
        db: db,
        serviceFactory: (Directory _, AppDatabase __) => fakeService,
      );
      expect(fakeService.syncCalls, 0,
          reason: 'explicit flag=false must NOT invoke '
              'ContentPackageService (user opt-out preserved)');
      expect(fakeService.lastAppVersion, isNull);
    });

    test(
        'flag=true (PR-B4 default): invokes syncIfNeeded with real appVersion '
        'from PackageInfo (covers PR-B4 default + PR-B3 Day 3 v0.2 #3)',
        () async {
      // PR-B4: setMockInitialValues({}) (from setUp) means no key set →
      // LocalSettingsService.manifestSyncEnabled returns the new
      // default=true, so the explicit setManifestSyncEnabled(true) here
      // is redundant but kept as documentation that this case was
      // originally written for the PR-B3 default=false world.
      final prefs = await SharedPreferences.getInstance();
      await LocalSettingsService(prefs).setManifestSyncEnabled(true);

      await runManifestSyncIfEnabled(
        db: db,
        serviceFactory: (Directory _, AppDatabase __) => fakeService,
      );

      expect(fakeService.syncCalls, 1,
          reason: 'flag=true (default in PR-B4) must invoke '
              'ContentPackageService.syncIfNeeded');
      // PR-B3 Day 3 v0.2 #3: appVersion must be the real pubspec version,
      // not null — server's min_app_version filter depends on it.
      expect(fakeService.lastAppVersion, '0.0.1',
          reason: 'appVersion must come from PackageInfo.fromPlatform(), '
              'not be null');
    });
  });
}
