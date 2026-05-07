/**
 * PR-D Option A: Shared helper for one-shot file-tree → Tencent COS sync.
 *
 * Used by:
 *   - sync-audio-mp3-to-cos.ts (mp3 in cdn-mock/audio/v1/)
 *   - sync-pronunciation-to-cos.ts (wav in data/pronunciation/)
 *
 * Behavior:
 *   - Walks `src` directory recursively, filtering by file extension.
 *   - For each file, computes md5; HEAD-checks COS object ETag; skips
 *     identical content (idempotent re-runs).
 *   - Streams file body to COS (createReadStream + ContentLength) to keep
 *     Node heap usage flat regardless of individual file size (R4 P1-2).
 *   - dry-run mode lists what *would* upload without contacting COS PUT.
 *
 * Loads COS_* env vars from one of:
 *   - apps/api/scripts/content_pipeline/.env (PR-C location; preferred)
 *   - apps/api/.env (server)
 * via the dotenv npm package (R4 P2-2).
 */

import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

import {
  S3Client,
  PutObjectCommand,
  HeadObjectCommand,
} from '@aws-sdk/client-s3';
import * as dotenv from 'dotenv';

// ---------- env loading (R4 P2-2: use dotenv npm) ----------
let envLoaded = false;
function loadEnv(): void {
  if (envLoaded) return;
  envLoaded = true;
  const candidates = [
    path.resolve(__dirname, 'content_pipeline', '.env'),
    path.resolve(__dirname, '..', '.env'),
  ];
  for (const envPath of candidates) {
    if (fs.existsSync(envPath)) {
      // override:false → existing process.env wins (CI / shell-export friendly)
      dotenv.config({ path: envPath, override: false });
    }
  }
}

// ---------- COS client ----------
export interface CosCreds {
  region: string;
  bucket: string;
  secretId: string;
  secretKey: string;
}

export function readCosCredsOrExit(): CosCreds {
  loadEnv();
  const region = process.env.COS_REGION || 'ap-shanghai';
  const bucket = process.env.COS_BUCKET;
  const secretId = process.env.COS_SECRET_ID;
  const secretKey = process.env.COS_SECRET_KEY;
  if (!bucket || !secretId || !secretKey) {
    console.error(
      'ERROR: COS_BUCKET / COS_SECRET_ID / COS_SECRET_KEY missing.\n' +
        '       Expected in apps/api/scripts/content_pipeline/.env (PR-C).',
    );
    process.exit(2);
  }
  return { region, bucket, secretId, secretKey };
}

export function buildCosClient(creds: CosCreds): S3Client {
  return new S3Client({
    region: creds.region,
    endpoint: `https://cos.${creds.region}.myqcloud.com`,
    credentials: {
      accessKeyId: creds.secretId,
      secretAccessKey: creds.secretKey,
    },
  });
}

// ---------- file walking ----------
async function* walkByExt(
  dir: string,
  ext: string,
  base = '',
): AsyncGenerator<{ abs: string; rel: string }> {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const abs = path.join(dir, entry.name);
    const rel = path.posix.join(base, entry.name);
    if (entry.isDirectory()) {
      yield* walkByExt(abs, ext, rel);
    } else if (entry.isFile() && entry.name.toLowerCase().endsWith(ext)) {
      yield { abs, rel };
    }
  }
}

function md5sumFile(filePath: string): string {
  const hash = crypto.createHash('md5');
  hash.update(fs.readFileSync(filePath));
  return hash.digest('hex');
}

// ---------- main sync entry ----------
export interface SyncOptions {
  src: string;
  prefix: string;
  fileExt: string; // include leading dot, e.g. '.mp3'
  contentType: string;
  cacheControl: string;
  commit: boolean;
}

export interface SyncResult {
  total: number;
  uploaded: number;
  skipped: number;
  totalBytes: number;
}

export async function syncDirectoryToCos(
  opts: SyncOptions,
): Promise<SyncResult> {
  const creds = readCosCredsOrExit();
  const client = buildCosClient(creds);

  if (!fs.existsSync(opts.src)) {
    console.error(`ERROR: src dir not found: ${opts.src}`);
    process.exit(2);
  }
  if (!fs.statSync(opts.src).isDirectory()) {
    console.error(`ERROR: src is not a directory: ${opts.src}`);
    process.exit(2);
  }

  console.log(`mode:    ${opts.commit ? 'COMMIT' : 'DRY-RUN'}`);
  console.log(`src:     ${opts.src}`);
  console.log(`prefix:  ${opts.prefix}`);
  console.log(`bucket:  ${creds.bucket}`);
  console.log(`region:  ${creds.region}`);
  console.log('');

  let total = 0;
  let uploaded = 0;
  let skipped = 0;
  let totalBytes = 0;

  for await (const { abs, rel } of walkByExt(opts.src, opts.fileExt)) {
    total++;
    const key = path.posix.join(opts.prefix, rel);
    const size = fs.statSync(abs).size;
    totalBytes += size;

    // Idempotent: HEAD ETag check. COS single-PUT (< 5GB) returns md5 hex
    // wrapped in quotes; multipart PUT uses a different scheme but we never
    // multipart here so md5 comparison is safe.
    let needUpload = true;
    try {
      const head = await client.send(
        new HeadObjectCommand({ Bucket: creds.bucket, Key: key }),
      );
      const remoteEtag = (head.ETag || '').replace(/"/g, '');
      const localMd5 = md5sumFile(abs);
      if (remoteEtag === localMd5) {
        needUpload = false;
        skipped++;
      }
    } catch (err: unknown) {
      const e = err as { $metadata?: { httpStatusCode?: number }; name?: string };
      const status = e?.$metadata?.httpStatusCode;
      if (status !== 404 && status !== 403 && e?.name !== 'NotFound') {
        // 403 from COS often means object missing on bucket-wide policy
        throw err;
      }
    }

    if (!needUpload) continue;

    if (!opts.commit) {
      console.log(`  [dry] would upload ${rel} (${size.toLocaleString()} bytes)`);
      uploaded++;
      continue;
    }

    // R4 P1-2: stream the body. Reading multi-GB into memory is OOM-prone.
    // ContentLength is required when Body is a Readable stream because S3
    // cannot infer length from a stream.
    await client.send(
      new PutObjectCommand({
        Bucket: creds.bucket,
        Key: key,
        Body: fs.createReadStream(abs),
        ContentLength: size,
        ContentType: opts.contentType,
        CacheControl: opts.cacheControl,
        ACL: 'public-read',
      }),
    );
    uploaded++;
    if (uploaded % 50 === 0) {
      console.log(`  uploaded ${uploaded}/${total} (skipped ${skipped})`);
    }
  }

  console.log('');
  console.log(
    `done. total=${total} uploaded=${uploaded} skipped=${skipped} totalBytes=${totalBytes.toLocaleString()}`,
  );
  return { total, uploaded, skipped, totalBytes };
}

// ---------- shared CLI arg parser ----------
export interface CliArgs {
  src: string;
  prefix: string;
  commit: boolean;
}

export function parseSyncArgs(toolName: string): CliArgs {
  const argv = process.argv.slice(2);
  const get = (flag: string): string | null => {
    const i = argv.indexOf(flag);
    return i >= 0 && i + 1 < argv.length ? argv[i + 1] : null;
  };
  const has = (flag: string): boolean => argv.includes(flag);

  const src = get('--src');
  const prefix = get('--prefix');
  if (!src || !prefix) {
    console.error(
      `Usage: ts-node ${toolName}.ts --src <dir> --prefix <cos-prefix> [--commit | --dry-run]\n\n` +
        `  --src     Local directory to walk (e.g. cdn-mock/audio/v1)\n` +
        `  --prefix  COS key prefix (e.g. audio/v1)\n` +
        `  --commit  Actually upload to COS (default is dry-run)\n` +
        `  --dry-run Explicit dry-run (default behavior)\n`,
    );
    process.exit(2);
  }
  if (has('--commit') && has('--dry-run')) {
    console.error('ERROR: cannot specify both --commit and --dry-run');
    process.exit(2);
  }
  return { src, prefix, commit: has('--commit') };
}
