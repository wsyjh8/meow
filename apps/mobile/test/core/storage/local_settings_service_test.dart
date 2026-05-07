// PR-B3 Day 2 v0.2: LocalSettingsService.manifestSyncEnabled — 3 cases.
//
// Day 2 → Day 3 间隔期: flag 字段实装但仅本测试访问；Day 3 commit 接
// main.dart 启动 hook + settings page 开关（v0.2 #8 R1#6 review-adopted）。

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meow_mobile/core/storage/local_settings_service.dart';

void main() {
  group('LocalSettingsService.manifestSyncEnabled (PR-B3 Day 2)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('default false (PR-B2 之前行为不变)', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(LocalSettingsService(prefs).manifestSyncEnabled, isFalse);
    });

    test('set true persists across reload', () async {
      final prefs = await SharedPreferences.getInstance();
      await LocalSettingsService(prefs).setManifestSyncEnabled(true);

      // Re-read via a fresh service instance (still backed by same prefs)
      final reloaded = LocalSettingsService(prefs);
      expect(reloaded.manifestSyncEnabled, isTrue);
    });

    test('set false then read returns false', () async {
      // Seed with true via initial values, then explicitly flip back.
      SharedPreferences.setMockInitialValues({
        'settings_manifest_sync_enabled': true,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(LocalSettingsService(prefs).manifestSyncEnabled, isTrue);

      await LocalSettingsService(prefs).setManifestSyncEnabled(false);
      expect(LocalSettingsService(prefs).manifestSyncEnabled, isFalse);
    });
  });
}
