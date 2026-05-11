/// 需求 23 Phase B — Auth credential storage.
///
/// Two-tier persistence per sp-keys-audit v1.1:
///   - Token (credential, sensitive) → flutter_secure_storage
///     (Android Keystore / iOS Keychain).
///   - user_id, account_type, pending-migration flags (non-sensitive
///     metadata) → SharedPreferences.
///
/// References:
///   - docs/design/plan-023-用户系统与用户数据隔离-v2.md §7.4
///   - docs/design/audits/sp-keys-audit.md §1.3a / §1.3b
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_types.dart';

class AuthStorage {
  static const _kTokenKey = 'auth_access_token';

  // SharedPreferences keys (non-sensitive metadata)
  static const _spUserId = 'auth_current_user_id';
  static const _spAccountType = 'auth_account_type';
  // β.9 will introduce these pending flags for cross-storage migration
  // bookkeeping (drift / sqflite / SP namespace). Phase B does not
  // exercise them yet but the keys are reserved.
  static const _spPendingSpMigration = 'auth_pending_sp_migration';
  static const _spPendingDriftMigration = 'auth_pending_local_drift_migration';
  static const _spPendingSqfliteMigration =
      'auth_pending_local_sqflite_migration';
  static const _spFreshInstallMarkerDone =
      'auth_fresh_install_marker_done';

  /// Placeholder user_id used when the app starts offline and the server
  /// hasn't issued a guest token yet. plan v2 §6.3 single-ID design.
  static const pendingLocalGuestUserId = 'pending-local-guest';

  /// SP keys probed by [markFreshInstallIfNeeded] to detect "this device
  /// already has pre-C-build user data" (plan-023-C-v2 §4.0 / D3). Two
  /// representative keys are enough — both `progress_*` and `settings_*`
  /// are populated only after the user actually does something in the
  /// pre-C app, so absence means truly fresh install.
  static const _legacyDetectionKeys = <String>[
    'settings_daily_goal',
    'progress_word_records',
  ];

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;

  AuthStorage({
    required FlutterSecureStorage secure,
    required SharedPreferences prefs,
  })  : _secure = secure,
        _prefs = prefs;

  /// Factory that initializes both backends. Use in startup flow.
  static Future<AuthStorage> open(SharedPreferences prefs) async {
    // FlutterSecureStorage defaults already use the latest crypto on
    // Android (custom AES-GCM via Jetpack-Security migration path); the
    // legacy `encryptedSharedPreferences: true` flag was deprecated and
    // is no-op since plugin v10. Default constructor is correct.
    return AuthStorage(
      secure: const FlutterSecureStorage(),
      prefs: prefs,
    );
  }

  // ========== Token (secure storage) ==========

  Future<String?> readToken() async {
    try {
      return await _secure.read(key: _kTokenKey);
    } catch (e) {
      // Secure storage failures (e.g. emulator without Keystore) — return
      // null so the app falls back to "no token / guest" instead of
      // crashing. We re-throw on write so the caller can react if write
      // is unavailable.
      return null;
    }
  }

  Future<void> writeToken(String token) =>
      _secure.write(key: _kTokenKey, value: token);

  Future<void> clearToken() => _secure.delete(key: _kTokenKey);

  // ========== Non-sensitive metadata (SharedPreferences) ==========

  String? readUserId() => _prefs.getString(_spUserId);

  Future<bool> writeUserId(String userId) =>
      _prefs.setString(_spUserId, userId);

  Future<bool> clearUserId() => _prefs.remove(_spUserId);

  AccountType readAccountType() =>
      accountTypeFromString(_prefs.getString(_spAccountType));

  Future<bool> writeAccountType(AccountType type) =>
      _prefs.setString(_spAccountType, accountTypeToString(type));

  Future<bool> clearAccountType() => _prefs.remove(_spAccountType);

  // ========== Pending migration flags (Phase C will exercise) ==========

  bool readPendingSpMigration() =>
      _prefs.getBool(_spPendingSpMigration) ?? false;

  Future<bool> writePendingSpMigration(bool v) =>
      _prefs.setBool(_spPendingSpMigration, v);

  bool readPendingDriftMigration() =>
      _prefs.getBool(_spPendingDriftMigration) ?? false;

  Future<bool> writePendingDriftMigration(bool v) =>
      _prefs.setBool(_spPendingDriftMigration, v);

  bool readPendingSqfliteMigration() =>
      _prefs.getBool(_spPendingSqfliteMigration) ?? false;

  Future<bool> writePendingSqfliteMigration(bool v) =>
      _prefs.setBool(_spPendingSqfliteMigration, v);

  // ========== Phase C: fresh-install detection ==========

  /// 需求 23 Phase C PR-C-α (plan-023-C-v2 §4.0 / D3): classify this
  /// device as **fresh install** vs **existing user upgrading to a C
  /// build** exactly once, and pre-seed the three pending-migration
  /// flags accordingly.
  ///
  /// Detection signal: any pre-existing user-scoped SP key (probed via
  /// [_legacyDetectionKeys]) means we're an upgrade and the SP / drift /
  /// sqflite migration paths will need to run when their PRs land
  /// (PR-C-β / PR-C-γ). Absence means truly fresh install — no
  /// migration needed, flags stay false.
  ///
  /// Idempotent via [_spFreshInstallMarkerDone]: subsequent calls
  /// short-circuit so a successful β migration that flips
  /// [_spPendingSpMigration] back to false isn't re-toggled to true on
  /// the next launch.
  ///
  /// Call site: main.dart, AFTER AuthBootstrap (which writes
  /// `auth_current_user_id`) and BEFORE LocalDatabase.initialize() /
  /// drift open. Drift v13 onUpgrade reads `auth_current_user_id` for
  /// backfill (plan-023-C-v2 §5).
  Future<void> markFreshInstallIfNeeded() async {
    if (_prefs.getBool(_spFreshInstallMarkerDone) ?? false) return;

    final hasLegacyData = _legacyDetectionKeys.any(_prefs.containsKey);

    await writePendingSpMigration(hasLegacyData);
    await writePendingDriftMigration(hasLegacyData);
    await writePendingSqfliteMigration(hasLegacyData);

    await _prefs.setBool(_spFreshInstallMarkerDone, true);
  }

  /// Testing-only: did [markFreshInstallIfNeeded] run on this storage?
  bool readFreshInstallMarkerDone() =>
      _prefs.getBool(_spFreshInstallMarkerDone) ?? false;

  /// PR-C-α transitional bridge for services that write to user-scoped
  /// drift tables but don't yet thread userId through their public API
  /// (FsrsService / ReviewLogService / SessionStore / LocalTodayService).
  /// Reads `auth_current_user_id` directly from SharedPreferences — the
  /// same SP key AuthBootstrap populates at startup — and falls back to
  /// [pendingLocalGuestUserId] when SP is empty (offline cold-start) or
  /// the platform channel is unavailable (test envs without
  /// TestWidgetsFlutterBinding).
  ///
  /// **PR-C-β will retire this method** in favour of repository classes
  /// (plan-023-C-v2 §4.4) where each table-owning repository is
  /// constructed with an explicit userId. Grep callers via this method's
  /// name to find migration sites.
  static Future<String> readBoundUserIdOrPlaceholder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_spUserId);
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {
      // SharedPreferences platform channel not registered (some test
      // setups skip TestWidgetsFlutterBinding) — fall through.
    }
    return pendingLocalGuestUserId;
  }

  // ========== Convenience: full logout ==========

  /// Clear token + user_id + account_type. Pending flags retained so
  /// migration bookkeeping survives a logout cycle. **Never** touches
  /// SQLite / drift / progress data — that's plan v2 §6.5 (D7) discipline.
  Future<void> clearSession() async {
    await clearToken();
    await clearUserId();
    await clearAccountType();
  }
}
