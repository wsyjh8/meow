// PR-B3 Day 2: LocalSettingsService.manifestSyncEnabled — 3 cases.
// PR-B4: default flipped from false to true (dev/profile builds auto-sync;
// release builds still dead-code-eliminate via main.dart kDebugMode guard).
// PR-C-β: LocalSettingsService is now user-scoped — all SP keys are
// prefixed with `u_<userId>_`. Tests use a fixed test userId.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meow_mobile/core/storage/local_settings_service.dart';

void main() {
  const testUserId = 'test-user';

  group('LocalSettingsService.manifestSyncEnabled (PR-B3 + PR-B4 + PR-C-β)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // PR-B4: default is now true (was false in PR-B3). Dev/profile builds
    // auto-sync without user opt-in; release builds dead-code-eliminate
    // the hook regardless of this default via main.dart's kDebugMode guard.
    test('default true (PR-B4: dev/profile auto-sync)', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(
          LocalSettingsService(prefs, userId: testUserId).manifestSyncEnabled,
          isTrue);
    });

    test('set false persists (user can opt out)', () async {
      final prefs = await SharedPreferences.getInstance();
      await LocalSettingsService(prefs, userId: testUserId)
          .setManifestSyncEnabled(false);

      // Re-read via a fresh service instance (still backed by same prefs)
      final reloaded = LocalSettingsService(prefs, userId: testUserId);
      expect(reloaded.manifestSyncEnabled, isFalse,
          reason: 'explicit false must override the new PR-B4 default=true');
    });

    test('set true after opt-out: returns true', () async {
      // PR-B4: simulate a user who previously opted out and now opts back in.
      // PR-C-β: SP keys are now per-user namespaced.
      SharedPreferences.setMockInitialValues({
        'u_${testUserId}_settings_manifest_sync_enabled': false,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(
          LocalSettingsService(prefs, userId: testUserId).manifestSyncEnabled,
          isFalse);

      await LocalSettingsService(prefs, userId: testUserId)
          .setManifestSyncEnabled(true);
      expect(
          LocalSettingsService(prefs, userId: testUserId).manifestSyncEnabled,
          isTrue);
    });

    test('two users have isolated manifestSyncEnabled (PR-C-β partition)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final a = LocalSettingsService(prefs, userId: 'user-a');
      final b = LocalSettingsService(prefs, userId: 'user-b');

      await a.setManifestSyncEnabled(false);
      expect(a.manifestSyncEnabled, isFalse);
      expect(b.manifestSyncEnabled, isTrue,
          reason: 'user-a opt-out must not leak into user-b session');
    });
  });
}
