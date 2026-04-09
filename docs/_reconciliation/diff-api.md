# API 差异对比报告

> **旧文档**: `背单词喵喵app_API设计草案_v0.1.4.md`
> **代码实际**: `current-api.md`（基于 commit bface75 代码反推）
> **生成日期**: 2026-04-08

---

## 一、总体差异概览

| 维度 | 旧文档 | 代码实际 |
|------|--------|----------|
| 端点总数 | 24 个 cloud API（9.接口清单） | 26 个 cloud API + 8 个本地 Service |
| 接口层级 | 仅云端 REST | 云端 REST + 本地 Service 层 + 同步接口 |
| 鉴权 | Bearer token | 无鉴权（dev mode, 硬编码 dev-user-001） |
| Base URL | `https://api.example.com/v1` | `/api/v1`（NestJS setGlobalPrefix，端口 3000） |
| 响应信封 | `{ok, request_id, data, meta}` | 无统一信封，直接返回 data |
| 降级模式 | 未提及 | MAINTENANCE_MODE / READ_ONLY_MODE / TEMPORARILY_UNAVAILABLE |
| 持久化后端 | PostgreSQL | dev-store(内存) + 可选 pg |

---

## 二、云端 API 差异（按模块分组）

---

### 模块：系统

---

### [API-001] [🟢] GET /health - 代码有、旧文档无

**位置**: current-api.md #1 / 旧文档无
**旧文档**: 无健康检查端点
**代码实际**: `GET /api/v1/health` 返回 `status`, `persistence_backend`, `write_blocked`, `degraded_state`, `timestamp`
**实现状态**: [已实现]
**建议动作**: 写入新文档

---

### [API-002] [🟢] 降级/维护模式 - 代码有、旧文档无

**位置**: current-api.md 全局设置 / 旧文档无
**旧文档**: 未提及降级机制
**代码实际**: 支持 `MAINTENANCE_MODE`, `READ_ONLY_MODE`, `TEMPORARILY_UNAVAILABLE` 环境变量，通过中间件全局拦截返回 503
**实现状态**: [已实现]
**建议动作**: 写入新文档

---

### 模块：认证与基础身份

---

### [API-003] [🔴] POST /auth/guest-sessions - 旧文档有、代码无

**位置**: 旧文档 10.1 / current-api.md 无对应端点
**旧文档**: 定义了 `POST /auth/guest-sessions`，支持游客模式创建，返回 `user_id`, `access_token`, `account_type`
**代码实际**: 无认证端点。使用硬编码 `dev-user-001` 作为所有请求的用户身份
**实现状态**: [占位·未实现] -- 认证模块整体未开发
**建议动作**: 需用户确认 -- 认证模块是否在近期计划内

---

### [API-004] [🔴] POST /auth/email-sessions - 旧文档有、代码无

**位置**: 旧文档 10.2 / current-api.md 无对应端点
**旧文档**: 定义了 `POST /auth/email-sessions`，为 MVP 留的登录契约入口
**代码实际**: 不存在
**实现状态**: [占位·未实现]
**建议动作**: 需用户确认 -- 是否保留为 planned

---

### 模块：词书与学习目标设置

---

### [API-005] [🔴] GET /word-books - 旧文档有、代码无

**位置**: 旧文档 11.1 / current-api.md 无对应端点
**旧文档**: `GET /word-books` 返回可用词书列表（含 code, name, difficulty, is_active）
**代码实际**: 无该端点。词书信息通过 dev-store 内存直接提供，Flutter 端通过 WordCacheService 的 `/books/:bookId/words` 间接获取
**实现状态**: [占位·未实现]
**建议动作**: 需用户确认

---

### [API-006] [🟡] PUT /me/book-settings vs PUT /me/settings/daily-goal

**��置**: 旧文档 11.2 / current-api.md #22
**旧文档**: `PUT /me/book-settings` 设置当前 active 词书与每日目标，请求体含 `book_id`, `daily_new_target`, `daily_review_target_mode`, `daily_review_target_value`
**代码实际**: `PUT /api/v1/me/settings/daily-goal` 仅更新每日新词目标（`daily_new_target`），无词书切换能力，无复习目标模式
**实现状态**: [已实现] -- 功能缩减版
**建议动作**: 以代码为准写入新文档；词书切换、复习目标模式设置未实现

---

### 模块：新词学习

---

### [API-007] [🟡] GET /me/new-words/next - 路径一致、响应差异

**位置**: 旧文档 13.1 / current-api.md #2
**旧文档**: 支持 `session_id` 可选参数，返回含 `example_sentence`, `audio_url`, `progress_current`, `progress_target`
**代码实际**: 无 `session_id` 参数，响应为 Word 对象（含 002 migration 新增的 `translation`, `definition`, `difficulty_level`, `is_core`, `tags`, `frequency_rank`, `word_forms`），无 `example_sentence`, 无 `audio_url`, 无 progress 字段
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [API-008] [🟡] POST /study-attempts vs POST /me/new-words - 路径与响应差异

**位置**: 旧文档 13.2 / current-api.md #3
**旧文档**: `POST /study-attempts` 路径，请求含 `session_id`，响应含 `attempt_id`, `is_effective_learning`, `progress_current`, `progress_target`, `session_snapshot`, `review_queue_effect`
**代码实际**: `POST /api/v1/me/new-words` 路径不同，无 `session_id`，响应含 `submit_status`, `today_new_completed`, `daily_goal_status`, `already_exists`, `settlement`(含 source_event_id, reward_settlement_status, reward_items)
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档；代码路径为 `/me/new-words` 而非设计中的 `/study-attempts`

---

### 模块：复习

---

### [API-009] [🟡] GET /me/review-groups/next - 响应差异

**位置**: 旧文档 14.1 / current-api.md #4
**旧文档**: 支持 `session_id` 参数，返回含 `group_size_total`, `group_size_completed`, `group_size_remaining`, `review_queue_count`, `review_progress_current`, `review_progress_target`, items 含 `review_item_id`, `question_type`, `prompt`, `options`, `answer_input_schema`
**代码实际**: 无 `session_id`，返回含 `review_group_id`, `group_status`, `group_completed`, `remaining_count`；items 仅含 `word_id`, `word_text`, `meaning`, `completed`；无 group size 统计、无 question_type/options
**实��状态**: [已实现] -- 精简版（无题型系统）
**建议动作**: 以代码为准写入新文档

---

### [API-010] [🟡] POST /review-attempts - 请求与响应差异

**位置**: 旧文档 14.2 / current-api.md #5
**旧文档**: 请求含 `review_item_id`, `question_type`, `answer`, `session_id`，响应含 `is_correct`, `is_effective_review`, 分层的 `review_group` 和 `today_review_progress` 对象, `session_snapshot`
**代码实际**: 请求仅含 `review_group_id`, `word_id`, `action_result('correct'/'incorrect')`；响应含 `submit_status`, `group_completed`, `group_remaining`, `today_review_completed`, `daily_goal_status`, `already_exists`, `settlement`
**实现状态**: [已实现] -- 扁平化响应
**建议动作**: 以代码为准写入新文档

---

### 模块：今日聚合

---

### [API-011] [🟡] GET /me/today - 响应结构差异

**位置**: 旧文档 12.1 / current-api.md #6
**旧文档**: 嵌套结构：`current_book{}`, `daily_goal{}`, `check_in{}`, `learning_day{}`, `streak{}`, `session{}`, `last_reward_settlement{}`, `cat_summary_brief{}`, `sync_status`，含 `server_time_utc`, `user_timezone`, `user_local_date`
**代码实际**: 扁平结构，字段直接平铺在顶层：`current_book_name`, `today_new_target`, ..., `daily_goal_status`, `has_checked_in_today`, `current_streak`, ..., `sync_status`；新增 `today_primary_action` 和 `review_summary`；无 `server_time_utc` / `user_timezone` / `user_local_date` 时间三件套
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [API-012] [🟡] GET /me/today - daily_goal_status 枚举差异

**位置**: 旧文档 7.1 (枚举) / current-api.md #6
**旧文档**: `daily_goal_status` 枚举含 `not_started`, `in_progress`, `partially_completed`, `completed`
**代码实际**: `daily_goal_status` 返回值为 `not_started`, `in_progress`, `completed`（无 `partially_completed`）
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档；需确认 `partially_completed` 是否后续加入

---

### [API-013] [🟢] GET /me/today - today_primary_action 代码有、旧文档无

**位置**: current-api.md #6 / 旧文档 PD-DB-003 (CTA winner rule 未冻结)
**旧文档**: CTA winner rule 标记为"仍待冻结"
**代码实际**: `today_primary_action` 已实现，含 `action`(`continue_review_group`/`go_review`/`go_new_words`/`go_session`) 和 `reason`
**实现状态**: [已实现]
**建议动作**: 写入新文档 -- 虽然旧文档标记为 pending，代码已实现初版 CTA decision-support

---

### [API-014] [🟡] GET /me/today - 缺少时间三件套

**位置**: 旧文档 5.4 + 12.1.3 / current-api.md #6
**旧文档**: 要求返回 `server_time_utc`, `user_local_date`, `user_timezone`
**代码实际**: 响应中无这三个字段
**实现状态**: [占位·未实现]
**建议动作**: 需用户确认 -- 是否为后续补齐项

---

### 模块：Session

---

### [API-015] [🟡] POST /sessions - 请求与响应差异

**位置**: 旧文档 15.1 / current-api.md #7
**旧文档**: 请求含 `session_type`, `planned_duration_seconds`，响应含 `required_effective_attempts`, `planned_duration_seconds`
**代码实际**: 请求含 `session_minutes_target`（直接用分钟），响应含 `session_minutes_target`, `started_at`, `already_exists`；无 `session_type`, 无 `required_effective_attempts`, 无 `planned_duration_seconds`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [API-016] [🟡] POST /sessions/:id/finish - 响应差异

**位置**: 旧文档 15.2 / current-api.md #8
**旧文档**: 响应含 `effective_attempts_total`, `required_effective_attempts`, `actual_duration_seconds`, `planned_duration_seconds`, `reward_settlement_status`, `jump_targets_available`
**代码实际**: 响应含 `session_id`, `session_status`, `session_validation_status`, `effective_learning_count`, `effective_review_count`, `session_minutes_target`, `started_at`, `ended_at`, `already_exists`；无 `reward_settlement_status`, 无 `jump_targets_available`, 无 `actual_duration_seconds`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [API-017] [🟡] GET /sessions/:id - 响应差异

**位置**: 旧文档 15.3 / current-api.md #9
**旧文档**: 响应含 `validation_reason`, `effective_attempts_total`, `required_effective_attempts`, `planned_duration_seconds`, `actual_duration_seconds`, `reward_settlement_status`, `validated_at`
**代码实际**: 响应仅含 `session_id`, `session_status`, `session_validation_status`, `session_minutes_target`, `started_at`, `ended_at`, `effective_learning_count`, `effective_review_count`
**实现状态**: [已实现] -- 精简版
**建议动作**: 以代码为准写入新文档

---

### 模块：签到与 Streak

---

### [API-018] [🟡] POST /check-ins - 响应结构差异

**位置**: 旧文档 16.1 / current-api.md #10
**旧文档**: 嵌套响应含 `check_in{check_in_id, checked_in, checked_in_at, user_local_date}`, `learning_day{has_learning_day_today, effective_attempt_count}`, `streak{current_streak, max_streak, streak_basis_type, streak_extended_today}`, `node_reward{reward_code, reward_settlement_status}`
**代码实际**: 响应含 `check_in{local_date, check_in_status}`, `streak{current_streak, streak_basis_type}`, `learning_day{learning_day_today}`, `already_exists`；无 `check_in_id`, 无 `checked_in_at`, 无 `max_streak`, 无 `streak_extended_today`, 无 `node_reward`
**实现状态**: [已实现] -- 精简版
**建议动作**: 以代码为准写入新文档

---

### [API-019] [🟢] GET /check-ins/today - 代码有、旧文档无

**位置**: current-api.md #11 / 旧文档无单独签到查询端点
**旧文档**: 签到查询通过 `GET /me/today` 中的 check_in 子对象实现
**代码实际**: 独立端点 `GET /api/v1/check-ins/today`，返回签到/streak/learning_day 状态
**实现状态**: [已实现] -- 但 Flutter 端 ApiClient 未封装此方法
**建议动作**: 写入新文档

---

### 模块：结算

---

### [API-020] [🟡] POST /settlements/learning-rounds - 请求字段差异

**位置**: 旧文档 17.1 / current-api.md #12
**旧文档**: 请求字段为 `settlement_source_type`（5 种枚举），响应含 `effective_learning_count`, `effective_review_count`, `daily_goal_status`, `session_validation_status`, `cat_growth_summary`, `jump_targets_available`
**代码实际**: 请求字段为 `source_event_type`（2 种：`effective_new_word` / `review_group_completed`）+ `source_ref_id`；响应含 `settlement_id`, `source_event_id`, `reward_settlement_status`, `reward_items[]`, `already_exists`；无 daily_goal/session 状态、无 cat_growth_summary、无 jump_targets
**实现状态**: [已实现] -- 精简版（仅 2 种 source_event_type）
**建议动作**: 以代码为准写入新文档

---

### [API-021] [🟡] GET /settlements/:sourceEventId - 响应差异

**位置**: 旧文档 17.2 / current-api.md #13
**旧文档**: 响应含 `settled_at`, `reward_items[].reward_amount`
**代码实际**: 响应含 `settlement_id`, `source_event_id`, `source_event_type`, `source_ref_id`, `reward_settlement_status`, `reward_items[]`, `created_at`, `updated_at`；Flutter 端 ApiClient 未封装此方法
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### 模块：统计

---

### [API-022] [🔴] GET /me/stats/summary - 旧文档有、代码无

**位置**: 旧文档 18.1 / current-api.md 无对应端点
**旧文档**: 定义了 `GET /me/stats/summary`，返回 today/week/all_time 三层统计汇总
**代码实际**: 无该端点
**实现状态**: [占位·未实现]
**建议动作**: 需用户确认 -- 统计页 API 是否在开发计划内

---

### 模块：副机制 - 二级激励

---

### [API-023] [🟡] GET /me/secondary-summary - 响应结构差异

**位置**: 旧文档 25.2.1 / current-api.md #14
**旧文档**: 响应含嵌套结构 `balances{coins, fish_treats, exp}`, `cat_summary{nickname, level, total_exp, mood, bond, energy}`, `companion_response{daily_greeting, ...}`, `equipped_preview[{slot_key, item_code, display_name}]`, `motivation_facts{has_checked_in_today, ...}`
**代码实际**: 响应为扁平结构含 `coins`, `fish_treats`, `exp`, `cat_summary{nickname, mood, level, exp_to_next_level, mood_display_text}`, `companion_response`, `equipped_preview(map)`, `change_highlights[]`, `stats_summary`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [API-024] [🟡] POST /me/feed - 请求与响应差异

**位置**: 旧文档 25.2.2 / current-api.md #15
**旧文档**: 请求字段为 `consumed_item_type`，响应含 `submit_status`, `benefit_tier`, `balances{}`, `cat_summary{}`, `growth_feedback{level_up, exp_delta, mood_delta, bond_delta}`
**代码实际**: 请求字段为 `feed_item_type`，响应分成功/失败两种：成功含 `feed_result{status, consumed_item, consumed_amount, mood_delta, exp_delta, already_exists}`, `growth_feedback{leveled_up, previous_level, current_level}`, `secondary_summary`（完整副机制摘要）；余额不足含 `feed_result{status, error_code}`, `secondary_summary`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [API-025] [🟡] GET /shop/catalog - 响应精简

**位置**: 旧文档 25.2.3 / current-api.md #16
**旧文档**: 返回含 `item_code`, `display_name`, `price_coins`, `level_required` 等详细字段
**代码实际**: 返回 `items[]` 为 CatalogItem 数组（具体字段来自 dev-store）
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [API-026] [🟡] POST /shop/purchases - 响应结构差异

**位置**: 旧文档 25.2.4 / current-api.md #17
**旧文档**: 请求字段为 `item_code`，错误码含 `CATALOG_ITEM_NOT_FOUND`, `ITEM_ALREADY_OWNED`, `ITEM_LEVEL_LOCKED`, `COINS_NOT_ENOUGH`
**代码实际**: 请求字段为 `item_id`；响应含 `purchase_result{status, item_id, coins_spent, already_exists}` + `inventory`；或失败时 `purchase_result{status, error_code}` + `inventory`
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [API-027] [🟡] GET /me/inventory, GET /me/equipment, POST equip/unequip - 存在但精简

**位置**: 旧文档 25.2.5-25.2.8 / current-api.md #18-21
**旧文档**: 详细定义了请求/响应结构
**代码实际**: 四个端点均已实现，但响应结构更精简；`POST /me/equipment/unequip` 的 Flutter ApiClient 未封装
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### 模块：备份/恢复

---

### [API-028] [🟡] POST /me/backups vs POST /me/backup - 路径与结构差异

**位置**: 旧文档 26.3.1 / current-api.md #23
**旧文档**: `POST /me/backups`（复数），请求含详细 metadata（backup_id, snapshot_scope, schema_version, checksum_algorithm, checksum_value, source_app_version, source_device_label）
**代码实际**: `POST /api/v1/me/backup`（单数），请求仅含 `snapshot(object)` + 可选 `schema_version`；响应含 `status`, `backup_id`, `uploaded_at`, `schema_version`
**实现状态**: [已实现] -- 精简版（无 checksum、无 device_label）
**建议动作**: 以代码为准写入新文档

---

### [API-029] [🟡] GET /me/backups/latest vs GET /me/backup/latest - 路径与响应差异

**位置**: 旧文档 26.3.2 / current-api.md #24
**旧文档**: `GET /me/backups/latest`（复数），返回含 `restorable_hint`, `source_device_label`, `payload_size_bytes`, `checksum_algorithm`, `checksum_value`
**代码实际**: `GET /api/v1/me/backup/latest`（单数），返回含 `status('succeeded'/'no_backup_yet')`, `backup_id`, `uploaded_at`, `schema_version`, `snapshot_size`；无 restorable_hint、无 checksum；Flutter 端未封装此方法
**实现状态**: [已实现]
**建议动作**: 以代码为准写入新文档

---

### [API-030] [🔴] POST /me/backups/latest/restore-precheck - 旧文档有、代码无

**位置**: 旧文档 26.3.3 / current-api.md 无对应端点
**旧文档**: 定义了 `POST /me/backups/latest/restore-precheck`，返回 `restore_readiness`, `warning_required`, `warning_code`, `checksum_verified`, `payload_structurally_valid`
**代码实际**: 无独立 precheck 端点；恢复流程直接通过 `GET /me/backup/latest/snapshot` 获取完整 snapshot 后在客户端做 schema 校验
**实现状态**: [占位·未实现] -- 安全检查逻辑在客户端而非独立 API
**建议���作**: 需用户确认 -- 是否需要服务端 precheck 端点

---

### [API-031] [🔴] POST /me/backups/latest/download - 旧文档有、代码无

**位置**: 旧文档 26.3.4 / current-api.md 无对应端点
**旧文档**: 定义了 `POST /me/backups/latest/download`，显式分层 download completed 与 apply success
**代码实际**: 无独立 download 端点；下载动作内嵌在 `GET /me/backup/latest/snapshot` 中
**实现状态**: [占位·未实现]
**建议动作**: 需用户确认

---

### [API-032] [🔴] POST /me/backups/latest/restore-apply - 旧文档有、代码无

**位置**: 旧文档 26.3.5 / current-api.md 无对应端点
**旧文档**: 定义了 `POST /me/backups/latest/restore-apply`，要求 `confirm_overwrite`, `client_checksum_verified`，返回 `restore_status`
**代码实际**: 无 restore-apply 端点；restore 操作完全在 Flutter 客户端本地执行（`BackupRestoreService`）
**实现状态**: [占位·未实现] -- restore apply 为纯客户端行为
**建议动作**: 需用户确认 -- 旧文档的三步分层（precheck/download/apply）被代码合并为客户端一步式流程

---

### [API-033] [🟢] GET /me/backup/latest/snapshot - 代码有、旧文档无独立端点

**位置**: current-api.md #25 / 旧文档无独立 snapshot 下载端点（被分拆到 download + apply）
**旧文档**: snapshot 获取分成两步：download endpoint + apply endpoint
**代码实际**: `GET /api/v1/me/backup/latest/snapshot` 直接返回完整 snapshot JSON（含 `status`, `schema_version`, `uploaded_at`, `snapshot`）
**实现状态**: [已实现]
**建议动作**: 写入新文档

---

### 模块：词库

---

### [API-034] [🟢] GET /books/:bookId/words - 代码有、旧文档无

**位置**: current-api.md #26 / 旧文档无
**旧文档**: 无词库批量下载端点
**代码实际**: `GET /api/v1/books/:bookId/words` 支持 offset/limit 分页（默认 500，最大 1000），供 Flutter 端 `WordCacheService` 批量下载词库到本地缓存
**实现状态**: [已实现]
**建议动作**: 写入新文档

---

## 三、本地端接口差异

---

### [API-035] [🟢] 本地端 Service 层 - 代码有、旧文档无

**位置**: current-api.md 本地端接口 / 旧文档未覆盖
**旧文档**: 仅覆盖云端 REST API 设计
**代码实际**: 存在完整本地端 Service 层架构：
- `StudyService` - Local-first 学习提交（SQLite 先写 + 后台同步 API）
- `FsrsService` - 纯本地 FSRS 复习调度（card_states + review_logs）
- `SessionBuilder` - 纯本地学习 Session 构建
- `WordCacheService` - 云端词库下载到本地缓存
- `LocalSettingsService` - SharedPreferences 设置管理
- `LocalProgressRepository` - SharedPreferences JSON 进度存储
- `LocalDatabase` - sqflite legacy 学习数据存储
- `AppDatabase (drift)` - FSRS + cached_words 存储
**实现状态**: [已实现]
**建议动作**: 写入新文档 -- 本地端 Service 层为全新内容

---

### [API-036] [🟢] 同步接口 - 代码有、旧文档无

**位置**: current-api.md 同步接口 / 旧文档未覆盖
**旧文档**: 未定义同步机制
**代码实际**: 存在三种同步流程：
1. 学习记录同步（SQLite synced=0 → API，stop-on-first-failure）
2. 备份/恢复（本地 snapshot export → cloud upload → cloud download → local apply）
3. 词库缓存下载（Cloud API → 本地 drift/SQLite）
**实现状态**: [已实现]
**建议动作**: 写入新文档

---

## 四、全局性差异

---

### [API-037] [🟡] 鉴权机制

**位置**: 旧文档 5.2 / current-api.md 鉴权机制
**旧文档**: `Authorization: Bearer <token>`，除游客创建和登录外均需鉴权
**代码实际**: 无鉴权。Dev mode，所有 API 均无 Authorization header，CORS 设为 `*`，单用户 `dev-user-001`
**实现状态**: [占位·未实现]
**建议动作**: 以代码为准写入新文档；鉴权属于 planned 但未实现

---

### [API-038] [🟡] 响应信封格式

**位置**: 旧文档 5.5 / current-api.md 全局
**旧文档**: 统一响应信封 `{ok, request_id, data, meta}` / 错误信封 `{ok: false, error: {code, message, retryable, details}}`
**代码实际**: 无统一信封，直接返回 data 对象；错误通过 HTTP status code + errorFilter 中间件处理
**实现状态**: [占位·未实现]
**建议动作**: 需用户确认 -- 是否计划实施统一信封

---

### [API-039] [🟡] 幂等 Header

**位置**: 旧文档 5.3 + 5.6 / current-api.md 全局
**旧文档**: 写接口必须带 `X-Idempotency-Key`，定义了详细的幂等规则
**代码实际**: Allowed Headers 中包含 `X-Idempotency-Key`，且 `idempotency_keys` 表存在于 DB 中；部分写接口实现了幂等（如 study-attempts, review-attempts, sessions, check-ins）
**实现状态**: [已实现] -- 部分端点已实现
**建议动作**: 以代码为准写入新文档

---

### [API-040] [🟡] 错误码体系

**位置**: 旧文档 8 / current-api.md 全局
**旧文档**: 定义了完整的错误码表（38+ 个错误码）
**代码实际**: 未见集中定义的错误码常量；错误通过 errorFilter 中间件和 HTTP status code 处理
**实现状态**: [已开发·未集成] -- 部分端点有特定错误处理但无统一错误码体系
**建议动作**: 需用户确认 -- 统一错误码体系是否在计划内

---

### [API-041] [🟡] 时间与自然日约定

**位置**: 旧文档 5.4 / current-api.md 全局
**旧文档**: 要求所有 streak/签到/daily goal 相关接口返回 `server_time_utc`, `user_local_date`, `user_timezone`
**代码实际**: 大部分响应中无时间三件套；时区处理在 dev-store 中实现但不暴露给客户端
**实现状态**: [占位·未实现]
**建议动作**: 需用户确认

---

### [API-042] [⚠️] 云端 vs 本地端数据权威源分歧

**位置**: 旧文档整体（假定 backend-truth）/ current-api.md 数据走向
**旧文档**: 设计原则为 Backend-truth，所有关键事实以后端为准
**代码实际**: 实际为混合架构：
- 词库：云端权威
- 新词学习：本地优先（SQLite 先写 → 后台同步）
- 复习(FSRS)：纯本地
- 复习分组(review_group)：云端
- 今日状态聚合：云端
- 用户设置(daily_goal)：双写（本地 SharedPreferences + 云端 API）
- FSRS 参数(desired_retention)：纯本地
**实现状态**: [已实现] -- 但与旧文档 Backend-truth 原则有偏差
**建议动作**: 需用户确认 -- Local-first 混合架构是否为有意设计决策

---

### [API-043] [⚠️] FSRS 数据无云端同步路径

**位置**: current-api.md 待确认项 T6 / 旧文档无
**旧文档**: 未提及 FSRS
**代码实际**: `review_logs` 和 `card_states`（FSRS 核心数据）目前无云端同步路径，备份 snapshot 仅含 v1 legacy 表数据
**实现状态**: [已实现] -- 但存在数据丢失风险
**建议动作**: 需用户确认 -- FSRS 数据的持久化/备份策略

---

### [API-044] [⚠️] dev-store 内存持久化问题

**位置**: current-api.md 待确认项 T7 / 旧文档无
**旧文档**: 未提及运行时存储模式
**代码实际**: 云端 dev-store 为纯内存实现，重启丢失所有数据；有可选 pg backend 但需配置 `PERSISTENCE_BACKEND` 环境变量
**实现状态**: [已实现] -- 但 production 持久化方案未确定
**建议动作**: 需用户确认 -- production 持久化迁移计划
