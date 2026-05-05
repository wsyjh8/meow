"""
Stable ID reference implementation (Python).

SSOT: docs/design/DB_TARGET_ARCHITECTURE_v0.3.0_candidate.md §3.4
Contract: docs/design/audio_contract.yaml

This is the **canonical reference implementation** — all other ports
(TypeScript apps/api/src/lib/stable-id.ts, Dart apps/mobile/lib/core/util/
stable_id.dart) MUST produce byte-identical output for every fixture in
tests/fixtures/.

Used by:
  - Local Windows TTS pipeline (Codex audio-pipeline) for stable_id /
    audio_id / source_text_hash computation
  - Fixture-fill script (scripts/audio_pipeline/fill_fixtures.py) to
    materialize the golden expected values from input data
"""

from __future__ import annotations

import hashlib
import json
import re
import unicodedata
from typing import Sequence


# =============================================================================
# Normalization (per DB §3.2)
# =============================================================================

_WHITESPACE_RUN = re.compile(r"\s+")


def normalize_word(s: str) -> str:
    """
    Derive the canonical form of a word for `words.id`.

    Algorithm (DB §3.2.1):
      1. NFC unicode normalization
      2. trim() leading/trailing whitespace
      3. lowercase()
      4. Collapse internal whitespace to single ASCII space
      5. Preserve hyphens, apostrophes, diacritics
    """
    s = unicodedata.normalize("NFC", s)
    s = s.strip().lower()
    s = _WHITESPACE_RUN.sub(" ", s)
    return s


def normalize_text(s: str) -> str:
    """
    Normalize an example sentence before hashing into stable_id.

    Algorithm (DB §3.2.2):
      1. NFC unicode normalization
      2. trim()
      3. Collapse all whitespace to single ASCII space
      4. Preserve case (sentence-initial capitals are meaningful)
      5. Preserve [bracket] highlight markers, apostrophes, hyphens
    """
    s = unicodedata.normalize("NFC", s)
    s = s.strip()
    s = _WHITESPACE_RUN.sub(" ", s)
    return s


# =============================================================================
# Canonical JSON (per DB §3.4.1)
# =============================================================================


def canonical_json_bytes(arr: Sequence) -> bytes:
    """
    Serialize a flat array to byte-identical canonical JSON for hashing.

    Strict rules (audio_contract.yaml §hash):
      - separators: (",", ":") — compact, no whitespace
      - ensure_ascii: false — non-ASCII NOT escaped
      - no null in array
      - no nested structures
    """
    for v in arr:
        if v is None:
            raise ValueError("canonical JSON array must not contain null")
        if isinstance(v, (list, tuple, dict)):
            raise ValueError(
                "canonical JSON array must not contain nested structures"
            )
        if not isinstance(v, (str, int)):
            raise ValueError(
                f"canonical JSON array element must be str or int, got {type(v).__name__}"
            )
    return json.dumps(list(arr), ensure_ascii=False, separators=(",", ":")).encode(
        "utf-8"
    )


# =============================================================================
# SHA-256 truncation (per DB §3.4.2)
# =============================================================================


def sha256_24(data: bytes) -> str:
    """SHA-256 hex digest, truncated to 24 lowercase hex chars (96-bit output)."""
    return hashlib.sha256(data).hexdigest()[:24]


def sha256_16(data: bytes) -> str:
    """SHA-256 hex digest, truncated to 16 lowercase hex chars (64-bit output).
    Used for `audio_assets.source_text_hash` (audit / release-gate, NOT a PK)."""
    return hashlib.sha256(data).hexdigest()[:16]


# =============================================================================
# Stable ID computation (per DB §3.1)
# =============================================================================


def compute_example_stable_id(word_id: str, raw_en: str) -> str:
    """
    Compute examples.stable_id.

    Formula:
      stable_id = sha256_24(canonical_json([word_id, normalize_text(en)]))

    word_id should already be normalized by the caller (use normalize_word).
    """
    return sha256_24(canonical_json_bytes([word_id, normalize_text(raw_en)]))


def compute_audio_id(
    *,
    target_kind: str,
    target_id: str,
    locale: str,
    voice: str,
    fmt: str,
    audio_version: str,
) -> str:
    """
    Compute audio_assets.id.

    Formula:
      audio_id = sha256_24(canonical_json([
        target_kind, target_id, locale, voice, format, audio_version
      ]))

    audio_version is in the hash so TTS regen → new audio_id → new CDN URL.
    """
    return sha256_24(
        canonical_json_bytes(
            [target_kind, target_id, locale, voice, fmt, audio_version]
        )
    )


def compute_source_text_hash(target_kind: str, input_for_example: str) -> str:
    """
    Compute audio_assets.source_text_hash for release-gate validation.

    For 'example' targets: hash of normalize_text(examples.en).
    For 'word' targets:    hash of target_id (already-normalized word_id).
    """
    if target_kind == "example":
        return sha256_16(normalize_text(input_for_example).encode("utf-8"))
    return sha256_16(input_for_example.encode("utf-8"))


# =============================================================================
# Example row content_hash (per v0.3 §B.4.2 — added in PR-A Day 2)
# =============================================================================


def compute_example_content_hash(
    *,
    stable_id: str,
    word_id: str,
    sense_label: str | None,
    en: str,
    cn: str,
    difficulty: str | None,
    ordinal: int,
    status: str,
) -> str:
    """
    Row-level fingerprint for client diff (v0.3 §B.4.2).

    Relationship to stable_id:
      - stable_id only binds the English sentence (normalize_text(en))
      - content_hash covers ALL package-visible fields; any change flips it
      - Edit cn translation: stable_id stays, content_hash changes →
        client row-diff triggers UPDATE locally
      - Edit en sentence: new stable_id → new examples row → old row deprecated

    Ordinal semantics (PR-A Day 2 review answer):
      ordinal is a row-level FIXED field, set at migration 004 import time
      based on each source-book's 0..4 numbering. The same word appearing
      in multiple source books gets multiple example rows (each with a
      distinct stable_id), each numbered 0..4 within its own source set.
      ordinal does NOT vary across packages — safe to include in row-level
      content_hash.

    NULL handling:
      sense_label / difficulty default to "" (empty string) when NULL —
      canonical_json forbids None entries (cross-language ambiguity).

    Algorithm:
      sha256_24(canonical_json([
        stable_id, word_id, sense_label or "", en, cn,
        difficulty or "", str(ordinal), status
      ]))

    Returns: 24-char lowercase hex.
    """
    return sha256_24(
        canonical_json_bytes(
            [
                stable_id,
                word_id,
                sense_label or "",
                en,
                cn,
                difficulty or "",
                str(ordinal),  # int → str: canonical_json strings only
                status,
            ]
        )
    )
