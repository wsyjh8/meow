/**
 * Audio Pipeline Ingest Script (P2.1 publish 子阶段).
 *
 * Reads two artifacts produced by the local Windows TTS pipeline and
 * writes them into the v0.3.0 pilot tables (created by migration 004):
 *
 *   - examples.json          → INSERT INTO examples (optional, kind=example)
 *   - audio_assets.jsonl     → INSERT INTO audio_assets (after URL rewrite)
 *   - + 1 row INTO content_manifest with is_active=true
 *
 * Usage (examples + audio):
 *   npx ts-node scripts/ingest-audio-assets.ts \
 *     --examples-json /path/to/audio-pipeline/input/examples.json \
 *     --audio-jsonl   /path/to/audio-pipeline/out/audio_assets.jsonl \
 *     [--cdn-origin   http://10.0.2.2:3000/cdn] \
 *     [--manifest-id  audio-meta-cet4@v1] \
 *     [--package-name audio-meta-cet4] \
 *     [--content-version v1] \
 *     [--dry-run]
 *
 * Usage (word audio only — P2.2.B; words are already in `words` table from
 * P1 seed, so no content-table side-input is needed):
 *   npx ts-node scripts/ingest-audio-assets.ts \
 *     --audio-jsonl   ../audio-pipeline-staging/audio_assets.jsonl \
 *     --manifest-id   audio-meta-words@v1 \
 *     --package-name  audio-meta-words
 *
 * URL rewrite: any `local://cdn/...` in audio_assets.jsonl is replaced
 * with `${cdnOrigin}/...`. This keeps the jsonl env-agnostic; binding
 * to a real CDN host is a one-line change at ingest time.
 */

import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';

// ========== Env loading (same pattern as scripts/db/import-json.ts) ==========
const envPath = path.resolve(__dirname, '..', '.env');
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

// ========== CLI args ==========
interface Args {
  examplesJson: string | undefined;
  audioJsonl: string;
  cdnOrigin: string;
  manifestId: string;
  packageName: string;
  contentVersion: string;
  dryRun: boolean;
}

function parseArgs(): Args {
  const argv = process.argv.slice(2);
  const get = (key: string, fallback?: string): string => {
    const idx = argv.indexOf(key);
    if (idx >= 0 && idx + 1 < argv.length) return argv[idx + 1];
    if (fallback !== undefined) return fallback;
    throw new Error(`Missing required arg: ${key}`);
  };
  const getOpt = (key: string): string | undefined => {
    const idx = argv.indexOf(key);
    if (idx >= 0 && idx + 1 < argv.length) return argv[idx + 1];
    return undefined;
  };
  const has = (key: string): boolean => argv.includes(key);

  // Default to monorepo-relative `audio-pipeline/` (Codex pipeline working dir).
  // Override at CLI for actual machine path.
  const repoRoot = path.resolve(__dirname, '..', '..', '..');
  const defaultAudio = path.join(repoRoot, 'audio-pipeline', 'out', 'audio_assets.jsonl');

  return {
    // Optional: when omitted, skip examples-table ingest. Used by the
    // word-audio path (kind=word) where there is no content-table side-input.
    examplesJson: getOpt('--examples-json'),
    audioJsonl: get('--audio-jsonl', defaultAudio),
    cdnOrigin: get('--cdn-origin', 'http://10.0.2.2:3000/cdn'),
    manifestId: get('--manifest-id', 'audio-meta-cet4@v1'),
    packageName: get('--package-name', 'audio-meta-cet4'),
    contentVersion: get('--content-version', 'v1'),
    dryRun: has('--dry-run'),
  };
}

// ========== Types matching pipeline output ==========
interface ExampleRow {
  stable_id: string;
  word_id: string;
  en: string;
  cn: string;
  sense?: string;
  sense_label?: string;
  ordinal?: number;
  difficulty?: string;
  generator?: string;
}

interface AudioAssetRow {
  id: string;
  target_kind: string;
  target_id: string;
  locale: string;
  voice: string;
  accent?: string;
  gender?: string;
  format: string;
  audio_version: string;
  checksum_sha256: string;
  source_text_hash: string;
  tts_provider: string;
  tts_model: string;
  tts_model_version?: string;
  bytes: number;
  duration_ms: number;
  url: string;
  status: string;
  composite_label?: string;
  generated_at: string;
}

// ========== Loaders ==========
function loadExamples(filePath: string): ExampleRow[] {
  const raw = fs.readFileSync(filePath, 'utf-8');
  const parsed = JSON.parse(raw);
  // Pipeline `prepare_examples.py` produces { items: [...] } or a top-level array.
  // Be tolerant of both.
  const items = Array.isArray(parsed) ? parsed : parsed.items ?? parsed.examples ?? [];
  if (!Array.isArray(items)) {
    throw new Error(`examples.json: cannot find array of items in ${filePath}`);
  }
  return items as ExampleRow[];
}

function loadAudioJsonl(filePath: string, cdnOrigin: string): AudioAssetRow[] {
  const raw = fs.readFileSync(filePath, 'utf-8');
  const lines = raw.split('\n').filter((l) => l.trim().length > 0);
  return lines.map((line, idx) => {
    let row: AudioAssetRow;
    try {
      row = JSON.parse(line);
    } catch (err) {
      throw new Error(`audio_assets.jsonl line ${idx + 1}: invalid JSON — ${(err as Error).message}`);
    }
    // URL rewrite: local://cdn/... → ${cdnOrigin}/...
    if (row.url && row.url.startsWith('local://cdn/')) {
      row.url = cdnOrigin + row.url.substring('local://cdn'.length);
    } else if (row.url && row.url.startsWith('local://')) {
      // Other local:// schemes (defensive — don't silently accept)
      throw new Error(`audio_assets.jsonl line ${idx + 1}: unexpected url scheme: ${row.url}`);
    }
    return row;
  });
}

// ========== Inserters ==========
async function ingestExamples(pool: Pool, rows: ExampleRow[], dryRun: boolean): Promise<number> {
  if (dryRun) {
    console.log(`[dry-run] would INSERT ${rows.length} examples`);
    return rows.length;
  }
  let n = 0;
  // Batch insert with parameterized values to avoid N round trips
  const BATCH_SIZE = 500;
  for (let i = 0; i < rows.length; i += BATCH_SIZE) {
    const batch = rows.slice(i, i + BATCH_SIZE);
    const values: string[] = [];
    const params: unknown[] = [];
    let p = 1;
    for (const r of batch) {
      values.push(
        `($${p++}, $${p++}, $${p++}, $${p++}, $${p++}, $${p++}, $${p++}, $${p++}, $${p++})`,
      );
      params.push(
        r.stable_id,
        r.word_id,
        r.sense_label ?? r.sense ?? null,
        r.en,
        r.cn,
        r.ordinal ?? 0,
        r.difficulty ?? null,
        r.generator ?? null,
        new Date().toISOString(),
      );
    }
    const sql = `
      INSERT INTO examples
        (stable_id, word_id, sense_label, en, cn, ordinal, difficulty, generator, generated_at)
      VALUES ${values.join(', ')}
      ON CONFLICT (stable_id) DO UPDATE SET
        word_id = EXCLUDED.word_id,
        sense_label = EXCLUDED.sense_label,
        en = EXCLUDED.en,
        cn = EXCLUDED.cn,
        ordinal = EXCLUDED.ordinal,
        difficulty = EXCLUDED.difficulty,
        generator = EXCLUDED.generator
    `;
    await pool.query(sql, params);
    n += batch.length;
    if (n % 5000 === 0 || n === rows.length) {
      console.log(`[examples] inserted ${n} / ${rows.length}`);
    }
  }
  return n;
}

async function ingestAudioAssets(
  pool: Pool,
  rows: AudioAssetRow[],
  dryRun: boolean,
): Promise<number> {
  if (dryRun) {
    console.log(`[dry-run] would INSERT ${rows.length} audio_assets`);
    return rows.length;
  }
  let n = 0;
  const BATCH_SIZE = 500;
  for (let i = 0; i < rows.length; i += BATCH_SIZE) {
    const batch = rows.slice(i, i + BATCH_SIZE);
    const values: string[] = [];
    const params: unknown[] = [];
    let p = 1;
    for (const r of batch) {
      // 19 columns
      values.push(
        `($${p++}, $${p++}, $${p++}, $${p++}, $${p++}, $${p++}, $${p++}, $${p++}, $${p++},
          $${p++}, $${p++}, $${p++}, $${p++}, $${p++}, $${p++}, $${p++}, $${p++}, $${p++}, $${p++})`,
      );
      params.push(
        r.id,
        r.target_kind,
        r.target_id,
        r.locale,
        r.voice,
        r.accent ?? null,
        r.gender ?? null,
        r.format,
        r.audio_version,
        r.checksum_sha256,
        r.source_text_hash,
        r.tts_provider,
        r.tts_model,
        r.tts_model_version ?? null,
        r.bytes,
        r.duration_ms,
        r.url,
        r.status,
        r.composite_label ?? null,
      );
    }
    const sql = `
      INSERT INTO audio_assets
        (id, target_kind, target_id, locale, voice, accent, gender, format, audio_version,
         checksum_sha256, source_text_hash, tts_provider, tts_model, tts_model_version,
         bytes, duration_ms, url, status, composite_label)
      VALUES ${values.join(', ')}
      ON CONFLICT (id) DO UPDATE SET
        url = EXCLUDED.url,
        checksum_sha256 = EXCLUDED.checksum_sha256,
        bytes = EXCLUDED.bytes,
        duration_ms = EXCLUDED.duration_ms,
        status = EXCLUDED.status
    `;
    await pool.query(sql, params);
    n += batch.length;
    if (n % 5000 === 0 || n === rows.length) {
      console.log(`[audio_assets] inserted ${n} / ${rows.length}`);
    }
  }
  return n;
}

async function upsertManifest(
  pool: Pool,
  manifestId: string,
  packageName: string,
  contentVersion: string,
  dryRun: boolean,
): Promise<void> {
  if (dryRun) {
    console.log(`[dry-run] would activate manifest ${manifestId}`);
    return;
  }
  // Deactivate any prior active row for this package_name
  await pool.query(
    'UPDATE content_manifest SET is_active = false WHERE package_name = $1 AND is_active = true',
    [packageName],
  );
  // Insert (or refresh) this version's row, set is_active=true
  await pool.query(
    `INSERT INTO content_manifest (id, package_name, package_kind, content_version, is_active)
     VALUES ($1, $2, 'audio_meta', $3, true)
     ON CONFLICT (id) DO UPDATE SET is_active = true`,
    [manifestId, packageName, contentVersion],
  );
  console.log(`[manifest] activated ${manifestId}`);
}

// ========== Main ==========
async function main() {
  const args = parseArgs();

  console.log('--- Audio Assets Ingest ---');
  console.log(`  examples-json:  ${args.examplesJson ?? '(skipped)'}`);
  console.log(`  audio-jsonl:    ${args.audioJsonl}`);
  console.log(`  cdn-origin:     ${args.cdnOrigin}`);
  console.log(`  manifest-id:    ${args.manifestId}`);
  console.log(`  dry-run:        ${args.dryRun}`);
  console.log('');

  // Load + sanity check
  if (args.examplesJson && !fs.existsSync(args.examplesJson)) {
    throw new Error(`examples-json not found: ${args.examplesJson}`);
  }
  if (!fs.existsSync(args.audioJsonl)) {
    throw new Error(`audio-jsonl not found: ${args.audioJsonl}`);
  }

  const examples = args.examplesJson ? loadExamples(args.examplesJson) : [];
  const audioAssets = loadAudioJsonl(args.audioJsonl, args.cdnOrigin);

  console.log(
    `Loaded ${examples.length} examples${args.examplesJson ? '' : ' (--examples-json omitted)'}, ${audioAssets.length} audio assets`,
  );

  // Referential sanity check (warn-only): when examples.json is provided,
  // every audio_asset row with target_kind='example' should have its
  // target_id (stable_id) present in examples. Skip this when --examples-json
  // is omitted (word-only ingest path).
  let missing = 0;
  if (args.examplesJson) {
    const exampleIds = new Set(examples.map((e) => e.stable_id));
    for (const a of audioAssets) {
      if (a.target_kind === 'example' && !exampleIds.has(a.target_id)) {
        missing++;
      }
    }
    if (missing > 0) {
      console.warn(
        `[warn] ${missing} audio_assets reference example stable_ids not in examples.json`,
      );
    }
  }

  // Connect & ingest. Prefer DATABASE_URL (project-standard env, set by .env)
  // and fall back to discrete PG_* vars for ops convenience.
  const connectionString = process.env.DATABASE_URL;
  const pool = connectionString
    ? new Pool({ connectionString })
    : new Pool({
        host: process.env.PG_HOST || 'localhost',
        port: parseInt(process.env.PG_PORT || '5432', 10),
        database: process.env.PG_DATABASE || 'meow_dev',
        user: process.env.PG_USER || 'postgres',
        password: process.env.PG_PASSWORD || '',
      });

  try {
    const nExamples = examples.length
      ? await ingestExamples(pool, examples, args.dryRun)
      : 0;
    const nAudio = await ingestAudioAssets(pool, audioAssets, args.dryRun);
    await upsertManifest(
      pool,
      args.manifestId,
      args.packageName,
      args.contentVersion,
      args.dryRun,
    );

    console.log('');
    console.log('--- Ingest complete ---');
    console.log(
      `  examples inserted/updated:     ${nExamples}${args.examplesJson ? '' : ' (skipped)'}`,
    );
    console.log(`  audio_assets inserted/updated: ${nAudio}`);
    console.log(`  manifest:                      ${args.manifestId} (active)`);
    if (missing > 0) {
      console.log(`  ⚠ ${missing} audio_assets reference unknown examples (see warning above)`);
    }
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('Ingest failed:', err);
  process.exit(1);
});
