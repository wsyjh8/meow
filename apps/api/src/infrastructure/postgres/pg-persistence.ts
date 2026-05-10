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

// 需求 23 Phase A4-α: pg-persistence still loads / saves a single user's
// snapshot (this constant). Multi-user load/save requires partitioning the
// in-memory DevStore state by userId — that's A4-β scope. Under permissive
// AUTH_ENFORCE=false, every request resolves to DEV_USER_ID anyway, so the
// effective behavior is correct. Under AUTH_ENFORCE=true with multiple
// users, A4-β must change this to load/save per-user snapshots on demand.
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
   * Async load — reconstructs DevStoreSnapshot from PG tables.
   */
  async loadAsync(): Promise<DevStoreSnapshot | null> {
    try {
      // Check if user exists
      const userCheck = await this.pool.query('SELECT id FROM users WHERE id = $1', [DEV_USER_ID]);
      if (userCheck.rows.length === 0) return null;

      const [
        studyAttemptsR, reviewGroupsR, reviewAttemptsR,
        sourceEventsR, rewardLedgerR, settlementsR,
        sessionsR, checkInsR, streakR, learningDaysR,
        dailyGoalR, feedEventsR, walletR, ownedItemsR,
        equipmentR, idempotencyR,
      ] = await Promise.all([
        this.pool.query('SELECT * FROM study_attempts WHERE user_id = $1 ORDER BY created_at', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM review_groups WHERE user_id = $1 ORDER BY created_at', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM review_attempts WHERE user_id = $1 ORDER BY created_at', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM reward_source_events WHERE user_id = $1 ORDER BY created_at', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM reward_ledger WHERE user_id = $1 ORDER BY created_at', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM settlements WHERE user_id = $1 ORDER BY created_at', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM session_records WHERE user_id = $1 ORDER BY created_at', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM check_in_records WHERE user_id = $1 ORDER BY created_at', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM streak_records WHERE user_id = $1', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM learning_day_facts WHERE user_id = $1', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM daily_goal_progress WHERE user_id = $1', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM feed_events WHERE user_id = $1 ORDER BY created_at', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM secondary_wallets WHERE user_id = $1', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM inventory_items WHERE user_id = $1', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM equipment_slots WHERE user_id = $1', [DEV_USER_ID]),
        this.pool.query('SELECT * FROM idempotency_keys WHERE user_id = $1', [DEV_USER_ID]),
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
          user_id: DEV_USER_ID,
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

  async saveAsync(snapshot: DevStoreSnapshot): Promise<void> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Clear user-state tables (order: reverse FK dependencies)
      // Delete review_group_items via parent join (no user_id column)
      await client.query(
        `DELETE FROM review_group_items WHERE review_group_id IN (SELECT id FROM review_groups WHERE user_id = $1)`,
        [DEV_USER_ID],
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
        await client.query(`DELETE FROM ${table} WHERE user_id = $1`, [DEV_USER_ID]);
      }
      // These tables need special handling (UPDATE instead of DELETE for seeded rows)
      await client.query(`UPDATE streak_records SET current_streak=0, last_check_in_date=NULL, updated_at=NOW() WHERE user_id=$1`, [DEV_USER_ID]);
      await client.query(`UPDATE secondary_wallets SET coins_spent=0, feed_mood_accumulated=0, feed_exp_accumulated=0, feed_bond_accumulated=0, updated_at=NOW() WHERE user_id=$1`, [DEV_USER_ID]);

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

      for (const sa of snapshot.studyAttempts || []) {
        await tryInsert(
          `INSERT INTO study_attempts (id, user_id, word_id, book_id, study_type, action_result, created_at)
           VALUES ($1,$2,$3,$4,$5,$6,$7) ON CONFLICT (id) DO NOTHING`,
          [sa.id, sa.user_id || DEV_USER_ID, sa.word_id, sa.book_id, sa.study_type, sa.action_result, sa.created_at],
        );
      }

      for (const rg of snapshot.reviewGroups || []) {
        await tryInsert(
          `INSERT INTO review_groups (id, user_id, group_status, group_completed, created_at, completed_at)
           VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (id) DO NOTHING`,
          [rg.review_group_id, rg.user_id || DEV_USER_ID, rg.group_status, rg.group_completed, rg.created_at, rg.completed_at || null],
        );
        for (const item of rg.items || []) {
          await tryInsert(
            `INSERT INTO review_group_items (review_group_id, word_id, word_text, meaning, completed)
             VALUES ($1,$2,$3,$4,$5) ON CONFLICT (review_group_id, word_id) DO NOTHING`,
            [rg.review_group_id, item.word_id, item.word_text, item.meaning, item.completed],
          );
        }
      }

      for (const ra of snapshot.reviewAttempts || []) {
        await tryInsert(
          `INSERT INTO review_attempts (id, user_id, review_group_id, word_id, action_result, created_at)
           VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (id) DO NOTHING`,
          [ra.id, ra.user_id || DEV_USER_ID, ra.review_group_id, ra.word_id, ra.action_result, ra.created_at],
        );
      }

      for (const se of snapshot.sourceEvents || []) {
        await tryInsert(
          `INSERT INTO reward_source_events (id, user_id, event_type, source_ref_id, created_at)
           VALUES ($1,$2,$3,$4,$5) ON CONFLICT (id) DO NOTHING`,
          [se.source_event_id, se.user_id || DEV_USER_ID, se.source_event_type, se.source_ref_id, se.created_at],
        );
      }

      for (const ri of snapshot.rewardLedgerItems || []) {
        await tryInsert(
          `INSERT INTO reward_ledger (id, source_event_id, user_id, reward_type, amount, reward_status, created_at)
           VALUES ($1,$2,$3,$4,$5,$6,$7) ON CONFLICT (id) DO NOTHING`,
          [ri.reward_item_id, ri.source_event_id, ri.user_id || DEV_USER_ID, ri.reward_type, ri.amount, ri.reward_status, ri.created_at],
        );
      }

      for (const st of snapshot.settlements || []) {
        await tryInsert(
          `INSERT INTO settlements (id, source_event_id, user_id, settlement_status, created_at, updated_at)
           VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (id) DO NOTHING`,
          [st.settlement_id, st.source_event_id, st.user_id || DEV_USER_ID, st.reward_settlement_status, st.created_at, st.updated_at],
        );
      }

      for (const s of snapshot.sessions || []) {
        await client.query(
          `INSERT INTO session_records (id, user_id, session_status, validation_status, minutes_target, started_at, ended_at, actual_minutes, effective_learning_count, effective_review_count)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) ON CONFLICT (id) DO NOTHING`,
          [s.session_id, s.user_id || DEV_USER_ID, s.session_status, s.session_validation_status, s.session_minutes_target, s.started_at, s.ended_at || null, s.actual_minutes || null, s.effective_learning_count, s.effective_review_count],
        );
      }

      for (const ci of snapshot.checkIns || []) {
        await client.query(
          `INSERT INTO check_in_records (id, user_id, local_date, status, created_at)
           VALUES ($1,$2,$3,$4,$5) ON CONFLICT (user_id, local_date) DO NOTHING`,
          [ci.check_in_id, ci.user_id || DEV_USER_ID, ci.local_date, ci.check_in_status, ci.created_at],
        );
      }

      for (const ld of snapshot.learningDays || []) {
        await client.query(
          `INSERT INTO learning_day_facts (user_id, local_date, is_learning_day, effective_learning_count, effective_review_count, updated_at)
           VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (user_id, local_date) DO UPDATE SET is_learning_day=$3, effective_learning_count=$4, effective_review_count=$5, updated_at=$6`,
          [ld.user_id || DEV_USER_ID, ld.local_date, ld.learning_day, ld.effective_learning_count, ld.effective_review_count, ld.updated_at],
        );
      }

      if (snapshot.streakRecord) {
        await client.query(
          `INSERT INTO streak_records (user_id, current_streak, streak_basis_type, last_check_in_date, updated_at)
           VALUES ($1,$2,$3,$4,$5) ON CONFLICT (user_id) DO UPDATE SET current_streak=$2, streak_basis_type=$3, last_check_in_date=$4, updated_at=$5`,
          [snapshot.streakRecord.user_id || DEV_USER_ID, snapshot.streakRecord.current_streak, snapshot.streakRecord.streak_basis_type, snapshot.streakRecord.last_check_in_date || null, snapshot.streakRecord.updated_at],
        );
      }

      for (const [date, state] of Object.entries<any>(snapshot.todayStates || {})) {
        await client.query(
          `INSERT INTO daily_goal_progress (user_id, local_date, new_target, new_completed, review_target, review_pending, review_completed, goal_status, active_review_group_id)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT (user_id, local_date) DO UPDATE SET new_target=$3, new_completed=$4, review_target=$5, review_pending=$6, review_completed=$7, goal_status=$8, active_review_group_id=$9`,
          [DEV_USER_ID, date, state.today_new_target, state.today_new_completed, state.today_review_target, state.today_review_pending, state.today_review_completed, state.daily_goal_status, state.active_review_group_id],
        );
      }

      for (const fe of snapshot.feedRecords || []) {
        await client.query(
          `INSERT INTO feed_events (id, user_id, feed_item_type, consumed_amount, mood_delta, exp_delta, bond_delta, local_date, created_at)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT (id) DO NOTHING`,
          [fe.feed_id, fe.user_id || DEV_USER_ID, fe.feed_item_type, fe.consumed_amount, fe.mood_delta, fe.exp_delta, fe.bond_delta, fe.local_date, fe.created_at],
        );
      }

      // Secondary wallet
      await client.query(
        `INSERT INTO secondary_wallets (user_id, coins_spent, feed_mood_accumulated, feed_exp_accumulated, feed_bond_accumulated, updated_at)
         VALUES ($1,$2,$3,$4,$5,NOW()) ON CONFLICT (user_id) DO UPDATE SET coins_spent=$2, feed_mood_accumulated=$3, feed_exp_accumulated=$4, feed_bond_accumulated=$5, updated_at=NOW()`,
        [DEV_USER_ID, snapshot.coinsSpent || 0, snapshot.feedMoodAccumulated || 0, snapshot.feedExpAccumulated || 0, snapshot.feedBondAccumulated || 0],
      );

      for (const oi of snapshot.ownedItems || []) {
        await client.query(
          `INSERT INTO inventory_items (user_id, item_id, item_type, slot, equipped, owned_at)
           VALUES ($1,$2,$3,$4,$5,$6) ON CONFLICT (user_id, item_id) DO UPDATE SET equipped=$5`,
          [DEV_USER_ID, oi.item_id, oi.item_type, oi.slot, oi.equipped || false, oi.owned_at],
        );
      }

      // Equipment slots
      for (const [slot, itemId] of Object.entries(snapshot.equippedOutfit || {})) {
        if (itemId) {
          await client.query(
            `INSERT INTO equipment_slots (user_id, slot, item_type, item_id) VALUES ($1,$2,'outfit',$3) ON CONFLICT (user_id, slot, item_type) DO UPDATE SET item_id=$3, updated_at=NOW()`,
            [DEV_USER_ID, slot, itemId],
          );
        }
      }
      for (const [slot, itemId] of Object.entries(snapshot.equippedRoom || {})) {
        if (itemId) {
          await client.query(
            `INSERT INTO equipment_slots (user_id, slot, item_type, item_id) VALUES ($1,$2,'room_item',$3) ON CONFLICT (user_id, slot, item_type) DO UPDATE SET item_id=$3, updated_at=NOW()`,
            [DEV_USER_ID, slot, itemId],
          );
        }
      }

      // Idempotency keys
      // 需求 23 / migration 009: PK changed from (key) to (user_id, key).
      // ON CONFLICT target must match the new PK columns.
      for (const [key, record] of Object.entries<any>(snapshot.idempotencyKeys || {})) {
        await client.query(
          `INSERT INTO idempotency_keys (key, user_id, path, response, created_at)
           VALUES ($1,$2,$3,$4,$5) ON CONFLICT (user_id, key) DO UPDATE SET response=$4`,
          [record.key || key, record.user_id || DEV_USER_ID, record.path || '', JSON.stringify(record.response || {}), record.created_at || new Date().toISOString()],
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

  clear(): void {
    this.clearAsync().catch(err => {
      console.error('[PgPersistence] Clear failed:', err);
    });
  }

  async clearAsync(): Promise<void> {
    // review_group_items has no user_id — delete via parent join
    await this.pool.query(
      `DELETE FROM review_group_items WHERE review_group_id IN (SELECT id FROM review_groups WHERE user_id = $1)`,
      [DEV_USER_ID],
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
      await this.pool.query(`DELETE FROM ${table} WHERE user_id = $1`, [DEV_USER_ID]).catch(() => {});
    }
    // Reset wallet + streak to defaults
    await this.pool.query(
      `UPDATE secondary_wallets SET coins_spent=0, feed_mood_accumulated=0, feed_exp_accumulated=0, feed_bond_accumulated=0 WHERE user_id=$1`,
      [DEV_USER_ID],
    ).catch(() => {});
    await this.pool.query(
      `UPDATE streak_records SET current_streak=0, last_check_in_date=NULL WHERE user_id=$1`,
      [DEV_USER_ID],
    ).catch(() => {});
  }

  getPool(): Pool {
    return this.pool;
  }
}
