import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/placed_furniture.dart';

/// 需求12 — 屋内布置画布 v1
///
/// 把已摆放家具列表持久化到 SharedPreferences（本地，不上云）。
/// key 内嵌 v1 版本号，将来 schema 变更时换 key 即可。
class RoomCanvasStorage {
  RoomCanvasStorage(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'room_canvas_layout_v1';

  /// 异步工厂：内部自取 SharedPreferences 实例。
  static Future<RoomCanvasStorage> open() async {
    final prefs = await SharedPreferences.getInstance();
    return RoomCanvasStorage(prefs);
  }

  Future<List<PlacedFurniture>> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final items = decoded['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => PlacedFurniture.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> save(List<PlacedFurniture> items) async {
    final payload = jsonEncode({
      'items': items.map((e) => e.toJson()).toList(),
    });
    return _prefs.setString(_key, payload);
  }

  Future<bool> clear() => _prefs.remove(_key);
}
