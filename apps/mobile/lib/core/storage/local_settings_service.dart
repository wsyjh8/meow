import 'package:shared_preferences/shared_preferences.dart';

/// P3.1 Phase 1 — Local settings persistence service.
///
/// Uses SharedPreferences for lightweight key-value settings.
/// Settings layer is SEPARATE from business progress data.
///
/// This is device-side persistence, NOT a replacement for active BR/API truth.
class LocalSettingsService {
  final SharedPreferences _prefs;

  LocalSettingsService(this._prefs);

  // ==================== Keys ====================
  static const _keyDailyGoal = 'settings_daily_goal';
  static const _keySoundEnabled = 'settings_sound_enabled';
  static const _keyTheme = 'settings_theme';
  static const _keyNotificationTime = 'settings_notification_time';
  static const _keyDesiredRetention = 'settings_desired_retention';
  static const _keyActiveWordbook = 'settings_active_wordbook';
  static const _keyManifestSyncEnabled = 'settings_manifest_sync_enabled';

  // ==================== Daily Goal ====================
  int get dailyGoal => _prefs.getInt(_keyDailyGoal) ?? 20;
  Future<bool> setDailyGoal(int value) => _prefs.setInt(_keyDailyGoal, value);

  // ==================== Sound ====================
  bool get soundEnabled => _prefs.getBool(_keySoundEnabled) ?? true;
  Future<bool> setSoundEnabled(bool value) => _prefs.setBool(_keySoundEnabled, value);

  // ==================== Theme ====================
  String get theme => _prefs.getString(_keyTheme) ?? 'light';
  Future<bool> setTheme(String value) => _prefs.setString(_keyTheme, value);

  // ==================== Desired Retention (FSRS) ====================
  /// FSRS desired retention rate. Default 0.9, range [0.85, 0.95].
  /// Higher = more review but stronger memory.
  /// Lower = less review but higher forgetting risk.
  double get desiredRetention =>
      _prefs.getDouble(_keyDesiredRetention) ?? 0.9;
  Future<bool> setDesiredRetention(double value) =>
      _prefs.setDouble(_keyDesiredRetention, value.clamp(0.85, 0.95));

  // ==================== Notification Time ====================
  /// Stored as "HH:mm" string. Default: "09:00".
  String get notificationTime => _prefs.getString(_keyNotificationTime) ?? '09:00';
  Future<bool> setNotificationTime(String value) => _prefs.setString(_keyNotificationTime, value);

  // ==================== Active Wordbook ====================
  /// Which wordbook the user is currently studying.
  /// 'book-001' = CET-4 (default), 'zk' = 中考, 'gk' = 高考.
  String get activeWordbook =>
      _prefs.getString(_keyActiveWordbook) ?? 'book-001';
  Future<bool> setActiveWordbook(String slug) =>
      _prefs.setString(_keyActiveWordbook, slug);

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
      _prefs.getBool(_keyManifestSyncEnabled) ?? true;
  Future<bool> setManifestSyncEnabled(bool value) =>
      _prefs.setBool(_keyManifestSyncEnabled, value);

  /// Clear all settings (for testing / debug only).
  Future<bool> clearAll() => _prefs.clear();
}
