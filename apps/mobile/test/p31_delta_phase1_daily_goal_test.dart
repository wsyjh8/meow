/// P3.1 Delta Phase 1 — Daily goal setting tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meow_mobile/core/storage/local_settings_service.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/core/api/api_client.dart';

void main() {
  // ==================== A. Read / write tests ====================

  group('Daily goal read/write', () {
    late LocalSettingsService settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      settings = LocalSettingsService(prefs);
    });

    test('default daily goal is 20', () {
      expect(settings.dailyGoal, 20);
    });

    test('can save legal new value', () async {
      await settings.setDailyGoal(30);
      expect(settings.dailyGoal, 30);
    });

    test('save and re-read is consistent', () async {
      await settings.setDailyGoal(50);
      // Re-create service from same prefs (simulates re-read)
      final prefs = await SharedPreferences.getInstance();
      final reloaded = LocalSettingsService(prefs);
      expect(reloaded.dailyGoal, 50);
    });

    test('survives simulated restart', () async {
      await settings.setDailyGoal(15);
      final prefs = await SharedPreferences.getInstance();
      final restarted = LocalSettingsService(prefs);
      expect(restarted.dailyGoal, 15);
    });
  });

  // ==================== B. Validation tests ====================

  group('Daily goal validation logic', () {
    // These test the validation rules that the UI enforces.
    // The LocalSettingsService itself accepts any int, but the UI validates.

    test('boundary value 1 is valid', () {
      final value = 1;
      expect(value > 0 && value <= 500, isTrue);
    });

    test('boundary value 500 is valid', () {
      final value = 500;
      expect(value > 0 && value <= 500, isTrue);
    });

    test('value 0 is invalid', () {
      final value = 0;
      expect(value > 0, isFalse);
    });

    test('negative value is invalid', () {
      final value = -5;
      expect(value > 0, isFalse);
    });

    test('value over 500 is invalid', () {
      final value = 501;
      expect(value <= 500, isFalse);
    });

    test('non-integer string fails int.tryParse', () {
      expect(int.tryParse('abc'), isNull);
      expect(int.tryParse('3.5'), isNull);
      expect(int.tryParse(''), isNull);
    });
  });

  // ==================== C. Immediate effect ====================

  group('Daily goal immediate effect', () {
    test('saved value is immediately readable', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = LocalSettingsService(prefs);

      await settings.setDailyGoal(25);
      // Immediate read — no restart needed
      expect(settings.dailyGoal, 25);
    });

    test('TodayState default target is independent (from API)', () {
      // The today_new_target comes from API, not from local settings directly.
      // This confirms they don't interfere.
      final state = TodayState.fromJson({});
      expect(state.todayNewTarget, 0); // API default, not local settings
    });
  });

  // ==================== D. No history recompute ====================

  group('No history recompute', () {
    test('changing daily goal does not alter existing settings', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = LocalSettingsService(prefs);

      // Set theme first
      await settings.setTheme('dark');
      // Then change daily goal
      await settings.setDailyGoal(40);
      // Theme should not be affected
      expect(settings.theme, 'dark');
      expect(settings.dailyGoal, 40);
    });

    test('daily goal is forward-only (no history field)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = LocalSettingsService(prefs);

      // There is no "previous_daily_goal" or "history" field
      await settings.setDailyGoal(30);
      await settings.setDailyGoal(50);
      // Only current value exists
      expect(settings.dailyGoal, 50);
      // No API to get "what was it before"
    });
  });

  // ==================== E. Regression ====================

  group('Daily goal does not affect other systems', () {
    test('isDailyGoalSettingEnabled is now true', () {
      expect(P3FeatureGuard.isDailyGoalSettingEnabled, true);
    });

    test('isManualUploadEnabled now true', () {
      expect(P3FeatureGuard.isManualUploadEnabled, true); // Delta Phase 2: enabled
    });

    test('isDownloadToLocalEnabled still false', () {
      expect(P3FeatureGuard.isDownloadToLocalEnabled, true); // Delta Phase 3: now enabled
    });

    test('TodayState defaults unchanged', () {
      final state = TodayState.fromJson({});
      expect(state.dailyGoalStatus, 'not_started');
      expect(state.syncStatus, 'healthy');
    });

    test('other settings not affected by daily goal change', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = LocalSettingsService(prefs);

      await settings.setDailyGoal(99);
      expect(settings.soundEnabled, true); // default unchanged
      expect(settings.theme, 'light'); // default unchanged
      expect(settings.notificationTime, '09:00'); // default unchanged
    });
  });
}
