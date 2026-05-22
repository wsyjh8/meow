# 背单词喵喵 App DB 设计草案 v0.2.2

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.2.2
- **Date:** 2026-04-12
- **Status:** incremental merged full baseline candidate / ready for Room 1 review
- **Role card:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.2`
- **Purpose:** 以 `背单词喵喵app_DB设计草案_v0.2.1.md` 为 full baseline，增量吸收 `DB_P3.2_BackupRestore_v0.1.md` 与 `P3.3.16` 已落地代码事实，形成新的单文件 full merged baseline candidate。

---

## 0. 文档定位

本稿不是：
- 对 `背单词喵喵app_DB设计草案_v0.2.1.md` 的整份重写
- 把所有 future candidate 一次性升格为 active runtime truth
- 把 P3.3.16 的 fuller cutover / `review_group` true exit / active DB baseline uplift 各类 pending judgment 写成已生效事实

本稿只做一件事：

> **在保留 `v0.2.1` full baseline 主结构的前提下，把已经影响开发、维护、联调、测试与后续文档引用的 DB 代码事实，吸收到新的 full merged baseline candidate。**

### 0.1 本轮吸收范围
本轮只吸收以下两类已经落地、且需要进入 full DB 文档的代码事实：

1. **P3.2 — Backup / Restore 增量**
   - 云端 DevStore 中 `latestBackup` / `backupSnapshot` 持久化
   - snapshot schema 升级到 `p3_2_snapshot_v1`
   - 本地 SQLite `card_states` 纳入 backup / restore 范围
   - backup 元数据中的 `device_id` / `device_model`

2. **P3.3.16 — Local Review Batch 增量**
   - `review_attempts` 接受 `local_batch_*` 前缀记录
   - 本地 FSRS 非续习批量提交接入后端结算链
   - `daily_goal_progress` / `learning_day_facts` / `reward_source_events` / `reward_ledger` / `settlements` / `idempotency_keys` 的代码现实更新

### 0.2 一句话原则
> **既不否认 `v0.2.1` 已收口的 dual-store 基线，也不让 P3.2 / P3.3.16 已落地的 DB 现实继续停留在 patch 附件里。**

---

## 1. 输入依据

### 1.1 当前治理层 / 运行层依据
- `ORG_v0.5.0.md`
- `PROJECT_RULES_MASTER_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.2`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.3.0.md`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- `Main_updated_2026-04-10_v34.md`
- `STATUS_updated_2026-04-10_v32.md`

### 1.2 当前 runtime active basis（推进层已 pin）
- BR active: `BR-OPP-001_v0.2.15.md`
- DB active: `背单词喵喵app_DB设计草案_v0.2.1.md`
- API active: `背单词喵喵app_API设计草案_v0.2.1.md`
- UI active: `UI_SPEC_v0.3.5.md`

### 1.3 本轮 sync / review candidate inputs
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `DB_P3.2_BackupRestore_v0.1.md`
- `API_P3.2_BackupRestore_v0.1.md`
- `P3.3.16_Claude_res.md`
- `BR-OPP-001_v0.2.15.md`
- `UI_SPEC_v0.3.6.md`

### 1.4 吸收原则
1. 保留 `v0.2.1` 的 full baseline 主结构与三层阅读方式
2. 正式吸收 P3.2 backup / restore 的 code-truth implemented reality
3. 正式吸收 P3.3.16 local review batch 的 code-truth implemented reality
4. 不把 pending 的 owner shift / true exit / baseline uplift judgment 静默写成当前事实
5. **No silent contract drift**

---

## 2. 三层阅读方式

### Layer A — Runtime active reference
说明当前推进层已 pin 的 active DB baseline 是什么。

### Layer B — Code-truth implemented reality
说明当前代码里真实已经存在、会影响实现与联调判断的云端 / 本地 / snapshot 数据结构是什么。

### Layer C — Candidate contracts not fully implemented
说明当前仍在 pending、不得被误写成 runtime truth 的 DB 契约或下一层演进方向是什么。

---

## 3. Room 2 总判断

### 3.1 总结论
> **v0.2.2 继续采用 “incremental merged baseline” 路线。**

也就是：
- 保留推进层 active DB baseline 的引用位置
- 沿用 `v0.2.1` 的 dual-store 主骨架
- 把 P3.2 / P3.3.16 已落地代码事实吸收进 full 文档
- 显式保留尚未 fully landed 的 candidate contracts / cutover judgment
- 清掉“这些变化只存在于 patch 文档”的状态

### 3.2 当前最重要的 DB 架构判断
1. 系统仍是 **dual-store**
   - 云端：PostgreSQL / DevStore
   - 本地：drift / sqflite / SharedPreferences / DataStore 等设备侧持久层

2. P3.2 没有把系统改成 full sync / auto merge 平台  
   它只把：
   - 本地 snapshot
   - 云端 backup 容器
   - 手动 restore apply 边界  
   收得更硬。

3. P3.3.16 没有把所有 review runtime truth 切成 local-only  
   它只把：
   - 非续习 ReviewPage 的本地 FSRS 队列结果
   - 通过 local batch 方式提交到后端结算链  
   推进到已实现现实。

4. `review_group` 没有因本轮直接退场  
   active continuation 与 cloud anchor posture 仍需按更高层规则 / UI / API / runtime judgment 继续处理。

---

## 4. Layer A — Runtime active reference

### 4.1 当前推进层已 pin 的 active DB baseline
当前推进层 `Main / STATUS` 仍将以下文件视为 active runtime DB baseline：
- `背单词喵喵app_DB设计草案_v0.2.1.md`

### 4.2 本稿与 active baseline 的关系
> **本稿是推荐 next-step DB full baseline candidate，不自动替代 active DB baseline。**

---

## 5. Layer B — Code-truth implemented reality（云端）

## 5.1 云端总体结论
当前代码现实中，云端存储层来自：
- PostgreSQL migrations / runtime tables
- DevStore persistence snapshot
- NestJS controllers / domain repository / persistence adaptation

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

### 5.1.2 DevStore / persistence snapshot 新增持久化对象（P3.2）
除上述运行态实体外，当前代码现实还包括以下 **DevStore 持久化对象**：
1. `latestBackup`
2. `backupSnapshot`

Room 2 正式表述：
- 它们不是业务表，但已成为当前 cloud backup / restore 路径上的 **真实持久化对象**
- 它们会直接影响 `POST /me/backup`、`GET /me/backup/latest`、`GET /me/backup/latest/snapshot` 的可用性与恢复行为
- 因此不允许继续只停留在 patch 文档或代码里

## 5.2 当前云端实现中的重要现实差异

### 5.2.1 `latestBackup`
当前 `latestBackup` 持久化对象最小承载以下字段：
- `backup_id`
- `schema_version`
- `uploaded_at`
- `snapshot_size`
- `status`
- `device_id`
- `device_model`

其语义是：
- 当前最新一次成功上传的备份元数据
- last-write-wins
- 用于 latest backup metadata 查询
- **它不是 full sync 状态，也不是 cross-device consistency 证明**

### 5.2.2 `backupSnapshot`
当前 `backupSnapshot` 持久化对象承载：
- 最新一次成功上传的完整 snapshot JSON

其语义是：
- 供 `GET /me/backup/latest/snapshot` 读取
- 服务重启后仍可恢复
- 仅作为 manual restore 的 recovery artifact
- **它不是 runtime truth mirror，也不是自动合并中间层**

### 5.2.3 `review_attempts.review_group_id` 现实扩张（P3.3.16）
当前 `review_attempts` 中，`review_group_id` 除原有 `group-*` 形态外，还正式接受：

- `local_batch_{timestamp}_{random6}`

这表示：
- 当前代码现实已经存在 **不对应云端 `review_groups` 行** 的 review batch 记录
- 该前缀标识本次记录来自本地 FSRS 队列的批量提交
- 该 ID 当前主要用于：
  - 幂等判断
  - 结算关联
  - 奖励 source reference 关联

### 5.2.4 `local_batch_*` 与 `review_groups` 的关系
当前代码现实明确为：
- `local_batch_*` 不会在 `review_groups` 表中有对应行
- 它不是对 `review_groups` 表的补写镜像
- 它是本地规划队列提交到后端结算链时使用的 **临时 / 内部 batch reference**

Room 2 正式处理：
- 接受其为 implemented reality
- 但不自动把它升格为长期 frozen review serving model
- 更不把它写成 `review_group` 已退出运行态

### 5.2.5 P3.3.16 对结算链相关表的现实影响
本轮代码现实中，本地非续习 review batch 一旦成功提交，会推动以下云端事实更新：

1. `daily_goal_progress`
   - `today_review_completed` 增加
   - `daily_goal_status` 重算

2. `learning_day_facts`
   - 当前批次存在 `correct` 时可更新 learning-day 相关事实

3. `reward_source_events`
4. `reward_ledger`
5. `settlements`
6. `idempotency_keys`

Room 2 正式表述：
- 当前 P3.3.16 已把本地 batch 提交接到 **后端 final fact / settlement 链**
- 这不是 UI hint，也不是 shadow evidence
- 但这也不等于 final fact owner 已从 backend 转移走；**最终事实仍以后端写入结果为准**

---

## 6. Layer B — Code-truth implemented reality（本地 SQLite / 设备侧）

## 6.1 本地总体结论
当前本地数据现实继续包括：
- drift / sqflite 的 SQLite 持久层
- SharedPreferences / DataStore 一类轻设置层
- FSRS card state / review logs / 本地运行态缓存

### 6.1.1 `card_states` 当前正式纳入 backup / restore 范围（P3.2）
此前 `card_states` 更偏本地调度内部表。  
当前代码现实中，它已正式纳入：
- backup export
- backup upload payload
- latest snapshot fetch
- restore apply

因此它不再只是“本地调度私有中间态”，而是：
> **P3.2 runtime 下可被备份、拉取、恢复的正式本地持久化资产之一。**

### 6.1.2 `card_states` 最小字段现实
当前 `card_states` 至少包含以下字段语义：
- `id`
- `word_id`
- `stability`
- `difficulty`
- `due`
- `last_review`
- `state`
- `step`
- `reps`
- `lapses`
- `scheduled_days`
- `elapsed_days`
- `last_rating`
- `created_at`
- `updated_at`

Room 2 正式表述：
- `id` 属于本地主键；备份时不必要求原值回放
- `word_id` 是 restore 语义的主要业务锚点
- `stability / difficulty / due / state / step / reps / lapses` 是当前 FSRS 运行态的核心字段现实

### 6.1.3 本地设置层与主进度层继续分开
P3.2 / P3.3.16 当前没有推翻此前边界：
- 轻设置项继续走本地轻持久层
- 主学习进度 / FSRS 调度状态继续走本地 SQLite
- restore warning 仍必须覆盖设置层也可能被覆盖这一事实

---

## 7. Layer B — Snapshot / Backup schema reality

## 7.1 当前 snapshot schema 版本
当前代码现实中，最新 snapshot schema 已升级到：

- `p3_2_snapshot_v1`

### 7.1.1 `p3_2_snapshot_v1` 的增量重点
相对更早 schema，本轮正式新增 / 强化：
1. `device` 块
   - `device_id`
   - `device_model`

2. `progress.card_states`
   - FSRS 调度状态数组

### 7.1.2 向后兼容
当前恢复链支持：
- `p3_2_snapshot_v1`：完整恢复
- `p3_1_snapshot_v2`：降级恢复（不含 `card_states`）

Room 2 正式处理：
- 接受该兼容性为当前 implemented reality
- 但不把它扩写成多版本 merge 平台或复杂 snapshot migration framework

## 7.2 Backup / restore 当前的 DB 语义边界
当前 DB 层必须继续严格区分：

1. **Backup upload success**
   - 只是 snapshot 上传并持久化成功

2. **Snapshot fetch success**
   - 只是可下载 / 可读取最新 snapshot

3. **Restore apply success**
   - 才会改变目标设备本地 runtime state

### 7.2.1 当前继续明确不做
以下仍不属于当前 DB reality：
- real-time sync
- background sync
- multi-device merge
- conflict auto-resolution
- partial restore orchestration
- backup history picker
- destructive sync rewrite

---

## 8. Layer C — Candidate contracts not fully implemented

### 8.1 Backup / restore 方向当前仍未升格为 full sync
当前仍不得写成已实现事实的内容包括：
1. 自动双向同步
2. 多设备冲突自动合并
3. 云端 snapshot = 当前所有设备一致真相
4. restore 无 warning 静默覆盖
5. backup existence = sync success

### 8.2 Local review batch 方向当前仍未升格的内容
当前仍不得写成已实现事实的内容包括：
1. `review_group` 已退场
2. active continuation 已切到 local source
3. local batch 已成为统一 review serving truth
4. final fact owner shift 已完成
5. planner merge / unified planner 已建立

### 8.3 当前已知风险 / hold notes
1. `local_batch_*` 成功提交后若 backend 不可用，当次结算仍可能丢失，当前无本地补偿型 final-fact fallback
2. `local_batch_*` 是当前 code-truth reality，但其长期命名、持久化姿态与是否继续扩张，仍需 Room 2 / Room 1 在后续 round 单独判断
3. `latestBackup` / `backupSnapshot` 当前只承载 latest snapshot，不是版本仓库

---

## 9. Room 2 本轮建议写回

### 9.1 建议吸收进 full baseline 的内容
以下内容建议由 Room 1 在合适轮次吸收进 next-step DB baseline：
1. `latestBackup` / `backupSnapshot` 持久化对象
2. `p3_2_snapshot_v1` 与 `card_states` 纳入 backup / restore
3. `review_attempts.review_group_id` 接受 `local_batch_*`
4. P3.3.16 对 `daily_goal_progress` / `learning_day_facts` / `reward_*` / `settlements` / `idempotency_keys` 的代码现实更新

### 9.2 本轮不建议静默升格的内容
以下内容当前仍不建议静默升格：
1. `review_group` true exit
2. active DB baseline uplift absorbed beyond documented deltas
3. final fact owner shift
4. full sync / merge platform 叙事
5. 本地 serving 全面取代 cloud review-serving layer

---

## 10. 结论

> **`v0.2.2` 的价值，不是把 DB 文档重写成另一套，而是把 `v0.2.1` 之后已经真实影响系统运行的 P3.2 / P3.3.16 数据现实，正式并回 full baseline。**

当前 Room 2 judgment 是：
- dual-store 主骨架不变
- backup / restore 的持久化与 snapshot reality 已应进入主文档
- local review batch 已进入后端结算链的 DB reality
- 但 `review_group` 退场、fact owner shift、full sync 化叙事仍不得偷写成当前事实
