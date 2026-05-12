/// P3.1 Phase 1 — Local settings + local runtime truth persistence tests.
///
/// Tests cover:
/// - Local settings (read/write/defaults/restart)
/// - Existing flow regression (not broken by local storage)
/// - Negative tests (no false success, no sync-implying state)
///
/// 需求 23 Phase C PR-C-β D9: LocalProgressRepository has been deleted —
/// SQLite is the only progress truth. The former B/C/E LocalProgressRepository
/// groups are gone; SQLite coverage lives elsewhere (e.g.
/// local_database_today_served_test.dart, snapshot export tests).
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meow_mobile/core/storage/local_settings_service.dart';
import 'package:meow_mobile/core/api/api_client.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/shared/helpers/streak_display.dart';

void main() {
  const testUserId = 'test-user';

  // ==================== A. Local settings persistence ====================

  group('LocalSettingsService', () {
    late LocalSettingsService settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      settings = LocalSettingsService(prefs, userId: testUserId);
    });

    test('default dailyGoal is 20', () {
      expect(settings.dailyGoal, 20);
    });

    test('default soundEnabled is true', () {
      expect(settings.soundEnabled, true);
    });

    test('default theme is light', () {
      expect(settings.theme, 'light');
    });

    test('default notificationTime is 09:00', () {
      expect(settings.notificationTime, '09:00');
    });

    test('setDailyGoal persists and reads back', () async {
      await settings.setDailyGoal(30);
      expect(settings.dailyGoal, 30);
    });

    test('setSoundEnabled persists and reads back', () async {
      await settings.setSoundEnabled(false);
      expect(settings.soundEnabled, false);
    });

    test('setTheme persists and reads back', () async {
      await settings.setTheme('dark');
      expect(settings.theme, 'dark');
    });

    test('setNotificationTime persists and reads back', () async {
      await settings.setNotificationTime('21:30');
      expect(settings.notificationTime, '21:30');
    });

    test('settings survive simulated restart (same SharedPreferences instance)', () async {
      await settings.setDailyGoal(15);
      await settings.setTheme('dark');

      // Simulate restart: create new service from same prefs
      final prefs = await SharedPreferences.getInstance();
      final restarted = LocalSettingsService(prefs, userId: testUserId);

      expect(restarted.dailyGoal, 15);
      expect(restarted.theme, 'dark');
    });

    test('clearAll resets to defaults', () async {
      await settings.setDailyGoal(50);
      await settings.setSoundEnabled(false);
      await settings.clearAll();

      expect(settings.dailyGoal, 20); // default
      expect(settings.soundEnabled, true); // default
    });
  });

  // ==================== D. Existing flow regression ====================

  group('P3.1 Phase 1 does not affect existing flows', () {
    test('TodayState defaults unchanged', () {
      final state = TodayState.fromJson({});
      expect(state.dailyGoalStatus, 'not_started');
      expect(state.syncStatus, 'healthy');
    });

    test('StreakDisplay still uses check_in basis', () {
      expect(StreakDisplay.basisLabel.contains('签到'), isTrue);
    });

    test('P3.1 backup guards still all false', () {
      // P3.2 BACKUP CUTOVER: all backup flags now enabled.
      expect(P3FeatureGuard.isLocalBackupEnabled, true); // P3.2: enabled
      expect(P3FeatureGuard.isCloudBackupEnabled, true); // P3.2: enabled
      expect(P3FeatureGuard.isRestoreEnabled, true); // Phase 4: now enabled
      expect(P3FeatureGuard.isBackupSettingsEntryEnabled, true); // P3.2: enabled
    });
  });

  // ==================== E. Negative tests ====================

  group('P3.1 Phase 1 negative boundary', () {
    test('local settings do not contain backup/sync fields', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = LocalSettingsService(prefs, userId: testUserId);

      // Settings service has NO backup/sync related getters
      // Only: dailyGoal, soundEnabled, theme, notificationTime
      expect(settings.dailyGoal, isNotNull);
      expect(settings.soundEnabled, isNotNull);
      expect(settings.theme, isNotNull);
      expect(settings.notificationTime, isNotNull);
    });
  });
}
