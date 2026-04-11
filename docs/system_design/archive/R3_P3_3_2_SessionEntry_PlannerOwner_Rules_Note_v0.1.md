# R3_P3_3_2_SessionEntry_PlannerOwner_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / session entry + planner owner split
- **Status:** ready for Room 1 review
- **Date:** 2026-04-10
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis:** `Main_updated_2026-04-10_v20.md` + `STATUS_updated_2026-04-10_v19.md`
- **Direct upstream input:** `R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 3 的业务规则视角，把 P3.3.2 当前轮需要先收口的两个最小合同——`session_entry_policy_v1` 与 `planner_owner_split_v1`——写成明确、可测试、可引用的规则边界。**

本稿不是：
- 新 BR 主文档
- 新 DB / API 主文档
- 新 UI SPEC 主文档
- 完整 SRS / 完整 review planning 规则正文
- Room 4 执行单

一句话：

> **P3.3.2 不是立刻做完整复习系统，而是先决定：首页“背单词”入口在业务上是什么意思、以及 cloud `review_group` 与 local FSRS 在业务上如何分工。**

---

## 1. 输入依据

### 1.1 当前治理层 / 推进层依据
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `Main_updated_2026-04-10_v20.md`
- `STATUS_updated_2026-04-10_v19.md`

### 1.2 当前 active runtime basis
- `BR-OPP-001_v0.2.3.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `UI_SPEC_v0.2.3.md`

### 1.3 本轮 handoff / framing 输入
- `R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1.md`
- `R2_P3_3_2_SessionEntry_PlannerOwner_Tech_Note_v0.1.md`

---

## 2. Room 3 总判断

### 2.1 本轮要回答什么
Room 1 这轮要求 Room 3 回答的，不是完整 review planning，而是 3 个主线程问题：

1. 首页点“背单词”后，当前轮的 **session entry** 到底冻结到哪一层  
2. 在 current dual-store 现实下，谁是 **planner owner**  
3. 当前轮是否从 preflight 进入 **next-layer minimal contract**，若进入，最小合同是什么

### 2.2 Room 3 一句话结论
> **Room 3 同意进入 `next-layer minimal contract`，但只进入一层很窄的规则合同：冻结 `home_word_entry = study_default` 的业务语义，以及 `cloud review_group / local FSRS` 的 owner split 业务边界；mixed / auto-routing / unified planner 继续 pending。**

### 2.3 为什么 Room 3 同意前进一步
如果继续完全停在 pure preflight，不写任何规则合同，后续会出现 3 个明显风险：

1. Room 4 会被迫自行理解“背单词入口是不是未来自动分流入口”
2. Room 5 会被迫自行理解 active `review_group` continuation 到底该不该吞掉 `/study` 入口
3. Room 2 / Room 4 / Room 5 会对 local FSRS 与 cloud `review_group` 的 owner 关系产生平行理解

这已经不是“未来讨论再说”的轻问题，而是会影响后续 BR / UI / TEST / execution framing 的真实规则空洞。

### 2.4 为什么 Room 3 也不同意走更深合同
因为再往下就会越过当前 round 明确的 out-of-scope：

- 完整 SRS / 完整复习调度算法
- 首页自动分流 runtime contract
- planner merge
- `review_group` 最小合同改写
- `previewDurations` 重新打开
- unified Study / Review page

所以，P3.3.2 当前只能前进到 **窄合同层**，不能前进到“完整 review planning 产品层”。

---

## 3. `session_entry_policy_v1`（Room 3 规则版）

## 3.1 RF-P3.3.2-001 — `home_word_entry = study_default`
- **Status:** Frozen for this round
- **Rule:** 首页“背单词”入口，当前轮在业务语义上继续冻结为：
  - **默认进入新词学习路径（Study default entry）**
  - 而不是 review planner dispatcher
  - 也不是 mixed / auto-routing dispatcher
- **Applies to:** BR / UI / TEST / implementation framing
- **Checkable:**
  1. 首页点击“背单词”后的默认路径继续承接到 `StudyPage`
  2. 不得把当前入口文案、helper、UI 结构解释成“系统已自动帮你决定走复习 / 混合”
  3. Room 4 不得把现有默认入口私自升级成自动分流逻辑
- **Why frozen:** 当前代码与文档现实都指向 `home_word_entry = study_default`；若本轮不写硬，后续会产生 silent reroute 漂移

## 3.2 RF-P3.3.2-002 — active `review_group` continuation 高优先，但当前不等于 silent reroute
- **Status:** Frozen for this round
- **Rule:** active `review_group` continuation 继续保持高优先级，但当前它只代表：
  - review continuation 在业务上优先被承接
  - 不代表首页“背单词”入口已自动变成 review dispatcher
- **Applies to:** BR / UI / TEST / implementation framing
- **Checkable:**
  1. 若要体现 active `review_group` continuation 优先，应通过独立 CTA / helper / priority block 承接
  2. 当前不得把 continuation 优先解释成“默认点击背单词就自动改路由”
  3. 若未来要进入 silent reroute / auto-routing，必须单开新 round pin
- **Must not do:**
  1. 不得用当前 P3.3.2 note 反向宣告 auto-routing 已成立
  2. 不得把 active `review_group` 的存在单独等价为“必须吞掉 `/study` 入口”
- **Why frozen:** 这是 Room 2 tech note 与 Room 1 scope pin 的共同边界；Room 3 只负责把它写成业务语义层规则

## 3.3 RF-P3.3.2-003 — mixed / auto-routing / unified planner 继续 Pending
- **Status:** Frozen as pending-boundary
- **Rule:** 以下内容当前继续保持 `Pending Decision`，不得被 Room 4 / Room 5 / 实现层脑补为已冻结事实：
  1. 首页点击“背单词”后的 mixed routing
  2. 自动分流到新词 / 复习 / 混合 session
  3. unified planner / planner merge
  4. 统一学习页 contract
- **Applies to:** BR / UI / TEST / implementation framing
- **Checkable:**
  1. 文档 / UI / 实现不得把这些候选方案写成当前事实
  2. 测试不得把这些未冻结方案当成当前通过标准
- **Why frozen:** 本轮是 contract gate，不是产品扩写轮

---

## 4. `planner_owner_split_v1`（Room 3 规则版）

## 4.1 RF-P3.3.2-004 — Cloud `review_group` 是 ReviewPage 的 serving truth owner
- **Status:** Frozen for this round
- **Rule:** 在 ReviewPage 复习路径上，cloud `review_group` 当前继续承担以下业务真相层职责：
  1. review queue serving
  2. active group continuation
  3. group completion 判定
  4. review path 下的 settlement 主链路
  5. ReviewPage 主队列真相层
- **Applies to:** BR / DB / API / UI / TEST / 实现
- **Checkable:**
  1. ReviewPage 不得由本地 due cards 直接接管主队列
  2. group completion 不得由本地 scheduling 层单独判定
  3. settlement gating 不得被本地 FSRS 接管
- **Why frozen:** 当前 `review_group` 最小合同与 P3.3 / P3.3.1 的 cloud-first 口径已稳定；本轮不重写它，只把其 owner 角色写硬

## 4.2 RF-P3.3.2-005 — Local FSRS 是 device-side scheduling owner
- **Status:** Frozen for this round
- **Rule:** local FSRS 当前继续承担以下设备侧调度职责：
  1. local card state
  2. rating → interval / stability / difficulty 的设备侧计算
  3. review logs
  4. local `init / ensure-local-card-state`
  5. future preview / local planning 的候选能力来源
- **Applies to:** BR / DB / API / UI / TEST / 实现
- **Checkable:**
  1. 本地 FSRS 可以增强 local scheduling 能力
  2. 但本轮不得被写成 ReviewPage 主队列 owner
  3. 不得被写成 group continuation / completion / settlement owner
- **Why frozen:** 当前代码现实已经有 local FSRS 独立存在；不把这层 owner 写硬，会继续出现“本地是不是已接近 planner owner”的理解漂移

## 4.3 RF-P3.3.2-006 — ReviewPage 继续 `cloud-first + local side-effect`
- **Status:** Frozen for this round
- **Rule:** ReviewPage 当前继续保持：
  - **cloud-first**
  - **local side-effect**
  的 owner split 语义
- **Canonical meaning:**
  1. 复习页主写入 / 主真相 / 主队列承接先服从 cloud `review_group`
  2. local FSRS 继续存在，但在 ReviewPage 路径上仍是 scheduling reality + side-effect layer
- **Checkable:**
  1. 本地 bridge / ensure 可以补强，但不得反向提升 planner owner
  2. UI 不得把本地 scheduling 副作用写成“云端已更新你的复习计划”
  3. TEST 不得把 local success 当成 cloud serving truth 成立
- **Why frozen:** 这是 P3.3.1 bridge controlled best-effort 进一步向 P3.3.2 窄合同层延伸的最小稳定表达

## 4.4 RF-P3.3.2-007 — planner owner split 不等于 planner merge
- **Status:** Frozen for this round
- **Rule:** 当前承认 owner split，不等于承认 planner merge。  
  也就是说：
  - cloud `review_group` 与 local FSRS 可分层共存
  - 但本轮不宣告它们已统一成一个 planner contract
- **Applies to:** BR / DB / API / UI / TEST / 实现
- **Checkable:**
  1. 不得把 owner split 写成 unified planner
  2. 不得把 local FSRS side-effect 成功写成“完整复习规划已更新”
  3. 不得把 current split 解释为未来 merge 已默认成立
- **Why frozen:** 这是本轮最容易被误写的地方，必须单独写硬

---

## 5. 文案与状态表达的事实边界（Room 3 给 Room 5 / Room 4 的挡板）

## 5.1 当前允许的表达
当前轮允许表达的，是：

- “背单词”默认进入学习页
- 当前仍可通过独立 review path / helper / CTA 承接复习 continuation
- cloud `review_group` 继续主导复习路径的 serving truth
- local FSRS 继续承担本地调度 / 记录 / bridge side-effect

## 5.2 当前禁止的表达
以下表达在 P3.3.2 当前轮仍然禁止：

1. **系统已自动帮你决定今天先学什么**
2. **已为你切换到最佳复习模式**
3. **已更新你的完整复习计划**
4. **本地学习模型已正式接管复习规划**
5. **云端与本地已统一为同一 planner**
6. **下次将在 X 天后复习**（当前轮）
7. **previewDurations 已重新进入 contract**
8. **背单词入口已经是自动分流入口**

### 原因
这些表达会越过当前轮的最小合同层，直接把 pending 的 deeper contract 写成已成立事实。

---

## 6. Pending 区（必须继续保持 Pending）

## 6.1 P3.3.2 当前继续 Pending 的内容
1. 完整 SRS / 完整复习调度算法
2. 完整 session 自动分流
3. planner merge / unified planner
4. `previewDurations` / interval preview
5. stronger ReviewPage bridge contract
6. unified Study / Review page
7. 首页 CTA winner 的完整状态驱动重写
8. 更深一层 readiness / due explanation / schedule explanation

## 6.2 Room 3 一句话原则
> **本轮只写“最小稳定语义”，不写“未来可能更聪明的系统”。**

---

## 7. 对 Room 4 的禁止补脑项（Room 3 版）

Room 4 在 Room 1 未完成 cross-room 吸收并给出 execution handoff 前，不得自行决定：

1. 把首页“背单词”入口改成 auto-routing dispatcher
2. 让 active `review_group` continuation 自动吞掉 `/study` 默认入口
3. 把 local FSRS 写成 ReviewPage 主队列 owner
4. 把 owner split 写成 planner merge
5. 把 current split 写成 unified planner
6. 把 `previewDurations` 重新拉回 UI / contract
7. 把本轮写成“完整 review planning 已完成”

---

## 8. Room 3 可直接给 Room 1 的决策句

### 8.1 Session entry decision sentence
> **Room 3 judgment：P3.3.2 当前建议冻结 `session_entry_policy_v1`：首页“背单词”入口继续保持 `study_default` 的业务语义；active `review_group` continuation 继续高优先，但当前只通过独立 review path / CTA / helper 承接，不等于 silent reroute，不等于 mixed / auto-routing contract。**

### 8.2 Planner owner decision sentence
> **Room 3 judgment：P3.3.2 当前建议冻结 `planner_owner_split_v1`：ReviewPage 的 queue / continuation / completion / settlement truth owner 继续是 cloud `review_group`；local FSRS 继续承担 device-side scheduling / review logs / ensure / side-effect owner，不替代 cloud serving truth。**

### 8.3 Pending boundary decision sentence
> **Room 3 judgment：P3.3.2 当前只进入“窄合同层”，不进入完整 review planning contract；mixed / auto-routing / unified planner / `previewDurations` / stronger bridge / unified Study-Review page 继续保持 pending。**

---

## 9. Room 3 最终一句话

> **P3.3.2 这轮，Room 3 同意从 pure preflight 前进一步，但只前进到 `session_entry_policy_v1 + planner_owner_split_v1` 的窄合同层：`home_word_entry` 继续是 `study_default`，active `review_group` continuation 高优先但不等于 silent reroute，ReviewPage 继续保持 `cloud-first + local side-effect`，而 mixed / auto-routing / unified planner / preview 解释全部继续 pending。**
