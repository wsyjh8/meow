-- 004_audio_assets_pilot.sql
-- v0.3.0 candidate pilot: examples + audio_assets + content_manifest
--
-- Purpose: minimum viable slice to ingest local TTS pipeline output.
--          Does NOT modify existing v0.2.x word/word_book/study_attempts tables.
--          Sits beside them as 3 new tables.
--
-- References:
--   docs/design/DB_TARGET_ARCHITECTURE_v0.3.0_candidate.md  §4.5 / §4.6 / §4.7
--   docs/design/AUDIO_GENERATION_PIPELINE_v0.1_local_windows.md  v0.1.2
--   docs/design/audio_contract.yaml
--   apps/api/scripts/audio-pipeline/  (Codex output)
--
-- FK note: examples.word_id intentionally has NO FK to v0.2.x `words.id`
--   because v0.2.x uses book-prefixed PK (e.g. 'cet4-abandon') while v0.3.0
--   stable_id derivation uses normalized word ('abandon'). Cross-referencing
--   will be enabled in P1 when word_book_memberships ships and v0.2.x words
--   table is restructured. For pilot, examples.word_id is plain VARCHAR.
--
-- audio_assets.target_id similarly has NO FK to examples.stable_id at SQL level
--   to allow target_kind='word' (target_id = words.id normalized form). Referential
--   integrity is enforced at release-gate level (see DB §4.6.2).

-- UP

-- ---------- examples ----------
CREATE TABLE IF NOT EXISTS examples (
  id            BIGSERIAL PRIMARY KEY,
  stable_id     VARCHAR(28) NOT NULL UNIQUE,        -- sha256_24(canonical_json([word_id, normalize_text(en)]))
  word_id       VARCHAR(64) NOT NULL,                -- normalized form (e.g. 'abandon'); no FK pilot phase
  sense_id      VARCHAR(80),                         -- nullable, P3 word_senses fills
  sense_label   VARCHAR(200),                        -- free-text fallback ('v. 放弃；抛弃')
  en            TEXT NOT NULL,                       -- raw, pre-normalize, may contain [bracket] markers
  cn            TEXT NOT NULL,
  ordinal       INT NOT NULL DEFAULT 0,              -- position in word's example list
  difficulty    VARCHAR(16),                         -- 'high_school' | 'cet4' | 'cet6' | ...
  generator     VARCHAR(32),                         -- 'claude-sonnet-4-6'
  generated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
  -- v0.3.0 P2.1: NO UNIQUE(word_id, ordinal). Same word can appear in
  -- multiple wordbooks (e.g. "a" in zk AND gk) with their own example
  -- pools. Each book numbers its examples 0..N independently, so cross-book
  -- ordinal collisions are normal. The canonical identifier is stable_id.
);

CREATE INDEX IF NOT EXISTS idx_examples_word_id   ON examples(word_id);
CREATE INDEX IF NOT EXISTS idx_examples_stable_id ON examples(stable_id);

-- ---------- audio_assets ----------
CREATE TABLE IF NOT EXISTS audio_assets (
  id                 VARCHAR(28) PRIMARY KEY,        -- sha256_24(canonical_json([kind, target_id, locale, voice, format, audio_version]))
  target_kind        VARCHAR(16) NOT NULL,           -- 'example' | 'word'
  target_id          VARCHAR(64) NOT NULL,           -- examples.stable_id OR normalized word_id
  locale             VARCHAR(16) NOT NULL,           -- 'en-US' | 'en-GB'
  voice              VARCHAR(32) NOT NULL,           -- 'af_bella' / 'am_michael' / ...
  accent             VARCHAR(8),                     -- 'us' / 'uk' / 'au'
  gender             VARCHAR(8),                     -- 'f' / 'm' / 'n'
  format             VARCHAR(8) NOT NULL,            -- 'mp3' (future: 'opus')
  audio_version      VARCHAR(32) NOT NULL,           -- 'v1' (must match contract pattern '^v[0-9]+$')
  checksum_sha256    VARCHAR(64) NOT NULL,           -- of binary mp3 content
  source_text_hash   VARCHAR(16) NOT NULL,           -- sha256_16(normalize_text(en)) — release gate field
  tts_provider       VARCHAR(32) NOT NULL,           -- 'kokoro-local' / 'openai' / 'azure'
  tts_model          VARCHAR(64) NOT NULL,           -- 'hexgrad/Kokoro-82M'
  tts_model_version  VARCHAR(64),                    -- 'kokoro-82m-v1'
  bytes              INT NOT NULL,
  duration_ms        INT NOT NULL,
  url                TEXT NOT NULL,                  -- CDN URL (or 'local://...' before publish)
  status             VARCHAR(16) NOT NULL DEFAULT 'ready',  -- 'ready' / 'qc_failed' / 'superseded' / 'gc_deleted' / 'pending'
  composite_label    VARCHAR(128),                   -- debug only, e.g. 'example:abc123:en-US:af_bella:v1'
  generated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audio_assets_target
  ON audio_assets(target_kind, target_id, status);
-- Lookup hot path: App resolves audio by (target_id + voice + format + audio_version)
CREATE INDEX IF NOT EXISTS idx_audio_assets_lookup
  ON audio_assets(target_id, voice, format, audio_version, status);

-- ---------- content_manifest ----------
CREATE TABLE IF NOT EXISTS content_manifest (
  id               VARCHAR(64) PRIMARY KEY,          -- '{package_name}@{content_version}', e.g. 'audio-meta-cet4@v1'
  package_name     VARCHAR(64) NOT NULL,             -- 'audio-meta-cet4' / 'wordbook-zk' / 'morphemes' / ...
  package_kind     VARCHAR(16) NOT NULL,             -- 'audio_meta' / 'wordbook' / 'dictionary'
  content_version  VARCHAR(16) NOT NULL,             -- 'v1' / 'v2' / ...
  file_url         TEXT,                              -- nullable; audio_meta points to manifest jsonl, not single file
  checksum_sha256  VARCHAR(64),
  size_bytes       BIGINT,
  min_app_version  VARCHAR(16) NOT NULL DEFAULT '0.0.0',
  is_active        BOOLEAN NOT NULL DEFAULT FALSE,
  generated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_content_manifest_active
  ON content_manifest(package_name, is_active);

-- DOWN

DROP INDEX IF EXISTS idx_content_manifest_active;
DROP TABLE IF EXISTS content_manifest;

DROP INDEX IF EXISTS idx_audio_assets_lookup;
DROP INDEX IF EXISTS idx_audio_assets_target;
DROP TABLE IF EXISTS audio_assets;

DROP INDEX IF EXISTS idx_examples_stable_id;
DROP INDEX IF EXISTS idx_examples_word_id;
DROP TABLE IF EXISTS examples;
