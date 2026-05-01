import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meow_mobile/core/api/api_client.dart';
import 'package:meow_mobile/spec/pages/lottery_gate_page.dart';

class LotteryTestApiClient implements ApiClient {
  LotteryTestApiClient({this.boxes, this.openResult, this.boxesException});

  LotteryBoxesResponse? boxes;
  LotteryOpenResult? openResult;
  Exception? boxesException;

  @override
  String get baseUrl => 'http://10.0.2.2:3000/api/v1';

  static LotteryBoxesResponse withBoxes() => LotteryBoxesResponse(
        pendingBoxes: [
          LotteryBoxData(id: 'lbox-aaaaaaaaa', source: 'fishing', createdAt: '2026-04-29T08:00:00Z'),
          LotteryBoxData(id: 'lbox-bbbbbbbbb', source: 'fishing', createdAt: '2026-04-29T09:00:00Z'),
        ],
        totalPending: 2,
        coinsBalance: 100,
        fishTreatsBalance: 12,
      );

  static LotteryBoxesResponse empty() => LotteryBoxesResponse(
        pendingBoxes: [],
        totalPending: 0,
        coinsBalance: 80,
        fishTreatsBalance: 4,
      );

  static LotteryOpenResult win50() => LotteryOpenResult(
        opened: true,
        boxId: 'lbox-aaaaaaaaa',
        prizeType: 'coins',
        coinsWon: 50,
        coinsBalance: 150,
      );

  @override
  Future<LotteryBoxesResponse> getLotteryBoxes() async {
    if (boxesException != null) throw boxesException!;
    return boxes ?? withBoxes();
  }

  @override
  Future<LotteryOpenResult> openLotteryBox({
    required String boxId,
    String? idempotencyKey,
  }) async => openResult ?? win50();

  // Stubs
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
  Future<DailyTaskStatus> getDailyTask() => throw UnimplementedError();
  @override
  Future<FishingRoundQuestion?> startFishingRound() => throw UnimplementedError();
  @override
  Future<FishingAttemptResult> submitFishingAttempt({required String taskId, required String chosenWordId, String? idempotencyKey}) => throw UnimplementedError();
  @override
  void dispose() {}
}

void main() {
  Widget buildTestWidget(LotteryTestApiClient client) {
    return MaterialApp(home: LotteryGatePage(apiClient: client));
  }

  testWidgets('LotteryGatePage renders loading state', (tester) async {
    final client = _NeverLoadLotteryClient();
    await tester.pumpWidget(buildTestWidget(client));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('LotteryGatePage shows §3.2 separation notice', (tester) async {
    final client = LotteryTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('不会变成学习进度'), findsOneWidget);
  });

  testWidgets('LotteryGatePage shows pending box list', (tester) async {
    final client = LotteryTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('未开启盲盒'), findsOneWidget);
    expect(find.text('2 个'), findsOneWidget);
    // Two boxes → two "打开喵" buttons
    expect(find.text('打开喵'), findsNWidgets(2));
  });

  testWidgets('LotteryGatePage shows empty state with link to fishing', (tester) async {
    final client = LotteryTestApiClient(boxes: LotteryTestApiClient.empty());
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('还没有盲盒'), findsOneWidget);
    expect(find.text('去钓鱼喵'), findsOneWidget);
  });

  testWidgets('LotteryGatePage opens a box and shows prize', (tester) async {
    final client = LotteryTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('打开喵').first);
    // Pump animation duration plus some buffer
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('抽到啦！'), findsOneWidget);
    expect(find.textContaining('+50'), findsOneWidget);
  });

  testWidgets('LotteryGatePage shows back-to-study chip', (tester) async {
    final client = LotteryTestApiClient();
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('回到学习'), findsOneWidget);
  });

  testWidgets('LotteryGatePage shows error state on load failure', (tester) async {
    final client = LotteryTestApiClient(boxesException: Exception('Net'));
    await tester.pumpWidget(buildTestWidget(client));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}

class _NeverLoadLotteryClient extends LotteryTestApiClient {
  @override
  Future<LotteryBoxesResponse> getLotteryBoxes() => Completer<LotteryBoxesResponse>().future;
}
