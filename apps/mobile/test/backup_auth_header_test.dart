/// 需求 23 Phase D PR-D-α (plan-023-D-v2 §4.1, Review 2 P0-1): verify
/// that mobile backup upload + restore requests route through the
/// injected `http.Client` (typically the AuthHttpClient AuthBootstrap
/// installed) so they carry `Authorization: Bearer <token>` headers.
///
/// Pre-D the services called `http.post` / `http.get` statically and
/// shipped requests WITHOUT any auth header. Under permissive mode the
/// server fell through to DEV_FALLBACK_USER_ID and silently rewrote
/// every user's backup to the same bucket. PR-D-α plumbs a `client:`
/// constructor arg through both services and defaults it to
/// `ApiClient.defaultHttpClient` (the AuthHttpClient AuthBootstrap
/// hands over).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:meow_mobile/core/api/api_client.dart';
import 'package:meow_mobile/core/auth/auth.dart';
import 'package:meow_mobile/core/storage/backup_restore_service.dart';
import 'package:meow_mobile/core/storage/backup_upload_service.dart';
import 'package:meow_mobile/core/storage/local_database.dart';
import 'package:meow_mobile/core/storage/local_settings_service.dart';
import 'package:meow_mobile/core/storage/snapshot_export_service.dart';

class _SecureChannelStub {
  final Map<String, String> store = {};
  void install() {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      final args = call.arguments as Map?;
      final key = args?['key'] as String?;
      switch (call.method) {
        case 'read':
          return key == null ? null : store[key];
        case 'write':
          if (key != null) store[key] = args!['value'] as String;
          return null;
        case 'delete':
          if (key != null) store.remove(key);
          return null;
        default:
          return null;
      }
    });
  }
}

/// Recording http.Client that captures every outbound request — lets
/// us assert headers without an HTTP server.
class _CapturingClient extends http.BaseClient {
  final List<http.BaseRequest> sent = [];
  int Function(http.BaseRequest) statusFn;
  Map<String, dynamic> Function(http.BaseRequest) bodyFn;

  _CapturingClient({
    required this.statusFn,
    required this.bodyFn,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    sent.add(request);
    final body = utf8.encode(json.encode(bodyFn(request)));
    return http.StreamedResponse(
      Stream.value(body),
      statusFn(request),
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // PR-D-α restore test uses LocalDatabase.initializeForTesting(),
  // which opens sqflite. Wire the FFI factory once at suite start.
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final secureStub = _SecureChannelStub();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureStub.store.clear();
    secureStub.install();
    ApiClient.setDefaultHttpClient(null);
  });

  tearDown(() {
    ApiClient.setDefaultHttpClient(null);
  });

  test(
      'BackupUploadService.upload routes through ApiClient.defaultHttpClient '
      '(AuthHttpClient adds Authorization header)', () async {
    // Plant a token in secure storage so AuthHttpClient injects it.
    secureStub.store['auth_access_token'] = 'tok-abc';

    final prefs = await SharedPreferences.getInstance();
    final storage = AuthStorage(
      secure: const FlutterSecureStorage(),
      prefs: prefs,
    );
    final controller = AuthController(storage: storage, api: AuthApi());

    // Inner stub that returns the server's `succeeded` shape.
    final inner = _CapturingClient(
      statusFn: (_) => 200,
      bodyFn: (_) => {
        'status': 'succeeded',
        'backup_id': 'bk-test-001',
        'uploaded_at': '2026-05-11T00:00:00Z',
        'schema_version': 'p3_2_snapshot_v1',
      },
    );
    // Wire AuthHttpClient on top of the capturing inner.
    final authClient = AuthHttpClient(
      storage: storage,
      controller: controller,
      inner: inner,
    );
    ApiClient.setDefaultHttpClient(authClient);

    // Construct the service with NO explicit `client:` — picks up the
    // installed default exactly like production main.dart does.
    final upload = BackupUploadService(
      baseUrl: 'http://api.test/api/v1',
      prefs: prefs,
      userId: 'user-d-alpha',
    );

    final exportResult = SnapshotExportResult(
      status: ExportStatus.success,
      snapshotJson: '{"schema_version":"p3_2_snapshot_v1"}',
      snapshotMap: const {'schema_version': 'p3_2_snapshot_v1'},
      schemaVersion: 'p3_2_snapshot_v1',
      exportedAt: '2026-05-11T00:00:00Z',
      byteLength: 64,
    );
    final result = await upload.upload(exportResult);

    expect(result.isSuccess, isTrue, reason: result.errorCode);
    expect(inner.sent.length, 1);
    final req = inner.sent.single;
    expect(req.headers['Authorization'], 'Bearer tok-abc');
    expect(req.method, 'POST');
    expect(req.url.path.endsWith('/me/backup'), isTrue);
  });

  test(
      'BackupRestoreService.preCheck + restore both inject Authorization '
      'via injected client', () async {
    secureStub.store['auth_access_token'] = 'tok-xyz';

    final prefs = await SharedPreferences.getInstance();
    final storage = AuthStorage(
      secure: const FlutterSecureStorage(),
      prefs: prefs,
    );
    final controller = AuthController(storage: storage, api: AuthApi());

    // Server replies with a valid restorable snapshot for both fetches.
    final inner = _CapturingClient(
      statusFn: (_) => 200,
      bodyFn: (req) {
        // Two calls (preCheck + restore) — both hit the same endpoint.
        return {
          'status': 'ok',
          'schema_version': 'p3_2_snapshot_v1',
          'uploaded_at': '2026-05-11T00:00:00Z',
          'snapshot': {
            'schema_version': 'p3_2_snapshot_v1',
            'device': {'device_id': 'dev-1', 'device_model': 'Pixel'},
            'progress': {
              'word_records': [],
            },
          },
        };
      },
    );
    final authClient = AuthHttpClient(
      storage: storage,
      controller: controller,
      inner: inner,
    );
    ApiClient.setDefaultHttpClient(authClient);

    // Need a real LocalDatabase for the restore path even though we
    // don't exercise the SQL writes (snapshot has empty word_records).
    await LocalDatabase.deleteDatabase_();
    // Use the test-only legacy schema bootstrap so the v13 columns
    // exist even though no drift connection opens here.
    addTearDown(() async {
      await LocalDatabase.instance.close();
    });

    // The restore service doesn't actually need drift open for an
    // empty snapshot — `LocalDatabase.instance` access only happens
    // if `_applySnapshot` writes. Skip init: the construction itself
    // doesn't touch the DB.
    final restore = BackupRestoreService(
      baseUrl: 'http://api.test/api/v1',
      settings: LocalSettingsService(prefs, userId: 'user-d-alpha'),
      db: await LocalDatabase.initializeForTesting(),
      userId: 'user-d-alpha',
    );

    final preCheck = await restore.preCheck();
    expect(preCheck.status, RestorePreCheckStatus.restorable,
        reason: 'stubbed snapshot should pre-check as restorable');
    expect(inner.sent.length, 1);
    expect(inner.sent[0].headers['Authorization'], 'Bearer tok-xyz');
    expect(inner.sent[0].method, 'GET');
    expect(inner.sent[0].url.path.endsWith('/me/backup/latest/snapshot'),
        isTrue);

    // Now actually run restore — second authenticated GET.
    final result = await restore.restore();
    expect(result.isSuccess, isTrue, reason: result.errorMessage);
    expect(inner.sent.length, 2);
    expect(inner.sent[1].headers['Authorization'], 'Bearer tok-xyz');
  });

  test(
      'explicit client: arg wins over ApiClient.defaultHttpClient (test '
      'isolation hook)', () async {
    // Make sure ApiClient.defaultHttpClient is set to something
    // distinguishable, then verify the explicit arg overrides it.
    final wrongDefault = _CapturingClient(
      statusFn: (_) => 500,
      bodyFn: (_) => {'status': 'wrong-default'},
    );
    ApiClient.setDefaultHttpClient(wrongDefault);

    final rightExplicit = _CapturingClient(
      statusFn: (_) => 200,
      bodyFn: (_) => {
        'status': 'succeeded',
        'backup_id': 'bk-explicit',
        'uploaded_at': '2026-05-11T00:00:00Z',
        'schema_version': 'p3_2_snapshot_v1',
      },
    );

    final prefs = await SharedPreferences.getInstance();
    final upload = BackupUploadService(
      baseUrl: 'http://api.test/api/v1',
      prefs: prefs,
      userId: 'user-explicit',
      client: rightExplicit,
    );

    final result = await upload.upload(SnapshotExportResult(
      status: ExportStatus.success,
      snapshotJson: '{}',
      snapshotMap: const {},
      schemaVersion: 'p3_2_snapshot_v1',
      exportedAt: '2026-05-11T00:00:00Z',
      byteLength: 2,
    ));

    expect(result.isSuccess, isTrue);
    expect(wrongDefault.sent, isEmpty,
        reason: 'explicit client must bypass the installed default');
    expect(rightExplicit.sent.length, 1);
  });
}
