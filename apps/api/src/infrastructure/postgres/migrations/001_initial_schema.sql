-- 001_initial_schema.sql
-- Option A A2: Full schema bootstrap for meow_dev
-- Covers: users, words, catalog, main mechanism, rewards, secondary mechanism

-- ========== Users & Settings ==========

CREATE TABLE users (
  id VARCHAR(64) PRIMARY KEY,
  nickname VARCHAR(100) NOT NULL DEFAULT 'Learner',
  timezone VARCHAR(64) NOT NULL DEFAULT 'UTC',
  locale VARCHAR(16) NOT NULL DEFAULT 'zh-CN',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE word_books (
  id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  word_count INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_book_settings (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  book_id VARCHAR(64) NOT NULL REFERENCES word_books(id),
  daily_new_target INT NOT NULL DEFAULT 20,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, book_id)
);
CREATE INDEX idx_user_book_settings_user ON user_book_settings(user_id);

-- ========== Words ==========

CREATE TABLE words (
  id VARCHAR(64) PRIMARY KEY,
  book_id VARCHAR(64) NOT NULL REFERENCES word_books(id),
  word_text VARCHAR(200) NOT NULL,
  meaning TEXT NOT NULL,
  phonetic VARCHAR(200),
  word_type VARCHAR(32) NOT NULL DEFAULT 'new',
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_words_book ON words(book_id);
CREATE INDEX idx_words_type ON words(word_type);

-- ========== Main Mechanism: Study ==========

CREATE TABLE study_attempts (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  word_id VARCHAR(64) NOT NULL REFERENCES words(id),
  book_id VARCHAR(64) NOT NULL REFERENCES word_books(id),
  study_type VARCHAR(16) NOT NULL,
  action_result VARCHAR(16) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_study_attempts_user ON study_attempts(user_id);
CREATE INDEX idx_study_attempts_user_word ON study_attempts(user_id, word_id);
CREATE INDEX idx_study_attempts_created ON study_attempts(created_at);

CREATE TABLE user_word_progress (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  word_id VARCHAR(64) NOT NULL REFERENCES words(id),
  familiarity INT NOT NULL DEFAULT 0,
  last_studied_at TIMESTAMPTZ,
  next_review_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, word_id)
);
CREATE INDEX idx_user_word_progress_user ON user_word_progress(user_id);

-- ========== Main Mechanism: Review ==========

CREATE TABLE review_groups (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  group_status VARCHAR(16) NOT NULL DEFAULT 'active',
  group_completed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);
CREATE INDEX idx_review_groups_user ON review_groups(user_id);
CREATE INDEX idx_review_groups_status ON review_groups(user_id, group_status);

CREATE TABLE review_group_items (
  id SERIAL PRIMARY KEY,
  review_group_id VARCHAR(64) NOT NULL REFERENCES review_groups(id),
  word_id VARCHAR(64) NOT NULL REFERENCES words(id),
  word_text VARCHAR(200) NOT NULL,
  meaning TEXT NOT NULL,
  completed BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE(review_group_id, word_id)
);
CREATE INDEX idx_review_group_items_group ON review_group_items(review_group_id);

CREATE TABLE review_attempts (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  review_group_id VARCHAR(64) NOT NULL REFERENCES review_groups(id),
  word_id VARCHAR(64) NOT NULL REFERENCES words(id),
  action_result VARCHAR(16) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_review_attempts_user ON review_attempts(user_id);
CREATE INDEX idx_review_attempts_group ON review_attempts(review_group_id);

-- ========== Main Mechanism: Daily / Session / Check-in ==========

CREATE TABLE daily_goal_progress (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  local_date DATE NOT NULL,
  new_target INT NOT NULL DEFAULT 20,
  new_completed INT NOT NULL DEFAULT 0,
  review_target INT NOT NULL DEFAULT 0,
  review_pending INT NOT NULL DEFAULT 0,
  review_completed INT NOT NULL DEFAULT 0,
  goal_status VARCHAR(32) NOT NULL DEFAULT 'not_started',
  active_review_group_id VARCHAR(64),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, local_date)
);
CREATE INDEX idx_daily_goal_user_date ON daily_goal_progress(user_id, local_date);

CREATE TABLE session_records (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  session_status VARCHAR(16) NOT NULL DEFAULT 'started',
  validation_status VARCHAR(16) NOT NULL DEFAULT 'pending',
  minutes_target INT NOT NULL DEFAULT 15,
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ,
  actual_minutes INT,
  effective_learning_count INT NOT NULL DEFAULT 0,
  effective_review_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_sessions_user ON session_records(user_id);
CREATE INDEX idx_sessions_status ON session_records(user_id, session_status);

CREATE TABLE check_in_records (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  local_date DATE NOT NULL,
  status VARCHAR(16) NOT NULL DEFAULT 'succeeded',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, local_date)
);
CREATE INDEX idx_checkins_user_date ON check_in_records(user_id, local_date);

CREATE TABLE learning_day_facts (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  local_date DATE NOT NULL,
  is_learning_day BOOLEAN NOT NULL DEFAULT FALSE,
  effective_learning_count INT NOT NULL DEFAULT 0,
  effective_review_count INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, local_date)
);
CREATE INDEX idx_learning_day_user_date ON learning_day_facts(user_id, local_date);

CREATE TABLE streak_records (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id) UNIQUE,
  current_streak INT NOT NULL DEFAULT 0,
  streak_basis_type VARCHAR(16) NOT NULL DEFAULT 'check_in',
  last_check_in_date DATE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ========== Reward & Settlement ==========

CREATE TABLE reward_source_events (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  event_type VARCHAR(64) NOT NULL,
  source_ref_id VARCHAR(128) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(event_type, source_ref_id)
);
CREATE INDEX idx_reward_source_user ON reward_source_events(user_id);

CREATE TABLE reward_ledger (
  id VARCHAR(64) PRIMARY KEY,
  source_event_id VARCHAR(64) NOT NULL REFERENCES reward_source_events(id),
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  reward_type VARCHAR(32) NOT NULL,
  amount INT NOT NULL,
  reward_status VARCHAR(16) NOT NULL DEFAULT 'succeeded',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_reward_ledger_user ON reward_ledger(user_id);
CREATE INDEX idx_reward_ledger_source ON reward_ledger(source_event_id);
CREATE INDEX idx_reward_ledger_type ON reward_ledger(user_id, reward_type);

CREATE TABLE settlements (
  id VARCHAR(64) PRIMARY KEY,
  source_event_id VARCHAR(64) NOT NULL REFERENCES reward_source_events(id) UNIQUE,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  settlement_status VARCHAR(16) NOT NULL DEFAULT 'succeeded',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_settlements_user ON settlements(user_id);

-- ========== Idempotency ==========

CREATE TABLE idempotency_keys (
  key VARCHAR(255) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  path VARCHAR(255) NOT NULL,
  response JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_idempotency_user ON idempotency_keys(user_id);

-- ========== Secondary Mechanism: Pet & Wallet ==========

CREATE TABLE secondary_wallets (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id) UNIQUE,
  coins_spent INT NOT NULL DEFAULT 0,
  feed_mood_accumulated INT NOT NULL DEFAULT 0,
  feed_exp_accumulated INT NOT NULL DEFAULT 0,
  feed_bond_accumulated INT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE pet_profiles (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id) UNIQUE,
  nickname VARCHAR(100) NOT NULL DEFAULT 'Mimi',
  base_mood INT NOT NULL DEFAULT 60,
  base_bond INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE feed_events (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  feed_item_type VARCHAR(32) NOT NULL,
  consumed_amount INT NOT NULL DEFAULT 1,
  mood_delta INT NOT NULL DEFAULT 0,
  exp_delta INT NOT NULL DEFAULT 0,
  bond_delta INT NOT NULL DEFAULT 0,
  local_date DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_feed_events_user ON feed_events(user_id);
CREATE INDEX idx_feed_events_date ON feed_events(user_id, local_date);

-- ========== Secondary Mechanism: Shop & Inventory ==========

CREATE TABLE shop_catalog_items (
  id VARCHAR(64) PRIMARY KEY,
  item_type VARCHAR(32) NOT NULL,
  slot VARCHAR(32) NOT NULL,
  name VARCHAR(200) NOT NULL,
  coin_price INT NOT NULL,
  required_level INT NOT NULL DEFAULT 1,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE inventory_items (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  item_id VARCHAR(64) NOT NULL REFERENCES shop_catalog_items(id),
  item_type VARCHAR(32) NOT NULL,
  slot VARCHAR(32) NOT NULL,
  equipped BOOLEAN NOT NULL DEFAULT FALSE,
  owned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, item_id)
);
CREATE INDEX idx_inventory_user ON inventory_items(user_id);

CREATE TABLE equipment_slots (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  slot VARCHAR(32) NOT NULL,
  item_type VARCHAR(32) NOT NULL,
  item_id VARCHAR(64) REFERENCES shop_catalog_items(id),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, slot, item_type)
);
CREATE INDEX idx_equipment_user ON equipment_slots(user_id);

CREATE TABLE purchase_records (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  item_id VARCHAR(64) NOT NULL REFERENCES shop_catalog_items(id),
  coins_spent INT NOT NULL,
  idempotency_key VARCHAR(255),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_purchases_user ON purchase_records(user_id);

-- DOWN

-- Reverse order drop
DROP TABLE IF EXISTS purchase_records;
DROP TABLE IF EXISTS equipment_slots;
DROP TABLE IF EXISTS inventory_items;
DROP TABLE IF EXISTS shop_catalog_items;
DROP TABLE IF EXISTS feed_events;
DROP TABLE IF EXISTS pet_profiles;
DROP TABLE IF EXISTS secondary_wallets;
DROP TABLE IF EXISTS idempotency_keys;
DROP TABLE IF EXISTS settlements;
DROP TABLE IF EXISTS reward_ledger;
DROP TABLE IF EXISTS reward_source_events;
DROP TABLE IF EXISTS streak_records;
DROP TABLE IF EXISTS learning_day_facts;
DROP TABLE IF EXISTS check_in_records;
DROP TABLE IF EXISTS session_records;
DROP TABLE IF EXISTS daily_goal_progress;
DROP TABLE IF EXISTS review_attempts;
DROP TABLE IF EXISTS review_group_items;
DROP TABLE IF EXISTS review_groups;
DROP TABLE IF EXISTS user_word_progress;
DROP TABLE IF EXISTS study_attempts;
DROP TABLE IF EXISTS words;
DROP TABLE IF EXISTS user_book_settings;
DROP TABLE IF EXISTS word_books;
DROP TABLE IF EXISTS users;
