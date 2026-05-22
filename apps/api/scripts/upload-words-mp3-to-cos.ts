/**
 * One-shot batch uploader: temp/out/mp3/words → COS audio/v1/words
 *
 * Features:
 *   - Checkpoint file (words-progress.json) records uploaded rel paths.
 *     Re-runs skip already-uploaded files without HEAD requests.
 *   - Batch size: 5000 per run. Exits after batch; re-run to continue.
 *   - Concurrency: 8 simultaneous uploads (pLimit).
 *   - Checkpoint flushed every 100 uploads + on SIGINT + on batch end.
 *   - withRetry: 5 attempts, exponential back-off.
 *
 * Usage:
 *   npx ts-node scripts/upload-words-mp3-to-cos.ts --dry-run   # preview
 *   npx ts-node scripts/upload-words-mp3-to-cos.ts --commit    # upload
 */

import * as fs from 'fs';
import * as path from 'path';

import { PutObjectCommand } from '@aws-sdk/client-s3';
import * as dotenv from 'dotenv';
import pLimit from 'p-limit';

import { readCosCredsOrExit, buildCosClient } from './cos-sync-helper';

// ---------- constants ----------
const PROJECT_ROOT = path.resolve(__dirname, '../../..');

// Load root .env as fallback (cos-sync-helper only checks apps/api/.env)
dotenv.config({ path: path.join(PROJECT_ROOT, '.env'), override: false });
const SRC_DIR = path.join(PROJECT_ROOT, 'temp', 'out', 'mp3', 'words');
const COS_PREFIX = 'audio/v1/words';
const CHECKPOINT_FILE = path.join(PROJECT_ROOT, 'temp', 'out', 'mp3', 'words-progress.json');
const BATCH_SIZE = 5000;
const CONCURRENCY = 8;
const FLUSH_EVERY = 100; // write checkpoint after this many new uploads

// ---------- file walking ----------
async function* walkMp3(
  dir: string,
  base = '',
): AsyncGenerator<{ abs: string; rel: string }> {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const abs = path.join(dir, entry.name);
    const rel = path.posix.join(base, entry.name);
    if (entry.isDirectory()) {
      yield* walkMp3(abs, rel);
    } else if (entry.isFile() && entry.name.toLowerCase().endsWith('.mp3')) {
      yield { abs, rel };
    }
  }
}

// ---------- retry ----------
async function withRetry<T>(
  fn: () => Promise<T>,
  maxAttempts = 5,
  baseDelayMs = 2000,
): Promise<T> {
  let lastErr: unknown;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err: unknown) {
      const e = err as { code?: string; $metadata?: { httpStatusCode?: number } };
      const code = e?.code;
      const httpStatus = e?.$metadata?.httpStatusCode;
      const isTransient =
        code === 'ECONNRESET' ||
        code === 'ETIMEDOUT' ||
        code === 'ENOTFOUND' ||
        (httpStatus !== undefined && httpStatus >= 500);
      if (!isTransient || attempt === maxAttempts) throw err;
      const delay = baseDelayMs * Math.pow(2, attempt - 1);
      console.log(`  [retry] attempt ${attempt}/${maxAttempts} after ${delay}ms`);
      await new Promise(r => setTimeout(r, delay));
      lastErr = err;
    }
  }
  throw lastErr;
}

// ---------- checkpoint ----------
function loadCheckpoint(): Set<string> {
  if (!fs.existsSync(CHECKPOINT_FILE)) return new Set();
  try {
    const raw = JSON.parse(fs.readFileSync(CHECKPOINT_FILE, 'utf-8')) as {
      uploaded: string[];
    };
    return new Set(raw.uploaded);
  } catch {
    console.warn('[warn] checkpoint file unreadable, starting fresh');
    return new Set();
  }
}

function saveCheckpoint(uploaded: Set<string>): void {
  fs.writeFileSync(
    CHECKPOINT_FILE,
    JSON.stringify({ uploaded: Array.from(uploaded) }, null, 2),
    'utf-8',
  );
}

// ---------- main ----------
async function main(): Promise<void> {
  const isDryRun = process.argv.includes('--dry-run');
  const isCommit = process.argv.includes('--commit');

  if (!isDryRun && !isCommit) {
    console.error(
      'Usage:\n' +
        '  npx ts-node scripts/upload-words-mp3-to-cos.ts --dry-run\n' +
        '  npx ts-node scripts/upload-words-mp3-to-cos.ts --commit',
    );
    process.exit(2);
  }

  const creds = readCosCredsOrExit();
  const client = buildCosClient(creds);

  console.log(`mode:       ${isDryRun ? 'DRY-RUN' : 'COMMIT'}`);
  console.log(`src:        ${SRC_DIR}`);
  console.log(`prefix:     ${COS_PREFIX}`);
  console.log(`bucket:     ${creds.bucket}`);
  console.log(`region:     ${creds.region}`);
  console.log(`batch-size: ${BATCH_SIZE}`);
  console.log(`checkpoint: ${CHECKPOINT_FILE}`);
  console.log('');

  if (!fs.existsSync(SRC_DIR)) {
    console.error(`ERROR: src dir not found: ${SRC_DIR}`);
    process.exit(2);
  }

  const uploaded = loadCheckpoint();
  console.log(`checkpoint: ${uploaded.size} files already uploaded, will be skipped`);

  // Walk src, filter out already-uploaded
  const pending: { abs: string; rel: string }[] = [];
  for await (const f of walkMp3(SRC_DIR)) {
    if (!uploaded.has(f.rel)) pending.push(f);
  }

  const grandTotal = uploaded.size + pending.length;
  console.log(`total .mp3 in src:          ${grandTotal}`);
  console.log(`pending (not yet uploaded): ${pending.length}`);

  if (pending.length === 0) {
    console.log('\nAll files already uploaded. Nothing to do.');
    return;
  }

  // Cap to one batch
  const batch = pending.slice(0, BATCH_SIZE);
  const moreRemain = pending.length > BATCH_SIZE;
  console.log(`this batch: ${batch.length} files`);
  if (moreRemain) {
    console.log(`(${pending.length - BATCH_SIZE} files will remain after this batch)`);
  }
  console.log('');

  let batchDone = 0;
  let lastFlushAt = 0;

  // Save checkpoint on Ctrl+C
  process.on('SIGINT', () => {
    console.log('\n[interrupted] saving checkpoint...');
    saveCheckpoint(uploaded);
    console.log(`Saved ${uploaded.size} total uploaded. Re-run to continue.`);
    process.exit(0);
  });

  const limit = pLimit(CONCURRENCY);

  await Promise.all(
    batch.map(({ abs, rel }) =>
      limit(async () => {
        const key = path.posix.join(COS_PREFIX, rel);
        const size = fs.statSync(abs).size;

        if (isDryRun) {
          console.log(`  [dry] ${rel}  (${size.toLocaleString()} B)`);
          batchDone++;
          return;
        }

        await withRetry(() =>
          client.send(
            new PutObjectCommand({
              Bucket: creds.bucket,
              Key: key,
              Body: fs.createReadStream(abs),
              ContentLength: size,
              ContentType: 'audio/mpeg',
              CacheControl: 'public, max-age=31536000, immutable',
              ACL: 'public-read',
            }),
          ),
        );

        uploaded.add(rel);
        batchDone++;

        // Periodic flush
        if (batchDone - lastFlushAt >= FLUSH_EVERY) {
          saveCheckpoint(uploaded);
          lastFlushAt = batchDone;
        }

        if (batchDone % 500 === 0) {
          console.log(
            `  progress: ${batchDone}/${batch.length} this batch` +
              ` | total uploaded: ${uploaded.size}/${grandTotal}`,
          );
        }
      }),
    ),
  );

  if (!isDryRun) {
    saveCheckpoint(uploaded);
  }

  console.log('');
  console.log(`batch done: ${batchDone} uploaded`);
  console.log(`total uploaded so far: ${uploaded.size} / ${grandTotal}`);

  if (moreRemain) {
    console.log(`\nBatch complete (${BATCH_SIZE}). Re-run to continue next batch.`);
  } else {
    console.log('\nAll files uploaded!');
  }
}

main().catch((err) => {
  console.error('ERROR:', err);
  process.exit(1);
});
