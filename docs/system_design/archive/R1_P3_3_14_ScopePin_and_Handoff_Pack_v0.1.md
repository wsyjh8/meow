# R1_P3_3_14_ScopePin_and_Handoff_Pack_v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** active / scope pin / unified handoff entry
- **Role basis:** `room1_v0.2.0.md`
- **Runtime basis:** `Main_updated_2026-04-10_v34.md` + `STATUS_updated_2026-04-10_v32.md`
- **Review basis for this round:**
  - `BR-OPP-001_v0.2.15.md`
  - `UI_SPEC_v0.3.5.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
  - `P3.3.13_Claude_res.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 user 已直接拍板的下一轮 focus：

> **P3.3.14 — Final Cutover Program Round**

正式收进主线程，并转译成一份 **统一 handoff 入口**，供 Room 2 / Room 3 / Room 5 在同一范围、同一问题集、同一交付口径下推进。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- Room 4 执行单
- P3.3.14 closeout

本文件只做一件事：

> **把原本 remaining 的“更接近 full cutover / true exit / uplift absorbed / cleanup”后续几轮，压缩成 1 个项目轮次，但在该轮次内部明确拆成 A / B / C 三个 sequential checkpoints，防止把未生效事实一次性误写成已生效。**

---

## 1. Room 1 当前审核结论

### 1.1 关于 `P3.3.13_Claude_res.md`
Room 1 当前判断：**合格，可接受，不构成阻塞项。**

当前依据不是“把 P3.3.13 写成 full cutover 已完成”，而是：
1. 本轮交付只落在 **very narrow execution-ready candidate execution**；
2. 未修改 runtime 主链路关键入口；
3. 未改 DB schema，未改 API core semantics；
4. 未发生 `review_group` true exit、未发生 active DB/API uplift absorbed、未发生 full cutover；
5. BR / UI 主文件已完成回写，且主线程已吸收 `P3.3.13 closed / next-focus pending`。

因此，从 Room 1 主线程角度，`P3.3.13` 已足够被视为 **已通过审核、已可进入下一轮范围规划**。

---

## 2. Room 1 对当前推进位置的判断

### 2.1 当前所处位置
Room 1 当前判断：

- `P3.3.9` 已完成 **First Very Narrow Cutover**
- `P3.3.10` 已完成 **Fuller Cutover / review_group Exit-Gate / DB-API Uplift Judgment**
- `P3.3.11` 已完成 **Fuller-Cutover Execution / review_group Exit-Candidate / DB-API Uplift-Readiness**
- `P3.3.12` 已完成 **Fuller-Cutover / True-Exit-Gate / DB-API Uplift-Absorb Judgment**
- `P3.3.13` 已完成 **Fuller-Cutover Execution / True-Exit-Candidate / DB-API Uplift-Absorb-Readiness**

现阶段如果继续 owner-shift 方向，Room 1 不再建议继续拆成多轮正式编号，而是：

> **进入 1 个合并后的 Final Cutover Program Round。**

### 2.2 为什么现在可以合并
因为当前已经具备：
1. first-cutover 与 widened execution subset 的连续落地证据；
2. retained anchor / rollback / hold / observability 的成套证据；
3. `review_group` true-exit-gate 与 true-exit-candidate 的前置条件清单；
4. DB/API uplift-absorb judgment / readiness 的 seam families 最小清单；
5. BR / UI 已连续多轮吸收 P3.3.9 → P3.3.13 的 judgment / candidate / readiness 结果；
6. 继续按旧节奏拆成多个正式轮次，治理收益开始下降，而推进成本开始上升。

### 2.3 为什么不能把合并理解成“一步到位直接宣告切完”
因为以下现实仍成立：
1. current runtime truth 仍大面积围绕 cloud `review_group`
2. 首页仍是 `study_default`
3. active continuation 仍未切到 local path
4. final fact / settlement 仍以后端为准
5. DB / API active baseline 仍是 `v0.2.1`
6. `review_group` 仍未进入 true exit
7. uplift-absorb-readiness 仍不是 uplift absorbed

所以，P3.3.14 虽然是 **1 个合并轮次**，但它不是：

> **一上来就 full cutover completed / true exit / uplift absorbed / cleanup completed 的宣告轮。**

---

## 3. 当前阶段命名

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.14 Final Cutover Program Preflight

### 一句话定义

> **P3.3.14 是把最后几轮合并成 1 个项目轮次，但在内部拆成 A / B / C 三个 checkpoint：A 先锁 judgment，B 再做真实 cutover 执行，C 最后才允许 absorb / cleanup。**

---

## 4. Room 1 当前判断（最关键）

### 4.1 总结论
> **P3.3.14 可以正式启动。**
>
> **但必须按 1 轮 3 checkpoint 的方式推进：A → B → C。**

### 4.2 Room 1 对合并轮次的硬理解
Room 1 当前只接受这样的 P3.3.14：

1. **A = Final Judgment Lock**
   - 把 fuller-cutover、true-exit-gate、uplift-absorb、cleanup 的生效前提一次写硬
   - 没过 A，不得进 B

2. **B = Real Cutover Execution**
   - 真正做更接近 full cutover 的执行
   - 没过 B，不得进 C

3. **C = Same-Round Absorb / Cleanup Closeout**
   - 只有当 B 的 runtime truth、回归、证据包都通过后
   - 才允许在同一轮尾部做 true exit / uplift absorbed / cleanup 的 absorb

### 4.3 Room 1 当前不接受的做法
本轮不接受：
1. 一上来直接宣告 runtime owner shift completed
2. 一上来直接宣告 `review_group` 已 true exit / 可清理
3. 一上来直接把 active DB/API uplift 写成已 absorbed
4. 不区分 A / B / C，直接把 fuller cutover + true exit + uplift absorbed + cleanup 一把梭绑成单次生效
5. 任何“因为已经合并成 1 轮，所以内部 checkpoint 可以省掉”的做法

---

## 5. 本轮核心问题（Room 1 统一问题集）

### Q1. `final_cutover_judgment_lock_v1`
本轮要不要正式推进：
- 哪些条件必须在 A checkpoint 被写硬
- 哪些 still-dependent paths 必须先被显式承认
- 哪些 overclaim 仍是禁区

### Q2. `real_cutover_execution_subset_v1`
本轮要不要正式推进：
- 哪些 serving-adapter / review-serving / homepage review acceptance 层可以在 B checkpoint 真正切换
- 切换后 blast radius、rollback complexity 如何控制

### Q3. `true_exit_absorb_gate_v1`
本轮要不要正式推进：
- `review_group` 从 true-exit-candidate 走到 true exit，最低还缺什么
- 哪些 replacement path / compatibility anchor / completion gating 必须先被证明成立

### Q4. `db_api_uplift_absorb_gate_v1`
本轮要不要正式推进：
- 哪些 DB/API seam 足够进入 absorbed judgment
- 哪些仍只能停留在 marker / migration / rollback / hold 层

### Q5. `fact_owner_cutover_guardrail_v1`
本轮要不要正式推进：
- serving seam 再前进一步后，哪些 final fact 仍绝不能跟着一起切
- 哪些 stronger-ingest path 只允许留在 candidate / readiness，而不升格为 owner

### Q6. `same_round_cleanup_gate_v1`
本轮要不要正式推进：
- cleanup / old-path purge 何时才允许在 C checkpoint 被吸收
- 哪些条件不满足时，必须 stop at B，不得进入 C

---

## 6. 本轮范围（In Scope）

### 6.1 A checkpoint — Final Judgment Lock
本轮纳入：
1. `final_cutover_judgment_lock_v1`
2. `true_exit_absorb_gate_v1`
3. `db_api_uplift_absorb_gate_v1`
4. `fact_owner_cutover_guardrail_v1`

### 6.2 B checkpoint — Real Cutover Execution
本轮纳入：
1. `real_cutover_execution_subset_v1`
2. rollback / hold / observability
3. true-exit-candidate → true-exit-ready 的 very narrow transition
4. uplift-absorb-readiness → uplift-absorb-ready 的 very narrow transition

### 6.3 C checkpoint — Same-Round Absorb / Cleanup Closeout
本轮纳入：
1. `same_round_cleanup_gate_v1`
2. absorb / cleanup / old-path purge 的进入条件
3. same-round closeout 的 write-back order

### 6.4 本轮允许合并，但不允许省略 gate
本轮允许把原先后续几轮压成一个正式编号轮次；
但不允许跳过：
- judgment lock
- real execution
- absorb / cleanup gate

---

## 7. 当前不纳入（Out of Scope）

以下内容 **不因 P3.3.14 自动纳入**：

1. A 未过时的 B 执行
2. B 未过时的 C absorb / cleanup
3. 无证据的 `review_group` true exit
4. 无证据的 active DB/API uplift absorbed
5. 无证据的 final fact owner shift
6. homepage route / planner-aware runtime route
7. active continuation source switch（除非被 A / B checkpoint 明确批准）
8. DB schema 重构
9. API core semantics 重写
10. 用户可见“已切完 / 已退场 / 已 absorbed / 已 cleanup”的先行宣告

---

## 8. 各 Room 任务分配

## 8.1 Room 2 — Final Cutover Program 技术先行
### 任务
产出：
`R2_P3_3_14_FinalCutoverProgram_Tech_Note_v0.1.md`

### 必答
1. A checkpoint 的技术生效前提清单
2. B checkpoint 真正可切的 execution subset
3. `review_group` true exit 的最低技术条件
4. DB/API uplift absorbed 的最低技术条件
5. cleanup 能否和 absorb 同轮尾部完成
6. 哪些动作一旦出现就越界成无门槛 bundling

### Done
给出：
- A/B/C checkpoint 技术进入条件
- true-exit / uplift-absorb / cleanup 的最小判断线
- Room 1 可 pin 的 final program contract

## 8.2 Room 3 — 规则与事实边界判断
### 任务
产出：
`R3_P3_3_14_FinalCutoverProgram_Rules_Note_v0.1.md`

### 必答
1. 哪些业务事实可进入 A judgment lock
2. 哪些 truth 可在 B execution 改写
3. 哪些 fact / settlement truth 仍必须锁在后端
4. 哪些文案一旦出现就属于 overclaim
5. cleanup / old-path purge 的最低业务前提
6. 哪些必须 stop at B，不得进 C

### Done
给出：
- A/B/C 对应的 rule-set
- fact-owner boundary
- must-hold / must-escalate 列表
- Room 1 可直接吸收的判定句

## 8.3 Room 5 — 页面 / 状态 /文案 final program 判断
### 任务
产出：
`UI_SPEC_P3_3_14_FinalCutoverProgram_UI_Preflight_v0.1.md`

### 必答
1. A/B/C 各 checkpoint 下，页面分别怎么表达
2. 哪些页面状态仍必须保持 current runtime truth
3. 哪些 helper / summary / CTA / fallback 能在 B 扩大
4. 哪些 UI 表述只有到 C 才允许出现
5. 哪些仍必须继续后置
6. 同轮 absorb / cleanup 的最小 UI 风险控制

### Done
给出：
- A/B/C 的 UI 状态承接建议
- runtime-truth guardrails
- overclaim 禁区
- Room 1 可 pin 的最小 UI program contract

---

## 9. 执行顺序（固定）

1. **Room 2**
2. **Room 3**
3. **Room 5**
4. **Room 1**
5. **Room 4**（仅在 Room 1 正式下发 `R1 → R4 P3.3.14 Execution Handoff` 后）

---

## 10. 风险 / Blockers

1. **这轮最大的风险，不是“做不完”，而是“因为合并了，就误以为可以跳过中间 gate”。**
2. **`review_group` true exit 仍是最容易被过度宣告的点。**
3. **DB/API uplift absorbed 仍不能只靠 candidate / readiness artifacts 直接升格。**
4. **cleanup 是最后吸收，不是顺手附带。**
5. **如果 A 不够硬、B 证据不够全，C 必须取消。**

---

## 11. Room 1 下一步输出

当 Room 2 / Room 3 / Room 5 本轮输入交齐后，Room 1 下一步只会在以下两种输出中二选一：

### 方案 A
`R1_P3_3_14_Close_Preflight_Note_v0.1.md`
- 若当前仍不足以进入 Final Cutover Program execution

### 方案 B
`R1_to_R4_P3_3_14_Execution_Handoff_v0.1.md`
- 若当前已足够进入 P3.3.14 Final Cutover Program 的 A/B/C checkpoint execution

---

## 12. Room 1 一句话 handoff

> **请 Room 2 / Room 3 / Room 5 围绕 `final_cutover_judgment_lock_v1`、`real_cutover_execution_subset_v1`、`true_exit_absorb_gate_v1`、`db_api_uplift_absorb_gate_v1`、`fact_owner_cutover_guardrail_v1` 与 `same_round_cleanup_gate_v1` 六个问题，完成一轮同边界、同问题集、同口径的 P3.3.14 输入；本轮允许把最后几轮合成 1 个项目轮次，但必须按 A judgment lock → B real execution → C absorb / cleanup 的 3 checkpoint 推进，不得把 true exit / uplift absorbed / cleanup 一上来就写成已生效事实。**
