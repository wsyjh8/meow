/// 需求 23 Phase B — Auth-aware http.BaseClient interceptor.
///
/// Wraps any `http.Client` and:
///   1. Injects `Authorization: Bearer <token>` on every outgoing request
///      when a token is in storage. Idempotent — if request already has
///      the header set, it is preserved.
///   2. On 401 response, asks AuthController to transition to
///      `tokenExpired` (UI then prompts re-login per plan v2 §6.4 / D11).
///
/// Existing controllers (ApiClient etc.) take this in their constructor
/// instead of building their own `http.Client`. Construction without an
/// auth client falls back to a plain `http.Client` (legacy / test path).
library;

import 'package:http/http.dart' as http;

import 'auth_controller.dart';
import 'auth_storage.dart';

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

    final response = await _inner.send(request);

    if (response.statusCode == 401) {
      // Token rejected by server — surface to AuthController so UI can
      // prompt re-login. plan v2 §6.4 / D11: DO NOT auto-switch to guest.
      // Fire-and-forget so we don't delay the caller's response handling.
      // ignore: unawaited_futures
      _controller.markTokenExpired();
    }

    return response;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
