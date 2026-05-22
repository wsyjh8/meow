# 背单词喵喵 App DB 设计草案 v0.2.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.2.1
- **Date:** 2026-04-08
- **Status:** reconciled baseline candidate / ready for Room 1 review
- **Role card:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Purpose:** 基于当前推进层 SSOT、`v0.2.0` 代码反读稿、`v0.1.5` 候选回写稿与 `R2_v0.2.0_CodeTruth_Reconciliation_Checklist_v0.1.md`，重做一版真正可被 Room 1 判断是否 pin 的 Room 2 DB 候选基线。

---

## 0. 文档定位

本稿不是：
- `背单词喵喵app_DB设计草案_v0.2.0.md` 的原样升格版
- `背单词喵喵app_DB设计草案_v0.1.5.md` 的继续 patch 版
- Room 1 已 pin 的 active DB baseline

本稿只做一件事：

> **把当前 DB 技术事实拆成 3 层并收口成单文件候选基线：**
> 1. Runtime active reference
> 2. Code-truth implemented reality
> 3. Candidate contracts not fully implemented

### 0.1 一句话原则
> **既不否认代码现实，也不让已收口但未完全落地的契约消失。**

---

## 1. 输入依据

### 1.1 当前治理层 / 运行层依据
- `ORG_v0.3.1.md`
- `PROJECT_RULES_MASTER_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `room1_v0.2.0.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.2`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- `Main_updated_2026-04-07_v17.md`
- `STATUS_updated_2026-04-07_v16.md`

### 1.2 当前 runtime active basis（推进层已 pin）
- BR active: `BR-OPP-001_v0.1.7.md`
- DB active: `背单词喵喵app_DB设计草案_v0.1.4.md`
- API active: `背单词喵喵app_API设计草案_v0.1.3.md`

### 1.3 当前 sync / review candidate inputs
- `背单词喵喵app_DB设计草案_v0.1.5.md`
- `背单词喵喵app_API设计草案_v0.1.4.md`
- `背单词喵喵app_DB设计草案_v0.2.0.md`
- `背单词喵喵app_API设计草案_v0.2.0.md`
- `R2_v0.2.0_CodeTruth_Reconciliation_Checklist_v0.1.md`
- `BR-OPP-001_v0.2.1.md`
- `UI_SPEC_v0.2.1.md`

### 1.4 吸收原则
1. 吸收 `v0.2.0` 的 code-truth reality
2. 不把 `v0.2.0` 直接当成唯一正式基线
3. 保留 `v0.1.5` 已收口但未 fully landed 的 candidate contracts
4. No silent contract drift

---

## 2. 三层阅读方式

### Layer A — Runtime active reference
说明当前推进层已 pin 的 active DB baseline 是什么。

### Layer B — Code-truth implemented reality
说明当前代码里真实已经存在的云端 / 本地数据结构是什么。

### Layer C — Candidate contracts not fully implemented
说明 Room 1 / Room 2 / Room 3 已收口，但代码还未 fully landed 的 DB 契约是什么。

---

## 3. Room 2 总判断

### 3.1 总结论
> **v0.2.1 采用 “reconciled baseline” 路线。**

也就是：
- 保留推进层 active baseline 的引用位置
- 正式吸收 `v0.2.0` 的代码现实
- 显式保留 `v0.1.5` 中仍有价值的 candidate contracts
- 清掉 `v0.1.5` 里的旧 patch metadata 残留

### 3.2 当前最重要的 DB 架构判断
1. 系统已明确进入 dual-store：
   - 云端：PostgreSQL / DevStore
   - 本地：drift / sqflite / SharedPreferences
2. 云端继续承载：
   - 今日聚合
   - review_group
   - 奖励 / 结算 / 商店 / 装备 / 签到
3. 本地继续承载：
   - FSRS 调度
   - review logs
   - 设备侧 `daily_goal`
   - 本地缓存 / 本地学习运行态
4. P3.1 backup / restore 方向当前仍是：
   - local-first
   - manual backup / restore
   - not full sync

---

## 4. Layer A — Runtime active reference

### 4.1 当前推进层已 pin 的 active DB baseline
当前推进层 `Main / STATUS` 仍将以下文件视为 active runtime DB baseline：
- `背单词喵喵app_DB设计草案_v0.1.4.md`

### 4.2 本稿与 active baseline 的关系
> **本稿是推荐 next-step DB baseline candidate，不自动替代 active DB baseline。**

---

## 5. Layer B — Code-truth implemented reality（云端）

## 5.1 云端总体结论
当前代码现实中，云端存储层来自：
- PostgreSQL migrations
- DevStore runtime
- NestJS controllers / persistence / domain types

Room 2 正式接受以下现实：

### 5.1.1 云端已实现的主表 / 运行态实体
1. `users`
2. `word_books`
3. `words`
4. `user_book_settings`
5. `study_attempts`
6. `user_word_progress`
7. `review_groups`
8. `review_group_items`
9. `review_attempts`
10. `daily_goal_progress`
11. `session_records`
12. `check_in_records`
13. `learning_day_facts`
14. `streak_records`
15. `reward_source_events`
16. `reward_ledger`
17. `settlements`
18. `feed_events`
19. `secondary_wallets`
20. `pet_profiles`
21. `shop_catalog_items`
22. `inventory_items`
23. `equipment_slots`
24. `purchase_records`
25. `idempotency_keys`

### 5.1.2 Room 2 正式表述
- 上述 25 张云端表 / 运行态实体，是当前 code-truth implemented reality
- 它们不是“未来规划”，而是当前代码已长期存在、足以影响开发与维护判断的 DB 现实

## 5.2 当前云端实现中的重要现实差异

### 5.2.1 `user_book_settings.daily_new_target`
当前云端设置表中，`daily_new_target` 已作为云端字段存在，并被 `PUT /me/settings/daily-goal` 使用。

Room 2 对此的正式表述是：
- 这是当前云端 implemented reality
- 但它不自动推翻 P3.1 delta 已收口的 `daily_goal local-first` 方向
- 因此它在本稿中被视为：
  - 云端已实现 reality
  - 与本地 local-first 方向存在暂时分歧的 reconciled item

### 5.2.2 `daily_goal` 范围差异
当前代码现实中：
- 云端 `daily_goal` 更新范围偏向 `1–100`
- Room 2 在 P3.1 delta 中推荐范围是 `1–500`

本稿中的处理：
- `1–100` = current implemented reality
- `1–500` = candidate / recommended validation range
- 当前不得把任一方偷写成长期 frozen business rule

## 5.3 当前云端未 fully landed 的候选项
以下内容当前仍不应写成“已 fully implemented truth”：
1. `review_queue`
2. `learning_stat_daily`
3. `user_backup_snapshots`
4. `backup_restore_operations`

这些对象当前应被归类为：
- 已存在设计 / 已收口候选契约
- 但 not fully landed in code / migration

---

## 6. Layer B — Code-truth implemented reality（本地）

## 6.1 本地总体结论
当前代码现实中，本地端不再只是“纯前端页面层”，而是已经包含独立数据层与服务层：

### 6.1.1 本地主要存储形态
1. drift / SQLite
2. legacy sqflite tables
3. SharedPreferences / 本地 settings / 本地 progress repo

### 6.1.2 本地主要服务现实
1. `FsrsService`
2. `SessionBuilder`
3. `WordCacheService`
4. `LocalSettingsService`
5. `LocalProgressRepository`

## 6.2 本地权威源划分（Room 2 v0.2.1 正式口径）

| 数据域 | 当前权威源 | 说明 |
|---|---|---|
| FSRS 调度 | 本地 drift / SQLite | 设备侧 runtime truth |
| review logs | 本地 drift / SQLite | INSERT-only local reality |
| `daily_goal` 当前生效值 | 本地 settings | 设备侧 local-first reality |
| 词书缓存 | 本地缓存 + 云端下载 | 云端是上游，设备侧为运行缓存 |
| today 聚合 | 云端 | 不是本地 truth |
| review_group | 云端 | 不是本地生成 |
| 奖励 / 商店 / 装备 | 云端 | 不是本地 truth |
| backup / restore | 混合 | 本地导出 + 云端容器 + 本地 apply |

---

## 7. Layer C — Candidate contracts not fully implemented

## 7.1 P3.1 backup / restore 候选契约
以下内容在 `v0.1.5` 中已经被 Room 2 写回，当前必须继续保留为 candidate contracts：
1. `user_backup_snapshots`
2. `backup_restore_operations`
3. latest backup metadata contract
4. restore-precheck contract
5. download success vs restore success 语义分层
6. overwrite safety
7. checksum / schema version / payload validity gating

### 7.1.1 当前状态
这些内容当前属于：
- approved candidate contracts
- 但不是 current implemented full reality
- 在 Room 1 未 pin / 代码未 fully landed 前，不能写成 active truth

## 7.2 `daily_goal` 的 local-first 候选契约
Room 2 继续保留以下收口：
1. `daily_goal` 改动本地即时生效
2. 新值只影响当前生效后的今日 / 后续目标
3. 不回溯重算历史日
4. 进入 backup snapshot 的是 `settings.daily_goal`
5. restore apply 可能覆盖最小设置层（包括 `daily_goal`）

### 7.2.1 当前状态
- 代码 reality：云端也存在 `PUT /me/settings/daily-goal`
- Room 2 候选契约：仍优先 local-first

### 7.2.2 Room 2 处理方式
本稿不强行裁定二者谁胜出，而是显式写为：
- implemented divergence
- pending reconciliation item

## 7.3 仍未冻结的核心 Pending
以下内容继续保留为 Pending：
1. 完整 SRS
2. 完整 review priority
3. `review_group` 分组算法细节
4. CTA winner 完整算法
5. `latest-only restore` 是否长期 frozen
6. `daily_goal` 最终长期上下限
7. auth 最终方案
8. response envelope 是否未来恢复统一信封

---

## 8. Room 2 推荐的 reconciled DB 口径

## 8.1 对云端表的正式分类
### A. Active runtime-backed + implemented
- `users`
- `word_books`
- `words`
- `study_attempts`
- `review_groups`
- `review_group_items`
- `review_attempts`
- `daily_goal_progress`
- `session_records`
- `check_in_records`
- `learning_day_facts`
- `streak_records`
- `reward_source_events`
- `reward_ledger`
- `settlements`
- P2 secondary truth layer

### B. Implemented reality but needs reconciliation wording
- `user_book_settings.daily_new_target`
- `user_word_progress`
- `idempotency_keys`

### C. Candidate contract / not fully landed
- `review_queue`
- `learning_stat_daily`
- `user_backup_snapshots`
- `backup_restore_operations`

## 8.2 对本地存储的正式分类
### A. Implemented local runtime truth
- FSRS tables
- review logs
- local settings
- local progress repository

### B. Implemented local cache / support store
- word cache
- local database legacy tables

### C. Pending / future reconciliation
- backup restore apply 后与云端口径的最终一致性策略
- 多端 conflict / merge

---

## 9. 当前必须修正的旧稿残留（已在 v0.2.1 处理）

本稿相对于 `v0.1.5` 已正式处理：
1. 删除旧的 P2 / `v0.1.3` metadata 残留
2. 不再把 P3.1 候选基线写成“继续对 v0.1.3 做 P2 write-back”
3. 把 `user_backup_snapshots` / `backup_restore_operations` 显式降级为：
   - candidate contract
   - not fully landed
4. 把 current implemented reality 与 candidate contract 分层，不再混成一层

---

## 10. Room 1 吸收建议（Main / Status）

若 Room 1 接受本稿，建议吸收为：

1. **Evidence**
   - Room 2 已交付 `DB v0.2.1`，完成了 DB 代码现实与候选契约的三层整合。

2. **Decision（建议待审）**
   - `DB v0.2.1` 作为 next-step Room 2 DB baseline candidate。
   - 在 Room 1 未进一步 pin 前，runtime active 仍保持 `DB v0.1.4`。
   - 后续若要 pin 新 active DB baseline，优先 pin `v0.2.1`，而不是直接 pin `v0.2.0`。

3. **Status**
   - Room 2 已完成 DB code-truth reconciliation。
   - 下一步若继续推进，应由 Room 1 判断是否采用 `v0.2.1` 作为新 active / review basis。

---

## 11. Room 2 最终一句话

> **`DB v0.2.1` 不是“继续 patch 旧稿”，也不是“直接宣布代码即唯一真相”；它是当前项目最适合被 Room 1 审核与 pin 的 Room 2 整合候选基线。**
