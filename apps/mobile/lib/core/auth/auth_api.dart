/// 需求 23 Phase B — Auth HTTP client for /auth/* endpoints.
///
/// Stateless HTTP wrapper. No token storage / state management — that's
/// AuthController's job. Token attachment for /auth/me + /auth/bind happens
/// here as explicit Bearer-header param, since those routes need auth but
/// are themselves part of the auth flow (chicken-and-egg with ApiClient).
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_base.dart';
import 'auth_types.dart';

class AuthApiException implements Exception {
  final int statusCode;
  final String errorCode;
  final String message;

  const AuthApiException({
    required this.statusCode,
    required this.errorCode,
    required this.message,
  });

  @override
  String toString() => '[AuthApiException $statusCode] $errorCode: $message';
}

/// Decode a NestJS error response and produce a typed exception.
/// NestJS exception filter wraps our `{error_code, message}` payload inside
/// a `message` field (the outer envelope is `{statusCode, message: {...}}`).
AuthApiException _decodeError(http.Response response) {
  String errorCode = 'UNKNOWN';
  String message = response.body;
  try {
    final body = json.decode(response.body) as Map<String, dynamic>;
    // Direct shape (custom controller exceptions)
    if (body.containsKey('error_code')) {
      errorCode = body['error_code'] as String? ?? errorCode;
      message = (body['message'] as String?) ?? message;
    } else if (body['message'] is Map) {
      final inner = body['message'] as Map<String, dynamic>;
      errorCode = inner['error_code'] as String? ?? errorCode;
      message = (inner['message'] as String?) ?? message;
    } else if (body['message'] is String) {
      message = body['message'] as String;
    }
  } catch (_) {
    // Non-JSON body: keep raw
  }
  return AuthApiException(
    statusCode: response.statusCode,
    errorCode: errorCode,
    message: message,
  );
}

class AuthApi {
  final String baseUrl;
  final http.Client _client;

  AuthApi({
    this.baseUrl = apiV1Base,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<AuthResponse> register({
    required String email,
    required String password,
    String? nickname,
  }) async {
    final res = await _client.post(
      _uri('/auth/register'),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
      }),
    );
    if (res.statusCode == 200) {
      return AuthResponse.fromJson(
        json.decode(res.body) as Map<String, dynamic>,
      );
    }
    throw _decodeError(res);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      _uri('/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      return AuthResponse.fromJson(
        json.decode(res.body) as Map<String, dynamic>,
      );
    }
    throw _decodeError(res);
  }

  /// Idempotent guest signup by device_id. Server returns the existing
  /// guest user if one already exists for the device.
  Future<AuthResponse> guest({required String deviceId}) async {
    final res = await _client.post(
      _uri('/auth/guest'),
      headers: const {'Content-Type': 'application/json'},
      body: json.encode({'device_id': deviceId}),
    );
    if (res.statusCode == 200) {
      return AuthResponse.fromJson(
        json.decode(res.body) as Map<String, dynamic>,
      );
    }
    throw _decodeError(res);
  }

  /// Same-row guest → registered upgrade. users.id is preserved
  /// (plan v2 §6.2). Caller must hold a guest token.
  Future<AuthResponse> bind({
    required String guestToken,
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      _uri('/auth/bind'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $guestToken',
      },
      body: json.encode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      return AuthResponse.fromJson(
        json.decode(res.body) as Map<String, dynamic>,
      );
    }
    throw _decodeError(res);
  }

  /// Verify a token and fetch the current user payload.
  Future<AuthUser> me({required String token}) async {
    final res = await _client.get(
      _uri('/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return AuthUser.fromJson(json.decode(res.body) as Map<String, dynamic>);
    }
    throw _decodeError(res);
  }

  /// Stateless logout — server has no token blacklist (plan v2 D3).
  /// Endpoint exists so clients have a single "log me out" call site.
  Future<void> logout({required String token}) async {
    final res = await _client.post(
      _uri('/auth/logout'),
      headers: {'Authorization': 'Bearer $token'},
    );
    // 200/401 both acceptable — we're discarding the token anyway.
    if (res.statusCode != 200 && res.statusCode != 401) {
      throw _decodeError(res);
    }
  }

  void close() => _client.close();
}
