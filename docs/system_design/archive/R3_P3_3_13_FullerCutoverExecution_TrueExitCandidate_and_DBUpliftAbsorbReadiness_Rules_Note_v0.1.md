# R3_P3_3_13_FullerCutoverExecution_TrueExitCandidate_and_DBUpliftAbsorbReadiness_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / fuller-cutover execution / true-exit-candidate / DB-API uplift-absorb-readiness round
- **Status:** ready for Room 1 review
- **Date:** 2026-04-11
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis:** `Main_updated_2026-04-10_v33.md` + `STATUS_updated_2026-04-10_v31.md`
- **Direct upstream input:** `R1_P3_3_13_ScopePin_and_Handoff_Pack_v0.1.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 3 的业务规则视角，把 P3.3.13 当前轮需要回答的 fuller-cutover execution / `review_group` true-exit-candidate / DB-API uplift-absorb-readiness 问题，收成一份可测试、可引用、可被 Room 1 判断是否 pin 的最小规则合同。**

本稿不是：
- 新 BR 主文档
- 新 DB / API 主文档
- 新 UI 主文档
- Room 4 执行单
- runtime owner shift 完成宣告
- `review_group` true exit 公告
- active DB/API baseline uplift absorbed 生效稿
- cleanup / old-path purge 方案书

一句话：

> **P3.3.13 是 fuller-cutover execution / true-exit-candidate / uplift-absorb-readiness round，不是 full cutover completed / true exit / uplift absorbed round。**


## 1. 输入依据

### 1.1 Governance / role basis
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_13_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.3 Current runtime / review basis
- `BR-OPP-001_v0.2.14.md`
- `UI_SPEC_v0.3.4.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `Main_updated_2026-04-10_v33.md`
- `STATUS_updated_2026-04-10_v31.md`
- `P3.3.12_Claude_res.md`

### 1.4 前一轮规则连续性
P3.3.12 已把：
1. `fuller_cutover_absorb_candidate_v1`
2. `review_group_true_exit_gate_v1`
3. `db_api_uplift_absorb_judgment_v1`
4. `cutover_vs_fact_owner_boundary_v4`
5. `exit_candidate_to_true_exit_transition_v1`
6. `phase6_writeback_order_v1`

推进到 judgment / gate / candidate 层。  
P3.3.13 当前不是重开判断层，而是把其中一小段推进到：

> **execution / true-exit-candidate / uplift-absorb-readiness**

但仍不允许把它们写成已经生效的 runtime truth。


## 2. Room 3 总判断

### 2.1 本轮是否应该前进一步
Room 3 结论：

> **应该前进一步。**

因为 P3.3.12 已完成：
1. widened subset 的 absorb-candidate judgment
2. `review_group` 的 true-exit-gate judgment
3. DB/API seam families 的 uplift-absorb judgment
4. stronger-ingest absorb-candidate binding prep
5. BR / UI 对上一轮 judgment 的主文档吸收基础

如果 P3.3.13 还不继续推进 execution / candidate / readiness，主线程会继续停在：

> “已经知道哪些东西更接近下一拍，但永远不敢把它们推进到下一层可执行准备。”

### 2.2 本轮不能直接写成什么
Room 3 同时明确：

> **P3.3.13 当前不能直接写成 `runtime owner shift completed`、`ReviewPage local-serving full runtime cutover completed`、`review_group` true exit、`active DB/API baseline uplift absorbed`、`cleanup`、`final fact owner shift`。**

### 2.3 Room 3 的一句话立场
> **Room 3 支持 P3.3.13 进入 fuller-cutover execution / true-exit-candidate / uplift-absorb-readiness；但这轮只应把“更宽一层的 execution subset、`review_group` 哪些内容可以进入 true-exit-candidate、哪些 seam 现在只够 uplift-absorb-readiness、以及哪些 truth / fact / wording 仍绝不能动”写硬。**


## 3. `fuller_cutover_execution_subset_v2`

## 3.1 Room 3 结论
> **P3.3.13 当前允许 fuller-cutover 从 judgment 再前进一步到更完整一拍的 execution subset；但这层仍只允许停在 ReviewPage + 首页 review 承接层，不允许越过到首页默认主 route、active continuation source、或 final fact owner。**

### RF-P3.3.13-001 — 当前允许进入 execution subset 的 widened family
- **Status:** Frozen candidate for this round
- **Rule:** 当前最稳的 fuller-cutover execution subset，只允许扩大到：
  1. **ReviewPage continuity-adjacent serving-adapter family**
  2. **与其强绑定的 source-neutral helper / summary / empty-state / completion 前置说明层**
  3. **首页 review helper / summary / no-review-state 的 retained-anchor-aware contract**
  4. **rollback / hold / fallback 的中性 copy / state contract**
  5. **stronger-ingest absorb-candidate binding prep**
- **Canonical meaning:** 这表示 widened subset 现在已足够从 judgment 进一步进入 execution-preflight / execution-ready 一小层，不表示 runtime 主真相源已经切换。

### RF-P3.3.13-002 — 当前明确禁止扩大到
- **Status:** Frozen candidate for this round
- **Forbidden layer:**
  1. 首页默认主 route 切换
  2. active continuation source switch
  3. user-visible planner-aware route / auto-routing runtime
  4. `review_group` true exit
  5. final fact owner shift
  6. active DB/API baseline uplift absorbed
  7. cleanup / old-path purge
- **Why frozen candidate:** 这些一旦一起进入，本轮就不再是 very narrow execution round，而会变成主链路静默重写。

### RF-P3.3.13-003 — widened execution subset 仍必须守住最小 rollback 与最小 blast radius
- **Status:** Frozen candidate for this round
- **Rule:** 本轮 widened subset 只允许在以下前提下前进一步：
  1. blast radius 继续主要局限在 **ReviewPage + 首页 review 承接层**
  2. rollback complexity 继续可由 retained anchor / fallback / hold 结构承受
  3. widened subset 不得误伤首页主路由、active continuation、final fact owner
- **Why frozen candidate:** 这轮的重点不是“能不能扩大”，而是“扩大后仍能不能被 very narrow 地兜住”。

### RF-P3.3.13-004 — execution subset ≠ fuller cutover completed
- **Status:** Frozen candidate for this round
- **Rule:** 即使 widened subset 进入 execution subset，也只表示：
  - 已具备进入更完整一拍 execution-preflight 的资格
  - 不表示当前已经完成 fuller cutover
- **Why frozen candidate:** `judgment / execution-ready / runtime truth` 必须继续分层。


## 4. `review_group_true_exit_candidate_v1`

## 4.1 Room 3 结论
> **`review_group` 当前允许从 true-exit-gate judgment 再往前推一点，但只允许进入 true-exit-candidate；不允许进入 true exit。**

### RF-P3.3.13-005 — `review_group` 当前仍必须保持四层并存
- **Status:** Frozen candidate for this round
- **Rule:** 在 P3.3.13 当前轮，`review_group` 仍必须继续保持：
  1. **current runtime serving owner**
  2. **retained fallback anchor**
  3. **compatibility anchor**
  4. **deprecated candidate**
- **Must not do:** 不得把它写成 true exit、fallback-only、historical-only、或可直接清理。
- **Why frozen candidate:** 当前还没有任何条件允许它脱离 current owner 身份。

### RF-P3.3.13-006 — 哪些内容当前允许进入 true-exit-candidate
- **Status:** Frozen candidate for this round
- **Rule:** 当前只允许进入 **true-exit-candidate** 层的包括：
  1. still-dependent paths 是否已逐条完成 inventory 与 replacement-readiness 判断
  2. 哪些 retained-anchor 依赖未来允许 very narrow 缩窄
  3. 哪些 fallback / rollback scope 未来允许 very narrow 缩窄
  4. 哪些 helper / summary / CTA / empty-state 需要先脱离 group-only wording
  5. true-exit-gate 所需 contract / runtime / test / doc / fallback 条件是否已成套
- **Canonical meaning:** 当前只判断“是否已接近 true exit 候选层”，不判断“现在可退出”。

### RF-P3.3.13-007 — 哪些内容当前仍必须继续保持 current owner + retained fallback anchor
- **Status:** Frozen candidate for this round
- **Rule:** 在 P3.3.13 当前轮，以下内容仍必须继续保持 current owner + retained fallback anchor：
  1. current visible owner 身份
  2. rollback target
  3. active continuation identity
  4. completion gating
  5. settlement trigger
  6. non-cutover / non-upgraded sessions baseline path
  7. compatibility anchor / QA baseline reference
- **Why frozen candidate:** 这些仍是 current owner 身份的硬依赖，不能因为进入 true-exit-candidate 就被提前抽空。

### RF-P3.3.13-008 — 哪些路径当前仍必须依赖 `review_group`
- **Status:** Frozen candidate for this round
- **Rule:** 只要以下任一仍未被清晰替代，`review_group` 就不得被写成已可 true exit：
  1. active continuation identity
  2. completion gating
  3. settlement trigger
  4. rollback target
  5. non-cutover / non-upgraded sessions baseline path
  6. compatibility anchor / QA baseline reference
- **Why frozen candidate:** 这 6 条是当前 true-exit-candidate 仍不等于 true exit 的直接证明。

### RF-P3.3.13-009 — true-exit-candidate ≠ true exit
- **Status:** Frozen candidate for this round
- **Rule:** 即使某些路径逐步进入 replacement-ready，也只代表：
  - `review_group` 可以进入 true-exit-candidate
  - 不代表当前已经进入 true exit，更不代表可以 cleanup
- **Why frozen candidate:** 这是本轮最容易被误写错的层级边界。


## 5. `db_api_uplift_absorb_readiness_v1`

## 5.1 Room 3 结论
> **从规则层看，本轮可以把少数 seam 从 uplift-absorb judgment 再前进一步到 uplift-absorb-readiness；但 uplift-absorb-readiness 仍不是 active baseline uplift absorbed。**

### RF-P3.3.13-010 — 哪些 seam 当前允许进入 uplift-absorb-readiness
- **Status:** Frozen candidate for this round
- **Rule:** 当前最多只允许以下与 fuller-cutover widened subset 直接绑定的 seam families 进入 uplift-absorb-readiness：
  1. serving source descriptor seam
  2. retained-anchor / fallback posture seam
  3. stronger-ingest path minimal seam
  4. rollback / hold / observability seam
  5. source-neutral state / helper / summary contract seam
- **Canonical meaning:** 这些 seam 可以被判断“是否已具备进入 absorb-readiness 的资格”，不表示 active baseline 已升级。

### RF-P3.3.13-011 — 哪些仍只能停留在 marker / migration / rollback / hold 层
- **Status:** Frozen candidate for this round
- **Rule:** 当前仍只能停留在 marker / migration / rollback / hold 层的包括：
  1. `review_group` true-exit 相关 seam
  2. active continuation source switch 相关 seam
  3. final fact owner shift 相关 seam
  4. homepage route / planner-aware route 相关 seam
  5. DB schema rewrite / API core semantics rewrite 相关 seam
- **Why frozen candidate:** 这些一旦越界，就不再是 uplift-absorb-readiness，而会直接变成 DB/API major rewrite judgment。

### RF-P3.3.13-012 — 哪些结论当前只能算 uplift-absorb-readiness，不得升格为 runtime truth
- **Status:** Frozen candidate for this round
- **Rule:** 以下结论当前只能停在 uplift-absorb-readiness 层：
  1. 某个 seam 已足够进入 absorb-readiness
  2. 某个 migration / rollback / hold floor 已足够支撑下一轮
  3. 某个 source-neutral contract 已足够稳
  4. 某个 stronger-ingest seam 已足够进入 absorb-readiness 审查
- **Must not do:** 不得把这些写成：
  - active DB/API baseline 已升级
  - endpoint meaning 已重写
  - runtime truth 已同步替换
  - 新基线已 absorbed 到运行态
- **Why frozen candidate:** `readiness` 与 `absorbed reality` 必须继续分层。


## 6. `cutover_vs_fact_owner_boundary_v5`

## 6.1 Room 3 结论
> **本轮允许 stronger-ingest candidate 再前进一步到 absorb-readiness-level candidate；但 final fact owner 当前仍绝不能动。**

### RF-P3.3.13-013 — 哪些 final fact 当前仍继续以后端为准
- **Status:** Frozen candidate for this round
- **Rule:** 即使 fuller-cutover execution 再前进一步，以下 final fact 当前仍必须继续以后端 / cloud fact layer 为准：
  1. 有效复习事实
  2. 今日目标完成
  3. 奖励结算 / 账本到账
  4. `check_in / learning_day / streak`
  5. completion / 到账类主反馈
- **Must not do:** 不得把 local stronger-ingest absorb-readiness candidate 写成这些最终事实可由本地裁定。

### RF-P3.3.13-014 — stronger-ingest candidate 当前最大允许走到哪
- **Status:** Frozen candidate for this round
- **Rule:** 当前 stronger-ingest candidate 最多只允许进入：
  1. **absorb-readiness-level stronger candidate**
  2. 更清楚的 accept / reject / duplicate / progress-candidate / completion-candidate 规则
  3. 更明确的 precondition / postcondition / hold-reason / evidence ownership
  4. 与 widened execution subset 直接绑定的最小 ingest contract
- **Current forbidden layer:**
  1. 直接改 ledger
  2. 直接改 daily goal final state
  3. 直接改 streak / learning_day 最终事实
  4. 直接替代 settlement owner
- **Why frozen candidate:** 更强的 absorb-readiness candidate ≠ final fact owner shift。

### RF-P3.3.13-015 — 哪些结果仍绝不能跟着 serving seam 一起切
- **Status:** Frozen candidate for this round
- **Rule:** 以下结果当前仍绝不能随着 serving seam 一起切换：
  1. effective learning / effective review 最终事实
  2. daily goal completed 最终判定
  3. reward settled /到账 最终判定
  4. streak / learning_day 最终判定
  5. completion /到账类主反馈
- **Why frozen candidate:** serving seam 再前进一步，不等于 result-fact seam 也可跟着前进一步。

### RF-P3.3.13-016 — 哪些 completion / reward / streak / daily goal / settlement 表达必须继续禁止
- **Status:** Frozen candidate for this round
- **Forbidden claims:**
  1. 本地已接管复习事实
  2. 本地已接管今日完成判定
  3. 本地结果已写回最终事实
  4. 奖励已按新主链路正式结算
  5. streak / learning day 已按新路径主导
  6. 今日目标已按新 serving seam 自动推进
  7. completion 已改由本地 stronger path 裁定
  8. `review_group` 已退场
  9. active DB/API baseline 已升级
  10. uplift 已 absorbed
  11. fuller cutover 已完成
  12. 新主链路已生效
- **Why frozen candidate:** 这些会把 execution / candidate / readiness 误写成 runtime truth。


## 7. `true_exit_candidate_narrowing_guardrail_v1`

## 7.1 Room 3 结论
> **本轮允许 true-exit-candidate very narrow 缩窄部分 retained-anchor 依赖，但 rollback target 仍必须继续固定为 `cloud_review_group_current_runtime_path`，且 stop-condition 继续全部保持。**

### RF-P3.3.13-017 — rollback target 是否继续固定
- **Status:** Frozen candidate for this round
- **Rule:** 在 P3.3.13 当前轮，rollback target 仍必须继续固定为：
  - **`cloud_review_group_current_runtime_path`**
- **Why frozen candidate:** 当前尚无第二个同等级 runtime truth owner 可以安全兜底。

### RF-P3.3.13-018 — 哪些 retained-anchor 依赖当前允许 very narrow 缩窄
- **Status:** Frozen candidate for this round
- **Rule:** 当前只允许 very narrow 缩窄：
  1. source-neutral helper / summary wording 的 group-only 耦合
  2. 首页 review helper / empty-state / no-review-state 的 retained-anchor-aware 表达
  3. rollback / fallback 说明中的历史性冗余 wording
  4. QA / docs 中对哪些 UI 资产已不再必须 group-only 的判断
- **Current forbidden layer:**
  1. rollback target 缩窄
  2. active continuation identity 缩窄
  3. completion gating 缩窄
  4. settlement trigger 缩窄
  5. non-cutover baseline path 缩窄
  6. current visible owner 身份缩窄
- **Why frozen candidate:** 仍然是“先缩表述和说明层，再缩路径级骨架”。

### RF-P3.3.13-019 — 哪些 stop-condition 必须继续保持硬挡板
- **Status:** Frozen candidate for this round
- **Must-hold list:**
  1. 首页 `study_default` 被触碰
  2. active continuation 被 silent reroute
  3. `review_group` 被写成 true exit / 已退场 / 可清理 / fallback-only
  4. local stronger path 影响 final fact / settlement truth
  5. 用户端出现“已切到本地规划 / 新主链路已生效 / `review_group` 已退场 / cutover 已完成 / uplift 已完成”
  6. fuller-cutover execution / true-exit-candidate / uplift-absorb-readiness 被误写成 runtime truth
  7. 需要改 DB schema / API core semantics 才能继续
- **Must-escalate list:**
  1. 需要把 `review_group` 从 current owner + retained anchor 改成非 current owner
  2. 需要把 active continuation 改到 local path
  3. 需要把 active DB/API baseline uplift 写成当前生效
  4. 需要把 cleanup / old-path purge 绑进当前轮
  5. 需要用户可见模式切换 / true exit / uplift absorbed / cleanup 宣告
- **Why frozen candidate:** 这些仍是当前轮的硬挡板，不得因为 execution 再前进一步就放松。


## 8. `phase7_writeback_order_v1`

## 8.1 Room 3 结论
> **本轮若要继续推进，必须把 execution-ready candidate、true-exit-candidate、uplift-absorb-readiness、runtime truth 四层的回写顺序继续写硬。**

### RF-P3.3.13-020 — 当前推荐 write-back 顺序
- **Status:** Frozen candidate for this round
- **Rule:** 当前推荐的最小回写顺序为：
  1. **Room 2 tech note**
  2. **Room 3 rules note**
  3. **Room 5 UI preflight**
  4. **Room 1 absorb / pin**
  5. 如获准，再进入 Room 4 更完整一拍 execution handoff
- **Why frozen candidate:** 先把 execution / candidate / readiness / truth 的边界写硬，再讨论是否值得进一步执行。

### RF-P3.3.13-021 — 哪些只能写成 execution-ready candidate
- **Status:** Frozen candidate for this round
- **Rule:** 当前只能写成 **execution-ready candidate** 的包括：
  1. widened execution subset
  2. true-exit-candidate judgment prep
  3. uplift-absorb-readiness seam families
  4. stronger-ingest absorb-readiness binding prep
  5. source-neutral / retained-anchor-aware UI migration prep
- **Current forbidden layer:** 不得写成 full cutover completed、`review_group` true exit、active DB/API uplift absorbed、final fact owner shift、或 cleanup 已生效。

### RF-P3.3.13-022 — 哪些可以被 Room 1 吸收到下一轮 Room4 handoff
- **Status:** Frozen candidate for this round
- **Rule:** 当前若要被 Room 1 吸收到下一轮 `R1 → R4` handoff，至少必须满足：
  1. no-overclaim
  2. rollback / hold / fallback / observability 已成套
  3. 不触碰首页 route / active continuation / final fact owner
  4. `review_group` 仍保持 current owner + retained anchor
  5. 不把 uplift-absorb-readiness 写成 active uplift
- **Why frozen candidate:** 这是当前 execution handoff 的最低治理门槛。


## 9. fact-copy / state guardrails

### 9.1 当前允许的表达方向
当前治理层允许的表达方向：
- fuller-cutover execution subset
- true-exit-candidate
- uplift-absorb-readiness
- retained anchor
- still backend-owned final facts
- not current runtime truth
- not active uplift
- not true exit

### 9.2 当前禁止的 overclaim
以下表达当前轮继续禁止：
1. 已切到本地规划
2. 本地已接管复习
3. `review_group` 已退场
4. 新主链路已生效
5. cutover 已完成
6. 本地结果已写回最终事实
7. active DB/API baseline 已升级
8. uplift 已 absorbed
9. true exit 已开始
10. 现在已经可以清理旧 path

---

## 10. 当前继续保持 Pending

1. full cutover completed
2. runtime owner shift completed
3. `review_group` true exit
4. active DB/API baseline uplift absorbed
5. cleanup / old-path purge
6. homepage route / planner-aware runtime route
7. active continuation source switch
8. auto-routing runtime
9. unified planner / planner merge
10. final fact owner shift
11. DB schema rewrite
12. API core semantics rewrite
13. 用户可见 owner-shift / cutover / exit / uplift absorbed 宣告


## 11. 可直接给 Room 1 的判定句

### 11.1 fuller-cutover execution 判定句
> **Room 3 judgment：P3.3.13 当前允许 fuller-cutover 从 P3.3.12 judgment 前进一步到更完整一拍的 execution subset，但这层只允许继续留在 ReviewPage + 首页 review 承接层的 widened family；首页默认主 route、active continuation source、final fact owner 与 full cutover 继续不进入当前执行层。**

### 11.2 true-exit-candidate 判定句
> **Room 3 judgment：`review_group` 当前可以进入 true-exit-candidate，但只允许进入 retained-anchor → true-exit-candidate 的资格判断与 very narrow 缩窄判断；它当前仍必须继续保持 current runtime owner + retained fallback anchor + compatibility anchor + deprecated candidate，不得被写成 true exit、fallback-only 或可清理。**

### 11.3 fact-boundary 判定句
> **Room 3 judgment：即使 fuller-cutover execution 前进一步，有效复习、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端为准；local stronger-ingest path 最多只允许进入 absorb-readiness-level stronger candidate，不得升格为 fact owner。**

### 11.4 uplift-absorb-readiness 判定句
> **Room 3 judgment：P3.3.13 当前可以把少数与 fuller-cutover 直接绑定的 seam 升到 uplift-absorb-readiness，但 uplift-absorb-readiness 只说明“可进入 active baseline uplift absorbed 审查前的 execution-ready / readiness 层”，不说明“active DB/API baseline 已升级”。**

### 11.5 must-hold / must-escalate 判定句
> **Room 3 judgment：凡触碰首页 `study_default`、active continuation、`review_group` current owner posture、final fact / settlement truth、active DB/API baseline、或用户可见 overclaim 的情况，一律不得按“可带着走的 execution-ready / true-exit-candidate / uplift-absorb-readiness 差异”处理；其中涉及 DB schema / API core semantics / cleanup / 用户可见 exit / uplift 宣告的，必须升级，不得在本轮内自行吸收。**

---

## 12. Room 3 最终一句话

> **P3.3.13 这轮，Room 3 支持把 fuller-cutover 从 judgment 推到更完整一拍的 execution subset，但这层仍然只回答“哪些 widened family 现在配得上再前进一步、哪些 retained-anchor 范围可 very narrow 缩窄、哪些 seam 只到 uplift-absorb-readiness”，不是在回答“现在已经切完 / 退完 / 升完”。**
