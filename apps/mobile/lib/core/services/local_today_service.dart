import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart' show TodayState;
import '../memory/fsrs_service.dart';
import '../storage/drift/app_database.dart';
import '../storage/local_database.dart';
import '../storage/local_settings_service.dart';
import '../storage/repositories/daily_checkin_repository.dart';

/// Local-first service that builds [TodayState] entirely from device data.
///
/// Replaces the cloud `GET /me/today` endpoint for core learning features.
/// Cloud code is retained (not deleted) for future cloud+local verification.
///
/// Data sources:
///   - [LocalSettingsService] → dailyGoal (SharedPreferences)
///   - [LocalDatabase] → countTodayNewCompleted(), getMasteredWordIds()
///   - [FsrsService] → countTodayReviewCompleted(), listDueCards()
///   - [DailyCheckinRepository] → check-in & streak
///
/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.4): user-scoped via injected
/// userId + [DailyCheckinRepository]. The PR-C-α SP-bridge fallback in
/// `checkIn()` is replaced by explicit construction-time userId.
class LocalTodayService {
  final SharedPreferences _prefs;
  final LocalDatabase _localDb;
  final FsrsService _fsrs;
  final DailyCheckinRepository _checkins;
  final LocalSettingsService _settings;
  final String _userId;

  LocalTodayService({
    required SharedPreferences prefs,
    required LocalDatabase localDb,
    required FsrsService fsrs,
    required DailyCheckinRepository checkins,
    required LocalSettingsService settings,
    required String userId,
  })  : _prefs = prefs,
        _localDb = localDb,
        _fsrs = fsrs,
        _checkins = checkins,
        _settings = settings,
        _userId = userId;

  /// Convenience constructor for callers that have the wider services
  /// but no repo. Builds the DailyCheckinRepository from [driftDb] and
  /// the LocalSettingsService from [prefs].
  factory LocalTodayService.forUser({
    required SharedPreferences prefs,
    required LocalDatabase localDb,
    required FsrsService fsrs,
    required AppDatabase driftDb,
    required String userId,
  }) {
    return LocalTodayService(
      prefs: prefs,
      localDb: localDb,
      fsrs: fsrs,
      checkins: DailyCheckinRepository(db: driftDb, userId: userId),
      settings: LocalSettingsService(prefs, userId: userId),
      userId: userId,
    );
  }

  // Exposed for legacy callers that read prefs directly; can be removed
  // once those sites use the settings field.
  SharedPreferences get prefs => _prefs;

  /// Build today's state entirely from local data.
  Future<TodayState> getTodayState() async {
    final dailyGoal = _settings.dailyGoal;

    // New words
    final newCompleted = await _localDb.countTodayNewCompleted(_userId);

    // Review words
    int reviewCompleted = 0;
    int reviewTarget = 0;
    try {
      reviewCompleted = await _fsrs.countTodayReviewCompleted();
      final dueCards = await _fsrs.listDueCards(nowLocal: DateTime.now());
      // Target = due cards remaining + already reviewed today
      reviewTarget = dueCards.length + reviewCompleted;
    } catch (_) {}

    // Daily goal status
    final String dailyGoalStatus;
    if (dailyGoal > 0 && newCompleted >= dailyGoal) {
      dailyGoalStatus = 'completed';
    } else if (newCompleted > 0) {
      dailyGoalStatus = 'in_progress';
    } else {
      dailyGoalStatus = 'not_started';
    }

    // Check-in & streak (PR-C-β: per-user via repository).
    final hasCheckedIn = await _hasCheckedInToday();
    final streak = await _getCurrentStreak();
    final learningDay = newCompleted > 0;

    return TodayState.offline(
      todayNewTarget: dailyGoal,
      todayNewCompleted: newCompleted,
      todayReviewCompleted: reviewCompleted,
    ).copyWithLocal(
      todayReviewTarget: reviewTarget,
      dailyGoalStatus: dailyGoalStatus,
      hasCheckedInToday: hasCheckedIn,
      currentStreak: streak,
      learningDayToday: learningDay,
      syncStatus: 'local',
    );
  }

  /// Check in for today. Writes to local daily_checkins table for this user.
  /// Returns true if this is a new check-in (not already done today).
  Future<bool> checkIn() async {
    final today = _todayDateString();
    final existing = await _checkins.findByDate(today);
    if (existing != null) return false; // already checked in

    await _checkins.insertCheckin(
      date: today,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    return true;
  }

  /// Check if user has checked in today (user-scoped).
  Future<bool> _hasCheckedInToday() async {
    final today = _todayDateString();
    return (await _checkins.findByDate(today)) != null;
  }

  /// Calculate current streak by scanning daily_checkins backwards from today.
  /// User-scoped via the repository.
  Future<int> _getCurrentStreak() async {
    final dates = await _checkins.listDatesDesc();
    if (dates.isEmpty) return 0;

    int streak = 0;
    var checkDate = DateTime.now();

    for (final date in dates) {
      final expected = _dateString(checkDate);
      if (date == expected) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  static String _todayDateString() => _dateString(DateTime.now());

  static String _dateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

/// Extension on TodayState to allow local overrides of specific fields.
extension TodayStateLocalOverride on TodayState {
  /// Create a copy with local-only field overrides.
  /// Used by LocalTodayService to fill in fields that TodayState.offline()
  /// doesn't support directly.
  TodayState copyWithLocal({
    int? todayReviewTarget,
    String? dailyGoalStatus,
    bool? hasCheckedInToday,
    int? currentStreak,
    bool? learningDayToday,
    String? syncStatus,
  }) {
    return TodayState(
      currentBookName: currentBookName,
      todayNewTarget: todayNewTarget,
      todayNewCompleted: todayNewCompleted,
      todayReviewTarget: todayReviewTarget ?? this.todayReviewTarget,
      todayReviewPending: todayReviewPending,
      todayReviewCompleted: todayReviewCompleted,
      dailyGoalStatus: dailyGoalStatus ?? this.dailyGoalStatus,
      activeReviewGroupId: activeReviewGroupId,
      activeReviewGroupStatus: activeReviewGroupStatus,
      activeReviewGroupRemaining: activeReviewGroupRemaining,
      syncStatus: syncStatus ?? this.syncStatus,
      lastRewardSettlement: lastRewardSettlement,
      hasCheckedInToday: hasCheckedInToday ?? this.hasCheckedInToday,
      learningDayToday: learningDayToday ?? this.learningDayToday,
      currentStreak: currentStreak ?? this.currentStreak,
      streakBasisType: streakBasisType,
      sessionStartedToday: sessionStartedToday,
      sessionValidToday: sessionValidToday,
      todayPrimaryAction: todayPrimaryAction,
      reviewSummary: reviewSummary,
    );
  }
}
