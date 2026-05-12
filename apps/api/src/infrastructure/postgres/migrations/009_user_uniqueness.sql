-- 009_user_uniqueness.sql
-- 需求 23 Phase A1：补两处 UNIQUE / PK 缺 user_id（多用户隔离前置）
--
-- References:
--   docs/design/audits/db-uniqueness-audit.md §2.1 §2.2 §3.6
--   docs/design/plan-023-用户系统与用户数据隔离-v2.md §3.2
--
-- 修复两个 critical gap：
--   1. reward_source_events UNIQUE(event_type, source_ref_id)
--      → UNIQUE(user_id, event_type, source_ref_id)
--      原约束跨用户共享，会让用户 A 的事件占位住用户 B 的 source_ref_id
--   2. idempotency_keys PK(key) → PK(user_id, key)
--      原约束全局唯一，可能导致用户 B 通过相同 key 拿到用户 A 的响应缓存
--
-- 应用层联动（必须同 PR 上线）：
--   - dev-store.ts: getIdempotencyKey(key) → getIdempotencyKey(userId, key)
--   - 18+ 调用点全部传入 userId
--   - 详见 controller-auth-audit §5 #5 + db-uniqueness-audit §3.6.1
--
-- dev 数据兼容：
--   dev-user-001 是当前唯一存量用户，新约束在单用户数据上不会冲突。

-- UP

-- 1. reward_source_events: 加 user_id 到 UNIQUE
--    PG 自动命名约束为 reward_source_events_event_type_source_ref_id_key
ALTER TABLE reward_source_events
  DROP CONSTRAINT IF EXISTS reward_source_events_event_type_source_ref_id_key;
ALTER TABLE reward_source_events
  ADD CONSTRAINT reward_source_events_user_event_ref_key
  UNIQUE (user_id, event_type, source_ref_id);

-- 2. idempotency_keys: PK(key) → PK(user_id, key)
--    PG 自动命名 PK 为 idempotency_keys_pkey
ALTER TABLE idempotency_keys DROP CONSTRAINT idempotency_keys_pkey;
ALTER TABLE idempotency_keys
  ADD CONSTRAINT idempotency_keys_pkey
  PRIMARY KEY (user_id, key);

-- idx_idempotency_user 仍保留（被 PK 部分覆盖但保留更稳）

-- DOWN

ALTER TABLE idempotency_keys DROP CONSTRAINT idempotency_keys_pkey;
ALTER TABLE idempotency_keys ADD CONSTRAINT idempotency_keys_pkey PRIMARY KEY (key);

ALTER TABLE reward_source_events
  DROP CONSTRAINT IF EXISTS reward_source_events_user_event_ref_key;
ALTER TABLE reward_source_events
  ADD CONSTRAINT reward_source_events_event_type_source_ref_id_key
  UNIQUE (event_type, source_ref_id);
