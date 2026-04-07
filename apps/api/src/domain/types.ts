/**
 * Domain types for Phase 1 & Phase 2 & Phase 3
 */

/**
 * Canonical status names (frozen)
 */
export type DailyGoalStatus = 'not_started' | 'in_progress' | 'partially_completed' | 'completed';
export type SessionStatus = 'started' | 'ended' | 'validating' | 'valid' | 'invalid';
export type SessionValidationStatus = 'pending' | 'valid' | 'invalid';
export type RewardSettlementStatus = 'pending' | 'settling' | 'succeeded' | 'failed' | 'claimed';
export type RewardStatus = 'pending' | 'succeeded' | 'failed';
export type CheckInStatus = 'succeeded' | 'failed';

/**
 * Study attempt types
 */
export type StudyType = 'new' | 'review';
export type StudyActionResult = 'know' | 'forgot';

/**
 * Review attempt types
 */
export type ReviewActionResult = 'correct' | 'incorrect';

/**
 * Review group status
 */
export type ReviewGroupStatus = 'active' | 'completed';

/**
 * Source event types (Phase 2)
 */
export type SourceEventType = 'effective_new_word' | 'review_group_completed';

/**
 * Reward types (Phase 2 MVP)
 */
export type RewardType = 'coins' | 'fish_treats' | 'exp';

/**
 * Word entity
 */
export interface Word {
  word_id: string;
  word_text: string;
  meaning: string;
  phonetic?: string;
  book_id: string;
  // Extended fields from CET-4 CSV (all optional for backwards compatibility)
  translation?: string;
  definition?: string;
  difficulty_level?: number;
  is_core?: boolean;
  tags?: string;
  frequency_rank?: number;
  word_forms?: string;
}

/**
 * Study attempt entity
 */
export interface StudyAttempt {
  id: string;
  user_id: string;
  word_id: string;
  book_id: string;
  study_type: StudyType;
  action_result: StudyActionResult;
  created_at: string;
}

/**
 * Review group item
 */
export interface ReviewGroupItem {
  word_id: string;
  word_text: string;
  meaning: string;
  completed: boolean;
}

/**
 * Review group entity
 *
 * Frozen rules:
 * - Backend generates and holds
 * - Only one active group per user at a time
 * - Group completion only advances today's review progress
 * - Group completion != today's review completion
 * - Same active group can span across sessions
 * - No duplicate completion/settlement/rewards
 */
export interface ReviewGroup {
  review_group_id: string;
  user_id: string;
  group_status: ReviewGroupStatus;
  group_completed: boolean;
  items: ReviewGroupItem[];
  created_at: string;
  completed_at?: string;
}

/**
 * Review attempt entity
 */
export interface ReviewAttempt {
  id: string;
  user_id: string;
  review_group_id: string;
  word_id: string;
  action_result: ReviewActionResult;
  created_at: string;
}

/**
 * Reward source event (Phase 2)
 *
 * Represents a main mechanism event that can trigger settlement.
 * Two-layer structure:
 * - Layer 1: Source event (this)
 * - Layer 2: Reward ledger items
 */
export interface RewardSourceEvent {
  source_event_id: string;
  user_id: string;
  source_event_type: SourceEventType;
  source_ref_id: string; // e.g., study attempt id or review group id
  created_at: string;
}

/**
 * Reward ledger item (Phase 2)
 *
 * Represents a specific reward item tied to a source event.
 * reward_status is independent from reward_settlement_status.
 */
export interface RewardLedgerItem {
  reward_item_id: string;
  source_event_id: string;
  user_id: string;
  reward_type: RewardType;
  amount: number;
  reward_status: RewardStatus;
  created_at: string;
}

/**
 * Settlement record (Phase 2)
 *
 * Ties together source event and reward ledger.
 */
export interface Settlement {
  settlement_id: string;
  source_event_id: string;
  user_id: string;
  reward_settlement_status: RewardSettlementStatus;
  reward_items: RewardLedgerItem[];
  created_at: string;
  updated_at: string;
}

/**
 * Today state (aggregated)
 */
export interface TodayState {
  user_id: string;
  local_date: string;
  current_book_name: string;
  today_new_target: number;
  today_new_completed: number;
  today_review_target: number;
  today_review_pending: number;
  today_review_completed: number;
  daily_goal_status: DailyGoalStatus;
  active_review_group_id: string | null;
  active_review_group_status: ReviewGroupStatus | null;
  active_review_group_remaining: number;
  sync_status: 'healthy' | 'syncing' | 'error';
  // Phase 2: Last reward settlement summary
  last_reward_settlement: {
    source_event_id: string | null;
    reward_settlement_status: RewardSettlementStatus | null;
  } | null;
  // Phase 3: Session / Check-in / Streak summary
  has_checked_in_today: boolean;
  learning_day_today: boolean;
  current_streak: number;
  streak_basis_type: 'check_in' | 'learning_day';
  session_started_today: boolean;
  session_valid_today: boolean;
  user_local_date: string;
  user_timezone: string;
  // P3 Phase 1: Very small CTA decision-support block (optional)
  today_primary_action?: TodayPrimaryAction;
  // P3 Phase 2: Very small review deeper summary (optional)
  review_summary?: ReviewSummary;
}

/**
 * Very small review deeper summary (P3 Phase 2).
 *
 * Assumption (temporary, not frozen):
 * - Only has_active_group, active_group_progress, active_group_completed,
 *   daily_review_progress, next_group_readiness are in scope.
 * - No full SRS, no priority engine, no local readiness inference.
 * - When absent, UI falls back to current active baseline.
 */
export type DailyReviewProgressStatus = 'not_started' | 'in_progress' | 'completed';
export type NextGroupReadiness = 'ready' | 'not_ready';

export interface ReviewSummary {
  has_active_group: boolean;
  active_group_progress: {
    completed_items: number;
    total_items: number;
  };
  active_group_completed: boolean;
  daily_review_progress: {
    completed_units: number;
    required_units: number;
    status: DailyReviewProgressStatus;
  };
  next_group_readiness: NextGroupReadiness;
}

/**
 * Very small CTA decision-support block (P3 Phase 1).
 *
 * Assumption (temporary, not frozen):
 * - Only `action` + `reason` are in scope for P3 Phase 1.
 * - `priority_band` and `blocking_condition` are NOT in this round.
 * - This is decision-support, not a "big CTA engine".
 * - When absent, UI must fall back to current Option C CTA baseline.
 */
export type TodayPrimaryActionType = 'continue_review_group' | 'go_review' | 'go_new_words' | 'go_session';
export type TodayPrimaryActionReason = 'active_review_group' | 'review_due_priority' | 'new_words_remaining' | 'session_pending';

export interface TodayPrimaryAction {
  action: TodayPrimaryActionType;
  reason: TodayPrimaryActionReason;
}

/**
 * Current secondary-currency balances derived from settled rewards.
 *
 * Assumption (temporary, not frozen):
 * - For dev mode, balances are computed from succeeded reward ledger items only.
 * - Spending / inventory deduction is not part of Phase 1A.
 */
export interface BalanceSnapshot {
  coins: number;
  fish_treats: number;
  exp: number;
}

/**
 * Minimal cat-facing summary for P2 bridge layer.
 *
 * Assumption (temporary, not frozen):
 * - This is a dev-mode placeholder truth, not a frozen pet-system design.
 * - Level / mood / bond / energy are minimum readable facts for downstream UI.
 */
export interface CatSummary {
  nickname: string;
  level: number;
  mood: number;
  bond: number;
  energy: 'low' | 'medium' | 'high';
}

/**
 * Companion response (Phase 2C)
 *
 * Assumption (temporary, not frozen):
 * - companion response strings and trigger rules in Phase 2C are minimal
 *   development copy rules based on current factual states, not a frozen
 *   narrative/copy system.
 */
export interface CompanionResponse {
  daily_greeting: string;
  post_learning_response: string | null;
  streak_node_response: string | null;
}

/**
 * Secondary summary read model for P2.
 */
export interface SecondarySummary extends BalanceSnapshot {
  cat_summary: CatSummary;
  companion_response: CompanionResponse;
  equipped_preview: Record<string, string | null>;
  change_highlights?: ChangeHighlight[];
  stats_summary?: StatsSummary;
}

/**
 * Minimal stats summary (C3 — summary-first / minimal summary).
 *
 * Assumption (temporary, not frozen):
 * - This is a read-only summary, not a full statistics product.
 * - `total_learning_days` is based on learning_day records ONLY, NOT check_in or streak.
 * - `total_check_ins` is separate from learning_days — they are independent facts.
 * - This does not replace or redefine check_in / learning_day / streak semantics.
 */
export interface StatsSummary {
  total_learning_days: number;
  total_words_learned: number;
  total_review_groups_completed: number;
  total_check_ins: number;
  current_streak: number;
  streak_basis: 'check_in' | 'learning_day';
}

/**
 * Read-only summary/hint layer for recent changes (B2-3 / B23-A).
 *
 * Assumption (temporary, not frozen):
 * - This is a read-only extension, not a new truth layer.
 * - `label` is display copy only, not a structured truth field.
 * - `hinted` means the change is expected but not yet backend-confirmed.
 * - `confirmed` means the change is backed by an existing truth layer
 *   (ownership, equipment, reward ledger, streak, etc.), but this field
 *   does NOT replace those truth layers.
 * - UI must not use `label` alone to override ownership/equipment/reward/streak truth.
 */
export type ChangeHighlightKind = 'purchase' | 'equip' | 'growth' | 'streak' | 'post_learning';
export type ChangeHighlightStatus = 'confirmed' | 'hinted';

export interface ChangeHighlight {
  kind: ChangeHighlightKind;
  status: ChangeHighlightStatus;
  label: string;
  related_item_code: string | null;
}

/**
 * Feed item types (Phase 2A)
 *
 * Assumption (temporary, not frozen):
 * - Only fish_treat is available in Phase 2A.
 */
export type FeedItemType = 'fish_treat';

/**
 * Feed result status (Phase 2A)
 */
export type FeedResultStatus = 'succeeded' | 'insufficient_resource';

/**
 * Feed record (Phase 2A)
 *
 * Tracks each real feed action for truth and anti-spam.
 */
export interface FeedRecord {
  feed_id: string;
  user_id: string;
  feed_item_type: FeedItemType;
  consumed_amount: number;
  mood_delta: number;
  exp_delta: number;
  bond_delta: number;
  local_date: string;
  created_at: string;
}

/**
 * Catalog item type (Phase 2D)
 */
export type CatalogItemType = 'outfit' | 'room_item';

/**
 * Catalog item (Phase 2D)
 *
 * Assumption (temporary, not frozen):
 * - Catalog items are hardcoded dev data for Phase 2D.
 * - Prices and level requirements are minimal dev rules, not frozen.
 */
export interface CatalogItem {
  item_id: string;
  item_type: CatalogItemType;
  slot: string;
  name: string;
  coin_price: number;
  required_level: number;
  is_active: boolean;
}

/**
 * Owned item record (Phase 2D)
 */
export interface OwnedItem {
  item_id: string;
  item_type: CatalogItemType;
  slot: string;
  owned_at: string;
  equipped: boolean;
}

/**
 * Inventory state (Phase 2D)
 */
export interface InventoryState {
  owned_items: OwnedItem[];
  coins_balance: number;
}

/**
 * Purchase result status (Phase 2D)
 */
export type PurchaseResultStatus = 'succeeded' | 'failed';

/**
 * Purchase error codes (Phase 2D)
 */
export type PurchaseErrorCode =
  | 'COINS_NOT_ENOUGH'
  | 'ITEM_ALREADY_OWNED'
  | 'ITEM_NOT_FOUND'
  | 'ITEM_LEVEL_LOCKED';

/**
 * Equipped snapshot (Phase 3)
 *
 * Tracks what is currently equipped per slot.
 * One item per slot; null means nothing equipped in that slot.
 */
export interface EquippedSnapshot {
  outfit: Record<string, string | null>;
  room: Record<string, string | null>;
}

/**
 * Equip result status (Phase 3)
 */
export type EquipResultStatus = 'succeeded' | 'failed';

/**
 * Equip error codes (Phase 3)
 */
export type EquipErrorCode =
  | 'ITEM_NOT_OWNED'
  | 'ITEM_NOT_FOUND';

/**
 * Idempotency key record
 */
export interface IdempotencyKeyRecord {
  key: string;
  user_id: string;
  path: string;
  response: Record<string, unknown>;
  created_at: string;
}

/**
 * Session entity (Phase 3)
 *
 * Frozen rules:
 * - session_status and session_validation_status are separate
 * - started / ended != valid
 * - Only after validation can we get valid or invalid
 */
export interface Session {
  session_id: string;
  user_id: string;
  session_status: SessionStatus;
  session_validation_status: SessionValidationStatus;
  session_minutes_target: number;
  started_at: string;
  ended_at?: string;
  effective_learning_count: number;
  effective_review_count: number;
  actual_minutes?: number;
}

/**
 * Check-in record (Phase 3)
 */
export interface CheckInRecord {
  check_in_id: string;
  user_id: string;
  local_date: string;
  check_in_status: CheckInStatus;
  created_at: string;
}

/**
 * Streak record (Phase 3)
 *
 * Current MVP: streak_basis_type = 'check_in'
 */
export interface StreakRecord {
  user_id: string;
  current_streak: number;
  streak_basis_type: 'check_in' | 'learning_day';
  last_check_in_date: string | null;
  updated_at: string;
}

/**
 * Learning day record (Phase 3)
 */
export interface LearningDayRecord {
  user_id: string;
  local_date: string;
  learning_day: boolean;
  effective_learning_count: number;
  effective_review_count: number;
  updated_at: string;
}
