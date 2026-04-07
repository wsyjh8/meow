/**
 * PostgreSQL health & readiness checks.
 */

import { query } from './client';

export interface PgHealthResult {
  connected: boolean;
  migrationsApplied: number;
  latestMigration: string | null;
  error?: string;
}

export async function checkPgHealth(): Promise<PgHealthResult> {
  try {
    // Basic connectivity
    await query('SELECT 1');

    // Check migration history
    const migrationCheck = await query(
      `SELECT COUNT(*)::int AS count, MAX(name) AS latest
       FROM _migrations`,
    );
    const row = migrationCheck.rows[0];

    return {
      connected: true,
      migrationsApplied: row.count,
      latestMigration: row.latest,
    };
  } catch (err: any) {
    // _migrations table might not exist yet
    if (err.code === '42P01') {
      // relation does not exist — migrations not yet run
      try {
        await query('SELECT 1');
        return {
          connected: true,
          migrationsApplied: 0,
          latestMigration: null,
          error: 'Migration table does not exist. Run migrations first.',
        };
      } catch {
        return { connected: false, migrationsApplied: 0, latestMigration: null, error: String(err) };
      }
    }
    return { connected: false, migrationsApplied: 0, latestMigration: null, error: String(err) };
  }
}
