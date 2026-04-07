/**
 * JSON → PostgreSQL Import Script (Option A A3).
 *
 * Reads the current DevStore JSON snapshot and imports all user-state
 * data into PostgreSQL tables. Static/seed data (users, words, catalog)
 * are skipped if already present (ON CONFLICT DO NOTHING).
 *
 * Usage: npx ts-node scripts/db/import-json.ts [--validate]
 */

import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';

// ========== Env loading ==========
const envPath = path.resolve(__dirname, '..', '..', '.env');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf-8');
  for (const line of envContent.split('\n')) {
    const trimmed = line.trim();
    if (trimmed && !trimmed.startsWith('#')) {
      const eqIdx = trimmed.indexOf('=');
      if (eqIdx > 0) {
        const key = trimmed.substring(0, eqIdx);
        const value = trimmed.substring(eqIdx + 1);
        if (!process.env[key]) process.env[key] = value;
      }
    }
  }
}

const DEV_USER_ID = 'dev-user-001';
const DEV_BOOK_ID = 'book-001';

interface ImportReport {
  table: string;
  imported: number;
  skipped: number;
  errors: string[];
}

const report: ImportReport[] = [];

function addReport(table: string, imported: number, skipped = 0, errors: string[] = []) {
  report.push({ table, imported, skipped, errors });
  const status = errors.length > 0 ? 'ERRORS' : imported > 0 ? 'OK' : 'SKIP';
  console.log(`  [${status}] ${table}: ${imported} imported, ${skipped} skipped${errors.length ? ', ' + errors.length + ' errors' : ''}`);
}

async function importJson(pool: Pool, snapshotPath: string) {
  if (!fs.existsSync(snapshotPath)) {
    console.log(`[import] No JSON snapshot found at ${snapshotPath}. Nothing to import.`);
    addReport('(no snapshot)', 0, 0, ['File not found: ' + snapshotPath]);
    return;
  }

  const raw = fs.readFileSync(snapshotPath, 'utf-8');
  const snapshot = JSON.parse(raw);

  console.log('[import] Starting JSON → PostgreSQL import...\n');

  // ========== Layer 1: Static (already seeded, verify/skip) ==========

  // Users — ensure dev user exists
  try {
    const r = await pool.query(
      `INSERT INTO users (id) VALUES ($1) ON CONFLICT (id) DO NOTHING RETURNING id`,
      [DEV_USER_ID],
    );
    addReport('users', r.rowCount ?? 0, r.rowCount === 0 ? 1 : 0);
  } catch (e: any) { addReport('users', 0, 0, [e.message]); }

  // word_books + words + shop_catalog_items — already seeded, skip
  addReport('word_books', 0, 1, []); // already seeded
  addReport('words', 0, 1, []);
  addReport('shop_catalog_items', 0, 1, []);
  addReport('user_book_settings', 0, 1, []);

  // ========== Layer 2: Main mechanism facts ==========

  // study_attempts
  const studyAttempts = snapshot.studyAttempts || [];
  let saCount = 0;
  for (const sa of studyAttempts) {
    try {
      await pool.query(
        `INSERT INTO study_attempts (id, user_id, word_id, book_id, study_type, action_result, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7) ON CONFLICT (id) DO NOTHING`,
        [sa.id, sa.user_id || DEV_USER_ID, sa.word_id, sa.book_id, sa.study_type, sa.action_result, sa.created_at],
      );
      saCount++;
    } catch (e: any) { /* skip FK violations for non-existent words */ }
  }
  addReport('study_attempts', saCount, studyAttempts.length - saCount);

  // review_groups + review_group_items
  const reviewGroups = snapshot.reviewGroups || [];
  let rgCount = 0, rgiCount = 0;
  for (const rg of reviewGroups) {
    try {
      await pool.query(
        `INSERT INTO review_groups (id, user_id, group_status, group_completed, created_at, completed_at)
         VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (id) DO NOTHING`,
        [rg.review_group_id, rg.user_id || DEV_USER_ID, rg.group_status, rg.group_completed, rg.created_at, rg.completed_at || null],
      );
      rgCount++;
      // Items
      for (const item of (rg.items || [])) {
        try {
          await pool.query(
            `INSERT INTO review_group_items (review_group_id, word_id, word_text, meaning, completed)
             VALUES ($1, $2, $3, $4, $5) ON CONFLICT (review_group_id, word_id) DO NOTHING`,
            [rg.review_group_id, item.word_id, item.word_text, item.meaning, item.completed],
          );
          rgiCount++;
        } catch { /* skip */ }
      }
    } catch (e: any) { /* skip */ }
  }
  addReport('review_groups', rgCount);
  addReport('review_group_items', rgiCount);

  // review_attempts
  const reviewAttempts = snapshot.reviewAttempts || [];
  let raCount = 0;
  for (const ra of reviewAttempts) {
    try {
      await pool.query(
        `INSERT INTO review_attempts (id, user_id, review_group_id, word_id, action_result, created_at)
         VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (id) DO NOTHING`,
        [ra.id, ra.user_id || DEV_USER_ID, ra.review_group_id, ra.word_id, ra.action_result, ra.created_at],
      );
      raCount++;
    } catch { /* skip FK */ }
  }
  addReport('review_attempts', raCount, reviewAttempts.length - raCount);

  // daily_goal_progress (from todayStates)
  const todayStates = snapshot.todayStates || {};
  let dgCount = 0;
  for (const [date, state] of Object.entries<any>(todayStates)) {
    try {
      await pool.query(
        `INSERT INTO daily_goal_progress (user_id, local_date, new_target, new_completed, review_target, review_pending, review_completed, goal_status, active_review_group_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) ON CONFLICT (user_id, local_date) DO NOTHING`,
        [DEV_USER_ID, date, state.today_new_target, state.today_new_completed, state.today_review_target, state.today_review_pending, state.today_review_completed, state.daily_goal_status, state.active_review_group_id],
      );
      dgCount++;
    } catch { /* skip */ }
  }
  addReport('daily_goal_progress', dgCount);

  // session_records
  const sessions = snapshot.sessions || [];
  let sessCount = 0;
  for (const s of sessions) {
    try {
      await pool.query(
        `INSERT INTO session_records (id, user_id, session_status, validation_status, minutes_target, started_at, ended_at, actual_minutes, effective_learning_count, effective_review_count)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) ON CONFLICT (id) DO NOTHING`,
        [s.session_id, s.user_id || DEV_USER_ID, s.session_status, s.session_validation_status, s.session_minutes_target, s.started_at, s.ended_at || null, s.actual_minutes || null, s.effective_learning_count, s.effective_review_count],
      );
      sessCount++;
    } catch { /* skip */ }
  }
  addReport('session_records', sessCount);

  // check_in_records
  const checkIns = snapshot.checkIns || [];
  let ciCount = 0;
  for (const ci of checkIns) {
    try {
      await pool.query(
        `INSERT INTO check_in_records (id, user_id, local_date, status, created_at)
         VALUES ($1, $2, $3, $4, $5) ON CONFLICT (user_id, local_date) DO NOTHING`,
        [ci.check_in_id, ci.user_id || DEV_USER_ID, ci.local_date, ci.check_in_status, ci.created_at],
      );
      ciCount++;
    } catch { /* skip */ }
  }
  addReport('check_in_records', ciCount);

  // learning_day_facts
  const learningDays = snapshot.learningDays || [];
  let ldCount = 0;
  for (const ld of learningDays) {
    try {
      await pool.query(
        `INSERT INTO learning_day_facts (user_id, local_date, is_learning_day, effective_learning_count, effective_review_count, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (user_id, local_date) DO NOTHING`,
        [ld.user_id || DEV_USER_ID, ld.local_date, ld.learning_day, ld.effective_learning_count, ld.effective_review_count, ld.updated_at],
      );
      ldCount++;
    } catch { /* skip */ }
  }
  addReport('learning_day_facts', ldCount);

  // streak_records
  const streak = snapshot.streakRecord;
  if (streak) {
    try {
      await pool.query(
        `INSERT INTO streak_records (user_id, current_streak, streak_basis_type, last_check_in_date, updated_at)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (user_id) DO UPDATE SET current_streak=$2, streak_basis_type=$3, last_check_in_date=$4, updated_at=$5`,
        [streak.user_id || DEV_USER_ID, streak.current_streak, streak.streak_basis_type, streak.last_check_in_date || null, streak.updated_at],
      );
      addReport('streak_records', 1);
    } catch (e: any) { addReport('streak_records', 0, 0, [e.message]); }
  } else {
    addReport('streak_records', 0, 1);
  }

  // ========== Layer 3: Reward + Secondary ==========

  // reward_source_events
  const sourceEvents = snapshot.sourceEvents || [];
  let seCount = 0;
  for (const se of sourceEvents) {
    try {
      await pool.query(
        `INSERT INTO reward_source_events (id, user_id, event_type, source_ref_id, created_at)
         VALUES ($1, $2, $3, $4, $5) ON CONFLICT (id) DO NOTHING`,
        [se.source_event_id, se.user_id || DEV_USER_ID, se.source_event_type, se.source_ref_id, se.created_at],
      );
      seCount++;
    } catch { /* skip */ }
  }
  addReport('reward_source_events', seCount);

  // reward_ledger
  const ledgerItems = snapshot.rewardLedgerItems || [];
  let rlCount = 0;
  for (const ri of ledgerItems) {
    try {
      await pool.query(
        `INSERT INTO reward_ledger (id, source_event_id, user_id, reward_type, amount, reward_status, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7) ON CONFLICT (id) DO NOTHING`,
        [ri.reward_item_id, ri.source_event_id, ri.user_id || DEV_USER_ID, ri.reward_type, ri.amount, ri.reward_status, ri.created_at],
      );
      rlCount++;
    } catch { /* skip */ }
  }
  addReport('reward_ledger', rlCount);

  // settlements
  const settlements = snapshot.settlements || [];
  let stCount = 0;
  for (const st of settlements) {
    try {
      await pool.query(
        `INSERT INTO settlements (id, source_event_id, user_id, settlement_status, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (id) DO NOTHING`,
        [st.settlement_id, st.source_event_id, st.user_id || DEV_USER_ID, st.reward_settlement_status, st.created_at, st.updated_at],
      );
      stCount++;
    } catch { /* skip */ }
  }
  addReport('settlements', stCount);

  // idempotency_keys
  const idemKeys = snapshot.idempotencyKeys || {};
  let ikCount = 0;
  for (const [key, record] of Object.entries<any>(idemKeys)) {
    try {
      await pool.query(
        `INSERT INTO idempotency_keys (key, user_id, path, response, created_at)
         VALUES ($1, $2, $3, $4, $5) ON CONFLICT (key) DO NOTHING`,
        [record.key || key, record.user_id || DEV_USER_ID, record.path || '', JSON.stringify(record.response || {}), record.created_at || new Date().toISOString()],
      );
      ikCount++;
    } catch { /* skip */ }
  }
  addReport('idempotency_keys', ikCount);

  // secondary_wallets (update existing)
  try {
    await pool.query(
      `UPDATE secondary_wallets SET coins_spent=$1, feed_mood_accumulated=$2, feed_exp_accumulated=$3, feed_bond_accumulated=$4, updated_at=NOW()
       WHERE user_id=$5`,
      [snapshot.coinsSpent || 0, snapshot.feedMoodAccumulated || 0, snapshot.feedExpAccumulated || 0, snapshot.feedBondAccumulated || 0, DEV_USER_ID],
    );
    addReport('secondary_wallets', 1);
  } catch (e: any) { addReport('secondary_wallets', 0, 0, [e.message]); }

  // feed_events
  const feedRecords = snapshot.feedRecords || [];
  let feCount = 0;
  for (const fe of feedRecords) {
    try {
      await pool.query(
        `INSERT INTO feed_events (id, user_id, feed_item_type, consumed_amount, mood_delta, exp_delta, bond_delta, local_date, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) ON CONFLICT (id) DO NOTHING`,
        [fe.feed_id, fe.user_id || DEV_USER_ID, fe.feed_item_type, fe.consumed_amount, fe.mood_delta, fe.exp_delta, fe.bond_delta, fe.local_date, fe.created_at],
      );
      feCount++;
    } catch { /* skip */ }
  }
  addReport('feed_events', feCount);

  // inventory_items
  const ownedItems = snapshot.ownedItems || [];
  let invCount = 0;
  for (const oi of ownedItems) {
    try {
      await pool.query(
        `INSERT INTO inventory_items (user_id, item_id, item_type, slot, equipped, owned_at)
         VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (user_id, item_id) DO NOTHING`,
        [DEV_USER_ID, oi.item_id, oi.item_type, oi.slot, oi.equipped || false, oi.owned_at],
      );
      invCount++;
    } catch { /* skip */ }
  }
  addReport('inventory_items', invCount);

  // equipment_slots
  const equippedOutfit = snapshot.equippedOutfit || {};
  const equippedRoom = snapshot.equippedRoom || {};
  let eqCount = 0;
  for (const [slot, itemId] of Object.entries(equippedOutfit)) {
    if (itemId) {
      try {
        await pool.query(
          `INSERT INTO equipment_slots (user_id, slot, item_type, item_id)
           VALUES ($1, $2, 'outfit', $3) ON CONFLICT (user_id, slot, item_type) DO UPDATE SET item_id=$3, updated_at=NOW()`,
          [DEV_USER_ID, slot, itemId],
        );
        eqCount++;
      } catch { /* skip */ }
    }
  }
  for (const [slot, itemId] of Object.entries(equippedRoom)) {
    if (itemId) {
      try {
        await pool.query(
          `INSERT INTO equipment_slots (user_id, slot, item_type, item_id)
           VALUES ($1, $2, 'room_item', $3) ON CONFLICT (user_id, slot, item_type) DO UPDATE SET item_id=$3, updated_at=NOW()`,
          [DEV_USER_ID, slot, itemId],
        );
        eqCount++;
      } catch { /* skip */ }
    }
  }
  addReport('equipment_slots', eqCount);

  // purchase_records — not tracked separately in JSON, but owned_items implies purchases
  addReport('purchase_records', 0, 1, []); // reconstructable from inventory + coinsSpent

  console.log('\n[import] Import complete.\n');
}

// ========== Validation ==========

async function validate(pool: Pool, snapshotPath: string) {
  console.log('[validate] Running parity checks...\n');
  const raw = fs.readFileSync(snapshotPath, 'utf-8');
  const snapshot = JSON.parse(raw);
  const checks: { name: string; pass: boolean; detail: string }[] = [];

  // Count checks
  async function countCheck(name: string, jsonArr: any[], pgTable: string) {
    const pgResult = await pool.query(`SELECT COUNT(*)::int AS count FROM ${pgTable}`);
    const pgCount = pgResult.rows[0].count;
    const jsonCount = jsonArr.length;
    const pass = pgCount >= jsonCount;
    checks.push({ name: `${name} count`, pass, detail: `JSON=${jsonCount}, PG=${pgCount}` });
  }

  await countCheck('study_attempts', snapshot.studyAttempts || [], 'study_attempts');
  await countCheck('review_groups', snapshot.reviewGroups || [], 'review_groups');
  await countCheck('review_attempts', snapshot.reviewAttempts || [], 'review_attempts');
  await countCheck('sessions', snapshot.sessions || [], 'session_records');
  await countCheck('check_ins', snapshot.checkIns || [], 'check_in_records');
  await countCheck('learning_days', snapshot.learningDays || [], 'learning_day_facts');
  await countCheck('source_events', snapshot.sourceEvents || [], 'reward_source_events');
  await countCheck('reward_ledger', snapshot.rewardLedgerItems || [], 'reward_ledger');
  await countCheck('settlements', snapshot.settlements || [], 'settlements');
  await countCheck('feed_events', snapshot.feedRecords || [], 'feed_events');
  await countCheck('inventory_items', snapshot.ownedItems || [], 'inventory_items');

  // Idempotency keys count
  const ikJson = Object.keys(snapshot.idempotencyKeys || {}).length;
  const ikPg = (await pool.query('SELECT COUNT(*)::int AS count FROM idempotency_keys')).rows[0].count;
  checks.push({ name: 'idempotency_keys count', pass: ikPg >= ikJson, detail: `JSON=${ikJson}, PG=${ikPg}` });

  // Balance parity — coins
  const ledgerCoins = (await pool.query(
    `SELECT COALESCE(SUM(amount),0)::int AS total FROM reward_ledger WHERE user_id=$1 AND reward_type='coins' AND reward_status='succeeded'`,
    [DEV_USER_ID],
  )).rows[0].total;
  const walletCoinsSpent = (await pool.query(
    `SELECT coins_spent FROM secondary_wallets WHERE user_id=$1`,
    [DEV_USER_ID],
  )).rows[0]?.coins_spent || 0;
  const pgCoinsBalance = ledgerCoins - walletCoinsSpent;

  const jsonLedgerCoins = (snapshot.rewardLedgerItems || [])
    .filter((r: any) => r.reward_type === 'coins' && r.reward_status === 'succeeded')
    .reduce((sum: number, r: any) => sum + r.amount, 0);
  const jsonCoinsBalance = jsonLedgerCoins - (snapshot.coinsSpent || 0);

  checks.push({ name: 'coins_balance parity', pass: pgCoinsBalance === jsonCoinsBalance, detail: `JSON=${jsonCoinsBalance}, PG=${pgCoinsBalance}` });

  // Fish treats parity
  const ledgerFish = (await pool.query(
    `SELECT COALESCE(SUM(amount),0)::int AS total FROM reward_ledger WHERE user_id=$1 AND reward_type='fish_treats' AND reward_status='succeeded'`,
    [DEV_USER_ID],
  )).rows[0].total;
  const feedConsumed = (await pool.query(
    `SELECT COALESCE(SUM(consumed_amount),0)::int AS total FROM feed_events WHERE user_id=$1`,
    [DEV_USER_ID],
  )).rows[0].total;
  const pgFishBalance = ledgerFish - feedConsumed;

  const jsonLedgerFish = (snapshot.rewardLedgerItems || [])
    .filter((r: any) => r.reward_type === 'fish_treats' && r.reward_status === 'succeeded')
    .reduce((sum: number, r: any) => sum + r.amount, 0);
  const jsonFeedConsumed = (snapshot.feedRecords || []).reduce((sum: number, r: any) => sum + r.consumed_amount, 0);
  const jsonFishBalance = jsonLedgerFish - jsonFeedConsumed;

  checks.push({ name: 'fish_treats_balance parity', pass: pgFishBalance === jsonFishBalance, detail: `JSON=${jsonFishBalance}, PG=${pgFishBalance}` });

  // Pet state parity
  const wallet = (await pool.query(`SELECT * FROM secondary_wallets WHERE user_id=$1`, [DEV_USER_ID])).rows[0];
  if (wallet) {
    checks.push({ name: 'feed_mood_accumulated', pass: wallet.feed_mood_accumulated === (snapshot.feedMoodAccumulated || 0), detail: `JSON=${snapshot.feedMoodAccumulated || 0}, PG=${wallet.feed_mood_accumulated}` });
    checks.push({ name: 'feed_exp_accumulated', pass: wallet.feed_exp_accumulated === (snapshot.feedExpAccumulated || 0), detail: `JSON=${snapshot.feedExpAccumulated || 0}, PG=${wallet.feed_exp_accumulated}` });
    checks.push({ name: 'feed_bond_accumulated', pass: wallet.feed_bond_accumulated === (snapshot.feedBondAccumulated || 0), detail: `JSON=${snapshot.feedBondAccumulated || 0}, PG=${wallet.feed_bond_accumulated}` });
  }

  // Equipment parity
  const pgEquip = (await pool.query(`SELECT slot, item_type, item_id FROM equipment_slots WHERE user_id=$1 AND item_id IS NOT NULL`, [DEV_USER_ID])).rows;
  const jsonEquipCount = Object.values(snapshot.equippedOutfit || {}).filter(Boolean).length + Object.values(snapshot.equippedRoom || {}).filter(Boolean).length;
  checks.push({ name: 'equipment_slots count', pass: pgEquip.length === jsonEquipCount, detail: `JSON=${jsonEquipCount}, PG=${pgEquip.length}` });

  // Streak parity
  if (snapshot.streakRecord) {
    const pgStreak = (await pool.query(`SELECT current_streak FROM streak_records WHERE user_id=$1`, [DEV_USER_ID])).rows[0];
    checks.push({ name: 'streak parity', pass: pgStreak?.current_streak === snapshot.streakRecord.current_streak, detail: `JSON=${snapshot.streakRecord.current_streak}, PG=${pgStreak?.current_streak}` });
  }

  // Print results
  let allPass = true;
  for (const c of checks) {
    const icon = c.pass ? 'PASS' : 'FAIL';
    if (!c.pass) allPass = false;
    console.log(`  [${icon}] ${c.name}: ${c.detail}`);
  }

  console.log(`\n[validate] ${checks.filter(c => c.pass).length}/${checks.length} checks passed.`);
  if (!allPass) {
    console.log('[validate] WARNING: Some parity checks failed. Review before proceeding to A4.');
  } else {
    console.log('[validate] All parity checks passed. Ready for A4.');
  }

  return { checks, allPass };
}

// ========== Main ==========

(async () => {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  const snapshotPath = process.env.DEV_STORE_PERSIST_PATH
    || path.resolve(__dirname, '..', '..', 'data', 'dev-store-state.json');
  const doValidate = process.argv.includes('--validate');

  try {
    await importJson(pool, snapshotPath);

    console.log('\n--- Import Report ---');
    let totalImported = 0;
    for (const r of report) {
      totalImported += r.imported;
      if (r.errors.length > 0) {
        console.log(`  ${r.table}: ${r.imported} imported, ${r.errors.length} errors`);
      }
    }
    console.log(`Total rows imported: ${totalImported}`);
    console.log(`Tables processed: ${report.length}`);

    if (doValidate) {
      console.log('\n');
      await validate(pool, snapshotPath);
    }
  } catch (err) {
    console.error('[import] Fatal error:', err);
    process.exit(1);
  } finally {
    await pool.end();
  }
})();

export { importJson, validate };
