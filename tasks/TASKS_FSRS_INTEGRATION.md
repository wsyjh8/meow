# Task：把 FSRS 记忆模型接入 Flutter 背单词项目

> 本文件是 Claude Code 在本阶段的**唯一任务总表**。
> 项目是 **Flutter + drift（sqflite）**，目前只有基础词库和每日词汇量设置，**没有**历史算法数据，也没有复杂缓存 / 发音模块。这是一次绿地建设，可以一步到位把 FSRS 相关的表和接口设计对。

## 关键设计原则

1. **不重造轮子**：用社区维护的 dart FSRS 库，第一版用默认 21 个参数，不自己按论文复刻。
2. **日志先于优化**：复习日志从 day 1 就埋，哪怕现在用不上。没日志 = 以后优化器没得跑，而且已经产生的数据永远找不回来。
3. **时区**：所有时间字段存 UTC，查询"今天到期"时在 Service 层按用户本地时区换算。**Store UTC, Display Local**。
4. **学习阶段保留**：新词的 1min / 10min 短间隔（FSRS 的 learning steps）对背单词场景很重要，不要关。
5. **最小侵入 + 清晰边界**：FSRS 代码集中在 `lib/core/memory/`（或 `lib/features/fsrs/`），对外只暴露几个方法（`initCardForWord`、`rateCard`、`listDueCards` 等）。**FSRS 库本身的类型不要泄漏到 UI 层**，UI 层只看到项目自己定义的 `ReviewRating` 枚举。
6. **每日词汇量 × FSRS**：现有的"每日词汇量"设置是**每日新词上限**，要和 FSRS 的到期队列协作。不要让 FSRS 直接决定每天展示多少词——它只负责"哪些词到期了"，session builder 负责"今天实际给用户多少新词 + 多少复习词"。

## 任务清单

每个任务完成后在 `[ ]` 打勾，并在"实际情况"一行写一句和默认计划的偏差。

---

### Task 0 — 方案草稿  `[x]`

**做什么**

- 扫一遍现有 drift 数据库定义，列出所有现有表（尤其词库表的主键和字段）
- 调研 dart 可用的 FSRS 库：优先看 **FSRS-5 / FSRS-6** 支持、是否在维护、是否纯 dart、license。给一个推荐 + 一个备选，说明理由
- 产出 `docs/FSRS_DESIGN_DRAFT.md`，至少包含：
  - 新增表的 schema（`card_states` + `review_logs`）
  - `FsrsService` 的对外方法签名
  - Rating 4 档到用户语言的映射表
  - **每日词汇量 × FSRS 的协作方案**（session builder 的伪代码）
  - 和词库表的外键关系

**交付物**

- `docs/FSRS_DESIGN_DRAFT.md`
- CHANGELOG 追加一条 Task 0 完成记录

**等我确认方案后再进入 Task 1。**

---

### Task 1 — drift schema + FsrsService 主链路  `[x]`

**做什么**

- 引入选定的 dart FSRS 库到 `pubspec.yaml`
- 在 drift database 里**新增两张表**（建议用独立的 `tables/fsrs_tables.dart` 文件）：

  **`card_states`** —— 每个单词的 FSRS 卡片状态
  ```
  id              INTEGER PK AUTO
  word_id         INTEGER NOT NULL  -- 外键到词库表
  stability       REAL NOT NULL
  difficulty      REAL NOT NULL
  due             INTEGER NOT NULL  -- UTC epoch ms
  last_review     INTEGER           -- UTC epoch ms, nullable
  state           INTEGER NOT NULL  -- 0=New 1=Learning 2=Review 3=Relearning
  reps            INTEGER NOT NULL DEFAULT 0
  lapses          INTEGER NOT NULL DEFAULT 0
  scheduled_days  REAL NOT NULL DEFAULT 0
  elapsed_days    REAL NOT NULL DEFAULT 0
  UNIQUE(word_id)
  INDEX on (due)  -- 到期查询要快
  INDEX on (state)
  ```

  **`review_logs`** —— 原始复习日志（Task 3 细化）

- 升级 drift 的 `schemaVersion`，写好 `MigrationStrategy`（`onCreate` 建表，`onUpgrade` 从当前版本 → 新版本）。因为项目刚起步、用户基数小或 0，简单 alter 即可，但**不要**走 destructive migration 偷懒，要写正规 migration 便于以后复用模式
- 新建 `lib/core/memory/fsrs_service.dart`，封装至少：
  ```dart
  Future<CardState> initCardForWord(int wordId);
  Future<CardState> rateCard(int wordId, ReviewRating rating, {DateTime? nowUtc});
  Future<List<CardState>> listDueCards({required DateTime nowLocal, int? limit});
  ```
- `ReviewRating` 枚举定义在 `lib/core/memory/review_rating.dart`，**不要**直接把 FSRS 库的 `Rating` 类型暴露出去；在 service 内部做转换
- 打通最小链路：**新词第一次出现 → initCardForWord → 用户评分 → rateCard → 写 card_states**
- 至少 2 个单测：
  - `initCardForWord` 后 state == New、due == now
  - `rateCard(good)` 后 due 明显推后

**不做**

- 不写 review_logs 的插入逻辑（Task 3 做，但**表要在 Task 1 就建好**，避免 Task 3 再开一次 migration）
- 不做 UI
- 不做 session builder

**交付物**

- `pubspec.yaml` 更新
- 新增 drift 表文件 + 生成的 `.g.dart`（记得跑 `build_runner`）
- `fsrs_service.dart` + `review_rating.dart`
- 单测
- CHANGELOG 详细记录：新依赖、新表（before/after schema 块）、新文件、schemaVersion 从 N → N+1

---

### Task 2 — 评分 UI 与 Rating 映射  `[x]`

**做什么**

- 在复习页加 4 个评分按钮，映射：
  - `Again` → **不认识**
  - `Hard` → **模糊**
  - `Good` → **想了一下才记起**
  - `Easy` → **秒答**
- UI 层只依赖 `ReviewRating { again, hard, good, easy }`，调用 `FsrsService.rateCard`
- 可选：在每个按钮下方小字显示"下次：X 天后"的预览（调用 FSRS 的 schedule preview 方法，如果库支持）
- a11y：按钮够大、色盲友好（不要只靠红黄绿区分，加 icon 或文字）

**不做**

- 不做键盘快捷键（TODO）
- 不做动画

**交付物**

- 复习页（或新建 `review_page.dart`）
- CHANGELOG 记录 UI 文件变更
- 在 `docs/FSRS_DESIGN_DRAFT.md` 里钉死最终的映射表

---

### Task 3 — 复习日志（非常重要，不能省）  `[x]`

**做什么**

- 在 Task 1 已经建好的 `review_logs` 表上，补 DAO 和写入逻辑
- 建议 schema：
  ```
  id                INTEGER PK AUTO
  card_state_id     INTEGER NOT NULL  -- FK
  word_id           INTEGER NOT NULL  -- 冗余，方便查询
  rating            INTEGER NOT NULL  -- 1=Again 2=Hard 3=Good 4=Easy
  review_time_utc   INTEGER NOT NULL  -- epoch ms
  elapsed_days      REAL NOT NULL     -- 距上次复习
  scheduled_days    REAL NOT NULL     -- 本次复习前 FSRS 安排的间隔
  state_before      INTEGER NOT NULL
  stability_before  REAL NOT NULL
  difficulty_before REAL NOT NULL
  client_version    TEXT              -- app 版本号
  INDEX on (word_id)
  INDEX on (review_time_utc)
  ```
- 每次 `rateCard` 调用必须**在一个 drift transaction 里**：先读当前 card_state → 写 review_log → 更新 card_state。保证"有日志无更新"或"有更新无日志"不会发生
- `review_logs` **只 insert，不 update、不 delete**。这是原始日志，神圣不可修改
- 加一个简单导出方法 `Future<String> exportReviewLogsAsJsonl()`，后期可以喂给 fsrs-optimizer
- 单测：调用一次 `rateCard` → `review_logs` 表恰好多一行、内容正确

**为什么现在做**：后补会非常痛苦，因为已经产生的复习数据永远追不回来。第一版上线就必须带。

**交付物**

- DAO + 事务封装
- 单测
- CHANGELOG 记录（因为表在 Task 1 就建了，这里只记 DAO 新增 + 写入逻辑上线）

---

### Task 4 — Session Builder：每日配额 × FSRS 到期队列  `[x]`

**做什么**

这一步是本项目特有的，因为你们已经有"每日词汇量"设置。需要把它和 FSRS 的到期队列对接好。

- 新建 `lib/core/memory/session_builder.dart`，提供：
  ```dart
  Future<ReviewSession> buildTodaySession({
    required DateTime nowLocal,
    required int newCardsDailyLimit,   // 来自用户设置的"每日词汇量"
    int? reviewCardsDailyLimit,        // 可选，默认不限制
  });
  ```
- 逻辑：
  1. 从词库表拉出"**还没有 card_state 的新词**"，最多 `newCardsDailyLimit` 个——这是今天的"新词"
  2. 从 `card_states` 拉 `due <= now` 的——这是今天的"到期复习"
  3. 用合理顺序混合（建议：先穿插，避免用户先刷完所有新词再复习到疲劳）
  4. 返回一个 `ReviewSession` 给 UI
- 还要考虑：**跨天逻辑**。一天的边界按用户本地 4:00 AM 还是 0:00 切？默认按 0:00，留 TODO 以后可配置
- 已经见过今天的新词不应该明天又被当"新词"拉出来——建议做法：`initCardForWord` 一旦被调用就在 `card_states` 留下记录，session builder 下次不会再把它当新词
- 单测：
  - 词库 100 词、每日配额 10、没有到期 → session 返回 10 个新词
  - 词库 100 词、20 张卡到期、每日配额 10 → session 返回 10 新 + 20 复习
  - 同一天第二次 buildTodaySession 不会把已加入的新词当成新词再拉

**交付物**

- `session_builder.dart` + `ReviewSession` 模型
- 单测覆盖上述三种场景
- CHANGELOG 记录
- 在 `docs/FSRS_DESIGN_DRAFT.md` 里钉死"每日配额只管新词，不管复习"这个契约

---

### Task 5 — 时区、desired_retention、learning steps  `[x]`

**5.1 时区**
- 所有存库时间字段一律 UTC（Task 1 已经按这个做）
- `listDueCards` 和 `buildTodaySession` 都接 `DateTime nowLocal`，内部换算 UTC 再查
- 单测：模拟用户在 UTC+8 的 23:59 和 00:01 各查一次，验证不会漏题或重复

**5.2 desired_retention 做成可调**
- 默认 `0.9`
- 在设置页加一项（可以放在 advanced 或隐藏入口），允许 `0.85 ~ 0.95`
- 文案提醒：调高 → 复习量暴增，调低 → 记忆率下降
- 存在本地 settings（沿用项目现有 settings 方案），`FsrsService` 初始化时读

**5.3 learning steps**
- **保留** FSRS 默认的 1min / 10min 短间隔
- 在 `FsrsService` 创建 FSRS 实例的地方加一条注释：`// 保留 learning steps 是因为背单词场景需要短期巩固，不要关`

**交付物**

- 时区单测
- 设置项 UI + 存取
- CHANGELOG 记录所有 5.x 的改动

---

### Task 6 — 上线前自检  `[x]`

- [ ] 复习一轮 20 张卡，确认到期时间、评分反馈、日志都正常
- [ ] drift migration 在"干净安装"和"升级安装"两种场景都能跑通（可以写个小脚本或手动测）
- [ ] 每日配额生效：改设置从 10 → 20，明天的 session 数量变化符合预期
- [ ] 时区单测通过
- [ ] review_logs 表里能查到完整的复习历史
- [ ] `docs/CHANGELOG_FSRS_PHASE.md` 从头读一遍，补齐遗漏
- [ ] 列一份 `docs/FSRS_POST_LAUNCH_TODO.md`：上线后要补的正式文档清单 + 以后要做的优化器工作（比如"累计 1000+ 条日志后跑 fsrs-optimizer 训练个性化参数"）

---

## CHANGELOG 模板

追加到 `docs/CHANGELOG_FSRS_PHASE.md`，**一个改动一块**：

```markdown
## [YYYY-MM-DD HH:mm] Task X.Y — 一句话标题

**动作**: 新增 / 修改 / 删除
**涉及文件**:
- `lib/core/memory/fsrs_service.dart` (新增)
- `lib/database/tables/fsrs_tables.dart` (新增)
- `lib/database/app_database.dart` (修改：schemaVersion N → N+1)
- `lib/database/app_database.g.dart` (重新生成，不手改)

**为什么**: 一句话动机

**对其它模块的影响**:
- 词库表: 无 / 有（具体描述）
- 每日词汇量设置: 无 / 有
- 其他 drift 表: 无 / 有
- 公共 API / 对外方法签名: 无 / 有

**需要后续补文档的点**:
- [ ] FsrsService 各方法的 dartdoc
- [ ] 用户设置页 desired_retention 的帮助文案
- [ ] 架构文档中 "memory" 模块一节
```

drift 表结构变更**额外**要求：

```markdown
### DB Schema Change —— <table_name>

**Before** (schemaVersion N):
（贴 drift table 定义 or 无）

**After** (schemaVersion N+1):
（贴新的 drift table 定义）

**Migration 策略**: onCreate / onUpgrade 里怎么写
**数据回填**: 无 / 有（具体 SQL 或 dart 代码）
```

## 协作约定（再强调）

- 每个 Task 开始前先出**计划**，等确认
- 每次动代码后**立刻**更 CHANGELOG，不要攒
- drift 表改完必须跑 `dart run build_runner build --delete-conflicting-outputs` 并把生成文件也 commit
- 拿不准的业务逻辑（比如跨天时间点、新词顺序）停下来问，不要自行假设
- 本阶段重点就是：**FSRS 跑通 + 日志埋好 + 每日配额对接上**。其它诱惑（优化器、个性化参数、UI 动效、键盘快捷键）全部扔进 `FSRS_POST_LAUNCH_TODO.md`
