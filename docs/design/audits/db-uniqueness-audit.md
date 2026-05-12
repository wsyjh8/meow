# DB Uniqueness Audit — Phase 0 / 需求 23

**Status:** complete (v1.2 — Phase G 落地映射 + migration 009/010 commit hash)
**Scope:** `apps/api/src/infrastructure/postgres/migrations/` 001 ~ 010 全部表
**Purpose:** 确认每张表的 PK / UNIQUE 约束在多用户化后是否会漏 user_id（导致跨用户冲突或越权）；v1.2 补 Phase A→D 实施完成后的落地映射
**关联:**
- [plan-023-用户系统与用户数据隔离-v2.md](../plan-023-用户系统与用户数据隔离-v2.md) §3.2 / §14
- [prd-§9-acceptance-coverage.md](./prd-§9-acceptance-coverage.md)
- [controller-auth-audit.md](./controller-auth-audit.md) §6 #5 / §6 #14-16
**日期:** 2026-05-09 (v1.0) → 2026-05-09 (v1.1，吸收两份外部 review) → 2026-05-11 (v1.2，Phase G 落地映射)

---

## v1.1 修订记录

| 修订点 | 来源 | 处理 |
|--------|------|------|
| §1 末尾 "总计 35 张表" → "34 张表" | review 1+2 | ✅ 采纳（25+4+3+1+1=34，原 35 是笔误） |
| §5 末尾 "确认现有代码不依赖" 从 TODO 改为已落地 | review 1 | ✅ 采纳，新增 §3.6 落地 grep 结论 |
| 跨审计联动到 controller-auth §5 #5 | review 1 §4.2 | ✅ 采纳 |

---

## 0. 标记规约

- **scope**：`per-user` = 每用户独立数据；`shared-content` = 公共内容；`event-log` = 追加日志；`config` = 全局配置
- **uniqueness**：`OK` = 约束已包含 user_id（或不需要）；`GAP` = 约束需补 user_id；`event-only` = 无 UNIQUE，幂等靠 idempotency_keys
- **gap-severity**：`critical` = 跨用户写冲突 / 越权风险；`info` = 不构成正确性问题

---

## 1. 全表一览

| 表 | 来源 migration | scope | PK / UNIQUE 约束 | uniqueness | gap |
|---|---|---|---|---|---|
| `users` | 001 | per-user | PK(`id`) | OK | — |
| `word_books` | 001 | shared-content | PK(`id`) | OK | — |
| `user_book_settings` | 001 | per-user | PK serial; **UNIQUE(`user_id`, `book_id`)** | OK | — |
| `words` | 001/002/005 | shared-content | PK(`id`) | OK | — |
| `study_attempts` | 001 | event-log | PK(`id`) | event-only | — |
| `user_word_progress` | 001 | per-user | PK serial; **UNIQUE(`user_id`, `word_id`)** | OK | — |
| `review_groups` | 001 | per-user | PK(`id`) | event-only | — |
| `review_group_items` | 001 | per-user (via parent) | PK serial; **UNIQUE(`review_group_id`, `word_id`)** | OK (review_group 已绑 user_id) | — |
| `review_attempts` | 001 | event-log | PK(`id`) | event-only | — |
| `daily_goal_progress` | 001 | per-user | PK serial; **UNIQUE(`user_id`, `local_date`)** | OK | — |
| `session_records` | 001 | event-log | PK(`id`) | event-only | — |
| `check_in_records` | 001 | per-user | PK(`id`); **UNIQUE(`user_id`, `local_date`)** | OK | — |
| `learning_day_facts` | 001 | per-user | PK serial; **UNIQUE(`user_id`, `local_date`)** | OK | — |
| `streak_records` | 001 | per-user | PK serial; **UNIQUE(`user_id`)** | OK | — |
| **`reward_source_events`** | 001 | per-user | PK(`id`); **UNIQUE(`event_type`, `source_ref_id`)** ⚠️ | **GAP** | **critical** |
| `reward_ledger` | 001 | event-log | PK(`id`) | event-only | — |
| `settlements` | 001 | per-user | PK(`id`); **UNIQUE(`source_event_id`)** | OK (派生自 reward_source_events) | — (依赖上条修复) |
| **`idempotency_keys`** | 001 | per-user | **PK(`key`)** ⚠️ | **GAP** | **critical** |
| `secondary_wallets` | 001 | per-user | PK serial; **UNIQUE(`user_id`)** | OK | — |
| `pet_profiles` | 001 | per-user | PK serial; **UNIQUE(`user_id`)** | OK | — |
| `feed_events` | 001 | event-log | PK(`id`) | event-only | — |
| `shop_catalog_items` | 001 | shared-content | PK(`id`) | OK | — |
| `inventory_items` | 001 | per-user | PK serial; **UNIQUE(`user_id`, `item_id`)** | OK | — |
| `equipment_slots` | 001 | per-user | PK serial; **UNIQUE(`user_id`, `slot`, `item_type`)** | OK | — |
| `purchase_records` | 001 | event-log | PK serial; `idempotency_key` 字段无 UNIQUE | event-only | — |
| `daily_fishing_tasks` | 003 | per-user | PK serial; **UNIQUE(`user_id`, `task_date`)** | OK | — |
| `fishing_attempts` | 003 | event-log | PK(`id`) | event-only | — |
| `lottery_boxes` | 003 | per-user | PK(`id`) | event-only | — |
| `lottery_drops_config` | 003 | config | PK serial | OK (全局配置) | — |
| `examples` | 004/006/007 | shared-content | PK(`id`); UNIQUE(`stable_id`); CHECK status; （006 删 UNIQUE(`word_id`, `ordinal`)） | OK | — |
| `audio_assets` | 004/007 | shared-content | PK(`id`) | OK | — |
| `content_manifest` | 004/007 | shared-content | PK(`id`); FK release_id NOT NULL | OK | — |
| `word_book_memberships` | 005 | shared-content | **PK(`word_id`, `book_id`)** | OK | — |
| `content_release` | 007 | shared-content | PK(`release_id`); CHECK status | OK | — |

**总计：34 张表，2 处 critical gap。**

> 表数核对（v1.1）：001=25 + 003=4 + 004=3 + 005=1 + 007=1 = 34。002 / 006 是纯 ALTER 不增表。

---

## 2. Critical Gap 详细分析

### 2.1 GAP #1：`reward_source_events` UNIQUE 缺 user_id

**当前 SQL（001:189）：**

```sql
CREATE TABLE reward_source_events (
  id VARCHAR(64) PRIMARY KEY,
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  event_type VARCHAR(64) NOT NULL,
  source_ref_id VARCHAR(128) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(event_type, source_ref_id)        -- ⚠️ 缺 user_id
);
```

**风险：**

- `event_type` = `'effective_new_word'`、`source_ref_id` = `'<study_attempt_id>'`
- 当前单用户 dev 环境 attempt id 是 UUID 不冲突，所以约束是隐式正确的（无碰撞数据）
- 多用户化后：用户 A 提交一个 source_ref_id，再传同样的 ref_id 给用户 B 的 settlement 接口 → 服务端会以为已结算 → **跨用户重放攻击**或**用户 A 的奖励"占位"住用户 B 的 source_ref_id**
- 进一步：[settlements](../../../apps/api/src/infrastructure/postgres/migrations/001_initial_schema.sql) UNIQUE(`source_event_id`) 是派生约束，依赖 reward_source_events 的正确性，本身 OK，但上游一坏全坏

**修复（plan v2 §3.2 migration 009）：**

```sql
ALTER TABLE reward_source_events
  DROP CONSTRAINT reward_source_events_event_type_source_ref_id_key;
ALTER TABLE reward_source_events
  ADD CONSTRAINT reward_source_events_user_event_ref_key
  UNIQUE (user_id, event_type, source_ref_id);
```

**dev-user-001 数据兼容：** 单用户存量数据下，新加 user_id 到 UNIQUE 不会产生冲突（同 user 同 ref_id 仍唯一）。安全可上。

---

### 2.2 GAP #2：`idempotency_keys` 全局 PK

**当前 SQL（001:218）：**

```sql
CREATE TABLE idempotency_keys (
  key VARCHAR(255) PRIMARY KEY,            -- ⚠️ 全局唯一，没带 user_id
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  path VARCHAR(255) NOT NULL,
  response JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_idempotency_user ON idempotency_keys(user_id);
```

**风险：**

- 客户端生成 idempotency key（UUID v4），单设备碰撞不可能；但**不同设备客户端生成相同 key 的概率不为零**，特别是有人故意构造时
- 用户 A 的 key 可被用户 B 复用，B 的请求会直接命中 A 的缓存响应 → 越权拿到 A 的响应内容
- 实际危害取决于响应内容（部分接口的响应是用户级数据如 `coins_spent`, `inventory`），构成信息泄露

**修复（plan v2 §3.2 migration 009）：**

```sql
ALTER TABLE idempotency_keys DROP CONSTRAINT idempotency_keys_pkey;
ALTER TABLE idempotency_keys ADD PRIMARY KEY (user_id, key);
-- idx_idempotency_user 仍然有用，保留
```

**dev-user-001 数据兼容：** 单用户存量下，将 PK 从 `key` 改为 `(user_id, key)` 的过程中：
- 原行没有重复（因为原 PK 已唯一）
- 复合 PK 退化为单列 user_id 子集 + key 子集，仍唯一
- 安全可上

**性能影响：** 复合 PK 的查询计划：
- 原查询 `WHERE key = ?` → 变成 `WHERE user_id = ? AND key = ?`，需要修改 `domain/idempotency-store.ts` 加上 user_id（**应用层修改是必须的**，单纯改 schema 不够）
- 原 `idx_idempotency_user(user_id)` 变得冗余（被 PK 覆盖），可保留可删除——保留更稳

---

## 3. 其他需 application 层确认的检查

### 3.1 `settlements` UNIQUE(source_event_id)

```sql
UNIQUE 在 001:208，`source_event_id` 是 reward_source_events.id 的 FK
```

`source_event_id` 是 reward_source_events 的 PK（`id`），全局唯一，UNIQUE 不需补 user_id。**前提是 `reward_source_events.id` 本身不被复用**（PK 自然约束）。GAP #1 修完后，settlements 自然安全。

### 3.2 `purchase_records.idempotency_key`

```sql
purchase_records (idempotency_key VARCHAR(255), ...)
-- 无 UNIQUE 约束
```

这是**信息字段**（追溯哪次购买用了哪个 key），不是约束。真实的购买幂等性由 `idempotency_keys` 表保证（GAP #2 修完后是 per-user）。OK。

### 3.3 `content_manifest.is_active` 与 `content_release.status='active'`

migration 007 注释里写"Day 4 manifest API 必须同时满足 release.status='active' AND content_manifest.is_active=true"。这是应用层契约，不是 DB 约束。与 user 隔离无关，跳过。

### 3.4 `lottery_drops_config`

全局配置（奖池权重），不带 user_id 是设计意图。OK。

### 3.5 `review_group_items` UNIQUE(review_group_id, word_id)

不带 user_id，但 `review_group_id` 已是 user_id 的派生（`review_groups.user_id` FK）。两个用户不可能共享一个 review_group。OK。

### 3.6 应用层依赖 grep 落地（v1.1 新增）

v1.0 草案 §5 末尾留了一个 TODO："确认现有代码不依赖 `event_type+source_ref_id` 全局唯一" + "确认 `idempotency_keys` 应用层 query 改造点"。本节落地 grep 结果。

#### 3.6.1 `idempotency_keys` 应用层 query 调用点

```
dev-store.ts:1098    getIdempotencyKey(key: string)              ⚠️ 无 userId 入参
dev-store.ts:1102    setIdempotencyKey(key, path, response)      ⚠️ 写入也未带 userId（虽然 PG 内部 store 时硬编码 DEV_USER_ID）
pg-persistence.ts:66 SELECT * FROM idempotency_keys WHERE user_id = $1  (硬编码 DEV_USER_ID)
```

**调用方（共 18+ 处）：**

```
dev-store.ts 内：第 766/958/1049/1252/1295/1743/1793/1909/2062/2195/2294/2359/2559/2663 行（共 14 处）
controllers 内：study-attempts(2)/task-attempts(2)/shop(1)/feed(1)/lottery(2)/equipment(2)/review-attempts(4) (共 14 处)
```

**v1.1 结论：** 应用层完全没"全局 key 唯一"假设的查询（没看到 `WHERE key = ?` 不带 user_id 的 raw SQL；都通过 `getIdempotencyKey` 间接访问）。所以 migration 009 改 PK 之后，**只需要把 `getIdempotencyKey(key)` 改成 `getIdempotencyKey(userId, key)`**，并修改全部调用点传入 userId。无 raw SQL 残留风险。

#### 3.6.2 `reward_source_events` UNIQUE 应用层 query 调用点

```
dev-store.ts (reward 相关方法 createOrGetSourceEvent / settle 等)
  → 内部按 source_event 模型 in-memory 查询，不直接拼 SQL
pg-persistence.ts
  → reward 相关持久化也是按 user_id 已经隐含 scope（snapshot 整份读写）
```

**v1.1 结论：** 应用层不存在"按 (event_type, source_ref_id) 全局查找"的代码，也没有"用户 A 通过此组合查到用户 B 的 source event"的路径。Migration 009 改 UNIQUE 后零应用层代码改动。仅 dev-store 的 in-memory 数据结构本身已经按 user 分桶（其实没分得很彻底，是 plan v2 §5 要解决的，但与 UNIQUE 改动正交）。

#### 3.6.3 与 controller-auth §5 #5 的联动

[controller-auth-audit.md](controller-auth-audit.md) §5 #5 已记录 idempotency 改造的方法签名变更。本节是其 SQL 侧的对应面：DB 改 PK，应用层改 method signature，二者必须同 PR 上线。

---

## 4. 索引相关说明（不影响正确性，但影响 Phase E 后性能）

### 4.1 已有用户级查询索引（保留）

```
idx_user_book_settings_user            user_book_settings(user_id)
idx_study_attempts_user                study_attempts(user_id)
idx_study_attempts_user_word           study_attempts(user_id, word_id)
idx_user_word_progress_user            user_word_progress(user_id)
idx_review_groups_user                 review_groups(user_id)
idx_review_groups_status               review_groups(user_id, group_status)
idx_review_attempts_user               review_attempts(user_id)
idx_daily_goal_user_date               daily_goal_progress(user_id, local_date)
idx_sessions_user                      session_records(user_id)
idx_sessions_status                    session_records(user_id, session_status)
idx_checkins_user_date                 check_in_records(user_id, local_date)
idx_learning_day_user_date             learning_day_facts(user_id, local_date)
idx_reward_source_user                 reward_source_events(user_id)
idx_reward_ledger_user                 reward_ledger(user_id)
idx_reward_ledger_type                 reward_ledger(user_id, reward_type)
idx_settlements_user                   settlements(user_id)
idx_idempotency_user                   idempotency_keys(user_id)
idx_feed_events_user                   feed_events(user_id)
idx_feed_events_date                   feed_events(user_id, local_date)
idx_inventory_user                     inventory_items(user_id)
idx_equipment_user                     equipment_slots(user_id)
idx_purchases_user                     purchase_records(user_id)
idx_fishing_tasks_user_date            daily_fishing_tasks(user_id, task_date)
idx_fishing_attempts_user              fishing_attempts(user_id)
idx_fishing_attempts_date              fishing_attempts(user_id, task_date)
idx_lottery_boxes_user                 lottery_boxes(user_id)
idx_lottery_boxes_pending              lottery_boxes(user_id, opened)
```

**评估：** 用户级索引覆盖很全，PG 部分基本不需要补充 index。Phase A 可以不写新 index。

### 4.2 建议补的索引（Phase E 后视实际查询热点决定）

无强需求。如果 reward_source_events 查询热点偏向 `WHERE user_id = ? AND created_at > ?` 类时间窗口，可以加个 `(user_id, created_at)`，但本轮不做。

---

## 5. migration 009 完整草案

```sql
-- 009_user_uniqueness.sql
-- v0.6 / 需求23：补两处 UNIQUE / PK 缺 user_id
--
-- References:
--   docs/design/audits/db-uniqueness-audit.md §2 (本文件)
--   docs/design/plan-023-用户系统与用户数据隔离-v2.md §3.2

-- UP

-- 1. reward_source_events: UNIQUE(event_type, source_ref_id) → UNIQUE(user_id, event_type, source_ref_id)
ALTER TABLE reward_source_events
  DROP CONSTRAINT IF EXISTS reward_source_events_event_type_source_ref_id_key;
ALTER TABLE reward_source_events
  ADD CONSTRAINT reward_source_events_user_event_ref_key
  UNIQUE (user_id, event_type, source_ref_id);

-- 2. idempotency_keys: PK(key) → PK(user_id, key)
ALTER TABLE idempotency_keys DROP CONSTRAINT idempotency_keys_pkey;
ALTER TABLE idempotency_keys ADD CONSTRAINT idempotency_keys_pkey
  PRIMARY KEY (user_id, key);

-- DOWN

ALTER TABLE idempotency_keys DROP CONSTRAINT idempotency_keys_pkey;
ALTER TABLE idempotency_keys ADD PRIMARY KEY (key);

ALTER TABLE reward_source_events DROP CONSTRAINT IF EXISTS reward_source_events_user_event_ref_key;
ALTER TABLE reward_source_events
  ADD CONSTRAINT reward_source_events_event_type_source_ref_id_key
  UNIQUE (event_type, source_ref_id);
```

**重要：必须配套修改 application 代码（详见 §3.6 v1.1 已落地分析）**

- `getIdempotencyKey(key)` → `getIdempotencyKey(userId, key)`（dev-store.ts:1098 + 18 个调用点）
- `setIdempotencyKey` 同步加 userId 入参
- `reward_source_events` 的 UNIQUE 改动**无需应用层代码改动**（§3.6.2 已确认）

---

## 6. 与 plan v2 §3.2 的对应

plan v2 §3.2 简述了这两个 GAP，本审计补：
- 全表 35 张的逐条审计（plan v2 仅点了 2 个）
- migration 009 完整 UP/DOWN 草案
- application 层联动修改清单（§5 重要）
- 无 GAP 表的明确确认（避免 Phase A 实施时再回头查）

---

## 7. 输出

本文档作为 migration 009 PR 的参考依据。Phase A 实施时按 §5 的草案 + application 层改动一并提交。

---

## 8. v1.2 修订记录（2026-05-11，Phase G 收尾）

### 8.1 §2 critical gap 落地映射

| Audit finding | 实施 commit | 落地内容 |
|---------------|-------------|---------|
| **§2.1 GAP #1**: `reward_source_events` UNIQUE 缺 user_id | `5547a85`（A1-A3） | `008_user_auth.sql` 已先一步加 user 列；`009_user_uniqueness.sql` 把 UNIQUE 从 `(event_type, source_ref_id)` 改成 `(user_id, event_type, source_ref_id)` |
| **§2.2 GAP #2**: `idempotency_keys` 全局 PK | `5547a85`（A1-A3） | `009_user_uniqueness.sql` 把 PK 从 `(key)` 改成 `(user_id, key)`；in-memory 同期升级为 `Map<userId, Map<key, record>>`（β.4 in `3833c25`） |

### 8.2 §3.6 应用层依赖落地

| 应用层调用点 | 实施 commit | 文件:行 |
|--------------|-------------|--------|
| `getIdempotencyKey(key)` → `getIdempotencyKey(userId, key)` | `1991be7`（A4-α） | `apps/api/src/domain/dev-store-adapter.ts:292-298` (Adapter 加 userId 参数)；`dev-store.ts:1451`（内部 facade，β.4 后 routes 到 `Map<userId, ...>`） |
| `setIdempotencyKey(userId, key, ...)` | `1991be7` | 同上 dev-store-adapter |
| dev-store 内部 18 个 idempotency 调用点全部带 user_id | `3833c25`（β.4） | `dev-store.ts` 中所有 `this.getIdempotencyKey` 都通过 facade 走 per-user inner Map |

### 8.3 新增 migration 010（v1.2 增补，原审计未覆盖）

Phase D-β 新增 `backup_snapshots` 表（plan-023-D-v2 §5）：

| 字段 | 约束 |
|------|------|
| `user_id` | PRIMARY KEY（每用户一槽，last-write-wins）|
| `backup_id` | 单独索引 `idx_backup_snapshots_backup_id`（plan-023-D-v2 Review 1 采纳）|
| 其它 meta 字段 | schema_version / uploaded_at / snapshot_size / device_id / device_model / snapshot (JSONB) |

实施 commit: `aaefffc`（Phase D PR-D-β）。完整 UP/DOWN 在 migration 010 文件，DOWN 在 plan-023-D-v2 §5 中。

### 8.4 引用约定（v1.2 强化）

后续 migration 改 schema 时必须先 reference 本文件 §1 一览表 + §2/§3 GAP 章节，确认新约束不会 reintroduce 已修复的 critical gap（特别是任何 UNIQUE / PK 调整都要保留 user_id 分量）。

### 8.5 与 PRD §9 验收的对应

| audit 项 | PRD §9 验收对应 |
|----------|---------------|
| §2.1 reward_source_events UNIQUE | §9.7-2（cross-user 越权 / ID 枚举防护）|
| §2.2 idempotency_keys PK | §9.7-2（idempotency key 跨用户不冲撞，per-user response cache 不串）|
| §8.3 backup_snapshots PK | §9.5-6（猫猫/奖励状态延续 — 通过业务表 user_id 稳定 + backup 通道 per-user 共同兑现）+ §9.7-3（/me/backup/* 只返当前用户）|
