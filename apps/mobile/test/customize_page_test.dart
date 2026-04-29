import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/core/api/api_client.dart';
import 'package:meow_mobile/features/customize/customize_page.dart';

/// Test ApiClient for Customize page tests.
/// Provides controlled responses for catalog, inventory, equipment.
class CustomizeTestApiClient implements ApiClient {
  CustomizeTestApiClient({
    this.catalog,
    this.inventory,
    this.equipment,
    this.catalogException,
  });

  final CatalogResponse? catalog;
  final InventoryStateData? inventory;
  final EquipmentResponse? equipment;
  final Exception? catalogException;

  @override
  String get baseUrl => 'http://10.0.2.2:3000/api/v1';
  //String get baseUrl => 'http://localhost:3000/api/v1';

  /// Default 10-item catalog matching DevStore
  static CatalogResponse defaultCatalog() => CatalogResponse(items: [
    CatalogItemData(itemId: 'cat_hat_red', itemType: 'outfit', slot: 'head', name: '红色小帽子', coinPrice: 60, requiredLevel: 1, isActive: true),
    CatalogItemData(itemId: 'cat_bow_blue', itemType: 'outfit', slot: 'neck', name: '蓝色蝴蝶结', coinPrice: 80, requiredLevel: 2, isActive: true),
    CatalogItemData(itemId: 'cat_scarf_pink', itemType: 'outfit', slot: 'neck', name: '粉色围巾', coinPrice: 100, requiredLevel: 3, isActive: true),
    CatalogItemData(itemId: 'room_lamp_warm', itemType: 'room_item', slot: 'decor', name: '暖光小台灯', coinPrice: 120, requiredLevel: 3, isActive: true),
    CatalogItemData(itemId: 'room_rug_soft', itemType: 'room_item', slot: 'floor', name: '柔软小地毯', coinPrice: 150, requiredLevel: 4, isActive: true),
    CatalogItemData(itemId: 'cat_hat_straw', itemType: 'outfit', slot: 'head', name: '草编小草帽', coinPrice: 90, requiredLevel: 2, isActive: true),
    CatalogItemData(itemId: 'cat_bow_yellow', itemType: 'outfit', slot: 'neck', name: '向日葵领结', coinPrice: 110, requiredLevel: 3, isActive: true),
    CatalogItemData(itemId: 'cat_scarf_stripe', itemType: 'outfit', slot: 'neck', name: '条纹暖围巾', coinPrice: 130, requiredLevel: 4, isActive: true),
    CatalogItemData(itemId: 'room_plant_small', itemType: 'room_item', slot: 'decor', name: '小盆栽绿植', coinPrice: 100, requiredLevel: 2, isActive: true),
    CatalogItemData(itemId: 'room_cushion_cloud', itemType: 'room_item', slot: 'floor', name: '云朵小靠垫', coinPrice: 140, requiredLevel: 3, isActive: true),
  ]);

  static InventoryStateData emptyInventory() => InventoryStateData(
    ownedItems: [],
    coinsBalance: 200,
  );

  static InventoryStateData inventoryWithItems() => InventoryStateData(
    ownedItems: [
      OwnedItemData(itemId: 'cat_hat_red', itemType: 'outfit', slot: 'head', ownedAt: '2026-04-01', equipped: true),
      OwnedItemData(itemId: 'cat_bow_blue', itemType: 'outfit', slot: 'neck', ownedAt: '2026-04-01', equipped: false),
      OwnedItemData(itemId: 'room_lamp_warm', itemType: 'room_item', slot: 'decor', ownedAt: '2026-04-02', equipped: false),
    ],
    coinsBalance: 50,
  );

  static EquipmentResponse emptyEquipment() => EquipmentResponse(
    equippedSnapshot: EquippedSnapshotData(outfit: {}, room: {}),
  );

  static EquipmentResponse partialEquipment() => EquipmentResponse(
    equippedSnapshot: EquippedSnapshotData(
      outfit: {'head': 'cat_hat_red', 'neck': null},
      room: {'decor': null, 'floor': null},
    ),
  );

  @override
  Future<CatalogResponse> getShopCatalog() async {
    if (catalogException != null) throw catalogException!;
    return catalog ?? defaultCatalog();
  }

  @override
  Future<InventoryStateData> getInventory() async {
    return inventory ?? emptyInventory();
  }

  @override
  Future<EquipmentResponse> getEquipment() async {
    return equipment ?? emptyEquipment();
  }

  // Stubs — not needed for display tests
  @override
  Future<TodayState> getToday() => throw UnimplementedError();
  @override
  Future<SecondarySummary> getSecondarySummary() => throw UnimplementedError();
  @override
  Future<Word?> getNextNewWord() => throw UnimplementedError();
  @override
  Future<StudyAttemptResult> submitStudyAttempt({required String wordId, required String bookId, required String studyType, required String actionResult, String? idempotencyKey}) => throw UnimplementedError();
  @override
  Future<ReviewGroup> getNextReviewGroup() => throw UnimplementedError();
  @override
  Future<ReviewAttemptResult> submitReviewAttempt({required String reviewGroupId, required String wordId, required String actionResult, String? idempotencyKey}) => throw UnimplementedError();
  @override
  Future<SessionInfo> startSession({int sessionMinutesTarget = 15, String? idempotencyKey}) => throw UnimplementedError();
  @override
  Future<SessionInfo> finishSession({required String sessionId, String? idempotencyKey}) => throw UnimplementedError();
  @override
  Future<SessionInfo> getSession(String sessionId) => throw UnimplementedError();
  @override
  Future<CheckInResult> checkIn({String? idempotencyKey}) => throw UnimplementedError();
  @override
  Future<PurchaseResponse> purchaseItem({required String itemId, String? idempotencyKey}) => throw UnimplementedError();
  @override
  Future<EquipResponse> equipItem({required String itemId, String? idempotencyKey}) => throw UnimplementedError();
  @override
  Future<FeedResponse> feedCat({String? idempotencyKey}) => throw UnimplementedError();
  @override
  Future<void> updateDailyGoal(int dailyNewTarget) => throw UnimplementedError();
  @override
  Future<ReviewAttemptResult> submitLocalReviewBatch({
    required List<LocalWordAttempt> attempts,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  void dispose() {}
}

void main() {
  Widget buildTestWidget(CustomizeTestApiClient client) {
    return MaterialApp(
      home: CustomizePage(apiClient: client),
    );
  }

  testWidgets('CustomizePage renders loading state', (tester) async {
    // Use a never-completing catalog to stay in loading state
    final client = _NeverLoadApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('CustomizePage renders catalog items (visible subset)', (tester) async {
    final client = CustomizeTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // ListView.builder only renders visible items.
    // First few items should be visible on screen.
    expect(find.text('红色小帽子'), findsOneWidget);
    expect(find.text('蓝色蝴蝶结'), findsOneWidget);
    // Total catalog = 10, verify owned count shows 0/10
    expect(find.textContaining('0/10'), findsOneWidget);
  });

  testWidgets('CustomizePage shows resource bar with owned count', (tester) async {
    final client = CustomizeTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // Resource bar: coins + owned/total count
    expect(find.text('200'), findsOneWidget); // coinsBalance
    expect(find.textContaining('已拥有 0/10 件'), findsOneWidget);
  });

  testWidgets('CustomizePage shows three-state correctly', (tester) async {
    final client = CustomizeTestApiClient(
      inventory: CustomizeTestApiClient.inventoryWithItems(),
      equipment: CustomizeTestApiClient.partialEquipment(),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // cat_hat_red is equipped — "已装备" chip visible in card + preview
    expect(find.text('已装备'), findsWidgets);
    // owned-not-equipped detail section is shown for cat_bow_blue / room_lamp_warm
    expect(find.textContaining('已拥有但还没装上'), findsOneWidget);
    // Owned count shows 3/10
    expect(find.textContaining('3/10'), findsOneWidget);
  });

  testWidgets('CustomizePage shows equipped slot chips in preview area', (tester) async {
    final client = CustomizeTestApiClient(
      inventory: CustomizeTestApiClient.inventoryWithItems(),
      equipment: CustomizeTestApiClient.partialEquipment(),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // Preview should show equipped item chip with slot label
    expect(find.textContaining('头饰'), findsWidgets);
  });

  testWidgets('CustomizePage shows empty slot indicators when partially equipped', (tester) async {
    final client = CustomizeTestApiClient(
      inventory: CustomizeTestApiClient.inventoryWithItems(),
      equipment: CustomizeTestApiClient.partialEquipment(),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // Should show empty slot chips (neck, decor, floor are empty)
    expect(find.textContaining('空'), findsWidgets);
  });

  testWidgets('CustomizePage shows owned-not-equipped detail section', (tester) async {
    final client = CustomizeTestApiClient(
      inventory: CustomizeTestApiClient.inventoryWithItems(),
      equipment: CustomizeTestApiClient.partialEquipment(),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // cat_bow_blue and room_lamp_warm are owned but not equipped
    expect(find.textContaining('已拥有但还没装上'), findsOneWidget);
  });

  testWidgets('CustomizePage shows save-up goal cue when cannot afford items', (tester) async {
    final client = CustomizeTestApiClient(
      inventory: InventoryStateData(
        ownedItems: [],
        coinsBalance: 55, // Can't afford cheapest (60 coins)
      ),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // Should show save-up cue with coin difference
    expect(find.textContaining('金币'), findsWidgets);
    expect(find.textContaining('红色小帽子'), findsWidgets);
  });

  testWidgets('CustomizePage hides save-up cue when can afford all', (tester) async {
    final client = CustomizeTestApiClient(
      inventory: InventoryStateData(
        ownedItems: [],
        coinsBalance: 9999, // Can afford everything
      ),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // No save-up goal cue shown
    expect(find.textContaining('还差'), findsNothing);
  });

  testWidgets('CustomizePage shows slot labels in item cards', (tester) async {
    final client = CustomizeTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // Slot labels should appear: 头饰, 颈饰, 装饰, 地面
    expect(find.textContaining('头饰'), findsWidgets);
    expect(find.textContaining('颈饰'), findsWidgets);
  });

  testWidgets('CustomizePage shows compare hints for unowned items', (tester) async {
    final client = CustomizeTestApiClient(
      inventory: CustomizeTestApiClient.inventoryWithItems(),
      equipment: CustomizeTestApiClient.partialEquipment(),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // Compare hints use text-based hints. Verify some hint text is present for
    // unowned items visible on screen.
    // cat_scarf_pink (neck, 100 coins, user has 50) should show "还差 50 金币"
    expect(find.textContaining('还差'), findsWidgets);
  });

  testWidgets('CustomizePage shows error state on load failure', (tester) async {
    final client = CustomizeTestApiClient(
      catalogException: Exception('Network error'),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('CustomizePage equipped count chip shows correct count', (tester) async {
    final client = CustomizeTestApiClient(
      inventory: CustomizeTestApiClient.inventoryWithItems(),
      equipment: CustomizeTestApiClient.partialEquipment(),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // head slot is equipped, others empty => 1/4
    expect(find.textContaining('已装备 1/4 槽'), findsOneWidget);
  });

  testWidgets('CustomizePage tabs filter items correctly', (tester) async {
    final client = CustomizeTestApiClient(
      inventory: CustomizeTestApiClient.inventoryWithItems(),
      equipment: CustomizeTestApiClient.partialEquipment(),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // Default "全部" tab shows all 10 items
    expect(find.text('全部'), findsOneWidget);
    expect(find.text('已拥有'), findsWidgets); // tab + status chips

    // Switch to "已装备" tab
    await tester.tap(find.text('已装备').last);
    await tester.pump(const Duration(milliseconds: 500));

    // Only equipped item(s) should show
    expect(find.text('红色小帽子'), findsOneWidget);
  });
}

/// API client that never completes loading (for loading state test).
class _NeverLoadApiClient extends CustomizeTestApiClient {
  @override
  Future<CatalogResponse> getShopCatalog() => Completer<CatalogResponse>().future;

  @override
  Future<InventoryStateData> getInventory() => Completer<InventoryStateData>().future;

  @override
  Future<EquipmentResponse> getEquipment() => Completer<EquipmentResponse>().future;
}
