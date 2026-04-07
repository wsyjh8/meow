import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/core/api/api_client.dart';

void main() {
  group('API Client Models - Phase 2', () {
    test('TodayState fromJson parses with last_reward_settlement', () {
      final json = <String, dynamic>{
        'current_book_name': 'CET-4',
        'today_new_target': 20,
        'today_new_completed': 5,
        'today_review_target': 1,
        'today_review_pending': 3,
        'today_review_completed': 0,
        'daily_goal_status': 'in_progress',
        'active_review_group_id': 'rg-001',
        'active_review_group_status': 'active',
        'active_review_group_remaining': 3,
        'sync_status': 'healthy',
        'last_reward_settlement': {
          'source_event_id': 'se-001',
          'reward_settlement_status': 'succeeded',
        },
      };

      final state = TodayState.fromJson(json);

      expect(state.currentBookName, 'CET-4');
      expect(state.todayNewTarget, 20);
      expect(state.todayNewCompleted, 5);
      expect(state.dailyGoalStatus, 'in_progress');
      expect(state.activeReviewGroupId, 'rg-001');
      expect(state.syncStatus, 'healthy');
      expect(state.lastRewardSettlement, isNotNull);
      expect(state.lastRewardSettlement!.sourceEventId, 'se-001');
      expect(state.lastRewardSettlement!.rewardSettlementStatus, 'succeeded');
    });

    test('LastRewardSettlement fromJson parses correctly', () {
      final json = <String, dynamic>{
        'source_event_id': 'se-001',
        'reward_settlement_status': 'succeeded',
      };

      final settlement = LastRewardSettlement.fromJson(json);

      expect(settlement.sourceEventId, 'se-001');
      expect(settlement.rewardSettlementStatus, 'succeeded');
    });

    test('SettlementInfo fromJson parses correctly', () {
      final json = <String, dynamic>{
        'source_event_id': 'se-001',
        'reward_settlement_status': 'succeeded',
        'reward_items': [
          <String, dynamic>{
            'reward_type': 'coins',
            'amount': 2,
            'reward_status': 'succeeded',
          },
          <String, dynamic>{
            'reward_type': 'exp',
            'amount': 1,
            'reward_status': 'succeeded',
          },
        ],
      };

      final settlement = SettlementInfo.fromJson(json);

      expect(settlement.sourceEventId, 'se-001');
      expect(settlement.rewardSettlementStatus, 'succeeded');
      expect(settlement.rewardItems.length, 2);
      expect(settlement.rewardItems[0].rewardType, 'coins');
      expect(settlement.rewardItems[0].amount, 2);
      expect(settlement.rewardItems[0].rewardStatus, 'succeeded');
    });

    test('StudyAttemptResult fromJson parses with settlement', () {
      final json = <String, dynamic>{
        'submit_status': 'accepted',
        'today_new_completed': 1,
        'daily_goal_status': 'in_progress',
        'already_exists': false,
        'settlement': {
          'source_event_id': 'se-001',
          'reward_settlement_status': 'succeeded',
          'reward_items': [
            <String, dynamic>{
              'reward_type': 'coins',
              'amount': 2,
              'reward_status': 'succeeded',
            },
          ],
        },
      };

      final result = StudyAttemptResult.fromJson(json);

      expect(result.submitStatus, 'accepted');
      expect(result.settlement, isNotNull);
      expect(result.settlement!.sourceEventId, 'se-001');
      expect(result.settlement!.rewardItems.length, 1);
    });

    test('ReviewAttemptResult fromJson parses with settlement', () {
      final json = <String, dynamic>{
        'submit_status': 'accepted',
        'group_completed': true,
        'group_remaining': 0,
        'today_review_completed': 1,
        'daily_goal_status': 'in_progress',
        'already_exists': false,
        'settlement': {
          'source_event_id': 'se-002',
          'reward_settlement_status': 'succeeded',
          'reward_items': [
            <String, dynamic>{
              'reward_type': 'coins',
              'amount': 5,
              'reward_status': 'succeeded',
            },
            <String, dynamic>{
              'reward_type': 'fish_treats',
              'amount': 1,
              'reward_status': 'succeeded',
            },
          ],
        },
      };

      final result = ReviewAttemptResult.fromJson(json);

      expect(result.submitStatus, 'accepted');
      expect(result.groupCompleted, true);
      expect(result.settlement, isNotNull);
      expect(result.settlement!.sourceEventId, 'se-002');
      expect(result.settlement!.rewardItems.length, 2);
    });
  });
}
