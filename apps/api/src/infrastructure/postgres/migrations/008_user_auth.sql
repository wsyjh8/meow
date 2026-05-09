-- 008_user_auth.sql
-- 需求 23 Phase A1：users 表加鉴权字段
--
-- References:
--   docs/design/plan-023-用户系统与用户数据隔离-v2.md §3.1
--   docs/design/audits/db-uniqueness-audit.md
--
-- 字段语义：
--   email           正式用户唯一标识；游客为 NULL；UNIQUE 通过 lower(email) 表达式索引
--   password_hash   bcrypt cost=12；游客为 NULL
--   account_type    'guest' | 'registered'；启动期默认 'guest'
--   device_id       guest 起号时的客户端 device 标识；用于 /auth/guest 幂等查询
--   last_login_at   仅记录，不做安全用途
--
-- 同行升级方案（plan v2 §6.2）：
--   绑定后 users.id 不变（避免业务表 user_id 改写），不留 guest 行
--   id 可保留 'guest-...' 前缀（人眼标记，不参与业务判断）

-- UP

ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS account_type VARCHAR(16) NOT NULL DEFAULT 'guest';
ALTER TABLE users ADD COLUMN IF NOT EXISTS device_id VARCHAR(128);
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;

-- account_type CHECK：合法值仅 'guest' / 'registered'
ALTER TABLE users DROP CONSTRAINT IF EXISTS chk_users_account_type;
ALTER TABLE users
  ADD CONSTRAINT chk_users_account_type
  CHECK (account_type IN ('guest', 'registered'));

-- email 大小写不敏感唯一（通过 lower(email) 表达式索引）；NULL 不参与唯一性
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_lower
  ON users (LOWER(email)) WHERE email IS NOT NULL;

-- guest 起号幂等查询索引：按 device_id 找已有 guest 用户
CREATE INDEX IF NOT EXISTS idx_users_device_id_guest
  ON users (device_id) WHERE account_type = 'guest';

-- 数据完整性约束（应用层强制，DB 不强制）：
--   account_type='registered' ⇒ email IS NOT NULL AND password_hash IS NOT NULL
--   account_type='guest'      ⇒ email IS NULL AND password_hash IS NULL
-- 不做 CHECK 因为绑定流程是同行 UPDATE，事务中间瞬间会违反；应用层保证最终一致

-- 把已存在的 dev-user-001 显式标为 guest（保持向后兼容；§6.1 dev_user_001 保留方案）
UPDATE users SET account_type = 'guest' WHERE account_type IS NULL OR account_type = '';

-- DOWN

DROP INDEX IF EXISTS idx_users_device_id_guest;
DROP INDEX IF EXISTS idx_users_email_lower;
ALTER TABLE users DROP CONSTRAINT IF EXISTS chk_users_account_type;
ALTER TABLE users DROP COLUMN IF EXISTS last_login_at;
ALTER TABLE users DROP COLUMN IF EXISTS device_id;
ALTER TABLE users DROP COLUMN IF EXISTS account_type;
ALTER TABLE users DROP COLUMN IF EXISTS password_hash;
ALTER TABLE users DROP COLUMN IF EXISTS email;
