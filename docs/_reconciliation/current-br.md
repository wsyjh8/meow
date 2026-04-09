# 业务需求现状（代码反推）

> Phase 1 产出。完全从代码提取，未参考旧文档。
> 基准 commit: bface75

---

## 产品概述

"背单词喵喵"是一款将单词学习与虚拟猫养成结合的移动端应用。用户通过学新词、复习、完成每日目标来获得虚拟货币和经验，用于喂养和装扮虚拟猫。当前为单用户开发模式（dev-user-001），后端使用内存存储 + PG 持久化，移动端使用本地 SQLite + FSRS 间隔重复调度。

## 用户角色

- 唯一角色：学习者（单用户开发模式，硬编码 `DEV_USER_ID = 'dev-user-001'`）

---

## 主要业务模块

### 模块 1: 单词学习 [双端·差异]

**业务动作：** 获取新词、提交学习结果（认识/不认识）

**云端逻辑（dev-store.ts）：**

- `getNextNewWord()`:
  - 前置条件：`today_new_completed < today_new_target`（且 `today_new_target > 0`）
  - 排除条件：排除所有 `study_type === 'new' && action_result === 'know'` 的 word_id（已掌握词）
  - 标记为 `forgot` 的词**不排除**，会重新出现
  - 出词顺序：从 wordPool 中按数组顺序（PG 中按 `sort_order ASC`），返回第一个未掌握词
  - 词池来源：PG `words` 表（`book_id = 'book-001'`，按 `sort_order ASC`），PG 不可用时使用 5 个硬编码 fallback 词

- `submitStudyAttempt(wordId, bookId, studyType='new', actionResult, idempotencyKey)`:
  - 幂等性：通过 `x-idempotency-key` 头保障
  - 重复检测：同一 `word_id + study_type` 且 `action_result` 相同 → 返回 `alreadyExists: true`
  - 结果升级：同一 `word_id + study_type` 但 `action_result` 从 `forgot` → `know` → 允许更新，计为新完成
  - 当 `action_result === 'know'` 时触发：
    1. `today_new_completed += 1`
    2. 重新计算 `daily_goal_status`
    3. 创建 `effective_new_word` 源事件 → 触发奖励结算
    4. 更新 learning_day

**本地端逻辑（SessionBuilder + FsrsService）：**

- 新词通过 `SessionBuilder.buildTodaySession()` 混入学习队列
- 从 `cached_words` 表中选取不在 `card_states` 中的词（即从未见过的词）
- 选取数量 = `newCardsDailyLimit - countNewCardsToday()`，不超过 `newCardsDailyLimit`
- 选中的新词立即通过 `initCardForWord()` 创建 FSRS 卡片（state=Learning, due=now）
- `initCardForWord()` 是幂等的：已存在则返回现有卡片

**批量词库下载（words.controller.ts）：**

- `GET /api/v1/books/:bookId/words?offset=0&limit=500`
- `offset` 默认 0，`limit` 默认 500，最大 1000
- 移动端通过 `WordCacheService.downloadAndCacheBook()` 分页下载到本地 `cached_words` 表
- 使用 `INSERT OR REPLACE` 保证幂等

**业务规则：**

| 规则 | 条件 |
|------|------|
| 每日新词上限 | `today_new_completed >= today_new_target` 时停止出新词 |
| 默认每日目标 | `userDailyNewTarget = 20` |
| 目标范围 | `Math.max(1, Math.min(100, Math.floor(value)))` |
| 掌握判定 | `action_result === 'know'` |
| 未掌握重现 | `action_result === 'forgot'` 的词不从池中排除 |

---

### 模块 2: FSRS 记忆调度 [本地端]

**业务动作：** 初始化卡片、评分卡片、查询到期卡片、预览调度

**核心参数：**

- `desiredRetention = 0.9`（默认），可调范围 `[0.85, 0.95]`
- `learningSteps = [1分钟, 10分钟]`
- `relearningSteps = [10分钟]`

**卡片状态（CardStateData）：**

- `state`: 1=Learning, 2=Review, 3=Relearning
- `reps`: 连续正确次数，rating=again 时归零
- `lapses`: 遗忘次数，rating=again 时 +1

**`rateCard(wordId, rating)` 业务规则：**

- 原子事务（drift transaction）：
  1. 读取当前 card_state
  2. 快照 state-before（用于 review_log）
  3. 计算 FSRS 调度结果
  4. INSERT review_log（**不可变，永不更新/删除**）
  5. UPDATE card_state
- rating=again → `lapses++, reps=0`
- rating!=again → `reps++`

**`listDueCards(nowLocal, limit?)` 业务规则：**

- 条件：`card_states.due <= nowUtcMs`
- 排序：`due ASC`（最过期优先）
- limit 可选（用于 reviewCardsDailyLimit）

**`countNewCardsToday(nowLocal)` 业务规则：**

- 统计条件：`card_states.created_at >= todayStart && < todayEnd`（本地日历日 00:00~23:59:59）

**`previewSchedule(wordId)` 业务规则：**

- 对 4 种 rating 分别计算下次复习间隔
- 不持久化，仅用于 UI 显示

**数据导出：**

- `exportReviewLogsAsJsonl()`: 以 JSONL 格式导出 review_logs，用于 fsrs-optimizer

**四级评分映射（ReviewRating）：**

| 枚举值 | fsrs Rating | 用户文案 |
|--------|-------------|---------|
| again | Rating.again (1) | 不认识 |
| hard | Rating.hard (2) | 模糊 |
| good | Rating.good (3) | 想了一下才记起 |
| easy | Rating.easy (4) | 秒答 |

---

### 模块 3: 复习 [双端·差异]

**云端逻辑（dev-store.ts — naive review group）：**

- `getOrCreateReviewGroup()`:
  - 前置条件：同一时间只允许一个 `group_status === 'active'` 的 group
  - 已有 active group → 直接返回
  - 新建规则：从 wordPool 中筛选 `word_id.startsWith('word-r-')` 的词，取前 3 个
  - 组大小：固定 3（临时开发规则）
  - 创建后更新 today_state：`today_review_target = 1`, `today_review_pending = items.length`

- `submitReviewAttempt(reviewGroupId, wordId, actionResult, idempotencyKey)`:
  - group 不存在 → `success: false`
  - group 已完成 → `success: false, alreadyExists: true`
  - word 不在 group 中 → `success: false`
  - word 已完成 → `alreadyExists: true`
  - 正常提交 → 标记 `item.completed = true`
  - 全部完成时：`group_status = 'completed'`, `group_completed = true`, `today_review_completed += 1`
  - 当 `action_result === 'correct'` 时触发 `updateLearningDay()`
  - group 完成时触发 `review_group_completed` 源事件 → 奖励结算（有去重检查 `hasReviewGroupCompletedEvent`）

**本地端逻辑（FSRS 驱动）：**

- `SessionBuilder.buildTodaySession()`:
  1. 收集到期复习卡：`FsrsService.listDueCards(nowLocal, limit=reviewCardsDailyLimit)`
  2. 计算剩余新词配额
  3. 从 `cached_words` 选取新词候选
  4. 为新词初始化 FSRS 卡片
  5. 交错排列：复习:新词 = 3:1 比例 → `[R, R, R, N, R, R, R, N, ...]`
  6. 某一列表耗尽后直接追加剩余

- 复习评分通过 `FsrsService.rateCard()` 完成，使用 4 级评分

**云端 vs 本地差异汇总：**

| 维度 | 云端 | 本地端 |
|------|------|--------|
| 复习词选取 | `word_id.startsWith('word-r-')` 硬编码 | FSRS `due <= now` 到期队列 |
| 组大小 | 固定 3 | 无组概念，直接队列 |
| 评分系统 | 二元 correct/incorrect | 四级 again/hard/good/easy |
| 调度算法 | 无调度 | FSRS 间隔重复 |
| 交错 | 无 | 复习:新词 = 3:1 |

---

### 模块 4: 每日目标与签到 [双端·差异]

**每日目标（DailyGoalStatus 状态机）：**

- 状态转换规则：
  - `not_started` → 初始状态，`today_new_completed === 0 && today_review_completed === 0`
  - `in_progress` → `today_new_completed > 0 || today_review_completed > 0`，但两个子目标均未达成
  - `partially_completed` → `newGoalMet XOR reviewGoalMet`（仅一个子目标达成）
  - `completed` → `newGoalMet && reviewGoalMet`
- 子目标判定：
  - `newGoalMet = today_new_completed >= today_new_target`
  - `reviewGoalMet = today_review_completed >= today_review_target`
- 每日目标设置：
  - `PUT /api/v1/me/settings/daily-goal`
  - 范围校验：`Math.max(1, Math.min(100, Math.floor(value || 20)))`
  - 同时更新 PG `user_book_settings` 和内存 today_state
  - 修改后立即重算 `daily_goal_status`

**今日状态初始化（getTodayState）：**

- 按日期键（`YYYY-MM-DD`）存储
- 新日自动创建：
  - `today_new_target` = `userDailyNewTarget`（默认 20）
  - 从历史 `studyAttempts` 重算当日 `today_new_completed`（防跨日累积）
  - 如有活跃 review group → `today_review_target = 1`

**签到（CheckIn）[云端]：**

- `POST /api/v1/check-ins`，需 `x-idempotency-key`
- 每日最多一次签到（按 `local_date` 去重）
- 签到后：`streak.current_streak += 1`
- 签到状态：`check_in_status = 'succeeded'`
- 签到 != learning_day（两者独立事实）

**CTA 决策支持（today_primary_action）[云端]：**

- 优先级：
  1. `active_review_group_id` 存在且 `remaining > 0` → `continue_review_group`
  2. `today_review_pending > 0` → `go_review`
  3. `session_started_today && !session_valid_today` → `go_session`
  4. 默认 → `go_new_words`

**本地设置（LocalSettingsService）：**

| 设置项 | 键名 | 默认值 | 范围 |
|--------|------|--------|------|
| 每日目标 | settings_daily_goal | 20 | 整数 |
| 声音开关 | settings_sound_enabled | true | bool |
| 主题 | settings_theme | 'light' | string |
| 通知时间 | settings_notification_time | '09:00' | 'HH:mm' |
| FSRS 记忆保留率 | settings_desired_retention | 0.9 | [0.85, 0.95] |

---

### 模块 5: 学习会话 [云端]

**业务动作：** 开始会话、结束会话、查询会话状态

**`startSession(minutesTarget, idempotencyKey)`：**

- 幂等：通过 idempotency key 和 active session 检查
- 同一时间只允许一个 `session_status === 'started'` 的 session
- 默认 `session_minutes_target = 15`
- 初始状态：`session_status = 'started'`, `session_validation_status = 'pending'`

**`finishSession(sessionId, idempotencyKey)`：**

- 终态检查：如 session 已处于 `valid` 或 `invalid` → 返回 `alreadyExists: true`
- 计算有效学习数：session 开始后的 `study_type === 'new' && action_result === 'know'` 数量
- 计算有效复习数：session 开始后的 `action_result === 'correct'` 数量
- 状态链：`started → ended → validating → valid|invalid`

**MVP 验证规则：**

| 条件 | 阈值 |
|------|------|
| 时长 | `actualMinutes >= 15` |
| 有效尝试总数 | `effectiveLearningCount + effectiveReviewCount >= 5` |
| 验证结果 | 两者均满足 → `valid`；否则 → `invalid` |

**会话验证通过后：** 更新 `session_valid_today = true`

---

### 模块 6: 奖励结算 [云端]

**两层结构：**

1. **源事件层（RewardSourceEvent）：** 记录触发奖励的主机制事件
2. **奖励账本层（RewardLedgerItem）：** 具体奖励条目

**触发条件：**

| 源事件类型 | 触发时机 | 奖励 |
|-----------|---------|------|
| `effective_new_word` | `submitStudyAttempt` 且 `action_result === 'know'` | 2 coins + 1 exp |
| `review_group_completed` | review group 内所有 item completed（有 `hasReviewGroupCompletedEvent` 去重） | 5 coins + 1 fish_treat |

**结算流程：**

1. `createOrGetSourceEvent(type, refId, idempotencyKey)` → 创建或获取源事件
2. `createSettlement(sourceEventId, idempotencyKey)` → 创建结算记录 + 奖励条目
3. `reward_settlement_status` 在 dev 模式下直接设为 `'succeeded'`

**余额计算（getBalanceSnapshot）：**

- 遍历 `rewardLedgerItems`，只累计 `reward_status === 'succeeded'` 的条目
- `fish_treats` 扣除所有 `feedRecords` 的 `consumed_amount`
- `coins` 扣除 `coinsSpent`（商店购买累计）
- 所有余额 `Math.max(0, ...)`

**独立结算入口：**

- `POST /api/v1/settlements/learning-rounds`：可手动创建结算（接受 source_event_type + source_ref_id）

---

### 模块 7: 虚拟猫养成 [云端]

**猫咪基础信息：**

- `nickname = 'Mimi'`（硬编码）
- `baseMood = 60`
- `baseBond = 0`

**等级系统（computeLevelFromExp）：**

| 等级 | 累计 EXP 需求 |
|------|--------------|
| Lv.1 | 0 |
| Lv.2 | 20 |
| Lv.3 | 50 |
| Lv.4 | 90 |
| Lv.5 | 145 |
| Lv.6 | 215 |
| Lv.7 | 305 |
| Lv.8 | 420 |
| Lv.9 | 565 |
| Lv.10 | 745 |

- 等级上限：Lv.10
- `totalExp = balanceSnapshot.exp + feedExpAccumulated`

**属性计算规则（getCatSummary）：**

| 属性 | 计算公式 |
|------|---------|
| level | `computeLevelFromExp(totalExp)` |
| mood | `Math.min(100, baseMood + fish_treats * 5 + feedMoodAccumulated)` |
| bond | `balanceSnapshot.exp + feedBondAccumulated` |
| energy | `totalExp >= 20` → 'high'；`totalExp === 0` → 'medium'；其余 → 'medium' |

> energy 的逻辑 totalExp > 0 且 < 20 时也返回 'medium'，low 状态在当前代码中**不可达**。

**喂食（feedCat）[云端]：**

- 仅支持 `feed_item_type = 'fish_treat'`
- 每次消耗 1 fish_treat
- 前置条件：`balanceSnapshot.fish_treats >= 1`
- 反作弊：每日前 3 次喂食为完整收益，第 4 次及以后为衰减收益

| 喂食次序 | mood_delta | exp_delta | bond_delta |
|---------|-----------|-----------|-----------|
| 第 1-3 次 | +4 | +2 | +1 |
| 第 4+ 次 | +1 | 0 | 0 |

- 喂食后检测升级：`levelAfterFeed > levelBeforeFeed` → `leveledUp: true`

**伙伴回应（getCompanionResponse）[云端]：**

- `daily_greeting`: 根据条件从文案池中随机选择
  - `learningDayToday` → 学习相关问候（7 条）
  - `hasCheckedIn` → 签到相关问候（5 条）
  - 默认 → 通用问候（7 条）
- `post_learning_response`:
  - `sessionValidToday` → 专注时间相关（5 条）
  - `learningDayToday && dailyGoalStatus === 'completed'` → 完成相关（5 条）
  - `learningDayToday && (partially_completed || in_progress)` → 进行中鼓励（5 条）
  - 其余 → `null`
- `streak_node_response`:
  - 连续天数节点：`[3, 5, 7, 10, 14, 21, 30, 50]`
  - 命中节点时从对应文案池随机选择
  - 非节点天数 → `null`

---

### 模块 8: 商店/库存/装备 [云端]

**商品目录（catalog）：**

| item_id | item_type | slot | name | coin_price | required_level |
|---------|-----------|------|------|-----------|---------------|
| cat_hat_red | outfit | head | 红色小帽子 | 60 | 1 |
| cat_bow_blue | outfit | neck | 蓝色蝴蝶结 | 80 | 2 |
| cat_scarf_pink | outfit | neck | 粉色围巾 | 100 | 3 |
| room_lamp_warm | room_item | decor | 暖光小台灯 | 120 | 3 |
| room_rug_soft | room_item | floor | 柔软小地毯 | 150 | 4 |
| cat_hat_straw | outfit | head | 草编小草帽 | 90 | 2 |
| cat_bow_yellow | outfit | neck | 向日葵领结 | 110 | 3 |
| cat_scarf_stripe | outfit | neck | 条纹暖围巾 | 130 | 4 |
| room_plant_small | room_item | decor | 小盆栽绿植 | 100 | 2 |
| room_cushion_cloud | room_item | floor | 云朵小靠垫 | 140 | 3 |

所有商品 `is_active = true`。

**购买（purchaseItem）业务规则：**

| 检查顺序 | 条件 | 错误码 |
|---------|------|--------|
| 1 | 商品不存在或非 active | `ITEM_NOT_FOUND` |
| 2 | 已拥有（无堆叠） | `ITEM_ALREADY_OWNED` |
| 3 | `computeLevelFromExp(totalExp) < required_level` | `ITEM_LEVEL_LOCKED` |
| 4 | `balanceSnapshot.coins < coin_price` | `COINS_NOT_ENOUGH` |
| 通过 | `coinsSpent += coin_price`，创建 OwnedItem | succeeded |

**装备（equipItem）业务规则：**

| 检查顺序 | 条件 | 错误码 |
|---------|------|--------|
| 1 | 商品不在目录中 | `ITEM_NOT_FOUND` |
| 2 | 未拥有 | `ITEM_NOT_OWNED` |
| 通过 | 装备到对应 slot，替换该 slot 旧装备 | succeeded |

- 每个 slot 只能装备一件物品
- 装备时：新物品 `equipped = true`，同 slot 同 item_type 的旧物品 `equipped = false`
- 装备分类：`outfit` → `equippedOutfit[slot]`，`room_item` → `equippedRoom[slot]`

**卸装（unequipItem）业务规则：**

- 商品不在目录 → `ITEM_NOT_FOUND`
- 未拥有 → `ITEM_NOT_OWNED`
- 通过 → 对应 slot 设为 `null`，`equipped = false`

**库存读取：**

- `GET /api/v1/me/inventory` → `{ owned_items, coins_balance }`

---

### 模块 9: 备份与恢复 [双端·差异]

**云端备份容器（backup.controller.ts）：**

- `POST /api/v1/me/backup` — 上传快照
  - 接受 `{ snapshot, schema_version }` body
  - 校验：`snapshot` 必须是非空对象
  - 存储在内存（`_latestBackup`, `_backupSnapshot`），非持久化
  - 返回 `backup_id`, `uploaded_at`, `schema_version`

- `GET /api/v1/me/backup/latest` — 查询最新备份状态
  - 无备份时返回 `status: 'no_backup_yet'`

- `GET /api/v1/me/backup/latest/snapshot` — 获取完整快照（用于恢复）
  - 无备份时返回 `status: 'no_backup_found'`
  - 有备份时返回完整 snapshot JSON

**本地端服务链：**

- `SnapshotExportService` — 本地快照导出
- `BackupUploadService` — 上传快照到云端
- `BackupRestoreService` — 从云端下载并恢复
- `LocalProgressRepository` — 本地进度数据

> 备份是**备份容器**，不是同步系统。upload success != sync success。

---

## 主要业务流程

### 流程 1: 每日学习完整流程

1. **打开应用** → `GET /api/v1/me/today`
   - 调用 `updateLearningDay(today)` 刷新学习日状态
   - 返回 TodayState（含 daily_goal_status、签到状态、连续天数、CTA 建议、复习摘要）

2. **签到**（可选）→ `POST /api/v1/check-ins`
   - `streak.current_streak += 1`
   - `has_checked_in_today = true`

3. **学习新词** → `GET /api/v1/me/new-words/next` 获取下一个新词
   - 达到 `today_new_target` 时返回空

4. **提交学习结果** → `POST /api/v1/me/new-words`
   - `action_result = 'know'` → 计为有效，触发奖励结算（+2 coins, +1 exp）
   - `action_result = 'forgot'` → 不计为有效，该词后续重新出现

5. **获取复习组** → `GET /api/v1/me/review-groups/next`
   - 返回 active group 或创建新 group（3 词）

6. **提交复习结果** → `POST /api/v1/review-attempts`
   - 逐词提交 correct/incorrect
   - group 全部完成 → 触发奖励结算（+5 coins, +1 fish_treat）

7. **开始会话**（可选）→ `POST /api/v1/sessions`
   - 设定 session_minutes_target（默认 15 分钟）

8. **结束会话** → `POST /api/v1/sessions/:id/finish`
   - 验证：>= 15 分钟 AND >= 5 有效尝试 → valid
   - valid 后 → `session_valid_today = true`

9. **查看次要激励摘要** → `GET /api/v1/me/secondary-summary`
   - 返回余额、猫摘要、伙伴回应、装备预览、变化高亮、统计摘要

10. **喂猫**（可选）→ `POST /api/v1/me/feed`
    - 消耗 1 fish_treat，获得 mood/exp/bond 增长

### 流程 2: 本地学习会话构建流程（移动端）

1. `WordCacheService.ensureCached(bookId)` — 确保词库已缓存
2. `SessionBuilder.buildTodaySession(nowLocal, newCardsDailyLimit, reviewCardsDailyLimit?)`:
   a. 收集到期复习卡（FSRS `due <= now`）
   b. 计算今日剩余新词配额
   c. 从 cached_words 选取新词候选
   d. 为新词初始化 FSRS 卡片
   e. 交错排列（3:1 复习:新词比例）
3. 用户作答 → `FsrsService.rateCard(wordId, rating)` — 原子更新卡片 + 写入 review_log

### 流程 3: 购买与装备流程

1. `GET /api/v1/shop/catalog` — 查看商品目录
2. `POST /api/v1/shop/purchases` — 购买（校验 4 项条件）
3. `POST /api/v1/me/equipment/equip` — 装备物品
4. `POST /api/v1/me/equipment/unequip` — 卸装物品
5. `GET /api/v1/me/equipment` — 查看装备快照

### 流程 4: 备份与恢复流程

1. 本地导出快照（SnapshotExportService）
2. `POST /api/v1/me/backup` — 上传到云端备份容器
3. `GET /api/v1/me/backup/latest` — 查询备份状态
4. `GET /api/v1/me/backup/latest/snapshot` — 下载完整快照
5. 本地恢复（BackupRestoreService）

---

## 业务规则汇总

| # | 规则描述 | 代码条件 | 模块 |
|---|---------|---------|------|
| BR-01 | 每日新词上限 | `today_new_completed >= today_new_target` | 单词学习 |
| BR-02 | 默认每日目标 | `userDailyNewTarget = 20` | 目标设置 |
| BR-03 | 目标值范围 | `Math.max(1, Math.min(100, Math.floor(value)))` | 目标设置 |
| BR-04 | 已掌握排除 | `study_type === 'new' && action_result === 'know'` 的词排除 | 单词学习 |
| BR-05 | 未掌握重现 | `action_result === 'forgot'` 的词不排除 | 单词学习 |
| BR-06 | 结果升级允许 | 同 word_id 从 forgot→know 允许更新 | 单词学习 |
| BR-07 | 同一活跃 group | `reviewGroups.find(g => g.group_status === 'active')` 最多一个 | 复习 |
| BR-08 | 复习组大小 | 固定 3 | 复习 |
| BR-09 | 日目标完成判定 | `newGoalMet && reviewGoalMet` → completed | 每日目标 |
| BR-10 | 部分完成判定 | `newGoalMet XOR reviewGoalMet` → partially_completed | 每日目标 |
| BR-11 | 每日签到唯一 | 同 `local_date` 只允许一次 | 签到 |
| BR-12 | 签到 != 学习日 | 两者独立事实 | 签到 |
| BR-13 | 连续天数基于签到 | `streak_basis_type = 'check_in'`（当前 MVP） | 签到 |
| BR-14 | 会话验证-时长 | `actualMinutes >= 15` | 会话 |
| BR-15 | 会话验证-尝试数 | `effectiveLearning + effectiveReview >= 5` | 会话 |
| BR-16 | 会话同时只一个 | `session_status === 'started'` 最多一个 | 会话 |
| BR-17 | 有效新词奖励 | `action_result === 'know'` → 2 coins + 1 exp | 奖励结算 |
| BR-18 | 复习组完成奖励 | group 全完成 → 5 coins + 1 fish_treat | 奖励结算 |
| BR-19 | 奖励去重 | `hasReviewGroupCompletedEvent` 检查 | 奖励结算 |
| BR-20 | 余额不低于零 | `Math.max(0, ...)` | 余额 |
| BR-21 | 喂食前置条件 | `balanceSnapshot.fish_treats >= 1` | 喂食 |
| BR-22 | 喂食反作弊 | 每日前 3 次完整收益，第 4+ 次衰减 | 喂食 |
| BR-23 | 等级上限 | Lv.10 = 745 cumulative exp | 猫养成 |
| BR-24 | mood 上限 | `Math.min(100, ...)` | 猫养成 |
| BR-25 | 购买-等级锁 | `currentLevel < required_level` → ITEM_LEVEL_LOCKED | 商店 |
| BR-26 | 购买-余额不足 | `balance.coins < coin_price` → COINS_NOT_ENOUGH | 商店 |
| BR-27 | 购买-不可堆叠 | 已拥有 → ITEM_ALREADY_OWNED | 商店 |
| BR-28 | 装备-每 slot 一件 | 同 slot 新装备替换旧装备 | 装备 |
| BR-29 | 装备-须拥有 | 未拥有 → ITEM_NOT_OWNED | 装备 |
| BR-30 | 幂等性 | 所有写操作通过 `x-idempotency-key` 保障 | 全局 |
| BR-31 | 学习日判定 | `effectiveLearningCount > 0 \|\| effectiveReviewCount > 0` | 学习日 |
| BR-32 | FSRS 默认保留率 | `desiredRetention = 0.9` | FSRS |
| BR-33 | FSRS 保留率范围 | `[0.85, 0.95]`（clamp） | FSRS |
| BR-34 | review_log 不可变 | INSERT-ONLY，永不 update/delete | FSRS |
| BR-35 | 新词计数-当日隔离 | `created_at.startsWith(today)` 防跨日累积 | 单词学习 |
| BR-36 | 连续天数节点回应 | `[3, 5, 7, 10, 14, 21, 30, 50]` | 伙伴回应 |
| BR-37 | 本地交错比例 | 复习:新词 = 3:1 | 本地会话 |
| BR-38 | 批量词库分页 | 默认 limit=500，最大 1000 | 词库下载 |
| BR-39 | 备份非同步 | upload success != sync success | 备份 |

---

## Feature Guards

所有 feature guard 定义于 `P3FeatureGuard`（`p3_feature_guard.dart`），均为编译时 `static const bool`。

| Guard 名称 | 当前值 | 控制范围 |
|-----------|--------|---------|
| `isStatisticsPageEnabled` | **false** | 统计独立页面（路由 + 导航 + shell） |
| `isCTADecisionSupportEnabled` | **false** | CTA 决策支持块（today_primary_action） |
| `isStreakBasisSwitchEnabled` | **false** | 连续天数基准切换（learning_day-based streak） |
| `isReviewReadinessContractEnabled` | **false** | 复习就绪契约（deeper review_summary） |
| `isStreakExplanationEnabled` | **false** | 连续天数未来说明块 |
| `isLocalBackupEnabled` | **false** | 本地快照导出 |
| `isCloudBackupEnabled` | **false** | 云端备份上传 |
| `isRestoreEnabled` | **true** | 从备份恢复（含 pre-check + 确认对话框） |
| `isBackupSettingsEntryEnabled` | **false** | 备份设置入口可见性 |
| `isDailyGoalSettingEnabled` | **true** | 每日目标设置 UI |
| `isManualUploadEnabled` | **true** | 手动上传进度到云端 |
| `isDownloadToLocalEnabled` | **true** | 从云端下载进度到本地 |

---

## 枚举值汇总

### 状态枚举

| 枚举名称 | 允许值 |
|---------|--------|
| `DailyGoalStatus` | `'not_started'` \| `'in_progress'` \| `'partially_completed'` \| `'completed'` |
| `SessionStatus` | `'started'` \| `'ended'` \| `'validating'` \| `'valid'` \| `'invalid'` |
| `SessionValidationStatus` | `'pending'` \| `'valid'` \| `'invalid'` |
| `RewardSettlementStatus` | `'pending'` \| `'settling'` \| `'succeeded'` \| `'failed'` \| `'claimed'` |
| `RewardStatus` | `'pending'` \| `'succeeded'` \| `'failed'` |
| `CheckInStatus` | `'succeeded'` \| `'failed'` |
| `ReviewGroupStatus` | `'active'` \| `'completed'` |
| `DailyReviewProgressStatus` | `'not_started'` \| `'in_progress'` \| `'completed'` |
| `NextGroupReadiness` | `'ready'` \| `'not_ready'` |

### 业务类型枚举

| 枚举名称 | 允许值 |
|---------|--------|
| `StudyType` | `'new'` \| `'review'` |
| `StudyActionResult` | `'know'` \| `'forgot'` |
| `ReviewActionResult` | `'correct'` \| `'incorrect'` |
| `SourceEventType` | `'effective_new_word'` \| `'review_group_completed'` |
| `RewardType` | `'coins'` \| `'fish_treats'` \| `'exp'` |
| `FeedItemType` | `'fish_treat'` |
| `FeedResultStatus` | `'succeeded'` \| `'insufficient_resource'` |
| `CatalogItemType` | `'outfit'` \| `'room_item'` |
| `PurchaseResultStatus` | `'succeeded'` \| `'failed'` |
| `PurchaseErrorCode` | `'COINS_NOT_ENOUGH'` \| `'ITEM_ALREADY_OWNED'` \| `'ITEM_NOT_FOUND'` \| `'ITEM_LEVEL_LOCKED'` |
| `EquipResultStatus` | `'succeeded'` \| `'failed'` |
| `EquipErrorCode` | `'ITEM_NOT_OWNED'` \| `'ITEM_NOT_FOUND'` |
| `TodayPrimaryActionType` | `'continue_review_group'` \| `'go_review'` \| `'go_new_words'` \| `'go_session'` |
| `TodayPrimaryActionReason` | `'active_review_group'` \| `'review_due_priority'` \| `'new_words_remaining'` \| `'session_pending'` |
| `ChangeHighlightKind` | `'purchase'` \| `'equip'` \| `'growth'` \| `'streak'` \| `'post_learning'` |
| `ChangeHighlightStatus` | `'confirmed'` \| `'hinted'` |

### 本地端枚举

| 枚举名称 | 允许值 | 说明 |
|---------|--------|------|
| `ReviewRating` | `again` \| `hard` \| `good` \| `easy` | 本地 FSRS 评分 |
| `CardState (int)` | `1` = Learning \| `2` = Review \| `3` = Relearning | FSRS 卡片状态 |

### 状态转换

**SessionStatus 状态链：**

```
started → ended → validating → valid
                             → invalid
```

> `valid`/`invalid` 为终态，不可再变。

**DailyGoalStatus 状态转换：**

```
not_started → in_progress → partially_completed → completed
                          → completed (直接跳)
```

> 任何学习/复习活动均可能跳过中间状态。

**ReviewGroupStatus 状态转换：**

```
active → completed
```

> group 内所有 item.completed === true 时转换。

**RewardSettlementStatus（定义值）：**

```
pending → settling → succeeded
                   → failed
succeeded → claimed
```

> 当前 dev 模式中只使用 `succeeded`，其余状态在类型定义中保留但代码未实现转换路径。 -- TODO(待确认): `settling`, `failed`, `claimed` 在生产环境的完整转换逻辑。

---

## 待确认事项

- TODO(待确认): `StudyType = 'review'` 在类型中定义但云端 submitStudyAttempt 仅接受 `'new'`，本地端是否使用了 review 类型？
- TODO(待确认): `RewardSettlementStatus` 中 `'settling'`, `'failed'`, `'claimed'` 在代码中无转换路径，仅 `'succeeded'` 被使用
- TODO(待确认): `StreakRecord.streak_basis_type` 支持 `'learning_day'` 值，但当前 MVP 固定为 `'check_in'`，切换逻辑受 `isStreakBasisSwitchEnabled = false` 守卫
- TODO(待确认): `CatSummary.energy = 'low'` 在当前代码逻辑中不可达
- TODO(待确认): 云端 review group 词源筛选 `word_id.startsWith('word-r-')` 在 PG 词库中是否有匹配数据
- TODO(待确认): `today_review_target` 在新建 review group 时固定设为 1，含义是"完成 1 个 group"还是"完成 1 轮复习"
- TODO(待确认): 备份快照存储在内存中（`_latestBackup`），服务重启后丢失，是否有持久化计划
- TODO(待确认): `SessionBuilder` 中 `day boundary: local midnight 00:00` 注释提及 `TODO: configurable 4:00 AM`，当前未实现
- TODO(待确认): `sync_status` 在 TodayState 中硬编码为 `'healthy'`，实际同步机制未实现
