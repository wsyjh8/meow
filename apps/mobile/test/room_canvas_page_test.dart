import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/core/api/api_client.dart';
import 'package:meow_mobile/features/room_canvas/storage/room_canvas_storage.dart';
import 'package:meow_mobile/features/room_canvas/widgets/furniture_widget.dart';
import 'package:meow_mobile/spec/pages/room_canvas_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stub ApiClient — overrides only what RoomCanvasPage uses.
class _StubApiClient extends ApiClient {
  _StubApiClient(this._inventory);
  final InventoryStateData _inventory;

  @override
  Future<InventoryStateData> getInventory() async => _inventory;
}

InventoryStateData _inventoryWithItems(List<String> itemIds) {
  return InventoryStateData(
    ownedItems: [
      for (final id in itemIds)
        OwnedItemData(
          itemId: id,
          itemType: 'room_item',
          slot: id.contains('rug') || id.contains('cushion') ? 'floor' : 'decor',
          ownedAt: '2026-04-01',
        ),
      // Mix in a non-room item to ensure we filter correctly
      OwnedItemData(
        itemId: 'cat_hat_red',
        itemType: 'outfit',
        slot: 'head',
        ownedAt: '2026-04-01',
      ),
    ],
    coinsBalance: 200,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required ApiClient apiClient,
    required RoomCanvasStorage storage,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RoomCanvasPage(apiClient: apiClient, storage: storage),
      ),
    );
    // settle initial async load
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
  }

  testWidgets('Renders empty canvas hint when nothing placed', (tester) async {
    final api = _StubApiClient(_inventoryWithItems(['room_lamp_warm']));
    final storage = await RoomCanvasStorage.open(userId: 'test-user');
    await pumpPage(tester, apiClient: api, storage: storage);

    expect(find.text('布置小窝'), findsOneWidget);
    expect(find.textContaining('点底部家具来摆放'), findsOneWidget);
    expect(find.byType(FurnitureWidget), findsNothing);
  });

  testWidgets('Bottom panel shows owned room items only', (tester) async {
    final api = _StubApiClient(
      _inventoryWithItems(['room_lamp_warm', 'room_plant_small']),
    );
    final storage = await RoomCanvasStorage.open(userId: 'test-user');
    await pumpPage(tester, apiClient: api, storage: storage);

    // 2 owned room items → 2 "+ 摆放" cards in panel
    expect(find.text('+ 摆放'), findsNWidgets(2));
  });

  testWidgets('Tapping a panel card adds furniture to canvas',
      (tester) async {
    final api = _StubApiClient(_inventoryWithItems(['room_lamp_warm']));
    final storage = await RoomCanvasStorage.open(userId: 'test-user');
    await pumpPage(tester, apiClient: api, storage: storage);

    expect(find.byType(FurnitureWidget), findsNothing);

    await tester.tap(find.text('+ 摆放').first);
    await tester.pump();

    expect(find.byType(FurnitureWidget), findsOneWidget);
  });

  testWidgets('Selecting a furniture shows delete button; deleting removes it',
      (tester) async {
    final api = _StubApiClient(_inventoryWithItems(['room_lamp_warm']));
    final storage = await RoomCanvasStorage.open(userId: 'test-user');
    await pumpPage(tester, apiClient: api, storage: storage);

    // Add one
    await tester.tap(find.text('+ 摆放').first);
    await tester.pump();
    expect(find.byType(FurnitureWidget), findsOneWidget);
    // After add, it auto-selects → delete button visible
    expect(find.text('删除'), findsOneWidget);

    // Tap delete
    await tester.tap(find.text('删除'));
    await tester.pump();
    expect(find.byType(FurnitureWidget), findsNothing);
  });

  testWidgets('Layout persists across page reloads', (tester) async {
    final api = _StubApiClient(_inventoryWithItems(['room_lamp_warm']));
    final storage = await RoomCanvasStorage.open(userId: 'test-user');
    await pumpPage(tester, apiClient: api, storage: storage);

    // Add a furniture, allow a tick for save
    await tester.tap(find.text('+ 摆放').first);
    await tester.pump();
    // Allow microtask for _persist() to complete
    await tester.pump(const Duration(milliseconds: 50));

    // Direct read from storage to confirm save
    final loaded = await storage.load();
    expect(loaded.length, 1);
    expect(loaded[0].furnitureId, 'room_lamp_warm');

    // Re-mount page and verify restoration
    final api2 = _StubApiClient(_inventoryWithItems(['room_lamp_warm']));
    await tester.pumpWidget(
      MaterialApp(
        home: RoomCanvasPage(apiClient: api2, storage: storage),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.byType(FurnitureWidget), findsOneWidget);
  });

  testWidgets('Empty owned room items shows empty-panel hint',
      (tester) async {
    final api = _StubApiClient(InventoryStateData(
      ownedItems: const [],
      coinsBalance: 0,
    ));
    final storage = await RoomCanvasStorage.open(userId: 'test-user');
    await pumpPage(tester, apiClient: api, storage: storage);

    expect(find.textContaining('小窝里还没有家具喵'), findsOneWidget);
  });
}
