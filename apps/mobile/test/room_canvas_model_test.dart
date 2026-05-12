import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/features/room_canvas/models/placed_furniture.dart';
import 'package:meow_mobile/features/room_canvas/storage/room_canvas_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('PlacedFurniture', () {
    test('toJson / fromJson roundtrip', () {
      final f = PlacedFurniture(
        instanceId: 'pf-123',
        furnitureId: 'room_lamp_warm',
        x: 100.5,
        y: 200.25,
        zIndex: 3,
      );
      final json = f.toJson();
      final f2 = PlacedFurniture.fromJson(json);

      expect(f2.instanceId, f.instanceId);
      expect(f2.furnitureId, f.furnitureId);
      expect(f2.x, f.x);
      expect(f2.y, f.y);
      expect(f2.zIndex, f.zIndex);
    });

    test('copyWith updates fields', () {
      final f = PlacedFurniture(
        instanceId: 'a',
        furnitureId: 'room_rug_soft',
        x: 0,
        y: 0,
      );
      final moved = f.copyWith(x: 10, y: 20);
      expect(moved.x, 10);
      expect(moved.y, 20);
      expect(moved.instanceId, 'a');
      expect(moved.furnitureId, 'room_rug_soft');
    });

    test('fromJson tolerates missing zIndex', () {
      final f = PlacedFurniture.fromJson({
        'instance_id': 'a',
        'furniture_id': 'b',
        'x': 1,
        'y': 2,
      });
      expect(f.zIndex, 0);
    });
  });

  group('RoomCanvasGeometry', () {
    test('clampFurnitureCenter keeps inside scene', () {
      final inside =
          RoomCanvasGeometry.clampFurnitureCenter(500, 500);
      expect(inside.$1, 500);
      expect(inside.$2, 500);

      final beyond =
          RoomCanvasGeometry.clampFurnitureCenter(99999, -99999);
      expect(beyond.$1, RoomCanvasGeometry.sceneWidth);
      expect(beyond.$2, 0);
    });

    test('clampViewport respects scene bounds', () {
      // Viewport smaller than scene: offset has room to move
      final ok =
          RoomCanvasGeometry.clampViewport(100, 100, 400, 300);
      expect(ok.$1, 100);
      expect(ok.$2, 100);

      // Negative offset clamps to 0
      final neg =
          RoomCanvasGeometry.clampViewport(-50, -50, 400, 300);
      expect(neg.$1, 0);
      expect(neg.$2, 0);

      // Offset past max clamps to (sceneW - viewportW)
      final past = RoomCanvasGeometry.clampViewport(99999, 99999, 400, 300);
      expect(past.$1, RoomCanvasGeometry.sceneWidth - 400);
      expect(past.$2, RoomCanvasGeometry.sceneHeight - 300);
    });

    test('clampViewport handles viewport >= scene', () {
      // If viewport is bigger than scene, offset must be 0
      final big = RoomCanvasGeometry.clampViewport(
        50,
        50,
        RoomCanvasGeometry.sceneWidth + 100,
        RoomCanvasGeometry.sceneHeight + 100,
      );
      expect(big.$1, 0);
      expect(big.$2, 0);
    });
  });

  group('RoomCanvasStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns empty list when nothing saved', () async {
      final storage = await RoomCanvasStorage.open(userId: 'test-user');
      final loaded = await storage.load();
      expect(loaded, isEmpty);
    });

    test('save then load roundtrip preserves items', () async {
      final storage = await RoomCanvasStorage.open(userId: 'test-user');
      final items = [
        PlacedFurniture(
          instanceId: 'i1',
          furnitureId: 'room_lamp_warm',
          x: 100,
          y: 200,
          zIndex: 0,
        ),
        PlacedFurniture(
          instanceId: 'i2',
          furnitureId: 'room_plant_small',
          x: 300,
          y: 400,
          zIndex: 1,
        ),
      ];
      await storage.save(items);

      final loaded = await storage.load();
      expect(loaded.length, 2);
      expect(loaded[0].instanceId, 'i1');
      expect(loaded[0].x, 100);
      expect(loaded[1].furnitureId, 'room_plant_small');
      expect(loaded[1].zIndex, 1);
    });

    test('load returns empty on corrupted JSON', () async {
      SharedPreferences.setMockInitialValues({
        'u_test-user_room_canvas_layout_v1': 'not-valid-json{',
      });
      final storage = await RoomCanvasStorage.open(userId: 'test-user');
      final loaded = await storage.load();
      expect(loaded, isEmpty);
    });

    test('clear empties the store', () async {
      final storage = await RoomCanvasStorage.open(userId: 'test-user');
      await storage.save([
        PlacedFurniture(
          instanceId: 'i1',
          furnitureId: 'room_lamp_warm',
          x: 0,
          y: 0,
        ),
      ]);
      await storage.clear();
      final loaded = await storage.load();
      expect(loaded, isEmpty);
    });
  });
}
