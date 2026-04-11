# R2_P3_3_11_FullerCutoverExecution_ExitCandidate_and_DBUpliftReadiness_Tech_Note_v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** fuller-cutover execution preflight / ready for Room 1 review
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Round:** `P3.3.11 — Fuller-Cutover Execution / review_group Exit-Candidate / DB-API Uplift-Readiness Round`

---

## 0. 文档定位

本稿不是：
- Room 4 的 fuller-cutover 执行单
- runtime owner shift 完成宣告
- `review_group` 真退场公告
- active DB / API baseline uplift 完成宣告
- cleanup / old-path purge 方案书
- DB 主文档 / API 主文档重写稿

本稿只做一件事：

> **从 Room 2 / CTO 视角，把 P3.3.11 收成一轮 “fuller-cutover execution / review_group exit-candidate / DB-API uplift-readiness” 的技术预收口：明确当前哪一组 widened subset 可以真正进入 execution-ready subset、`review_group` 哪些内容只到 exit-candidate、哪些 DB/API seams 已经从 judgment-ready 进入 uplift-readiness、以及 retained-anchor / rollback / hold / fact-owner boundary / write-back 的下一层硬红线。**

一句话：

> **P3.3.11 应进入 fuller-cutover execution preflight；但当前只适合把切口扩大一小层并写硬 execution-ready subset / exit-candidate / uplift-readiness，不适合把 full cutover、`review_group` 真退场、active DB/API uplift、cleanup 或 final fact owner shift 写成已生效事实。**

---

## 1. 输入依据与采用口径

### 1.1 Governance / role basis
- `ORG_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.2`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_11_ScopePin_and_Handoff_Pack_v0.2.md`
- `Main_updated_2026-04-10_v31.md`
- `STATUS_updated_2026-04-10_v29.md`

### 1.3 Review basis for this round
- `BR-OPP-001_v0.2.12.md`
- `UI_SPEC_v0.3.2.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.10_Claude_res.md`

### 1.4 Room 2 采用口径
1. **本轮服从 Room 1 handoff 指定的 review basis。**
2. **当前 runtime active reality 仍以 Main / STATUS 已 pin 的 active versions 为准。**
3. `BR v0.2.12` 与 `UI v0.3.2` 当前按 runtime active / latest review basis 使用；`DB/API v0.2.1` 仍是 active baseline，同时也是本轮 uplift-readiness 的起点。
4. `P3.3.10` 已把 fuller-cutover judgment / exit-gate judgment / uplift judgment 做成可引用的 artifacts，但仍未改 runtime 文件主链路、未改 DB schema、未改 API core semantics、未让 `review_group` 退场、未让 active DB/API uplift absorbed。
5. **No silent contract drift**：凡 execution-ready subset、exit-candidate、uplift-readiness 一旦被 Room 1 pin，后续执行与回写必须同步到 BR / UI / DB / API / test 证据层。

---

## 2. Room 2 总判断

### 2.1 本轮是否应该前进一步
Room 2 结论：

> **应该前进一步。**

但推进方式必须是：

> **Fuller-Cutover Execution / `review_group` Exit-Candidate / DB-API Uplift-Readiness Preflight**

而不是：

> **runtime owner shift completed / full cutover completed / `review_group` true exit / active DB-API uplift absorbed / cleanup started**

### 2.2 为什么现在值得进入 fuller-cutover execution
因为当前已经具备：
1. `P3.3.9` 的 first-cutover runtime 证据；
2. `P3.3.10` 的 fuller subset / exit-gate / uplift judgment artifacts；
3. retained anchor / rollback / hold / observability 成套证据；
4. `review_group` exit-candidate 的前置条件清单；
5. DB/API uplift-judgment-ready seam families 的最小清单；
6. BR / UI 已完成 `P3.3.10` judgment 结果的主文档候选回写。

### 2.3 为什么仍不能直接进入 full cutover
因为当前仍同时成立：
1. ReviewPage current serving truth 仍大面积围绕 cloud `review_group`；
2. 首页 runtime 仍是 `home_word_entry = study_default`；
3. active continuation 仍未切到 local path；
4. final fact / settlement truth 仍以后端为准；
5. DB / API active baseline 仍是 `v0.2.1`；
6. `review_group` 仍未进入真实退场。

### 2.4 Room 2 一句话立场
> **P3.3.11 该收成“把 widened subset 变成 execution-ready subset”的轮；不该收成“现在可以把 fuller cutover、true exit、uplift、cleanup 一口气拉满”的执行轮。**

---

## 3. Q1 — `fuller_cutover_execution_subset_v1`

### 3.1 Room 2 结论
> **P3.3.11 当前最值得进入 execution-ready subset 的，仍应留在 ReviewPage 与首页 review 承接层；并且只允许从 P3.3.10 的 continuity-adjacent judgment，推进到一个 very narrow、可 rollback、可 hold、可回归的 widened serving-adapter family。**

### 3.2 Room 2 推荐的 execution-ready subset
当前最稳的 execution-ready subset，只建议包含以下 5 层：

#### A. ReviewPage wider serving-adapter family
- 在 `P3.3.9` 的 non-continuation serving seam 之上，
- 允许把 **ReviewPage 内部 continuity-adjacent source-selection / adapter / helper / summary / empty-state / completion 前置说明** 扩大一小层，
- 但仍然只限于 ReviewPage 页面内部。

#### B. 首页 review helper / no-review-state 的 retained-anchor-aware prep
- 允许把首页中与 review 承接相关的 helper / summary / no-review-state 做 source-neutral / retained-anchor-aware execution prep；
- 但 **不触碰首页默认主 route**，也不做 planner-aware / auto-routing。

#### C. rollback / hold / fallback neutral contract
- 允许把 widened subset 所需的 rollback / hold / fallback 逻辑推进到 execution-ready 模板；
- 重点是 failure bucket / blast radius / stop-condition 的稳定落点；
- 但 rollback target 当前仍固定指向 `cloud_review_group_current_runtime_path`。

#### D. stronger-ingest candidate 的 execution-ready binding prep
- 允许从 P3.3.10 的 `validated stronger-ingest candidate layer` 再前进一步，
- 进入 **execution-ready stronger-ingest binding candidate**，
- 只讨论 accept / reject / duplicate / progress-candidate / completion-candidate 的更稳绑定；
- 不得升格为 final fact write。

#### E. continuity-adjacent helper seam
- 允许把与 active continuation 共边但不改 continuation owner 的 helper / state / guard / observability 接缝推进到 execution-ready；
- **不允许** 把 active continuation 真实承接路径切到 local。

### 3.3 当前不推荐纳入 execution-ready subset 的方向
以下内容都不建议纳入 P3.3.11 execution-ready subset：
1. 首页默认 route / planner-aware entry
2. active continuation source switch
3. final fact / settlement owner switch
4. `review_group` 真退场 / old path cleanup
5. DB schema rewrite / API core semantics rewrite
6. active DB / API baseline uplift absorbed
7. user-visible “new main path already active” 宣告

### 3.4 Room 2 的硬句
> **P3.3.11 可以扩大 execution-ready subset，但仍必须把切口留在 ReviewPage 与首页 review 承接层；不得把首页主 route、continuation truth 与 final fact truth 一起带过去。**

---

## 4. Q2 — `review_group_exit_candidate_v1`

### 4.1 Room 2 结论
> **P3.3.11 可以把 `review_group` 从纯 judgment 推到 exit-candidate 层；但 exit-candidate 只表示“退场资格准备中”，不表示“已具备 true exit 条件”，更不表示“当前可退场”。**

### 4.2 当前允许进入 `exit-candidate` 的内容
本轮最多只建议推进以下 5 类：

1. **依赖 inventory 明文化**
   - 把当前哪些路径仍必须依赖 `review_group` 写成显式 inventory；
   - 尤其是 completion gating、settlement trigger、rollback target、baseline compare、failure fallback。

2. **replacement-readiness marker**
   - 对 widened subset 所需的 replacement path 是否已存在、是否可验证、是否可解释，进入 marker 层；
   - 但 marker ≠ runtime replacement already active。

3. **retained-anchor → exit-candidate 条件清单**
   - 允许把何时才可缩窄 retained anchor 的条件写硬；
   - 包括 contract / test / doc / runtime evidence / boundary guard 五类条件。

4. **fallback scope judgement**
   - 允许判断 rollback / fallback scope 哪些未来可 very narrow 缩窄；
   - 但当前仍不得把 retained anchor 改成 fallback-only。

5. **no-overclaim / no-cleanup assertions**
   - 必须继续显式声明：当前不得写成 retired / removed / no longer used / safe to purge。

### 4.3 当前仍必须继续保持的 `review_group` 姿态
以下内容本轮仍必须继续保持：
1. **current runtime serving owner**
2. **retained fallback anchor**
3. **compatibility anchor**
4. **deprecated candidate**

### 4.4 当前仍必须依赖 `review_group` 的路径
至少包括：
1. active continuation identity
2. current completion gating
3. current settlement trigger
4. rollback target
5. baseline compare / compatibility anchor
6. widened subset failure 时的 fallback path
7. 用户当前可见主队列来源的最终兜底

### 4.5 Room 2 的硬句
> **P3.3.11 可以把 `review_group` 推到 exit-candidate，但还不能把它写成 fallback-only、retired、removed 或 safe-to-clean。**

---

## 5. Q3 — `db_api_uplift_readiness_v1`

### 5.1 Room 2 结论
> **P3.3.11 可以把一小组 seam 从 uplift-judgment-ready 推到 uplift-readiness；但 uplift-readiness 仍不是 active baseline uplift。**

### 5.2 Room 2 推荐“已可进入 uplift-readiness”的 seam families
当前最有资格进入 uplift-readiness 的，只建议包括：

1. **review_serving_source_descriptor seam**
   - 用于表达 ReviewPage widened subset 下的 serving-source 判定与来源层级；
   - 不改现有 endpoint 核心语义。

2. **retained_anchor / fallback posture seam**
   - 用于表达 current owner / retained fallback anchor / compatibility anchor / deprecated candidate / exit-candidate posture；
   - 仍停留在 marker / posture / migration 层。

3. **stronger_ingest_path_minimal seam**
   - 用于表达 accept / reject / duplicate / progress-candidate / completion-candidate 的 execution-ready stronger binding；
   - 仍不等于 final fact write。

4. **rollback / hold / observability seam**
   - 用于表达 rollback target、hold reason、evidence bucket、stop-condition、no-final-fact-owner-switch assertions；
   - 这一组已经足够进入 uplift-readiness。

5. **continuation-adjacent helper seam**
   - 仅限 continuity-adjacent state / helper / summary / gating 边界的表达层与 marker 层；
   - 不包括 active continuation source switch 本身。

### 5.3 当前仍只能停留在 migration note / hold note / rollback floor 的内容
1. DB schema rewrite
2. API endpoint core semantics rewrite
3. final fact / settlement owner fields
4. homepage route / auto-routing result fields
5. `review_group` exited / old path purge indicators
6. active baseline declarations
7. cleanup bundle / old-path deletion markers

### 5.4 当前仍绝不能进入 active baseline 的内容
1. 任何需要数据迁移、历史回填或兼容补丁的 schema 动作
2. 任何改变 API 核心用途 / 核心请求返回结构 / 核心参数语义的动作
3. 任何会让 UI / BR / test 误以为 uplift 已 absorbed 的字段或 copy
4. 任何会把 local-serving / stronger-ingest 误写成 final fact owner 的层
5. 任何用来宣告 `review_group` 已退出运行态的 baseline 级字段

### 5.5 Room 2 的硬句
> **P3.3.11 允许判断哪些 seams 已够格进入 uplift-readiness，但不允许把 uplift-readiness 写成 active DB/API uplift 已完成。**

---

## 6. Q4 — `cutover_vs_fact_owner_boundary_v3`

### 6.1 Room 2 结论
> **fuller-cutover execution 扩大一小层后，stronger ingest candidate 最多只允许推进到 execution-ready binding layer；final fact owner 继续不得跟着切。**

### 6.2 当前允许前进一步的 stronger-ingest candidate 上限
只建议前进到以下层级：
1. accept / reject / duplicate 结果绑定更稳
2. progress-candidate / completion-candidate 前后置条件更清晰
3. hold-reason / rollback ownership 更显式
4. no-final-fact-owner-switch assertion 更稳定
5. minimal ingest binding 与 widened serving subset 对齐

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

### 6.5 Room 2 的硬句
> **serving subset 可以扩大，stronger-ingest binding 可以更稳；但 final fact owner 当前仍必须以后端为准。**

---

## 7. Q5 — `retained_anchor_narrowing_guardrail_v1`

### 7.1 Room 2 结论
> **P3.3.11 可以 very narrow 地讨论 retained anchor 的缩窄；但只能缩窄说明层与 helper / fallback scope，不能缩窄 owner identity、rollback target、completion gating 与 settlement trigger。**

### 7.2 当前允许 very narrow 缩窄的范围
本轮最多只建议允许缩窄：
1. helper / summary / no-review-state 的 retained-anchor-aware 说明层
2. fallback copy / hold note / migration note 的表述范围
3. widened subset 内部非主事实 helper 的兼容语义
4. 某些 marker / posture 的文档与 UI 表达层
5. 某些 future-narrowable rollback bucket 的判断层

### 7.3 当前仍不得缩窄的范围
以下本轮仍不得缩窄：
1. rollback target 主句：`cloud_review_group_current_runtime_path`
2. current runtime serving owner 身份
3. active continuation identity
4. current completion gating
5. current settlement trigger
6. compatibility anchor
7. non-cutover baseline path

### 7.4 当前仍必须保持的 stop conditions
任一出现，仍必须 hold / rollback / escalate：
1. active continuation 被误切到 local path
2. local subset 被写成 current ReviewPage full truth
3. local evidence 直接改 final ledger / daily_goal / streak / settlement
4. 首页 route 被 planner-aware / auto-routing 改写
5. 用户端出现 cutover completed / owner shift completed / `review_group` exited / uplift absorbed 类 overclaim
6. 需要改 DB schema 或 API core semantics 才能维持 widened subset
7. rollback path 不存在、不可验证或不可解释

### 7.5 Room 2 的硬句
> **P3.3.11 当前只适合 very narrow 地缩窄 retained anchor 的说明层与 helper scope，不适合动它的 owner / rollback / completion / settlement 骨架。**

---

## 8. Q6 — `phase5_writeback_order_v1`

### 8.1 Room 2 结论
> **P3.3.11 的回写顺序必须比 P3.3.10 更强调 “execution-ready candidate / exit-candidate / uplift-readiness” 三层分离；runtime truth 仍必须最后单开。**

### 8.2 Room 2 推荐的 write-back 次序
1. **先写 Room 2 tech note**
   - widened execution subset / exit-candidate / uplift-readiness / fact-boundary / retained-anchor narrowing 红线

2. **再写 Room 3 rules note**
   - exit-candidate 规则、fact-owner boundary、must-hold / must-escalate、overclaim guardrails

3. **再写 Room 5 UI preflight**
   - runtime-truth guardrails / exit-candidate UI guidance / uplift-readiness UI guidance / retained-anchor-aware copy

4. **Room 1 再判断是否形成更完整一拍的 Room 4 execution handoff**
   - 只形成 very narrow fuller-cutover execution handoff
   - 不形成 full cutover / true exit / uplift absorbed / cleanup

5. **DB/API write-back 只进入 uplift-readiness candidate 层**
   - 先写 seam families / marker / rollback / hold / migration / observability
   - 不改 active baseline

6. **runtime baseline update 最后再单开判断**
   - 只有当 Room 1 单独 pin，且下一层执行证据具备，才可讨论 active uplift / true exit / cleanup bundling

### 8.3 哪些只能写成 execution-ready / exit-candidate / uplift-readiness
1. widened subset 可切到哪层
2. `review_group` 哪些内容只到 exit-candidate
3. 哪些 DB/API seams 已 uplift-readiness
4. stronger-ingest binding 当前最多能走到哪层
5. retained anchor 哪些范围允许 very narrow 缩窄

### 8.4 哪些仍不能升格为 runtime truth
1. full cutover completed
2. `review_group` true exit
3. active DB/API uplift absorbed
4. final fact owner shift
5. homepage route / active continuation source switch
6. cleanup / old-path purge

### 8.5 Room 2 的硬句
> **P3.3.11 的最佳收口，不是“现在宣布切更多”，而是“把 widened subset 真正推进到 execution-ready，同时继续把 exit-candidate、uplift-readiness 与 runtime truth 严格分层”。**

---

## 9. Room 2 正式建议给 Room 1 的最小 pin 集合

若 Room 1 要 pin，本轮 Room 2 建议只 pin：

1. **`fuller_cutover_execution_subset_v1`**
   - 只 pin ReviewPage + 首页 review 承接层的 very narrow widened execution-ready subset
   - 不 pin homepage route / continuation owner / final fact owner switch

2. **`review_group_exit_candidate_v1`**
   - 只 pin exit-candidate 层允许进入的内容与仍必须依赖 `review_group` 的路径
   - 不 pin true exit

3. **`db_api_uplift_readiness_v1`**
   - 只 pin uplift-readiness seam families
   - 不 pin active DB / API uplift

4. **`cutover_vs_fact_owner_boundary_v3`**
   - 只 pin stronger-ingest execution-ready binding 的前进上限与 final fact owner 红线
   - 不 pin fact owner switch

5. **`retained_anchor_narrowing_guardrail_v1`**
   - 只 pin retained anchor 允许 very narrow 缩窄的范围与 stop conditions
   - 不 pin fallback-only / cleanup

6. **`phase5_writeback_order_v1`**
   - 只 pin execution-ready candidate / exit-candidate / uplift-readiness / runtime truth 的回写顺序
   - 不 pin runtime baseline update

---

## 10. Room 2 对 Room 1 的最终建议

### 10.1 建议
> **建议 Room 1 正式启动 P3.3.11。**

### 10.2 但只能以什么形式启动
只能以：

> **Fuller-Cutover Execution / `review_group` Exit-Candidate / DB-API Uplift-Readiness Preflight**

的形式启动。

### 10.3 不建议 Room 1 当前轮做什么
当前不建议 Room 1：
1. 把本轮写成 full cutover execution completed
2. 把 `review_group` 写成 true exit / safe-to-clean
3. 把 active DB / API uplift 写成已生效
4. 把 cleanup 与 wider subset execution bundling
5. 把 final fact owner 边界往 serving subset 内偷拉

### 10.4 Room 2 一句话 closing
> **P3.3.11 可以切得更深一点，但仍只能在 very narrow widened subset 内切；`review_group` 仍只到 exit-candidate，DB/API 仍只到 uplift-readiness，final fact owner 继续不动。**
