/**
 * PostgreSQL connection pool (Option A).
 *
 * Provides a singleton Pool instance for the application.
 * Reads DATABASE_URL from environment.
 */

import { Pool, PoolClient } from 'pg';

let pool: Pool | null = null;

export function getPool(): Pool {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error(
        '[PG] DATABASE_URL is not set. Copy .env.example to .env and fill in your credentials.',
      );
    }
    pool = new Pool({ connectionString });
  }
  return pool;
}

export async function query(text: string, params?: any[]) {
  return getPool().query(text, params);
}

export async function getClient(): Promise<PoolClient> {
  return getPool().connect();
}

export async function closePool(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
  }
}
