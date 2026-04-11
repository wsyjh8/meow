# R3_P3_3_9_FirstVeryNarrowCutover_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / first very narrow cutover round
- **Status:** ready for Room 1 review
- **Date:** 2026-04-11
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis:** `Main_updated_2026-04-10_v29.md` + `STATUS_updated_2026-04-10_v27.md`
- **Direct upstream input:** `R1_P3_3_9_ScopePin_and_Handoff_Pack_v0.1.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 3 的业务规则视角，把 P3.3.9 当前轮需要回答的 first very narrow cutover 问题，收成一份可测试、可引用、可被 Room 1 判断是否 pin 的最小规则合同。**

本稿不是：
- 新 BR 主文档
- 新 DB / API 主文档
- 新 UI 主文档
- Room 4 执行单
- runtime owner shift 完成宣告
- `review_group` 退场公告
- full cutover 方案书
- unified planner / planner merge 最终版

一句话：

> **P3.3.9 是 first very narrow cutover preflight，不是 full cutover，也不是 cleanup / exit / baseline uplift 合并轮。**

---

## 1. 输入依据

### 1.1 Governance / role basis
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_9_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.3 Current runtime / review basis
- `BR-OPP-001_v0.2.10.md`
- `UI_SPEC_v0.3.0.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `Main_updated_2026-04-10_v29.md`
- `STATUS_updated_2026-04-10_v27.md`

### 1.4 Prior-round evidence basis
- `P3.3.8_Claude_res.md`

---

## 2. Room 3 总判断

### 2.1 本轮是否应该前进一步
Room 3 结论：

> **应该前进一步。**

因为 P3.3.8 已经把：
- gate evidence
- candidate seam
- `review_group` exit gate
- fact / settlement cutover boundary
- migration / rollback / hold-note baseline

推进到了 **Phase 3 gate / candidate / migration** 层。  
如果 P3.3.9 还不回答“第一刀到底切哪一小段”，主线程会继续停在“已经有 gate，但永远不敢切第一刀”的状态。

### 2.2 本轮不能直接写成什么
Room 3 同时明确：

> **P3.3.9 当前不能直接写成 `runtime owner shift completed`、`ReviewPage local-serving full runtime cutover completed`、`review_group` 已退出运行态、`auto-routing` 已开启、`planner merge / unified planner` 已成立。**

### 2.3 Room 3 的一句话立场
> **Room 3 支持 P3.3.9 进入 first very narrow cutover preflight；但这轮只应把“第一刀切哪一小段、哪些 runtime truth 可以极窄切换、`review_group` 要保留成什么锚点、final fact 哪些绝不能跟着切、以及 rollback / hold / observability 护栏”写硬，不能把 first-cutover 候选误写成 full cutover 已成立。**

---

## 3. `first_cutover_rule_set_v1`

## 3.1 Room 3 核心结论
> **第一轮 first-cutover 当前只允许切 “ReviewPage 内部 serving seam 的 very narrow subset”，不允许切首页 runtime 入口、不允许切 final fact owner、不允许切 `review_group` 退场。**

### RF-P3.3.9-001 — 本轮允许的 first-cutover subset
- **Status:** Frozen candidate for this round
- **Rule:** P3.3.9 当前只允许讨论以下 very narrow subset 作为 first-cutover 候选：
  1. **ReviewPage 内部 serving seam 的 source switch candidate**
  2. **local-serving 结果进入 stronger ingest path 的最小接缝**
  3. **与该 seam 直接相关的 helper / summary / state contract 极小迁移**
  4. **rollback / hold / observability 最小配套**
- **Current forbidden layer:**
  1. 首页 `study_default` runtime 入口切换
  2. active continuation 承接方式整体改写
  3. `review_group` 真实退场
  4. final fact owner shift
  5. DB / API baseline uplift
- **Why frozen candidate:** 这是当前风险最低、回滚最容易、也最不容易污染 final fact 的第一刀。

### RF-P3.3.9-002 — 本轮不接受“先切 helper / 文案，不切真实 seam”的伪 cutover
- **Status:** Frozen candidate for this round
- **Rule:** 若本轮叫 first cutover，就必须真的切一个 **runtime seam**；只改 helper / 文案 / state contract，而完全不触碰 seam，本质仍是 migration prep，不算 first cutover。
- **Canonical meaning:**  
  本轮允许的最小真切口，是 **ReviewPage 内部 serving seam**；不是首页入口，也不是 final fact owner。

### RF-P3.3.9-003 — 本轮不接受“先切 final fact stronger-path，再补 serving seam”的倒序
- **Status:** Frozen candidate for this round
- **Rule:** first cutover 当前不应先切 stronger ingest / final-fact path，而应先切 **serving seam 的 very narrow subset**，并保持 final fact owner 不变。
- **Why frozen candidate:** 否则会把“显示 / 承接层面的切口”直接升级成“最终事实切口”，风险过大。

---

## 4. `runtime_truth_switch_boundary_v1`

## 4.1 Room 3 结论
> **本轮若真切一刀，只允许极窄地切 ReviewPage 内部 serving seam；以下 runtime truth 继续不得改。**

### RF-P3.3.9-004 — 当前允许 very narrow 切换的 runtime truth
- **Status:** Frozen candidate for this round
- **Rule:** 当前唯一允许进入 first-cutover 讨论的 runtime-truth switch 候选，是：
  - **ReviewPage 内部“当前一组复习项从哪里来”的极小 serving seam**
- **Boundary meaning:**
  1. 只讨论 ReviewPage 内部当前 item source / queue source 的 very narrow switch
  2. 不讨论首页入口 truth
  3. 不讨论 completion truth
  4. 不讨论 reward / settlement truth
  5. 不讨论 planning / unified planner truth

### RF-P3.3.9-005 — 以下 runtime truth 当前继续必须保持不变
- **Status:** Frozen candidate for this round
- **Rule:** P3.3.9 当前轮以下 runtime truth 继续保持不变：
  1. 首页继续 `home_word_entry = study_default`
  2. active continuation 继续独立承接，不得 silent reroute
  3. `review_group` 当前继续是 current runtime serving owner
  4. final fact / settlement truth 继续以后端为准
  5. preview / explanation 不得借本轮升级成 committed plan fact
- **Why frozen candidate:** 这 5 条是 first-cutover 仍不越界的最关键护栏。

### RF-P3.3.9-006 — serving seam 可局部切，但不得误伤 summary / continuation / settlement
- **Status:** Frozen candidate for this round
- **Rule:** 即使 ReviewPage 内部 serving seam 进入 very narrow switch，以下部分仍不得被该切口顺手改写：
  1. 首页 summary truth
  2. active continuation 高优先语义
  3. group completion / settlement truth
  4. reward / daily goal / streak / learning day 结果表达
- **Canonical meaning:**  
  local-serving 的第一刀，只能切 ReviewPage 内部 serving seam；不能把外围 truth 一起带走。

---

## 5. `review_group_retained_anchor_v1`

## 5.1 Room 3 结论
> **P3.3.9 当前最稳的业务写法，不是让 `review_group` 继续只做 current owner，也不是让它直接退场，而是进入 “dual posture：current owner + retained fallback anchor”。**

### RF-P3.3.9-007 — `review_group` 当前应进入 dual posture
- **Status:** Frozen candidate for this round
- **Rule:** 在 first-cutover round 中，`review_group` 当前应被明确写成：
  1. **current runtime owner（对当前未切路径）**
  2. **retained fallback anchor（对新切 very narrow seam）**
  3. **compatibility anchor**
  4. **deprecated candidate（但不是 exit now）**
- **Why frozen candidate:**  
  如果继续只写 current owner，不够支撑 first-cutover；  
  如果直接写成 fallback-only，又会偷切 current runtime truth。  
  dual posture 是当前最稳的中间态。

### RF-P3.3.9-008 — 哪些路径仍必须继续走 `review_group`
- **Status:** Frozen candidate for this round
- **Rule:** 即使本轮切 very narrow serving seam，以下路径当前仍必须继续明确依赖 `review_group`：
  1. active continuation identity
  2. current completion gating
  3. current settlement trigger
  4. rollback target
  5. non-cutover users / sessions 的 baseline path
- **Canonical meaning:**  
  本轮最多切 “某一小段 serving seam”，不能把整条 `review_group` path 直接抽空。

### RF-P3.3.9-009 — 触发 rollback 时必须回到 `review_group`
- **Status:** Frozen candidate for this round
- **Rule:** 若 first-cutover seam 触发 stop condition / hold / rollback，则回退目标必须是：
  - **cloud `review_group` current runtime path**
- **Why frozen candidate:** 当前没有第二个同等级 runtime truth owner 可兜底。

### RF-P3.3.9-010 — 本轮继续禁止的 `review_group` overclaim
- **Status:** Frozen candidate for this round
- **Forbidden claims:**
  1. `review_group` 已退场
  2. `review_group` 已不再是 runtime owner
  3. `review_group` 仅剩历史兼容意义
  4. 可以直接清理旧 path
- **Why frozen candidate:** 这些都属于 cleanup / exit / uplift 轮，不属于本轮。

---

## 6. `fact_owner_guardrail_v1`

## 6.1 Room 3 结论
> **本轮最重要的红线仍然是：serving subset 可以 very narrow 切，但 final fact 绝不能跟着切。**

### RF-P3.3.9-011 — 以下 final fact 继续必须以后端为准
- **Status:** Frozen candidate for this round
- **Rule:** 即使 ReviewPage 内部 serving seam 进入 first cutover，以下 final fact 当前仍必须继续以后端 / cloud fact layer 为准：
  1. 有效复习事实
  2. 今日目标完成
  3. 奖励结算 / 账本到账
  4. `check_in / learning_day / streak`
- **Must not do:** 不得把 local-serving 的 first-cutover 结果写成这些最终事实已经跟着切换。

### RF-P3.3.9-012 — stronger ingest path 当前最多只允许 very narrow 升级，不允许 fact owner shift
- **Status:** Frozen candidate for this round
- **Rule:** 本轮若要推进 stronger ingest path，最多只允许：
  1. 更强的 evidence ingestion
  2. accept / reject / duplicate 规则更明确
  3. 与 first-cutover seam 直接相关的最小传递
- **Current forbidden layer:**
  1. local 直接改 ledger
  2. local 直接改 daily_goal completion
  3. local 直接改 streak / learning_day 最终事实
  4. local 直接替代 settlement owner
- **Why frozen candidate:** serving seam 的第一刀，不得带出 fact owner shift。

### RF-P3.3.9-013 — 以下 wording / state 一旦出现即属于 overclaim
- **Status:** Frozen candidate for this round
- **Forbidden claims:**
  1. 本地已接管复习事实
  2. 本地已接管今日完成判定
  3. 本地结果已写回最终事实
  4. 奖励已按本地主路径正式结算
  5. streak / learning day 已按本地 serving 续上
- **Why frozen candidate:** 这些会把 serving cutover 误写成 fact cutover。

---

## 7. `db_api_cutover_candidate_v2`（Room 3 规则层口径）

## 7.1 Room 3 结论
> **从规则层看，本轮只允许 DB / API seam 从 candidate 升到 first-cutover-ready；不允许任何 core semantics rewrite。**

### RF-P3.3.9-014 — 哪些 seam 当前可升到 first-cutover-ready
- **Status:** Frozen candidate for this round
- **Rule:** 当前可讨论升格的，只能是与 first-cutover seam 直接相关的：
  1. serving source descriptor seam
  2. retained-anchor / fallback marker seam
  3. stronger ingest path minimal seam
  4. rollback / hold / observability seam
- **Current forbidden layer:**
  1. DB schema rewrite
  2. endpoint core semantics rewrite
  3. active baseline uplift to new owner-shift reality
- **Why frozen candidate:** 本轮是 first cutover，不是 baseline rewrite。

### RF-P3.3.9-015 — API / DB 本轮继续绝不能改的东西
- **Status:** Frozen candidate for this round
- **Forbidden changes:**
  1. 当前 active DB baseline uplift
  2. 当前 active API baseline uplift
  3. current endpoint meaning rewrite
  4. `review_group` 语义改写成非当前 owner
  5. settlement / reward owner 改写
- **Why frozen candidate:** 这些一旦进入，就不再是 very narrow cutover。

---

## 8. `rollback_holdnote_and_observability_v1`

## 8.1 Room 3 结论
> **本轮若真进入 first cutover，rollback / hold / observability 不是附属项，而是 cutover 合同的一部分。**

### RF-P3.3.9-016 — rollback floor
- **Status:** Frozen candidate for this round
- **Rule:** 第一轮 first-cutover 至少必须具备以下 rollback floor：
  1. 明确的回退目标 = `review_group` current runtime path
  2. 明确的回退触发条件
  3. 明确的回退后用户可见 truth 不变
  4. 明确的 no-cut-runtime-truth statement
- **Canonical meaning:**  
  回退不是“以后再看”，而是本轮切口成立的前置条件。

### RF-P3.3.9-017 — must-hold
- **Status:** Frozen candidate for this round
- **Must-hold list:**
  1. first-cutover seam 影响首页 `study_default`
  2. active continuation 被 silent reroute
  3. `review_group` 被误写成已退场 / 不再是 current owner
  4. local-serving 结果影响 final fact / settlement truth
  5. 用户端出现“已切到本地规划 / 已接管复习 / cutover 已完成”
  6. 需要改 DB schema / API core semantics 才能继续
- **Action:** hold，本轮不得继续扩写。

### RF-P3.3.9-018 — must-escalate
- **Status:** Frozen candidate for this round
- **Must-escalate list:**
  1. 需要把 `review_group` 从 dual posture 提前改成 fallback-only
  2. 需要把 stronger ingest seam 升格成 active fact path
  3. 需要把 auto-routing / planner merge / unified planner 拉进当前轮
  4. 需要用户可见模式切换说明
  5. 需要把 cleanup / exit / baseline uplift 绑进来
- **Action:** escalate 给 Room 1 / Room 2 / User，不得在本轮内自行吸收。

### RF-P3.3.9-019 — observability 最小要求
- **Status:** Frozen candidate for this round
- **Rule:** 本轮至少要补齐能支撑 first-cutover 的最小证据位：
  1. seam hit / fallback hit
  2. retained-anchor rollback hit
  3. stronger ingest candidate accept / reject / duplicate
  4. hold trigger
  5. user-visible overclaim guard check
- **Why frozen candidate:** 没有这些证据位，first cutover 不可控。

---

## 9. `fact_copy_guardrails_v2`

### 9.1 当前允许的内部表达
- first-cutover candidate
- retained anchor
- fallback path
- stronger ingest candidate
- runtime truth not fully switched
- not final fact owner
- rollback-ready
- hold if crossed

### 9.2 当前禁止的 overclaim
以下表达当前轮继续禁止：
1. 已切到本地规划
2. 本地已接管复习
3. `review_group` 已退场
4. 已自动安排学习路径
5. cutover 已完成
6. 本地结果已写回最终事实
7. 新主链路已生效
8. 现在已按本地主 serving 运行

### 9.3 helper / state / summary 禁区
以下位置当前都不得出现 overclaim：
- 首页 helper
- ReviewPage summary
- empty-state
- completion 文案
- toast
- settings / backup 成功提示
- migration / cutover banner

---

## 10. 当前继续保持 Pending

1. runtime owner shift completed
2. ReviewPage local-serving full runtime cutover
3. `review_group` 真退场
4. cleanup / old path purge
5. active DB/API baseline uplift
6. DB schema rewrite
7. API core semantics rewrite
8. auto-routing runtime
9. planner merge / unified planner
10. 用户可见 owner-shift / cutover 宣告

---

## 11. 可直接给 Room 1 的判定句

### 11.1 first-cutover 规则句
> **Room 3 judgment：P3.3.9 当前可以进入 first very narrow cutover preflight，但第一刀只建议切 ReviewPage 内部 serving seam 的最小子集；首页 `study_default`、active continuation、`review_group` exit、final fact owner 与 DB/API baseline uplift 都不进入当前切口。**

### 11.2 retained-anchor 规则句
> **Room 3 judgment：`review_group` 在 P3.3.9 当前最稳的业务姿态不是“继续只做 current owner”，也不是“立即退场”，而是 `current runtime owner + retained fallback anchor + compatibility anchor + deprecated candidate` 的 dual posture；任何把它写成已退场、已不再使用或可直接清理的表达都属于越界。**

### 11.3 fact-owner guardrail 规则句
> **Room 3 judgment：first-cutover 当前只允许切 serving seam，不允许切 final fact owner；有效复习、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端 / cloud fact layer 为准。**

### 11.4 must-hold / must-escalate 规则句
> **Room 3 judgment：凡触碰首页 `study_default`、active continuation、`review_group` current owner posture、final fact / settlement truth、或用户可见 overclaim 的情况，一律不得按“可带着走的 very narrow cutover 差异”处理；其中涉及 cleanup / exit / baseline uplift / auto-routing / planner merge / 用户可见模式切换说明的，必须升级，不得在本轮内自行吸收。**

---

## 12. Room 3 最终一句话

> **P3.3.9 这轮，Room 3 支持进入第一轮 very narrow cutover preflight；但这轮真正允许切的，只是 ReviewPage 内部 serving seam 的最小一刀，而且必须在 `review_group` retained-anchor、final fact owner 不动、rollback / hold / observability 成套存在的前提下推进。**
