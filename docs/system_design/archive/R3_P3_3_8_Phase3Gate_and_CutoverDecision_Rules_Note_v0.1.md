# R3_P3_3_8_Phase3Gate_and_CutoverDecision_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / Phase 3 gate / cutover-decision round
- **Status:** ready for Room 1 review
- **Date:** 2026-04-11
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis:** `Main_updated_2026-04-10_v28.md` + `STATUS_updated_2026-04-10_v26.md`
- **Direct upstream input:** `R1_P3_3_8_ScopePin_and_Handoff_Pack_v0.1.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 3 的业务规则视角，把 P3.3.8 当前轮需要先回答的 Phase 3 gate / cutover-decision 问题，收成一份可测试、可引用、可被 Room 1 判断是否 pin 的最小规则合同。**

本稿不是：
- 新 BR 主文档
- 新 DB / API 主文档
- 新 UI 主文档
- Room 4 cutover 执行单
- runtime owner shift 完成宣告
- local-serving cutover 方案书
- unified planner / planner merge 最终版

一句话：

> **P3.3.8 是 Phase 3 gate / cutover-decision + DB/API candidate round，不是 cutover round。**

---

## 1. 输入依据

### 1.1 Governance / role basis
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_8_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.3 Current runtime / review basis
- `BR-OPP-001_v0.2.9.md`
- `UI_SPEC_v0.2.9.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `Main_updated_2026-04-10_v28.md`
- `STATUS_updated_2026-04-10_v26.md`

### 1.4 Prior-round evidence basis
- `P3.3.7_Claude_res.md`

---

## 2. Room 3 总判断

### 2.1 本轮是否应该前进一步
Room 3 结论：

> **应该前进一步。**

因为 P3.3.7 已经不只是 “shadow-prep”，而是已经形成：
1. current runtime truth regression evidence  
2. shadow parity evidence  
3. mismatch / stop-condition 分级  
4. local-serving / routing / fact-ingest 的真实 shadow run evidence  

如果 P3.3.8 还不回答 gate / decision / candidate / migration，这些证据就只会继续堆积，无法转成下一层主线程判断。

### 2.2 本轮不能直接写成什么
Room 3 同时明确：

> **P3.3.8 当前不能直接写成 `runtime owner shift completed`、`ReviewPage local-serving runtime cutover completed`、`review_group 已退出运行态`、`auto-routing 已开启`、`planner merge / unified planner 已成立`。**

当前 runtime truth 仍必须保持：
1. 首页继续 `home_word_entry = study_default`
2. active continuation 继续独立承接，不得 silent reroute
3. ReviewPage current serving truth 继续围绕 cloud `review_group`
4. `review_group` 当前仍是 current owner + compatibility anchor + deprecated candidate
5. final fact / settlement truth 继续以后端为准

### 2.3 Room 3 的一句话立场
> **Room 3 支持 P3.3.8 进入 Phase 3 gate / cutover-decision；但这轮只应把“什么证据足以进下一层、什么必须 hold / escalate、哪些还只能停在 candidate”写硬，不能把 gate 结论误写成 cutover 已成立。**

---

## 3. `phase3_gate_decision_v1`

## 3.1 Room 3 结论
> **P3.3.8 当前可以进入 Phase 3 gate 判断；但 gate 的本质是“是否具备下一层讨论资格”，不是“是否已经切换完成”。**

### RF-P3.3.8-001 — gate 只判断“是否可进入下一层候选”，不判断“当前已切完”
- **Status:** Frozen candidate for this round
- **Rule:** `phase3_gate_decision_v1` 当前只允许产生以下层级结论：
  1. proceed to next-layer candidate review
  2. hold
  3. revise
  4. escalate
- **Current forbidden layer:**
  1. runtime owner shift completed
  2. local-serving cutover completed
  3. `review_group` 已正式退场
  4. unified planner 已成立
- **Why frozen candidate:** gate 是“是否可继续”，不是“现在就生效”。

### RF-P3.3.8-002 — shadow evidence 必须满足“可解释 + 可回归 + 不越界”
- **Status:** Frozen candidate for this round
- **Rule:** 要让 shadow evidence 足以支撑进入下一层 gate，至少必须同时满足：
  1. current runtime truth 未被偷切
  2. shadow result 未漏到用户端
  3. `review_group` current owner posture 未被破坏
  4. final fact / settlement truth 未被 shadow 改写
  5. mismatch 分级稳定、可复现、可回归
  6. 证据可被明确解释，而不是“看起来差不多”
- **Canonical meaning:** 可进入 gate 的最低门槛，是 guardrails 全守住，再谈 candidate 是否可进一步深化。

### RF-P3.3.8-003 — “看起来更合理”本身不足以进入下一层
- **Status:** Frozen candidate for this round
- **Rule:** 即使 local-serving / routing / ingest shadow：
  - 看起来更合理
  - 与 baseline 大体一致
  - 能通过多数 compare  
  也不能仅凭这一点自动进入下一层 cutover 准备。
- **Why frozen candidate:** 本轮需要的是“足够稳、足够可解释、足够不越界”的证据，而不是“主观上更像未来方向”。

---

## 4. `limited_cutover_scope_candidate_v1`

## 4.1 Room 3 结论
> **若 P3.3.8 允许推进下一层，Room 3 只接受 very narrow candidate scope，不接受一口气进入 full serving cutover。**

### RF-P3.3.8-004 — 最小可行切口只能是 candidate / migration subset
- **Status:** Frozen candidate for this round
- **Rule:** 若 Room 1 允许进入下一层，最小切口只能从以下集合中选 very narrow subset：
  1. `review_group` exit 条件判断准备
  2. fact ingest stronger-path candidate
  3. helper / summary / state contract migration prep
  4. DB / API seam candidate formalization
  5. rollback / hold / migration note baseline
- **Current forbidden layer:**
  1. ReviewPage local-serving runtime cutover
  2. auto-routing runtime
  3. unified planner / planner merge
  4. final fact owner shift
- **Why frozen candidate:** P3.3.8 当前还是 gate / candidate / migration round，不是 execution round。

### RF-P3.3.8-005 — serving source 不得先于 fact boundary 被偷切
- **Status:** Frozen candidate for this round
- **Rule:** 即使未来 serving source 要变化，也不得先于 fact-settlement boundary 被明确写硬。
- **Canonical meaning:**  
  先切 serving source，但 fact / settlement / daily_goal / streak 的最终事实边界还不清楚，属于高风险越界。
- **Why frozen candidate:** planner / serving owner shift 不自动带出 fact owner shift，这条在 P3.3.6 / P3.3.7 后必须继续守住。

---

## 5. `review_group_exit_gate_v1`

## 5.1 Room 3 结论
> **`review_group` 当前还不能进入真实退场；P3.3.8 只能冻结“什么时候才有资格进入退场判断”。**

### RF-P3.3.8-006 — `review_group` 当前仍是 current runtime owner
- **Status:** Frozen candidate for this round
- **Rule:** 在 P3.3.8 当前轮，`review_group` 继续保持：
  1. current runtime serving owner
  2. compatibility anchor
  3. deprecated candidate
- **Must not do:** 不得把它写成“现在只是兼容层”或“已经退场完成”。

### RF-P3.3.8-007 — `review_group` 进入真实退场判断前，至少要先齐 4 类东西
- **Status:** Frozen candidate for this round
- **Rule:** 只有当以下 4 类前置条件都具备时，`review_group` 才有资格进入真实退场判断：
  1. **contract 条件**：local-serving candidate、fact ingest candidate、routing compat、write-back markers 已被完整 pin 成下一层 candidate 合同
  2. **test 条件**：shadow / parity 证据长期稳定，无 must-hold mismatch 未清
  3. **doc 条件**：BR / UI / DB / API / TEST 的 candidate write-back 次序与 migration note 已明确
  4. **boundary 条件**：final fact / settlement owner 仍清楚写在后端，不存在偷切
- **Canonical meaning:** `review_group` 退场不是“觉得差不多了”，而是“上下游条件已经齐”。

### RF-P3.3.8-008 — 真实退场判断 ≠ 当前轮立刻退场
- **Status:** Frozen candidate for this round
- **Rule:** 即使上述前置条件逐步接近，也只代表“可讨论 exit gate”，不代表本轮直接退场。
- **Why frozen candidate:** 这是 gate / cutover-decision round，不是 runtime cutover round。

---

## 6. `fact_settlement_cutover_boundary_v1`

## 6.1 Room 3 结论
> **P3.3.8 当前最该写硬的，不是“local 能做更多什么”，而是“哪些最终事实仍必须以后端为准”。**

### RF-P3.3.8-009 — 以下最终事实当前仍必须以后端为准
- **Status:** Frozen candidate for this round
- **Rule:** 即使进入 Phase 3 gate，这些事实当前仍必须继续以后端 / cloud fact layer 为准：
  1. 有效复习事实
  2. 今日目标完成
  3. 奖励结算 / 账本到账
  4. `check_in / learning_day / streak`
- **Must not do:** 不得把 local-serving evidence、parity result 或 ingest candidate 写成这些最终事实已可由本地裁定。

### RF-P3.3.8-010 — local evidence 当前最多只允许进入更强的 active ingest path 候选，不允许越权成 fact owner
- **Status:** Frozen candidate for this round
- **Rule:** 本轮若要推进，local evidence 最多只允许讨论：
  1. 更强的 active ingest path candidate
  2. accept / reject / duplicate 规则是否足够稳
  3. 进入候选 write-back / migration 的条件
- **Current forbidden layer:**
  1. 直接改 ledger
  2. 直接改 daily goal 完成态
  3. 直接改 streak / learning_day 最终事实
  4. 直接替代 cloud settlement owner
- **Why frozen candidate:** candidate stronger-path ≠ fact owner shift。

### RF-P3.3.8-011 — owner shift 的 overclaim 禁区
- **Status:** Frozen candidate for this round
- **Rule:** 以下表达当前轮继续属于 overclaim：
  - 本地已接管复习事实
  - 本地已接管今日完成判定
  - 本地结果已写回最终事实
  - 奖励已按本地规划正式结算
  - streak / learning day 已由本地主导
- **Why frozen candidate:** 这些表达会把 candidate ingest / evidence path 误写成 fact owner shift。

---

## 7. `phase3_writeback_and_migration_v1`

## 7.1 Room 3 结论
> **P3.3.8 若要继续推进，必须先写硬 write-back 顺序与 migration note 结构，否则又会出现 silent contract drift。**

### RF-P3.3.8-012 — write-back 顺序必须先规则护栏，再技术候选
- **Status:** Frozen candidate for this round
- **Rule:** Room 3 当前推荐的最小 write-back 顺序为：
  1. **Room 2 tech candidate note**
  2. **Room 3 rules note**
  3. **Room 5 UI preflight**
  4. **Room 1 absorb / pin**
  5. 如获准，再进入 Room 4 execution handoff
- **Why frozen candidate:** 先把 guardrails 写硬，再让技术候选进入下一层，能最大程度避免 overclaim。

### RF-P3.3.8-013 — migration note / rollback note / hold note 的最小要求
- **Status:** Frozen candidate for this round
- **Rule:** P3.3.8 若进入下一层 candidate round，至少必须补齐：
  1. **migration note**：before / after / staged condition / synced docs
  2. **rollback note**：什么情况必须回退到 current runtime truth
  3. **hold note**：哪些 mismatch / boundary 触发 hold
- **Current forbidden layer:** 不得只写“建议继续推进”，不写何时停、何时回退。

### RF-P3.3.8-014 — deprecated / compatibility / runtime truth 三层切换条件必须继续显式分开
- **Status:** Frozen candidate for this round
- **Rule:** 本轮 write-back 里，仍必须继续显式区分：
  1. `runtime truth`
  2. `compatibility-only`
  3. `deprecated candidate`
- **Must not do:** 不得把 deprecated candidate 写成已消失，也不得把 compatibility-only 写成 current owner。

---

## 8. `must_hold` / `must_escalate` 列表

## 8.1 `must_hold`
以下任一出现，Room 3 判断必须 hold：
1. shadow / candidate 结果进入用户可见层
2. current runtime truth 被偷切
3. `review_group` 被误写成已退场
4. local evidence 改动 final fact / settlement truth
5. `study_default` 被改成 runtime auto-routing
6. preview / explanation 被写成 committed plan fact
7. helper / summary / CTA 出现“已切到本地规划 / 本地已接管复习”之类宣告

## 8.2 `must_escalate`
以下任一出现，Room 3 判断必须 escalate 给 Room 1 / Room 2：
1. 需要改 DB schema
2. 需要改 API core semantics
3. 需要改 reward / settlement owner
4. 需要把 `review_group` 从 current runtime owner 改成 compatibility-only
5. 需要把 auto-routing / planner merge / unified planner 拉进当前轮
6. 需要把 local ingest candidate 升格成 active fact owner path
7. 需要用户可见 cutover 宣告或模式切换说明

---

## 9. fact-copy / helper / state guardrails

### 9.1 当前允许的表达方向
当前内部 /治理层允许的表达方向：
- shadow
- candidate
- compatibility-only
- deprecated candidate
- parity evidence
- not current runtime truth
- gate only
- cutover-decision pending

### 9.2 当前禁止的 overclaim
以下表达当前轮继续禁止：
1. 已切换到本地规划
2. 本地已接管复习
3. `review_group` 已退场
4. 已自动安排学习路径
5. 已进入新的复习模式
6. 本地结果已写回最终事实
7. cutover 已完成
8. 现在已按本地主规划运行

### 9.3 helper / state / summary 禁区
以下位置当前都不得出现 overclaim：
- 首页 helper
- ReviewPage summary
- empty-state
- completion 文案
- toast
- settings / backup 成功提示
- 任何 migration banner

---

## 10. 当前继续保持 Pending

1. runtime owner shift completed
2. ReviewPage local-serving runtime cutover
3. local due queue 接管 current ReviewPage truth
4. `review_group` 退出运行态
5. auto-routing runtime
6. planner merge / unified planner
7. DB schema rewrite
8. API core semantics rewrite
9. reward / settlement / daily_goal / streak 最终事实 owner shift
10. 用户可见 owner-shift 宣告

---

## 11. 可直接给 Room 1 的判定句

### 11.1 gate 规则句
> **Room 3 judgment：P3.3.8 当前可以进入 Phase 3 gate / cutover-decision 判断，但 gate 只判断“是否具备进入下一层 candidate / migration review 的资格”，不判断“当前已完成 cutover”。**

### 11.2 must-hold / must-escalate 句
> **Room 3 judgment：凡触碰 current runtime truth、`review_group` current owner posture、final fact / settlement owner、或用户可见 overclaim 的情况，一律不得按“可带着走的 candidate 差异”处理；其中碰到 DB / API core semantics、reward / settlement owner、planner merge / auto-routing、或用户可见 cutover 宣告的，必须升级，不得在本轮内自行吸收。**

### 11.3 fact-copy guardrails 句
> **Room 3 judgment：P3.3.8 当前所有文案 / helper / state 仍必须继续明确 `shadow / candidate / compatibility-only / deprecated candidate / not current runtime truth` 与 runtime fact 的边界；任何“已切到本地规划 / review_group 已退场 / 本地已接管复习 / 已自动安排学习路径”的表达都属于 overclaim。**

### 11.4 `review_group_exit_gate_v1` 句
> **Room 3 judgment：`review_group` 当前仍不得进入真实退场；只有在 contract、test、doc、boundary 四类前置条件都先齐之后，它才有资格进入 exit gate 判断。**

### 11.5 `fact_settlement_cutover_boundary_v1` 句
> **Room 3 judgment：即使进入 Phase 3 gate，有效复习、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端为准；local evidence 最多只允许讨论更强的 ingest path candidate，不允许越权成 fact owner。**

---

## 12. Room 3 最终一句话

> **P3.3.8 这轮，Room 3 支持把 P3.3.7 的 shadow evidence 转成 Phase 3 gate / cutover-decision 的规则判断；但这轮仍然只是在回答“能不能进下一层候选与迁移审查”，不是在回答“今天就已经切过去了”。**
