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
import 'package:meow_mobile/core/api/api_client.dart';
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

    test('offline (network throws) without token → offlineGuest state + persisted placeholder',
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
      expect(controller.currentUserId, AuthStorage.pendingLocalGuestUserId);
      // Phase B fix-5: placeholder is PERSISTED to SP per plan v2 §6.3
      // so drift migration (Phase C) has a stable user_id source.
      expect(storage.readUserId(), AuthStorage.pendingLocalGuestUserId);
      expect(storage.readAccountType(), AccountType.guest);
    });

    test('Phase B fix-4: network error with registered token → keeps registered status (NOT tokenExpired)',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );
      await storage.writeToken('tok-net');
      await storage.writeUserId('user-existing');
      await storage.writeAccountType(AccountType.registered);

      // Server returns 503 (5xx, not 401) — transient network failure.
      final fakeClient = _FakeHttpClient(
        statusFn: (r) => 503,
        bodyFn: (r) => '{"statusCode":503,"message":"upstream timeout"}',
      );
      final api = AuthApi(client: fakeClient);
      final controller = AuthController(storage: storage, api: api);

      await controller.bootstrap(deviceId: 'dev-net');

      // Registered user with network error should NOT be told "登录已过期".
      expect(controller.status, AuthStatus.authedRegistered);
      // Token is preserved (might still work on next retry); not cleared.
      expect(await storage.readToken(), 'tok-net');
    });
  });

  group('AuthController actions', () {
    test('logout without bootstrap → offlineGuest (no deviceId to re-attach)',
        () async {
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
      // No bootstrap → no _boundDeviceId. logout falls back to offlineGuest.
      await controller.logout();

      expect(controller.status, AuthStatus.offlineGuest);
      expect(await storage.readToken(), isNull);
      expect(storage.readUserId(), isNull);
    });

    test('Phase B fix-3: logout AFTER bootstrap re-attaches as guest', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );

      // Programmable responses: bootstrap calls /auth/guest → returns guest;
      // login calls /auth/login → returns registered;
      // logout calls /auth/logout then /auth/guest (re-attach).
      var callIndex = 0;
      final fakeClient = _FakeHttpClient(
        statusFn: (r) => 200,
        bodyFn: (r) {
          callIndex++;
          if (r.url.path.endsWith('/auth/logout')) {
            return '{"status":"ok"}';
          }
          if (r.url.path.endsWith('/auth/login')) {
            return json.encode({
              'user': {
                'id': 'user-reg-1',
                'email': 'x@b.com',
                'nickname': 'X',
                'account_type': 'registered',
                'created_at': '2026-05-10T00:00:00Z',
              },
              'token': 'tok-reg',
              'expires_at': 9999999999,
            });
          }
          // /auth/guest — first call returns guest-1, second (post-logout)
          // returns guest-2 (different device wouldn't change ID, but for
          // the test we just want a distinct token to prove re-attach).
          return json.encode({
            'user': {
              'id': callIndex == 1 ? 'guest-1' : 'guest-2',
              'email': null,
              'nickname': 'Learner',
              'account_type': 'guest',
              'created_at': '2026-05-10T00:00:00Z',
            },
            'token': callIndex == 1 ? 'tok-g1' : 'tok-g2',
            'expires_at': 9999999999,
          });
        },
      );
      final api = AuthApi(client: fakeClient);
      final controller = AuthController(storage: storage, api: api);

      // Bootstrap as guest, then login as registered, then logout.
      await controller.bootstrap(deviceId: 'dev-abc');
      expect(controller.status, AuthStatus.authedGuest);
      await controller.login(email: 'x@b.com', password: 'pw12345678');
      expect(controller.status, AuthStatus.authedRegistered);

      await controller.logout();

      // After logout: re-attached as guest (NOT offlineGuest).
      expect(controller.status, AuthStatus.authedGuest);
      expect(await storage.readToken(), 'tok-g2');
      expect(storage.readUserId(), 'guest-2');
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

  _registerIntegrationTests();

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

/// Phase B fix-7 (评审采纳): integration test proving ApiClient actually
/// uses the AuthHttpClient set via setDefaultHttpClient. Review 1+2 P1
/// flagged that AuthHttpClient was an "orphan class" with 18 ApiClient
/// call sites still using bare http. This test exercises the wiring end
/// to end so a future regression that disconnects them is caught.
void _registerIntegrationTests() {
  group('ApiClient ↔ AuthHttpClient wiring (Phase B fix-7)', () {
    tearDown(() {
      // Clean up the process-wide default so other tests don't inherit
      // an AuthHttpClient + stale storage.
      ApiClient.setDefaultHttpClient(null);
    });

    test(
        'ApiClient with no explicit client picks up the default AuthHttpClient '
        '→ Authorization header is injected', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );
      await storage.writeToken('tok-integration-1');

      final inner = _FakeHttpClient(
        statusFn: (r) => 200,
        bodyFn: (r) => json.encode({
          'current_book_name': 'CET-4',
          'today_new_target': 20,
          'today_new_completed': 0,
          'today_review_target': 0,
          'today_review_pending': 0,
          'today_review_completed': 0,
          'daily_goal_status': 'not_started',
          'active_review_group_id': null,
          'active_review_group_status': null,
          'active_review_group_remaining': 0,
          'sync_status': 'healthy',
        }),
      );
      final controller = AuthController(
        storage: storage,
        api: AuthApi(client: inner),
      );
      final authClient = AuthHttpClient(
        storage: storage,
        controller: controller,
        inner: inner,
      );

      // The wiring under test: install authClient as process-wide default.
      ApiClient.setDefaultHttpClient(authClient);

      // Call ApiClient with NO explicit client arg. This is the shape
      // used by ~18 existing call sites (`ApiClient()` zero-arg).
      final client = ApiClient(baseUrl: 'http://x.test/api/v1');
      await client.getToday();

      // Critical assertion: the underlying request carried the token.
      expect(inner.sent.length, 1);
      expect(
        inner.sent[0].headers['Authorization'],
        'Bearer tok-integration-1',
        reason: 'ApiClient zero-arg must inherit the auth-aware default '
            'http.Client; otherwise AUTH_ENFORCE=true would 401 every '
            '/me/* call. Review 1+2 P1 hot-fix.',
      );
    });

    test('explicit client: still wins over default', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = AuthStorage(
        secure: const FlutterSecureStorage(),
        prefs: prefs,
      );
      await storage.writeToken('tok-default');

      final defaultInner = _FakeHttpClient(
        statusFn: (r) => 200,
        bodyFn: (r) => '{}',
      );
      final controller = AuthController(
        storage: storage,
        api: AuthApi(client: defaultInner),
      );
      ApiClient.setDefaultHttpClient(AuthHttpClient(
        storage: storage,
        controller: controller,
        inner: defaultInner,
      ));

      // Explicit override should bypass the default (used in tests).
      final explicitInner = _FakeHttpClient(
        statusFn: (r) => 200,
        bodyFn: (r) => json.encode({
          'current_book_name': 'CET-4',
          'today_new_target': 20,
          'today_new_completed': 0,
          'today_review_target': 0,
          'today_review_pending': 0,
          'today_review_completed': 0,
          'daily_goal_status': 'not_started',
          'active_review_group_id': null,
          'active_review_group_status': null,
          'active_review_group_remaining': 0,
          'sync_status': 'healthy',
        }),
      );
      final client = ApiClient(
        baseUrl: 'http://x.test/api/v1',
        client: explicitInner,
      );
      await client.getToday();

      expect(explicitInner.sent.length, 1);
      expect(defaultInner.sent, isEmpty,
          reason: 'default must not be used when explicit client passed');
    });
  });
}
