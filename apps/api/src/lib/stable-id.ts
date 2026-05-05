/**
 * Stable ID reference implementation (TypeScript).
 *
 * SSOT: docs/design/DB_TARGET_ARCHITECTURE_v0.3.0_candidate.md §3.4
 * Contract: docs/design/audio_contract.yaml
 *
 * **Critical:** This implementation MUST produce byte-identical output to:
 *   - Python reference (apps/api/scripts/audio_pipeline/reference.py)
 *   - Dart reference (apps/mobile/lib/core/util/stable_id.dart)
 *
 * Verified by golden tests in tests/fixtures/{canonical_json,normalize_text,
 * normalize_word,stable_id,audio_id}.yaml — every port runs the same fixtures.
 */

import { createHash } from 'crypto';

// ============================================================================
// Normalization (per DB §3.2)
// ============================================================================

/**
 * `normalize_word(s)` — used to derive `words.id` from raw word_text.
 *
 * Algorithm (DB §3.2.1):
 *   1. NFC unicode normalization
 *   2. trim() leading/trailing whitespace
 *   3. lowercase()
 *   4. Collapse internal whitespace to single ASCII space
 *   5. Preserve hyphens, apostrophes, diacritics
 *
 * Multi-word phrases are NOT entered into the words table; this function
 * doesn't reject them, but callers should route phrases to word_phrases.
 */
export function normalizeWord(s: string): string {
  return s
    .normalize('NFC')
    .trim()
    .toLowerCase()
    .replace(/\s+/g, ' ');
}

/**
 * `normalize_text(s)` — used for example sentences before hashing into stable_id.
 *
 * Algorithm (DB §3.2.2):
 *   1. NFC unicode normalization
 *   2. trim()
 *   3. Collapse all whitespace (\t \n \r U+00A0) to single ASCII space
 *   4. Preserve case (sentence case is meaningful)
 *   5. Preserve [bracket] highlight markers
 *
 * Why aggressive whitespace collapse: CSV imports often introduce trailing
 * \r\n or stray tabs; without folding, two physically equivalent sentences
 * would get different stable_ids.
 *
 * U+00A0 (non-breaking space) is folded because it's invisible whitespace.
 * \s in JS regex covers \t \n \r \f \v plus all unicode whitespace.
 */
export function normalizeText(s: string): string {
  return s
    .normalize('NFC')
    .trim()
    .replace(/\s+/g, ' ');
}

// ============================================================================
// Canonical JSON (per DB §3.4.1)
// ============================================================================

type CanonicalValue = string | number | null;

/**
 * Serialize an array to byte-identical canonical JSON for hashing.
 *
 * Strict rules (audio_contract.yaml §hash):
 *   - separators: (",", ":") — compact, no whitespace
 *   - ensure_ascii: false — non-ASCII characters NOT escaped
 *   - no null in array
 *   - no nested structures (only flat array of strings/ints)
 *
 * Returns a Uint8Array of UTF-8 bytes (no BOM).
 *
 * **JSON.stringify gotchas in Node:**
 *   - Default separators are already (",", ":") when no `space` arg passed
 *   - Non-ASCII chars are NOT escaped by default (matches ensure_ascii=false)
 *   - So the standard call IS canonical, given valid input
 */
export function canonicalJsonBytes(arr: CanonicalValue[]): Uint8Array {
  for (const v of arr) {
    if (v === null) {
      throw new Error('canonical JSON array must not contain null');
    }
    if (Array.isArray(v) || (typeof v === 'object' && v !== null)) {
      throw new Error('canonical JSON array must not contain nested structures');
    }
    if (typeof v !== 'string' && typeof v !== 'number') {
      throw new Error(`canonical JSON array element must be string or number, got ${typeof v}`);
    }
  }
  const json = JSON.stringify(arr);
  return new TextEncoder().encode(json);
}

// ============================================================================
// SHA-256 truncation (per DB §3.4.2)
// ============================================================================

/**
 * SHA-256 hex digest, truncated to 24 lowercase hex chars (96-bit output).
 * No uppercase, no base64, no other digest size — these are contract violations.
 */
export function sha256_24(data: Uint8Array): string {
  return createHash('sha256').update(data).digest('hex').slice(0, 24);
}

/**
 * SHA-256 hex digest truncated to 16 lowercase hex chars (64-bit).
 * Used for `audio_assets.source_text_hash` (audit / release-gate, NOT a PK).
 */
export function sha256_16(data: Uint8Array): string {
  return createHash('sha256').update(data).digest('hex').slice(0, 16);
}

// ============================================================================
// Stable ID computation (per DB §3.1)
// ============================================================================

/**
 * Compute `examples.stable_id` from word_id and raw English sentence.
 *
 * Formula:
 *   stable_id = sha256_24(canonical_json([word_id, normalize_text(en)]))
 *
 * Caller must already have normalized word_id (e.g. via normalizeWord);
 * this function does NOT re-normalize word_id to avoid double-application.
 */
export function computeExampleStableId(wordId: string, rawEn: string): string {
  return sha256_24(canonicalJsonBytes([wordId, normalizeText(rawEn)]));
}

/**
 * Compute `audio_assets.id` from the 6-tuple identifying a unique audio binary.
 *
 * Formula:
 *   audio_id = sha256_24(canonical_json([
 *     target_kind, target_id, locale, voice, format, audio_version
 *   ]))
 *
 * `audio_version` is part of the hash so TTS regeneration produces a fresh
 * audio_id (CDN-cache friendly, atomic publish, easy rollback). See DB §4.6.
 */
export function computeAudioId(params: {
  targetKind: 'word' | 'example';
  targetId: string;
  locale: string;
  voice: string;
  format: 'mp3' | 'opus';
  audioVersion: string;
}): string {
  return sha256_24(
    canonicalJsonBytes([
      params.targetKind,
      params.targetId,
      params.locale,
      params.voice,
      params.format,
      params.audioVersion,
    ]),
  );
}

/**
 * Compute `audio_assets.source_text_hash` for release-gate validation.
 *
 * For example targets: hash of `normalize_text(examples.en)`.
 * For word targets:    hash of `target_id` (already normalized word_id).
 */
export function computeSourceTextHash(
  targetKind: 'word' | 'example',
  inputForExample: string,
): string {
  if (targetKind === 'example') {
    const normalized = normalizeText(inputForExample);
    return sha256_16(new TextEncoder().encode(normalized));
  }
  // For words: target_id is already a normalized word_id; hash it directly.
  return sha256_16(new TextEncoder().encode(inputForExample));
}
