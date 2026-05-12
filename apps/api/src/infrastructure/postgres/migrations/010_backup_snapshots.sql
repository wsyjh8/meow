-- 010_backup_snapshots.sql
-- 需求 23 Phase D PR-D-β：备份 PG 持久化 (v1 plan 漏 DOWN，v2 补齐)
--
-- 设计：单插槽 per user，last-write-wins。snapshot JSONB 存完整客户端导出
-- (mobile 端 v13 schema 的 9 张 user-scoped 表 + LocalSettings)。
--
-- 不存的内容（plan §9 闭环修订口径）：
--   后端业务表 (inventory_items / equipment_slots / secondary_wallets /
--   pet_profiles 等) 已经按 user_id partition 持久化（A4-β 落地）。
--   换设备登录后由后端 /me/* API 自然返回，不走 backup payload。
--
-- 为什么 BackupController 直接读这张表（不走 dev-store in-memory）：
--   dev-store β.5 lazy-load 缺口：startup 只 load DEV_USER_ID 的 slice，
--   其他用户的 in-memory bucket 在 server restart 后空。
--   走 PG 直接查 WHERE user_id = $1 切断这个依赖。
--
-- References:
--   docs/design/plan-023-D-backup-restore-closure-v2.md §4.2 / §5

-- UP

CREATE TABLE backup_snapshots (
  user_id          VARCHAR(64) NOT NULL PRIMARY KEY
                    REFERENCES users(id) ON DELETE CASCADE,
  backup_id        VARCHAR(64) NOT NULL,
  schema_version   VARCHAR(64) NOT NULL,
  uploaded_at      TIMESTAMPTZ NOT NULL,
  snapshot_size    INT NOT NULL,
  device_id        VARCHAR(128),
  device_model     VARCHAR(255),
  snapshot         JSONB NOT NULL,
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_backup_snapshots_uploaded_at
  ON backup_snapshots(uploaded_at);
CREATE INDEX idx_backup_snapshots_backup_id
  ON backup_snapshots(backup_id);

-- DOWN

DROP INDEX IF EXISTS idx_backup_snapshots_backup_id;
DROP INDEX IF EXISTS idx_backup_snapshots_uploaded_at;
DROP TABLE IF EXISTS backup_snapshots;
