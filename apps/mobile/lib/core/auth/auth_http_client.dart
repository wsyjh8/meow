/// 需求 23 Phase B — Auth-aware http.BaseClient interceptor.
///
/// Wraps any `http.Client` and:
///   1. Injects `Authorization: Bearer <token>` on every outgoing request
///      when a token is in storage. Idempotent — if request already has
///      the header set, it is preserved.
///   2. On 401 response, asks AuthController to transition to
///      `tokenExpired` (UI then prompts re-login per plan v2 §6.4 / D11).
///   3. (需求 23 Phase C PR-C-γ / plan §4.5) captures
///      `controller.epoch` at request issue time and validates it on
///      response. If the epoch has incremented mid-flight (account
///      switch / logout), throws [RequestStaleException] so the caller
///      can drop the result — preventing cross-user data from leaking
///      into the just-switched-to user's session.
///
/// Existing controllers (ApiClient etc.) take this in their constructor
/// instead of building their own `http.Client`. Construction without an
/// auth client falls back to a plain `http.Client` (legacy / test path).
library;

import 'package:http/http.dart' as http;

import 'auth_controller.dart';
import 'auth_storage.dart';

/// Thrown by [AuthHttpClient.send] when the bound user changes
/// mid-flight (login / bind / logout). The HTTP request itself may have
/// succeeded, but the response belongs to a now-stale auth context and
/// must not be applied to the current user's state.
///
/// Callers typically catch and either retry or drop the result — UI
/// layers usually drop because the AuthScope rebuild has already
/// re-triggered a fresh fetch with the new user.
class RequestStaleException implements Exception {
  /// The epoch captured when the request was sent.
  final int issueEpoch;

  /// The current epoch at response time.
  final int currentEpoch;

  /// Optional request URL (header / first line) for log context.
  final String? requestPath;

  const RequestStaleException({
    required this.issueEpoch,
    required this.currentEpoch,
    this.requestPath,
  });

  @override
  String toString() =>
      'RequestStaleException(issueEpoch=$issueEpoch, '
      'currentEpoch=$currentEpoch'
      '${requestPath != null ? ', path=$requestPath' : ''})';
}

class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;
  final AuthStorage _storage;
  final AuthController _controller;

  AuthHttpClient({
    required AuthStorage storage,
    required AuthController controller,
    http.Client? inner,
  })  : _storage = storage,
        _controller = controller,
        _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Skip Authorization injection if caller already set one (e.g.
    // AuthApi /auth/me which passes the token explicitly during
    // bootstrap, before AuthStorage has the value committed).
    if (!request.headers.containsKey('Authorization')) {
      final token = await _storage.readToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    // PR-C-γ §4.5: capture epoch at issue time so we can detect a
    // mid-flight account switch when the response comes back. Plan v2
    // §6.6 partition guarantee depends on this — without it, response
    // body for user A could be `setState`'d into user B's UI after a
    // logout / bind that happened in between.
    final issueEpoch = _controller.epoch;

    final response = await _inner.send(request);

    if (response.statusCode == 401) {
      // Token rejected by server — surface to AuthController so UI can
      // prompt re-login. plan v2 §6.4 / D11: DO NOT auto-switch to guest.
      // Fire-and-forget so we don't delay the caller's response handling.
      // ignore: unawaited_futures
      _controller.markTokenExpired();
    }

    // Epoch check AFTER 401 handling so a 401 still marks tokenExpired
    // even if the user switched mid-flight (the 401 is the more
    // important signal — UI re-prompts regardless of who the response
    // was "for"). For all other status codes, throw early so callers
    // skip applying the body. We also defensively drain the response
    // stream so the socket can be reused even though we discard the body.
    final currentEpoch = _controller.epoch;
    if (currentEpoch != issueEpoch) {
      // Drain so the underlying socket isn't blocked. Best effort —
      // small body for most API responses; large bodies will simply
      // consume a bit of bandwidth before being dropped.
      // ignore: unawaited_futures
      response.stream.drain<void>();
      throw RequestStaleException(
        issueEpoch: issueEpoch,
        currentEpoch: currentEpoch,
        requestPath: request.url.path,
      );
    }

    return response;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
