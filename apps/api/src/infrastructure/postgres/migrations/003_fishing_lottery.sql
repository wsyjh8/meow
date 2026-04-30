-- 003_fishing_lottery.sql
-- Phase D: Fishing mini-game + blind box lottery
-- Daily reset: Beijing time (UTC+8), 05:00 local

-- ========== Fishing Game ==========

-- One row per user per effective day (Beijing 05:00 reset).
-- task_date stores the Beijing effective date string (e.g. '2026-04-29').
CREATE TABLE daily_fishing_tasks (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  task_date DATE NOT NULL,
  rounds_completed INT NOT NULL DEFAULT 0,
  rounds_total INT NOT NULL DEFAULT 3,
  status VARCHAR(16) NOT NULL DEFAULT 'available', -- available | exhausted
  current_round_fish_word_id VARCHAR(64) REFERENCES words(id),
  current_round_fish_word_meaning TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, task_date)
);
CREATE INDEX idx_fishing_tasks_user_date ON daily_fishing_tasks(user_id, task_date);

-- Each word guess the user makes during a fishing round.
CREATE TABLE fishing_attempts (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  task_date DATE NOT NULL,
  round_number INT NOT NULL,
  fish_word_id VARCHAR(64) NOT NULL REFERENCES words(id),
  chosen_word_id VARCHAR(64) NOT NULL REFERENCES words(id),
  is_correct BOOLEAN NOT NULL,
  fish_treats_earned INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_fishing_attempts_user ON fishing_attempts(user_id);
CREATE INDEX idx_fishing_attempts_date ON fishing_attempts(user_id, task_date);

-- ========== Lottery ==========

-- Per-user lottery box inventory (earned by completing fishing rounds).
CREATE TABLE lottery_boxes (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  source VARCHAR(32) NOT NULL DEFAULT 'fishing', -- fishing | other
  opened BOOLEAN NOT NULL DEFAULT FALSE,
  opened_at TIMESTAMPTZ,
  prize_type VARCHAR(32),    -- coins | item (null until opened)
  prize_ref VARCHAR(64),     -- coin amount or item_id (null until opened)
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_lottery_boxes_user ON lottery_boxes(user_id);
CREATE INDEX idx_lottery_boxes_pending ON lottery_boxes(user_id, opened);

-- Prize pool config. Weighted random draw on box open.
CREATE TABLE lottery_drops_config (
  id SERIAL PRIMARY KEY,
  prize_type VARCHAR(32) NOT NULL, -- coins
  prize_ref VARCHAR(64) NOT NULL,  -- coin amount as string, e.g. '20'
  weight INT NOT NULL DEFAULT 100, -- relative weight; higher = more common
  is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Seed prize pool: 20 coins (common), 50 coins (uncommon), 100 coins (rare)
INSERT INTO lottery_drops_config (prize_type, prize_ref, weight) VALUES
  ('coins', '20',  60),
  ('coins', '50',  30),
  ('coins', '100', 10);

-- DOWN
DROP TABLE IF EXISTS lottery_drops_config;
DROP TABLE IF EXISTS lottery_boxes;
DROP TABLE IF EXISTS fishing_attempts;
DROP TABLE IF EXISTS daily_fishing_tasks;
