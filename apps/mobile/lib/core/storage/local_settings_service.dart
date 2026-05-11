import 'package:shared_preferences/shared_preferences.dart';

/// P3.1 Phase 1 — Local settings persistence service.
///
/// Uses SharedPreferences for lightweight key-value settings.
/// Settings layer is SEPARATE from business progress data.
///
/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.3): per-user partition.
/// All 7 settings_* keys are prefixed with `u_<userId>_` so user A's
/// daily goal can't leak into user B's session. Construction now
/// requires a userId; main.dart resolves it from AuthBootstrap and
/// passes it through.
class LocalSettingsService {
  final SharedPreferences _prefs;
  final String _userId;

  LocalSettingsService(this._prefs, {required String userId})
      : _userId = userId;

  // ==================== Key prefixing helpers ====================

  String _k(String suffix) => 'u_${_userId}_$suffix';

  static const _kDailyGoalSuffix = 'settings_daily_goal';
  static const _kSoundEnabledSuffix = 'settings_sound_enabled';
  static const _kThemeSuffix = 'settings_theme';
  static const _kNotificationTimeSuffix = 'settings_notification_time';
  static const _kDesiredRetentionSuffix = 'settings_desired_retention';
  static const _kActiveWordbookSuffix = 'settings_active_wordbook';
  static const _kManifestSyncEnabledSuffix = 'settings_manifest_sync_enabled';

  /// Suffixes used by [SpMigrator] to migrate pre-C global keys to
  /// per-user namespaces. Keeping the list here keeps the prefix scheme
  /// and the migration contract co-located.
  static const List<String> migratableKeySuffixes = [
    _kDailyGoalSuffix,
    _kSoundEnabledSuffix,
    _kThemeSuffix,
    _kNotificationTimeSuffix,
    _kDesiredRetentionSuffix,
    _kActiveWordbookSuffix,
    _kManifestSyncEnabledSuffix,
  ];

  // ==================== Daily Goal ====================
  int get dailyGoal => _prefs.getInt(_k(_kDailyGoalSuffix)) ?? 20;
  Future<bool> setDailyGoal(int value) =>
      _prefs.setInt(_k(_kDailyGoalSuffix), value);

  // ==================== Sound ====================
  bool get soundEnabled => _prefs.getBool(_k(_kSoundEnabledSuffix)) ?? true;
  Future<bool> setSoundEnabled(bool value) =>
      _prefs.setBool(_k(_kSoundEnabledSuffix), value);

  // ==================== Theme ====================
  String get theme => _prefs.getString(_k(_kThemeSuffix)) ?? 'light';
  Future<bool> setTheme(String value) =>
      _prefs.setString(_k(_kThemeSuffix), value);

  // ==================== Desired Retention (FSRS) ====================
  /// FSRS desired retention rate. Default 0.9, range [0.85, 0.95].
  /// Higher = more review but stronger memory.
  /// Lower = less review but higher forgetting risk.
  double get desiredRetention =>
      _prefs.getDouble(_k(_kDesiredRetentionSuffix)) ?? 0.9;
  Future<bool> setDesiredRetention(double value) =>
      _prefs.setDouble(_k(_kDesiredRetentionSuffix), value.clamp(0.85, 0.95));

  // ==================== Notification Time ====================
  /// Stored as "HH:mm" string. Default: "09:00".
  String get notificationTime =>
      _prefs.getString(_k(_kNotificationTimeSuffix)) ?? '09:00';
  Future<bool> setNotificationTime(String value) =>
      _prefs.setString(_k(_kNotificationTimeSuffix), value);

  // ==================== Active Wordbook ====================
  /// Which wordbook the user is currently studying.
  /// 'book-001' = CET-4 (default), 'zk' = 中考, 'gk' = 高考.
  String get activeWordbook =>
      _prefs.getString(_k(_kActiveWordbookSuffix)) ?? 'book-001';
  Future<bool> setActiveWordbook(String slug) =>
      _prefs.setString(_k(_kActiveWordbookSuffix), slug);

  // ==================== Manifest Sync (PR-B3 + PR-B4) ====================
  /// PR-B3 feature flag — when true, app fires async manifest sync on
  /// startup (PR-B3 Day 3 wires it into main.dart).
  ///
  /// **PR-B4: default flipped to `true`.** Dev/profile builds now
  /// auto-sync on cold start without the user toggling the debug switch.
  /// Release builds still dead-code-eliminate the entire hook via
  /// main.dart's `kDebugMode` guard, so the default only takes effect in
  /// debug/profile builds; release behavior is byte-for-byte identical
  /// to PR-B3 (and PR-B2, since PR-B3 default was false). Removing the
  /// `kDebugMode` guard is deferred to PR-B5, after PR-C lands real CDN
  /// URLs in pipeline.py — until then production manifest API skips all
  /// `file://` rows and would return an empty packages list anyway.
  ///
  /// Failure of sync NEVER blocks UI; flag exists purely to gate the
  /// fire-and-forget call in main.dart.
  bool get manifestSyncEnabled =>
      _prefs.getBool(_k(_kManifestSyncEnabledSuffix)) ?? true;
  Future<bool> setManifestSyncEnabled(bool value) =>
      _prefs.setBool(_k(_kManifestSyncEnabledSuffix), value);

  /// Clear THIS USER's settings (for testing / debug only). Other users'
  /// keys are untouched — the previous `_prefs.clear()` was a partition
  /// leak that would wipe everyone's settings.
  Future<void> clearAll() async {
    for (final suffix in migratableKeySuffixes) {
      await _prefs.remove(_k(suffix));
    }
  }
}
