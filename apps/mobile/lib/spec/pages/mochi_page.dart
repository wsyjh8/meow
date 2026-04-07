import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../theme/tokens.dart';
import '../icons/mochi_illustrations.dart';
import '../widgets/spec_cards.dart';

/// SPEC 6.2 — Mochi Page
///
/// Information hierarchy:
/// 1. Top: Mochi name + days together + bond level pill
/// 2. Large Mochi illustration (visual center + speech bubble + new photo + guide tip)
/// 3. Progress bar: words until next stage
/// 4. Rose CTA: Learn words, earn fishies
/// 5. 4 secondary entries: Dress-up / Room / Snack cabinet / Diary
/// 6. Diary preview card
class SpecMochiPage extends StatefulWidget {
  const SpecMochiPage({super.key});

  @override
  State<SpecMochiPage> createState() => _SpecMochiPageState();
}

class _SpecMochiPageState extends State<SpecMochiPage> {
  final ApiClient _apiClient = ApiClient();
  SecondarySummary? _summary;
  TodayState? _todayState;
  bool _isLoading = true;
  bool _showGuideTip = true; // First-time guide
  bool _showNewPhoto = true; // New photo overlay

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
      final results = await Future.wait([
        _apiClient.getSecondarySummary(),
        _apiClient.getToday(),
      ]);
      if (mounted) {
        setState(() {
          _summary = results[0] as SecondarySummary;
          _todayState = results[1] as TodayState;
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
        body: Center(child: CircularProgressIndicator(color: SpecBrand.mochiRose)),
      );
    }

    return Scaffold(
      backgroundColor: SpecBg.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopInfo(),
              _buildIllustrationArea(),
              _buildProgressBar(),
              _buildMochiCTA(),
              _buildSecondaryEntries(),
              _buildDiaryPreview(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 6.2.2 Top Info ====================

  Widget _buildTopInfo() {
    final cat = _summary?.catSummary;
    final level = cat?.level ?? 1;
    // Days together: simplified — use streak as proxy
    final daysTogether = _todayState?.currentStreak ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 10, SpecSpacing.pageH, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: name + days
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mochi',
                style: TextStyle(fontSize: 17, fontWeight: SpecTypo.medium, color: SpecText.primary),
              ),
              Text(
                '陪伴你 $daysTogether 天',
                style: const TextStyle(fontSize: 11, fontWeight: SpecTypo.regular, color: SpecText.secondary),
              ),
            ],
          ),
          // Right: bond level pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFBEAF0),
              borderRadius: SpecRadius.pillRadius,
            ),
            child: Text(
              '羁绊 Lv.$level',
              style: const TextStyle(fontSize: 11, fontWeight: SpecTypo.medium, color: Color(0xFF72243E)),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 6.2.3 Large Illustration Area ====================

  Widget _buildIllustrationArea() {
    final hasStudied = _todayState?.learningDayToday ?? false;
    final streak = _todayState?.currentStreak ?? 0;

    // Speech bubble content
    String speechText;
    if (hasStudied) {
      speechText = '今天也辛苦你了';
    } else if (streak == 0) {
      speechText = '还记得我吗';
    } else {
      speechText = '今天也想和你\n一起学单词～';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 16),
      child: SpecCardMochiWarm(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // (a) Large Mochi SVG — clickable
            Center(
              child: GestureDetector(
                onTap: () {
                  // Mochi interaction — hide guide tip permanently
                  if (_showGuideTip) setState(() => _showGuideTip = false);
                  debugPrint('Mochi tapped! (interaction animation placeholder)');
                },
                child: const SizedBox(
                  height: 200,
                  child: MochiLarge(width: 180),
                ),
              ),
            ),

            // (b) Speech bubble
            Positioned(
              top: 22,
              right: 14,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 130),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: Text(
                  speechText,
                  style: const TextStyle(fontSize: 11, color: SpecText.mochi, height: 1.4),
                ),
              ),
            ),

            // (c) "+1 new photo" overlay
            if (_showNewPhoto)
              Positioned(
                top: 14,
                left: 14,
                child: GestureDetector(
                  onTap: () => setState(() => _showNewPhoto = false),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: SpecRadius.pillRadius,
                      boxShadow: SpecShadow.floater,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0997B),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '+1 张新照片',
                          style: TextStyle(fontSize: 10, color: SpecText.mochi),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // (d) Guide tip — only for first-time users
            if (_showGuideTip)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: 0.7,
                    child: const Text(
                      '轻轻戳一下试试',
                      style: TextStyle(fontSize: 10, color: SpecText.coral),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== 6.2.4 Progress Bar ====================

  Widget _buildProgressBar() {
    final cat = _summary?.catSummary;
    final level = cat?.level ?? 1;
    final totalExp = _summary?.exp ?? 0;
    // Simplified progress: next level needs more words
    final wordsToUnlock = (level * 15) - totalExp;
    final progress = totalExp > 0 ? (totalExp / (level * 15)).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '距离下一阶段',
                style: TextStyle(fontSize: 11, color: SpecText.secondary),
              ),
              Text(
                '背 ${wordsToUnlock > 0 ? wordsToUnlock : 0} 个词解锁',
                style: const TextStyle(fontSize: 11, color: SpecText.secondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFFBEAF0),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: SpecBrand.mochiRose,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 6.2.5 Mochi Main CTA ====================

  Widget _buildMochiCTA() {
    final hasStudied = _todayState?.learningDayToday ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 16),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/study'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SpecBrand.mochiRose,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasStudied ? '今天已经一起学过啦' : '今天还没喂 Mochi',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
              ),
              const SizedBox(height: 4),
              const Text(
                '学单词，赚小鱼干 →',
                style: TextStyle(fontSize: 16, fontWeight: SpecTypo.medium, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 6.2.6 Four Secondary Entries ====================

  Widget _buildSecondaryEntries() {
    final fishTreats = _summary?.fishTreats ?? 0;

    const entries = [
      _EntryData('换装', Color(0xFFF0997B), false, 4.0),
      _EntryData('房间', Color(0xFFFAC775), false, 4.0),
      _EntryData('零食柜', Color(0xFFF4C0D1), true, 999.0), // circle
      _EntryData('日记', Color(0xFFAFA9EC), false, 4.0),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 18),
      child: Row(
        children: entries.map((entry) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: entry == entries.last ? 0 : 8),
              child: _buildEntry(entry, entry.label == '零食柜' ? fishTreats : null),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEntry(_EntryData entry, int? badgeCount) {
    return GestureDetector(
      onTap: () {
        // Sub-pages are out of scope (SPEC 9.2)
        debugPrint('${entry.label} tapped — sub-page not designed yet');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: SpecBg.card,
          borderRadius: SpecRadius.cardRadius,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                // Placeholder icon color block
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: entry.color,
                    borderRadius: BorderRadius.circular(entry.isCircle ? 999 : entry.radius),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  entry.label,
                  style: const TextStyle(fontSize: 11, color: SpecText.primary),
                ),
              ],
            ),
            // Snack cabinet badge (resource count, NOT anxiety red dot)
            if (badgeCount != null)
              Positioned(
                top: -4,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: SpecBrand.mochiRose,
                    borderRadius: SpecRadius.pillRadius,
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(fontSize: 9, fontWeight: SpecTypo.medium, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== 6.2.7 Diary Preview Card ====================

  Widget _buildDiaryPreview() {
    final wordsLearned = _todayState?.todayNewCompleted ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 18),
      child: SpecCardOutlined(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mochi 的日记 · 今天',
              style: TextStyle(fontSize: 10, color: SpecText.tertiary),
            ),
            const SizedBox(height: 6),
            Text(
              wordsLearned > 0
                  ? '主人今天学了 $wordsLearned 个新词。我趴在旁边假装睡觉，其实一直在偷看。'
                  : '主人今天还没来学习呢。我把小鱼干摆好了，等你来～',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: SpecTypo.regular,
                color: SpecText.primary,
                fontStyle: FontStyle.italic,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryData {
  final String label;
  final Color color;
  final bool isCircle;
  final double radius;
  const _EntryData(this.label, this.color, this.isCircle, this.radius);
}
