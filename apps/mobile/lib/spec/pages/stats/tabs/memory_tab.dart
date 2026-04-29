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

/// Tab 2 —— 记忆分析
///
/// - 遗忘曲线 / 记忆留存率（用户实测 vs 艾宾浩斯标准）
/// - 词汇掌握等级分布（环形图）
/// - 测试正确率趋势（折线图）
class MemoryTab extends StatefulWidget {
  const MemoryTab({super.key});

  @override
  State<MemoryTab> createState() => _MemoryTabState();
}

class _MemoryTabState extends State<MemoryTab> {
  bool _loading = true;
  String? _error;

  List<RetentionBucket> _retention = [];
  MasteryDistribution _mastery = MasteryDistribution.empty;
  List<DailyAccuracy> _accuracy = [];

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
        svc.getRetentionCurve(),
        svc.getMasteryDistribution(),
        svc.getAccuracyTrend(),
      ]);
      if (!mounted) return;
      setState(() {
        _retention = results[0] as List<RetentionBucket>;
        _mastery = results[1] as MasteryDistribution;
        _accuracy = results[2] as List<DailyAccuracy>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
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
            _buildRetention(),
            const SizedBox(height: 16),
            _buildMastery(),
            const SizedBox(height: 16),
            _buildAccuracy(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('记忆质量科学分析',
            style: TextStyle(
              fontSize: 18,
              fontWeight: SpecTypo.medium,
              color: SpecText.primary,
            )),
        SizedBox(height: 6),
        Text(
          '本部分利用科学算法量化您的记忆留存情况。通过分析遗忘曲线和掌握等级分布，帮助您直观看到哪些知识已进入长期记忆，并监控您的测试正确率趋势。',
          style: TextStyle(fontSize: 12, color: SpecText.secondary, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildRetention() {
    final hasUserData = _retention.any((b) => b.userRetention != null);
    return StatsChartCard(
      title: '遗忘曲线 / 记忆留存率',
      subtitle: '基于艾宾浩斯记忆法，不同时间间隔后单词的保留百分比。',
      height: 220,
      child: hasUserData ? _buildRetentionChart() : const StatsEmptyState(),
    );
  }

  Widget _buildRetentionChart() {
    // X 轴用桶 index 0..6 等距，Y = 留存率 0..1
    final userSpots = <FlSpot>[];
    final ebbSpots = <FlSpot>[];
    for (var i = 0; i < _retention.length; i++) {
      ebbSpots.add(FlSpot(i.toDouble(), _retention[i].ebbinghaus));
      final ur = _retention[i].userRetention;
      if (ur != null) userSpots.add(FlSpot(i.toDouble(), ur));
    }

    return Column(
      children: [
        // 图例
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _LegendDot(color: SpecBrand.purple, label: '您的留存率'),
            SizedBox(width: 14),
            _LegendDot(color: Color(0xFFB8A8D4), label: '标准艾宾浩斯', dashed: true),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (_retention.length - 1).toDouble(),
              minY: 0,
              maxY: 1.0,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 0.25,
                    getTitlesWidget: (value, _) => Text(
                      '${(value * 100).toInt()}%',
                      style: const TextStyle(fontSize: 9, color: SpecText.tertiary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 18,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= _retention.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _retention[i].label,
                          style: const TextStyle(fontSize: 9, color: SpecText.tertiary),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                // 艾宾浩斯标准（虚线）
                LineChartBarData(
                  spots: ebbSpots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: const Color(0xFFB8A8D4),
                  barWidth: 1.5,
                  dashArray: [5, 3],
                  dotData: const FlDotData(show: false),
                ),
                // 用户实测（实线）
                if (userSpots.isNotEmpty)
                  LineChartBarData(
                    spots: userSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: SpecBrand.purple,
                    barWidth: 2,
                    dotData: const FlDotData(show: true),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMastery() {
    final total = _mastery.total;
    return StatsChartCard(
      title: '词汇掌握等级分布',
      subtitle: '将当前词库分类，见证"牢记"比例的不断扩大。',
      height: 220,
      child: total == 0
          ? const StatsEmptyState()
          : _buildMasteryChart(total),
    );
  }

  Widget _buildMasteryChart(int total) {
    const colors = [
      Color(0xFFD8D2E5), // 陌生
      Color(0xFFE8A86A), // 学习中（橘）
      Color(0xFF7A8FE5), // 熟悉（蓝紫）
      Color(0xFF5BC993), // 牢记（绿）
    ];
    final values = [
      _mastery.unfamiliar,
      _mastery.learning,
      _mastery.familiar,
      _mastery.mastered,
    ];
    const labels = ['陌生 (New)', '模糊 (Learning)', '熟悉 (Familiar)', '牢记 (Mastered)'];

    return Row(
      children: [
        // 环形图
        SizedBox(
          width: 150,
          height: 150,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              startDegreeOffset: -90,
              sections: List.generate(4, (i) {
                final v = values[i];
                if (v == 0) return PieChartSectionData(value: 0, radius: 0);
                return PieChartSectionData(
                  value: v.toDouble(),
                  color: colors[i],
                  radius: 22,
                  showTitle: false,
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 中心数字 + 图例
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$total',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: SpecTypo.medium,
                    color: SpecText.primary,
                  )),
              const Text('总词数',
                  style: TextStyle(fontSize: 11, color: SpecText.tertiary)),
              const SizedBox(height: 12),
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _LegendDot(
                    color: colors[i],
                    label: '${labels[i]}  ${values[i]}',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracy() {
    final hasData = _accuracy.any((a) => a.accuracy != null);
    return StatsChartCard(
      title: '测试正确率趋势分析',
      subtitle: '近 14 天复习正确率（rating ≥ 3 占比）。',
      height: 180,
      child: hasData ? _buildAccuracyChart() : const StatsEmptyState(),
    );
  }

  Widget _buildAccuracyChart() {
    final spots = <FlSpot>[];
    for (var i = 0; i < _accuracy.length; i++) {
      final acc = _accuracy[i].accuracy;
      if (acc != null) spots.add(FlSpot(i.toDouble(), acc * 100));
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (_accuracy.length - 1).toDouble(),
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 25,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}%',
                style: const TextStyle(fontSize: 9, color: SpecText.tertiary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              interval: 2,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= _accuracy.length) return const SizedBox.shrink();
                if (i % 2 != 0 && i != _accuracy.length - 1) {
                  return const SizedBox.shrink();
                }
                final d = _accuracy[i].localDate;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${d.month}/${d.day}',
                    style: const TextStyle(fontSize: 9, color: SpecText.tertiary),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: SpecBrand.purple,
            barWidth: 2,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: SpecBrand.purple.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _LegendDot({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            border: dashed ? Border.all(color: color, width: 1.5) : null,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: SpecText.secondary),
        ),
      ],
    );
  }
}
