/**
 * PG Backup Script (Option A A5).
 *
 * Exports current PG state to a JSON snapshot file for backup/restore.
 * This is a read-only export — does NOT modify PG.
 *
 * Usage: npx ts-node scripts/db/backup.ts [output-path]
 * Default output: data/pg-backup-{timestamp}.json
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

(async () => {
  const pg = new PgDevStorePersistence();
  console.log('[backup] Loading state from PostgreSQL...');

  const snapshot = await pg.loadAsync();
  if (!snapshot) {
    console.log('[backup] No state found in PG (empty or user not found).');
    await pg.getPool().end();
    process.exit(0);
  }

  const outputPath = process.argv[2] || path.resolve(
    __dirname, '..', '..', 'data',
    `pg-backup-${new Date().toISOString().replace(/[:.]/g, '-')}.json`,
  );

  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

  fs.writeFileSync(outputPath, JSON.stringify(snapshot, null, 2), 'utf-8');
  console.log(`[backup] Exported to: ${outputPath}`);
  console.log(`[backup] studyAttempts: ${snapshot.studyAttempts.length}`);
  console.log(`[backup] idempotencyKeys: ${Object.keys(snapshot.idempotencyKeys).length}`);
  console.log(`[backup] ownedItems: ${snapshot.ownedItems.length}`);
  console.log(`[backup] coinsSpent: ${snapshot.coinsSpent}`);

  await pg.getPool().end();
  console.log('[backup] Done.');
})();
