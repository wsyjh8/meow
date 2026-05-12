/**
 * PostgreSQL persistence adapter for DevStore (Option A A4).
 *
 * Implements IDevStorePersistence by reading/writing DevStoreSnapshot
 * to/from PostgreSQL tables. Replaces JSON file persistence.
 *
 * Strategy: On save(), serializes full snapshot to PG tables.
 * On load(), reads all tables and reconstructs the snapshot.
 * On clear(), truncates user-state tables (keeps seed/static data).
 */

import { Pool } from 'pg';
import type { IDevStorePersistence, DevStoreSnapshot } from '../../domain/persistence';

// 需求 23 Phase A4-β.5: load / save / clear all accept an optional userId
// parameter. Default falls back to DEV_USER_ID for back-compat with single-
// user dev mode (AUTH_ENFORCE=false). When AUTH_ENFORCE=true callers pass
// the actual userId so that each user's slice is loaded/saved independently.
//
// β.5 limitation: lazy-load on first withUser of an unseen user is NOT
// implemented — startup loadAsync only restores DEV_USER_ID's bucket.
// Other users' state lives in memory after their first request and gets
// persisted via saveAsync(snapshot, userId). After server restart, those
// users start with an empty in-memory bucket; PG row truth still per-user
// correct, but in-memory cache must be re-warmed. Full lazy-load is
// β.5b / Phase E1 切流前置 work.
const DEV_USER_ID = 'dev-user-001';

export class PgDevStorePersistence implements IDevStorePersistence {
  private pool: Pool;

  constructor(pool?: Pool) {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString && !pool) {
      throw new Error('[PgPersistence] DATABASE_URL is not set.');
    }
    this.pool = pool || new Pool({ connectionString });
  }

  load(): DevStoreSnapshot | null {
    // Synchronous interface — we return null and let async init handle it
    // DevStore calls loadFromDisk() which is private. We need an async load.
    // WORKAROUND: return null here; use loadAsync() separately.
    return null;
  }

  /**
   * Async load — reconstructs DevStoreSnapshot for a single user from PG.
   * 需求 23 Phase A4-β.5: userId param replaces hardcoded DEV_USER_ID.
   */
  async loadAsync(userId: string = DEV_USER_ID): Promise<DevStoreSnapshot | null> {
    try {
      // Check if user exists
      const userCheck = await this.pool.query('SELECT id FROM users WHERE id = $1', [userId]);
      if (userCheck.rows.length === 0) return null;

      const [
        studyAttemptsR, reviewGroupsR, reviewAttemptsR,
        sourceEventsR, rewardLedgerR, settlementsR,
        sessionsR, checkInsR, streakR, learningDaysR,
        dailyGoalR, feedEventsR, walletR, ownedItemsR,
        equipmentR, idempotencyR,
      ] = await Promise.all([
        this.pool.query('SELECT * FROM study_attempts WHERE user_id = $1 ORDER BY created_at', [userId]),
        this.pool.query('SELECT * FROM review_groups WHERE user_id = $1 ORDER BY created_at', [userId]),
        this.pool.query('SELECT * FROM review_attempts WHERE user_id = $1 ORDER BY created_at', [userId]),
        this.pool.query('SELECT * FROM reward_source_events WHERE user_id = $1 ORDER BY created_at', [userId]),
        this.pool.query('SELECT * FROM reward_ledger WHERE user_id = $1 ORDER BY created_at', [userId]),
        this.pool.query('SELECT * FROM settlements WHERE user_id = $1 ORDER BY created_at', [userId]),
        this.pool.query('SELECT * FROM session_records WHERE user_id = $1 ORDER BY created_at', [userId]),
        this.pool.query('SELECT * FROM check_in_records WHERE user_id = $1 ORDER BY created_at', [userId]),
        this.pool.query('SELECT * FROM streak_records WHERE user_id = $1', [userId]),
        this.pool.query('SELECT * FROM learning_day_facts WHERE user_id = $1', [userId]),
        this.pool.query('SELECT * FROM daily_goal_progress WHERE user_id = $1', [userId]),
        this.pool.query('SELECT * FROM feed_events WHERE user_id = $1 ORDER BY created_at', [userId]),
        this.pool.query('SELECT * FROM secondary_wallets WHERE user_id = $1', [userId]),
        this.pool.query('SELECT * FROM inventory_items WHERE user_id = $1', [userId]),
        this.pool.query('SELECT * FROM equipment_slots WHERE user_id = $1', [userId]),
        this.pool.query('SELECT * FROM idempotency_keys WHERE user_id = $1', [userId]),
      ]);

      // Map review groups with items
      const reviewGroups = [];
      for (const rg of reviewGroupsR.rows) {
        const itemsR = await this.pool.query(
          'SELECT * FROM review_group_items WHERE review_group_id = $1', [rg.id],
        );
        reviewGroups.push({
          review_group_id: rg.id,
          user_id: rg.user_id,
          group_status: rg.group_status,
          group_completed: rg.group_completed,
          items: itemsR.rows.map((i: any) => ({
            word_id: i.word_id, word_text: i.word_text,
            meaning: i.meaning, completed: i.completed,
          })),
          created_at: rg.created_at?.toISOString?.() || rg.created_at,
          completed_at: rg.completed_at?.toISOString?.() || rg.completed_at || undefined,
        });
      }

      // Map today states
      const todayStates: Record<string, any> = {};
      for (const dg of dailyGoalR.rows) {
        const dateKey = typeof dg.local_date === 'string' ? dg.local_date : dg.local_date.toISOString().split('T')[0];
        todayStates[dateKey] = {
          user_id: userId,
          local_date: dateKey,
          current_book_name: 'CET-4',
          today_new_target: dg.new_target,
          today_new_completed: dg.new_completed,
          today_review_target: dg.review_target,
          today_review_pending: dg.review_pending,
          today_review_completed: dg.review_completed,
          daily_goal_status: dg.goal_status,
          active_review_group_id: dg.active_review_group_id,
          active_review_group_status: null,
          active_review_group_remaining: 0,
          sync_status: 'healthy',
          last_reward_settlement: null,
          has_checked_in_today: false,
          learning_day_today: false,
          current_streak: 0,
          streak_basis_type: 'check_in',
          session_started_today: false,
          session_valid_today: false,
          user_local_date: dateKey,
          user_timezone: 'UTC',
        };
      }

      const wallet = walletR.rows[0];

      // Map equipped
      const equippedOutfit: Record<string, string | null> = {};
      const equippedRoom: Record<string, string | null> = {};
      for (const eq of equipmentR.rows) {
        if (eq.item_type === 'outfit') equippedOutfit[eq.slot] = eq.item_id;
        else equippedRoom[eq.slot] = eq.item_id;
      }

      // Map idempotency keys
      const idempotencyKeys: Record<string, any> = {};
      for (const ik of idempotencyR.rows) {
        idempotencyKeys[ik.key] = {
          key: ik.key, user_id: ik.user_id, path: ik.path,
          response: ik.response,
          created_at: ik.created_at?.toISOString?.() || ik.created_at,
        };
      }

      const toISO = (d: any) => d?.toISOString?.() || d || undefined;

      return {
        studyAttempts: studyAttemptsR.rows.map((r: any) => ({
          id: r.id, user_id: r.user_id, word_id: r.word_id, book_id: r.book_id,
          study_type: r.study_type, action_result: r.action_result,
          created_at: toISO(r.created_at),
        })),
        reviewGroups,
        reviewAttempts: reviewAttemptsR.rows.map((r: any) => ({
          id: r.id, user_id: r.user_id, review_group_id: r.review_group_id,
          word_id: r.word_id, action_result: r.action_result, created_at: toISO(r.created_at),
        })),
        sourceEvents: sourceEventsR.rows.map((r: any) => ({
          source_event_id: r.id, user_id: r.user_id,
          source_event_type: r.event_type, source_ref_id: r.source_ref_id,
          created_at: toISO(r.created_at),
        })),
        rewardLedgerItems: rewardLedgerR.rows.map((r: any) => ({
          reward_item_id: r.id, source_event_id: r.source_event_id, user_id: r.user_id,
          reward_type: r.reward_type, amount: r.amount, reward_status: r.reward_status,
          created_at: toISO(r.created_at),
        })),
        settlements: settlementsR.rows.map((r: any) => ({
          settlement_id: r.id, source_event_id: r.source_event_id, user_id: r.user_id,
          reward_settlement_status: r.settlement_status,
          reward_items: [], // will be populated at DevStore level
          created_at: toISO(r.created_at), updated_at: toISO(r.updated_at),
        })),
        sessions: sessionsR.rows.map((r: any) => ({
          session_id: r.id, user_id: r.user_id,
          session_status: r.session_status, session_validation_status: r.validation_status,
          session_minutes_target: r.minutes_target, started_at: toISO(r.started_at),
          ended_at: toISO(r.ended_at), effective_learning_count: r.effective_learning_count,
          effective_review_count: r.effective_review_count, actual_minutes: r.actual_minutes,
        })),
        checkIns: checkInsR.rows.map((r: any) => ({
          check_in_id: r.id, user_id: r.user_id,
          local_date: typeof r.local_date === 'string' ? r.local_date : r.local_date.toISOString().split('T')[0],
          check_in_status: r.status, created_at: toISO(r.created_at),
        })),
        streakRecord: streakR.rows[0] ? {
          user_id: streakR.rows[0].user_id,
          current_streak: streakR.rows[0].current_streak,
          streak_basis_type: streakR.rows[0].streak_basis_type,
          last_check_in_date: streakR.rows[0].last_check_in_date
            ? (typeof streakR.rows[0].last_check_in_date === 'string'
              ? streakR.rows[0].last_check_in_date
              : streakR.rows[0].last_check_in_date.toISOString().split('T')[0])
            : null,
          updated_at: toISO(streakR.rows[0].updated_at),
        } : null,
        learningDays: learningDaysR.rows.map((r: any) => ({
          user_id: r.user_id,
          local_date: typeof r.local_date === 'string' ? r.local_date : r.local_date.toISOString().split('T')[0],
          learning_day: r.is_learning_day, effective_learning_count: r.effective_learning_count,
          effective_review_count: r.effective_review_count, updated_at: toISO(r.updated_at),
        })),
        todayStates,
        feedRecords: feedEventsR.rows.map((r: any) => ({
          feed_id: r.id, user_id: r.user_id, feed_item_type: r.feed_item_type,
          consumed_amount: r.consumed_amount, mood_delta: r.mood_delta,
          exp_delta: r.exp_delta, bond_delta: r.bond_delta,
          local_date: typeof r.local_date === 'string' ? r.local_date : r.local_date.toISOString().split('T')[0],
          created_at: toISO(r.created_at),
        })),
        feedMoodAccumulated: wallet?.feed_mood_accumulated || 0,
        feedExpAccumulated: wallet?.feed_exp_accumulated || 0,
        feedBondAccumulated: wallet?.feed_bond_accumulated || 0,
        ownedItems: ownedItemsR.rows.map((r: any) => ({
          item_id: r.item_id, item_type: r.item_type, slot: r.slot,
          owned_at: toISO(r.owned_at), equipped: r.equipped,
        })),
        coinsSpent: wallet?.coins_spent || 0,
        equippedOutfit,
        equippedRoom,
        idempotencyKeys,
      };
    } catch (err) {
      console.warn('[PgPersistence] Failed to load:', err);
      return null;
    }
  }

  save(snapshot: DevStoreSnapshot): void {
    // Sync facade — for interface compat. Callers should prefer saveToDiskAsync().
    this.saveAsync(snapshot).catch(err => {
      console.error('[PgPersistence] Save (sync facade) failed:', err);
    });
  }

  /**
   * Persist a single user's slice of the snapshot.
   * 需求 23 Phase A4-β.5: userId param replaces hardcoded DEV_USER_ID.
   * Each entity collection is filtered to only the rows matching userId
   * (other users' rows in the snapshot are untouched in PG, since DELETE
   * is also scoped to userId).
   */
  async saveAsync(snapshot: DevStoreSnapshot, userId: string = DEV_USER_ID): Promise<void> {
    const client = await this.pool.connect();
    const ownedBy = (row: any) => (row.user_id ?? DEV_USER_ID) === userId;
    try {
      await client.query('BEGIN');

      // Clear THIS USER's state tables (order: reverse FK dependencies).
      // Other users' rows in PG are untouched.
      await client.query(
        `DELETE FROM review_group_items WHERE review_group_id IN (SELECT id FROM review_groups WHERE user_id = $1)`,
        [userId],
      );

      const clearTables = [
        'equipment_slots', 'inventory_items', 'purchase_records',
        'feed_events',
        'idempotency_keys', 'settlements', 'reward_ledger', 'reward_source_events',
        'learning_day_facts', 'check_in_records', 'session_records',
        'daily_goal_progress', 'review_attempts',
        'review_groups', 'study_attempts',
      ];
      for (const table of clearTables) {
        await client.query(`DELETE FROM ${table} WHERE user_id = $1`, [userId]);
      }
      // These tables need special handling (UPDATE instead of DELETE for seeded rows)
      await client.query(`UPDATE streak_records SET current_streak=0, last_check_in_date=NULL, updated_at=NOW() WHERE user_id=$1`, [userId]);
      await client.query(`UPDATE secondary_wallets SET coins_spent=0, feed_mood_accumulated=0, feed_exp_accumulated=0, feed_bond_accumulated=0, updated_at=NOW() WHERE user_id=$1`, [userId]);

      // Re-insert all state
      // Helper: try insert with savepoint (FK violations don't abort the transaction)
      const tryInsert = async (sql: string, params: any[]) => {
        await client.query('SAVEPOINT sp');
        try {
          await client.query(sql, params);
          await client.query('RELEASE SAVEPOINT sp');
        } catch (e: any) {
          await client.query('ROLLBACK TO SAVEPOINT sp');
          if (e?.code !== '23503' && e?.code !== '23505') throw e; // re-throw non-FK/unique errors
        }
      };

      for (const sa of (snapshot.studyAttempts || []).filter(ownedBy)) {
        await tryInsert(
          `INSERT INTO study_attempts (id, user_id, word_id, book_id, study_type, action_result, created_at)
           VALUES ($1,$2,$3,$4,$5,$6,$7) ON CONFLICT (id) DO NOTHING`,
          [sa.id, userId, sa.word_id, sa.book_id, sa.study_type, sa.action_result, sa.created_at],
        );
      }

      for (const rg of (snapshot.reviewGroups || []).filter(ownedBy)) {
        await tryInsert(
          `INSERT INTO review_groups (id, user_id, group_status, group_completed, created_at, completed_at)
           VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (id) DO NOTHING`,
          [rg.review_group_id, userId, rg.group_status, rg.group_completed, rg.created_at, rg.completed_at || null],
        );
        for (const item of rg.items || []) {
          await tryInsert(
            `INSERT INTO review_group_items (review_group_id, word_id, word_text, meaning, completed)
             VALUES ($1,$2,$3,$4,$5) ON CONFLICT (review_group_id, word_id) DO NOTHING`,
            [rg.review_group_id, item.word_id, item.word_text, item.meaning, item.completed],
          );
        }
      }

      for (const ra of (snapshot.reviewAttempts || []).filter(ownedBy)) {
        await tryInsert(
          `INSERT INTO review_attempts (id, user_id, review_group_id, word_id, action_result, created_at)
           VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (id) DO NOTHING`,
          [ra.id, userId, ra.review_group_id, ra.word_id, ra.action_result, ra.created_at],
        );
      }

      for (const se of (snapshot.sourceEvents || []).filter(ownedBy)) {
        await tryInsert(
          `INSERT INTO reward_source_events (id, user_id, event_type, source_ref_id, created_at)
           VALUES ($1,$2,$3,$4,$5) ON CONFLICT (id) DO NOTHING`,
          [se.source_event_id, userId, se.source_event_type, se.source_ref_id, se.created_at],
        );
      }

      for (const ri of (snapshot.rewardLedgerItems || []).filter(ownedBy)) {
        await tryInsert(
          `INSERT INTO reward_ledger (id, source_event_id, user_id, reward_type, amount, reward_status, created_at)
           VALUES ($1,$2,$3,$4,$5,$6,$7) ON CONFLICT (id) DO NOTHING`,
          [ri.reward_item_id, ri.source_event_id, userId, ri.reward_type, ri.amount, ri.reward_status, ri.created_at],
        );
      }

      for (const st of (snapshot.settlements || []).filter(ownedBy)) {
        await tryInsert(
          `INSERT INTO settlements (id, source_event_id, user_id, settlement_status, created_at, updated_at)
           VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (id) DO NOTHING`,
          [st.settlement_id, st.source_event_id, userId, st.reward_settlement_status, st.created_at, st.updated_at],
        );
      }

      for (const s of (snapshot.sessions || []).filter(ownedBy)) {
        await client.query(
          `INSERT INTO session_records (id, user_id, session_status, validation_status, minutes_target, started_at, ended_at, actual_minutes, effective_learning_count, effective_review_count)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) ON CONFLICT (id) DO NOTHING`,
          [s.session_id, userId, s.session_status, s.session_validation_status, s.session_minutes_target, s.started_at, s.ended_at || null, s.actual_minutes || null, s.effective_learning_count, s.effective_review_count],
        );
      }

      for (const ci of (snapshot.checkIns || []).filter(ownedBy)) {
        await client.query(
          `INSERT INTO check_in_records (id, user_id, local_date, status, created_at)
           VALUES ($1,$2,$3,$4,$5) ON CONFLICT (user_id, local_date) DO NOTHING`,
          [ci.check_in_id, userId, ci.local_date, ci.check_in_status, ci.created_at],
        );
      }

      for (const ld of (snapshot.learningDays || []).filter(ownedBy)) {
        await client.query(
          `INSERT INTO learning_day_facts (user_id, local_date, is_learning_day, effective_learning_count, effective_review_count, updated_at)
           VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (user_id, local_date) DO UPDATE SET is_learning_day=$3, effective_learning_count=$4, effective_review_count=$5, updated_at=$6`,
          [userId, ld.local_date, ld.learning_day, ld.effective_learning_count, ld.effective_review_count, ld.updated_at],
        );
      }

      // streakRecord: snapshot's primary streak only applies to userId if
      // it belongs to userId. Otherwise skip (we DELETE'd already above).
      if (snapshot.streakRecord && ownedBy(snapshot.streakRecord)) {
        await client.query(
          `INSERT INTO streak_records (user_id, current_streak, streak_basis_type, last_check_in_date, updated_at)
           VALUES ($1,$2,$3,$4,$5) ON CONFLICT (user_id) DO UPDATE SET current_streak=$2, streak_basis_type=$3, last_check_in_date=$4, updated_at=$5`,
          [userId, snapshot.streakRecord.current_streak, snapshot.streakRecord.streak_basis_type, snapshot.streakRecord.last_check_in_date || null, snapshot.streakRecord.updated_at],
        );
      }

      // todayStates: snapshot's todayStates Record<date, state> uses
      // date-only keys — only persist entries whose user_id matches.
      for (const [date, state] of Object.entries<any>(snapshot.todayStates || {})) {
        if (!ownedBy(state)) continue;
        await client.query(
          `INSERT INTO daily_goal_progress (user_id, local_date, new_target, new_completed, review_target, review_pending, review_completed, goal_status, active_review_group_id)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT (user_id, local_date) DO UPDATE SET new_target=$3, new_completed=$4, review_target=$5, review_pending=$6, review_completed=$7, goal_status=$8, active_review_group_id=$9`,
          [userId, date, state.today_new_target, state.today_new_completed, state.today_review_target, state.today_review_pending, state.today_review_completed, state.daily_goal_status, state.active_review_group_id],
        );
      }

      for (const fe of (snapshot.feedRecords || []).filter(ownedBy)) {
        await client.query(
          `INSERT INTO feed_events (id, user_id, feed_item_type, consumed_amount, mood_delta, exp_delta, bond_delta, local_date, created_at)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT (id) DO NOTHING`,
          [fe.feed_id, userId, fe.feed_item_type, fe.consumed_amount, fe.mood_delta, fe.exp_delta, fe.bond_delta, fe.local_date, fe.created_at],
        );
      }

      // Secondary wallet (single-row per user; snapshot accumulators reflect
      // the primary user — for current user only).
      // β.5 limitation: dev-store snapshot.coinsSpent etc. is the primary
      // user's view, not necessarily this userId's. β.5b will add per-user
      // accumulator columns to snapshot. For now, only update wallet for
      // the primary user (DEV_USER_ID under permissive AUTH_ENFORCE=false).
      if (userId === DEV_USER_ID) {
        await client.query(
          `INSERT INTO secondary_wallets (user_id, coins_spent, feed_mood_accumulated, feed_exp_accumulated, feed_bond_accumulated, updated_at)
           VALUES ($1,$2,$3,$4,$5,NOW()) ON CONFLICT (user_id) DO UPDATE SET coins_spent=$2, feed_mood_accumulated=$3, feed_exp_accumulated=$4, feed_bond_accumulated=$5, updated_at=NOW()`,
          [userId, snapshot.coinsSpent || 0, snapshot.feedMoodAccumulated || 0, snapshot.feedExpAccumulated || 0, snapshot.feedBondAccumulated || 0],
        );
      }

      // ownedItems: legacy snapshot has no user_id field — only persist
      // for the primary user (DEV_USER_ID). β.5b will add user_id column.
      if (userId === DEV_USER_ID) {
        for (const oi of snapshot.ownedItems || []) {
          await client.query(
            `INSERT INTO inventory_items (user_id, item_id, item_type, slot, equipped, owned_at)
             VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (user_id, item_id) DO UPDATE SET equipped=$5`,
            [userId, oi.item_id, oi.item_type, oi.slot, oi.equipped || false, oi.owned_at],
          );
        }

        // Equipment slots — same single-user limit
        for (const [slot, itemId] of Object.entries(snapshot.equippedOutfit || {})) {
          if (itemId) {
            await client.query(
              `INSERT INTO equipment_slots (user_id, slot, item_type, item_id) VALUES ($1,$2,'outfit',$3) ON CONFLICT (user_id, slot, item_type) DO UPDATE SET item_id=$3, updated_at=NOW()`,
              [userId, slot, itemId],
            );
          }
        }
        for (const [slot, itemId] of Object.entries(snapshot.equippedRoom || {})) {
          if (itemId) {
            await client.query(
              `INSERT INTO equipment_slots (user_id, slot, item_type, item_id) VALUES ($1,$2,'room_item',$3) ON CONFLICT (user_id, slot, item_type) DO UPDATE SET item_id=$3, updated_at=NOW()`,
              [userId, slot, itemId],
            );
          }
        }
      }

      // Idempotency keys
      // 需求 23 / migration 009: PK changed from (key) to (user_id, key).
      for (const [key, record] of Object.entries<any>(snapshot.idempotencyKeys || {})) {
        if (!ownedBy(record)) continue;
        await client.query(
          `INSERT INTO idempotency_keys (key, user_id, path, response, created_at)
           VALUES ($1,$2,$3,$4,$5) ON CONFLICT (user_id, key) DO UPDATE SET response=$4`,
          [record.key || key, userId, record.path || '', JSON.stringify(record.response || {}), record.created_at || new Date().toISOString()],
        );
      }

      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  clear(userId: string = DEV_USER_ID): void {
    this.clearAsync(userId).catch(err => {
      console.error('[PgPersistence] Clear failed:', err);
    });
  }

  async clearAsync(userId: string = DEV_USER_ID): Promise<void> {
    // review_group_items has no user_id — delete via parent join
    await this.pool.query(
      `DELETE FROM review_group_items WHERE review_group_id IN (SELECT id FROM review_groups WHERE user_id = $1)`,
      [userId],
    ).catch(() => {});

    const clearTables = [
      'equipment_slots', 'inventory_items', 'purchase_records',
      'feed_events',
      'idempotency_keys', 'settlements', 'reward_ledger', 'reward_source_events',
      'learning_day_facts', 'check_in_records', 'session_records',
      'daily_goal_progress', 'review_attempts',
      'review_groups', 'study_attempts',
    ];
    for (const table of clearTables) {
      await this.pool.query(`DELETE FROM ${table} WHERE user_id = $1`, [userId]).catch(() => {});
    }
    // Reset wallet + streak to defaults
    await this.pool.query(
      `UPDATE secondary_wallets SET coins_spent=0, feed_mood_accumulated=0, feed_exp_accumulated=0, feed_bond_accumulated=0 WHERE user_id=$1`,
      [userId],
    ).catch(() => {});
    await this.pool.query(
      `UPDATE streak_records SET current_streak=0, last_check_in_date=NULL WHERE user_id=$1`,
      [userId],
    ).catch(() => {});
  }

  getPool(): Pool {
    return this.pool;
  }

  // ============================================================
  // 需求 23 Phase D PR-D-β: per-user backup snapshot persistence.
  //
  // These methods are INDEPENDENT of saveAsync / loadAsync — they
  // own the `backup_snapshots` PG table directly. BackupController
  // calls them so that backup cross-user reads don't depend on
  // dev-store in-memory lazy-load (β.5b deferred). Net effect:
  // server restart → backup data is durable; user A's POST →
  // user B's GET returns no_backup_yet because the row is keyed
  // by user_id PRIMARY KEY.
  //
  // Plan reference: plan-023-D-backup-restore-closure-v2.md §4.2
  // ============================================================

  /// Persist (UPSERT) the latest snapshot for [userId]. PRIMARY KEY
  /// is user_id, so each user owns exactly one slot — last-write-wins.
  async saveBackupForUser(
    userId: string,
    meta: {
      backupId: string;
      schemaVersion: string;
      uploadedAt: string;
      snapshotSize: number;
      deviceId?: string | null;
      deviceModel?: string | null;
      snapshot: unknown;
    },
  ): Promise<void> {
    await this.pool.query(
      `INSERT INTO backup_snapshots
         (user_id, backup_id, schema_version, uploaded_at,
          snapshot_size, device_id, device_model, snapshot, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
       ON CONFLICT (user_id) DO UPDATE SET
         backup_id      = EXCLUDED.backup_id,
         schema_version = EXCLUDED.schema_version,
         uploaded_at    = EXCLUDED.uploaded_at,
         snapshot_size  = EXCLUDED.snapshot_size,
         device_id      = EXCLUDED.device_id,
         device_model   = EXCLUDED.device_model,
         snapshot       = EXCLUDED.snapshot,
         updated_at     = NOW()`,
      [
        userId,
        meta.backupId,
        meta.schemaVersion,
        meta.uploadedAt,
        meta.snapshotSize,
        meta.deviceId ?? null,
        meta.deviceModel ?? null,
        JSON.stringify(meta.snapshot),
      ],
    );
  }

  /// Read metadata only for [userId] — no snapshot body. Used by
  /// GET /me/backup/latest where the client only wants status + ids.
  async loadBackupMetaForUser(userId: string): Promise<{
    backupId: string;
    schemaVersion: string;
    uploadedAt: string;
    snapshotSize: number;
    deviceId: string | null;
    deviceModel: string | null;
  } | null> {
    const result = await this.pool.query(
      `SELECT backup_id, schema_version, uploaded_at, snapshot_size,
              device_id, device_model
         FROM backup_snapshots
        WHERE user_id = $1`,
      [userId],
    );
    if (result.rows.length === 0) return null;
    const r = result.rows[0];
    return {
      backupId: r.backup_id,
      schemaVersion: r.schema_version,
      uploadedAt: r.uploaded_at?.toISOString?.() ?? r.uploaded_at,
      snapshotSize: r.snapshot_size,
      deviceId: r.device_id ?? null,
      deviceModel: r.device_model ?? null,
    };
  }

  /// Read full snapshot + meta for [userId]. Used by
  /// GET /me/backup/latest/snapshot during restore.
  async loadBackupFullForUser(userId: string): Promise<{
    backupId: string;
    schemaVersion: string;
    uploadedAt: string;
    snapshotSize: number;
    deviceId: string | null;
    deviceModel: string | null;
    snapshot: unknown;
  } | null> {
    const result = await this.pool.query(
      `SELECT backup_id, schema_version, uploaded_at, snapshot_size,
              device_id, device_model, snapshot
         FROM backup_snapshots
        WHERE user_id = $1`,
      [userId],
    );
    if (result.rows.length === 0) return null;
    const r = result.rows[0];
    return {
      backupId: r.backup_id,
      schemaVersion: r.schema_version,
      uploadedAt: r.uploaded_at?.toISOString?.() ?? r.uploaded_at,
      snapshotSize: r.snapshot_size,
      deviceId: r.device_id ?? null,
      deviceModel: r.device_model ?? null,
      // pg driver auto-parses JSONB to JS objects; if it's a string
      // (some test stubs), parse defensively.
      snapshot: typeof r.snapshot === 'string' ? JSON.parse(r.snapshot) : r.snapshot,
    };
  }

  /// Drop [userId]'s backup row (test helper, or admin / user-deletion
  /// flow). Not surfaced via REST in Phase D.
  async clearBackupForUser(userId: string): Promise<void> {
    await this.pool.query(
      `DELETE FROM backup_snapshots WHERE user_id = $1`,
      [userId],
    );
  }
}
