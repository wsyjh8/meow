import 'package:flutter/material.dart';

import '../../../spec/theme/tokens.dart';
import '../data/room_item_visuals.dart';
import '../models/placed_furniture.dart';

/// 需求12 — 屋内布置画布 v1
///
/// 单个已摆放家具：
/// - 自身的 GestureDetector 处理点击（选中）和拖动（移动家具）。
/// - 子级 GestureDetector 命中时会消费手势 → 不会触发外层场景拖动。
/// - 选中态下，上方显示删除小按钮。
class FurnitureWidget extends StatelessWidget {
  const FurnitureWidget({
    super.key,
    required this.placed,
    required this.selected,
    required this.onTapDown,
    required this.onPanUpdate,
    required this.onDelete,
  });

  final PlacedFurniture placed;
  final bool selected;
  final VoidCallback onTapDown;
  final void Function(Offset delta) onPanUpdate;
  final VoidCallback onDelete;

  /// 家具显示尺寸（视觉直径），保证有足够触摸区。
  static const double size = 56.0;

  @override
  Widget build(BuildContext context) {
    final emoji = RoomItemVisuals.emojiFor(placed.furnitureId);

    // 用 Stack 让选中态的「删除」按钮浮在家具上方。
    return SizedBox(
      width: size,
      // 给删除按钮留出顶部空间
      height: size + (selected ? 28 : 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 删除按钮 — 选中时浮于家具上方
          if (selected)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: onDelete,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9A825),
                      borderRadius: SpecRadius.pillRadius,
                    ),
                    child: const Text(
                      '删除',
                      style: TextStyle(
                        fontSize: SpecTypo.sizeTiny,
                        fontWeight: SpecTypo.medium,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 家具本体
          Positioned(
            top: selected ? 28 : 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => onTapDown(),
              onPanUpdate: (details) => onPanUpdate(details.delta),
              child: Container(
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFF9A825).withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(SpecRadius.small),
                  border: selected
                      ? Border.all(
                          color: const Color(0xFFF9A825).withValues(alpha: 0.5),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
