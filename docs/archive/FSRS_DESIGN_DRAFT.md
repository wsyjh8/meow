# FSRS 接入设计草稿

> Task 0 交付物。本文件在后续 Task 中会持续更新（钉死映射表、补 session builder 契约等）。

---

## 1. FSRS 库选型

### 选定：`fsrs` v2.0.1

| 项 | 详情 |
|---|---|
| pub.dev | https://pub.dev/packages/fsrs |
| 算法版本 | FSRS-6（21 个默认参数） |
| 纯 Dart | 是（唯一依赖 `meta`） |
| License | MIT |
| pub.dev 评分 | 160 / 160 |
| 维护方 | open-spaced-repetition 官方 org |
| desired_retention | 可配，默认 0.9 |
| learning_steps | 可配，默认 [1 min, 10 min] |
| relearning_steps | 可配，默认 [10 min] |
| maximum_interval | 默认 36500 天 |
| enable_fuzzing | 默认 true |
| 序列化 | Card.toMap() / Card.fromMap()、ReviewLog.toMap() / ReviewLog.fromMap() |

### 核心 API

```dart
// 创建调度器
final scheduler = Scheduler(
  desiredRetention: 0.9,
  learningSteps: [Duration(minutes: 1), Duration(minutes: 10)],
  relearningSteps: [Duration(minutes: 10)],
);

// 创建新卡（state 默认 State.learning）
final card = Card(cardId: 1);

// 复习评分 → 返回 (card: Card, reviewLog: ReviewLog)
final (:card as newCard, :reviewLog) = scheduler.reviewCard(card, Rating.good);

// 可回忆概率
double r = scheduler.getCardRetrievability(card);
```

### State 枚举值

| 枚举 | 值 | 说明 |
|------|---|------|
| State.learning | 1 | 学习中（新卡默认状态） |
| State.review | 2 | 已进入长期复习 |
| State.relearning | 3 | 遗忘后重新学习 |

> 注意：fsrs 库**没有** `State.new`（值 0）。新卡直接是 `State.learning`。

### Rating 枚举值

| 枚举 | 值 |
|------|---|
| Rating.again | 1 |
| Rating.hard | 2 |
| Rating.good | 3 |
| Rating.easy | 4 |

### 淘汰的候选

| 库 | 淘汰原因 |
|---|---|
| `fsrs-rs-dart` | 需 Rust 工具链、未发布 pub.dev、构建复杂 |
| `sm2` | GPL-3.0、已停维（2020）、Dart 3 不兼容 |
| `spaced_repetition` | GPL-3.0、已停维（2022） |
| `dolphinsr_dart` | 已停维（2021）、SM-2 算法过时 |

---

## 2. 新增 drift 表 Schema

### 2.1 数据库迁移策略

- 当前：raw sqflite，schema v1，5 张表
- 目标：drift，schema v2，8 张表（5 旧 + 3 新）
- 物理文件：`meow_progress.db`（不变）

| 场景 | 处理方式 |
|------|---------|
| 全新安装 | drift `onCreate` 建全部 8 张表 |
| 升级安装（v1→v2） | `onUpgrade` 只建 3 张新表，旧表已存在 |

### 2.2 `card_states` — FSRS 卡片状态

```sql
CREATE TABLE card_states (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  word_id       TEXT    NOT NULL UNIQUE,         -- FK 到 cached_words / 对应后端 words.id
  stability     REAL,                            -- FSRS stability（新卡可 null）
  difficulty    REAL,                            -- FSRS difficulty（新卡可 null）
  due           INTEGER NOT NULL,                -- UTC epoch ms，下次到期时间
  last_review   INTEGER,                         -- UTC epoch ms，上次复习时间
  state         INTEGER NOT NULL DEFAULT 1,      -- 1=Learning, 2=Review, 3=Relearning
  step          INTEGER,                         -- learning/relearning step index（Review 时 null）
  reps          INTEGER NOT NULL DEFAULT 0,      -- 连续正确复习次数
  lapses        INTEGER NOT NULL DEFAULT 0,      -- 遗忘次数
  created_at    INTEGER NOT NULL                 -- UTC epoch ms，创建时间
);

CREATE INDEX idx_card_states_due   ON card_states(due);
CREATE INDEX idx_card_states_state ON card_states(state);
```

### 2.3 `review_logs` — 原始复习日志（INSERT-ONLY）

```sql
CREATE TABLE review_logs (
  id                INTEGER PRIMARY KEY AUTOINCREMENT,
  card_state_id     INTEGER NOT NULL REFERENCES card_states(id),
  word_id           TEXT    NOT NULL,             -- 冗余，方便直接按词查询
  rating            INTEGER NOT NULL,             -- 1=Again, 2=Hard, 3=Good, 4=Easy
  review_time_utc   INTEGER NOT NULL,             -- UTC epoch ms
  elapsed_days      REAL    NOT NULL,             -- 距上次复习的天数
  scheduled_days    REAL    NOT NULL,             -- 复习前 FSRS 安排的间隔天数
  state_before      INTEGER NOT NULL,             -- 复习前的 card state
  stability_before  REAL,                         -- 复习前的 stability
  difficulty_before REAL,                         -- 复习前的 difficulty
  client_version    TEXT                          -- app 版本号
);

CREATE INDEX idx_review_logs_word_id     ON review_logs(word_id);
CREATE INDEX idx_review_logs_review_time ON review_logs(review_time_utc);
```

> **规则：review_logs 只 INSERT，不 UPDATE、不 DELETE。** 这是喂给 fsrs-optimizer 的原始数据。

### 2.4 `cached_words` — 本地词库缓存

```sql
CREATE TABLE cached_words (
  word_id         TEXT PRIMARY KEY,               -- 如 'cet4-abandon'
  book_id         TEXT    NOT NULL,
  word_text       TEXT    NOT NULL,
  meaning         TEXT    NOT NULL,
  phonetic        TEXT,
  translation     TEXT,
  frequency_rank  INTEGER NOT NULL DEFAULT 0,
  sort_order      INTEGER NOT NULL DEFAULT 0,     -- 学习顺序（高频→低频）
  cached_at       INTEGER NOT NULL                -- UTC epoch ms
);
```

### 2.5 与词库表的关系

```
后端 PG: words 表 (3849 CET-4 词)
        ↓ 批量下载 / 逐个缓存
Flutter SQLite: cached_words（本地副本）
        ↓ word_id 关联
Flutter SQLite: card_states（FSRS 调度状态）
        ↓ card_state_id FK
Flutter SQLite: review_logs（复习日志）
```

---

## 3. FsrsService 对外方法签名

```dart
/// 文件：lib/core/memory/fsrs_service.dart
///
/// 封装 fsrs 库。FSRS 库的类型（Card, Rating, State）不泄漏到此文件之外。
/// UI 层只看到 ReviewRating / CardStateData。
class FsrsService {
  FsrsService({required AppDatabase db, double desiredRetention = 0.9});

  /// 为新词创建 FSRS 卡片。
  /// 幂等：word_id 已有 card_states 记录则直接返回。
  /// 新卡 state=1(Learning), due=now, stability/difficulty=null
  Future<CardStateData> initCardForWord(String wordId);

  /// 用户评分后调用。
  /// 在一个 drift transaction 里：
  ///   1. 读 card_states 当前行
  ///   2. 插入 review_logs（state-before 快照）
  ///   3. 调 scheduler.reviewCard() 计算新值
  ///   4. 更新 card_states
  /// 返回更新后的卡片状态。
  Future<CardStateData> rateCard(
    String wordId,
    ReviewRating rating,
    {DateTime? nowUtc},
  );

  /// 查询所有 due <= nowUtc 的卡片。
  /// nowLocal 内部转 UTC 再查。结果按 due ASC（最过期的排前面）。
  Future<List<CardStateData>> listDueCards({
    required DateTime nowLocal,
    int? limit,
  });

  /// 今天已引入多少张新卡。
  /// "今天" = nowLocal 的 00:00 ~ 23:59（本地时区）。
  Future<int> countNewCardsToday({required DateTime nowLocal});

  /// 预览 4 种评分各自的下次复习间隔（不持久化）。
  /// 用于 UI 在按钮下方显示"下次：X 天后"。
  Future<Map<ReviewRating, Duration>> previewSchedule(String wordId);

  /// 导出 review_logs 为 JSONL（一行一条 JSON），用于 fsrs-optimizer。
  Future<String> exportReviewLogsAsJsonl();

  /// 运行时更新 desired_retention（重建内部 Scheduler 实例）。
  void updateDesiredRetention(double value);
}
```

---

## 4. Rating 映射表（已钉死）

### 4.1 当前方案：4 按钮

| ReviewRating | FSRS Rating | 值 | 用户文案 | 副标签 | Icon | 色值 |
|---|---|---|---|---|---|---|
| `again` | Rating.again | 1 | **不认识** | 重来 | refresh_rounded | #E8564A (暖红) |
| `hard` | Rating.hard | 2 | **模糊** | 有点印象 | cloud_outlined | #E8A54A (暖橙) |
| `good` | Rating.good | 3 | **记得** | 想了一下 | check_rounded | #6B4FA8 (品牌紫) |
| `easy` | Rating.easy | 4 | **秒答** | 很简单 | bolt_rounded | #3D9970 (沉静绿) |

> 色盲友好：每个按钮同时有 **颜色 + icon + 文字标签**，不单靠颜色区分。

### 4.2 如果将来改成 3 按钮，需要改哪些文件

**场景示例：** 去掉 `hard`，只保留 Again / Good / Easy。

| 序号 | 文件 | 改什么 | 难度 |
|------|------|--------|------|
| 1 | `lib/core/memory/widgets/rating_buttons.dart` | 从 `defaultRatingConfigs` 列表删掉 `hard` 条目 | 1 行 |
| 2 | `lib/core/memory/review_rating.dart` | 从 `ReviewRating` 枚举删掉 `hard` | 1 行 |
| 3 | `lib/core/memory/fsrs_service.dart` | `_toFsrsRating()` 的 switch 删掉 `hard` case | 1 行 |
| 4 | `docs/FSRS_DESIGN_DRAFT.md` | 更新本节映射表 | 文档 |

**不需要改的（rating-count 无关）：**

| 不需要改的 | 原因 |
|---|---|
| `card_states` 表 | 不存 rating |
| `review_logs` 表 | `rating` 列存 int (1/2/3/4)，仍能正确记录 |
| `fsrs_service.dart` 的 `rateCard()` | 接收 ReviewRating 枚举，switch 自动处理 |
| `fsrs_service.dart` 的 `previewSchedule()` | 遍历 `ReviewRating.values`，自动适应 |
| `session_builder.dart` | 不关心 rating 是几档 |
| `app_database.dart` / migration | 表结构无变化 |
| 所有单测 | 只需删 hard 相关断言或让它们编译报错时修 |

**总结：3→4 或 4→3 的切换影响面 ≤ 4 个文件，核心数据层零改动。**

---

## 5. 每日词汇量 × FSRS 到期队列协作方案

### 核心契约（已钉死，Task 4 实现并测试通过）

| 维度 | 规则 |
|------|------|
| 每日新词上限 | 用户设置的 `daily_goal`（SharedPreferences `settings_daily_goal`，默认 20） |
| 到期复习 | 默认**不限制**，所有 due <= now 的卡片都出（可选 reviewCardsDailyLimit 截断） |
| 谁管新词 | SessionBuilder 从 `cached_words` 中取没有 `card_states` 的词 |
| 谁管复习 | FsrsService.listDueCards() |
| 怎么混合 | 复习:新词 = 3:1 穿插，避免连续刷新词导致疲劳 |
| 幂等性 | initCardForWord 一调即不可逆；同一天重复 buildTodaySession 不重复引入新词 |
| 日切边界 | 本地 00:00（TODO: 可配置 04:00） |

### Session Builder 伪代码

```
buildTodaySession(nowLocal, newCardsDailyLimit, reviewCardsDailyLimit?):

  // Step 1: 到期复习卡（无限制 or 可选限制）
  dueCards = fsrsService.listDueCards(nowLocal, limit: reviewCardsDailyLimit)

  // Step 2: 今日新词余额
  usedNew = fsrsService.countNewCardsToday(nowLocal)
  remainingNew = max(0, newCardsDailyLimit - usedNew)

  // Step 3: 新词候选
  // 从 cached_words 取没有 card_states 记录的词，按 sort_order 排
  candidates = SELECT word_id FROM cached_words
               WHERE word_id NOT IN (SELECT word_id FROM card_states)
               ORDER BY sort_order ASC
               LIMIT :remainingNew

  // Step 4: 初始化新词卡片（idempotent）
  newCards = []
  for wordId in candidates:
    card = fsrsService.initCardForWord(wordId)
    newCards.add(card)

  // Step 5: 穿插编排
  queue = interleave(dueCards, newCards, ratio: 3)
  // ratio=3: 每 3 张复习卡后插 1 张新词

  return ReviewSession(
    queue: queue,
    totalNew: newCards.length,
    totalReview: dueCards.length,
  )
```

### 关键不变量

1. **`initCardForWord` 一调即不可逆** — 该 word_id 在 `card_states` 有记录后，永远不再被当"新词"
2. **同一天重复调用 `buildTodaySession`** — `countNewCardsToday` 扣减已用配额，不会重复引入
3. **日切边界** — 本地 00:00（TODO：可配置 04:00 for 夜猫子）
4. **复习卡不受每日新词限制** — 50 张到期就 50 张出，不截断

### 穿插算法示例

```
dueCards = [R1, R2, R3, R4, R5, R6, R7]
newCards = [N1, N2, N3]
ratio = 3

结果: [R1, R2, R3, N1, R4, R5, R6, N2, R7, N3]
```

---

## 6. 时间存储规范

| 字段 | 存储格式 | 查询时 |
|------|---------|--------|
| `card_states.due` | UTC epoch ms (INTEGER) | `listDueCards` 接 nowLocal，内部转 UTC 比较 |
| `card_states.last_review` | UTC epoch ms | 直接存 |
| `card_states.created_at` | UTC epoch ms | `countNewCardsToday` 用 nowLocal 计算今日 UTC 范围 |
| `review_logs.review_time_utc` | UTC epoch ms | 直接存 |
| `cached_words.cached_at` | UTC epoch ms | 直接存 |

> **Store UTC, Display Local.** 所有 "今天" 的概念在 Service 层按用户本地时区换算。

---

## 7. desired_retention 配置

| 项 | 值 |
|---|---|
| 存储 | SharedPreferences `settings_desired_retention` |
| 默认值 | 0.9 |
| 允许范围 | 0.85 ~ 0.95 |
| UI | 设置页 Advanced 区域（或隐藏入口） |
| 文案 | "记忆保留率：调高 → 复习量增加但记忆更牢，调低 → 复习量减少但可能遗忘更多" |
| 生效时机 | `FsrsService.updateDesiredRetention()` 重建内部 Scheduler |

---

## 8. Learning Steps 配置

| 项 | 值 |
|---|---|
| 默认 learning_steps | [1 min, 10 min] |
| 默认 relearning_steps | [10 min] |
| 是否可配 | 第一版不可配（hardcode），留 TODO |

> 保留 learning steps 是因为背单词场景需要短期巩固，不要关。

---

## 9. 文件结构总览

```
lib/core/
  memory/
    fsrs_service.dart           — FsrsService 主类
    review_rating.dart          — ReviewRating 枚举
    card_state_data.dart        — CardStateData DTO
    session_builder.dart        — SessionBuilder + ReviewSession

  storage/
    drift/
      app_database.dart         — @DriftDatabase, schemaVersion 2, migration
      app_database.g.dart       — generated
      tables/
        legacy_tables.dart      — 5 张旧表 drift 定义
        fsrs_tables.dart        — card_states + review_logs + cached_words
      daos/
        word_record_dao.dart    — word_records 操作
        fsrs_dao.dart           — FSRS 表 CRUD
        cached_word_dao.dart    — cached_words 操作
```

---

## 10. Task 执行顺序

```
Task 0 — 方案草稿 ← 本文件
  ↓
Task 1 — drift 迁移 + drift 表 + FsrsService 主链路 + 单测
  ↓
Task 3 — review_logs 写入逻辑 + 事务封装（日志比 UI 更优先）
  ↓
Task 2 — 评分 UI（4 按钮 + 可选预览）
  ↓
Task 4 — SessionBuilder（每日配额 × FSRS 到期队列）
  ↓
Task 5 — 时区单测 + desired_retention 设置 + learning steps 注释
  ↓
Task 6 — 上线前自检清单
```
