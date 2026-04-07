-- 002: Word table restructure for CET-4 CSV import
-- Adds rich metadata fields to support mainstream vocabulary app features

-- UP
ALTER TABLE words ADD COLUMN IF NOT EXISTS translation TEXT;
ALTER TABLE words ADD COLUMN IF NOT EXISTS definition TEXT;
ALTER TABLE words ADD COLUMN IF NOT EXISTS difficulty_level INT NOT NULL DEFAULT 0;
ALTER TABLE words ADD COLUMN IF NOT EXISTS is_core BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE words ADD COLUMN IF NOT EXISTS tags TEXT;
ALTER TABLE words ADD COLUMN IF NOT EXISTS frequency_rank INT NOT NULL DEFAULT 0;
ALTER TABLE words ADD COLUMN IF NOT EXISTS word_forms TEXT;

CREATE INDEX IF NOT EXISTS idx_words_frequency ON words(frequency_rank);

-- DOWN
DROP INDEX IF EXISTS idx_words_frequency;
ALTER TABLE words DROP COLUMN IF EXISTS word_forms;
ALTER TABLE words DROP COLUMN IF EXISTS frequency_rank;
ALTER TABLE words DROP COLUMN IF EXISTS tags;
ALTER TABLE words DROP COLUMN IF EXISTS is_core;
ALTER TABLE words DROP COLUMN IF EXISTS difficulty_level;
ALTER TABLE words DROP COLUMN IF EXISTS definition;
ALTER TABLE words DROP COLUMN IF EXISTS translation;
