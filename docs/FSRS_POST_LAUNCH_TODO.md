# FSRS 上线后 TODO 清单

> 本阶段（Task 0-6）聚焦"FSRS 跑通 + 日志埋好 + 每日配额对接"。
> 以下是上线后要补的正式文档和未来优化项。

---

## 一、正式文档待补

- [ ] FsrsService 各方法 dartdoc（当前只有基本注释）
- [ ] SessionBuilder 正式 API 文档 + 契约说明
- [ ] review_logs 表数据字典（字段含义、取值范围）
- [ ] drift migration 操作指南（加表/改列的标准流程）
- [ ] 架构文档：`lib/core/memory/` 模块一节
- [ ] desired_retention 设置的帮助页面 / Tooltip
- [ ] 评分按钮 a11y 文档（Semantics label）
- [ ] 3↔4 按钮切换操作手册（已有 FSRS_DESIGN_DRAFT.md §4.2 草稿）

---

## 二、功能优化

### 2.1 fsrs-optimizer 个性化参数

- [ ] 累计 1000+ 条 review_logs 后，导出 JSONL 喂给 [fsrs-optimizer](https://github.com/open-spaced-repetition/fsrs-optimizer)
- [ ] 训练出个性化 21 参数，替换 `defaultParameters`
- [ ] 可在设置页加"优化我的记忆模型"入口

### 2.2 Learning steps 可配

- [ ] 当前 hardcode [1min, 10min]，留 TODO 给用户可配
- [ ] UI：设置页 Advanced 区域
- [ ] 持久化到 SharedPreferences

### 2.3 日切时间可配

- [ ] 当前固定本地 00:00 切天
- [ ] 夜猫子选项：04:00 AM 切天
- [ ] 存 SharedPreferences，SessionBuilder 读取

### 2.4 词库缓存更新策略

- [ ] 当前 `ensureCached` 只检查 count>0，不检查数据版本
- [ ] 加版本号/hash 对比，支持词库更新后增量同步
- [ ] 支持多本词书切换时的缓存管理

---

## 三、集成待完成

### 3.1 学习页接入 SessionBuilder

- [ ] 替换 `StudyService.getNextWord()`（API-driven）为 `SessionBuilder.buildTodaySession()`（local-driven）
- [ ] 学习页用 `FsrsRatingButtons` 替换现有"掌握/模糊"两按钮
- [ ] 每次评分调 `FsrsService.rateCard()` 而非 `ApiClient.submitStudyAttempt()`

### 3.2 复习页接入 FSRS

- [ ] 替换 `ApiClient.getNextReviewGroup()`（后端 review group）为 `SessionBuilder` 的到期卡
- [ ] 复习页用 `FsrsRatingButtons` 替换现有"忘记/正确"两按钮

### 3.3 旧 LocalDatabase 完整迁移

- [ ] `StudyService` 改用 drift AppDatabase 的 DAO
- [ ] `SnapshotExportService` 包含 card_states + review_logs + cached_words
- [ ] `BackupRestoreService` 能恢复 FSRS 数据
- [ ] 最终移除旧 `local_database.dart`

### 3.4 首页数据源切换

- [ ] 首页"本书进度"从 API `todayState` 改为本地 card_states 统计
- [ ] 首页"今日任务"从 API 改为 SessionBuilder 驱动

---

## 四、UI 增强（低优先级）

- [ ] 评分按钮动画（按下反馈）
- [ ] 键盘快捷键（1=Again, 2=Hard, 3=Good, 4=Easy）
- [ ] 学习进度环形图（基于 card_states 的 state 分布）
- [ ] 复习日历热力图（基于 review_logs 的 review_time_utc）

---

## 五、测试待补

- [ ] v1→v2 升级安装在真机上验证（当前只有内存 DB 测试）
- [ ] `WordCacheService.downloadAndCacheBook` 网络层集成测试
- [ ] 大数据量压力测试（10000+ card_states 的 listDueCards 性能）
