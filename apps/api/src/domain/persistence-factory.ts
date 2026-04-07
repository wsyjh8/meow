/**
 * Persistence factory (Option A A5 — hardened).
 *
 * Single switch point for choosing persistence backend.
 *
 * Default runtime: PostgreSQL (requires DATABASE_URL).
 * JSON is ONLY available via explicit opt-in (PERSISTENCE_BACKEND=json).
 * JSON is NOT a silent fallback — missing DATABASE_URL with PG backend is an error.
 *
 * Allowed values for PERSISTENCE_BACKEND:
 *   - 'pg'   (default): PostgreSQL — production runtime truth
 *   - 'json' (explicit): Legacy JSON file — test isolation / emergency only
 */

import * as fs from 'fs';
import * as path from 'path';
import { IDevStorePersistence, DevStorePersistence } from './persistence';
import { PgDevStorePersistence } from '../infrastructure/postgres/pg-persistence';

// Load .env at factory init time (before DevStore singleton is created)
const envPath = path.resolve(__dirname, '..', '..', '.env');
if (fs.existsSync(envPath)) {
  for (const line of fs.readFileSync(envPath, 'utf-8').split('\n')) {
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

export function createPersistence(overridePath?: string): IDevStorePersistence {
  const backend = process.env.PERSISTENCE_BACKEND || 'pg';

  if (backend === 'json') {
    // JSON is only used when explicitly requested (tests, emergency, local dev)
    console.log('[Persistence] Using JSON file backend (explicit opt-in).');
    return new DevStorePersistence(overridePath);
  }

  // Default: PostgreSQL — the sole production runtime truth
  if (!process.env.DATABASE_URL) {
    throw new Error(
      '[Persistence] DATABASE_URL is required when PERSISTENCE_BACKEND=pg (default). ' +
      'Set DATABASE_URL in .env, or set PERSISTENCE_BACKEND=json for local/test use.',
    );
  }

  console.log('[Persistence] Using PostgreSQL backend (production runtime truth).');
  return new PgDevStorePersistence();
}
