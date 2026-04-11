# R2_P3_3_10_FullerCutover_ExitGate_and_DBUplift_Tech_Note_v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** fuller-cutover judgment preflight / ready for Room 1 review
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Round:** `P3.3.10 — Fuller Cutover / review_group Exit-Gate / DB-API Uplift Judgment Round`

---

## 0. 文档定位

本稿不是：
- Room 4 fuller-cutover 执行单
- DB 主文档重写稿
- API 主文档重写稿
- runtime owner shift 完成宣告
- `review_group` 退场公告
- active DB / API baseline uplift 完成宣告
- cleanup / old-path purge 方案书

本稿只做一件事：

> **从 Room 2 / CTO 视角，把 P3.3.10 收成一轮“fuller cutover / exit-gate / DB-API uplift judgment preflight”：给出下一拍最值得扩大的 cutover subset、`review_group` 何时才有资格从 retained anchor 进入真实 exit judgment、哪些 DB/API seams 已够格进入 uplift judgment、以及 rollback / hold / observability / write-back 的下一层红线。**

一句话：

> **P3.3.10 应进入 fuller-cutover judgment preflight；但当前只适合判断“下一拍可扩大到哪一层”，不适合把 fuller cutover、`review_group` 退场、DB/API uplift 与 cleanup 写成已生效事实。**

---

## 1. 输入依据与采用口径

### 1.1 Governance / Role basis
- `ORG_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.2`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_10_ScopePin_and_Handoff_Pack_v0.1.md`
- `Main_updated_2026-04-10_v30.md`
- `STATUS_updated_2026-04-10_v28.md`

### 1.3 Review basis for this round
- `BR-OPP-001_v0.2.11.md`
- `UI_SPEC_v0.3.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.9_Claude_res.md`

### 1.4 Room 2 采用口径
1. **本轮服从 Room 1 handoff 指定的 review basis。**
2. **当前 runtime active reality 仍以 Main / STATUS 已 pin 的 active versions 为准。**
3. `BR v0.2.11` 与 `UI v0.3.1` 当前按 runtime active basis 使用；`DB/API v0.2.1` 仍是 active baseline，同时也是本轮 uplift judgment 的起点。
4. P3.3.9 已证明 first-cutover 可控，但只证明了 **ReviewPage non-continuation serving seam** 这一拍，不自动证明 fuller cutover / exit / uplift 已具备资格。
5. No silent contract drift。

---

## 2. Room 2 总判断

### 2.1 本轮是否应该前进一步
Room 2 结论：

> **应该前进一步。**

但推进方式必须是：

> **Fuller Cutover / `review_group` Exit-Gate / DB-API Uplift Judgment Preflight**

而不是：

> **runtime owner shift completed / ReviewPage local-serving full runtime cutover completed / `review_group` exited / active DB/API baseline uplift absorbed / cleanup started**

### 2.2 为什么现在值得进入 fuller-cutover judgment
因为当前已经具备：
1. first-cutover 的 runtime 落地证据；
2. retained anchor / rollback / hold / observability 成套证据；
3. `review_group` exit-gate 的前置条件已比 P3.3.9 前更清楚；
4. BR / UI 已把 P3.3.9 的事实吸收到新的主文档候选 / active runtime basis；
5. 下一层真正的难点已经从“敢不敢切第一刀”变成“下一拍到底能扩大到哪一层”。

### 2.3 为什么仍不能直接进入 fuller-cutover execution
因为当前仍同时成立：
1. ReviewPage current serving truth 仍大面积围绕 cloud `review_group`；
2. 首页 runtime 仍是 `home_word_entry = study_default`；
3. active continuation 仍未切到 local path；
4. final fact / settlement truth 仍以后端为准；
5. DB / API active baseline 仍是 `v0.2.1`；
6. `review_group` 仍未进入真实退场。

### 2.4 Room 2 一句话立场
> **P3.3.10 该收成“下一拍可扩大到哪一层”的 judgment round；不该收成“现在可以把 fuller cutover、exit、uplift、cleanup 一口气拉满”的执行轮。**

---

## 3. Q1 — `fuller_cutover_subset_v1`

### 3.1 Room 2 结论
> **下一拍最值得扩大的 fuller subset，仍应留在 ReviewPage 内部；但可以从 “non-continuation serving seam” 扩大到 “continuity-adjacent serving-adapter family”，而不是直接跳到首页 route / auto-routing / final fact owner。**

### 3.2 Room 2 推荐的 fuller-cutover subset
当前最稳的扩大方向，只建议包含以下 4 层：

#### A. ReviewPage wider serving-adapter family
- 从 `non-continuation serving seam` 扩大到 **ReviewPage 内部更完整的一组 source-selection / adapter / helper seams**；
- 允许把与 ReviewPage 当前来源判定强绑定的 neutral state / helper / summary / empty-state 一并纳入；
- 仍不离开 ReviewPage 页面边界。

#### B. continuity-adjacent seam（不是 continuation owner switch）
- 允许讨论 **与 continuation 共边、但不改 continuation owner 的接缝**；
- 例如：continuation-adjacent helper / state / serving-decision boundary 是否需要 source-neutral 化；
- 但 **active continuation 真实承接路径** 继续不得切到 local。

#### C. stronger ingest candidate 的一小步前进
- 允许从 “evidence-path only” 进一步进入 **validated stronger-ingest candidate layer**；
- 只讨论 accept / reject / duplicate / progress-candidate / completion-candidate 的更清晰接缝；
- 不把它升格成 final fact write。

#### D. rollback / hold / retained-anchor 的收窄判断
- 允许判断哪些 rollback / hold 仍必须无条件保留；
- 允许判断 retained anchor 的职责是否可从“current owner + retained fallback anchor”收窄到更接近 exit-candidate 的姿态；
- 但本轮只做 judgment，不直接切换。

### 3.3 当前不推荐的 fuller-cutover 扩大方向
以下都不建议作为 P3.3.10 的下一拍：
1. 首页 route / planner-aware entry
2. active continuation source switch
3. final fact owner switch
4. `review_group` 真实退场 / old cloud path cleanup
5. DB schema rewrite / API core semantics rewrite
6. active DB / API baseline uplift absorbed

### 3.4 Room 2 的硬句
> **下一拍可以扩大 serving-adapter family，但仍不该越过 ReviewPage 页面边界，更不能把 continuation truth、route truth 与 final fact truth 一起带过去。**

---

## 4. Q2 — `review_group_exit_gate_v2`

### 4.1 Room 2 结论
> **`review_group` 当前还不具备进入真实 exit judgment 的资格；P3.3.10 只适合把 exit-gate 条件写硬，而不适合宣告“已经可以退场”。**

### 4.2 进入真实 exit judgment 前仍缺的条件
至少还缺以下 6 类前置件：

1. **更宽一层的 runtime evidence**
   - first-cutover 只证明了 non-continuation seam；
   - 还没有证明 continuity-adjacent family 被扩大后仍稳定。

2. **continuation 依赖的显式处理方案**
   - active continuation 仍是 `review_group` 的最硬 owner 区域；
   - 若这一层还没得到独立 judgment，exit-gate 不能前推。

3. **completion / settlement / final-fact 依赖清单**
   - 还需要把哪些 completion gating / settlement trigger / fact assertions 仍依赖 `review_group` 写得更显式；
   - 没有这张清单，不允许谈真实 exit。

4. **文档四件套同步**
   - BR / UI / DB / API 必须同步具备 exit-candidate / retained-anchor / rollback-target 的一致写法；
   - 不能只在代码或单一 note 中出现。

5. **可重复的 runtime / QA evidence**
   - 不只是单次 pass；
   - 需要更宽 subset 下的 hold / rollback / retained-anchor 仍可稳定复现。

6. **旧路径依赖 inventory**
   - 必须列清当前仍必须走 `review_group` 的路径；
   - 没有 inventory，不得把 retained anchor 收窄成 exit candidate。

### 4.3 当前仍必须继续依赖 `review_group` 的路径
至少包括：
1. active continuation identity
2. current completion gating
3. current settlement trigger
4. rollback target
5. baseline compare / compatibility anchor
6. fallback path when widened subset fails

### 4.4 Room 2 的硬句
> **P3.3.10 当前可以写“何时才有资格进入真实 exit judgment”，但还不能写“现在已经有资格 exit”。**

---

## 5. Q3 — `db_api_uplift_judgment_v1`

### 5.1 Room 2 结论
> **P3.3.10 可以正式进入 uplift judgment；但当前只允许把一小组与 fuller-cutover 直接相关的 seams 升到 uplift-judgment-ready，不允许把 DB/API baseline 真升成 active。**

### 5.2 Room 2 推荐“已 uplift-judgment-ready”的 seam families
当前最有资格进入 uplift judgment 的，只建议包括：

1. **Review serving source descriptor seam**
   - 用于表达 ReviewPage 当前 serving-source 判定与其来源层级；
   - 仍不改现有 endpoint 核心语义。

2. **retained-anchor / fallback marker seam**
   - 用于表达 current owner / retained fallback anchor / compatibility anchor / deprecated candidate 等姿态；
   - 仍停留在 marker / posture / migration 层。

3. **stronger ingest path minimal seam**
   - 用于表达 accept / reject / duplicate / progress-candidate / completion-candidate 的更强接缝；
   - 仍不等于 final fact write。

4. **rollback / hold / observability seam**
   - 用于表达 rollback target、hold reason、evidence bucket、no-final-fact-owner-switch assertions；
   - 这一组已经足够进入 uplift judgment。

5. **continuation-adjacent helper seam**
   - 仅限 continuity-adjacent state / helper / summary / gating 边界的表达层与 marker 层；
   - 不包括 active continuation source switch 本身。

### 5.3 当前仍必须停留在 candidate / migration note 的内容
1. DB schema rewrite
2. current API endpoint core semantics rewrite
3. final fact / settlement owner fields
4. homepage route / auto-routing result fields
5. `review_group` exited / old path purge indicators
6. new active baseline declarations

### 5.4 何时才允许讨论 active DB/API baseline uplift
至少需要同时满足：
1. P3.3.10 所建议的 fuller subset 已拿到可回归 runtime 证据；
2. `review_group` exit-gate 至少进入“条件已齐、可单开真实 exit judgment”状态；
3. BR / UI / DB / API 四件套已完成同层 write-back；
4. 没有任何 action 仍依赖改 DB schema / API core semantics 才能维持当前 subset；
5. Room 1 单独开出 uplift judgment 之后的下一层执行判断轮。

### 5.5 Room 2 的硬句
> **P3.3.10 允许判断哪些 seams 够格进入 uplift judgment，但不允许把 uplift judgment 写成 active baseline uplift。**

---

## 6. Q4 — `cutover_vs_fact_owner_boundary_v2`

### 6.1 Room 2 结论
> **fuller cutover 与 final fact owner 仍必须继续拆开；P3.3.10 当前只允许 stronger ingest candidate 前进一步，不允许 final fact owner 跟着切。**

### 6.2 当前允许前进一步的 stronger ingest path
只建议前进到以下层级：
1. accept / reject / duplicate 结果标准化
2. attempt / progress / completion candidate 的更清晰命名
3. stronger ingest precondition / postcondition
4. hold reason / reject reason / mismatch bucket 的显式化
5. no-final-fact-owner-switch assertion 的更稳定落点

### 6.3 当前仍必须继续以后端为准的 final facts
1. effective review fact
2. daily goal progress / completion
3. reward settlement / ledger arrival
4. `check_in / learning_day / streak`
5. completion / 到账类主反馈

### 6.4 当前继续禁止的动作
1. local-serving 结果直接改 ledger
2. local-serving 结果直接推进 daily goal 完成
3. local-serving 结果直接续上 streak / learning_day
4. local-serving 结果直接产生“已到账 / 已完成 / 已记为有效复习”的用户事实

### 6.5 Room 2 的硬句
> **serving subset 可以 fuller，ingest candidate 可以 stronger；但 final fact owner 当前仍不能跟着切。**

---

## 7. Q5 — `retained_anchor_to_exit_transition_v1`

### 7.1 Room 2 结论
> **P3.3.10 只适合定义 retained anchor 向 exit candidate 过渡的资格条件；当前不适合真正把 `review_group` 改成 fallback-only，更不适合进入清理。**

### 7.2 何时才可从 retained anchor 进入 exit candidate
建议至少同时满足：
1. fuller subset 已证明比 P3.3.9 更宽，但仍稳定；
2. active continuation 的边界已被单独写硬，且不再依赖默认 retained-anchor 姿态兜底；
3. rollback / hold 被证明是收敛的，而不是常态触发；
4. completion / settlement / compare baseline 对 `review_group` 的依赖已被 inventory 化；
5. BR / UI / DB / API 四件套都已显式写出 exit-candidate 的边界；
6. Room 1 单独接受“进入真实 exit judgment”的下一层范围。

### 7.3 rollback target 当前如何变化
当前不建议改变 rollback target 的主句：
- **主 rollback target 继续保持 `cloud_review_group_current_runtime_path`。**

P3.3.10 只允许额外判断：
- 哪些 widened subset failure 仍必须一律回到这个 target；
- 哪些 failure bucket 未来才有资格区分成更细的 fallback 路由。

### 7.4 当前仍必须保持的 stop conditions
任一出现，仍必须 hold / rollback / escalate：
1. active continuation 被误切到 local path
2. local subset 被写成 current ReviewPage full truth
3. local evidence 直接改 final ledger / daily_goal / streak / settlement
4. 首页 route 被 planner-aware / auto-routing 改写
5. 用户端出现 cutover completed / owner shift completed / `review_group` exited 类 overclaim
6. 需要改 DB schema 或 API core semantics 才能维持 fuller subset
7. rollback path 不存在、不可验证或不可解释

### 7.5 Room 2 的硬句
> **P3.3.10 当前只适合判断“何时才有资格从 retained anchor 进入 exit candidate”，不适合真的把 retained anchor 改成 fallback-only。**

---

## 8. Q6 — `phase4_writeback_order_v1`

### 8.1 Room 2 结论
> **P3.3.10 的回写顺序必须比 P3.3.9 更强调“judgment 先于 execution-ready candidate，execution-ready candidate 先于 runtime truth”。**

### 8.2 Room 2 推荐的 write-back 次序
1. **先写 Room 2 judgment note**
   - fuller subset / exit-gate / uplift judgment / fact boundary / rollback 红线

2. **再写 Room 3 rules note**
   - exit-gate rule set / fact-copy guardrails / must-hold / must-escalate

3. **再写 Room 5 UI preflight**
   - runtime-truth guardrails / exit-candidate UI guidance / uplift-judgment UI guidance

4. **Room 1 再判断是否形成 execution-ready candidate**
   - 只形成 very narrow fuller-cutover execution handoff
   - 不形成 full cutover / cleanup / uplift absorbed

5. **DB/API write-back 只进入 uplift-judgment candidate 层**
   - 先写 seam families / marker / rollback / hold / observability
   - 不改 active baseline

6. **runtime baseline update 最后再单开判断**
   - 只有当 Room 1 单独 pin，且下一层执行证据具备，才可讨论 active uplift

### 8.3 哪些只能写成 judgment
1. fuller cutover 可扩大到哪层
2. `review_group` 何时才具备真实 exit judgment 资格
3. 哪些 DB/API seams 已 uplift-judgment-ready
4. stronger ingest path 能前进到哪层

### 8.4 哪些可以写成 execution-ready candidate
1. ReviewPage wider serving-adapter family 的 very narrow next subset
2. retained-anchor / rollback / hold / observability 的下一层固定模板
3. source-neutral helper / summary / state contract 的继续迁移
4. uplift-judgment-ready seam list

### 8.5 Room 2 的硬句
> **P3.3.10 的最佳收口，不是“现在宣布切更多”，而是“把下一拍该怎么切、何时可退场、哪些 seam 够格进入 uplift judgment 写硬”。**

---

## 9. Room 2 正式建议给 Room 1 的最小 pin 集合

若 Room 1 要 pin，本轮 Room 2 建议只 pin：

1. **`fuller_cutover_subset_v1`**
   - 只 pin ReviewPage 内 fuller serving-adapter family 的 very narrow 扩大方向
   - 不 pin homepage route / continuation owner / final fact owner switch

2. **`review_group_exit_gate_v2`**
   - 只 pin进入真实 exit judgment 前仍缺的前置条件
   - 不 pin `review_group` 可退场

3. **`db_api_uplift_judgment_v1`**
   - 只 pin uplift-judgment-ready seam families
   - 不 pin active DB / API uplift

4. **`cutover_vs_fact_owner_boundary_v2`**
   - 只 pin stronger ingest candidate 的前进上限与 final fact owner 红线
   - 不 pin fact owner switch

5. **`retained_anchor_to_exit_transition_v1`**
   - 只 pin retained anchor → exit candidate 的资格条件
   - 不 pin fallback-only / cleanup

6. **`phase4_writeback_order_v1`**
   - 只 pin judgment / execution-ready candidate / runtime truth 的顺序
   - 不 pin absorbed runtime changes

---

## 10. 哪些动作一旦出现就越界成 fuller-cutover overreach / DB-API major

以下任一出现，都视为越界：
1. 一轮内把 fuller cutover 写成 runtime owner shift completed
2. 一轮内把 `review_group` 写成可直接清理 / 已退场
3. 一轮内把 active DB / API uplift 写成已生效
4. 一轮内同时做 fuller cutover + exit + uplift + cleanup
5. active continuation source switch
6. homepage route / auto-routing runtime switch
7. final fact owner switch
8. DB schema rewrite
9. API core semantics rewrite
10. 用户可见“新主链路已生效 / 本地 serving 已全面接管 / cutover 已完成 / `review_group` 已退出”的宣告

---

## 11. Room 2 可直接给 Room 1 的判定句

### 11.1 fuller-cutover judgment 句
> **Room 2 judgment：P3.3.10 当前可以进入 fuller-cutover judgment preflight；但下一拍最稳的扩大方向仍应留在 ReviewPage 内部，只扩大到 continuity-adjacent serving-adapter family，不应越过首页 route、active continuation owner、`review_group` 真退场、final fact owner 与 active DB/API uplift。**

### 11.2 exit-gate judgment 句
> **Room 2 judgment：`review_group` 当前仍不具备进入真实 exit judgment 的资格；P3.3.10 最多只应把 “还缺哪些 contract / tests / docs / runtime evidence” 写硬，并继续把 `cloud_review_group_current_runtime_path` 保留为主 rollback target。**

### 11.3 uplift-judgment 句
> **Room 2 judgment：P3.3.10 可以把一小组 first-cutover-related seams 升到 uplift-judgment-ready，但当前仍不应讨论 active DB/API baseline uplift absorbed，更不应引入 schema rewrite 或 API core semantics rewrite。**

