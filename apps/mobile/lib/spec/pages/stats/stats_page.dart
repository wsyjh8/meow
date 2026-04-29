import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'tabs/achievements_tab.dart';
import 'tabs/key_points_tab.dart';
import 'tabs/memory_tab.dart';
import 'tabs/overview_tab.dart';

/// 学习统计页 —— 4 tab 壳。
///
/// Tabs:
/// - 概览趋势  (OverviewTab)   — 数字卡 / 周月趋势 / 活跃时段 / 年度热力图
/// - 记忆分析  (MemoryTab)     — 遗忘曲线 / 掌握等级 / 正确率趋势
/// - 重点难点  (KeyPointsTab)  — 顽固词 Top10 / 词性雷达
/// - 激励成就  (AchievementsTab) — 全球排名 / 增长预测 / 勋章墙
///
/// 每个 tab 独立持有 loading/error 状态（用 [IndexedStack] 不重建）。
class SpecStatsPage extends StatefulWidget {
  const SpecStatsPage({super.key});

  @override
  State<SpecStatsPage> createState() => _SpecStatsPageState();
}

class _SpecStatsPageState extends State<SpecStatsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpecBg.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(SpecSpacing.pageH, 10, SpecSpacing.pageH, 8),
              child: Text('学习统计', style: SpecTypo.pageTitle),
            ),
            // Tab bar
            TabBar(
              controller: _tabController,
              indicatorColor: SpecBrand.purple,
              indicatorWeight: 2,
              labelColor: SpecText.purple,
              unselectedLabelColor: SpecText.secondary,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: SpecTypo.medium),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: SpecTypo.regular),
              dividerColor: SpecBorder.divider,
              dividerHeight: 0.5,
              tabs: const [
                Tab(text: '概览趋势'),
                Tab(text: '记忆分析'),
                Tab(text: '重点难点'),
                Tab(text: '激励成就'),
              ],
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const ClampingScrollPhysics(),
                children: const [
                  OverviewTab(),
                  MemoryTab(),
                  KeyPointsTab(),
                  AchievementsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
