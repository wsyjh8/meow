# 背单词喵喵 App DB 设计草案 v0.1.5

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Status:** incremental P3.1 direct-scope delta write-back / ready for Room 1 review
- **Purpose:** 基于当前推进层 SSOT、`BR-OPP-001_v0.1.9.md`、`R1_to_R2_P3_1_Delta_DB_API_Writeback_Handoff_v0.1.md` 与 `R2_P3_1_DirectScopePin_Delta_Tech_Note_v0.1.1.md`，在 `v0.1.4` 的单文件基线上，把 P3.1 direct-scope delta round 已 close 的 backup / restore / daily_goal 相关技术契约，增量回写进 Room 2 的 DB 候选基线。
- **Scope:** 本稿继续保留主机制事实层、进度层、结算层与 P2 已吸收的副机制最小真相层，并新增 P3.1 direct-scope delta 相关的 cloud backup container / restore operation audit / latest backup metadata 契约。
- **Out of scope:** full sync、real-time sync、background sync、multi-device merge、partial restore、snapshot picker、delete backup、clear local、destructive actions bundle、production-grade persistence rollout 细节。

---

## 0. Based on current active versions

### Runtime / Product
- `Main.md`（current runtime: `Main_updated_2026-04-07_v17.md`）
- `OPP-001_STATUS.md`（current runtime: `STATUS_updated_2026-04-07_v16.md`）
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `背单词喵喵app_副机制prd_v_0.md`
- `背单词喵喵app_副机制数值草案_v_0.md`
- `UI_SPEC_P3_1_LocalProgress_CloudBackup_v0.1.1.md`
- `UI_SPEC_P3_1_DirectScopePin_Delta_v0.1.1.md`

### Governance / Rules / Decision basis
- `PROJECT_RULES_MASTER_v0.3.1.md`
- `room1_v0.2.0.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.0.md`
- `room4_v0.2.0.md`
- `room5_v0.2.0.md`
- `BR-OPP-001_v0.1.9.md`
- `R1_to_R2_P3_1_Delta_DB_API_Writeback_Handoff_v0.1.md`
- `R2_P3_1_DirectScopePin_Delta_Tech_Note_v0.1.1.md`
- `R3_P3_1_DirectScopePin_Delta_Rules_Note_v0.1.1.md`
- `R4_P3_1_DirectScopePin_Delta_Execution_Note_v0.1.1.md`

> 说明：本稿是对 `背单词喵喵app_DB设计草案_v0.1.3.md` 的 **incremental P2 secondary write-back**。
> - 保留 `v0.1.3` 已经稳定的主机制事实层、进度层、结算层与 `review_group / check_in / learning_day / streak` 基线。
> - 只回写 Room 4 已经真正实现并在 `R4_P2_final_delivery_package_v0.1.md` 中声明为 backend runtime truth 的 secondary mechanism 最小真相层。
> - 不反向扩写多猫、社交、复杂商店、完整房间坐标系统，也不把 dev numbers 假装冻结成长期业务规则。
> - 目标仍是保持 **single-file baseline**，让 Room 4 / Room 1 不需要通过“旧版 + patch”拼完整语义。


---

## 1. 本稿目标

本稿要解决 8 件事：

1. 保留 `v0.1.2` 的 **全量表设计、状态机、风险与 trade-off**，不让单文件基线因为增量回写再次变薄。
2. 把 `D-OPP-001-010` 正式回写到 DB：
   - `review_group` 最小稳定对象
   - 单用户单 active group 约束
   - group completion 幂等与唯一结算
3. 把 `D-OPP-001-011` 正式回写到 DB：
   - `check_in`
   - `learning_day`
   - `streak`
   三类事实拆分表达
4. 正式冻结：
   - `streak_basis_type = check_in`
   - `local_date / timezone` 为三类事实统一自然日口径
5. 继续保留真正仍未冻结的事项，不把 `group size`、分组算法、完整 SRS、熟练度阈值等偷冻结。
6. 把 UI / API / DB 的主命名继续统一到：
   - `daily_goal_status`
   - `session_validation_status`
   - `reward_settlement_status`
7. 让 Room 4 继续把本文件当作 **standalone latest draft** 阅读，不需要额外拼接 `R2_alignment_note` 或旧版 DB。
8. 给后续 `API设计草案_v0.1.2.md`、Room 4 `plan.md` / `TEST_PLAN` 与 Room 1 下一轮 active pin 提供稳定 DB 基准。


---

## 2. 设计原则

### 2.1 Fact-first（事实优先）
先记录原子学习事实，再汇总为进度、状态、结算结果；避免把 UI 展示态直接写死成数据库唯一事实。

### 2.2 Main-first（主机制优先）
副机制不得绕开主机制发奖；因此奖励来源必须能追到主机制 source event。

### 2.3 Idempotent-by-design（天生防重）
所有影响奖励、进度、Session、签到的关键写操作，都必须可幂等。

### 2.4 State-visible（状态可追踪）
UI 需要显示的关键状态，必须在 DB 中可追踪，而不是靠前端推导。

### 2.5 Backend-truth（后端真相源）
`daily_goal_status`、`session_validation_status`、`reward_settlement_status` 都由服务端产出；UI 只能读取，不得前端补脑。

### 2.6 Pending-explicit（未冻结显式保留）
当前仍未冻结的规则不在实现中“脑补定死”；通过字段预留、状态枚举、decision block 标记保留。

---
## 3. 本稿覆盖范围

本稿至少覆盖以下核心实体：

1. `users`
2. `word_books`
3. `words`
4. `user_book_settings`
5. `study_attempts`
6. `user_word_progress`
7. `review_queue`
8. `review_groups`
9. `review_group_items`
10. `daily_goal_progress`
11. `session_records`
12. `check_in_records`
13. `learning_day_facts`
14. `streak_records`
15. `reward_source_events`
16. `reward_ledger`
17. `learning_stat_daily`

> 说明：
> - `study_attempts` 是本稿新增的事实层表，用于承接新词学习 / 复习的原子提交。
> - 主机制 PRD 只要求最少覆盖若干核心实体，但从实现角度，如果没有原子事实层，后续幂等、补偿、统计、回放都会变脆。

---

## 4. 全局约定

## 4.1 ID 约定
- 主键统一使用 `uuid`
- 所有跨表引用统一 `uuid`
- 外部幂等键统一 `varchar(128)`

## 4.2 时间约定
- 所有时间字段使用 UTC 存储
- 字段名统一：
  - `created_at`
  - `updated_at`
  - 业务时间使用 `*_at`
- 自然日统计口径额外保存 `local_date`（按用户时区折算后的 date）

## 4.3 删除策略
- MVP 优先不做业务软删主路径
- 如需软删，仅配置类表使用 `is_active`
- 事实表默认不可删除，只允许补偿和状态修正

## 4.4 状态字段约定
- 业务状态优先使用小写枚举字符串
- 所有状态字段禁止使用“前端展示文案”直接入库

## 4.5 用户时区
- `users.timezone` 必须存在
- streak、签到、daily goal 都依赖用户自然日

---

## 5. 已冻结规则 / 仍待冻结事项

### 5.1 已冻结（本稿必须正式落库支持）

#### FD-DB-001 `daily_goal_status` 严格判定口径
- 只由“今日新词目标 + 今日复习要求”共同决定。
- **不包含** Session 是否完成。
- **不包含** 签到是否成功。
- 当日无待复习内容时，复习要求视为自然满足。

#### FD-DB-002 `session_validation_status` MVP 阈值
- 只有同时满足以下条件，Session 才记为 `valid`：
  1. 正常启动
  2. 正常结束
  3. 达到当前配置时长（MVP 默认 15 分钟）
  4. Session 内至少 5 次 `effective learning / effective review attempts` 总和
- 否则在校验完成后记为 `invalid`。

#### FD-DB-003 主机制结算层与副机制承接边界
- DB 层只负责：
  - 存储主机制来源事件
  - 存储来源事件结算状态
  - 存储奖励账本到账状态
  - 存储可选的轻量结算摘要快照
- DB 不直接表达“UI 是否可展示副机制深操作”；但必须支持 UI 严格区分：
  - 结算已触发 / 已展示
  - 奖励已到账

#### FD-DB-004 `review_group` 最小业务合同
- `review_group` 是 **后端生成、后端持有的一次有限复习批次对象**。
- 同一用户同一时刻 **只允许一个 active `review_group`**。
- “本组复习完成”指：当前 `review_group_id` 下，后端要求完成的 item 已全部获得有效提交结果，且该组完成结果已被服务端唯一确认。
- “本组完成”只推进“今日复习进度”，**不自动等于**“今日复习完成”。
- 允许同一 active group 跨 Session 继续完成，但不得并行生成多个 active group，不得重复结算，不得重复发奖。

#### FD-DB-005 `check_in / learning_day / streak` 关系
- 当前 MVP 冻结为三类独立事实：
  - `check_in`
  - `learning_day`
  - `streak`
- `check_in` 只表示签到事实成立，不自动等于 `learning_day`、有效学习完成、或 `daily_goal_status=completed`。
- `learning_day` 表示该 `local_date` 下满足后端口径的有效学习事实成立，不依赖签到是否发生。
- `streak` 当前阶段 **按 `check_in` 驱动**，即 `streak_basis_type = check_in`。
- 三类事实统一按用户时区折算后的 `local_date` 处理，服务端为最终真相源。

### 5.2 仍待冻结（本稿继续显式保留）

#### PD-DB-001 熟练度 / 掌握阈值
- **现状：** 仍未冻结完整算法。
- **本稿处理：**
  - `user_word_progress.mastery_score`
  - `user_word_progress.mastery_level`
  - `user_word_progress.is_mastered`
  全部保留，但不在本稿冻结算法。

#### PD-DB-002 完整 SRS / review priority / review_group 分组算法细节
- **现状：** `review_group` 的最小合同已冻结，但组大小、分组算法、题型比例、完整 SRS 与 review priority 详细算法仍未冻结。
- **本稿处理：**
  - `review_queue.queue_status`
  - `priority_score`
  - `due_at`
  - `last_scheduled_at`
  - `review_groups.source_queue_snapshot_version`
  - `review_group_items`
  先提供稳定容器与可追踪对象，算法后补。

#### PD-DB-003 今日页主 CTA winner rule
- **现状：** “有待复习且优先级更高时先去复习”的最终仲裁规则仍未冻结。
- **本稿处理：**
  - DB 提供足够聚合字段
  - 不在 DB 层假装冻结 CTA 胜出逻辑

#### PD-DB-004 统计页是否扩成下一轮极简规格
- **现状：** 统计页目前只保留入口，范围仍未冻结。
- **本稿处理：**
  - 保留 `learning_stat_daily`
  - 保留 `learning_day_facts`
  - 不反向扩大当前 DB 范围

---

## 6. 实体总览图（逻辑）
## 6. 实体总览图（逻辑）

```text
users
 ├─< user_book_settings >─ word_books
 ├─< study_attempts >─ words
 ├─< user_word_progress >─ words
 ├─< review_queue >─ words
 ├─< review_groups
 │   └─< review_group_items >─ words
 ├─< daily_goal_progress
 ├─< session_records
 ├─< check_in_records
 ├─< learning_day_facts
 ├─1 streak_records
 ├─< reward_source_events
 ├─< reward_ledger
 └─< learning_stat_daily
```

---

## 7. 表设计

# 7.1 `users`

## 7.1.1 目标
承载主机制一切事实的用户归属、自然日口径与基础学习配置。

## 7.1.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | 用户 ID |
| account_type | varchar(32) | guest / email / oauth |
| email | varchar(255) nullable unique | 邮箱 |
| nickname | varchar(64) nullable | 昵称 |
| timezone | varchar(64) not null | 用户时区 |
| locale | varchar(16) nullable | 语言偏好 |
| current_level | int default 1 | 账号学习等级，MVP 可选 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

## 7.1.3 索引 / 约束
- `pk_users(id)`
- `uk_users_email(email)` where email is not null
- `chk_users_timezone_not_blank`

## 7.1.4 备注
- 是否做独立 `user_profiles`，MVP 可暂不拆。

---

# 7.2 `word_books`

## 7.2.1 目标
定义词书 / 词库。

## 7.2.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | 词书 ID |
| code | varchar(64) unique | 稳定编码 |
| name | varchar(128) | 词书名 |
| language | varchar(16) | 语言 |
| difficulty | varchar(32) nullable | 难度层级 |
| is_active | boolean default true | 是否启用 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

---

# 7.3 `words`

## 7.3.1 目标
定义基础词条。

## 7.3.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | 单词 ID |
| book_id | uuid fk -> word_books.id | 所属词书 |
| word_text | varchar(128) | 单词文本 |
| phonetic | varchar(128) nullable | 音标 |
| meaning | text | 中文释义 |
| example_sentence | text nullable | 例句 |
| audio_url | text nullable | 音频 |
| sort_order | int | 在词书中的顺序 |
| difficulty_score | int nullable | 难度分 |
| is_active | boolean default true | 是否有效 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

## 7.3.3 索引 / 约束
- `idx_words_book_sort(book_id, sort_order)`
- `uk_words_book_word(book_id, word_text)`

---

# 7.4 `user_book_settings`

## 7.4.1 目标
记录用户当前 active 词书与目标设置。

## 7.4.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | 主键 |
| user_id | uuid fk -> users.id | 用户 |
| book_id | uuid fk -> word_books.id | 当前词书 |
| is_active | boolean default true | 是否当前 active |
| daily_new_target | int not null | 每日新词目标 |
| daily_review_target_mode | varchar(32) not null | auto / fixed_minimum |
| daily_review_target_value | int nullable | 固定目标值 |
| switched_at | timestamptz nullable | 最近切换时间 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

## 7.4.3 索引 / 约束
- `idx_user_book_settings_user_active(user_id, is_active)`
- `uk_user_book_settings_single_active(user_id) where is_active=true`
- `chk_daily_new_target_positive`

## 7.4.4 备注
- 词库切换频率规则未冻结；DB 只保留能力。

---

# 7.5 `study_attempts`

## 7.5.1 目标
主机制学习事实层；统一记录新词学习与复习提交。

## 7.5.2 为什么必须有
如果只有 `user_word_progress` 聚合表，没有原子行为事实：
- 无法可靠做幂等
- 无法回放奖励来源
- 无法补偿统计
- 无法验证“本次 Session 到底做了什么”

## 7.5.3 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | attempt ID |
| user_id | uuid fk -> users.id | 用户 |
| word_id | uuid fk -> words.id | 单词 |
| book_id | uuid fk -> word_books.id | 词书 |
| session_id | uuid nullable fk -> session_records.id | 所属 Session |
| study_type | varchar(16) not null | new / review |
| action_result | varchar(32) not null | know / dont_know / later / correct / wrong |
| review_group_id | uuid nullable fk -> review_groups.id | 若为复习，所属组 |
| question_type | varchar(32) nullable | 复习题型 |
| is_effective_learning | boolean not null default false | 是否计为有效学习 |
| idempotency_key | varchar(128) not null | 客户端/服务端幂等键 |
| submitted_at | timestamptz | 提交时间 |
| local_date | date not null | 用户自然日 |
| created_at | timestamptz | 创建时间 |

## 7.5.4 索引 / 约束
- `uk_study_attempts_user_idempotency(user_id, idempotency_key)`
- `idx_study_attempts_user_date(user_id, local_date)`
- `idx_study_attempts_user_session(user_id, session_id)`
- `idx_study_attempts_word(word_id)`
- `chk_study_type_enum`
- `chk_action_result_enum`

## 7.5.5 枚举建议
### `study_type`
- `new`
- `review`

### `action_result`
- 新词：`know` / `dont_know` / `later`
- 复习：`correct` / `wrong`

## 7.5.6 备注
- `is_effective_learning` 由后端判定后回写，不由前端直接传最终值。
- 同一单词多次提交允许存在，但必须依赖不同 `idempotency_key`。
- 若 `study_type='review'`，则 `review_group_id` 应稳定指向当前 active group；Room 4 不应靠 attempt 临时推导“当前组”。

---

# 7.6 `user_word_progress`

## 7.6.1 目标
记录用户对单词的当前聚合状态。

## 7.6.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | 主键 |
| user_id | uuid fk -> users.id | 用户 |
| word_id | uuid fk -> words.id | 单词 |
| book_id | uuid fk -> word_books.id | 词书 |
| current_status | varchar(32) not null | unseen / learning / review_due / reviewing / mastered |
| mastery_score | numeric(6,2) default 0 | 熟练度分 |
| mastery_level | int default 0 | 熟练度等级 |
| is_mastered | boolean default false | 是否掌握 |
| learn_count | int default 0 | 新词学习次数 |
| review_count | int default 0 | 复习次数 |
| correct_count | int default 0 | 正确次数 |
| wrong_count | int default 0 | 错误次数 |
| later_count | int default 0 | 稍后复习次数 |
| first_learned_at | timestamptz nullable | 首学时间 |
| last_learned_at | timestamptz nullable | 最近新学时间 |
| last_reviewed_at | timestamptz nullable | 最近复习时间 |
| next_review_at | timestamptz nullable | 下次建议复习时间 |
| last_result | varchar(32) nullable | 最近一次结果 |
| updated_at | timestamptz | 更新时间 |
| created_at | timestamptz | 创建时间 |

## 7.6.3 索引 / 约束
- `uk_user_word_progress(user_id, word_id)`
- `idx_uwp_user_book_status(user_id, book_id, current_status)`
- `idx_uwp_user_next_review(user_id, next_review_at)`

## 7.6.4 枚举建议
### `current_status`
- `unseen`
- `learning`
- `review_due`
- `reviewing`
- `mastered`

## 7.6.5 Pending
- `mastery_score -> is_mastered` 的阈值暂不冻结。

---

# 7.7 `review_queue`

## 7.7.1 目标
承接“今天有哪些要复习”的队列事实。

## 7.7.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | 队列项 ID |
| user_id | uuid fk -> users.id | 用户 |
| word_id | uuid fk -> words.id | 单词 |
| book_id | uuid fk -> word_books.id | 词书 |
| source_progress_id | uuid fk -> user_word_progress.id | 来源 progress |
| queue_status | varchar(32) not null | pending / in_progress / done / skipped |
| priority_score | numeric(8,2) default 0 | 复习优先级 |
| due_at | timestamptz not null | 应复习时间 |
| first_queued_at | timestamptz | 首次入队时间 |
| last_scheduled_at | timestamptz | 最近调度时间 |
| last_review_group_id | uuid nullable fk -> review_groups.id | 最近分组 |
| last_reviewed_at | timestamptz nullable | 最近复习时间 |
| local_due_date | date not null | 用户自然日 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

## 7.7.3 索引 / 约束
- `idx_review_queue_user_due(user_id, queue_status, due_at)`
- `idx_review_queue_user_local_due(user_id, local_due_date, queue_status)`
- `uk_review_queue_pending_unique(user_id, word_id, queue_status) where queue_status in ('pending','in_progress')`

## 7.7.4 枚举建议
### `queue_status`
- `pending`
- `in_progress`
- `done`
- `skipped`

## 7.7.5 备注
- 先支持简化队列；完整 SRS 后续只需更新调度逻辑，不必重做表。


# 7.7A `review_groups`

## 7.7A.1 目标
把 `review_group` 从“零散 attempt 临时推导概念”升级为**后端稳定持有的最小复习批次对象**，支撑：
- 当前组读取
- 本组完成判定
- 同组跨 Session 继续
- 同组完成唯一结算

## 7.7A.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | review group ID |
| user_id | uuid fk -> users.id | 用户 |
| local_date | date not null | 组首次生成对应的用户自然日 |
| group_status | varchar(32) not null | active / completed / expired / abandoned |
| group_size_total | int not null | 本组总 item 数 |
| group_size_completed | int not null default 0 | 已完成 item 数 |
| source_queue_snapshot_version | varchar(64) nullable | 生成该组时采用的队列快照版本 |
| completion_source_event_id | uuid nullable fk -> reward_source_events.id | 本组完成对应来源事件 |
| generated_at | timestamptz not null | 组生成时间 |
| completed_at | timestamptz nullable | 组完成时间 |
| expires_at | timestamptz nullable | 组自然失效时间（MVP 可空） |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

## 7.7A.3 索引 / 约束
- `idx_review_groups_user_date(user_id, local_date, group_status)`
- `uk_review_groups_single_active(user_id) where group_status='active'`
- `uk_review_groups_completion_source(completion_source_event_id) where completion_source_event_id is not null`
- `chk_review_groups_size_nonnegative`
- `chk_review_groups_completed_lte_total`

## 7.7A.4 枚举建议
### `group_status`
- `active`
- `completed`
- `expired`
- `abandoned`

## 7.7A.5 冻结规则对应说明
- 同一用户同一时刻只能有一个 `group_status='active'`。
- `group_status='completed'` 不自动等于今日复习完成，只表示组级完成。
- 允许同组跨 Session 继续；group 与 Session 故意不做强绑定。
- `completion_source_event_id` 用于保证“同组完成”唯一结算、唯一发奖。

---

# 7.7B `review_group_items`

## 7.7B.1 目标
把 group 内 item 变成可追踪、可恢复、可测试的稳定对象，不把组内容只塞进 JSON snapshot。

## 7.7B.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | group item ID |
| review_group_id | uuid fk -> review_groups.id | 所属组 |
| word_id | uuid fk -> words.id | 单词 |
| item_status | varchar(16) not null | pending / completed |
| completed_attempt_id | uuid nullable fk -> study_attempts.id | 完成该 item 的 attempt |
| sort_order | int not null | 展示顺序 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

## 7.7B.3 索引 / 约束
- `idx_review_group_items_group(review_group_id, sort_order)`
- `uk_review_group_items_group_word(review_group_id, word_id)`
- `uk_review_group_items_completed_attempt(completed_attempt_id) where completed_attempt_id is not null`

## 7.7B.4 备注
- 同一 group 内，同一 word 只能出现一次。
- item 完成必须依赖具体 attempt，避免重复推进 group 完成计数。
- 若后续要支持“跳过 / 替换题型”，再扩 `item_status`，本轮不先做复杂化。

---

# 7.8 `daily_goal_progress`

## 7.8.1 目标
给今日页与结算层提供统一的“今天还差什么”事实来源，并输出唯一可信的 `daily_goal_status`。

## 7.8.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | 主键 |
| user_id | uuid fk -> users.id | 用户 |
| local_date | date not null | 用户自然日 |
| book_id | uuid fk -> word_books.id | 当日词书 |
| target_new_count | int not null | 今日新词目标 |
| completed_new_count | int not null default 0 | 今日已完成新词数 |
| review_target_mode | varchar(32) not null | auto / fixed_minimum |
| target_review_count | int not null default 0 | 今日复习要求数 |
| pending_review_count_snapshot | int not null default 0 | 今日待复习快照 |
| completed_review_count | int not null default 0 | 今日已完成复习数 |
| check_in_completed | boolean not null default false | 今日是否已签到（仅签到事实） |
| valid_session_completed | boolean not null default false | 今日是否已有 valid session |
| goal_status | varchar(32) not null | not_started / in_progress / partially_completed / completed |
| goal_status_reason | varchar(64) nullable | 例如 `new_done_review_pending` |
| last_evaluated_at | timestamptz nullable | 最近判定时间 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

## 7.8.3 索引 / 约束
- `uk_daily_goal_progress_user_date(user_id, local_date)`
- `idx_daily_goal_progress_user_status(user_id, local_date, goal_status)`
- `chk_goal_status_enum`
- `chk_target_new_count_nonnegative`
- `chk_target_review_count_nonnegative`

## 7.8.4 枚举建议
### `goal_status`
- `not_started`
- `in_progress`
- `partially_completed`
- `completed`

## 7.8.5 冻结口径
- `goal_status` 只看新词目标与复习要求。
- `check_in_completed`、`valid_session_completed` 不进入 `goal_status` 判定。
- 当 `pending_review_count_snapshot = 0` 且无额外固定复习要求时，复习要求自然满足。

## 7.8.6 备注
- `goal_status_reason` 是为 UI / API / TEST 提供可解释性；不是必须对用户直接展示。
- UI 文案可显示“部分完成”，DB 不直接存文案。

---

# 7.9 `session_records`

## 7.9.1 目标
支撑 Session 开始 / 结束 / 校验 / 结算全链路，并记录最终 `session_validation_status`。

## 7.9.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | session ID |
| user_id | uuid fk -> users.id | 用户 |
| local_date | date not null | 用户自然日 |
| session_type | varchar(32) not null | focus_15m |
| session_minutes_target | int not null default 15 | 目标时长，MVP 默认 15 |
| actual_duration_seconds | int default 0 | 实际时长 |
| session_status | varchar(32) not null | started / ended / validating / valid / invalid |
| validation_status | varchar(32) not null | pending / valid / invalid |
| validation_reason_code | varchar(64) nullable | 例如 `duration_not_met` / `effective_attempts_not_met` |
| effective_learning_count | int not null default 0 | Session 内有效新学数 |
| effective_review_count | int not null default 0 | Session 内有效复习数 |
| session_rules_snapshot | jsonb not null | 当次使用规则快照，如 `{"min_minutes":15,"min_effective_attempts":5}` |
| reward_settlement_status | varchar(32) not null default 'pending' | 页面级结算状态：pending / settling / succeeded / failed / compensated |
| start_idempotency_key | varchar(128) not null | start 请求幂等键 |
| finish_idempotency_key | varchar(128) nullable | finish 请求幂等键 |
| started_at | timestamptz not null | 开始时间 |
| ended_at | timestamptz nullable | 结束时间 |
| validated_at | timestamptz nullable | 校验时间 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

## 7.9.3 索引 / 约束
- `idx_session_records_user_date(user_id, local_date)`
- `idx_session_records_user_status(user_id, session_status)`
- `idx_session_records_validation(user_id, validation_status, local_date)`
- `uk_session_records_start_idempotency(user_id, start_idempotency_key)`
- `uk_session_records_finish_idempotency(user_id, finish_idempotency_key) where finish_idempotency_key is not null`
- `chk_session_status_enum`
- `chk_validation_status_enum`
- `chk_effective_counts_nonnegative`

## 7.9.4 枚举建议
### `session_status`
- `started`
- `ended`
- `validating`
- `valid`
- `invalid`

### `validation_status`
- `pending`
- `valid`
- `invalid`

### `reward_settlement_status`
- `pending`
- `settling`
- `succeeded`
- `failed`
- `compensated`

## 7.9.5 冻结阈值对应规则
- `validation_status=valid` 的最低要求：
  - started + ended
  - 达到 `session_minutes_target`（MVP 默认 15）
  - `effective_learning_count + effective_review_count >= 5`
- 否则校验完成后写 `validation_status=invalid`。

## 7.9.6 备注
- UI 读 `session_validation_status` 时，对应 DB 字段为 `validation_status`。
- `session_status` 与 `validation_status` 故意分开：started / ended 不等于 valid / invalid。
- 页面级旧字段 `reward_status` 在本稿中正式替换为 `reward_settlement_status`，不再保留为主叫法。

---

# 7.10 `check_in_records`

## 7.10.1 目标
承接每日签到事实本身，不把签到默认等同于有效学习日。

## 7.10.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | check-in ID |
| user_id | uuid fk -> users.id | 用户 |
| local_date | date not null | 用户自然日 |
| check_in_status | varchar(16) not null | succeeded |
| streak_snapshot_before | int not null default 0 | 签到前 streak 快照 |
| streak_snapshot_after | int not null default 0 | 签到后 streak 快照 |
| node_reward_code | varchar(64) nullable | 连签节点奖励 |
| check_in_reward_source_event_id | uuid nullable fk -> reward_source_events.id | 与签到相关的来源事件 |
| idempotency_key | varchar(128) not null | 幂等键 |
| checked_in_at | timestamptz not null | 签到时间 |
| created_at | timestamptz | 创建时间 |

## 7.10.3 索引 / 约束
- `uk_check_in_records_user_date(user_id, local_date)`
- `uk_check_in_records_user_idempotency(user_id, idempotency_key)`

## 7.10.4 备注
- 每自然日一次签到。
- `check_in_records` 只承载签到事实，不默认等于有效学习日。
- `streak_snapshot_after` 当前按 `check_in` basis 计算，不代表 learning day 成立。


# 7.10A `learning_day_facts`

## 7.10A.1 目标
把 `learning_day` 作为与 `check_in`、`streak` 并行的独立事实落库，支撑：
- “签到成功但没有有效学习”
- “有有效学习但没有签到”
- 统计与 API 分离返回

## 7.10A.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | learning day fact ID |
| user_id | uuid fk -> users.id | 用户 |
| local_date | date not null | 用户自然日 |
| learning_day_status | varchar(16) not null | met |
| effective_attempt_count | int not null default 0 | 触发 learning day 的有效 attempts 数 |
| first_effective_attempt_at | timestamptz not null | 当日首次有效学习时间 |
| last_effective_attempt_at | timestamptz not null | 当日最近一次有效学习时间 |
| source_rule_snapshot | jsonb nullable | 形成 learning day 时采用的后端口径快照 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

## 7.10A.3 索引 / 约束
- `uk_learning_day_facts_user_date(user_id, local_date)`
- `idx_learning_day_facts_user_date(user_id, local_date desc)`
- `chk_learning_day_effective_attempt_count_positive`

## 7.10A.4 备注
- 本表只表达“该自然日 learning day 是否成立”；前端要展示 false 时，由服务层根据“无记录”返回。
- `learning_day` 与 `check_in` 不互相推出。
- 当前 MVP 不把 `learning_day` 直接拿来延续 `streak`；但该事实必须可独立读取。

---

# 7.11 `streak_records`

## 7.11.1 目标
记录连续事实的当前状态，并明确当前 MVP 下 `streak` 由 `check_in` 驱动。

## 7.11.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| user_id | uuid pk fk -> users.id | 用户 |
| current_streak | int not null default 0 | 当前连续天数 |
| max_streak | int not null default 0 | 历史最大连续天数 |
| streak_basis_type | varchar(32) not null default 'check_in' | 当前连续口径 basis，MVP 冻结为 check_in |
| last_counted_local_date | date nullable | 最近一次计入连续的自然日 |
| total_learning_days | int not null default 0 | 有效学习天数累计（由 learning_day_facts 聚合） |
| updated_at | timestamptz | 更新时间 |
| created_at | timestamptz | 创建时间 |

## 7.11.3 备注
- 当前 MVP **正式冻结** `streak_basis_type='check_in'`。
- `streak`、`check_in`、`learning_day` 三类事实故意拆开；未来若 Room 1 冻结为 learning-day-based，可迁移而不打断表结构。

---

# 7.12 `reward_source_events`

## 7.12.1 目标
统一承接所有“可触发奖励结算”的主机制来源事件。

## 7.12.2 为什么必须有
如果直接往 `reward_ledger` 发账：
- 无法表达“事件已成立，但奖励仍在结算中”
- 无法做补偿重放
- 无法稳定支撑 UI 的 `reward_settlement_status`

## 7.12.3 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | source event ID |
| user_id | uuid fk -> users.id | 用户 |
| source_event_type | varchar(32) not null | effective_new_word / effective_review / review_group_completed / daily_goal_completed / session_valid_completed / check_in / streak_node / mastery_milestone |
| source_ref_id | uuid nullable | 指向对应业务记录，例如 session / daily goal / check-in |
| local_date | date not null | 用户自然日 |
| source_payload | jsonb nullable | 来源快照 |
| settlement_status | varchar(32) not null | pending / settling / succeeded / failed / compensated |
| settlement_error_code | varchar(64) nullable | 失败码 |
| settlement_summary | jsonb nullable | 给结算层读取的轻摘要，不替代 reward_ledger |
| idempotency_key | varchar(128) not null | 奖励来源幂等键 |
| emitted_at | timestamptz not null | 事件产出时间 |
| settled_at | timestamptz nullable | 结算完成时间 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

## 7.12.4 索引 / 约束
- `uk_reward_source_events_user_idempotency(user_id, idempotency_key)`
- `uk_reward_source_events_unique_ref(user_id, source_event_type, source_ref_id) where source_ref_id is not null`
- `idx_reward_source_events_user_date(user_id, local_date, source_event_type)`
- `idx_reward_source_events_settlement(settlement_status, emitted_at)`

## 7.12.5 枚举建议
### `source_event_type`
- `effective_new_word`
- `effective_review`
- `review_group_completed`
- `daily_goal_completed`
- `session_valid_completed`
- `check_in`
- `streak_node`
- `mastery_milestone`

### `settlement_status`
- `pending`
- `settling`
- `succeeded`
- `failed`
- `compensated`

## 7.12.6 备注
- 页面级 `reward_settlement_status` 对应 `reward_source_events.settlement_status`。
- `source_event_type=check_in` 只代表签到事件本身，不代表有效学习日。
- `source_event_type=review_group_completed` 应指向 `review_groups.id`，同一 group 只能有一个完成来源事件。
- `settlement_summary` 允许结算层展示“本轮奖励摘要 / 可去看看变化”，但不代表账本已到账。

---

# 7.13 `reward_ledger`

## 7.13.1 目标
奖励账本；Coins / Fish Treats / EXP / 解锁类奖励的最终发放记录。

## 7.13.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | ledger item ID |
| user_id | uuid fk -> users.id | 用户 |
| source_event_id | uuid fk -> reward_source_events.id | 来源事件 |
| reward_type | varchar(32) not null | coins / fish_treat / exp / unlock |
| reward_item_code | varchar(64) not null | 具体奖励项编码 |
| reward_amount | numeric(12,2) not null | 数量 |
| status | varchar(32) not null | pending / succeeded / failed / compensated |
| balance_after | int nullable | 发放后余额快照（货币型可选） |
| applied_at | timestamptz nullable | 真正入账时间 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

## 7.13.3 索引 / 约束
- `idx_reward_ledger_user_status(user_id, status)`
- `idx_reward_ledger_user_applied(user_id, applied_at desc)`
- `uk_reward_ledger_unique_item(source_event_id, reward_type, reward_item_code)`

## 7.13.4 枚举建议
### `reward_type`
- `coins`
- `fish_treat`
- `exp`
- `unlock`

### `status`
- `pending`
- `succeeded`
- `failed`
- `compensated`

## 7.13.5 关键去重说明
同一 `source_event_id` + 同一奖励类型 + 同一奖励项编码，不可重复发放。

## 7.13.6 说明
- `reward_items[].reward_status` 对应本表 `status`。
- UI 禁止拿 `reward_ledger.status` 去替代页面级 `reward_settlement_status`，反之亦然。

---

# 7.14 `learning_stat_daily`

## 7.14.1 目标
为今日页、统计页、回放与核对提供每日汇总快照。

## 7.14.2 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | 主键 |
| user_id | uuid fk -> users.id | 用户 |
| local_date | date not null | 用户自然日 |
| new_word_count | int default 0 | 新词完成数 |
| effective_new_word_count | int default 0 | 有效新学数 |
| review_count | int default 0 | 复习数 |
| effective_review_count | int default 0 | 有效复习数 |
| valid_session_count | int default 0 | 有效 Session 数 |
| check_in_count | int default 0 | 签到次数（应≤1） |
| learning_day_count | int default 0 | learning day 成立次数（应≤1） |
| reward_source_event_count | int default 0 | 奖励来源事件数 |
| coins_issued | int default 0 | 当日发放金币 |
| fish_treats_issued | int default 0 | 当日发放小鱼干 |
| exp_issued | int default 0 | 当日发放 EXP |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

## 7.14.3 索引 / 约束
- `uk_learning_stat_daily_user_date(user_id, local_date)`

## 7.14.4 备注
- 统计页与今日页尽量共用事实来源，不做两套不同口径。

---

## 8. 状态机建议

# 8.1 新词学习状态（词级）

```text
unseen -> learning -> review_due -> reviewing -> mastered
```

### 触发原则
- 首次新学：`unseen -> learning`
- 达到进入复习条件：`learning -> review_due`
- 进入复习过程：`review_due -> reviewing`
- 满足掌握阈值：`reviewing -> mastered`

### 未冻结项
- 进入 mastered 的阈值未冻结。

---

# 8.2 复习队列状态

```text
pending -> in_progress -> done
pending -> skipped
```


# 8.2A `review_group` 状态

```text
active -> completed
active -> expired
active -> abandoned
```

### 触发原则
- 生成组后：`active`
- 组内 item 全部完成且服务端唯一确认后：`completed`
- 组在策略上失效后：`expired`
- 组被显式废弃后：`abandoned`

### 冻结边界
- `completed` 只表示组级完成，不自动等于今日复习完成。
- 同一用户不允许并行存在多个 `active` group。
- 同一 `review_group_id` 只能产生一次 `review_group_completed` 来源事件。

---

# 8.3 今日目标状态

```text
not_started -> in_progress -> partially_completed -> completed
```

### 当前建议
- `not_started`：新学/复习都未发生
- `in_progress`：已发生学习行为，但两类目标都未达到阶段完成
- `partially_completed`：至少一个核心维度达到阶段完成，但未满足“全部完成”
- `completed`：满足已冻结的“新词目标 + 复习要求”双因素口径

### 已冻结说明
- `completed` 只由新词目标与复习要求共同决定。
- `check_in_completed` 与 `valid_session_completed` 不参与 `goal_status` 判定。
- 当日无待复习内容时，复习要求自然满足。

---

# 8.4 Session 状态

```text
started -> ended -> validating -> valid
started -> ended -> validating -> invalid
```

### 当前建议
- `started`：开始计时
- `ended`：用户结束或计时结束
- `validating`：服务端根据实际学习行为校验
- `valid`：满足已冻结阈值
- `invalid`：不满足已冻结阈值

### 已冻结说明
- MVP 最低阈值：15 分钟 + 至少 5 次 effective attempts + started / ended 正常成立。
- `session_status` 与 `validation_status` 必须分开追踪。

---

# 8.5 奖励结算状态

```text
pending -> settling -> succeeded
pending -> settling -> failed -> compensated
```

### 当前建议
- 事件成立 ≠ 奖励已到账
- UI 可展示 “待补齐 / 失败待重试”，DB 必须可追踪
- 允许以 `settlement_summary` 提供轻量摘要，但不替代 `reward_ledger`

### 已冻结说明
- 结算层与到账层必须分开：
  - 来源事件层：`reward_source_events.settlement_status`
  - 账本层：`reward_ledger.status`

---

# 8.6 `check_in / learning_day / streak` 状态

### check_in
- 事实层只记录“这天是否签到成功”。
- 唯一口径：`(user_id, local_date)` 下最多一次成功签到。

### learning_day
- 以 `learning_day_facts` 表示“这天是否发生满足后端口径的有效学习”。
- 不依赖签到是否发生。

### streak
- 由服务层根据 `check_in_records` 更新 `streak_records`。
- 当前 MVP 正式冻结：
  - `streak_basis_type='check_in'`
  - `current_streak` 表示签到 streak
  - `total_learning_days` 表示有效学习天数累计

### 冻结边界
- 签到成功但无有效学习：允许 `check_in=true`、`learning_day=false`、`streak` 延续。
- 有有效学习但未签到：允许 `check_in=false`、`learning_day=true`、`streak` 不延续。

---

## 9. 幂等与去重策略

# 9.1 学习提交幂等
- 表：`study_attempts`
- 约束：`(user_id, idempotency_key)` unique
- 用途：防止重复点击“认识 / 不认识 / 提交答案”重复写入

# 9.2 复习组唯一性 / 组完成幂等
- 表：`review_groups` / `review_group_items` / `reward_source_events`
- 约束：
  - `uk_review_groups_single_active(user_id) where group_status='active'`
  - `uk_reward_source_events_unique_ref(user_id, source_event_type, source_ref_id)`
- 用途：保证同一用户同一时刻只有一个 active group，同一 group 完成只结算一次、不重复发奖

# 9.3 签到幂等
- 表：`check_in_records`
- 约束：`(user_id, local_date)` unique
- 用途：防止同一天重复签到

# 9.4 learning day 唯一性
- 表：`learning_day_facts`
- 约束：`(user_id, local_date)` unique
- 用途：保证同一自然日 learning day 只成立一次

# 9.5 奖励来源幂等
- 表：`reward_source_events`
- 约束：`(user_id, idempotency_key)` unique
- 用途：防止同一来源事件重复创建

# 9.6 奖励账本幂等
- 表：`reward_ledger`
- 约束：`(source_event_id, reward_type, reward_item_code)` unique
- 用途：防止同一来源重复发奖

# 9.7 Session 幂等
- `session_records.id` 为主 session 身份
- start / finish / validate 都必须有幂等语义
- start / finish 建议分别保留独立 idempotency key

---

## 10. 关键关系到 UI / API 的字段映射

| UI 使用名 | API 字段建议 | DB 来源 |
|---|---|---|
| `daily_goal_status` | `daily_goal.daily_goal_status` | `daily_goal_progress.goal_status` |
| `today_new_target` | `daily_goal.today_new_target` | `daily_goal_progress.target_new_count` |
| `today_new_completed` | `daily_goal.today_new_completed` | `daily_goal_progress.completed_new_count` |
| `today_review_target` | `daily_goal.today_review_target` | `daily_goal_progress.target_review_count` |
| `today_review_pending` | `daily_goal.today_review_pending` | `daily_goal_progress.pending_review_count_snapshot` 或 `review_queue` 聚合 |
| `today_review_completed` | `daily_goal.today_review_completed` | `daily_goal_progress.completed_review_count` |
| `review_group_id` | `review_group.review_group_id` | `review_groups.id` |
| `review_group_status` | `review_group.group_status` | `review_groups.group_status` |
| `group_completed` | `review_group.group_completed` | `review_groups.group_status='completed'` |
| `group_size_remaining` | `review_group.group_size_remaining` | `review_groups.group_size_total - review_groups.group_size_completed` |
| `has_checked_in_today` | `check_in.has_checked_in_today` | `check_in_records` / `daily_goal_progress.check_in_completed` |
| `has_learning_day_today` | `learning_day.has_learning_day_today` | `learning_day_facts` |
| `current_streak` | `check_in.current_streak` | `streak_records.current_streak` |
| `streak_basis_type` | `check_in.streak_basis_type` | `streak_records.streak_basis_type` |
| `session_valid_today` | `session.session_valid_today` | `daily_goal_progress.valid_session_completed` 或 `session_records` 聚合 |
| `session_started_today` | `session.session_started_today` | `session_records` 聚合 |
| `session_validation_status` | `session_validation_status` / `last_session_validation_status` | `session_records.validation_status` |
| `reward_settlement_status` | `last_reward_settlement.reward_settlement_status` 或 settlement API 返回字段 | `reward_source_events.settlement_status` |
| `reward_items[].reward_status` | `reward_items[].reward_status` | `reward_ledger.status` |
| `effective_learning_count` | `effective_learning_count` | `session_records.effective_learning_count` |
| `effective_review_count` | `effective_review_count` | `session_records.effective_review_count` |

> 说明：
> 1. 本表正式替换 v0.1 中的 `reward_settlement_last_status`、`reward_status` 等旧主叫法。
> 2. 若后续 API 局部字段名再微调，以 Room 1 pin 的 active API 为准，但 DB 主口径不再回退到旧命名。

---

## 11. 建议不在本稿强行落表的内容

以下内容本轮先不纳入 Room 2 DB 草案主范围：

1. 完整宠物域（`pet_cats`, `pet_inventory`, `pet_decor`）
2. 商店域
3. 文案库域
4. 运营活动域
5. 多词书并行学习的高级策略域

> 原因：当前主线程明确是先把主机制推进到 Dev-Ready，副机制承接只需要奖励来源与账本接口先可接。

---

## 12. Open Items / Risks / Trade-offs

# 12.1 当前 Open Items

### O-DB-001 完整 SRS / review priority / review_group 分组算法细节仍未冻结
- 影响：`review_group` 最小合同已冻结，但“组多大、如何选题、何时切下一组”仍不可在实现里补脑。
- 当前处理：保留 `review_queue`、`review_groups`、`review_group_items` 三层容器，算法后补。

### O-DB-002 熟练度 / 掌握阈值仍未冻结
- 影响：`mastered` 进入条件与里程碑仍需后续 BR / 数值继续收口。
- 当前处理：继续保留 `mastery_score / mastery_level / is_mastered`，但不冻结算法。

### O-DB-003 统计页是否进入下一轮极简规格尚未冻结
- 影响：`learning_stat_daily` 与 `learning_day_facts` 可能首版更多服务内部核对与 summary 查询。
- 当前处理：保留表，不反向扩大前台页面范围。

# 12.2 Major Risks

### R-DB-001 若 API 不同步升版，`review_group` / `learning_day` 会出现 DB 已写硬、API 仍口径偏薄的双轨
- 影响：Room 4 会继续在接口层手工补适配。
- 建议：Room 2 下一棒同步把 `API设计草案_v0.1.1.md` 升到 `v0.1.2`，吸收 `review_group` 与 `check_in / learning_day / streak` 分离返回。

### R-DB-002 若实现时把 `check_in`、`learning_day`、`streak` 混成一个布尔链路，后续规则升级会高成本返工
- 影响：Room 4 很难稳定测试“签到成功但 learning day 不成立”“learning day 成立但 streak 不延续”。
- 建议：严格以 `check_in_records`、`learning_day_facts`、`streak_records` 三层事实建模。

# 12.3 关键 Trade-off

### T-DB-001 为什么把 `review_group` 落成独立对象
- **方案 A：** 只保留 `study_attempts.review_group_id`，靠 attempt 临时推导。
- **方案 B：** 增加 `review_groups + review_group_items`。
- **选择：** 方案 B。
- **原因：** 当前 Room 1 已冻结“单用户单 active group”“组完成唯一结算”“允许跨 Session 继续”，若没有稳定 group 对象，Room 4 难以正确实现和测试。

### T-DB-002 为什么把 `check_in`、`learning_day`、`streak` 拆开
- **方案 A：** 认为三者可直接绑死。
- **方案 B：** 三者拆开，当前 streak 先按 `check_in` 驱动。
- **选择：** 方案 B。
- **原因：** 这与 Room 1 `D-OPP-001-011` 完全一致，并能最小化 MVP 返工成本。

---

## 13. 对 API / Room 4 的直接输入

当前 `API设计草案_v0.1.2.md`（下一棒建议升版）与 Room 4 `plan.md` / `TEST_PLAN` 应至少直接消费本稿以下表：

1. `study_attempts`
2. `user_word_progress`
3. `review_queue`
4. `review_groups`
5. `review_group_items`
6. `daily_goal_progress`
7. `session_records`
8. `check_in_records`
9. `learning_day_facts`
10. `streak_records`
11. `reward_source_events`
12. `reward_ledger`
13. `learning_stat_daily`

并至少围绕以下链路建立实现 / 测试：
- 学习记录提交
- 复习组读取 / 复习结果提交 / 本组完成
- 今日目标查询
- Session 开始 / 结束 / 校验 / 结算
- 签到
- learning day 聚合
- streak 更新
- 奖励结算
- 今日页聚合查询
- 统计查询（若保留）

---

## 14. Room 1 吸收建议（Main / Status）

建议 Room 1 在 Main / Status 吸收以下内容：

1. **Evidence**
   - Room 2 已交付 `DB设计草案_v0.1.3.md`，把 `D-OPP-001-010 / 011` 正式回写到 DB 单文件基线。

2. **Decision（建议待审）**
   - DB active pin 应由 `背单词喵喵app_DB设计草案_v0.1.2.md` 升到 `背单词喵喵app_DB设计草案_v0.1.3.md`。
   - DB 继续采用“事实表 + 聚合表 + review_group 稳定对象 + 奖励来源事件 + 奖励账本”的结构。

3. **Open Items**
   - 完整 SRS / review priority / review_group 分组算法细节
   - 熟练度 / 掌握阈值
   - 统计页是否补极简规格

4. **Next Action**
   - Room 2 继续把 API 升到 `v0.1.2`
   - Room 4 基于本稿更新 `plan.md` / `TEST_PLAN`

---

## 15. 给 Room 4 的实现提示

1. 先按本稿的状态字段和唯一键建模，不要先凭接口临时拼状态。
2. 奖励链路必须按 `reward_source_events -> reward_ledger` 两段实现，不要直接在学习接口里“顺手加余额”。
3. `study_attempts` 是幂等、防重、统计一致性的基础，不建议删。
4. `review_groups` 与 `review_group_items` 是本轮正式冻结后新增的稳定对象；不要再只靠 `study_attempts.review_group_id` 临时推导“当前组”。
5. `daily_goal_progress.goal_status` 只能服务端更新，不允许前端本地写死。
6. `session_records.validation_status` 与 `session_records.session_status` 必须分开。
7. 页面级 `reward_settlement_status` 与账本项级 `reward_items[].reward_status` 必须分开。
8. `check_in`、`learning_day`、`streak` 三类事实必须分层实现；当前 MVP 下 `streak_basis_type='check_in'`，不要在实现中默默切到 learning-day-based。

---

## 16. 结论

本稿在 `v0.1.2` 的 consolidated full 基底上，正式吸收了 Room 1 `D-OPP-001-010 / 011` 决策，现在可以作为 Room 2 的 **standalone consolidated full + decision write-back draft** 使用。

本稿已经稳定收口以下主状态与关键对象：
- `daily_goal_status`
- `session_validation_status`
- `reward_settlement_status`
- `review_group` 最小稳定对象
- `check_in / learning_day / streak` 三类独立事实

同时保住了主机制事实、队列、Session、签到、learning day、streak、奖励来源与奖励账本的可开发最小结构。

**当前判断：**
- 应升级为新的 active DB 候选基线
- 可直接作为 Room 4 的 DB 阅读入口
- 需要 Room 2 下一棒继续同步 API 升版
- 但仍有少量 open items 需要后续 BR / Room 1 继续收口，不应假装已经 Test-Ready / Release-Ready


---

## 17. P2 secondary mechanism incremental write-back（v0.1.4）

### 17.1 本轮 patch 定位
本轮不重写 `v0.1.3` 已稳定的主机制基线，只把 Room 4 在 `R4_P2_final_delivery_package_v0.1.md` 中已经落地并验证过的 **P2 minimum backend truth** 正式回写到 DB 技术基线。当前运行态仍以 Room 1 pin 的 active versions 为准，本稿只是新的 DB 候选基线。

### 17.2 本轮正式吸收的最小 secondary truth layer
以下对象现在正式进入 Room 2 DB baseline：

#### 17.2.1 `secondary_wallets`
**目标：** 为 `coins / fish_treats` 提供稳定的后端余额真相层，避免前端继续通过 `reward_ledger` 或本地历史临时相加。

| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | 主键 |
| user_id | uuid fk -> users.id | 用户 |
| available_coins | int not null default 0 | 当前可用金币 |
| available_fish_treats | int not null default 0 | 当前可用小鱼干 |
| lifetime_earned_coins | int not null default 0 | 累计获得金币 |
| lifetime_spent_coins | int not null default 0 | 累计消耗金币 |
| lifetime_earned_fish_treats | int not null default 0 | 累计获得小鱼干 |
| lifetime_spent_fish_treats | int not null default 0 | 累计消耗小鱼干 |
| source_version | bigint not null default 0 | 快照版本 / 乐观锁版本 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

**约束：** `uk_secondary_wallets_user(user_id)`；余额非负。

#### 17.2.2 `pet_profiles`
**目标：** 为 `cat_summary` 提供 pet-facing 持久状态，至少支撑 `level / total_exp / mood / bond / energy / nickname`。

| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | pet profile ID |
| user_id | uuid fk -> users.id | 用户 |
| pet_code | varchar(64) not null | 初始猫模板 / 品种编码 |
| nickname | varchar(64) nullable | 猫猫昵称 |
| total_exp | int not null default 0 | 当前累计 EXP |
| current_level | int not null default 1 | 当前等级 |
| mood_value | int not null default 0 | 心情值 |
| bond_value | int not null default 0 | 亲密度 |
| energy_value | int not null default 0 | 活力值 / 今日陪伴强度 |
| last_growth_feedback_at | timestamptz nullable | 最近一次成长反馈时间 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

**约束：** `uk_pet_profiles_user(user_id)`；数值非负。

#### 17.2.3 `pet_feed_events`
**目标：** 让 `feed` 变成真正的后端写事实，而不是纯前端表现。

| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | feed event ID |
| user_id | uuid fk -> users.id | 用户 |
| pet_profile_id | uuid fk -> pet_profiles.id | 宠物状态 |
| consumed_item_type | varchar(32) not null | fish_treat |
| consumed_amount | int not null default 1 | 本次消耗数量 |
| benefit_tier | varchar(32) not null | full / reduced / none |
| mood_delta | int not null default 0 | 心情变化 |
| exp_delta | int not null default 0 | EXP 变化 |
| bond_delta | int not null default 0 | 亲密度变化 |
| local_date | date not null | 用户自然日 |
| idempotency_key | varchar(128) not null | 幂等键 |
| balance_after_fish_treats | int nullable | 扣减后余额快照 |
| created_at | timestamptz | 创建时间 |

**约束：** `uk_pet_feed_events_user_idempotency(user_id, idempotency_key)`。

> 说明：当前 feed 数值（如 +4 mood / +2 exp / +1 bond、前三次 full）仍视为 **dev rules**，本稿只冻结“有服务端 benefit tier 与状态变化记录”，不冻结具体数值。

#### 17.2.4 `shop_catalog_items`
**目标：** 表达当前 MVP 的最小目录真相层，支撑购买 / 装备 / level lock。

| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | catalog item ID |
| item_code | varchar(64) unique | 稳定编码 |
| item_type | varchar(32) not null | outfit / room_item |
| slot_key | varchar(32) nullable | 槽位，如 hat / accessory / room_bg |
| display_name | varchar(128) not null | 展示名 |
| price_coins | int not null default 0 | 金币价格 |
| level_required | int not null default 1 | 等级门槛 |
| is_active | boolean not null default true | 是否上架 |
| sort_order | int not null default 0 | 排序 |
| item_payload | jsonb nullable | 轻量显示元数据 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

#### 17.2.5 `shop_purchase_events`
**目标：** 记录购买命令真相层，支撑扣币、防重、ownership 建立与审计。

| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | purchase event ID |
| user_id | uuid fk -> users.id | 用户 |
| catalog_item_id | uuid fk -> shop_catalog_items.id | 目录项 |
| purchase_status | varchar(32) not null | succeeded / failed / compensated |
| price_coins | int not null | 实际扣减金币 |
| balance_after_coins | int nullable | 扣减后余额快照 |
| failure_code | varchar(64) nullable | 失败码 |
| idempotency_key | varchar(128) not null | 幂等键 |
| purchased_at | timestamptz not null | 购买时间 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

#### 17.2.6 `user_inventory_items`
**目标：** 表达“用户已拥有”的最小真相层。

| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | inventory item ID |
| user_id | uuid fk -> users.id | 用户 |
| catalog_item_id | uuid fk -> shop_catalog_items.id | 对应目录项 |
| quantity | int not null default 1 | 当前拥有数量（MVP 通常=1） |
| ownership_status | varchar(32) not null default 'owned' | owned / revoked |
| source_purchase_event_id | uuid nullable fk -> shop_purchase_events.id | 来源购买事件 |
| acquired_at | timestamptz not null | 获得时间 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

#### 17.2.7 `user_equipment_slots`
**目标：** 表达已装备真相层，支撑 equipped preview 与 customize 三态 UI。

| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | equipment slot record ID |
| user_id | uuid fk -> users.id | 用户 |
| slot_key | varchar(32) not null | 装备槽位 |
| inventory_item_id | uuid nullable fk -> user_inventory_items.id | 当前装备物品 |
| equipped_at | timestamptz nullable | 装备时间 |
| created_at | timestamptz | 创建时间 |
| updated_at | timestamptz | 更新时间 |

**约束：** `uk_user_equipment_slots_user_slot(user_id, slot_key)`；同槽位同一时刻只允许一个 current equipped truth。

### 17.3 `secondary_summary` 读模型约定（不强制独立落表）
当前技术基线正式承认：P2 的 `secondary_summary` 是 **后端组合读模型**，至少应能稳定输出：
- `balances.coins`
- `balances.fish_treats`
- `balances.exp`
- `cat_summary`
- `companion_response`
- `equipped_preview`

推荐来源：`secondary_wallets + pet_profiles + user_equipment_slots + user_inventory_items + shop_catalog_items + check_in_records + learning_day_facts + streak_records + session_records`。

### 17.4 本轮冻结与不冻结边界
**本轮冻结：**
1. P2 当前余额与 pet state 必须以后端为准。
2. `feed / purchase / equip` 必须是后端命令，不是前端幻觉。
3. 当前可以表达“runtime truth 已能跨 restart 保存”，但**不能**把 file-backed JSON 当成 production-grade persistence 已完成。

**本轮不冻结：**
1. feed 数值、level thresholds、catalog 内容、copy 体系
2. interaction action
3. room coordinate placement / drag-drop domain
4. 多设备同步 / production DB migration 方案

### 17.5 本轮新增的幂等要求
1. `feed`：`(user_id, idempotency_key)` 必须唯一，避免重复扣鱼干、重复涨状态。
2. `purchase`：`(user_id, idempotency_key)` 必须唯一，避免重复扣币、重复写 ownership。
3. `equip / unequip`：以 `(user_id, slot_key)` 的单槽位目标态为准，不允许出现多条 current equipped truth。

### 17.6 本轮新增的 UI / API / DB 对齐重点
- `coins` → `secondary_wallets.available_coins`
- `fish_treats` → `secondary_wallets.available_fish_treats`
- `exp / level / mood / bond / energy` → `pet_profiles`
- `equipped_preview` → `user_equipment_slots + user_inventory_items + shop_catalog_items`
- `companion_response` → 后端读模型组合，不要求当前即有独立文案域

### 17.7 Room 1 吸收建议
1. 若接受 P2 closeout 证据，DB active pin 建议由 `背单词喵喵app_DB设计草案_v0.1.3.md` 升到 `背单词喵喵app_DB设计草案_v0.1.4.md`。
2. 本轮 DB write-back 不要求 Room 1 同时拍板 feed 数值、level thresholds、catalog 内容与 production persistence 方案。
3. 下一棒应由 Room 2 把 API 同步升到 `背单词喵喵app_API设计草案_v0.1.3.md`，保证 Room 4 closeout evidence 与技术 SSOT 同步。


## 18. P3.1 direct-scope delta incremental write-back（v0.1.5）

### 18.1 本轮 patch 定位
本轮 `v0.1.5` 不是 full DB rewrite，也不是把 P3.1 写成 cloud-first / full-sync-first。  
本轮只在 `v0.1.4` 的 consolidated single-file baseline 上，增量吸收 **P3.1 direct-scope delta round 已 close** 的 3 个功能对应技术契约：

1. `daily_goal` setting
2. manual upload / cloud backup
3. manual download-to-local / restore-apply first-shot

### 18.2 Room 2 总体判断
1. **当前需要新增 cloud backup container truth layer**
2. **当前需要新增 restore operation audit / safety layer**
3. **当前不需要把 local-first `daily_goal` setting 反向写成新的 server-authoritative runtime truth**
4. **当前不需要重写现有主机制事实层、奖励层、Session、签到、streak、review group 结构**

一句话：
> **本轮要加的是 backup lane 与 restore safety lane，不是重写主机制主事实层。**

### 18.3 新增 / 正式回写的最小 backup truth layer

#### 18.3.1 `user_backup_snapshots`
##### 目标
承载用户手动上传到云端 backup container 的 **全量 snapshot 元数据与 payload 引用**。  
它表达的是：
- upload success / upload failed
- latest backup metadata
- schema / checksum / payload size / source app version

它**不表达**：
- runtime truth 已切到云端
- full sync
- 多端自动一致

##### 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | 主键 |
| user_id | uuid fk -> users.id | 用户 |
| backup_id | varchar(64) not null | 稳定备份标识 |
| snapshot_scope | varchar(32) not null | `full_local_snapshot` |
| schema_version | varchar(32) not null | snapshot schema 版本 |
| snapshot_version | int not null | snapshot 版本号 |
| source_app_version | varchar(32) not null | 来源 app 版本 |
| source_device_label | varchar(64) nullable | 来源设备标记 |
| payload_storage_mode | varchar(16) not null | `inline_json` / `object_ref` |
| payload_blob | jsonb nullable | 内联 payload |
| payload_object_ref | text nullable | 对象存储引用 |
| payload_size_bytes | bigint not null | payload 大小 |
| checksum_algorithm | varchar(16) not null | 默认 `sha256` |
| checksum_value | varchar(128) not null | checksum 值 |
| upload_status | varchar(32) not null | `uploading` / `upload_succeeded` / `upload_failed` / `superseded` |
| restorable_hint | boolean default true | 结构上是否可进入 restore-precheck |
| upload_error_code | varchar(64) nullable | 上传失败码 |
| created_at | timestamptz | 创建时间 |
| uploaded_at | timestamptz nullable | 上传成功时间 |
| failed_at | timestamptz nullable | 上传失败时间 |
| updated_at | timestamptz | 更新时间 |

##### 索引 / 约束
- `uk_user_backup_snapshots_user_backup(user_id, backup_id)`
- `idx_user_backup_snapshots_user_created(user_id, created_at desc)`
- `idx_user_backup_snapshots_user_status(user_id, upload_status)`
- `chk_user_backup_snapshots_payload_mode`
- `chk_user_backup_snapshots_scope = full_local_snapshot`

##### 枚举建议
###### `upload_status`
- `uploading`
- `upload_succeeded`
- `upload_failed`
- `superseded`

##### 冻结边界
- `upload_status=upload_succeeded` 只表示上传成功
- 不等于 download success
- 不等于 restore / apply success
- 不等于 sync success
- 不等于 cloud runtime truth

---

#### 18.3.2 `backup_restore_operations`
##### 目标
记录 **manual-only** 的 restore 相关高风险动作审计轨迹。  
它的存在是为了把以下三类技术语义分层写硬：
1. pre-check
2. download completed
3. restore / apply success

##### 字段
| 字段 | 类型 | 说明 |
|---|---|---|
| id | uuid pk | 主键 |
| user_id | uuid fk -> users.id | 用户 |
| backup_snapshot_id | uuid fk -> user_backup_snapshots.id | 对应快照 |
| operation_type | varchar(32) not null | `restore_precheck` / `snapshot_download` / `restore_apply` |
| operation_status | varchar(32) not null | 见下 |
| target_scope | varchar(32) not null | `current_device_local_store` |
| target_device_label | varchar(64) nullable | 目标设备 |
| request_id | varchar(128) nullable | 请求追踪 ID |
| idempotency_key | varchar(128) nullable | 幂等键 |
| warning_presented | boolean default false | 是否展示 warning |
| confirm_overwrite | boolean default false | 是否显式确认覆盖 |
| schema_compatible | boolean nullable | schema 是否兼容 |
| checksum_verified | boolean nullable | checksum 是否通过 |
| payload_structurally_valid | boolean nullable | payload 是否结构有效 |
| blocked_reason_code | varchar(64) nullable | blocked 原因 |
| operation_error_code | varchar(64) nullable | 失败码 |
| created_at | timestamptz | 创建时间 |
| finished_at | timestamptz nullable | 完成时间 |
| updated_at | timestamptz | 更新时间 |

##### 索引 / 约束
- `idx_backup_restore_operations_user_created(user_id, created_at desc)`
- `idx_backup_restore_operations_snapshot(backup_snapshot_id, operation_type, created_at desc)`
- `idx_backup_restore_operations_request(request_id)`
- `idx_backup_restore_operations_idempotency(user_id, idempotency_key) where idempotency_key is not null`

##### 枚举建议
###### `operation_type`
- `restore_precheck`
- `snapshot_download`
- `restore_apply`

###### `operation_status`
- `requested`
- `ready`
- `blocked`
- `download_succeeded`
- `apply_succeeded`
- `failed`

##### 冻结边界
- `snapshot_download + download_succeeded` 只表示 **下载层动作** 成功
- 它本身**不改变**本地 runtime state
- 只有 `restore_apply + apply_succeeded` 才允许表达：
  - 当前本机本地持久化层已完成 apply
- `restore_apply` 当前必须满足：
  - manual only
  - warning presented = true
  - confirm_overwrite = true
  - schema_compatible = true
  - checksum_verified = true
  - payload_structurally_valid = true

---

### 18.4 `daily_goal` setting 的 DB 落点说明（本轮新增）
#### 18.4.1 Room 2 当前推荐
`daily_goal` 本轮继续保持：
- **设备侧 local settings lane 为 runtime truth**
- 云端通过 snapshot `settings.daily_goal` 承接
- restore apply 时，若用户确认覆盖，则允许把 snapshot 内的 `daily_goal` 一并恢复到当前本地设置层

#### 18.4.2 本轮刻意不做的事
本轮 `v0.1.5` **不新增** 独立 server-authoritative `daily_goal` 主真相表，也**不把**现有 `user_book_settings.daily_new_target` 直接改写成 P3.1 local-first daily goal 的唯一新真相源。

原因：
1. 当前 Room 1 pin 的是 **local-first + manual backup**
2. `daily_goal` setting 当前首先是设备侧显式设置动作
3. 若此时强行引入 server-authoritative 改写，会和本轮 local-first 立场冲突

#### 18.4.3 必须继续保持
- `daily_goal` 改动不影响：
  - `daily_goal_status`
  - `session_validation_status`
  - `check_in / learning_day / streak`
  - `streak_basis_type = check_in`
- 不回溯重算历史日

#### 18.4.4 当前级别
- `1–500` 当前仅作为 **Room 2 recommended validation range**
- 不自动升格为长期 frozen business rule

---

### 18.5 latest backup metadata（本轮正式回写）
当前 Room 2 推荐的 latest backup metadata 最小集合如下，并要求从 `user_backup_snapshots` 可直接读取：

- `backup_id`
- `created_at`
- `upload_status`
- `schema_version`
- `snapshot_version`
- `source_app_version`
- `payload_size_bytes`
- `checksum_algorithm`
- `checksum_value`
- `source_device_label`
- `restorable_hint`

### 18.5.1 说明
- `restorable_hint=true` 只表示结构上允许进入 pre-check
- 不等于最终一定 restore success
- 不等于当前本机可被静默覆盖

---

### 18.6 overwrite / checksum / versioning / restore safety（本轮正式回写）
#### 18.6.1 overwrite safety
- restore/apply 当前必须 manual only
- 必须先 pre-check
- 必须有 warning
- 必须有 confirm
- 未 `confirm_overwrite=true` 不得进入 apply success
- pre-check blocked 不得强行 apply

#### 18.6.2 checksum / payload validity
- `checksum_verified=false` → blocked
- `payload_structurally_valid=false` → blocked
- `schema_compatible=false` → blocked

#### 18.6.3 versioning
- `schema_version` 必须存在于 `user_backup_snapshots`
- restore path 必须先检查 schema compatibility
- 当前先按 `latest snapshot apply first-shot` 推荐路径设计
- 但 `latest-only restore` 当前仍属推荐实现路径，不自动升格为长期 frozen business rule

---

### 18.7 本轮继续明确不做
1. full sync
2. real-time sync
3. background sync
4. multi-device merge
5. partial restore
6. snapshot picker
7. delete backup
8. clear local
9. destructive actions bundle
10. history recompute for `daily_goal`

---

### 18.8 对 API / Room 4 的直接输入（P3.1 delta）
API v0.1.4 与 Room 4 当前应至少直接消费：

1. `user_backup_snapshots`
2. `backup_restore_operations`

并围绕以下链路建立实现 / 测试：
- manual upload
- latest backup metadata read
- restore-precheck
- snapshot download
- restore-apply
- `daily_goal` restore scope warning
- upload / download / restore success semantics 分层

---

### 18.9 Room 1 吸收建议（Main / Status）
建议 Room 1 在完成 review 后，若接受本稿：

1. **Evidence**
   - Room 2 已交付 `DB v0.1.5`，把 P3.1 direct-scope delta 已 close 的 backup / restore / daily_goal 相关 DB contract 正式回写进候选基线。

2. **Decision（建议待审）**
   - DB active pin 应由 `背单词喵喵app_DB设计草案_v0.1.4.md` 升到 `背单词喵喵app_DB设计草案_v0.1.5.md`。
   - 当前 DB 继续采用：
     - 主机制事实层
     - 奖励来源与账本
     - P2 secondary truth layer
     - P3.1 backup container + restore operation audit layer
   - 不把本轮写成 full sync DB baseline。

3. **Status**
   - `P3.1 delta round` 的 DB write-back 已完成，等待 Room 1 最终 pin active DB baseline。

---

### 18.10 结论
本稿在 `v0.1.4` 的 consolidated baseline 上，正式补齐了：
- cloud backup container truth layer
- restore operation audit / safety layer
- `daily_goal` 在 P3.1 local-first 路线下的 DB 边界说明
- latest backup metadata / overwrite / checksum / versioning / restore safety 的最小 DB contract

**当前判断：**
- 应升级为新的 active DB 候选基线
- 不需要重写主机制主事实层
- 已足够支撑 Room 1 判断是否更新 active DB baseline
