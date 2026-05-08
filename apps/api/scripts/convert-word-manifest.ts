/**
 * One-off converter: word_audio_manifest.jsonl → audio_assets.jsonl
 *
 * Background: the local Kokoro word-audio pipeline emits
 *   word_audio_manifest.jsonl with its own schema (mp3_path, word, stage, ...).
 * The server ingest tool (scripts/ingest-audio-assets.ts) expects the
 * canonical audio_assets.jsonl schema (id, target_kind, target_id, url, ...).
 *
 * This script reads the word manifest and emits a v0.3.0-compatible
 * audio_assets.jsonl into the same directory, ready for ingest with:
 *   --audio-jsonl <out>/audio_assets.jsonl
 *   --manifest-id audio-meta-words@v1
 *   --package-name audio-meta-words
 *
 * Usage:
 *   npx ts-node scripts/convert-word-manifest.ts \
 *     --src   D:/code/AI/startUp/meow/temp/out/mp3/words/word_audio_manifest.jsonl \
 *     --out   D:/code/AI/startUp/meow/temp/out/mp3/words/audio_assets.jsonl
 *
 * Idempotent: overwrites --out. Skips rows where stage != 'ready'.
 */

import * as fs from 'fs';
import * as crypto from 'crypto';

interface WordManifestRow {
  word: string;
  locale: string;       // e.g. "en-US", "en-GB"
  voice: string;        // e.g. "af_bella", "am_michael", "bf_emma"
  audio_version: string;
  shard: string;        // e.g. "a"
  mp3_path: string;     // e.g. "out_mp3/en-GB/bf_emma/v1/a/a.mp3"
  bytes: number;
  duration_ms: number;
  checksum_sha256: string;
  converted_at: string;
  stage: string;
  last_error: string | null;
}

interface AudioAssetRow {
  id: string;
  target_kind: 'word';
  target_id: string;
  locale: string;
  voice: string;
  accent: string | null;
  gender: string | null;
  format: 'mp3';
  audio_version: string;
  checksum_sha256: string;
  source_text_hash: string;
  tts_provider: string;
  tts_model: string;
  tts_model_version: string;
  bytes: number;
  duration_ms: number;
  url: string;
  status: string;
  composite_label: string;
  generated_at: string;
}

// ---------- arg parsing ----------
function parseArgs(): { src: string; out: string } {
  const argv = process.argv.slice(2);
  const get = (k: string): string | undefined => {
    const i = argv.indexOf(k);
    return i >= 0 && i + 1 < argv.length ? argv[i + 1] : undefined;
  };
  const src = get('--src');
  const out = get('--out');
  if (!src || !out) {
    console.error(
      'Usage: ts-node scripts/convert-word-manifest.ts --src <input.jsonl> --out <output.jsonl>',
    );
    process.exit(2);
  }
  return { src, out };
}

// ---------- field derivers ----------

// locale → accent: en-US → "us", en-GB → "gb", others → null (don't guess)
function deriveAccent(locale: string): string | null {
  if (locale === 'en-US') return 'us';
  if (locale === 'en-GB') return 'gb';
  return null;
}

// Kokoro voice naming: <locale-letter><gender-letter>_<name>
//   af_bella  → a/f → us/female
//   am_michael→ a/m → us/male
//   bf_emma   → b/f → gb/female
//   bm_*      → b/m → gb/male
function deriveGender(voice: string): string | null {
  const m = voice.match(/^[ab]([fm])_/);
  return m ? m[1] : null;
}

function md5Hex(input: string): string {
  return crypto.createHash('md5').update(input).digest('hex');
}

// ---------- conversion ----------
function convertRow(w: WordManifestRow): AudioAssetRow | null {
  if (w.stage !== 'ready') return null;
  if (!w.checksum_sha256) {
    console.warn(`[skip] missing checksum: word=${w.word} locale=${w.locale} voice=${w.voice}`);
    return null;
  }

  // id: first 24 hex chars of sha256, matches examples' 24-char id pattern.
  // checksum_sha256 is content-addressed → guaranteed unique per (word,locale,voice,version).
  const id = w.checksum_sha256.slice(0, 24);

  // url: rewrite to canonical local://cdn/ form. Ingest will replace with AUDIO_CDN_ORIGIN.
  // Layout matches what cos sync-audio-mp3 uploaded under prefix audio/v1/words/.
  const url = `local://cdn/audio/v1/words/${w.locale}/${w.voice}/${w.audio_version}/${w.shard}/${w.word}.mp3`;

  return {
    id,
    target_kind: 'word',
    target_id: w.word,
    locale: w.locale,
    voice: w.voice,
    accent: deriveAccent(w.locale),
    gender: deriveGender(w.voice),
    format: 'mp3',
    audio_version: w.audio_version,
    checksum_sha256: w.checksum_sha256,
    source_text_hash: md5Hex(w.word).slice(0, 16),
    tts_provider: 'kokoro-local',
    tts_model: 'hexgrad/Kokoro-82M',
    tts_model_version: 'kokoro-82m-v1',
    bytes: w.bytes,
    duration_ms: w.duration_ms,
    url,
    status: 'ready',
    composite_label: `word:${w.word}:${w.locale}:${w.voice}:${w.audio_version}`,
    generated_at: w.converted_at,
  };
}

// ---------- main ----------
function main() {
  const { src, out } = parseArgs();

  if (!fs.existsSync(src)) {
    console.error(`ERROR: src not found: ${src}`);
    process.exit(2);
  }

  const raw = fs.readFileSync(src, 'utf-8');
  const lines = raw.split('\n').filter((l) => l.trim().length > 0);

  console.log(`--- word manifest → audio_assets converter ---`);
  console.log(`  src:  ${src}`);
  console.log(`  out:  ${out}`);
  console.log(`  rows: ${lines.length}`);
  console.log('');

  const idsSeen = new Map<string, string>(); // id → composite_label (collision check)
  const writer = fs.createWriteStream(out, { encoding: 'utf-8' });

  let converted = 0;
  let skipped = 0;
  const stageCounts: Record<string, number> = {};

  for (let i = 0; i < lines.length; i++) {
    let row: WordManifestRow;
    try {
      row = JSON.parse(lines[i]) as WordManifestRow;
    } catch (e) {
      console.error(`[skip] line ${i + 1}: invalid JSON (${(e as Error).message})`);
      skipped++;
      continue;
    }

    stageCounts[row.stage] = (stageCounts[row.stage] || 0) + 1;

    const out = convertRow(row);
    if (!out) {
      skipped++;
      continue;
    }

    // Defensive: id collision = different content with truncation collision.
    // 24 hex chars = 96 bits → astronomically unlikely but log if it happens.
    const prev = idsSeen.get(out.id);
    if (prev && prev !== out.composite_label) {
      console.warn(`[warn] id collision id=${out.id}: prev=${prev} curr=${out.composite_label}`);
    }
    idsSeen.set(out.id, out.composite_label);

    writer.write(JSON.stringify(out) + '\n');
    converted++;
  }

  writer.end(() => {
    console.log(`done.`);
    console.log(`  converted: ${converted}`);
    console.log(`  skipped:   ${skipped}`);
    console.log(`  stages:    ${JSON.stringify(stageCounts)}`);
    console.log(`  unique ids: ${idsSeen.size}`);
    console.log(`  out file:  ${out}`);
  });
}

main();
