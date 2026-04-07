import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/core/api/api_client.dart';

void main() {
  group('Phase 3 API Client Models', () {
    test('SessionInfo fromJson parses correctly', () {
      final json = <String, dynamic>{
        'session_id': 'sess-001',
        'session_status': 'started',
        'session_validation_status': 'not_started',
        'session_minutes_target': 15,
        'started_at': '2026-04-02T12:00:00Z',
        'effective_learning_count': 0,
        'effective_review_count': 0,
      };

      final session = SessionInfo.fromJson(json);

      expect(session.sessionId, 'sess-001');
      expect(session.sessionStatus, 'started');
      expect(session.sessionValidationStatus, 'not_started');
      expect(session.sessionMinutesTarget, 15);
      expect(session.effectiveLearningCount, 0);
      expect(session.effectiveReviewCount, 0);
    });

    test('CheckInResult fromJson parses correctly', () {
      final json = <String, dynamic>{
        'check_in': {
          'local_date': '2026-04-02',
          'check_in_status': 'succeeded',
        },
        'streak': {
          'current_streak': 5,
          'streak_basis_type': 'check_in',
        },
        'learning_day': {
          'learning_day_today': false,
        },
        'already_exists': false,
      };

      final result = CheckInResult.fromJson(json);

      expect(result.checkIn.localDate, '2026-04-02');
      expect(result.checkIn.checkInStatus, 'succeeded');
      expect(result.streak.currentStreak, 5);
      expect(result.streak.streakBasisType, 'check_in');
      expect(result.learningDay.learningDayToday, false);
      expect(result.alreadyExists, false);
    });

    test('TodayState fromJson parses Phase 3 fields', () {
      final json = <String, dynamic>{
        'current_book_name': 'CET-4',
        'today_new_target': 20,
        'today_new_completed': 0,
        'today_review_target': 0,
        'today_review_pending': 0,
        'today_review_completed': 0,
        'daily_goal_status': 'not_started',
        'sync_status': 'healthy',
        'has_checked_in_today': true,
        'learning_day_today': false,
        'current_streak': 5,
        'streak_basis_type': 'check_in',
        'session_started_today': false,
        'session_valid_today': false,
      };

      final state = TodayState.fromJson(json);

      expect(state.currentBookName, 'CET-4');
      expect(state.hasCheckedInToday, true);
      expect(state.learningDayToday, false);
      expect(state.currentStreak, 5);
      expect(state.streakBasisType, 'check_in');
      expect(state.sessionStartedToday, false);
      expect(state.sessionValidToday, false);
    });

    test('TodayState fromJson handles missing Phase 3 fields', () {
      final json = <String, dynamic>{
        'current_book_name': 'CET-4',
        'today_new_target': 20,
        'today_new_completed': 0,
        'today_review_target': 0,
        'today_review_pending': 0,
        'today_review_completed': 0,
        'daily_goal_status': 'not_started',
        'sync_status': 'healthy',
      };

      final state = TodayState.fromJson(json);

      // Should default to false/0
      expect(state.hasCheckedInToday, false);
      expect(state.learningDayToday, false);
      expect(state.currentStreak, 0);
      expect(state.streakBasisType, 'check_in');
      expect(state.sessionStartedToday, false);
      expect(state.sessionValidToday, false);
    });
  });
}
