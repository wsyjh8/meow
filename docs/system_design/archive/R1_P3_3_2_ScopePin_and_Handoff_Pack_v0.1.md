# R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** active / scope pin / unified handoff entry
- **Role basis:** `room1_v0.2.0.md`
- **Runtime basis:** `Main_updated_2026-04-10_v20.md` + `STATUS_updated_2026-04-10_v19.md`
- **Review basis for this round:**
  - `BR-OPP-001_v0.2.3.md`
  - `UI_SPEC_v0.2.3.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 user 已直接拍板的下一轮 focus：

> **P3.3.2 — 复习规划继续深化**

正式收进主线程，并转译成一份 **统一 handoff 入口**，供 Room 2 / Room 3 / Room 5 依同一范围、同一问题集、同一交付口径推进。

本文件不是：
- 新 PRD
- 新 BR 主文档
- 新 DB / API 主文档
- Room 4 执行任务单
- P3.3.2 closeout

本文件只做一件事：

> **把 P3.3 overall closed 之后，关于复习规划继续深化的下一轮问题，先收口成一轮 contract preflight / gate，而不是直接进入实现。**

---

## 1. 背景

当前推进层 SSOT 已明确：
- `P3.3` 已 overall closed；
- 当前主线程状态仍是 **Next-Focus Pending**；
- `P3.3.1` 已完成 final wording freeze、`previewDurations` defer、ReviewPage bridge controlled best-effort 与 UI / 文案 / 测试补强。

与此同时，本轮已更新的 BR / UI 主文件继续共同指向同一批 **尚未正式收口的 review planning pending**：
1. 首页点击“背单词”后的 **session entry** 合同仍未最终 pin；
2. 云端 `review_group` 与本地 FSRS 的 **planner owner / 收敛方向** 仍 pending；
3. 完整 review planning / 更下一层 review planning contract 仍未决定是否进入。

因此，Room 1 现将 user 直接拍板的下一方向正式命名为：

> **P3.3.2 — Review Planning Deepening / Contract Gate**

一句话：

> **先把“入口怎么定、谁是 planner owner、cloud review_group 与 local FSRS 怎么分工、要不要进下一层 contract”收口，再决定是否给 Room 4。**

---

## 2. 当前阶段命名

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — P3.3.2 Scope Pin / Review Planning Contract Preflight

### 一句话定义

> **P3.3.2 不是立刻做完整复习系统，而是先决定：我们是否从“已跑通的第一拍”继续进入“更明确的复习规划合同层”。**

---

## 3. 本轮核心问题（Room 1 统一问题集）

本轮必须回答的不是零散讨论，而是以下 3 个主线程问题：

### Q1. Session Entry
首页点“背单词”后，当前轮要把 session entry 明确到哪一层？
- 只是继续保留轻入口 + 现状承接？
- 还是明确进入：
  - 新词优先
  - 复习优先
  - active group continuation 优先
  - 混合 / 自动分流

### Q2. Planner Owner
在当前 dual-store 现实下，谁是复习规划层的 owner？
- 云端 `review_group`
- 本地 FSRS
- 二者分层共存
- 还是需要新的 planner contract

### Q3. 下一层 Review Planning Contract
当前轮是否要从 preflight 进入 **next-layer review planning contract**？
- 若进入：最小合同是什么
- 若不进入：哪些点继续保持 pending
- 进入后是否会触碰 DB / API / planner owner / UI state contract

---

## 4. 本轮范围（In Scope）

### 4.1 Session Entry 继续明确
本轮纳入：
1. 首页“背单词”入口之后的 session entry 路径候选
2. active `review_group` continuation 与新词入口的优先级关系
3. 是否允许“自动分流 / 混合进入”进入候选合同层
4. session entry 继续只停留在 UI 承接，还是进入 contract 层

### 4.2 Planner Owner / 分工继续明确
本轮纳入：
1. 云端 `review_group` 与本地 FSRS 的职责边界
2. 哪一层负责：
   - 队列
   - continuation
   - 计划生成 / interval
   - 结果提交后的本地 side-effect
3. 当前轮是否要继续保持“cloud-first + local side-effect”
4. 若要更深入，最低要进入到哪一层 contract

### 4.3 是否进入下一层 Review Planning Contract
本轮纳入：
1. Room 2 给出技术进入条件 / 风险 / 推荐
2. Room 3 给出业务语义边界 / 不可脑补项
3. Room 5 给出 UI / 状态层影响
4. 最终由 Room 1 判断：
   - 本轮只完成 preflight
   - 还是正式 pin 下一层 contract

### 4.4 只做 contract / planning 层，不做实现层
本轮纳入的是：
- 方案范围
- owner 边界
- 状态与合同
- 进入条件
- 风险与不做什么

本轮**不直接纳入** Room 4 实现。

---

## 5. 当前不纳入（Out of Scope）

以下内容 **不因 P3.3.2 自动纳入**：

1. 不直接实现完整 SRS / 完整复习调度算法
2. 不直接改 DB schema
3. 不直接改 API core semantics
4. 不直接改 `review_group` 最小合同
5. 不直接把本地 FSRS 升格成唯一 planner owner
6. 不直接把首页 CTA winner 重写成完整状态驱动系统
7. 不直接合并 StudyPage / ReviewPage 为统一学习页
8. 不直接重新打开 `previewDurations`
9. 不直接让 Room 4 按猜测进入编码

一句话：

> **P3.3.2 先做“要不要进下一层 contract”的判断，而不是先把下一层当成已决定事实。**

---

## 6. Room 1 当前主线程判断

### 6.1 为什么这轮不能直接交给 Room 4
因为当前尚未收口的 3 个问题都不是纯实现问题：
1. **session entry** 会影响产品路径与 UI 承接；
2. **planner owner** 会影响 core contract / technical boundary；
3. **review_group 与 local FSRS 分工** 会同时影响 BR / DB / API / UI / TEST。

这类问题如果不先收口，Room 4 会被迫替 Room 1 / Room 2 / Room 3 拍板。

### 6.2 Room 1 当前倾向
Room 1 当前倾向是：

> **P3.3.2 先以“contract preflight / gate”推进；只有在 Room 2 / Room 3 / Room 5 交回后，Room 1 才决定是否升级为 `R1 → R4 P3.3.2 Execution Handoff`。**

---

## 7. 各 Room 的执行顺序（Room 1 正式排序）

### 正式顺序
1. **Room 2**
2. **Room 3**
3. **Room 5**
4. **Room 1 吸收并拍板**
5. **若通过，再进入 Room 4**

### 为什么是这个顺序

#### 1) Room 2 先
因为本轮最先要收口的是：
- planner owner
- cloud review_group vs local FSRS 的技术边界
- 是否会触碰 DB / API / core contract

这些是 **Room 2 的 first-pass 技术 framing**，应先给出可行边界和不该越线的地方。

#### 2) Room 3 第二
因为 Room 3 需要在 **Room 2 已给出的技术可行边界** 上，写硬：
- session entry 的业务语义
- planner owner / 分工在业务上意味着什么
- 哪些表达 / 哪些 contract 会越界

#### 3) Room 5 第三
因为 UI / UX 需要建立在：
- 业务语义先收口
- 技术边界先明确

之后才能判断：
- 首页“背单词”点进去怎么承接
- 是否需要新状态
- 哪些状态仍不能写成系统事实

#### 4) Room 1 第四
Room 1 负责把 2 / 3 / 5 的输入统一吸收，决定：
- 继续只停留在 preflight
- 还是正式进入 next-layer review planning contract

#### 5) Room 4 最后
只有当 Room 1 正式下发 `R1 → R4` 执行单后，Room 4 才进入。

---

## 8. 给各 Room 的任务定义

## 8.1 Room 2 — Technical Framing First Pass
### 任务
请 Room 2 输出一份：
`R2_P3_3_2_SessionEntry_PlannerOwner_Tech_Note_v0.1.md`

### 必答问题
1. 当前 dual-store 下，session entry 的技术分流现实是什么
2. planner owner 当前最合理是谁
3. `review_group` 与本地 FSRS 的最低稳定分工是什么
4. 如果进入 next-layer review planning contract，最小可进入层是什么
5. 当前轮若进入，会不会触碰：
   - DB schema
   - API core contract
   - planner owner
   - `review_group` 最小合同
6. Room 2 推荐：
   - keep preflight
   - or enter next-layer minimal contract

### Done
- 给出 **推荐方案 + 不推荐方案 + 风险边界 + 是否建议进入下一层 contract**

---

## 8.2 Room 3 — Rules / Semantics Freeze Input
### 任务
请 Room 3 输出一份：
`R3_P3_3_2_SessionEntry_PlannerOwner_Rules_Note_v0.1.md`

### 必答问题
1. 首页点“背单词”后的 session entry，在业务语义上允许冻结到哪一层
2. `review_group` 与本地 FSRS 在业务上各自代表什么
3. planner owner 若继续 pending，哪些实现 / UI 表达绝不能偷写成已收口事实
4. 若进入 next-layer review planning contract，Room 3 允许冻结哪些业务语义；哪些继续 pending
5. 哪些文案 / 状态是高风险误导

### Done
- 给出 **业务语义边界 + forbidden assumptions + 是否支持进入下一层 contract 的规则判断**

---

## 8.3 Room 5 — UI / State Impact Note
### 任务
请 Room 5 输出一份：
`R5_P3_3_2_SessionEntry_and_ReviewPlanning_UI_Impact_Note_v0.1.md`

### 必答问题
1. 首页“背单词”点击后的 UI 承接，当前最小可成立路径是什么
2. 若 session entry 仍 pending，UI 应如何避免假确定性
3. 若进入 next-layer review planning contract，最少需要新增哪些 UI state / state matrix
4. Study / Review / Today / HomeEntry 哪些页面会被影响
5. 哪些 UI 表达必须继续保持中性，不得冒充计划事实

### Done
- 给出 **最小 UI 承接建议 + state impact matrix + 是否支持进入下一层 contract 的 UI judgment**

---

## 9. Room 1 的后续动作

在 Room 2 / Room 3 / Room 5 交回后，Room 1 只做两件事：

1. 统一吸收三方输入
2. 输出二选一结论：
   - **A. 继续停留在 preflight，暂不进入 next-layer contract**
   - **B. 正式进入 next-layer minimal review planning contract，并下发 `R1_to_R4_P3_3_2_Execution_Handoff_v0.1.md`**

---

## 10. 一句话 handoff

> **请 Room 2 先做技术 framing，Room 3 再做业务语义收口，Room 5 最后做 UI/state 影响判断；Room 1 将基于三方输入，决定 P3.3.2 是停留在 review planning preflight，还是正式进入 next-layer review planning contract。**
