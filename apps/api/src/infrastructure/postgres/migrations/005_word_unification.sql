-- 005_word_unification.sql
-- v0.3.0 P1: CET-4 收编 + words 拆 word_book_memberships
--
-- v0.2.x baseline stored words.id as 'cet4-abandon' / 'zk-abandon' /
-- 'gk-abandon' (book-prefixed PK). Six dependent tables (study_attempts,
-- review_attempts, review_group_items, user_word_progress, examples,
-- audio_assets) reference these prefixed ids.
--
-- v0.3.0 P1 collapses this to a canonical PK: words.id = 'abandon' (lowercase
-- normalized form, no prefix). Book membership moves to a M:N association
-- table `word_book_memberships(word_id, book_id, sort_order, source_key)`.
--
-- Strategy (per approved plan): TRUNCATE + reseed.
--   - Dev-only environment, no real users → safe to drop all data.
--   - Avoids the complexity of a per-row UPDATE migration script.
--   - Rerun `npm run db:reset` after this migration to re-populate.
--
-- This migration intentionally does NOT preserve user state. If real-user
-- data ever needs to be migrated, write a separate one-shot script BEFORE
-- running this and apply it as a no-op replacement.
--
-- References:
--   - docs/design/DB_TARGET_ARCHITECTURE_v0.3.0_candidate.md §4.2 / §4.3 / §9 (P1)
--   - apps/api/src/lib/stable-id.ts (normalize_word algorithm)

-- UP

-- 1. Clear all word_id-referencing data. CASCADE handles dependent rows
--    (review_group_items follows review_groups; user_word_progress,
--    review_attempts, study_attempts have FKs to words.id).
TRUNCATE TABLE
  audio_assets,
  examples,
  user_word_progress,
  review_attempts,
  review_group_items,
  study_attempts
CASCADE;

-- 2. Restructure `words` table to v0.3.0 canonical form.
--    - drop the FK to word_books (book membership moves out)
--    - drop columns that no longer belong on a word: book_id, word_type, sort_order
--    - add updated_at to align with v0.3.0 §4.2
ALTER TABLE words DROP CONSTRAINT IF EXISTS words_book_id_fkey;
ALTER TABLE words DROP COLUMN IF EXISTS book_id;
ALTER TABLE words DROP COLUMN IF EXISTS word_type;
ALTER TABLE words DROP COLUMN IF EXISTS sort_order;
ALTER TABLE words ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
TRUNCATE TABLE words CASCADE;

-- 3. Create `word_book_memberships` (M:N words ↔ word_books).
CREATE TABLE IF NOT EXISTS word_book_memberships (
  word_id    VARCHAR(64) NOT NULL REFERENCES words(id) ON DELETE CASCADE,
  book_id    VARCHAR(64) NOT NULL REFERENCES word_books(id) ON DELETE CASCADE,
  sort_order INT NOT NULL DEFAULT 0,
  source_key VARCHAR(64),  -- e.g. 'cet4-1234' for CSV row traceability
  PRIMARY KEY (word_id, book_id)
);

CREATE INDEX IF NOT EXISTS idx_wbm_book_sort
  ON word_book_memberships(book_id, sort_order);

-- DOWN

DROP INDEX IF EXISTS idx_wbm_book_sort;
DROP TABLE IF EXISTS word_book_memberships;

ALTER TABLE words DROP COLUMN IF EXISTS updated_at;
ALTER TABLE words ADD COLUMN IF NOT EXISTS book_id VARCHAR(64);
ALTER TABLE words ADD COLUMN IF NOT EXISTS word_type VARCHAR(32) NOT NULL DEFAULT 'new';
ALTER TABLE words ADD COLUMN IF NOT EXISTS sort_order INT NOT NULL DEFAULT 0;

-- Note: DOWN restores schema only, NOT data. After rolling back this
-- migration, run `npm run db:reset` to repopulate with v0.2.x-shape data
-- (which requires also rolling back the seed script — see git history).
