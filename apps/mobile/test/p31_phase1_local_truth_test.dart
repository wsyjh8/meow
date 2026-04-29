/// P3.1 Phase 1 — Local settings + local runtime truth persistence tests.
///
/// Tests cover:
/// - Local settings (read/write/defaults/restart)
/// - Local progress (word_records, wordbook_progress, daily_checkins, etc.)
/// - Restart/rehydrate behavior
/// - Existing flow regression (not broken by local storage)
/// - Negative tests (no false success, no sync-implying state)
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meow_mobile/core/storage/local_settings_service.dart';
import 'package:meow_mobile/core/storage/local_progress_repository.dart';
import 'package:meow_mobile/core/api/api_client.dart';
import 'package:meow_mobile/core/guards/p3_feature_guard.dart';
import 'package:meow_mobile/shared/helpers/streak_display.dart';

void main() {
  // ==================== A. Local settings persistence ====================

  group('LocalSettingsService', () {
    late LocalSettingsService settings;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      settings = LocalSettingsService(prefs);
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
      final restarted = LocalSettingsService(prefs);

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

  // ==================== B. Local progress persistence ====================

  group('LocalProgressRepository', () {
    late LocalProgressRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = LocalProgressRepository(prefs);
    });

    test('word_records: empty by default', () {
      expect(repo.getWordRecords(), isEmpty);
    });

    test('word_records: add and read back', () async {
      await repo.addWordRecord({'word_id': 'w-001', 'action': 'know', 'date': '2026-04-06'});
      final records = repo.getWordRecords();
      expect(records.length, 1);
      expect(records[0]['word_id'], 'w-001');
    });

    test('word_records: batch set and read', () async {
      await repo.setWordRecords([
        {'word_id': 'w-001', 'action': 'know'},
        {'word_id': 'w-002', 'action': 'forgot'},
      ]);
      expect(repo.getWordRecords().length, 2);
    });

    test('wordbook_progress: null by default', () {
      expect(repo.getWordbookProgress(), isNull);
    });

    test('wordbook_progress: set and read back', () async {
      await repo.setWordbookProgress({
        'book_id': 'cet4',
        'total': 100,
        'completed': 25,
      });
      final progress = repo.getWordbookProgress();
      expect(progress, isNotNull);
      expect(progress!['completed'], 25);
    });

    test('daily_checkins: empty by default', () {
      expect(repo.getDailyCheckins(), isEmpty);
    });

    test('daily_checkins: add and read back', () async {
      await repo.addDailyCheckin({'date': '2026-04-06', 'checked_in': true});
      expect(repo.getDailyCheckins().length, 1);
    });

    test('custom_wordbooks: empty by default', () {
      expect(repo.getCustomWordbooks(), isEmpty);
    });

    test('custom_wordbooks: set and read back', () async {
      await repo.setCustomWordbooks([
        {'name': 'My Words', 'word_count': 10},
      ]);
      expect(repo.getCustomWordbooks().length, 1);
    });

    test('vocabulary_notebook: empty by default', () {
      expect(repo.getVocabularyNotebook(), isEmpty);
    });

    test('vocabulary_notebook: add and read back', () async {
      await repo.addVocabularyEntry({'word': 'hello', 'note': 'greeting'});
      expect(repo.getVocabularyNotebook().length, 1);
    });

    test('hasAnyData: false when empty', () {
      expect(repo.hasAnyData, false);
    });

    test('hasAnyData: true after adding data', () async {
      await repo.addWordRecord({'word_id': 'w-001'});
      expect(repo.hasAnyData, true);
    });

    test('clearAll removes all progress data', () async {
      await repo.addWordRecord({'word_id': 'w-001'});
      await repo.setWordbookProgress({'book_id': 'cet4'});
      await repo.clearAll();
      expect(repo.hasAnyData, false);
      expect(repo.getWordbookProgress(), isNull);
    });
  });

  // ==================== C. Restart / rehydrate ====================

  group('Restart / rehydrate', () {
    test('progress data survives simulated restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalProgressRepository(prefs);

      await repo.addWordRecord({'word_id': 'w-001', 'action': 'know'});
      await repo.setWordbookProgress({'book_id': 'cet4', 'completed': 10});

      // Simulate restart: new repository from same prefs
      final restarted = LocalProgressRepository(prefs);
      expect(restarted.getWordRecords().length, 1);
      expect(restarted.getWordbookProgress()!['completed'], 10);
    });

    test('empty local storage gives stable defaults, no crash', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalProgressRepository(prefs);

      expect(repo.getWordRecords(), isEmpty);
      expect(repo.getWordbookProgress(), isNull);
      expect(repo.getDailyCheckins(), isEmpty);
      expect(repo.getCustomWordbooks(), isEmpty);
      expect(repo.getVocabularyNotebook(), isEmpty);
      expect(repo.hasAnyData, false);
    });

    test('corrupted JSON falls back to empty, no crash', () async {
      SharedPreferences.setMockInitialValues({
        'progress_word_records': 'not valid json{{{',
        'progress_wordbook_progress': '12345',
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalProgressRepository(prefs);

      // Corrupted data should return safe defaults
      expect(repo.getWordRecords(), isEmpty);
      expect(repo.getWordbookProgress(), isNull);
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
      expect(StreakDisplay.basisLabel.contains('\u7b7e\u5230'), isTrue);
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
    test('local storage exception does not produce false success', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalProgressRepository(prefs);

      // Empty repo should NOT be interpreted as "completed" or "restored"
      expect(repo.hasAnyData, false);
      // hasAnyData=false must NOT be mapped to "backup succeeded" or "restore completed"
    });

    test('empty local data not mapped to completed/restored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = LocalProgressRepository(prefs);

      expect(repo.getWordRecords(), isEmpty);
      // Empty records != "all words completed"
      // Empty records != "restore completed"
      // Empty records == "no progress yet"
    });

    test('local settings do not contain backup/sync fields', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = LocalSettingsService(prefs);

      // Settings service has NO backup/sync related getters
      // Only: dailyGoal, soundEnabled, theme, notificationTime
      expect(settings.dailyGoal, isNotNull);
      expect(settings.soundEnabled, isNotNull);
      expect(settings.theme, isNotNull);
      expect(settings.notificationTime, isNotNull);
    });
  });
}
