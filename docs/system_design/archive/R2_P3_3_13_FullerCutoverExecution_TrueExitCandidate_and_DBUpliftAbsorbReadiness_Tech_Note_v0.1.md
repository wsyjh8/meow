# R2_P3_3_13_FullerCutoverExecution_TrueExitCandidate_and_DBUpliftAbsorbReadiness_Tech_Note_v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** fuller-cutover execution / true-exit-candidate / DB-API uplift-absorb-readiness preflight / ready for Room 1 review
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Round:** `P3.3.13 — Fuller-Cutover Execution / True-Exit-Candidate / DB-API Uplift-Absorb-Readiness Round`

---

## 0. 文档定位

本稿不是：
- Room 4 的执行单
- full cutover completed 宣告
- `review_group` true exit 公告
- active DB / API baseline uplift absorbed 完成宣告
- cleanup / old-path purge 方案书
- DB / API 主文档重写稿

本稿只做一件事：

> **从 Room 2 / CTO 视角，把 P3.3.13 收成一轮“fuller-cutover execution / true-exit-candidate / DB-API uplift-absorb-readiness”的技术预收口：明确当前哪一组 widened subset 现在真的够格进入更完整一拍 execution subset、`review_group` true-exit-candidate 当前能走到哪一步、哪些 DB/API seam 已进入 uplift-absorb-readiness-ready、哪些 retained-anchor 依赖允许 very narrow 缩窄，以及 rollback / hold / observability / write-back 的下一层硬红线。**

一句话：

> **P3.3.13 应进入 fuller-cutover execution / true-exit-candidate / uplift-absorb-readiness preflight；但当前只适合把 execution subset / candidate / readiness 条件写硬，不适合把 full cutover、true exit、active DB/API uplift absorbed、cleanup 或 final fact owner shift 写成已生效事实。**

---

## 1. 输入依据与采用口径

### 1.1 Governance / role basis
- `ORG_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.2`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_13_ScopePin_and_Handoff_Pack_v0.1.md`
- `Main_updated_2026-04-10_v33.md`
- `STATUS_updated_2026-04-10_v31.md`

### 1.3 Review basis for this round
- `BR-OPP-001_v0.2.14.md`
- `UI_SPEC_v0.3.4.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.12_Claude_res.md`

### 1.4 Room 2 采用口径
1. **本轮服从 Room 1 handoff 指定的 review basis。**
2. **当前 runtime active reality 仍以 Main / STATUS 已 pin 的 active versions 为准。**
3. 当前 active BR / UI 已升级到 `v0.2.14 / v0.3.4`；DB / API active baseline 继续保持 `v0.2.1`。
4. `P3.3.12` 已把 widened subset 推到 **absorb-candidate judgment / true-exit-gate judgment / uplift-absorb-judgment-ready** 层，但仍未发生 full cutover、`review_group` true exit、active DB/API uplift absorbed、final fact owner shift。
5. **No silent contract drift**：凡 execution-ready / candidate / readiness / runtime-truth 一旦被 Room 1 pin，后续执行与回写必须同步到 BR / UI / DB / API / test 证据层。

---

## 2. Room 2 总判断

### 2.1 本轮是否应该前进一步
Room 2 结论：

> **应该前进一步。**

但推进方式必须是：

> **Fuller-Cutover Execution / True-Exit-Candidate / DB-API Uplift-Absorb-Readiness Preflight**

而不是：

> **runtime owner shift completed / full cutover completed / `review_group` true exit / active DB-API uplift absorbed / cleanup started**

### 2.2 为什么现在值得进入这一轮
因为当前已经具备：
1. `P3.3.9` first-cutover 的 runtime 证据；
2. `P3.3.10` 的 fuller-cutover judgment / exit-gate / uplift-judgment artifacts；
3. `P3.3.11` 的 execution-ready / exit-candidate / uplift-readiness artifacts；
4. `P3.3.12` 的 absorb-candidate judgment / true-exit-gate judgment / uplift-absorb-judgment artifacts；
5. retained anchor / rollback / hold / observability 的成套护栏；
6. `review_group` still-dependent paths 与 transition 条件清单；
7. DB/API uplift-absorb-judgment seam families 的最小清单。

### 2.3 为什么仍不能直接进入 full cutover / true exit / uplift absorbed
因为当前仍同时成立：
1. ReviewPage current serving truth 仍大面积围绕 cloud `review_group`；
2. 首页 runtime 仍是 `home_word_entry = study_default`；
3. active continuation 仍未切到 local path；
4. final fact / settlement truth 仍以后端为准；
5. DB / API active baseline 仍是 `v0.2.1`；
6. `review_group` 仍未进入 true exit；
7. uplift-absorb-readiness 仍不是 uplift absorbed。

### 2.4 Room 2 一句话立场
> **P3.3.13 该收成“哪一组 widened subset 现在够格进入更完整一拍 execution、哪一组 `review_group` 依赖现在只够格进入 true-exit-candidate、哪一组 DB/API seam 现在只够格进入 uplift-absorb-readiness”的轮；不该收成“现在可以把 fuller cutover、true exit、uplift absorb、cleanup 一口气拉满”的执行轮。**

---

## 3. Q1 — `fuller_cutover_execution_subset_v2`

### 3.1 Room 2 结论
> **P3.3.13 当前最值得进入更完整一拍 execution subset 的，仍应留在 ReviewPage 与首页 review 承接层；并且只允许从 P3.3.12 absorb-candidate judgment，再推进到一个更完整但仍 very narrow 的 execution family。**

### 3.2 Room 2 推荐的 execution subset
当前最稳的 execution subset，只建议包含以下 5 层：

#### A. ReviewPage continuity-adjacent serving-adapter family（核心）
- 允许把 `P3.3.12` 里已进入 absorb-candidate judgment 的 ReviewPage continuity-adjacent family，推进到更完整一拍 execution subset；
- 允许执行范围扩大到 source-selection / serving-adapter / helper / summary / empty-state / completion 前置说明层之间的协同；
- 但仍只限于 ReviewPage 页面内部，不得越界成 active continuation source switch。

#### B. 首页 review helper / summary / no-review-state 的 retained-anchor-aware execution prep
- 允许把首页中与 review 承接相关的 helper / summary / no-review-state，从 judgment 提升到更完整一拍 execution prep；
- 但 **不触碰首页默认主 route**，也不做 planner-aware / auto-routing runtime。

#### C. rollback / hold / fallback neutral orchestration v2
- 允许把 rollback trigger、hold trigger、stop-condition、fallback messaging、failure isolation 再前进一步做 execution prep；
- 但 rollback target 仍固定指向 `cloud_review_group_current_runtime_path`。

#### D. stronger-ingest binding absorb-readiness prep
- 允许把 accept / reject / duplicate / progress-candidate / completion-candidate 的 binding，再前进一步推进到更稳的 absorb-readiness prep；
- 但只讨论 binding / ingest / orchestration，**不进入 final fact write**。

#### E. source-neutral state / helper / summary contract family v2
- 允许把 source-neutral / retained-anchor-aware 的 UI + helper + state contract，推进到更完整一拍 execution subset；
- 但不写成“当前主真相源已经切换”。

### 3.3 当前不推荐纳入 execution subset 的方向
以下内容都不建议纳入 P3.3.13 execution subset：
1. 首页默认主 route
2. active continuation source switch
3. final fact / settlement owner switch
4. `review_group` true exit
5. active DB/API baseline uplift absorbed
6. cleanup / old-path purge
7. user-visible mode switch / cutover 宣告

### 3.4 Room 2 的硬句
> **P3.3.13 可以判断 widened subset 是否更接近 fuller cutover，并推进到更完整一拍 execution subset；但这组 subset 仍只是 execution-ready / candidate / readiness family，不得被写成 current runtime truth 已整体切换。**

---

## 4. Q2 — `review_group_true_exit_candidate_v1`

### 4.1 Room 2 结论
> **`review_group` 当前可以从 true-exit-gate judgment 前进一步，但最多只允许推进到更硬的 true-exit-candidate；仍不允许进入 true exit，更不允许降成 fallback-only / historical-only。**

### 4.2 当前可接受的 true-exit-candidate 层
当前只建议把以下内容推进到 true-exit-candidate：

#### A. still-dependent paths 的更硬清单
以下路径当前仍必须继续显式依赖 `review_group`：
1. active continuation identity
2. completion gating
3. settlement trigger
4. rollback target
5. non-cutover / non-upgraded sessions baseline path
6. compatibility anchor / QA baseline reference

#### B. retained-anchor very narrow narrowing preparation
允许 very narrow 缩窄的，只能是：
1. source-neutral helper / summary wording 的 retained-anchor 依赖
2. 首页 review helper / no-review-state 的部分 retained-anchor-aware 表达
3. rollback / fallback 说明中的历史性冗余 wording

#### C. true-exit-candidate 的 simultaneous-precondition framing
P3.3.13 当前可前进一步写硬的，不是 true exit 本身，而是：
1. 哪些 contract 条件需要同时成立
2. 哪些 runtime 证据需要同时成立
3. 哪些 test / regression / rollback 证据需要同时成立
4. 哪些 doc / write-back / fallback note 需要同时成立

### 4.3 当前明确不能推进到的层
1. `review_group` current owner 身份删除
2. rollback target 改写
3. current visible owner identity 改写
4. active continuation 当前承接路径切换
5. completion / settlement explanation pathway 改写
6. old-path cleanup / purge

### 4.4 Room 2 的硬句
> **P3.3.13 当前允许的是“true-exit-candidate 更硬、更可执行”，不是“true exit 已开始”。凡把 `review_group` 写成 true exit、fallback-only、historical-only、可清理，均视为越界。**

---

## 5. Q3 — `db_api_uplift_absorb_readiness_v1`

### 5.1 Room 2 结论
> **P3.3.13 当前最值得前进一步的，是把 P3.3.12 的 uplift-absorb-judgment-ready seam families，推进到 uplift-absorb-readiness；但仍不能写成 active DB/API baseline uplift absorbed。**

### 5.2 当前推荐进入 uplift-absorb-readiness 的 seam families
只建议推进以下 5 组：

1. **serving source descriptor seam family**
2. **retained-anchor / fallback posture seam family**
3. **stronger-ingest path minimal seam family**
4. **rollback / hold / observability seam family**
5. **source-neutral state / helper / summary contract seam family**

### 5.3 当前必须继续停留在 marker / migration / rollback / hold 层的 seam
1. `review_group` true-exit seam
2. active continuation source switch seam
3. final fact owner shift seam
4. homepage route / planner-aware route seam
5. DB schema rewrite seam
6. API core semantics rewrite seam
7. cleanup / purge seam

### 5.4 Room 2 的正式边界
- 本轮允许前进一步的是 **readiness**，不是 **absorbed**；
- 允许前进一步的是 **candidate seam families**，不是 **active baseline**；
- 允许前进一步的是 **migration / rollback / hold / observability preparation**，不是 **schema / endpoint rewrite**。

### 5.5 Room 2 的硬句
> **P3.3.13 当前最多只允许把与 widened execution subset 直接绑定的一小组 DB/API seam 提升到 uplift-absorb-readiness；active `DB/API v0.2.1` 继续保持不变。**

---

## 6. Q4 — `cutover_vs_fact_owner_boundary_v5`

### 6.1 Room 2 结论
> **fuller-cutover execution 再前进一步后，stronger-ingest candidate 最多只能推进到 absorb-readiness-level ingest prep；仍不得跟着 serving seam 一起切到 final fact owner。**

### 6.2 当前继续必须以后端 / cloud fact layer 为准的最终事实
以下 5 组当前继续不得跟着 serving seam 一起切：
1. 有效复习事实
2. 今日目标完成
3. 奖励结算 / 账本到账
4. `check_in / learning_day / streak`
5. completion / 到账类主反馈

### 6.3 stronger-ingest 当前最多能走到哪
当前最多只允许推进到：
- absorb-readiness-level binding prep
- accept / reject / duplicate 更强 ingest judgment
- progress / completion-candidate 更稳的 orchestration
- observability / parity / rollback / hold 更完整一拍的 execution prep

### 6.4 当前仍继续禁止的动作
1. local ingest 直接改 ledger
2. local ingest 直接改 daily goal completion
3. local ingest 直接改 streak / learning day
4. local ingest 直接触发 final settlement
5. local completion-candidate 写成用户可见“已完成 / 已到账 / 已生效”

### 6.5 Room 2 的硬句
> **Serving seam advancement does not equal final fact owner advancement。P3.3.13 当前无论 widened subset 再怎么前进一步，都不能把后端 / cloud fact layer 的最终事实护栏一起带走。**

---

## 7. Q5 — `true_exit_candidate_narrowing_guardrail_v1`

### 7.1 Room 2 结论
> **P3.3.13 当前允许做的，只是 retained-anchor very narrow narrowing guardrail；rollback target 仍必须固定，stop-condition 仍必须保持硬挡板。**

### 7.2 当前允许 very narrow 缩窄的 retained-anchor 依赖
1. helper / summary / no-review-state 的部分 wording 依赖
2. source-neutral fallback / hold copy 的部分 retained-anchor aware 表达
3. QA / debug / internal evidence 中的历史描述噪音

### 7.3 当前仍必须固定不动的骨架
1. rollback target = `cloud_review_group_current_runtime_path`
2. current visible owner identity
3. retained fallback anchor identity
4. active continuation 当前承接路径
5. completion / settlement explanation pathway

### 7.4 必须继续保持的 stop-condition / hold-condition
1. 任何 current runtime truth 被偷切
2. 任何 `review_group` posture 被误写成 true exit / fallback-only / historical-only
3. 任何 stronger-ingest evidence 被误升格成 final fact owner
4. 任何 homepage route / planner-aware route 被提前切换
5. 任何 DB/API seam 被误写成 active uplift absorbed

### 7.5 Room 2 的硬句
> **P3.3.13 当前允许 very narrow 缩窄 retained-anchor 依赖，但 rollback target 与 current owner 解释骨架绝不能动。**

---

## 8. Q6 — `phase7_writeback_order_v1`

### 8.1 Room 2 结论
> **P3.3.13 仍必须维持“Room 2 → Room 3 → Room 5 → Room 1 →（若 Room 1 放行）Room 4 execution handoff”的写回顺序；execution-ready candidate / true-exit-candidate / uplift-absorb-readiness 与 runtime truth 必须继续分层。**

### 8.2 当前建议的最小写回顺序
1. Room 2 tech note：先写技术判断、execution subset、candidate / readiness 边界
2. Room 3 rules note：写业务语义、fact-copy guardrails、must-hold / must-escalate
3. Room 5 UI preflight：写页面 / 状态 / wording / fallback guidance
4. Room 1 absorb / pin：只吸收本轮允许进入主线程的 execution-ready candidate / true-exit-candidate / uplift-absorb-readiness
5. 若 Room 1 放行，再进入 `R1 → R4 P3.3.13 Execution Handoff`

### 8.3 本轮哪些只能写成 execution-ready candidate / true-exit-candidate / readiness
1. widened execution subset
2. true-exit-candidate
3. uplift-absorb-readiness seam families
4. stronger-ingest absorb-readiness prep
5. retained-anchor very narrow narrowing guardrail

### 8.4 本轮哪些仍不能升格为 runtime truth
1. full cutover completed
2. `review_group` true exit
3. active DB/API uplift absorbed
4. homepage route switch
5. active continuation source switch
6. final fact owner shift
7. cleanup / old-path purge

### 8.5 Room 2 的硬句
> **P3.3.13 的写回目标，是把“更完整一拍 execution / candidate / readiness”写硬；不是把 runtime truth 偷升级。**

---

## 9. 推荐进入层 / 推荐不进入层

### 9.1 推荐进入层
1. `fuller_cutover_execution_subset_v2`
2. `review_group_true_exit_candidate_v1`
3. `db_api_uplift_absorb_readiness_v1`
4. `cutover_vs_fact_owner_boundary_v5`
5. `true_exit_candidate_narrowing_guardrail_v1`
6. `phase7_writeback_order_v1`

### 9.2 推荐不进入层
1. full cutover completed
2. runtime owner shift completed
3. `review_group` true exit
4. active DB/API uplift absorbed
5. cleanup / old-path purge
6. homepage route / planner-aware runtime route
7. active continuation source switch
8. final fact owner shift
9. DB schema rewrite
10. API core semantics rewrite

---

## 10. Room 1 可 pin 的最小 execution-ready 合同集合

Room 2 当前建议 Room 1 若要继续推进，只 pin 以下最小集合：
1. **更完整一拍 execution subset 仍主要留在 ReviewPage + 首页 review 承接层**
2. **`review_group` 当前只进入 true-exit-candidate，不进入 true exit**
3. **DB/API 当前只进入 uplift-absorb-readiness，不进入 uplift absorbed**
4. **rollback target / current owner identity / active continuation / final fact owner 继续固定不动**
5. **Room 4 若被放行，只能进入 very narrow execution layer，不得默认升级成 full cutover / true exit / uplift absorbed / cleanup bundling**

---

## 11. Room 2 最终结论

> **P3.3.13 可以正式启动，但 Room 2 只支持它进入“更完整一拍的 fuller-cutover execution / true-exit-candidate / DB-API uplift-absorb-readiness preflight”。当前最稳的推进方式，仍然是继续把 execution subset、candidate、readiness 与 runtime truth 分开；一旦把它们绑成同一轮生效，就会立刻越界成 full cutover / true exit / uplift absorbed / cleanup bundling。**
