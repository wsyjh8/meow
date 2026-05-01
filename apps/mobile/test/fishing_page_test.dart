import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/core/api/api_client.dart';
import 'package:meow_mobile/spec/pages/fishing_page.dart';

/// Test ApiClient stub for FishingPage tests.
class FishingTestApiClient implements ApiClient {
  FishingTestApiClient({
    this.status,
    this.question,
    this.attemptResult,
    this.statusException,
  });

  DailyTaskStatus? status;
  FishingRoundQuestion? question;
  FishingAttemptResult? attemptResult;
  Exception? statusException;

  @override
  String get baseUrl => 'http://10.0.2.2:3000/api/v1';

  static DailyTaskStatus availableStatus({int completed = 0}) =>
      DailyTaskStatus(
        taskId: 'ft-2026-04-29',
        taskDate: '2026-04-29',
        roundsCompleted: completed,
        roundsTotal: 3,
        status: completed >= 3 ? 'exhausted' : 'available',
        hasActiveRound: false,
        fishTreatsBalance: completed * 2,
      );

  static FishingRoundQuestion sampleQuestion() => FishingRoundQuestion(
        taskId: 'ft-2026-04-29',
        roundNumber: 1,
        choices: [
          FishingChoice(wordId: 'w1', wordText: 'ephemeral'),
          FishingChoice(wordId: 'w2', wordText: 'ubiquitous'),
          FishingChoice(wordId: 'w3', wordText: 'serendipity'),
          FishingChoice(wordId: 'w4', wordText: 'resilient'),
          FishingChoice(wordId: 'w5', wordText: 'nomenclature'),
        ],
      );

  static FishingAttemptResult correctResult() => FishingAttemptResult(
        isCorrect: true,
        fishWord: FishingFishWord(
          wordId: 'w1',
          wordText: 'ephemeral',
          meaning: '短暂的',
        ),
        fishTreatsEarned: 2,
        roundsCompleted: 1,
        roundsTotal: 3,
        status: 'available',
        boxEarned: false,
        boxId: null,
        fishTreatsBalance: 2,
      );

  @override
  Future<DailyTaskStatus> getDailyTask() async {
    if (statusException != null) throw statusException!;
    return status ?? availableStatus();
  }

  @override
  Future<FishingRoundQuestion?> startFishingRound() async => question ?? sampleQuestion();

  @override
  Future<FishingAttemptResult> submitFishingAttempt({
    required String taskId,
    required String chosenWordId,
    String? idempotencyKey,
  }) async => attemptResult ?? correctResult();

  // Stubs for unused methods
  @override
  Future<TodayState> getToday() => throw UnimplementedError();
  @override
  Future<SecondarySummary> getSecondarySummary() => throw UnimplementedError();
  @override
  Future<Word?> getNextNewWord() => throw UnimplementedError();
  @override
  Future<StudyAttemptResult> submitStudyAttempt({required String wordId, required String bookId, required String studyType, required String actionResult, String? idempotencyKey, String? sessionId}) => throw UnimplementedError();
  @override
  Future<ReviewGroup> getNextReviewGroup() => throw UnimplementedError();
  @override
  Future<ReviewAttemptResult> submitReviewAttempt({required String reviewGroupId, required String wordId, required String actionResult, String? idempotencyKey, String? sessionId}) => throw UnimplementedError();
  @override
  Future<SessionInfo> startSession({int sessionMinutesTarget = 15, String? idempotencyKey, String? sessionId}) => throw UnimplementedError();
  @override
  Future<SessionInfo> finishSession({required String sessionId, String? idempotencyKey}) => throw UnimplementedError();
  @override
  Future<SessionInfo> getSession(String sessionId) => throw UnimplementedError();
  @override
  Future<List<WordReviewHistoryItem>> getWordReviewHistory({required String wordId, int limit = 20}) => throw UnimplementedError();

  @override
  Future<CheckInResult> checkIn({String? idempotencyKey}) => throw UnimplementedError();
  @override
  Future<CatalogResponse> getShopCatalog() => throw UnimplementedError();
  @override
  Future<InventoryStateData> getInventory() => throw UnimplementedError();
  @override
  Future<EquipmentResponse> getEquipment() => throw UnimplementedError();
  @override
  Future<PurchaseResponse> purchaseItem({required String itemId, String? idempotencyKey}) => throw UnimplementedError();
  @override
  Future<EquipResponse> equipItem({required String itemId, String? idempotencyKey}) => throw UnimplementedError();
  @override
  Future<FeedResponse> feedCat({String? idempotencyKey}) => throw UnimplementedError();
  @override
  Future<void> updateDailyGoal(int dailyNewTarget) => throw UnimplementedError();
  @override
  Future<ReviewAttemptResult> submitLocalReviewBatch({required List<LocalWordAttempt> attempts, String? idempotencyKey, String? sessionId}) => throw UnimplementedError();
  @override
  Future<LotteryBoxesResponse> getLotteryBoxes() => throw UnimplementedError();
  @override
  Future<LotteryOpenResult> openLotteryBox({required String boxId, String? idempotencyKey}) => throw UnimplementedError();
  @override
  void dispose() {}
}

void main() {
  Widget buildTestWidget(FishingTestApiClient client) {
    return MaterialApp(home: FishingPage(apiClient: client));
  }

  testWidgets('FishingPage renders loading state', (tester) async {
    final client = _NeverLoadFishingClient();
    await tester.pumpWidget(buildTestWidget(client));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('FishingPage renders progress and start CTA when available', (tester) async {
    final client = FishingTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('钓鱼小游戏'), findsOneWidget);
    expect(find.text('今日进度'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
    expect(find.text('开始钓鱼喵'), findsOneWidget);
  });

  testWidgets('FishingPage shows §3.2 separation notice', (tester) async {
    final client = FishingTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('不会变成学习进度'), findsOneWidget);
  });

  testWidgets('FishingPage shows back-to-study chip', (tester) async {
    final client = FishingTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('回到学习'), findsOneWidget);
  });

  testWidgets('FishingPage shows fish_treats balance in AppBar', (tester) async {
    final client = FishingTestApiClient(
      status: FishingTestApiClient.availableStatus(completed: 2),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('🐟'), findsWidgets);
  });

  testWidgets('FishingPage shows exhausted state correctly', (tester) async {
    final client = FishingTestApiClient(
      status: FishingTestApiClient.availableStatus(completed: 3),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('明天再来喵'), findsOneWidget);
    expect(find.textContaining('今天已经钓完啦'), findsOneWidget);
  });

  testWidgets('FishingPage starts a round and shows 5 choices', (tester) async {
    final client = FishingTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('开始钓鱼喵'));
    await tester.pump(const Duration(milliseconds: 500));

    // 5 word choices should appear
    expect(find.text('ephemeral'), findsOneWidget);
    expect(find.text('ubiquitous'), findsOneWidget);
    expect(find.text('serendipity'), findsOneWidget);
    expect(find.text('resilient'), findsOneWidget);
    expect(find.text('nomenclature'), findsOneWidget);
  });

  testWidgets('FishingPage shows correct result with reward', (tester) async {
    final client = FishingTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('开始钓鱼喵'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('ephemeral'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('钓到啦！'), findsOneWidget);
    expect(find.textContaining('+2 小鱼干'), findsOneWidget);
  });

  testWidgets('FishingPage shows error state on load failure', (tester) async {
    final client = FishingTestApiClient(statusException: Exception('Net'));
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('FishingPage shows box earned chip when last round wins', (tester) async {
    final client = FishingTestApiClient(
      attemptResult: FishingAttemptResult(
        isCorrect: true,
        fishWord: FishingFishWord(wordId: 'w1', wordText: 'ephemeral', meaning: '短暂的'),
        fishTreatsEarned: 2,
        roundsCompleted: 3,
        roundsTotal: 3,
        status: 'exhausted',
        boxEarned: true,
        boxId: 'lbox-test',
        fishTreatsBalance: 6,
      ),
    );
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('开始钓鱼喵'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('ephemeral'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('收到 1 个盲盒'), findsOneWidget);
    expect(find.text('去开盲盒喵'), findsOneWidget);
  });
}

class _NeverLoadFishingClient extends FishingTestApiClient {
  @override
  Future<DailyTaskStatus> getDailyTask() => Completer<DailyTaskStatus>().future;
}
