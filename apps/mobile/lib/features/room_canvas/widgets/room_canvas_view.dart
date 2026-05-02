import 'package:flutter/material.dart';

import '../../../spec/theme/tokens.dart';
import '../models/placed_furniture.dart';
import 'furniture_widget.dart';

/// 需求12 — 屋内布置画布 v1
///
/// 画布主组件：
/// - 场景画布 (1200 × 900) > 视野 → 可拖动查看屏幕外区域。
/// - 外层 GestureDetector 处理「按住空白区域拖动 = 移动视野」。
/// - 子级 FurnitureWidget 自带 GestureDetector，命中时消费手势 → 自动满足
///   「按住家具拖动 = 移动家具」规则。
///
/// 视野偏移的「真相源」：父级 RoomCanvasPage 持有，View 通过
/// onViewportChanged 同步给父级，父级用它来定位「添加到视野中心」。
class RoomCanvasView extends StatefulWidget {
  const RoomCanvasView({
    super.key,
    required this.placed,
    required this.selectedInstanceId,
    required this.onSelect,
    required this.onDeselect,
    required this.onMoveFurniture,
    required this.onDeleteFurniture,
    required this.onViewportChanged,
  });

  final List<PlacedFurniture> placed;
  final String? selectedInstanceId;
  final void Function(String instanceId) onSelect;
  final VoidCallback onDeselect;
  final void Function(String instanceId, double dx, double dy) onMoveFurniture;
  final void Function(String instanceId) onDeleteFurniture;
  final void Function(Offset viewportOffset, Size viewportSize)
      onViewportChanged;

  @override
  State<RoomCanvasView> createState() => _RoomCanvasViewState();
}

class _RoomCanvasViewState extends State<RoomCanvasView> {
  Offset _viewportOffset = Offset.zero;
  Size _lastReportedSize = Size.zero;
  Offset _lastReportedOffset = Offset.zero;

  void _reportIfChanged(Offset offset, Size size) {
    if (offset != _lastReportedOffset || size != _lastReportedSize) {
      _lastReportedOffset = offset;
      _lastReportedSize = size;
      widget.onViewportChanged(offset, size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        // 当前 offset 用最新视野尺寸 clamp（处理屏幕旋转、初始化等）
        final clamped = RoomCanvasGeometry.clampViewport(
          _viewportOffset.dx,
          _viewportOffset.dy,
          viewportSize.width,
          viewportSize.height,
        );
        final currentOffset = Offset(clamped.$1, clamped.$2);

        // 在 build 之后通知父级（避免 build 中 setState）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _reportIfChanged(currentOffset, viewportSize);
        });

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            // 手指向右拖 → 视野左移（offset 减小）
            final raw = currentOffset - details.delta;
            final c = RoomCanvasGeometry.clampViewport(
              raw.dx,
              raw.dy,
              viewportSize.width,
              viewportSize.height,
            );
            setState(() {
              _viewportOffset = Offset(c.$1, c.$2);
            });
          },
          onTapDown: (_) => widget.onDeselect(),
          child: ClipRect(
            child: SizedBox.expand(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 场景层（包含背景 + 家具）
                  Transform.translate(
                    offset: -currentOffset,
                    child: SizedBox(
                      width: RoomCanvasGeometry.sceneWidth,
                      height: RoomCanvasGeometry.sceneHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // 背景：暖米色
                          Positioned.fill(
                            child: Container(
                              color: const Color(0xFFFAF3E8),
                            ),
                          ),
                          // 地板色带（底部 25%）
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: RoomCanvasGeometry.sceneHeight * 0.25,
                            child: Container(
                              color: const Color(0xFFEEE0C8),
                            ),
                          ),
                          // 网格点（让用户感知"场景比屏幕大"）
                          ..._buildGridDots(),
                          // 已摆放家具
                          ...widget.placed.map(
                            (f) => _buildPositionedFurniture(f),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 空画布提示
                  if (widget.placed.isEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: SpecRadius.pillRadius,
                        ),
                        child: const Text(
                          '点底部家具来摆放，按住空白处拖动看看小窝喵～',
                          style: TextStyle(
                            fontSize: SpecTypo.sizeTiny,
                            color: SpecText.secondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPositionedFurniture(PlacedFurniture f) {
    final selected = f.instanceId == widget.selectedInstanceId;
    // 选中态下，FurnitureWidget 高度 = size + 28（顶部留给删除按钮）。
    // 为了让家具本体始终居中在 (f.x, f.y)，top 在选中态额外上移 28。
    final extraTop = selected ? 28.0 : 0.0;
    return Positioned(
      left: f.x - FurnitureWidget.size / 2,
      top: f.y - FurnitureWidget.size / 2 - extraTop,
      child: FurnitureWidget(
        placed: f,
        selected: selected,
        onTapDown: () => widget.onSelect(f.instanceId),
        onPanUpdate: (delta) => widget.onMoveFurniture(
          f.instanceId,
          delta.dx,
          delta.dy,
        ),
        onDelete: () => widget.onDeleteFurniture(f.instanceId),
      ),
    );
  }

  /// 简单网格点：每 200px 一个。
  List<Widget> _buildGridDots() {
    final dots = <Widget>[];
    const spacing = 200.0;
    for (double x = spacing; x < RoomCanvasGeometry.sceneWidth; x += spacing) {
      for (double y = spacing;
          y < RoomCanvasGeometry.sceneHeight;
          y += spacing) {
        dots.add(Positioned(
          left: x - 2,
          top: y - 2,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE8DFCF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ));
      }
    }
    return dots;
  }
}
