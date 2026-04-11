# R2_P3_3_3_ReviewPlanningContractV1_Tech_Note_v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** tech framing / contract-gate input / ready for Room 1 review
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Round:** `P3.3.3 — Review Planning Contract v1 / SRS Boundary Round`

---

## 0. 文档定位

本稿不是：
- 新 DB 主文档
- 新 API 主文档
- Room 4 执行单
- 完整 SRS 方案
- 完整复习调度产品

本稿只做一件事：

> **从 Room 2 / CTO 视角，把 P3.3.3 这一轮 review planning deeper-contract 收到“可被 Room 1 判断是否 pin 的最小技术合同层”。**

一句话：

> **继续前进，但只前进到“readiness / priority / generation / schedule-source / previewDurations”五个问题的窄合同层；不直接进入完整 planner 产品，更不直接进入大实现。**

---

## 1. 输入依据与本稿采用口径

## 1.1 Role / Governance basis
- `ORG_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.2`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`

## 1.2 主线程 handoff basis
- `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md`

## 1.3 Review / runtime basis
- `BR-OPP-001_v0.2.4.md`
- `UI_SPEC_v0.2.4.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `Main_updated_2026-04-10_v21.md`
- `STATUS_updated_2026-04-10_v20.md`

## 1.4 Room 2 对当前入口一致性的处理
当前存在一个需要明确写出来的小口径：
- `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md` 已把 **`BR-OPP-001_v0.2.4.md` + `UI_SPEC_v0.2.4.md`** 指定为本轮 **review basis**；
- 但 `Main_updated_2026-04-10_v21.md` / `STATUS_updated_2026-04-10_v20.md` 片段中，仍显示 runtime active baseline 为 **BR `v0.2.3` + UI `v0.2.3`**。

因此，本稿采取以下 Room 2 口径：
1. **P3.3.3 本轮分析服从 Room 1 handoff 指定的 review basis。**
2. **不把 `v0.2.4` 自动写成已被推进层正式 pin 的 runtime truth。**
3. **若本轮结论被 Room 1 吸收，再由 Room 1 决定是否同步更新 active baseline。**

---

## 2. Room 2 总判断

## 2.1 总结论
> **Room 2 支持 P3.3.3 从 pure preflight 前进一步，但只支持进入 `Review Planning Contract v1` 的 very narrow minimal contract。**

这轮最稳的方向不是：
- 直接做完整 SRS
- 直接做完整复习调度算法
- 直接做 unified planner / planner merge
- 直接把 `previewDurations` 放进当前稳定合同

这轮最稳的方向是：
- **冻结 truth-source hierarchy**
- **冻结 readiness / priority / generation 的最低可引用层级**
- **冻结 local FSRS 与 cloud `review_group` 的 planning boundary**
- **明确哪些仍然 pending，防止 Room 4 / UI / 测试继续补脑**

## 2.2 Room 2 本轮正式推荐
Room 2 推荐 Room 1 在本轮优先考虑：

### 可进入下一层最小合同的部分
1. `review_readiness_policy_v1`
2. `review_priority_policy_v1`
3. `review_group_generation_policy_v1`（仅最小边界）
4. `schedule_source_contract_v1`

### 当前仍应保持 deferred / pending 的部分
1. `previewDurations` 继续 deferred
2. exact group size 不进入硬合同
3. full scoring / full priority algorithm 不进入硬合同
4. unified planner / planner merge 继续 pending
5. stronger ReviewPage bridge contract 继续 pending
6. mixed / auto-routing runtime contract 继续 pending

---

## 3. Q1 — `review_readiness_policy_v1`

## 3.1 Room 2 结论
> **本轮应冻结 `review_readiness_policy_v1`，但 readiness 的 serving truth source 必须继续是 cloud aggregate / cloud review-serving layer，不应改由本地 FSRS 直接担任页面级 readiness truth。**

## 3.2 为什么这样定
因为从 P3.3.2 已冻结的 owner split 往下延伸，当前已明确：
- ReviewPage 主真相层仍围绕 cloud `review_group`
- local FSRS 仍是 device-side scheduling owner
- ReviewPage 仍是 `cloud-first + local side-effect`

如果在 P3.3.3 把 readiness 直接切给本地 FSRS：
- 会与当前 ReviewPage 主 serving truth 冲突
- 会诱发 UI / TEST 把本地 due 直接当成“现在就可服务”的页面事实
- 会把 P3.3.3 从 contract gate 误推进成 planner owner 重写轮

## 3.3 Room 2 推荐的最小 readiness 合同
本轮可冻结到以下层级：

### A. 定义层
1. **`ready_now`**
   - 当前存在可被 review serving layer 立即提供的复习工作单元
   - 在当前架构下，优先表现为：
     - 有 active `review_group` continuation
     - 或 cloud 端已明确可发放下一组 review work

2. **`not_ready_now`**
   - 当前 review serving layer 不能立即提供可做的 review group / next review work
   - 不等于“本地没有 due cards”
   - 只表示当前 serving truth 下不可立即服务

3. **`next_group_eligible`**
   - 当前没有 active group，且已满足下一组可生成 / 可发放的最小前提
   - 它是 generation gating 的前提语义，不等于 group 已经在 UI 上可见

4. **`temporarily_unservable`**
   - 当前不能稳定给出 review serving 结果，原因可能是：
     - cloud aggregation 未完成
     - generation 仍未执行
     - serving summary 不足
   - 它不是“永远没得复习”，而是“当前轮不可立即服务”

### B. Truth-source 规则
1. **页面级 readiness 事实，以 cloud aggregate / review-serving summary 为准。**
2. **local FSRS 只能作为 candidate input source，不直接充当页面级 readiness truth。**
3. **前端不得用本地 due count、local card state 或 remaining 推导出 readiness 最终事实。**

## 3.4 Room 2 不建议本轮冻结的部分
1. readiness 的完整 reason enum
2. readiness 的完整时间窗与阈值算法
3. local-only readiness mode
4. “由于本地 FSRS 判断已到期，所以首页自动进入 review”这类 runtime 行为

---

## 4. Q2 — `review_priority_policy_v1`

## 4.1 Room 2 结论
> **本轮应冻结 priority 的层级顺序，但只冻结层级，不冻结完整打分算法。**

## 4.2 当前最稳的最小优先级层级
Room 2 推荐冻结为：

1. **active `review_group` continuation**
2. **due review**（仅限 cloud 侧已确认可服务）
3. **high-priority review**（仅限 cloud 侧已确认）
4. **new words**
5. **session**

## 4.3 解释
### 4.3.1 continuation 最高优先
这与 P3.3.2 已冻结内容一致：已有 active `review_group` continuation 时，优先级最高，但当前只能通过独立承接，不等于 silent reroute。

### 4.3.2 due / high-priority 仍必须是 cloud-confirmed
本轮不应把 local FSRS 的本地 due 直接提升为页面级 priority winner。否则会把 due 的真相层偷切到本地。

### 4.3.3 new words 继续作为默认主线 fallback
在没有 active continuation、没有 cloud-confirmed due / high-priority review 时，`study_default` 继续是最稳 fallback。

### 4.3.4 session 继续保守
Session 当前仍不是自动最高优先级。除非 Room 1 未来另开 round 收口 CTA / session deeper policy，否则它应继续放在本轮 hierarchy 底部。

## 4.4 本轮不建议冻结的内容
1. 完整优先级分值模型
2. due vs high-priority 的详细权重
3. local overdue bucket 如何参与最终排序
4. CTA winner 的完整状态驱动 contract

---

## 5. Q3 — `review_group_generation_policy_v1`

## 5.1 Room 2 结论
> **本轮应冻结 group generation 的“最小进入条件与 owner 归属”，但不建议冻结 exact group size，也不建议冻结完整 regeneration algorithm。**

## 5.2 Room 2 推荐冻结的部分
### A. Owner 归属
1. **group generation owner = cloud**
2. **group regeneration / replenishment owner = cloud**
3. **local FSRS 不负责直接生成 ReviewPage 主 group**

### B. 最小合同
1. **同一用户同一时刻最多一个 active `review_group`**
2. **存在 active group 时，不得再并发生成第二个 active group 供同一路径消费**
3. **只有在 active group 已完成 / 已关闭 / 已不可继续时，才允许进入 next-group decision**
4. **next group 的进入条件，至少依赖 cloud-confirmed readiness，而不是 local-only readiness**
5. **generation 可以是 on-demand / lazy generation；本轮不强制要求 pre-generation**

## 5.3 Room 2 明确不建议本轮冻结的部分
1. exact group size
2. same-day multi-group policy 的完整细则
3. pre-generation vs lazy-generation 的长期 winner
4. regeneration cadence
5. group 的完整 balancing algorithm

## 5.4 Room 2 对 group size 的建议
> **group size 当前不进入硬合同。**

理由：
- 一旦进入硬合同，后续很容易触发 API / DB / TEST / UI 多文档同步
- 这轮目标是先把 planner boundary 写硬，不是把 serving batch 设计钉死
- group size 更适合作为 cloud implementation parameter / candidate tuning point

---

## 6. Q4 — `schedule_source_contract_v1`

## 6.1 Room 2 结论
> **本轮应冻结 `schedule_source_contract_v1` 的“概念接口”和“truth split”，但不建议冻结成新的 DB schema 或新的 active API payload。**

## 6.2 Room 2 推荐的最小 truth split
### A. Local FSRS 继续输出的 candidate scheduling inputs
local FSRS 作为 device-side scheduling owner，可继续提供以下概念层输出：
1. `local_card_state exists / not exists`
2. `local_due_at` / `next_due_candidate`
3. `last_reviewed_at`
4. `interval / stability / difficulty` 的本地计算结果
5. `review logs`
6. future `previewDurations` 的候选原料

### B. Cloud `review_group` 继续承担的 serving outputs
cloud 侧继续承担：
1. review queue serving
2. active group continuation
3. next item serving
4. group completion truth
5. review-path settlement trigger
6. 进入页面级 readiness / priority / next-group 的最终可服务判断

## 6.3 本轮可冻结的最小交界面
Room 2 推荐把 `schedule_source_contract_v1` 冻结成以下原则：

1. **local FSRS → planning layer：只提供 scheduling candidates，不直接提供页面级 serving truth。**
2. **cloud review-serving layer → ReviewPage / Home review decision-support：提供最终可服务事实。**
3. **本轮的交界面是“conceptual contract”，不是“新 schema / 新 API payload 已被 pin”。**
4. **任何 future planner merge，都必须在单独 round 中把 candidate inputs 与 serving outputs 的兼容策略写硬。**

## 6.4 Room 2 不建议本轮直接冻结的字段级合同
当前不建议在 P3.3.3 直接把以下内容升格成 active contract：
- `preview_durations[]`
- `scheduler_summary`
- `readiness_reason`
- `priority_band`
- `next_group_summary`
- `local_due_bucket`

这些内容若未来进入，应先经过：
1. Room 1 pin
2. Room 3 规则语义冻结
3. Room 5 state / copy 风险检查
4. Room 2 再决定是否会触发 API / DB Major

---

## 7. Q5 — `preview_durations_contract_decision`

## 7.1 Room 2 结论
> **`previewDurations` 在 P3.3.3 继续 deferred。**

## 7.2 为什么继续 deferred
因为当前它依然缺 3 个前提：

1. **稳定 source 没有 pin 完**
   - 本地 FSRS 可算
   - 但页面能否展示成稳定事实，仍受 cloud-first serving truth 边界约束

2. **解释层风险仍高**
   - 一旦展示时长 / 下次复习间隔，用户会把它理解成“系统已经确定的安排”
   - 这会直接碰到 UI fact-copy 禁区

3. **它会牵动 Study / Review 两页的一致性问题**
   - 是只在 Study 显示
   - 还是 Study + Review 都显示
   - 是按 local candidate 显示还是按 cloud-confirmed 显示
   - 这些都还没到可稳定 pin 的程度

## 7.3 Room 2 的正式推荐
本轮对 `previewDurations` 只冻结一句：

> **继续 deferred；直到 `schedule_source_contract_v1` 与页面解释边界都被单独 pin 后，才允许 re-entry。**

## 7.4 本轮不应出现的误写
1. 不得写成 active UI 事实
2. 不得写成 active API contract
3. 不得写成 active ReviewPage explanation
4. 不得写成“本地 FSRS 已稳定提供下次复习时间”

---

## 8. Room 2 对是否进入下一层合同的最终判断

## 8.1 支持进入的部分
Room 2 支持 Room 1 在本轮考虑 pin 以下 **very narrow contract subset**：
1. `review_readiness_policy_v1`
2. `review_priority_policy_v1`（hierarchy only）
3. `review_group_generation_policy_v1`（entry boundary only）
4. `schedule_source_contract_v1`（truth split + conceptual interface only）

## 8.2 不支持进入的部分
Room 2 当前不支持在本轮 pin：
1. `previewDurations` re-entry
2. exact group size contract
3. full generation / regeneration algorithm
4. full priority scoring engine
5. unified planner / planner merge
6. auto-routing runtime behavior
7. stronger ReviewPage bridge contract

## 8.3 Room 2 一句话判断
> **P3.3.3 可以从“只有 owner split”前进一步，进入“review planning minimal contract v1”；但它仍然不能越过 narrow contract 层，不能直接变成完整 planner product。**

---

## 9. 对 Room 4 的预判边界（仅供 Room 1 后续判断，不是执行单）

若 Room 1 最终选择进入一层 very narrow execution，下游最安全的范围也应只限于：
1. decision-support / summary contract 的 very thin addition
2. 不改变 DB schema 的实现补强
3. 不改变 API core semantics 的可选字段 / 聚合字段候选
4. dev/test 可观察性补强
5. 不触碰 unified planner / auto-routing / preview explanation

任何以下动作，Room 2 默认视为 **Major / 需再审**：
1. 把 local FSRS due 直接改成页面级主 truth
2. 改 ReviewPage 主 serving flow
3. 引入 exact group-size promise
4. 引入 planner merge / unified planner
5. 把 `previewDurations` 拉进稳定 UI / API 合同

---

## 10. Room 2 最终交付摘要

### 本轮结论
1. `review_readiness_policy_v1`：**可冻**，但 truth source = cloud serving layer
2. `review_priority_policy_v1`：**可冻 hierarchy**，不冻 full algorithm
3. `review_group_generation_policy_v1`：**可冻 entry boundary**，不冻 exact group size
4. `schedule_source_contract_v1`：**可冻 truth split + conceptual interface**，不冻新 schema / 新 active payload
5. `previewDurations`：**继续 deferred**

### Room 2 正式推荐
> **支持 Room 1 进入 very narrow `Review Planning Contract v1`；不支持把 P3.3.3 直接升级成完整 SRS / 完整复习规划 / 完整 planner 产品。**
