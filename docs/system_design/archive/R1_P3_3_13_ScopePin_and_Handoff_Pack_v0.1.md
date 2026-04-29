# R1_P3_3_13_ScopePin_and_Handoff_Pack_v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** active / scope pin / unified handoff entry
- **Role basis:** `room1_v0.2.0.md`
- **Runtime basis:** `Main_updated_2026-04-10_v33.md` + `STATUS_updated_2026-04-10_v31.md`
- **Review basis for this round:**
  - `BR-OPP-001_v0.2.14.md`
  - `UI_SPEC_v0.3.4.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
  - `P3.3.12_Claude_res.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 user 已直接拍板的下一轮 focus：

> **P3.3.13 — Fuller-Cutover Execution / True-Exit-Candidate / DB-API Uplift-Absorb-Readiness Round**

正式收进主线程，并转译成一份 **统一 handoff 入口**，供 Room 2 / Room 3 / Room 5 在同一范围、同一问题集、同一交付口径下推进。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- Room 4 执行单
- P3.3.13 closeout

本文件只做一件事：

> **在 P3.3.12 已完成 fuller-cutover / true-exit-gate / DB-API uplift-absorb judgment 的前提下，把 P3.3.13 收成“更完整一拍的 fuller-cutover execution、`review_group` 的 true-exit-candidate、以及 DB/API uplift-absorb-readiness”的正式 scope pin。**

---

## 1. Room 1 当前审核结论

### 1.1 关于 `P3.3.12_Claude_res.md`
Room 1 当前判断：**合格，可接受，不构成阻塞项。**

当前依据不是“把 P3.3.12 写成 full cutover 已完成”，而是：
1. 本轮交付只落在 **judgment-driven very narrow execution**；
2. 未修改任何 runtime 主链路关键文件入口；
3. 未改 DB schema，未改 API core semantics；
4. 未发生 `review_group` true exit、未发生 active DB/API uplift absorbed、未发生 full cutover；
5. 测试 / analyze 完整通过，且 BR / UI 主文件已完成回写。

因此，从 Room 1 主线程角度，`P3.3.12` 已足够被视为 **已通过审核、已可进入下一轮范围规划**。

---

## 2. Room 1 对当前推进位置的判断

### 2.1 当前所处位置
Room 1 当前判断：

- `P3.3.9` 已完成 **First Very Narrow Cutover**
- `P3.3.10` 已完成 **Fuller Cutover / review_group Exit-Gate / DB-API Uplift Judgment**
- `P3.3.11` 已完成 **Fuller-Cutover Execution / review_group Exit-Candidate / DB-API Uplift-Readiness**
- `P3.3.12` 已完成 **Fuller-Cutover / True-Exit-Gate / DB-API Uplift-Absorb Judgment**
- 现阶段如果继续 owner-shift 方向，下一轮最自然的推进，不再只是 judgment，而是：

> **进入一轮更完整但仍然很窄的 execution / candidate / readiness round**

### 2.2 为什么现在可以进入 P3.3.13
因为当前已经具备：
1. first-cutover 与 fuller-cutover widened subset 的落地证据；
2. retained anchor / rollback / hold / observability 成套证据；
3. `review_group` true-exit-gate 的前置条件与 still-dependent paths 清单；
4. DB/API uplift-absorb-judgment-ready seam families 的最小清单；
5. BR / UI 已把 P3.3.12 的 judgment 结果吸收到新的主文档候选；
6. 下一层真正难点，已经从“谁有资格进入更完整判断”转向“谁现在有资格进入 very narrow execution / candidate / readiness”。

### 2.3 为什么这轮仍不能叫“full cutover completed”
因为以下现实仍成立：
1. current runtime truth 仍大面积围绕 cloud `review_group`
2. 首页仍是 `study_default`
3. active continuation 仍未切到 local path
4. final fact / settlement 仍以后端为准
5. DB / API active baseline 仍是 `v0.2.1`
6. `review_group` 仍未进入 true exit
7. uplift-absorb judgment 仍不是 uplift absorbed

所以，P3.3.13 只能是：

> **Fuller-Cutover Execution / True-Exit-Candidate / DB-API Uplift-Absorb-Readiness Round**  
> 不是 full cutover completed，  
> 也不是 `review_group` true exit / active DB-API uplift absorbed / cleanup 已完成。

---

## 3. 当前阶段命名

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.13 Scope Pin / Fuller-Cutover Execution Preflight

### 一句话定义

> **P3.3.13 不是宣布“已经切完”的轮，而是允许在 P3.3.12 judgment 的基础上，把 ReviewPage + 首页 review 承接层从 judgment 推到更完整一拍的 execution subset，并同时把 `review_group` 继续保持在 true-exit-candidate 而非 true exit，把 DB/API 继续保持在 uplift-absorb-readiness 而非 uplift absorbed。**

---

## 4. Room 1 当前判断（最关键）

### 4.1 总结论
> **P3.3.13 可以正式启动，但只能先走“fuller-cutover execution / true-exit-candidate / uplift-absorb-readiness preflight”。**

### 4.2 Room 1 对这一轮的硬理解
Room 1 当前只接受这样的 P3.3.13：

1. **把 widened subset 从 judgment 推到 execution subset**
2. **扩大后的范围仍主要留在 ReviewPage + 首页 review 承接层**
3. **仍不切首页默认主 route**
4. **仍不切 active continuation source**
5. **仍不切 final fact / settlement owner**
6. **`review_group` 只进入 true-exit-candidate，不进入 true exit**
7. **DB/API 只进入 uplift-absorb-readiness，不进入 uplift absorbed**

### 4.3 Room 1 当前不接受的做法
本轮不接受：
1. 一轮内直接宣告 runtime owner shift completed
2. 一轮内直接宣告 `review_group` 已 true exit / 可清理
3. 一轮内直接把 active DB/API uplift 写成已 absorbed
4. 一轮内同时做 fuller cutover + true exit + uplift absorb + cleanup
5. 任何“因为 P3.3.12 judgment 通过，所以现在可以静默继续扩大成主链路切换”的默认升级

---

## 5. 本轮核心问题（Room 1 统一问题集）

### Q1. `fuller_cutover_execution_subset_v2`
当前轮要不要正式推进：
- 在 P3.3.12 judgment 基础上，哪一组 widened subset 现在可以真正进入更完整一拍 execution subset
- 这个 subset 扩大后，仍如何保持最小 rollback 与最小 blast radius

### Q2. `review_group_true_exit_candidate_v1`
当前轮要不要正式推进：
- `review_group` 在 P3.3.13 中，哪些内容允许进入 **true-exit-candidate** 层
- 哪些内容仍必须继续保持 current owner + retained fallback anchor
- 哪些路径仍必须依赖 `review_group`

### Q3. `db_api_uplift_absorb_readiness_v1`
当前轮要不要正式推进：
- 哪些 DB/API seam 已经从 uplift-absorb judgment-ready 升到 uplift-absorb-readiness
- 哪些仍只能停留在 marker / migration / rollback / hold 层
- 哪些仍绝不能进入 active baseline

### Q4. `cutover_vs_fact_owner_boundary_v5`
当前轮要不要正式推进：
- fuller-cutover execution 再前进一步后，stronger ingest candidate 最大能走到哪
- 哪些结果仍绝不能跟着 serving seam 一起切
- 哪些 completion / reward / streak / daily goal / settlement 表达必须继续禁止

### Q5. `true_exit_candidate_narrowing_guardrail_v1`
当前轮要不要正式推进：
- true-exit-candidate 阶段，哪些 retained-anchor 依赖允许 very narrow 缩窄
- rollback target 是否继续固定为 `cloud_review_group_current_runtime_path`
- 哪些 stop-condition 必须继续保持硬挡板

### Q6. `phase7_writeback_order_v1`
当前轮要不要正式推进：
- fuller-cutover execution / true-exit-candidate / uplift-absorb-readiness 的回写顺序
- 哪些只能写成 execution-ready candidate
- 哪些可以被 Room 1 吸收到下一轮 Room4 handoff
- 哪些仍不能升格为 runtime truth

---

## 6. 本轮范围（In Scope）

### 6.1 Fuller-cutover execution
本轮纳入：
1. `fuller_cutover_execution_subset_v2`
2. `cutover_vs_fact_owner_boundary_v5`
3. `true_exit_candidate_narrowing_guardrail_v1`

### 6.2 `review_group` true-exit-candidate
本轮纳入：
1. `review_group_true_exit_candidate_v1`
2. true-exit-candidate 与 retained-anchor 的并存姿态
3. 哪些路径仍需依赖 `review_group`
4. rollback / fallback scope 是否允许 very narrow 缩窄

### 6.3 DB/API uplift-absorb-readiness
本轮纳入：
1. `db_api_uplift_absorb_readiness_v1`
2. uplift-absorb-readiness seam families
3. migration / hold / rollback / observability 下一层要求

### 6.4 回写与阶段化吸收
本轮纳入：
1. `phase7_writeback_order_v1`
2. execution-ready candidate / true-exit-candidate / uplift-absorb-readiness / runtime truth 的分层
3. 下一轮是否足够给 Room 4 更完整 cutover execution handoff

### 6.5 本轮只做 execution / candidate / readiness 收口
本轮纳入的是：
- fuller-cutover execution
- true-exit-candidate
- uplift-absorb-readiness
- rollback / hold / migration / observability
- write-back order

本轮**不直接纳入**：
- full cutover completed
- `review_group` true exit
- active DB/API baseline uplift absorbed
- cleanup / old-path purge

---

## 7. 当前不纳入（Out of Scope）

以下内容 **不因 P3.3.13 自动纳入**：

1. full cutover completed
2. runtime owner shift completed
3. `review_group` true exit
4. active DB/API baseline uplift absorbed
5. cleanup / old path purge
6. homepage route / planner-aware runtime route
7. active continuation source switch
8. auto-routing runtime
9. unified planner / planner merge
10. final fact owner shift
11. DB schema 重构
12. API core semantics 重写
13. 用户可见“`review_group` 已退场 / 新主链路已生效 / uplift 已完成 / cutover 已完成”的宣告

---

## 8. 各 Room 任务分配

## 8.1 Room 2 — Fuller-cutover execution / uplift-absorb-readiness 先行
### 任务
产出：
`R2_P3_3_13_FullerCutoverExecution_TrueExitCandidate_and_DBUpliftAbsorbReadiness_Tech_Note_v0.1.md`

### 必答
1. 哪一组 widened subset 现在可以进入更完整一拍 execution subset
2. `review_group` true-exit-candidate 当前能走到哪一步
3. 哪些 DB/API seam 已 uplift-absorb-readiness-ready
4. 哪些 retained-anchor 依赖允许 very narrow 缩窄
5. rollback / hold / stop-condition / observability 下一层如何升级
6. 哪些动作一旦出现就越界成 full cutover / true exit / uplift absorbed / DB-API major / cleanup bundling

### Done
给出：
- 推荐 fuller-cutover execution subset
- 推荐不进入层
- true-exit-candidate 条件
- uplift-absorb-readiness seam 清单
- Room 1 可 pin 的最小 execution-ready 合同集合

## 8.2 Room 3 — True-exit-candidate / fact-boundary / uplift-absorb-readiness 规则判断
### 任务
产出：
`R3_P3_3_13_FullerCutoverExecution_TrueExitCandidate_and_DBUpliftAbsorbReadiness_Rules_Note_v0.1.md`

### 必答
1. 哪个 fuller-cutover execution subset 现在允许前进一步
2. `review_group` 哪些内容现在可以进入 true-exit-candidate
3. 哪些 final fact 仍继续以后端为准
4. 哪些 wording / state 一旦出现就属于 overclaim
5. 哪些 hold / escalate 条件必须继续保持
6. 哪些结论只能算 uplift-absorb-readiness，不得升格为 runtime truth

### Done
给出：
- fuller-cutover execution rule set
- true-exit-candidate rule set
- fact-copy guardrails
- must-hold / must-escalate 列表
- Room 1 可直接吸收的判定句

## 8.3 Room 5 — Fuller-cutover execution / true-exit-candidate / uplift-absorb-readiness 的 UI 判断
### 任务
产出：
`UI_SPEC_P3_3_13_FullerCutoverExecution_TrueExitCandidate_and_DBUpliftAbsorbReadiness_UI_Preflight_v0.1.md`

### 必答
1. 如果 fuller-cutover execution 前进一步，哪些页面最先受影响
2. `review_group` retained-anchor → true-exit-candidate 会如何影响 helper / summary / CTA / empty-state
3. 哪些 UI 状态仍必须保持 current runtime truth
4. rollback / hold / fallback 的 UI 说明下一层怎么写
5. 哪些表述绝不能提前出现
6. 哪些 UI 迁移必须继续后置到 true exit / uplift absorbed / cleanup 轮

### Done
给出：
- 页面承接建议
- runtime-truth guardrails
- true-exit-candidate UI guidance
- uplift-absorb-readiness UI guidance
- 最小 UI execution subset 层

---

## 9. 执行顺序（固定）

1. **Room 2**
2. **Room 3**
3. **Room 5**
4. **Room 1**
5. **Room 4**（仅在 Room 1 正式下发 `R1 → R4 P3.3.13 Execution Handoff` 后）

---

## 10. 风险 / Blockers

1. **这轮已经不是 judgment，而是 judgment 之后的更完整 execution 扩层**
   - 所以最容易发生“把 true-exit-candidate 误写成 true exit”“把 uplift-absorb-readiness 误写成 uplift absorbed”的问题。

2. **`review_group` 仍是当前最关键的 retained anchor**
   - 即使开始讨论 true-exit-candidate，本轮也仍不能默认它已经不是 current owner。

3. **DB/API uplift 仍只是 readiness，不是 active baseline absorbed**
   - 如果把 uplift-absorb-readiness 写成 active uplift absorbed，会立刻造成治理层 / 运行态 / 代码事实漂移。

4. **更完整一拍的 cutover 仍不是 full cutover**
   - 这轮最容易犯的错误，就是把“更宽一层的 execution subset”写成“主链路现在已经切完”。

---

## 11. Room 1 下一步输出

当 Room 2 / Room 3 / Room 5 本轮输入交齐后，Room 1 下一步只会在以下两种输出中二选一：

### 方案 A
`R1_P3_3_13_Close_Preflight_Note_v0.1.md`
- 若当前仍不足以进入 fuller-cutover execution handoff

### 方案 B
`R1_to_R4_P3_3_13_Execution_Handoff_v0.1.md`
- 若当前已足够进入 fuller-cutover execution / true-exit-candidate / uplift-absorb-readiness 的 very narrow execution layer

---

## 12. Room 1 一句话 handoff

> **请 Room 2 / Room 3 / Room 5 围绕 `fuller_cutover_execution_subset_v2`、`review_group_true_exit_candidate_v1`、`db_api_uplift_absorb_readiness_v1`、`cutover_vs_fact_owner_boundary_v5`、`true_exit_candidate_narrowing_guardrail_v1` 与 `phase7_writeback_order_v1` 六个问题，先完成一轮同边界、同问题集、同口径的 P3.3.13 输入；本轮允许把 fuller-cutover 从 judgment 推到更完整一拍的 execution subset，但不把 true exit / uplift absorbed / cleanup 写成已生效事实。**
