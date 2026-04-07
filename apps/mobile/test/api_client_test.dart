import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/core/api/api_client.dart';

void main() {
  group('API Client Models', () {
    test('TodayState fromJson parses correctly', () {
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
      };

      final state = TodayState.fromJson(json);

      expect(state.currentBookName, 'CET-4');
      expect(state.todayNewTarget, 20);
      expect(state.todayNewCompleted, 5);
      expect(state.dailyGoalStatus, 'in_progress');
      expect(state.activeReviewGroupId, 'rg-001');
      expect(state.syncStatus, 'healthy');
    });

    test('Word fromJson parses correctly', () {
      final json = <String, dynamic>{
        'word_id': 'word-001',
        'word_text': 'abandon',
        'meaning': '放弃',
        'phonetic': '/əˈbændən/',
        'book_id': 'book-001',
      };

      final word = Word.fromJson(json);

      expect(word.wordId, 'word-001');
      expect(word.wordText, 'abandon');
      expect(word.meaning, '放弃');
      expect(word.phonetic, '/əˈbændən/');
      expect(word.bookId, 'book-001');
    });

    test('ReviewGroup fromJson parses correctly', () {
      final json = <String, dynamic>{
        'review_group_id': 'rg-001',
        'group_status': 'active',
        'group_completed': false,
        'remaining_count': 3,
        'items': [
          <String, dynamic>{
            'word_id': 'word-r-001',
            'word_text': 'abandon',
            'meaning': '放弃',
            'completed': false,
          },
        ],
      };

      final group = ReviewGroup.fromJson(json);

      expect(group.reviewGroupId, 'rg-001');
      expect(group.groupStatus, 'active');
      expect(group.groupCompleted, false);
      expect(group.remainingCount, 3);
      expect(group.items.length, 1);
      expect(group.items.first.wordId, 'word-r-001');
    });

    test('SecondarySummary fromJson parses correctly', () {
      final json = <String, dynamic>{
        'coins': 7,
        'fish_treats': 1,
        'exp': 3,
        'cat_summary': <String, dynamic>{
          'nickname': 'Mimi',
          'level': 1,
          'mood': 65,
          'bond': 3,
          'energy': 'medium',
        },
      };

      final summary = SecondarySummary.fromJson(json);

      expect(summary.coins, 7);
      expect(summary.fishTreats, 1);
      expect(summary.exp, 3);
      expect(summary.catSummary.nickname, 'Mimi');
      expect(summary.catSummary.level, 1);
      expect(summary.catSummary.mood, 65);
      expect(summary.catSummary.bond, 3);
      expect(summary.catSummary.energy, 'medium');
    });

    test('SecondarySummary fromJson handles missing fields safely', () {
      final json = <String, dynamic>{};

      final summary = SecondarySummary.fromJson(json);

      expect(summary.coins, 0);
      expect(summary.fishTreats, 0);
      expect(summary.exp, 0);
      expect(summary.catSummary.nickname, 'Mimi');
      expect(summary.catSummary.level, 1);
      expect(summary.catSummary.mood, 60);
      expect(summary.catSummary.bond, 0);
      expect(summary.catSummary.energy, 'medium');
    });

    // Phase 2D: Shop / Inventory model tests
    test('CatalogResponse fromJson parses correctly', () {
      final json = <String, dynamic>{
        'items': [
          <String, dynamic>{
            'item_id': 'cat_hat_red',
            'item_type': 'outfit',
            'slot': 'head',
            'name': '红色小帽子',
            'coin_price': 60,
            'required_level': 1,
            'is_active': true,
          },
        ],
      };

      final catalog = CatalogResponse.fromJson(json);
      expect(catalog.items.length, 1);
      expect(catalog.items[0].itemId, 'cat_hat_red');
      expect(catalog.items[0].coinPrice, 60);
      expect(catalog.items[0].requiredLevel, 1);
    });

    test('InventoryStateData fromJson parses correctly', () {
      final json = <String, dynamic>{
        'owned_items': [
          <String, dynamic>{
            'item_id': 'cat_hat_red',
            'item_type': 'outfit',
            'slot': 'head',
            'owned_at': '2026-04-03T12:00:00Z',
            'equipped': false,
          },
        ],
        'coins_balance': 140,
      };

      final inv = InventoryStateData.fromJson(json);
      expect(inv.ownedItems.length, 1);
      expect(inv.ownedItems[0].itemId, 'cat_hat_red');
      expect(inv.ownedItems[0].equipped, false);
      expect(inv.coinsBalance, 140);
    });

    test('PurchaseResponse fromJson parses correctly', () {
      final json = <String, dynamic>{
        'purchase_result': <String, dynamic>{
          'status': 'succeeded',
          'item_id': 'cat_hat_red',
          'coins_spent': 60,
          'already_exists': false,
        },
        'inventory': <String, dynamic>{
          'owned_items': [],
          'coins_balance': 0,
        },
      };

      final resp = PurchaseResponse.fromJson(json);
      expect(resp.purchaseResult.isSuccess, true);
      expect(resp.purchaseResult.itemId, 'cat_hat_red');
      expect(resp.purchaseResult.coinsSpent, 60);
    });

    test('EquipmentResponse fromJson parses correctly', () {
      final json = <String, dynamic>{
        'equipped_snapshot': <String, dynamic>{
          'outfit': <String, dynamic>{'head': 'cat_hat_red', 'neck': null},
          'room': <String, dynamic>{'decor': 'room_lamp_warm'},
        },
      };

      final resp = EquipmentResponse.fromJson(json);
      expect(resp.equippedSnapshot.outfit['head'], 'cat_hat_red');
      expect(resp.equippedSnapshot.outfit['neck'], isNull);
      expect(resp.equippedSnapshot.room['decor'], 'room_lamp_warm');
    });

    test('EquipResponse fromJson parses correctly', () {
      final json = <String, dynamic>{
        'equip_result': <String, dynamic>{
          'status': 'succeeded',
          'item_id': 'cat_hat_red',
          'slot': 'head',
          'item_type': 'outfit',
          'already_exists': false,
        },
        'equipped_snapshot': <String, dynamic>{
          'outfit': <String, dynamic>{'head': 'cat_hat_red'},
          'room': <String, dynamic>{},
        },
      };

      final resp = EquipResponse.fromJson(json);
      expect(resp.equipResult.isSuccess, true);
      expect(resp.equipResult.slot, 'head');
    });

    test('PurchaseResponse fromJson parses failed result', () {
      final json = <String, dynamic>{
        'purchase_result': <String, dynamic>{
          'status': 'failed',
          'error_code': 'COINS_NOT_ENOUGH',
          'item_id': 'cat_hat_red',
          'coins_spent': 0,
        },
        'inventory': <String, dynamic>{
          'owned_items': [],
          'coins_balance': 10,
        },
      };

      final resp = PurchaseResponse.fromJson(json);
      expect(resp.purchaseResult.isFailed, true);
      expect(resp.purchaseResult.errorCode, 'COINS_NOT_ENOUGH');
    });
  });
}
