# 背单词喵喵 App DB 设计草案 v0.2.3

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.2.3
- **Date:** 2026-04-14
- **Status:** incremental merged full baseline candidate / ready for Room 1 review
- **Role card:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.2`
- **Purpose:** 以 `背单词喵喵app_DB设计草案_v0.2.2.md` 为 full merged baseline candidate base，增量吸收 `需求-001-增加例句词书.md`、`plan-001-增加例句词书.md` 与 `dp修改.md` 中已收口的本地内容层 DB 事实，形成新的单文件 full merged baseline candidate。

---

## 0. 文档定位

本稿不是：
- 对 `背单词喵喵app_DB设计草案_v0.2.1.md` 的整份重写
- 把所有 future candidate 一次性升格为 active runtime truth
- 把 P3.3.16 的 fuller cutover / `review_group` true exit / active DB baseline uplift 各类 pending judgment 写成已生效事实

本稿只做一件事：

> **在保留 `v0.2.1` full baseline 主结构的前提下，把已经影响开发、维护、联调、测试与后续文档引用的 DB 代码事实，吸收到新的 full merged baseline candidate。**

### 0.1 本轮吸收范围
本轮在 `v0.2.2` 的基础上，只吸收以下一类已经收口、且需要进入 full DB 文档的代码 / 契约事实：

1. **词书 + 例句本地内容层增量**
   - 新增本地内容层 4 张表：`preset_wordbooks`、`word_entries`、`word_book_assignments`、`example_sentences`
   - 支持单词-词书多对多、单词-例句一对多
   - `example_sentences (word_id, sort_order)` 进入复合唯一约束语义
   - `word_entries.cached_at` 修正为 `imported_at`
   - `word_book_assignments` 新增 `source_key`
   - `preset_wordbooks` 新增 `content_version`
   - 内容层 migration 从 `v3` 调整到 `v4`
   - 4 张表继续保持 **asset-derived / local-only / offline-readable**

### 0.2 一句话原则
> **既不否认 `v0.2.2` 已收口的 dual-store + backup/local-batch 基线，也不让“词书 + 例句本地内容层”继续只停留在需求说明和 patch 附件里。**

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
- `背单词喵喵app_DB设计草案_v0.2.2.md`
- `需求-001-增加例句词书.md`
- `plan-001-增加例句词书.md`
- `dp修改.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `Main_updated_2026-04-10_v34.md`

### 1.4 吸收原则
1. 保留 `v0.2.2` 的 full baseline 主结构与三层阅读方式
2. 正式吸收“词书 + 例句本地内容层”的 local-only DB reality
3. 显式写清它与主机制真相层、FSRS、奖励、结算、云端 API 的边界
4. 不把 content layer 偷写成 cloud truth、sync truth 或主机制事实层升级
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
> **v0.2.3 继续采用 “incremental merged baseline” 路线。**

也就是：
- 保留推进层 active DB baseline 的引用位置
- 沿用 `v0.2.2` 的 dual-store 主骨架
- 把“词书 + 例句本地内容层”已收口的数据现实吸收进 full 文档
- 显式保留 local-only / asset-derived / not-cloud-truth 的边界
- 清掉“这些变化只存在于需求说明与 patch 文档”的状态

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

5. 本轮新增的词书 / 例句能力是 **本地内容层扩展**，不是云端主事实层升级。  
   它服务学习页内容展示与多词书离线读取，但不改变 FSRS、奖励、结算、today 聚合与主机制真相源。

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


### 6.1.4 词书 + 例句本地内容层（P-001）
当前代码 / 方案收口中，本地 SQLite 新增一层 **asset-derived content layer**，用于承载：
- 预置词书
- 规范化单词主表
- 单词-词书多对多关系
- 单词-例句一对多关系

Room 2 正式表述：
- 这一层属于 **本地内容层**，不是云端 today / reward / settlement / review_group truth layer
- 它的目标是支持 ZK / GK 等预置词书的离线读取与学习页例句增强
- 它不替代现有 `cached_words` / `book-001.json` 路径；当前 CET-4 路径继续保持不变
- 它不改变当前“用户同一时间一个 active 学习词书”的产品口径；只是把底层数据能力升级为 **one word ↔ many books** 与 **one word ↔ many examples**

### 6.1.5 新增 4 张本地内容表
#### A. `preset_wordbooks`
当前最小字段语义：
- `slug`
- `display_name`
- `total_words`
- `description`
- `sort_order`
- `content_version`

其语义是：
- 预置词书主表
- 当前至少承载 `zk` / `gk` 两类预置词书
- `content_version` 用于控制 asset 内容版本与重新导入判断

#### B. `word_entries`
当前最小字段语义：
- `word_id`
- `word_text`
- `phonetic`
- `meaning`
- `translation`
- `definition`
- `frequency_rank`
- `word_forms`
- `imported_at`

Room 2 正式处理：
- `word_id` 是 canonical key，按 lowercase word text 统一
- `imported_at` 表示 asset 导入时间，不再使用 `cached_at` 这种容易误解成“云端缓存时间”的命名
- 该表是内容层规范化单词主表，不等于主机制 progress / FSRS / fact tables

#### C. `word_book_assignments`
当前最小字段语义：
- `word_id`
- `book_slug`
- `sort_order`
- `source_key`

当前结构语义：
- `PK = (word_id, book_slug)`
- `idx_wba_book_order ON (book_slug, sort_order)`

Room 2 正式处理：
- 这张表是单词-词书多对多联表
- `source_key` 用于记录原始 CSV 来源位置，使 canonical `word_id` 与 source origin 可独立追溯
- 它解决“同一个单词可以属于多个词书”的底层事实，不自动改变 UI 或当前 active 词书产品口径

#### D. `example_sentences`
当前最小字段语义：
- `id`
- `word_id`
- `sense`
- `en`
- `cn`
- `sort_order`

当前结构语义：
- `idx_es_word_order` 必须带 **unique** 语义
- `(word_id, sort_order)` 作为复合唯一约束，用于配合 `INSERT OR IGNORE` 拦住重复导入

Room 2 正式处理：
- 该表是单词-例句一对多表
- 当前例句只作为学习页内容增强，不进入主机制最终事实判断
- 英文 / 中文例句中的 bracket 标注属于内容层原始显示资产，不影响主机制评分 / 结算 / 复习真相

### 6.1.6 本地内容层的当前权威源划分
在 `v0.2.3`，本地端至少应分成三类语义层：

| 数据域 | 当前权威源 | 说明 |
|---|---|---|
| FSRS 调度 / review logs / local progress | 本地 drift / SQLite | 主学习运行态 |
| `daily_goal` / `activeWordbook` 等轻设置 | 本地 settings / SharedPreferences | 设备侧当前生效值 |
| 预置词书 / 例句内容层 | 本地 drift / SQLite + asset JSON 导入 | local-only / offline-readable 内容资产 |

Room 2 正式处理：
- `activeWordbook` 当前属于本地 settings 控制项，不是云端用户设置真相
- 词书内容层是“本地导入后可运行”的内容资产，不等于云端内容服务
- 例句存在与否不影响学习提交、复习提交、奖励结算与 today 聚合的真相判断

### 6.1.7 导入与 migration 现实（v3 → v4）
当前本地内容层的 migration / import 现实应写清如下：

1. 4 张内容层表都是 **asset 派生数据**
   - 无用户原创内容
   - 无需复杂回填
   - 可通过重新导入恢复

2. `v3 → v4` 当前允许采用：
   - `DROP + CREATE`
   - 顺序：`example_sentences → word_book_assignments → word_entries → preset_wordbooks`

3. 重建后：
   - 下次启动由 `WordbookLoader.loadIfNeeded()` 自动重新导入
   - 判定条件不再只是 `slug exists`
   - 还要检查 `content_version` 是否匹配

4. `export-wordbook-json.ts` 当前输出层新增：
   - 顶层 `contentVersion`
   - 每词 `sourceKey`

Room 2 正式处理：
- 这是 **本地内容资产导入链**，不是 cloud migration / DB schema cutover / data reconciliation program
- 因为内容层不含用户原创写入，所以当前不需要手工 backfill、复杂 rollback script 或线上数据修复叙事

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
4. 词书 + 例句内容层当前是 local-only / asset-derived；尚未进入云端内容服务、差量更新、内容审核流水或多端内容同步
5. `activeWordbook` 当前仍是设备侧设置；它未来若进入账号级同步或跨端统一，需要单开下一轮 DB / API / BR judgment

---

## 9. Room 2 本轮建议写回

### 9.1 建议吸收进 full baseline 的内容
以下内容建议由 Room 1 在合适轮次吸收进 next-step DB baseline：
1. 本地内容层 4 张表：`preset_wordbooks` / `word_entries` / `word_book_assignments` / `example_sentences`
2. `example_sentences (word_id, sort_order)` 复合唯一约束语义
3. `word_entries.imported_at`、`word_book_assignments.source_key`、`preset_wordbooks.content_version`
4. `v3 → v4` 的 asset-derived content migration 口径
5. local-only content layer 与 FSRS / reward / settlement / cloud truth 的边界

### 9.2 本轮不建议静默升格的内容
以下内容当前仍不建议静默升格：
1. 词书内容层进入云端 truth 或账号级同步 truth
2. 例句进入主机制事实层、奖励层或复习结算层
3. `activeWordbook` 自动变成云端用户设置真相
4. 内容层引申成复杂词书市场 / 内容分发平台 / delta sync 平台
5. 因内容层新增而误写成 FSRS、review_group、today 聚合或 final fact owner 被改动

---

## 10. 结论

> **`v0.2.3` 的价值，不是把 DB 文档改成“另起一套内容平台设计”，而是把 `v0.2.2` 之后已经真实影响本地 SQLite 结构与学习页内容读取的“词书 + 例句本地内容层”现实，正式并回 full baseline。**

当前 Room 2 judgment 是：
- dual-store 主骨架不变
- P3.2 backup / restore 与 P3.3.16 local-batch 现实继续保留
- 词书 + 例句本地内容层应正式进入主 DB 文档
- 但它仍是 local-only / asset-derived / offline-readable 内容层，不得偷写成 cloud truth、sync truth 或主机制 final-fact 层升级
