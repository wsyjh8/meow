/**
 * PR-D Option A: Sync local pronunciation wav files to Tencent COS.
 *
 * Walks --src, finds *.wav, uploads to COS at <bucket>/<--prefix>/<rel>.
 * Idempotent (HEAD ETag check skips identical content). Streams body to
 * keep memory flat (R4 P1-2).
 *
 * Path layout:
 *   --src data/pronunciation   --prefix pronunciation
 *   data/pronunciation/en-US/am_michael/v1/a/abandon.wav
 *   → COS key: pronunciation/en-US/am_michael/v1/a/abandon.wav
 *
 * Cache-Control aligned with audio mp3 (R4 Nit-10): wav path includes a v1
 * version segment, objects are never overwritten in place, so 1y immutable
 * is safe.
 *
 * Prerequisite (R4 P2-1): apps/api/data/pronunciation/ must exist on the
 * dev machine running this tool. See pr-d-plan.md §0.4 for the three
 * options if the directory is missing (back up restore / regenerate via
 * pipeline / skip the sync and accept F4 expected-fail).
 *
 * Usage:
 *   npx ts-node scripts/sync-pronunciation-to-cos.ts \
 *     --src data/pronunciation \
 *     --prefix pronunciation \
 *     [--commit | --dry-run]
 */

import {
  parseSyncArgs,
  syncDirectoryToCos,
} from './cos-sync-helper';

async function main(): Promise<void> {
  const args = parseSyncArgs('sync-pronunciation-to-cos');
  await syncDirectoryToCos({
    src: args.src,
    prefix: args.prefix,
    fileExt: '.wav',
    contentType: 'audio/wav',
    cacheControl: 'public, max-age=31536000, immutable',
    commit: args.commit,
  });
}

main().catch((err) => {
  console.error('ERROR:', err);
  process.exit(1);
});
