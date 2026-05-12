/**
 * Development In-Memory Store.
 *
 * 需求 23 lifecycle status (post-A4-β.9):
 * - PostgreSQL is the production runtime truth (PERSISTENCE_BACKEND=pg).
 *   This class operates as an in-memory cache backed by PG via
 *   `PgDevStorePersistence` — multi-user safe after β.3-β.5 partition.
 * - JSON-file persistence (`DevStorePersistence`) is **legacy / unit-test
 *   only**. Single-user semantics; not suitable for multi-user staging
 *   or production. plan v2 §5.1 short-term policy: prod/staging must
 *   use pg; dev local may use either.
 *
 * Why this class still exists (not @deprecated outright):
 * - Unit tests instantiate it directly with a mock persistence.
 * - PG persistence layer reuses its hydrate / serialize shape.
 * - Replacing it wholesale is a larger refactor than Phase A scope.
 *
 * Production-readiness guard: main.ts asserts NODE_ENV=production ⇒
 * AUTH_ENFORCE=true (D13). β.9 hot-fix proposal: also assert
 * NODE_ENV=production ⇒ PERSISTENCE_BACKEND=pg (deferred to Phase E1).
 */

import { NotFoundException } from '@nestjs/common';
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
  // Phase D
  DailyFishingTask,
  DailyFishingStatus,
  FishingAttempt,
  FishingRoundQuestion,
  FishingChoice,
  LotteryBox,
  LotteryDropConfig,
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
  // 需求 23 Phase A4-β.3: in-memory state is now PARTITIONED per-user via
  // *ByUser maps. The current "bound" user (`this.userId`) is still set
  // at the top of every public method via withUser; legacy method bodies
  // continue to read `this.studyAttempts`, `this.coinsSpent`, etc. — those
  // are now TypeScript getters that resolve to the current user's bucket.
  //
  // Hydrate / serialize keep flat shapes (compatible with PG schema and
  // pre-β.3 JSON snapshots).
  private userId: string = DEV_USER_ID;

  // Persistence adapter (PG or JSON, determined by factory)
  private persistence: IDevStorePersistence;

  /// 需求 23 Phase D PR-D-β: exposed read-only so BackupController can
  /// call the PG-only backup methods directly (bypassing the
  /// dev-store in-memory backup map that depends on β.5b lazy-load).
  /// Plan-023-D-v2 §4.2.
  get backingPersistence(): IDevStorePersistence {
    return this.persistence;
  }

  // ========== Per-user partitioned state ==========
  // (the public legacy fields are getters defined below)

  private studyAttemptsByUser: Map<string, StudyAttempt[]> = new Map();
  private reviewGroupsByUser: Map<string, ReviewGroup[]> = new Map();
  private reviewAttemptsByUser: Map<string, ReviewAttempt[]> = new Map();
  private todayStatesByUser: Map<string, Map<string, TodayState>> = new Map();
  private idempotencyKeysByUser: Map<string, Map<string, IdempotencyKeyRecord>> = new Map();
  private sourceEventsByUser: Map<string, RewardSourceEvent[]> = new Map();
  private rewardLedgerItemsByUser: Map<string, RewardLedgerItem[]> = new Map();
  private settlementsByUser: Map<string, Settlement[]> = new Map();
  private sessionsByUser: Map<string, Session[]> = new Map();
  private checkInsByUser: Map<string, CheckInRecord[]> = new Map();
  private streakRecordByUser: Map<string, StreakRecord> = new Map();
  private learningDaysByUser: Map<string, LearningDayRecord[]> = new Map();
  private feedRecordsByUser: Map<string, FeedRecord[]> = new Map();
  private feedMoodAccumulatedByUser: Map<string, number> = new Map();
  private feedExpAccumulatedByUser: Map<string, number> = new Map();
  private feedBondAccumulatedByUser: Map<string, number> = new Map();
  private ownedItemsByUser: Map<string, OwnedItem[]> = new Map();
  private coinsSpentByUser: Map<string, number> = new Map();
  private equippedOutfitByUser: Map<string, Record<string, string | null>> = new Map();
  private equippedRoomByUser: Map<string, Record<string, string | null>> = new Map();
  private fishingTasksByUser: Map<string, Map<string, DailyFishingTask>> = new Map();
  private fishingAttemptsByUser: Map<string, FishingAttempt[]> = new Map();
  private lotteryBoxesByUser: Map<string, LotteryBox[]> = new Map();

  // ========== Bucket helpers ==========

  private bucketArr<T>(map: Map<string, T[]>, userId: string = this.userId): T[] {
    let arr = map.get(userId);
    if (!arr) { arr = []; map.set(userId, arr); }
    return arr;
  }

  private bucketMap<K, V>(
    outer: Map<string, Map<K, V>>,
    userId: string = this.userId,
  ): Map<K, V> {
    let inner = outer.get(userId);
    if (!inner) { inner = new Map(); outer.set(userId, inner); }
    return inner;
  }

  // ========== Legacy field facades (getters/setters route to current bucket) ==========

  private get studyAttempts(): StudyAttempt[] {
    return this.bucketArr(this.studyAttemptsByUser);
  }
  private get reviewGroups(): ReviewGroup[] {
    return this.bucketArr(this.reviewGroupsByUser);
  }
  private get reviewAttempts(): ReviewAttempt[] {
    return this.bucketArr(this.reviewAttemptsByUser);
  }
  private get todayStates(): Map<string, TodayState> {
    return this.bucketMap(this.todayStatesByUser);
  }
  private get idempotencyKeys(): Map<string, IdempotencyKeyRecord> {
    return this.bucketMap(this.idempotencyKeysByUser);
  }
  private get sourceEvents(): RewardSourceEvent[] {
    return this.bucketArr(this.sourceEventsByUser);
  }
  private get rewardLedgerItems(): RewardLedgerItem[] {
    return this.bucketArr(this.rewardLedgerItemsByUser);
  }
  private get settlements(): Settlement[] {
    return this.bucketArr(this.settlementsByUser);
  }
  private get sessions(): Session[] {
    return this.bucketArr(this.sessionsByUser);
  }
  private get checkIns(): CheckInRecord[] {
    return this.bucketArr(this.checkInsByUser);
  }
  private get learningDays(): LearningDayRecord[] {
    return this.bucketArr(this.learningDaysByUser);
  }
  private get feedRecords(): FeedRecord[] {
    return this.bucketArr(this.feedRecordsByUser);
  }
  private get ownedItems(): OwnedItem[] {
    return this.bucketArr(this.ownedItemsByUser);
  }
  private get fishingTasks(): Map<string, DailyFishingTask> {
    return this.bucketMap(this.fishingTasksByUser);
  }
  private get fishingAttempts(): FishingAttempt[] {
    return this.bucketArr(this.fishingAttemptsByUser);
  }
  private get lotteryBoxes(): LotteryBox[] {
    return this.bucketArr(this.lotteryBoxesByUser);
  }

  // Single-value field facades (must support both read & write)
  private get streakRecord(): StreakRecord | null {
    return this.streakRecordByUser.get(this.userId) ?? null;
  }
  private set streakRecord(v: StreakRecord | null) {
    if (v === null) this.streakRecordByUser.delete(this.userId);
    else this.streakRecordByUser.set(this.userId, v);
  }
  private get coinsSpent(): number {
    return this.coinsSpentByUser.get(this.userId) ?? 0;
  }
  private set coinsSpent(v: number) {
    this.coinsSpentByUser.set(this.userId, v);
  }
  private get feedMoodAccumulated(): number {
    return this.feedMoodAccumulatedByUser.get(this.userId) ?? 0;
  }
  private set feedMoodAccumulated(v: number) {
    this.feedMoodAccumulatedByUser.set(this.userId, v);
  }
  private get feedExpAccumulated(): number {
    return this.feedExpAccumulatedByUser.get(this.userId) ?? 0;
  }
  private set feedExpAccumulated(v: number) {
    this.feedExpAccumulatedByUser.set(this.userId, v);
  }
  private get feedBondAccumulated(): number {
    return this.feedBondAccumulatedByUser.get(this.userId) ?? 0;
  }
  private set feedBondAccumulated(v: number) {
    this.feedBondAccumulatedByUser.set(this.userId, v);
  }
  private get equippedOutfit(): Record<string, string | null> {
    let r = this.equippedOutfitByUser.get(this.userId);
    if (!r) { r = {}; this.equippedOutfitByUser.set(this.userId, r); }
    return r;
  }
  private get equippedRoom(): Record<string, string | null> {
    let r = this.equippedRoomByUser.get(this.userId);
    if (!r) { r = {}; this.equippedRoomByUser.set(this.userId, r); }
    return r;
  }

  // β.9 hot-fix (评审采纳): user_book_settings.daily_new_target is per-user
  // (PRD §5.1 settings). Was a single field — A changing daily goal would
  // affect B. Default 20 for users without a stored setting.
  private userDailyNewTargetByUser: Map<string, number> = new Map();
  private get userDailyNewTarget(): number {
    return this.userDailyNewTargetByUser.get(this.userId) ?? 20;
  }
  private set userDailyNewTarget(v: number) {
    this.userDailyNewTargetByUser.set(this.userId, v);
  }

  // β.9 hot-fix (评审采纳): pet_profiles.nickname is per-user (PRD §5.1).
  // catProfile.nickname is the BASELINE default for new users — user-modified
  // nicknames overlay via this Map (hydrated from PG pet_profiles on demand).
  private petNicknameByUser: Map<string, string> = new Map();

  // Assumption (temporary, not frozen):
  // Minimal dev-only cat profile defaults for P2 bridge layer.
  private readonly catProfile = {
    nickname: DEV_CAT_NICKNAME,
    baseMood: 60,
    baseBond: 0,
  };

  // P3.2 — Cloud backup storage (persisted, last-write-wins, per-user).
  // 需求 23 Phase A4-β.2: per-user buckets. Methods take userId as
  // first arg directly (no withUser wrapping needed).
  private latestBackupByUser: Map<string, any> = new Map();
  private backupSnapshotByUser: Map<string, any> = new Map();

  // 需求 23 Phase A4-β.5b: lazy-load tracking for non-DEV users.
  // - loadedUsers: users whose PG slice has been hydrated into in-memory
  //   buckets. AuthGuard calls ensureUserLoaded() on every request; this
  //   set short-circuits repeat work.
  // - loadingByUser: in-flight load promises, keyed by userId. Concurrent
  //   first-requests for the same user share one PG round-trip.
  private loadedUsers: Set<string> = new Set();
  private loadingByUser: Map<string, Promise<void>> = new Map();

  // Prize pool: seeded inline — mirrors lottery_drops_config seed data
  private readonly lotteryDropsConfig: LotteryDropConfig[] = [
    { id: 1, prize_type: 'coins', prize_ref: '20',  weight: 60, is_active: true },
    { id: 2, prize_type: 'coins', prize_ref: '50',  weight: 30, is_active: true },
    { id: 3, prize_type: 'coins', prize_ref: '100', weight: 10, is_active: true },
  ];

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
   * 需求 23 Phase A4-α: bind a userId for the duration of the wrapped call.
   *
   * Every adapter method routes through this so that downstream
   * `this.userId` references inside the public method body resolve to
   * the caller-provided userId (extracted from the request token by
   * AuthGuard, or DEV_FALLBACK_USER_ID under permissive AUTH_ENFORCE=false).
   *
   * Single-threaded Node.js makes this safe under permissive mode where
   * userId is always DEV_USER_ID. Under AUTH_ENFORCE=true with concurrent
   * requests, the previous-value restoration prevents stack-style leaks
   * but in-memory state mutations from one request remain visible to
   * another. A4-β solves the latter by partitioning state per-user.
   *
   * Phase A4-β.1 hot-fix: refuse async fn so that future code adding
   * an `await` inside the wrapped block can't silently leak userId
   * across concurrent requests (the resumed continuation would see
   * `this.userId` already restored to a different caller's value).
   * Async paths must NOT use withUser — they should be either sync OR
   * post-A4-β (pass userId explicitly to per-user buckets).
   */
  withUser<T>(userId: string, fn: () => T): T {
    const prev = this.userId;
    this.userId = userId;
    try {
      const result = fn();
      if (
        result !== null &&
        typeof result === 'object' &&
        typeof (result as { then?: unknown }).then === 'function'
      ) {
        // Defensive: async fn would resume after `this.userId = prev`
        // and corrupt state. Caller must restructure to a sync path or
        // wait for A4-β to expose user-scoped methods.
        throw new Error(
          '[withUser] async fn forbidden — see plan-023-A4-beta-v1.md §β.1',
        );
      }
      return result;
    } finally {
      this.userId = prev;
    }
  }

  /**
   * Read the currently-bound user id (test/internal use only).
   */
  getCurrentUserId(): string {
    return this.userId;
  }

  /**
   * Async initialization for PG backend.
   * Must be called after construction when using PG persistence.
   */
  async initAsync(): Promise<void> {
    const pg = this.persistence as any;
    if (typeof pg.loadAsync === 'function') {
      // Startup: cold-load only DEV_USER_ID's slice. Non-dev users' slices
      // hydrate on demand via ensureUserLoaded (β.5b) when AuthGuard sees
      // the first request from each user.
      const snapshot = await pg.loadAsync(DEV_USER_ID);
      if (snapshot) {
        this.hydrate(snapshot);
        console.log('[DevStore] State restored from PostgreSQL.');
      }
    }
    // Load word pool from PG (or fallback)
    await this.loadWordPool();
    // Load user settings (daily new target) from PG for DEV_USER_ID.
    // ensureUserLoaded() hydrates other users' settings on first access.
    await this.loadUserSettings(DEV_USER_ID);
    // β.5b: DEV_USER_ID is now warmed; mark loaded so ensureUserLoaded
    // becomes a no-op for permissive mode's default user.
    this.loadedUsers.add(DEV_USER_ID);
  }

  /**
   * 需求 23 Phase A4-β.5b: lazy-load a user's PG slice into in-memory buckets.
   *
   * AuthGuard awaits this once per request — for users already in
   * `loadedUsers` it's an O(1) Set check. The first time we see a user we
   * trigger `pg.loadAsync(userId)` + `hydrateUserSlice` + `loadUserSettings`.
   *
   * Concurrent first-requests for the same user share a single load via
   * the `loadingByUser` promise cache, preventing duplicate SQL round-trips.
   *
   * Failure semantics: errors propagate to AuthGuard. Caller decides
   * whether to fail the request or fall through with an empty bucket.
   * `loadingByUser` is cleared in `finally` so a retry can re-attempt.
   *
   * No-op for JSON / unit-test persistence backends (loadAsync absent) —
   * the user just gets an empty bucket which is correct for fresh tests.
   */
  async ensureUserLoaded(userId: string): Promise<void> {
    if (this.loadedUsers.has(userId)) return;

    const inflight = this.loadingByUser.get(userId);
    if (inflight) return inflight;

    const pg = this.persistence as any;
    if (typeof pg.loadAsync !== 'function') {
      // JSON / unit-test backend — nothing to load, just remember we tried.
      this.loadedUsers.add(userId);
      return;
    }

    const promise = (async () => {
      try {
        const snapshot = await pg.loadAsync(userId);
        if (snapshot) {
          this.hydrateUserSlice(userId, snapshot);
        }
        // Also hydrate per-user settings (daily_new_target, pet nickname)
        // from their own PG tables.
        await this.loadUserSettings(userId);
        this.loadedUsers.add(userId);
      } finally {
        this.loadingByUser.delete(userId);
      }
    })();

    this.loadingByUser.set(userId, promise);
    return promise;
  }

  /**
   * Replace ONLY `userId`'s slice in every per-user bucket, leaving other
   * users' data untouched. Used by ensureUserLoaded — distinct from full
   * `hydrate()` which clears every bucket and rebuilds from a flat snapshot.
   *
   * The input snapshot is the output of `pg.loadAsync(userId)`, so every
   * collection / record describes exactly this one user.
   */
  private hydrateUserSlice(userId: string, snapshot: DevStoreSnapshot): void {
    const setArr = <T>(by: Map<string, T[]>, rows: T[] | undefined) => {
      by.set(userId, rows ? [...rows] : []);
    };
    setArr(this.studyAttemptsByUser, snapshot.studyAttempts);
    setArr(this.reviewGroupsByUser, snapshot.reviewGroups);
    setArr(this.reviewAttemptsByUser, snapshot.reviewAttempts);
    setArr(this.sourceEventsByUser, snapshot.sourceEvents);
    setArr(this.rewardLedgerItemsByUser, snapshot.rewardLedgerItems);
    setArr(this.settlementsByUser, snapshot.settlements);
    setArr(this.sessionsByUser, snapshot.sessions);
    setArr(this.checkInsByUser, snapshot.checkIns);
    setArr(this.learningDaysByUser, snapshot.learningDays);
    setArr(this.feedRecordsByUser, snapshot.feedRecords);
    setArr(this.fishingAttemptsByUser, snapshot.fishingAttempts as any);
    setArr(this.lotteryBoxesByUser, snapshot.lotteryBoxes as any);

    // Streak — pg.loadAsync returns it under `streakRecord` for this user.
    if (snapshot.streakRecord) {
      this.streakRecordByUser.set(userId, snapshot.streakRecord as StreakRecord);
    } else {
      this.streakRecordByUser.delete(userId);
    }

    // todayStates Record<date, state> — single user's daily progress.
    const todayInner = new Map<string, TodayState>();
    if (snapshot.todayStates) {
      for (const [date, v] of Object.entries(snapshot.todayStates)) {
        todayInner.set(date, v as TodayState);
      }
    }
    this.todayStatesByUser.set(userId, todayInner);

    // Idempotency keys.
    const idemInner = new Map<string, IdempotencyKeyRecord>();
    if (snapshot.idempotencyKeys) {
      for (const [k, v] of Object.entries(snapshot.idempotencyKeys)) {
        idemInner.set(k, v as IdempotencyKeyRecord);
      }
    }
    this.idempotencyKeysByUser.set(userId, idemInner);

    // β.5c: prefer per-user maps from pg-persistence; fall back to legacy
    // flat fields for DEV_USER_ID only (other users have empty defaults
    // since their data wasn't being persisted pre-β.5c).
    const owned = snapshot.ownedItemsByUser?.[userId];
    this.ownedItemsByUser.set(userId, owned ? [...(owned as OwnedItem[])] : []);

    const outfit = snapshot.equippedOutfitByUser?.[userId];
    this.equippedOutfitByUser.set(userId, outfit ? { ...outfit } : {});

    const room = snapshot.equippedRoomByUser?.[userId];
    this.equippedRoomByUser.set(userId, room ? { ...room } : {});

    const wallet = snapshot.walletByUser?.[userId];
    this.coinsSpentByUser.set(userId, wallet?.coinsSpent ?? 0);
    this.feedMoodAccumulatedByUser.set(userId, wallet?.feedMoodAccumulated ?? 0);
    this.feedExpAccumulatedByUser.set(userId, wallet?.feedExpAccumulated ?? 0);
    this.feedBondAccumulatedByUser.set(userId, wallet?.feedBondAccumulated ?? 0);

    // Backup buckets (β.2 stored in PG via separate methods, but the JSON
    // path may still carry them via snapshot — keep parity for completeness).
    const latestBackup = snapshot.latestBackupsByUser?.[userId];
    if (latestBackup) this.latestBackupByUser.set(userId, latestBackup);
    const backupSnap = snapshot.backupSnapshotsByUser?.[userId];
    if (backupSnap) this.backupSnapshotByUser.set(userId, backupSnap);
  }

  /**
   * Audit §6 owner-check helper: throw NotFoundException if `itemId` is in
   * another user's inventory bucket. Inventory items get a global catalog
   * id (e.g. `cat_hat_red`), so we can't fall back to "not in catalog" =>
   * 404 — a legitimate ID can still be cross-user-owned. β.5c/this PR
   * routes equip/unequip through this guard, complementing the β.9.3
   * source_ref_id / session_id checks.
   *
   * Unknown items (not owned by anyone) fall through silently so the
   * existing ITEM_NOT_OWNED / ITEM_NOT_FOUND error codes still surface
   * for legitimate user-facing UX (e.g. user tries to equip something
   * they never bought).
   */
  private assertInventoryItemNotCrossUser(itemId: string): void {
    for (const [uid, items] of this.ownedItemsByUser.entries()) {
      if (uid === this.userId) continue;
      if (items.some(o => o.item_id === itemId)) {
        throw new NotFoundException(`Inventory item not found: ${itemId}`);
      }
    }
  }

  /**
   * Audit §6 owner-check helper for session_id values that arrive on
   * write paths (study attempts, review attempts, local-batch reviews).
   * Reject only if the session_id is clearly owned by another user;
   * unknown / test-style ids fall through so dev workflows keep working.
   */
  private assertSessionIdNotCrossUser(sessionId: string | undefined): void {
    if (!sessionId) return;
    for (const [uid, sessions] of this.sessionsByUser.entries()) {
      if (uid === this.userId) continue;
      if (sessions.some(s => s.session_id === sessionId)) {
        throw new NotFoundException(`Session not found: ${sessionId}`);
      }
    }
  }

  /**
   * Serialize all mutable state to a snapshot for persistence.
   *
   * 需求 23 Phase A4-β.3: in-memory state is per-user. Snapshot keeps the
   * flat shape (compatible with PG schema + pre-β.3 JSON snapshots).
   * We flatten across all user buckets — each entity row has its own
   * user_id field which is the source of truth on hydrate.
   */
  serialize(): DevStoreSnapshot {
    const flat = <T>(map: Map<string, T[]>): T[] => {
      const out: T[] = [];
      for (const arr of map.values()) out.push(...arr);
      return out;
    };

    // β.3 limitation: pg-persistence still operates on single-user snapshots
    // (β.5 fixes that). For Map<key, T>-shaped fields where the key is NOT
    // the userId (e.g. local_date, idempotency key string, fishing task id),
    // dump only the DEV_USER_ID bucket — other users' Map data stays
    // in-memory until β.5 lands.
    //
    // Array fields (studyAttempts etc.) DO flatten across all users —
    // pg-persistence inserts each row using its own `user_id` column.
    const primaryForMaps = DEV_USER_ID;
    const todayStatesObj: Record<string, any> = {};
    const todayMap = this.todayStatesByUser.get(primaryForMaps);
    if (todayMap) {
      for (const [date, state] of todayMap.entries()) {
        todayStatesObj[date] = state;
      }
    }
    const idempotencyKeysObj: Record<string, any> = {};
    const idemMap = this.idempotencyKeysByUser.get(primaryForMaps);
    if (idemMap) {
      for (const [k, v] of idemMap.entries()) {
        idempotencyKeysObj[k] = v;
      }
    }
    const fishingTasksObj: Record<string, any> = {};
    const ftMap = this.fishingTasksByUser.get(primaryForMaps);
    if (ftMap) {
      for (const [tid, task] of ftMap.entries()) {
        fishingTasksObj[tid] = task;
      }
    }

    // Single-value per-user fields collapse to a primary-user view for the
    // legacy flat snapshot fields (backward compat). The new *ByUser
    // records are the truth; legacy fields kept for old hydrate paths.
    //
    // β.5c: ownedItems / equipped* / wallet now ALSO flatten across all
    // users into *ByUser records. pg-persistence saveAsync(snapshot, userId)
    // reads from the *ByUser maps for non-DEV users so their inventory /
    // equipment / wallet survives server restart.
    const primary = DEV_USER_ID;
    const equippedOutfitByUserObj: Record<string, Record<string, string | null>> = {};
    for (const [uid, slots] of this.equippedOutfitByUser.entries()) {
      equippedOutfitByUserObj[uid] = { ...slots };
    }
    const equippedRoomByUserObj: Record<string, Record<string, string | null>> = {};
    for (const [uid, slots] of this.equippedRoomByUser.entries()) {
      equippedRoomByUserObj[uid] = { ...slots };
    }
    const ownedItemsByUserObj: Record<string, OwnedItem[]> = {};
    for (const [uid, items] of this.ownedItemsByUser.entries()) {
      ownedItemsByUserObj[uid] = [...items];
    }
    const walletByUserObj: Record<string, {
      coinsSpent: number;
      feedMoodAccumulated: number;
      feedExpAccumulated: number;
      feedBondAccumulated: number;
    }> = {};
    const walletUserIds = new Set<string>([
      ...this.coinsSpentByUser.keys(),
      ...this.feedMoodAccumulatedByUser.keys(),
      ...this.feedExpAccumulatedByUser.keys(),
      ...this.feedBondAccumulatedByUser.keys(),
    ]);
    for (const uid of walletUserIds) {
      walletByUserObj[uid] = {
        coinsSpent: this.coinsSpentByUser.get(uid) ?? 0,
        feedMoodAccumulated: this.feedMoodAccumulatedByUser.get(uid) ?? 0,
        feedExpAccumulated: this.feedExpAccumulatedByUser.get(uid) ?? 0,
        feedBondAccumulated: this.feedBondAccumulatedByUser.get(uid) ?? 0,
      };
    }

    return {
      studyAttempts: flat(this.studyAttemptsByUser),
      reviewGroups: flat(this.reviewGroupsByUser),
      reviewAttempts: flat(this.reviewAttemptsByUser),
      sourceEvents: flat(this.sourceEventsByUser),
      rewardLedgerItems: flat(this.rewardLedgerItemsByUser),
      settlements: flat(this.settlementsByUser),
      sessions: flat(this.sessionsByUser),
      checkIns: flat(this.checkInsByUser),
      streakRecord: this.streakRecordByUser.get(primary) ?? null,
      learningDays: flat(this.learningDaysByUser),
      todayStates: todayStatesObj,
      feedRecords: flat(this.feedRecordsByUser),
      feedMoodAccumulated: this.feedMoodAccumulatedByUser.get(primary) ?? 0,
      feedExpAccumulated: this.feedExpAccumulatedByUser.get(primary) ?? 0,
      feedBondAccumulated: this.feedBondAccumulatedByUser.get(primary) ?? 0,
      ownedItems: flat(this.ownedItemsByUser),
      coinsSpent: this.coinsSpentByUser.get(primary) ?? 0,
      equippedOutfit: this.equippedOutfitByUser.get(primary) ?? {},
      equippedRoom: this.equippedRoomByUser.get(primary) ?? {},
      idempotencyKeys: idempotencyKeysObj,
      // β.2: per-user backup buckets serialized as Record<userId, ...>.
      latestBackupsByUser: Object.fromEntries(this.latestBackupByUser.entries()),
      backupSnapshotsByUser: Object.fromEntries(this.backupSnapshotByUser.entries()),
      fishingTasks: fishingTasksObj,
      fishingAttempts: flat(this.fishingAttemptsByUser),
      lotteryBoxes: flat(this.lotteryBoxesByUser),
      // β.5c: per-user inventory / equipment / wallet.
      ownedItemsByUser: ownedItemsByUserObj,
      equippedOutfitByUser: equippedOutfitByUserObj,
      equippedRoomByUser: equippedRoomByUserObj,
      walletByUser: walletByUserObj,
    };
  }

  /**
   * Hydrate in-memory state from a snapshot.
   *
   * 需求 23 Phase A4-β.3: each entity row is bucketed by its own
   * `user_id` field. Legacy snapshots without user_id (extremely rare
   * dev-only) get assigned to DEV_USER_ID.
   */
  hydrate(snapshot: DevStoreSnapshot): void {
    const bucketize = <T extends { user_id?: string }>(
      flat: T[] | undefined,
      target: Map<string, T[]>,
    ) => {
      target.clear();
      for (const row of flat ?? []) {
        const uid = row.user_id ?? DEV_USER_ID;
        let arr = target.get(uid);
        if (!arr) { arr = []; target.set(uid, arr); }
        arr.push(row);
      }
    };

    bucketize(snapshot.studyAttempts, this.studyAttemptsByUser);
    bucketize(snapshot.reviewGroups, this.reviewGroupsByUser);
    bucketize(snapshot.reviewAttempts, this.reviewAttemptsByUser);
    bucketize(snapshot.sourceEvents as any, this.sourceEventsByUser);
    bucketize(snapshot.rewardLedgerItems as any, this.rewardLedgerItemsByUser);
    bucketize(snapshot.settlements as any, this.settlementsByUser);
    bucketize(snapshot.sessions as any, this.sessionsByUser);
    bucketize(snapshot.checkIns as any, this.checkInsByUser);
    bucketize(snapshot.learningDays as any, this.learningDaysByUser);
    bucketize(snapshot.feedRecords as any, this.feedRecordsByUser);
    bucketize(snapshot.fishingAttempts as any ?? [], this.fishingAttemptsByUser);
    bucketize(snapshot.lotteryBoxes as any ?? [], this.lotteryBoxesByUser);

    // β.5c: prefer per-user maps; fall back to legacy single-slot fields
    // (those migrate into the DEV_USER_ID bucket for backward compat).
    const primary = DEV_USER_ID;

    this.ownedItemsByUser.clear();
    if (snapshot.ownedItemsByUser) {
      for (const [uid, items] of Object.entries(snapshot.ownedItemsByUser)) {
        this.ownedItemsByUser.set(uid, [...(items as OwnedItem[])]);
      }
    } else if (snapshot.ownedItems && snapshot.ownedItems.length > 0) {
      this.ownedItemsByUser.set(primary, [...snapshot.ownedItems]);
    }

    this.streakRecordByUser.clear();
    if (snapshot.streakRecord) {
      const sr = snapshot.streakRecord as StreakRecord;
      this.streakRecordByUser.set(sr.user_id ?? primary, sr);
    }

    this.feedMoodAccumulatedByUser.clear();
    this.feedExpAccumulatedByUser.clear();
    this.feedBondAccumulatedByUser.clear();
    this.coinsSpentByUser.clear();
    if (snapshot.walletByUser) {
      for (const [uid, w] of Object.entries(snapshot.walletByUser)) {
        this.coinsSpentByUser.set(uid, w.coinsSpent ?? 0);
        this.feedMoodAccumulatedByUser.set(uid, w.feedMoodAccumulated ?? 0);
        this.feedExpAccumulatedByUser.set(uid, w.feedExpAccumulated ?? 0);
        this.feedBondAccumulatedByUser.set(uid, w.feedBondAccumulated ?? 0);
      }
    } else {
      this.coinsSpentByUser.set(primary, snapshot.coinsSpent ?? 0);
      this.feedMoodAccumulatedByUser.set(primary, snapshot.feedMoodAccumulated ?? 0);
      this.feedExpAccumulatedByUser.set(primary, snapshot.feedExpAccumulated ?? 0);
      this.feedBondAccumulatedByUser.set(primary, snapshot.feedBondAccumulated ?? 0);
    }

    this.equippedOutfitByUser.clear();
    if (snapshot.equippedOutfitByUser) {
      for (const [uid, slots] of Object.entries(snapshot.equippedOutfitByUser)) {
        this.equippedOutfitByUser.set(uid, { ...slots });
      }
    } else {
      this.equippedOutfitByUser.set(primary, snapshot.equippedOutfit ?? {});
    }

    this.equippedRoomByUser.clear();
    if (snapshot.equippedRoomByUser) {
      for (const [uid, slots] of Object.entries(snapshot.equippedRoomByUser)) {
        this.equippedRoomByUser.set(uid, { ...slots });
      }
    } else {
      this.equippedRoomByUser.set(primary, snapshot.equippedRoom ?? {});
    }

    // todayStates: snapshot uses date-only keys (β.3 single-user persistence
    // limit; β.5 will introduce per-user persistence). Each value's
    // user_id field is the source of truth for partitioning.
    this.todayStatesByUser.clear();
    if (snapshot.todayStates) {
      for (const [date, v] of Object.entries(snapshot.todayStates)) {
        const uid = (v as any)?.user_id ?? primary;
        let inner = this.todayStatesByUser.get(uid);
        if (!inner) { inner = new Map(); this.todayStatesByUser.set(uid, inner); }
        inner.set(date, v as TodayState);
      }
    }

    this.idempotencyKeysByUser.clear();
    if (snapshot.idempotencyKeys) {
      for (const [key, v] of Object.entries(snapshot.idempotencyKeys)) {
        const rec = v as any;
        const uid = rec?.user_id ?? primary;
        let inner = this.idempotencyKeysByUser.get(uid);
        if (!inner) { inner = new Map(); this.idempotencyKeysByUser.set(uid, inner); }
        inner.set(key, { ...rec, key, user_id: uid });
      }
    }

    // fishingTasks: each task has user_id field.
    this.fishingTasksByUser.clear();
    if (snapshot.fishingTasks) {
      for (const [tid, v] of Object.entries(snapshot.fishingTasks)) {
        const task = v as DailyFishingTask;
        const uid = task.user_id ?? primary;
        let inner = this.fishingTasksByUser.get(uid);
        if (!inner) { inner = new Map(); this.fishingTasksByUser.set(uid, inner); }
        inner.set(tid, task);
      }
    }

    // P3.2 backup state.
    // β.2: prefer per-user buckets; if a legacy single-slot field is present
    // (from a pre-β.2 snapshot), migrate it into the DEV_USER_ID bucket.
    this.latestBackupByUser.clear();
    this.backupSnapshotByUser.clear();
    if (snapshot.latestBackupsByUser) {
      for (const [uid, meta] of Object.entries(snapshot.latestBackupsByUser)) {
        this.latestBackupByUser.set(uid, meta);
      }
    } else if (snapshot.latestBackup) {
      // legacy single-slot → dev-user bucket (last-write-wins under that user)
      this.latestBackupByUser.set(DEV_USER_ID, snapshot.latestBackup);
    }
    if (snapshot.backupSnapshotsByUser) {
      for (const [uid, snap] of Object.entries(snapshot.backupSnapshotsByUser)) {
        this.backupSnapshotByUser.set(uid, snap);
      }
    } else if (snapshot.backupSnapshot) {
      this.backupSnapshotByUser.set(DEV_USER_ID, snapshot.backupSnapshot);
    }

    // Phase D fishingAttempts / lotteryBoxes already bucketized above.
    // fishingTasks Map already populated above.
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
      const userIdAtSave = this.userId; // capture bound user
      this.saveError = null;
      this.saveChain = this.saveChain
        .then(() => this.persistence.saveAsync!(snapshot, userIdAtSave))
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

  // β.9 hot-fix: replaced by userDailyNewTargetByUser Map (declared above).
  // Legacy facade `this.userDailyNewTarget` getter/setter routes per-user.

  /**
   * v0.3.0 P1 dev fixture: which canonical word_ids count as "review-eligible"
   * for review-group seeding. Replaces the legacy `word.word_id.startsWith('word-r-')`
   * hack that depended on synthesized prefixed ids.
   *
   * In production, review-eligibility is determined by user_word_progress (a
   * word becomes review-eligible after the user has studied it once). This
   * static set exists only to make review-feature dev-testing easy without
   * first walking through the new-word flow.
   */
  private static readonly REVIEW_SEED_WORD_IDS = new Set<string>([
    'background',
    'bacteria',
    'balance',
    'banner',
    'barrier',
    'behavior',
    'benefit',
    'biology',
    'boundary',
    'abandon',
  ]);

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
      // v0.3.0 P1: words no longer carries book_id directly; we JOIN the
      // word_book_memberships M:N table to denormalize one (word, book)
      // tuple per row for the in-memory wordPool.
      const result = await pool.query(
        `SELECT
           w.id AS word_id,
           w.word_text,
           w.meaning,
           w.phonetic,
           m.book_id,
           w.translation,
           w.definition,
           w.difficulty_level,
           w.is_core,
           w.tags,
           w.frequency_rank,
           w.word_forms
         FROM words w
         JOIN word_book_memberships m ON m.word_id = w.id
         WHERE m.book_id = $1
         ORDER BY m.sort_order ASC`,
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

    // Minimal fallback for JSON persistence / test mode (canonical ids per v0.3.0).
    this.wordPool = [
      { word_id: 'abandon', word_text: 'abandon', meaning: '放弃', phonetic: '/əˈbændən/', book_id: DEV_BOOK_ID },
      { word_id: 'ability', word_text: 'ability', meaning: '能力', phonetic: '/əˈbɪləti/', book_id: DEV_BOOK_ID },
      { word_id: 'abnormal', word_text: 'abnormal', meaning: '异常的', phonetic: '/æbˈnɔːrml/', book_id: DEV_BOOK_ID },
      { word_id: 'aboard', word_text: 'aboard', meaning: '在船上', phonetic: '/əˈbɔːrd/', book_id: DEV_BOOK_ID },
      { word_id: 'abrupt', word_text: 'abrupt', meaning: '突然的', phonetic: '/əˈbrʌpt/', book_id: DEV_BOOK_ID },
    ];
    console.log(`[DevStore] Using ${this.wordPool.length} fallback words (PG not available).`);
  }

  /**
   * Load a user's daily new target from PG user_book_settings.
   * Falls back to 20 if PG unavailable or user has no settings row.
   *
   * β.9 hot-fix (评审采纳): takes userId; was hardcoded DEV_USER_ID before
   * which made A's setting affect B (PRD §5.1 settings must be per-user).
   */
  async loadUserSettings(userId: string = DEV_USER_ID): Promise<void> {
    try {
      const { Pool } = require('pg');
      const pool = new Pool({
        connectionString: process.env.DATABASE_URL || 'postgresql://postgres:jason123@localhost:5432/meow_dev',
      });
      const result = await pool.query(
        'SELECT daily_new_target FROM user_book_settings WHERE user_id = $1 AND is_active = TRUE LIMIT 1',
        [userId],
      );
      // β.9: also hydrate pet nickname from PG pet_profiles (per-user)
      const petResult = await pool.query(
        'SELECT nickname FROM pet_profiles WHERE user_id = $1 LIMIT 1',
        [userId],
      );
      await pool.end();
      if (result.rows.length > 0) {
        this.userDailyNewTargetByUser.set(userId, result.rows[0].daily_new_target);
        console.log(`[DevStore] User ${userId} daily new target: ${result.rows[0].daily_new_target}`);
      }
      if (petResult.rows.length > 0 && petResult.rows[0].nickname) {
        this.petNicknameByUser.set(userId, petResult.rows[0].nickname);
      }
    } catch (e) {
      // PG not available — keep default 20
    }
  }

  /**
   * Update a user's daily new target in PG and in-memory.
   * Also updates today's state target so it takes effect immediately.
   *
   * β.9 hot-fix (评审采纳): takes userId; was hardcoded DEV_USER_ID before.
   */
  async updateDailyNewTarget(userId: string, newTarget: number): Promise<void> {
    this.userDailyNewTargetByUser.set(userId, newTarget);

    // Update PG
    try {
      const { Pool } = require('pg');
      const pool = new Pool({
        connectionString: process.env.DATABASE_URL || 'postgresql://postgres:jason123@localhost:5432/meow_dev',
      });
      await pool.query(
        'UPDATE user_book_settings SET daily_new_target = $1, updated_at = NOW() WHERE user_id = $2 AND is_active = TRUE',
        [newTarget, userId],
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
    idempotencyKey: string,
    sessionId?: string,
  ): { success: boolean; alreadyExists: boolean; attempt: StudyAttempt } {
    // β.9 hot-fix (audit §6 评审采纳): session_id cross-user check.
    // Reject ONLY if session_id is clearly owned by another user.
    // Unknown session_id (legacy / test data) is allowed — only the
    // explicit cross-user attribution attack is blocked.
    if (sessionId) {
      for (const [uid, sessions] of this.sessionsByUser.entries()) {
        if (uid === this.userId) continue;
        if (sessions.some(s => s.session_id === sessionId)) {
          throw new NotFoundException(`Session not found: ${sessionId}`);
        }
      }
    }
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
            created_at: '',
            session_id: sessionId,
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
      if (sessionId) {
        existingAttempt.session_id = sessionId;
      }

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
      session_id: sessionId,
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
    // v0.3.0 P1: review eligibility was previously inferred from the legacy
    // 'word-r-*' prefix on synthesized word_ids. Now that all word_ids are
    // canonical, we use the explicit REVIEW_SEED_WORD_IDS dev fixture set.
    const reviewWords = this.wordPool.filter((w) =>
      DevStore.REVIEW_SEED_WORD_IDS.has(w.word_id),
    );
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
    idempotencyKey: string,
    sessionId?: string,
  ): { success: boolean; groupCompleted: boolean; alreadyExists: boolean } {
    // 需求 23 audit §6 owner-check: review_group must belong to current user.
    // Phase A4-β.1: cross-user review_group access throws 404 (was returning
    // {success:false} which leaked group existence). Item-not-in-group and
    // other validation paths still return {success:false} below — only the
    // owner-mismatch path is hardened here.
    const group = this.reviewGroups.find(
      g => g.review_group_id === reviewGroupId && g.user_id === this.userId,
    );
    if (!group) {
      throw new NotFoundException(`Review group not found: ${reviewGroupId}`);
    }
    // β.9 hot-fix (audit §6 评审采纳): session_id cross-user check
    // (same lenient logic as submitStudyAttempt above).
    if (sessionId) {
      for (const [uid, sessions] of this.sessionsByUser.entries()) {
        if (uid === this.userId) continue;
        if (sessions.some(s => s.session_id === sessionId)) {
          throw new NotFoundException(`Session not found: ${sessionId}`);
        }
      }
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
      session_id: sessionId,
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
   * Submit a local-origin review session batch.
   *
   * Called by POST /review-attempts/local-batch when the mobile client
   * serves from the local FSRS queue (non-continuation cutover path).
   * No backend-issued reviewGroupId is needed — the group is ephemeral.
   *
   * Returns: { success, alreadyExists, localGroupId }
   */
  submitLocalReviewBatch(
    wordAttempts: { word_id: string; action_result: 'correct' | 'incorrect'; session_id?: string }[],
    idempotencyKey: string,
  ): { success: boolean; alreadyExists: boolean; localGroupId: string } {
    const localGroupId = `local_batch_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;

    // β.5c/audit §6 hot-fix: reject if any word_attempt carries a session_id
    // that belongs to another user. submitStudyAttempt and submitReviewAttempt
    // already enforce this on their session_id arg; local-batch was the
    // remaining gap audit §6 line 230 flagged.
    for (const wa of wordAttempts) {
      this.assertSessionIdNotCrossUser(wa.session_id);
    }

    if (idempotencyKey) {
      const existing = this.getIdempotencyKey(idempotencyKey);
      if (existing) {
        return { success: true, alreadyExists: true, localGroupId };
      }
    }

    // Record all attempts under the ephemeral local group ID
    for (const attempt of wordAttempts) {
      const ra: ReviewAttempt = {
        id: `ra-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        user_id: this.userId,
        review_group_id: localGroupId,
        word_id: attempt.word_id,
        action_result: attempt.action_result,
        created_at: new Date().toISOString(),
        session_id: attempt.session_id,
      };
      this.reviewAttempts.push(ra);
    }

    // Update daily goal state (same logic as single-word group completion)
    const state = this.getTodayState();
    const reviewCompleted = state.today_review_completed + 1;
    let dailyGoalStatus: DailyGoalStatus = state.daily_goal_status;
    const newGoalMet = state.today_new_completed >= state.today_new_target;
    const reviewGoalMet = reviewCompleted >= state.today_review_target;
    if (newGoalMet && reviewGoalMet) {
      dailyGoalStatus = 'completed';
    } else if (newGoalMet || reviewGoalMet) {
      dailyGoalStatus = 'partially_completed';
    } else {
      dailyGoalStatus = 'in_progress';
    }

    this.updateTodayState({
      active_review_group_status: 'completed',
      active_review_group_remaining: 0,
      today_review_completed: reviewCompleted,
      today_review_pending: 0,
      daily_goal_status: dailyGoalStatus,
    });

    this.saveToDisk();
    return { success: true, alreadyExists: false, localGroupId };
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

  // ==================== P3.2 Backup Storage ====================
  //
  // 需求 23 Phase A4-β.2: per-user buckets. All three methods take userId
  // as first arg (no `withUser` wrapping needed) for explicit ownership.

  /**
   * Store a backup snapshot for the given user (last-write-wins per user).
   * Persisted via the normal saveToDisk() chain.
   */
  storeBackup(
    userId: string,
    backupId: string,
    schemaVersion: string,
    uploadedAt: string,
    snapshotSizeBytes: number,
    snapshot: Record<string, any>,
    deviceId?: string,
    deviceModel?: string,
  ): void {
    this.latestBackupByUser.set(userId, {
      backup_id: backupId,
      schema_version: schemaVersion,
      uploaded_at: uploadedAt,
      snapshot_size: snapshotSizeBytes,
      status: 'succeeded',
      device_id: deviceId ?? null,
      device_model: deviceModel ?? null,
    });
    this.backupSnapshotByUser.set(userId, snapshot);
    this.saveToDisk();
  }

  /** Get latest backup metadata for the given user. Null if none stored. */
  getLatestBackupMeta(userId: string): any | null {
    return this.latestBackupByUser.get(userId) ?? null;
  }

  /** Get the full backup snapshot for the given user. Null if none stored. */
  getBackupSnapshot(userId: string): any | null {
    return this.backupSnapshotByUser.get(userId) ?? null;
  }

  /**
   * Get store for testing.
   *
   * 需求 23 Phase A4-α: bulk read methods filter by current user_id to
   * prevent cross-user data leakage. Defensive — under permissive
   * AUTH_ENFORCE=false all entities are owned by DEV_USER_ID anyway.
   */
  getStudyAttempts(): StudyAttempt[] {
    return this.studyAttempts.filter(a => a.user_id === this.userId);
  }

  getReviewGroups(): ReviewGroup[] {
    return this.reviewGroups.filter(g => g.user_id === this.userId);
  }

  getReviewAttempts(): ReviewAttempt[] {
    return this.reviewAttempts.filter(a => a.user_id === this.userId);
  }

  /**
   * Need #10 — Newest-first review history for a single word.
   * Stable sort: created_at DESC, then attempt id DESC as tiebreaker so
   * multiple attempts within the same millisecond are still ordered.
   *
   * 需求 23 Phase A4-α: filtered by current user_id.
   */
  getReviewAttemptsForWord(wordId: string, limit: number): ReviewAttempt[] {
    const matches = this.reviewAttempts.filter(
      a => a.word_id === wordId && a.user_id === this.userId,
    );
    matches.sort((a, b) => {
      const ca = new Date(a.created_at).getTime();
      const cb = new Date(b.created_at).getTime();
      if (cb !== ca) return cb - ca;
      return b.id.localeCompare(a.id);
    });
    const cap = Math.max(1, Math.min(limit, 200));
    return matches.slice(0, cap);
  }

  getSourceEvents(): RewardSourceEvent[] {
    return this.sourceEvents.filter(e => e.user_id === this.userId);
  }

  getSettlements(): Settlement[] {
    return this.settlements.filter(s => s.user_id === this.userId);
  }

  getRewardLedgerItems(): RewardLedgerItem[] {
    return this.rewardLedgerItems.filter(r => r.user_id === this.userId);
  }

  /**
   * Reset store (for testing).
   * Clears both in-memory state and persisted file.
   *
   * 需求 23 Phase A4-β.3: clear all *ByUser buckets (was per-field
   * single-state in α/pre-β).
   */
  reset(): void {
    this.studyAttemptsByUser.clear();
    this.reviewGroupsByUser.clear();
    this.reviewAttemptsByUser.clear();
    this.todayStatesByUser.clear();
    this.idempotencyKeysByUser.clear();
    this.sourceEventsByUser.clear();
    this.rewardLedgerItemsByUser.clear();
    this.settlementsByUser.clear();
    this.sessionsByUser.clear();
    this.checkInsByUser.clear();
    this.streakRecordByUser.clear();
    this.learningDaysByUser.clear();
    this.feedRecordsByUser.clear();
    this.feedMoodAccumulatedByUser.clear();
    this.feedExpAccumulatedByUser.clear();
    this.feedBondAccumulatedByUser.clear();
    this.ownedItemsByUser.clear();
    this.coinsSpentByUser.clear();
    this.equippedOutfitByUser.clear();
    this.equippedRoomByUser.clear();
    this.fishingTasksByUser.clear();
    this.fishingAttemptsByUser.clear();
    this.lotteryBoxesByUser.clear();
    // β.2: backup buckets
    this.latestBackupByUser.clear();
    this.backupSnapshotByUser.clear();
    // β.5b: forget what we've already hydrated so the next request
    // triggers a fresh load.
    this.loadedUsers.clear();
    this.loadingByUser.clear();
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

    // β.9 hot-fix (audit §6 评审采纳): cross-user owner check.
    // Only REJECT if source_ref_id is clearly OWNED BY ANOTHER USER.
    // Allow if it belongs to current user OR is unrecognized (dev-style
    // test ref ids like 'pg-purchase-1' must continue working).
    //
    // Attack prevented: user A submits B's study_attempt.id → would have
    // double-claimed B's effective_new_word. Now blocked.
    // Not blocked: A submits an arbitrary string never seen before — that's
    // dev / test workflow shape, and no entity-cross-pollination happens
    // (the source_event just records the string under A's user_id).
    const findInOtherUser = (
      byUser: Map<string, { id?: string; review_group_id?: string }[]>,
      matchFn: (e: any) => boolean,
    ): boolean => {
      for (const [uid, arr] of byUser.entries()) {
        if (uid === this.userId) continue;
        if (arr.some(matchFn)) return true;
      }
      return false;
    };

    if (sourceEventType === 'effective_new_word') {
      if (findInOtherUser(
        this.studyAttemptsByUser as Map<string, any[]>,
        (a: any) => a.id === sourceRefId,
      )) {
        throw new NotFoundException(`Study attempt not found: ${sourceRefId}`);
      }
    } else if (sourceEventType === 'review_group_completed') {
      if (findInOtherUser(
        this.reviewGroupsByUser as Map<string, any[]>,
        (g: any) => g.review_group_id === sourceRefId,
      )) {
        throw new NotFoundException(`Review group not found: ${sourceRefId}`);
      }
    }

    // Check if source event already exists for this ref
    // 需求 23 / migration 009: UNIQUE now scoped per-user. Match (user_id, type, ref).
    const existingSourceEvent = this.sourceEvents.find(
      e => e.user_id === this.userId
        && e.source_event_type === sourceEventType
        && e.source_ref_id === sourceRefId
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

    // 需求 23 audit §6 owner-check: source_event must belong to current user.
    // Mismatched user → "not found" (404) to avoid ID enumeration.
    // Phase A4-β.1: unified to NotFoundException for clean controller semantics.
    const sourceEvent = this.sourceEvents.find(
      e => e.source_event_id === sourceEventId && e.user_id === this.userId,
    );
    if (!sourceEvent) {
      throw new NotFoundException(`Source event not found: ${sourceEventId}`);
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
   *
   * 需求 23 audit §6 owner-check: returns null if settlement is not
   * owned by the currently bound user.
   */
  getSettlementBySourceEventId(sourceEventId: string): Settlement | null {
    return (
      this.settlements.find(
        s => s.source_event_id === sourceEventId && s.user_id === this.userId,
      ) || null
    );
  }

  /**
   * Get settlement by settlement ID
   *
   * 需求 23 audit §6 owner-check: returns null if settlement is not
   * owned by the currently bound user.
   */
  getSettlement(settlementId: string): Settlement | null {
    return (
      this.settlements.find(
        s => s.settlement_id === settlementId && s.user_id === this.userId,
      ) || null
    );
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

    // β.9 hot-fix: nickname is per-user — user-modified overlay (PG
    // pet_profiles) takes precedence over baseline catProfile.nickname.
    // catProfile.nickname remains the default for users who haven't
    // customized (or where PG hydrate failed).
    const nickname = this.petNicknameByUser.get(this.userId) ?? this.catProfile.nickname;

    return {
      nickname,
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
    const today = new Date().toISOString().split('T')[0];
    const todayState = this.todayStates.get(today);
    return {
      ...balances,
      // Phase 2A: total exp includes feed-accumulated exp
      exp: balances.exp + this.feedExpAccumulated,
      cat_summary: this.getCatSummary(),
      companion_response: this.getCompanionResponse(),
      equipped_preview: this.getEquippedPreview(),
      change_highlights: this.buildChangeHighlights(),
      stats_summary: this.buildStatsSummary(),
      review_debt: todayState?.today_review_pending ?? 0,
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
  startSession(
    minutesTarget: number,
    idempotencyKey: string,
    clientSessionId?: string,
  ): { session: Session; alreadyExists: boolean } {
    // Check idempotency
    const existingRecord = this.getIdempotencyKey(idempotencyKey);
    if (existingRecord) {
      const sessionId = (existingRecord.response as any).session_id;
      const existingSession = this.sessions.find(s => s.session_id === sessionId);
      if (existingSession) {
        return { session: existingSession, alreadyExists: true };
      }
    }

    // If client supplied a session_id and it already exists, treat as idempotent.
    if (clientSessionId) {
      const existingByClientId = this.sessions.find(s => s.session_id === clientSessionId);
      if (existingByClientId) {
        return { session: existingByClientId, alreadyExists: true };
      }
    }

    // Check for existing active session (global single-active constraint).
    const existingActive = this.getActiveSession();
    if (existingActive) {
      return { session: existingActive, alreadyExists: true };
    }

    // Create new session — prefer client-supplied id (offline-first UUID).
    const session: Session = {
      session_id: clientSessionId ?? `sess-${Date.now()}`,
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
    // 需求 23 audit §6 owner-check: only owner may finish.
    // We resolve session by (id, user_id) below; if mismatch → "not found"
    // (404) to avoid entity ID enumeration.
    // Check idempotency
    const existingRecord = this.getIdempotencyKey(idempotencyKey);
    if (existingRecord) {
      const existingSession = this.sessions.find(
        s => s.session_id === sessionId && s.user_id === this.userId,
      );
      // Phase 5 closeout: Check for any terminal state (valid/invalid)
      if (existingSession && ['valid', 'invalid'].includes(existingSession.session_status)) {
        return { session: existingSession, alreadyExists: true };
      }
    }

    // Owner-check failure → NotFoundException (404, no leakage of "session
    // exists but not yours"). 需求 23 Phase A4-β.1: unified error shape.
    const session = this.sessions.find(
      s => s.session_id === sessionId && s.user_id === this.userId,
    );
    if (!session) {
      throw new NotFoundException(`Session not found: ${sessionId}`);
    }

    // Phase 5 closeout: Check for any terminal state
    if (['valid', 'invalid'].includes(session.session_status)) {
      return { session, alreadyExists: true };
    }

    // Count effective attempts during this session.
    // Primary path: explicit session_id linkage. Fallback: time window (for legacy/late-arriving offline attempts without session_id).
    const sessionStartTime = new Date(session.started_at).getTime();
    const now = Date.now();

    const learningById = this.studyAttempts.filter(
      a => a.session_id === session.session_id &&
           a.study_type === 'new' &&
           a.action_result === 'know',
    ).length;

    const reviewById = this.reviewAttempts.filter(
      a => a.session_id === session.session_id &&
           a.action_result === 'correct',
    ).length;

    let effectiveLearningCount = learningById;
    let effectiveReviewCount = reviewById;

    if (effectiveLearningCount === 0 && effectiveReviewCount === 0) {
      effectiveLearningCount = this.studyAttempts.filter(
        a => !a.session_id &&
             a.study_type === 'new' &&
             a.action_result === 'know' &&
             new Date(a.created_at).getTime() >= sessionStartTime &&
             new Date(a.created_at).getTime() <= now,
      ).length;
      effectiveReviewCount = this.reviewAttempts.filter(
        a => !a.session_id &&
             a.action_result === 'correct' &&
             new Date(a.created_at).getTime() >= sessionStartTime &&
             new Date(a.created_at).getTime() <= now,
      ).length;
    }

    session.effective_learning_count = effectiveLearningCount;
    session.effective_review_count = effectiveReviewCount;
    session.session_status = 'ended';
    session.ended_at = new Date().toISOString();

    // Duration: keep actual_minutes for backward compat + add duration_seconds (frozen field per BR-011 derivative).
    const elapsedMs = now - sessionStartTime;
    session.duration_seconds = Math.max(0, Math.round(elapsedMs / 1000));
    const actualMinutes = elapsedMs / 1000 / 60;
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
   *
   * 需求 23 audit §6 owner-check: returns null if session is not owned
   * by the currently bound user (prevents cross-user reads).
   */
  getSession(sessionId: string): Session | null {
    return (
      this.sessions.find(
        s => s.session_id === sessionId && s.user_id === this.userId,
      ) || null
    );
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
    // β.5c/audit §6 hot-fix: cross-user owner check. Reject only when the
    // item is clearly owned by ANOTHER user — that's the ID-enumeration
    // attack the audit prohibits. "Never bought by anyone" still resolves
    // to ITEM_NOT_OWNED below (legitimate UX response).
    this.assertInventoryItemNotCrossUser(itemId);

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
    // β.5c/audit §6 hot-fix: cross-user owner check (same rule as equipItem).
    this.assertInventoryItemNotCrossUser(itemId);

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
   * Get owned items for testing.
   *
   * Note (A4-α): OwnedItem has no user_id field, so under multi-user
   * mode (AUTH_ENFORCE=true) this WILL leak across users. A4-β must
   * partition `this.ownedItems` per-user. Single-user permissive mode
   * is unaffected.
   */
  getOwnedItems(): OwnedItem[] {
    return [...this.ownedItems];
  }

  /**
   * Get feed records for testing.
   *
   * 需求 23 Phase A4-α: filtered by current user_id.
   */
  getFeedRecords(): FeedRecord[] {
    return this.feedRecords.filter(f => f.user_id === this.userId);
  }

  /**
   * Get today's feed count (for testing anti-spam)
   *
   * 需求 23 Phase A4-α: filtered by current user_id.
   */
  getTodayFeedCount(): number {
    const today = new Date().toISOString().split('T')[0];
    return this.feedRecords.filter(
      f => f.local_date === today && f.user_id === this.userId,
    ).length;
  }

  /**
   * Get sessions for testing.
   * 需求 23 Phase A4-α: filtered by current user_id.
   */
  getSessions(): Session[] {
    return this.sessions.filter(s => s.user_id === this.userId);
  }

  /**
   * Get check-ins for testing.
   * 需求 23 Phase A4-α: filtered by current user_id.
   */
  getCheckIns(): CheckInRecord[] {
    return this.checkIns.filter(c => c.user_id === this.userId);
  }

  /**
   * Get streak for testing.
   * Note (A4-α): streakRecord is a single field, not a list. It implicitly
   * belongs to the bound user. Under multi-user mode A4-β must partition.
   */
  getStreak(): StreakRecord | null {
    if (this.streakRecord && this.streakRecord.user_id !== this.userId) {
      return null;
    }
    return this.streakRecord;
  }

  // ========== Phase D: Fishing Game ==========

  /**
   * Returns the Beijing effective date for daily resets.
   * Day starts at 05:00 Beijing time (UTC+8).
   */
  private getBeijingEffectiveDate(): string {
    const now = new Date();
    const beijingMs = now.getTime() + 8 * 60 * 60 * 1000;
    const beijingDate = new Date(beijingMs);
    const hour = beijingDate.getUTCHours();
    // Before 05:00 Beijing → still counts as previous day
    const effectiveMs = hour < 5 ? beijingMs - 24 * 60 * 60 * 1000 : beijingMs;
    return new Date(effectiveMs).toISOString().split('T')[0];
  }

  /** Get or create today's fishing task record. */
  getDailyFishingTask(): DailyFishingTask {
    const taskDate = this.getBeijingEffectiveDate();
    const key = `ft-${taskDate}`;
    if (!this.fishingTasks.has(key)) {
      const task: DailyFishingTask = {
        id: key,
        user_id: this.userId,
        task_date: taskDate,
        rounds_completed: 0,
        rounds_total: 3,
        status: 'available',
        current_round_fish_word_id: null,
        current_round_fish_word_meaning: null,
      };
      this.fishingTasks.set(key, task);
    }
    return this.fishingTasks.get(key)!;
  }

  /**
   * Start the next fishing round.
   * Picks one studied word as the "fish" and 4 unstudied decoys.
   * Returns null if fishing is exhausted or the user has no studied words.
   */
  startFishingRound(): FishingRoundQuestion | null {
    const task = this.getDailyFishingTask();
    if (task.status === 'exhausted') return null;
    if (task.current_round_fish_word_id) {
      // Round already started but not submitted — return same question
      const fish = this.wordPool.find(w => w.word_id === task.current_round_fish_word_id);
      if (!fish) return null;
      return this._buildRoundQuestion(task, fish);
    }

    // Collect mastered words
    const masteredIds = new Set(
      this.studyAttempts
        .filter(a => a.action_result === 'know')
        .map(a => a.word_id),
    );
    const masteredWords = this.wordPool.filter(w => masteredIds.has(w.word_id));
    if (masteredWords.length === 0) return null;

    // Random fish word
    const fish = masteredWords[Math.floor(Math.random() * masteredWords.length)];

    // 4 decoy words never studied
    const decoyPool = this.wordPool.filter(
      w => !masteredIds.has(w.word_id) && w.word_id !== fish.word_id,
    );
    const shuffledDecoys = decoyPool.sort(() => Math.random() - 0.5).slice(0, 4);
    if (shuffledDecoys.length < 4) {
      // Not enough decoys — allow fewer (edge case with tiny word pool)
    }

    // Persist active round
    task.current_round_fish_word_id = fish.word_id;
    task.current_round_fish_word_meaning = fish.meaning;
    this.saveToDisk();

    return this._buildRoundQuestion(task, fish, shuffledDecoys);
  }

  private _buildRoundQuestion(
    task: DailyFishingTask,
    fish: Word,
    decoys?: Word[],
  ): FishingRoundQuestion {
    const decoysToUse = decoys ?? this.wordPool
      .filter(w => w.word_id !== fish.word_id)
      .sort(() => Math.random() - 0.5)
      .slice(0, 4);

    const choices: FishingChoice[] = [
      { word_id: fish.word_id, word_text: fish.word_text },
      ...decoysToUse.map(d => ({ word_id: d.word_id, word_text: d.word_text })),
    ].sort(() => Math.random() - 0.5);

    return {
      task_id: task.id,
      round_number: task.rounds_completed + 1,
      choices,
    };
  }

  /**
   * Submit the user's choice for the active fishing round.
   * Idempotent via idempotency key.
   */
  submitFishingAttempt(
    taskId: string,
    chosenWordId: string,
    idempotencyKey: string,
  ): {
    alreadyExists: boolean;
    attempt: FishingAttempt | null;
    isCorrect: boolean;
    fishWord: { word_id: string; word_text: string; meaning: string } | null;
    fishTreatsEarned: number;
    roundsCompleted: number;
    roundsTotal: number;
    status: DailyFishingStatus;
    boxEarned: boolean;
    boxId: string | null;
  } {
    if (idempotencyKey) {
      const existing = this.getIdempotencyKey(idempotencyKey);
      if (existing) {
        return { alreadyExists: true, attempt: null, isCorrect: false, fishWord: null, fishTreatsEarned: 0, roundsCompleted: 0, roundsTotal: 3, status: 'available', boxEarned: false, boxId: null };
      }
    }

    // 需求 23 audit §6 owner-check: fishing task must belong to current user.
    // Phase A4-β.1: split owner-mismatch (→ 404) from "no active round"
    // (legitimate state; client may need to start a round first).
    const task = this.fishingTasks.get(taskId);
    if (!task || task.user_id !== this.userId) {
      throw new NotFoundException(`Fishing task not found: ${taskId}`);
    }
    if (!task.current_round_fish_word_id) {
      return { alreadyExists: false, attempt: null, isCorrect: false, fishWord: null, fishTreatsEarned: 0, roundsCompleted: task.rounds_completed, roundsTotal: task.rounds_total, status: task.status, boxEarned: false, boxId: null };
    }

    const fishWordId = task.current_round_fish_word_id;
    const fishWord = this.wordPool.find(w => w.word_id === fishWordId);
    const isCorrect = chosenWordId === fishWordId;
    const fishTreatsEarned = isCorrect ? 2 : 0;

    const attempt: FishingAttempt = {
      id: `fa-${Date.now()}-${Math.random().toString(36).substr(2, 6)}`,
      user_id: this.userId,
      task_date: task.task_date,
      round_number: task.rounds_completed + 1,
      fish_word_id: fishWordId,
      chosen_word_id: chosenWordId,
      is_correct: isCorrect,
      fish_treats_earned: fishTreatsEarned,
      created_at: new Date().toISOString(),
    };
    this.fishingAttempts.push(attempt);

    // Reward fish treats via ledger if correct
    if (isCorrect && fishTreatsEarned > 0) {
      const ledgerItem: RewardLedgerItem = {
        reward_item_id: `rl-fish-${attempt.id}`,
        source_event_id: `fishing-${attempt.id}`,
        user_id: this.userId,
        reward_type: 'fish_treats',
        amount: fishTreatsEarned,
        reward_status: 'succeeded',
        created_at: attempt.created_at,
      };
      this.rewardLedgerItems.push(ledgerItem);
    }

    // Advance task
    task.rounds_completed += 1;
    task.current_round_fish_word_id = null;
    task.current_round_fish_word_meaning = null;
    if (task.rounds_completed >= task.rounds_total) {
      task.status = 'exhausted';
    }

    // Box earned when all rounds completed
    let boxId: string | null = null;
    if (task.rounds_completed >= task.rounds_total) {
      const box: LotteryBox = {
        id: `lbox-${Date.now()}-${Math.random().toString(36).substr(2, 6)}`,
        user_id: this.userId,
        source: 'fishing',
        opened: false,
        opened_at: null,
        prize_type: null,
        prize_ref: null,
        created_at: new Date().toISOString(),
      };
      this.lotteryBoxes.push(box);
      boxId = box.id;
    }

    this.saveToDisk();

    return {
      alreadyExists: false,
      attempt,
      isCorrect,
      fishWord: fishWord ? { word_id: fishWord.word_id, word_text: fishWord.word_text, meaning: fishWord.meaning } : null,
      fishTreatsEarned,
      roundsCompleted: task.rounds_completed,
      roundsTotal: task.rounds_total,
      status: task.status,
      boxEarned: boxId !== null,
      boxId,
    };
  }

  // ========== Phase D: Lottery ==========

  /** Get all unopened lottery boxes for this user.
   *
   * 需求 23 audit §6 owner-check: filter by user_id. */
  getLotteryBoxes(): LotteryBox[] {
    return this.lotteryBoxes.filter(b => !b.opened && b.user_id === this.userId);
  }

  /**
   * Open a lottery box. Draws a prize using weighted random from lotteryDropsConfig.
   * Awards coins to reward ledger.
   */
  openLotteryBox(
    boxId: string,
    idempotencyKey: string,
  ): {
    alreadyExists: boolean;
    box: LotteryBox | null;
    coinsWon: number;
  } {
    if (idempotencyKey) {
      const existing = this.getIdempotencyKey(idempotencyKey);
      if (existing) {
        return { alreadyExists: true, box: null, coinsWon: 0 };
      }
    }

    // 需求 23 audit §6 owner-check: box must belong to current user.
    // Phase A4-β.1: split outcomes for clarity.
    //   - not found OR not owned → 404 (no enumeration)
    //   - already opened → idempotent replay (alreadyExists=true)
    const box = this.lotteryBoxes.find(
      b => b.id === boxId && b.user_id === this.userId,
    );
    if (!box) {
      throw new NotFoundException(`Lottery box not found: ${boxId}`);
    }
    if (box.opened) {
      return { alreadyExists: true, box, coinsWon: 0 };
    }

    // Weighted random draw
    const activeConfigs = this.lotteryDropsConfig.filter(c => c.is_active);
    const totalWeight = activeConfigs.reduce((sum, c) => sum + c.weight, 0);
    let roll = Math.random() * totalWeight;
    let picked = activeConfigs[activeConfigs.length - 1];
    for (const config of activeConfigs) {
      roll -= config.weight;
      if (roll <= 0) { picked = config; break; }
    }

    const coinsWon = parseInt(picked.prize_ref, 10);
    const now = new Date().toISOString();

    box.opened = true;
    box.opened_at = now;
    box.prize_type = picked.prize_type;
    box.prize_ref = picked.prize_ref;

    // Award coins via reward ledger
    const ledgerItem: RewardLedgerItem = {
      reward_item_id: `rl-lbox-${boxId}`,
      source_event_id: `lottery-${boxId}`,
      user_id: this.userId,
      reward_type: 'coins',
      amount: coinsWon,
      reward_status: 'succeeded',
      created_at: now,
    };
    this.rewardLedgerItems.push(ledgerItem);

    this.saveToDisk();
    return { alreadyExists: false, box, coinsWon };
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
