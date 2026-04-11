# R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** active / scope pin / unified handoff entry
- **Role basis:** `room1_v0.2.0.md`
- **Runtime basis:** `Main_updated_2026-04-10_v24.md` + `STATUS_updated_2026-04-10_v22.md`
- **Review basis for this round:**
  - `BR-OPP-001_v0.2.5.md`
  - `UI_SPEC_v0.2.5.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `p3.3.4_user.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 user 已直接拍板的下一轮 focus：

> **P3.3.4 — Preview Re-entry + Stronger Bridge Round**

正式收进主线程，并转译成一份 **统一 handoff 入口**，供 Room 2 / Room 3 / Room 5 依同一范围、同一问题集、同一交付口径推进。

本文件不是：
- 新 PRD
- 新 BR 主文档
- 新 DB / API 主文档
- Room 4 执行任务单
- P3.3.4 closeout

本文件只做一件事：

> **在 P3.3.3 已冻结 review planning minimal contract 的前提下，把 `previewDurations` 的最小 re-entry 与 ReviewPage `stronger bridge contract` 收成下一轮可被 Room 1 判断是否 pin 的合同入口。**

---

## 1. 背景

当前推进层 SSOT 已明确：
- `P3.3.3` 已 closed；
- 当前主线程状态应视为 **Next-Focus Pending**；
- BR / UI 主文件已完成回写更新；
- 当前 runtime 已冻结：
  - `review_readiness_policy_v1`
  - `review_priority_policy_v1`
  - `review_group_generation_policy_v1`
  - `schedule_source_contract_v1`
- 当前仍明确保持 deferred / pending：
  - `previewDurations` future re-entry
  - stronger ReviewPage bridge contract
  - mixed / auto-routing runtime
  - unified planner / planner merge
  - unified Study / Review page
  - exact group size contract
  - full priority scoring
  - 完整 SRS / 完整 review planning product

与此同时，`p3.3.4_user.md` 已直接给出本轮建议主题与边界：

> **在 `P3.3.3` 已冻结 readiness / priority / generation / schedule_source 的前提下，推进 `previewDurations` 的最小 re-entry 与 ReviewPage stronger bridge contract，但仍不进入 auto-routing / unified planner / planner merge。**

因此，Room 1 现将 user 直接拍板的下一方向正式命名为：

> **P3.3.4 — Preview Re-entry + Stronger Bridge Round**

一句话：

> **先把 `previewDurations` 的最小回归合同和 ReviewPage stronger bridge 的最小技术收口做出来，再决定是否给 Room 4。**

---

## 2. 当前阶段命名

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.4 Scope Pin / Preview Re-entry + Stronger Bridge Preflight

### 一句话定义

> **P3.3.4 不是做完整复习规划产品，而是把 `previewDurations` 从 deferred 推进到“最小可开发合同候选”，并把 ReviewPage bridge 从 residual technical reality 推进到“更强但仍受边界约束的 contract candidate”。**

---

## 3. 本轮核心问题（Room 1 统一问题集）

本轮必须回答的不是零散讨论，而是以下 4 个主线程问题：

### Q1. `preview_durations_reentry_contract_v1`
当前轮要不要正式推进：
- `previewDurations` 的 source of truth 是谁
- 先只放 StudyPage，还是允许 Study + Review
- 它是 hint 还是可依赖计划事实
- explanation 是否必须带“预计 / 仅供参考”语气
- 哪些表达必须继续列为 fact-copy 禁区

### Q2. `reviewpage_stronger_bridge_contract_v1`
当前轮要不要正式推进：
- ReviewPage 当前的 `controlled best-effort` 是否需要进一步收紧
- `ensure-local-card-state / init` 要不要进入更强保障层
- bridge miss / bridge failure 的最小修复路径是什么
- failure handling 是否需要更强 dev/test 可观测性

### Q3. `preview + bridge` 的 UI / 文案事实边界
当前轮要不要正式冻结：
- preview 落位
- Study only vs Study + Review
- ReviewPage 是否仍禁止显示 preview
- stronger bridge 完成后哪些话仍不能写成“系统已安排 / 已更新计划 / 下次将在 X 天后复习”

### Q4. `preview + bridge` 的最小测试与回写合同
当前轮要不要正式冻结：
- preview 显示 / 不显示断言
- source 正确性断言
- stronger bridge 行为断言
- 文案不越界断言
- BR / UI 主文档 patch / sync 要求

---

## 4. 本轮范围（In Scope）

### 4.1 Preview Re-entry
本轮纳入：
1. `preview_durations_reentry_contract_v1` 候选
2. source of truth
3. Study only vs Study + Review
4. explanation boundary
5. UI 落位与 fact-copy 边界
6. 只推进到 minimal contract，不自动等于实现 winner

### 4.2 Stronger Bridge
本轮纳入：
1. `reviewpage_stronger_bridge_contract_v1` 候选
2. stronger local ensure / init 是否进入合同
3. bridge observability
4. bridge failure handling boundary
5. bridge miss 的最小修复路径
6. 只推进到 minimal stronger contract，不自动等于 planner merge

### 4.3 Preview + Bridge 的 UI / Copy / Test
本轮纳入：
1. preview 的页面落位与禁区
2. stronger bridge 的页面事实边界
3. preview / bridge 的测试断言最小集合
4. patch / sync plan

### 4.4 只做 contract / planning 层，不做实现层
本轮纳入的是：
- source of truth
- owner 边界
- explanation boundary
- fact-copy guardrails
- stronger bridge 上限
- 测试与回写合同

本轮**不直接纳入** Room 4 实现。

---

## 5. 当前不纳入（Out of Scope）

以下内容 **不因 P3.3.4 自动纳入**：

1. mixed / auto-routing runtime
2. unified planner / planner merge
3. unified Study / Review page
4. exact group size contract
5. full priority scoring
6. 完整 SRS / 完整复习调度产品
7. 完整 preview explanation system
8. 完整 planner explanation product
9. DB schema 重构
10. API core semantics 重构

---

## 6. Room 1 当前判断

### 6.1 总结论
> **P3.3.4 仍然先走 contract-gate / preflight。**

原因很简单：
- `P3.3.3` 才刚把 review planning minimal contract 收住；
- BR / UI 当前继续明确把 `previewDurations` future re-entry 与 stronger bridge contract 保持为 pending；
- `p3.3.4_user.md` 自己也明确建议本轮只推进“最小可开发合同”，不要直接跳进 unified planner 深水区。

### 6.2 Room 1 倾向
Room 1 倾向：
- **本轮先让 Room 2 / Room 3 / Room 5 交一轮专项输入**
- 再由 Room 1 统一判断：
  - 继续只停在 preflight
  - 还是正式 pin `preview_durations_reentry_contract_v1` 与 / 或 `reviewpage_stronger_bridge_contract_v1` 的最小子集
- **Room 4 只有在 Room 1 正式产出 `R1 → R4 P3.3.4 Execution Handoff` 后才进入**

---

## 7. 各 Room 任务分配

## 7.1 Room 2 — 技术 framing 先行
### 任务
产出：
`R2_P3_3_4_PreviewReentry_and_StrongerBridge_Tech_Note_v0.1.md`

### 必答
1. `preview_durations_reentry_contract_v1` 的 source of truth 应该是谁
2. Preview 当前最稳是 Study only 还是可安全进入 Study + Review
3. preview 如果回归，是否必须以 hint / estimated contract 进入
4. stronger bridge 是否值得从 `controlled best-effort` 进一步收紧
5. `ensure-local-card-state / init`、observability、failure handling 最低能冻结到哪一层而不碰 API / DB major
6. 哪些动作一旦出现就越界成 planner merge / unified planner / API core semantics change

### Done
给出：
- 推荐进入层
- 推荐不进入层
- 越界红线
- 推荐 Room 1 可 pin 的最小合同集合

---

## 7.2 Room 3 — 规则语义收口
### 任务
产出：
`R3_P3_3_4_PreviewReentry_and_StrongerBridge_Rules_Note_v0.1.md`

### 必答
1. `preview_durations_reentry_contract_v1` 在业务上是什么意思
2. preview 是 hint、candidate 还是计划事实
3. 哪些 preview / schedule explanation 文案必须继续列为硬禁区
4. stronger bridge 在业务上应该被写到哪一层，不该被写到哪一层
5. stronger bridge 完成后哪些话仍不能写成“系统已安排 / 已同步计划 / 下次将在 X 天后复习”
6. 哪些内容必须继续 pending，防止 Room 4 / UI 误升格

### Done
给出：
- Frozen candidate
- Pending items
- Fact-copy / rule-boundary 护栏
- 可直接给 Room 1 吸收的决策句

---

## 7.3 Room 5 — UI / state impact 判断
### 任务
产出：
`UI_SPEC_P3_3_4_PreviewReentry_and_StrongerBridge_UI_Preflight_v0.1.md`

### 必答
1. preview 若回归，应该落在哪些页面 / 区块
2. Preview 当前最稳是 Study only 还是 Study + Review
3. explanation 语气是否必须显示“预计 / 仅供参考”
4. stronger bridge 会影响哪些页面状态与文案边界
5. ReviewPage 当前是否仍应禁止 preview 显示
6. 哪些表达会把 preview / stronger bridge 写成既成事实或完整 planner

### Done
给出：
- 页面承接建议
- state contract risk
- fact-copy 禁区
- 推荐 Room 1 可 pin 的最小 UI 合同层

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
   - 先把 source of truth、bridge stronger 上限、Major 红线写硬
2. **Room 3 第二**
   - 在 Room 2 技术 framing 基础上，把 preview / stronger bridge 的业务语义和 fact-copy 边界写硬
3. **Room 5 第三**
   - 基于 Room 2 + Room 3 的共同边界，判断页面落位 / 文案 / state impact
4. **Room 1 第四**
   - 统一吸收，决定这轮是继续 preflight 还是 pin 下一层最小合同
5. **Room 4 最后**
   - 只有当 Room 1 明确下发 `R1 → R4` 执行单后，才允许进入实现治理 / 执行层

---

## 9. Room 1 下一步输出

当 Room 2 / Room 3 / Room 5 本轮输入交齐后，Room 1 下一步只会在以下两种输出中二选一：

### 方案 A
`R1_P3_3_4_Close_Preflight_Note_v0.1.md`
- 若当前仍不适合 pin preview / stronger bridge contract
- 继续保持 pending，并记录 why / what next

### 方案 B
`R1_to_R4_P3_3_4_Execution_Handoff_v0.1.md`
- 若当前已足够进入 very narrow execution layer
- 只把 Room 1 明确 pin 的最小合同下发给 Room 4

---

## 10. Room 1 一句话 handoff

> **请 Room 2 / Room 3 / Room 5 围绕 `preview_durations_reentry_contract_v1`、`reviewpage_stronger_bridge_contract_v1`、`preview + bridge` 的 UI / 文案事实边界、以及最小测试与回写合同四个问题，先完成一轮同边界、同问题集、同口径的 contract-gate 输入；P3.3.4 当前仍不直接进入大实现。**
