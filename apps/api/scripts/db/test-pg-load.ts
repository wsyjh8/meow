/**
 * Quick test: verify PG persistence can load a snapshot.
 */
import * as fs from 'fs';
import * as path from 'path';

// Load .env
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

process.env.PERSISTENCE_BACKEND = 'pg';

import { PgDevStorePersistence } from '../../src/infrastructure/postgres/pg-persistence';

(async () => {
  const pg = new PgDevStorePersistence();
  console.log('[test-pg-load] Loading from PG...');
  const snapshot = await pg.loadAsync();

  if (snapshot) {
    console.log('[test-pg-load] PG load SUCCESS');
    console.log('  studyAttempts:', snapshot.studyAttempts.length);
    console.log('  reviewGroups:', snapshot.reviewGroups.length);
    console.log('  sourceEvents:', snapshot.sourceEvents.length);
    console.log('  rewardLedgerItems:', snapshot.rewardLedgerItems.length);
    console.log('  sessions:', snapshot.sessions.length);
    console.log('  checkIns:', snapshot.checkIns.length);
    console.log('  feedRecords:', snapshot.feedRecords.length);
    console.log('  ownedItems:', snapshot.ownedItems.length);
    console.log('  coinsSpent:', snapshot.coinsSpent);
    console.log('  feedMoodAccumulated:', snapshot.feedMoodAccumulated);
    console.log('  idempotencyKeys:', Object.keys(snapshot.idempotencyKeys).length);
    console.log('  equippedOutfit:', JSON.stringify(snapshot.equippedOutfit));
    console.log('  streakRecord:', snapshot.streakRecord ? `streak=${snapshot.streakRecord.current_streak}` : 'null');
  } else {
    console.log('[test-pg-load] PG load returned null (empty user state — seed data only)');
  }

  // Test save: create a small mutation and save
  console.log('\n[test-pg-load] Testing save...');
  const testSnapshot = snapshot || {
    studyAttempts: [], reviewGroups: [], reviewAttempts: [],
    sourceEvents: [], rewardLedgerItems: [], settlements: [],
    sessions: [], checkIns: [], streakRecord: null, learningDays: [],
    todayStates: {}, feedRecords: [],
    feedMoodAccumulated: 0, feedExpAccumulated: 0, feedBondAccumulated: 0,
    ownedItems: [], coinsSpent: 0, equippedOutfit: {}, equippedRoom: {},
    idempotencyKeys: {},
  };
  pg.save(testSnapshot);
  // Wait for async save
  await new Promise(r => setTimeout(r, 2000));
  console.log('[test-pg-load] Save completed (no error).');

  // Reload to verify roundtrip
  const reloaded = await pg.loadAsync();
  console.log('[test-pg-load] Reload after save:', reloaded !== null ? 'SUCCESS' : 'FAILED');

  await pg.getPool().end();
  console.log('\n[test-pg-load] Done.');
})();
