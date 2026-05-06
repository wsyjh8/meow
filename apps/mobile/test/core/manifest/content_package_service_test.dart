// PR-B2 Day 2 v0.2: ContentPackageService unit tests, 6 cases.
//
// Uses fake ManifestClient / DownloadManager / PackageInstaller injected
// into the service. The default installer-shares-db bug (#2) and
// manifest-fetch-error (#12) are explicitly tested.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/manifest/content_package_service.dart';
import 'package:meow_mobile/core/manifest/download_manager.dart';
import 'package:meow_mobile/core/manifest/manifest_client.dart';
import 'package:meow_mobile/core/manifest/package_installer.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

class _FakeManifestClient implements ManifestClient {
  final ManifestResponse Function() responder;
  _FakeManifestClient(this.responder);

  @override
  Future<ManifestResponse> fetchManifest({String? appVersion}) async =>
      responder();

  @override
  String get baseUrl => 'http://fake/';

  @override
  Duration get timeout => const Duration(seconds: 10);
}

class _ThrowingManifestClient implements ManifestClient {
  final Exception err;
  _ThrowingManifestClient(this.err);

  @override
  Future<ManifestResponse> fetchManifest({String? appVersion}) async =>
      throw err;

  @override
  String get baseUrl => 'http://fake/';

  @override
  Duration get timeout => const Duration(seconds: 10);
}

class _FakeDownloadManager implements DownloadManager {
  final Future<File> Function(ManifestPackage pkg) handler;
  _FakeDownloadManager(this.handler);

  @override
  Future<File> downloadPackage(ManifestPackage pkg) => handler(pkg);

  // Other members unused in tests; cast as needed.
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingInstaller implements PackageInstaller {
  final List<String> installed = [];
  _RecordingInstaller();

  @override
  Future<void> install(File gzFile, ManifestPackage pkg) async {
    installed.add(pkg.packageId);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ManifestPackage _pkg({
  String packageId = 'examples-zk@v1',
  String packageName = 'examples-zk',
  String packageKind = 'examples',
  String contentVersion = 'v1',
}) =>
    ManifestPackage(
      packageId: packageId,
      packageName: packageName,
      packageKind: packageKind,
      bookId: 'zk',
      contentVersion: contentVersion,
      fileUrl: 'http://test/$packageId.gz',
      checksumSha256: 'h',
      sizeBytes: 1000,
      compression: 'gzip',
      minAppVersion: '0.0.0',
      releaseId: 'rel-1',
    );

void main() {
  late AppDatabase db;
  late Directory tmpCache;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tmpCache = await Directory.systemTemp.createTemp('cps_test_');
  });
  tearDown(() async {
    await db.close();
    if (await tmpCache.exists()) await tmpCache.delete(recursive: true);
  });

  group('ContentPackageService', () {
    test('happy: 1 examples package, fresh install', () async {
      final installer = _RecordingInstaller();
      final service = ContentPackageService(
        cacheDir: tmpCache,
        db: db,
        manifestClient: _FakeManifestClient(() => ManifestResponse(
              releaseIds: ['rel-1'],
              packages: [_pkg()],
            )),
        downloadManager: _FakeDownloadManager(
          (pkg) async => File('${tmpCache.path}/dummy.gz'),
        ),
        installer: installer,
      );

      final result = await service.syncIfNeeded();

      expect(result.installed, ['examples-zk@v1']);
      expect(result.replaced, isEmpty);
      expect(result.skipped, isEmpty);
      expect(result.failed, isEmpty);
      expect(result.manifestError, isNull);
      expect(installer.installed, ['examples-zk@v1']);
    });

    test('kind filter: audio_meta package skipped, not downloaded',
        () async {
      var downloadCalls = 0;
      final installer = _RecordingInstaller();
      final service = ContentPackageService(
        cacheDir: tmpCache,
        db: db,
        manifestClient: _FakeManifestClient(() => ManifestResponse(
              releaseIds: ['rel-1'],
              packages: [
                _pkg(
                  packageId: 'audio-meta-zk@v1',
                  packageName: 'audio-meta-zk',
                  packageKind: 'audio_meta',
                ),
              ],
            )),
        downloadManager: _FakeDownloadManager((pkg) async {
          downloadCalls++;
          return File('${tmpCache.path}/should-not.gz');
        }),
        installer: installer,
      );

      final result = await service.syncIfNeeded();

      expect(result.skipped, ['audio-meta-zk@v1']);
      expect(result.installed, isEmpty);
      expect(installer.installed, isEmpty);
      expect(downloadCalls, 0,
          reason: 'kind filter must run BEFORE download (R1#5)');
      expect(result.failureReasons['audio-meta-zk@v1'], contains('kind='));
    });

    // Day 2 v0.2 #9: replaced (not "upgraded") covers rollback downgrade
    test('replace: server v2 vs local v1 → replaced', () async {
      // Pre-seed local state with v1.
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

      final installer = _RecordingInstaller();
      final service = ContentPackageService(
        cacheDir: tmpCache,
        db: db,
        manifestClient: _FakeManifestClient(() => ManifestResponse(
              releaseIds: ['rel-1'],
              packages: [
                _pkg(packageId: 'examples-zk@v2', contentVersion: 'v2'),
              ],
            )),
        downloadManager: _FakeDownloadManager(
          (pkg) async => File('${tmpCache.path}/dummy.gz'),
        ),
        installer: installer,
      );

      final result = await service.syncIfNeeded();

      expect(result.replaced, ['examples-zk@v2']);
      expect(result.installed, isEmpty);
      expect(installer.installed, ['examples-zk@v2']);
    });

    test('skip: server v1 == local v1 → skipped, no download', () async {
      await db.into(db.contentPackageStates).insert(
            ContentPackageStatesCompanion.insert(
              packageId: 'examples-zk@v1',
              packageName: 'examples-zk',
              packageKind: 'examples',
              contentVersion: 'v1',
              releaseId: 'rel-1',
              checksumSha256: 'same',
              installedAt: 1,
            ),
          );

      var downloadCalls = 0;
      final service = ContentPackageService(
        cacheDir: tmpCache,
        db: db,
        manifestClient: _FakeManifestClient(() => ManifestResponse(
              releaseIds: ['rel-1'],
              packages: [_pkg()],
            )),
        downloadManager: _FakeDownloadManager((pkg) async {
          downloadCalls++;
          return File('${tmpCache.path}/dummy.gz');
        }),
        installer: _RecordingInstaller(),
      );

      final result = await service.syncIfNeeded();

      expect(result.skipped, ['examples-zk@v1']);
      expect(result.installed, isEmpty);
      expect(result.replaced, isEmpty);
      expect(downloadCalls, 0);
    });

    test('download fails: package in failed[], reason recorded', () async {
      final installer = _RecordingInstaller();
      final service = ContentPackageService(
        cacheDir: tmpCache,
        db: db,
        manifestClient: _FakeManifestClient(() => ManifestResponse(
              releaseIds: ['rel-1'],
              packages: [_pkg()],
            )),
        downloadManager: _FakeDownloadManager(
          (pkg) async => throw DownloadFailedError(
            pkg.packageId,
            'simulated network error',
            3,
          ),
        ),
        installer: installer,
      );

      final result = await service.syncIfNeeded();

      expect(result.failed, ['examples-zk@v1']);
      expect(result.installed, isEmpty);
      expect(result.failureReasons['examples-zk@v1'], contains('network'));
      expect(installer.installed, isEmpty);
      // No state row written on failure → next sync re-downloads.
      expect(await db.select(db.contentPackageStates).get(), isEmpty);
    });

    // Day 2 v0.2 #12: manifest fetch fails → manifestError populated
    test(
        'manifest fetch fails: result.manifestError populated, '
        'hasFailure=true', () async {
      final service = ContentPackageService(
        cacheDir: tmpCache,
        db: db,
        manifestClient: _ThrowingManifestClient(
          ManifestNetworkError('connection refused'),
        ),
        downloadManager: _FakeDownloadManager(
          (pkg) async => fail('download must not be called'),
        ),
        installer: _RecordingInstaller(),
      );

      final result = await service.syncIfNeeded();

      expect(result.manifestError, contains('connection refused'));
      expect(result.installed, isEmpty);
      expect(result.replaced, isEmpty);
      expect(result.failed, isEmpty);
      expect(result.hasFailure, isTrue);
      expect(result.hasChanges, isFalse);
    });
  });
}
