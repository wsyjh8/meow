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
import '../../core/storage/local_settings_service.dart';
import '../../shared/theme.dart';
import '../../shared/animations.dart';
import '../../shared/widgets/meow_card.dart';
import '../../shared/widgets/meow_chip.dart';
import '../../shared/helpers/streak_display.dart';

/// TodayPage — Option B Phase 3 redesign + B23-B change_highlights consumption.
///
/// Learning CTA is always the strongest element.
/// Companion Card is warm but subordinate.
/// B23-B: change_highlights[] shown in Companion Card Layer 2 (max 2).
class TodayPage extends StatefulWidget {
  const TodayPage({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();

  TodayState? _todayState;
  SecondarySummary? _secondarySummary; // B23-B: for change_highlights consumption
  bool _isLoading = true;
  String? _error;

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
    setState(() { _isLoading = true; _error = null; });
    try {
      // Today state: local-first via LocalTodayService.
      // future: cloud verification — getToday() retained for hybrid mode.
      final userId = AuthScope.currentUserIdOf(context);
      final prefs = await SharedPreferences.getInstance();
      late TodayState todayState;
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
        // Local service failed — fall back to cloud API.
        todayState = await _apiClient.getToday();
      }

      // Secondary summary: cloud-only (rewards/cat state — not migrated).
      SecondarySummary? secondary;
      try {
        secondary = await _apiClient.getSecondarySummary();
      } catch (_) {
        secondary = SecondarySummary(
          coins: 0, fishTreats: 0, exp: 0,
          catSummary: CatSummary(nickname: 'Mimi', level: 1, mood: 60, bond: 0, energy: 'medium'),
        );
      }

      if (mounted) {
        setState(() {
          _todayState = todayState;
          _secondarySummary = secondary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _openMeowHome() {
    Navigator.pushNamed(context, AppRouter.meowHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeowColors.background,
      appBar: AppBar(
        title: const Text('今日'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _todayState == null
                  ? const Center(child: Text('暂无今日数据'))
                  : _buildContent(_todayState!),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: MeowColors.error),
            const SizedBox(height: 16),
            Text('加载失败', style: MeowTextStyles.subtitle),
            const SizedBox(height: 8),
            Text(_error!, style: MeowTextStyles.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(TodayState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MeowSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===== 1. Primary CTA — always on top, always strongest =====
          _buildPrimaryCTA(state),
          const SizedBox(height: MeowSpacing.md),

          // ===== 2. Today Goals Card =====
          _buildGoalsCard(state),
          const SizedBox(height: MeowSpacing.md),

          // ===== 3. Review Deeper Summary (P3 Phase 2) / fallback to C2 =====
          _buildReviewDeeperBlock(state),

          // ===== 4. Check-in & Streak =====
          _buildCheckInStreakCard(state),
          const SizedBox(height: MeowSpacing.md),

          // ===== 5. Session (if active) =====
          if (state.sessionStartedToday || state.sessionValidToday) ...[
            _buildSessionCard(state),
            const SizedBox(height: MeowSpacing.md),
          ],

          // ===== 6. Companion Card — warm, subordinate =====
          _buildCompanionCard(state),
          const SizedBox(height: MeowSpacing.md),

          // ===== 7. Settlement承接 (if any) =====
          if (state.lastRewardSettlement != null) ...[
            _buildSettlementCard(state.lastRewardSettlement!),
            const SizedBox(height: MeowSpacing.md),
          ],

          const SizedBox(height: MeowSpacing.xxl),
        ],
      ),
    );
  }

  // ==================== 1. Primary CTA (P3 Phase 1: contract-driven + Option C fallback) ====================
  //
  // P3 Phase 1: When today_primary_action is present (action + reason both valid),
  // use backend decision-support. Otherwise fall back to Option C CTA baseline.
  //
  // This is NOT a big CTA engine. Only `action` + `reason`.
  // priority_band / blocking_condition are NOT consumed this round.

  /// Resolve CTA: contract-driven when present, Option C baseline when absent.
  _CtaWinner _resolveCtaWinner(TodayState state) {
    final contract = state.todayPrimaryAction;

    // P3 Phase 1: If contract present (both action + reason valid), use it.
    if (contract != null) {
      return _resolveFromContract(contract, state);
    }

    // Fallback: Option C CTA baseline (contract absent / delayed / degraded / invalid)
    return _resolveOptionCBaseline(state);
  }

  /// P3 Phase 1: Resolve CTA from backend decision-support block.
  _CtaWinner _resolveFromContract(TodayPrimaryActionData contract, TodayState state) {
    switch (contract.action) {
      case 'continue_review_group':
        return _CtaWinner(
          label: '继续本组复习 (剩余${state.activeReviewGroupRemaining}词)',
          icon: '🔄',
          route: AppRouter.review,
          accentColor: MeowColors.info,
          reason: contract.reason,
          reasonLine: _reasonLabel(contract.reason),
        );
      case 'go_review':
        return _CtaWinner(
          label: '先去复习',
          icon: '🔄',
          route: AppRouter.review,
          accentColor: MeowColors.info,
          reason: contract.reason,
          reasonLine: _reasonLabel(contract.reason),
        );
      case 'go_session':
        return _CtaWinner(
          label: '继续专注',
          icon: '⏱️',
          route: AppRouter.session,
          accentColor: MeowColors.warning,
          reason: contract.reason,
          reasonLine: _reasonLabel(contract.reason),
        );
      case 'go_new_words':
      default:
        return _CtaWinner(
          label: state.dailyGoalStatus == 'not_started' ? '开始今日学习' : '继续学习',
          icon: '📚',
          route: AppRouter.study,
          accentColor: MeowColors.primary,
          reason: contract.reason,
          reasonLine: _reasonLabel(contract.reason),
        );
    }
  }

  /// Option C CTA baseline — used when contract is absent/delayed/degraded/invalid.
  _CtaWinner _resolveOptionCBaseline(TodayState state) {
    if (state.activeReviewGroupId != null && state.activeReviewGroupRemaining > 0) {
      return _CtaWinner(
        label: '继续本组复习 (剩余${state.activeReviewGroupRemaining}词)',
        icon: '🔄',
        route: AppRouter.review,
        accentColor: MeowColors.info,
        reason: 'active_review_group',
      );
    }
    if (state.todayReviewPending > 0) {
      return _CtaWinner(
        label: '先去复习',
        icon: '🔄',
        route: AppRouter.review,
        accentColor: MeowColors.info,
        reason: 'review_pending',
      );
    }
    if (state.dailyGoalStatus == 'completed') {
      return _CtaWinner(
        label: '今日目标已完成 ✅',
        icon: '📚',
        route: AppRouter.study,
        accentColor: MeowColors.success,
        reason: 'goal_completed',
      );
    }
    return _CtaWinner(
      label: state.dailyGoalStatus == 'not_started' ? '开始今日学习' : '继续学习',
      icon: '📚',
      route: AppRouter.study,
      accentColor: MeowColors.primary,
      reason: 'new_words',
    );
  }

  /// P3 Phase 1: Map reason to supporting display line (weak hint, not badge).
  String? _reasonLabel(String reason) {
    switch (reason) {
      case 'active_review_group': return '有未完成的复习组';
      case 'review_due_priority': return '有待复习的内容';
      case 'new_words_remaining': return '继续今日新词目标';
      case 'session_pending': return '专注尚未完成';
      default: return null;
    }
  }

  Widget _buildPrimaryCTA(TodayState state) {
    final winner = _resolveCtaWinner(state);

    return MeowCard(
      color: winner.accentColor.withValues(alpha: 0.06),
      borderColor: winner.accentColor.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(winner.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(state.currentBookName, style: MeowTextStyles.title),
              const Spacer(),
              _buildGoalStatusChip(state.dailyGoalStatus),
            ],
          ),
          const SizedBox(height: MeowSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('today-primary-study-cta'),
              onPressed: () => Navigator.pushNamed(context, winner.route),
              style: ElevatedButton.styleFrom(
                backgroundColor: winner.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              child: Text(winner.label),
            ),
          ),
          // P3 Phase 1: Optional reason line (weak supporting hint, not a badge)
          if (winner.reasonLine != null) ...[
            const SizedBox(height: MeowSpacing.sm),
            Text(
              winner.reasonLine!,
              style: MeowTextStyles.caption.copyWith(color: MeowColors.textHint),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== 2. Goals Card ====================

  Widget _buildGoalsCard(TodayState state) {
    return MeowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('今日目标', style: MeowTextStyles.label),
          const SizedBox(height: MeowSpacing.md),
          _buildProgressRow('📖 新词', state.todayNewCompleted, state.todayNewTarget),
          const SizedBox(height: MeowSpacing.sm),
          // C2: Label clarifies this is group-count progress, not item-count
          _buildProgressRow('🔄 复习组', state.todayReviewCompleted, state.todayReviewTarget),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int completed, int target) {
    final progress = target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: MeowTextStyles.bodySmall)),
        Expanded(
          child: MeowAnimatedProgress(
            value: progress,
            color: progress >= 1.0 ? MeowColors.success : MeowColors.primary,
            height: 8,
          ),
        ),
        const SizedBox(width: 8),
        Text('$completed/$target', style: MeowTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ==================== 3. Review Group ====================

  Widget _buildReviewGroupCard(TodayState state) {
    return MeowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔄', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('当前复习组', style: MeowTextStyles.label),
              const Spacer(),
              MeowChip(label: '剩余 ${state.activeReviewGroupRemaining} 词', variant: MeowChipVariant.info, small: true),
            ],
          ),
          // C1: No competing CTA button here — primary CTA already handles review.
        ],
      ),
    );
  }

  // ==================== 3. Review Deeper Block (P3 Phase 2) ====================
  // Shows review deeper state when contract present. Falls back to C2 baseline when absent.
  // Does NOT change CTA winner — that stays in _resolveCtaWinner().

  Widget _buildReviewDeeperBlock(TodayState state) {
    final summary = state.reviewSummary;

    // Contract absent → fall back to C2 baseline behavior
    if (summary == null) {
      // C2 fallback: show review group card or progress note
      if (state.activeReviewGroupId != null && state.activeReviewGroupRemaining > 0) {
        return Padding(
          padding: const EdgeInsets.only(bottom: MeowSpacing.md),
          child: _buildReviewGroupCard(state),
        );
      }
      if (state.todayReviewCompleted > 0 && state.todayReviewCompleted < state.todayReviewTarget) {
        return Padding(
          padding: const EdgeInsets.only(bottom: MeowSpacing.md),
          child: _buildReviewProgressNote(state),
        );
      }
      return const SizedBox.shrink();
    }

    // Contract present → show deeper summary
    return Padding(
      padding: const EdgeInsets.only(bottom: MeowSpacing.md),
      child: MeowCard(
        key: const Key('today-review-deeper-block'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('\u{1f504}', style: TextStyle(fontSize: 16)), // 🔄
                const SizedBox(width: 6),
                Text('\u590d\u4e60\u8fdb\u5ea6', style: MeowTextStyles.label), // 复习进度
                const Spacer(),
                if (summary.activeGroupCompleted)
                  const MeowChip(label: '\u672c\u7ec4\u5df2\u5b8c\u6210', variant: MeowChipVariant.success, small: true), // 本组已完成
              ],
            ),
            const SizedBox(height: MeowSpacing.sm),
            // Group progress
            if (summary.hasActiveGroup || summary.activeGroupCompleted)
              _buildProgressRow(
                '\u{1f4d6} \u672c\u7ec4', // 📖 本组
                summary.completedItems,
                summary.totalItems,
              ),
            const SizedBox(height: MeowSpacing.xs),
            // Daily review progress — SEPARATE from group progress
            _buildProgressRow(
              '\u{1f4c5} \u4eca\u65e5\u590d\u4e60', // 📅 今日复习
              summary.completedUnits,
              summary.requiredUnits,
            ),
            // Next group readiness (weak hint only)
            if (summary.nextGroupReadiness == 'ready' && !summary.hasActiveGroup) ...[
              const SizedBox(height: MeowSpacing.sm),
              Text(
                '\u53ef\u4ee5\u5f00\u59cb\u4e0b\u4e00\u7ec4\u590d\u4e60', // 可以开始下一组复习
                style: MeowTextStyles.caption.copyWith(color: MeowColors.info),
              ),
            ],
            if (summary.nextGroupReadiness == 'not_ready' && summary.activeGroupCompleted) ...[
              const SizedBox(height: MeowSpacing.sm),
              Text(
                '\u4e0b\u4e00\u7ec4\u662f\u5426\u53ef\u7528\uff0c\u4ee5\u540e\u7aef\u5224\u65ad\u4e3a\u51c6', // 下一组是否可用，以后端判断为准
                style: MeowTextStyles.caption.copyWith(color: MeowColors.textHint),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== 3b. Review Progress Note (C2) ====================
  // Shows when group is done but daily review target not yet met.
  // Frozen rule: group completion ≠ daily review completion.

  Widget _buildReviewProgressNote(TodayState state) {
    return MeowCard(
      child: Row(
        children: [
          const Text('🔄', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '已完成 ${state.todayReviewCompleted}/${state.todayReviewTarget} 组复习',
              style: MeowTextStyles.bodySmall,
            ),
          ),
          MeowChip(
            label: '进行中',
            variant: MeowChipVariant.info,
            small: true,
          ),
        ],
      ),
    );
  }

  // ==================== 4. Check-in & Streak ====================

  Widget _buildCheckInStreakCard(TodayState state) {
    return MeowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('签到与坚持', style: MeowTextStyles.label),
            ],
          ),
          const SizedBox(height: MeowSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: state.hasCheckedInToday ? '✅' : '⬜',
                  label: '今日签到',
                  value: state.hasCheckedInToday ? '已签到' : '未签到',
                  variant: state.hasCheckedInToday ? MeowChipVariant.success : MeowChipVariant.neutral,
                ),
              ),
              const SizedBox(width: MeowSpacing.md),
              Expanded(
                child: _buildStatItem(
                  icon: state.learningDayToday ? '✅' : '⬜',
                  label: '学习日',
                  value: state.learningDayToday ? '有效' : '未达成',
                  variant: state.learningDayToday ? MeowChipVariant.success : MeowChipVariant.neutral,
                ),
              ),
            ],
          ),
          const SizedBox(height: MeowSpacing.md),
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                StreakDisplay.streakText(state.currentStreak),
                style: MeowTextStyles.title.copyWith(color: MeowColors.primary),
              ),
              const SizedBox(width: 6),
              Text(StreakDisplay.basisLabelParens, style: MeowTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String label,
    required String value,
    required MeowChipVariant variant,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label, style: MeowTextStyles.caption),
          ],
        ),
        const SizedBox(height: 4),
        MeowChip(label: value, variant: variant, small: true),
      ],
    );
  }

  // ==================== 5. Session Card ====================

  Widget _buildSessionCard(TodayState state) {
    return MeowCard(
      child: Row(
        children: [
          Text(state.sessionValidToday ? '✅' : '⏳', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: MeowSpacing.sm),
          Expanded(
            child: Text(
              state.sessionValidToday ? '今日已有有效 Session' : 'Session 进行中 / 待确认',
              style: MeowTextStyles.body.copyWith(
                color: state.sessionValidToday ? MeowColors.success : MeowColors.info,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 6. Companion Card (B2-1B: two-layer) ====================

  Widget _buildCompanionCard(TodayState state) {
    return MeowCardWarm(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Layer 1: Greeting + companion copy ---
          Row(
            children: [
              const Text('🐱', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('喵喵在等你~', style: MeowTextStyles.label.copyWith(color: MeowColors.primaryDark)),
              const Spacer(),
            ],
          ),
          const SizedBox(height: MeowSpacing.sm),
          Text(
            _getCompanionCardCopy(state.dailyGoalStatus),
            style: MeowTextStyles.bodySmall.copyWith(color: MeowColors.textSecondary),
          ),

          // --- Layer 2: Changes chips + highlights + goal cues ---
          const SizedBox(height: MeowSpacing.md),
          _buildChangesChips(state),

          // --- B23-B: change_highlights (max 2, read-only summary/hint) ---
          _buildChangeHighlights(),

          // --- Weak goal cue ---
          if (state.dailyGoalStatus != 'completed') ...[
            const SizedBox(height: MeowSpacing.sm),
            _buildGoalCue(state),
          ],

          // --- Entry button ---
          const SizedBox(height: MeowSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('today-meow-home-entry'),
              onPressed: _openMeowHome,
              icon: const Text('🐾', style: TextStyle(fontSize: 14)),
              label: Text(
                state.lastRewardSettlement != null
                    ? '去看看今天的小变化'
                    : '去看看喵喵',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: MeowColors.primaryDark,
                side: BorderSide(color: MeowColors.primaryLight.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// B2-1B: Changes chips — show what's happened today using existing backend fields.
  /// All data from TodayState (direct existing backend fields). No fabricated history.
  Widget _buildChangesChips(TodayState state) {
    final chips = <Widget>[];

    // Check-in status (direct backend field)
    if (state.hasCheckedInToday) {
      chips.add(const MeowChip(label: '✅ 已签到', variant: MeowChipVariant.success, small: true));
    }

    // Learning day (direct backend field)
    if (state.learningDayToday) {
      chips.add(const MeowChip(label: '📖 有效学习日', variant: MeowChipVariant.primary, small: true));
    }

    // Session valid (direct backend field)
    if (state.sessionValidToday) {
      chips.add(const MeowChip(label: '⏱️ 有效专注', variant: MeowChipVariant.info, small: true));
    }

    // Streak (direct backend field) — C4: explicitly note basis for consistency
    if (state.currentStreak > 0) {
      chips.add(MeowChip(label: StreakDisplay.streakChipLabel(state.currentStreak), variant: MeowChipVariant.warning, small: true));
    }

    // Goal progress (direct backend field)
    if (state.todayNewCompleted > 0) {
      chips.add(MeowChip(label: '📝 学了${state.todayNewCompleted}词', variant: MeowChipVariant.neutral, small: true));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }

  // ==================== B23-B: Change Highlights (max 2) ====================
  // Read-only summary/hint layer. NOT a new truth layer.
  // `label` is display copy — UI must not use it to override truth layers.

  /// Fallback copy when no highlights available (B23-B).
  static const _noHighlightsFallback = [
    '今天继续学一点，它也许会有新变化~',
    '每一点积累，都会有小惊喜~',
    '坚持就有变化，喵喵等着呢~',
  ];

  Widget _buildChangeHighlights() {
    final highlights = _secondarySummary?.changeHighlights ?? [];
    final displayHighlights = highlights.take(2).toList(); // Max 2 for Today

    // Fallback: no highlights → warm fallback copy (not blank)
    if (displayHighlights.isEmpty) {
      final fallback = _noHighlightsFallback[Random().nextInt(_noHighlightsFallback.length)];
      return Padding(
        padding: const EdgeInsets.only(top: MeowSpacing.sm),
        child: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                fallback,
                style: MeowTextStyles.caption.copyWith(
                  color: MeowColors.textHint,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: MeowSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: displayHighlights.map((h) => _buildHighlightRow(h)).toList(),
      ),
    );
  }

  Widget _buildHighlightRow(ChangeHighlightData highlight) {
    // hinted: neutral, suggestive ("也许", "可以看看")
    // confirmed: warm, light summary (not replacement for truth)
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
              '待确认',
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
      case 'purchase': return '🛍️';
      case 'equip': return '✨';
      case 'growth': return '⬆️';
      case 'streak': return '🔥';
      case 'post_learning': return '📖';
      default: return '💡';
    }
  }

  /// B2-1B: Light goal cue — encouragement based on current progress.
  /// Pure frontend static content layer. Not a business promise.
  Widget _buildGoalCue(TodayState state) {
    // Goal cue copy pools (B2-1B)
    const cueNewWords = [
      '再学几个新词，喵喵的小鱼干就更多啦~',
      '多认识几个单词，今天会更充实~',
      '离今日目标又近了一步~',
    ];
    const cueReview = [
      '复习一组，记忆就更牢固了~',
      '温故而知新，喵喵也在旁边陪你~',
    ];
    const cueGeneral = [
      '每一点进步，喵喵都看在眼里~',
      '坚持下去，好事会慢慢发生~',
      '今天再做一点点就很棒了~',
    ];

    String cue;
    final r = Random();
    if (state.todayNewCompleted < state.todayNewTarget && state.todayNewTarget > 0) {
      cue = cueNewWords[r.nextInt(cueNewWords.length)];
    } else if (state.todayReviewCompleted < state.todayReviewTarget && state.todayReviewTarget > 0) {
      cue = cueReview[r.nextInt(cueReview.length)];
    } else {
      cue = cueGeneral[r.nextInt(cueGeneral.length)];
    }

    return Row(
      children: [
        const Text('💡', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            cue,
            style: MeowTextStyles.caption.copyWith(
              color: MeowColors.primaryDark.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== 7. Settlement Card (B2-1B: lighter承接) ====================

  Widget _buildSettlementCard(LastRewardSettlement settlement) {
    MeowChipVariant chipVariant;
    String statusText;
    String followUp;

    switch (settlement.rewardSettlementStatus) {
      case 'succeeded':
        chipVariant = MeowChipVariant.success;
        statusText = '学习结果已记录';
        followUp = '今天的努力已经有回报了~';
        break;
      case 'settling':
        chipVariant = MeowChipVariant.info;
        statusText = '奖励正在刷新';
        followUp = '稍等一下，好东西在路上~';
        break;
      case 'failed':
        chipVariant = MeowChipVariant.warning;
        statusText = '奖励仍在同步';
        followUp = '还在处理中，不用担心~';
        break;
      default:
        chipVariant = MeowChipVariant.neutral;
        statusText = '结算状态待更新';
        followUp = '';
    }

    return MeowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎁', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              MeowChip(label: statusText, variant: chipVariant, small: true),
              const Spacer(),
              TextButton(
                key: const Key('today-meow-home-secondary-entry'),
                onPressed: _openMeowHome,
                child: Text('去看看变化 \u2192', style: MeowTextStyles.bodySmall.copyWith(color: MeowColors.primary)),
              ),
            ],
          ),
          // B23-C: Settlement bridge — max 2 highlight items as light bridge
          _buildSettlementBridge(),
          if (settlement.rewardSettlementStatus == 'succeeded') ...[
            const SizedBox(height: 4),
            Text(
              followUp,
              style: MeowTextStyles.caption.copyWith(color: MeowColors.textHint),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== B23-C: Settlement Bridge (max 2) ====================
  // Light bridge — "go see today's changes". Not a new settlement layer.

  Widget _buildSettlementBridge() {
    final highlights = _secondarySummary?.changeHighlights ?? [];
    final bridgeItems = highlights.take(2).toList(); // Default 1, max 2

    if (bridgeItems.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: bridgeItems.map((h) {
          final icon = _highlightKindIcon(h.kind);
          final isConfirmed = h.status == 'confirmed';
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    h.label,
                    style: MeowTextStyles.caption.copyWith(
                      color: isConfirmed ? MeowColors.textSecondary : MeowColors.textHint,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isConfirmed) ...[
                  const SizedBox(width: 3),
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
        }).toList(),
      ),
    );
  }

  // ==================== Helpers ====================

  // Today Companion Card copy pools (B2-1A expansion)
  static const _companionCompleted = [
    '今天学得好棒，去看看喵喵的变化吧~',
    '任务全搞定！喵喵为你感到骄傲~',
    '圆满完成~ 快去看看喵喵开不开心~',
    '你太厉害了！喵喵想给你一个拥抱~',
  ];
  static const _companionNotStarted = [
    '学完今天的任务，喵喵会更开心哦~',
    '喵喵在等你开始呢，加油~',
    '新的一天，一起来学点东西吧~',
    '先去学习，回来喵喵给你惊喜~',
  ];
  static const _companionInProgress = [
    '已经做得很不错了，喵喵在为你加油~',
    '继续努力，喵喵在旁边陪着你~',
    '你正在进步中，我看到了哦~',
    '慢慢来不着急，喵喵等你~',
  ];

  String _getCompanionCardCopy(String goalStatus) {
    final r = Random();
    switch (goalStatus) {
      case 'completed':
        return _companionCompleted[r.nextInt(_companionCompleted.length)];
      case 'not_started':
        return _companionNotStarted[r.nextInt(_companionNotStarted.length)];
      default:
        return _companionInProgress[r.nextInt(_companionInProgress.length)];
    }
  }

  Widget _buildGoalStatusChip(String status) {
    MeowChipVariant variant;
    String label;

    switch (status) {
      case 'completed':
        variant = MeowChipVariant.success;
        label = '今日完成';
        break;
      case 'partially_completed':
        variant = MeowChipVariant.info;
        label = '部分完成';
        break;
      case 'in_progress':
        variant = MeowChipVariant.warning;
        label = '进行中';
        break;
      case 'not_started':
      default:
        variant = MeowChipVariant.neutral;
        label = '未开始';
    }

    return MeowChip(label: label, variant: variant, small: true);
  }
}

/// CTA winner result — holds the resolved single strongest CTA.
/// P3 Phase 1: May be driven by backend contract (action+reason) or Option C baseline fallback.
class _CtaWinner {
  final String label;
  final String icon;
  final String route;
  final Color accentColor;
  final String reason;
  final String? reasonLine; // P3 Phase 1: optional weak supporting hint (null = not shown)

  const _CtaWinner({
    required this.label,
    required this.icon,
    required this.route,
    required this.accentColor,
    required this.reason,
    this.reasonLine,
  });
}
