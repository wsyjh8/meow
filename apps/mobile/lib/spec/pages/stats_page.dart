import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/memory/fsrs_service.dart';
import '../../core/services/local_today_service.dart';
import '../../core/storage/drift/app_database.dart';
import '../../core/storage/local_database.dart';
import '../theme/tokens.dart';
import '../icons/mochi_illustrations.dart';
import '../widgets/spec_cards.dart';

/// SPEC 6.3 — Stats Page (统计页)
///
/// Information hierarchy:
/// 1. Title "学习统计"
/// 2. Large hero: words mastered (positive framing, NEVER "remaining")
/// 3. Three metrics: streak / this week / memory rate
/// 4. 12-week heatmap
/// 5. This week highlights (green, hide if no positive data)
/// 6. "Needs attention" action list (gentle wording)
/// 7. Mochi signature (emotional exit, NOT interactive)
class SpecStatsPage extends StatefulWidget {
  const SpecStatsPage({super.key});

  @override
  State<SpecStatsPage> createState() => _SpecStatsPageState();
}

class _SpecStatsPageState extends State<SpecStatsPage> {
  final ApiClient _apiClient = ApiClient();
  SecondarySummary? _summary;
  TodayState? _todayState;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Today state: local-first.
      // future: cloud verification — getToday() retained for hybrid mode.
      final prefs = await SharedPreferences.getInstance();
      late TodayState todayState;
      try {
        final appDb = AppDatabase();
        final localService = LocalTodayService(
          prefs: prefs,
          localDb: LocalDatabase.instance,
          fsrs: FsrsService(db: appDb),
          driftDb: appDb,
        );
        todayState = await localService.getTodayState();
      } catch (_) {
        // Local service failed — fall back to cloud API.
        todayState = await _apiClient.getToday();
      }

      // Secondary summary: cloud-only (rewards/cat/stats — not migrated).
      SecondarySummary? summary;
      try {
        summary = await _apiClient.getSecondarySummary();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _summary = summary;
          _todayState = todayState;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: SpecBg.canvas,
        body: Center(child: CircularProgressIndicator(color: SpecBrand.purple)),
      );
    }

    final stats = _summary?.statsSummary;

    return Scaffold(
      backgroundColor: SpecBg.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              _buildHeroCard(stats),
              _buildMetricCards(stats),
              _buildHeatmap(),
              _buildWeekHighlights(stats),
              _buildAttentionList(stats),
              _buildMochiSignature(stats),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 6.3.2 Title ====================

  Widget _buildTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(SpecSpacing.pageH, 10, SpecSpacing.pageH, 14),
      child: Text('学习统计', style: SpecTypo.pageTitle),
    );
  }

  // ==================== 6.3.3 Hero Card ====================

  Widget _buildHeroCard(StatsSummaryData? stats) {
    final mastered = stats?.totalWordsLearned ?? 0;
    final total = 20; // Dev word pool
    final percent = total > 0 ? (mastered / total * 100).round() : 0;
    final progress = total > 0 ? (mastered / total).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 18),
      child: SpecCardStatsHero(
        showPawPrint: true,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Column(
          children: [
            // "已掌握" — NEVER "还差多少"
            const Text(
              '已掌握',
              style: TextStyle(fontSize: 12, color: SpecText.purple),
            ),
            const SizedBox(height: 4),
            Text(
              '$mastered',
              style: const TextStyle(fontSize: 38, fontWeight: SpecTypo.medium, color: SpecText.purpleDeep, height: 1),
            ),
            const SizedBox(height: 4),
            Text(
              '个单词 · 占本书 $percent%',
              style: const TextStyle(fontSize: 12, color: SpecText.purple),
            ),
            const SizedBox(height: 14),
            // Progress bar
            Container(
              height: 5,
              decoration: BoxDecoration(
                color: SpecBrand.purple.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: SpecBrand.purple,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 6.3.4 Three Metric Cards ====================

  Widget _buildMetricCards(StatsSummaryData? stats) {
    final streak = stats?.currentStreak ?? _todayState?.currentStreak ?? 0;
    final weekWords = _todayState?.todayNewCompleted ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 16),
      child: Row(
        children: [
          // Streak — coral color (warmth/commitment)
          Expanded(child: _metricCard('连续', '$streak', '天', SpecText.coral)),
          const SizedBox(width: 10),
          // This week — purple (cognitive data)
          Expanded(child: _metricCard('本周', '$weekWords', '个新词', SpecText.purple)),
          const SizedBox(width: 10),
          // Memory rate — purple
          Expanded(child: _metricCard('记忆率', '82', '%', SpecText.purple)),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String number, String unit, Color numberColor) {
    return SpecCardFilled(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: SpecText.secondary)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: number,
                  style: TextStyle(fontSize: 18, fontWeight: SpecTypo.medium, color: numberColor),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(fontSize: 11, fontWeight: SpecTypo.regular, color: SpecText.tertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 6.3.5 Heatmap ====================

  Widget _buildHeatmap() {
    // 5 purple shades (weak to strong) — NO red-green
    const colors = [
      Color(0xFFEEEDFE), // weakest
      Color(0xFFCECBF6),
      Color(0xFFAFA9EC),
      Color(0xFF7F77DD),
      Color(0xFF6B4FA8), // strongest
    ];

    // Generate mock heatmap data (3 rows × 12 cols)
    final rng = Random(42); // Fixed seed for consistency
    final data = List.generate(3, (_) => List.generate(12, (_) => rng.nextInt(5)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 18),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('最近 12 周', style: TextStyle(fontSize: 13, fontWeight: SpecTypo.medium, color: SpecText.primary)),
              Text('深色 = 学得多', style: TextStyle(fontSize: 11, color: SpecText.secondary)),
            ],
          ),
          const SizedBox(height: 10),
          // Grid
          ...List.generate(3, (row) {
            return Padding(
              padding: EdgeInsets.only(bottom: row < 2 ? 2 : 0),
              child: Row(
                children: List.generate(12, (col) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: col < 11 ? 2 : 0),
                      child: AspectRatio(
                        aspectRatio: 20 / 14,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors[data[row][col]],
                            borderRadius: BorderRadius.circular(SpecRadius.heatmap),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
          const SizedBox(height: 4),
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('12 周前', style: TextStyle(fontSize: 9, color: SpecText.tertiary)),
              Text('本周', style: TextStyle(fontSize: 9, color: SpecText.tertiary)),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 6.3.6 Week Highlights (Green) ====================

  Widget _buildWeekHighlights(StatsSummaryData? stats) {
    final wordsLearned = stats?.totalWordsLearned ?? 0;
    // Hide if no positive data
    if (wordsLearned == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: SpecBg.highlightGreen,
          borderRadius: SpecRadius.cardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '本周亮点',
              style: TextStyle(fontSize: 11, color: Color(0xFF0F6E56)),
            ),
            const SizedBox(height: 4),
            Text(
              '你已经掌握了 $wordsLearned 个单词，学得越来越稳了',
              style: const TextStyle(fontSize: 13, fontWeight: SpecTypo.medium, color: SpecText.green, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 6.3.7 Attention List ====================

  Widget _buildAttentionList(StatsSummaryData? stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('需要关注', style: TextStyle(fontSize: 13, fontWeight: SpecTypo.medium, color: SpecText.primary)),
          ),
          _attentionItem('3 个易遗忘词', '建议今天巩固'),
          const SizedBox(height: 8),
          _attentionItem('按当前进度', '预计 30 天学完'),
        ],
      ),
    );
  }

  Widget _attentionItem(String title, String subtitle) {
    return SpecCardOutlined(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: SpecText.primary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: SpecText.secondary)),
            ],
          ),
          const Text('→', style: TextStyle(fontSize: 16, color: SpecText.tertiary)),
        ],
      ),
    );
  }

  // ==================== 6.3.8 Mochi Signature ====================
  // NOT clickable. NOT a card. NOT bold.
  // "被看到，被感受，然后被忘记" — peak-end rule emotional exit.

  Widget _buildMochiSignature(StatsSummaryData? stats) {
    final days = stats?.totalLearningDays ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const MochiAvatar(size: 32),
          const SizedBox(width: 10),
          Text(
            'Mochi 见证了你的 $days 天',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: SpecTypo.regular,
              color: SpecText.secondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
