import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/local_settings_service.dart';
import '../theme/tokens.dart';
import '../icons/mochi_illustrations.dart';
import '../widgets/spec_settings_list.dart';

/// SPEC 6.4 — Profile Page (我的页)
///
/// Information hierarchy:
/// 1. User identity area (avatar + name + meta)
/// 2. Current textbook card (high-frequency switch entry)
/// 3. Settings group: Learning (4 items)
/// 4. Settings group: Data (2 items)
/// 5. Settings group: About (2 items, version not clickable)
class SpecProfilePage extends StatefulWidget {
  const SpecProfilePage({super.key});

  @override
  State<SpecProfilePage> createState() => _SpecProfilePageState();
}

class _SpecProfilePageState extends State<SpecProfilePage> {
  final ApiClient _apiClient = ApiClient();
  SecondarySummary? _summary;
  int _dailyGoal = 20;
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
      final results = await Future.wait([
        _apiClient.getSecondarySummary(),
        SharedPreferences.getInstance(),
      ]);
      if (mounted) {
        final prefs = results[1] as SharedPreferences;
        setState(() {
          _summary = results[0] as SecondarySummary;
          _dailyGoal = LocalSettingsService(prefs).dailyGoal;
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

    return Scaffold(
      backgroundColor: SpecBg.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserIdentity(),
              _buildCurrentBookCard(),
              _buildLearningSettings(),
              _buildDataSettings(),
              _buildAboutSettings(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== 6.4.2 User Identity ====================
  // Subtitle is USER's achievement, NOT Mochi's state.
  // Default avatar is Mochi — but this is the user's page, not Mochi's.

  Widget _buildUserIdentity() {
    final stats = _summary?.statsSummary;
    final wordsLearned = stats?.totalWordsLearned ?? 0;
    final daysJoined = stats?.totalLearningDays ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 14, SpecSpacing.pageH, 18),
      child: GestureDetector(
        onTap: () {
          // Profile edit page — out of scope (SPEC 9.3)
          debugPrint('Profile edit tapped — page not designed yet');
        },
        child: Row(
          children: [
            // Avatar: default Mochi, 54×54 circle
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: SpecBg.mochiWarm,
                shape: BoxShape.circle,
              ),
              child: const Center(child: MochiAvatar(size: 44)),
            ),
            const SizedBox(width: 14),
            // Name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alex',
                    style: TextStyle(fontSize: 16, fontWeight: SpecTypo.medium, color: SpecText.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '加入 $daysJoined 天 · 共掌握 $wordsLearned 词',
                    style: const TextStyle(fontSize: 12, color: SpecText.secondary),
                  ),
                ],
              ),
            ),
            // Chevron
            const Text('→', style: TextStyle(fontSize: 16, color: SpecText.tertiary)),
          ],
        ),
      ),
    );
  }

  // ==================== 6.4.3 Current Textbook Card ====================
  // "切换 →" is the ONLY colored high-frequency entry on this page.
  // Purple hint is INTENTIONAL — users switch textbooks more than any other setting.

  Widget _buildCurrentBookCard() {
    final wordsLearned = _summary?.statsSummary?.totalWordsLearned ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SpecBg.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '当前词书',
                  style: TextStyle(fontSize: 12, color: SpecText.secondary),
                ),
                GestureDetector(
                  onTap: () {
                    // Textbook switch — out of scope (SPEC 9.3)
                    debugPrint('Switch textbook tapped — page not designed yet');
                  },
                  child: const Text(
                    '切换 →',
                    style: TextStyle(fontSize: 11, fontWeight: SpecTypo.medium, color: SpecText.purple),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'CET-4 核心词汇',
              style: TextStyle(fontSize: 15, fontWeight: SpecTypo.medium, color: SpecText.primary),
            ),
            const SizedBox(height: 4),
            Text(
              '已学 $wordsLearned / 20 词',
              style: const TextStyle(fontSize: 11, color: SpecText.tertiary),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 6.4.4 Learning Settings ====================
  // "复习算法" MUST be visible — core users deserve this respect.

  Widget _buildLearningSettings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SpecSettingsGroupLabel('学习'),
          SpecSettingsGroup(
            rows: [
              SpecSettingsRow(
                label: '每日新词数量',
                value: '$_dailyGoal',
                onTap: () async {
                  await Navigator.pushNamed(context, '/settings');
                  // Reload after returning from settings (user may have changed daily goal)
                  _loadData();
                },
              ),
              SpecSettingsRow(
                label: '复习算法',
                value: '艾宾浩斯',
                onTap: () => debugPrint('Review algorithm — sub-page not designed'),
              ),
              SpecSettingsRow(
                label: '学习提醒',
                value: '每天 8:00',
                onTap: () => debugPrint('Reminder — sub-page not designed'),
              ),
              SpecSettingsRow(
                label: '发音',
                value: '英式',
                onTap: () => debugPrint('Pronunciation — sub-page not designed'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 6.4.5 Data Settings ====================

  Widget _buildDataSettings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SpecSettingsGroupLabel('数据'),
          SpecSettingsGroup(
            rows: [
              SpecSettingsRow(
                label: '同步与备份',
                value: '5 分钟前',
                onTap: () => Navigator.pushNamed(context, '/settings'),
              ),
              SpecSettingsRow(
                label: '导出学习记录',
                onTap: () => debugPrint('Export — sub-page not designed'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== 6.4.6 About Settings ====================
  // NEVER add: rating, invite friends, membership, check-in, daily tasks.

  Widget _buildAboutSettings() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SpecSettingsGroupLabel('关于'),
          SpecSettingsGroup(
            rows: [
              SpecSettingsRow(
                label: '帮助与反馈',
                onTap: () => debugPrint('Help — sub-page not designed'),
              ),
              // Version — NOT clickable, just display
              const SpecSettingsRow(
                label: '版本',
                value: '1.0.0',
                showChevron: false,
                valueColor: SpecText.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
