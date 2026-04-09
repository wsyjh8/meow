/**
 * Development In-Memory Store for Phase 1
 * 
 * Assumption (temporary, not frozen):
 * - This is a development-only in-memory store for Phase 1 rapid iteration.
 * - It will be replaced with a real database in later phases.
 * - Code structure is designed to allow easy replacement.
 */

import {
  TodayState,
  StudyAttempt,
  ReviewGroup,
  ReviewAttempt,
  Word,
  IdempotencyKeyRecord,
  DailyGoalStatus,
  RewardSourceEvent,
  RewardLedgerItem,
  Settlement,
  RewardSettlementStatus,
  SourceEventType,
  RewardStatus,
  Session,
  SessionStatus,
  SessionValidationStatus,
  CheckInRecord,
  StreakRecord,
  LearningDayRecord,
  CheckInStatus,
  BalanceSnapshot,
  CatSummary,
  SecondarySummary,
  CompanionResponse,
  FeedRecord,
  FeedItemType,
  FeedResultStatus,
  CatalogItem,
  OwnedItem,
  InventoryState,
  PurchaseResultStatus,
  PurchaseErrorCode,
  EquippedSnapshot,
  EquipResultStatus,
  EquipErrorCode,
  ChangeHighlight,
  StatsSummary,
  TodayPrimaryAction,
  ReviewSummary,
  DailyReviewProgressStatus,
  NextGroupReadiness,
} from './types';

const DEV_USER_ID = 'dev-user-001';
const DEV_BOOK_ID = 'book-001';
const DEV_BOOK_NAME = 'CET-4';
const DEV_CAT_NICKNAME = 'Mimi';

/**
 * Assumption (temporary, not frozen):
 * Current Phase 2B level thresholds follow the current MVP secondary numbers draft
 * for Lv1–Lv10, and can still be adjusted by future numeric balancing if Room 1
 * re-pins the numbers baseline.
 *
 * cumulative_exp is the total EXP needed to reach that level.
 * Level 1 requires 0 cumulative EXP (starting level).
 */
const LEVEL_THRESHOLDS: { level: number; cumulative_exp: number }[] = [
  { level: 1, cumulative_exp: 0 },
  { level: 2, cumulative_exp: 20 },
  { level: 3, cumulative_exp: 50 },
  { level: 4, cumulative_exp: 90 },
  { level: 5, cumulative_exp: 145 },
  { level: 6, cumulative_exp: 215 },
  { level: 7, cumulative_exp: 305 },
  { level: 8, cumulative_exp: 420 },
  { level: 9, cumulative_exp: 565 },
  { level: 10, cumulative_exp: 745 },
];

/**
 * Compute level from total accumulated EXP.
 * Caps at Lv10 for Phase 2B.
 */
function computeLevelFromExp(totalExp: number): number {
  let level = 1;
  for (const threshold of LEVEL_THRESHOLDS) {
    if (totalExp >= threshold.cumulative_exp) {
      level = threshold.level;
    } else {
      break;
    }
  }
  return level;
}

/**
 * Initial today state factory
 */
function createInitialTodayState(userId: string, localDate: string, dailyNewTarget: number = 20): TodayState {
  return {
    user_id: userId,
    local_date: localDate,
    current_book_name: DEV_BOOK_NAME,
    today_new_target: dailyNewTarget,
    today_new_completed: 0,
    today_review_target: 0,
    today_review_pending: 0,
    today_review_completed: 0,
    daily_goal_status: 'not_started',
    active_review_group_id: null,
    active_review_group_status: null,
    active_review_group_remaining: 0,
    sync_status: 'healthy',
    last_reward_settlement: null,
    // Phase 3 defaults
    has_checked_in_today: false,
    learning_day_today: false,
    current_streak: 0,
    streak_basis_type: 'check_in' as const,
    session_started_today: false,
    session_valid_today: false,
    user_local_date: localDate,
    user_timezone: 'UTC',
  };
}

import { IDevStorePersistence, DevStorePersistence, DevStoreSnapshot } from './persistence';
import { createPersistence } from './persistence-factory';

/**
 * In-memory store class with pluggable persistence (A4 cutover).
 *
 * State is held in memory for fast access. Writes trigger a save
 * to the active persistence backend (PostgreSQL by default, JSON fallback).
 */
export class DevStore {
  // Single user for Phase 1 development
  private readonly userId = DEV_USER_ID;

  // Persistence adapter (PG or JSON, determined by factory)
  private persistence: IDevStorePersistence;

  // State storage
  private todayStates: Map<string, TodayState> = new Map();
  private studyAttempts: StudyAttempt[] = [];
  private reviewGroups: ReviewGroup[] = [];
  private reviewAttempts: ReviewAttempt[] = [];
  private idempotencyKeys: Map<string, IdempotencyKeyRecord> = new Map();
  
  // Phase 2: Reward settlement storage
  private sourceEvents: RewardSourceEvent[] = [];
  private rewardLedgerItems: RewardLedgerItem[] = [];
  private settlements: Settlement[] = [];
  
  // Phase 3: Session / Check-in / Streak storage
  private sessions: Session[] = [];
  private checkIns: CheckInRecord[] = [];
  private streakRecord: StreakRecord | null = null;
  private learningDays: LearningDayRecord[] = [];

  // Phase 2A: Feed storage
  private feedRecords: FeedRecord[] = [];
  // Accumulated mood/exp deltas from feeding (separate from reward-derived values)
  private feedMoodAccumulated = 0;
  private feedExpAccumulated = 0;
  private feedBondAccumulated = 0;

  // Assumption (temporary, not frozen):
  // Minimal dev-only cat profile defaults for P2 bridge layer.
  private readonly catProfile = {
    nickname: DEV_CAT_NICKNAME,
    baseMood: 60,
    baseBond: 0,
  };

  // Phase 2D: Inventory
  private ownedItems: OwnedItem[] = [];
  private coinsSpent = 0;

  // Phase 3: Equipped state — slot -> item_id
  private equippedOutfit: Record<string, string | null> = {};
  private equippedRoom: Record<string, string | null> = {};

  constructor(persistenceOverride?: IDevStorePersistence | string) {
    if (typeof persistenceOverride === 'string') {
      // Direct file path — use JSON persistence (for tests)
      this.persistence = new DevStorePersistence(persistenceOverride);
    } else if (persistenceOverride) {
      // Explicit adapter injection (for tests)
      this.persistence = persistenceOverride;
    } else {
      // Use factory (reads PERSISTENCE_BACKEND env)
      this.persistence = createPersistence();
    }
    this.loadFromDisk();
  }

  /**
   * Async initialization for PG backend.
   * Must be called after construction when using PG persistence.
   */
  async initAsync(): Promise<void> {
    const pg = this.persistence as any;
    if (typeof pg.loadAsync === 'function') {
      const snapshot = await pg.loadAsync();
      if (snapshot) {
        this.hydrate(snapshot);
        console.log('[DevStore] State restored from PostgreSQL.');
      }
    }
    // Load word pool from PG (or fallback)
    await this.loadWordPool();
    // Load user settings (daily new target) from PG
    await this.loadUserSettings();
  }

  /**
   * Serialize all mutable state to a snapshot for persistence.
   */
  serialize(): DevStoreSnapshot {
    const todayStatesObj: Record<string, any> = {};
    for (const [k, v] of this.todayStates.entries()) {
      todayStatesObj[k] = v;
    }
    const idempotencyKeysObj: Record<string, any> = {};
    for (const [k, v] of this.idempotencyKeys.entries()) {
      idempotencyKeysObj[k] = v;
    }
    return {
      studyAttempts: this.studyAttempts,
      reviewGroups: this.reviewGroups,
      reviewAttempts: this.reviewAttempts,
      sourceEvents: this.sourceEvents,
      rewardLedgerItems: this.rewardLedgerItems,
      settlements: this.settlements,
      sessions: this.sessions,
      checkIns: this.checkIns,
      streakRecord: this.streakRecord,
      learningDays: this.learningDays,
      todayStates: todayStatesObj,
      feedRecords: this.feedRecords,
      feedMoodAccumulated: this.feedMoodAccumulated,
      feedExpAccumulated: this.feedExpAccumulated,
      feedBondAccumulated: this.feedBondAccumulated,
      ownedItems: this.ownedItems,
      coinsSpent: this.coinsSpent,
      equippedOutfit: this.equippedOutfit,
      equippedRoom: this.equippedRoom,
      idempotencyKeys: idempotencyKeysObj,
    };
  }

  /**
   * Hydrate in-memory state from a snapshot.
   */
  hydrate(snapshot: DevStoreSnapshot): void {
    this.studyAttempts = snapshot.studyAttempts ?? [];
    this.reviewGroups = snapshot.reviewGroups ?? [];
    this.reviewAttempts = snapshot.reviewAttempts ?? [];
    this.sourceEvents = snapshot.sourceEvents ?? [];
    this.rewardLedgerItems = snapshot.rewardLedgerItems ?? [];
    this.settlements = snapshot.settlements ?? [];
    this.sessions = snapshot.sessions ?? [];
    this.checkIns = snapshot.checkIns ?? [];
    this.streakRecord = snapshot.streakRecord ?? null;
    this.learningDays = snapshot.learningDays ?? [];
    this.feedRecords = snapshot.feedRecords ?? [];
    this.feedMoodAccumulated = snapshot.feedMoodAccumulated ?? 0;
    this.feedExpAccumulated = snapshot.feedExpAccumulated ?? 0;
    this.feedBondAccumulated = snapshot.feedBondAccumulated ?? 0;
    this.ownedItems = snapshot.ownedItems ?? [];
    this.coinsSpent = snapshot.coinsSpent ?? 0;
    this.equippedOutfit = snapshot.equippedOutfit ?? {};
    this.equippedRoom = snapshot.equippedRoom ?? {};

    // Restore Maps
    this.todayStates.clear();
    if (snapshot.todayStates) {
      for (const [k, v] of Object.entries(snapshot.todayStates)) {
        this.todayStates.set(k, v);
      }
    }
    this.idempotencyKeys.clear();
    if (snapshot.idempotencyKeys) {
      for (const [k, v] of Object.entries(snapshot.idempotencyKeys)) {
        this.idempotencyKeys.set(k, v);
      }
    }
  }

  // Serialized save chain — only one PG save runs at a time
  private saveChain: Promise<void> = Promise.resolve();
  private saveError: Error | null = null;

  /**
   * Save current state to persistence backend.
   * For PG: queues async save in a serial chain.
   * For JSON: synchronous write.
   */
  saveToDisk(): void {
    if (this.persistence.saveAsync) {
      const snapshot = this.serialize();
      this.saveError = null;
      this.saveChain = this.saveChain
        .then(() => this.persistence.saveAsync!(snapshot))
        .catch(err => {
          this.saveError = err;
          console.error('[DevStore] PG save failed:', err?.message || err);
        });
    } else {
      this.persistence.save(this.serialize());
    }
  }

  /**
   * Await all pending saves and confirm persistence succeeded.
   * Controllers MUST await this after write operations.
   * Throws if PG save failed — caller must NOT return success.
   */
  async saveToDiskAsync(): Promise<void> {
    await this.saveChain;
    if (this.saveError) {
      const err = this.saveError;
      this.saveError = null;
      // Wrap in PersistenceFailureError for structured filter handling
      const { PersistenceFailureError } = require('../middleware/persistence-failure.filter');
      throw new PersistenceFailureError(err);
    }
  }

  /**
   * Load state from disk (called once at construction).
   */
  private loadFromDisk(): void {
    const snapshot = this.persistence.load();
    if (snapshot) {
      this.hydrate(snapshot);
      console.log('[DevStore] State restored from disk.');
    }
  }

  /**
   * Assumption (temporary, not frozen):
   * Dev catalog with minimal items for Phase 2D. Prices and level
   * requirements are minimal dev rules, not a frozen price table.
   */
  private readonly catalog: CatalogItem[] = [
    // Original 5 items (Phase 2D)
    { item_id: 'cat_hat_red', item_type: 'outfit', slot: 'head', name: '红色小帽子', coin_price: 60, required_level: 1, is_active: true },
    { item_id: 'cat_bow_blue', item_type: 'outfit', slot: 'neck', name: '蓝色蝴蝶结', coin_price: 80, required_level: 2, is_active: true },
    { item_id: 'cat_scarf_pink', item_type: 'outfit', slot: 'neck', name: '粉色围巾', coin_price: 100, required_level: 3, is_active: true },
    { item_id: 'room_lamp_warm', item_type: 'room_item', slot: 'decor', name: '暖光小台灯', coin_price: 120, required_level: 3, is_active: true },
    { item_id: 'room_rug_soft', item_type: 'room_item', slot: 'floor', name: '柔软小地毯', coin_price: 150, required_level: 4, is_active: true },
    // B2-2A: New 5 items (reusing existing item_type, slot, price, level semantics)
    { item_id: 'cat_hat_straw', item_type: 'outfit', slot: 'head', name: '草编小草帽', coin_price: 90, required_level: 2, is_active: true },
    { item_id: 'cat_bow_yellow', item_type: 'outfit', slot: 'neck', name: '向日葵领结', coin_price: 110, required_level: 3, is_active: true },
    { item_id: 'cat_scarf_stripe', item_type: 'outfit', slot: 'neck', name: '条纹暖围巾', coin_price: 130, required_level: 4, is_active: true },
    { item_id: 'room_plant_small', item_type: 'room_item', slot: 'decor', name: '小盆栽绿植', coin_price: 100, required_level: 2, is_active: true },
    { item_id: 'room_cushion_cloud', item_type: 'room_item', slot: 'floor', name: '云朵小靠垫', coin_price: 140, required_level: 3, is_active: true },
  ];

  // Word pool — loaded dynamically from PG, with fallback for JSON mode
  private wordPool: Word[] = [];

  // User daily new target — loaded from PG user_book_settings, default 20
  private userDailyNewTarget: number = 20;

  /**
   * Load word pool from PG or use minimal fallback.
   * Called during initialization. If PG has CET-4 words, use those.
   * Otherwise fall back to a minimal set for dev/test.
   */
  async loadWordPool(): Promise<void> {
    try {
      // Try loading from PG via persistence layer
      const { Pool } = require('pg');
      const pool = new Pool({
        connectionString: process.env.DATABASE_URL || 'postgresql://postgres:jason123@localhost:5432/meow_dev',
      });
      const result = await pool.query(
        'SELECT id as word_id, word_text, meaning, phonetic, book_id, translation, definition, difficulty_level, is_core, tags, frequency_rank, word_forms FROM words WHERE book_id = $1 ORDER BY sort_order ASC',
        [DEV_BOOK_ID],
      );
      await pool.end();

      if (result.rows.length > 0) {
        this.wordPool = result.rows;
        console.log(`[DevStore] Loaded ${this.wordPool.length} words from PG.`);
        return;
      }
    } catch (e) {
      // PG not available — use fallback
    }

    // Minimal fallback for JSON persistence / test mode
    this.wordPool = [
      { word_id: 'word-001', word_text: 'abandon', meaning: '放弃', phonetic: '/əˈbændən/', book_id: DEV_BOOK_ID },
      { word_id: 'word-002', word_text: 'ability', meaning: '能力', phonetic: '/əˈbɪləti/', book_id: DEV_BOOK_ID },
      { word_id: 'word-003', word_text: 'abnormal', meaning: '异常的', phonetic: '/æbˈnɔːrml/', book_id: DEV_BOOK_ID },
      { word_id: 'word-004', word_text: 'aboard', meaning: '在船上', phonetic: '/əˈbɔːrd/', book_id: DEV_BOOK_ID },
      { word_id: 'word-005', word_text: 'abrupt', meaning: '突然的', phonetic: '/əˈbrʌpt/', book_id: DEV_BOOK_ID },
    ];
    console.log(`[DevStore] Using ${this.wordPool.length} fallback words (PG not available).`);
  }

  /**
   * Load user daily new target from PG user_book_settings.
   * Falls back to 20 if PG unavailable.
   */
  async loadUserSettings(): Promise<void> {
    try {
      const { Pool } = require('pg');
      const pool = new Pool({
        connectionString: process.env.DATABASE_URL || 'postgresql://postgres:jason123@localhost:5432/meow_dev',
      });
      const result = await pool.query(
        'SELECT daily_new_target FROM user_book_settings WHERE user_id = $1 AND is_active = TRUE LIMIT 1',
        [DEV_USER_ID],
      );
      await pool.end();
      if (result.rows.length > 0) {
        this.userDailyNewTarget = result.rows[0].daily_new_target;
        console.log(`[DevStore] User daily new target: ${this.userDailyNewTarget}`);
      }
    } catch (e) {
      // PG not available — keep default 20
    }
  }

  /**
   * Update user daily new target in PG and in-memory.
   * Also updates today's state target so it takes effect immediately.
   */
  async updateDailyNewTarget(newTarget: number): Promise<void> {
    this.userDailyNewTarget = newTarget;

    // Update PG
    try {
      const { Pool } = require('pg');
      const pool = new Pool({
        connectionString: process.env.DATABASE_URL || 'postgresql://postgres:jason123@localhost:5432/meow_dev',
      });
      await pool.query(
        'UPDATE user_book_settings SET daily_new_target = $1, updated_at = NOW() WHERE user_id = $2 AND is_active = TRUE',
        [newTarget, DEV_USER_ID],
      );
      await pool.end();
    } catch (e) {
      // PG not available — in-memory update still applies
    }

    // Update today's state immediately
    const today = new Date().toISOString().split('T')[0];
    const state = this.todayStates.get(today);
    if (state) {
      state.today_new_target = newTarget;
      // Recompute daily goal status
      const newGoalMet = state.today_new_completed >= newTarget;
      const reviewGoalMet = state.today_review_completed >= state.today_review_target;
      if (newGoalMet && reviewGoalMet) {
        state.daily_goal_status = 'completed';
      } else if (newGoalMet || reviewGoalMet) {
        state.daily_goal_status = 'partially_completed';
      } else if (state.today_new_completed > 0 || state.today_review_completed > 0) {
        state.daily_goal_status = 'in_progress';
      } else {
        state.daily_goal_status = 'not_started';
      }
      this.saveToDisk();
    }
  }

  /**
   * Get or create today state
   */
  getTodayState(): TodayState {
    const today = new Date().toISOString().split('T')[0];
    let state = this.todayStates.get(today);

    if (!state) {
      // Check if there's an active review group from previous days
      const activeGroup = this.getActiveReviewGroup();
      const reviewPending = activeGroup ? activeGroup.items.filter(i => !i.completed).length : 0;

      state = createInitialTodayState(this.userId, today, this.userDailyNewTarget);

      // Recount today_new_completed from today's study_attempts ONLY
      // This prevents cross-day accumulation
      const todayNewCompleted = this.studyAttempts.filter(
        a => a.study_type === 'new' && a.action_result === 'know'
          && a.created_at.startsWith(today)
      ).length;
      state.today_new_completed = todayNewCompleted;

      // Recompute daily_goal_status based on actual counts
      if (todayNewCompleted > 0) {
        const newGoalMet = todayNewCompleted >= state.today_new_target;
        const reviewGoalMet = state.today_review_completed >= state.today_review_target;
        if (newGoalMet && reviewGoalMet) {
          state.daily_goal_status = 'completed';
        } else if (newGoalMet || reviewGoalMet) {
          state.daily_goal_status = 'partially_completed';
        } else {
          state.daily_goal_status = 'in_progress';
        }
      }

      // Assumption (temporary, not frozen):
      // Simple rule: if there's pending review, set target to 1
      if (reviewPending > 0) {
        state.today_review_target = 1;
        state.today_review_pending = reviewPending;
      }

      this.todayStates.set(today, state);
    } else {
      // Existing state for today — ensure target reflects current user setting
      state.today_new_target = this.userDailyNewTarget;
    }

    // P3 Phase 1: Compute very small CTA decision-support block.
    state.today_primary_action = this.computeTodayPrimaryAction(state);

    // P3 Phase 2: Compute very small review deeper summary.
    state.review_summary = this.computeReviewSummary(state);

    return state;
  }

  /**
   * P3 Phase 1: Compute today_primary_action (very small CTA decision-support).
   *
   * Priority (same as Option C CTA baseline but now backend-driven):
   *   1. active review_group → continue_review_group
   *   2. review pending (no active group) → go_review
   *   3. session pending (started but not valid) → go_session
   *   4. default → go_new_words
   *
   * Only `action` + `reason` — no priority_band or blocking_condition.
   */
  private computeTodayPrimaryAction(state: TodayState): TodayPrimaryAction {
    // Priority 1: active review group continuation-first
    if (state.active_review_group_id && state.active_review_group_remaining > 0) {
      return { action: 'continue_review_group', reason: 'active_review_group' };
    }

    // Priority 2: review due (no active group, but review pending)
    if (state.today_review_pending > 0) {
      return { action: 'go_review', reason: 'review_due_priority' };
    }

    // Priority 3: session pending (started but not yet valid)
    if (state.session_started_today && !state.session_valid_today) {
      return { action: 'go_session', reason: 'session_pending' };
    }

    // Priority 4: default — new words
    return { action: 'go_new_words', reason: 'new_words_remaining' };
  }

  /**
   * P3 Phase 2: Compute review deeper summary.
   *
   * All readiness/progress from backend aggregation — NOT from local remaining count.
   * active_group_completed and daily_review_progress.status are SEPARATE facts.
   */
  private computeReviewSummary(state: TodayState): ReviewSummary {
    const activeGroup = this.getActiveReviewGroup();

    const hasActiveGroup = activeGroup !== null && !activeGroup.group_completed;
    const completedItems = activeGroup
      ? activeGroup.items.filter(i => i.completed).length
      : 0;
    const totalItems = activeGroup ? activeGroup.items.length : 0;
    const groupCompleted = activeGroup ? activeGroup.group_completed : false;

    // Daily review progress — based on backend state, not local inference
    const completedUnits = state.today_review_completed;
    const requiredUnits = state.today_review_target;
    let dailyStatus: DailyReviewProgressStatus = 'not_started';
    if (completedUnits >= requiredUnits && requiredUnits > 0) {
      dailyStatus = 'completed';
    } else if (completedUnits > 0) {
      dailyStatus = 'in_progress';
    }

    // Next group readiness — backend-driven, conservative
    // Only "ready" when: no active group AND daily review not yet completed AND required > completed
    let readiness: NextGroupReadiness = 'not_ready';
    if (!hasActiveGroup && !groupCompleted && dailyStatus !== 'completed' && requiredUnits > completedUnits) {
      readiness = 'ready';
    }

    return {
      has_active_group: hasActiveGroup,
      active_group_progress: {
        completed_items: completedItems,
        total_items: totalItems > 0 ? totalItems : 0,
      },
      active_group_completed: groupCompleted,
      daily_review_progress: {
        completed_units: completedUnits,
        required_units: requiredUnits,
        status: dailyStatus,
      },
      next_group_readiness: readiness,
    };
  }

  /**
   * Update today state
   */
  updateTodayState(updates: Partial<TodayState>): TodayState {
    const state = this.getTodayState();
    const updated = { ...state, ...updates };
    this.todayStates.set(state.local_date, updated);
    return updated;
  }

  /**
   * Get next new word
   */
  /**
   * Get all words for a book (for batch download to client cache).
   * Supports offset/limit pagination.
   */
  getWordsByBook(bookId: string, offset: number = 0, limit: number = 500): { words: Word[], total: number } {
    const allWords = this.wordPool.filter(w => w.book_id === bookId);
    const words = allWords.slice(offset, offset + limit);
    return { words, total: allWords.length };
  }

  getNextNewWord(): Word | null {
    // Check daily limit: if today's target is reached, stop serving new words
    const state = this.getTodayState();
    if (state.today_new_completed >= state.today_new_target && state.today_new_target > 0) {
      return null; // Daily target reached
    }

    // Find words already mastered (action_result === 'know').
    // Words marked 'forgot' should REAPPEAR so the user can study them again.
    const masteredWordIds = new Set(
      this.studyAttempts
        .filter(a => a.study_type === 'new' && a.action_result === 'know')
        .map(a => a.word_id)
    );

    // Get unmastered words from pool (all words are candidates with real data)
    const newWords = this.wordPool.filter(
      w => !masteredWordIds.has(w.word_id)
    );

    if (newWords.length === 0) {
      return null;
    }

    // Return first available (simple round-robin for Phase 1)
    return newWords[0];
  }

  /**
   * Submit study attempt
   * 
   * Returns: { success: boolean, alreadyExists: boolean }
   */
  submitStudyAttempt(
    wordId: string,
    bookId: string,
    studyType: 'new',
    actionResult: 'know' | 'forgot',
    idempotencyKey: string
  ): { success: boolean; alreadyExists: boolean; attempt: StudyAttempt } {
    // Check idempotency key first
    if (idempotencyKey) {
      const existingRecord = this.getIdempotencyKey(idempotencyKey);
      if (existingRecord) {
        // Return alreadyExists=true for idempotent replay
        return { 
          success: true, 
          alreadyExists: true, 
          attempt: { 
            id: '', 
            user_id: this.userId, 
            word_id: wordId, 
            book_id: bookId, 
            study_type: studyType, 
            action_result: actionResult, 
            created_at: '' 
          } 
        };
      }
    }

    // Check if already submitted this word with the SAME action result.
    // If user previously answered 'forgot' and now answers 'know', allow the update.
    const existingAttempt = this.studyAttempts.find(
      a => a.word_id === wordId && a.study_type === studyType
    );

    if (existingAttempt) {
      // If same action result, it's a true duplicate — skip
      if (existingAttempt.action_result === actionResult) {
        return { success: true, alreadyExists: true, attempt: existingAttempt };
      }
      // Different action result (e.g., forgot→know): update the existing attempt
      existingAttempt.action_result = actionResult;
      existingAttempt.created_at = new Date().toISOString();

      // If upgrading from forgot to know, count as newly completed
      if (studyType === 'new' && actionResult === 'know') {
        const state = this.getTodayState();
        const newCompleted = state.today_new_completed + 1;
        let dailyGoalStatus: DailyGoalStatus = 'in_progress';
        const newGoalMet = newCompleted >= state.today_new_target;
        const reviewGoalMet = state.today_review_completed >= state.today_review_target;
        if (newGoalMet && reviewGoalMet) {
          dailyGoalStatus = 'completed';
        } else if (newGoalMet || reviewGoalMet) {
          dailyGoalStatus = 'partially_completed';
        }
        this.updateTodayState({
          today_new_completed: newCompleted,
          daily_goal_status: dailyGoalStatus,
        });
      }

      this.saveToDisk();
      return { success: true, alreadyExists: false, attempt: existingAttempt };
    }

    const attempt: StudyAttempt = {
      id: `sa-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      user_id: this.userId,
      word_id: wordId,
      book_id: bookId,
      study_type: studyType,
      action_result: actionResult,
      created_at: new Date().toISOString(),
    };

    this.studyAttempts.push(attempt);

    // Update today state
    const state = this.getTodayState();
    if (studyType === 'new' && actionResult === 'know') {
      const newCompleted = state.today_new_completed + 1;
      let dailyGoalStatus: DailyGoalStatus = 'in_progress';

      // Check if both new and review goals are met
      const newGoalMet = newCompleted >= state.today_new_target;
      const reviewGoalMet = state.today_review_completed >= state.today_review_target;

      // Phase 5 closeout: Support partially_completed state
      if (newGoalMet && reviewGoalMet) {
        dailyGoalStatus = 'completed';
      } else if (newGoalMet || reviewGoalMet) {
        // One goal met but not both
        dailyGoalStatus = 'partially_completed';
      }

      this.updateTodayState({
        today_new_completed: newCompleted,
        daily_goal_status: dailyGoalStatus,
      });
    }

    this.saveToDisk();
    return { success: true, alreadyExists: false, attempt };
  }

  /**
   * Get active review group
   */
  getActiveReviewGroup(): ReviewGroup | null {
    return this.reviewGroups.find(g => g.group_status === 'active') || null;
  }

  /**
   * Get or create review group
   * 
   * Frozen rules:
   * - Only one active group per user at a time
   * - Backend generates and holds
   */
  getOrCreateReviewGroup(): ReviewGroup {
    // Check for existing active group
    const existing = this.getActiveReviewGroup();
    if (existing) {
      return existing;
    }

    // Create new review group
    // Assumption (temporary, not frozen):
    // Group size is temporarily fixed at 3 for Phase 1 development
    const groupSize = 3;
    const reviewWords = this.wordPool.filter(w => w.word_id.startsWith('word-r-'));
    const selectedWords = reviewWords.slice(0, groupSize);

    const group: ReviewGroup = {
      review_group_id: `rg-${Date.now()}`,
      user_id: this.userId,
      group_status: 'active',
      group_completed: false,
      items: selectedWords.map(w => ({
        word_id: w.word_id,
        word_text: w.word_text,
        meaning: w.meaning,
        completed: false,
      })),
      created_at: new Date().toISOString(),
    };

    this.reviewGroups.push(group);

    // Update today state with review target
    this.updateTodayState({
      active_review_group_id: group.review_group_id,
      active_review_group_status: 'active',
      active_review_group_remaining: group.items.length,
      today_review_target: 1,
      today_review_pending: group.items.length,
    });

    return group;
  }

  /**
   * Submit review attempt
   *
   * Returns: { success: boolean; groupCompleted: boolean; alreadyExists: boolean }
   */
  submitReviewAttempt(
    reviewGroupId: string,
    wordId: string,
    actionResult: 'correct' | 'incorrect',
    idempotencyKey: string
  ): { success: boolean; groupCompleted: boolean; alreadyExists: boolean } {
    const group = this.reviewGroups.find(g => g.review_group_id === reviewGroupId);
    if (!group) {
      return { success: false, groupCompleted: false, alreadyExists: false };
    }

    if (group.group_status === 'completed') {
      // Group already completed, reject duplicate
      return { success: false, groupCompleted: true, alreadyExists: true };
    }

    // Check if this word in group is already completed
    const item = group.items.find(i => i.word_id === wordId);
    if (!item) {
      return { success: false, groupCompleted: false, alreadyExists: false };
    }

    // Check idempotency key first
    if (idempotencyKey) {
      const existingRecord = this.getIdempotencyKey(idempotencyKey);
      if (existingRecord) {
        // Return alreadyExists=true for idempotent replay
        return { success: true, groupCompleted: group.group_completed, alreadyExists: true };
      }
    }

    if (item.completed) {
      // Already completed with this idempotency key context
      return { success: true, groupCompleted: group.group_completed, alreadyExists: true };
    }

    // Record attempt
    const attempt: ReviewAttempt = {
      id: `ra-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      user_id: this.userId,
      review_group_id: reviewGroupId,
      word_id: wordId,
      action_result: actionResult,
      created_at: new Date().toISOString(),
    };
    this.reviewAttempts.push(attempt);

    // Mark item as completed
    item.completed = true;

    // Check if group is completed
    const allCompleted = group.items.every(i => i.completed);
    if (allCompleted) {
      group.group_status = 'completed';
      group.group_completed = true;
      group.completed_at = new Date().toISOString();

      // Update today state
      const state = this.getTodayState();
      const reviewCompleted = state.today_review_completed + 1;

      // Frozen rule: group completion != today completion
      // Only update review progress, don't auto-complete daily goal
      let dailyGoalStatus: DailyGoalStatus = state.daily_goal_status;
      const newGoalMet = state.today_new_completed >= state.today_new_target;
      const reviewGoalMet = reviewCompleted >= state.today_review_target;

      // Phase 5 closeout: Support partially_completed state
      if (newGoalMet && reviewGoalMet) {
        dailyGoalStatus = 'completed';
      } else if (newGoalMet || reviewGoalMet) {
        // One goal met but not both
        dailyGoalStatus = 'partially_completed';
      }

      this.updateTodayState({
        active_review_group_status: 'completed',
        active_review_group_remaining: 0,
        today_review_completed: reviewCompleted,
        today_review_pending: 0,
        daily_goal_status: dailyGoalStatus,
      });

      this.saveToDisk();
      return { success: true, groupCompleted: true, alreadyExists: false };
    }

    // Update remaining count
    const remaining = group.items.filter(i => !i.completed).length;
    this.updateTodayState({
      active_review_group_remaining: remaining,
      today_review_pending: remaining,
    });

    this.saveToDisk();
    return { success: true, groupCompleted: false, alreadyExists: false };
  }

  /**
   * Idempotency key management
   */
  getIdempotencyKey(key: string): IdempotencyKeyRecord | null {
    return this.idempotencyKeys.get(key) || null;
  }

  setIdempotencyKey(
    key: string,
    path: string,
    response: Record<string, unknown>
  ): void {
    const record: IdempotencyKeyRecord = {
      key,
      user_id: this.userId,
      path,
      response,
      created_at: new Date().toISOString(),
    };
    this.idempotencyKeys.set(key, record);
    this.saveToDisk();
  }

  /**
   * Get store for testing
   */
  getStudyAttempts(): StudyAttempt[] {
    return [...this.studyAttempts];
  }

  getReviewGroups(): ReviewGroup[] {
    return [...this.reviewGroups];
  }

  getReviewAttempts(): ReviewAttempt[] {
    return [...this.reviewAttempts];
  }

  getSourceEvents(): RewardSourceEvent[] {
    return [...this.sourceEvents];
  }

  getSettlements(): Settlement[] {
    return [...this.settlements];
  }

  getRewardLedgerItems(): RewardLedgerItem[] {
    return [...this.rewardLedgerItems];
  }

  /**
   * Reset store (for testing).
   * Clears both in-memory state and persisted file.
   */
  reset(): void {
    this.todayStates.clear();
    this.studyAttempts = [];
    this.reviewGroups = [];
    this.reviewAttempts = [];
    this.idempotencyKeys.clear();
    this.sourceEvents = [];
    this.rewardLedgerItems = [];
    this.settlements = [];
    // Phase 3
    this.sessions = [];
    this.checkIns = [];
    this.streakRecord = null;
    this.learningDays = [];
    // Phase 2A
    this.feedRecords = [];
    this.feedMoodAccumulated = 0;
    this.feedExpAccumulated = 0;
    this.feedBondAccumulated = 0;
    // Phase 2D
    this.ownedItems = [];
    this.coinsSpent = 0;
    // Phase 3
    this.equippedOutfit = {};
    this.equippedRoom = {};
    // Phase 4: clear persistence
    this.persistence.clear();
  }

  // ========== Phase 2: Settlement Methods ==========

  /**
   * Create or get source event
   * 
   * Frozen rules:
   * - Same source_ref_id should not create duplicate source events
   * - Idempotency key prevents duplicate creation
   */
  createOrGetSourceEvent(
    sourceEventType: SourceEventType,
    sourceRefId: string,
    idempotencyKey: string
  ): { sourceEvent: RewardSourceEvent; alreadyExists: boolean } {
    // Check idempotency first
    const existingRecord = this.getIdempotencyKey(idempotencyKey);
    if (existingRecord) {
      // Find the source event from the cached response
      const sourceEventId = (existingRecord.response as any).source_event_id;
      const existingEvent = this.sourceEvents.find(e => e.source_event_id === sourceEventId);
      if (existingEvent) {
        return { sourceEvent: existingEvent, alreadyExists: true };
      }
    }

    // Check if source event already exists for this ref
    const existingSourceEvent = this.sourceEvents.find(
      e => e.source_event_type === sourceEventType && e.source_ref_id === sourceRefId
    );
    if (existingSourceEvent) {
      return { sourceEvent: existingSourceEvent, alreadyExists: true };
    }

    // Create new source event
    const sourceEvent: RewardSourceEvent = {
      source_event_id: `se-${Date.now()}`,
      user_id: this.userId,
      source_event_type: sourceEventType,
      source_ref_id: sourceRefId,
      created_at: new Date().toISOString(),
    };

    this.sourceEvents.push(sourceEvent);
    return { sourceEvent, alreadyExists: false };
  }

  /**
   * Create settlement with reward ledger items
   * 
   * Assumption (temporary, not frozen):
   * - MVP reward amounts are placeholder values
   * - Settlement is synchronous in dev mode
   */
  createSettlement(
    sourceEventId: string,
    idempotencyKey: string
  ): { settlement: Settlement; alreadyExists: boolean } {
    // Check idempotency
    const existingRecord = this.getIdempotencyKey(idempotencyKey);
    if (existingRecord) {
      const settlementId = (existingRecord.response as any).settlement_id;
      const existingSettlement = this.settlements.find(s => s.settlement_id === settlementId);
      if (existingSettlement) {
        return { settlement: existingSettlement, alreadyExists: true };
      }
    }

    // Check if settlement already exists for this source event
    const existingSettlement = this.settlements.find(s => s.source_event_id === sourceEventId);
    if (existingSettlement) {
      return { settlement: existingSettlement, alreadyExists: true };
    }

    // Find source event
    const sourceEvent = this.sourceEvents.find(e => e.source_event_id === sourceEventId);
    if (!sourceEvent) {
      throw new Error(`Source event not found: ${sourceEventId}`);
    }

    // Create reward ledger items based on source event type
    // Assumption (temporary, not frozen): MVP placeholder reward amounts
    const rewardItems: RewardLedgerItem[] = [];
    const baseRewardItemId = `ri-${Date.now()}`;

    if (sourceEvent.source_event_type === 'effective_new_word') {
      // Placeholder: 2 coins per effective new word
      rewardItems.push({
        reward_item_id: `${baseRewardItemId}-coins`,
        source_event_id: sourceEventId,
        user_id: this.userId,
        reward_type: 'coins',
        amount: 2,
        reward_status: 'succeeded',
        created_at: new Date().toISOString(),
      });
      // Placeholder: 1 exp per effective new word
      rewardItems.push({
        reward_item_id: `${baseRewardItemId}-exp`,
        source_event_id: sourceEventId,
        user_id: this.userId,
        reward_type: 'exp',
        amount: 1,
        reward_status: 'succeeded',
        created_at: new Date().toISOString(),
      });
    } else if (sourceEvent.source_event_type === 'review_group_completed') {
      // Placeholder: 5 coins for completing a review group
      rewardItems.push({
        reward_item_id: `${baseRewardItemId}-coins`,
        source_event_id: sourceEventId,
        user_id: this.userId,
        reward_type: 'coins',
        amount: 5,
        reward_status: 'succeeded',
        created_at: new Date().toISOString(),
      });
      // Placeholder: 1 fish treat for completing a review group
      rewardItems.push({
        reward_item_id: `${baseRewardItemId}-fish`,
        source_event_id: sourceEventId,
        user_id: this.userId,
        reward_type: 'fish_treats',
        amount: 1,
        reward_status: 'succeeded',
        created_at: new Date().toISOString(),
      });
    }

    this.rewardLedgerItems.push(...rewardItems);

    // Create settlement record
    const settlement: Settlement = {
      settlement_id: `st-${Date.now()}`,
      source_event_id: sourceEventId,
      user_id: this.userId,
      reward_settlement_status: 'succeeded',
      reward_items: rewardItems,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    this.settlements.push(settlement);

    // Update today state with last reward settlement
    const todayState = this.getTodayState();
    this.updateTodayState({
      last_reward_settlement: {
        source_event_id: settlement.source_event_id,
        reward_settlement_status: settlement.reward_settlement_status,
      },
    });

    this.saveToDisk();
    return { settlement, alreadyExists: false };
  }

  /**
   * Get settlement by source event ID
   */
  getSettlementBySourceEventId(sourceEventId: string): Settlement | null {
    return this.settlements.find(s => s.source_event_id === sourceEventId) || null;
  }

  /**
   * Get settlement by settlement ID
   */
  getSettlement(settlementId: string): Settlement | null {
    return this.settlements.find(s => s.settlement_id === settlementId) || null;
  }

  getBalanceSnapshot(): BalanceSnapshot {
    const snapshot: BalanceSnapshot = {
      coins: 0,
      fish_treats: 0,
      exp: 0,
    };

    for (const item of this.rewardLedgerItems) {
      if (item.reward_status !== 'succeeded') {
        continue;
      }

      snapshot[item.reward_type] += item.amount;
    }

    // Phase 2A: Subtract fish_treats consumed by feeding
    const totalFishTreatsConsumed = this.feedRecords.reduce(
      (sum, r) => sum + r.consumed_amount, 0
    );
    snapshot.fish_treats = Math.max(0, snapshot.fish_treats - totalFishTreatsConsumed);

    // Phase 2D: Subtract coins spent on purchases
    snapshot.coins = Math.max(0, snapshot.coins - this.coinsSpent);

    return snapshot;
  }

  /**
   * Get total accumulated EXP (reward ledger + feed).
   * This is the single source of truth for EXP used by level computation.
   */
  getTotalExp(): number {
    const balances = this.getBalanceSnapshot();
    return balances.exp + this.feedExpAccumulated;
  }

  getCatSummary(): CatSummary {
    const balances = this.getBalanceSnapshot();
    const totalExp = this.getTotalExp();

    // Phase 2B: level derives from total EXP using threshold table
    const level = computeLevelFromExp(totalExp);

    // Phase 2A: mood includes feed-accumulated delta, capped at 100
    const mood = Math.min(100, this.catProfile.baseMood + balances.fish_treats * 5 + this.feedMoodAccumulated);
    // bond uses total exp + feed bond delta
    const bond = balances.exp + this.feedBondAccumulated;

    let energy: CatSummary['energy'] = 'medium';
    if (totalExp >= 20) {
      energy = 'high';
    } else if (totalExp === 0) {
      energy = 'medium';
    }

    return {
      nickname: this.catProfile.nickname,
      level,
      mood,
      bond,
      energy,
    };
  }

  // ========== Phase 2C: Companion Response ==========

  /**
   * Generate companion response based on current factual state.
   *
   * Assumption (temporary, not frozen):
   * - companion response strings and trigger rules in Phase 2C are minimal
   *   development copy rules based on current factual states, not a frozen
   *   narrative/copy system.
   */
  getCompanionResponse(): CompanionResponse {
    const todayState = this.getTodayState();
    const today = new Date().toISOString().split('T')[0];
    const checkIn = this.getCheckInForDate(today);
    const hasCheckedIn = checkIn !== null;

    // Update learning day to get fresh state
    this.updateLearningDay(today);
    const learningDayToday = todayState.learning_day_today;
    const dailyGoalStatus = todayState.daily_goal_status;
    const sessionValidToday = todayState.session_valid_today;
    const streak = this.getOrCreateStreak();

    // --- Copy pools (B2-1A expansion) ---
    const pick = (arr: string[]) => arr[Math.floor(Math.random() * arr.length)];

    // --- daily_greeting ---
    const GREETING_LEARNED = [
      '今天见到你真开心~',
      '又来学习啦，真棒~',
      '今天也在一起努力呢~',
      '学了新东西，我也跟着进步了~',
      '辛苦啦，你今天很认真呢~',
      '每次看到你学习的样子，我都好开心~',
      '又多认识了几个新朋友（单词）~',
    ];
    const GREETING_CHECKED_IN = [
      '签到收到啦，今天要不要再学一点？',
      '签到成功~ 今天也是元气满满的一天！',
      '早呀，今天也来陪陪我吧~',
      '打卡打卡~ 你来了我就放心了~',
      '今天的你，也准时出现了呢~',
    ];
    const GREETING_DEFAULT = [
      '今天也来陪陪我吧~',
      '好久不见~ 我等你好久了',
      '新的一天，一起加油吧~',
      '打开就看到你，好开心~',
      '嘿，你来了~ 今天想做点什么？',
      '窝了一天了，终于等到你~',
      '欢迎回来~ 我一直在这里等你哦',
    ];

    let dailyGreeting: string;
    if (learningDayToday) {
      dailyGreeting = pick(GREETING_LEARNED);
    } else if (hasCheckedIn) {
      dailyGreeting = pick(GREETING_CHECKED_IN);
    } else {
      dailyGreeting = pick(GREETING_DEFAULT);
    }

    // --- post_learning_response ---
    const POST_SESSION_VALID = [
      '刚刚那段专注时间很棒~',
      '专心学习的你最帅了~',
      '一段认真的时光，我都看到了~',
      '这段时间好充实呀~',
      '你刚刚特别专注，我都不敢打扰~',
    ];
    const POST_COMPLETED = [
      '今天的任务完成啦，我为你骄傲~',
      '全部搞定！你太厉害了~',
      '今天圆满完成~ 好棒好棒！',
      '所有目标都达成了，今天满分！',
      '完美收工~ 你是我最棒的学习搭档！',
    ];
    const POST_IN_PROGRESS = [
      '已经做得不错了，再来一点点吧~',
      '进度在推进呢，继续加油~',
      '一步步来就好，不着急~',
      '你已经开始了，这就是最大的进步~',
      '慢慢来也没关系，我陪着你~',
    ];

    let postLearningResponse: string | null = null;
    if (sessionValidToday) {
      postLearningResponse = pick(POST_SESSION_VALID);
    } else if (learningDayToday && dailyGoalStatus === 'completed') {
      postLearningResponse = pick(POST_COMPLETED);
    } else if (learningDayToday && (dailyGoalStatus === 'partially_completed' || dailyGoalStatus === 'in_progress')) {
      postLearningResponse = pick(POST_IN_PROGRESS);
    }

    // --- streak_node_response ---
    const STREAK_NODES = [3, 5, 7, 10, 14, 21, 30, 50];
    const STREAK_NODE_COPY: Record<number, string[]> = {
      3: ['连续 3 天了，小小的坚持也很了不起~', '三天打卡成功！继续保持呀~', '第三天！我们的故事开始了~'],
      5: ['五天了！养成习惯的第一步~', '连续五天，你比想象中更厉害~'],
      7: ['一周啦！你和我都在进步~', '整整七天！你的坚持我都记住了~', '一周打卡！这份毅力值得骄傲~'],
      10: ['十天了！两位数的坚持！', '连续十天，已经很了不起了~'],
      14: ['两周不间断，我越来越喜欢你了~', '14 天了！你是我见过最棒的学习伙伴~'],
      21: ['三周了！一起走过的日子越来越多~', '21 天的坚持，已经是了不起的习惯了~'],
      30: ['30 天！你是最棒的伙伴~', '一整个月！我们的故事还在继续~', '月度冠军！这份坚持太珍贵了~'],
      50: ['50 天！半百的坚持，我感动了~', '连续五十天！你已经是传说了~'],
    };
    let streakNodeResponse: string | null = null;
    if (STREAK_NODES.includes(streak.current_streak)) {
      const candidates = STREAK_NODE_COPY[streak.current_streak];
      if (candidates) {
        streakNodeResponse = pick(candidates);
      }
    }

    return {
      daily_greeting: dailyGreeting,
      post_learning_response: postLearningResponse,
      streak_node_response: streakNodeResponse,
    };
  }

  getSecondarySummary(): SecondarySummary {
    const balances = this.getBalanceSnapshot();
    return {
      ...balances,
      // Phase 2A: total exp includes feed-accumulated exp
      exp: balances.exp + this.feedExpAccumulated,
      cat_summary: this.getCatSummary(),
      companion_response: this.getCompanionResponse(),
      equipped_preview: this.getEquippedPreview(),
      change_highlights: this.buildChangeHighlights(),
      stats_summary: this.buildStatsSummary(),
    };
  }

  /**
   * Build stats_summary — minimal statistics summary (C3).
   *
   * This is a read-only summary, NOT a full statistics product.
   * - total_learning_days is based on learning_day records ONLY (not check_in or streak).
   * - total_check_ins is separate and independent.
   * - streak is reported as-is with its current basis (check_in).
   */
  private buildStatsSummary(): StatsSummary {
    const streak = this.getOrCreateStreak();

    return {
      // C3: learning_day count — ONLY days where learning_day=true
      total_learning_days: this.learningDays.filter(d => d.learning_day).length,
      // Total words where user answered "know" on new words
      total_words_learned: this.studyAttempts.filter(
        a => a.study_type === 'new' && a.action_result === 'know'
      ).length,
      // Total completed review groups
      total_review_groups_completed: this.reviewGroups.filter(g => g.group_completed).length,
      // Total check-ins (independent from learning_days)
      total_check_ins: this.checkIns.length,
      // Current streak as-is
      current_streak: streak.current_streak,
      streak_basis: streak.streak_basis_type,
    };
  }

  /**
   * Build change_highlights[] — read-only summary/hint layer (B23-A).
   *
   * This is NOT a new truth layer. It is a convenience summary derived
   * entirely from existing confirmed truth (ownership, equipment, growth,
   * streak, post-learning). UI must not use these labels to override
   * the real truth layers.
   */
  private buildChangeHighlights(): ChangeHighlight[] {
    const today = new Date().toISOString().slice(0, 10);
    const highlights: ChangeHighlight[] = [];

    // 1. Growth — level derived from existing EXP truth
    const catSummary = this.getCatSummary();
    if (catSummary.level >= 2) {
      highlights.push({
        kind: 'growth',
        status: 'confirmed',
        label: `已达到 Lv.${catSummary.level}`,
        related_item_code: null,
      });
    }

    // 2. Streak — from existing streak truth
    if (this.streakRecord && this.streakRecord.current_streak >= 2) {
      highlights.push({
        kind: 'streak',
        status: 'confirmed',
        label: `连续学习 ${this.streakRecord.current_streak} 天`,
        related_item_code: null,
      });
    }

    // 3. Post-learning — from today's learning day truth
    const todayLearningDay = this.learningDays.find(l => l.local_date === today);
    if (todayLearningDay && todayLearningDay.learning_day) {
      highlights.push({
        kind: 'post_learning',
        status: 'confirmed',
        label: '今日已有效学习',
        related_item_code: null,
      });
    }

    // 4. Recent purchases — from ownership truth (today's purchases)
    const todayOwned = this.ownedItems.filter(
      item => item.owned_at && item.owned_at.startsWith(today)
    );
    for (const item of todayOwned.slice(0, 2)) {
      const catalogItem = this.catalog.find(c => c.item_id === item.item_id);
      highlights.push({
        kind: 'purchase',
        status: 'confirmed',
        label: `入手了「${catalogItem?.name ?? item.item_id}」`,
        related_item_code: item.item_id,
      });
    }

    // 5. Currently equipped — from equipment truth (show latest equip as highlight)
    const allEquipped = { ...this.equippedOutfit, ...this.equippedRoom };
    const equippedItemIds = Object.values(allEquipped).filter((v): v is string => v != null);
    if (equippedItemIds.length > 0) {
      const latestEquipped = equippedItemIds[equippedItemIds.length - 1];
      const catalogItem = this.catalog.find(c => c.item_id === latestEquipped);
      highlights.push({
        kind: 'equip',
        status: 'confirmed',
        label: `装备了「${catalogItem?.name ?? latestEquipped}」`,
        related_item_code: latestEquipped,
      });
    }

    return highlights;
  }

  /**
   * Check if review group completion source event already exists
   */
  hasReviewGroupCompletedEvent(reviewGroupId: string): boolean {
    return this.sourceEvents.some(
      e => e.source_event_type === 'review_group_completed' && e.source_ref_id === reviewGroupId
    );
  }

  // ========== Phase 3: Session / Check-in / Streak Methods ==========

  /**
   * Get active session
   */
  getActiveSession(): Session | null {
    return this.sessions.find(s => s.session_status === 'started') || null;
  }

  /**
   * Start a new session
   * 
   * Frozen rules:
   * - Only one active session per user at a time
   * - Idempotency key prevents duplicate creation
   */
  startSession(minutesTarget: number, idempotencyKey: string): { session: Session; alreadyExists: boolean } {
    // Check idempotency
    const existingRecord = this.getIdempotencyKey(idempotencyKey);
    if (existingRecord) {
      const sessionId = (existingRecord.response as any).session_id;
      const existingSession = this.sessions.find(s => s.session_id === sessionId);
      if (existingSession) {
        return { session: existingSession, alreadyExists: true };
      }
    }

    // Check for existing active session
    const existingActive = this.getActiveSession();
    if (existingActive) {
      return { session: existingActive, alreadyExists: true };
    }

    // Create new session
    const session: Session = {
      session_id: `sess-${Date.now()}`,
      user_id: this.userId,
      session_status: 'started',
      session_validation_status: 'pending',
      session_minutes_target: minutesTarget,
      started_at: new Date().toISOString(),
      effective_learning_count: 0,
      effective_review_count: 0,
    };

    this.sessions.push(session);
    this.saveToDisk();
    return { session, alreadyExists: false };
  }

  /**
   * Finish a session
   * 
   * Frozen rules:
   * - session_status = 'ended' after finish
   * - session_validation_status = 'valid' or 'invalid' based on MVP rules
   * - MVP valid criteria: >= 15 minutes AND >= 5 effective attempts total
   */
  finishSession(sessionId: string, idempotencyKey: string): { session: Session; alreadyExists: boolean } {
    // Check idempotency
    const existingRecord = this.getIdempotencyKey(idempotencyKey);
    if (existingRecord) {
      const existingSession = this.sessions.find(s => s.session_id === sessionId);
      // Phase 5 closeout: Check for any terminal state (valid/invalid)
      if (existingSession && ['valid', 'invalid'].includes(existingSession.session_status)) {
        return { session: existingSession, alreadyExists: true };
      }
    }

    const session = this.sessions.find(s => s.session_id === sessionId);
    if (!session) {
      throw new Error(`Session not found: ${sessionId}`);
    }

    // Phase 5 closeout: Check for any terminal state
    if (['valid', 'invalid'].includes(session.session_status)) {
      return { session, alreadyExists: true };
    }

    // Count effective attempts during this session
    const sessionStartTime = new Date(session.started_at).getTime();
    const now = Date.now();

    const effectiveLearningCount = this.studyAttempts.filter(
      a => a.study_type === 'new' &&
           a.action_result === 'know' &&
           new Date(a.created_at).getTime() >= sessionStartTime
    ).length;

    const effectiveReviewCount = this.reviewAttempts.filter(
      a => a.action_result === 'correct' &&
           new Date(a.created_at).getTime() >= sessionStartTime
    ).length;

    session.effective_learning_count = effectiveLearningCount;
    session.effective_review_count = effectiveReviewCount;
    session.session_status = 'ended';
    session.ended_at = new Date().toISOString();

    // Calculate actual session duration in minutes
    const actualMinutes = (now - sessionStartTime) / 1000 / 60;
    session.actual_minutes = Math.ceil(actualMinutes);

    // Phase 5 closeout: Enter validating state first, then validate
    session.session_status = 'validating';
    session.session_validation_status = 'pending';

    // MVP validation rules:
    // - At least 15 minutes
    // - At least 5 effective attempts total
    const totalEffective = effectiveLearningCount + effectiveReviewCount;
    const durationMet = actualMinutes >= 15;
    const attemptsMet = totalEffective >= 5;

    // Complete validation and transition to final state
    if (durationMet && attemptsMet) {
      session.session_status = 'valid';
      session.session_validation_status = 'valid';
    } else {
      session.session_status = 'invalid';
      session.session_validation_status = 'invalid';
    }

    // Update today state
    const todayState = this.getTodayState();
    if (session.session_validation_status === 'valid') {
      this.updateTodayState({
        session_valid_today: true,
      });
    }

    this.saveToDisk();
    return { session, alreadyExists: false };
  }

  /**
   * Get session by ID
   */
  getSession(sessionId: string): Session | null {
    return this.sessions.find(s => s.session_id === sessionId) || null;
  }

  /**
   * Check in for today
   * 
   * Frozen rules:
   * - Only one check-in per local_date
   * - check_in != learning_day
   * - streak is based on check_in in current MVP
   */
  checkIn(idempotencyKey: string): { checkIn: CheckInRecord; streak: StreakRecord; alreadyExists: boolean } {
    const today = new Date().toISOString().split('T')[0];

    // Check idempotency
    const existingRecord = this.getIdempotencyKey(idempotencyKey);
    if (existingRecord) {
      const existingCheckIn = this.checkIns.find(c => c.local_date === today);
      if (existingCheckIn) {
        return { 
          checkIn: existingCheckIn, 
          streak: this.getOrCreateStreak(),
          alreadyExists: true 
        };
      }
    }

    // Check if already checked in today
    const existingToday = this.checkIns.find(c => c.local_date === today);
    if (existingToday) {
      return { 
        checkIn: existingToday, 
        streak: this.getOrCreateStreak(),
        alreadyExists: true 
      };
    }

    // Create check-in record
    const checkIn: CheckInRecord = {
      check_in_id: `ci-${Date.now()}`,
      user_id: this.userId,
      local_date: today,
      check_in_status: 'succeeded',
      created_at: new Date().toISOString(),
    };

    this.checkIns.push(checkIn);

    // Update streak (based on check_in)
    const streak = this.getOrCreateStreak();
    streak.current_streak += 1;
    streak.last_check_in_date = today;
    streak.updated_at = new Date().toISOString();

    // Update today state
    this.updateTodayState({
      has_checked_in_today: true,
      current_streak: streak.current_streak,
    });

    this.saveToDisk();
    return { checkIn, streak, alreadyExists: false };
  }

  /**
   * Get or create streak record
   */
  getOrCreateStreak(): StreakRecord {
    if (!this.streakRecord) {
      this.streakRecord = {
        user_id: this.userId,
        current_streak: 0,
        streak_basis_type: 'check_in',
        last_check_in_date: null,
        updated_at: new Date().toISOString(),
      };
    }
    return this.streakRecord;
  }

  /**
   * Get check-in for a specific date
   */
  getCheckInForDate(localDate: string): CheckInRecord | null {
    return this.checkIns.find(c => c.local_date === localDate) || null;
  }

  /**
   * Update learning day status
   * 
   * Assumption (temporary, not frozen): 
   * - learning_day is true when there's at least one effective study/review attempt
   * - This is MVP minimum implementation, not final business logic
   */
  updateLearningDay(localDate: string): LearningDayRecord {
    const sessionStartTime = new Date(localDate).getTime();
    
    const effectiveLearningCount = this.studyAttempts.filter(
      a => a.study_type === 'new' && 
           a.action_result === 'know' &&
           a.created_at.startsWith(localDate)
    ).length;

    const effectiveReviewCount = this.reviewAttempts.filter(
      a => a.action_result === 'correct' &&
           a.created_at.startsWith(localDate)
    ).length;

    const learningDay = effectiveLearningCount > 0 || effectiveReviewCount > 0;

    // Update or create learning day record
    let record = this.learningDays.find(l => l.local_date === localDate);
    
    if (record) {
      record.learning_day = learningDay;
      record.effective_learning_count = effectiveLearningCount;
      record.effective_review_count = effectiveReviewCount;
      record.updated_at = new Date().toISOString();
    } else {
      record = {
        user_id: this.userId,
        local_date: localDate,
        learning_day: learningDay,
        effective_learning_count: effectiveLearningCount,
        effective_review_count: effectiveReviewCount,
        updated_at: new Date().toISOString(),
      };
      this.learningDays.push(record);
    }

    // Update today state
    this.updateTodayState({
      learning_day_today: learningDay,
    });

    return record;
  }

  // ========== Phase 2A: Feed Methods ==========

  /**
   * Feed the cat.
   *
   * Assumption (temporary, not frozen):
   * - current Phase 2A feed uses +4 mood and +2 exp as a minimal development rule
   *   based on the current MVP secondary numbers draft, not as a frozen growth balance.
   * - Anti-spam: first 3 feeds per day get full benefit; 4th+ get mood +1 only, no exp.
   * - bond +1 per feed (temporary dev rule, not frozen).
   *
   * Frozen rules applied:
   * - fish_treats deduction is backend truth
   * - idempotency key prevents duplicate deduction
   * - cannot deduct below zero
   */
  feedCat(
    feedItemType: FeedItemType,
    idempotencyKey: string,
  ): {
    status: FeedResultStatus;
    feedRecord: FeedRecord | null;
    alreadyExists: boolean;
    leveledUp: boolean;
    previousLevel: number;
    currentLevel: number;
  } {
    const currentLevel = computeLevelFromExp(this.getTotalExp());

    // 1. Idempotency check
    const existingRecord = this.getIdempotencyKey(idempotencyKey);
    if (existingRecord) {
      const existingFeedId = (existingRecord.response as any).feed_id;
      const existingFeed = this.feedRecords.find(f => f.feed_id === existingFeedId);
      if (existingFeed) {
        return {
          status: 'succeeded', feedRecord: existingFeed, alreadyExists: true,
          leveledUp: false, previousLevel: currentLevel, currentLevel,
        };
      }
    }

    // 2. Check balance — must have at least 1 fish_treat
    const balances = this.getBalanceSnapshot();
    if (balances.fish_treats < 1) {
      return {
        status: 'insufficient_resource', feedRecord: null, alreadyExists: false,
        leveledUp: false, previousLevel: currentLevel, currentLevel,
      };
    }

    // Capture level before feed for level-up detection
    const levelBeforeFeed = currentLevel;

    // 3. Anti-spam: count today's feeds
    const today = new Date().toISOString().split('T')[0];
    const todayFeedCount = this.feedRecords.filter(f => f.local_date === today).length;

    // Assumption (temporary, not frozen):
    // First 3 feeds per day: full benefit. 4th+: mood +1 only, no exp, no bond.
    const FULL_BENEFIT_LIMIT = 3;
    let moodDelta: number;
    let expDelta: number;
    let bondDelta: number;

    if (todayFeedCount < FULL_BENEFIT_LIMIT) {
      moodDelta = 4;
      expDelta = 2;
      bondDelta = 1;
    } else {
      moodDelta = 1;
      expDelta = 0;
      bondDelta = 0;
    }

    // 4. Create feed record (this acts as the consumption truth)
    const feedRecord: FeedRecord = {
      feed_id: `feed-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      user_id: this.userId,
      feed_item_type: feedItemType,
      consumed_amount: 1,
      mood_delta: moodDelta,
      exp_delta: expDelta,
      bond_delta: bondDelta,
      local_date: today,
      created_at: new Date().toISOString(),
    };

    this.feedRecords.push(feedRecord);

    // 5. Accumulate pet-state deltas
    this.feedMoodAccumulated += moodDelta;
    this.feedExpAccumulated += expDelta;
    this.feedBondAccumulated += bondDelta;

    // 6. Phase 2B: Detect level-up
    const levelAfterFeed = computeLevelFromExp(this.getTotalExp());
    const leveledUp = levelAfterFeed > levelBeforeFeed;

    this.saveToDisk();
    return {
      status: 'succeeded',
      feedRecord,
      alreadyExists: false,
      leveledUp,
      previousLevel: levelBeforeFeed,
      currentLevel: levelAfterFeed,
    };
  }

  // ========== Phase 2D: Catalog / Inventory / Purchase ==========

  /**
   * Get shop catalog.
   */
  getCatalog(): CatalogItem[] {
    return this.catalog.filter(i => i.is_active);
  }

  /**
   * Get catalog item by ID.
   */
  getCatalogItem(itemId: string): CatalogItem | null {
    return this.catalog.find(i => i.item_id === itemId && i.is_active) ?? null;
  }

  /**
   * Get inventory state.
   */
  getInventory(): InventoryState {
    return {
      owned_items: [...this.ownedItems],
      coins_balance: this.getBalanceSnapshot().coins,
    };
  }

  /**
   * Check if item is already owned.
   */
  isItemOwned(itemId: string): boolean {
    return this.ownedItems.some(o => o.item_id === itemId);
  }

  /**
   * Purchase an item.
   *
   * Frozen rules applied:
   * - Coins deduction is backend truth
   * - Idempotency key prevents duplicate purchase
   * - Cannot purchase if coins insufficient
   * - Cannot purchase if level requirement not met
   * - Cannot purchase if already owned (no stacking in MVP)
   */
  purchaseItem(
    itemId: string,
    idempotencyKey: string,
  ): {
    status: PurchaseResultStatus;
    errorCode: PurchaseErrorCode | null;
    coinsSpent: number;
    alreadyExists: boolean;
  } {
    // 1. Idempotency check
    const existingRecord = this.getIdempotencyKey(idempotencyKey);
    if (existingRecord) {
      const existingItemId = (existingRecord.response as any).item_id;
      if (existingItemId === itemId) {
        return {
          status: 'succeeded',
          errorCode: null,
          coinsSpent: (existingRecord.response as any).coins_spent ?? 0,
          alreadyExists: true,
        };
      }
    }

    // 2. Find catalog item
    const catalogItem = this.getCatalogItem(itemId);
    if (!catalogItem) {
      return { status: 'failed', errorCode: 'ITEM_NOT_FOUND', coinsSpent: 0, alreadyExists: false };
    }

    // 3. Check already owned
    if (this.isItemOwned(itemId)) {
      return { status: 'failed', errorCode: 'ITEM_ALREADY_OWNED', coinsSpent: 0, alreadyExists: false };
    }

    // 4. Check level requirement
    const currentLevel = computeLevelFromExp(this.getTotalExp());
    if (currentLevel < catalogItem.required_level) {
      return { status: 'failed', errorCode: 'ITEM_LEVEL_LOCKED', coinsSpent: 0, alreadyExists: false };
    }

    // 5. Check coins balance
    const balance = this.getBalanceSnapshot();
    if (balance.coins < catalogItem.coin_price) {
      return { status: 'failed', errorCode: 'COINS_NOT_ENOUGH', coinsSpent: 0, alreadyExists: false };
    }

    // 6. Deduct coins and add to inventory
    this.coinsSpent += catalogItem.coin_price;
    const ownedItem: OwnedItem = {
      item_id: catalogItem.item_id,
      item_type: catalogItem.item_type,
      slot: catalogItem.slot,
      owned_at: new Date().toISOString(),
      equipped: false,
    };
    this.ownedItems.push(ownedItem);

    this.saveToDisk();
    return {
      status: 'succeeded',
      errorCode: null,
      coinsSpent: catalogItem.coin_price,
      alreadyExists: false,
    };
  }

  // ========== Phase 3: Equipment Methods ==========

  /**
   * Get equipped snapshot.
   */
  getEquippedSnapshot(): EquippedSnapshot {
    return {
      outfit: { ...this.equippedOutfit },
      room: { ...this.equippedRoom },
    };
  }

  /**
   * Get a flat equipped preview for secondary summary.
   * Merges outfit + room slots into a single flat map.
   */
  getEquippedPreview(): Record<string, string | null> {
    return {
      ...this.equippedOutfit,
      ...this.equippedRoom,
    };
  }

  /**
   * Equip an owned item.
   *
   * Rules:
   * - Item must be owned
   * - Item must exist in catalog
   * - Same slot: new item replaces old
   * - Idempotency: same key replay is safe
   */
  equipItem(
    itemId: string,
    idempotencyKey: string,
  ): {
    status: EquipResultStatus;
    errorCode: EquipErrorCode | null;
    slot: string | null;
    itemType: string | null;
    alreadyExists: boolean;
  } {
    // 1. Idempotency
    const existingRecord = this.getIdempotencyKey(idempotencyKey);
    if (existingRecord) {
      const existingItemId = (existingRecord.response as any).item_id;
      if (existingItemId === itemId) {
        const slot = (existingRecord.response as any).slot as string;
        const itemType = (existingRecord.response as any).item_type as string;
        return { status: 'succeeded', errorCode: null, slot, itemType, alreadyExists: true };
      }
    }

    // 2. Item must exist in catalog
    const catalogItem = this.getCatalogItem(itemId);
    if (!catalogItem) {
      return { status: 'failed', errorCode: 'ITEM_NOT_FOUND', slot: null, itemType: null, alreadyExists: false };
    }

    // 3. Item must be owned
    if (!this.isItemOwned(itemId)) {
      return { status: 'failed', errorCode: 'ITEM_NOT_OWNED', slot: null, itemType: null, alreadyExists: false };
    }

    // 4. Equip: put item in its slot, replacing previous
    const slot = catalogItem.slot;
    if (catalogItem.item_type === 'outfit') {
      this.equippedOutfit[slot] = itemId;
    } else {
      this.equippedRoom[slot] = itemId;
    }

    // 5. Update the owned item's equipped flag
    for (const ownedItem of this.ownedItems) {
      // Unequip previous item in same slot
      if (ownedItem.item_id !== itemId) {
        const ci = this.getCatalogItem(ownedItem.item_id);
        if (ci && ci.slot === slot && ci.item_type === catalogItem.item_type) {
          ownedItem.equipped = false;
        }
      }
    }
    const targetOwned = this.ownedItems.find(o => o.item_id === itemId);
    if (targetOwned) {
      targetOwned.equipped = true;
    }

    this.saveToDisk();
    return {
      status: 'succeeded',
      errorCode: null,
      slot,
      itemType: catalogItem.item_type,
      alreadyExists: false,
    };
  }

  /**
   * Unequip an item from its slot.
   */
  unequipItem(
    itemId: string,
    idempotencyKey: string,
  ): {
    status: EquipResultStatus;
    errorCode: EquipErrorCode | null;
    alreadyExists: boolean;
  } {
    const existingRecord = this.getIdempotencyKey(idempotencyKey);
    if (existingRecord) {
      return { status: 'succeeded', errorCode: null, alreadyExists: true };
    }

    const catalogItem = this.getCatalogItem(itemId);
    if (!catalogItem) {
      return { status: 'failed', errorCode: 'ITEM_NOT_FOUND', alreadyExists: false };
    }

    if (!this.isItemOwned(itemId)) {
      return { status: 'failed', errorCode: 'ITEM_NOT_OWNED', alreadyExists: false };
    }

    const slot = catalogItem.slot;
    if (catalogItem.item_type === 'outfit') {
      if (this.equippedOutfit[slot] === itemId) {
        this.equippedOutfit[slot] = null;
      }
    } else {
      if (this.equippedRoom[slot] === itemId) {
        this.equippedRoom[slot] = null;
      }
    }

    const targetOwned = this.ownedItems.find(o => o.item_id === itemId);
    if (targetOwned) {
      targetOwned.equipped = false;
    }

    this.saveToDisk();
    return { status: 'succeeded', errorCode: null, alreadyExists: false };
  }

  /**
   * Get owned items for testing
   */
  getOwnedItems(): OwnedItem[] {
    return [...this.ownedItems];
  }

  /**
   * Get feed records for testing
   */
  getFeedRecords(): FeedRecord[] {
    return [...this.feedRecords];
  }

  /**
   * Get today's feed count (for testing anti-spam)
   */
  getTodayFeedCount(): number {
    const today = new Date().toISOString().split('T')[0];
    return this.feedRecords.filter(f => f.local_date === today).length;
  }

  /**
   * Get sessions for testing
   */
  getSessions(): Session[] {
    return [...this.sessions];
  }

  /**
   * Get check-ins for testing
   */
  getCheckIns(): CheckInRecord[] {
    return [...this.checkIns];
  }

  /**
   * Get streak for testing
   */
  getStreak(): StreakRecord | null {
    return this.streakRecord;
  }
}

/**
 * Singleton instance for Phase 1 development
 */
export const devStore = new DevStore();

// Async PG initialization (non-blocking — state loads in background)
devStore.initAsync().catch(err => {
  console.warn('[DevStore] Async init failed (PG may not be available):', err?.message || err);
});

// Export for testing
export { computeLevelFromExp, LEVEL_THRESHOLDS };
