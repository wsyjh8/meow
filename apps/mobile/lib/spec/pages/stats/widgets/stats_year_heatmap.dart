import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../models/stats_models.dart';

/// 年度打卡热力图 — GitHub 风格 53 列 × 7 行格子。
///
/// 输入 [cells] 应包含从今天往回 365 天（升序），由 [StatsService.getYearHeatmap] 提供。
/// 列代表周（最左 = 最早），行代表星期（0=周一 ... 6=周日）。
///
/// 5 档紫色梯度由 [HeatmapCell.level] (0..4) 决定。
class StatsYearHeatmap extends StatelessWidget {
  final List<HeatmapCell> cells;

  /// 单元格大小（像素）。响应式由父组件 layout 决定，自动按宽度撑满。
  final double cellSize;
  final double cellGap;

  const StatsYearHeatmap({
    super.key,
    required this.cells,
    this.cellSize = 9,
    this.cellGap = 2,
  });

  static const _palette = <Color>[
    Color(0xFFEDE9F8), // 0 — 几乎透明的浅紫（弱化）
    Color(0xFFC8BEEC),
    Color(0xFF9C8BD9),
    Color(0xFF7460C3),
    Color(0xFF534AB7), // 4 — 最深 (与现有 heatmap 风格一致)
  ];

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) {
      return const SizedBox.shrink();
    }

    // 把 365 天按"周列 × 周内日"二维化。
    // 第 0 列起点：cells[0].localDate 当天的星期 - 1 个偏移（假设周一为周首）
    // 简化：第 i 个 cell 对应 (col = (i + offset) ~/ 7, row = (i + offset) % 7)
    // 其中 offset = cells[0].localDate.weekday - 1 (Monday=1 → 0; Sunday=7 → 6)
    final firstWeekday = cells.first.localDate.weekday; // 1..7
    final offset = firstWeekday - 1; // 0..6
    final totalSlots = offset + cells.length;
    final colCount = (totalSlots / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        // 自动按可用宽度计算 cellSize（保持每周 7 行不变）
        final availW = constraints.maxWidth;
        final perCol = (availW - (colCount - 1) * cellGap) / colCount;
        final size = perCol.clamp(6.0, cellSize);
        final totalH = size * 7 + cellGap * 6;

        return SizedBox(
          height: totalH,
          width: availW,
          child: Stack(
            children: [
              for (var i = 0; i < cells.length; i++)
                _buildCell(i, offset, size, cells[i]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCell(int i, int offset, double size, HeatmapCell cell) {
    final slot = i + offset;
    final col = slot ~/ 7;
    final row = slot % 7;
    final left = col * (size + cellGap);
    final top = row * (size + cellGap);
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: _palette[cell.level.clamp(0, 4)],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
