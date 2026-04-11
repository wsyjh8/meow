/// fact_settlement_ingest_contract_candidate_v1 (FROZEN, P3.3.6)
///
/// Contract anchor for future local-evidence → cloud-fact ingest boundary.
/// Even if future serving owner shifts to local, the fact/settlement
/// owner does NOT automatically shift (RF-P3.3.6-008).
///
/// This file is a CONTRACT ANCHOR — it exposes enums and constants that
/// express which facts remain cloud-owned and what the ingest action
/// semantics are. It does not perform any ingest and is not consumed by
/// any runtime path.
///
/// ============================================================================
/// Frozen rules referenced
/// ============================================================================
///
/// RF-P3.3.6-008: planner/serving owner shift does NOT auto-bring
///                fact/settlement owner shift. Even if future serving
///                shifts to local, the following remain cloud-owned:
///                  - effective_review_fact
///                  - daily_goal_progress
///                  - reward_settlement_ledger
///                  - check_in / learning_day / streak
///
/// RF-P3.3.6-009: local-serving candidate is ONLY an evidence/ingest
///                candidate — NOT a direct ledger writer.
///                Allowed layers: attempt/completion/progress candidate
///                evidence, future ingest interface candidate, accept/
///                reject/duplicate shadow/parity verification.
///                Forbidden: direct ledger change, direct daily goal
///                change, direct streak/learning_day change.
///
/// RF-P3.3.6-010: this round freezes MINIMUM interface semantics only,
///                NOT final API/DB rewrite. What's frozen:
///                  - ingest necessity
///                  - accept / reject / duplicate three result semantics
///                  - evidence vs runtime truth boundary
///                What's NOT frozen:
///                  - API core semantics rewrite
///                  - DB schema rewrite
///                  - reward/settlement owner rewrite
library;

/// The three ingest actions the cloud fact layer takes on local evidence.
///
/// These are the ONLY allowed shadow-parity outcomes for local evidence
/// this round — none of them directly mutate runtime final facts.
enum FactIngestAction {
  /// Cloud fact layer has accepted the local evidence as valid input.
  /// This is still NOT a direct fact write — it's an ingest result.
  /// Any downstream fact change still flows through cloud settlement.
  accept,

  /// Cloud fact layer has rejected the local evidence.
  /// Reasons may include: format mismatch, timing, conflict, schema gap.
  reject,

  /// Cloud fact layer has identified the local evidence as duplicate.
  /// Idempotency detected — no double-counting.
  duplicate,
}

/// Contract anchor constants for fact/settlement ingest boundary.
abstract final class FactSettlementIngestBoundary {
  /// Final facts that MUST stay cloud-owned this round (RF-P3.3.6-008).
  ///
  /// Local evidence can feed into these as ingest candidates, but local
  /// code MUST NOT directly rewrite any of them.
  static const List<String> kCloudOwnedFinalFacts = [
    'effective_review_fact',
    'daily_goal_progress',
    'reward_settlement_ledger',
    'check_in_learning_day_streak',
  ];

  /// The 3 canonical ingest action names.
  /// Tests assert this list has exactly 3 entries.
  static const List<String> kIngestActionNames = [
    'accept',
    'reject',
    'duplicate',
  ];

  /// Ingest evidence layer — where local evidence is allowed to live.
  /// MUST NOT be a runtime truth layer.
  static const String kEvidenceLayer = 'shadow_parity_evidence';

  /// Final fact owner this round — cloud backend fact layer.
  /// NOT a cut candidate this round (RF-P3.3.6-008).
  static const String kFinalFactOwner = 'cloud_backend_fact_layer';

  /// Forbidden claims — must never appear in user-facing UI.
  /// Local evidence can never claim to have directly changed any of these.
  /// The last entry ("已记为有效复习") is only allowed when the cloud fact
  /// layer has confirmed — never from local-only evidence.
  static const List<String> kForbiddenLocalFactClaims = [
    '本地已直接记为有效复习',
    '今日进度已因本地 shadow 更新',
    '奖励已因本地队列到账',
    'streak 已由本地 shadow 续上',
    'local evidence 已成为 final fact',
    '学习事实已同步到云端',
  ];
}
