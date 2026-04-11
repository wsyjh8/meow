# R3_P3_3_3_ReviewPlanningContractV1_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / review planning contract v1 / SRS boundary round
- **Status:** ready for Room 1 review
- **Date:** 2026-04-10
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis for this round:** `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md` 指定的 review basis
- **Direct upstream input:** `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 3 的业务规则视角，把 P3.3.3 当前轮需要进一步收口的 5 个 review-planning 问题，写成可测试、可引用、可被 Room 1 判断是否 pin 的最小规则合同。**

本稿不是：
- 新 BR 主文档
- 新 DB / API / UI 主文档
- 完整 SRS / 完整复习调度产品规则正文
- Room 4 执行单
- 自动分流 / unified planner 最终方案

一句话：

> **P3.3.3 继续前进，但只前进到 `review_readiness / review_priority / review_group_generation / schedule_source / previewDurations decision` 的窄合同层。**

---

## 1. 输入依据

### 1.1 Governance / Role basis
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.3 Current review basis for this round
- `BR-OPP-001_v0.2.4.md`
- `UI_SPEC_v0.2.4.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `Main_updated_2026-04-10_v21.md`
- `STATUS_updated_2026-04-10_v20.md`
- `R2_P3_3_3_ReviewPlanningContractV1_Tech_Note_v0.1.md`

---

## 2. Room 3 总判断

### 2.1 本轮是否应该前进一步
Room 3 结论：

> **应该前进一步。**

原因不是为了“做更多”，而是因为 P3.3.2 之后，项目已经明确冻结：
- `session_entry_policy_v1`
- `planner_owner_split_v1`

如果现在不继续补齐下一层 review planning contract，后续各层会继续出现以下业务语义空洞：

1. “什么时候算该复习”没有唯一可引用定义
2. continuation / due / new words / session 的层级会被不同层各自理解
3. `review_group` 的 generation / next-group 边界仍会被 UI / execution 脑补
4. local FSRS 与 cloud `review_group` 的 planning 交界面仍会继续模糊
5. `previewDurations` 会不断以“先放一点解释”形式被悄悄拉回页面

### 2.2 本轮不能走多深
Room 3 同时明确：

> **P3.3.3 当前仍然只是 contract gate，不是完整 review planning 产品轮。**

所以本轮不能越界到：
- 完整 SRS
- 完整 priority scoring
- auto-routing runtime 行为
- planner merge / unified planner
- unified Study / Review page
- stronger ReviewPage bridge contract
- preview explanation 正式回归 UI

### 2.3 Room 3 的一句话立场
> **Room 3 支持 Room 1 在本轮 pin 一套 `Review Planning Contract v1` 的 very narrow minimal contract；但这套合同必须继续坚持 cloud serving truth 优先、继续把 local FSRS 放在 scheduling candidate / device-side owner 层，并把所有更深算法与 UI 解释留在 pending。**

---

## 3. `review_readiness_policy_v1`

## 3.1 Room 3 结论
> **本轮应冻结 `review_readiness_policy_v1`，但页面级 readiness truth 继续以 cloud review-serving layer 为准，本地 FSRS 不直接上位为页面 readiness truth。**

## 3.2 为什么这样定
从当前已冻结的 `planner_owner_split_v1` 往下延伸：
- ReviewPage serving truth owner 仍是 cloud `review_group`
- local FSRS 仍是 device-side scheduling owner
- 若此时把 readiness 直接切到 local FSRS，会在业务层造成 owner 漂移

Room 3 不反对 local FSRS 作为：
- planning input
- scheduling signal source
- local explanation candidate source

但反对把它在本轮直接升格为：
- 页面级 readiness 最终事实
- 首页 review 可服务性的最终真相源

## 3.3 最小 readiness 语义（Room 3 版）
本轮建议冻结以下 4 个最小 readiness 业务语义：

### RF-P3.3.3-001 — `ready_now`
- **Status:** Frozen for this round
- **Rule:** 当前存在可被 review-serving layer 立即服务的复习工作单元。
- **Canonical meaning:** 用户现在可以开始一轮 review path。
- **Truth-source:** 以后端 aggregate / review-serving summary 为准。
- **Must not do:** 不得仅凭本地 due count / local scheduler 结果直接展示“现在就该复习”。

### RF-P3.3.3-002 — `not_ready_now`
- **Status:** Frozen for this round
- **Rule:** 当前 review-serving layer 无法立即提供可做的 review work。
- **Canonical meaning:** 当前不是“现在可直接开始 review”的可服务状态。
- **Must not imply:** 不等于“本地没有 due cards”，也不等于“以后都不需要复习”。

### RF-P3.3.3-003 — `next_group_eligible`
- **Status:** Frozen for this round
- **Rule:** 当前没有 active group，且已满足生成 / 发放下一组 review work 的最小前提。
- **Canonical meaning:** 具备“下一组可以进入”的资格，但不自动等于页面上已经有下一组可见。
- **Why frozen:** 它是 generation gating 的上游业务语义，后续 DB / API / UI / TEST 都会引用。

### RF-P3.3.3-004 — `temporarily_unservable`
- **Status:** Frozen for this round
- **Rule:** 当前并非永远不能复习，而是当前轮 review-serving layer 暂时无法稳定提供可服务结果。
- **Canonical meaning:** 当前不可立即服务，但这属于阶段性不可服务，不是永久否定。
- **Must not do:** 不得把这类状态写成“你今天没有复习资格”或“系统已判定你不需要复习”。

## 3.4 本轮不冻结的 readiness 内容
继续 Pending：
1. readiness 的完整 reason enum
2. 时间窗 / 阈值算法
3. local-only readiness mode
4. 首页 readiness explanation 的最终文案集

---

## 4. `review_priority_policy_v1`

## 4.1 Room 3 结论
> **本轮应冻结 priority 的层级顺序，但只冻结层级，不冻结完整打分算法。**

## 4.2 本轮建议冻结的优先级层级
Room 3 建议冻结为：

1. **active `review_group` continuation**
2. **due review**（仅限 cloud-confirmed / serving-confirmed）
3. **high-priority review**（仅限 cloud-confirmed）
4. **new words**
5. **session**

## 4.3 业务解释
### RF-P3.3.3-005 — continuation 最高优先
- **Status:** Frozen for this round
- **Rule:** 若存在 active `review_group` continuation，则它继续拥有最高优先级。
- **Must not do:** 不得把 continuation 高优先解释成 silent reroute 已成立。

### RF-P3.3.3-006 — due / high-priority 必须是 cloud-confirmed
- **Status:** Frozen for this round
- **Rule:** due review 与 high-priority review 只有在 cloud serving layer 已确认可服务时，才可进入页面级优先级层级。
- **Must not do:** 不得把 local overdue / local FSRS 候选结果直接升格为 priority winner。

### RF-P3.3.3-007 — new words 继续作为 fallback 主线
- **Status:** Frozen for this round
- **Rule:** 在没有 active continuation、没有 cloud-confirmed due / high-priority review 时，`study_default` 继续作为最稳 fallback 主线。

### RF-P3.3.3-008 — session 继续保守
- **Status:** Frozen for this round
- **Rule:** Session 当前继续放在优先级层级的低位，不自动升为最高优先。
- **Why frozen:** 当前项目还未进入完整 CTA winner / session deeper policy round。

## 4.4 本轮继续 Pending 的 priority 内容
1. 完整 priority scoring
2. due vs high-priority 的权重
3. local overdue bucket 如何参与排序
4. CTA winner 的完整状态驱动 contract

---

## 5. `review_group_generation_policy_v1`

## 5.1 Room 3 结论
> **本轮应冻结 generation 的“进入条件 + owner 归属 + completion 后的最小下一步边界”，但不冻结 exact group size，也不冻结完整分组算法。**

## 5.2 最小 generation 合同（Room 3 版）

### RF-P3.3.3-009 — generation owner 继续在 cloud review-serving layer
- **Status:** Frozen for this round
- **Rule:** review group 的 generation / issuance / regeneration，当前继续由 cloud review-serving layer 承担 owner。
- **Must not do:** 不得把本地 FSRS 直接写成 group producer。

### RF-P3.3.3-010 — active group completion 是下一组生成的前提之一
- **Status:** Frozen for this round
- **Rule:** 在当前 contract 下，active `review_group` 未完成前，不进入“下一组可服务”的业务路径。
- **Canonical meaning:** completion 是 next-group 进入条件的一部分。
- **Must not do:** 不得因本地 due cards 变化而跳过 active group completion gating。

### RF-P3.3.3-011 — `next_group_eligible` ≠ `next_group_generated`
- **Status:** Frozen for this round
- **Rule:** 下一组具备生成资格，不自动等于下一组已经生成、已经在 UI 可见、或已经下发到客户端。
- **Why frozen:** 避免 UI / implementation 把 eligibility 误写成 generated fact。

### RF-P3.3.3-012 — exact group size 继续 Pending
- **Status:** Frozen as pending-boundary
- **Rule:** exact group size 当前继续不进入硬合同。
- **Must not do:** 不得把当前实现里的临时 group size 写成长期规则事实。

## 5.3 本轮继续 Pending 的 generation 内容
1. exact group size
2. 完整分组算法
3. regeneration 详细时机
4. next-group issuance 的完整时间窗
5. local-first generation 候选

---

## 6. `schedule_source_contract_v1`

## 6.1 Room 3 结论
> **本轮应冻结 `schedule_source_contract_v1`：local FSRS 提供 scheduling candidate signals，cloud `review_group` 继续承担 serving truth；两边共存，但不等于 unified planner。**

## 6.2 最小交界面（业务语义层）

### RF-P3.3.3-013 — local FSRS 输出的是 scheduling candidate signals
- **Status:** Frozen for this round
- **Rule:** local FSRS 当前在业务层输出的是“设备侧 scheduling 候选信号”，而不是页面最终 serving truth。
- **可包含的最小候选语义：**
  1. 当前卡片 due / overdue 候选状态
  2. rating 后的本地 interval / stability / difficulty 结果
  3. local review log / card state
  4. future preview / explanation 的候选能力来源
- **Must not do:** 不得把这些候选结果直接写成“系统已经为你确认的复习安排”。

### RF-P3.3.3-014 — cloud `review_group` 消费的是 planning-facing summary，不消费完整本地 planner truth
- **Status:** Frozen for this round
- **Rule:** cloud review-serving layer 未来若与 local FSRS 对接，当前也只应建立最小 planning-facing 交界面，而不是直接消费完整本地 planner truth。
- **Canonical meaning:** 本轮只允许“最小交界面 contract”进入候选，不允许宣告 planner merge。

### RF-P3.3.3-015 — `serving truth` 与 `scheduling truth` 必须分层表达
- **Status:** Frozen for this round
- **Rule:** 当前业务层必须明确区分：
  - **serving truth**：页面现在能不能服务、当前给哪一组、当前 remaining / completion / settlement 以谁为准
  - **scheduling truth**：本地如何估算 due、如何记录 rating、如何形成未来调度候选
- **Must not do:** 不得把两类 truth 混写成一个“planner 已统一”的事实。

### RF-P3.3.3-016 — owner split 不等于 merge
- **Status:** Frozen for this round
- **Rule:** 当前承认 owner split，不等于承认 unified planner / planner merge。
- **Why frozen:** 这是 P3.3.3 当前最容易被错误升级的地方。

---

## 7. `preview_durations_contract_decision`

## 7.1 Room 3 结论
> **Room 3 当前不建议把 `previewDurations` 从 deferred 拉回 active contract。**

## 7.2 原因
如果本轮拉回，会立刻制造 3 个业务语义问题：

1. 用户会把它理解成“系统已稳定承诺的下次安排”
2. UI 会被诱导写出 schedule explanation / next interval fact copy
3. 实现层会继续脑补：
   - 数据究竟来自 local FSRS 还是 cloud aggregate
   - Study / Review 是否共用一套 preview source
   - bridge / owner split 是否已足够稳定到可展示

这些都超出 P3.3.3 当前范围。

## 7.3 Room 3 本轮正式判断
### RF-P3.3.3-017 — `previewDurations` 继续 deferred
- **Status:** Frozen for this round
- **Rule:** `previewDurations` 当前继续 deferred，不进入 active contract。
- **Applies to:** BR / UI / TEST / implementation framing
- **Checkable:**
  1. 当前不进入稳定可见 UI
  2. 不作为页面级事实文案来源
  3. 不作为本轮执行通过标准
- **Must not do:** 不得写成“下次将在 X 天后复习”“预计 X 天后再次出现”等稳定事实。

### RF-P3.3.3-018 — future re-entry 的最小前提
- **Status:** Frozen as pending-boundary
- **Rule:** 若未来要重新进入 contract，至少先回答：
  1. source of truth 是谁
  2. explanation layer 怎么表达
  3. 是 Study only 还是 Study + Review
  4. 是否允许受 bridge 状态影响
- **Why frozen:** 这不是本轮要实现，而是 future re-entry 的最低前提。

---

## 8. 文案事实边界（Room 3 给 Room 5 / Room 4 的挡板）

## 8.1 当前允许的表达
当前轮可以表达：
- 你有一组复习未完成
- 现在可继续复习
- 当前默认从背单词开始
- 复习继续以当前 review group 为主
- 本地 FSRS 继续参与本地调度

## 8.2 当前禁止的表达
以下表达在 P3.3.3 当前轮继续禁止：

1. 系统已自动为你决定今天先学什么
2. 已切换到最佳复习模式
3. 已根据 FSRS 自动重排你的学习路径
4. 已为你生成完整复习计划
5. 云端与本地已统一为同一 planner
6. 下次将在 X 天后复习
7. 预计 X 天后再次出现
8. 本地计划已接管复习路径
9. 自动分流已开启
10. 统一学习模式已启用

---

## 9. Room 4 禁止补脑项（Room 3 版）

Room 4 在 Room 1 未完成 cross-room 吸收并给出 execution handoff 前，不得自行决定：

1. 把 local FSRS 直接写成 readiness truth
2. 把 due local cards 直接写成页面 priority winner
3. 把 local planner 直接写成 group producer
4. 把 owner split 写成 unified planner
5. 把 `previewDurations` 拉回 UI
6. 把本轮写成“完整 review planning 已完成”

---

## 10. Room 3 可直接给 Room 1 的决策句

### 10.1 Readiness decision sentence
> **Room 3 judgment：P3.3.3 当前建议冻结 `review_readiness_policy_v1`，但页面级 readiness truth 继续以后端 review-serving layer 为准；local FSRS 只作为 scheduling candidate input，不直接升格为页面 readiness truth。**

### 10.2 Priority decision sentence
> **Room 3 judgment：P3.3.3 当前建议冻结 `review_priority_policy_v1` 的最小层级顺序：active continuation > cloud-confirmed due review > cloud-confirmed high-priority review > new words > session；只冻结层级，不冻结完整算法。**

### 10.3 Group generation decision sentence
> **Room 3 judgment：P3.3.3 当前建议冻结 `review_group_generation_policy_v1` 的最小合同：group generation / issuance owner 继续在 cloud review-serving layer；active group completion 是 next-group 进入前提之一；exact group size 继续 pending。**

### 10.4 Schedule source decision sentence
> **Room 3 judgment：P3.3.3 当前建议冻结 `schedule_source_contract_v1`：local FSRS 继续输出 scheduling candidate signals，cloud `review_group` 继续承担 serving truth；owner split 不等于 planner merge。**

### 10.5 Preview decision sentence
> **Room 3 judgment：`previewDurations` 在 P3.3.3 当前轮继续保持 deferred；在 source of truth、explanation layer 与 Study / Review scope 未统一前，不应重新进入 active contract。**

---

## 11. Room 3 最终一句话

> **P3.3.3 这轮，Room 3 支持把 review planning 从入口 / owner split 继续推进到 `Review Planning Contract v1` 的窄合同层：冻结 readiness / priority / generation / schedule-source 的最小业务语义，但继续把完整 SRS、planner merge、preview explanation 和 auto-routing 留在 pending。**
