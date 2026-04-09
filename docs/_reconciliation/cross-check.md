# 四份文档交叉一致性检查

> Phase 4 产出。基于 v0.2.0 四份文档互相验证。
> 日期: 2026-04-08
> 基准 commit: bface75
> 对照文档: BR v0.2.0 / API v0.2.0 / DB v0.2.0 / UI SPEC v0.2.0

---

## 检查摘要

| 检查维度 | 发现数 | 严重 | 一般 | 信息 |
|----------|--------|------|------|------|
| 1. BR -> 实现映射 | 5 | 0 | 2 | 3 |
| 2. API 孤儿检查 | 4 | 0 | 2 | 2 |
| 3. DB 孤儿检查 | 4 | 0 | 1 | 3 |
| 4. UI -> 后端完整性 | 5 | 0 | 3 | 2 |
| 5. 双端一致性 | 8 | 1 | 4 | 3 |
| **合计** | **26** | **1** | **12** | **13** |

> 总体评价: 四份文档高度一致，均以同一 commit (bface75) 为基准重写。发现 1 项严重级别问题（daily_goal_status 枚举双端不一致），12 项一般问题（多为已知 tech debt 或双端差异），13 项信息级记录。无文档间自相矛盾的严重冲突。

---

## 1. BR -> 实现映射

### 1.1 已实现的 BR 功能

| BR 功能 (模块) | BR 编号 | API 端点 / 本地 Service | UI 页面 | DB 表 | 一致性 |
|---|---|---|---|---|---|
| 单词学习（云端） | BR-01~BR-10 | `GET /me/new-words/next`, `POST /me/new-words` | StudyPage | study_attempts, words | OK |
| 单词学习（本地） | BR-01~BR-10 | SessionBuilder, FsrsService | StudyPage (local-first) | word_records, card_states, cached_words | OK |
| 批量词库下载 | BR-38 | `GET /books/:bookId/words`, WordCacheService | 无直接 UI（后台下载） | words -> cached_words | OK |
| FSRS 记忆调度 | BR-32~BR-37 | FsrsService (7 methods) | FsrsRatingButtons [已开发.未集成] | card_states, review_logs | OK |
| 复习（云端） | BR-07~BR-08, RV-01~RV-06 | `GET /me/review-groups/next`, `POST /review-attempts` | ReviewPage | review_groups, review_group_items, review_attempts | OK |
| 复习（本地 FSRS） | RV-05~RV-06 | SessionBuilder.buildTodaySession, FsrsService.rateCard | [未集成到 ReviewPage] | card_states, review_logs | OK |
| 每日目标 | BR-09~BR-10, DG-01~DG-08 | `GET /me/today`, `PUT /me/settings/daily-goal`, LocalSettingsService | TodayPage, SpecHomePage, SettingsPage | daily_goal_progress, user_book_settings, SP:settings_daily_goal | OK |
| 签到 | BR-11~BR-13 | `POST /check-ins`, `GET /check-ins/today` | CheckInPage, TodayPage | check_in_records, streak_records | OK |
| 学习日 | BR-31 | `GET /me/today` (内部 updateLearningDay) | TodayPage (展示 learning_day_today) | learning_day_facts | OK |
| Session | BR-14~BR-16, SS-01~SS-04 | `POST /sessions`, `POST /sessions/:id/finish`, `GET /sessions/:id` | SessionPage | session_records | OK |
| 奖励结算 | BR-17~BR-20, RW-01~RW-05 | `POST /settlements/learning-rounds`, 内部自动触发 | TodayPage (展示), MeowHomePage (展示) | reward_source_events, reward_ledger, settlements | OK |
| 猫养成 | BR-21~BR-24, CAT-01~CAT-05 | `GET /me/secondary-summary`, `POST /me/feed` | MeowHomePage, SpecMochiPage | pet_profiles, secondary_wallets, feed_events | OK |
| 商店/购买 | BR-25~BR-27, SHOP-01~SHOP-03 | `GET /shop/catalog`, `POST /shop/purchases` | InventoryPage, CustomizePage | shop_catalog_items, inventory_items, purchase_records | OK |
| 装备/卸装 | BR-28~BR-29, SHOP-04~SHOP-05 | `POST /me/equipment/equip`, `POST /me/equipment/unequip`, `GET /me/equipment` | CustomizePage | equipment_slots, inventory_items | OK |
| 备份/恢复 | BR-39~BR-42, BK-01~BK-04 | `POST /me/backup`, `GET /me/backup/latest`, `GET /me/backup/latest/snapshot`, BackupUploadService, BackupRestoreService | SettingsPage | dev-store 内存 (_latestBackup) | OK |
| 幂等性 | BR-30 | X-Idempotency-Key (全写接口) | -- | idempotency_keys | OK |
| 伙伴回应 | BR-36 | `GET /me/secondary-summary` (内含 companionResponse) | TodayPage, MeowHomePage | -- (dev-store 运行时计算) | OK |
| Feature Guard | -- | P3FeatureGuard (12 flags) | SettingsPage, TodayPage | -- | OK |

### 1.2 未找到完整实现的 BR 功能

| BR 功能 | BR 来源 | 缺失侧 | 严重性 | 说明 |
|---|---|---|---|---|
| CTA winner 状态驱动 (SpecHomePage) | BR-009, PD-004 | UI | 一般 | BR 记录 `today_primary_action` 已开发未集成；API 有返回该字段；但 SpecHomePage 主 CTA 硬编码跳 `/study`，未接入状态机。TodayPage(Legacy) 保留了合约驱动。BR 已标注 `isCTADecisionSupportEnabled=false`。 |
| 统计页真实数据 | BR PD-005 | UI+API | 一般 | BR 标注 `isStatisticsPageEnabled=false`；API 无 `/me/stats/summary` 端点；UI SpecStatsPage 数据为 mock。三份文档均标注 Pending，一致。 |
| 结算浮层完整实现 | BR-004, BR-012 | UI | 信息 | BR 标注两段式奖励链路已实现，但 UI SettlementPage 为纯占位。ReviewPage 用 SnackBar 替代。四份文档均标注为占位/Pending。 |
| StudyPage 评分按钮最终方案 | BR TODO-10 | UI | 信息 | BR、API、UI 三份文档均标注为"暂定"。FSRS 4 按钮组件已开发未集成，当前使用 2 按钮。四文档一致。 |
| 签到节点奖励进 RewardLedger | BR PD-010 | API+DB | 信息 | BR 有 streak 节点文案回应 (CAT-05)，但节点奖励未接入奖励结算系统。四文档一致标注 Pending。 |

---

## 2. API 孤儿检查

### 2.1 云端 API 端点调用关系

| # | 端点 | 调用者 (UI / 本地 Service) | 状态 |
|---|---|---|---|
| 1 | `GET /health` | 运维/监控 | OK（非 UI 调用，合理） |
| 2 | `GET /me/new-words/next` | StudyPage -> StudyService -> ApiClient | OK |
| 3 | `POST /me/new-words` | StudyPage -> StudyService -> ApiClient (后台同步) | OK |
| 4 | `GET /me/review-groups/next` | ReviewPage -> ApiClient | OK |
| 5 | `POST /review-attempts` | ReviewPage -> ApiClient | OK |
| 6 | `GET /me/today` | SpecHomePage, SpecMochiPage, SpecStatsPage, TodayPage, MeowHomePage -> ApiClient | OK |
| 7 | `POST /sessions` | SessionPage -> ApiClient | OK |
| 8 | `POST /sessions/:id/finish` | SessionPage -> ApiClient | OK |
| 9 | `GET /sessions/:id` | SessionPage -> ApiClient | OK |
| 10 | `POST /check-ins` | CheckInPage -> ApiClient | OK |
| 11 | `GET /check-ins/today` | **ApiClient 未封装此方法** | 见下 |
| 12 | `POST /settlements/learning-rounds` | 内部自动触发（submitStudyAttempt/submitReviewAttempt 内部调用）；**ApiClient 未封装** | 见下 |
| 13 | `GET /settlements/:sourceEventId` | **ApiClient 未封装** | 见下 |
| 14 | `GET /me/secondary-summary` | SpecHomePage, SpecMochiPage, SpecStatsPage, SpecProfilePage, TodayPage, MeowHomePage -> ApiClient | OK |
| 15 | `POST /me/feed` | MeowHomePage -> ApiClient | OK |
| 16 | `GET /shop/catalog` | CustomizePage, InventoryPage -> ApiClient | OK |
| 17 | `POST /shop/purchases` | CustomizePage, InventoryPage -> ApiClient | OK |
| 18 | `GET /me/inventory` | CustomizePage, InventoryPage -> ApiClient | OK |
| 19 | `GET /me/equipment` | CustomizePage -> ApiClient | OK |
| 20 | `POST /me/equipment/equip` | CustomizePage -> ApiClient | OK |
| 21 | `POST /me/equipment/unequip` | **ApiClient 未封装** | 见下 |
| 22 | `PUT /me/settings/daily-goal` | SettingsPage -> ApiClient | OK |
| 23 | `POST /me/backup` | SettingsPage -> BackupUploadService | OK |
| 24 | `GET /me/backup/latest` | **ApiClient 未封装**（BackupRestoreService 直接 HTTP） | OK（Service 层调用） |
| 25 | `GET /me/backup/latest/snapshot` | SettingsPage -> BackupRestoreService | OK |
| 26 | `GET /books/:bookId/words` | WordCacheService（直接 HTTP，不走 ApiClient） | OK |

### 2.2 疑似孤儿端点

| 端点 | 问题 | 严重性 | 说明 |
|---|---|---|---|
| `GET /check-ins/today` (API-011) | ApiClient 未封装，UI 未直接调用 | 一般 | API 文档标注"ApiClient 未封装"。CheckInPage 通过 POST /check-ins 返回值获取签到状态，TodayPage 通过 GET /me/today 间接获取。此端点可被直接 HTTP 调用，但无 Flutter 侧包装。可能为开发期预留。 |
| `POST /me/equipment/unequip` (API-021) | ApiClient 未封装 | 一般 | API 文档标注"ApiClient 未封装"。CustomizePage 代码中有 equip 但未见 unequip UI 按钮。DB 有 equipment_slots 支持。UI SPEC 中 CustomizePage 交互列表无卸装操作。 |
| `POST /settlements/learning-rounds` (API-012) | ApiClient 未封装，仅内部触发 | 信息 | 此端点为独立结算入口。正常流程中由 submitStudyAttempt/submitReviewAttempt 内部自动触发。作为可选的手动补偿入口存在是合理的。 |
| `GET /settlements/:sourceEventId` (API-013) | ApiClient 未封装 | 信息 | 查询结算详情端点，开发/调试用途。不影响核心业务。 |

### 2.3 本地端 Service 调用关系

| Service | 调用者 (UI) | 状态 |
|---|---|---|
| StudyService | StudyPage | OK |
| FsrsService | **未被任何 UI 页面直接调用** | 已知 -- [已开发.未集成] |
| SessionBuilder | **未被任何 UI 页面直接调用** | 已知 -- [已开发.未集成] |
| WordCacheService | **未被任何 UI 页面直接调用** | 已知 -- 后台服务，无直接 UI 入口 |
| LocalSettingsService | SettingsPage, SpecProfilePage | OK |
| LocalProgressRepository | BackupUploadService (间接) | OK |
| LocalDatabase | StudyService (间接) | OK |
| AppDatabase (drift) | FsrsService, SessionBuilder, WordCacheService (间接) | OK |

> FsrsService / SessionBuilder / WordCacheService 未被 UI 直接调用属于已知状态（FSRS 未集成到 StudyPage/ReviewPage），四份文档均一致标注。

---

## 3. DB 孤儿检查

### 3.1 云端表使用状态

| 表 | 被哪些 API 端点 / 业务逻辑使用 | 状态 |
|---|---|---|
| users | 全局 (dev-user-001 硬编码) | OK |
| word_books | GET /books/:bookId/words, GET /me/today (current_book_name) | OK |
| words | GET /me/new-words/next, GET /books/:bookId/words | OK |
| user_book_settings | PUT /me/settings/daily-goal, GET /me/today (today_new_target) | OK |
| study_attempts | POST /me/new-words, sessions/finish (有效学习计数) | OK |
| user_word_progress | **PG 已建表，DevStore 未直接使用** | 见下 |
| review_groups | GET /me/review-groups/next, POST /review-attempts | OK |
| review_group_items | GET /me/review-groups/next | OK |
| review_attempts | POST /review-attempts, sessions/finish (有效复习计数) | OK |
| daily_goal_progress | GET /me/today (今日目标聚合) | OK |
| session_records | POST /sessions, POST /sessions/:id/finish, GET /sessions/:id | OK |
| check_in_records | POST /check-ins, GET /check-ins/today | OK |
| learning_day_facts | GET /me/today (updateLearningDay) | OK |
| streak_records | POST /check-ins (streak 更新), GET /me/today | OK |
| reward_source_events | submitStudyAttempt/submitReviewAttempt 内部触发 | OK |
| reward_ledger | settlements 流程, getBalanceSnapshot | OK |
| settlements | POST /settlements/learning-rounds | OK |
| idempotency_keys | 全局写接口 | OK |
| secondary_wallets | getBalanceSnapshot, feedCat | OK |
| pet_profiles | getCatSummary | OK |
| feed_events | POST /me/feed, getBalanceSnapshot (fish_treats 扣除) | OK |
| shop_catalog_items | GET /shop/catalog, purchaseItem, equipItem | OK |
| inventory_items | GET /me/inventory, purchaseItem, equipItem | OK |
| equipment_slots | GET /me/equipment, equipItem, unequipItem | OK |
| purchase_records | POST /shop/purchases (审计记录) | OK |

### 3.2 本地端表使用状态

| 表 | 被哪些 Service / UI 使用 | 状态 |
|---|---|---|
| word_records | StudyService, LocalDatabase, SnapshotExportService | OK |
| wordbook_progress | LocalProgressRepository, SnapshotExportService | OK |
| daily_checkins | LocalProgressRepository, SnapshotExportService | OK |
| custom_wordbooks | LocalProgressRepository, SnapshotExportService | OK |
| vocabulary_notebook | LocalProgressRepository, SnapshotExportService | OK |
| card_states | FsrsService, SessionBuilder | OK ([已开发.未集成]) |
| review_logs | FsrsService (INSERT-ONLY) | OK ([已开发.未集成]) |
| cached_words | WordCacheService, SessionBuilder | OK ([已开发.未集成]) |

### 3.3 孤儿表 / 孤儿字段

| 表/字段 | 端 | 问题 | 严重性 | 说明 |
|---|---|---|---|---|
| `user_word_progress` (整表) | 云端 | PG migration 已建表，但 DevStore 运行态从未读写此表 | 一般 | DB 文档已标注："当前 PG migration 已建表，但 DevStore 运行态未直接使用此表。熟练度/掌握阈值算法仍未冻结。" BR PD-003 同样标注 Pending。四文档一致。 |
| `words.word_type` | 云端 | `study_type = 'review'` 在 submitStudyAttempt 中未实际使用 | 信息 | BR TODO-09 已标注。word_type 字段用于区分 new/review 词条，review 词条供 review_groups 使用（`word-r-*` 前缀筛选），但 submitStudyAttempt 的 study_type 参数始终传 'new'。 |
| `words.definition`, `words.tags`, `words.word_forms` | 云端 | 002 migration 添加的富元数据字段，API 返回但 UI 未展示 | 信息 | API GET /me/new-words/next 返回这些字段，但 StudyPage 仅展示 wordText + phonetic + meaning。作为 CET-4 扩展数据合理存在。 |
| `daily_checkins` (本地) vs `check_in_records` (云端) | 双端 | 本地 daily_checkins 表存在但 CheckInPage 直接走云端 API，本地签到表仅在 backup/restore snapshot 中使用 | 信息 | 本地 daily_checkins 在 LocalProgressRepository 中通过 SharedPreferences 维护（非 SQLite 直接查询），作为 snapshot 一部分备份。与云端 check_in_records 非实时同步。属于 local-first + backup 架构的预期行为。 |

---

## 4. UI -> 后端完整性

### 4.1 UI 交互与后端对应关系

| 页面 | 交互 | 对应 API / Service | 对应 DB | 状态 |
|---|---|---|---|---|
| SpecHomePage | "继续学习" CTA | -> `/study` (静态) | -- | OK（但未接入 today_primary_action 状态驱动） |
| SpecHomePage | 下拉刷新 | GET /me/today + GET /me/secondary-summary | dev-store | OK |
| SpecHomePage | "5 分钟快速复习" | -> `/review` | -- | OK |
| SpecMochiPage | "学单词，赚小鱼干" CTA | -> `/study` | -- | OK |
| SpecStatsPage | 12 周热力图 | GET /me/secondary-summary.statsSummary | -- | **数据为 mock** |
| SpecStatsPage | 记忆率 82% | -- | -- | **硬编码** |
| SpecProfilePage | "每日新词数量" | -> `/settings` | SP:settings_daily_goal | OK |
| TodayPage | 主 CTA (合约驱动) | today_primary_action -> /study or /review or /session | dev-store | OK |
| TodayPage | 签到区域 | -> `/check-in` | check_in_records | OK |
| StudyPage | "掌握"/"模糊" 按钮 | StudyService -> SQLite + API | word_records, study_attempts | OK |
| ReviewPage | "正确"/"忘记" 按钮 | ApiClient -> POST /review-attempts | review_attempts | OK |
| SessionPage | 开始/结束 Session | POST /sessions, POST /sessions/:id/finish | session_records | OK |
| CheckInPage | "立即签到" 按钮 | POST /check-ins | check_in_records, streak_records | OK |
| MeowHomePage | "喂小鱼干" 按钮 | POST /me/feed | feed_events, secondary_wallets | OK |
| MeowHomePage | "装扮与小窝" | -> `/customize` | -- | OK |
| MeowHomePage | "收藏与商店" | -> `/inventory` | -- | OK |
| CustomizePage | "购买" 按钮 | POST /shop/purchases | purchase_records, inventory_items | OK |
| CustomizePage | "装备" 按钮 | POST /me/equipment/equip | equipment_slots | OK |
| InventoryPage | "购买" 按钮 | POST /shop/purchases | purchase_records, inventory_items | OK |
| SettingsPage | 每日目标设置 | LocalSettingsService + PUT /me/settings/daily-goal | SP + user_book_settings | OK |
| SettingsPage | 记忆保留率设置 | LocalSettingsService | SP:settings_desired_retention | OK |
| SettingsPage | "立即备份" | SnapshotExportService + POST /me/backup | dev-store 内存 | OK |
| SettingsPage | "恢复备份" | BackupRestoreService + GET /me/backup/latest/snapshot | dev-store 内存 | OK |

### 4.2 UI 缺失后端支持的交互

| 页面 | 交互 | 问题 | 严重性 | 说明 |
|---|---|---|---|---|
| SpecStatsPage | 热力图、记忆率、掌握词数等 | 数据为 mock/硬编码，无真实数据 API | 一般 | API 无 `/me/stats/summary` 端点。API 文档 PD-007、BR PD-005 均标注 Pending。`isStatisticsPageEnabled=false`。SpecStatsPage 从 secondary-summary.statsSummary 获取部分数据，但 statsSummary 本身在 API 响应中内容有限。 |
| SpecHomePage | 主 CTA 状态驱动 | CTA 硬编码跳 `/study`，未接入 `today_primary_action` | 一般 | API 已返回 `today_primary_action` 字段，DB 已支持。BR 已标注 `isCTADecisionSupportEnabled=false`。TodayPage(Legacy) 有合约驱动实现，SpecHomePage 尚未接入。四文档一致。 |
| CustomizePage | 卸装操作 | UI 无卸装按钮 | 一般 | API 有 `POST /me/equipment/unequip` 端点且已实现，DB equipment_slots 支持。但 UI CustomizePage 交互列表中无卸装操作（已装备物品无操作按钮）。API 文档标注 "ApiClient 未封装"。 |
| SpecMochiPage | 4 个次级入口 (换装/房间/零食柜/日记) | 均为 debugPrint 占位 | 信息 | UI 文档已标注。换装 -> 可映射到 /customize，零食柜 -> 可映射到 /inventory，但当前为占位。 |
| SpecProfilePage | 多个 debugPrint 占位入口 | 个人编辑、切换词书、复习算法、学习提醒、发音、导出学习记录、帮助与反馈 | 信息 | UI 文档已标注。均为后续功能预留。 |

---

## 5. 双端一致性

### 5.1 相同用途表的字段对照

#### 学习记录: `study_attempts` (云端) vs `word_records` (本地)

| 字段 | 云端 study_attempts | 本地 word_records | 一致性 |
|---|---|---|---|
| 主键 | VARCHAR(64) id | INTEGER AUTOINCREMENT id | OK（技术差异） |
| 用户 | user_id FK | -- (单用户隐含) | OK |
| 单词 | word_id FK | word_id TEXT | OK |
| 词书 | book_id FK | book_id TEXT | OK |
| 学习类型 | study_type VARCHAR(16) | study_type TEXT DEFAULT 'new' | OK |
| 结果 | action_result VARCHAR(16) | action_result TEXT | OK |
| 时间 | created_at TIMESTAMPTZ | created_at TEXT (ISO 8601) | OK（格式不同但兼容） |
| 同步标记 | -- | **synced INTEGER DEFAULT 0** | OK（本地专用字段） |

> 结论: 字段语义一致，本地多一个 `synced` 标记用于异步同步追踪，属于 local-first 架构预期设计。

#### 复习记录: `review_attempts` (云端) vs `review_logs` (本地)

| 维度 | 云端 review_attempts | 本地 review_logs | 差异 |
|---|---|---|---|
| 记录模型 | group-based (review_group_id) | card-based (card_state_id) | **不同模型** |
| 评分 | binary (correct/incorrect) | 4-level (again/hard/good/easy) | **不同评分** |
| 调度 | 无调度（naive group） | FSRS 间隔重复 | **不同算法** |
| 不可变性 | -- | INSERT-ONLY | 本地更严格 |
| 额外元数据 | -- | elapsed_days, scheduled_days, state_before, stability_before, difficulty_before | 本地更丰富 |

> 结论: 这两张表是**不同复习系统**的记录，不是同一系统的双端映射。BR 4.3.3 明确列出了云端 vs 本地差异。四文档一致。

#### 签到: `check_in_records` (云端) vs `daily_checkins` (本地)

| 字段 | 云端 check_in_records | 本地 daily_checkins | 一致性 |
|---|---|---|---|
| 日期 | local_date DATE | date TEXT | OK（语义一致） |
| 状态 | status VARCHAR(16) | checked_in INTEGER | 简化（本地只有 1=已签到） |

> 结论: 本地签到表为简化版本。当前 CheckInPage 直接走云端 API，本地表仅在 snapshot 中使用。

#### 词库缓存: `words` (云端) vs `cached_words` (本地)

| 字段 | 云端 words | 本地 cached_words | 一致性 |
|---|---|---|---|
| word_id | id VARCHAR(64) | word_id TEXT PK | OK |
| book_id | book_id FK | book_id TEXT | OK |
| word_text | word_text VARCHAR(200) | word_text TEXT | OK |
| meaning | meaning TEXT | meaning TEXT | OK |
| phonetic | phonetic VARCHAR(200) | phonetic TEXT | OK |
| translation | translation TEXT | translation TEXT | OK |
| frequency_rank | frequency_rank INT | frequency_rank INTEGER | OK |
| sort_order | sort_order INT | sort_order INTEGER | OK |
| definition | definition TEXT | **缺失** | 见下 |
| difficulty_level | difficulty_level INT | **缺失** | 见下 |
| is_core | is_core BOOLEAN | **缺失** | 见下 |
| tags | tags TEXT | **缺失** | 见下 |
| word_forms | word_forms TEXT | **缺失** | 见下 |
| word_type | word_type VARCHAR(32) | **缺失** | 见下 |
| cached_at | -- | cached_at INTEGER | 本地专用 |

> 结论: cached_words 缺少 `definition`, `difficulty_level`, `is_core`, `tags`, `word_forms`, `word_type` 6 个字段。这些字段是 002 migration 添加的 CET-4 富元数据。当前 SessionBuilder 只需 word_id/word_text/meaning/sort_order 来构建会话，缺失字段**不影响当前功能**。但如果未来 UI 需要展示这些富数据（如难度标签、词形变化），cached_words 需要扩展。

### 5.2 双端不一致发现

| # | 发现 | 相关文档 | 严重性 | 说明 |
|---|---|---|---|---|
| DC-01 | `daily_goal_status` 枚举值不一致 | BR 7.1 vs API 3.9 | **严重** | BR 7.1 枚举表列出 4 个值: `not_started / in_progress / partially_completed / completed`。API 3.9 明确标注: "旧文档中的 `partially_completed` 已不存在于代码中"，仅列 3 个值: `not_started / in_progress / completed`。但 BR 4.4.1 又详细描述了 `partially_completed` 的转换规则，BR 6.0 汇总表 BR-10 也引用了 `partially_completed`。**BR 自身在枚举列表(7.1)和规则描述(4.4.1)中包含 `partially_completed`，但 API 文档声明此值已不存在。** DB daily_goal_progress 表的 goal_status 枚举也包含 `partially_completed`。需要确认代码实际行为：是 BR 遗留了旧值，还是 API 文档遗漏了此值。 |
| DC-02 | 每日目标范围双端不一致 | BR WL-03/WL-04, API 3.9 | 一般 | 云端 clamp 到 [1, 100]，本地设置页允许 [1, 500]。BR 已标注为 Assumption 且列入 TODO-01 / PD-006。API 文档 API-022 确认云端 clamp [1, 100]。UI 文档 4.14 确认"弹出输入对话框（范围 1-500）"。四文档对此不一致均有记载，但未修正。 |
| DC-03 | 云端复习评分 vs 本地端复习评分 | BR 4.3.3, API 4.3/5.2 | 一般 | 云端: binary correct/incorrect（2 值），通过 review_group 机制。本地: 4-level again/hard/good/easy，通过 FSRS。BR 4.3.3 明确列出差异表。四文档一致。属于已知 tech debt，收敛方向待定 (BR TODO-11)。 |
| DC-04 | `cached_words` 缺少 6 个云端 `words` 字段 | DB 6.8 vs DB 4.3 | 一般 | 见 5.1 详细对照。cached_words 下载逻辑（WordCacheService）从 API 获取完整 word 对象但只存部分字段到本地。如果 API 返回了 definition/tags 等字段但本地未存储，属于客户端选择性缓存。当前不影响功能。 |
| DC-05 | 备份 snapshot 不含 FSRS 数据 | DB 9.3, API 6.2 | 一般 | 备份 snapshot schema `p3_1_snapshot_v2` 包含: settings + progress (word_records, wordbook_progress, daily_checkins, custom_wordbooks, vocabulary_notebook)。不包含 FSRS 表 (card_states, review_logs) 和 cached_words。BR BK-01~BK-04 和 API 6.2 均描述了此 scope。如果用户重度使用 FSRS（待集成），恢复备份后 FSRS 状态会丢失。当前因 FSRS 未集成到 UI 所以不影响。 |

### 5.3 云端独有表分析

| 云端表 | 是否应有本地对应 | 说明 |
|---|---|---|
| users | 否 | 单用户模式，无需本地存储 |
| word_books | 否 | 词书元数据仅云端管理 |
| user_book_settings | 部分 -- dailyGoal 已本地化 | SP:settings_daily_goal 覆盖了核心设置 |
| review_groups / review_group_items | 否 | 云端 naive review 机制，本地用 FSRS 替代 |
| daily_goal_progress | 否 | 云端聚合表，本地无需 |
| session_records | 否 | Session 仅云端管理（离线不可用） |
| learning_day_facts | 否 | 云端计算，本地无需 |
| streak_records | 否 | 云端计算 |
| reward_source_events | 否 | 奖励系统纯云端 |
| reward_ledger | 否 | 奖励系统纯云端 |
| settlements | 否 | 奖励系统纯云端 |
| idempotency_keys | 否 | 云端幂等基础设施 |
| secondary_wallets | 否 | 副机制纯云端 |
| pet_profiles | 否 | 副机制纯云端 |
| feed_events | 否 | 副机制纯云端 |
| shop_catalog_items | 否 | 副机制纯云端 |
| inventory_items | 否 | 副机制纯云端 |
| equipment_slots | 否 | 副机制纯云端 |
| purchase_records | 否 | 副机制纯云端 |

> 结论: 云端独有表均为合理设计。奖励/副机制/Session/签到计算均为 backend-truth 模式，无需本地存储。

### 5.4 本地独有表/字段分析

| 本地表/字段 | 用途 | 是否合理 |
|---|---|---|
| word_records.synced | 异步同步追踪标记 | OK -- local-first 架构核心字段 |
| wordbook_progress | 本地词书进度 | OK -- 本地端独立追踪 |
| custom_wordbooks | 用户自建词书 | OK -- 纯本地功能 |
| vocabulary_notebook | 生词本 | OK -- 纯本地功能 |
| card_states | FSRS 卡片状态 | OK -- 纯本地 FSRS 调度 |
| review_logs | FSRS 复习历史 | OK -- 纯本地，INSERT-ONLY |
| cached_words | 离线词库缓存 | OK -- 云端下载的本地缓存 |
| cached_words.cached_at | 缓存时间戳 | OK -- 用于判断缓存新鲜度 |

> 结论: 本地独有表均有明确用途，无废弃/孤儿表。

### 5.5 同步接口覆盖

| 数据类型 | 同步方式 | 方向 | 同步状态 | 覆盖评估 |
|---|---|---|---|---|
| 新词学习记录 | StudyService fire-and-forget | 本地 -> 云端 | [已实现] 异步同步 | OK |
| 词库数据 | WordCacheService 下载 | 云端 -> 本地 | [已实现] 批量下载 | OK |
| 每日目标设置 | SettingsPage 双写 | 双向 | [已实现] 本地 SP + API PUT | OK |
| 备份 snapshot | BackupUploadService | 本地 -> 云端 | [已实现] 手动触发 | OK |
| 恢复 snapshot | BackupRestoreService | 云端 -> 本地 | [已实现] 手动触发 | OK |
| FSRS 卡片状态 | **无同步** | -- | **不同步** | 已知 -- FSRS 为纯本地 |
| FSRS review_logs | **无同步** | -- | **不同步** | 已知 -- INSERT-ONLY 纯本地 |
| 签到记录 | **非实时同步** | 云端 API 直接 | 本地 daily_checkins 仅在 snapshot 中 | 已知 |
| 复习组数据 | **无同步** | 云端 API 直接 | 纯云端 | OK |
| 奖励/副机制 | **无同步** | 云端 API 直接 | 纯云端 | OK |

> 结论: 同步策略与 BR "local-first + simple backup" 总定位一致。FSRS 数据不同步是已知设计选择（纯本地），但 snapshot 未包含 FSRS 数据需在 FSRS 集成前解决（DC-05）。

### 5.6 UI 离线依赖

| UI 页面 | 离线可用 | 本地 DB/Service 支持 | 评估 |
|---|---|---|---|
| StudyPage | 部分（写入 OK，获取新词需网络） | word_records (SQLite), StudyService | OK -- 已学词可写入本地，下一词需 API |
| SettingsPage | 部分（设置读写 OK，备份/恢复需网络） | LocalSettingsService (SP) | OK |
| SpecProfilePage | 部分（dailyGoal 本地，summary 需网络） | LocalSettingsService (SP) | OK |
| 其余所有页面 | 需要网络 | -- | OK -- 当前 MVP 架构预期 |

> 结论: UI 离线依赖与本地 DB/Service 支持匹配。StudyPage 的 local-first 写入、SettingsPage 的本地设置读写、FSRS 未来集成后的纯本地复习均有 DB 支持。

---

## 6. 综合建议

### 6.1 需要修正的文档问题

| 优先级 | 问题 | 建议 | 涉及文档 |
|---|---|---|---|
| **P0** | DC-01: `daily_goal_status` 枚举值 BR 与 API 不一致 | 确认代码实际行为：若 dev-store 确实计算 `partially_completed`，则 API 文档应补充此值并修改 3.9 节说明；若代码已移除，则 BR 4.4.1 和 6.0 BR-10 应删除对 `partially_completed` 的引用。DB daily_goal_progress 枚举也需同步。 | BR, API, DB |
| **P1** | DC-02: 每日目标范围双端不一致 (1-100 vs 1-500) | 已知 tech debt (BR TODO-01, PD-006)。建议在下次迭代统一范围。四文档均已记录，无额外修正需要。 | -- |
| **P1** | CustomizePage 缺少卸装 UI | API 有 unequip 端点，DB 支持，但 UI 无卸装按钮。建议补充 UI 或在 API 文档标注"UI 暂未使用"。 | UI, API |

### 6.2 后续集成前需解决的问题

| 优先级 | 问题 | 建议 | 涉及文档 |
|---|---|---|---|
| **P1** | DC-05: 备份 snapshot 不含 FSRS 数据 | 在 FSRS 集成到 StudyPage/ReviewPage 之前，需扩展 snapshot schema 包含 card_states + review_logs + cached_words。否则恢复备份会导致 FSRS 状态丢失。 | DB, API, BR |
| **P1** | DC-04: cached_words 缺少 6 个云端字段 | 当前不影响功能，但如果未来 StudyPage 需要展示 definition/tags/word_forms 等富数据，需扩展 cached_words 表和 WordCacheService 存储逻辑。 | DB |
| **P2** | StudyPage 评分按钮方案确认 | 四文档均标注"暂定"。FSRS 4 按钮已开发，2 按钮正在使用。需要产品决策。 | BR, API, UI |
| **P2** | SpecHomePage 主 CTA 状态驱动 | API 已返回 today_primary_action，TodayPage 已实现合约驱动。SpecHomePage 需要接入。 | UI |

### 6.3 已知 Tech Debt（已记录且一致，无需额外处理）

| 项目 | 状态 | 四文档一致性 |
|---|---|---|
| 云端 vs 本地复习系统 (naive group vs FSRS) | BR TODO-11 | 一致 |
| user_word_progress 表未使用 | BR PD-003 | 一致 |
| 统计页 mock 数据 | BR PD-005 | 一致 |
| 结算浮层占位 | Pending | 一致 |
| 认证系统未开发 | BR PD-009 | 一致 |
| Feature Guard 关闭的功能 (8 个 false) | 各文档均标注 | 一致 |
| 三套设计系统并存 | UI 7.0 Major #7 | 仅 UI 相关 |
| ApiClient 未封装的 4 个端点 | API 文档已标注 | 一致 |

---

> Phase 4 完成。四份 v0.2.0 文档整体一致性良好，均基于同一代码基准 (bface75) 重写。
> 1 项严重问题 (daily_goal_status 枚举)、12 项一般问题（多为已知 tech debt）、13 项信息级记录。
> 建议优先处理 P0 枚举一致性问题。
