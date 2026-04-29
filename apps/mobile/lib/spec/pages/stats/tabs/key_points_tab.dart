import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/stats_service.dart';
import '../../../../core/storage/drift/app_database.dart';
import '../../../../core/storage/local_database.dart';
import '../../../theme/tokens.dart';
import '../models/stats_models.dart';
import '../widgets/stats_chart_card.dart';
import '../widgets/stats_empty_state.dart';

/// Tab 3 —— 重点难点
///
/// - 顽固词 Top 10 表（单词 + 释义 + 错误次数）
/// - 一键强化复习按钮（占位 — SnackBar "即将上线"）
/// - 词性雷达图（4 轴：名 / 动 / 形 / 副）
class KeyPointsTab extends StatefulWidget {
  const KeyPointsTab({super.key});

  @override
  State<KeyPointsTab> createState() => _KeyPointsTabState();
}

class _KeyPointsTabState extends State<KeyPointsTab> {
  bool _loading = true;
  String? _error;

  List<StubbornWord> _stubborn = [];
  PosRadarData _radar = PosRadarData.empty;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final driftDb = AppDatabase();
      final svc = StatsService(
        localDb: LocalDatabase.instance,
        driftDb: driftDb,
        prefs: prefs,
      );
      final results = await Future.wait([
        svc.getTopStubbornWords(),
        svc.getPosRadar(),
      ]);
      if (!mounted) return;
      setState(() {
        _stubborn = results[0] as List<StubbornWord>;
        _radar = results[1] as PosRadarData;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 即将上线'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: SpecBrand.purple));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('加载失败：$_error',
              style: const TextStyle(color: SpecText.tertiary, fontSize: 12)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: SpecBrand.purple,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 16, SpecSpacing.pageH, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildStubbornCard(),
            const SizedBox(height: 16),
            _buildRadarCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('重点难点挖掘',
            style: TextStyle(
              fontSize: 18,
              fontWeight: SpecTypo.medium,
              color: SpecText.primary,
            )),
        SizedBox(height: 6),
        Text(
          '本部分提供功能性统计，帮您精准定位薄弱环节。通过找出错误频次最高的"顽固"单词和分析不同词性的掌握程度，实现针对性高效复习。',
          style: TextStyle(fontSize: 12, color: SpecText.secondary, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildStubbornCard() {
    return StatsChartCard(
      title: '"顽固"单词榜 Top 10',
      subtitle: '这些是您在复习中错误次数最多的单词。',
      trailing: GestureDetector(
        onTap: () => _showComingSoon('一键强化复习'),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: SpecBrand.purple,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '一键强化复习',
            style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: SpecTypo.medium),
          ),
        ),
      ),
      child: _stubborn.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: StatsEmptyState(
                message: '还没有顽固词。继续保持！',
                icon: Icons.celebration_outlined,
              ),
            )
          : Column(
              children: [
                _buildStubbornHeader(),
                const SizedBox(height: 4),
                const Divider(color: SpecBorder.divider, height: 1, thickness: 0.5),
                for (var i = 0; i < _stubborn.length; i++) ...[
                  _buildStubbornRow(i + 1, _stubborn[i]),
                  if (i < _stubborn.length - 1)
                    const Divider(color: SpecBorder.divider, height: 1, thickness: 0.5),
                ],
              ],
            ),
    );
  }

  Widget _buildStubbornHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: Text('单词',
                style: TextStyle(fontSize: 11, color: SpecText.tertiary)),
          ),
          Expanded(
            flex: 5,
            child: Text('释义',
                style: TextStyle(fontSize: 11, color: SpecText.tertiary)),
          ),
          SizedBox(
            width: 56,
            child: Text('错误次数',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11, color: SpecText.tertiary)),
          ),
        ],
      ),
    );
  }

  Widget _buildStubbornRow(int rank, StubbornWord w) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank.',
              style: const TextStyle(
                fontSize: 12,
                color: SpecText.tertiary,
                fontWeight: SpecTypo.medium,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              w.wordText,
              style: const TextStyle(
                fontSize: 13,
                color: SpecText.primary,
                fontWeight: SpecTypo.medium,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              w.meaning,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: SpecText.secondary, height: 1.4),
            ),
          ),
          SizedBox(
            width: 56,
            child: Container(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEEBEC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${w.lapses} 次',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB14855),
                    fontWeight: SpecTypo.medium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarCard() {
    return StatsChartCard(
      title: '词性掌握度',
      subtitle: '查看您在不同词性词汇上的掌握均衡度。',
      height: 260,
      child: _radar.total == 0
          ? const StatsEmptyState()
          : _buildRadarChart(),
    );
  }

  Widget _buildRadarChart() {
    final maxV = [_radar.noun, _radar.verb, _radar.adj, _radar.adv]
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();
    final maxValue = (maxV * 1.2).clamp(4.0, double.infinity);

    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        radarBorderData: const BorderSide(color: SpecBorder.divider, width: 0.5),
        gridBorderData: const BorderSide(color: SpecBorder.divider, width: 0.5),
        tickBorderData: const BorderSide(color: Colors.transparent),
        ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
        tickCount: 4,
        titleTextStyle: const TextStyle(fontSize: 11, color: SpecText.secondary),
        titlePositionPercentageOffset: 0.18,
        getTitle: (index, angle) {
          const labels = ['名词', '动词', '形容词', '副词'];
          return RadarChartTitle(text: labels[index]);
        },
        radarBackgroundColor: Colors.transparent,
        dataSets: [
          RadarDataSet(
            fillColor: SpecBrand.purple.withValues(alpha: 0.18),
            borderColor: SpecBrand.purple,
            borderWidth: 1.5,
            entryRadius: 3,
            dataEntries: [
              RadarEntry(value: _radar.noun.toDouble()),
              RadarEntry(value: _radar.verb.toDouble()),
              RadarEntry(value: _radar.adj.toDouble()),
              RadarEntry(value: _radar.adv.toDouble()),
            ],
          ),
        ],
        // 显式设最大值（fl_chart 的 RadarChart 没有 maxEntry，
        // 通过给一个 invisible 数据集铺底来限制 scale）
        // 实际使用 dataSets[0] 已经够用，这里 maxValue 仅作 ticks 计算参考
        // ignore: deprecated_member_use_from_same_package
        // (fl_chart 0.69 RadarChartData 自动按数据集 max 缩放)
      ),
      duration: Duration.zero,
      // 通过外部 Container width 限制即可保持比例。
    );
  }
}
