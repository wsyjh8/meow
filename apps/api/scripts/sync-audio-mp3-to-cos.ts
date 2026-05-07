/**
 * PR-D Option A: Sync local audio mp3 files to Tencent COS.
 *
 * Walks --src, finds *.mp3, uploads to COS at <bucket>/<--prefix>/<rel>.
 * Idempotent (HEAD ETag check skips identical content). Streams body to
 * keep memory flat (R4 P1-2).
 *
 * Path layout (R4 P1#1: --src already nests under audio/v1, so --prefix
 * audio/v1 keeps single layer; no double prefix):
 *   --src cdn-mock/audio/v1   --prefix audio/v1
 *   cdn-mock/audio/v1/examples/en-US/af_bella/v1/ab/abc.mp3
 *   → COS key: audio/v1/examples/en-US/af_bella/v1/ab/abc.mp3
 *
 * Usage:
 *   npx ts-node scripts/sync-audio-mp3-to-cos.ts \
 *     --src cdn-mock/audio/v1 \
 *     --prefix audio/v1 \
 *     [--commit | --dry-run]
 */

import {
  parseSyncArgs,
  syncDirectoryToCos,
} from './cos-sync-helper';

async function main(): Promise<void> {
  const args = parseSyncArgs('sync-audio-mp3-to-cos');
  await syncDirectoryToCos({
    src: args.src,
    prefix: args.prefix,
    fileExt: '.mp3',
    contentType: 'audio/mpeg',
    // audio_id is content-addressable + version-pathed; never overwritten in
    // place → safe to mark immutable for 1y (matches old /cdn static route
    // header in main.ts).
    cacheControl: 'public, max-age=31536000, immutable',
    commit: args.commit,
  });
}

main().catch((err) => {
  console.error('ERROR:', err);
  process.exit(1);
});
