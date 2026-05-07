/**
 * PR-D Option A: One-shot tool to rewrite PG `audio_assets.url` from one
 * origin prefix to another (e.g. emulator `http://10.0.2.2:3000/cdn` →
 * COS `https://<bucket>.cos.<region>.myqcloud.com`).
 *
 * Why: PR-A `ingest-audio-assets.ts` baked the dev cdnOrigin into PG. After
 * PR-D Option A migrates audio mp3s to COS public-read, existing rows still
 * point at the old origin. This tool rewrites them in a single transaction.
 *
 * Safety:
 *   - dry-run by default; --commit required to actually write.
 *   - Single transaction; rolled back if anything errors mid-way.
 *   - Prefix LIKE match (precise: only rows starting with --from prefix).
 *   - Idempotent: re-running after success matches 0 rows (safe to retry).
 *   - Sample 3 before/after rows printed for human eyeballing.
 *
 * Usage:
 *   # Dry-run (default)
 *   npx ts-node scripts/repipe-audio-urls.ts \
 *     --from 'http://10.0.2.2:3000/cdn' \
 *     --to   'https://my-bucket.cos.ap-shanghai.myqcloud.com'
 *
 *   # Commit
 *   npx ts-node scripts/repipe-audio-urls.ts \
 *     --from 'http://10.0.2.2:3000/cdn' \
 *     --to   'https://my-bucket.cos.ap-shanghai.myqcloud.com' \
 *     --commit
 *
 * Reads DATABASE_URL from process.env (loaded from apps/api/.env via dotenv).
 */

import * as fs from 'fs';
import * as path from 'path';
import * as dotenv from 'dotenv';
import { Pool } from 'pg';

// ---------- env loading (dotenv; same pattern as cos-sync-helper) ----------
const envCandidates = [
  path.resolve(__dirname, 'content_pipeline', '.env'),
  path.resolve(__dirname, '..', '.env'),
];
for (const envPath of envCandidates) {
  if (fs.existsSync(envPath)) {
    dotenv.config({ path: envPath, override: false });
  }
}

// ---------- CLI args ----------
interface Args {
  from: string;
  to: string;
  commit: boolean;
}

function parseArgs(): Args {
  const argv = process.argv.slice(2);
  const get = (flag: string): string | null => {
    const i = argv.indexOf(flag);
    return i >= 0 && i + 1 < argv.length ? argv[i + 1] : null;
  };
  const has = (flag: string): boolean => argv.includes(flag);

  const from = get('--from');
  const to = get('--to');
  if (!from || !to) {
    console.error(
      'Usage: ts-node repipe-audio-urls.ts --from <prefix> --to <prefix> [--commit]\n\n' +
        '  --from   Old URL prefix to match (LIKE prefix)\n' +
        '  --to     New URL prefix\n' +
        '  --commit Actually write changes (default is dry-run)\n',
    );
    process.exit(2);
  }
  if (from === to) {
    console.error('ERROR: --from and --to must differ');
    process.exit(2);
  }
  // Strip trailing slash on --to so prefix swap doesn't double-slash
  // (--from is matched as LIKE prefix; trailing slash there matters less).
  const toClean = to.replace(/\/+$/, '');
  return { from, to: toClean, commit: has('--commit') };
}

// ---------- main ----------
async function main(): Promise<void> {
  const args = parseArgs();

  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    console.error('ERROR: DATABASE_URL not set');
    process.exit(2);
  }

  console.log('--- repipe-audio-urls ---');
  console.log(`  from:    ${args.from}`);
  console.log(`  to:      ${args.to}`);
  console.log(`  mode:    ${args.commit ? 'COMMIT' : 'DRY-RUN'}`);
  console.log('');

  const pool = new Pool({ connectionString });
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const likePattern = `${args.from}%`;

    // Count matched rows + sample
    const countRes = await client.query(
      'SELECT COUNT(*)::int AS n FROM audio_assets WHERE url LIKE $1',
      [likePattern],
    );
    const matched: number = countRes.rows[0]?.n ?? 0;

    const sampleRes = await client.query(
      'SELECT id, url FROM audio_assets WHERE url LIKE $1 ORDER BY id LIMIT 3',
      [likePattern],
    );

    console.log(`matched rows: ${matched}`);
    if (matched === 0) {
      console.log('Nothing to do (already repiped or no rows match).');
      await client.query('ROLLBACK');
      return;
    }

    console.log('sample (first 3, before/after):');
    for (const row of sampleRes.rows) {
      const before: string = row.url;
      const after = before.startsWith(args.from)
        ? args.to + before.substring(args.from.length)
        : before;
      console.log(`  ${row.id}`);
      console.log(`    before: ${before}`);
      console.log(`    after:  ${after}`);
    }
    console.log('');

    // Apply: SUBSTRING swap on prefix length
    const updateSql = `
      UPDATE audio_assets
      SET url = $1 || SUBSTRING(url FROM $2)
      WHERE url LIKE $3
    `;
    const fromLen = args.from.length;
    const updateRes = await client.query(updateSql, [
      args.to,
      fromLen + 1, // PG SUBSTRING is 1-indexed; +1 chops the prefix
      likePattern,
    ]);

    if (!args.commit) {
      console.log(`[dry-run] would rewrite ${updateRes.rowCount} rows; rolling back.`);
      await client.query('ROLLBACK');
      return;
    }

    await client.query('COMMIT');
    console.log(`COMMIT: rewrote ${updateRes.rowCount} rows.`);
  } catch (err) {
    await client.query('ROLLBACK').catch(() => undefined);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error('repipe-audio-urls failed:', err);
  process.exit(1);
});
