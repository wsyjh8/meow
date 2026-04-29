import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/memory/fsrs_service.dart';
import '../../core/services/local_today_service.dart';
import '../../core/serving/home_review_helper_summary.dart';
import '../../core/storage/drift/app_database.dart';
import '../../core/storage/local_database.dart';
import '../../core/storage/local_settings_service.dart';
import '../theme/tokens.dart';
import '../icons/mochi_illustrations.dart';
import '../widgets/spec_cards.dart';

/// SPEC 6.1 — Home Page (首页)
///
/// Information hierarchy (top to bottom):
/// 1. Greeting + current textbook + user avatar
/// 2. Mochi check-in card (warmth engine)
/// 3. Main CTA: Continue learning (visual center)
/// 4. Two number cards: book progress / wrong words
/// 5. 5-minute quick review entry
class SpecHomePage extends StatefulWidget {
  const SpecHomePage({super.key});

  @override
  State<SpecHomePage> createState() => _SpecHomePageState();
}

class _SpecHomePageState extends State<SpecHomePage> {
  final ApiClient _apiClient = ApiClient();
  TodayState? _todayState;
  SecondarySummary? _summary;
  bool _isLoading = true;
  // Learning statistics (all-time, not today-only)
  int _totalMastered = 0;   // 总学习单词: globally unique mastered word count
  int _bookMastered  = 0;   // 本书单词: mastered count scoped to active book
  int _totalInBook   = 0;   // total words in current book (denominator)
  String _activeBookName = 'CET-4 核心词汇';  // displayed in greeting area

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

    // 1. Secondary summary: cloud-only (rewards/cat state — not migrated).
    SecondarySummary? summary;
    try {
      summary = await _apiClient.getSecondarySummary();
    } catch (_) {}

    // 2. Today state: local-first via LocalTodayService, cloud fallback.
    //    This block is intentionally isolated — its failures must not mask stats.
    TodayState? todayState;
    try {
      final prefs = await SharedPreferences.getInstance();
      final appDb = AppDatabase();
      todayState = await LocalTodayService(
        prefs: prefs,
        localDb: LocalDatabase.instance,
        fsrs: FsrsService(db: appDb),
        driftDb: appDb,
      ).getTodayState();
    } catch (_) {
      try { todayState = await _apiClient.getToday(); } catch (_) {}
    }

    // 3. Learning statistics — independent try-catch so a today-state failure
    //    never causes stats to silently stay at 0.
    int totalMastered = 0;
    int bookMastered  = 0;
    int totalInBook   = 0;
    String activeBookName = 'CET-4 核心词汇';
    try {
      final prefs = await SharedPreferences.getInstance();
      final appDb = AppDatabase();
      final activeBook = LocalSettingsService(prefs).activeWordbook;
      activeBookName = _bookDisplayName(activeBook);
      final masteredIds = await LocalDatabase.instance.getMasteredWordIds();
      totalMastered = masteredIds.length;
      // Per-book count: app-level intersection (sqflite ∩ drift — can't SQL JOIN).
      final bookWordIds = await appDb.getWordIdsForBook(activeBook);
      bookMastered = masteredIds.intersection(bookWordIds).length;
      totalInBook = await appDb.countWordsInBook(activeBook);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _todayState = todayState;
        _summary = summary;
        _totalMastered = totalMastered;
        _bookMastered  = bookMastered;
        _totalInBook   = totalInBook;
        _activeBookName = activeBookName;
        _isLoading = false;
      });
    }
  }

  static String _bookDisplayName(String slug) => switch (slug) {
    'book-001' => 'CET-4 核心词汇',
    'zk'       => '中考',
    'gk'       => '高考',
    _          => slug,
  };

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
        child: RefreshIndicator(
          color: SpecBrand.purple,
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 6.1.2 Greeting area
                _buildGreeting(),
                // 6.1.3 Mochi check-in card
                _buildMochiCard(),
                // P3.3: "背单词" primary entry
                _buildStudyEntry(),
                // 6.1.4 Main CTA (task progress)
                _buildMainCTA(),
                // 6.1.5 Number cards
                _buildNumberCards(),
                // 6.1.6 Quick review entry
                _buildQuickReview(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 6.1.2 Greeting ====================

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour >= 5 && hour < 11) {
      greeting = '早上好';
    } else if (hour >= 11 && hour < 13) {
      greeting = '中午好';
    } else if (hour >= 13 && hour < 18) {
      greeting = '下午好';
    } else if (hour >= 18 && hour < 23) {
      greeting = '晚上好';
    } else {
      greeting = '夜深了';
    }

    final bookName = _activeBookName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 12, SpecSpacing.pageH, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: greeting + book name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting',
                style: const TextStyle(fontSize: 13, fontWeight: SpecTypo.regular, color: SpecText.secondary),
              ),
              const SizedBox(height: 2),
              Text(
                bookName,
                style: const TextStyle(fontSize: 15, fontWeight: SpecTypo.medium, color: SpecText.primary),
              ),
            ],
          ),
          // Right: user avatar (clickable → profile)
          GestureDetector(
            onTap: () {}, // Navigate to profile — handled by tab bar
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: SpecBg.card,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'U',
                  style: TextStyle(fontSize: 13, fontWeight: SpecTypo.medium, color: SpecText.purple),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 6.1.3 Mochi Check-in Card ====================

  Widget _buildMochiCard() {
    final streak = _todayState?.currentStreak ?? 0;
    final hasStudied = _todayState?.learningDayToday ?? false;

    String status;
    if (hasStudied) {
      status = '今天已经一起学过啦';
    } else if (streak == 0) {
      status = '好久不见';
    } else {
      status = '今天还没见面';
    }

    // Hours since "last open" — simplified: use current hour as proxy
    final waitHours = DateTime.now().hour;

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 8, SpecSpacing.pageH, 16),
      child: SpecCardMochiWarm(
        onTap: () {}, // Navigate to Mochi page — handled by tab bar
        child: Row(
          children: [
            const MochiAvatar(size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mochi 等了你 $waitHours 小时',
                    style: const TextStyle(fontSize: 13, fontWeight: SpecTypo.medium, color: SpecText.mochi),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '连续陪伴 $streak 天 · $status',
                    style: const TextStyle(fontSize: 11, fontWeight: SpecTypo.regular, color: SpecText.coral),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== P3.3 / P3.3.2: 背单词 Primary Entry ====================
  // session_entry_policy_v1 (FROZEN, P3.3.2):
  //   home_word_entry = study_default
  //   "背单词" → StudyPage is the default entry, always.
  //   This is NOT a review dispatcher. NOT a mixed/auto-routing dispatcher.
  //   active review_group continuation is expressed via the independent
  //   review CTA in _buildQuickReview(), NOT by rerouting this button.
  //   If auto-routing / mixed dispatch is ever needed, it must be pinned
  //   in a separate round — never silently added here.

  Widget _buildStudyEntry() {
    final completedNew = _todayState?.todayNewCompleted ?? 0;
    final targetNew = _todayState?.todayNewTarget ?? 20;
    final isGoalMet = _todayState != null && completedNew >= targetNew && targetNew > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 12),
      child: SpecCardHero(
        showPawPrint: true,
        // session_entry_policy_v1 (FROZEN, P3.3.2): routes to StudyPage.
        // Guard: no entry when daily new-word goal already met.
        onTap: isGoalMet
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 今日单词已学完，明天继续加油！'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                )
            : () => Navigator.pushNamed(context, '/study'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '背单词',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: SpecTypo.medium,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isGoalMet ? '今日单词已学完 ✓' : '开始今天的学习',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: SpecTypo.regular,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            Icon(
              isGoalMet ? Icons.check_circle_outline_rounded : Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 6.1.4 Main CTA ====================

  Widget _buildMainCTA() {
    final newTarget = _todayState?.todayNewTarget ?? 20;
    final reviewTarget = _todayState?.todayReviewTarget ?? 0;
    final completedNew = _todayState?.todayNewCompleted ?? 0;
    final completedReview = _todayState?.todayReviewCompleted ?? 0;
    final totalCompleted = completedNew + completedReview;
    final progress = newTarget > 0 ? (completedNew / newTarget).clamp(0.0, 1.0) : 0.0;
    final isCompleted = _todayState != null &&
        (completedNew >= newTarget && newTarget > 0 ||
            _todayState!.dailyGoalStatus == 'completed');

    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 18),
      child: SpecCardHero(
        showPawPrint: true,
        onTap: isCompleted
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 今日任务已完成，休息一下吧！'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                )
            : () => Navigator.pushNamed(context, '/study'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top label
            Text(
              '今日任务',
              style: TextStyle(fontSize: 12, fontWeight: SpecTypo.regular, color: Colors.white.withValues(alpha: 0.78)),
            ),
            const SizedBox(height: 6),
            // Main title
            Text(
              isCompleted ? '今天已完成 ✓' : '继续学习',
              style: const TextStyle(fontSize: 22, fontWeight: SpecTypo.medium, color: Colors.white, height: 1.2),
            ),
            const SizedBox(height: 12),
            // Metadata row: show today's actual completed counts
            Row(
              children: [
                _ctaMeta('今日已学 $totalCompleted 词'),
                const SizedBox(width: 16),
                _ctaMeta('新词 $completedNew/$newTarget'),
                const SizedBox(width: 16),
                _ctaMeta('复习 $completedReview/$reviewTarget'),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctaMeta(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: SpecTypo.regular, color: Colors.white.withValues(alpha: 0.78)),
    );
  }

  // ==================== 6.1.5 Number Cards ====================

  Widget _buildNumberCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 16),
      child: Row(
        children: [
          // 总学习单词: globally unique mastered count across all books.
          Expanded(
            child: SpecCardFilled(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '总学习单词',
                    style: TextStyle(fontSize: 11, fontWeight: SpecTypo.regular, color: SpecText.secondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$_totalMastered',
                    style: const TextStyle(fontSize: 15, fontWeight: SpecTypo.medium, color: SpecText.purple),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 本书单词: mastered count scoped to the current active book.
          Expanded(
            child: SpecCardFilled(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '本书单词',
                    style: TextStyle(fontSize: 11, fontWeight: SpecTypo.regular, color: SpecText.secondary),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$_bookMastered',
                          style: const TextStyle(fontSize: 15, fontWeight: SpecTypo.medium, color: SpecText.purple),
                        ),
                        TextSpan(
                          text: ' / $_totalInBook',
                          style: const TextStyle(fontSize: 12, fontWeight: SpecTypo.regular, color: SpecText.tertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 错词本: placeholder — out of scope until wrong-word feature ships.
          Expanded(
            child: SpecCardFilled(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '错词本',
                    style: TextStyle(fontSize: 11, fontWeight: SpecTypo.regular, color: SpecText.secondary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '0',
                    style: TextStyle(fontSize: 15, fontWeight: SpecTypo.medium, color: SpecText.coral),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 6.1.6 Quick Review Entry ====================
  // session_entry_policy_v1 (FROZEN, P3.3.2):
  //   This is the INDEPENDENT CTA承接 for active review_group continuation.
  //   It is SEPARATE from "背单词". Its existence does NOT make "背单词"
  //   a review dispatcher — both entries coexist independently.
  //   Currently always shown (dev simplification). If future dynamic
  //   show/hide based on active review_group state is needed, it requires
  //   a separate contract pin with Room 1.
  //
  // review_priority_policy_v1 (FROZEN, P3.3.3):
  //   Priority hierarchy: continuation > dueReview > highPriorityReview > newWords > session
  //   This CTA承接 review_group continuation at the highest priority tier.
  //   However, continuation priority ≠ silent reroute of "背单词".
  //   dueReview / highPriorityReview ONLY count if cloud-confirmed (serving-confirmed).
  //   Local FSRS due count MUST NOT be used as a priority signal here.
  //   newWords (study_default) is the stable fallback — currently the default "背单词" path.
  //   session continues at lowest priority — NOT auto-promoted.

  Widget _buildQuickReview() {
    // Dev simplification: always show. Future: conditional on active review_group.
    //
    // real_cutover_execution_subset_v1 Member 3 (FROZEN, P3.3.14):
    // Additive retained-anchor-aware review helper caption renders
    // below the existing quick review CTA. Primary route remains
    // unchanged (`study_default` is still the "背单词" button's
    // destination). This helper summary is a supplementary caption
    // only — it does NOT reroute, does NOT drive a dispatcher, and
    // does NOT claim planner-aware routing.
    return Padding(
      padding: const EdgeInsets.fromLTRB(SpecSpacing.pageH, 0, SpecSpacing.pageH, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpecCardOutlined(
            onTap: () => Navigator.pushNamed(context, '/review'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '时间不够？',
                      style: TextStyle(fontSize: 12, fontWeight: SpecTypo.regular, color: SpecText.secondary),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '5 分钟快速复习',
                      style: TextStyle(fontSize: 13, fontWeight: SpecTypo.medium, color: SpecText.primary),
                    ),
                  ],
                ),
                const Text(
                  '→',
                  style: TextStyle(fontSize: 16, color: SpecText.tertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // P3.3.14 B Member 3: retained-anchor-aware review helper
          // summary caption. The state is hard-wired to `reviewAvailable`
          // in this round — we do not yet drive it from cloud response
          // because that would touch the "home page review helper
          // summary state" layer which is not in this round's B subset.
          // Future rounds may wire state detection additively.
          const HomeReviewHelperSummaryCaption(
            state: HomeReviewHelperSummaryState.reviewAvailable,
          ),
        ],
      ),
    );
  }
}
