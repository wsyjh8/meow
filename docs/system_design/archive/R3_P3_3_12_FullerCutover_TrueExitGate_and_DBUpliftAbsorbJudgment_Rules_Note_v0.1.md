# R3_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_Rules_Note_v0.1

- **Owner:** Room 3
- **Project:** 背单词喵喵 App
- **Type:** rules note / fuller-cutover judgment / true-exit-gate / DB-API uplift-absorb judgment round
- **Status:** ready for Room 1 review
- **Date:** 2026-04-11
- **Role basis:** `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- **Runtime basis:** `Main_updated_2026-04-10_v32.md` + `STATUS_updated_2026-04-10_v30.md`
- **Direct upstream input:** `R1_P3_3_12_ScopePin_and_Handoff_Pack_v0.1.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 3 的业务规则视角，把 P3.3.12 当前轮需要回答的 fuller-cutover / true-exit-gate / DB-API uplift-absorb judgment 问题，收成一份可测试、可引用、可被 Room 1 判断是否 pin 的最小规则合同。**

本稿不是：
- 新 BR 主文档
- 新 DB / API 主文档
- 新 UI 主文档
- Room 4 执行单
- runtime owner shift 完成宣告
- `review_group` true exit 公告
- active DB / API baseline uplift absorbed 生效稿
- cleanup / old-path purge 方案书

一句话：

> **P3.3.12 是 fuller-cutover / true-exit-gate / uplift-absorb judgment round，不是 full cutover completed / true exit / uplift absorbed round。**

---

## 1. 输入依据

### 1.1 Governance / role basis
- `ORG_v0.3.1.md`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_12_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.3 Current runtime / review basis
- `BR-OPP-001_v0.2.13.md`
- `UI_SPEC_v0.3.3.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `Main_updated_2026-04-10_v32.md`
- `STATUS_updated_2026-04-10_v30.md`
- `P3.3.11_Claude_res.md`

---

## 2. Room 3 总判断

### 2.1 本轮是否应该前进一步
Room 3 结论：

> **应该前进一步。**

因为 P3.3.11 已经完成：
1. fuller-cutover execution-ready subset
2. `review_group` exit-candidate
3. DB/API uplift-readiness
4. stronger-ingest execution-ready binding prep
5. BR / UI 对上一轮结果的吸收基础

如果 P3.3.12 还不继续回答：
- 哪些 widened subset 已足够进入 fuller-cutover absorb judgment
- `review_group` 何时才具备 true-exit gate 的最低资格
- DB/API 哪些 seam 何时才具备 uplift-absorb judgment 资格

那么主线程会继续停在“execution-ready 已经具备，但再往前一步该怎么判断”这一层。

### 2.2 本轮不能直接写成什么
Room 3 同时明确：

> **P3.3.12 当前不能直接写成 `runtime owner shift completed`、`ReviewPage local-serving full runtime cutover completed`、`review_group` true exit 已生效、`active DB/API baseline uplift absorbed`、`cleanup`、`final fact owner shift`。**

### 2.3 Room 3 一句话立场
> **Room 3 支持 P3.3.12 进入 fuller-cutover / true-exit-gate / uplift-absorb judgment；但这轮只应把“哪些 widened subset 现在够资格进入更完整 cutover 判断、哪些条件现在够资格进入 true-exit gate、哪些 seam 现在够资格进入 uplift-absorb judgment、以及哪些 truth / fact / wording 仍绝不能动”写硬。**

---

## 3. `fuller_cutover_absorb_candidate_v1`

## 3.1 Room 3 结论
> **P3.3.12 当前允许前进一步，但只允许把 P3.3.11 的 execution-ready subset 提升到 absorb-candidate judgment；不允许把它直接写成 fuller cutover 已吸收、已生效。**

### RF-P3.3.12-001 — 当前允许进入 fuller-cutover absorb judgment 的 subset
- **Status:** Frozen candidate for this round
- **Rule:** 当前最稳的 absorb-candidate judgment subset，只允许围绕以下 widened family 展开：
  1. **ReviewPage continuity-adjacent serving-adapter family**
  2. **与其强绑定的 source-neutral helper / summary / empty-state / completion 前置说明层**
  3. **首页 review helper / summary / no-review-state 的 retained-anchor-aware contract**
  4. **rollback / hold / fallback 的中性 copy / state contract**
  5. **stronger-ingest execution-ready binding prep**
- **Canonical meaning:** 这表示“已足够进入更完整一拍的 cutover 判断”，不表示“这些 widened family 已被吸收到 runtime truth”。

### RF-P3.3.12-002 — 当前明确禁止扩大到
- **Status:** Frozen candidate for this round
- **Forbidden layer:**
  1. 首页默认主 route 切换
  2. active continuation source switch
  3. user-visible planner-aware route / auto-routing runtime
  4. `review_group` true exit
  5. final fact owner shift
  6. active DB/API baseline uplift absorbed
  7. cleanup / old-path purge
- **Why frozen candidate:** 这些一旦一起进入，本轮就不再是 judgment round，而会变成 silent runtime rewrite。

### RF-P3.3.12-003 — absorb-candidate judgment 不等于 absorb
- **Status:** Frozen candidate for this round
- **Rule:** 即使某个 widened subset 进入 absorb-candidate judgment，也只表示：
  - 已具备进入下一层 fuller-cutover absorb 审查的资格
  - 不表示当前已经 absorbed into runtime truth
- **Why frozen candidate:** `judgment-ready / absorb-candidate / absorbed` 必须继续分层。

### RF-P3.3.12-004 — blast radius 与 rollback complexity 当前必须显式纳入判断
- **Status:** Frozen candidate for this round
- **Rule:** P3.3.12 当前若要判断 widened subset 是否值得前进一步，必须同时显式考察：
  1. blast radius 是否仍局限在 ReviewPage + 首页 review 承接层
  2. rollback complexity 是否仍可由当前 retained anchor / fallback / hold 结构承受
  3. widened subset 是否会误伤 active continuation / final fact owner / main route
- **Why frozen candidate:** 本轮的判断重点，已经不只是“可不可以”，而是“代价是否仍在 very narrow preflight 可承受范围内”。

---

## 4. `review_group_true_exit_gate_v1`

## 4.1 Room 3 结论
> **`review_group` 当前仍不能进入 true exit；P3.3.12 最多只允许把它推进到 true-exit-gate judgment。**

### RF-P3.3.12-005 — `review_group` 当前仍必须保持四层并存
- **Status:** Frozen candidate for this round
- **Rule:** 在 P3.3.12 当前轮，`review_group` 仍必须继续保持：
  1. **current runtime serving owner**
  2. **retained fallback anchor**
  3. **compatibility anchor**
  4. **deprecated candidate**
- **Must not do:** 不得把它写成 true exit、fallback-only、historical-only、或可直接清理。
- **Why frozen candidate:** 当前还没有任何条件允许它脱离 current owner 身份。

### RF-P3.3.12-006 — 当前哪些条件可以进入 true-exit gate judgment
- **Status:** Frozen candidate for this round
- **Rule:** 当前只允许把以下内容推进到 **true-exit-gate judgment**：
  1. **contract 条件**：fuller-cutover absorb-candidate、fact-owner boundary v4、uplift-absorb judgment、phase6 writeback order 是否已形成下一层最小合同
  2. **runtime 条件**：哪些 still-dependent paths 是否已有清晰替代路径
  3. **test 条件**：更完整一拍 widened subset 的 regression / rollback / hold / observability 是否持续稳定
  4. **doc 条件**：BR / UI / DB / API / TEST 的 exit 影响范围、fallback target、no-overclaim 边界是否已同步
  5. **fallback 条件**：rollback target 是否仍安全、fallback scope 是否仍可解释
- **Canonical meaning:** 当前只判断“够不够资格进入 true-exit gate”，不判断“现在就 true exit”。

### RF-P3.3.12-007 — 哪些 still-dependent paths 当前仍阻止 `review_group` 进入 true exit
- **Status:** Frozen candidate for this round
- **Rule:** 只要以下任一仍未被清晰替代，`review_group` 就不得进入 true exit：
  1. active continuation identity
  2. completion gating
  3. settlement trigger
  4. rollback target
  5. non-cutover / non-upgraded sessions baseline path
  6. compatibility anchor / QA baseline reference
- **Why frozen candidate:** 这些都是 current owner 身份的硬依赖。

### RF-P3.3.12-008 — true-exit gate judgment ≠ true exit
- **Status:** Frozen candidate for this round
- **Rule:** 即使上述条件逐步齐备，也只代表：
  - 可以讨论是否进入 true-exit gate
  - 不代表本轮已开始 true exit，更不代表可以 cleanup
- **Why frozen candidate:** 这是本轮最容易被误写错的点。

### RF-P3.3.12-009 — retained anchor 哪些未来才允许继续缩窄
- **Status:** Frozen candidate for this round
- **Rule:** 当前只允许判断 future-narrowable scope；真正可继续缩窄 retained anchor 的前提，至少必须先满足：
  1. rollback target 有可替代且可验证的新安全目标
  2. active continuation 已有稳定替代 contract
  3. completion gating / settlement trigger 已有不依赖 `review_group` 的清晰解释通路
  4. no-overclaim / no-cleanup 边界已被所有下游文档同步
- **Must not do:** 本轮不得提前改 rollback target，不得提前改 current owner posture。
- **Why frozen candidate:** 先判断 future 条件，不是现在就缩。

---

## 5. `db_api_uplift_absorb_judgment_v1`

## 5.1 Room 3 结论
> **从规则层看，本轮可以开始判断哪些 seam 已经够资格进入 uplift-absorb judgment；但 uplift-absorb judgment 仍不是 active uplift absorbed。**

### RF-P3.3.12-010 — 哪些 seam 当前可以进入 uplift-absorb judgment
- **Status:** Frozen candidate for this round
- **Rule:** 当前最多只允许以下与 fuller-cutover widened subset 直接绑定的 seam families 进入 uplift-absorb judgment：
  1. serving source descriptor seam
  2. retained-anchor / fallback posture seam
  3. stronger-ingest path minimal seam
  4. rollback / hold / observability seam
  5. source-neutral state / helper / summary contract seam
- **Canonical meaning:** 这些 seam 可以被判断“是否具备进入 uplift-absorb 的资格”，不表示已经 absorbed。

### RF-P3.3.12-011 — 哪些仍只能停留在 marker / migration / rollback / hold 层
- **Status:** Frozen candidate for this round
- **Rule:** 当前仍只能停留在 marker / migration / rollback / hold 层的包括：
  1. `review_group` true-exit 相关 seam
  2. active continuation source switch 相关 seam
  3. final fact owner shift 相关 seam
  4. homepage route / planner-aware route 相关 seam
  5. DB schema rewrite / API core semantics rewrite 相关 seam
- **Why frozen candidate:** 这些一旦越界，就不再是 uplift-absorb judgment，而会直接变成 major rewrite judgment。

### RF-P3.3.12-012 — 哪些结论当前只能算 uplift-absorb judgment，不得升格为 runtime truth
- **Status:** Frozen candidate for this round
- **Rule:** 以下结论当前只能停在 uplift-absorb judgment 层：
  1. 某个 seam 已足够讨论 absorb
  2. 某个 migration / rollback / hold floor 已足够支撑下一轮
  3. 某个 source-neutral contract 已足够稳
  4. 某个 stronger-ingest seam 已足够进入 absorb 审查
- **Must not do:** 不得把这些写成：
  - active DB/API baseline 已升级
  - endpoint meaning 已重写
  - runtime truth 已同步替换
  - 新基线已吸收到运行态
- **Why frozen candidate:** absorbed judgment 与 absorbed reality 必须继续分层。

---

## 6. `cutover_vs_fact_owner_boundary_v4`

## 6.1 Room 3 结论
> **本轮允许 stronger-ingest candidate 再前进一步到 absorb-judgment-level candidate；但 final fact owner 当前仍绝不能动。**

### RF-P3.3.12-013 — 哪些 final fact 当前仍继续以后端为准
- **Status:** Frozen candidate for this round
- **Rule:** 即使更完整一拍 fuller cutover judgment 前进一步，以下 final fact 当前仍必须继续以后端 / cloud fact layer 为准：
  1. 有效复习事实
  2. 今日目标完成
  3. 奖励结算 / 账本到账
  4. `check_in / learning_day / streak`
  5. completion / 到账类主反馈
- **Must not do:** 不得把 local stronger-ingest absorb-candidate 写成这些最终事实可由本地裁定。

### RF-P3.3.12-014 — stronger-ingest candidate 当前最大允许走到哪
- **Status:** Frozen candidate for this round
- **Rule:** 当前 stronger-ingest candidate 最多只允许进入：
  1. **absorb-judgment-level stronger candidate**
  2. 更清楚的 accept / reject / duplicate / progress-candidate / completion-candidate 规则
  3. 更明确的 precondition / postcondition / hold-reason / evidence ownership
  4. 与 widened subset 直接绑定的最小 ingest contract
- **Current forbidden layer:**
  1. 直接改 ledger
  2. 直接改 daily goal final state
  3. 直接改 streak / learning_day 最终事实
  4. 直接替代 settlement owner
- **Why frozen candidate:** 更强的 judgment-level candidate ≠ final fact owner shift。

### RF-P3.3.12-015 — 哪些 wording / state 一旦出现就属于 overclaim
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
- **Why frozen candidate:** 这些会把 judgment / candidate / readiness 误写成 runtime truth。

---

## 7. `exit_candidate_to_true_exit_transition_v1`

## 7.1 Room 3 结论
> **本轮允许判断 exit-candidate → true-exit-gate 的最小条件，但不允许进入 true exit transition。**

### RF-P3.3.12-016 — 当前仍必须固定不动的项
- **Status:** Frozen candidate for this round
- **Rule:** 在 P3.3.12 当前轮，以下项仍必须继续固定不动：
  1. rollback target = `cloud_review_group_current_runtime_path`
  2. current visible owner 身份
  3. retained fallback anchor 身份
  4. active continuation 当前承接路径
  5. completion gating / settlement trigger 的解释通路
- **Why frozen candidate:** 这些是 true-exit gate judgment 之前不能动的硬基座。

### RF-P3.3.12-017 — 哪些 future change 现在才允许被讨论
- **Status:** Frozen candidate for this round
- **Rule:** 当前只允许讨论：
  1. rollback target 何时才可能变动
  2. fallback scope 何时才可能缩窄
  3. `review_group` 何时才可能从 current owner + retained anchor 过渡到非 current owner
  4. 哪些 docs / QA / UI copy 需要先脱离 group-only dependency
- **Must not do:** 这些当前都不能被写成已经发生。
- **Why frozen candidate:** 当前只是 transition condition judgment，不是 transition execution。

---

## 8. `phase6_writeback_order_v1`

## 8.1 Room 3 结论
> **本轮若要继续推进，必须把 judgment、candidate、runtime truth 三层的回写顺序继续写硬；否则极易把“更接近 absorbed / true exit”误写成“已 absorbed / 已 true exit”。**

### RF-P3.3.12-018 — 当前推荐 write-back 顺序
- **Status:** Frozen candidate for this round
- **Rule:** 当前推荐的最小回写顺序为：
  1. **Room 2 tech note**
  2. **Room 3 rules note**
  3. **Room 5 UI preflight**
  4. **Room 1 absorb / pin**
  5. 如获准，再进入 Room 4 更完整 cutover judgment / execution handoff
- **Why frozen candidate:** 先写硬 judgment 护栏，再讨论是否值得进一步执行。

### RF-P3.3.12-019 — 哪些只能写成 judgment，哪些可以写成 execution-ready candidate
- **Status:** Frozen candidate for this round
- **Rule:** 当前只能写成 **judgment** 的包括：
  1. fuller-cutover absorb candidate
  2. true-exit-gate
  3. uplift-absorb judgment
  4. exit-candidate → true-exit transition 条件

  当前最多只允许写成 **execution-ready candidate** 的包括：
  1. widened subset 的延续层
  2. stronger-ingest absorb-candidate binding prep
  3. source-neutral / retained-anchor-aware UI migration prep
  4. rollback / hold / observability floor
- **Current forbidden layer:** 不得写成 full cutover completed、`review_group` true exit、active DB/API uplift absorbed、final fact owner shift、cleanup 已生效。

### RF-P3.3.12-020 — 哪些可以被 Room 1 吸收到下一轮 Room4 handoff
- **Status:** Frozen candidate for this round
- **Rule:** 当前若要被 Room 1 吸收到下一轮 `R1 → R4` handoff，至少必须满足：
  1. no-overclaim
  2. rollback / hold / fallback / observability 已成套
  3. 不触碰首页 route / active continuation / final fact owner
  4. `review_group` 仍保持 current owner + retained anchor
  5. 不把 uplift-absorb judgment 写成 active uplift
- **Why frozen candidate:** 这是当前 judgment 进入下一层执行判断的最低治理门槛。

---

## 9. must-hold / must-escalate

### 9.1 must-hold
以下任一出现，Room 3 判断必须 hold：
1. 首页 `study_default` 被改动
2. active continuation 被 silent reroute
3. `review_group` 被写成 true exit / 已退场 / 可清理
4. local stronger path 影响 final fact / settlement truth
5. 用户端出现“已切到本地规划 / 新主链路已生效 / `review_group` 已退场 / cutover 已完成 / uplift 已完成”
6. fuller-cutover / true-exit-gate / uplift-absorb judgment 被误写成 runtime truth

### 9.2 must-escalate
以下任一出现，Room 3 判断必须 escalate 给 Room 1 / Room 2：
1. 需要改 DB schema
2. 需要改 API core semantics
3. 需要改 reward / settlement owner
4. 需要把 `review_group` 从 current owner + retained anchor 改成非 current owner
5. 需要把 active continuation 改到 local path
6. 需要把 active DB/API baseline uplift 写成当前生效
7. 需要用户可见模式切换 / true exit / uplift absorbed / cleanup 宣告
8. 需要把 cleanup / old-path purge 绑进当前轮

---

## 10. fact-copy / state guardrails

### 10.1 当前允许的表达方向
当前治理层允许的表达方向：
- fuller-cutover absorb judgment
- true-exit-gate judgment
- uplift-absorb judgment
- retained anchor
- true-exit candidate
- still backend-owned final facts
- not current runtime truth
- not active uplift
- not true exit

### 10.2 当前禁止的 overclaim
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

## 11. 当前继续保持 Pending

1. full cutover completed
2. runtime owner shift completed
3. `review_group` true exit 生效
4. active DB/API baseline uplift absorbed 生效
5. cleanup / old-path purge
6. homepage route / planner-aware runtime route
7. active continuation source switch
8. auto-routing runtime
9. unified planner / planner merge
10. final fact owner shift
11. DB schema rewrite
12. API core semantics rewrite
13. 用户可见 owner-shift / cutover / exit / uplift absorbed 宣告

---

## 12. 可直接给 Room 1 的判定句

### 12.1 fuller-cutover judgment 判定句
> **Room 3 judgment：P3.3.12 当前允许把 P3.3.11 的 widened execution-ready subset 提升到 fuller-cutover absorb judgment，但这层仍只允许停在 ReviewPage + 首页 review 承接层的 widened family；首页默认主 route、active continuation source、final fact owner 与 full cutover 继续不进入当前判断层。**

### 12.2 true-exit-gate 判定句
> **Room 3 judgment：`review_group` 当前可以进入 true-exit-gate judgment，但只允许进入 retained-anchor → true-exit-gate 的资格判断；它当前仍必须继续保持 current runtime owner + retained fallback anchor + compatibility anchor + deprecated candidate，不得被写成 true exit、fallback-only 或可清理。**

### 12.3 fact-boundary 判定句
> **Room 3 judgment：即使 fuller-cutover judgment 前进一步，有效复习、今日目标完成、奖励结算 / 账本到账、`check_in / learning_day / streak` 当前仍必须以后端为准；local stronger-ingest path 最多只允许进入 absorb-judgment-level candidate，不得升格为 fact owner。**

### 12.4 uplift-absorb judgment 判定句
> **Room 3 judgment：P3.3.12 当前可以把少数与 fuller-cutover 直接绑定的 seam 升到 uplift-absorb judgment，但 uplift-absorb judgment 只说明“可进入 active baseline uplift absorbed 审查前的 judgment 层”，不说明“active DB/API baseline 已升级”。**

### 12.5 must-hold / must-escalate 判定句
> **Room 3 judgment：凡触碰首页 `study_default`、active continuation、`review_group` current owner posture、final fact / settlement truth、active DB/API baseline、或用户可见 overclaim 的情况，一律不得按“可带着走的 fuller-cutover / true-exit / uplift-absorb judgment 差异”处理；其中涉及 DB schema / API core semantics / settlement owner / cleanup / 用户可见 true exit / uplift 宣告的，必须升级，不得在本轮内自行吸收。**

---

## 13. Room 3 最终一句话

> **P3.3.12 这轮，Room 3 支持把 P3.3.11 的 execution-ready subset 再往前推到 fuller-cutover / true-exit-gate / uplift-absorb judgment；但这轮仍然只是在回答“哪些 widened family 现在配得上进入更完整判断、哪些条件现在配得上进入 true-exit gate、哪些 seam 现在配得上进入 uplift-absorb judgment”，不是在回答“现在已经切完 / 退完 / 升完”。**
