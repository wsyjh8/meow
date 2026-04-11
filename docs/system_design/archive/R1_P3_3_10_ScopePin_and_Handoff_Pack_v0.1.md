# R1_P3_3_10_ScopePin_and_Handoff_Pack_v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** active / scope pin / unified handoff entry
- **Role basis:** `room1_v0.2.0.md`
- **Runtime basis:** `Main_updated_2026-04-10_v30.md` + `STATUS_updated_2026-04-10_v28.md`
- **Review basis for this round:**
  - `BR-OPP-001_v0.2.11.md`
  - `UI_SPEC_v0.3.1.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
  - `P3.3.9_Claude_res.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 user 已直接拍板的下一轮 focus：

> **P3.3.10 — Fuller Cutover / `review_group` Exit-Gate / DB-API Uplift Judgment Round**

正式收进主线程，并转译成一份 **统一 handoff 入口**，供 Room 2 / Room 3 / Room 5 在同一范围、同一问题集、同一交付口径下推进。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- Room 4 执行单
- P3.3.10 closeout

本文件只做一件事：

> **在 P3.3.9 已完成 first very narrow cutover 的前提下，把 P3.3.10 收成“更完整 cutover 判断轮”的正式 scope pin：允许讨论下一层 fuller cutover、`review_group` exit-gate、以及 active DB/API baseline uplift judgment，但当前仍不把它们直接写成已生效事实。**

---

## 1. Room 1 当前审核结论

### 1.1 关于 `P3.3.9_Claude_res.md`
Room 1 当前判断：**合格，可接受，不构成阻塞项。**

当前依据不是“把 P3.3.9 写成 full cutover 已完成”，而是：
1. `P3.3.9` 的交付明确守住了 current runtime truth 大面积不变；
2. 真正切入的只有 **ReviewPage non-continuation serving seam** 的 first very narrow subset；
3. `review_group` 继续保持 current owner + retained fallback anchor；
4. final fact / settlement 继续以后端为准；
5. 未改 DB schema，未改 API core semantics，未做 cleanup / `review_group` exit / active DB/API uplift。

因此，从 Room 1 主线程角度，`P3.3.9` 已足够被视为 **已通过审核、已可进入下一轮范围规划**。

---

## 2. Room 1 对当前推进位置的判断

### 2.1 当前所处位置
Room 1 当前判断：

- `P3.3.8` 已完成 **Phase 3 / Gate / Cutover-Decision + DB/API Candidate Round**
- `P3.3.9` 已完成 **First Very Narrow Cutover**
- 现阶段如果继续 owner-shift 方向，下一轮最自然的推进，不再是继续只做 first seam，也不应直接跳成 cleanup，而是：

> **更完整一层的 cutover judgment round**

### 2.2 为什么现在可以进入 fuller cutover judgment
因为当前已经具备：
1. first-cutover 的 runtime 落地证据
2. retained anchor / rollback / hold / observability 证据
3. `review_group` exit-gate 的更清楚前置条件基础
4. BR / UI 已把 P3.3.9 的事实吸收到新的主文档候选
5. 下一层真正的难点，已经不再是“敢不敢切第一刀”，而是：
   - 下一拍要不要扩大 cutover 范围
   - `review_group` 什么时候才有资格进入真实退场判断
   - DB / API 什么时候才有资格从 candidate seam 进入 uplift judgment

### 2.3 为什么这轮仍不能叫“full cutover 已开始”
因为以下现实仍成立：
1. current runtime truth 仍大面积围绕 cloud `review_group`
2. 首页仍是 `study_default`
3. active continuation 仍未切到 local path
4. final fact / settlement 仍以后端为准
5. DB / API active baseline 仍是 `v0.2.1`
6. `review_group` 仍未进入真实退场

所以，P3.3.10 只能是：

> **Fuller Cutover / `review_group` Exit-Gate / DB-API Uplift Judgment Round**  
> 不是 full cutover completed，  
> 也不是 cleanup / old-path purge / uplift absorbed round。

---

## 3. 当前阶段命名

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.10 Scope Pin / Fuller Cutover Judgment Preflight

### 一句话定义

> **P3.3.10 不是宣布“已经切完”的轮，而是把 next-cutover subset、`review_group` 退场资格、以及 DB/API baseline uplift 的判断条件写硬。**

---

## 4. Room 1 当前判断（最关键）

### 4.1 总结论
> **P3.3.10 可以正式启动，但只能先走“fuller cutover judgment preflight”。**

### 4.2 Room 1 对“fuller cutover” 的硬理解
Room 1 当前只接受这样的 fuller cutover judgment：

1. **先判断下一拍 cutover 能扩大到哪一层**
2. **先判断 `review_group` 何时才有资格从 retained anchor 进入真实退场判断**
3. **先判断 DB / API candidate seams 何时才有资格进入 uplift judgment**
4. **继续明确切换、退场、升基线三件事的顺序**
5. **不把 full cutover、cleanup、baseline uplift 一口气压成同一轮既成事实**

### 4.3 Room 1 当前不接受的做法
本轮不接受：
1. 一轮内直接宣告 runtime owner shift completed
2. 一轮内直接宣告 `review_group` 可清理 / 已退场
3. 一轮内直接把 DB / API uplift 写成 active
4. 一轮内把 fuller cutover + exit + uplift + cleanup 一起拉满
5. 任何“因为第一刀成功，所以现在可以自动继续往下切”的静默升级

---

## 5. 本轮核心问题（Room 1 统一问题集）

### Q1. `fuller_cutover_subset_v1`
当前轮要不要正式推进：
- P3.3.9 之后，下一拍最值得扩大的 cutover subset 是什么
- 仍只限 ReviewPage，还是可扩大到 continuity-adjacent seam
- 哪个 fuller subset 最可控、最容易 rollback、最不容易污染 final fact

### Q2. `review_group_exit_gate_v2`
当前轮要不要正式推进：
- `review_group` 从 current owner + retained fallback anchor，何时才有资格进入真实 exit judgment
- 真实退场前还缺哪些 contract / tests / docs / runtime evidence
- 哪些路径当前仍必须继续依赖 `review_group`

### Q3. `db_api_uplift_judgment_v1`
当前轮要不要正式推进：
- 哪些 DB/API seam 已从 candidate 升到 uplift-judgment-ready
- 哪些仍只能停留在 candidate / migration note
- 何时才允许讨论 active DB/API baseline uplift

### Q4. `cutover_vs_fact_owner_boundary_v2`
当前轮要不要正式推进：
- fuller cutover 与 final fact owner 之间继续如何切开
- 哪些 stronger ingest path 可以前进一步
- 哪些 reward / ledger / daily goal / streak / learning_day 结果仍绝不能跟着 cutover 一起切

### Q5. `retained_anchor_to_exit_transition_v1`
当前轮要不要正式推进：
- `review_group` 什么时候从 retained anchor 过渡到 exit candidate
- rollback target 如何变化
- 哪些 stop-condition 仍然必须保持

### Q6. `phase4_writeback_order_v1`
当前轮要不要正式推进：
- fuller cutover / exit-gate / DB-API uplift judgment 的回写顺序
- hold / rollback / proceed / uplift-candidate 的文档吸收顺序
- 哪些只能写成 judgment，哪些可以写成 execution-ready candidate

---

## 6. 本轮范围（In Scope）

### 6.1 Fuller cutover judgment
本轮纳入：
1. `fuller_cutover_subset_v1`
2. `cutover_vs_fact_owner_boundary_v2`
3. `retained_anchor_to_exit_transition_v1`

### 6.2 `review_group` exit-gate judgment
本轮纳入：
1. `review_group_exit_gate_v2`
2. retained anchor 到 exit candidate 的条件
3. fallback / rollback 何时允许缩窄

### 6.3 DB / API uplift judgment
本轮纳入：
1. `db_api_uplift_judgment_v1`
2. candidate seam 与 uplift-ready seam 的区分
3. uplift 前的 rollback / hold / migration 要求

### 6.4 回写与阶段化吸收
本轮纳入：
1. `phase4_writeback_order_v1`
2. judgment vs candidate vs runtime-truth 的分层
3. 下一轮是否足够给 Room 4 fuller-cutover execution handoff

### 6.5 本轮只做 judgment / gate / candidate 收口
本轮纳入的是：
- fuller cutover judgment
- exit-gate judgment
- uplift judgment
- write-back order
- hold / rollback / migration boundary

本轮**不直接纳入**：
- full cutover 完成
- `review_group` 真退场
- active DB/API baseline uplift 正式生效

---

## 7. 当前不纳入（Out of Scope）

以下内容 **不因 P3.3.10 自动纳入**：

1. full cutover completed
2. runtime owner shift completed
3. `review_group` 直接删出运行态
4. active DB/API baseline uplift absorbed
5. cleanup / old path purge
6. auto-routing runtime
7. unified planner / planner merge
8. final fact owner shift
9. DB schema 重构
10. API core semantics 重写
11. 用户可见“`review_group` 已退场 / 新主链路已生效 / cutover 已完成”的宣告

---

## 8. 各 Room 任务分配

## 8.1 Room 2 — Fuller cutover / DB-API uplift judgment 先行
### 任务
产出：
`R2_P3_3_10_FullerCutover_ExitGate_and_DBUplift_Tech_Note_v0.1.md`

### 必答
1. P3.3.9 之后，下一拍 fuller-cutover 最小可行切口是什么
2. `review_group` exit-gate 还缺什么
3. 哪些 DB/API seam 已 uplift-judgment-ready
4. 哪些仍必须停留在 candidate
5. rollback / hold / stop-condition 下一层如何变化
6. 哪些动作一旦出现就越界成 full cutover / cleanup / DB-API major / uplift-overclaim

### Done
给出：
- 推荐 fuller-cutover subset
- 推荐不进入层
- exit-gate judgment 条件
- uplift-judgment-ready seam 清单
- Room 1 可 pin 的最小合同集合

---

## 8.2 Room 3 — Exit-gate / fact-boundary / uplift 规则判断
### 任务
产出：
`R3_P3_3_10_FullerCutover_ExitGate_and_DBUplift_Rules_Note_v0.1.md`

### 必答
1. fuller cutover 哪一层现在允许前进一步
2. `review_group` 何时才有资格进入真实 exit judgment
3. 哪些 final fact 仍继续以后端为准
4. 哪些 wording / state 一旦出现就属于 overclaim
5. 哪些 hold / escalate 条件必须继续保持
6. 哪些结论只能算 uplift judgment，不得升格为 runtime truth

### Done
给出：
- fuller-cutover rule set
- exit-gate rule set
- fact-copy guardrails
- must-hold / must-escalate 列表
- Room 1 可直接吸收的判定句

---

## 8.3 Room 5 — Fuller cutover / exit-gate / uplift 的 UI 判断
### 任务
产出：
`UI_SPEC_P3_3_10_FullerCutover_ExitGate_and_DBUplift_UI_Preflight_v0.1.md`

### 必答
1. 如果 fuller cutover 前进一步，哪些页面最先受影响
2. `review_group` retained-anchor → exit candidate 会如何影响 helper / summary / CTA / empty-state
3. 哪些 UI 状态仍必须保持 current runtime truth
4. rollback / hold / fallback 的 UI 说明下一层怎么写
5. 哪些表述绝不能提前出现
6. 哪些 UI 迁移必须继续后置到 true exit / uplift absorbed 轮

### Done
给出：
- 页面承接建议
- runtime-truth guardrails
- exit-gate UI guidance
- uplift-judgment UI guidance
- 最小 UI candidate subset 层

---

## 9. 执行顺序（固定）

1. **Room 2**
2. **Room 3**
3. **Room 5**
4. **Room 1**
5. **Room 4**（仅在 Room 1 正式下发 `R1 → R4 P3.3.10 Execution Handoff` 后）

---

## 10. 风险 / Blockers

1. **这轮已经不是“第一刀”，而是在判断要不要扩大切口**
   - 所以最容易发生“因为第一刀成功，就误以为旧锚点可以直接撤掉”的问题。

2. **`review_group` 仍是当前最关键的 retained anchor**
   - 如果 exit-gate 判断写不硬，下一轮 very easy overclaim。

3. **DB/API uplift 仍是 judgment，不是 baseline update**
   - 如果把 uplift judgment 写成 active uplift，会立刻造成治理层 / 运行态 / 代码事实漂移。

4. **fuller cutover 仍不是 full cutover**
   - 这轮最容易犯的错误，就是把“下一拍可扩大切口”写成“主链路现在已经切完”。

---

## 11. Room 1 下一步输出

当 Room 2 / Room 3 / Room 5 本轮输入交齐后，Room 1 下一步只会在以下两种输出中二选一：

### 方案 A
`R1_P3_3_10_Close_Preflight_Note_v0.1.md`
- 若当前仍不足以进入 fuller-cutover execution judgment

### 方案 B
`R1_to_R4_P3_3_10_Execution_Handoff_v0.1.md`
- 若当前已足够进入 fuller cutover / exit-gate / uplift judgment 的 very narrow execution layer

---

## 12. Room 1 一句话 handoff

> **请 Room 2 / Room 3 / Room 5 围绕 `fuller_cutover_subset_v1`、`review_group_exit_gate_v2`、`db_api_uplift_judgment_v1`、`cutover_vs_fact_owner_boundary_v2`、`retained_anchor_to_exit_transition_v1` 与 `phase4_writeback_order_v1` 六个问题，先完成一轮同边界、同问题集、同口径的 P3.3.10 judgment 输入；本轮先判断 fuller cutover、exit-gate 与 uplift 的资格与顺序，不直接把它们写成已生效事实。**
