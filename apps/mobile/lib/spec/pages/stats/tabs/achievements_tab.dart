import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/stats_service.dart';
import '../../../../core/storage/drift/app_database.dart';
import '../../../../core/storage/local_database.dart';
import '../../../theme/tokens.dart';
import '../models/stats_models.dart';
import '../widgets/badge_tile.dart';
import '../widgets/stats_chart_card.dart';

/// Tab 4 —— 激励成就
///
/// - 全球排名击败 X% 卡（占位 — "功能即将上线"）
/// - 词汇量增长预测：当前 / 目标 / 还需天数 / 预计达成日期
/// - 个人勋章墙：6 枚（凌晨学习者 / 百日斩 / 满月战士 / 记忆大师 / 词汇巅峰 / 完美主义）
class AchievementsTab extends StatefulWidget {
  const AchievementsTab({super.key});

  @override
  State<AchievementsTab> createState() => _AchievementsTabState();
}

class _AchievementsTabState extends State<AchievementsTab> {
  bool _loading = true;
  String? _error;

  VocabularyForecast? _forecast;
  List<BadgeStatus> _badges = [];

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
        svc.getVocabularyForecast(),
        svc.getBadges(),
      ]);
      if (!mounted) return;
      setState(() {
        _forecast = results[0] as VocabularyForecast;
        _badges = results[1] as List<BadgeStatus>;
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
            _buildGlobalRankCard(),
            const SizedBox(height: 16),
            _buildForecastCard(),
            const SizedBox(height: 16),
            _buildBadgeWall(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('激励与社交',
            style: TextStyle(
              fontSize: 18,
              fontWeight: SpecTypo.medium,
              color: SpecText.primary,
            )),
        SizedBox(height: 6),
        Text(
          '本部分构建情感链接与成就系统。通过对比全体用户、预测目标达成时间以及展示勋章墙，激发您的学习斗志，并方便您分享成果。',
          style: TextStyle(fontSize: 12, color: SpecText.secondary, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildGlobalRankCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: SpecBg.heroPurple,
        borderRadius: SpecRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('全球排名击败',
              style: TextStyle(
                fontSize: 13,
                fontWeight: SpecTypo.medium,
                color: SpecText.purpleDeep,
              )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: SpecBrand.purple.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '功能即将上线',
              style: TextStyle(fontSize: 11, color: SpecText.purple),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '排行榜需要云端数据支持，我们正在开发中——敬请期待。',
            style: TextStyle(fontSize: 12, color: SpecText.secondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard() {
    final f = _forecast!;
    return StatsChartCard(
      title: '词汇量增长预测',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 数字行
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${f.targetTotal}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: SpecTypo.medium,
                  color: SpecText.primary,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '目标词汇量',
                style: TextStyle(fontSize: 11, color: SpecText.tertiary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '基于您当前 ${f.avgDailyNew.toStringAsFixed(1)} 词/天 的学习速度：',
            style: const TextStyle(fontSize: 12, color: SpecText.secondary),
          ),
          const SizedBox(height: 10),
          // 进度条 + 还需天数
          Row(
            children: [
              Text('当前：${f.currentMastered}',
                  style: const TextStyle(fontSize: 11, color: SpecText.secondary)),
              const Spacer(),
              if (f.daysRemaining != null)
                Text('预计还需 ${f.daysRemaining} 天',
                    style: const TextStyle(
                      fontSize: 11,
                      color: SpecText.coral,
                      fontWeight: SpecTypo.medium,
                    ))
              else
                const Text('继续学习以解锁预测',
                    style: TextStyle(fontSize: 11, color: SpecText.tertiary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: f.progress,
              minHeight: 6,
              backgroundColor: SpecBorder.divider,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF5BC993)),
            ),
          ),
          if (f.estimatedDate != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                '预计达成日期：${_formatDate(f.estimatedDate!)}',
                style: const TextStyle(fontSize: 11, color: SpecText.tertiary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeWall() {
    const emojis = {
      'night_owl': '🦉',
      'century': '🔥',
      'full_moon': '📅',
      'memory_master': '🧠',
      'vocab_peak': '🏔️',
      'perfectionist': '💯',
    };
    return StatsChartCard(
      title: '个人勋章墙',
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
        children: [
          for (final b in _badges)
            BadgeTile(
              badge: b,
              emoji: emojis[b.id] ?? '⭐',
            ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.year}年${d.month}月${d.day}日';
  }
}
