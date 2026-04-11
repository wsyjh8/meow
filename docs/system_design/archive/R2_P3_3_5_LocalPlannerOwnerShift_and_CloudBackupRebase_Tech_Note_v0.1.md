# R2_P3_3_5_LocalPlannerOwnerShift_and_CloudBackupRebase_Tech_Note_v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** tech framing / architecture-gate input / ready for Room 1 review
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Round:** `P3.3.5 — Local Planner Owner Shift / Cloud Backup Rebase Round`

---

## 0. 文档定位

本稿不是：
- 新 DB 主文档
- 新 API 主文档
- Room 4 执行单
- 直接 owner shift 的实施方案
- 完整复习系统重写稿
- planner merge / unified planner 的直接落地稿

本稿只做一件事：

> **从 Room 2 / CTO 视角，判断 P3.3.5 这轮“local planner owner shift + cloud backup rebase”是否值得推进、能推进到哪一层、哪些必须 staged rollout、哪些一旦下发就越界成 Major implementation / architecture rewrite。**

一句话：

> **方向可以讨论，但当前不宜直接 pin 成 runtime owner shift；更稳的推进方式，是先 pin“目标架构方向 + 迁移边界 + 兼容/弃用计划”的 staged architecture contract。**

---

## 1. 输入依据与采用口径

### 1.1 Governance / Role basis
- `ORG_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.2`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_5_ScopePin_and_Handoff_Pack_v0.1.md`
- `p3.3.5_user.md`

### 1.3 Review basis for this round
- `BR-OPP-001_v0.2.5.md`
- `UI_SPEC_v0.2.5.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `Main_updated_2026-04-10_v23.md`
- `STATUS_updated_2026-04-10_v22.md`

### 1.4 Room 2 对当前技术底座的采用口径
Room 2 当前继续明确采用以下现实：
1. **dual-store 继续成立**：cloud 继续承接 today aggregate / `review_group` / 奖励 / 结算 / 商店 / 签到等 serving / settlement 域；local 继续承接 FSRS scheduling / review logs / local settings / 设备侧运行态。
2. **P3.3.2 / P3.3.3 的 owner split 仍有效**：ReviewPage 的 queue / continuation / completion / settlement truth 当前仍由 cloud `review_group` 承接；local FSRS 仍是 device-side scheduling owner。
3. **P3.3.4 只是最小 preview 回归 + stronger bridge**：它没有改 DB schema、没有改 API core semantics、没有发生 planner owner shift。
4. **主机制 PRD 仍然明确“后端收口事实”与“本地优先、备份兜底”并存**：因此 P3.3.5 不是单点 feature 扩写，而是要处理“谁负责规划”和“谁负责最终事实”这两个层级是否一起改写。

---

## 2. Room 2 总判断

### 2.1 总结论
> **Room 2 认为 P3.3.5 这个方向“值得评估”，但当前不建议直接 pin 为 runtime owner shift。**

Room 2 当前正式推荐：

> **把 P3.3.5 收成一轮 staged architecture / migration gate，而不是一轮直接给 Room 4 的实现轮。**

### 2.2 为什么“值得评估”
因为当前产品与实现已经具备以下现实基础：
1. local FSRS / local scheduler 已经是真实存在的设备侧调度能力，而不是纯概念；
2. P3.1 已经把“本地优先 + 手动全量备份”写进主机制边界；
3. P3.3.2 / P3.3.3 / P3.3.4 已连续把 local 侧从 candidate input、preview、bridge 逐步推进到更强的存在感；
4. 若长期仍把复习 serving 完全锁在 cloud `review_group`，会持续出现 dual-store 语义拉扯，后面每次深化 review planning 都会卡在 owner split 上。

### 2.3 为什么“当前不能直接 pin”
因为当前 active BR / UI / DB / API / PRD 仍共同绑定以下事实：
1. 页面级 readiness truth 仍在 cloud review-serving layer；
2. ReviewPage serving truth owner 仍是 cloud `review_group`；
3. API / DB 仍保留 `GET /me/review-groups/next`、`POST /review-attempts`、`review_groups`、`review_group_items` 等 review-serving 现实；
4. 主机制 PRD 仍把“有效学习 / 有效复习 / 今日目标完成 / Session 完成 / streak 成立以后端为准”写成产品原则；
5. 一旦把 owner shift 误写成 runtime truth，就会同步冲击 BR / DB / API / UI / TEST 五个面。

所以 Room 2 的结论不是“不要做”，而是：

> **先冻结 target-state 与 staged rollout contract，再决定是否给下一轮更窄的 execution gate。**

### 2.4 Room 2 一句话立场
> **P3.3.5 应进入“目标架构方向 + 迁移边界 + 兼容 / 弃用计划”的合同层；不应直接进入“本地已接管复习 serving truth”的运行态层。**

---

## 3. Q1 — `planner_owner_shift_v2`

### 3.1 Room 2 结论
> **从技术方向上，local FSRS / local scheduler 升格为 future primary planner owner 是可以成立的；但当前只适合作为 target-state candidate，不适合直接写成 current runtime truth。**

### 3.2 Room 2 推荐的“目标架构拆分”
Room 2 建议把“planner owner”拆成三个层级，避免一刀切：

#### A. scheduling owner
- 目标方向：**local**
- 负责：due / overdue / interval / stability / difficulty / local review session generation candidate

#### B. serving owner
- 当前运行态：**cloud**
- 目标方向：未来可切向 **local-serving contract**
- 负责：ReviewPage 当前真正显示与消费的队列 / continuation / completion / group lifecycle

#### C. fact / settlement owner
- 当前运行态：**cloud**
- 本轮不建议切走
- 负责：有效复习事实、今日目标完成事实、奖励结算、账本、签到 / streak 相关最终业务事实

### 3.3 Room 2 正式推荐
P3.3.5 当前最多只建议 Room 1 pin 到：

> **“local 作为 future primary scheduling owner 的方向被接受；serving owner 与 fact / settlement owner 的切换必须 staged，不可一轮并切。”**

### 3.4 当前不建议直接 pin 的表述
以下表述当前都过深：
1. `local 已是 ReviewPage primary truth owner`
2. `cloud 不再裁定复习事实`
3. `review_group 已退出运行态`
4. `本地已完全接管复习主链路`
5. `owner shift 已完成`

---

## 4. Q2 — `review_serving_contract_v2`

### 4.1 Room 2 结论
> **本轮可以讨论 `review_serving_contract_v2`，但只建议 pin “future local-serving target + current compatibility reality”，不建议直接把 local due queue 写成 current serving truth。**

### 4.2 Room 2 推荐的最小目标形态
未来若进入 v2，Room 2 认为最自然的方向是：
1. ReviewPage 的队列来源改为 **local due cards / local generated review session**；
2. `review_group` 退出 primary runtime serving path；
3. cloud 只保留：
   - backup / restore container
   - optional aggregate / analytics support
   - 非复习规划域（奖励 / 商店 / 装备 / 签到 / 账户）

### 4.3 但当前不能直接这样写死的原因
因为现有运行态还没解决以下关键技术断点：
1. local queue 与 current reward / settlement chain 如何对接；
2. local review completion 如何被后端可靠接收为“有效复习事实”；
3. `review_group` 退场后，`/me/today` 和页面 readiness / progress summary 由谁汇总；
4. local-only serving 下，多设备 restore 后如何避免“本机计划事实”和“云端旧 summary”冲突。

### 4.4 Room 2 对 `review_group` 的正式建议
> **当前最稳的技术建议不是“全废弃”，而是“进入 compatibility / deprecation path”。**

Room 2 建议把 `review_group` 视为：
1. **current runtime owner**（现在）
2. **compatibility-serving layer**（中间态）
3. **deprecated candidate**（未来）

也就是说：
- 当前不直接删
- 中期不再扩它
- 未来等 local-serving + fact-sync contract 落地后，再决定是否彻底退场

---

## 5. Q3 — `session_entry_and_routing_v2`

### 5.1 Room 2 结论
> **本轮不建议直接重写首页默认入口或放开 auto-routing。**

### 5.2 原因
当前 active 合同仍是：
- `home_word_entry = study_default`
- active `review_group` continuation 高优先，但不得 silent reroute

一旦本轮同时做：
1. owner shift
2. serving rewrite
3. 首页默认入口重写
4. auto-routing 候选

就会把 P3.3.5 从 contract / architecture round 直接拉成大重构轮。

### 5.3 Room 2 当前推荐
P3.3.5 最多只建议 pin：
1. **未来如果 local-serving 成立，首页可进入 planner-aware entry 候选阶段**；
2. 但当前 runtime 继续保持：
   - `study_default`
   - no silent reroute
   - no auto-routing runtime contract

### 5.4 Room 2 不建议本轮直接进入的 routing 内容
1. local planner 自动决定 Study / Review / Mixed
2. 首页点击“背单词”后 silent jump to review
3. unified Study / Review page
4. planner-winner 直接重写 CTA 事实层

---

## 6. Q4 — `preview_and_explanation_contract_v2`

### 6.1 Room 2 结论
> **若 P3.3.5 只是 architecture round，则 `preview_and_explanation_contract_v2` 当前只适合记录“未来可能随 owner shift 变化”，不建议在本轮直接升格。**

### 6.2 原因
当前 `previewDurations` 才刚被 pin 到：
- local preview candidate
- StudyPage only
- estimated / reference-only hint
- 不参与 readiness / priority / routing / settlement

如果在 owner shift 仍未被 pin 的情况下，提前把 preview 升级为：
- ReviewPage 可见
- 更像 plan fact
- explanation system 主层

就会直接制造页面假事实。

### 6.3 Room 2 当前推荐
本轮只建议 Room 1 pin：
1. **若未来 local-serving 成立，preview / explanation contract 需要重写；**
2. **在 owner shift 未被正式 pin 前，P3.3.4 的 preview 边界继续有效。**

也就是：
- 继续 StudyPage only
- 继续 hint-only
- 继续 estimated / reference-only
- 继续禁止 ReviewPage preview
- 继续禁止“系统已安排 / 下次将在 X 天后复习 / 已同步计划”等表述

---

## 7. Q5 — `backup_restore_and_cross_device_boundary_v2`

### 7.1 Room 2 结论
> **这一组是 P3.3.5 最值得提前 pin 的部分之一。**

如果未来 local 要成为 primary planner owner，那么 backup / restore 的边界必须先写清；否则 owner shift 会把多设备与恢复风险放大。

### 7.2 Room 2 推荐的最小安全边界
Room 2 建议当前先 pin 以下合同：

#### A. backup payload boundary
- 未来 backup 若承接 planner owner shift，必须能覆盖：
  1. local FSRS card state
  2. local review logs
  3. local settings 中影响规划的项
  4. planner schema version / payload version
- 但这当前仍是 **contract candidate**，不是已 fully landed reality

#### B. restore authority boundary
- restore 继续 **manual only**
- restore 必须 **pre-check + warning + confirm**
- restore success ≠ sync success
- restore apply 之后，目标设备本地状态才成为新 runtime truth

#### C. cross-device truth boundary
- 在不做 real-time sync / auto merge 的前提下，**每台设备自己的本地 planner state 都是该设备当下 runtime truth**
- 云端 latest backup 只是 recovery artifact，不是 live serving truth
- “哪台设备为准”不能靠静默策略决定，只能靠用户显式 restore / apply 触发

#### D. semantics floor
必须继续严格分开：
1. `backup success`
2. `snapshot fetched / download success`
3. `restore apply success`
4. `live sync success`（当前仍 out of scope）

### 7.3 Room 2 一句话建议
> **如果 Room 1 只想在 P3.3.5 pin 一层最有价值、最不容易反悔的合同，那么 backup / restore / cross-device boundary 是最值得先 pin 的。**

---

## 8. Q6 — `migration_and_deprecation_plan_v1`

### 8.1 Room 2 结论
> **必须 staged rollout。**

Room 2 不支持任何“先让 Room 4 直接改，后面再补迁移方案”的做法。

### 8.2 Room 2 推荐的 staged rollout

#### Phase 0 — Architecture / Contract Gate（当前 P3.3.5）
只做：
1. target-state 是否值得进入
2. 哪些 owner 会变
3. 哪些当前不变
4. backup / restore / deprecation 边界
5. Major 红线

#### Phase 1 — Compatibility Contract Round
只做：
1. `review_group` compatibility posture
2. new local-serving candidate contract
3. fact / settlement ingest contract 候选
4. deprecation markers
5. shadow / parity test strategy

#### Phase 2 — Limited Execution / Shadow Mode
只在 Room 1 单独 pin 后考虑：
1. dev / flag 下 local-serving shadow run
2. parity checks
3. no-user-facing owner-shift claim

#### Phase 3 — Cutover / Cleanup
只在以下条件满足后才考虑：
1. local-serving + fact-sync path 稳定
2. backup / restore contract 可测
3. deprecated cloud paths 有替代方案
4. Room 1 / User 再次拍板

### 8.3 Room 2 推荐的 deprecated candidate 清单
当前可进入“未来可能 deprecated”的候选包括：
1. `GET /me/review-groups/next`
2. `review_groups`
3. `review_group_items`
4. cloud readiness / generation 相关聚合字段
5. 只服务于 cloud review-serving 的中间解释层

但当前 **都只能记为 deprecated candidate，不得写成当前已退场。**

---

## 9. Room 2 推荐进入层 / 不进入层

## 9.1 推荐进入层（Room 1 当前可 pin）
1. **`planner_owner_shift_v2` 进入 target-state candidate 层**
   - 方向上接受“local 可成为 future primary scheduling owner”
   - 但不写成 current runtime owner shift

2. **`review_serving_contract_v2` 进入 migration-target 层**
   - 定义 future local-serving 方向
   - 明确 `review_group` 当前先走 compatibility / deprecation path

3. **`session_entry_and_routing_v2` 只进入 freeze-later note 层**
   - 明确若 owner shift 成立，入口 / routing 将受影响
   - 当前 runtime 继续保持 `study_default` + no silent reroute

4. **`backup_restore_and_cross_device_boundary_v2` 进入最小安全合同层**
   - manual only
   - no real-time sync
   - no auto merge
   - restore apply 才改变目标设备 runtime truth
   - 三层 success 语义严格分离

5. **`migration_and_deprecation_plan_v1` 进入 staged rollout 合同层**
   - 明确必须 Phase 0 / 1 / 2 / 3
   - 明确 deprecated candidate 与 current runtime truth 分开

## 9.2 当前不建议进入层
1. current runtime owner shift
2. local 已接管 ReviewPage serving truth
3. auto-routing runtime
4. unified planner / planner merge
5. ReviewPage preview explanation 升格
6. ReviewPage / 首页基于 local planner 直接改主 CTA 事实
7. DB schema 直接重构
8. API core semantics 直接重写
9. `review_group` 直接硬删
10. full sync / real-time sync / auto merge

---

## 10. Major 红线（Room 2 明确写死）

以下动作一旦出现，Room 2 视为 **Major implementation / architecture rewrite**，不得在无二次 gate 的情况下交给 Room 4：

1. **把 local FSRS 直接写成 current ReviewPage truth owner**
2. **删除或绕空 `review_group` 但不提供兼容 / 迁移方案**
3. **改写 `/me/today`、`GET /me/review-groups/next`、`POST /review-attempts` 的核心语义**
4. **让本地 planner 直接决定 reward / settlement / daily_goal 最终事实**
5. **把 backup / restore 写成 real-time sync / auto merge / auto recovery**
6. **修改 DB schema / API core semantics 但不先写 deprecation 与 staged rollout**
7. **把 preview / explanation 写成 owner shift 已完成的页面事实**
8. **把首页默认入口与 routing 一并重写成 planner-driven runtime 行为**

---

## 11. Room 2 给 Room 1 的最小可 pin 合同集合

Room 2 当前建议 Room 1 若要继续推进 P3.3.5，可只 pin 以下最小集合：

### A. 方向层
- `local primary planner owner` 当前可作为 **future target-state candidate** 进入主线程
- 当前不自动改写 runtime owner

### B. 迁移层
- `review_group` 当前进入 **compatibility / deprecation path** 候选
- 当前不直接退场

### C. 入口层
- `session_entry_and_routing_v2` 当前只记录“未来会受影响”，不改 runtime entry

### D. 备份层
- `backup_restore_and_cross_device_boundary_v2` 可以先 pin：
  - local runtime truth per device
  - cloud snapshot = recovery artifact
  - restore apply 才改变目标设备 truth
  - manual only / no real-time sync / no auto merge

### E. 迁移方法层
- `migration_and_deprecation_plan_v1` 必须 staged rollout
- 不允许跳过 compatibility / shadow / parity thinking 直接切主链路

---

## 12. Room 2 最终一句话结论

> **P3.3.5 方向值得做，但当前只值得把它收成“目标架构方向 + backup/restore 安全边界 + review_group 兼容/弃用计划”的 staged architecture contract；不值得直接 pin 成 runtime owner shift，更不应直接下发 Room 4 实现。**

