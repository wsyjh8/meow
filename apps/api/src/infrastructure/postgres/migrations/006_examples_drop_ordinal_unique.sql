-- 006_examples_drop_ordinal_unique.sql
-- v0.3.0 P2.1 fix: drop UNIQUE(word_id, ordinal) on examples.
--
-- The constraint was a v0.2.x hangover that assumed each word has one
-- canonical example list with stable ordinals. In v0.3.0 the same word_id
-- (e.g. 'a' in both ZK and GK) can carry independent example pools from
-- different wordbooks; their ordinal numbering naturally collides.
--
-- Examples are identified by stable_id (content hash). Ordinal is purely
-- a display hint within a per-book context. No UNIQUE needed.

-- UP

ALTER TABLE examples DROP CONSTRAINT IF EXISTS examples_word_id_ordinal_key;

-- DOWN

-- Cannot easily restore the UNIQUE constraint — would fail if cross-book
-- duplicates were inserted. Down is a no-op.
