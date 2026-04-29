# R1_P3_3_12_ScopePin_and_Handoff_Pack_v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** active / scope pin / unified handoff entry
- **Role basis:** `room1_v0.2.0.md`
- **Runtime basis:** `Main_updated_2026-04-10_v32.md` + `STATUS_updated_2026-04-10_v30.md`
- **Review basis for this round:**
  - `BR-OPP-001_v0.2.13.md`
  - `UI_SPEC_v0.3.3.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
  - `P3.3.11_Claude_res.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 user 已直接拍板的下一轮 focus：

> **P3.3.12 — Fuller-Cutover / True-Exit-Gate / DB-API Uplift-Absorb Judgment Round**

正式收进主线程，并转译成一份 **统一 handoff 入口**，供 Room 2 / Room 3 / Room 5 在同一范围、同一问题集、同一交付口径下推进。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- Room 4 执行单
- P3.3.12 closeout

本文件只做一件事：

> **在 P3.3.11 已完成 fuller-cutover execution-ready subset / review_group exit-candidate / DB-API uplift-readiness 的前提下，把 P3.3.12 收成“是否足够进入更完整一拍 cutover、是否足够进入 true-exit-gate、以及 DB/API 是否足够进入 uplift-absorb judgment”的正式 scope pin。**

---

## 1. Room 1 当前审核结论

### 1.1 关于 `P3.3.11_Claude_res.md`
Room 1 当前判断：**合格，可接受，不构成阻塞项。**

当前依据不是“把 P3.3.11 写成 full cutover 已完成”，而是：
1. 本轮交付只落在 **very narrow execution-ready candidate execution**；
2. 未修改任何 runtime 主链路关键文件入口；
3. 未改 DB schema，未改 API core semantics；
4. 未发生 `review_group` true exit、未发生 active DB/API uplift absorbed、未发生 full cutover；
5. 测试 / analyze 完整通过，且 BR / UI 主文件已完成回写。

因此，从 Room 1 主线程角度，`P3.3.11` 已足够被视为 **已通过审核、已可进入下一轮范围规划**。

---

## 2. Room 1 对当前推进位置的判断

### 2.1 当前所处位置
Room 1 当前判断：

- `P3.3.9` 已完成 **First Very Narrow Cutover**
- `P3.3.10` 已完成 **Fuller Cutover / review_group Exit-Gate / DB-API Uplift Judgment**
- `P3.3.11` 已完成 **Fuller-Cutover Execution / review_group Exit-Candidate / DB-API Uplift-Readiness**
- 现阶段如果继续 owner-shift 方向，下一轮最自然的推进，不再只是 execution-ready subset，而是：

> **进入一轮 `fuller-cutover / true-exit-gate / DB-API uplift-absorb judgment`**

### 2.2 为什么现在可以进入这一轮 judgment
因为当前已经具备：
1. first-cutover 与 fuller-cutover execution-ready 的落地证据；
2. retained anchor / rollback / hold / observability 成套证据；
3. `review_group` exit-candidate 的前置条件与 still-dependent paths 清单；
4. DB/API uplift-readiness seam families 的最小清单；
5. BR / UI 已把 P3.3.11 的结果吸收到新的主文档候选；
6. 下一层真正的难点，已经从“execution-ready subset 能不能扩大”转向：
   - 哪些 widened subset 已足够进入更完整 cutover 判断
   - `review_group` 何时才真正具备 true-exit gate 资格
   - DB/API 何时才具备 uplift-absorb judgment 资格

### 2.3 为什么这轮仍不能叫“full cutover completed”
因为以下现实仍成立：
1. current runtime truth 仍大面积围绕 cloud `review_group`
2. 首页仍是 `study_default`
3. active continuation 仍未切到 local path
4. final fact / settlement 仍以后端为准
5. DB / API active baseline 仍是 `v0.2.1`
6. `review_group` 仍未进入 true exit
7. uplift-readiness 仍不是 uplift absorbed

所以，P3.3.12 只能是：

> **Fuller-Cutover / True-Exit-Gate / DB-API Uplift-Absorb Judgment Round**  
> 不是 full cutover completed，  
> 也不是 `review_group` true exit / active DB-API uplift absorbed / cleanup 已完成。

---

## 3. 当前阶段命名

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.12 Scope Pin / Fuller-Cutover Judgment Preflight

### 一句话定义

> **P3.3.12 不是宣布“已经切完”的轮，而是判断在 P3.3.11 execution-ready subset 的基础上，是否足够进入更完整一拍 fuller cutover、是否足够进入 `review_group` 的 true-exit gate、以及 DB/API 是否足够进入 uplift-absorb judgment。**

---

## 4. Room 1 当前判断（最关键）

### 4.1 总结论
> **P3.3.12 可以正式启动，但只能先走“fuller-cutover / true-exit-gate / uplift-absorb judgment preflight”。**

### 4.2 Room 1 对这一轮的硬理解
Room 1 当前只接受这样的 P3.3.12：

1. **先判断下一拍 fuller cutover 能扩大到哪一层**
2. **先判断 `review_group` 是否具备 true-exit gate 的最低资格**
3. **先判断 DB/API 是否足够进入 uplift-absorb judgment**
4. **继续把 cutover、true exit、uplift absorb、cleanup 四件事拆开排序**
5. **不把它们一口气写成已生效事实**

### 4.3 Room 1 当前不接受的做法
本轮不接受：
1. 一轮内直接宣告 runtime owner shift completed
2. 一轮内直接宣告 `review_group` 已 true exit / 可清理
3. 一轮内直接把 active DB/API uplift 写成已 absorbed
4. 一轮内同时做 fuller cutover + true exit + uplift absorb + cleanup
5. 任何“因为 P3.3.11 已 execution-ready，所以现在默认可以继续主链路切换”的静默升级

---

## 5. 本轮核心问题（Room 1 统一问题集）

### Q1. `fuller_cutover_absorb_candidate_v1`
当前轮要不要正式推进：
- P3.3.11 之后，哪些 widened subset 已经足够进入更完整一拍 fuller-cutover judgment
- 这个 subset 若继续扩大，blast radius 与 rollback complexity 会怎样变化

### Q2. `review_group_true_exit_gate_v1`
当前轮要不要正式推进：
- `review_group` 距离 true exit 还缺哪些 contract / runtime / test / doc / fallback 条件
- 当前哪些 still-dependent paths 仍阻止它进入 true exit gate

### Q3. `db_api_uplift_absorb_judgment_v1`
当前轮要不要正式推进：
- 哪些 DB/API seam 已经从 uplift-readiness 升到 uplift-absorb judgment-ready
- 哪些仍只能停留在 marker / migration / rollback / hold 层
- 何时才允许 Room 1 讨论 active DB/API baseline uplift absorbed

### Q4. `cutover_vs_fact_owner_boundary_v4`
当前轮要不要正式推进：
- 更完整一拍 fuller cutover judgment 后，stronger ingest candidate 最大能走到哪
- 哪些结果仍绝不能跟着 serving seam 一起切
- 哪些 completion / reward / streak / daily goal / settlement 表达必须继续禁止

### Q5. `exit_candidate_to_true_exit_transition_v1`
当前轮要不要正式推进：
- `review_group` 从 exit-candidate 过渡到 true-exit gate 的最小条件是什么
- retained anchor 哪些范围未来才允许继续缩窄
- rollback target / fallback scope 何时才允许变动

### Q6. `phase6_writeback_order_v1`
当前轮要不要正式推进：
- fuller-cutover judgment / true-exit-gate / uplift-absorb judgment 的回写顺序
- 哪些只能写成 judgment
- 哪些可以写成 execution-ready candidate
- 哪些仍不能升格为 runtime truth

---

## 6. 本轮范围（In Scope）

### 6.1 Fuller-cutover judgment
本轮纳入：
1. `fuller_cutover_absorb_candidate_v1`
2. `cutover_vs_fact_owner_boundary_v4`
3. widened subset / rollback / blast-radius judgement

### 6.2 `review_group` true-exit-gate judgment
本轮纳入：
1. `review_group_true_exit_gate_v1`
2. `exit_candidate_to_true_exit_transition_v1`
3. retained anchor / fallback / rollback 何时允许进一步缩窄

### 6.3 DB/API uplift-absorb judgment
本轮纳入：
1. `db_api_uplift_absorb_judgment_v1`
2. uplift-absorb judgment-ready seam families
3. migration / hold / rollback / observability 下一层要求

### 6.4 回写与阶段化吸收
本轮纳入：
1. `phase6_writeback_order_v1`
2. judgment / execution-ready / runtime truth 的分层
3. 下一轮是否足够给 Room 4 更完整 cutover judgment / execution handoff

### 6.5 本轮只做 judgment / gate / candidate 收口
本轮纳入的是：
- fuller-cutover judgment
- true-exit-gate judgment
- uplift-absorb judgment
- rollback / hold / migration / observability
- write-back order

本轮**不直接纳入**：
- full cutover completed
- `review_group` true exit 已生效
- active DB/API baseline uplift absorbed
- cleanup / old-path purge

---

## 7. 当前不纳入（Out of Scope）

以下内容 **不因 P3.3.12 自动纳入**：

1. full cutover completed
2. runtime owner shift completed
3. `review_group` true exit 生效
4. active DB/API baseline uplift absorbed 生效
5. cleanup / old-path purge
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

## 8.1 Room 2 — Fuller-cutover / true-exit-gate / uplift-absorb judgment 先行
### 任务
产出：
`R2_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_Tech_Note_v0.1.md`

### 必答
1. 哪一组 widened subset 已足够进入 fuller-cutover absorb judgment
2. `review_group` 距 true exit 还缺什么
3. 哪些 DB/API seam 已 uplift-absorb-judgment-ready
4. retained anchor / rollback target 哪些未来才允许变动
5. rollback / hold / stop-condition / observability 下一层如何升级
6. 哪些动作一旦出现就越界成 full cutover / true exit / uplift absorbed / cleanup bundling

### Done
给出：
- 推荐 fuller-cutover judgment subset
- 推荐不进入层
- true-exit-gate 条件
- uplift-absorb-judgment-ready seam 清单
- Room 1 可 pin 的最小 judgment 合同集合

## 8.2 Room 3 — True-exit-gate / fact-boundary / uplift-absorb 规则判断
### 任务
产出：
`R3_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_Rules_Note_v0.1.md`

### 必答
1. 哪个 fuller-cutover judgment subset 现在允许前进一步
2. `review_group` 哪些条件现在可以进入 true-exit gate judgment
3. 哪些 final fact 仍继续以后端为准
4. 哪些 wording / state 一旦出现就属于 overclaim
5. 哪些 hold / escalate 条件必须继续保持
6. 哪些结论只能算 uplift-absorb judgment，不得升格为 runtime truth

### Done
给出：
- fuller-cutover judgment rule set
- true-exit-gate rule set
- fact-copy guardrails
- must-hold / must-escalate 列表
- Room 1 可直接吸收的判定句

## 8.3 Room 5 — Fuller-cutover / true-exit-gate / uplift-absorb 的 UI 判断
### 任务
产出：
`UI_SPEC_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_UI_Preflight_v0.1.md`

### 必答
1. 如果 fuller-cutover judgement 前进一步，哪些页面最先受影响
2. `review_group` exit-candidate → true-exit-gate 会如何影响 helper / summary / CTA / empty-state
3. 哪些 UI 状态仍必须保持 current runtime truth
4. rollback / hold / fallback 的 UI 说明下一层怎么写
5. 哪些表述绝不能提前出现
6. 哪些 UI 迁移必须继续后置到 true exit / uplift absorbed / cleanup 轮

### Done
给出：
- 页面承接建议
- runtime-truth guardrails
- true-exit-gate UI guidance
- uplift-absorb judgment UI guidance
- 最小 UI judgment subset 层

---

## 9. 执行顺序（固定）

1. **Room 2**
2. **Room 3**
3. **Room 5**
4. **Room 1**
5. **Room 4**（仅在 Room 1 正式下发 `R1 → R4 P3.3.12 Execution Handoff` 后）

---

## 10. 风险 / Blockers

1. **这轮已经不再只是 execution-ready，而是在判断是否足够接近 true exit / uplift absorb**
   - 所以最容易发生“把 true-exit gate 写成 true exit”“把 uplift-absorb judgment 写成 uplift absorbed”的问题。

2. **`review_group` 仍是当前最关键的 retained anchor**
   - 即使进入 true-exit-gate judgment，本轮也仍不能默认它已经不是 current owner。

3. **DB/API uplift-absorb 仍只是 judgment，不是 active baseline 更新**
   - 如果把 uplift-absorb judgment 写成 active uplift，会立刻造成治理层 / 运行态 / 代码事实漂移。

4. **更完整一拍的 cutover judgment 仍不是 full cutover**
   - 这轮最容易犯的错误，就是把“更接近 full cutover”写成“主链路现在已经切完”。

---

## 11. Room 1 下一步输出

当 Room 2 / Room 3 / Room 5 本轮输入交齐后，Room 1 下一步只会在以下两种输出中二选一：

### 方案 A
`R1_P3_3_12_Close_Preflight_Note_v0.1.md`
- 若当前仍不足以进入更完整的 cutover judgment / execution handoff

### 方案 B
`R1_to_R4_P3_3_12_Execution_Handoff_v0.1.md`
- 若当前已足够进入 fuller-cutover / true-exit-gate / uplift-absorb judgment 的 very narrow execution layer

---

## 12. Room 1 一句话 handoff

> **请 Room 2 / Room 3 / Room 5 围绕 `fuller_cutover_absorb_candidate_v1`、`review_group_true_exit_gate_v1`、`db_api_uplift_absorb_judgment_v1`、`cutover_vs_fact_owner_boundary_v4`、`exit_candidate_to_true_exit_transition_v1` 与 `phase6_writeback_order_v1` 六个问题，先完成一轮同边界、同问题集、同口径的 P3.3.12 输入；本轮只判断 fuller cutover、true-exit-gate 与 uplift-absorb 的资格与顺序，不直接把它们写成已生效事实。**
