/**
 * Minimal SQL migration runner (Option A A2).
 *
 * - Reads .sql files from migrations/ directory
 * - Tracks applied migrations in _migrations table
 * - Supports up (apply pending) and down (rollback last)
 * - Each migration file must export up/down SQL separated by "-- DOWN"
 */

import * as fs from 'fs';
import * as path from 'path';
import { getPool, closePool } from './client';

const MIGRATIONS_DIR = path.resolve(__dirname, 'migrations');

interface MigrationFile {
  name: string;
  upSql: string;
  downSql: string;
}

function parseMigrationFile(filePath: string): MigrationFile {
  const content = fs.readFileSync(filePath, 'utf-8');
  const name = path.basename(filePath, '.sql');

  const downMarker = '-- DOWN';
  const downIdx = content.indexOf(downMarker);

  let upSql: string;
  let downSql: string;

  if (downIdx >= 0) {
    upSql = content.substring(0, downIdx).trim();
    downSql = content.substring(downIdx + downMarker.length).trim();
  } else {
    upSql = content.trim();
    downSql = '';
  }

  return { name, upSql, downSql };
}

function getMigrationFiles(): MigrationFile[] {
  if (!fs.existsSync(MIGRATIONS_DIR)) {
    return [];
  }
  return fs
    .readdirSync(MIGRATIONS_DIR)
    .filter(f => f.endsWith('.sql'))
    .sort()
    .map(f => parseMigrationFile(path.join(MIGRATIONS_DIR, f)));
}

async function ensureMigrationTable(): Promise<void> {
  const pool = getPool();
  await pool.query(`
    CREATE TABLE IF NOT EXISTS _migrations (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL UNIQUE,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `);
}

async function getAppliedMigrations(): Promise<string[]> {
  const pool = getPool();
  const result = await pool.query('SELECT name FROM _migrations ORDER BY id');
  return result.rows.map(r => r.name);
}

export async function migrateUp(): Promise<string[]> {
  await ensureMigrationTable();
  const applied = await getAppliedMigrations();
  const all = getMigrationFiles();
  const pending = all.filter(m => !applied.includes(m.name));

  const pool = getPool();
  const appliedNow: string[] = [];

  for (const migration of pending) {
    console.log(`[migrate] Applying: ${migration.name}`);
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(migration.upSql);
      await client.query('INSERT INTO _migrations (name) VALUES ($1)', [migration.name]);
      await client.query('COMMIT');
      appliedNow.push(migration.name);
      console.log(`[migrate] Applied: ${migration.name}`);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error(`[migrate] Failed: ${migration.name}`, err);
      throw err;
    } finally {
      client.release();
    }
  }

  if (appliedNow.length === 0) {
    console.log('[migrate] No pending migrations.');
  }

  return appliedNow;
}

export async function migrateDown(): Promise<string | null> {
  await ensureMigrationTable();
  const applied = await getAppliedMigrations();

  if (applied.length === 0) {
    console.log('[migrate] No migrations to rollback.');
    return null;
  }

  const lastName = applied[applied.length - 1];
  const all = getMigrationFiles();
  const migration = all.find(m => m.name === lastName);

  if (!migration) {
    throw new Error(`[migrate] Migration file not found for: ${lastName}`);
  }

  if (!migration.downSql) {
    throw new Error(`[migrate] No DOWN section in migration: ${lastName}`);
  }

  const pool = getPool();
  const client = await pool.connect();

  try {
    console.log(`[migrate] Rolling back: ${migration.name}`);
    await client.query('BEGIN');
    await client.query(migration.downSql);
    await client.query('DELETE FROM _migrations WHERE name = $1', [migration.name]);
    await client.query('COMMIT');
    console.log(`[migrate] Rolled back: ${migration.name}`);
    return migration.name;
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(`[migrate] Rollback failed: ${migration.name}`, err);
    throw err;
  } finally {
    client.release();
  }
}

export async function migrateStatus(): Promise<{
  applied: string[];
  pending: string[];
}> {
  await ensureMigrationTable();
  const applied = await getAppliedMigrations();
  const all = getMigrationFiles();
  const pending = all.filter(m => !applied.includes(m.name)).map(m => m.name);
  return { applied, pending };
}

// CLI entry point
if (require.main === module) {
  // Load .env
  const envPath = path.resolve(__dirname, '..', '..', '..', '.env');
  if (fs.existsSync(envPath)) {
    const envContent = fs.readFileSync(envPath, 'utf-8');
    for (const line of envContent.split('\n')) {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const eqIdx = trimmed.indexOf('=');
        if (eqIdx > 0) {
          const key = trimmed.substring(0, eqIdx);
          const value = trimmed.substring(eqIdx + 1);
          if (!process.env[key]) {
            process.env[key] = value;
          }
        }
      }
    }
  }

  const command = process.argv[2] || 'up';

  (async () => {
    try {
      if (command === 'up') {
        const applied = await migrateUp();
        console.log(`Done. Applied ${applied.length} migration(s).`);
      } else if (command === 'down') {
        const rolled = await migrateDown();
        console.log(rolled ? `Rolled back: ${rolled}` : 'Nothing to rollback.');
      } else if (command === 'status') {
        const status = await migrateStatus();
        console.log('Applied:', status.applied);
        console.log('Pending:', status.pending);
      } else {
        console.log('Usage: migrate.ts [up|down|status]');
      }
    } catch (err) {
      console.error(err);
      process.exit(1);
    } finally {
      await closePool();
    }
  })();
}
