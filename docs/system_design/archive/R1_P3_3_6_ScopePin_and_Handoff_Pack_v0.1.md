# R1_P3_3_6_ScopePin_and_Handoff_Pack_v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** active / scope pin / unified handoff entry
- **Role basis:** `room1_v0.2.0.md`
- **Runtime basis:** `Main_updated_2026-04-10_v26.md` + `STATUS_updated_2026-04-10_v24.md`
- **Review basis for this round:**
  - `BR-OPP-001_v0.2.7.md`
  - `UI_SPEC_v0.2.7.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
  - `p3.3.6_user.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 user 已直接拍板的下一轮 focus：

> **P3.3.6 — Local-Serving Compatibility Contract / Shadow-Mode Entry Round**

正式收进主线程，并转译成一份 **统一 handoff 入口**，供 Room 2 / Room 3 / Room 5 在同一范围、同一问题集、同一交付口径下推进。

本文件不是：
- 新 PRD
- 新 BR 主文档
- 新 DB / API 主文档
- Room 4 执行任务单
- P3.3.6 closeout

本文件只做一件事：

> **在 P3.3.5 已完成 Phase 0 / Compatibility-Prep 的前提下，把 P3.3.6 收成 `Phase 1 — Compatibility Contract Round`：继续收口 local-serving 候选合同、`review_group` 兼容姿态、fact/settlement ingest 候选、routing 兼容层、deprecation/write-back 计划、以及 shadow/parity 测试策略，但当前仍不宣告 runtime owner shift 完成。**

---

## 1. 背景

当前推进层 SSOT 已明确：
- `P3.3.5` 已 close，并已被 Room 1 吸收为 **Phase 0 / Compatibility-Prep 已完成**；
- 当前 active BR / UI runtime baselines 仍是 `BR-OPP-001_v0.2.6.md` 与 `UI_SPEC_v0.2.6.md`；
- 新回写主文件 `BR-OPP-001_v0.2.7.md` 与 `UI_SPEC_v0.2.7.md` 已形成 **ready for Room 1 runtime-baseline update** 的 next-step candidate；
- `P3.3.5` 已明确：
  - `local primary planner owner` 目前只接受为 **future target-state candidate**
  - current serving truth 继续是 cloud `review_group`
  - `backup success / restore success / sync success` 必须严格区分
  - staged rollout 必须按 **Phase 0 → Phase 1 → Phase 2 → Phase 3** 推进

与此同时，`p3.3.6_user.md` 已把下一轮最自然的主题明确建议为：

> **Phase 1 — Compatibility Contract Round**
> 即：`P3.3.6 — Local-Serving Compatibility Contract / Shadow-Mode Entry Round`

一句话：

> **P3.3.6 不是 runtime owner shift / local-serving cutover 轮，而是把“未来 local-serving 怎么进入、`review_group` 如何兼容退场、fact/settlement ingest 怎么对接、shadow/parity 怎么验证”先收成下一层可被执行与测试引用的最小合同。**

---

## 2. 当前阶段命名

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.6 Scope Pin / Local-Serving Compatibility Contract Preflight

### 一句话定义

> **P3.3.6 不是“大切换轮”，而是把 P3.3.5 的 target-state candidate 继续推进到“更近执行、但仍不越界 cutover”的 Compatibility Contract / Shadow-Entry 层。**

---

## 3. Room 1 当前判断

### 3.1 总结论
> **P3.3.6 当前仍必须先走 contract / architecture round。**

原因很简单：
1. 当前 `P3.3.5` 只冻结到 future target-state candidate + compatibility/deprecation/shadow-prep。
2. 当前 runtime truth 仍是：
   - 首页 `study_default`
   - ReviewPage serving truth = cloud `review_group`
   - no auto-routing runtime
   - no planner merge
3. `p3.3.6_user.md` 本身也明确建议：P3.3.6 最自然的推进不是“大切换轮”，而是 **Phase 1 — Compatibility Contract Round**。
4. DB / API active baselines 仍是 `v0.2.1`，若下一层继续 owner-shift 方向，必须先有更具体的 compatibility / ingest / shadow 合同，再决定是否进入实现。

### 3.2 Room 1 当前不直接做的事
本轮 **不直接** 给 Room 4 下 cutover 实施单。  
先由 Room 2 / Room 3 / Room 5 做一轮专项输入，再由 Room 1 判断：
- 是否值得把 P3.3.6 pin 成 “Compatibility Contract v1”
- 哪些内容只进入 shadow
- 哪些仍必须继续 pending
- 是否已经足够产出一个 very narrow `R1 → R4 P3.3.6 Execution Handoff`

---

## 4. 本轮核心问题（Room 1 统一问题集）

本轮必须回答的不是零散讨论，而是以下 6 个主线程问题：

### Q1. `local_serving_candidate_contract_v1`
当前轮要不要正式推进：
- local due cards 的最小 serving 形态是什么
- local generated review session 的最小 serving 形态是什么
- ReviewPage future queue source 需要哪些字段 / 状态 / truth split
- 哪些仅能作为 shadow candidate，哪些能进入 compatibility contract

### Q2. `review_group_compatibility_posture_v1`
当前轮要不要正式推进：
- `review_group` 在 P3.3.6 后继续扮演 current runtime owner、还是进入更明确的 compatibility-only role
- `review_group` 与 local-serving candidate 的并存关系是什么
- 哪些页面 / 流程当前仍依赖 `review_group`
- 哪些点可以正式标成 deprecated candidate

### Q3. `fact_settlement_ingest_contract_candidate_v1`
当前轮至少要回答：
- 如果 future serving 往 local 靠，local-serving 产出的尝试结果如何被 cloud fact layer ingest
- 哪些最终事实仍以后端为准
- local 与 cloud 在 fact / settlement 上的最小接口是什么
- planner owner shift 为什么不自动带出 fact owner shift

### Q4. `session_entry_and_routing_compat_v1`
当前轮要不要正式推进：
- 首页是否继续 `study_default`
- active continuation 未来怎样兼容 local-serving candidate
- 哪些 routing 只进 shadow，不进 runtime
- auto-routing runtime 当前继续怎么保持 pending

### Q5. `deprecation_markers_and_writeback_plan_v1`
当前轮要不要正式推进：
- 哪些 API / DB / UI / helper / copy / state contract 进入 deprecated candidate
- 哪些 contract 进入 compatibility-only
- BR / DB / API / UI / TEST 各自要怎么回写
- 如何防止 silent contract drift

### Q6. `shadow_parity_test_strategy_v1`
当前轮要不要正式推进：
- local-serving shadow run 如何挂 flag
- parity checks 比什么
- 哪些结果只能写成 shadow evidence，不能写成 owner shift 已完成
- 哪些固定回归集需要在 Phase 1 先收硬

---

## 5. 本轮范围（In Scope）

### 5.1 Serving Compatibility
本轮纳入：
1. `local_serving_candidate_contract_v1`
2. `review_group_compatibility_posture_v1`
3. `session_entry_and_routing_compat_v1`

### 5.2 Fact / Settlement Ingest
本轮纳入：
1. `fact_settlement_ingest_contract_candidate_v1`
2. local-serving candidate 与 cloud fact layer 的最小 ingest 边界
3. 不同 owner 层的 truth split

### 5.3 Deprecation / Write-back / Shadow
本轮纳入：
1. `deprecation_markers_and_writeback_plan_v1`
2. `shadow_parity_test_strategy_v1`
3. staged rollout Phase 1 的最小测试与回写要求

### 5.4 只做 contract / architecture round
本轮纳入的是：
- future serving candidate
- compatibility posture
- fact ingest candidate
- routing compatibility
- deprecation / write-back plan
- shadow / parity strategy

本轮**不直接纳入** Room 4 cutover 实现。

---

## 6. 当前不纳入（Out of Scope）

以下内容 **不因 P3.3.6 自动纳入**：

1. runtime owner shift completed
2. ReviewPage local-serving runtime cutover
3. local due queue 直接接管当前 ReviewPage truth
4. `review_group` 直接删出运行态
5. auto-routing runtime
6. unified planner / planner merge
7. unified Study / Review page
8. ReviewPage preview re-entry
9. 完整 preview / explanation system 升级
10. DB schema 重构
11. API core semantics 重写
12. full sync / real-time sync / auto merge
13. 完整 SRS / 完整复习调度产品重写

---

## 7. 各 Room 任务分配

## 7.1 Room 2 — 技术 / 架构 framing 先行
### 任务
产出：
`R2_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Tech_Note_v0.1.md`

### 必答
1. `local_serving_candidate_contract_v1` 的最小技术合同是什么
2. `review_group_compatibility_posture_v1` 在技术上怎样并存最稳
3. `fact_settlement_ingest_contract_candidate_v1` 的最小接口是什么
4. `session_entry_and_routing_compat_v1` 哪些能进 shadow，哪些必须继续 pending
5. `deprecation_markers_and_writeback_plan_v1` 的技术落点在哪里
6. `shadow_parity_test_strategy_v1` 应如何设计 flags / seams / parity evidence
7. 哪些动作一旦出现就越界成 Phase 2 / Phase 3 或 API / DB Major

### Done
给出：
- 推荐进入层
- 推荐不进入层
- Major 红线
- Phase 1 compatibility contract 候选集合
- future Phase 2 shadow-entry 前置条件

---

## 7.2 Room 3 — 业务规则语义收口
### 任务
产出：
`R3_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Rules_Note_v0.1.md`

### 必答
1. `local_serving_candidate_contract_v1` 在业务上是什么意思
2. `review_group_compatibility_posture_v1` 在业务上是 current owner、compatibility role 还是 deprecated candidate
3. `fact_settlement_ingest_contract_candidate_v1` 在业务上如何定义“事实仍以后端为准”
4. `session_entry_and_routing_compat_v1` 的业务语义与禁区是什么
5. `deprecation_markers_and_writeback_plan_v1` 在规则层怎么写硬
6. `shadow_parity_test_strategy_v1` 哪些结论只能算 shadow evidence，不能升格为 runtime fact

### Done
给出：
- Frozen candidate
- Pending items
- Fact-copy / rule-boundary 护栏
- 可直接给 Room 1 吸收的决策句

---

## 7.3 Room 5 — UI / state contract 影响判断
### 任务
产出：
`UI_SPEC_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_UI_Preflight_v0.1.md`

### 必答
1. local-serving candidate 若进入 compatibility contract，首页 / Study / Review / helper / summary 会受什么影响
2. `review_group_compatibility_posture_v1` 在页面层如何表达 current truth 与 deprecated candidate
3. `fact_settlement_ingest_contract_candidate_v1` 会影响哪些页面事实 / 成功反馈 / 结算语义
4. `session_entry_and_routing_compat_v1` 会如何影响首页默认入口、continuation、shadow-only routing 提示
5. `deprecation_markers_and_writeback_plan_v1` 会影响哪些 helper / copy / state contract
6. `shadow_parity_test_strategy_v1` 在 UI 层有哪些不能被用户误读成“owner shift 已完成”的禁区

### Done
给出：
- 页面承接建议
- state contract risk
- fact-copy 禁区
- 最小 UI compatibility contract 层
- staged UI migration / shadow marker 建议

---

## 8. 执行顺序（固定）

### 顺序
1. **Room 2**
2. **Room 3**
3. **Room 5**
4. **Room 1**
5. **Room 4（仅在 Room 1 正式下发执行单后）**

### 为什么这样排
1. **Room 2 先行**
   - P3.3.6 本质上先是 serving / ingest / shadow / compatibility 的技术合同轮，不先看技术边界，后面都会飘。
2. **Room 3 第二**
   - 在 Room 2 的技术 framing 基础上，把业务语义、compatibility posture、事实边界与禁区写硬。
3. **Room 5 第三**
   - 基于 Room 2 + Room 3 的共同边界，判断 UI / state / helper / copy / shadow marker 影响，不提前把 pending 合同写成既成事实。
4. **Room 1 第四**
   - 统一吸收并决定：继续 preflight / pin Compatibility Contract v1 / 或再升级给 user 做更明确范围拍板。
5. **Room 4 最后**
   - 只有当 Room 1 明确下发 `R1 → R4` 执行单后，才允许进入实现治理 / 执行层。

---

## 9. 风险 / Blockers

1. **这是 Phase 1 compatibility contract round，不是 cutover round**
   - 若把 shadow / compatibility 误写成 runtime owner shift，会立即造成 BR / UI / TEST / 实现事实漂移。
2. **当前 runtime truth 仍在 cloud review-serving layer**
   - 任何“local 已接管 ReviewPage current truth”的表达，在本轮前都属于假事实。
3. **若不先写 fact/settlement ingest，后续 owner shift 会卡死**
   - 因为 planner owner shift 不自动带出 fact owner shift。
4. **若不先写 deprecation / write-back / shadow parity，后续一定出现 silent contract drift**
   - 特别是 `review_group`、helper / copy、API / DB candidate 与 UI state truth 的错位。

---

## 10. Room 1 下一步输出

当 Room 2 / Room 3 / Room 5 本轮输入交齐后，Room 1 下一步只会在以下两种输出中二选一：

### 方案 A
`R1_P3_3_6_Close_Preflight_Note_v0.1.md`
- 若当前仍不适合 pin Compatibility Contract v1
- 保持 pending，并记录 why / what next

### 方案 B
`R1_to_R4_P3_3_6_Execution_Handoff_v0.1.md`
- 若当前已足够进入 very narrow execution layer
- 只把 Room 1 明确 pin 的 Phase 1 compatibility subset 下发给 Room 4

---

## 11. Room 1 一句话 handoff

> **请 Room 2 / Room 3 / Room 5 围绕 `local_serving_candidate_contract_v1`、`review_group_compatibility_posture_v1`、`fact_settlement_ingest_contract_candidate_v1`、`session_entry_and_routing_compat_v1`、`deprecation_markers_and_writeback_plan_v1` 与 `shadow_parity_test_strategy_v1` 六个问题，先完成一轮同边界、同问题集、同口径的 Compatibility Contract / Shadow-Mode Entry 输入；P3.3.6 当前不直接进入 cutover 实现。**
