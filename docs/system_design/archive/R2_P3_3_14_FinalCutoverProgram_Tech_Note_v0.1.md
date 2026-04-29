# R2_P3_3_14_FinalCutoverProgram_Tech_Note_v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** final cutover program preflight / ready for Room 1 review
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Round:** `P3.3.14 — Final Cutover Program Round`

---

## 0. 文档定位

本稿不是：
- Room 4 的执行单
- full cutover completed 宣告
- `review_group` true exit 公告
- active DB / API baseline uplift absorbed 完成宣告
- cleanup / old-path purge 完成宣告
- DB / API 主文档重写稿

本稿只做一件事：

> **从 Room 2 / CTO 视角，把 P3.3.14 收成一轮 “Final Cutover Program” 的技术预收口：在保留 A / B / C 三个 sequential checkpoints 的前提下，明确哪些条件必须先被 judgment lock 写硬，哪些 serving / helper / ingest seam 现在真的够格进入 real cutover execution，`review_group` 距离 true exit 还差什么，哪些 DB / API seam 够格进入 uplift absorbed judgment，以及 cleanup 是否具备同轮尾部吸收资格。**

一句话：

> **P3.3.14 可以正式启动，但只能按 A judgment lock → B real cutover execution → C same-round absorb / cleanup 的程序推进；当前不适合把 true exit、uplift absorbed、cleanup 或 final fact owner shift 直接写成已生效事实。**

---

## 1. 输入依据与采用口径

### 1.1 Governance / role basis
- `ORG_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.2`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`

### 1.2 Main-thread handoff basis
- `R1_P3_3_14_ScopePin_and_Handoff_Pack_v0.1.md`
- `Main_updated_2026-04-10_v34.md`
- `STATUS_updated_2026-04-10_v32.md`

### 1.3 Review basis for this round
- `BR-OPP-001_v0.2.15.md`
- `UI_SPEC_v0.3.5.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
- `P3.3.13_Claude_res.md`

### 1.4 Room 2 采用口径
1. **本轮服从 Room 1 handoff 指定的 review basis。**
2. **当前 runtime active reality 仍以 Main / STATUS 已 pin 的 active versions 为准。**
3. 当前 active BR / UI 已升级到 `v0.2.15 / v0.3.5`；DB / API active baseline 继续保持 `v0.2.1`。
4. `P3.3.13` 已把 widened subset 推到 **execution subset / true-exit-candidate / uplift-absorb-readiness** 层，但仍未发生 full cutover、`review_group` true exit、active DB/API uplift absorbed、final fact owner shift。
5. **No silent contract drift**：凡 execution / absorbed / cleanup 一旦被 Room 1 pin，后续执行与回写必须同步到 BR / UI / DB / API / TEST / Main / STATUS。

---

## 2. Room 2 总判断

### 2.1 本轮是否应该启动
Room 2 结论：

> **应该启动。**

但推进方式必须是：

> **Final Cutover Program Preflight（A / B / C 三 checkpoint）。**

而不是：

> **runtime owner shift completed / full cutover completed / `review_group` true exit / active DB-API uplift absorbed / cleanup completed。**

### 2.2 为什么现在值得合并成 1 个项目轮次
因为当前已经具备：
1. `P3.3.9` first-cutover 的 runtime evidence；
2. `P3.3.10`–`P3.3.12` 的 judgment / gate / absorb-candidate artifacts；
3. `P3.3.13` 的 widened execution subset / true-exit-candidate / uplift-absorb-readiness artifacts；
4. retained anchor / rollback / hold / observability 的成套护栏；
5. `review_group` still-dependent paths、still-missing preconditions 与 narrowing guardrails；
6. DB/API uplift 相关 seam families 的 marker / migration / rollback / hold 最小清单。

### 2.3 为什么合并后仍不能“一步切完”
因为当前仍同时成立：
1. ReviewPage current serving truth 仍大面积围绕 cloud `review_group`；
2. 首页 runtime 仍是 `home_word_entry = study_default`；
3. active continuation 仍未切到 local path；
4. final fact / settlement truth 仍以后端 / cloud fact layer 为准；
5. active DB / API baseline 仍是 `v0.2.1`；
6. `review_group` 当前最多只是 true-exit-candidate，不是 true exit；
7. uplift-absorb-readiness 不等于 uplift absorbed。

### 2.4 Room 2 最终一句话
> **P3.3.14 这轮可以做成“合并后的最终项目轮次”，但技术上仍必须拆成 A judgment lock、B real execution、C absorb / cleanup 三个门；默认逻辑是“先锁、再切、最后才吸收”，不是“因为轮次合并，所以状态也一并生效”。**

---

## 3. Q1 — `final_cutover_judgment_lock_v1`

### 3.1 Room 2 结论
> **A checkpoint 必须先写硬 6 组前提，否则 B 一律不得启动。**

### 3.2 A checkpoint 必须写硬的 6 组技术前提
1. **Runtime truth immovables**
   - 首页默认入口继续是 `study_default`
   - current visible Review serving owner 继续围绕 cloud `review_group`
   - active continuation 当前承接路径不可静默改写
   - final fact / settlement owner 不随 serving seam advancement 一起切换

2. **Rollback immovables**
   - rollback target 继续固定为 `cloud_review_group_current_runtime_path`
   - hold fallback 继续必须能稳定回到 cloud current runtime path
   - rollback / hold copy 不得先写成 historical-only

3. **True-exit preconditions inventory**
   - still-dependent paths 必须被完整承认
   - still-missing preconditions 必须有固定清单
   - true-exit-candidate ≠ true-exit-started ≠ true-exit-absorbed

4. **DB/API uplift absorb inventory**
   - uplift seam families 必须区分 absorbed-ready 与 marker-only
   - DB schema rewrite / API core semantics rewrite 仍保持 out of scope
   - active baseline 仍必须显示为 `DB/API v0.2.1`

5. **Fact-owner guardrail**
   - serving seam advancement 不得自动带出 review fact / daily completion / settlement / streak / learning_day / reward ledger owner shift
   - stronger-ingest path 只允许进入 candidate / readiness / absorbed-judgment 讨论，不得直接升格为 final owner

6. **Cleanup gating**
   - old-path purge、historical demotion、deprecated candidate 清理、文档 runtime truth 升级，当前都必须后置到 C
   - A checkpoint 不允许提前消化 cleanup

### 3.3 A checkpoint 必须继续保持的 overclaim 禁区
以下表达在 A checkpoint 继续是禁区：
- `full cutover 已完成`
- `review_group 已 true exit`
- `active DB/API 已 uplift absorbed`
- `本地已接管最终复习事实`
- `首页已改为 planner-aware route`
- `active continuation 已切本地`
- `cleanup 已完成 / 旧路径已清理`

### 3.4 Room 2 的硬句
> **A checkpoint 的作用不是“再讨论一次是否要推进”，而是把所有 still-dependent path、rollback floor、fact-owner guardrail 与 uplift boundary 一次写硬；没写硬，B 不得开。**

---

## 4. Q2 — `real_cutover_execution_subset_v1`

### 4.1 Room 2 结论
> **B checkpoint 可以进入 real cutover execution，但当前真正可切的 execution subset 仍必须保持 very narrow。**

### 4.2 当前唯一推荐进入 B 的 real execution subset
当前最稳的扩大方向仍只限于：
1. **ReviewPage continuity-adjacent serving-adapter family**
2. **ReviewPage helper / summary / empty-state / completion 前置说明层**
3. **首页 review helper / summary / no-review-state 的 retained-anchor-aware 承接层**
4. **rollback / hold / fallback neutral orchestration layer**
5. **与 stronger-ingest absorb-readiness 直接绑定的最小 precondition / binding seam**

### 4.3 当前不应纳入 B 的真实切换
以下内容当前仍不建议在 B 里真实切换：
1. 首页默认主 route
2. active continuation source switch
3. `review_group` current visible owner identity
4. final fact / settlement owner
5. DB schema rewrite
6. API core semantics rewrite
7. cleanup / old-path purge

### 4.4 B checkpoint 的 blast radius 控制原则
1. **只扩大 ReviewPage + 首页 review acceptance 层，不扩大 product-wide routing。**
2. **只允许 retained-anchor-aware execution，不允许 retained-anchor removal。**
3. **任何新 execution 仍必须可 hold、可 rollback、可对照 current cloud path。**
4. **用户端不得因为 B 启动而看到 true-exit / uplift-absorbed / cleanup 文案。**

### 4.5 Room 2 的硬句
> **B checkpoint 可以“更真地切”，但当前只允许切 serving-adapter / acceptance 层，不允许切 owner 身份层。**

---

## 5. Q3 — `true_exit_absorb_gate_v1`

### 5.1 Room 2 结论
> **`review_group` 当前还不具备在本轮一上来进入 true exit 的资格；最多只允许在 B 后半段进入 true-exit-ready judgment，并且只有在 C 才可能被 absorb。**

### 5.2 `review_group` 进入 true exit 的最低技术条件
以下条件缺一不可：
1. **replacement path 已能覆盖 non-continuation + widened serving subset 的 current runtime needs**
2. **active continuation 当前承接路径已被单独验证，不再依赖 current cloud visible owner posture 才能解释清楚**
3. **completion gating / settlement trigger explanation pathway 已有 source-neutral 或 replacement-safe 通路**
4. **rollback target 已从 “必须 current owner” 过渡到 “可 fallback-only anchor” 的资格被证实**
5. **QA / regression 已证明 `review_group` true exit 不会破坏 hold / rollback / parity baseline**
6. **所有 user-visible wording 已清掉 current owner identity 依赖**

### 5.3 当前仍阻止 true exit 的关键原因
1. retained fallback anchor 仍是当前最硬的回退骨架；
2. active continuation 仍是最高风险链路；
3. completion / settlement 解释通路仍不能失去 `review_group` 当前姿态；
4. runtime truth 仍大面积围绕 current cloud serving owner；
5. 当前 closeout 证据仍不足以支持同轮直接 absorb true exit。

### 5.4 Room 2 的判断线
- **A 通过**：可以把 true-exit gate 写硬
- **B 通过**：可以把 true-exit-candidate 推到 true-exit-ready judgment
- **C 通过**：才可能允许 `review_group` true exit 被 absorb

### 5.5 Room 2 的硬句
> **没有 replacement-safe + rollback-safe + completion-safe + wording-safe 的成套证据，`review_group` 不得从 true-exit-candidate 升格为 true exit。**

---

## 6. Q4 — `db_api_uplift_absorb_gate_v1`

### 6.1 Room 2 结论
> **DB/API 当前最多只具备“absorbed judgment”的讨论资格，不具备“baseline uplift absorbed 已可宣告”的资格。**

### 6.2 够格进入 absorbed judgment 的 seam families
当前可进入 absorbed judgment 的，仅限于以下 seam families：
1. serving source descriptor seam
2. retained-anchor / fallback posture seam
3. stronger-ingest path minimal seam
4. rollback / hold / observability seam
5. source-neutral state / helper / summary contract seam

### 6.3 当前仍只能停留在 marker / migration / rollback / hold 层的项目
1. DB schema rewrite
2. API endpoint core semantics rewrite
3. true-exit-dependent seam families
4. active continuation source switch related DB/API rewrites
5. homepage route / planner-aware route related API meaning shifts
6. final fact owner shift related ingest / settlement / ledger rewrites
7. cleanup / old-path purge related hard removal semantics

### 6.4 Active baseline 判断
- **当前 active DB baseline：`v0.2.1`**
- **当前 active API baseline：`v0.2.1`**
- 本轮最多只允许形成 `uplift-absorbed judgment-ready` 或 `uplift-absorbed candidate absorbable` 的判断，不允许直接改 active baseline。

### 6.5 Room 2 的硬句
> **DB/API uplift absorbed 不是“readiness 多跑一轮”就会自动成立；只要 schema / endpoint core meaning / fact-owner implication 还没被完整锁住，就只能停在 judgment。**

---

## 7. Q5 — `fact_owner_cutover_guardrail_v1`

### 7.1 Room 2 结论
> **无论 P3.3.14 的 serving seam 走到哪一步，final fact / settlement owner 当前都必须继续锁在后端 / cloud fact layer。**

### 7.2 当前仍绝不能跟着一起切的 final facts
以下最终事实当前继续以后端为准：
1. effective review fact
2. daily goal progress / completion
3. reward settlement / ledger arrival
4. `check_in / learning_day / streak`
5. completion / 到账类主反馈

### 7.3 stronger-ingest 当前最多允许到哪一层
当前最多允许：
1. 更清楚的 accept / reject / duplicate / progress-candidate / completion-candidate 规则
2. 更清楚的 precondition / postcondition / hold-reason / evidence ownership
3. 与 widened execution subset 直接绑定的最小 ingest contract
4. absorbed judgment 所需的 candidate seam formalization

当前仍不允许：
1. local stronger-ingest 直接裁定 final review fact
2. local stronger-ingest 直接推进 daily completion / settlement / ledger / streak
3. 用 ingest candidate 结果反向替代后端主事实

### 7.4 Room 2 的硬句
> **Serving seam advancement does not equal final fact owner advancement；P3.3.14 当前最应该防的，不是“切得不够多”，而是“切 serving 时顺手把 fact-owner 也切走了”。**

---

## 8. Q6 — `same_round_cleanup_gate_v1`

### 8.1 Room 2 结论
> **cleanup 可以被纳入同轮尾部判断，但默认不保证本轮一定能做；Room 2 的默认立场是“允许进入 C 的判断，不默认允许被吸收”。**

### 8.2 C checkpoint 允许 absorb / cleanup 的最低技术条件
以下条件缺一不可：
1. A judgment lock 已被 Room 1 正式 pin
2. B real execution 的 runtime truth、回归、证据包全部通过
3. `review_group` true exit 已通过 true-exit-ready → true-exit absorb judgment
4. DB/API uplift absorbed 已通过 absorbed judgment
5. fact-owner boundary 继续完整保留
6. rollback / hold 已从 current runtime fallback 过渡到 new absorbed-state rollback floor，并被回归验证
7. cleanup 不会破坏 same-round closeout 的 write-back order

### 8.3 必须 stop at B 的情形
只要出现以下任一情况，必须 stop at B：
1. A judgment lock 不够硬
2. B execution subset 证据不全
3. `review_group` 仍只是 candidate / ready，不是 absorbable
4. DB/API 仍只是 marker / readiness，不是 absorbable
5. fact-owner boundary 出现模糊
6. rollback target 仍依赖 current cloud owner posture
7. cleanup 需要硬删 schema / endpoint / old path 才能成立

### 8.4 Room 2 的硬句
> **cleanup 不是“执行顺手带一下”；它只能是 A 锁死、B 跑通、true exit 与 uplift absorbed 都被证明后，C 才有资格吸收的尾部动作。**

---

## 9. Room 2 给 Room 1 的最小 final program contract

Room 2 建议 Room 1 只 pin 以下 6 个 program-level contracts：

1. **`final_cutover_judgment_lock_v1`**
   - A checkpoint 必须先锁住 runtime truth immovables、rollback floor、true-exit inventory、uplift inventory、fact-owner guardrail、cleanup gating

2. **`real_cutover_execution_subset_v1`**
   - B checkpoint 当前唯一推荐真实切换范围，仍只限于 ReviewPage + 首页 review acceptance layer 的 widened serving-adapter / helper / fallback / stronger-ingest-prep

3. **`true_exit_absorb_gate_v1`**
   - `review_group` 在本轮最多从 true-exit-candidate 走到 true-exit-ready judgment；只有当 replacement-safe + rollback-safe + completion-safe + wording-safe 全部满足时，C 才可能 absorb

4. **`db_api_uplift_absorb_gate_v1`**
   - DB/API 只有 seam-family 层面能进入 absorbed judgment；active baseline 继续保持 `v0.2.1`，直到 C checkpoint 真正通过

5. **`fact_owner_cutover_guardrail_v1`**
   - serving seam advancement、true-exit judgment、DB/API uplift judgment 全都不得带出 final fact owner shift

6. **`same_round_cleanup_gate_v1`**
   - cleanup 允许进入同轮尾部判断，但默认不得自动吸收；若任一前置条件不满足，必须 stop at B

---

## 10. Room 2 的最终一句话

> **P3.3.14 可以合并成最终项目轮次，但技术上仍必须坚持：A 先把“什么绝不能偷切”写死，B 再 very narrowly 真切，C 最后才讨论 absorb / cleanup；只要 true exit、DB/API uplift absorbed、fact-owner guardrail 其中任一项证据不够，本轮就必须停在 B，不得用“已经合并”当作提前生效的理由。**
