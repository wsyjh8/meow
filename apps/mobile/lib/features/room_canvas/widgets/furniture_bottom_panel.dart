import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../spec/theme/tokens.dart';
import '../data/room_item_visuals.dart';

/// 需求12 — 屋内布置画布 v1
///
/// 底部家具面板：列出所有已购入的 room_items。点击 → 添加到画布中心。
class FurnitureBottomPanel extends StatelessWidget {
  const FurnitureBottomPanel({
    super.key,
    required this.ownedRoomItems,
    required this.onPick,
  });

  final List<OwnedItemData> ownedRoomItems;
  final void Function(OwnedItemData item) onPick;

  static const double height = 110.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: SpecBg.card,
        border: Border(
          top: BorderSide(
            color: SpecBorder.defaultColor,
            width: SpecBorder.width,
          ),
        ),
      ),
      child: ownedRoomItems.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: SpecSpacing.pageH,
                vertical: 12,
              ),
              itemCount: ownedRoomItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _buildCard(ownedRoomItems[i]),
            ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: SpecSpacing.pageH),
        child: Text(
          '小窝里还没有家具喵～去「我的小窝」买几件吧',
          style: TextStyle(
            fontSize: SpecTypo.sizeLabelSmall,
            color: SpecText.tertiary,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(OwnedItemData item) {
    final emoji = RoomItemVisuals.emojiFor(item.itemId);
    return GestureDetector(
      onTap: () => onPick(item),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 72,
        decoration: BoxDecoration(
          color: SpecBg.canvas,
          borderRadius: BorderRadius.circular(SpecRadius.small),
          border: Border.all(
            color: SpecBorder.defaultColor,
            width: SpecBorder.width,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            const Text(
              '+ 摆放',
              style: TextStyle(
                fontSize: SpecTypo.sizeTiny,
                color: Color(0xFFF9A825),
                fontWeight: SpecTypo.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
