# R1_P3_3_7_ScopePin_and_Handoff_Pack_v0.2.md

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.2
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
  - `P3.3.5_Claude_res.md`
  - `P3.3.6_Claude_res.md`
  - `p3.3.7_user.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 user 已直接拍板的下一轮 focus：

> **P3.3.7 — Local-Serving Limited Execution / Shadow Mode Round**

正式收进主线程，并转译成一份 **统一 handoff 入口**，供 Room 2 / Room 3 / Room 5 在同一范围、同一问题集、同一交付口径下推进。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- Room 4 执行单
- runtime owner shift 完成宣告
- local-serving cutover 方案书
- unified planner / planner merge 直接落地稿
- P3.3.7 closeout

本文件只做一件事：

> **在 `P3.3.6` 已完成 Compatibility Contract v1 的前提下，把 `P3.3.7` 收成 staged rollout 的 Phase 2：让 local-serving candidate、fact/settlement ingest candidate、routing shadow candidate 开始在 dev / flag / QA evidence 层真实跑起来，并与 current cloud `review_group` 路径做 parity 对照；但 current runtime truth 仍不切到 local。**

---

## 1. Room 1 先行审核与背景吸收

### 1.1 `P3.3.5_Claude_res.md` 审核结论
Room 1 判断：**合格，可接受**。

原因：
1. `P3.3.5` 明确只做到 **Phase 0 / Compatibility-Prep**；
2. current runtime truth 保持不变；
3. 未改 DB schema / API core semantics / `review_group` 运行态行为；
4. close / absorb 条件可成立，不构成当前轮阻塞。

### 1.2 `P3.3.6_Claude_res.md` 吸收结论
Room 1 判断：**可 close / 可进入下一轮判断**。

原因：
1. `Compatibility Contract v1` 的 very narrow subset 已落地；
2. `review_group` 的 current owner + compatibility anchor + deprecated candidate 三层姿态已写硬；
3. local-serving candidate 仍停留在 candidate / compatibility / shadow 层；
4. shadow / parity / regression 集已固定；
5. `P3.3.6_Claude_res.md` 明确建议进入 **P3.3.7 判断（Phase 2 shadow mode execution）**。

### 1.3 `p3.3.7_user.md` 的直接拍板吸收
Room 1 现正式吸收 user 对下一轮的方向建议：
- staged rollout 的下一自然层是 **Phase 2 — Limited Execution / Shadow Mode**
- 不是 cutover
- 不是 runtime owner shift completed
- 不是 `review_group` 退场
- 不是 auto-routing runtime
- 不是 DB / API core rewrite

---

## 2. 当前阶段命名

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.7 Scope Pin / Limited Execution / Shadow Mode Preflight

### 一句话定义
> **P3.3.7 不是把 local-serving 切成 current runtime truth，而是让它在 shadow 层真实跑起来，与 current cloud `review_group` 路径做有限执行和 parity 对照。**

---

## 3. Room 1 当前判断

### 3.1 总结论
> **P3.3.7 应正式作为 Phase 2 / Limited Execution / Shadow Mode 启动。**

### 3.2 为什么现在应该前进一步
因为当前已经具备进入 shadow-mode 的最低前置：
1. `P3.3.5` 已完成 Phase 0 compatibility-prep；
2. `P3.3.6` 已完成 Compatibility Contract v1；
3. local-serving candidate / fact ingest candidate / routing shadow candidate / write-back / parity test strategy 都已进入可被执行引用的层；
4. 如果再停在 contract-only，会让主线程继续空转，无法产出真正的 shadow evidence。

### 3.3 为什么仍不能叫 cutover
因为以下 current runtime truth 仍必须保持：
1. 首页继续 `home_word_entry = study_default`
2. active continuation 继续独立承接，不得 silent reroute
3. ReviewPage current serving truth 继续围绕 cloud `review_group`
4. `review_group` 当前不是已退场，而是 current owner + compatibility anchor + deprecated candidate
5. final fact / settlement truth 继续以后端为准
6. auto-routing runtime / planner merge / unified planner 继续 pending

---

## 4. 本轮核心问题（Room 1 统一问题集）

本轮必须回答的不是零散讨论，而是以下 4 个主线程问题：

### Q1. `shadow_execution_scope_v1`
当前轮到底允许哪些 candidate 真正进入 limited execution：
- `local_due_queue_candidate`
- `local_generated_review_session_candidate`
- `fact_ingest_shadow_evidence`
- `routing_shadow_candidate`

### Q2. `shadow_result_visibility_v1`
当前轮哪些 shadow 结果可以被：
- dev / test 看见
- internal debug / log / QA evidence 看见
- patch draft 记录
- 但绝不能给用户看见

### Q3. `shadow_acceptance_gate_v1`
本轮怎么定义：
- parity pass
- acceptable mismatch
- must-hold mismatch
- 必须 escalate 的 mismatch
- 哪些 stop conditions 一旦出现就不能继续 Phase 2

### Q4. `shadow_to_phase3_gate_v1`
本轮至少要回答：
- 什么样的 parity / ingest / routing evidence 足以支持未来进入 Phase 3 判断
- 哪些证据不够，必须继续补
- 哪些“看起来可行”的 shadow 结果仍然不能升格为 runtime fact

---

## 5. 本轮范围（In Scope）

### 5.1 `local_serving_shadow_run_v1`
本轮纳入：
1. `local_due_queue_candidate` 的 shadow run
2. `local_generated_review_session_candidate` 的 shadow run
3. flag / seam / hidden marker 挂载
4. 只进入 dev / QA / evidence 层，不进入用户主路径

### 5.2 `parity_checks_v1`
本轮纳入：
1. local shadow queue vs cloud `review_group` 的对照
2. serving eligibility 对照
3. attempt / progress / completion 对照
4. accept / reject / duplicate 的 evidence 对照

### 5.3 `review_group_shadow_compat_v1`
本轮纳入：
1. `review_group` 继续 current runtime owner
2. `review_group` 同时作为 shadow 对照基准
3. local-serving 继续只做 shadow candidate
4. 不允许把 `review_group` 写成已退场

### 5.4 `fact_ingest_shadow_evidence_v1`
本轮纳入：
1. local evidence → cloud fact layer 的 shadow ingest
2. accept / reject / duplicate 的证据回包与分级
3. final fact 仍以后端为准
4. local 不得直接改 ledger / daily_goal / streak / settlement

### 5.5 `routing_shadow_prep_v1`
本轮纳入：
1. `study_default` 继续保持不变
2. active continuation 继续独立承接
3. planner-aware / shadow-routing 只进 hidden marker / flag-prep / evidence 层
4. 不允许 auto-routing runtime

### 5.6 `shadow_regression_and_writeback_v1`
本轮纳入：
1. runtime truth regression
2. shadow parity evidence tests
3. marker / contract-only tests
4. patch draft / write-back plan
5. no-major-change statement

---

## 6. 当前不纳入（Out of Scope）

1. runtime owner shift completed
2. ReviewPage local-serving runtime cutover
3. local due queue 接管 current ReviewPage truth
4. `review_group` 退出运行态
5. auto-routing runtime
6. planner merge / unified planner
7. unified Study / Review page
8. DB schema rewrite
9. API core semantics rewrite
10. reward / settlement / daily_goal / streak 最终事实 owner shift
11. 用户可见“已切换到本地规划 / 本地已接管复习 / 已自动安排学习路径”类宣告

---

## 7. 各 Room 任务分配

## 7.1 Room 2 — Limited Execution 技术边界
### 任务
产出：
`R2_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_Tech_Note_v0.1.md`

### 必答
1. 哪些 shadow candidate 可以安全进入 limited execution
2. 哪些必须继续停留在 contract-only
3. queue compare / ingest compare / routing compare 的最小技术路径
4. parity mismatch 分级与 stop conditions
5. 哪些动作一旦出现就越界成 Phase 3 / DB-API Major

### Done
给出：
- allowed trial set
- forbidden trial set
- stop conditions
- 推荐 Room 1 可 pin 的 very narrow shadow execution subset

---

## 7.2 Room 3 — Shadow 结果的规则层口径
### 任务
产出：
`R3_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_Rules_Note_v0.1.md`

### 必答
1. shadow evidence 与 runtime fact 的规则边界
2. fact / settlement ingest compare 结果该如何被业务层解释
3. 哪些 mismatch 只是 shadow warning，哪些必须 hold
4. 哪些 label / helper / debug wording 可以出现，哪些绝不可以出现
5. future Phase 3 需要哪些业务证据

### Done
给出：
- shadow evidence rule set
- mismatch severity rule set
- fact-copy guardrails
- 可直接给 Room 1 吸收的 gate 句子

---

## 7.3 Room 5 — Shadow / internal-only 的 UI-state 边界
### 任务
产出：
`UI_SPEC_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_UI_Preflight_v0.1.md`

### 必答
1. 哪些 shadow indicators 只能存在于 dev/test/internal，不得露出给用户
2. 哪些当前 helper / summary / CTA 需要继续保护 current runtime truth
3. routing shadow / local-serving shadow / ingest shadow 对页面状态的最小影响
4. 哪些表达一旦出现就会把 shadow 误写成 runtime cutover

### Done
给出：
- internal-only marker guidance
- runtime-truth guardrails
- user-visible forbidden claims
- 最小 UI shadow contract 层

---

## 8. 执行顺序（固定）

1. **Room 2**
2. **Room 3**
3. **Room 5**
4. **Room 1**
5. **Room 4**（仅在 Room 1 正式下发 `R1 → R4 P3.3.7 Execution Handoff` 后）

---

## 9. 风险 / Blockers

1. **这是 Phase 2 shadow mode round，不是 cutover round**
   - 若把 shadow 结果误写成 runtime owner shift，会立即造成 BR / UI / TEST / 实现事实漂移。

2. **当前 runtime truth 仍在 cloud `review_group`**
   - 任何“local 已接管 ReviewPage current truth”的表达，在本轮前都属于假事实。

3. **若不先收 shadow mismatch 分级，后续 Phase 2 会变成“跑了很多影子逻辑，但不知道什么时候停、什么时候过”**
   - 所以本轮必须把 acceptance gate 与 stop conditions 写硬。

---

## 10. Room 1 下一步输出

当 Room 2 / Room 3 / Room 5 本轮输入交齐后，Room 1 下一步只会在以下两种输出中二选一：

### 方案 A
`R1_P3_3_7_Close_Preflight_Note_v0.1.md`
- 若当前仍不适合进入 Limited Execution / Shadow Mode

### 方案 B
`R1_to_R4_P3_3_7_Execution_Handoff_v0.1.md`
- 若当前已足够进入 very narrow shadow-mode trial

---

## 11. Room 1 一句话 handoff

> **请 Room 2 / Room 3 / Room 5 围绕 `local_serving_shadow_run_v1`、`parity_checks_v1`、`review_group_shadow_compat_v1`、`fact_ingest_shadow_evidence_v1`、`routing_shadow_prep_v1` 与 `shadow_regression_and_writeback_v1` 六个问题，先完成一轮同边界、同问题集、同口径的 Phase 2 / Limited Execution / Shadow Mode 输入；P3.3.7 当前仍不直接进入 cutover。**
