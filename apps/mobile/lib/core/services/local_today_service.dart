import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart' show TodayState;
import '../memory/fsrs_service.dart';
import '../storage/drift/app_database.dart';
import '../storage/local_database.dart';
import '../storage/local_settings_service.dart';

/// Local-first service that builds [TodayState] entirely from device data.
///
/// Replaces the cloud `GET /me/today` endpoint for core learning features.
/// Cloud code is retained (not deleted) for future cloud+local verification.
///
/// Data sources:
///   - [LocalSettingsService] → dailyGoal (SharedPreferences)
///   - [LocalDatabase] → countTodayNewCompleted(), getMasteredWordIds()
///   - [FsrsService] → countTodayReviewCompleted(), listDueCards()
///   - [AppDatabase] → daily_checkins table (streak, check-in)
class LocalTodayService {
  final SharedPreferences _prefs;
  final LocalDatabase _localDb;
  final FsrsService _fsrs;
  final AppDatabase _driftDb;

  LocalTodayService({
    required SharedPreferences prefs,
    required LocalDatabase localDb,
    required FsrsService fsrs,
    required AppDatabase driftDb,
  })  : _prefs = prefs,
        _localDb = localDb,
        _fsrs = fsrs,
        _driftDb = driftDb;

  /// Build today's state entirely from local data.
  Future<TodayState> getTodayState() async {
    final settings = LocalSettingsService(_prefs);
    final dailyGoal = settings.dailyGoal;

    // New words
    final newCompleted = await _localDb.countTodayNewCompleted();

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

    // Check-in & streak
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

  /// Check in for today. Writes to local daily_checkins table.
  /// Returns true if this is a new check-in (not already done today).
  Future<bool> checkIn() async {
    final today = _todayDateString();
    final existing = await (_driftDb.select(_driftDb.dailyCheckins)
          ..where((t) => t.date.equals(today)))
        .getSingleOrNull();

    if (existing != null) return false; // already checked in

    await _driftDb.into(_driftDb.dailyCheckins).insert(
      DailyCheckinsCompanion.insert(
        date: today,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
    return true;
  }

  /// Check if user has checked in today.
  Future<bool> _hasCheckedInToday() async {
    final today = _todayDateString();
    final row = await (_driftDb.select(_driftDb.dailyCheckins)
          ..where((t) => t.date.equals(today)))
        .getSingleOrNull();
    return row != null;
  }

  /// Calculate current streak by scanning daily_checkins backwards from today.
  Future<int> _getCurrentStreak() async {
    final rows = await (_driftDb.select(_driftDb.dailyCheckins)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();

    if (rows.isEmpty) return 0;

    int streak = 0;
    var checkDate = DateTime.now();

    for (final row in rows) {
      final expected = _dateString(checkDate);
      if (row.date == expected) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  static String _todayDateString() =>
      _dateString(DateTime.now());

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
