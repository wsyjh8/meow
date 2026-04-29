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
import '../widgets/stats_number_card.dart';
import '../widgets/stats_year_heatmap.dart';

/// Tab 1 —— 概览趋势
///
/// - 4 数字卡（累计/已掌握/连续打卡/今日任务）
/// - 周/月学习趋势堆叠柱状图（带 7天/30天 切换器）
/// - 24h 活跃时段折线
/// - 365 天年度热力图
class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  StatsService? _service;
  bool _loading = true;
  String? _error;

  OverviewHeader _header = OverviewHeader.empty;
  List<DailyActivity> _trend = [];
  List<int> _hourly = List<int>.filled(24, 0);
  List<HeatmapCell> _heatmap = [];

  String _granularity = 'week'; // 'week' | 'month'

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
      _service = svc;

      final results = await Future.wait([
        svc.getOverviewHeader(),
        svc.getActivityTrend(granularity: _granularity),
        svc.getHourlyActivity(),
        svc.getYearHeatmap(),
      ]);

      if (!mounted) return;
      setState(() {
        _header = results[0] as OverviewHeader;
        _trend = results[1] as List<DailyActivity>;
        _hourly = results[2] as List<int>;
        _heatmap = results[3] as List<HeatmapCell>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _switchGranularity(String g) async {
    if (g == _granularity || _service == null) return;
    setState(() => _granularity = g);
    try {
      final trend = await _service!.getActivityTrend(granularity: g);
      if (mounted) setState(() => _trend = trend);
    } catch (_) {}
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
            _buildNumberCards(),
            const SizedBox(height: 16),
            _buildActivityTrend(),
            const SizedBox(height: 16),
            _buildHourlyActivity(),
            const SizedBox(height: 16),
            _buildYearHeatmap(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('核心概览与学习趋势',
            style: TextStyle(
              fontSize: 18,
              fontWeight: SpecTypo.medium,
              color: SpecText.primary,
            )),
        SizedBox(height: 6),
        Text(
          '本部分展示您的顶层学习成就与近期习惯。通过最醒目的数字给予正向反馈，并通过折线图和热力图将您的坚持可视化。',
          style: TextStyle(fontSize: 12, color: SpecText.secondary, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildNumberCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatsNumberCard(
                label: '累计词汇量',
                number: '${_header.totalWordsLearned}',
                subtitle: _header.weeklyDelta > 0
                    ? '↑ 较上周 +${_header.weeklyDelta}'
                    : null,
                numberColor: SpecText.purpleDeep,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatsNumberCard(
                label: '已掌握词数 (长期记忆)',
                number: '${_header.totalMastered}',
                subtitle: _header.masteryPercent > 0
                    ? '占总词汇 ${_header.masteryPercent}%'
                    : null,
                numberColor: SpecBrand.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: StatsNumberCard(
                label: '连续坚持打卡 (天)',
                number: '${_header.currentStreak}',
                subtitle: _header.currentStreak > 0 ? '🔥 保持热情' : null,
                numberColor: SpecText.coral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatsNumberCard(
                label: '今日任务 (新词/复习)',
                number: '${_header.todayCompleted}',
                unit: '/${_header.todayGoal}',
                numberColor: SpecBrand.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityTrend() {
    final hasData = _trend.any((d) => d.total > 0);
    return StatsChartCard(
      title: '${_granularity == 'week' ? '周' : '月'}学习趋势',
      subtitle: '区分新词与复习，查看每天的知识巩固情况。',
      trailing: _granularitySwitch(),
      height: 180,
      child: hasData ? _buildTrendBarChart() : const StatsEmptyState(),
    );
  }

  Widget _granularitySwitch() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: SpecBg.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _granPill('week', '7天'),
          _granPill('month', '30天'),
        ],
      ),
    );
  }

  Widget _granPill(String value, String label) {
    final selected = _granularity == value;
    return GestureDetector(
      onTap: () => _switchGranularity(value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: selected ? SpecText.purple : SpecText.secondary,
            fontWeight: selected ? SpecTypo.medium : SpecTypo.regular,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendBarChart() {
    final maxY = _trend
        .map((d) => d.total)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble();
    final yMax = (maxY * 1.2).clamp(5.0, double.infinity);

    return BarChart(
      BarChartData(
        maxY: yMax,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (yMax / 4).ceilToDouble().clamp(1, 999),
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: SpecText.tertiary),
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
                if (i < 0 || i >= _trend.length) return const SizedBox.shrink();
                // 7 天显示每天，30 天每 5 天一个标签
                final step = _granularity == 'week' ? 1 : 5;
                if (i % step != 0 && i != _trend.length - 1) {
                  return const SizedBox.shrink();
                }
                final d = _trend[i].localDate;
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
        barGroups: List.generate(_trend.length, (i) {
          final d = _trend[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: d.total.toDouble(),
                width: _granularity == 'week' ? 16 : 6,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                rodStackItems: [
                  BarChartRodStackItem(
                    0,
                    d.newCount.toDouble(),
                    SpecBrand.purple,
                  ),
                  BarChartRodStackItem(
                    d.newCount.toDouble(),
                    d.total.toDouble(),
                    const Color(0xFFB8A8D4), // 浅紫 = 复习
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHourlyActivity() {
    final hasData = _hourly.any((c) => c > 0);
    return StatsChartCard(
      title: '活跃时段分布',
      subtitle: '近 30 天复习时间习惯（按小时统计活跃次数）。',
      height: 160,
      child: hasData ? _buildHourlyLineChart() : const StatsEmptyState(),
    );
  }

  Widget _buildHourlyLineChart() {
    final maxY = _hourly.fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    final yMax = (maxY * 1.2).clamp(3.0, double.infinity);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 23,
        minY: 0,
        maxY: yMax,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (yMax / 3).ceilToDouble().clamp(1, 999),
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 9, color: SpecText.tertiary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              interval: 4,
              getTitlesWidget: (value, _) => Text(
                '${value.toInt()}',
                style: const TextStyle(fontSize: 9, color: SpecText.tertiary),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              24,
              (i) => FlSpot(i.toDouble(), _hourly[i].toDouble()),
            ),
            isCurved: true,
            curveSmoothness: 0.35,
            color: SpecBrand.purple,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: SpecBrand.purple.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearHeatmap() {
    final hasData = _heatmap.any((c) => c.count > 0);
    return StatsChartCard(
      title: '年度打卡热力图',
      subtitle: '每一抹绿都是您坚持的证明。颜色越深，当日学习单词越多。',
      child: hasData
          ? StatsYearHeatmap(cells: _heatmap)
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: StatsEmptyState(),
            ),
    );
  }
}
