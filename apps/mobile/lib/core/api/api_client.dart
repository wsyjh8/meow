import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_base.dart';
import '../models/content_models.dart';
export '../models/content_models.dart' show WordExample;

/// API Client for Phase 1 / Phase 2 / Phase 3
///
/// Minimal API client for Today / New Study / Review / Settlement / Session / Check-in flows.
///
/// PR-C S1=β: `baseUrl` defaults to [apiV1Base] resolved by
/// `--dart-define=API_BASE=...` at compile time.
class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({
    this.baseUrl = apiV1Base,
    http.Client? client,
  }) : _client = client ?? http.Client();

  // ========== Today ==========

  /// Get today's aggregated state
  Future<TodayState> getToday() async {
    final response = await _client.get(Uri.parse('$baseUrl/me/today'));
    if (response.statusCode == 200) {
      return TodayState.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('GET /me/today failed: ${response.statusCode}');
  }

  // ========== New Words ==========

  /// Get next new word to study
  Future<Word?> getNextNewWord() async {
    final response = await _client.get(Uri.parse('$baseUrl/me/new-words/next'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data.containsKey('message')) {
        return null; // No more words
      }
      return Word.fromJson(data);
    }
    throw ApiException('GET /me/new-words/next failed: ${response.statusCode}');
  }

  /// Submit a study attempt
  Future<StudyAttemptResult> submitStudyAttempt({
    required String wordId,
    required String bookId,
    required String studyType,
    required String actionResult,
    String? idempotencyKey,
    String? sessionId,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (idempotencyKey != null) {
      headers['X-Idempotency-Key'] = idempotencyKey;
    }

    final body = <String, dynamic>{
      'word_id': wordId,
      'book_id': bookId,
      'study_type': studyType,
      'action_result': actionResult,
    };
    if (sessionId != null) body['session_id'] = sessionId;

    final response = await _client.post(
      Uri.parse('$baseUrl/me/new-words'),
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return StudyAttemptResult.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('POST /me/new-words failed: ${response.statusCode}');
  }

  // ========== Review Groups ==========

  /// Get or create active review group.
  ///
  /// review_group_compatibility_contract_v1 (FROZEN, P3.3.5):
  ///   CURRENT RUNTIME PATH — MUST continue to be called by ReviewPage.
  ///   Future deprecation candidate (if local-serving cutover is pinned).
  ///   Do NOT bypass, replace, or condition-gate this call without a
  ///   Room 1 pin. RF-P3.3.5-015: `review_group` / cloud readiness
  ///   enters staged deprecation — NOT "disappeared".
  Future<ReviewGroup> getNextReviewGroup() async {
    final response =
        await _client.get(Uri.parse('$baseUrl/me/review-groups/next'));
    if (response.statusCode == 200) {
      return ReviewGroup.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    // Include statusCode so ReviewPage can distinguish not_ready_now (404)
    // from temporarily_unservable (network/server errors).
    // review_readiness_policy_v1 (P3.3.3): truth source is cloud response.
    throw ApiException(
      'GET /me/review-groups/next failed: ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  // ========== Review Attempts ==========

  /// Submit a review attempt to the cloud fact/settlement layer.
  ///
  /// review_group_compatibility_contract_v1 (FROZEN, P3.3.5):
  ///   CURRENT RUNTIME PATH — cloud-first submission is PRIMARY.
  ///   Fact/settlement owner = cloud backend; NOT a cut candidate
  ///   this round per RF-P3.3.5-003 (local owner shift does not
  ///   automatically bring fact owner shift).
  Future<ReviewAttemptResult> submitReviewAttempt({
    required String reviewGroupId,
    required String wordId,
    required String actionResult,
    String? idempotencyKey,
    String? sessionId,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (idempotencyKey != null) {
      headers['X-Idempotency-Key'] = idempotencyKey;
    }

    final body = <String, dynamic>{
      'review_group_id': reviewGroupId,
      'word_id': wordId,
      'action_result': actionResult,
    };
    if (sessionId != null) body['session_id'] = sessionId;

    final response = await _client.post(
      Uri.parse('$baseUrl/review-attempts'),
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return ReviewAttemptResult.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('POST /review-attempts failed: ${response.statusCode}');
  }

  /// Submit a completed local-origin review session batch.
  ///
  /// P3.3.16 — Real cutover path. Called when ReviewPage is serving from
  /// the local FSRS queue (non-continuation sessions). No backend-issued
  /// reviewGroupId is required — the backend creates an ephemeral group.
  /// Returns the same [ReviewAttemptResult] shape as [submitReviewAttempt].
  /// Route: POST /review-attempts/local-batch
  Future<ReviewAttemptResult> submitLocalReviewBatch({
    required List<LocalWordAttempt> attempts,
    String? idempotencyKey,
    String? sessionId,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (idempotencyKey != null) {
      headers['X-Idempotency-Key'] = idempotencyKey;
    }
    final body = <String, dynamic>{
      'word_attempts': attempts
          .map((a) => {'word_id': a.wordId, 'action_result': a.actionResult})
          .toList(),
    };
    if (sessionId != null) body['session_id'] = sessionId;
    final response = await _client.post(
      Uri.parse('$baseUrl/review-attempts/local-batch'),
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return ReviewAttemptResult.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException(
        'POST /review-attempts/local-batch failed: ${response.statusCode}');
  }

  // ========== Phase 3: Session ==========

  /// Start a new session
  Future<SessionInfo> startSession({
    int sessionMinutesTarget = 15,
    String? idempotencyKey,
    String? sessionId,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (idempotencyKey != null) {
      headers['X-Idempotency-Key'] = idempotencyKey;
    }

    final body = <String, dynamic>{
      'session_minutes_target': sessionMinutesTarget,
    };
    if (sessionId != null) body['session_id'] = sessionId;

    final response = await _client.post(
      Uri.parse('$baseUrl/sessions'),
      headers: headers,
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return SessionInfo.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('POST /sessions failed: ${response.statusCode}');
  }

  /// Finish a session
  Future<SessionInfo> finishSession({
    required String sessionId,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (idempotencyKey != null) {
      headers['X-Idempotency-Key'] = idempotencyKey;
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/sessions/$sessionId/finish'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return SessionInfo.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('POST /sessions/$sessionId/finish failed: ${response.statusCode}');
  }

  /// Get session status
  Future<SessionInfo> getSession(String sessionId) async {
    final response = await _client.get(Uri.parse('$baseUrl/sessions/$sessionId'));
    if (response.statusCode == 200) {
      return SessionInfo.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('GET /sessions/$sessionId failed: ${response.statusCode}');
  }

  // ========== Need #10: Per-word review history ==========

  /// Get cloud-accepted review history for a single word, newest first.
  /// Returns up to [limit] items (server clamps at 200).
  Future<List<WordReviewHistoryItem>> getWordReviewHistory({
    required String wordId,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/me/words/$wordId/review-history')
        .replace(queryParameters: {'limit': limit.toString()});
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final items = (body['items'] as List<dynamic>? ?? [])
          .map((e) => WordReviewHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return items;
    }
    throw ApiException(
        'GET /me/words/$wordId/review-history failed: ${response.statusCode}');
  }

  // ========== Phase 3: Check-in ==========

  /// Check in for today
  Future<CheckInResult> checkIn({String? idempotencyKey}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (idempotencyKey != null) {
      headers['X-Idempotency-Key'] = idempotencyKey;
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/check-ins'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return CheckInResult.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('POST /check-ins failed: ${response.statusCode}');
  }

  // ========== P2 Phase 2A: Feed ==========

  /// Feed the cat with a fish treat.
  /// Returns full feed result with updated secondary summary.
  Future<FeedResponse> feedCat({String? idempotencyKey}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (idempotencyKey != null) {
      headers['X-Idempotency-Key'] = idempotencyKey;
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/me/feed'),
      headers: headers,
      body: json.encode({
        'feed_item_type': 'fish_treat',
      }),
    );
    if (response.statusCode == 200) {
      return FeedResponse.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('POST /me/feed failed: ${response.statusCode}');
  }

  // ========== P2 Phase 2D: Shop / Inventory ==========

  /// Get shop catalog
  Future<CatalogResponse> getShopCatalog() async {
    final response = await _client.get(Uri.parse('$baseUrl/shop/catalog'));
    if (response.statusCode == 200) {
      return CatalogResponse.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('GET /shop/catalog failed: ${response.statusCode}');
  }

  /// Get user inventory
  Future<InventoryStateData> getInventory() async {
    final response = await _client.get(Uri.parse('$baseUrl/me/inventory'));
    if (response.statusCode == 200) {
      return InventoryStateData.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('GET /me/inventory failed: ${response.statusCode}');
  }

  /// Purchase an item from the shop
  Future<PurchaseResponse> purchaseItem({
    required String itemId,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (idempotencyKey != null) {
      headers['X-Idempotency-Key'] = idempotencyKey;
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/shop/purchases'),
      headers: headers,
      body: json.encode({
        'item_id': itemId,
      }),
    );
    if (response.statusCode == 200) {
      return PurchaseResponse.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('POST /shop/purchases failed: ${response.statusCode}');
  }

  // ========== P2 Phase 3: Equipment ==========

  /// Get current equipped state
  Future<EquipmentResponse> getEquipment() async {
    final response = await _client.get(Uri.parse('$baseUrl/me/equipment'));
    if (response.statusCode == 200) {
      return EquipmentResponse.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('GET /me/equipment failed: ${response.statusCode}');
  }

  /// Equip an owned item
  Future<EquipResponse> equipItem({
    required String itemId,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (idempotencyKey != null) headers['X-Idempotency-Key'] = idempotencyKey;

    final response = await _client.post(
      Uri.parse('$baseUrl/me/equipment/equip'),
      headers: headers,
      body: json.encode({'item_id': itemId}),
    );
    if (response.statusCode == 200) {
      return EquipResponse.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('POST /me/equipment/equip failed: ${response.statusCode}');
  }

  // ========== P2 Phase 1A: Secondary Summary ==========

  /// Get backend-owned secondary summary for P2 bridge layer
  Future<SecondarySummary> getSecondarySummary() async {
    final response = await _client.get(Uri.parse('$baseUrl/me/secondary-summary'));
    if (response.statusCode == 200) {
      return SecondarySummary.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException(
      'GET /me/secondary-summary failed: ${response.statusCode}',
    );
  }

  // ========== Settings ==========

  /// Update daily new word target on backend
  Future<void> updateDailyGoal(int dailyNewTarget) async {
    final response = await _client.put(
      Uri.parse('$baseUrl/me/settings/daily-goal'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'daily_new_target': dailyNewTarget}),
    );
    if (response.statusCode != 200) {
      throw ApiException('PUT /me/settings/daily-goal failed: ${response.statusCode}');
    }
  }

  // ========== Phase D: Fishing + Lottery ==========

  /// Get today's fishing task status (Beijing-time daily reset at 05:00).
  Future<DailyTaskStatus> getDailyTask() async {
    final response = await _client.get(Uri.parse('$baseUrl/me/daily-tasks'));
    if (response.statusCode == 200) {
      return DailyTaskStatus.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('GET /me/daily-tasks failed: ${response.statusCode}');
  }

  /// Start the next fishing round. Returns null if no rounds remain or no studied words.
  Future<FishingRoundQuestion?> startFishingRound() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/me/daily-tasks/start'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['started'] == true) {
        return FishingRoundQuestion.fromJson(data);
      }
      return null;
    }
    throw ApiException('POST /me/daily-tasks/start failed: ${response.statusCode}');
  }

  /// Submit a fishing attempt (the user's chosen word).
  Future<FishingAttemptResult> submitFishingAttempt({
    required String taskId,
    required String chosenWordId,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (idempotencyKey != null) headers['X-Idempotency-Key'] = idempotencyKey;
    final response = await _client.post(
      Uri.parse('$baseUrl/me/task-attempts'),
      headers: headers,
      body: json.encode({
        'task_id': taskId,
        'chosen_word_id': chosenWordId,
      }),
    );
    if (response.statusCode == 200) {
      return FishingAttemptResult.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('POST /me/task-attempts failed: ${response.statusCode}');
  }

  /// Get list of unopened lottery boxes.
  Future<LotteryBoxesResponse> getLotteryBoxes() async {
    final response = await _client.get(Uri.parse('$baseUrl/me/lottery-boxes'));
    if (response.statusCode == 200) {
      return LotteryBoxesResponse.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('GET /me/lottery-boxes failed: ${response.statusCode}');
  }

  /// Open a specific lottery box. Returns the prize won.
  Future<LotteryOpenResult> openLotteryBox({
    required String boxId,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (idempotencyKey != null) headers['X-Idempotency-Key'] = idempotencyKey;
    final response = await _client.post(
      Uri.parse('$baseUrl/me/lottery-boxes/$boxId/open'),
      headers: headers,
      body: json.encode({}),
    );
    if (response.statusCode == 200) {
      return LotteryOpenResult.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw ApiException('POST /me/lottery-boxes/:id/open failed: ${response.statusCode}');
  }

  void dispose() {
    _client.close();
  }
}

// ========== Response Models ==========

class TodayState {
  final String currentBookName;
  final int todayNewTarget;
  final int todayNewCompleted;
  final int todayReviewTarget;
  final int todayReviewPending;
  final int todayReviewCompleted;
  final String dailyGoalStatus;
  final String? activeReviewGroupId;
  final String? activeReviewGroupStatus;
  final int activeReviewGroupRemaining;
  final String syncStatus;
  final LastRewardSettlement? lastRewardSettlement;
  // Phase 3 fields
  final bool hasCheckedInToday;
  final bool learningDayToday;
  final int currentStreak;
  final String streakBasisType;
  final bool sessionStartedToday;
  final bool sessionValidToday;
  // P3 Phase 1: CTA decision-support (optional — absent = use Option C baseline)
  final TodayPrimaryActionData? todayPrimaryAction;
  // P3 Phase 2: Review deeper summary (optional — absent = hide deeper block)
  final ReviewSummaryData? reviewSummary;

  TodayState({
    required this.currentBookName,
    required this.todayNewTarget,
    required this.todayNewCompleted,
    required this.todayReviewTarget,
    required this.todayReviewPending,
    required this.todayReviewCompleted,
    required this.dailyGoalStatus,
    this.activeReviewGroupId,
    this.activeReviewGroupStatus,
    this.activeReviewGroupRemaining = 0,
    required this.syncStatus,
    this.lastRewardSettlement,
    this.hasCheckedInToday = false,
    this.learningDayToday = false,
    this.currentStreak = 0,
    this.streakBasisType = 'check_in',
    this.sessionStartedToday = false,
    this.sessionValidToday = false,
    this.todayPrimaryAction,
    this.reviewSummary,
  });

  /// Offline fallback — built entirely from local data when [getToday()] fails.
  ///
  /// Only [todayNewTarget] and [todayNewCompleted] carry real information;
  /// all other fields use safe zero-defaults. Review fields are omitted
  /// (unknown offline). syncStatus = 'offline'.
  factory TodayState.offline({
    required int todayNewTarget,
    required int todayNewCompleted,
    int todayReviewCompleted = 0,
  }) {
    final goalMet = todayNewTarget > 0 && todayNewCompleted >= todayNewTarget;
    return TodayState(
      currentBookName: 'CET-4',
      todayNewTarget: todayNewTarget,
      todayNewCompleted: todayNewCompleted,
      todayReviewTarget: 0,
      todayReviewPending: 0,
      todayReviewCompleted: todayReviewCompleted,
      dailyGoalStatus: goalMet
          ? 'completed'
          : todayNewCompleted > 0 ? 'in_progress' : 'not_started',
      activeReviewGroupRemaining: 0,
      syncStatus: 'offline',
      sessionStartedToday: todayNewCompleted > 0,
      learningDayToday: todayNewCompleted > 0,
    );
  }

  // Phase 0 guard: all fields use null-safe defaults to prevent crash
  // when backend omits fields (contract-absent scenario).
  // Defaults are conservative — never imply completion or availability.
  factory TodayState.fromJson(Map<String, dynamic> json) {
    return TodayState(
      currentBookName: (json['current_book_name'] as String?) ?? '',
      todayNewTarget: (json['today_new_target'] as num?)?.toInt() ?? 0,
      todayNewCompleted: (json['today_new_completed'] as num?)?.toInt() ?? 0,
      todayReviewTarget: (json['today_review_target'] as num?)?.toInt() ?? 0,
      todayReviewPending: (json['today_review_pending'] as num?)?.toInt() ?? 0,
      todayReviewCompleted: (json['today_review_completed'] as num?)?.toInt() ?? 0,
      dailyGoalStatus: (json['daily_goal_status'] as String?) ?? 'not_started',
      activeReviewGroupId: json['active_review_group_id'] as String?,
      activeReviewGroupStatus: json['active_review_group_status'] as String?,
      activeReviewGroupRemaining: (json['active_review_group_remaining'] as num?)?.toInt() ?? 0,
      syncStatus: (json['sync_status'] as String?) ?? 'healthy',
      lastRewardSettlement: json['last_reward_settlement'] != null
          ? LastRewardSettlement.fromJson(json['last_reward_settlement'] as Map<String, dynamic>)
          : null,
      hasCheckedInToday: json['has_checked_in_today'] as bool? ?? false,
      learningDayToday: json['learning_day_today'] as bool? ?? false,
      currentStreak: json['current_streak'] as int? ?? 0,
      streakBasisType: json['streak_basis_type'] as String? ?? 'check_in',
      sessionStartedToday: json['session_started_today'] as bool? ?? false,
      sessionValidToday: json['session_valid_today'] as bool? ?? false,
      // P3 Phase 1: optional CTA decision-support — absent = null = use Option C baseline
      todayPrimaryAction: TodayPrimaryActionData.tryParse(json['today_primary_action']),
      // P3 Phase 2: optional review deeper summary — absent = null = hide deeper block
      reviewSummary: ReviewSummaryData.tryParse(json['review_summary']),
    );
  }
}

/// P3 Phase 1: Very small CTA decision-support block.
/// Only `action` + `reason` — no priority_band or blocking_condition.
/// When absent/invalid, UI must fall back to Option C CTA baseline.
class TodayPrimaryActionData {
  final String action;
  final String reason;

  const TodayPrimaryActionData({required this.action, required this.reason});

  /// Known action values for this round.
  static const validActions = {'continue_review_group', 'go_review', 'go_new_words', 'go_session'};
  static const validReasons = {'active_review_group', 'review_due_priority', 'new_words_remaining', 'session_pending'};

  /// Strict parser: returns null if contract is absent, incomplete, or has unknown values.
  /// When null → UI falls back to Option C CTA baseline.
  static TodayPrimaryActionData? tryParse(dynamic raw) {
    if (raw == null || raw is! Map) return null;
    final map = raw;
    final action = map['action'];
    final reason = map['reason'];
    // Both must be present and valid — otherwise contract is considered absent.
    if (action is! String || reason is! String) return null;
    if (!validActions.contains(action) || !validReasons.contains(reason)) return null;
    return TodayPrimaryActionData(action: action, reason: reason);
  }
}

/// P3 Phase 2: Very small review deeper summary.
/// Strict parsing: absent/invalid/incomplete → null → hide deeper block.
class ReviewSummaryData {
  final bool hasActiveGroup;
  final int completedItems;
  final int totalItems;
  final bool activeGroupCompleted;
  final int completedUnits;
  final int requiredUnits;
  final String dailyReviewStatus; // 'not_started' | 'in_progress' | 'completed'
  final String nextGroupReadiness; // 'ready' | 'not_ready'

  const ReviewSummaryData({
    required this.hasActiveGroup,
    required this.completedItems,
    required this.totalItems,
    required this.activeGroupCompleted,
    required this.completedUnits,
    required this.requiredUnits,
    required this.dailyReviewStatus,
    required this.nextGroupReadiness,
  });

  static const _validStatuses = {'not_started', 'in_progress', 'completed'};
  static const _validReadiness = {'ready', 'not_ready'};

  /// Strict parser: returns null if contract absent, incomplete, or invalid.
  static ReviewSummaryData? tryParse(dynamic raw) {
    if (raw == null || raw is! Map) return null;
    try {
      final hasActive = raw['has_active_group'];
      final groupProgress = raw['active_group_progress'];
      final groupCompleted = raw['active_group_completed'];
      final dailyProgress = raw['daily_review_progress'];
      final readiness = raw['next_group_readiness'];

      if (hasActive is! bool) return null;
      if (groupCompleted is! bool) return null;
      if (groupProgress is! Map) return null;
      if (dailyProgress is! Map) return null;
      if (readiness is! String || !_validReadiness.contains(readiness)) return null;

      final compItems = groupProgress['completed_items'];
      final totalItems = groupProgress['total_items'];
      if (compItems is! num || totalItems is! num) return null;
      if (compItems < 0 || totalItems <= 0) return null;

      final compUnits = dailyProgress['completed_units'];
      final reqUnits = dailyProgress['required_units'];
      final status = dailyProgress['status'];
      if (compUnits is! num || reqUnits is! num) return null;
      if (compUnits < 0 || reqUnits <= 0) return null;
      if (status is! String || !_validStatuses.contains(status)) return null;

      return ReviewSummaryData(
        hasActiveGroup: hasActive,
        completedItems: compItems.toInt(),
        totalItems: totalItems.toInt(),
        activeGroupCompleted: groupCompleted,
        completedUnits: compUnits.toInt(),
        requiredUnits: reqUnits.toInt(),
        dailyReviewStatus: status,
        nextGroupReadiness: readiness,
      );
    } catch (_) {
      return null;
    }
  }
}

class LastRewardSettlement {
  final String? sourceEventId;
  final String? rewardSettlementStatus;

  LastRewardSettlement({
    this.sourceEventId,
    this.rewardSettlementStatus,
  });

  factory LastRewardSettlement.fromJson(Map<String, dynamic> json) {
    return LastRewardSettlement(
      sourceEventId: json['source_event_id'] as String?,
      rewardSettlementStatus: json['reward_settlement_status'] as String?,
    );
  }
}

class Word {
  final String wordId;
  final String wordText;
  final String meaning;
  final String? phonetic;
  final String bookId;
  // Extended fields from CET-4 data (all nullable for backwards compat)
  final String? translation;
  final String? definition;
  final int? difficultyLevel;
  final bool? isCore;
  final String? tags;
  final int? frequencyRank;
  final String? wordForms;
  // Local-only: example sentences from bundled assets (word_entries / example_sentences tables).
  // Null for cloud-served words that have no local content entry.
  final List<WordExample>? examples;

  Word({
    required this.wordId,
    required this.wordText,
    required this.meaning,
    this.phonetic,
    required this.bookId,
    this.translation,
    this.definition,
    this.difficultyLevel,
    this.isCore,
    this.tags,
    this.frequencyRank,
    this.wordForms,
    this.examples,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      wordId: json['word_id'] as String,
      wordText: json['word_text'] as String,
      meaning: json['meaning'] as String,
      phonetic: json['phonetic'] as String?,
      bookId: json['book_id'] as String,
      translation: json['translation'] as String?,
      definition: json['definition'] as String?,
      difficultyLevel: (json['difficulty_level'] as num?)?.toInt(),
      isCore: json['is_core'] as bool?,
      tags: json['tags'] as String?,
      frequencyRank: (json['frequency_rank'] as num?)?.toInt(),
      wordForms: json['word_forms'] as String?,
    );
  }
}

class StudyAttemptResult {
  final String submitStatus;
  final int todayNewCompleted;
  final String dailyGoalStatus;
  final bool alreadyExists;
  final SettlementInfo? settlement;

  StudyAttemptResult({
    required this.submitStatus,
    required this.todayNewCompleted,
    required this.dailyGoalStatus,
    required this.alreadyExists,
    this.settlement,
  });

  factory StudyAttemptResult.fromJson(Map<String, dynamic> json) {
    return StudyAttemptResult(
      submitStatus: json['submit_status'] as String,
      todayNewCompleted: json['today_new_completed'] as int,
      dailyGoalStatus: json['daily_goal_status'] as String,
      alreadyExists: json['already_exists'] as bool,
      settlement: json['settlement'] != null
          ? SettlementInfo.fromJson(json['settlement'] as Map<String, dynamic>)
          : null,
    );
  }
}

class SettlementInfo {
  final String sourceEventId;
  final String rewardSettlementStatus;
  final List<RewardItemInfo> rewardItems;

  SettlementInfo({
    required this.sourceEventId,
    required this.rewardSettlementStatus,
    required this.rewardItems,
  });

  factory SettlementInfo.fromJson(Map<String, dynamic> json) {
    return SettlementInfo(
      sourceEventId: json['source_event_id'] as String,
      rewardSettlementStatus: json['reward_settlement_status'] as String,
      rewardItems: (json['reward_items'] as List<dynamic>)
          .map((item) => RewardItemInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RewardItemInfo {
  final String rewardType;
  final int amount;
  final String rewardStatus;

  RewardItemInfo({
    required this.rewardType,
    required this.amount,
    required this.rewardStatus,
  });

  factory RewardItemInfo.fromJson(Map<String, dynamic> json) {
    return RewardItemInfo(
      rewardType: json['reward_type'] as String,
      amount: json['amount'] as int,
      rewardStatus: json['reward_status'] as String,
    );
  }
}

/// Review group fetched from the cloud serving layer.
///
/// review_group_compatibility_contract_v1 (FROZEN, P3.3.5):
///   Current runtime: this DTO IS the ReviewPage serving truth shape.
///   Future deprecation candidate — NOT deprecated in this round.
///   MUST continue to be consumed in runtime. RF-P3.3.5-016: deprecated
///   MUST NOT be written as active truth and MUST NOT be pretended
///   fully migrated.
class ReviewGroup {
  final String reviewGroupId;
  final String groupStatus;
  final bool groupCompleted;
  final int remainingCount;
  final List<ReviewGroupItem> items;

  ReviewGroup({
    required this.reviewGroupId,
    required this.groupStatus,
    required this.groupCompleted,
    required this.remainingCount,
    required this.items,
  });

  factory ReviewGroup.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>;
    return ReviewGroup(
      reviewGroupId: json['review_group_id'] as String,
      groupStatus: json['group_status'] as String,
      groupCompleted: json['group_completed'] as bool,
      remainingCount: json['remaining_count'] as int,
      items: itemsJson
          .map((i) => ReviewGroupItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReviewGroupItem {
  final String wordId;
  final String wordText;
  final String meaning;
  final bool completed;

  ReviewGroupItem({
    required this.wordId,
    required this.wordText,
    required this.meaning,
    required this.completed,
  });

  factory ReviewGroupItem.fromJson(Map<String, dynamic> json) {
    return ReviewGroupItem(
      wordId: json['word_id'] as String,
      wordText: json['word_text'] as String,
      meaning: json['meaning'] as String,
      completed: json['completed'] as bool,
    );
  }
}

class ReviewAttemptResult {
  final String submitStatus;
  final bool groupCompleted;
  final int groupRemaining;
  final int todayReviewCompleted;
  final String dailyGoalStatus;
  final bool alreadyExists;
  final SettlementInfo? settlement;

  ReviewAttemptResult({
    required this.submitStatus,
    required this.groupCompleted,
    required this.groupRemaining,
    required this.todayReviewCompleted,
    required this.dailyGoalStatus,
    required this.alreadyExists,
    this.settlement,
  });

  factory ReviewAttemptResult.fromJson(Map<String, dynamic> json) {
    return ReviewAttemptResult(
      submitStatus: json['submit_status'] as String,
      groupCompleted: json['group_completed'] as bool,
      groupRemaining: json['group_remaining'] as int,
      todayReviewCompleted: json['today_review_completed'] as int,
      dailyGoalStatus: json['daily_goal_status'] as String,
      alreadyExists: json['already_exists'] as bool,
      settlement: json['settlement'] != null
          ? SettlementInfo.fromJson(json['settlement'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// One word rating in a local-origin review session batch.
/// Used with [ApiClient.submitLocalReviewBatch]. P3.3.16.
class LocalWordAttempt {
  final String wordId;
  final String actionResult; // 'correct' | 'incorrect'

  const LocalWordAttempt({required this.wordId, required this.actionResult});
}

// ========== Phase 3: Session / Check-in Models ==========

class SessionInfo {
  final String sessionId;
  final String sessionStatus;
  final String sessionValidationStatus;
  final int sessionMinutesTarget;
  final String startedAt;
  final String? endedAt;
  final int effectiveLearningCount;
  final int effectiveReviewCount;
  final int? actualMinutes;
  final int? durationSeconds;

  SessionInfo({
    required this.sessionId,
    required this.sessionStatus,
    required this.sessionValidationStatus,
    required this.sessionMinutesTarget,
    required this.startedAt,
    this.endedAt,
    this.effectiveLearningCount = 0,
    this.effectiveReviewCount = 0,
    this.actualMinutes,
    this.durationSeconds,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      sessionId: json['session_id'] as String,
      sessionStatus: json['session_status'] as String,
      sessionValidationStatus: json['session_validation_status'] as String,
      sessionMinutesTarget: json['session_minutes_target'] as int,
      startedAt: json['started_at'] as String,
      endedAt: json['ended_at'] as String?,
      // The /sessions start response omits these — default to 0 to keep parsing robust.
      effectiveLearningCount: (json['effective_learning_count'] as int?) ?? 0,
      effectiveReviewCount: (json['effective_review_count'] as int?) ?? 0,
      actualMinutes: json['actual_minutes'] as int?,
      durationSeconds: json['duration_seconds'] as int?,
    );
  }
}

/// Need #10 — One cloud-accepted review attempt for a word.
class WordReviewHistoryItem {
  final String attemptId;
  final String wordId;
  final String reviewGroupId;
  final String actionResult;
  final String reviewedAt;
  final String? sessionId;

  WordReviewHistoryItem({
    required this.attemptId,
    required this.wordId,
    required this.reviewGroupId,
    required this.actionResult,
    required this.reviewedAt,
    this.sessionId,
  });

  factory WordReviewHistoryItem.fromJson(Map<String, dynamic> json) {
    return WordReviewHistoryItem(
      attemptId: json['attempt_id'] as String,
      wordId: json['word_id'] as String,
      reviewGroupId: json['review_group_id'] as String,
      actionResult: json['action_result'] as String,
      reviewedAt: json['reviewed_at'] as String,
      sessionId: json['session_id'] as String?,
    );
  }
}

class CheckInResult {
  final CheckInInfo checkIn;
  final StreakInfo streak;
  final LearningDayInfo learningDay;
  final bool alreadyExists;

  CheckInResult({
    required this.checkIn,
    required this.streak,
    required this.learningDay,
    required this.alreadyExists,
  });

  factory CheckInResult.fromJson(Map<String, dynamic> json) {
    return CheckInResult(
      checkIn: CheckInInfo.fromJson(json['check_in'] as Map<String, dynamic>),
      streak: StreakInfo.fromJson(json['streak'] as Map<String, dynamic>),
      learningDay: LearningDayInfo.fromJson(json['learning_day'] as Map<String, dynamic>),
      alreadyExists: json['already_exists'] as bool,
    );
  }
}

class CheckInInfo {
  final String localDate;
  final String checkInStatus;

  CheckInInfo({
    required this.localDate,
    required this.checkInStatus,
  });

  factory CheckInInfo.fromJson(Map<String, dynamic> json) {
    return CheckInInfo(
      localDate: json['local_date'] as String,
      checkInStatus: json['check_in_status'] as String,
    );
  }
}

class StreakInfo {
  final int currentStreak;
  final String streakBasisType;

  StreakInfo({
    required this.currentStreak,
    required this.streakBasisType,
  });

  factory StreakInfo.fromJson(Map<String, dynamic> json) {
    return StreakInfo(
      currentStreak: json['current_streak'] as int,
      streakBasisType: json['streak_basis_type'] as String,
    );
  }
}

class LearningDayInfo {
  final bool learningDayToday;

  LearningDayInfo({
    required this.learningDayToday,
  });

  factory LearningDayInfo.fromJson(Map<String, dynamic> json) {
    return LearningDayInfo(
      learningDayToday: json['learning_day_today'] as bool,
    );
  }
}

// ========== P2 Phase 1A: Secondary Summary Models ==========

class SecondarySummary {
  final int coins;
  final int fishTreats;
  final int exp;
  final CatSummary catSummary;
  final CompanionResponseData? companionResponse;
  final Map<String, String?> equippedPreview;
  final List<ChangeHighlightData> changeHighlights;
  final StatsSummaryData? statsSummary;
  final int reviewDebt;

  SecondarySummary({
    required this.coins,
    required this.fishTreats,
    required this.exp,
    required this.catSummary,
    this.companionResponse,
    this.equippedPreview = const {},
    this.changeHighlights = const [],
    this.statsSummary,
    this.reviewDebt = 0,
  });

  factory SecondarySummary.fromJson(Map<String, dynamic> json) {
    final rawPreview = json['equipped_preview'] as Map<String, dynamic>?;
    final preview = <String, String?>{};
    if (rawPreview != null) {
      for (final e in rawPreview.entries) {
        preview[e.key] = e.value as String?;
      }
    }
    return SecondarySummary(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      fishTreats: (json['fish_treats'] as num?)?.toInt() ?? 0,
      exp: (json['exp'] as num?)?.toInt() ?? 0,
      catSummary: CatSummary.fromJson(
        (json['cat_summary'] as Map<String, dynamic>?) ?? const {},
      ),
      companionResponse: json['companion_response'] != null
          ? CompanionResponseData.fromJson(
              json['companion_response'] as Map<String, dynamic>,
            )
          : null,
      equippedPreview: preview,
      // B23-A: change_highlights is optional — missing or null → empty list
      changeHighlights: (json['change_highlights'] as List<dynamic>?)
          ?.map((h) => ChangeHighlightData.fromJson(h as Map<String, dynamic>))
          .toList() ?? const [],
      // C3: stats_summary is optional — missing or null → null
      statsSummary: json['stats_summary'] != null
          ? StatsSummaryData.fromJson(json['stats_summary'] as Map<String, dynamic>)
          : null,
      reviewDebt: (json['review_debt'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Minimal statistics summary (C3 — summary-first).
/// total_learning_days is based on learning_day ONLY, not check_in or streak.
/// total_check_ins is separate and independent from learning_days.
class StatsSummaryData {
  final int totalLearningDays;
  final int totalWordsLearned;
  final int totalReviewGroupsCompleted;
  final int totalCheckIns;
  final int currentStreak;
  final String streakBasis;

  StatsSummaryData({
    required this.totalLearningDays,
    required this.totalWordsLearned,
    required this.totalReviewGroupsCompleted,
    required this.totalCheckIns,
    required this.currentStreak,
    required this.streakBasis,
  });

  factory StatsSummaryData.fromJson(Map<String, dynamic> json) {
    return StatsSummaryData(
      totalLearningDays: (json['total_learning_days'] as num?)?.toInt() ?? 0,
      totalWordsLearned: (json['total_words_learned'] as num?)?.toInt() ?? 0,
      totalReviewGroupsCompleted: (json['total_review_groups_completed'] as num?)?.toInt() ?? 0,
      totalCheckIns: (json['total_check_ins'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      streakBasis: json['streak_basis'] as String? ?? 'check_in',
    );
  }
}

/// Read-only change highlight data (B23-A).
/// This is a summary/hint layer, NOT a truth layer.
/// UI must not use `label` alone to override ownership/equipment/reward/streak truth.
class ChangeHighlightData {
  final String kind;
  final String status;
  final String label;
  final String? relatedItemCode;

  ChangeHighlightData({
    required this.kind,
    required this.status,
    required this.label,
    this.relatedItemCode,
  });

  factory ChangeHighlightData.fromJson(Map<String, dynamic> json) {
    return ChangeHighlightData(
      kind: json['kind'] as String? ?? '',
      status: json['status'] as String? ?? 'hinted',
      label: json['label'] as String? ?? '',
      relatedItemCode: json['related_item_code'] as String?,
    );
  }
}

class CompanionResponseData {
  final String dailyGreeting;
  final String? postLearningResponse;
  final String? streakNodeResponse;

  CompanionResponseData({
    required this.dailyGreeting,
    this.postLearningResponse,
    this.streakNodeResponse,
  });

  factory CompanionResponseData.fromJson(Map<String, dynamic> json) {
    return CompanionResponseData(
      dailyGreeting: json['daily_greeting'] as String? ?? '',
      postLearningResponse: json['post_learning_response'] as String?,
      streakNodeResponse: json['streak_node_response'] as String?,
    );
  }
}

class CatSummary {
  final String nickname;
  final int level;
  final int mood;
  final int bond;
  final String energy;

  CatSummary({
    required this.nickname,
    required this.level,
    required this.mood,
    required this.bond,
    required this.energy,
  });

  factory CatSummary.fromJson(Map<String, dynamic> json) {
    return CatSummary(
      nickname: json['nickname'] as String? ?? 'Mimi',
      level: (json['level'] as num?)?.toInt() ?? 1,
      mood: (json['mood'] as num?)?.toInt() ?? 60,
      bond: (json['bond'] as num?)?.toInt() ?? 0,
      energy: json['energy'] as String? ?? 'medium',
    );
  }
}

// ========== P2 Phase 2A: Feed Models ==========

class FeedResponse {
  final FeedResult feedResult;
  final GrowthFeedback? growthFeedback;
  final SecondarySummary secondarySummary;

  FeedResponse({
    required this.feedResult,
    this.growthFeedback,
    required this.secondarySummary,
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    return FeedResponse(
      feedResult: FeedResult.fromJson(
        json['feed_result'] as Map<String, dynamic>,
      ),
      growthFeedback: json['growth_feedback'] != null
          ? GrowthFeedback.fromJson(
              json['growth_feedback'] as Map<String, dynamic>,
            )
          : null,
      secondarySummary: SecondarySummary.fromJson(
        json['secondary_summary'] as Map<String, dynamic>,
      ),
    );
  }
}

class GrowthFeedback {
  final bool leveledUp;
  final int previousLevel;
  final int currentLevel;

  GrowthFeedback({
    required this.leveledUp,
    required this.previousLevel,
    required this.currentLevel,
  });

  factory GrowthFeedback.fromJson(Map<String, dynamic> json) {
    return GrowthFeedback(
      leveledUp: json['leveled_up'] as bool? ?? false,
      previousLevel: (json['previous_level'] as num?)?.toInt() ?? 1,
      currentLevel: (json['current_level'] as num?)?.toInt() ?? 1,
    );
  }
}

class FeedResult {
  final String status;
  final String? errorCode;
  final String? consumedItem;
  final int consumedAmount;
  final int? moodDelta;
  final int? expDelta;
  final bool alreadyExists;

  FeedResult({
    required this.status,
    this.errorCode,
    this.consumedItem,
    required this.consumedAmount,
    this.moodDelta,
    this.expDelta,
    this.alreadyExists = false,
  });

  bool get isSuccess => status == 'succeeded';
  bool get isInsufficientResource => status == 'insufficient_resource';

  factory FeedResult.fromJson(Map<String, dynamic> json) {
    return FeedResult(
      status: json['status'] as String,
      errorCode: json['error_code'] as String?,
      consumedItem: json['consumed_item'] as String?,
      consumedAmount: (json['consumed_amount'] as num?)?.toInt() ?? 0,
      moodDelta: (json['mood_delta'] as num?)?.toInt(),
      expDelta: (json['exp_delta'] as num?)?.toInt(),
      alreadyExists: json['already_exists'] as bool? ?? false,
    );
  }
}

// ========== P2 Phase 2D: Shop / Inventory Models ==========

class CatalogResponse {
  final List<CatalogItemData> items;

  CatalogResponse({required this.items});

  factory CatalogResponse.fromJson(Map<String, dynamic> json) {
    return CatalogResponse(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => CatalogItemData.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CatalogItemData {
  final String itemId;
  final String itemType;
  final String slot;
  final String name;
  final int coinPrice;
  final int requiredLevel;
  final bool isActive;

  CatalogItemData({
    required this.itemId,
    required this.itemType,
    required this.slot,
    required this.name,
    required this.coinPrice,
    required this.requiredLevel,
    required this.isActive,
  });

  factory CatalogItemData.fromJson(Map<String, dynamic> json) {
    return CatalogItemData(
      itemId: json['item_id'] as String,
      itemType: json['item_type'] as String,
      slot: json['slot'] as String,
      name: json['name'] as String,
      coinPrice: (json['coin_price'] as num).toInt(),
      requiredLevel: (json['required_level'] as num).toInt(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class InventoryStateData {
  final List<OwnedItemData> ownedItems;
  final int coinsBalance;

  InventoryStateData({
    required this.ownedItems,
    required this.coinsBalance,
  });

  factory InventoryStateData.fromJson(Map<String, dynamic> json) {
    return InventoryStateData(
      ownedItems: (json['owned_items'] as List<dynamic>? ?? [])
          .map((i) => OwnedItemData.fromJson(i as Map<String, dynamic>))
          .toList(),
      coinsBalance: (json['coins_balance'] as num?)?.toInt() ?? 0,
    );
  }
}

class OwnedItemData {
  final String itemId;
  final String itemType;
  final String slot;
  final String ownedAt;
  final bool equipped;

  OwnedItemData({
    required this.itemId,
    required this.itemType,
    required this.slot,
    required this.ownedAt,
    this.equipped = false,
  });

  factory OwnedItemData.fromJson(Map<String, dynamic> json) {
    return OwnedItemData(
      itemId: json['item_id'] as String,
      itemType: json['item_type'] as String,
      slot: json['slot'] as String,
      ownedAt: json['owned_at'] as String,
      equipped: json['equipped'] as bool? ?? false,
    );
  }
}

class PurchaseResponse {
  final PurchaseResultData purchaseResult;
  final InventoryStateData inventory;

  PurchaseResponse({
    required this.purchaseResult,
    required this.inventory,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseResponse(
      purchaseResult: PurchaseResultData.fromJson(
        json['purchase_result'] as Map<String, dynamic>,
      ),
      inventory: InventoryStateData.fromJson(
        json['inventory'] as Map<String, dynamic>,
      ),
    );
  }
}

class PurchaseResultData {
  final String status;
  final String? errorCode;
  final String itemId;
  final int coinsSpent;
  final bool alreadyExists;

  PurchaseResultData({
    required this.status,
    this.errorCode,
    required this.itemId,
    required this.coinsSpent,
    this.alreadyExists = false,
  });

  bool get isSuccess => status == 'succeeded';
  bool get isFailed => status == 'failed';

  factory PurchaseResultData.fromJson(Map<String, dynamic> json) {
    return PurchaseResultData(
      status: json['status'] as String,
      errorCode: json['error_code'] as String?,
      itemId: json['item_id'] as String,
      coinsSpent: (json['coins_spent'] as num?)?.toInt() ?? 0,
      alreadyExists: json['already_exists'] as bool? ?? false,
    );
  }
}

// ========== P2 Phase 3: Equipment Models ==========

class EquipmentResponse {
  final EquippedSnapshotData equippedSnapshot;

  EquipmentResponse({required this.equippedSnapshot});

  factory EquipmentResponse.fromJson(Map<String, dynamic> json) {
    return EquipmentResponse(
      equippedSnapshot: EquippedSnapshotData.fromJson(
        json['equipped_snapshot'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class EquippedSnapshotData {
  final Map<String, String?> outfit;
  final Map<String, String?> room;

  EquippedSnapshotData({this.outfit = const {}, this.room = const {}});

  factory EquippedSnapshotData.fromJson(Map<String, dynamic> json) {
    Map<String, String?> parseSlotMap(Map<String, dynamic>? raw) {
      if (raw == null) return {};
      return raw.map((k, v) => MapEntry(k, v as String?));
    }
    return EquippedSnapshotData(
      outfit: parseSlotMap(json['outfit'] as Map<String, dynamic>?),
      room: parseSlotMap(json['room'] as Map<String, dynamic>?),
    );
  }
}

class EquipResponse {
  final EquipResultData equipResult;
  final EquippedSnapshotData equippedSnapshot;

  EquipResponse({required this.equipResult, required this.equippedSnapshot});

  factory EquipResponse.fromJson(Map<String, dynamic> json) {
    return EquipResponse(
      equipResult: EquipResultData.fromJson(
        json['equip_result'] as Map<String, dynamic>,
      ),
      equippedSnapshot: EquippedSnapshotData.fromJson(
        json['equipped_snapshot'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class EquipResultData {
  final String status;
  final String? errorCode;
  final String itemId;
  final String? slot;
  final String? itemType;
  final bool alreadyExists;

  EquipResultData({
    required this.status,
    this.errorCode,
    required this.itemId,
    this.slot,
    this.itemType,
    this.alreadyExists = false,
  });

  bool get isSuccess => status == 'succeeded';

  factory EquipResultData.fromJson(Map<String, dynamic> json) {
    return EquipResultData(
      status: json['status'] as String,
      errorCode: json['error_code'] as String?,
      itemId: json['item_id'] as String,
      slot: json['slot'] as String?,
      itemType: json['item_type'] as String?,
      alreadyExists: json['already_exists'] as bool? ?? false,
    );
  }
}

// ========== Phase D: Fishing + Lottery Models ==========

class DailyTaskStatus {
  final String taskId;
  final String taskDate;
  final int roundsCompleted;
  final int roundsTotal;
  final String status; // 'available' | 'exhausted'
  final bool hasActiveRound;
  final int fishTreatsBalance;

  DailyTaskStatus({
    required this.taskId,
    required this.taskDate,
    required this.roundsCompleted,
    required this.roundsTotal,
    required this.status,
    required this.hasActiveRound,
    required this.fishTreatsBalance,
  });

  factory DailyTaskStatus.fromJson(Map<String, dynamic> json) {
    return DailyTaskStatus(
      taskId: json['task_id'] as String,
      taskDate: json['task_date'] as String,
      roundsCompleted: (json['rounds_completed'] as num).toInt(),
      roundsTotal: (json['rounds_total'] as num).toInt(),
      status: json['status'] as String,
      hasActiveRound: json['has_active_round'] as bool? ?? false,
      fishTreatsBalance: (json['fish_treats_balance'] as num?)?.toInt() ?? 0,
    );
  }
}

class FishingChoice {
  final String wordId;
  final String wordText;
  FishingChoice({required this.wordId, required this.wordText});
  factory FishingChoice.fromJson(Map<String, dynamic> json) => FishingChoice(
        wordId: json['word_id'] as String,
        wordText: json['word_text'] as String,
      );
}

class FishingRoundQuestion {
  final String taskId;
  final int roundNumber;
  final List<FishingChoice> choices;
  FishingRoundQuestion({
    required this.taskId,
    required this.roundNumber,
    required this.choices,
  });
  factory FishingRoundQuestion.fromJson(Map<String, dynamic> json) {
    final list = (json['choices'] as List<dynamic>)
        .map((e) => FishingChoice.fromJson(e as Map<String, dynamic>))
        .toList();
    return FishingRoundQuestion(
      taskId: json['task_id'] as String,
      roundNumber: (json['round_number'] as num).toInt(),
      choices: list,
    );
  }
}

class FishingFishWord {
  final String wordId;
  final String wordText;
  final String meaning;
  FishingFishWord({required this.wordId, required this.wordText, required this.meaning});
  factory FishingFishWord.fromJson(Map<String, dynamic> json) => FishingFishWord(
        wordId: json['word_id'] as String,
        wordText: json['word_text'] as String,
        meaning: json['meaning'] as String,
      );
}

class FishingAttemptResult {
  final bool isCorrect;
  final FishingFishWord? fishWord;
  final int fishTreatsEarned;
  final int roundsCompleted;
  final int roundsTotal;
  final String status;
  final bool boxEarned;
  final String? boxId;
  final int fishTreatsBalance;

  FishingAttemptResult({
    required this.isCorrect,
    required this.fishWord,
    required this.fishTreatsEarned,
    required this.roundsCompleted,
    required this.roundsTotal,
    required this.status,
    required this.boxEarned,
    required this.boxId,
    required this.fishTreatsBalance,
  });

  factory FishingAttemptResult.fromJson(Map<String, dynamic> json) {
    return FishingAttemptResult(
      isCorrect: json['is_correct'] as bool? ?? false,
      fishWord: json['fish_word'] != null
          ? FishingFishWord.fromJson(json['fish_word'] as Map<String, dynamic>)
          : null,
      fishTreatsEarned: (json['fish_treats_earned'] as num?)?.toInt() ?? 0,
      roundsCompleted: (json['rounds_completed'] as num?)?.toInt() ?? 0,
      roundsTotal: (json['rounds_total'] as num?)?.toInt() ?? 3,
      status: json['status'] as String? ?? 'available',
      boxEarned: json['box_earned'] as bool? ?? false,
      boxId: json['box_id'] as String?,
      fishTreatsBalance: (json['fish_treats_balance'] as num?)?.toInt() ?? 0,
    );
  }
}

class LotteryBoxData {
  final String id;
  final String source;
  final String createdAt;
  LotteryBoxData({required this.id, required this.source, required this.createdAt});
  factory LotteryBoxData.fromJson(Map<String, dynamic> json) => LotteryBoxData(
        id: json['id'] as String,
        source: json['source'] as String,
        createdAt: json['created_at'] as String,
      );
}

class LotteryBoxesResponse {
  final List<LotteryBoxData> pendingBoxes;
  final int totalPending;
  final int coinsBalance;
  final int fishTreatsBalance;

  LotteryBoxesResponse({
    required this.pendingBoxes,
    required this.totalPending,
    required this.coinsBalance,
    required this.fishTreatsBalance,
  });

  factory LotteryBoxesResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['pending_boxes'] as List<dynamic>? ?? [])
        .map((e) => LotteryBoxData.fromJson(e as Map<String, dynamic>))
        .toList();
    return LotteryBoxesResponse(
      pendingBoxes: list,
      totalPending: (json['total_pending'] as num?)?.toInt() ?? 0,
      coinsBalance: (json['coins_balance'] as num?)?.toInt() ?? 0,
      fishTreatsBalance: (json['fish_treats_balance'] as num?)?.toInt() ?? 0,
    );
  }
}

class LotteryOpenResult {
  final bool opened;
  final String? boxId;
  final String? prizeType;
  final int coinsWon;
  final int coinsBalance;

  LotteryOpenResult({
    required this.opened,
    required this.boxId,
    required this.prizeType,
    required this.coinsWon,
    required this.coinsBalance,
  });

  factory LotteryOpenResult.fromJson(Map<String, dynamic> json) {
    return LotteryOpenResult(
      opened: json['opened'] as bool? ?? false,
      boxId: json['box_id'] as String?,
      prizeType: json['prize_type'] as String?,
      coinsWon: (json['coins_won'] as num?)?.toInt() ?? 0,
      coinsBalance: (json['coins_balance'] as num?)?.toInt() ?? 0,
    );
  }
}

class ApiException implements Exception {
  final String message;

  /// HTTP status code, if available.
  /// Used by ReviewPage to distinguish `not_ready_now` (404) from
  /// `temporarily_unservable` (network/server errors).
  /// schedule_source_contract_v1 (P3.3.3): readiness derivation uses cloud
  /// signals — this statusCode is from the cloud response, not local FSRS.
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message';
}
