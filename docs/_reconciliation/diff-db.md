# DB 差异对比报告

> **旧文档**: `背单词喵喵app_DB设计草案_v0.1.5.md`
> **代码实际**: `current-db.md`（基于 commit bface75 代码反推）
> **生成日期**: 2026-04-08

---

## 一、总体差异概览

| 维度 | 旧文档 | 代码实际 |
|------|--------|----------|
| 云端 DBMS | PostgreSQL (uuid PK) | PostgreSQL，但 PK 为 VARCHAR(64) |
| 云端表数 | 17 张主机制 + 7 张副机制 + 2 张 backup = ~26 张 | 25 张（无 backup 表、无 review_queue、无 learning_stat_daily） |
| 本地端 | 未覆盖 | 8 张本地表 + SharedPreferences |
| Migration | 未提及 | 001_initial_schema.sql + 002_word_restructure.sql |
| ORM | 未提及 | 无 ORM，使用 pg driver 直连 |
| 内存层 | 未提及 | dev-store 纯内存实现 |

---

## 二、云端表级差异（按模块分组）

---

### 模块：用户与设置

---

### [DB-001] [🟡] users 表 - 主键类型不一致

**位置**: 旧文档 7.1 / current-db.md Table: users
**旧文档**: `id` 类型为 `uuid pk`，含 `account_type`, `email`, `current_level` 等字段
**代码实际**: `id` 类型为 `VARCHAR(64) NOT NULL`，无 `account_type`、无 `email`、无 `current_level`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档；旧文档中 `account_type`/`email`/`current_level` 属于设计但尚未落库的字段，需用户确认是否标记为 planned

---

### [DB-002] [🟡] users 表 - 缺失字段

**位置**: 旧文档 7.1 / current-db.md Table: users
**旧文档**: 包含 `account_type (varchar32)`, `email (varchar255 nullable unique)`, `current_level (int default 1)`
**代码实际**: 这三个字段均不存在
**实现状态**: [占位·未实现] -- 认证模块整体未实现（dev mode 硬编码 dev-user-001）
**建议动作**: 需用户确认 -- 是计划后续加入还是已放弃

---

### [DB-003] [🟡] users 表 - nickname 默认值差异

**位置**: 旧文档 7.1 / current-db.md Table: users
**旧文档**: `nickname varchar(64) nullable`
**代码实际**: `nickname VARCHAR(100) NOT NULL DEFAULT 'Learner'`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [DB-004] [🟡] users 表 - locale 差异

**位置**: 旧文档 7.1 / current-db.md Table: users
**旧文档**: `locale varchar(16) nullable`
**代码实际**: `locale VARCHAR(16) NOT NULL DEFAULT 'zh-CN'`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [DB-005] [🟡] users 表 - timezone 默认值

**位置**: 旧文档 7.1 / current-db.md Table: users
**旧文档**: `timezone varchar(64) not null`，有 `chk_users_timezone_not_blank` 约束
**代码实际**: `timezone VARCHAR(64) NOT NULL DEFAULT 'UTC'`，无 CHECK 约束
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [DB-006] [🟡] word_books 表 - 字段差异

**位置**: 旧文档 7.2 / current-db.md Table: word_books
**旧文档**: 包含 `code (varchar64 unique)`, `language (varchar16)`, `difficulty (varchar32 nullable)`, `updated_at`
**代码实际**: 无 `code`、无 `language`、无 `difficulty`、无 `updated_at`；新增 `description (TEXT nullable)`, `word_count (INT NOT NULL DEFAULT 0)`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档；旧文档中 `code`/`language`/`difficulty` 需确认是否 planned

---

### [DB-007] [🟡] user_book_settings 表 - 主键与字段差异

**位置**: 旧文档 7.4 / current-db.md Table: user_book_settings
**旧文档**: `id uuid pk`，包含 `daily_review_target_mode`, `daily_review_target_value`, `switched_at`
**代码实际**: `id SERIAL` 自增主键，无 `daily_review_target_mode`、无 `daily_review_target_value`、无 `switched_at`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档；复习目标模式字段为设计但未实现

---

### 模块：词库

---

### [DB-008] [🟡] words 表 - 字段差异较大

**位置**: 旧文档 7.3 / current-db.md Table: words
**旧文档**: 包含 `example_sentence`, `audio_url`, `difficulty_score`, `is_active`, `updated_at`；使用 `uuid pk`
**代码实际**: 无 `example_sentence`、无 `audio_url`、无 `difficulty_score`、无 `is_active`、无 `updated_at`；使用 `VARCHAR(64) pk`；新增 `translation`, `definition`, `difficulty_level`, `is_core`, `tags`, `frequency_rank`, `word_forms`（均来自 002_word_restructure.sql）
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档；002 migration 对 words 做了结构重组

---

### 模块：主机制 - 学习

---

### [DB-009] [🟡] study_attempts 表 - 字段精简

**位置**: 旧文档 7.5 / current-db.md Table: study_attempts
**旧文档**: 包含 `session_id`, `review_group_id`, `question_type`, `is_effective_learning`, `idempotency_key`, `submitted_at`, `local_date`
**代码实际**: 无 `session_id`、无 `review_group_id`、无 `question_type`、无 `is_effective_learning`、无 `idempotency_key`、无 `submitted_at`、无 `local_date`；仅保留 `id, user_id, word_id, book_id, study_type, action_result, created_at`
**实现状态**: [已实现] -- 代码实现为精简版
**建议动作**: 以代码为准写入新文档；旧文档中缺失的字段属于设计期的丰富字段，代码选择了最小实现

---

### [DB-010] [🟡] user_word_progress 表 - 字段精简

**位置**: 旧文档 7.6 / current-db.md Table: user_word_progress
**旧文档**: 包含 `book_id`, `current_status`, `mastery_score`, `mastery_level`, `is_mastered`, `learn_count`, `review_count`, `correct_count`, `wrong_count`, `later_count`, `first_learned_at`, `last_learned_at`, `last_reviewed_at`, `last_result` 等 20+ 字段
**代码实际**: 仅有 `id(SERIAL), user_id, word_id, familiarity(INT DEFAULT 0), last_studied_at, next_review_at, created_at, updated_at`
**实现状态**: [已实现] -- 极简版本
**建议动作**: 以代码为准写入新文档；设计中的 mastery/status 系统未实现

---

### 模块：主机制 - 复习

---

### [DB-011] [🔴] review_queue 表 - 代码中不存在

**位置**: 旧文档 7.7 / current-db.md 无对应表
**旧文档**: 定义了完整的 `review_queue` 表（含 `queue_status`, `priority_score`, `due_at` 等 14 个字段）
**代码实际**: 该表不存在于任何 migration 中
**实现状态**: [占位·未实现]
**建议动作**: 需用户确认 -- 是否计划后续实现，或已被 FSRS 本地端替代

---

### [DB-012] [🟡] review_groups 表 - 字段精简

**位置**: 旧文档 7.7A / current-db.md Table: review_groups
**旧文档**: 包含 `local_date`, `group_size_total`, `group_size_completed`, `source_queue_snapshot_version`, `completion_source_event_id`, `generated_at`, `expires_at`, `updated_at`；`group_status` 枚举为 `active/completed/expired/abandoned`
**代码实际**: 仅有 `id, user_id, group_status(VARCHAR16 DEFAULT 'active'), group_completed(BOOLEAN DEFAULT FALSE), created_at, completed_at`；无 `local_date`, 无 size 计数字段, 无 `source_queue_snapshot_version`, 无 `completion_source_event_id`
**实现状态**: [已实现] -- 最小版本
**建议动作**: 以代码为准写入新文档

---

### [DB-013] [🟡] review_group_items 表 - 字段差异

**位置**: 旧文档 7.7B / current-db.md Table: review_group_items
**旧文档**: 包含 `item_status (pending/completed)`, `completed_attempt_id`, `sort_order`, `updated_at`
**代码实际**: 无 `item_status`（用 `completed BOOLEAN` 替代）、无 `completed_attempt_id`、无 `sort_order`、无 `updated_at`；新增 `word_text` 和 `meaning` 冗余字段
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [DB-014] [🟢] review_attempts 表 - 代码有、旧文档无

**位置**: current-db.md Table: review_attempts / 旧文档无独立表
**旧文档**: 复习提交通过 `study_attempts` 统一记录（`study_type='review'`）
**代码实际**: 独立表 `review_attempts`，字段为 `id, user_id, review_group_id, word_id, action_result, created_at`
**实现状态**: [已实现]
**建议动作**: 写入新文档 -- 代码将复习 attempt 与学习 attempt 分表，需记录此设计决策

---

### 模块：主机制 - 日常/Session/签到

---

### [DB-015] [🟡] daily_goal_progress 表 - 字段差异

**位置**: 旧文档 7.8 / current-db.md Table: daily_goal_progress
**旧文档**: 包含 `book_id`, `target_new_count`, `completed_new_count`, `review_target_mode`, `target_review_count`, `pending_review_count_snapshot`, `completed_review_count`, `check_in_completed`, `valid_session_completed`, `goal_status_reason`, `last_evaluated_at`
**代码实际**: 字段名略有不同：`new_target`(非 target_new_count), `new_completed`(非 completed_new_count), `review_target`, `review_pending`, `review_completed`, `goal_status`；无 `book_id`, `review_target_mode`, `check_in_completed`, `valid_session_completed`, `goal_status_reason`, `last_evaluated_at`；新增 `active_review_group_id`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [DB-016] [🟡] session_records 表 - 字段精简

**位置**: 旧文档 7.9 / current-db.md Table: session_records
**旧文档**: 包含 `local_date`, `session_type`, `actual_duration_seconds`, `validation_reason_code`, `session_rules_snapshot(jsonb)`, `reward_settlement_status`, `start_idempotency_key`, `finish_idempotency_key`, `validated_at` 等丰富字段
**代码实际**: 仅有 `id, user_id, session_status, validation_status, minutes_target, started_at, ended_at, actual_minutes, effective_learning_count, effective_review_count, created_at`；无 `local_date`, 无 `session_type`, 无 `session_rules_snapshot`, 无 `reward_settlement_status`, 无 idempotency_key 字段
**实现状态**: [已实现] -- 精简版
**建议动作**: 以代码为准写入新文档

---

### [DB-017] [🟡] check_in_records 表 - 字段精简

**位置**: 旧文档 7.10 / current-db.md Table: check_in_records
**旧文档**: 包含 `check_in_status`, `streak_snapshot_before`, `streak_snapshot_after`, `node_reward_code`, `check_in_reward_source_event_id`, `idempotency_key`, `checked_in_at`
**代码实际**: 仅有 `id, user_id, local_date, status(DEFAULT 'succeeded'), created_at`；无 streak 快照、无奖励关联、无幂等键
**实现状态**: [已实现] -- 最小版
**建议动作**: 以代码为准写入新文档

---

### [DB-018] [🟡] learning_day_facts 表 - 字段精简

**位置**: 旧文档 7.10A / current-db.md Table: learning_day_facts
**旧文档**: 包含 `learning_day_status`, `effective_attempt_count`, `first_effective_attempt_at`, `last_effective_attempt_at`, `source_rule_snapshot`
**代码实际**: 仅有 `id(SERIAL), user_id, local_date, is_learning_day(BOOLEAN), effective_learning_count, effective_review_count, updated_at`；用布尔代替 status 枚举，增加了 review_count
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [DB-019] [🟡] streak_records 表 - 字段精简

**位置**: 旧文档 7.11 / current-db.md Table: streak_records
**旧文档**: PK 为 `user_id`，包含 `max_streak`, `last_counted_local_date`, `total_learning_days`, `created_at`
**代码实际**: PK 为 `id(SERIAL)`，`user_id UNIQUE`；无 `max_streak`、无 `total_learning_days`；`last_counted_local_date` 改名为 `last_check_in_date`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### 模块：奖励与结算

---

### [DB-020] [🟡] reward_source_events 表 - 字段精简

**位置**: 旧文档 7.12 / current-db.md Table: reward_source_events
**旧文档**: 包含 `source_event_type(8种枚举)`, `source_ref_id(uuid nullable)`, `local_date`, `source_payload(jsonb)`, `settlement_status(5种)`, `settlement_error_code`, `settlement_summary(jsonb)`, `idempotency_key`, `emitted_at`, `settled_at` 等 16 个字段
**代码实际**: 仅有 `id, user_id, event_type, source_ref_id(VARCHAR128 NOT NULL), created_at`；约束 `UNIQUE(event_type, source_ref_id)`
**实现状态**: [已实现] -- 极简版
**建议动作**: 以代码为准写入新文档；settlement_status 等字段被拆到 settlements 表

---

### [DB-021] [🟡] reward_ledger 表 - 字段差异

**位置**: 旧文档 7.13 / current-db.md Table: reward_ledger
**旧文档**: 包含 `reward_item_code`, `reward_amount(numeric12,2)`, `status(4种枚举)`, `balance_after`, `applied_at`, `updated_at`
**代码实际**: 无 `reward_item_code`、无 `balance_after`、无 `applied_at`、无 `updated_at`；`amount` 为 `INT`（非 numeric），`reward_status` 默认 `'succeeded'`（非 pending）
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [DB-022] [🟢] settlements 表 - 代码有、旧文档无

**位置**: current-db.md Table: settlements / 旧文档无独立表
**旧文档**: 结算状态内嵌于 `reward_source_events.settlement_status`
**代码实际**: 独立表 `settlements`，含 `id, source_event_id(UNIQUE), user_id, settlement_status(DEFAULT 'succeeded'), created_at, updated_at`
**实现状态**: [已实现]
**建议动作**: 写入新文档 -- 代码将结算拆为独立表

---

### [DB-023] [🟢] idempotency_keys 表 - 代码有、旧文档无

**位置**: current-db.md Table: idempotency_keys / 旧文档无独立表
**旧文档**: 幂等键内嵌于各业务表（如 `study_attempts.idempotency_key`）
**代码实际**: 独立表 `idempotency_keys`，含 `key(PK), user_id, path, response(JSONB DEFAULT '{}'), created_at`
**实现状态**: [已实现]
**建议动作**: 写入新文档 -- 代码采用集中式幂等管理

---

### [DB-024] [🔴] learning_stat_daily 表 - 代码中不存在

**位置**: 旧文档 7.14 / current-db.md 无对应表
**旧文档**: 定义了 `learning_stat_daily` 表（含 16 个字段，用于每日统计汇总）
**代码实际**: 该表不存在于任何 migration 中
**实现状态**: [占位·未实现]
**建议动作**: 需用户确认 -- 是计划后续实现还是已放弃

---

### 模块：副机制 - 宠物与钱包

---

### [DB-025] [🟡] secondary_wallets 表 - 字段差异

**位置**: 旧文档 17.2.1 / current-db.md Table: secondary_wallets
**旧文档**: 包含 `available_coins`, `available_fish_treats`, `lifetime_earned_coins`, `lifetime_spent_coins`, `lifetime_earned_fish_treats`, `lifetime_spent_fish_treats`, `source_version(bigint)`, `created_at`
**代码实际**: 仅有 `id(SERIAL), user_id(UNIQUE), coins_spent, feed_mood_accumulated, feed_exp_accumulated, feed_bond_accumulated, updated_at`；无余额字段、无 lifetime 统计、无 source_version
**实现状态**: [已实现] -- 实现思路不同（代码存累计变化量，非即时余额）
**建议动作**: 以代码为准写入新文档；需确认余额是否通过 reward_ledger 聚合计算

---

### [DB-026] [🟡] pet_profiles 表 - 字段差异

**位置**: 旧文档 17.2.2 / current-db.md Table: pet_profiles
**旧文档**: 包含 `pet_code`, `total_exp`, `current_level`, `mood_value`, `bond_value`, `energy_value`, `last_growth_feedback_at`
**代码实际**: 仅有 `id(SERIAL), user_id(UNIQUE), nickname(DEFAULT 'Mimi'), base_mood(INT DEFAULT 60), base_bond(INT DEFAULT 0), created_at, updated_at`；无 `pet_code`, 无 `total_exp`, 无 `current_level`, 无 `energy_value`
**实现状态**: [已实现] -- 精简版
**建议动作**: 以代码为准写入新文档

---

### [DB-027] [🟡] feed_events 表 - 命名与字段差异

**位置**: 旧文档 17.2.3 (pet_feed_events) / current-db.md Table: feed_events
**旧文档**: 表名为 `pet_feed_events`，包含 `pet_profile_id`, `consumed_item_type`, `benefit_tier`, `idempotency_key`, `balance_after_fish_treats`
**代码实际**: 表名为 `feed_events`，无 `pet_profile_id`, 无 `benefit_tier`, 无 `idempotency_key`, 无 `balance_after_fish_treats`；新增 `consumed_amount(INT DEFAULT 1)`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### 模块：副机制 - 商店与装备

---

### [DB-028] [🟡] shop_catalog_items 表 - 字段差异

**位置**: 旧文档 17.2.4 / current-db.md Table: shop_catalog_items
**旧文档**: 包含 `item_code(unique)`, `slot_key`, `display_name`, `price_coins`, `level_required`, `sort_order`, `item_payload(jsonb)`, `updated_at`
**代码实际**: 无 `item_code`，`slot` 代替 `slot_key`，`name` 代替 `display_name`，`coin_price` 代替 `price_coins`，`required_level` 代替 `level_required`；无 `sort_order`, 无 `item_payload`, 无 `updated_at`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [DB-029] [🟡] inventory_items / purchase_records 表 - 与设计差异

**位置**: 旧文档 17.2.5 (shop_purchase_events) + 17.2.6 (user_inventory_items) / current-db.md
**旧文档**: `shop_purchase_events` 含 `purchase_status`, `failure_code`, `idempotency_key`, `balance_after_coins`, `purchased_at`；`user_inventory_items` 含 `quantity`, `ownership_status`, `source_purchase_event_id`
**代码实际**: `purchase_records` 更精简（`id SERIAL, user_id, item_id, coins_spent, idempotency_key, created_at`）；`inventory_items` 含 `equipped(BOOLEAN)`, `owned_at`，无 `quantity`, 无 `ownership_status`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [DB-030] [🟡] equipment_slots 表 - 字段差异

**位置**: 旧文档 17.2.7 (user_equipment_slots) / current-db.md Table: equipment_slots
**旧文档**: 表名 `user_equipment_slots`，引用 `inventory_item_id`，含 `equipped_at`
**代码实际**: 表名 `equipment_slots`，引用 `item_id -> shop_catalog_items`（而非 inventory），无 `equipped_at`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### 模块：Backup / Restore

---

### [DB-031] [🔴] user_backup_snapshots 表 - 代码中不存在

**位置**: 旧文档 18.3.1 / current-db.md 无对应表
**旧文档**: 定义了详细的 `user_backup_snapshots` 表（含 ~20 个字段：upload_status, checksum, schema_version 等）
**代码实际**: 备份数据存于 dev-store 内存（`_latestBackup`, `_backupSnapshot`），无持久化表
**实现状态**: [已开发·未集成] -- 备份功能已通过 API 可用，但数据仅在内存中
**建议动作**: 需用户确认 -- 当前 dev-store 内存实现是否为临时方案

---

### [DB-032] [🔴] backup_restore_operations 表 - 代码中不存在

**位置**: 旧文档 18.3.2 / current-db.md 无对应表
**旧文档**: 定义了详细的 `backup_restore_operations` 审计表（含 ~20 个字段）
**代码实际**: 该表不存在，restore 操作无审计记录
**实现状态**: [占位·未实现]
**建议动作**: 需用户确认 -- 设计中的 restore audit trail 是否在开发计划内

---

## 三、全局性差异

---

### [DB-033] [🟡] 全局 PK 类型不一致

**位置**: 旧文档 4.1 / current-db.md 全局
**旧文档**: "主键统一使用 uuid"
**代码实际**: 混用 `VARCHAR(64)` 和 `SERIAL`（自增整数）。部分表用 VARCHAR(64) 字符串作 PK，部分表用 SERIAL
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档；记录当前 PK 策略为混合方案

---

### [DB-034] [🟡] 索引与约束精简

**位置**: 旧文档各表 §X.3 / current-db.md 全局
**旧文档**: 每表定义了详细的唯一约束、CHECK 约束、条件唯一索引
**代码实际**: 约束数量明显少于设计文档（如无 CHECK 约束、条件唯一索引精简）
**实现状态**: [已实现] -- MVP 精简版
**建议动作**: 以代码为准写入新文档

---

### [DB-035] [🟢] 本地端数据库 - 代码有、旧文档无

**位置**: current-db.md 本地端数据库 / 旧文档未覆盖
**旧文档**: 仅覆盖云端 PostgreSQL 表设计
**代码实际**: 存在完整的本地端 SQLite 架构：
- Legacy v1（sqflite）: `word_records`, `wordbook_progress`, `daily_checkins`, `custom_wordbooks`, `vocabulary_notebook`
- FSRS v2（drift）: `card_states`, `review_logs`, `cached_words`
- SharedPreferences: 设置类 + 备份状态 + 进度缓存
**实现状态**: [已实现]
**建议动作**: 写入新文档 -- 本地端数据库为全新内容，旧文档完全未覆盖

---

### [DB-036] [🟢] FSRS 复习调度体系 - 代码有、旧文档无

**位置**: current-db.md Table: card_states + review_logs / 旧文档无
**旧文档**: 复习调度依赖云端 `review_queue` + `review_groups`
**代码实际**: 本地端存在独立的 FSRS 复习调度体系（`card_states` + `review_logs`），与云端 `review_groups` 并行运行，两套体系无直接映射
**实现状态**: [已实现]
**建议动作**: 写入新文档 -- 记录双轨复习架构现状

---

### [DB-037] [🟢] dev-store 内存层 - 代码有、旧文档无

**位置**: current-db.md 技术信息 / 旧文档无
**旧文档**: 未提及运行时存储模式
**代码实际**: 云端存在 dev-store（纯内存）+ 可选 pg backend 双模式，通过 `PERSISTENCE_BACKEND` 环境变量切换
**实现状态**: [已实现]
**建议动作**: 写入新文档

---

### [DB-038] [⚠️] 云端与本地端复习机制的关系

**位置**: current-db.md 对比4 / 旧文档 7.7-7.7B
**旧文档**: 假定复习全部走云端 review_groups/review_queue 路径
**代码实际**: 云端有 review_groups/review_group_items/review_attempts，本地端有 FSRS card_states/review_logs。两套体系当前独立运行，无直接映射
**实现状态**: [已实现] -- 但架构上存在双轨问题
**建议动作**: 需用户确认 -- 两套复习体系的长期合并/统一策略

---

### [DB-039] [⚠️] 本地端独有表的云端对应关系

**位置**: current-db.md 对比 5/6/7
**旧文档**: 未提及 `custom_wordbooks`, `vocabulary_notebook`, `wordbook_progress`
**代码实际**: 这三张本地表无云端对应：
- `custom_wordbooks` - 用户自建词书（云端无）
- `vocabulary_notebook` - 生词本（云端无）
- `wordbook_progress` - 词书进度（云端无直接对应，需聚合 user_word_progress）
**实现状态**: [已实现]
**建议动作**: 需用户确认 -- 这些本地独有功能是否需要云端同步支持
