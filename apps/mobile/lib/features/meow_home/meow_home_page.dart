import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth.dart';
import '../../core/memory/fsrs_service.dart';
import '../../core/router/app_router.dart';
import '../../core/services/local_today_service.dart';
import '../../core/storage/drift/app_database.dart';
import '../../core/storage/local_database.dart';
import '../../shared/theme.dart';
import '../../shared/animations.dart';
import '../../shared/widgets/meow_card.dart';
import '../../shared/widgets/meow_chip.dart';
import '../../shared/widgets/resource_badge.dart';
import '../../shared/helpers/streak_display.dart';

/// MeowHomePage — Option B Phase 2 redesign.
///
/// Structure: Hero Cat Area → Resource Bar → Growth Card →
///            Companion Copy → Equipped → Actions
class MeowHomePage extends StatefulWidget {
  const MeowHomePage({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<MeowHomePage> createState() => _MeowHomePageState();
}

class _MeowHomePageState extends State<MeowHomePage>
    with TickerProviderStateMixin {
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();

  SecondarySummary? _summary;
  TodayState? _todayState;
  bool _isLoading = true;
  String? _error;
  bool _isFeeding = false;
  bool _interactCooldown = false;
  String? _interactResponse;

  // Breathing animation for cat avatar
  late final AnimationController _breathController;
  late final Animation<double> _breathAnimation;

  // Interaction copy pool (B2-1A expansion)
  static const _interactCopies = [
    '喵~ 被摸到了很舒服呢',
    '咕噜咕噜... 好开心',
    '蹭蹭~ 你今天辛苦了',
    '伸了个懒腰~ 继续陪你',
    '喵呜~ 最喜欢你了',
    '眯起眼睛享受中...',
    '翻了个肚皮~ 信任你哦',
    '轻轻甩了甩尾巴~',
    '用爪子轻轻碰了碰你~',
    '歪头看着你，好奇的样子',
    '窝在你旁边打了个小盹~',
    '发出了满足的小呼噜声~',
    '耳朵抖了抖，好痒~',
    '舒服得眯成了一条缝~',
    '轻轻蹭了蹭你的手心~',
    '尾巴竖起来摇了摇，开心的信号~',
  ];

  // Feed success copy pool (B2-1A expansion)
  static const _feedSuccessCopies = [
    '喵喵吃得很开心~',
    '小鱼干真好吃！谢谢~',
    '满足地舔了舔嘴巴~',
    '吃饱了，精神满满！',
    '好吃！期待下一次~',
    '嗯嗯，这个味道最喜欢了~',
    '吃完想打个盹... zzZ',
    '谢谢投喂！你是最好的铲屎官~',
  ];

  // Friendly display names for equipped items
  static const _itemDisplayNames = <String, String>{
    'cat_hat_red': '🎩 红色小帽子',
    'cat_bow_blue': '🎀 蓝色蝴蝶结',
    'cat_scarf_pink': '🧣 粉色围巾',
    'room_lamp_warm': '💡 暖光小台灯',
    'room_rug_soft': '🏠 柔软小地毯',
    // B2-2A new items
    'cat_hat_straw': '👒 草编小草帽',
    'cat_bow_yellow': '🌻 向日葵领结',
    'cat_scarf_stripe': '🧣 条纹暖围巾',
    'room_plant_small': '🌿 小盆栽绿植',
    'room_cushion_cloud': '☁️ 云朵小靠垫',
  };

  static const _slotDisplayNames = <String, String>{
    'head': '头饰',
    'neck': '颈饰',
    'decor': '装饰',
    'floor': '地面',
  };

  // Level thresholds for progress bar (matching backend)
  static const _levelThresholds = [0, 20, 50, 90, 145, 215, 305, 420, 565, 745];

  /// 需求 23 Phase C PR-C-γ §4.5: last-seen auth epoch for the
  /// account-switch reset hook in [didChangeDependencies]. Null on
  /// first frame; set by the initial dependency pass.
  int? _lastSeenEpoch;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _loadSummary();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // PR-C-γ §4.5: drop stale per-user state on account switch.
    final controller = AuthScope.maybeRead(context);
    final epoch = controller?.epoch;
    if (epoch != null && _lastSeenEpoch != null && _lastSeenEpoch != epoch) {
      setState(() {
        _summary = null;
        _todayState = null;
        _isLoading = true;
        _error = null;
      });
      _loadSummary();
    }
    _lastSeenEpoch = epoch;
  }

  @override
  void dispose() {
    _breathController.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() { _isLoading = true; _error = null; });

    // Secondary summary: always has a graceful fallback — never blocks the page.
    SecondarySummary summary;
    try {
      summary = await _apiClient.getSecondarySummary();
    } catch (_) {
      summary = SecondarySummary(
        coins: 0, fishTreats: 0, exp: 0,
        catSummary: CatSummary(
          nickname: 'Mimi', level: 1, mood: 60, bond: 0, energy: 'medium'),
      );
    }

    // Today state: local-first via LocalTodayService, cloud API as fallback.
    // future: cloud verification — getToday() retained for hybrid mode.
    TodayState? todayState;
    try {
      final userId = AuthScope.currentUserIdOf(context);
      final prefs = await SharedPreferences.getInstance();
      try {
        final appDb = AppDatabase();
        // PR-C-β: user-scoped via factory constructor.
        final localService = LocalTodayService.forUser(
          prefs: prefs,
          localDb: LocalDatabase.instance,
          fsrs: FsrsService.forUser(db: appDb, userId: userId),
          driftDb: appDb,
          userId: userId,
        );
        todayState = await localService.getTodayState();
      } catch (_) {
        // Local service failed (e.g., drift unavailable) — cloud fallback.
        todayState = await _apiClient.getToday();
      }
    } catch (_) {
      // SharedPreferences or all paths failed — todayState stays null.
    }

    if (!mounted) return;
    if (todayState == null) {
      setState(() { _error = 'offline'; _isLoading = false; });
    } else {
      setState(() {
        _summary = summary;
        _todayState = todayState;
        _isLoading = false;
      });
    }
  }

  Future<void> _feedCat() async {
    if (_isFeeding) return;
    setState(() => _isFeeding = true);

    try {
      final key = 'feed-${DateTime.now().millisecondsSinceEpoch}';
      final response = await _apiClient.feedCat(idempotencyKey: key);
      if (!mounted) return;

      if (response.feedResult.isInsufficientResource) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('小鱼干不够啦，先去学一点单词吧~')),
        );
      } else if (response.feedResult.isSuccess) {
        setState(() => _summary = response.secondarySummary);
        final gf = response.growthFeedback;
        if (gf != null && gf.leveledUp && !response.feedResult.alreadyExists) {
          _showLevelUpDialog(gf.currentLevel);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response.feedResult.alreadyExists
                    ? '喵喵已经吃过啦~'
                    : '${_feedSuccessCopies[Random().nextInt(_feedSuccessCopies.length)]}  Mood +${response.feedResult.moodDelta ?? 0}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('喂猫失败了: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFeeding = false);
    }
  }

  void _handleInteract() {
    if (_interactCooldown) return;
    final copy = _interactCopies[Random().nextInt(_interactCopies.length)];
    setState(() {
      _interactResponse = copy;
      _interactCooldown = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() { _interactCooldown = false; _interactResponse = null; });
    });
  }

  void _showLevelUpDialog(int newLevel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: MeowRadius.dialogRadius),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: MeowColors.primary, size: 28),
            const SizedBox(width: 8),
            const Text('喵喵升级啦!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: MeowColors.catOrange,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('Lv.$newLevel',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: MeowColors.primaryDark)),
              ),
            ),
            const SizedBox(height: 16),
            Text('${_summary?.catSummary.nickname ?? "Mimi"} 升到 Lv.$newLevel 了',
                style: MeowTextStyles.subtitle),
            const SizedBox(height: 8),
            Text('继续学习，陪它一起长大~', style: MeowTextStyles.bodySmall),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('好的')),
        ],
      ),
    );
  }

  double _getExpProgress(int exp, int level) {
    if (level >= _levelThresholds.length) return 1.0;
    final currentThreshold = _levelThresholds[level - 1];
    final nextThreshold = level < _levelThresholds.length
        ? _levelThresholds[level]
        : currentThreshold + 200;
    final range = nextThreshold - currentThreshold;
    if (range <= 0) return 1.0;
    return ((exp - currentThreshold) / range).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeowColors.background,
      appBar: AppBar(
        title: const Text('喵喵主页'),
        actions: [
          IconButton(tooltip: '刷新', onPressed: _loadSummary, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(key: ValueKey('meow-home-loading'), child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        key: const ValueKey('meow-home-error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 52, color: MeowColors.primary),
              const SizedBox(height: 16),
              const Text('暂时还没拿到喵喵主页信息', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: MeowTextStyles.bodySmall),
              const SizedBox(height: 16),
              ElevatedButton(key: const Key('meow-home-retry'), onPressed: _loadSummary, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final summary = _summary ?? SecondarySummary.fromJson(const {'cat_summary': {}});
    final cat = summary.catSummary;
    final companion = summary.companionResponse;

    return SingleChildScrollView(
      key: const ValueKey('meow-home-content'),
      child: Column(
        children: [
          // ===== 1. Hero Cat Area =====
          _buildHeroArea(cat),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MeowSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== 2. Resource Bar =====
                _buildResourceBar(summary),
                const SizedBox(height: MeowSpacing.md),

                // ===== 3. Growth Card =====
                _buildGrowthCard(cat, summary.exp),
                const SizedBox(height: MeowSpacing.md),

                // ===== 4. Today Highlights (B2-1C) + change_highlights (B23-C) =====
                if (_todayState != null) ...[
                  _buildTodayHighlights(_todayState!),
                  const SizedBox(height: MeowSpacing.md),
                ],
                // B23-C: change_highlights area (max 3, today's key changes)
                _buildChangeHighlightsArea(),

                // ===== 5. Companion Copy =====
                if (companion != null) ...[
                  _buildCompanionSection(companion),
                  const SizedBox(height: MeowSpacing.md),
                ],

                // ===== 6. Equipped Display =====
                if (summary.equippedPreview.values.any((v) => v != null)) ...[
                  _buildEquippedSection(summary.equippedPreview),
                  const SizedBox(height: MeowSpacing.md),
                ],

                // ===== 7. Stats Summary (P3P3: summary-first hardened) =====
                _buildStatsSummarySection(summary.statsSummary),

                // ===== 8. Actions =====
                _buildActionsSection(),
                const SizedBox(height: MeowSpacing.xxxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 1. Hero Cat Area ====================

  Widget _buildHeroArea(CatSummary cat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: MeowSpacing.lg, bottom: MeowSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [MeowColors.catOrange.withValues(alpha: 0.15), MeowColors.background],
        ),
      ),
      child: Column(
        children: [
          // Cat avatar with breathing animation
          ScaleTransition(
            scale: _breathAnimation,
            child: Container(
              key: const Key('meow-home-cat-avatar'),
              width: 140, height: 140,
              decoration: BoxDecoration(
                color: MeowColors.catOrange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: MeowColors.catOrangeDeep.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 6)),
                ],
              ),
              child: const Center(child: Text('🐱', style: TextStyle(fontSize: 64))),
            ),
          ),
          const SizedBox(height: MeowSpacing.md),

          // Status bubble (interaction response or mood)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _interactResponse != null
                ? Container(
                    key: ValueKey(_interactResponse),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: MeowColors.secondary.withValues(alpha: 0.3),
                      borderRadius: MeowRadius.chipRadius,
                    ),
                    child: Text(_interactResponse!, style: MeowTextStyles.bodySmall.copyWith(color: MeowColors.primaryDark)),
                  )
                : Container(
                    key: const ValueKey('mood-bubble'),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: MeowColors.surfaceWarm,
                      borderRadius: MeowRadius.chipRadius,
                    ),
                    child: Text(
                      _getMoodText(cat.mood),
                      style: MeowTextStyles.bodySmall.copyWith(color: MeowColors.textSecondary),
                    ),
                  ),
          ),
          const SizedBox(height: MeowSpacing.sm),

          // Name + Level
          Text(cat.nickname, style: MeowTextStyles.headline),
          const SizedBox(height: 4),
          MeowChip(
            label: 'Lv. ${cat.level}',
            icon: Icons.auto_awesome,
            variant: MeowChipVariant.primary,
          ),
          const SizedBox(height: MeowSpacing.sm),

          // Mood / Bond / Energy chips
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              MeowChip(label: 'Mood ${cat.mood}', variant: MeowChipVariant.warning, small: true),
              MeowChip(label: 'Bond ${cat.bond}', variant: MeowChipVariant.accent, small: true),
              MeowChip(label: 'Energy ${cat.energy}', variant: MeowChipVariant.info, small: true),
            ],
          ),
        ],
      ),
    );
  }

  // Mood bubble copy (B2-1A expansion)
  static const _moodHigh = ['心情超好~ ✨', '开心得转圈圈~', '今天元气满满！', '幸福感爆棚~'];
  static const _moodGood = ['心情不错呢 😊', '感觉还蛮好的~', '嘿嘿，今天挺开心', '舒舒服服的~'];
  static const _moodOk = ['还行吧~', '普普通通的一天', '有点犯困...', '在等你来陪我~'];
  static const _moodLow = ['有点无聊...', '好想出去玩~', '今天安安静静的', '来陪陪我嘛~'];

  String _getMoodText(int mood) {
    if (mood >= 80) return _moodHigh[Random().nextInt(_moodHigh.length)];
    if (mood >= 60) return _moodGood[Random().nextInt(_moodGood.length)];
    if (mood >= 40) return _moodOk[Random().nextInt(_moodOk.length)];
    return _moodLow[Random().nextInt(_moodLow.length)];
  }

  // ==================== 2. Resource Bar ====================

  Widget _buildResourceBar(SecondarySummary summary) {
    return MeowCard(
      padding: const EdgeInsets.symmetric(horizontal: MeowSpacing.md, vertical: MeowSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: ResourceBadge(
              icon: Icons.monetization_on,
              value: '${summary.coins}',
              color: MeowColors.coinGold,
              label: '金币',
              compact: true,
            ),
          ),
          Container(width: 1, height: 24, color: MeowColors.divider),
          Expanded(
            child: Center(
              child: ResourceBadge(
                icon: Icons.set_meal,
                value: '${summary.fishTreats}',
                color: MeowColors.fishBlue,
                label: '小鱼干',
                compact: true,
              ),
            ),
          ),
          Container(width: 1, height: 24, color: MeowColors.divider),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: ResourceBadge(
                icon: Icons.auto_awesome,
                value: '${summary.exp}',
                color: MeowColors.expPurple,
                label: 'EXP',
                compact: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 3. Growth Card ====================

  Widget _buildGrowthCard(CatSummary cat, int totalExp) {
    final progress = _getExpProgress(totalExp, cat.level);
    final nextLevel = cat.level < 10 ? cat.level + 1 : 10;
    final nextThreshold = cat.level < _levelThresholds.length
        ? _levelThresholds[cat.level]
        : totalExp;

    return MeowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 18, color: MeowColors.primary),
              const SizedBox(width: 6),
              Text('成长', style: MeowTextStyles.label),
              const Spacer(),
              Text('Lv.${cat.level}', style: MeowTextStyles.label.copyWith(color: MeowColors.primary)),
            ],
          ),
          const SizedBox(height: MeowSpacing.md),
          MeowAnimatedProgress(
            value: progress,
            color: MeowColors.primary,
            backgroundColor: MeowColors.primaryLight.withValues(alpha: 0.3),
            height: 10,
          ),
          const SizedBox(height: 6),
          Text(
            cat.level >= 10
                ? 'EXP $totalExp · 已达最高等级'
                : 'EXP $totalExp / $nextThreshold · 距 Lv.$nextLevel 还差 ${nextThreshold - totalExp}',
            style: MeowTextStyles.caption,
          ),
        ],
      ),
    );
  }

  // ==================== 4. Today Highlights (B2-1C) ====================

  /// Shows today's activity as light chips — all from TodayState direct fields.
  Widget _buildTodayHighlights(TodayState today) {
    final chips = <Widget>[];

    if (today.hasCheckedInToday) {
      chips.add(const MeowChip(label: '✅ 已签到', variant: MeowChipVariant.success, small: true));
    }
    if (today.learningDayToday) {
      chips.add(const MeowChip(label: '📖 有效学习', variant: MeowChipVariant.primary, small: true));
    }
    if (today.todayNewCompleted > 0) {
      chips.add(MeowChip(label: '📝 +${today.todayNewCompleted}词', variant: MeowChipVariant.neutral, small: true));
    }
    if (today.todayReviewCompleted > 0) {
      chips.add(MeowChip(label: '🔄 复习${today.todayReviewCompleted}组', variant: MeowChipVariant.info, small: true));
    }
    if (today.sessionValidToday) {
      chips.add(const MeowChip(label: '⏱️ 专注达标', variant: MeowChipVariant.info, small: true));
    }
    if (today.currentStreak > 1) {
      // C4: streak chip explicitly notes basis (consistent with Today page and Stats card)
      chips.add(MeowChip(label: StreakDisplay.streakChipLabelAlt(today.currentStreak), variant: MeowChipVariant.warning, small: true));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    // Today highlights copy pool (B2-1C)
    const highlightHeaders = [
      '今天的小成就',
      '今天的收获',
      '今日进展',
    ];

    return MeowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌟', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                highlightHeaders[Random().nextInt(highlightHeaders.length)],
                style: MeowTextStyles.label,
              ),
            ],
          ),
          const SizedBox(height: MeowSpacing.sm),
          Wrap(spacing: 6, runSpacing: 6, children: chips),
        ],
      ),
    );
  }

  // ==================== 4b. Change Highlights Area (B23-C, max 3) ====================
  // Read-only summary/hint layer. NOT a new truth layer. NOT a feed/timeline.
  // label is display copy only — UI must not use it to override truth layers.

  Widget _buildChangeHighlightsArea() {
    final highlights = _summary?.changeHighlights ?? [];
    final displayHighlights = highlights.take(3).toList(); // Max 3 for Meow Home

    // Empty → hide area entirely (no skeleton, no fake changes)
    if (displayHighlights.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: MeowSpacing.md),
      child: MeowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('\u2728', style: TextStyle(fontSize: 14)), // ✨
                const SizedBox(width: 6),
                Text(
                  '\u4eca\u65e5\u91cd\u70b9\u53d8\u5316', // 今日重点变化
                  style: MeowTextStyles.label,
                ),
              ],
            ),
            const SizedBox(height: MeowSpacing.sm),
            ...displayHighlights.map((h) => _buildHighlightItem(h)),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightItem(ChangeHighlightData highlight) {
    final isConfirmed = highlight.status == 'confirmed';
    final icon = _highlightKindIcon(highlight.kind);
    final chipVariant = isConfirmed ? MeowChipVariant.primary : MeowChipVariant.neutral;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Flexible(
            child: MeowChip(
              label: highlight.label,
              variant: chipVariant,
              small: true,
            ),
          ),
          if (!isConfirmed) ...[
            const SizedBox(width: 4),
            Text(
              '\u5f85\u786e\u8ba4', // 待确认
              style: MeowTextStyles.caption.copyWith(
                color: MeowColors.textHint,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _highlightKindIcon(String kind) {
    switch (kind) {
      case 'purchase': return '\ud83d\udecd\ufe0f'; // 🛍️
      case 'equip': return '\u2728'; // ✨
      case 'growth': return '\u2b06\ufe0f'; // ⬆️
      case 'streak': return '\ud83d\udd25'; // 🔥
      case 'post_learning': return '\ud83d\udcd6'; // 📖
      default: return '\ud83d\udca1'; // 💡
    }
  }

  // ==================== 5. Companion Section ====================

  Widget _buildCompanionSection(CompanionResponseData companion) {
    return MeowCardWarm(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🐾', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  companion.dailyGreeting,
                  key: const Key('companion-daily-greeting'),
                  style: MeowTextStyles.body.copyWith(color: MeowColors.textPrimary),
                ),
              ),
            ],
          ),
          if (companion.postLearningResponse != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✨', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    companion.postLearningResponse!,
                    key: const Key('companion-post-learning'),
                    style: MeowTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          if (companion.streakNodeResponse != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: MeowColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: MeowRadius.chipRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      companion.streakNodeResponse!,
                      key: const Key('companion-streak-node'),
                      style: MeowTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: MeowColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== 5. Equipped Section ====================

  Widget _buildEquippedSection(Map<String, String?> equippedPreview) {
    final equipped = equippedPreview.entries.where((e) => e.value != null).toList();
    if (equipped.isEmpty) return const SizedBox.shrink();

    return MeowCard(
      key: const Key('meow-home-equipped-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('👗', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('当前装扮', style: MeowTextStyles.label),
            ],
          ),
          const SizedBox(height: MeowSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: equipped.map((e) {
              final displayName = _itemDisplayNames[e.value] ?? e.value!;
              final slotName = _slotDisplayNames[e.key] ?? e.key;
              return MeowChip(
                label: '$slotName: $displayName',
                variant: MeowChipVariant.primary,
                small: true,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ==================== 7. Stats Summary (P3 Phase 3: summary-first hardened) ====================
  // Summary-first ONLY. No standalone page, no route, no first-level nav.
  // learning_days = learning_day ONLY. check_in and streak are separate facts.
  // State matrix: normal / empty / unavailable (null stats = hidden).

  Widget _buildStatsSummarySection(StatsSummaryData? stats) {
    // Unavailable / contract absent → hidden entirely (no skeleton, no fake data)
    if (stats == null) return const SizedBox.shrink();

    // Empty state: all metrics zero → show encouraging neutral message
    final allZero = stats.totalLearningDays == 0 &&
        stats.totalWordsLearned == 0 &&
        stats.totalReviewGroupsCompleted == 0 &&
        stats.totalCheckIns == 0;

    if (allZero) {
      return Padding(
        padding: const EdgeInsets.only(bottom: MeowSpacing.md),
        child: MeowCard(
          key: const Key('stats-summary-empty'),
          child: Column(
            children: [
              const Text('\u{1f4ca}', style: TextStyle(fontSize: 24)), // 📊
              const SizedBox(height: MeowSpacing.sm),
              Text(
                '\u5b66\u4e00\u70b9\u4e1c\u897f\uff0c\u8fd9\u91cc\u4f1a\u6709\u4f60\u7684\u8bb0\u5f55\u54e6~',
                // 学一点东西，这里会有你的记录哦~
                style: MeowTextStyles.bodySmall.copyWith(color: MeowColors.textHint),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Normal state: show metrics
    return Padding(
      padding: const EdgeInsets.only(bottom: MeowSpacing.md),
      child: MeowCard(
        key: const Key('stats-summary-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('\u{1f4ca}', style: TextStyle(fontSize: 14)), // 📊
                const SizedBox(width: 6),
                Text('\u5b66\u4e60\u6982\u89c8', style: MeowTextStyles.label), // 学习概览
              ],
            ),
            const SizedBox(height: MeowSpacing.md),
            Row(
              children: [
                // P3P3: Each metric has a sub-label clarifying its truth source
                Expanded(child: _buildStatMetric(
                  '\u{1f4d6}', // 📖
                  '${stats.totalLearningDays}',
                  '\u5b66\u4e60\u5929\u6570', // 学习天数
                  '\u6709\u6548\u5b66\u4e60\u65e5', // 有效学习日 (sub-label)
                )),
                Expanded(child: _buildStatMetric(
                  '\u{1f4dd}', // 📝
                  '${stats.totalWordsLearned}',
                  '\u5df2\u5b66\u5355\u8bcd', // 已学单词
                  null,
                )),
                Expanded(child: _buildStatMetric(
                  '\u{1f504}', // 🔄
                  '${stats.totalReviewGroupsCompleted}',
                  '\u590d\u4e60\u7ec4', // 复习组
                  null,
                )),
                Expanded(child: _buildStatMetric(
                  '\u{2705}', // ✅
                  '${stats.totalCheckIns}',
                  '\u7b7e\u5230', // 签到
                  '\u72ec\u7acb\u4e8e\u5b66\u4e60\u65e5', // 独立于学习日 (sub-label)
                )),
              ],
            ),
            const SizedBox(height: MeowSpacing.sm),
            // Streak: explicitly labeled with basis, separated from learning_days
            Row(
              children: [
                const Text('\u{1f525}', style: TextStyle(fontSize: 12)), // 🔥
                const SizedBox(width: 4),
                Text(
                  StreakDisplay.streakText(stats.currentStreak),
                  style: MeowTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Text(
                  StreakDisplay.basisLabelParens,
                  style: MeowTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// P3P3: Stat metric with optional sub-label for truth-boundary clarity.
  Widget _buildStatMetric(String emoji, String value, String label, String? subLabel) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(value, style: MeowTextStyles.title.copyWith(fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: MeowTextStyles.caption),
        if (subLabel != null) ...[
          const SizedBox(height: 1),
          Text(subLabel, style: MeowTextStyles.caption.copyWith(fontSize: 9, color: MeowColors.textHint)),
        ],
      ],
    );
  }

  // ==================== 8. Actions Section ====================

  Widget _buildActionsSection() {
    return Column(
      children: [
        // Feed button — primary action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            key: const Key('meow-home-feed-button'),
            onPressed: _isFeeding ? null : _feedCat,
            icon: _isFeeding
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('🐟', style: TextStyle(fontSize: 18)),
            label: Text(_isFeeding ? '喂食中...' : '喂小鱼干'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: MeowColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: MeowRadius.buttonRadius),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: MeowSpacing.md),
        // Secondary actions row
        Row(
          children: [
            // Interact button — pure frontend feedback
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('meow-home-interact-button'),
                onPressed: _interactCooldown ? null : _handleInteract,
                icon: Text(_interactCooldown ? '😌' : '🐾', style: const TextStyle(fontSize: 16)),
                label: Text(_interactCooldown ? '正在享受~' : '摸摸它'),
              ),
            ),
            const SizedBox(width: MeowSpacing.md),
            // Customize entry
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('meow-home-customize-button'),
                onPressed: () async {
                  await Navigator.pushNamed(context, AppRouter.customize);
                  _loadSummary();
                },
                icon: const Text('\u2728', style: TextStyle(fontSize: 16)), // ✨
                label: const Text('\u88c5\u626e\u4e0e\u5c0f\u7aa9'), // 装扮与小窝
              ),
            ),
          ],
        ),
        const SizedBox(height: MeowSpacing.sm),
        // P3.1: Settings / backup entry — minimal, not a sync center
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            key: const Key('meow-home-settings-button'),
            onPressed: () => Navigator.pushNamed(context, AppRouter.settings),
            icon: const Text('\u2699\ufe0f', style: TextStyle(fontSize: 14)), // ⚙️
            label: Text(
              '\u8bbe\u7f6e\u4e0e\u5907\u4efd', // 设置与备份
              style: MeowTextStyles.caption.copyWith(color: MeowColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
