/**
 * PG Restore Script (Option A A5).
 *
 * Restores PG state from a JSON backup snapshot.
 * WARNING: This replaces current PG user state with the backup.
 *
 * Usage: npx ts-node scripts/db/restore.ts <backup-path>
 */

import * as fs from 'fs';
import * as path from 'path';

// Load .env
const envPath = path.resolve(__dirname, '..', '..', '.env');
if (fs.existsSync(envPath)) {
  for (const line of fs.readFileSync(envPath, 'utf-8').split('\n')) {
    const t = line.trim();
    if (t && !t.startsWith('#')) {
      const eq = t.indexOf('=');
      if (eq > 0 && !process.env[t.substring(0, eq)]) {
        process.env[t.substring(0, eq)] = t.substring(eq + 1);
      }
    }
  }
}

import { PgDevStorePersistence } from '../../src/infrastructure/postgres/pg-persistence';
import { DevStoreSnapshot } from '../../src/domain/persistence';

(async () => {
  const backupPath = process.argv[2];
  if (!backupPath) {
    console.error('Usage: npx ts-node scripts/db/restore.ts <backup-path>');
    process.exit(1);
  }

  if (!fs.existsSync(backupPath)) {
    console.error(`[restore] File not found: ${backupPath}`);
    process.exit(1);
  }

  const raw = fs.readFileSync(backupPath, 'utf-8');
  const snapshot: DevStoreSnapshot = JSON.parse(raw);

  console.log('[restore] Backup snapshot loaded:');
  console.log(`  studyAttempts: ${(snapshot.studyAttempts || []).length}`);
  console.log(`  idempotencyKeys: ${Object.keys(snapshot.idempotencyKeys || {}).length}`);
  console.log(`  ownedItems: ${(snapshot.ownedItems || []).length}`);
  console.log(`  coinsSpent: ${snapshot.coinsSpent || 0}`);

  const pg = new PgDevStorePersistence();

  console.log('[restore] Clearing current PG user state...');
  await pg.clearAsync();

  console.log('[restore] Writing backup to PG...');
  // Use the internal async save
  await (pg as any).saveAsync(snapshot);

  console.log('[restore] Verifying restore...');
  const reloaded = await pg.loadAsync();
  if (reloaded) {
    console.log('[restore] Verification:');
    console.log(`  studyAttempts: ${reloaded.studyAttempts.length}`);
    console.log(`  idempotencyKeys: ${Object.keys(reloaded.idempotencyKeys).length}`);
    console.log(`  ownedItems: ${reloaded.ownedItems.length}`);
    console.log(`  coinsSpent: ${reloaded.coinsSpent}`);
    console.log('[restore] Restore complete and verified.');
  } else {
    console.warn('[restore] WARNING: Verification load returned null.');
  }

  await pg.getPool().end();
})();
