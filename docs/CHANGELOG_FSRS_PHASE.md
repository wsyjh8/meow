# CHANGELOG —— FSRS 接入阶段

> 这份文件是本开发阶段的**唯一真相源**。所有改动都追加在这里，后续补正式文档时从这份文件回溯。
> 格式见 `tasks/FSRS_INTEGRATION.md` 末尾的 "CHANGELOG 模板" 小节。
> **规则**：漏记一条 = 这条改动没做。发现漏记立刻补。

---

## [2026-04-07 22:00] Task 0 — 现状盘点与方案草稿

**动作**: 新增

**涉及文件**:
- `docs/FSRS_DESIGN_DRAFT.md` (新增)
- `docs/CHANGELOG_FSRS_PHASE.md` (修改：填充 Task 0 记录)

**为什么**: 在动代码之前完成完整的技术选型和架构设计，确定 FSRS 库、drift 迁移策略、表 schema、FsrsService 接口、Session Builder 协作方案。

**现状盘点发现**:
- 数据库是 raw sqflite（不是 drift），schema v1，5 张表
- word_id 类型是 TEXT（如 `cet4-abandon`），不是 INTEGER
- 词库只在后端 PG，无本地缓存
- 无任何 SRS 算法，复习完全 API 驱动
- 每日目标存 SharedPreferences，后端硬编码 20（已有 bug fix 让后端读 PG）

**关键决策**:
- FSRS 库：选定 `fsrs` v2.0.1（FSRS-6，纯 Dart，MIT，160/160 分）
- 数据库：从 raw sqflite 迁移到 drift
- word_id：保持 TEXT，不改为 INTEGER
- 新增 3 张表：card_states、review_logs、cached_words
- Task 执行顺序：0 → 1 → 3 → 2 → 4 → 5 → 6（Task 3 先于 Task 2，确保日志从 day 1 就有）

**对其它模块的影响**:
- 词库缓存层: 需新增 cached_words 表 + 后端批量 API
- 现有 DB 表: 5 张旧表迁移到 drift 定义（SQL 必须完全一致）
- 备份/恢复: 需扩展 snapshot 包含 card_states + review_logs + cached_words
- 公共 API: 新增 FsrsService / ReviewRating / CardStateData / SessionBuilder

**需要后续补文档的点**:
- [ ] FSRS_DESIGN_DRAFT.md 在各 Task 完成后更新钉死的细节
- [ ] FsrsService 各方法的 dartdoc
- [ ] Session Builder 的契约文档
- [ ] drift migration 指南
- [ ] 架构文档中 "memory" 模块一节

---

## [2026-04-07 23:30] Task 1 — drift 迁移 + FsrsService 主链路

**动作**: 新增 / 修改

**涉及文件**:
- `apps/mobile/pubspec.yaml` (修改：+drift ^2.32.1, +drift_sqflite ^2.0.1, +fsrs ^2.0.1, +path_provider ^2.1.5, +drift_dev, +build_runner)
- `apps/mobile/lib/core/storage/drift/tables/legacy_tables.dart` (新增：5 张旧表的 drift 定义)
- `apps/mobile/lib/core/storage/drift/tables/fsrs_tables.dart` (新增：card_states + review_logs + cached_words)
- `apps/mobile/lib/core/storage/drift/app_database.dart` (新增：@DriftDatabase, schemaVersion 2, migration)
- `apps/mobile/lib/core/storage/drift/app_database.g.dart` (自动生成)
- `apps/mobile/lib/core/memory/review_rating.dart` (新增：ReviewRating 枚举)
- `apps/mobile/lib/core/memory/card_state_data.dart` (新增：CardStateData DTO)
- `apps/mobile/lib/core/memory/fsrs_service.dart` (新增：FsrsService 主链路)
- `apps/mobile/test/fsrs_service_test.dart` (新增：9 个单测)

**为什么**: 建立 FSRS 核心链路——新词初始化、评分计算、到期查询。drift 替代 raw sqflite 提供类型安全和事务支持。

**对其它模块的影响**:
- 现有 DB 表: 旧 `LocalDatabase` 暂时保留共存，FSRS 功能用新 drift AppDatabase
- 公共 API: 新增 FsrsService（initCardForWord / rateCard / listDueCards / countNewCardsToday / previewSchedule / exportReviewLogsAsJsonl / updateDesiredRetention）
- 备份/恢复: 尚未更新（TODO Task 后续）

**实际情况与默认方案的偏差**:
- fsrs 库的 Card 没有 `reps` / `lapses` 字段 → 在 FsrsService 层自行维护
- fsrs 库的 State 枚举用 `.value`(1/2/3) 而不是 `.index`(0/1/2) → 用 `State.fromValue()` 转换
- 旧调用方迁移推迟 — Task 1 只建 FSRS 主链路，不改现有 study/review 页面

**需要后续补文档的点**:
- [ ] FsrsService 各方法的 dartdoc（已有基本注释）
- [ ] drift migration 从 v1→v2 的测试覆盖（升级安装场景）
- [ ] 旧 LocalDatabase → drift AppDatabase 的完整迁移

### DB Schema Change — card_states

**Before** (schemaVersion 1):
无

**After** (schemaVersion 2):
```sql
CREATE TABLE card_states (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  word_id     TEXT NOT NULL UNIQUE,
  stability   REAL,
  difficulty  REAL,
  due         INTEGER NOT NULL,
  last_review INTEGER,
  state       INTEGER NOT NULL DEFAULT 1,
  step        INTEGER,
  reps        INTEGER NOT NULL DEFAULT 0,
  lapses      INTEGER NOT NULL DEFAULT 0,
  created_at  INTEGER NOT NULL
);
CREATE INDEX idx_card_states_due ON card_states(due);
CREATE INDEX idx_card_states_state ON card_states(state);
```

**Migration 策略**: onCreate 建全部 8 表；onUpgrade(1→2) 只 createTable 3 张新表
**数据回填**: 无

### DB Schema Change — review_logs

**Before**: 无

**After** (schemaVersion 2):
```sql
CREATE TABLE review_logs (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  card_state_id     INTEGER NOT NULL REFERENCES card_states(id),
  word_id           TEXT NOT NULL,
  rating            INTEGER NOT NULL,
  review_time_utc   INTEGER NOT NULL,
  elapsed_days      REAL NOT NULL,
  scheduled_days    REAL NOT NULL,
  state_before      INTEGER NOT NULL,
  stability_before  REAL,
  difficulty_before REAL,
  client_version    TEXT
);
CREATE INDEX idx_review_logs_word_id ON review_logs(word_id);
CREATE INDEX idx_review_logs_review_time ON review_logs(review_time_utc);
```

### DB Schema Change — cached_words

**Before**: 无

**After** (schemaVersion 2):
```sql
CREATE TABLE cached_words (
  word_id         TEXT PRIMARY KEY,
  book_id         TEXT NOT NULL,
  word_text       TEXT NOT NULL,
  meaning         TEXT NOT NULL,
  phonetic        TEXT,
  translation     TEXT,
  frequency_rank  INTEGER NOT NULL DEFAULT 0,
  sort_order      INTEGER NOT NULL DEFAULT 0,
  cached_at       INTEGER NOT NULL
);
```

### 单测结果
```
00:00 +9: All tests passed!
```
覆盖：initCardForWord（创建+幂等）、rateCard（good/again/step推进）、listDueCards（到期/未到期）、countNewCardsToday、previewSchedule

---

## [2026-04-07 23:50] Task 3 — 复习日志事务封装

**动作**: 修改

**涉及文件**:
- `apps/mobile/lib/core/memory/fsrs_service.dart` (修改：rateCard 包进 db.transaction，新增 review_log INSERT)
- `apps/mobile/test/fsrs_service_test.dart` (修改：新增 4 个 Task 3 测试)

**为什么**: review_logs 是喂给 fsrs-optimizer 的原始数据，从 day 1 就必须有。rateCard 的「读 card → 写 log → 更新 card」必须原子，否则可能出现「有更新无日志」或「有日志无更新」。

**改动细节**:
- `rateCard()` 全部逻辑包进 `_db.transaction(() async { ... })`
- 在 FSRS 计算之后、card_states 更新之前，INSERT 一条 review_log
- review_log 记录：rating、review_time_utc、elapsed_days、scheduled_days、state_before、stability_before、difficulty_before、client_version
- elapsed_days = (now - last_review) 小时数 / 24
- scheduled_days = (due - last_review) 毫秒数 / 一天毫秒数
- review_logs **只 INSERT，不 UPDATE、不 DELETE**（神圣不可改）

**对其它模块的影响**:
- FsrsService.rateCard: 签名不变，内部改为事务
- exportReviewLogsAsJsonl: 已有，无需改动
- 备份/恢复: 仍需后续更新 snapshot 包含 review_logs

**单测结果**: 13/13 通过
- 新增：rateCard 后 review_logs 恰好多一行
- 新增：review_log 的 state_before/rating 值正确
- 新增：多次 rateCard 产生多条 log
- 新增：exportReviewLogsAsJsonl 输出有效 JSONL

**需要后续补文档的点**:
- [ ] review_logs 表的数据字典文档
- [ ] fsrs-optimizer 的喂数据指南

---

## [2026-04-08 00:10] Task 2 — 评分 UI 与 Rating 映射

**动作**: 新增

**涉及文件**:
- `apps/mobile/lib/core/memory/widgets/rating_buttons.dart` (新增：FsrsRatingButtons 组件 + RatingButtonConfig)
- `apps/mobile/test/rating_buttons_test.dart` (新增：8 个单测)
- `docs/FSRS_DESIGN_DRAFT.md` (修改：钉死 4.1 映射表 + 新增 4.2 三按钮过渡指南)

**为什么**: 提供 FSRS 四档评分的 UI 组件。组件设计为独立可复用 Widget，通过 `configs` 参数支持运行时切换 3/4 按钮，实际改动面仅 4 个文件。

**组件设计要点**:
- `FsrsRatingButtons`: 接收 `onRate(ReviewRating)` 回调，UI 层不知道 fsrs 库
- `RatingButtonConfig`: 集中定义每个按钮的 label/sublabel/icon/color
- `defaultRatingConfigs`: 4 按钮默认配置（again/hard/good/easy）
- `previewDurations`: 可选参数，传入则在按钮下方显示"下次: X天"
- 色盲友好：每个按钮同时有颜色 + icon + 文字标签
- 支持 `enabled: false` 禁用状态

**3↔4 按钮过渡指南（已写入 FSRS_DESIGN_DRAFT.md 4.2 节）**:
- 改动面：rating_buttons.dart (删配置条目) + review_rating.dart (删枚举值) + fsrs_service.dart (删 switch case) + 文档
- 零改动：card_states / review_logs / session_builder / app_database / migration
- 测试已覆盖：`works with 3-button config (no hard)` 验证了 3 按钮场景

**对其它模块的影响**:
- 复习页 / 学习页: 尚未接入（需 Task 4 Session Builder 就绪后统一接入）
- 公共 API: 新增 FsrsRatingButtons / RatingButtonConfig / defaultRatingConfigs

**单测结果**: 8/8 通过
- Widget 测试：4 按钮渲染、点击回调、disabled 状态、preview 显示、3 按钮配置
- 纯逻辑测试：配置数量、颜色唯一性、icon 完整性

**需要后续补文档的点**:
- [ ] 评分按钮的 a11y 测试（Semantics label）
- [ ] 动画（任务文件明确说不做，留 TODO）

---

## [2026-04-08 00:40] Task 4 — Session Builder：每日配额 × FSRS 到期队列

**动作**: 新增 / 修改

**涉及文件**:
- `apps/api/src/domain/dev-store.ts` (修改：新增 getWordsByBook 方法)
- `apps/api/src/controllers/words.controller.ts` (新增：GET /books/:bookId/words 分页 API)
- `apps/api/src/controllers/index.ts` (修改：导出 WordsController)
- `apps/api/src/routes/routes.module.ts` (修改：注册 WordsController)
- `apps/mobile/lib/core/memory/word_cache_service.dart` (新增：WordCacheService 批量下载 + 本地缓存)
- `apps/mobile/lib/core/memory/session_builder.dart` (新增：SessionBuilder + ReviewSession + SessionItem)
- `apps/mobile/test/session_builder_test.dart` (新增：5 个单测)

**为什么**: Session Builder 是连接"每日词汇量设置"和"FSRS 到期队列"的关键枢纽。后端新增批量词 API 让 Flutter 端可以一次性下载整本词书到本地缓存，实现离线选词。

**改动细节**:

后端：
- `devStore.getWordsByBook(bookId, offset, limit)`: 从内存 wordPool 分页返回
- `GET /api/v1/books/:bookId/words?offset=0&limit=500`: 分页下载，每页最多 1000

Flutter：
- `WordCacheService.downloadAndCacheBook(bookId)`: 分页下载 → INSERT OR REPLACE 到 cached_words
- `WordCacheService.ensureCached(bookId)`: 已有缓存则跳过，否则下载
- `SessionBuilder.buildTodaySession(nowLocal, newCardsDailyLimit, reviewCardsDailyLimit?)`:
  1. listDueCards → 拉到期复习卡
  2. countNewCardsToday → 计算今日新词余额
  3. SELECT cached_words WHERE NOT IN card_states → 新词候选
  4. initCardForWord → 初始化新词卡片
  5. interleave(3:1) → 交叉编排

**已钉死的契约**:
- `newCardsDailyLimit` 只管新词，复习默认不限
- `initCardForWord` 一调即不可逆，该词永不再当"新词"
- 同一天重复 `buildTodaySession` 不会重复引入新词
- 穿插比例：复习:新词 = 3:1
- 日切边界：本地 00:00（TODO: 可配 04:00）

**对其它模块的影响**:
- 后端: 新增 WordsController，对现有 API 无影响
- 公共 API: 新增 WordCacheService / SessionBuilder / ReviewSession / SessionItem
- 学习页: 尚未接入（TODO: 替换现有 API-driven 流程为 SessionBuilder-driven）

**单测结果**: 5/5 通过 (总计 26/26)
- 100词+配额10+无到期 → 10新
- 100词+20到期+配额10 → 10新+20复习，3:1交叉
- 同日重复build → 不重复引入
- 空缓存 → 空session
- reviewCardsDailyLimit=10 → 复习被截断

**需要后续补文档的点**:
- [ ] SessionBuilder 的正式 API 文档
- [ ] WordCacheService 的缓存更新策略（版本号/增量更新）
- [ ] 学习页/复习页接入 SessionBuilder 的集成指南

---

## [2026-04-08 01:10] Task 5 — 时区、desired_retention、learning steps

**动作**: 修改 / 新增

**涉及文件**:
- `apps/mobile/test/fsrs_service_test.dart` (修改：+3 时区/retention 测试)
- `apps/mobile/lib/core/storage/local_settings_service.dart` (修改：+desiredRetention getter/setter)
- `apps/mobile/lib/features/settings/settings_page.dart` (修改：+记忆保留率设置 UI)

**为什么**: 确保 FSRS 在不同时区下正确计算"今天"边界，同时让用户可以调节 desired_retention 以平衡复习量和记忆效果。

**5.1 时区**:
- 3 个单测：UTC+8 的 23:59 到期卡可见、跨天边界 countNewCardsToday 正确切分、retention 变化影响间隔
- 测试策略：机器时区无关 — 从 `DateTime(local).toUtc()` 推导 UTC 范围，不硬编码偏移

**5.2 desired_retention**:
- `local_settings_service.dart`: 新增 key `settings_desired_retention`，默认 0.9，范围 [0.85, 0.95]
- 设置页：ListTile 显示当前值 + Slider 对话框（0.85~0.95，步进 0.01，10 档）
- 帮助文案："调高→复习量增加但记忆更牢；调低→复习量减少但可能遗忘更多"
- `FsrsService.updateDesiredRetention()` 已在 Task 1 实现，无需改动

**5.3 learning steps**:
- 已确认 `fsrs_service.dart` line 27-28 有正确注释：
  `// 保留 learning steps 是因为背单词场景需要短期巩固，不要关`
- 默认 [1min, 10min] + relearning [10min]，第一版不可配，留 TODO

**对其它模块的影响**:
- LocalSettingsService: 新增 desiredRetention，对现有 key 无影响
- 设置页: 新增"记忆设置"卡片，位于每日目标和备份之间

**单测结果**: 29/29 通过（+3 新测试）
- timezone: local 23:59 sees due cards ✓
- timezone: countNewCardsToday across day boundary ✓
- timezone: desired_retention change affects preview intervals ✓

**需要后续补文档的点**:
- [ ] desired_retention UI 的帮助页面/Tooltip
- [ ] learning steps 可配化（目前 hardcode）

---

## [2026-04-08 01:30] Task 6 — 上线前自检

**动作**: 新增

**涉及文件**:
- `apps/mobile/test/migration_test.dart` (新增：4 个 migration 测试)
- `apps/mobile/test/e2e_self_check_test.dart` (新增：4 个端到端自检)
- `docs/FSRS_POST_LAUNCH_TODO.md` (新增)

**自检清单结果**:
- [x] drift migration 干净安装：8 表全建，可读写 ✓
- [x] drift migration v1→v2 升级：旧数据完好，3 新表可写 ✓
- [x] UNIQUE(word_id) 约束生效 ✓
- [x] 每日配额 10→20 立即生效 ✓
- [x] 20 卡 session 后 review_logs 恰好 20 条，字段完整 ✓
- [x] exportReviewLogsAsJsonl 输出 20 条 ✓
- [x] 时区跨天边界新词不重复 ✓
- [x] CHANGELOG 通读无遗漏 ✓

**单测总计**: 37/37 全部通过

---

<!-- 新改动向上追加在这条线之前 -->
