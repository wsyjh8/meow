# BR 差异报告：旧文档 vs 代码现状

> **旧文档**: `BR-OPP-001_v0.1.9_full.md`（业务规则完整基线）
> **代码现状**: `current-br.md`（从代码反推，基准 commit bface75）
> **生成日期**: 2026-04-08

---

## 一、产品定位与架构

### BR-D001 产品定位一致性

**位置**: 旧文档 &sect;BR-001 / current-br.md &sect;产品概述
**旧文档**: 定位为"学习驱动型轻养成产品"，主机制为产品主线，副机制为承接学习结果的陪伴与成长层。
**代码实际**: "背单词喵喵"将单词学习与虚拟猫养成结合。代码结构符合主副机制分离：主机制（学习/复习/目标/Session/签到）产生事件和奖励，副机制（猫养成/商店/装备）消费这些奖励。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注一致。

---

### BR-D002 单用户开发模式

**位置**: 旧文档无对应 / current-br.md &sect;用户角色
**旧文档**: 未提及单用户/多用户模式。
**代码实际**: 硬编码 `DEV_USER_ID = 'dev-user-001'`，单用户开发模式。后端使用内存存储 + PG 持久化。
**实现状态**: [已实现]
**建议动作**: 写入新文档。这是开发阶段的实现细节，旧 BR 作为规则文档不涉及此层。

---

### BR-D003 本地端 FSRS 调度系统

**位置**: 旧文档 &sect;BR-014 / current-br.md &sect;模块 2: FSRS 记忆调度
**旧文档**: BR-014 将完整 SRS/复习调度算法列为 Pending，review_group 仅定义为"后端生成、后端持有的一次有限复习批次对象"。
**代码实际**: 本地端实现了完整的 FSRS 记忆调度系统：fsrs pub.dev 库封装、4 级评分（again/hard/good/easy）、卡片状态机（Learning/Review/Relearning）、`desiredRetention=0.9`、learningSteps=[1min,10min]、relearningSteps=[10min]、到期卡片查询、调度预览、review_log 不可变写入。
**实现状态**: [已实现]（本地端）
**建议动作**: 写入新文档。旧 BR 将 SRS 列为 Pending，但本地端已实现完整 FSRS。需确认本地 FSRS 与云端 naive review group 的关系定位。

---

## 二、单词学习模块

### BR-D004 学习提交的幂等性实现

**位置**: 旧文档 &sect;BR-005 / current-br.md &sect;模块 1
**旧文档**: "所有会推进进度或发奖的关键写操作必须幂等，且不得重复发奖。"
**代码实际**: `submitStudyAttempt` 通过 `x-idempotency-key` 头保障幂等。重复检测：同一 `word_id + study_type` 且 `action_result` 相同返回 `alreadyExists: true`。从 `forgot` 升级到 `know` 允许更新。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注已符合 BR-005。

---

### BR-D005 目标值范围差异

**位置**: 旧文档无精确范围定义 / current-br.md &sect;模块 1 + 模块 4
**旧文档**: BR-024 仅声明 `1-500` 为 Room 2 recommended validation range，未升格为 frozen business rule。
**代码实际**: 云端目标范围为 `Math.max(1, Math.min(100, Math.floor(value)))`（1-100）。本地端设置页允许 1-500。两端范围不一致。
**实现状态**: [已实现]（但云端与本地端范围不一致）
**建议动作**: 需用户确认。云端 1-100 vs 本地端 1-500 的范围差异需要对齐。旧 BR 将此保留为 Pending Decision (PD-006)。

---

### BR-D006 未掌握词重现规则

**位置**: 旧文档无精确定义 / current-br.md &sect;模块 1
**旧文档**: 未定义 `forgot` 标记词是否重现。
**代码实际**: `action_result === 'forgot'` 的词不从出词池中排除，会重新出现。仅 `action_result === 'know'` 的词被排除。
**实现状态**: [已实现]
**建议动作**: 写入新文档。这是代码新增的具体实现规则。

---

### BR-D007 批量词库下载

**位置**: 旧文档无对应 / current-br.md &sect;模块 1（批量词库下载）
**旧文档**: 无词库下载的业务规则。
**代码实际**: `GET /api/v1/books/:bookId/words?offset=0&limit=500`，最大 1000。移动端通过 `WordCacheService.downloadAndCacheBook()` 分页下载到本地 `cached_words` 表，`INSERT OR REPLACE` 保证幂等。
**实现状态**: [已实现]
**建议动作**: 写入新文档。

---

## 三、复习模块

### BR-D008 云端 vs 本地端复习系统差异

**位置**: 旧文档 &sect;BR-014 / current-br.md &sect;模块 3
**旧文档**: review_group 定义为"后端生成、后端持有的一次有限复习批次对象"，group size 等细节为 Pending。
**代码实际**: 云端和本地端存在显著差异：

| 维度 | 云端 | 本地端 |
|------|------|--------|
| 复习词选取 | `word_id.startsWith('word-r-')` 硬编码 | FSRS `due <= now` 到期队列 |
| 组大小 | 固定 3 | 无组概念，直接队列 |
| 评分系统 | 二元 correct/incorrect | 四级 again/hard/good/easy |
| 调度算法 | 无调度 | FSRS 间隔重复 |
| 交错 | 无 | 复习:新词 = 3:1 |

**实现状态**: [已实现]（双端差异大）
**建议动作**: 需用户确认。云端 naive review group（固定 3 词，`word-r-*` 前缀筛选）是临时开发实现，与旧 BR 定义的"后端生成、后端持有"不矛盾但远未达到规划精度。本地端 FSRS 驱动的复习系统与云端的 review_group 概念完全不同。需明确后续收敛方向。

---

### BR-D009 review_group 最小业务契约符合度

**位置**: 旧文档 &sect;BR-014 / current-br.md &sect;模块 3
**旧文档**: (1) 同一用户同一时刻只允许一个 active group；(2) 同一 group 只能唯一完成、唯一结算、不得重复发奖；(3) "本组完成"只推进"今日复习进度"不等于"今日复习完成"。
**代码实际**: (1) `reviewGroups.find(g => g.group_status === 'active')` 最多一个 -- 符合; (2) `hasReviewGroupCompletedEvent` 去重检查防止重复发奖 -- 符合; (3) group 完成时 `today_review_completed += 1` 推进进度但不直接等于 daily goal completed -- 符合。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注 BR-014 最小业务契约已符合。

---

### BR-D010 本地端 SessionBuilder 交错规则

**位置**: 旧文档无对应 / current-br.md &sect;模块 3
**旧文档**: 无学习队列交错规则。
**代码实际**: `SessionBuilder.buildTodaySession()` 采用 3:1 比例交错排列复习和新词：`[R, R, R, N, R, R, R, N, ...]`，某一列表耗尽后直接追加剩余。
**实现状态**: [已实现]
**建议动作**: 写入新文档。

---

## 四、每日目标与签到

### BR-D011 daily_goal_status 判定口径

**位置**: 旧文档 &sect;BR-010 / current-br.md &sect;模块 4
**旧文档**: `daily_goal_status` 只由"今日新词目标 + 今日复习要求"共同决定；不包含 Session 和签到。当日无待复习时，复习要求自然满足。标准状态：not_started / in_progress / partially_completed / completed。
**代码实际**: 状态转换完全符合：
- `not_started`: `today_new_completed === 0 && today_review_completed === 0`
- `in_progress`: 有活动但两个子目标均未达成
- `partially_completed`: `newGoalMet XOR reviewGoalMet`
- `completed`: `newGoalMet && reviewGoalMet`

子目标判定：`newGoalMet = today_new_completed >= today_new_target`，`reviewGoalMet = today_review_completed >= today_review_target`。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注 BR-010 完全符合。

---

### BR-D012 签到三事实分离

**位置**: 旧文档 &sect;BR-007 / current-br.md &sect;模块 4
**旧文档**: `check_in` / `learning_day` / `streak` 是三类独立事实；当前 MVP `streak` 按 `check_in` 延续。
**代码实际**: 签到后 `streak.current_streak += 1`（基于 check_in），与 learning_day 独立。签到 != learning_day（两者独立事实）。`streak_basis_type` 支持 `'learning_day'` 值但当前固定为 `'check_in'`，受 `isStreakBasisSwitchEnabled = false` 守卫。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注 BR-007 已符合。

---

### BR-D013 daily_goal 即时生效不回溯

**位置**: 旧文档 &sect;BR-023 / current-br.md &sect;模块 4
**旧文档**: `daily_goal` 修改后本地保存即当天即时生效；不回溯重算历史。
**代码实际**: `PUT /api/v1/me/settings/daily-goal` 同时更新 PG `user_book_settings` 和内存 today_state，修改后立即重算 `daily_goal_status`。从代码看无历史回溯机制。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注 BR-023 已符合。

---

### BR-D014 今日状态跨日隔离

**位置**: 旧文档无精确定义 / current-br.md &sect;模块 4
**旧文档**: 三类自然日口径统一按 `local_date` 处理。
**代码实际**: 按日期键 `YYYY-MM-DD` 存储今日状态。新日自动创建时，从历史 `studyAttempts` 重算当日 `today_new_completed`（防跨日累积）。
**实现状态**: [已实现]
**建议动作**: 写入新文档。

---

### BR-D015 CTA 决策支持

**位置**: 旧文档 &sect;BR-009 / current-br.md &sect;模块 4
**旧文档**: CTA winner 规则层已冻结（单一强 CTA + continuation 优先 + 后端确认的高优先复习可胜出），但 `today_primary_action` 是否进入 active contract 仍 Pending。
**代码实际**: 云端已实现 `today_primary_action` 决策逻辑：
1. `active_review_group_id` 存在且 `remaining > 0` -> `continue_review_group`
2. `today_review_pending > 0` -> `go_review`
3. `session_started_today && !session_valid_today` -> `go_session`
4. 默认 -> `go_new_words`

但受 `isCTADecisionSupportEnabled = false` feature guard 守卫。
**实现状态**: [已开发·未集成]（代码存在但 feature guard = false）
**建议动作**: 写入新文档。代码已实现 CTA 决策逻辑但被 guard 关闭。旧 BR 将此定为 Pending Decision，代码提前实现但通过 guard 控制符合规划。

---

### BR-D016 本地设置项

**位置**: 旧文档无对应 / current-br.md &sect;模块 4（本地设置）
**旧文档**: 仅定义了 `daily_goal` 的业务规则。
**代码实际**: LocalSettingsService 包含 5 项设置：daily_goal(20)、sound_enabled(true)、theme('light')、notification_time('09:00')、desired_retention(0.9)。
**实现状态**: [已实现]
**建议动作**: 写入新文档。声音/主题/通知时间是代码新增的本地设置。

---

## 五、学习会话 (Session)

### BR-D017 Session 验证规则

**位置**: 旧文档 &sect;BR-011 / current-br.md &sect;模块 5
**旧文档**: MVP 阈值：正常启动 + 正常结束 + >= 15 分钟 + >= 5 次 effective attempts 总和 -> valid。
**代码实际**: `actualMinutes >= 15` AND `effectiveLearningCount + effectiveReviewCount >= 5` -> valid，否则 invalid。状态链 `started -> ended -> validating -> valid|invalid`。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注 BR-011 完全符合。

---

### BR-D018 Session 同时只一个

**位置**: 旧文档 &sect;BR-011 / current-br.md &sect;模块 5
**旧文档**: 隐含在 session 规则中。
**代码实际**: 同一时间只允许一个 `session_status === 'started'` 的 session，通过 active session 检查实现。
**实现状态**: [已实现]
**建议动作**: 写入新文档。

---

### BR-D019 有效学习/复习计数方式

**位置**: 旧文档 &sect;BR-011 / current-br.md &sect;模块 5
**旧文档**: `effective attempts` 指同一 `session_id` 下被后端最终计入有效事实的原子学习提交总数。
**代码实际**: 有效学习数 = session 开始后 `study_type === 'new' && action_result === 'know'` 的数量；有效复习数 = session 开始后 `action_result === 'correct'` 的数量。
**实现状态**: [已实现]
**建议动作**: 写入新文档。代码的计数逻辑具体化了旧 BR 的抽象定义。

---

## 六、奖励结算

### BR-D020 两层奖励结构

**位置**: 旧文档 &sect;BR-004 / current-br.md &sect;模块 6
**旧文档**: 奖励链路必须分两段：来源事件成立（可进入结算） + 奖励账本到账（最终发放）。
**代码实际**: 完全符合两层结构：
1. 源事件层（RewardSourceEvent）：`effective_new_word` / `review_group_completed`
2. 奖励账本层（RewardLedgerItem）：具体 coins/fish_treats/exp 条目

结算流程：createOrGetSourceEvent -> createSettlement -> 创建 ledger items。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注 BR-004 完全符合。

---

### BR-D021 奖励具体数值

**位置**: 旧文档无具体数值 / current-br.md &sect;模块 6
**旧文档**: BR-004/BR-005 定义了奖励结构和防重规则，但未定义具体奖励数值。
**代码实际**:
- `effective_new_word`（know 一个新词）: +2 coins, +1 exp
- `review_group_completed`（一组复习完成）: +5 coins, +1 fish_treat
**实现状态**: [已实现]
**建议动作**: 写入新文档。具体数值是代码定义的实现细节。

---

### BR-D022 reward_settlement_status 简化

**位置**: 旧文档 &sect;BR-008 / current-br.md &sect;模块 6 + 枚举值汇总
**旧文档**: 统一命名 `reward_settlement_status`，类型定义应包含完整状态链。
**代码实际**: 类型定义中 `RewardSettlementStatus` 包含 `pending | settling | succeeded | failed | claimed`，但 dev 模式下直接设为 `'succeeded'`。`settling`、`failed`、`claimed` 在代码中无转换路径。
**实现状态**: [已实现]（简化版，仅 succeeded 路径可达）
**建议动作**: 写入新文档。标注 dev 模式简化，`settling/failed/claimed` 转换路径待生产环境补全。

---

## 七、虚拟猫养成

### BR-D023 猫咪等级系统

**位置**: 旧文档无对应 / current-br.md &sect;模块 7
**旧文档**: BR 未定义猫咪具体等级/数值规则（属于副机制详细规则，BR &sect;1.2 声明不覆盖）。
**代码实际**: 完整等级系统已实现：Lv.1-10（累计 EXP: 0/20/50/90/145/215/305/420/565/745）、mood 计算（min(100, baseMood + fish_treats*5 + feedMoodAccumulated)）、bond 计算、energy 计算（但 'low' 状态不可达）。
**实现状态**: [已实现]
**建议动作**: 写入新文档。旧 BR 明确声明不覆盖副机制详细规则，代码中的具体数值需记录在其他文档中。

---

### BR-D024 喂食反作弊规则

**位置**: 旧文档无对应 / current-br.md &sect;模块 7
**旧文档**: BR 不覆盖副机制详细规则。
**代码实际**: 每日前 3 次喂食完整收益（mood+4, exp+2, bond+1），第 4 次起衰减收益（mood+1, exp+0, bond+0）。仅支持 `fish_treat` 类型，每次消耗 1 个。
**实现状态**: [已实现]
**建议动作**: 写入新文档。

---

### BR-D025 伴侣回应文案系统

**位置**: 旧文档无对应 / current-br.md &sect;模块 7
**旧文档**: BR 不覆盖具体文案系统。
**代码实际**: `getCompanionResponse` 实现三类文案：daily_greeting（基于学习/签到/默认状态选择文案池）、post_learning_response（基于 session/daily_goal/learning 状态）、streak_node_response（连续天数节点 [3,5,7,10,14,21,30,50]）。
**实现状态**: [已实现]
**建议动作**: 写入新文档。

---

## 八、商店/库存/装备

### BR-D026 商品目录与购买规则

**位置**: 旧文档无对应 / current-br.md &sect;模块 8
**旧文档**: BR &sect;1.2 声明不覆盖完整副机制商店域规则。
**代码实际**: 10 件商品（5 outfit + 5 room_item），4 种 slot（head/neck/decor/floor）。购买校验 4 项检查顺序：商品存在 -> 未拥有 -> 等级达标 -> 余额充足。不可堆叠。装备每 slot 一件。
**实现状态**: [已实现]
**建议动作**: 写入新文档。

---

## 九、备份与恢复

### BR-D027 三层成功语义

**位置**: 旧文档 &sect;BR-020 / current-br.md &sect;模块 9
**旧文档**: `upload success` / `download success` / `restore/apply success` 是三层不同语义，必须严格分开。
**代码实际**: 代码服务链明确分层：`SnapshotExportService`（本地导出）-> `BackupUploadService`（上传到云端）-> `BackupRestoreService`（下载并恢复）。云端为备份容器（内存存储，非持久化），不是同步系统。代码注释明确标注"备份是备份容器，不是同步系统"。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注 BR-020 已符合。

---

### BR-D028 restore manual-only + 安全边界

**位置**: 旧文档 &sect;BR-021, BR-022 / current-br.md &sect;模块 9
**旧文档**: restore 必须具备 pre-check + warning + confirm，不得 silent overwrite。Warning 须覆盖作用对象、覆盖风险、非自动同步定位。
**代码实际**: 恢复备份区受 `isRestoreEnabled` guard 守卫。实现了预检查（无备份/版本不支持/服务不可用时阻止）和确认弹窗（高风险操作标注）。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注 BR-021/BR-022 基本符合。需确认 warning 内容是否完整覆盖了"最小设置层(daily_goal)覆盖风险"。

---

### BR-D029 备份容器非持久化

**位置**: 旧文档无对应 / current-br.md &sect;模块 9 + 待确认事项
**旧文档**: 无备份存储持久化要求。
**代码实际**: 云端备份存储在内存中（`_latestBackup`、`_backupSnapshot`），非持久化。服务重启后丢失。
**实现状态**: [已实现]（开发阶段临时实现）
**建议动作**: 需用户确认。current-br.md 标注为 TODO 待确认项。

---

### BR-D030 P3.1 local-first 总定位

**位置**: 旧文档 &sect;BR-019A / current-br.md &sect;模块 9
**旧文档**: 系统采取 local-first + simple backup 总定位。本地运行态是真相源，云端只是 backup container。
**代码实际**: StudyPage 采用 local-first（SQLite 先写入 + API 后台同步）。备份明确标注为 backup container，不是 sync 系统。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注 BR-019A 已符合。

---

## 十、高风险边界用例符合度

### BR-D031 签到成功但无有效学习 (E-016)

**位置**: 旧文档 &sect;E-016 / current-br.md &sect;模块 4
**旧文档**: 应表达为 `check_in=true, learning_day=false`；streak 可按签到延续；不自动表达 daily_goal_status=completed。
**代码实际**: 签到后 `check_in_status = 'succeeded'`，`streak.current_streak += 1`。signing_day 独立于 check_in。daily_goal_status 仅由 newGoalMet && reviewGoalMet 决定，不含签到。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注 E-016 已符合。

---

### BR-D032 同一自然日重复签到 (E-017)

**位置**: 旧文档 &sect;E-017 / current-br.md &sect;模块 4
**旧文档**: 第二次签到只能失败或返回已存在。
**代码实际**: 每日最多一次签到（按 `local_date` 去重）。需 `x-idempotency-key`。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注 E-017 已符合。

---

### BR-D033 Session 计时达标但 attempts 不足 (E-011)

**位置**: 旧文档 &sect;E-011 / current-br.md &sect;模块 5
**旧文档**: 只有计时达标且 attempts >= 5 才 valid。
**代码实际**: `actualMinutes >= 15 AND effectiveLearningCount + effectiveReviewCount >= 5`，两者必须同时满足。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注 E-011 已符合。

---

### BR-D034 review_group 重复提交 (E-014)

**位置**: 旧文档 &sect;E-014 / current-br.md &sect;模块 3
**旧文档**: 同组重复提交不得重复发奖、不得重复推进进度。
**代码实际**: word 已完成返回 `alreadyExists: true`；group 已完成返回 `success: false, alreadyExists: true`；`hasReviewGroupCompletedEvent` 去重检查防止重复创建源事件。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注 E-014 已符合。

---

### BR-D035 learning_day 判定规则

**位置**: 旧文档 &sect;BR-007 / current-br.md &sect;业务规则汇总 BR-31
**旧文档**: `learning_day` 表示当日满足后端口径的有效学习行为。
**代码实际**: `effectiveLearningCount > 0 || effectiveReviewCount > 0` 即判定为 learning_day。
**实现状态**: [已实现]
**建议动作**: 写入新文档。具体口径为"有任何一次有效学习或有效复习即成立"。

---

## 十一、Feature Guards 与规则控制

### BR-D036 Feature Guard 体系对应 BR Pending Decisions

**位置**: 旧文档 &sect;3.2 (Pending) / current-br.md &sect;Feature Guards
**旧文档**: 列出 5 项 Pending Decision（熟练度阈值/SRS 算法/CTA 完整算法/统计页深度/streak basis 切换）。
**代码实际**: Feature Guards 精确对应 Pending Decisions：
- `isCTADecisionSupportEnabled = false` 对应 PD-004 (CTA winner 算法)
- `isStreakBasisSwitchEnabled = false` 对应 PD-001 (streak basis)
- `isStatisticsPageEnabled = false` 对应 PD-005 (统计页)
- `isReviewReadinessContractEnabled = false` 对应 PD-002 (review_group 算法)
- `isStreakExplanationEnabled = false` 对应 streak future stance

**实现状态**: [已实现]
**建议动作**: 写入新文档。Feature guard 体系完美对应 BR 的 Pending Decision 控制。

---

## 十二、旧 BR 规划但代码未实现的内容

### BR-D037 迁移/维护/只读降级语义 (BR-017, BR-018, BR-019)

**位置**: 旧文档 &sect;BR-017, BR-018, BR-019 / current-br.md 无对应
**旧文档**: 条件冻结规则：同源一致性、写操作降级语义、displayed snapshot != fresh backend truth。仅当 Room 1 pin Option A 时生效。
**代码实际**: `sync_status` 硬编码为 `'healthy'`。无 maintenance / read_only / temporarily_unavailable 机制。无降级态实现。
**实现状态**: [旧文档规划·未开发]（条件冻结规则，Room 1 未 pin Option A）
**建议动作**: 保留为 TODO。旧 BR 明确声明为"Conditional Frozen"，当前不需要实现。

---

### BR-D038 熟练度/掌握阈值 (BR-013)

**位置**: 旧文档 &sect;BR-013 / current-br.md 无精确定义
**旧文档**: Status = Pending。"什么叫已掌握"的算法与阈值未冻结。
**代码实际**: 云端仅以 `action_result === 'know'` 作为掌握判定（单次认识即掌握）。本地端有 FSRS 卡片状态机（Learning -> Review -> Relearning），但无"已掌握"的明确阈值定义。
**实现状态**: [已实现]（简化版：单次 know = 掌握）
**建议动作**: 需用户确认。当前云端"单次 know = 掌握"是否为 MVP 可接受方案，还是需要迭代到更精细的判定。旧 BR 明确要求"单次认识点击不得直接等于掌握"。

---

### BR-D039 完整 CTA winner 算法 (PD-004)

**位置**: 旧文档 &sect;BR-009 Pending Part / current-br.md &sect;模块 4
**旧文档**: 完整优先级算法、reason 枚举、loading/empty/error 下 CTA 策略均为 Pending。
**代码实际**: 基础 4 级优先级已实现（continue_review > go_review > go_session > go_new_words），但被 feature guard 关闭。缺少 loading/error fallback 策略。
**实现状态**: [已开发·未集成]
**建议动作**: 保留为 TODO。

---

### BR-D040 节点奖励进入 RewardLedger

**位置**: 旧文档 &sect;3.2 Pending / current-br.md 无对应
**旧文档**: 节点奖励是否同步进入 RewardLedger 仍为 Pending Decision。
**代码实际**: 当前奖励源事件仅有 `effective_new_word` 和 `review_group_completed`。签到/streak 节点奖励未进入奖励结算系统。伴侣回应中有 streak_node_response 文案，但无对应奖励发放。
**实现状态**: [旧文档规划·未开发]
**建议动作**: 保留为 TODO。

---

### BR-D041 input validation 覆盖度 (BR-024)

**位置**: 旧文档 &sect;BR-024 / current-br.md &sect;模块 4
**旧文档**: 非法输入不得静默失败，至少需覆盖：空值、非数字、小数、负数、0、超过上限、过长字符串、粘贴异常字符。
**代码实际**: 云端 `Math.max(1, Math.min(100, Math.floor(value || 20)))` 做了基础范围限制（静默 clamp 而非显式报错）。本地端设置页弹出对话框范围 1-500。
**实现状态**: [已实现]（但云端采用静默 clamp 而非显式报错）
**建议动作**: 需用户确认。旧 BR 要求"非法输入不得静默失败"，但云端 `Math.max/min/floor` 实际是静默 clamp 非法值到合法范围。是否需要改为显式拒绝？

---

## 十三、命名与术语

### BR-D042 命名统一符合度

**位置**: 旧文档 &sect;BR-008, &sect;6.2 / current-br.md &sect;枚举值汇总
**旧文档**: 统一命名 `daily_goal_status` / `session_validation_status` / `reward_settlement_status`。禁止 `session_reward_status` 等平行叫法。
**代码实际**: 枚举定义完全使用规范命名：`DailyGoalStatus`、`SessionValidationStatus`、`RewardSettlementStatus`。未发现平行旧叫法。
**实现状态**: [已实现]
**建议动作**: 写入新文档，标注 BR-008 已符合。

---

### BR-D043 状态枚举完整度

**位置**: 旧文档 &sect;BR-010, BR-011 / current-br.md &sect;枚举值汇总
**旧文档**: 定义了各状态的 canonical values。
**代码实际**: 所有规范枚举已定义，且额外包含了旧 BR 未提及的细分枚举：
- `DailyReviewProgressStatus`: not_started / in_progress / completed
- `NextGroupReadiness`: ready / not_ready
- `TodayPrimaryActionType`: 4 种 CTA 类型
- `TodayPrimaryActionReason`: 4 种 CTA 原因
- `ChangeHighlightKind` / `ChangeHighlightStatus`
- 本地端 `ReviewRating`（again/hard/good/easy）、`CardState`（1/2/3）
**实现状态**: [已实现]
**建议动作**: 写入新文档。代码枚举比旧 BR 定义更丰富。

---

## 十四、待确认事项（代码层面）

### BR-D044 云端 review group 词源筛选

**位置**: 旧文档无对应 / current-br.md &sect;待确认事项
**旧文档**: review_group 为后端生成。
**代码实际**: 词源筛选使用 `word_id.startsWith('word-r-')` 硬编码。current-br.md 标注为 TODO 待确认：PG 词库中是否有匹配数据。
**实现状态**: [已实现]（临时开发规则）
**建议动作**: 需用户确认。

---

### BR-D045 today_review_target 语义

**位置**: 旧文档 &sect;BR-014 / current-br.md &sect;待确认事项
**旧文档**: review_group 完成推进"今日复习进度"。
**代码实际**: 新建 review group 时 `today_review_target = 1`。current-br.md 标注为 TODO 待确认：含义是"完成 1 个 group"还是"完成 1 轮复习"。
**实现状态**: [已实现]（语义待确认）
**建议动作**: 需用户确认。

---

### BR-D046 SessionBuilder day boundary

**位置**: 旧文档 &sect;BR-007（local_date 处理） / current-br.md &sect;待确认事项
**旧文档**: 三类自然日口径统一按用户时区折算后的 `local_date` 处理。
**代码实际**: SessionBuilder 中 day boundary 使用 local midnight 00:00，代码注释 `TODO: configurable 4:00 AM`，当前未实现。
**实现状态**: [已实现]（使用 00:00，4AM 可配置未实现）
**建议动作**: 需用户确认。是否需要将 day boundary 改为 4:00 AM。

---

## 十五、汇总

| 类别 | 数量 | 编号 |
|------|------|------|
| 已符合旧 BR | 16 | BR-D001, D004, D009, D011, D012, D013, D017, D018, D019, D020, D027, D028, D030, D031, D032, D033, D034, D042 |
| 新增（代码有旧 BR 无） | 12 | BR-D002, D003, D006, D007, D010, D016, D021, D023, D024, D025, D026, D043 |
| 修改/差异 | 4 | BR-D005, D008, D015, D022 |
| 已开发未集成 | 2 | BR-D015, D039 |
| 旧文档规划未开发 | 3 | BR-D037, D038(部分), D040 |
| 需用户确认 | 6 | BR-D005, D008, D029, D038, D041, D044, D045, D046 |

### 关键发现

1. **旧 BR 的核心冻结规则在代码中基本全部符合**：daily_goal_status 判定、session 验证、签到三事实分离、两层奖励结构、幂等性、命名统一。

2. **代码新增了大量旧 BR 未覆盖的内容**：FSRS 本地调度系统、商店/装备完整规则、猫养成数值、伴侣文案系统、批量词库下载、Feature Guard 体系。这些大多属于旧 BR 明确声明"不覆盖"的副机制详细规则和实现细节。

3. **云端与本地端存在显著差异**：特别是复习系统（naive review group vs FSRS 调度）和目标范围（1-100 vs 1-500），需要明确收敛方向。

4. **旧 BR 的条件冻结规则(BR-017~019)均未实现**：这符合预期，因为 Room 1 未 pin Option A。

5. **Feature Guard 体系完美对应旧 BR 的 Pending Decision**：这是工程实践上的亮点，说明代码架构预留了规则演进空间。
