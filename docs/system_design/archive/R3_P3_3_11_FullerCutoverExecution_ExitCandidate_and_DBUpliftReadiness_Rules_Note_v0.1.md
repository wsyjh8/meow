# R3_P3_3_11_FullerCutoverExecution_ExitCandidate_and_DBUpliftReadiness_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / fuller-cutover execution / exit-candidate / DB-API uplift-readiness round
- **Status:** ready for Room 1 review
- **Date:** 2026-04-11
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis:** `Main_updated_2026-04-10_v31.md` + `STATUS_updated_2026-04-10_v29.md`
- **Direct upstream input:** `R1_P3_3_11_ScopePin_and_Handoff_Pack_v0.2.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 3 的业务规则视角，把 P3.3.11 当前轮需要回答的 fuller-cutover execution / `review_group` exit-candidate / DB-API uplift-readiness 问题，收成一份可测试、可引用、可被 Room 1 判断是否 pin 的最小规则合同。**

一句话：

> **P3.3.11 是 fuller-cutover execution / exit-candidate / uplift-readiness round，不是 full cutover completed / true exit / uplift absorbed round。**


## 1. 输入依据

### 1.1 Governance / role basis
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_11_ScopePin_and_Handoff_Pack_v0.2.md`

### 1.3 Current runtime / review basis
- `BR-OPP-001_v0.2.12.md`
- `UI_SPEC_v0.3.2.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `Main_updated_2026-04-10_v31.md`
- `STATUS_updated_2026-04-10_v29.md`
- `P3.3.10_Claude_res.md`


## 2. Room 3 总判断

### 2.1 本轮是否应该前进一步
Room 3 结论：

> **应该前进一步。**

因为 P3.3.10 已完成：
1. fuller-cutover judgment
2. `review_group` exit-gate judgment
3. DB/API uplift judgment
4. BR / UI 对上一轮结论的吸收基础

如果 P3.3.11 还不推进 execution-ready subset，主线程会继续停在“知道下一拍能切哪一层，但永远不敢真的往前走”。

### 2.2 本轮不能直接写成什么
Room 3 同时明确：

> **P3.3.11 当前不能直接写成 `runtime owner shift completed`、`ReviewPage local-serving full runtime cutover completed`、`review_group` true exit、`active DB/API baseline uplift absorbed`、`cleanup`、`final fact owner shift`。**

### 2.3 Room 3 一句话立场
> **Room 3 支持 P3.3.11 进入 fuller-cutover execution / exit-candidate / uplift-readiness；但这轮只应把“更宽一层的 execution subset、`review_group` 哪些范围可以进入 exit-candidate、哪些 seam 只到 uplift-readiness、以及哪些 truth / fact / wording 仍绝不能动”写硬。**


## 3. `fuller_cutover_execution_rule_set_v1`

### RF-P3.3.11-001 — 当前允许前进一步的 execution-ready subset
- **Status:** Frozen candidate for this round
- **Rule:** 当前最稳的 execution-ready subset，只允许扩大到：
  1. **ReviewPage continuity-adjacent serving-adapter family**
  2. **与其强绑定的 source-neutral helper / summary / empty-state / completion 前置说明层**
  3. **首页 review helper / summary / no-review-state 的 retained-anchor-aware prep**
  4. **rollback / hold / fallback 的中性 copy / state contract prep**

### RF-P3.3.11-002 — 当前明确禁止扩大到
- **Status:** Frozen candidate for this round
- **Forbidden layer:**
  1. 首页默认主 route 切换
  2. active continuation source switch
  3. user-visible planner-aware route / auto-routing runtime
  4. `review_group` true exit
  5. final fact owner shift
  6. active DB/API baseline uplift absorbed

### RF-P3.3.11-003 — execution-ready subset 不等于 full cutover execution
- **Status:** Frozen candidate for this round
- **Rule:** 即使某一层进入 execution-ready subset，也只表示：
  - 已具备进入更完整但仍 very narrow 的执行准备层
  - 不表示已经完成 full cutover execution


## 4. `review_group_exit_candidate_v1`

### RF-P3.3.11-004 — `review_group` 当前仍必须保持四层并存
- **Status:** Frozen candidate for this round
- **Rule:** `review_group` 当前仍必须继续保持：
  1. **current runtime serving owner**
  2. **retained fallback anchor**
  3. **compatibility anchor**
  4. **deprecated candidate**

### RF-P3.3.11-005 — 哪些内容当前允许进入 exit-candidate
- **Status:** Frozen candidate for this round
- **Rule:** 当前只允许进入：
  1. 前置条件是否齐备的判断
  2. 哪些 retained-anchor 依赖路径未来可 very narrow 缩窄
  3. rollback / fallback scope 哪些未来可 very narrow 缩窄
  4. 哪些 helper / summary / CTA / empty-state 需要先脱离 group-only wording

### RF-P3.3.11-006 — 哪些路径当前仍必须依赖 `review_group`
- **Status:** Frozen candidate for this round
- **Rule:** 当前以下路径仍必须继续显式依赖 `review_group`：
  1. active continuation identity
  2. completion gating
  3. settlement trigger
  4. rollback target
  5. non-cutover / non-upgraded sessions baseline path

### RF-P3.3.11-007 — retained anchor 哪些范围当前允许 very narrow 缩窄
- **Status:** Frozen candidate for this round
- **Rule:** 当前只允许缩窄：
  1. source-neutral helper / summary wording 的 group-only 耦合
  2. 首页 review helper / empty-state / no-review-state 的 retained-anchor-aware 表达
  3. rollback / fallback 说明中的历史性冗余 wording
- **Current forbidden layer:** rollback target、active continuation identity、completion gating、settlement trigger、non-cutover baseline path


## 5. `db_api_uplift_readiness_v1`

### RF-P3.3.11-008 — 哪些 seam 当前允许进入 uplift-readiness
- **Status:** Frozen candidate for this round
- **Rule:** 当前最多只允许以下 seam families 进入 uplift-readiness：
  1. serving source descriptor seam
  2. retained-anchor / fallback posture seam
  3. stronger ingest path minimal seam
  4. rollback / hold / observability seam
  5. source-neutral state / helper / summary contract seam

### RF-P3.3.11-009 — 哪些仍只能停留在 migration / hold / rollback 层
- **Status:** Frozen candidate for this round
- **Rule:** 当前仍只能停留在 migration / hold / rollback 层的包括：
  1. `review_group` true-exit 相关 seam
  2. active continuation source switch 相关 seam
  3. final fact owner shift 相关 seam
  4. homepage route / planner-aware route 相关 seam

### RF-P3.3.11-010 — 哪些结论当前只能算 uplift-readiness
- **Status:** Frozen candidate for this round
- **Rule:** 以下结论当前只能停在 uplift-readiness / execution-ready candidate 层：
  1. 某个 seam 已足够进入 uplift-readiness
  2. 某个 fallback / rollback floor 已足够支撑下一轮
  3. 某个 source-neutral state contract 已更稳
  4. 某个 stronger ingest seam 已更适合 candidate execution
- **Must not do:** 不得把这些写成 active DB/API baseline 已更新、endpoint meaning 已重写、或 runtime truth 已同步替换。


## 6. `cutover_vs_fact_owner_boundary_v3`

### RF-P3.3.11-011 — 哪些 final fact 当前仍继续以后端为准
- **Status:** Frozen candidate for this round
- **Rule:** 即使 fuller-cutover execution 前进一步，以下 final fact 当前仍必须继续以后端 / cloud fact layer 为准：
  1. 有效复习事实
  2. 今日目标完成
  3. 奖励结算 / 账本到账
  4. `check_in / learning_day / streak`

### RF-P3.3.11-012 — stronger ingest candidate 当前最大允许走到哪
- **Status:** Frozen candidate for this round
- **Rule:** 当前 stronger ingest candidate 最多只允许进入：
  1. **validated stronger-ingest candidate execution layer**
  2. 更清楚的 accept / reject / duplicate 规则
  3. 更明确的 precondition / postcondition / hold-reason / evidence ownership
  4. 与 fuller-cutover execution subset 直接绑定的最小 ingest contract

### RF-P3.3.11-013 — 哪些表达当前继续禁止
- **Status:** Frozen candidate for this round
- **Forbidden claims:**
  1. 本地已接管复习事实
  2. 本地已接管今日完成判定
  3. 本地结果已写回最终事实
  4. 奖励已按新主链路正式结算
  5. streak / learning day 已按本地 serving 续上
  6. 今日目标已按新 serving seam 自动推进
  7. completion 已改由本地 stronger path 裁定


## 7. `retained_anchor_narrowing_guardrail_v1`

### RF-P3.3.11-014 — rollback target 当前仍必须固定不动
- **Status:** Frozen candidate for this round
- **Rule:** rollback target 仍必须继续明确指向：
  - **`cloud_review_group_current_runtime_path`**

### RF-P3.3.11-015 — 哪些范围当前允许 very narrow 缩窄
- **Status:** Frozen candidate for this round
- **Rule:** 当前只允许 very narrow 缩窄：
  1. source-neutral helper / summary wording 的 group-only 耦合
  2. 首页 review helper / empty-state / no-review-state 的 retained-anchor-aware 表达
  3. rollback / fallback 说明中的历史性冗余 wording

### RF-P3.3.11-016 — 哪些 hold / escalate 条件必须继续保持
- **Status:** Frozen candidate for this round
- **Must-hold list:**
  1. 首页 `study_default` 被触碰
  2. active continuation 被 silent reroute
  3. `review_group` 被写成 fallback-only / 已退场 / 可清理
  4. local stronger path 影响 final fact / settlement truth
  5. 用户端出现“已切到本地规划 / 新主链路已生效 / `review_group` 已退场 / cutover 已完成 / uplift 已完成”
  6. 需要改 DB schema / API core semantics 才能继续
- **Must-escalate list:**
  1. 需要把 `review_group` 从 current owner + retained anchor 改成非 current owner
  2. 需要把 active continuation 改到 local path
  3. 需要把 active DB/API baseline uplift 写成当前生效
  4. 需要把 cleanup / old-path purge 绑进当前轮
  5. 需要用户可见模式切换 / cutover / exit / uplift absorbed 宣告


## 8. `phase5_writeback_order_v1`

### RF-P3.3.11-017 — 当前推荐 write-back 顺序
- **Status:** Frozen candidate for this round
- **Rule:** 当前推荐的最小回写顺序为：
  1. **Room 2 tech note**
  2. **Room 3 rules note**
  3. **Room 5 UI preflight**
  4. **Room 1 absorb / pin**
  5. 如获准，再进入 Room 4 fuller-cutover execution handoff

### RF-P3.3.11-018 — 哪些只能写成 execution-ready candidate
- **Status:** Frozen candidate for this round
- **Rule:** 当前只能写成 **execution-ready candidate** 的包括：
  1. continuity-adjacent serving-adapter family
  2. exit-candidate judgment prep
  3. uplift-readiness seam families
  4. stronger ingest validated-candidate layer
  5. source-neutral / retained-anchor-aware UI migration prep

### RF-P3.3.11-019 — 哪些可以被 Room 1 吸收到下一轮 Room4 handoff
- **Status:** Frozen candidate for this round
- **Rule:** 当前若要被 Room 1 吸收到下一轮 `R1 → R4` handoff，至少必须满足：
  1. no-overclaim
  2. rollback / hold / fallback / observability 已成套
  3. 不触碰首页 route / active continuation / final fact owner
  4. `review_group` 仍保持 current owner + retained anchor
  5. 不把 uplift-readiness 写成 active uplift


## 9. fact-copy / state guardrails

### 9.1 当前允许的表达方向
- fuller-cutover execution-ready subset
- exit-candidate
- uplift-readiness
- retained anchor
- still backend-owned final facts
- not current runtime truth
- not active uplift
- not true exit

### 9.2 当前禁止的 overclaim
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
> **Room 3 judgment：P3.3.11 当前允许 fuller-cutover 从 judgment 前进一步到 execution-ready subset，但这层只允许扩大到 ReviewPage + 首页 review 承接层的 continuity-adjacent serving-adapter family；首页默认主 route、active continuation source、final fact owner 与 full cutover 继续不进入当前执行层。**

### 11.2 exit-candidate 判定句
> **Room 3 judgment：`review_group` 当前可以进入 exit-candidate，但只允许进入 retained-anchor → exit-candidate 的资格判断与 very narrow 缩窄判断；它当前仍必须继续保持 current runtime owner + retained fallback anchor + compatibility anchor + deprecated candidate，不得被写成 true exit、fallback-only 或可清理。**

### 11.3 fact-boundary 判定句
> **Room 3 judgment：即使 fuller-cutover execution 前进一步，有效复习、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端为准；local stronger ingest path 最多只允许进入 validated stronger-candidate execution layer，不得升格为 fact owner。**

### 11.4 uplift-readiness 判定句
> **Room 3 judgment：P3.3.11 当前可以把少数与 fuller-cutover 直接绑定的 seam 升到 uplift-readiness，但 uplift-readiness 只说明“可进入 active baseline uplift 审查前的 execution-ready / readiness 层”，不说明“active DB/API baseline 已升级”。**

### 11.5 must-hold / must-escalate 判定句
> **Room 3 judgment：凡触碰首页 `study_default`、active continuation、`review_group` current owner posture、final fact / settlement truth、active DB/API baseline、或用户可见 overclaim 的情况，一律不得按“可带着走的 execution-ready 差异”处理；其中涉及 DB schema / API core semantics / cleanup / 用户可见 exit / uplift 宣告的，必须升级，不得在本轮内自行吸收。**

---

## 12. Room 3 最终一句话

> **P3.3.11 这轮，Room 3 支持把 fuller-cutover 从 judgment 推到 execution-ready 一小层，但这层仍然只回答“哪些 seam 现在配得上再前进一步、哪些 retained-anchor 范围可 very narrow 缩窄、哪些 seam 只到 uplift-readiness”，不是在回答“现在已经切完 / 退完 / 升完”。**
