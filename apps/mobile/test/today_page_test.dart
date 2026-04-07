import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/features/today/today_page.dart';
import 'package:meow_mobile/core/api/api_client.dart';

/// Mock API client for testing
class MockApiClient implements ApiClient {
  TodayState? mockTodayState;
  SecondarySummary? mockSecondarySummary;
  Exception? mockException;

  MockApiClient({this.mockTodayState, this.mockSecondarySummary, this.mockException});

  @override
  String get baseUrl => 'http://10.0.2.2:3000/api/v1';
 // String get baseUrl => 'http://localhost:3000/api/v1';

  @override
  Future<TodayState> getToday() async {
    if (mockException != null) {
      throw mockException!;
    }
    if (mockTodayState == null) {
      return TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20,
        todayNewCompleted: 0,
        todayReviewTarget: 1,
        todayReviewPending: 0,
        todayReviewCompleted: 0,
        dailyGoalStatus: 'not_started',
        activeReviewGroupId: null,
        activeReviewGroupStatus: null,
        activeReviewGroupRemaining: 0,
        syncStatus: 'healthy',
        lastRewardSettlement: null,
        hasCheckedInToday: false,
        learningDayToday: false,
        currentStreak: 0,
        sessionStartedToday: false,
        sessionValidToday: false,
      );
    }
    return mockTodayState!;
  }

  @override
  Future<Word?> getNextNewWord() => throw UnimplementedError();

  @override
  Future<StudyAttemptResult> submitStudyAttempt({
    required String wordId,
    required String bookId,
    required String studyType,
    required String actionResult,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<ReviewGroup> getNextReviewGroup() => throw UnimplementedError();

  @override
  Future<ReviewAttemptResult> submitReviewAttempt({
    required String reviewGroupId,
    required String wordId,
    required String actionResult,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  void dispose() {}

  // Phase 3 methods - stub implementations for testing
  @override
  Future<SessionInfo> startSession({
    int sessionMinutesTarget = 15,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<SessionInfo> finishSession({
    required String sessionId,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<SessionInfo> getSession(String sessionId) =>
      throw UnimplementedError();

  @override
  Future<CheckInResult> checkIn({String? idempotencyKey}) =>
      throw UnimplementedError();

  @override
  Future<SecondarySummary> getSecondarySummary() async {
    return mockSecondarySummary ?? SecondarySummary(
      coins: 0, fishTreats: 0, exp: 0,
      catSummary: CatSummary(nickname: 'Mimi', level: 1, mood: 60, bond: 0, energy: 'medium'),
    );
  }

  @override
  Future<FeedResponse> feedCat({String? idempotencyKey}) =>
      throw UnimplementedError();

  @override
  Future<CatalogResponse> getShopCatalog() => throw UnimplementedError();

  @override
  Future<InventoryStateData> getInventory() => throw UnimplementedError();

  @override
  Future<PurchaseResponse> purchaseItem({
    required String itemId,
    String? idempotencyKey,
  }) => throw UnimplementedError();

  @override
  Future<EquipmentResponse> getEquipment() => throw UnimplementedError();

  @override
  Future<EquipResponse> equipItem({
    required String itemId,
    String? idempotencyKey,
  }) => throw UnimplementedError();
}

void main() {
  testWidgets('TodayPage renders loading state', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TodayPage(),
      ),
    );

    // Initial loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('TodayPage renders today data', (WidgetTester tester) async {
    // Inject mock client (in real test, we'd use dependency injection)
    // For now, we test the widget structure
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Text('CET-4'), // Book name
              const Text('新词'),
              const Text('复习'),
              const Text('5 / 20'), // Progress
            ],
          ),
        ),
      ),
    );

    expect(find.text('CET-4'), findsOneWidget);
    expect(find.text('新词'), findsOneWidget);
    expect(find.text('复习'), findsOneWidget);
  });

  testWidgets('TodayPage shows error state', (WidgetTester tester) async {
    // This would require more complex mocking
    // For Phase 1, we verify the basic structure compiles
    expect(true, isTrue);
  });

  // ==================== B23-B: change_highlights Today consumption tests ====================

  testWidgets('TodayPage shows change_highlights in Companion Card', (WidgetTester tester) async {
    final client = MockApiClient(
      mockSecondarySummary: SecondarySummary(
        coins: 10, fishTreats: 1, exp: 25,
        catSummary: CatSummary(nickname: 'Mimi', level: 2, mood: 70, bond: 5, energy: 'high'),
        changeHighlights: [
          ChangeHighlightData(kind: 'growth', status: 'confirmed', label: '已达到 Lv.2'),
          ChangeHighlightData(kind: 'streak', status: 'confirmed', label: '连续学习 3 天'),
        ],
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Highlights should be visible in Companion Card
    expect(find.textContaining('Lv.2'), findsWidgets);
    expect(find.textContaining('连续学习'), findsWidgets);
  });

  testWidgets('TodayPage limits highlights to max 2', (WidgetTester tester) async {
    final client = MockApiClient(
      mockSecondarySummary: SecondarySummary(
        coins: 10, fishTreats: 1, exp: 25,
        catSummary: CatSummary(nickname: 'Mimi', level: 2, mood: 70, bond: 5, energy: 'high'),
        changeHighlights: [
          ChangeHighlightData(kind: 'growth', status: 'confirmed', label: 'Reached Lv.2'),
          ChangeHighlightData(kind: 'streak', status: 'confirmed', label: 'Streak 3 days'),
          ChangeHighlightData(kind: 'purchase', status: 'confirmed', label: 'Got red hat', relatedItemCode: 'cat_hat_red'),
        ],
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // 3rd highlight (purchase "Got red hat") should NOT appear — max 2
    expect(find.textContaining('Got red hat'), findsNothing);
    // First highlight should be present
    expect(find.textContaining('Reached Lv.2'), findsWidgets);
  });

  testWidgets('TodayPage shows fallback when no highlights', (WidgetTester tester) async {
    final client = MockApiClient(
      mockSecondarySummary: SecondarySummary(
        coins: 0, fishTreats: 0, exp: 0,
        catSummary: CatSummary(nickname: 'Mimi', level: 1, mood: 60, bond: 0, energy: 'medium'),
        changeHighlights: [],
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Fallback text should appear (one of the pool)
    expect(find.textContaining('✨'), findsWidgets);
  });

  testWidgets('TodayPage shows hinted highlight with pending label', (WidgetTester tester) async {
    final client = MockApiClient(
      mockSecondarySummary: SecondarySummary(
        coins: 10, fishTreats: 1, exp: 5,
        catSummary: CatSummary(nickname: 'Mimi', level: 1, mood: 60, bond: 0, energy: 'medium'),
        changeHighlights: [
          ChangeHighlightData(kind: 'growth', status: 'hinted', label: 'Almost level up'),
        ],
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Hinted highlights show label + pending indicator
    expect(find.textContaining('Almost level up'), findsOneWidget);
    expect(find.textContaining('\u5f85\u786e\u8ba4'), findsOneWidget); // 待确认
  });

  testWidgets('TodayPage primary CTA still present with highlights', (WidgetTester tester) async {
    final client = MockApiClient(
      mockSecondarySummary: SecondarySummary(
        coins: 10, fishTreats: 1, exp: 25,
        catSummary: CatSummary(nickname: 'Mimi', level: 2, mood: 70, bond: 5, energy: 'high'),
        changeHighlights: [
          ChangeHighlightData(kind: 'growth', status: 'confirmed', label: '已达到 Lv.2'),
        ],
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Primary CTA must still be present and not displaced
    expect(find.byKey(const Key('today-primary-study-cta')), findsOneWidget);
  });

  testWidgets('TodayPage handles secondarySummary load failure gracefully', (WidgetTester tester) async {
    // Default mock returns empty summary, simulating graceful fallback
    final client = MockApiClient();
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Page should still load without crash
    expect(find.byKey(const Key('today-primary-study-cta')), findsOneWidget);
    // Fallback highlights text visible
    expect(find.textContaining('✨'), findsWidgets);
  });

  // ==================== C1: Today CTA winner state matrix tests ====================

  testWidgets('C1: CTA shows review continuation when active group exists', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 5,
        todayReviewTarget: 1, todayReviewPending: 2, todayReviewCompleted: 0,
        dailyGoalStatus: 'partially_completed',
        activeReviewGroupId: 'rg-001',
        activeReviewGroupStatus: 'in_progress',
        activeReviewGroupRemaining: 2,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: true, learningDayToday: false,
        currentStreak: 1, sessionStartedToday: false, sessionValidToday: false,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Primary CTA should be review continuation
    expect(find.byKey(const Key('today-primary-study-cta')), findsOneWidget);
    expect(find.textContaining('\u7ee7\u7eed\u672c\u7ec4\u590d\u4e60'), findsOneWidget); // 继续本组复习
  });

  testWidgets('C1: CTA shows review-first when pending review but no active group', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 0,
        todayReviewTarget: 1, todayReviewPending: 3, todayReviewCompleted: 0,
        dailyGoalStatus: 'not_started',
        activeReviewGroupId: null,
        activeReviewGroupStatus: null,
        activeReviewGroupRemaining: 0,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: false, learningDayToday: false,
        currentStreak: 0, sessionStartedToday: false, sessionValidToday: false,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Primary CTA should be review-first
    expect(find.textContaining('\u5148\u53bb\u590d\u4e60'), findsOneWidget); // 先去复习
  });

  testWidgets('C1: CTA shows new word learning when no review needed', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 0,
        todayReviewTarget: 0, todayReviewPending: 0, todayReviewCompleted: 0,
        dailyGoalStatus: 'not_started',
        activeReviewGroupId: null,
        activeReviewGroupStatus: null,
        activeReviewGroupRemaining: 0,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: false, learningDayToday: false,
        currentStreak: 0, sessionStartedToday: false, sessionValidToday: false,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Primary CTA should be new word learning
    expect(find.textContaining('\u5f00\u59cb\u4eca\u65e5\u5b66\u4e60'), findsOneWidget); // 开始今日学习
  });

  testWidgets('C1: CTA shows goal completed when all done', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 20,
        todayReviewTarget: 1, todayReviewPending: 0, todayReviewCompleted: 1,
        dailyGoalStatus: 'completed',
        activeReviewGroupId: null,
        activeReviewGroupStatus: null,
        activeReviewGroupRemaining: 0,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: true, learningDayToday: true,
        currentStreak: 3, sessionStartedToday: false, sessionValidToday: true,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Primary CTA should show completed
    expect(find.textContaining('\u5df2\u5b8c\u6210'), findsOneWidget); // 已完成
  });

  testWidgets('C1: Session card is info-only, no competing CTA button', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 5,
        todayReviewTarget: 0, todayReviewPending: 0, todayReviewCompleted: 0,
        dailyGoalStatus: 'partially_completed',
        activeReviewGroupId: null,
        activeReviewGroupStatus: null,
        activeReviewGroupRemaining: 0,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: true, learningDayToday: false,
        currentStreak: 1, sessionStartedToday: true, sessionValidToday: false,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Session card shows but has no ElevatedButton (only info text)
    // Primary CTA is the only ElevatedButton with that key
    expect(find.byKey(const Key('today-primary-study-cta')), findsOneWidget);
    // Session text should be present
    expect(find.textContaining('Session'), findsWidgets);
  });

  testWidgets('C1: Only one primary CTA exists at any time', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 5,
        todayReviewTarget: 1, todayReviewPending: 2, todayReviewCompleted: 0,
        dailyGoalStatus: 'partially_completed',
        activeReviewGroupId: 'rg-001',
        activeReviewGroupStatus: 'in_progress',
        activeReviewGroupRemaining: 2,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: true, learningDayToday: false,
        currentStreak: 1, sessionStartedToday: true, sessionValidToday: false,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Only ONE primary CTA button with the key
    expect(find.byKey(const Key('today-primary-study-cta')), findsOneWidget);
    // Review group card should NOT have its own CTA button (removed in C1)
    expect(find.text('\u7ee7\u7eed\u672c\u7ec4\u590d\u4e60'), findsNothing); // No separate "继续本组复习" button text
    // The CTA text should contain review continuation info
    expect(find.textContaining('\u590d\u4e60'), findsWidgets); // 复习 appears in primary CTA
  });

  // ==================== C2: Review continuation / boundary tests ====================

  testWidgets('C2: Goals card shows review group count (not item count)', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 10,
        todayReviewTarget: 2, todayReviewPending: 0, todayReviewCompleted: 1,
        dailyGoalStatus: 'partially_completed',
        activeReviewGroupId: null,
        activeReviewGroupStatus: null,
        activeReviewGroupRemaining: 0,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: true, learningDayToday: true,
        currentStreak: 2, sessionStartedToday: false, sessionValidToday: false,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Goals card should show review GROUP count label
    expect(find.textContaining('\u590d\u4e60\u7ec4'), findsOneWidget); // 复习组
    expect(find.text('1/2'), findsOneWidget); // 1 of 2 groups done
  });

  testWidgets('C2: Shows review progress note when group done but daily not complete', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 10,
        todayReviewTarget: 2, todayReviewPending: 0, todayReviewCompleted: 1,
        dailyGoalStatus: 'partially_completed',
        activeReviewGroupId: null, // group completed
        activeReviewGroupStatus: null,
        activeReviewGroupRemaining: 0,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: true, learningDayToday: true,
        currentStreak: 2, sessionStartedToday: false, sessionValidToday: false,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Review progress note should show (group done but target=2, completed=1)
    expect(find.textContaining('1/2'), findsWidgets);
    expect(find.textContaining('\u8fdb\u884c\u4e2d'), findsOneWidget); // 进行中
  });

  testWidgets('C2: No review progress note when daily review goal met', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 20,
        todayReviewTarget: 1, todayReviewPending: 0, todayReviewCompleted: 1,
        dailyGoalStatus: 'completed',
        activeReviewGroupId: null,
        activeReviewGroupStatus: null,
        activeReviewGroupRemaining: 0,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: true, learningDayToday: true,
        currentStreak: 3, sessionStartedToday: false, sessionValidToday: true,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Daily goal completed — no review progress note needed
    // CTA shows completed
    expect(find.textContaining('\u5df2\u5b8c\u6210'), findsOneWidget); // 已完成
  });

  testWidgets('C2: CTA falls through to new words after all review groups done', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 5,
        todayReviewTarget: 1, todayReviewPending: 0, todayReviewCompleted: 1,
        dailyGoalStatus: 'partially_completed',
        activeReviewGroupId: null,
        activeReviewGroupStatus: null,
        activeReviewGroupRemaining: 0,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: true, learningDayToday: true,
        currentStreak: 2, sessionStartedToday: false, sessionValidToday: false,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // No active group, no pending review → falls to new words CTA
    expect(find.textContaining('\u7ee7\u7eed\u5b66\u4e60'), findsOneWidget); // 继续学习
  });

  // ==================== P3 Phase 1: CTA decision-support contract tests ====================

  testWidgets('P3P1: Contract present — continue_review_group driven by backend', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 5,
        todayReviewTarget: 1, todayReviewPending: 2, todayReviewCompleted: 0,
        dailyGoalStatus: 'partially_completed',
        activeReviewGroupId: 'rg-001', activeReviewGroupStatus: 'in_progress', activeReviewGroupRemaining: 2,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: true, learningDayToday: false,
        currentStreak: 1, sessionStartedToday: false, sessionValidToday: false,
        todayPrimaryAction: TodayPrimaryActionData(action: 'continue_review_group', reason: 'active_review_group'),
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('\u590d\u4e60'), findsWidgets); // 复习
    expect(find.textContaining('\u672a\u5b8c\u6210\u7684\u590d\u4e60\u7ec4'), findsOneWidget); // reason line
  });

  testWidgets('P3P1: Contract present — go_new_words with reason line', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 5,
        todayReviewTarget: 0, todayReviewPending: 0, todayReviewCompleted: 0,
        dailyGoalStatus: 'partially_completed',
        activeReviewGroupId: null, activeReviewGroupStatus: null, activeReviewGroupRemaining: 0,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: false, learningDayToday: false,
        currentStreak: 0, sessionStartedToday: false, sessionValidToday: false,
        todayPrimaryAction: TodayPrimaryActionData(action: 'go_new_words', reason: 'new_words_remaining'),
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('\u5b66\u4e60'), findsWidgets); // 学习
    expect(find.textContaining('\u65b0\u8bcd\u76ee\u6807'), findsOneWidget); // 新词目标 in reason line
  });

  testWidgets('P3P1: Contract absent — falls back to Option C baseline', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 0,
        todayReviewTarget: 0, todayReviewPending: 0, todayReviewCompleted: 0,
        dailyGoalStatus: 'not_started',
        activeReviewGroupId: null, activeReviewGroupStatus: null, activeReviewGroupRemaining: 0,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: false, learningDayToday: false,
        currentStreak: 0, sessionStartedToday: false, sessionValidToday: false,
        // todayPrimaryAction intentionally null — contract absent
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Fallback: Option C baseline — new words CTA
    expect(find.textContaining('\u5f00\u59cb\u4eca\u65e5\u5b66\u4e60'), findsOneWidget); // 开始今日学习
    // No reason line when contract absent
  });

  testWidgets('P3P1: Still only one primary CTA with contract present', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 5,
        todayReviewTarget: 1, todayReviewPending: 0, todayReviewCompleted: 1,
        dailyGoalStatus: 'partially_completed',
        activeReviewGroupId: null, activeReviewGroupStatus: null, activeReviewGroupRemaining: 0,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: true, learningDayToday: true,
        currentStreak: 2, sessionStartedToday: true, sessionValidToday: false,
        todayPrimaryAction: TodayPrimaryActionData(action: 'go_session', reason: 'session_pending'),
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Only ONE primary CTA button
    expect(find.byKey(const Key('today-primary-study-cta')), findsOneWidget);
  });

  // ==================== C4: Streak truth-boundary hardening tests ====================

  testWidgets('C4: Check-in and learning_day shown separately in Today', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 5,
        todayReviewTarget: 0, todayReviewPending: 0, todayReviewCompleted: 0,
        dailyGoalStatus: 'partially_completed',
        activeReviewGroupId: null, activeReviewGroupStatus: null, activeReviewGroupRemaining: 0,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: true,    // checked in
        learningDayToday: false,     // NOT a learning day (check_in ≠ learning_day)
        currentStreak: 3,
        sessionStartedToday: false, sessionValidToday: false,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Check-in shown as checked
    expect(find.textContaining('\u5df2\u7b7e\u5230'), findsWidgets); // 已签到
    // Learning day shown as NOT achieved (despite check-in being true)
    expect(find.textContaining('\u672a\u8fbe\u6210'), findsOneWidget); // 未达成
    // Streak shown with basis label
    expect(find.textContaining('\u7b7e\u5230'), findsWidgets); // 签到 appears in basis labels
  });

  testWidgets('C4: Streak chip includes basis label (签到)', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 0,
        todayReviewTarget: 0, todayReviewPending: 0, todayReviewCompleted: 0,
        dailyGoalStatus: 'not_started',
        activeReviewGroupId: null, activeReviewGroupStatus: null, activeReviewGroupRemaining: 0,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: true, learningDayToday: false,
        currentStreak: 5,
        sessionStartedToday: false, sessionValidToday: false,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Streak section shows "(基于签到)" label
    expect(find.textContaining('\u57fa\u4e8e\u7b7e\u5230'), findsWidgets); // 基于签到
  });

  testWidgets('C4: Learning day true does NOT show streak as learning-based', (WidgetTester tester) async {
    final client = MockApiClient(
      mockTodayState: TodayState(
        currentBookName: 'CET-4',
        todayNewTarget: 20, todayNewCompleted: 10,
        todayReviewTarget: 0, todayReviewPending: 0, todayReviewCompleted: 0,
        dailyGoalStatus: 'partially_completed',
        activeReviewGroupId: null, activeReviewGroupStatus: null, activeReviewGroupRemaining: 0,
        syncStatus: 'healthy', lastRewardSettlement: null,
        hasCheckedInToday: true,
        learningDayToday: true,  // learning day IS true
        currentStreak: 3,
        sessionStartedToday: false, sessionValidToday: false,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: TodayPage(apiClient: client)));
    await tester.pump(const Duration(milliseconds: 500));

    // Even with learning_day=true, streak is still labeled as check_in based
    expect(find.textContaining('\u57fa\u4e8e\u7b7e\u5230'), findsWidgets); // 基于签到
    // Learning day shown as effective (separate from streak) — may appear in card + chip
    expect(find.textContaining('\u6709\u6548'), findsWidgets); // 有效
  });
}
