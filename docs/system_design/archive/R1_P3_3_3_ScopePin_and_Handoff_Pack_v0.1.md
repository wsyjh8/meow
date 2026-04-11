# R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** active / scope pin / unified handoff entry
- **Role basis:** `room1_v0.2.0.md`
- **Runtime basis:** `Main_updated_2026-04-10_v21.md` + `STATUS_updated_2026-04-10_v20.md`
- **Review basis for this round:**
  - `BR-OPP-001_v0.2.4.md`
  - `UI_SPEC_v0.2.4.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `p3.3.3_user.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 user 已直接拍板的下一轮 focus：

> **P3.3.3 — Review Planning Contract v1 / SRS Boundary Round**

正式收进主线程，并转译成一份 **统一 handoff 入口**，供 Room 2 / Room 3 / Room 5 依同一范围、同一问题集、同一交付口径推进。

本文件不是：
- 新 PRD
- 新 BR 主文档
- 新 DB / API 主文档
- Room 4 执行任务单
- P3.3.3 closeout

本文件只做一件事：

> **把 P3.3.2 已冻结的 `session_entry_policy_v1` 与 `planner_owner_split_v1` 继续向下一层复习规划合同推进，但仍然先走 contract gate / preflight，不直接进入大实现。**

---

## 1. 背景

当前推进层 SSOT 已明确：
- `P3.3.2` 已 closed；
- 当前主线程状态仍是 **Next-Focus Pending**；
- BR / UI 主文件已完成回写更新；
- 当前 runtime 已冻结：
  - `session_entry_policy_v1`
  - `planner_owner_split_v1`

与此同时，当前 BR / UI 仍共同保留以下 review planning deeper-contract pending：
1. `review_readiness`
2. `review_priority`
3. `review_group_generation`
4. `schedule_source_contract`
5. `previewDurations` future contract re-entry

因此，Room 1 现将 user 直接拍板的下一方向正式命名为：

> **P3.3.3 — Review Planning Contract v1 / SRS Boundary Round**

一句话：

> **先把“什么时候该复习、谁优先、group 怎么生成、schedule source 怎么对接、previewDurations 要不要进合同”收口成下一层最小合同，再决定是否给 Room 4。**

---

## 2. 当前阶段命名

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.3 Scope Pin / Review Planning Contract v1 Preflight

### 一句话定义

> **P3.3.3 不是直接做完整 SRS 或完整复习系统，而是把 review planning 从“入口与 owner split”继续推进到“可被 BR / UI / TEST / execution 引用的下一层最小合同”。**

---

## 3. 本轮核心问题（Room 1 统一问题集）

本轮必须回答的不是零散讨论，而是以下 5 个主线程问题：

### Q1. `review_readiness_policy_v1`
当前轮要不要正式冻结：
- 什么叫“该复习”
- 什么叫“可进入下一组”
- 什么叫“本轮可服务 / 暂不可服务”
- readiness 以后端聚合还是本地 FSRS 计算为准

### Q2. `review_priority_policy_v1`
当前轮要不要正式冻结以下优先级层级：
- active `review_group` continuation
- due review
- high-priority review
- new words
- session

### Q3. `review_group_generation_policy_v1`
当前轮要不要正式冻结：
- group size 是否进入合同
- group 何时生成
- group 何时补发 / 续发
- group completion 后下一个 group 的最小进入条件

### Q4. `schedule_source_contract_v1`
当前轮要不要正式冻结：
- local FSRS 输出什么给规划层
- cloud `review_group` 消费什么
- 哪些是本地 scheduling truth
- 哪些是云端 serving truth
- 两边最小交界面是什么

### Q5. `preview_durations_contract_decision`
当前轮至少要拍一件事：
- `previewDurations` 继续 deferred
- 或者正式进入下一层合同

若进入，则至少要先回答：
- 数据来源是谁
- 解释层怎么显示
- 是 Study only 还是 Study + Review

---

## 4. 本轮范围（In Scope）

### 4.1 Review Readiness
本轮纳入：
1. `review_readiness_policy_v1` 候选
2. readiness truth source（cloud aggregate vs local FSRS）
3. “可服务 / 暂不可服务 / 可进入下一组”的最小合同

### 4.2 Review Priority
本轮纳入：
1. `review_priority_policy_v1` 候选
2. continuation / due / high-priority / new words / session 的层级关系
3. 只冻结层级，不冻结完整算法

### 4.3 Review Group Generation
本轮纳入：
1. `review_group_generation_policy_v1` 候选
2. group size 是否进入合同
3. generation / regeneration / next-group 最小进入条件

### 4.4 Schedule Source
本轮纳入：
1. `schedule_source_contract_v1` 候选
2. local FSRS 与 cloud `review_group` 的最小交界面
3. 不同 truth 层的输出 / 消费边界

### 4.5 Preview Durations Decision
本轮纳入：
1. `previewDurations` 是否继续 deferred
2. 若要进入下一层合同，进入的最小形式是什么
3. 不直接等于实现层落地

### 4.6 只做 contract / planning 层，不做实现层
本轮纳入的是：
- 方案范围
- owner 边界
- truth source
- 状态与合同
- 进入条件
- 风险与不做什么

本轮**不直接纳入** Room 4 实现。

---

## 5. 当前不纳入（Out of Scope）

以下内容 **不因 P3.3.3 自动纳入**：

1. 不直接实现完整 SRS 引擎
2. 不直接实现完整复习调度算法
3. 不直接做 auto-routing runtime 行为
4. 不直接做 complete planner merge / unified planner
5. 不直接重写 DB schema
6. 不直接重写 API core semantics
7. 不直接把 StudyPage / ReviewPage 合并成统一学习页
8. 不直接把 stronger ReviewPage bridge contract 拉进实现层
9. 不直接把 CTA winner 改成完整状态驱动系统
10. 不直接把 preview / schedule explanation 写成当前稳定事实

---

## 6. Room 1 当前判断

### 6.1 总结论
> **P3.3.3 仍然先走 contract-gate / preflight。**

原因很简单：
- 当前 `P3.3.2` 只冻结到入口语义与 owner split；
- BR / UI 继续明确保留更深的 readiness / priority / generation / preview contract 为 pending；
- user 的 `p3.3.3_user.md` 也明确建议本轮“继续收口最小合同边界，但仍然先不直接进入大实现”。

### 6.2 Room 1 倾向
Room 1 倾向：
- **本轮先让 Room 2 / Room 3 / Room 5 交一轮专项输入**
- 再由 Room 1 统一判断：
  - 继续只停在 preflight
  - 还是正式 pin `Review Planning Contract v1` 的最小子集
- **Room 4 只有在 Room 1 正式产出 `R1 → R4 P3.3.3 Execution Handoff` 后才进入**

---

## 7. 各 Room 任务分配

## 7.1 Room 2 — 技术 framing 先行
### 任务
产出：
`R2_P3_3_3_ReviewPlanningContractV1_Tech_Note_v0.1.md`

### 必答
1. `review_readiness_policy_v1` 的最小 truth source 应该是谁
2. `review_priority_policy_v1` 最低能冻结到哪一层而不碰 API / DB major
3. `review_group_generation_policy_v1` 最低能冻结到哪一层而不改最小合同
4. `schedule_source_contract_v1` 的最小交界面是什么
5. `previewDurations` 继续 deferred 还是可进入下一层 minimal contract
6. 哪些动作一旦出现就越界成 Major

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
`R3_P3_3_3_ReviewPlanningContractV1_Rules_Note_v0.1.md`

### 必答
1. `review_readiness_policy_v1` 在业务上是什么意思
2. `review_priority_policy_v1` 哪些层级可以先冻结
3. `review_group_generation_policy_v1` 哪些可写成规则，哪些必须继续 pending
4. `schedule_source_contract_v1` 的业务语义边界是什么
5. `previewDurations` 若继续 pending，应如何写硬禁止补脑
6. 哪些文案 / UI 表达会越过当前合同层

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
`UI_SPEC_P3_3_3_ReviewPlanningContractV1_UI_Preflight_v0.1.md`

### 必答
1. `review_readiness_policy_v1` 会影响哪些页面承接与状态块
2. `review_priority_policy_v1` 若冻结一层，首页 / ReviewPage / StudyPage 如何表达
3. `review_group_generation_policy_v1` 若冻结一层，页面应该承接到哪一层，不该承接到哪一层
4. `schedule_source_contract_v1` 会影响哪些 UI truth / 禁区
5. `previewDurations` 若继续 deferred / 若最小 re-entry，各自的 UI 风险是什么
6. 哪些表达会把 pending deeper-contract 写成既成事实

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
   - 先把技术 truth source、owner split 延伸边界、Major 红线写硬
2. **Room 3 第二**
   - 在 Room 2 技术 framing 基础上，把业务语义和规则合同写硬
3. **Room 5 第三**
   - 基于 Room 2 + Room 3 的共同边界，判断页面承接 / 文案 / state impact
4. **Room 1 第四**
   - 统一吸收，决定这轮是继续 preflight 还是 pin 下一层最小合同
5. **Room 4 最后**
   - 只有当 Room 1 明确下发 `R1 → R4` 执行单后，才允许进入实现治理 / 执行层

---

## 9. Room 1 下一步输出

当 Room 2 / Room 3 / Room 5 本轮输入交齐后，Room 1 下一步只会在以下两种输出中二选一：

### 方案 A
`R1_P3_3_3_Close_Preflight_Note_v0.1.md`
- 若当前仍不适合 pin deeper contract
- 继续保持 pending，并记录 why / what next

### 方案 B
`R1_to_R4_P3_3_3_Execution_Handoff_v0.1.md`
- 若当前已足够进入 very narrow execution layer
- 只把 Room 1 明确 pin 的最小合同下发给 Room 4

---

## 10. Room 1 一句话 handoff

> **请 Room 2 / Room 3 / Room 5 围绕 `review_readiness_policy_v1`、`review_priority_policy_v1`、`review_group_generation_policy_v1`、`schedule_source_contract_v1` 与 `preview_durations_contract_decision` 五个问题，先完成一轮同边界、同问题集、同口径的 contract-gate 输入；P3.3.3 当前仍不直接进入大实现。**
