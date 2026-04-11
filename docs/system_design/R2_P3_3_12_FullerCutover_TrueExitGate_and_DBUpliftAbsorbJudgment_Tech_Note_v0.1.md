# R2_P3_3_12_FullerCutover_TrueExitGate_and_DBUpliftAbsorbJudgment_Tech_Note_v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** fuller-cutover / true-exit-gate / DB-API uplift-absorb judgment preflight / ready for Room 1 review
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Round:** `P3.3.12 — Fuller-Cutover / True-Exit-Gate / DB-API Uplift-Absorb Judgment Round`

---

## 0. 文档定位

本稿不是：
- Room 4 的执行单
- runtime owner shift 完成宣告
- `review_group` true exit 公告
- active DB / API baseline uplift absorbed 完成宣告
- cleanup / old-path purge 方案书
- DB 主文档 / API 主文档重写稿

本稿只做一件事：

> **从 Room 2 / CTO 视角，把 P3.3.12 收成一轮 “fuller-cutover / true-exit-gate / DB-API uplift-absorb judgment” 的技术预收口：明确当前哪一组 widened subset 已够格进入更完整一拍的 fuller-cutover absorb judgment、`review_group` 距离 true-exit gate 还缺什么、哪些 DB/API seam 已进入 uplift-absorb-judgment-ready、以及 retained-anchor / rollback / hold / fact-owner boundary / write-back 的下一层硬红线。**

一句话：

> **P3.3.12 应进入 fuller-cutover / true-exit-gate / uplift-absorb judgment preflight；但当前只适合把“更接近下一层”的资格条件写硬，不适合把 full cutover、true exit、active DB/API uplift absorbed、cleanup 或 final fact owner shift 写成已生效事实。**

---

## 1. 输入依据与采用口径

### 1.1 Governance / role basis
- `ORG_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.2`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_12_ScopePin_and_Handoff_Pack_v0.1.md`
- `Main_updated_2026-04-10_v32.md`
- `STATUS_updated_2026-04-10_v30.md`

### 1.3 Review basis for this round
- `BR-OPP-001_v0.2.13.md`
- `UI_SPEC_v0.3.3.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.11_Claude_res.md`

### 1.4 Room 2 采用口径
1. **本轮服从 Room 1 handoff 指定的 review basis。**
2. **当前 runtime active reality 仍以 Main / STATUS 已 pin 的 active versions 为准。**
3. 当前 active BR / UI 已升级到 `v0.2.13 / v0.3.3`；DB / API active baseline 继续保持 `v0.2.1`。
4. `P3.3.11` 已把 widened subset 推到 **execution-ready candidate** 层，但仍未修改 runtime 主链路、未改 DB schema、未改 API core semantics、未发生 `review_group` true exit、未发生 active DB/API uplift absorbed。
5. **No silent contract drift**：凡 judgment-ready / execution-ready / runtime-truth 一旦被 Room 1 pin，后续执行与回写必须同步到 BR / UI / DB / API / test 证据层。

---

## 2. Room 2 总判断

### 2.1 本轮是否应该前进一步
Room 2 结论：

> **应该前进一步。**

但推进方式必须是：

> **Fuller-Cutover / True-Exit-Gate / DB-API Uplift-Absorb Judgment Preflight**

而不是：

> **runtime owner shift completed / full cutover completed / `review_group` true exit / active DB-API uplift absorbed / cleanup started**

### 2.2 为什么现在值得进入这一轮 judgment
因为当前已经具备：
1. `P3.3.9` 的 first-cutover runtime 证据；
2. `P3.3.10` 的 fuller-cutover / exit-gate / uplift judgment artifacts；
3. `P3.3.11` 的 execution-ready candidate artifacts；
4. retained anchor / rollback / hold / observability 成套证据；
5. `review_group` exit-candidate 的前置条件与 still-dependent paths 清单；
6. DB/API uplift-readiness seam families 的最小清单；
7. BR / UI 已完成 `P3.3.11` 结果的主文档候选回写。

### 2.3 为什么仍不能直接进入 full cutover / true exit / uplift absorbed
因为当前仍同时成立：
1. ReviewPage current serving truth 仍大面积围绕 cloud `review_group`；
2. 首页 runtime 仍是 `home_word_entry = study_default`；
3. active continuation 仍未切到 local path；
4. final fact / settlement truth 仍以后端为准；
5. DB / API active baseline 仍是 `v0.2.1`；
6. `review_group` 仍未进入 true exit；
7. uplift-readiness 仍不是 uplift absorbed。

### 2.4 Room 2 一句话立场
> **P3.3.12 该收成“判断谁已经够格进入下一拍”的轮；不该收成“现在可以把 fuller cutover、true exit、uplift absorb、cleanup 一口气拉满”的执行轮。**

---

## 3. Q1 — `fuller_cutover_absorb_candidate_v1`

### 3.1 Room 2 结论
> **P3.3.12 当前最值得进入 fuller-cutover absorb judgment 的，仍应留在 ReviewPage 与首页 review 承接层；并且只允许从 P3.3.11 的 execution-ready subset，推进到一个更完整但仍 very narrow 的 absorb-candidate family。**

### 3.2 Room 2 推荐的 absorb-candidate subset
当前最稳的 absorb-candidate subset，只建议包含以下 5 层：

#### A. ReviewPage continuity-adjacent serving-adapter family（核心）
- 在 `P3.3.11` execution-ready subset 之上，
- 允许把 **ReviewPage 内部 source-selection / adapter / helper / summary / empty-state / completion 前置说明** 作为一组整体来判断是否已具备更完整一拍的 absorb 资格；
- 但仍然只限于 ReviewPage 页面内部。

#### B. 首页 review helper / summary / no-review-state 的 retained-anchor-aware prep
- 允许把首页中与 review 承接相关的 helper / summary / no-review-state，一并纳入 absorb judgment；
- 但 **不触碰首页默认主 route**，也不做 planner-aware / auto-routing。

#### C. rollback / hold / fallback neutral orchestration
- 允许判断 widened subset 若再前进一步，rollback complexity / stop-condition / blast radius 是否仍可控；
- 但 rollback target 当前仍固定指向 `cloud_review_group_current_runtime_path`。

#### D. stronger-ingest binding absorb-candidate prep
- 允许把 accept / reject / duplicate / progress-candidate / completion-candidate 的 binding 稳定性纳入 absorb judgment；
- 但只讨论 binding 与 orchestration，**不进入 final fact write**。

#### E. source-neutral state / helper / summary contract family
- 允许把 source-neutral / retained-anchor-aware 的 UI + helper + state contract 作为一组判断；
- 但不写成“当前主真相源已经切换”。

### 3.3 当前不推荐纳入 fuller-cutover absorb judgment 的方向
以下内容都不建议纳入 P3.3.12 absorb-candidate subset：
1. 首页默认主 route
2. active continuation source switch
3. final fact / settlement owner switch
4. `review_group` true exit
5. active DB/API baseline uplift absorbed
6. cleanup / old-path purge
7. user-visible mode switch / cutover 宣告

### 3.4 Room 2 的硬句
> **P3.3.12 可以判断 widened subset 是否更接近 fuller cutover；但这组 subset 仍必须留在 ReviewPage 与首页 review 承接层，不得越过到首页主路由、active continuation 与最终事实。**

---

## 4. Q2 — `review_group_true_exit_gate_v1`

### 4.1 Room 2 结论
> **P3.3.12 可以正式进入 true-exit-gate judgment；但当前结论应是“开始判断 true-exit 资格”，而不是“现在已具备 true exit 条件”。**

### 4.2 `review_group` 距离 true exit 仍缺的条件
当前至少还缺以下 7 类条件：

1. **replacement path completeness**
   - widened subset 覆盖到的当前 owner 解释层，必须存在可替代且可验证的新 path；
   - 当前仍未证明全量 replacement path 完整成立。

2. **active continuation independence**
   - active continuation 当前仍是 immobile 项；
   - 若 continuation 不能独立保持不变或单独迁移，就不具备 true-exit gate 资格。

3. **completion / settlement trigger decoupling**
   - 当前 completion gating / settlement trigger 仍依赖 `review_group` 解释通路；
   - 若未证明可替代，不得进入 true exit。

4. **rollback target replacement readiness**
   - 当前 rollback target 仍固定为 `cloud_review_group_current_runtime_path`；
   - 在 alternative rollback target 未被证明前，不得进入 true exit。

5. **compatibility anchor retirement readiness**
   - 当前 compatibility anchor 仍承担 baseline compare / QA / fallback reference；
   - 若这些 reference 仍需它，就不能进入 true exit。

6. **non-cutover baseline path safety**
   - non-cutover / non-upgraded sessions 的 baseline path 仍必须稳定存在；
   - 若该 path 仍依赖 `review_group`，true-exit gate 不能通过。

7. **doc + test + runtime evidence completeness**
   - true exit 不是只看代码或文档一边；
   - 必须同时具备 contract、runtime evidence、回归测试、rollback 解释与 write-back readiness。

### 4.3 当前允许进入 true-exit-gate judgment 的内容
本轮最多只建议推进以下 5 类：
1. still-dependent paths inventory 是否完整
2. replacement readiness matrix 是否齐
3. rollback target / fallback scope 是否可未来变动
4. retained-anchor → true-exit 的资格条件是否成套
5. no-cleanup / no-overclaim assertions 是否足够硬

### 4.4 当前仍不得写成 true exit 的内容
1. `review_group` 已退出运行态
2. `review_group` 已降为 fallback-only
3. `review_group` 当前已不再是 current owner
4. 旧 path 已可清理
5. rollback target 可直接换掉

### 4.5 Room 2 的硬句
> **P3.3.12 可以判断 `review_group` 何时才配进入 true-exit gate；但在 active continuation、completion / settlement trigger、rollback target 与 compatibility anchor 仍未替换前，当前绝不能把它写成 true exit。**

---

## 5. Q3 — `db_api_uplift_absorb_judgment_v1`

### 5.1 Room 2 结论
> **P3.3.12 可以把少数 DB/API seam 从 uplift-readiness 推到 uplift-absorb-judgment-ready；但这仍只是“有资格进入吸收判断”，不是 active baseline 已 uplift absorbed。**

### 5.2 当前最适合进入 uplift-absorb judgment 的 seam families
当前最多只建议以下 4 组进入 judgment-ready：

1. **reviewServingSourceDescriptor seam**
   - 因为它直接绑定 widened serving subset；
   - 当前已具备从 readiness 走到 absorb judgment 的必要条件。

2. **retainedAnchorFallbackPosture seam**
   - 因为 true-exit gate 的判断离不开它；
   - 当前可进入 absorb judgment，但不进入 absorbed。

3. **rollbackHoldObservability seam**
   - 因为下一层若要前进，必须先证明 hold / rollback / stop-condition / observability 的 floor 足够稳；
   - 当前可进入 absorb judgment。

4. **sourceNeutralStateHelperSummaryContract seam**
   - 因为 widened subset 的 UI / helper / state contract 已被执行就绪层验证；
   - 当前可进入 absorb judgment。

### 5.3 当前仍只能停留在 marker / migration / rollback / hold 层的内容
以下当前仍不建议进入 absorb judgment-ready：
1. 任何 `review_group` true-exit declarations 相关 seam
2. active continuation source switch 相关 seam
3. final fact / settlement owner fields / payloads
4. homepage route / planner-aware routing 相关 seam
5. cleanup / old-path purge 相关 seam
6. 任何需要 schema rewrite / history backfill / compatibility patch 的动作
7. 任何改变 endpoint core semantics 的动作

### 5.4 何时才允许 Room 1 讨论 active DB/API uplift absorbed
至少同时满足以下 5 条时，Room 1 才可讨论：
1. absorb-candidate subset 已有下一层 execution 证据
2. true-exit gate 不再被关键 still-dependent paths 阻挡
3. rollback / hold / observability floor 已可解释且可验证
4. BR / UI / DB / API / TEST write-back ready
5. 无需 schema rewrite / API core semantics rewrite 才能维持新层级

### 5.5 Room 2 的硬句
> **P3.3.12 允许判断哪些 seams 已够格进入 uplift-absorb judgment；但不允许把 judgment-ready 写成 active DB/API uplift 已完成。**

---

## 6. Q4 — `cutover_vs_fact_owner_boundary_v4`

### 6.1 Room 2 结论
> **更完整一拍 fuller-cutover judgment 后，stronger-ingest candidate 最多只允许推进到 absorb-judgment candidate layer；final fact owner 继续不得跟着切。**

### 6.2 当前允许前进一步的 stronger-ingest candidate 上限
只建议前进到以下层级：
1. accept / reject / duplicate 绑定更稳
2. progress-candidate / completion-candidate 前后置条件更清晰
3. hold-reason / rollback ownership 更显式
4. no-final-fact-owner-switch assertion 更稳定
5. minimal ingest binding 与 absorb-candidate subset 对齐

### 6.3 当前仍绝不能跟着 serving seam 一起切的结果
以下都继续不得跟着 serving seam 一起切：
1. effective review final fact
2. daily goal progress / completion owner
3. reward settlement / ledger arrival owner
4. check_in / learning_day / streak owner
5. completion-arrival 主反馈的最终真相源

### 6.4 当前必须继续禁止的表达
继续禁止：
- “本地已确认完成”
- “奖励已到账”
- “今日目标已达成”
- “连续学习已更新”
- “复习事实已切到本地”
- “新主链路已生效”
- “`review_group` 已退场”
- “uplift 已完成”

### 6.5 Room 2 的硬句
> **serving seam 可以更接近下一拍，stronger-ingest binding 可以更稳；但 final fact owner 当前仍必须以后端为准。**

---

## 7. Q5 — `exit_candidate_to_true_exit_transition_v1`

### 7.1 Room 2 结论
> **P3.3.12 可以讨论从 exit-candidate 到 true-exit-gate 的过渡；但当前只适合写硬 transition 条件，不适合动 retained anchor 的 owner / rollback / completion / settlement 骨架。**

### 7.2 当前最小 transition 条件
当前若要从 exit-candidate 走到 true-exit-gate，至少需要：
1. current owner 解释路径存在 replacement plan
2. active continuation 保持独立或单开迁移轮
3. rollback target 存在 future-replaceable proof
4. completion gating / settlement trigger 的替代解释路径存在
5. compatibility anchor / baseline compare path 可迁移
6. no-cleanup assertions 继续成立
7. regression / runtime evidence / docs readiness 成套

### 7.3 retained anchor 哪些未来才允许继续缩窄
以下只有在 true-exit gate judgment 明确通过后，未来才允许继续缩窄：
1. current runtime serving owner 身份
2. retained fallback anchor 身份
3. rollback target 主句
4. active continuation identity
5. current completion gating
6. current settlement trigger
7. compatibility anchor / non-cutover baseline path

### 7.4 rollback target / fallback scope 何时才允许变动
只有当同时满足以下条件时，才允许讨论：
1. replacement path 有 runtime evidence
2. stop-condition / rollback path 可解释
3. non-cutover baseline path 不再依赖当前 target
4. Room 1 单独 pin true-exit gate 的下一拍执行

### 7.5 Room 2 的硬句
> **P3.3.12 当前只适合把 exit-candidate → true-exit-gate 的过渡条件写硬，不适合把 retained anchor 改成可移动骨架。**

---

## 8. Q6 — `phase6_writeback_order_v1`

### 8.1 Room 2 结论
> **P3.3.12 的回写顺序必须比 P3.3.11 更强调 “judgment / execution-ready / runtime truth” 三层分离；true-exit 与 uplift-absorb 仍必须最后单开。**

### 8.2 Room 2 推荐的 write-back 次序
1. **先写 Room 2 tech note**
   - fuller-cutover absorb judgment / true-exit-gate / uplift-absorb judgment / fact-boundary / transition 红线

2. **再写 Room 3 rules note**
   - true-exit gate 规则、fact-owner boundary、must-hold / must-escalate、overclaim guardrails

3. **再写 Room 5 UI preflight**
   - runtime-truth guardrails / true-exit-gate UI guidance / uplift-absorb judgment UI guidance / retained-anchor-aware copy

4. **Room 1 再判断是否形成下一拍的 Room 4 execution handoff**
   - 只形成 very narrow fuller-cutover / true-exit-gate / uplift-absorb judgment handoff
   - 不形成 full cutover / true exit / uplift absorbed / cleanup

5. **DB/API write-back 只进入 judgment-ready / candidate 层**
   - 先写 seam families / marker / rollback / hold / migration / observability
   - 不改 active baseline

6. **runtime baseline update 最后再单开判断**
   - 只有当 Room 1 单独 pin，且下一层执行证据具备，才可讨论 active uplift / true exit / cleanup bundling

### 8.3 哪些只能写成 judgment / candidate
1. 哪组 widened subset 已够格进入 absorb judgment
2. `review_group` 哪些内容已够格进入 true-exit gate judgment
3. 哪些 DB/API seams 已 uplift-absorb-judgment-ready
4. stronger-ingest 当前最多能走到哪层
5. retained anchor / rollback target 何时未来才允许变动

### 8.4 哪些仍不能升格为 runtime truth
1. full cutover completed
2. `review_group` true exit
3. active DB/API uplift absorbed
4. final fact owner shift
5. homepage route / active continuation source switch
6. cleanup / old-path purge

### 8.5 Room 2 的硬句
> **P3.3.12 的最佳收口，不是“现在宣布再切更多”，而是“把谁够格进入下一拍判断写硬，同时继续把 true-exit、uplift-absorb 与 runtime truth 严格分层”。**

---

## 9. Room 2 正式建议给 Room 1 的最小 pin 集合

若 Room 1 要 pin，本轮 Room 2 建议只 pin：

1. **`fuller_cutover_absorb_candidate_v1`**
   - 只 pin ReviewPage + 首页 review 承接层的 very narrow absorb-candidate subset
   - 不 pin homepage route / continuation owner / final fact owner switch

2. **`review_group_true_exit_gate_v1`**
   - 只 pin true-exit gate judgment 的资格条件与 still-dependent paths
   - 不 pin true exit 生效

3. **`db_api_uplift_absorb_judgment_v1`**
   - 只 pin uplift-absorb-judgment-ready seam families
   - 不 pin active DB / API uplift absorbed

4. **`cutover_vs_fact_owner_boundary_v4`**
   - 只 pin stronger-ingest absorb-judgment candidate 的前进上限与 final fact owner 红线
   - 不 pin fact owner switch

5. **`exit_candidate_to_true_exit_transition_v1`**
   - 只 pin transition 条件与 retained anchor / rollback target 暂不可动的范围
   - 不 pin fallback-only / cleanup

6. **`phase6_writeback_order_v1`**
   - 只 pin judgment / candidate / runtime truth 的回写顺序
   - 不 pin runtime baseline update

---

## 10. Room 2 对 Room 1 的最终建议

### 10.1 建议
> **建议 Room 1 正式启动 P3.3.12。**

### 10.2 但只能以什么形式启动
只能以：

> **Fuller-Cutover / True-Exit-Gate / DB-API Uplift-Absorb Judgment Preflight**

的形式启动。

### 10.3 不建议以什么形式启动
不建议以：
- full cutover execution
- `review_group` true exit execution
- active DB/API uplift absorbed round
- cleanup / old-path purge round

的形式启动。

### 10.4 Room 2 最终一句话
> **P3.3.12 最值得做的，不是继续静默往主链路里塞更多切换，而是把“谁已经配进入下一拍 judgment、谁还不配”写硬；这样下一轮无论继续 owner-shift，还是选择 hold，都不会让治理层、运行态与代码事实再度漂移。**
