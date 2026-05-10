/// 需求 23 Phase B — Auth types (mirror of apps/api/src/auth/auth.types.ts).
///
/// Mobile-side wire shapes for /auth/* endpoint responses. Server is the
/// source of truth — see backend types for canonical definitions.
library;

enum AccountType {
  guest,
  registered,
}

AccountType accountTypeFromString(String? value) {
  switch (value) {
    case 'registered':
      return AccountType.registered;
    case 'guest':
    default:
      return AccountType.guest;
  }
}

String accountTypeToString(AccountType t) =>
    t == AccountType.registered ? 'registered' : 'guest';

/// Sanitized user shape returned by /auth/* endpoints. Never includes
/// password_hash or any other credential field.
class AuthUser {
  final String id;
  final String? email;
  final String nickname;
  final AccountType accountType;
  final String createdAt;

  const AuthUser({
    required this.id,
    required this.email,
    required this.nickname,
    required this.accountType,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      nickname: (json['nickname'] as String?) ?? 'Learner',
      accountType: accountTypeFromString(json['account_type'] as String?),
      createdAt: (json['created_at'] as String?) ?? '',
    );
  }

  AuthUser copyWith({
    String? id,
    String? email,
    String? nickname,
    AccountType? accountType,
    String? createdAt,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      accountType: accountType ?? this.accountType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// /auth/* response shape: { user, token, expires_at }
class AuthResponse {
  final AuthUser user;
  final String token;

  /// Seconds-since-epoch when the token expires. Convenience for clients.
  final int expiresAt;

  const AuthResponse({
    required this.user,
    required this.token,
    required this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
      expiresAt: (json['expires_at'] as num).toInt(),
    );
  }
}

/// AuthController exposes one of these high-level lifecycle states.
enum AuthStatus {
  /// AuthBootstrap has not yet resolved the initial user (cold start).
  loading,

  /// Guest user without server-issued token — offline placeholder
  /// (`pending-local-guest`). Operations fall back to local-only mode.
  offlineGuest,

  /// Authenticated as a guest (server-issued token).
  authedGuest,

  /// Authenticated as a registered user.
  authedRegistered,

  /// Token expired (401). UI must prompt re-login. NEVER auto-switch to
  /// guest — see plan-023-用户系统与用户数据隔离-v2.md §6.4 / D11.
  tokenExpired,
}
