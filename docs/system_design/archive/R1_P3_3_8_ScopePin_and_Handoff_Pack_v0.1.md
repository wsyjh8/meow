# R1_P3_3_8_ScopePin_and_Handoff_Pack_v0.1.md

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** active / provisional scope pin / unified handoff entry
- **Role basis:** `room1_v0.2.0.md`
- **Runtime basis:** `Main_updated_2026-04-10_v28.md` + `STATUS_updated_2026-04-10_v26.md`
- **Review basis for this round:**
  - `BR-OPP-001_v0.2.9.md`
  - `UI_SPEC_v0.2.9.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
  - `P3.3.7_Claude_res.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于在以下前提下，先给出一份可推进的下一轮 handoff：

1. `P3.3.7_Claude_res.md` 已审核通过；
2. BR / UI 主文件已完成回写；
3. 当前轮次已走到 `P3.3.7` closeout 之后；
4. **当前可访问文件集中未检到 `p3.3.8_user.md` 原文**，因此本稿只能作为 **provisional handoff**，不冒充读到了不存在的 user 文件。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- Room 4 执行单
- P3.3.8 closeout

本文件只做一件事：

> **在现有 staged-rollout 证据基础上，把 `P3.3.8` 暂定为 `Phase 3 — Gate / Cutover-Decision + DB/API Candidate Round` 的 Room 1 临时 scope pin，供 Room 2 / Room 3 / Room 5 继续收口。**

---

## 1. Room 1 审核结论（P3.3.7）

### 1.1 `P3.3.7_Claude_res.md`
Room 1 判断：**合格，可接受**。

本轮满足：
- current runtime truth 未被偷切
- local-serving / routing / fact-ingest 只进入 shadow / evidence 层
- `review_group` 继续保持 current runtime owner + shadow baseline
- 未触碰 DB schema / API core semantics
- 已形成 parity / mismatch / stop-condition 证据集

因此，`P3.3.7_Claude_res.md` **不构成阻塞项**，不拦主线程进入下一轮。

---

## 2. Room 1 对当前推进位置的判断

### 2.1 当前所处位置
Room 1 当前判断：

- `P3.3.5` 已通过审核
- `P3.3.6` 已完成 Compatibility Contract v1 / Shadow-Entry Prep
- `P3.3.7` 已完成 Limited Execution / Shadow Mode
- staged rollout 的下一自然层，不是再做一个同级 shadow round，而是：

> **Phase 3 — Gate / Cutover-Decision**

### 2.2 为什么这样判断
因为当前已具备：
1. current runtime truth regression 证据
2. shadow parity evidence
3. mismatch / stop-condition 分级
4. local-serving candidate / routing shadow / ingest shadow 的真实运行证据
5. BR / UI 已回写到 `v0.2.9` 候选层

如果下一轮还只停在 shadow-only / compatibility-only，不再推进 gate / decision，主线程会再次进入“证据已经在，但没有把证据转成下一步决策”的空转。

### 2.3 但为什么仍不直接叫 cutover
因为以下现实仍成立：
1. current runtime truth 仍在 cloud `review_group`
2. current 首页仍 `study_default`
3. current runtime 仍禁止 auto-routing
4. DB / API active baselines 仍是 `v0.2.1`
5. planner owner shift 仍未升格成 current runtime truth

所以，P3.3.8 最多只能是：

> **Phase 3 — Gate / Cutover-Decision + DB/API Candidate Round**  
> 不是 cutover / cleanup。

---

## 3. 暂定主题（provisional）

### 3.1 建议命名
> **P3.3.8 — Phase 3 Gate / Cutover-Decision + DB/API Candidate Round**

### 3.2 一句话定义
> **把 P3.3.7 的 shadow evidence 转成下一层是否可进入 limited cutover 准备的 gate 决策，并同步开启 DB / API compatibility + ingest + migration candidate round。**

---

## 4. 本轮核心问题（Room 1 统一问题集）

### Q1. `phase3_gate_decision_v1`
当前轮要不要正式推进：
- 哪些 parity / mismatch / stop-condition 结果足以支撑进入下一层
- 哪些证据不足，必须继续补
- 哪些 mismatch 一旦存在，就必须 hold / escalate

### Q2. `limited_cutover_scope_candidate_v1`
当前轮要不要正式推进：
- 若进入 Phase 3，最小 cutover subset 是什么
- 是先动 serving source，还是先动 ingest / route / helper
- 哪些仍必须继续保持 runtime truth 不变

### Q3. `db_api_candidate_round_v1`
当前轮要不要正式推进：
- 哪些 DB / API seams 需要从“语义字段组”升级到 candidate contract
- 哪些只应写成 candidate，不应立刻进入 active baseline
- 哪些核心语义继续禁止重写

### Q4. `review_group_exit_gate_v1`
当前轮至少要回答：
- `review_group` 什么时候才允许从 current runtime owner + compatibility anchor 进入真实退场判断
- 在这之前，哪些 contract / tests / docs 必须先齐

### Q5. `fact_settlement_cutover_boundary_v1`
当前轮要不要正式推进：
- local evidence 何时才允许进入更强的 active ingest path
- 哪些最终事实仍必须继续以后端为准
- 哪些 owner shift 绝不能被误写成 fact owner shift

### Q6. `phase3_writeback_and_migration_v1`
当前轮要不要正式推进：
- DB / API / BR / UI / TEST 的回写次序
- deprecated / compatibility / runtime truth 的切换条件
- migration note / rollback note / hold note 的最小要求

---

## 5. 本轮范围（In Scope）

### 5.1 Gate / Cutover-Decision
本轮纳入：
1. `phase3_gate_decision_v1`
2. `limited_cutover_scope_candidate_v1`
3. hold / revise / escalate / proceed 条件

### 5.2 DB / API Candidate Round
本轮纳入：
1. `db_api_candidate_round_v1`
2. serving / ingest / route 相关 seam 的 candidate 合同
3. migration / compatibility / rollback 基线

### 5.3 `review_group` / fact / routing 的下一层判断
本轮纳入：
1. `review_group_exit_gate_v1`
2. `fact_settlement_cutover_boundary_v1`
3. Phase 3 write-back / migration plan

### 5.4 只做 gate / candidate / migration round
本轮纳入的是：
- gate
- decision
- candidate contract
- migration boundary
- rollback / hold 条件
- write-back 次序

本轮**不直接纳入** Room 4 cutover 实现。

---

## 6. 当前不纳入（Out of Scope）

1. runtime owner shift completed
2. ReviewPage local-serving runtime cutover
3. `review_group` 直接删出运行态
4. auto-routing runtime
5. unified planner / planner merge
6. DB schema 直接重构落地
7. API core semantics 直接重写落地
8. 用户可见“已切到本地规划 / 本地已接管复习 / 已自动安排学习路径”的宣告
9. full sync / real-time sync / auto merge
10. 完整复习规划产品重写

---

## 7. 各 Room 任务分配

### 7.1 Room 2 — Gate / DB/API candidate 先行
**任务：**  
产出 `R2_P3_3_8_Phase3Gate_and_DB_API_Candidate_Tech_Note_v0.1.md`

**必答：**
1. `phase3_gate_decision_v1` 的最低通过条件是什么
2. `limited_cutover_scope_candidate_v1` 最小可行切口是什么
3. `db_api_candidate_round_v1` 该冻结到哪一层
4. `review_group_exit_gate_v1` 还缺什么
5. `fact_settlement_cutover_boundary_v1` 哪些绝不能动
6. 哪些动作一旦出现就越界成 DB/API Major 或错误 cutover

**Done：**
给出：
- proceed / hold / revise / escalate 建议
- DB/API candidate 清单
- migration / rollback 边界
- Room 1 可 pin 的最小合同集合

### 7.2 Room 3 — 规则层 gate 与事实边界
**任务：**  
产出 `R3_P3_3_8_Phase3Gate_and_CutoverDecision_Rules_Note_v0.1.md`

**必答：**
1. shadow evidence 什么时候足以支撑进入下一层 gate
2. `review_group_exit_gate_v1` 的业务条件是什么
3. `fact_settlement_cutover_boundary_v1` 哪些仍必须以后端为准
4. 哪些文案 / helper / state 一旦出现就等于 overclaim
5. 哪些 mismatch 必须 hold
6. 哪些结论只能继续算 candidate，不能升格为 runtime truth

**Done：**
给出：
- gate 规则句
- must-hold / must-escalate 列表
- fact-copy guardrails
- Room 1 可直接吸收的判定句

### 7.3 Room 5 — UI / state cutover-decision 影响判断
**任务：**  
产出 `UI_SPEC_P3_3_8_Phase3Gate_and_CutoverDecision_UI_Preflight_v0.1.md`

**必答：**
1. 若进入下一层 limited cutover candidate，哪些页面最先受影响
2. 哪些状态仍必须保持 current runtime truth
3. 哪些 helper / summary / CTA / empty-state 会首先出问题
4. 哪些表述绝不能提前出现
5. 回写顺序与 UI migration 的最小路径是什么

**Done：**
给出：
- 页面承接建议
- runtime-truth guardrails
- user-visible forbidden claims
- 最小 UI candidate migration 层

---

## 8. 执行顺序（固定）

1. **Room 2**
2. **Room 3**
3. **Room 5**
4. **Room 1**
5. **Room 4**（仅在 Room 1 正式下发 `R1 → R4 P3.3.8 Execution Handoff` 后）

---

## 9. Room 1 下一步输出

当 Room 2 / Room 3 / Room 5 本轮输入交齐后，Room 1 只会在以下两种输出中二选一：

### 方案 A
`R1_P3_3_8_Close_Preflight_Note_v0.1.md`
- 若当前仍不足以进入 Phase 3 gate / cutover-decision

### 方案 B
`R1_to_R4_P3_3_8_Execution_Handoff_v0.1.md`
- 若当前已足够进入 very narrow gate-driven / candidate-driven execution layer

---

## 10. Room 1 一句话 handoff

> **请 Room 2 / Room 3 / Room 5 围绕 `phase3_gate_decision_v1`、`limited_cutover_scope_candidate_v1`、`db_api_candidate_round_v1`、`review_group_exit_gate_v1`、`fact_settlement_cutover_boundary_v1` 与 `phase3_writeback_and_migration_v1` 六个问题，先完成一轮同边界、同问题集、同口径的 Phase 3 gate / cutover-decision + DB/API candidate 输入；P3.3.8 当前仍不直接进入 cutover 实现。**
