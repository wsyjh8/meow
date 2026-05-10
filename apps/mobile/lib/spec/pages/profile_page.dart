import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth.dart';
import '../../core/storage/drift/app_database.dart';
import '../../core/storage/local_settings_service.dart';
import '../../features/auth/auth_form_page.dart';
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
  String _activeWordbook = 'book-001';
  int _wordbookTotal = 0;
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

    // Always read local settings (no network needed).
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = LocalSettingsService(prefs);
      _dailyGoal = settings.dailyGoal;
      _activeWordbook = settings.activeWordbook;

      final driftDb = AppDatabase();
      _wordbookTotal = await driftDb.countWordsInBook(_activeWordbook);
      // Do not close driftDb: sqflite uses a per-path singleton.
    } catch (_) {} // stays at previous values on error

    // Secondary summary: best-effort, silent fallback.
    try {
      final summary = await _apiClient.getSecondarySummary();
      if (mounted) _summary = summary;
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
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
              _buildAccountBlock(),
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

    // 需求 23 Phase B: display nickname/email from AuthScope.
    // Guest fallback shows "游客" without an explicit "Alex" placeholder.
    final auth = AuthScope.of(context);
    final user = auth.currentUser;
    final displayName = user?.nickname.isNotEmpty == true
        ? user!.nickname
        : (auth.status == AuthStatus.authedRegistered ? 'Learner' : '游客');
    final displaySub = '加入 $daysJoined 天 · 共掌握 $wordsLearned 词';

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
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 16, fontWeight: SpecTypo.medium, color: SpecText.primary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displaySub,
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

  // ==================== 需求 23 Phase B — Account block ====================
  //
  // Shows account status (guest / registered / token expired) with the
  // single most useful CTA. plan v2 §7.2 says we display:
  //   - current account status
  //   - nickname or email
  //   - bind-account / logout / re-login entry
  //   - (备份入口 already exists via "数据" group below)
  //
  // 项目硬纪律 §3.4: never blame / never threaten. The bind prompt is
  // a gentle "more secure"-style hint, not a guilt trip.

  Widget _buildAccountBlock() {
    final auth = AuthScope.of(context);
    final status = auth.status;
    final email = auth.currentUser?.email;

    String label;
    String? sublabel;
    String? ctaLabel;
    VoidCallback? onCta;
    Color ctaColor = SpecText.purple;

    switch (status) {
      case AuthStatus.authedRegistered:
        label = email ?? '已登录';
        sublabel = '正式账号';
        ctaLabel = '退出登录';
        ctaColor = SpecText.secondary;
        onCta = _confirmLogout;
        break;
      case AuthStatus.authedGuest:
        label = '游客模式';
        sublabel = '绑定后可在新设备上找回进度';
        ctaLabel = '绑定账号';
        onCta = () => _openAuth(AuthFormMode.bind);
        break;
      case AuthStatus.offlineGuest:
        label = '游客模式（离线）';
        sublabel = '联网后会自动获取账号身份';
        ctaLabel = null;
        onCta = null;
        break;
      case AuthStatus.tokenExpired:
        label = '登录已过期';
        sublabel = '本设备进度安全保留，请重新登录';
        ctaLabel = '重新登录';
        onCta = () => _openAuth(AuthFormMode.login);
        break;
      case AuthStatus.loading:
        label = '正在加载…';
        sublabel = null;
        ctaLabel = null;
        onCta = null;
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SpecBg.card,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: SpecTypo.medium,
                      color: SpecText.primary,
                    ),
                  ),
                  if (sublabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      sublabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: SpecText.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (ctaLabel != null && onCta != null)
              GestureDetector(
                onTap: onCta,
                child: Text(
                  '$ctaLabel →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: SpecTypo.medium,
                    color: ctaColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAuth(AuthFormMode mode) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AuthFormPage(initialMode: mode)),
    );
    // AuthScope notifyListeners after auth flow will trigger rebuild
    // automatically (this widget calls AuthScope.of in build).
    if (mounted) _loadData();
  }

  Future<void> _confirmLogout() async {
    // plan v2 §7.3: 退出登录确认。文案重点："退出后本设备将不再显示当前账号
    // 数据。如未备份，重新安装或清除本地数据可能导致进度丢失。"
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认退出登录?'),
        content: const Text(
          '退出后，本设备将不再显示当前账号数据。\n'
          '如未备份，重新安装或清除本地数据可能导致进度丢失。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('退出登录', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await AuthScope.read(context).logout();
    }
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
                  onTap: () async {
                    await Navigator.pushNamed(context, '/books');
                    if (mounted) _loadData();
                  },
                  child: const Text(
                    '切换 →',
                    style: TextStyle(fontSize: 11, fontWeight: SpecTypo.medium, color: SpecText.purple),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _displayNameFor(_activeWordbook),
              style: const TextStyle(fontSize: 15, fontWeight: SpecTypo.medium, color: SpecText.primary),
            ),
            const SizedBox(height: 4),
            Text(
              '已学 $wordsLearned / $_wordbookTotal 词',
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
  //
  // backup_restore_semantic_contract_v1 (FROZEN, P3.3.5):
  //   Label is "备份与恢复" — NOT "同步与备份". There is no real-time
  //   sync in the current regime (RF-P3.3.5-013: sync_success is NOT a
  //   valid user-facing state). A row-level timestamp value like
  //   "5 分钟前" is NOT shown here because:
  //     1. Hardcoded timestamps imply sync_success (forbidden).
  //     2. The authoritative backup status lives on /settings.
  //   See `lib/core/backup/backup_restore_semantics.dart` for full contract.

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
                label: '备份与恢复',
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

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _displayNameFor(String slug) => switch (slug) {
    'book-001' => 'CET-4 核心词汇',
    'zk'       => '中考',
    'gk'       => '高考',
    _          => slug,
  };
}
