# BR-USER-001 v0.1.0 -- 用户身份与数据隔离业务规则

**Project:** 背单词喵喵 App
**Version:** v0.1.0
**Date:** 2026-05-11
**Status:** complete (v0.1.0 — 首次发布，落地 plan-023-v2 §10 D14 决策)
**Base commits:** `5547a85` (auth foundation) → `34a67df` (β.5b/5c 收尾)
**关联:**
- 顶层 plan: [`./plan-023-用户系统与用户数据隔离-v2.md`](./plan-023-用户系统与用户数据隔离-v2.md)
- PRD: [`./prd-023-用户系统与用户数据隔离-v1.md`](./prd-023-用户系统与用户数据隔离-v1.md) §5 / §6 / §9
- §9 验收对照: [`./audits/prd-§9-acceptance-coverage.md`](./audits/prd-§9-acceptance-coverage.md)
- BR 命名约定: plan v2 §10 D14（`BR-USER-NNN_v0.x.0_full.md` 形式，目录 `docs/design/`）
- 文档结构参考: [`./BR-OPP-001_v0.2.0_full.md`](./BR-OPP-001_v0.2.0_full.md)

---

## 1. 适用范围

本文规定**用户系统**（user identity + auth flow）与**用户数据隔离**（per-user partition）四类业务规则的硬纪律。所有 contributor 在动以下任一区域代码前必须先读本文：

- 后端 `/auth/*` 接口、AuthGuard、dev-store/repositories
- 后端 PG 迁移 008 / 009 / 010 及任何添加 `user_id` 列的后续 migration
- 移动端 `apps/mobile/lib/core/auth/` 全部、`core/storage/` 的 user-scoped 表 + SP key
- 任何涉及「登录 / 退出 / 绑定 / 切换账号」交互的 UI 改动

每条 BR 由「规则正文 / 实现 / 验证测试」三段组成；引用真实 commit hash（feature/user-auth 分支）+ 文件:行。

---

## 2. 总体边界（共享前提）

| 项 | 决策 |
|----|------|
| 用户上下文唯一 | App 任意时刻只有一个 active user context（PRD §6 Rule 1）。**不允许「页面 A 用 user X，页面 B 用 user Y，提交接口用 user Z」**。|
| 写操作必须绑定当前用户 | 所有用户数据写入路径必须 sink 当前 `user_id`，不允许全局态、不允许默认 fallback 覆盖 token 解析的真用户 id（PRD §6 Rule 2）。|
| 静态内容层不按用户复制 | `words` / `examples` / `audio_assets` 等公共内容跨用户共享；只有「用户对内容产生的行为和进度」才按 `user_id` 隔离（PRD §6 Rule 4 / §5.2）。|
| 登录 ≠ 同步完成 | 登录成功只代表 user_id 已切换；本地数据是否反映新用户由后续 `/me/*` 拉取 + 本地 partition 共同决定（PRD §6 Rule 3）。|

---

## 3. BR-USER-001-A: 用户身份规则

### 3.1 规则

| # | 规则 | 说明 |
|---|------|------|
| A-01 | 用户状态枚举：`guest` / `registered`，无第三状态 | 由 `users.account_type` 列承载，CHECK 约束限定。|
| A-02 | `users.id` 在用户**整个生命周期**不变 | 包含 guest → registered 升级；id 改变即视为新用户。|
| A-03 | `guest` 用户由 `device_id` 索引；同 device_id 重发 `/auth/guest` 是幂等的 | 不创建新行；返回既有 guest 用户 + 新签发的 token。|
| A-04 | `registered` 用户由 `email` 唯一索引（LOWER）；同 email 重复 register → 409 EMAIL_TAKEN | 区分大小写已规一化。|
| A-05 | JWT TTL = 30 天（D3 决策） | 过期不刷新；过期后客户端走 `tokenExpired` 状态，提示重登（D11）。|
| A-06 | JWT secret 必须 ≥ 16 字符 | `auth.service.ts:43` `getJwtSecret` 启动时校验，缺则启动失败。|

### 3.2 实现

| 元素 | 位置 |
|------|------|
| `users` 表结构 | `apps/api/src/infrastructure/postgres/migrations/008_user_auth.sql` （commit `5547a85`）|
| 状态枚举 + CHECK | `users.account_type IN ('guest','registered')` |
| guest 创建（按 device_id 幂等） | `apps/api/src/auth/auth.service.ts:199` `startGuest()` —— `findGuestByDevice` 命中即返回既有用户，否则 `INSERT INTO users (id, ..., account_type='guest', device_id)` |
| register | `auth.service.ts:139` `register()` — 同 email 抛 ConflictException(EMAIL_TAKEN) |
| login | `auth.service.ts:171` `login()` — bcrypt verify + touch last_login_at |
| JWT 签发 / 校验 | `auth.service.ts:52-78` `signToken` / `verifyToken`；TTL `TOKEN_TTL_SECONDS = 30 * 24 * 60 * 60` (`:35`) |
| Token 解析 → req.user | `apps/api/src/auth/auth.guard.ts:44` `AuthGuard.canActivate` |

### 3.3 验证测试

| 测试 | 位置 |
|------|------|
| guest 幂等 | `apps/api/test/auth.e2e-spec.ts:79` "POST /auth/guest creates a guest and is idempotent by device_id" |
| register → login round-trip | `auth.e2e-spec.ts:96` |
| duplicate email 409 | `auth.e2e-spec.ts:124` |
| /auth/me 拉当前用户 | `auth.e2e-spec.ts:140` |
| invalid token → 401 (enforce 模式) | `auth.e2e-spec.ts` AUTH_ENFORCE=true 用例 + `auth-isolation.e2e-spec.ts:137` |

**引用 commits：** `5547a85`（核心实现 + 测试）；JWT secret guard 等同 commit。

---

## 4. BR-USER-001-B: 游客绑定规则

### 4.1 规则

| # | 规则 | 说明 |
|---|------|------|
| B-01 | 绑定 = `users` 表**same-row UPDATE**，不新建行 | `auth_type='guest'` → `'registered'`，set `email/password_hash`；id 保留。|
| B-02 | 已 registered 用户调用 `/auth/bind` → 400 NOT_GUEST | 不允许重复绑定 / 不允许 registered 转回 guest。|
| B-03 | 绑定 email 在事务内做唯一性 `FOR UPDATE` | 防并发 register + bind 撞 email。|
| B-04 | 绑定失败必须服务端事务回滚 + 不损坏本地数据 | 客户端 fallback：保留本地 `pending-local-guest` 占位 + 重试 flags。|
| B-05 | 客户端 retry 通过 SharedPreferences flags 实现 | `auth_pending_sp_migration` / `auth_pending_local_drift_migration` / `auth_pending_local_sqflite_migration` 三个 flag 记录哪些 migration 还没完成；下一次 cold start 由 AuthBootstrap 续跑（PendingGuestMigrator）。|
| B-06 | 同行场景下（from == to）pending-guest migration 是 no-op | 防止把数据自己迁移给自己导致主键冲突或行计数翻倍。|

### 4.2 实现

| 元素 | 位置 |
|------|------|
| `bindGuest` 事务（same-row UPDATE） | `apps/api/src/auth/auth.service.ts:229-297` — `BEGIN`→`SELECT ... FOR UPDATE`→`UPDATE users ... WHERE id=$1 AND account_type='guest'`→`COMMIT`/`ROLLBACK` |
| `bindGuest` 拒绝 non-guest | `auth.service.ts:235-240` 抛 `BadRequestException(NOT_GUEST)` |
| Email 冲突 in-txn 检测 | `auth.service.ts:248-258` |
| 客户端绑定流程 | `apps/mobile/lib/core/auth/auth_controller.dart` `bindGuest` 接 server response，触发 `_finalizeBindIfNeeded` |
| 客户端 retry flags | `apps/mobile/lib/core/auth/auth_storage.dart:28-31` `_spPendingSpMigration` / `_spPendingDriftMigration` / `_spPendingLocalSqfliteMigration` |
| Pending migration 续跑器 | `apps/mobile/lib/core/auth/pending_guest_migrator.dart:33` `PendingGuestMigrator` — 同行场景 (`from == to`) 直接 return（`:70` `'refusing: empty id'` + 同行 no-op 早出） |
| AuthBootstrap 续跑入口 | `apps/mobile/lib/core/auth/auth_bootstrap.dart` 启动期检查 flags + 触发 migrator |

### 4.3 验证测试

| 测试 | 位置 |
|------|------|
| Bind upgrades guest → registered，**preserves users.id** | `apps/api/test/auth.e2e-spec.ts:154` "POST /auth/bind upgrades guest → registered, preserves users.id" |
| Bind 二次调用（已 registered）→ 400 | `auth.e2e-spec.ts:184-189` |
| 同行场景 migrate(X→X) no-op | `apps/mobile/test/phase_c_e2e_test.dart:425` "T8 — same-row bind: pending-local-guest migration must skip — migrate(from: X, to: X) is a no-op" |
| 绑定后 backup 仍可读 | `apps/api/test/backup-persistence.e2e-spec.ts:369` D-T13 "guest uploads backup → bind to registered → backup still readable" |
| 邦定后业务数据延续（PRD §9.5 整段） | `audits/prd-§9-acceptance-coverage.md` §6 表格全 ✅ |

**引用 commits：** Backend `5547a85`（bindGuest 事务）；Mobile `1584440`（C-γ pending-local-guest migrator + 同行 no-op）；E2E `4d3cb3a`（C-δ T8）+ `4c679a9`（D-δ D-T13）。

---

## 5. BR-USER-001-C: 退出 / 切换账号规则

### 5.1 规则

| # | 规则 | 说明 |
|---|------|------|
| C-01 | 退出 = **清 token + 清 user_id 引用 + 切到 guest 上下文**，**不删本地数据** | plan v2 §6.5 / D7：本地数据保留供下次同 user 登录还原。|
| C-02 | 切换账号 = epoch 自增 + 取消 in-flight + per-page state reset | epoch 是 `auth_http_client` 用来识别「响应对应的请求来自哪一代 user」的单调递增整数。|
| C-03 | 401 → `tokenExpired` 状态；**绝不自动切游客**（plan v2 D11 红线） | 网络错误 / 5xx 不应误判为 tokenExpired（Phase B 评审采纳）。|
| C-04 | 退出后再次启动 App，若没有 token，回到 guest 上下文（不要求显式登录） | guest 自带 device_id；可继续学习；本地数据仍按 currentUserId 路由（pending-local-guest 占位）。|
| C-05 | logout 服务端调用是 best-effort | `auth_controller.dart:264` 注释明示「server logout is best-effort; storage clear is authoritative」。|

### 5.2 实现

| 元素 | 位置 |
|------|------|
| Backend logout endpoint | `apps/api/src/auth/auth.controller.ts:84-88` `@Post('logout')` — stateless（无 token blacklist），返 `{status:'ok'}` |
| Mobile logout 主流程 | `apps/mobile/lib/core/auth/auth_controller.dart:256` `logout()` — 调 `api.logout(token)`（catch swallowed）→ 清 SP / secure storage → 切回 guest 上下文（重新调 `/auth/guest` with stored device_id） |
| Epoch 机制 | `apps/mobile/lib/core/auth/auth_http_client.dart` 在 send 前 capture `currentEpoch`；response 回来时若 epoch 不匹配 → drop 响应（防止 user A 的响应写到 user B 的状态） |
| `tokenExpired` 状态 | `auth_controller.dart:91` `isTokenExpired` getter；`:284-290` `markTokenExpired()`；`auth_http_client.dart` 401 拦截后调用 |
| 网络 ≠ tokenExpired 区分 | `auth_controller.dart:154` 注释 "Phase B fix-4 (评审采纳): network/5xx is NOT tokenExpired"；只有明确 401 才转 tokenExpired |
| Logout 不删本地数据 | `auth_controller.dart:256-275` 只清 auth-related storage，**不动 drift / SP business keys** |

### 5.3 验证测试

| 测试 | 位置 |
|------|------|
| logout retains drift data | `apps/mobile/test/phase_c_e2e_test.dart:373-380` "T7 — logout clears token/userId/accountType in SP+secure storage but retains drift data (plan §6.5 / D7)" |
| Epoch 递增 + 切换无串数据 | `apps/mobile/test/auth_test.dart:388` "epoch increments on session commit and logout" |
| Epoch race guard：旧响应被 drop | `apps/mobile/test/auth_http_client_epoch_test.dart:160` "send returns normally when epoch is unchanged" + 配套 mismatch 用例 |
| 多用户切换不串状态（DAO / Service 层）| `phase_c_e2e_test.dart:285` "T6 — service A/B isolation"（5 个 sub-test）+ `:205` "T5 DAO isolation" |
| 401 不切游客（Phase B hot-fix）| Mobile auth tests + hot-fix commit `5d83936` 描述明示 |

**引用 commits：** Mobile `9d992c8`（Phase B 原始 logout / epoch）+ `5d83936`（Phase B hot-fix 评审：401 → tokenExpired，不切游客）+ `1584440`（Phase C-γ epoch race guard 在 in-flight 上的硬化）+ `4d3cb3a`（C-δ T6/T7 e2e）。

---

## 6. BR-USER-001-D: 数据归属规则

### 6.1 规则

| # | 规则 | 说明 |
|---|------|------|
| D-01 | PRD §5.1 列出的字段**必须** `user_id` per-row partition | 后端 PG 表、移动端 drift / SP key，三层都要 |
| D-02 | PRD §5.2 列出的字段**不能**加 `user_id` | 静态内容层跨用户共享 |
| D-03 | 用户对内容产生的行为 / 进度仍要 per-user | 即使 word 是公共的，「user X 是否学过 word Y」「user X 的笔记」「user X 的 FSRS state」必须 per-user |
| D-04 | 后端 dev-store 内部 `Map<userId, ...>` partition；不允许全局单值 | A4-β.3 落地的 23 个 *ByUser maps；β.5c 再补 ownedItems/equipped/wallet 等最后 4 个 |
| D-05 | PG 持久化必须 per-row `user_id` + UNIQUE/PK 必须含 `user_id` | migration 009 已修两处 critical gap（详见 db-uniqueness-audit.md） |
| D-06 | 跨用户读 / 写未授权 entity → 返 NotFoundException(404)（不返 403） | 防 entity-id 枚举攻击（controller-auth-audit.md §6） |
| D-07 | 备份恢复 (`/me/backup/*`) 必须 per-user 且 last-write-wins | 单插槽 keyed by user_id，`backup_snapshots.user_id` PRIMARY KEY |
| D-08 | Restore 必须**无条件覆盖** snapshot 内的 user_id 为当前 token user | 防御 polluted snapshot（D-γ）；同时客户端 + 服务端双校验 |

### 6.2 必须 per-user 的字段清单（援引 PRD §5.1）

**后端 PG 表（22 张，已全部 user-scoped）：**
- 用户设置：`user_book_settings`、`pet_profiles`
- 学习行为：`study_attempts`、`review_attempts`、`review_groups`、`review_group_items`（via review_groups.user_id）、`session_records`、`task_attempts`、`fishing_attempts`、`daily_fishing_tasks`
- 日历事实：`check_in_records`、`learning_day_facts`、`streak_records`、`daily_goal_progress`
- 奖励：`reward_source_events`、`reward_ledger`、`settlements`、`secondary_wallets`
- 副机制：`feed_events`、`inventory_items`、`equipment_slots`、`purchase_records`、`lottery_boxes`
- 其他：`idempotency_keys`、`backup_snapshots`

**移动端 drift v13（9 张 user-scoped 表 + UNIQUE 复合 key）：**
- `card_states` UNIQUE(user_id, word_id)
- `review_logs`
- `wordbook_progress` UNIQUE(user_id, book_id)
- `daily_checkins` UNIQUE(user_id, date)
- `word_records` UNIQUE(user_id, word_id, study_type)
- 其余 4 张：`session_records` / `session_words` / `task_attempts` / `room_canvas_state` 等（详见 sp-keys-audit.md §4.1-4.2）

**移动端 SharedPreferences keys（前缀 `u_${userId}_`）：**
- `settings_daily_goal` / `settings_sound_enabled` / `settings_theme` / `settings_notification_time` / `settings_desired_retention` / `settings_active_wordbook` / `settings_manifest_sync_enabled`（详见 `LocalSettingsService.migratableKeySuffixes`）

### 6.3 必须**不** per-user 的字段清单（援引 PRD §5.2）

- 词内容：`words`、`word_entries`、`example_sentences`、`audio_assets`、`word_forms`、`word_relations`、`word_phrases`、`morpheme_entries`、`word_morpheme_matches`
- 词书结构：`wordbooks`、`word_book_assignments`
- 公共配置：`lottery_drops_config`、`content_manifest`、`content_release`

### 6.4 实现

| 元素 | 位置 |
|------|------|
| Migration 008 — users 表 + auth 字段 | `apps/api/src/infrastructure/postgres/migrations/008_user_auth.sql` (`5547a85`) |
| Migration 009 — UNIQUE 补 user_id（reward_source_events / idempotency_keys 两处 critical gap） | `migrations/009_user_scoped_uniqueness.sql` (`5547a85`)；详见 `audits/db-uniqueness-audit.md` §2 |
| Migration 010 — backup_snapshots 表 | `migrations/010_backup_snapshots.sql`（Phase D-β `aaefffc`） |
| Backend dev-store 23 个 *ByUser maps | `apps/api/src/domain/dev-store.ts:184-206` (A4-β.3 `3833c25`) |
| Backend dev-store 最后 4 个 *ByUser (ownedItems/equipped/wallet) | `dev-store.ts:200-203`；β.5c snapshot 扩字段 (`persistence.ts:103-125`)；pg-persistence saveAsync 走 `walletForUser`/`ownedForUser`/`outfitForUser`/`roomForUser`（`pg-persistence.ts:413-470`）— β.5c `34a67df` |
| ensureUserLoaded lazy-load | `dev-store.ts:469` `ensureUserLoaded` + `loadingByUser` dedup；AuthGuard 在 `canActivate` 末尾 await（`auth.guard.ts:78`）— β.5b `34a67df` |
| Audit §6 owner-check：cross-user 写 → 404 | dev-store 内部 `assertInventoryItemNotCrossUser` (`dev-store.ts:582`) + `assertSessionIdNotCrossUser` (`:602`)；createOrGetSourceEvent / submitStudyAttempt / submitReviewAttempt 同模式（A4-β.9 `a4b1627`）；equipItem / unequipItem / submitLocalReviewBatch 同模式（β.5c `34a67df`） |
| Mobile drift v13 schema | `apps/mobile/lib/core/storage/drift/tables/fsrs_tables.dart`、`legacy_tables.dart`、`session_tables.dart`、`enrichment_tables.dart`（C-α `6d33cbe`），`schemaVersion => 13` (`app_database.dart:119`) |
| Mobile DAO user-scoped | `apps/mobile/lib/core/storage/local_database.dart` 所有 user 行为查询带 `userId`；repos `card_state_repository.dart` 等（C-β `d93279d`） |
| Mobile SP key 命名空间 | `apps/mobile/lib/core/storage/local_settings_service.dart:22` `_k(suffix) => 'u_${_userId}_$suffix'` (C-β `d93279d`) |
| SP migrator（pre-C → per-user） | `apps/mobile/lib/core/auth/sp_migrator.dart` + `auth_pending_sp_migration` flag（C-β `d93279d`） |
| Backup `backup_snapshots.user_id` PRIMARY KEY | `migrations/010_backup_snapshots.sql`；`PgDevStorePersistence.saveBackupForUser` / `loadBackupFullForUser` (`pg-persistence.ts:518-617`) — D-β `aaefffc` |
| Restore 无条件覆盖 user_id | `backup_restore_service.dart` (mobile) + `BackupController._validateSnapshotUserIds` (backend) — D-γ `2f32510` |

### 6.5 验证测试

| 测试 | 位置 |
|------|------|
| §6 owner-check 矩阵 14 + 4 e2e | `apps/api/test/auth-isolation.e2e-spec.ts:128-959` — sessions / settlements / source_ref_id / session_id / lottery / fishing / equip / unequip / local-batch / backup cross-user → 404 |
| dev-store per-user partition：A 不影响 B | `auth-isolation.e2e-spec.ts:349/380/485/635` 等（study / balance / inventory / daily_goal） |
| β.5c PG inventory / equipment / wallet per-user persist | `auth-isolation.e2e-spec.ts:763/806/825` （β.5c three tests） |
| β.5b lazy-load 从 PG warm 新用户 | `auth-isolation.e2e-spec.ts:704` + `:741` (β.5b 两个用例) |
| Mobile drift v13 schema 强制 NOT NULL user_id | `phase_c_e2e_test.dart:461` T14（两个 sub-test） |
| Mobile DAO isolation | `phase_c_e2e_test.dart:205` T5（5 个 sub-test） |
| Mobile SP key partition | `phase_c_e2e_test.dart:81` T3 + `:351` clearAll 不串 |
| Backup cross-user → no_backup_yet | `auth-isolation.e2e-spec.ts:243` "User B does NOT see User A's backup snapshot" + `:286` LWW per-user |
| D-T11 多账号本地共存 restore 不污染 | `phase_d_e2e_test.dart:193` "user C restore does not touch user A's drift rows" |

**引用 commits：** `5547a85`（migration 008/009 + dev-store 接 userId）+ `1991be7`（A4-α plumbing）+ `3833c25`（A4-β.3 dev-store partition）+ `78eec7c`（β.7 e2e）+ `a4b1627`（β.9 partition 补漏 + owner-check 硬化）+ `34a67df`（β.5b/c + 4 audit §6 e2e）+ `6d33cbe`+`d93279d`（Phase C 移动端 partition）+ `aaefffc`+`2f32510`+`4c679a9`（Phase D backup per-user）。

---

## 7. 跨 BR 联动备忘

四条 BR 互相依赖，按时间顺序的因果链如下：

```
A-02 users.id 生命周期不变
  ↓
B-01 绑定是 same-row UPDATE（不改 id）
  ↓
B-06 同行场景下 pending-guest migration 是 no-op
  ↓
C-01 退出不删本地数据（再次以同 id 登录可还原）
  ↓
D-04 / D-05 所有持久化都以 user_id 为唯一 partition key
```

破坏任一一条都会导致 PRD §9.5 「绑定不丢数据」/ §9.6 「切换不串数据」连锁失效。Phase A 评审 1+2 / Phase D 评审 1+2 中所有 P0/P1 评审项都映射到这条因果链上的某一节。

---

## 8. 修订记录

| 版本 | 日期 | 修订点 |
|------|------|--------|
| v0.1.0 | 2026-05-11 | 首次发布；落地 plan-023-v2 §10 D14 决策（BR 命名约定 + 内容范围）。四条 BR 实现路径全部 grep 实测，commit 链 `5547a85` → `34a67df` |
