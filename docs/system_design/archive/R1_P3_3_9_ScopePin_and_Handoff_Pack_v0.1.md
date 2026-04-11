# R1_P3_3_9_ScopePin_and_Handoff_Pack_v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** active / scope pin / unified handoff entry
- **Role basis:** `room1_v0.2.0.md`
- **Runtime basis:** `Main_updated_2026-04-10_v29.md` + `STATUS_updated_2026-04-10_v27.md`
- **Review basis for this round:**
  - `BR-OPP-001_v0.2.10.md`
  - `UI_SPEC_v0.3.0.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
  - `P3.3.8_Claude_res.md`（Room 4 closeout evidence / user relay）

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 user 已直接拍板的下一轮 focus：

> **P3.3.9 — First Very Narrow Cutover Round**

正式收进主线程，并转译成一份 **统一 handoff 入口**，供 Room 2 / Room 3 / Room 5 在同一范围、同一问题集、同一交付口径下推进。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- Room 4 执行单
- P3.3.9 closeout

本文件只做一件事：

> **在 P3.3.8 已完成 Phase 3 gate / candidate / migration prep 的前提下，把 P3.3.9 收成“第一轮 very narrow cutover”的正式 scope pin：允许讨论并定义一个最小 cutover 子集，但仍不把 cleanup / `review_group` 退场 / active DB/API baseline uplift 合并进本轮。**

---

## 1. Room 1 当前审核结论

### 1.1 关于 `P3.3.8_Claude_res.md`
Room 1 当前判断：**不构成阻塞项，可进入下一轮。**

当前依据不是“把 P3.3.8 写成已经 cutover”，而是：
1. `BR-OPP-001_v0.2.10.md` 已把 P3.3.8 的规则层收口吸收到主 BR 候选；
2. `UI_SPEC_v0.3.0.md` 已把 P3.3.8 的 gate / candidate / migration UI 事实吸收到主 UI 候选；
3. 两份主文档都把 P3.3.8 明确写成：  
   - gate / candidate / migration round  
   - 不是 runtime owner shift completed  
   - 不是 ReviewPage local-serving runtime cutover  
   - 不是 `review_group` 退场轮  
4. 因此，从 Room 1 主线程角度，P3.3.8 已足够被视为 **已通过审核、已可进入下一轮范围规划**。

---

## 2. Room 1 对当前推进位置的判断

### 2.1 当前所处位置
Room 1 当前判断：

- `P3.3.7` 已完成 Phase 2 / Limited Execution / Shadow Mode
- `P3.3.8` 已完成 Phase 3 / Gate / Cutover-Decision + DB/API Candidate Round
- 现阶段如果继续 owner-shift 方向，下一轮最自然的推进，不再是继续 gate-only / candidate-only，而是：

> **第一轮 very narrow cutover**

### 2.2 为什么现在可以进入第一轮 very narrow cutover
因为当前已经具备：
1. shadow evidence / parity / mismatch / stop-condition
2. `review_group` exit gate 仍被清楚 gated
3. final fact / settlement boundary 已被继续写硬
4. UI migration / copy neutralization / forbidden claims 已进入主文档候选
5. DB/API seam candidate / migration / rollback / hold-note 已完成上一轮 framing

### 2.3 为什么这轮仍不能叫“大 cutover”
因为以下现实仍成立：
1. current runtime truth 仍在 cloud `review_group`
2. current 首页仍 `study_default`
3. final fact / settlement truth 仍以后端为准
4. DB / API active baseline 仍是 `v0.2.1`
5. `review_group` 仍不是可直接清理对象

所以，P3.3.9 只能是：

> **First Very Narrow Cutover Round**  
> 不是 full cutover，  
> 也不是 cleanup / `review_group` exit / active DB/API uplift 合并轮。

---

## 3. 当前阶段命名

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.9 Scope Pin / First Very Narrow Cutover Preflight

### 一句话定义

> **P3.3.9 不是“大切换轮”，而是允许一个最小 runtime seam 从 candidate / gate 层进入 first cutover subset；同时继续保留 `review_group`、fact boundary、rollback、hold-note 与 UI overclaim guardrails。**

---

## 4. Room 1 当前判断（最关键）

## 4.1 总结论
> **P3.3.9 可以正式启动，但只能先走“first very narrow cutover preflight”。**

### 4.2 Room 1 对“第一轮 cutover” 的硬理解
Room 1 当前只接受这样的 cutover：

1. **只切一个 very narrow subset**
2. **切 runtime seam，不切全主链路**
3. **切 serving candidate 的最小一段，不切 final fact owner**
4. **切换时保留 `review_group` 作为 fallback / rollback anchor**
5. **不把 cleanup / `review_group` 退场 / active DB/API baseline uplift 绑进同一轮**

### 4.3 Room 1 当前不接受的做法
本轮不接受：
1. 一轮内同时做 cutover + cleanup
2. 一轮内同时做 cutover + `review_group` 真退场
3. 一轮内同时做 cutover + active DB/API baseline uplift
4. 一轮内把 routing / fact / serving / `review_group` exit 全都切掉
5. 任何“既切换、又清理、又升基线、又宣布完成”的一口气方案

---

## 5. 本轮核心问题（Room 1 统一问题集）

### Q1. `first_cutover_subset_v1`
当前轮要不要正式推进：
- 第一轮 cutover 到底切哪一个最小子集
- 是先切 serving seam，还是先切 ingest stronger-path，还是先切 helper / state contract
- 哪个 subset 的风险最低、回滚最容易、最不容易污染 final fact

### Q2. `runtime_truth_switch_boundary_v1`
当前轮要不要正式推进：
- 哪一条 runtime truth 允许在 very narrow 范围内真正切换
- 哪些 runtime truth 继续必须保持不变
- serving truth 能否局部切，且不误伤首页 / continuation / review summary / settlement

### Q3. `review_group_retained_anchor_v1`
当前轮至少要回答：
- 第一轮 cutover 里，`review_group` 保留到什么程度
- 它是继续作为 current owner、还是变成 retained fallback anchor
- 哪些路径仍必须继续走 `review_group`
- 什么情况下触发 rollback 到 `review_group`

### Q4. `fact_owner_guardrail_v1`
当前轮要不要正式推进：
- serving subset 切换后，local-serving 产出的结果怎么进入 stronger ingest path
- 哪些 final fact 继续以后端为准
- 哪些 completion / reward / streak / daily goal 结果绝不能跟着 serving cutover 一起切

### Q5. `db_api_cutover_candidate_v2`
当前轮要不要正式推进：
- 哪些 DB/API seam 能从 candidate 升到 first-cutover-ready
- 哪些 contract 仍只允许停留在 candidate / migration note
- 哪些 API / DB 语义本轮继续绝不能改

### Q6. `rollback_holdnote_and_observability_v1`
当前轮要不要正式推进：
- rollback floor 是什么
- hold note 怎么写
- 哪些 stop condition 一旦触发就必须回退
- 本轮要补哪些日志 / evidence / QA 证据位，才能保证 first cutover 可控

---

## 6. 本轮范围（In Scope）

### 6.1 First very narrow cutover subset
本轮纳入：
1. `first_cutover_subset_v1`
2. `runtime_truth_switch_boundary_v1`
3. `review_group_retained_anchor_v1`

### 6.2 Final fact / ingest / DB-API stronger seam
本轮纳入：
1. `fact_owner_guardrail_v1`
2. `db_api_cutover_candidate_v2`
3. stronger ingest path 的 very narrow candidate

### 6.3 Rollback / hold / observability
本轮纳入：
1. `rollback_holdnote_and_observability_v1`
2. stop conditions
3. evidence / logging / QA packet
4. first-cutover 回写要求

### 6.4 只做“第一轮 very narrow cutover”
本轮纳入的是：
- 一个最小 cutover 子集
- runtime seam 的有限切换
- rollback / hold / fallback
- DB/API stronger seam 候选
- 文档与测试的前置约束

本轮**不直接纳入**：
- cleanup
- `review_group` 真退场
- active DB/API baseline uplift

---

## 7. 当前不纳入（Out of Scope）

以下内容 **不因 P3.3.9 自动纳入**：

1. full cutover
2. runtime owner shift completed
3. ReviewPage local-serving full runtime cutover
4. `review_group` 直接删出运行态
5. auto-routing runtime
6. unified planner / planner merge
7. unified Study / Review page
8. final fact owner shift
9. cleanup / old path purge
10. active DB/API baseline uplift
11. DB schema 重构
12. API core semantics 重写
13. 用户可见“已切到本地规划 / 已接管复习 / `review_group` 已退场 / cutover 已完成”的宣告

---

## 8. 各 Room 任务分配

## 8.1 Room 2 — First cutover 技术边界先行
### 任务
产出：
`R2_P3_3_9_FirstVeryNarrowCutover_Tech_Note_v0.1.md`

### 必答
1. 第一轮 first-cutover subset 最小可行切口是什么
2. 哪条 runtime seam 现在最值得先切
3. `review_group` 在 first cutover 中该保留成什么角色
4. 哪些 DB/API seam 能升到 first-cutover-ready
5. rollback / hold / stop-condition 的最低技术要求是什么
6. 哪些动作一旦出现就越界成 full cutover / DB-API major / cleanup bundling

### Done
给出：
- 推荐 first-cutover subset
- 推荐不进入层
- rollback floor
- stop conditions
- Room 1 可 pin 的最小 cutover 合同集合

---

## 8.2 Room 3 — First cutover 规则层与事实边界
### 任务
产出：
`R3_P3_3_9_FirstVeryNarrowCutover_Rules_Note_v0.1.md`

### 必答
1. 哪个 serving subset 现在允许 first cutover
2. `review_group` 在业务上应保留为 current owner、fallback anchor 还是 dual posture
3. 哪些 final fact 继续必须以后端为准
4. 哪些 wording / state 一旦出现就属于 overclaim
5. 哪些 stop condition 必须 hold / escalate
6. 哪些结论只能算 candidate / migration，不得升格为 runtime truth

### Done
给出：
- first-cutover rule set
- must-hold / must-escalate 列表
- fact-copy guardrails
- Room 1 可直接吸收的判定句

---

## 8.3 Room 5 — First cutover 的 UI / state migration 影响
### 任务
产出：
`UI_SPEC_P3_3_9_FirstVeryNarrowCutover_UI_Preflight_v0.1.md`

### 必答
1. 第一轮 cutover 若切一个 serving subset，哪些页面最先受影响
2. 哪些页面 / 状态仍必须保持 current runtime truth
3. `review_group` retained anchor 会影响哪些 helper / summary / CTA / empty-state
4. rollback / hold / fallback 的 UI 说明最小要求是什么
5. 哪些文案绝不能提前出现
6. 哪些 UI 迁移必须继续后置到 cleanup / exit / baseline uplift 轮

### Done
给出：
- 页面承接建议
- runtime-truth guardrails
- retained-anchor UI guidance
- fallback / hold UI notes
- 最小 UI cutover subset 层

---

## 9. 执行顺序（固定）

1. **Room 2**
2. **Room 3**
3. **Room 5**
4. **Room 1**
5. **Room 4**（仅在 Room 1 正式下发 `R1 → R4 P3.3.9 Execution Handoff` 后）

---

## 10. 风险 / Blockers

1. **这轮是真正第一拍 cutover，不再只是 gate / candidate**
   - 所以任何 source switch 都必须配 rollback / hold / retained anchor。
2. **如果把 cleanup / `review_group` 退场 / active DB/API uplift 绑进来，风险会明显抬升**
   - 会同时增加验证难度、回滚难度、文档与代码漂移概率。
3. **first cutover 不是 full cutover**
   - 本轮最容易犯的错误，就是把“切一个 very narrow seam”写成“主链路已经完成 owner shift”。
4. **final fact owner 仍不能被偷切**
   - serving subset 变化，不能被用户、实现、测试误解为 reward / streak / daily goal / settlement 也已切换。

---

## 11. Room 1 下一步输出

当 Room 2 / Room 3 / Room 5 本轮输入交齐后，Room 1 下一步只会在以下两种输出中二选一：

### 方案 A
`R1_P3_3_9_Close_Preflight_Note_v0.1.md`
- 若当前仍不足以进入 first very narrow cutover execution

### 方案 B
`R1_to_R4_P3_3_9_Execution_Handoff_v0.1.md`
- 若当前已足够进入第一轮 very narrow cutover 的执行层

---

## 12. Room 1 一句话 handoff

> **请 Room 2 / Room 3 / Room 5 围绕 `first_cutover_subset_v1`、`runtime_truth_switch_boundary_v1`、`review_group_retained_anchor_v1`、`fact_owner_guardrail_v1`、`db_api_cutover_candidate_v2` 与 `rollback_holdnote_and_observability_v1` 六个问题，先完成一轮同边界、同问题集、同口径的“第一轮 very narrow cutover”输入；P3.3.9 当前不把 cleanup / `review_group` 退场 / active DB/API baseline uplift 绑进来。**
