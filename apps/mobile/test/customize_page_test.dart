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
  // Phase D stubs
  @override
  Future<DailyTaskStatus> getDailyTask() => throw UnimplementedError();
  @override
  Future<FishingRoundQuestion?> startFishingRound() => throw UnimplementedError();
  @override
  Future<FishingAttemptResult> submitFishingAttempt({
    required String taskId,
    required String chosenWordId,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  Future<LotteryBoxesResponse> getLotteryBoxes() => throw UnimplementedError();
  @override
  Future<LotteryOpenResult> openLotteryBox({
    required String boxId,
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
    final client = _NeverLoadApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('CustomizePage renders catalog items in grid', (tester) async {
    final client = CustomizeTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // Grid shows item names (GridView renders all 10 in scrollable)
    expect(find.text('红色小帽子'), findsOneWidget);
    expect(find.text('蓝色蝴蝶结'), findsOneWidget);
  });

  testWidgets('CustomizePage shows coins in AppBar', (tester) async {
    final client = CustomizeTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // AppBar trailing shows coin balance
    expect(find.textContaining('200'), findsOneWidget);
  });

  testWidgets('CustomizePage shows three-state labels correctly', (tester) async {
    final client = CustomizeTestApiClient(
      inventory: CustomizeTestApiClient.inventoryWithItems(),
      equipment: CustomizeTestApiClient.partialEquipment(),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // cat_hat_red is equipped → "已装备" shown
    expect(find.text('已装备'), findsWidgets);
    // cat_bow_blue is owned not equipped → "装备" button shown
    expect(find.text('装备'), findsWidgets);
    // Unowned items show price + "币"
    expect(find.textContaining('币'), findsWidgets);
  });

  testWidgets('CustomizePage shows slot indicator chips in preview stage', (tester) async {
    final client = CustomizeTestApiClient(
      inventory: CustomizeTestApiClient.inventoryWithItems(),
      equipment: CustomizeTestApiClient.partialEquipment(),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // Preview stage shows 4 slot chips: 头 颈 饰 地
    expect(find.text('头'), findsOneWidget);
    expect(find.text('颈'), findsOneWidget);
    expect(find.text('饰'), findsOneWidget);
    expect(find.text('地'), findsOneWidget);
  });

  testWidgets('CustomizePage shows error state on load failure', (tester) async {
    final client = CustomizeTestApiClient(
      catalogException: Exception('Network error'),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('CustomizePage tabs filter items correctly', (tester) async {
    final client = CustomizeTestApiClient(
      inventory: CustomizeTestApiClient.inventoryWithItems(),
      equipment: CustomizeTestApiClient.partialEquipment(),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // "全部" tab is default — all items visible
    expect(find.text('全部'), findsOneWidget);

    // Switch to "已装备" tab
    await tester.tap(find.text('已装备').last);
    await tester.pump(const Duration(milliseconds: 500));

    // Only equipped item should show in grid (preview area may also show its name)
    expect(find.text('红色小帽子'), findsAtLeast(1));
  });

  testWidgets('CustomizePage shows price for unowned items', (tester) async {
    final client = CustomizeTestApiClient(
      inventory: InventoryStateData(ownedItems: [], coinsBalance: 55),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // Unowned items show "N 币" price label
    expect(find.textContaining('币'), findsWidgets);
  });

  testWidgets('CustomizePage shows back-to-study chip', (tester) async {
    final client = CustomizeTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('回到学习'), findsOneWidget);
  });

  testWidgets('CustomizePage shows learning-decor separation notice', (tester) async {
    final client = CustomizeTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    // §3.2 主副机制隔离提示条
    expect(find.textContaining('不会变成学习进度'), findsOneWidget);
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
