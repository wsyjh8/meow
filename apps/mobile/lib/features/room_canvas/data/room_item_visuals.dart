/// 需求12 — 屋内布置画布 v1
///
/// 房间物品 itemId → emoji 的集中映射。room_page 与 room_canvas 共享。
/// v1 用 emoji 表达，待美术素材就位后改为图片资源。
abstract final class RoomItemVisuals {
  static const Map<String, String> emoji = {
    'room_lamp_warm': '💡',
    'room_rug_soft': '🟫',
    'room_plant_small': '🌿',
    'room_cushion_cloud': '☁️',
  };

  static String emojiFor(String itemId) => emoji[itemId] ?? '🏠';
}
