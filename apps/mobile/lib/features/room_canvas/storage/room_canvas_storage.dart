import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/placed_furniture.dart';

/// 需求12 — 屋内布置画布 v1
///
/// 把已摆放家具列表持久化到 SharedPreferences（本地，不上云）。
/// key 内嵌 v1 版本号，将来 schema 变更时换 key 即可。
///
/// 需求 23 Phase C PR-C-β (plan-023-C-v2 §4.3): per-user partition.
/// The SP key suffix `room_canvas_layout_v1` is prefixed with
/// `u_<userId>_` so two users on the same device keep distinct layouts.
/// Construction requires userId — typical call site grabs it from
/// `AuthScope.of(context).currentUserId`.
class RoomCanvasStorage {
  RoomCanvasStorage(this._prefs, {required String userId}) : _userId = userId;

  final SharedPreferences _prefs;
  final String _userId;

  static const String _keySuffix = 'room_canvas_layout_v1';

  /// Exported for [SpMigrator] (keeps the suffix list in one place).
  static const List<String> migratableKeySuffixes = [_keySuffix];

  String get _key => 'u_${_userId}_$_keySuffix';

  /// 异步工厂：内部自取 SharedPreferences 实例。
  ///
  /// PR-C-β: now requires userId so the loaded layout belongs to the
  /// caller's user. Replaces the old zero-arg `open()`.
  static Future<RoomCanvasStorage> open({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    return RoomCanvasStorage(prefs, userId: userId);
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
