/// 需求 23 Phase B — Auth layer tests
///
/// Covers AuthApi (with mocked http.Client), AuthController bootstrap +
/// state transitions, AuthStorage SP read/write, and AuthHttpClient
/// header injection / 401 dispatch.
///
/// Notes:
///   - flutter_secure_storage is NOT mocked here — tests inject the
///     storage object directly so secure storage isn't exercised.
///   - AuthController.bootstrap network paths are tested via mocked
///     http.Client returning canned JSON.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:meow_mobile/core/auth/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal in-memory FlutterSecureStorage stub. We can't easily mock
/// the plugin via the public API, so we go through MethodChannel.
class _SecureChannelStub {
  final Map<String, String> store = {};

  void install() {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
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
        case 'deleteAll':
        case 'containsKey':
        case 'readAll':
        default:
          return null;
      }
    });
  }
}

/// Fake http.Client that returns canned responses based on URL substrings.
class _FakeHttpClient extends http.BaseClient {
  final List<http.Request> sent = [];
  int Function(http.Request) statusFn;
  String Function(http.Request) bodyFn;

  _FakeHttpClient({
    required this.statusFn,
    required this.bodyFn,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final req = request as http.Request;
    sent.add(req);
    final body = bodyFn(req);
    final stream = Stream.value(utf8.encode(body));
    return http.StreamedResponse(
      stream,
      statusFn(req),
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final secureStub = _SecureChannelStub();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureStub.store.clear();
    secureStub.install();
  });

  group('AuthStorage', () {
    test('readUserId returns null when absent', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );
      expect(storage.readUserId(), isNull);
    });

    test('writeUserId / readUserId round-trip', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );
      await storage.writeUserId('guest-abc');
      expect(storage.readUserId(), 'guest-abc');
    });

    test('account type round-trip', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );
      await storage.writeAccountType(AccountType.registered);
      expect(storage.readAccountType(), AccountType.registered);
      await storage.writeAccountType(AccountType.guest);
      expect(storage.readAccountType(), AccountType.guest);
    });

    test('clearSession clears token + user_id + account_type', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );
      await storage.writeToken('tok-1');
      await storage.writeUserId('u-1');
      await storage.writeAccountType(AccountType.registered);
      await storage.clearSession();
      expect(await storage.readToken(), isNull);
      expect(storage.readUserId(), isNull);
      expect(storage.readAccountType(), AccountType.guest); // default
    });
  });

  group('AuthController bootstrap', () {
    test('cold start without token calls /auth/guest and stores token',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );
      final fakeClient = _FakeHttpClient(
        statusFn: (r) => 200,
        bodyFn: (r) => json.encode({
          'user': {
            'id': 'guest-test-1',
            'email': null,
            'nickname': 'Learner',
            'account_type': 'guest',
            'created_at': '2026-05-10T00:00:00Z',
          },
          'token': 'tok-guest-1',
          'expires_at': 9999999999,
        }),
      );
      final api = AuthApi(client: fakeClient);
      final controller = AuthController(storage: storage, api: api);

      await controller.bootstrap(deviceId: 'dev-abc');

      expect(controller.status, AuthStatus.authedGuest);
      expect(controller.currentUser?.id, 'guest-test-1');
      expect(await storage.readToken(), 'tok-guest-1');
      expect(storage.readUserId(), 'guest-test-1');
      expect(storage.readAccountType(), AccountType.guest);

      // First call should target /auth/guest
      expect(fakeClient.sent.length, 1);
      expect(fakeClient.sent[0].url.path.endsWith('/auth/guest'), isTrue);
    });

    test('existing token + 200 from /auth/me restores authed state',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );
      await storage.writeToken('tok-existing');
      await storage.writeUserId('user-existing');
      await storage.writeAccountType(AccountType.registered);

      final fakeClient = _FakeHttpClient(
        statusFn: (r) => 200,
        bodyFn: (r) => json.encode({
          'id': 'user-existing',
          'email': 'a@b.com',
          'nickname': 'Tester',
          'account_type': 'registered',
          'created_at': '2026-05-09T00:00:00Z',
        }),
      );
      final api = AuthApi(client: fakeClient);
      final controller = AuthController(storage: storage, api: api);

      await controller.bootstrap(deviceId: 'dev-abc');

      expect(controller.status, AuthStatus.authedRegistered);
      expect(controller.currentUser?.email, 'a@b.com');
      expect(fakeClient.sent.length, 1);
      expect(fakeClient.sent[0].url.path.endsWith('/auth/me'), isTrue);
    });

    test('401 on /auth/me → tokenExpired (does NOT auto-switch to guest)',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );
      await storage.writeToken('tok-expired');
      await storage.writeUserId('user-existing');
      await storage.writeAccountType(AccountType.registered);

      final fakeClient = _FakeHttpClient(
        statusFn: (r) => 401,
        bodyFn: (r) => json.encode({
          'statusCode': 401,
          'message': 'Token expired',
        }),
      );
      final api = AuthApi(client: fakeClient);
      final controller = AuthController(storage: storage, api: api);

      await controller.bootstrap(deviceId: 'dev-abc');

      // Critical: state is tokenExpired, NOT offlineGuest. plan v2 §6.4
      expect(controller.status, AuthStatus.tokenExpired);
      // Token wiped, user_id preserved (so drift queries stay valid)
      expect(await storage.readToken(), isNull);
      expect(storage.readUserId(), 'user-existing');
      // currentUser populated with stored id (UI can show "重新登录")
      expect(controller.currentUser?.id, 'user-existing');
    });

    test('offline (network throws) without token → offlineGuest state',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );

      final fakeClient = _FakeHttpClient(
        statusFn: (r) => 500,
        bodyFn: (r) => throw const SocketExceptionLike(),
      );
      final api = AuthApi(client: fakeClient);
      final controller = AuthController(storage: storage, api: api);

      await controller.bootstrap(
        deviceId: 'dev-abc',
        networkTimeout: const Duration(milliseconds: 50),
      );

      expect(controller.status, AuthStatus.offlineGuest);
      // currentUserId placeholder used for downstream local queries
      expect(controller.currentUserId, AuthStorage.pendingLocalGuestUserId);
    });
  });

  group('AuthController actions', () {
    test('logout clears storage and transitions to offlineGuest', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );
      await storage.writeToken('tok-1');
      await storage.writeUserId('u-1');
      await storage.writeAccountType(AccountType.registered);

      final fakeClient = _FakeHttpClient(
        statusFn: (r) => 200,
        bodyFn: (r) => '{"status":"ok"}',
      );
      final api = AuthApi(client: fakeClient);
      final controller = AuthController(storage: storage, api: api);
      // Skip bootstrap; set state manually for the test
      // by using internal _commitSession path via login mock
      // (we don't have direct field setter — just call logout)
      await controller.logout();

      expect(controller.status, AuthStatus.offlineGuest);
      expect(await storage.readToken(), isNull);
      expect(storage.readUserId(), isNull);
    });

    test('epoch increments on session commit and logout', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );

      final fakeClient = _FakeHttpClient(
        statusFn: (r) => 200,
        bodyFn: (r) => json.encode({
          'user': {
            'id': 'u-x',
            'email': 'x@b.com',
            'nickname': 'X',
            'account_type': 'registered',
            'created_at': '2026-05-10T00:00:00Z',
          },
          'token': 'tok-x',
          'expires_at': 9999999999,
        }),
      );
      final api = AuthApi(client: fakeClient);
      final controller = AuthController(storage: storage, api: api);

      final e0 = controller.epoch;
      await controller.login(email: 'x@b.com', password: 'pw12345678');
      final e1 = controller.epoch;
      expect(e1, greaterThan(e0));

      await controller.logout();
      final e2 = controller.epoch;
      expect(e2, greaterThan(e1));
    });
  });

  group('AuthHttpClient interceptor', () {
    test('injects Authorization header when token in storage', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );
      await storage.writeToken('tok-injected');

      final inner = _FakeHttpClient(
        statusFn: (r) => 200,
        bodyFn: (r) => '{}',
      );
      final controller = AuthController(
        storage: storage,
        api: AuthApi(client: inner),
      );
      final auth = AuthHttpClient(
        storage: storage,
        controller: controller,
        inner: inner,
      );

      await auth.get(Uri.parse('http://x.test/api/v1/me/today'));
      expect(inner.sent.length, 1);
      expect(inner.sent[0].headers['Authorization'], 'Bearer tok-injected');
    });

    test('401 from inner client triggers markTokenExpired', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );
      await storage.writeToken('tok-1');
      await storage.writeUserId('u-1');
      await storage.writeAccountType(AccountType.registered);

      final inner = _FakeHttpClient(
        statusFn: (r) => 401,
        bodyFn: (r) => '{}',
      );
      final controller = AuthController(
        storage: storage,
        api: AuthApi(client: inner),
      );
      // Force controller into authed state so markTokenExpired has
      // something to transition from; simulate via login mock setup
      // is unnecessary — markTokenExpired works from any state.

      final auth = AuthHttpClient(
        storage: storage,
        controller: controller,
        inner: inner,
      );
      await auth.get(Uri.parse('http://x.test/api/v1/me/today'));

      // Give the unawaited markTokenExpired a microtask to settle.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.status, AuthStatus.tokenExpired);
      expect(await storage.readToken(), isNull);
    });
  });
}

class SocketExceptionLike implements Exception {
  const SocketExceptionLike();
  @override
  String toString() => 'SocketExceptionLike';
}
