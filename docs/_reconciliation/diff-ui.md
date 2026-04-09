# UI 差异报告：旧文档 vs 代码现状

> **旧文档**: `UI_SPEC_v0.1.4.md`（主机制页面结构稿）
> **代码现状**: `current-ui.md`（从代码反推，基准 commit bface75）
> **生成日期**: 2026-04-08

---

## 一、导航架构与页面结构

### UI-001 底部导航架构重构

**位置**: 旧文档 &sect;2.1-2.2 / current-ui.md &sect;导航架构
**旧文档**: 未定义底部导航具体架构。主链路为 App 打开 -> 今日页 -> 学习/复习 -> 结算 -> 返回今日页。无 Tab Shell 概念，今日页为默认落点。
**代码实际**: 采用 `SpecShell` 6-Tab 底部导航栏：首页(SpecHomePage) / 词书(placeholder) / Mochi / 统计 / 我的 / 原版(Legacy TodayPage)。Tab 切换不触发路由栈变化。
**实现状态**: [已实现]
**建议动作**: 写入新文档。旧文档基于"今日页为唯一主入口"的单页面入口模型，代码已演进为 6-Tab 多入口架构。

---

### UI-002 SpecHomePage 替代今日页成为默认首页

**位置**: 旧文档 &sect;3 (页面一：今日页) / current-ui.md &sect;SpecHomePage
**旧文档**: 今日页(TodayPage)是 App 打开后默认落点，包含签到区、Session 区、任务卡、副机制摘要等丰富区块。
**代码实际**: 默认落点变为 `SpecHomePage`（Tab: home），信息层级精简为：问候语 -> Mochi 签到卡 -> 主 CTA "继续学习" -> 数字卡片(本书进度/错词本) -> 5 分钟快速复习入口。原始 TodayPage 降级为 legacy Tab（含 debug-only 警告 banner）。
**实现状态**: [已实现]
**建议动作**: 写入新文档。SpecHomePage 大幅精简了旧文档定义的今日页结构。

---

### UI-003 旧文档今日页六大区块 vs 代码实际

**位置**: 旧文档 &sect;3.D (D1-D6) / current-ui.md &sect;SpecHomePage + TodayPage
**旧文档**: 今日页定义六大区块：D1 顶部区（问候/词库/日期/streak）、D2 核心任务卡（新词目标/复习目标/主CTA）、D3 Session 区块、D4 签到区块、D5 副机制摘要区、D6 辅助信息区。
**代码实际**:
- SpecHomePage（新首页）：仅有问候语、Mochi 签到卡、主 CTA、数字卡片、快速复习。无独立 Session 区、无签到按钮、无副机制摘要区、无辅助信息区。
- TodayPage（Legacy）：保留了主 CTA（合约驱动）、今日目标进度、复习深度块、签到+连续天数区域、Session 卡片、伴侣卡片、猫咪主页入口、结算卡片。结构更接近旧文档但仍有差异。
**实现状态**: [已实现] SpecHomePage 为精简版; TodayPage 作为 Legacy 保留
**建议动作**: 写入新文档。需明确新首页采用精简策略，旧文档的详细区块定义仅 Legacy TodayPage 部分保留。

---

### UI-004 词书 Tab 为占位

**位置**: 旧文档无对应 / current-ui.md &sect;Tab 栏配置
**旧文档**: 未定义词书选择/切换的独立 Tab 页面。首次链路中提及"选词库/目标"。
**代码实际**: Tab 栏有"词书"Tab，但页面为 placeholder（"词书页尚未设计"）。
**实现状态**: [占位·未实现]
**建议动作**: 写入新文档，标注为占位。

---

### UI-005 我的页面(Profile)

**位置**: 旧文档无对应完整页面稿 / current-ui.md &sect;SpecProfilePage
**旧文档**: 无 Profile 页面独立定义。仅在今日页提及"弱化的设置入口"。
**代码实际**: `SpecProfilePage` 作为"我的"Tab 页，包含：用户身份区、当前词书卡、学习设置组（每日新词数量 -> 跳转 Settings、复习算法/学习提醒/发音均为 debugPrint 占位）、数据设置组（同步与备份 -> 跳转 Settings、导出学习记录 debugPrint 占位）、关于设置组。
**实现状态**: [已实现]（部分子页跳转为 debugPrint 占位）
**建议动作**: 写入新文档。这是代码新增的页面。

---

### UI-006 Mochi 页面（独立 Tab）

**位置**: 旧文档 &sect;2.3 (副机制界面边界) / current-ui.md &sect;SpecMochiPage
**旧文档**: 今日页只显示猫猫摘要卡/入口（弱入口），不展开喂猫与装扮操作。副机制主页是从今日页跳转进入的二级页面。
**代码实际**: `SpecMochiPage` 作为独立 Mochi Tab，展示猫咪大图、名称+天数+羁绊等级、进度条、主 CTA "学单词，赚小鱼干"跳转到 /study、4 个次级入口（换装/房间/零食柜/日记均为 debugPrint 占位）、日记预览。
**实现状态**: [已实现]（4 个次级入口为 debugPrint 占位）
**建议动作**: 写入新文档。Mochi 从旧文档的"弱入口"升级为独立 Tab。

---

### UI-007 统计页（独立 Tab）

**位置**: 旧文档 &sect;2.6 / current-ui.md &sect;SpecStatsPage
**旧文档**: 明确声明"统计页仍未展开成独立完整页面稿"，保留入口但不展开，属于 summary-first 策略。
**代码实际**: `SpecStatsPage` 已作为独立 Tab 实现，包含：已掌握 Hero 卡、三指标卡（连续/本周/记忆率）、12 周热力图（mock 数据，固定种子 Random(42)）、本周亮点、需要关注列表。但记忆率硬编码为 82%。
**实现状态**: [已实现]（数据为 mock/硬编码，未接入真实数据）
**建议动作**: 需用户确认。旧文档明确声明不展开统计页，但代码已实现独立 Tab。需确认是否正式纳入，以及 feature guard `isStatisticsPageEnabled = false` 与实际 Tab 可见的关系。

---

## 二、页面内容差异

### UI-008 新词学习页按钮差异

**位置**: 旧文档 &sect;4.D3 / current-ui.md &sect;StudyPage
**旧文档**: 操作区定义三个按钮：认识 / 不认识 / 稍后复习（或等价标记）。
**代码实际**: StudyPage 仅有两个按钮："模糊"(`_submitStudy('forgot')`) 和 "掌握"(`_submitStudy('know')`)。无"稍后复习"按钮。
**实现状态**: [已实现]
**建议动作**: 写入新文档。代码采用二元按钮（掌握/模糊），与旧文档三按钮设计不同。注意：代码中有 `FsrsRatingButtons` 组件（4 级评分：不认识/模糊/记得/秒答），但 StudyPage 和 ReviewPage 均未集成。

---

### UI-009 复习页评分系统差异

**位置**: 旧文档 &sect;5.D2-D3 / current-ui.md &sect;ReviewPage
**旧文档**: 复习页定义题目区含题干/选项/输入区、结果反馈区含当前题是否答对+下一题按钮。暗示存在选择题等多题型。
**代码实际**: ReviewPage 仅有两个按钮："忘记"(`_submitReview('incorrect')`) 和 "正确"(`_submitReview('correct')`)。纯展示 wordText + meaning，无选项/输入区。二元判断而非多题型。
**实现状态**: [已实现]
**建议动作**: 写入新文档。旧文档的"题型"概念在代码中简化为二元判断卡片。FSRS 4 级评分组件已开发但未集成。

---

### UI-010 FSRS 四级评分组件已开发未集成

**位置**: 旧文档无对应 / current-ui.md &sect;FSRS 评分按钮
**旧文档**: 无 FSRS 四级评分的 UI 定义。
**代码实际**: `FsrsRatingButtons` 组件已开发（不认识/模糊/记得/秒答，含颜色/图标/可选 interval 预览），但 StudyPage 和 ReviewPage 均未集成，仍使用旧版 2 按钮。
**实现状态**: [已开发·未集成]
**建议动作**: 写入新文档。标注为已开发未集成，待确认是否在下一阶段替换旧版 2 按钮。

---

### UI-011 结算页为占位

**位置**: 旧文档 &sect;6 (页面四：主机制结算浮层) / current-ui.md &sect;SettlementPage
**旧文档**: 详细定义了结算浮层的五大区域（标题/结果摘要/奖励展示/成长承接/操作区）、多种状态矩阵（正常/空/loading/异常/奖励/部分完成/全部完成/Session 有效无效/升级解锁/同步失败兜底）。
**代码实际**: `SettlementPage` 为纯占位页面，仅显示 "SettlementPage - Phase 1 暂不实现"，无任何数据依赖和交互。
**实现状态**: [占位·未实现]
**建议动作**: 写入新文档，标注为占位。旧文档对结算浮层有完整规格定义，代码尚未实现。

---

### UI-012 新词学习完成后的退出路径差异

**位置**: 旧文档 &sect;4.C / current-ui.md &sect;StudyPage
**旧文档**: 学习完成 -> 主机制结算浮层；用户主动退出 -> 返回今日页（需有确认或保存机制）。
**代码实际**: 全部学完 -> 展示"今日新词已学完" + "返回"按钮 -> `Navigator.pop(context)` 返回上层。无结算浮层跳转（因 SettlementPage 为占位），无退出确认机制。
**实现状态**: [已实现]（但绕过了结算浮层）
**建议动作**: 写入新文档。结算浮层未实现导致学习完成直接返回。

---

### UI-013 复习页组完成后的结算展示

**位置**: 旧文档 &sect;5.F6 / current-ui.md &sect;ReviewPage
**旧文档**: 组完成后不在题中段发大量奖励动画，统一在组完成结果或结算浮层承接。
**代码实际**: 本组完成时展示三层边界提示（组完成/今日进度/下一组可用性）+ "返回今日"按钮。如有 settlement 则通过 SnackBar 展示奖励状态。无结算浮层跳转。
**实现状态**: [已实现]（用 SnackBar 替代结算浮层）
**建议动作**: 写入新文档。当前用 SnackBar 轻量展示，与旧文档"统一在结算浮层"的设计不同。

---

### UI-014 签到页信息差异

**位置**: 旧文档 &sect;7.D / current-ui.md &sect;CheckInPage
**旧文档**: 签到区定义简版区块（今日签到状态/streak/立即签到/节点奖励预告）和展开层（月历/签到记录/节点奖励列表 3/7/14/30/今日奖励结果/learning_day 状态）。
**代码实际**: 签到页较简：未签到时显示"立即签到"按钮，已签到后显示连续签到卡片（currentStreak 天数）、今日学习卡片（learningDayToday 状态）、签到说明卡片（签到 != 学习日）、返回按钮。无月历、无节点奖励列表、无节点奖励预告。
**实现状态**: [已实现]（精简版）
**建议动作**: 写入新文档。月历和节点奖励展示为旧文档规划，代码实现了精简版本。

---

### UI-015 Session 页面状态拆分

**位置**: 旧文档 &sect;8.D / current-ui.md &sect;SessionPage
**旧文档**: 要求 Session 至少拆分 started / ended / validating / valid / invalid 五态，并有对应 UI 展示。
**代码实际**: Session 页面实现了三态：无 session（"开始 Session"按钮）、session 进行中（计时器+学习统计+结束按钮）、session 已结束（验证结果弹窗 valid/invalid/pending + "开始新 Session"按钮）。状态链 started -> ended -> 弹窗显示验证结果。
**实现状态**: [已实现]
**建议动作**: 写入新文档。代码实现基本符合旧文档要求的五态拆分精神，但以弹窗形式而非独立页面状态展示。

---

## 三、设计系统与视觉

### UI-016 两套 UI 设计系统并存

**位置**: 旧文档 &sect;1.3 (气质要求) / current-ui.md &sect;两套 UI 系统共存说明
**旧文档**: 定义统一气质要求（清爽/专注/温柔/可爱不低幼），未预见多套设计系统并存。
**代码实际**: 存在三套设计系统并行：(1) SPEC 设计系统（新版，用于 SpecHomePage/SpecMochiPage/SpecStatsPage/SpecProfilePage）；(2) Legacy 设计系统（MeowColors/MeowTextStyles，用于 TodayPage/MeowHomePage/CustomizePage/InventoryPage/SettingsPage）；(3) 原生 Material 风格（用于 StudyPage/ReviewPage/SessionPage/CheckInPage/SettlementPage）。
**实现状态**: [已实现]
**建议动作**: 写入新文档。需记录当前多设计系统共存的现状，作为后续统一的基础。

---

### UI-017 SPEC Design Tokens 体系

**位置**: 旧文档无对应 / current-ui.md &sect;SPEC 设计系统
**旧文档**: 无 design token 定义。
**代码实际**: 完整的 token 体系已建立：SpecBg（7 色）、SpecText（8 色）、SpecBrand（3 色）、SpecTypo（字重仅 400/500，最小 11px，9 个预设样式）、SpecRadius（5 级）、SpecSpacing（7 值）、SpecShadow（零阴影原则+唯一 floater 例外）。
**实现状态**: [已实现]
**建议动作**: 写入新文档。完整 design token 体系是代码新增内容。

---

### UI-018 SPEC 卡片组件库

**位置**: 旧文档无对应 / current-ui.md &sect;组件库
**旧文档**: &sect;9 提到跨页面统一组件建议（任务状态标签/奖励展示组件/错误提示/首次引导），但无具体实现定义。
**代码实际**: 5 种卡片组件已实现：SpecCardFilled、SpecCardOutlined、SpecCardHero（含猫爪水印）、SpecCardMochiWarm、SpecCardStatsHero。另有 SpecSettingsGroup/SpecSettingsRow、MochiAvatar/MochiLarge 等。
**实现状态**: [已实现]
**建议动作**: 写入新文档。

---

## 四、数据与状态

### UI-019 主 CTA 合约驱动 vs 静态路由

**位置**: 旧文档 &sect;3.D2 / current-ui.md &sect;SpecHomePage + TodayPage
**旧文档**: 主 CTA 根据状态机动态切换（未开始/继续本组复习/先去复习/继续完成/再学一点），由后端返回决定，标注为 Pending Decision。
**代码实际**:
- SpecHomePage：主 CTA "继续学习" 硬编码跳转 `/study`，无状态驱动。
- TodayPage（Legacy）：主 CTA 根据 `TodayPrimaryActionData` 合约驱动，支持 `continue_review_group -> /review`、`go_review -> /review`、`go_session -> /session`、`go_new_words -> /study` 四种。
**实现状态**: [已实现] TodayPage 合约驱动; SpecHomePage 静态跳转
**建议动作**: 写入新文档。需明确 SpecHomePage 当前采用静态 CTA，TodayPage 保留了合约驱动。

---

### UI-020 Feature Guards 体系

**位置**: 旧文档无对应 / current-ui.md &sect;Feature Guards
**旧文档**: 未定义 feature guard 机制。
**代码实际**: `P3FeatureGuard` 含 12 个编译时静态常量开关，其中 4 个已启用（isRestoreEnabled / isDailyGoalSettingEnabled / isManualUploadEnabled / isDownloadToLocalEnabled），8 个为 false（isStatisticsPageEnabled / isCTADecisionSupportEnabled / isStreakBasisSwitchEnabled / isReviewReadinessContractEnabled 等）。
**实现状态**: [已实现]
**建议动作**: 写入新文档。Feature guard 体系是代码新增的重要架构决策。

---

### UI-021 本地端数据架构（Local-first）

**位置**: 旧文档无对应 / current-ui.md &sect;StudyPage + 本地存储服务
**旧文档**: 未定义本地数据存储架构。UI 字段依赖表假设数据来自 API。
**代码实际**: StudyPage 采用 local-first 架构：SQLite 先写入 + API 后台 fire-and-forget 同步。LocalDatabase（SQLite via drift）用于学习记录写入、FSRS 卡片状态存储、备份导出快照。LocalSettingsService（SharedPreferences）存储每日目标等本地设置。
**实现状态**: [已实现]
**建议动作**: 写入新文档。Local-first 架构是重要的实现决策。

---

### UI-022 设置页实际内容

**位置**: 旧文档无独立设置页定义 / current-ui.md &sect;SettingsPage
**旧文档**: 今日页仅提及"弱化的设置入口"。
**代码实际**: SettingsPage 包含：每日学习目标区（受 isDailyGoalSettingEnabled 守卫，范围 1-500，弹出对话框）、记忆设置区（记忆保留率 Slider 0.85-0.95）、数据备份区（导出+上传）、恢复备份区（受 isRestoreEnabled 守卫，含预检查+确认弹窗）。
**实现状态**: [已实现]
**建议动作**: 写入新文档。设置页是代码新增的完整页面。

---

## 五、旧文档规划但未开发的功能

### UI-023 迁移/维护/只读降级态

**位置**: 旧文档 &sect;3.F11, &sect;9.6 / current-ui.md 无对应
**旧文档**: 详细定义了 `sync_status=delayed` / `read_only=true` / `maintenance=true` / `temporarily_unavailable=true` 四种降级态的 UI 表现，含最小可观察结果表。
**代码实际**: 代码中 `sync_status` 在 TodayState 中硬编码为 `'healthy'`。无任何降级态 UI 实现，无 read_only/maintenance/temporarily_unavailable 的前端处理。
**实现状态**: [旧文档规划·未开发]（条件冻结规则，仅当 Room 1 pin Option A 时生效）
**建议动作**: 保留为 TODO。旧文档明确声明这些是"条件冻结"，不阻塞当前实现。

---

### UI-024 首次引导态

**位置**: 旧文档 &sect;3.F5, &sect;4.F5, &sect;5.F5, &sect;7.F5, &sect;8.F5
**旧文档**: 每个关键页面都定义了首次引导态（高亮提示点，每页不超过 2 个）。
**代码实际**: 无任何首次引导态实现。
**实现状态**: [旧文档规划·未开发]
**建议动作**: 保留为 TODO。

---

### UI-025 骨架屏/Loading 态

**位置**: 旧文档 &sect;3.F3, &sect;5.F3, &sect;7.F3
**旧文档**: 定义了骨架屏策略（首次进入加载用骨架屏，局部刷新只在对应卡片内 loading）。
**代码实际**: 各页面使用简单的 CircularProgressIndicator 或条件渲染，无骨架屏组件。
**实现状态**: [旧文档规划·未开发]（精细骨架屏）
**建议动作**: 保留为 TODO。

---

### UI-026 节点奖励展示

**位置**: 旧文档 &sect;7.D1, &sect;7.F6
**旧文档**: 签到区定义了节点奖励列表（3/7/14/30 天）、节点奖励预告、节点奖励日额外展示。
**代码实际**: 签到页无节点奖励列表展示。云端有 streak node 逻辑（连续天数节点 [3,5,7,10,14,21,30,50]），但签到 UI 仅显示当前 streak 天数。
**实现状态**: [旧文档规划·未开发]（UI 层未展示节点奖励，但后端有对应逻辑）
**建议动作**: 保留为 TODO。

---

### UI-027 旧文档统一状态标签与统一命名

**位置**: 旧文档 &sect;1.5, &sect;1.7, &sect;9.1-9.2
**旧文档**: 定义了统一页面状态语言（未开始/进行中/部分完成/已完成/待校验/结算成功等 10 种）、统一命名约定（reward_settlement_status / session_validation_status / daily_goal_status）、统一奖励展示组件规格。
**代码实际**: 状态枚举在类型定义中存在（DailyGoalStatus / SessionValidationStatus / RewardSettlementStatus 等），但 UI 层无统一的状态标签组件或奖励展示组件。各页面独立处理状态展示。
**实现状态**: [已开发·未集成]（类型定义存在，统一 UI 组件未实现）
**建议动作**: 写入新文档。类型层已有命名统一，但 UI 组件层未统一。

---

## 六、MeowHome / Customize / Inventory 差异

### UI-028 MeowHomePage 实际功能

**位置**: 旧文档 &sect;2.3, &sect;9.6.2 / current-ui.md &sect;MeowHomePage
**旧文档**: 副机制主页只在 persistence hardening 附录中定义了降级最小契约，无完整页面稿。
**代码实际**: MeowHomePage 功能丰富：猫咪头像可点击（随机互动文案+3 秒冷却）、"喂小鱼干"按钮（含升级检测弹窗）、资源栏（金币/小鱼干/EXP）、成长卡片、今日亮点区（chips）、变化亮点区（change_highlights）、伴侣区（companionResponse）、装备区、统计摘要区、操作按钮区（装扮与小窝/收藏与商店跳转）。
**实现状态**: [已实现]
**建议动作**: 写入新文档。旧文档未给出完整页面稿，代码已实现了完整的副机制主页。

---

### UI-029 CustomizePage 装备系统

**位置**: 旧文档 &sect;9.6.3 / current-ui.md &sect;CustomizePage
**旧文档**: Customize 只在 persistence hardening 附录定义了降级最小契约（购买/装备写操作暂停时的只读禁用态）。
**代码实际**: 完整的装扮页面已实现：预览区（猫咪+装备槽位）、资源栏、攒钱目标提示（自动计算）、已拥有未装备提示、3 个 Tab（全部/已拥有/已装备）、物品卡片（购买/装备按钮）、4 个装备槽位（head/neck/decor/floor）。
**实现状态**: [已实现]
**建议动作**: 写入新文档。

---

### UI-030 InventoryPage 商店系统

**位置**: 旧文档无对应 / current-ui.md &sect;InventoryPage
**旧文档**: 无商店页面定义。
**代码实际**: 完整的收藏与商店页面已实现：余额卡片、我的收藏列表、商店列表（含购买按钮+各种错误提示：金币不足/已拥有/等级锁定）。
**实现状态**: [已实现]
**建议动作**: 写入新文档。

---

## 七、主 CTA / 交互逻辑差异

### UI-031 快速复习入口

**位置**: 旧文档无对应 / current-ui.md &sect;SpecHomePage
**旧文档**: 今日页定义复习入口为核心任务卡的 CTA（先去复习/继续本组复习）。
**代码实际**: SpecHomePage 有独立的"5 分钟快速复习"入口，直接跳转 `/review`。
**实现状态**: [已实现]
**建议动作**: 写入新文档。

---

### UI-032 Mochi 页主 CTA 跳学习

**位置**: 旧文档无对应 / current-ui.md &sect;SpecMochiPage
**旧文档**: 副机制页面不应主导学习链路。
**代码实际**: SpecMochiPage 有主 CTA "学单词，赚小鱼干"跳转到 `/study`。这在一定程度上是副机制引导主学习行为，但方向是鼓励学习而非反向干扰。
**实现状态**: [已实现]
**建议动作**: 需用户确认。此 CTA 是否违反"副机制不得反向主导主学习流程"的原则，需确认。

---

### UI-033 发音按钮

**位置**: 旧文档 &sect;4.D2, &sect;4.E / current-ui.md 无对应
**旧文档**: 新词学习页定义了发音按钮和播放发音操作。
**代码实际**: StudyPage 展示 wordText + phonetic + meaning，无发音按钮实现。
**实现状态**: [旧文档规划·未开发]
**建议动作**: 保留为 TODO。

---

### UI-034 例句展示

**位置**: 旧文档 &sect;4.D2 / current-ui.md 无对应
**旧文档**: 单词主卡区定义了例句（MVP 可折叠）。
**代码实际**: StudyPage 仅展示 wordText + phonetic + meaning，无例句。
**实现状态**: [旧文档规划·未开发]
**建议动作**: 保留为 TODO。

---

## 八、旧文档文案边界的代码符合度

### UI-035 签到 != 学习日 的 UI 表达

**位置**: 旧文档 &sect;7.G, &sect;7.K / current-ui.md &sect;CheckInPage
**旧文档**: 签到成功不能写成"完成有效学习日"，签到和学习日必须独立标注。
**代码实际**: CheckInPage 签到后展示"签到说明卡片"明确说明"签到 != 学习日"，并独立展示 `learningDayToday` 状态。符合旧文档要求。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注为已符合。

---

### UI-036 本组完成 vs 今日复习完成的区分

**位置**: 旧文档 &sect;5.G / current-ui.md &sect;ReviewPage
**旧文档**: "本组完成"不等于"今日复习完成"，必须双层口径区分。
**代码实际**: ReviewPage 本组完成时展示三层边界提示（组完成/今日进度/下一组可用性），符合双层口径。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注为已符合。

---

## 九、汇总

| 类别 | 数量 | 编号 |
|------|------|------|
| 新增 | 14 | UI-002, 004, 005, 006, 010, 016, 017, 018, 020, 021, 022, 028, 029, 030 |
| 修改 | 10 | UI-001, 003, 008, 009, 012, 013, 014, 019, 031, 032 |
| 占位/未实现 | 6 | UI-004, 011, 023, 024, 025, 026 |
| 已符合 | 3 | UI-015, 035, 036 |
| 需确认 | 2 | UI-007, 032 |
| 旧文档规划未开发 | 4 | UI-023, 024, 033, 034 |
