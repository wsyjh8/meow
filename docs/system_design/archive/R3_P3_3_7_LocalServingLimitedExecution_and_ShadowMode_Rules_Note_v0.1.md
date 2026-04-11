# R3_P3_3_7_LocalServingLimitedExecution_and_ShadowMode_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / limited execution / shadow mode round
- **Status:** ready for Room 1 review
- **Date:** 2026-04-10
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis for this round:** `R1_P3_3_7_ScopePin_and_Handoff_Pack_v0.2.md` 指定的 review basis
- **Direct upstream inputs:**  
  - `R1_P3_3_7_ScopePin_and_Handoff_Pack_v0.2.md`  
  - `BR-OPP-001_v0.2.7.md`  
  - `UI_SPEC_v0.2.7.md`  
  - `P3.3.5_Claude_res.md`  
  - `P3.3.6_Claude_res.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 3 的业务规则视角，把 P3.3.7 当前轮需要先收口的 shadow-mode 问题，写成可测试、可引用、可被 Room 1 判断是否 pin 的最小规则合同。**

本稿不是：
- 新 BR 主文档
- 新 DB / API / UI 主文档
- Room 4 cutover 执行单
- runtime owner shift 完成宣告
- local-serving cutover 方案书
- unified planner / planner merge 最终版

一句话：

> **P3.3.7 是 Phase 2 / Limited Execution / Shadow Mode round，不是 cutover round。**

---

## 1. 输入依据

### 1.1 Governance / Role basis
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_7_ScopePin_and_Handoff_Pack_v0.2.md`

### 1.3 Current runtime / review basis
- `BR-OPP-001_v0.2.7.md`
- `UI_SPEC_v0.2.7.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `Main_updated_2026-04-10_v26.md`
- `STATUS_updated_2026-04-10_v24.md`

### 1.4 Prior-round closeout references
- `P3.3.5_Claude_res.md`
- `P3.3.6_Claude_res.md`
- `R3_P3_3_6_LocalServingCompatibility_and_ShadowModeEntry_Rules_Note_v0.1.md`

---

## 2. Room 3 总判断

### 2.1 本轮是否应该前进一步
Room 3 结论：

> **应该前进一步。**

原因不是因为要“直接切换”，而是因为 P3.3.6 已经把：
- local-serving candidate contract
- `review_group` compatibility posture
- fact / settlement ingest candidate
- routing compatibility
- deprecation / write-back
- shadow / parity test strategy

推进到了 **Compatibility Contract v1**。  
如果 P3.3.7 还不让这些东西在 shadow 层真实跑起来，主线程会继续停留在“规则都写了，但没有 shadow evidence”的状态。

### 2.2 本轮不能直接写成什么
Room 3 同时明确：

> **P3.3.7 当前不能直接写成 `runtime owner shift completed`、`ReviewPage local-serving runtime cutover completed`、`review_group 已退出运行态`、`auto-routing 已开启`。**

当前 runtime truth 仍必须保持：
1. 首页继续 `home_word_entry = study_default`
2. active continuation 继续独立承接，不得 silent reroute
3. ReviewPage current serving truth 继续围绕 cloud `review_group`
4. `review_group` 当前仍是 current owner + compatibility anchor + deprecated candidate
5. final fact / settlement truth 继续以后端为准

### 2.3 Room 3 的一句话立场
> **Room 3 支持 P3.3.7 进入 Phase 2 / Limited Execution / Shadow Mode；但这轮只应把 local-serving、fact ingest、routing 的 shadow run 与 parity 结果收成 evidence，不得把 shadow evidence 误写成 runtime fact。**

---

## 3. `shadow_evidence_rule_set_v1`

## 3.1 Room 3 结论
> **本轮所有 shadow run 结果，只能先进入 evidence 层，不得进入 current runtime truth。**

### RF-P3.3.7-001 — shadow result 只能是 evidence，不是 runtime fact
- **Status:** Frozen candidate for this round
- **Rule:** 以下结果当前只能写成 shadow evidence：
  1. `local_due_queue_candidate` 看起来更合理
  2. `local_generated_review_session_candidate` 可以跑通
  3. local fact ingest candidate 被云端 accept / reject / duplicate
  4. routing shadow candidate 给出不同判断
- **Must not do:** 不得把这些结果写成：
  - owner shift 已完成
  - local 已接管 ReviewPage
  - `review_group` 已退出运行态
  - auto-routing 已上线
  - 当前复习路径已由本地正式主导

### RF-P3.3.7-002 — shadow run 可以进入 limited execution，但只能在 dev / flag / QA evidence 层
- **Status:** Frozen candidate for this round
- **Rule:** 本轮允许以下 candidate 进入 limited execution：
  1. `local_due_queue_candidate`
  2. `local_generated_review_session_candidate`
  3. `fact_ingest_shadow_evidence`
  4. `routing_shadow_candidate`
- **Current allowed layer:**
  1. dev / test
  2. internal debug / log
  3. QA evidence
  4. patch draft / write-back evidence
- **Current forbidden layer:**
  1. user-visible runtime path
  2. current serving truth
  3. final fact / settlement truth
  4. current CTA / helper / summary truth

### RF-P3.3.7-003 — `review_group` 继续是 current runtime owner + shadow baseline
- **Status:** Frozen candidate for this round
- **Rule:** 在 P3.3.7 当前轮：
  1. `review_group` 继续是 ReviewPage current serving truth
  2. 同时也是 shadow compare 的 baseline
  3. local-serving 继续只是 shadow candidate
- **Must not do:** 不得把 shadow compare 的存在写成“`review_group` 已经退场”。

### RF-P3.3.7-004 — local fact ingest compare 只比较 evidence path，不比较 final truth owner
- **Status:** Frozen candidate for this round
- **Rule:** 本轮可比的是：
  1. accept / reject / duplicate evidence path
  2. attempt / progress / completion candidate evidence
  3. parity completeness
- **Current forbidden layer:**
  1. local 直接改账本
  2. local 直接改今日目标完成
  3. local 直接改 streak / learning_day 最终事实
- **Why frozen candidate:** planner / serving owner shift 不自动带出 fact owner shift。

---

## 4. `shadow_result_visibility_v1`

## 4.1 Room 3 结论
> **shadow 结果当前只允许对 dev/test/internal 可见，不允许对用户形成任何可依赖事实。**

### RF-P3.3.7-005 — 允许可见的层级
- **Status:** Frozen candidate for this round
- **Rule:** 当前 shadow 结果允许被以下对象看见：
  1. dev / test
  2. internal debug panel / log
  3. QA evidence 包
  4. patch draft / closeout 摘要
  5. Room 1 / Room 2 / Room 3 / Room 5 的治理层文档
- **Why frozen candidate:** Room 1 handoff 已明确把 visible scope 限在 evidence 层。

### RF-P3.3.7-006 — 禁止可见给用户的内容
- **Status:** Frozen candidate for this round
- **Rule:** 以下 shadow 结果绝不能给用户看见：
  1. local queue compare 结果
  2. parity mismatch 结果
  3. accept / reject / duplicate shadow 证据
  4. shadow routing 判断
  5. “本地更合理 / 本地更优 / 本地已准备接管”的内部判断
- **Must not do:** 不得把 internal-only marker、debug badge、parity label、shadow status 暴露到用户端。

---

## 5. `mismatch_severity_rule_set_v1`

## 5.1 Room 3 结论
> **P3.3.7 必须把 mismatch 分级写硬，否则 shadow 跑起来以后无法判断“只是 warning”还是“必须 hold”。**

### RF-P3.3.7-007 — `info_only_mismatch`
- **Status:** Frozen candidate for this round
- **Definition:** 只影响 shadow 解释细节，不影响 current runtime truth、fact ingest 语义或 continuation / completion 判断。
- **Examples:**
  1. candidate_reason 文案不同
  2. generated_at 粒度不同
  3. shadow queue metadata 轻微差异
- **Action:** 记录即可，不阻塞 Phase 2。

### RF-P3.3.7-008 — `warning_mismatch`
- **Status:** Frozen candidate for this round
- **Definition:** 影响 parity 美观度或候选一致性，但仍未越过 runtime truth / final fact 边界。
- **Examples:**
  1. queue candidate size 不一致，但不影响 serving eligibility
  2. item identity overlap 轻度偏移，但 continuation / completion 逻辑未变
  3. routing shadow 倾向不同，但未进入用户路径
- **Action:** 允许继续 limited execution，但必须持续记录。

### RF-P3.3.7-009 — `must_hold_mismatch`
- **Status:** Frozen candidate for this round
- **Definition:** 一旦出现，就说明当前 shadow 已越过 compatibility / evidence 边界，必须 hold。
- **Examples:**
  1. shadow 结果被用户看见
  2. local candidate 影响 current ReviewPage serving truth
  3. local fact ingest evidence 影响账本 / daily_goal / streak 最终事实
  4. active continuation / completion gating 被 shadow 改写
  5. `study_default` 被 shadow routing 改成 runtime auto-routing
- **Action:** 立即 hold，本轮不得继续扩写。

### RF-P3.3.7-010 — `must_escalate_mismatch`
- **Status:** Frozen candidate for this round
- **Definition:** 一旦出现，说明已触碰下一阶段或跨模块核心契约，必须升级给 Room 1 / Room 2。
- **Examples:**
  1. 需要改 DB schema
  2. 需要改 API core semantics
  3. 需要改 reward / settlement owner
  4. 需要把 `review_group` 从 current runtime owner 改成 compatibility-only
  5. 需要把 auto-routing / planner merge / unified planner 拉进当前轮
- **Action:** escalate，不得在本轮内自行吸收。

---

## 6. `shadow_acceptance_gate_v1`

## 6.1 Room 3 结论
> **本轮 acceptance gate 不是“影子逻辑能不能跑”，而是“影子逻辑跑起来后，是否仍守住 current runtime truth 与 fact-copy guardrails”。**

### RF-P3.3.7-011 — parity pass 的最低要求
- **Status:** Frozen candidate for this round
- **Rule:** 本轮若要判定 shadow trial 可继续，至少要满足：
  1. current runtime truth 未被偷切
  2. shadow 结果未漏到用户端
  3. `review_group` current owner posture 未被破坏
  4. final fact / settlement truth 未被 shadow 改写
  5. parity compare / evidence path 可被稳定记录
- **Canonical meaning:** pass 先看 guardrails，再看“像不像”。

### RF-P3.3.7-012 — acceptable mismatch 的最低边界
- **Status:** Frozen candidate for this round
- **Rule:** 以下 mismatch 当前可接受：
  1. 只停留在 evidence 层
  2. 不改变 current runtime truth
  3. 不触碰 final fact owner
  4. 不让用户感知
  5. 可解释、可记录、可回归
- **Why frozen candidate:** 本轮不是 cutover，允许 candidate 与 baseline 暂时不完全一致。

### RF-P3.3.7-013 — stop conditions
- **Status:** Frozen candidate for this round
- **Rule:** 出现以下任一情况，本轮不得继续：
  1. shadow 结果进入用户可见层
  2. current runtime truth 被偷切
  3. `review_group` 被误写成已退场
  4. local ingest evidence 改动 final fact / settlement
  5. routing shadow 进入 runtime
  6. 需要改 DB / API core semantics
- **Action:** hold / escalate，而不是继续写 patch。

---

## 7. `fact_copy_guardrails_v1`

## 7.1 Room 3 一句话判断
> **只要一句话会让人以为“系统已经正式切过去了”，它在本轮就是禁区。**

### RF-P3.3.7-014 — 当前允许的 internal wording
- **Status:** Frozen candidate for this round
- **Allowed wording direction:**
  1. `shadow`
  2. `candidate`
  3. `internal-only`
  4. `parity evidence`
  5. `compare result`
  6. `debug only`
  7. `not current runtime truth`
- **Use case:** dev/test/internal docs、patch draft、QA evidence。

### RF-P3.3.7-015 — 当前禁止的 user-facing / overclaim wording
- **Status:** Frozen candidate for this round
- **Forbidden claims:**
  1. 已切换到本地规划
  2. 本地已接管复习
  3. `review_group` 已退场
  4. 已自动安排学习路径
  5. 已进入新的复习模式
  6. 系统已按本地规划正式运行
  7. 本地结果已写回最终事实
  8. shadow compare 已通过，因此已完成切换
- **Why frozen candidate:** 这些表达都会把 shadow evidence 误写成 runtime cutover。

### RF-P3.3.7-016 — helper / label / debug wording 的使用范围
- **Status:** Frozen candidate for this round
- **Rule:** helper / label / debug wording 当前只允许：
  1. internal docs
  2. debug panel
  3. QA evidence
  4. patch / closeout 附件
- **Current forbidden layer:**
  1. Home user summary
  2. ReviewPage user helper
  3. StudyPage 正常说明
  4. 用户可见 toast / empty / completion 文案

---

## 8. `shadow_to_phase3_gate_v1`

## 8.1 Room 3 结论
> **进入 Phase 3 的业务前提，不是“影子逻辑存在”，而是“影子逻辑已经积累到足够多、且足够稳定的可解释证据”。**

### RF-P3.3.7-017 — future Phase 3 需要的业务证据
- **Status:** Frozen candidate for this round
- **Required evidence direction:**
  1. queue compare 长期稳定，不持续出现 must-hold mismatch
  2. continuation / completion / eligibility 判断在 evidence 层可解释
  3. fact ingest evidence 的 accept / reject / duplicate 规则稳定
  4. routing shadow 不与 `study_default` / continuation truth 冲突
  5. `review_group` 的 compatibility posture 未被破坏
  6. shadow 结果可被长期 regression 固定
- **Current meaning:** 只有这些证据逐步齐备，Room 1 才有资格讨论 Phase 3。

### RF-P3.3.7-018 — “看起来可行”不等于“可以升格为 runtime fact”
- **Status:** Frozen candidate for this round
- **Rule:** 即使本轮 shadow 结果：
  - 看起来更合理
  - 与 cloud baseline 大体一致
  - 可通过大多数 compare
  也仍然不能自动升格为 runtime fact。
- **Why frozen candidate:** Phase 2 的任务是收证据，不是完成切换。

---

## 9. 哪些内容必须继续 Pending

### 9.1 当前继续 Pending
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

### 9.2 Room 3 一句话原则
> **本轮只回答“影子怎么跑、跑出什么证据算合格”，不回答“今天就已经切完了”。**

---

## 10. 可直接给 Room 1 的决策句

### 10.1 Shadow evidence decision sentence
> **Room 3 judgment：P3.3.7 当前可以进入 Phase 2 / Limited Execution / Shadow Mode，但所有 local-serving / fact-ingest / routing 的 shadow 结果只允许先进入 evidence 层，不得升格为 current runtime truth。**

### 10.2 Mismatch severity decision sentence
> **Room 3 judgment：P3.3.7 当前必须把 mismatch 分成 `info-only / warning / must-hold / must-escalate` 四层；凡触碰 current runtime truth、final fact owner、`review_group` current owner posture、或 user-visible overclaim 的 mismatch，都不属于可带着走的 warning。**

### 10.3 Gate decision sentence
> **Room 3 judgment：P3.3.7 的 acceptance gate 先看 guardrails 是否守住——current runtime truth 不变、shadow 不漏到用户端、final fact 不被 shadow 改写、`review_group` posture 不被破坏——再看 parity 是否逐步稳定；“影子结果看起来合理”本身不足以进入 Phase 3。**

---

## 11. Room 3 最终一句话

> **P3.3.7 这轮，Room 3 支持进入 Limited Execution / Shadow Mode；但 shadow 结果当前只能是 evidence，不能是 fact；能跑起来不等于能切过去，证据足够也不等于现在就可以改 current runtime truth。**
