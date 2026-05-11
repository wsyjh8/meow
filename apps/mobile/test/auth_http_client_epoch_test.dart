/// 需求 23 Phase C PR-C-γ §4.5: AuthHttpClient epoch-check behaviour.
///
/// Verifies that an in-flight request that races with an account
/// switch (epoch bump on the AuthController) surfaces a
/// [RequestStaleException] when the response arrives.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:meow_mobile/core/auth/auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// http.BaseClient stub that holds the response until [release] is
/// called — lets the test bump the controller's epoch BEFORE the
/// response stream returns.
class _DeferrableHttpClient extends http.BaseClient {
  final Completer<void> gate = Completer<void>();
  int sendCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    sendCount += 1;
    await gate.future;
    final body = utf8.encode('{"ok":true}');
    return http.StreamedResponse(
      Stream.value(body),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  void release() {
    if (!gate.isCompleted) gate.complete();
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

  test(
      'send captures epoch at issue and throws RequestStaleException when '
      'the controller epoch bumps before the response arrives', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = AuthStorage(
      secure: const FlutterSecureStorage(),
      prefs: prefs,
    );

    // We don't need real /auth network calls; just a controller whose
    // epoch we can bump synchronously. Construct without bootstrap.
    final controller = AuthController(
      storage: storage,
      api: AuthApi(),
    );

    final inner = _DeferrableHttpClient();
    final client = AuthHttpClient(
      storage: storage,
      controller: controller,
      inner: inner,
    );

    // Kick off the request — it will block on inner.gate.
    final responseFuture = client.send(
      http.Request('GET', Uri.parse('https://api.example.com/me/today')),
    );

    // Yield so client.send actually reaches inner.send.
    await Future<void>.delayed(Duration.zero);
    expect(inner.sendCount, 1);

    // Simulate an account switch mid-flight: AuthController.logout
    // bumps epoch. We invoke a private path via `markTokenExpired` is
    // not a switch — instead, drive `_commitSession` indirectly by
    // calling `logout()` if we can. But logout makes network calls
    // we don't want; instead use the existing public hook: register
    // is the simplest non-network bump path... Actually all auth flows
    // hit the network. Use direct field bump via a helper: since
    // AuthController extends ChangeNotifier, the simplest mid-test
    // bump is to call `markTokenExpired` (which doesn't bump epoch)
    // — so we need another path.
    //
    // The cleanest test-only path: use AuthController's epoch++ via a
    // simulated session commit. We construct a fake AuthResponse and
    // hand it to a wrapper that does what _commitSession does (write
    // user_id + bump epoch + notify). Since _commitSession is private,
    // emulate the effect through logout() — but logout makes a network
    // call. Skip network by writing storage and calling logout with a
    // pre-cleared token (server logout is best-effort and tolerates
    // network errors silently).
    await storage.clearToken();
    // Force epoch++ via the public `logout()` path. It will try the
    // network and fail silently (no token, no AuthApi configured
    // here), then bump epoch and finally call _attachGuest which will
    // also fail (no deviceId — _boundDeviceId is null because we
    // never bootstrapped). _attachGuest's catch persists the
    // placeholder and sets offlineGuest status. Net effect: epoch++ +
    // we don't care about status.
    final beforeEpoch = controller.epoch;
    await controller.logout();
    expect(controller.epoch, beforeEpoch + 1,
        reason: 'logout must bump epoch');

    // Now release the in-flight response. The send() should detect
    // the epoch mismatch and throw.
    inner.release();

    Object? caught;
    try {
      await responseFuture;
    } catch (e) {
      caught = e;
    }
    expect(caught, isA<RequestStaleException>());
    final stale = caught as RequestStaleException;
    expect(stale.issueEpoch, beforeEpoch);
    expect(stale.currentEpoch, beforeEpoch + 1);
    expect(stale.requestPath, '/me/today');
  });

  test('send returns normally when epoch is unchanged', () async {
    final prefs = await SharedPreferences.getInstance();
    final storage = AuthStorage(
      secure: const FlutterSecureStorage(),
      prefs: prefs,
    );
    final controller = AuthController(storage: storage, api: AuthApi());

    final inner = _DeferrableHttpClient();
    final client = AuthHttpClient(
      storage: storage,
      controller: controller,
      inner: inner,
    );

    final beforeEpoch = controller.epoch;
    inner.release(); // immediately resolve
    final response = await client.send(
      http.Request('GET', Uri.parse('https://api.example.com/healthy')),
    );

    expect(controller.epoch, beforeEpoch,
        reason: 'no auth state change, epoch should not move');
    expect(response.statusCode, 200);
  });
}
