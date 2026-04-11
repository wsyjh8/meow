# R1_to_R4_P3_3_10_Execution_Handoff_v0.1.md

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** execution handoff / ready for Room4-治理层
- **Role basis:** `room1_v0.2.0.md`
- **Governance basis:** `ORG_v0.3.1.md`
- **Runtime basis used for this round:** `Main_updated_2026-04-10_v30.md` + `STATUS_updated_2026-04-10_v28.md`
- **Direct upstream inputs:**
  - `R1_P3_3_10_ScopePin_and_Handoff_Pack_v0.1.md`
  - `R2_P3_3_10_FullerCutover_ExitGate_and_DBUplift_Tech_Note_v0.1.md`
  - `R3_P3_3_10_FullerCutover_ExitGate_and_DBUplift_Rules_Note_v0.1.md`
  - `UI_SPEC_P3_3_10_FullerCutover_ExitGate_and_DBUplift_UI_Preflight_v0.1.md`
  - `BR-OPP-001_v0.2.11.md`
  - `UI_SPEC_v0.3.1.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
  - `P3.3.9_Claude_res.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 P3.3.10 这轮已经完成 cross-room 收口的内容，
正式压成一份可交给 **Room4-治理层** 的统一执行任务单。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- runtime owner shift 完成宣告
- `review_group` 真退场公告
- active DB / API baseline uplift 生效稿
- full cutover / cleanup / old-path purge 方案书
- P3.3.10 closeout

本文件只做一件事：

> **把 P3.3.10 已被 Room 2 / Room 3 / Room 5 收成一致的 “fuller cutover / `review_group` exit-gate / DB-API uplift judgment” 压成一份 very narrow、可执行、可测试、不可误写成 full cutover / exit / uplift absorbed 的执行 handoff。**

---

## 1. Room 1 吸收后的统一结论

### 1.1 本轮允许进入执行，但只允许进入 **Judgment-Driven Candidate Execution Layer**
Room 1 当前接受：

1. **`fuller_cutover_subset_v1` 可进入执行**
   - 但只允许进入 **ReviewPage 内部更宽一层的 continuity-adjacent serving-adapter family**
   - 不得写成 full ReviewPage current truth 已切换

2. **`review_group_exit_gate_v2` 可进入执行**
   - 但只允许进入 **exit-candidate judgment / preconditions / retained-anchor transition judgment**
   - 不得写成 `review_group` 已退场、可直接清理、或已降成 fallback-only

3. **`db_api_uplift_judgment_v1` 可进入执行**
   - 但只允许进入 **uplift-judgment-ready seam families / hold-note / rollback floor / migration note**
   - 不得写成 active DB/API baseline 已 uplift

4. **`cutover_vs_fact_owner_boundary_v2` 必须进入执行**
   - fuller cutover 当前仍只许动 serving-adapter family / stronger ingest candidate 的很窄一层
   - final fact / settlement owner 继续以后端为准

5. **`retained_anchor_to_exit_transition_v1` 可进入执行**
   - 但只允许进入 retained anchor → exit-candidate 的资格条件判断
   - 不得真的把 retained anchor 改成 fallback-only，更不得触发真实 exit

6. **`phase4_writeback_order_v1` 必须进入执行**
   - judgment / execution-ready candidate / runtime truth 的三层顺序必须写硬
   - 没有这个顺序，就不允许 fuller cutover judgment 往下落

### 1.2 Room 1 因此给 Room 4 的不是“full cutover 单”，而是：
> **P3.3.10 = Fuller-Cutover Judgment / Exit-Gate / Uplift-Judgment 的 very narrow execution handoff。**

也就是说，本轮允许 Room 4 做：
- continuity-adjacent serving-adapter family 的 seam-map / candidate execution prep
- `review_group` exit-gate 前置条件清单与 retained-anchor transition judgment prep
- uplift-judgment-ready seam families 的 patch-draft / marker / rollback / hold / migration note
- stronger ingest candidate 的边界固化
- source-neutral / retained-anchor-aware UI contract 扩大一小层
- regression / write-back / no-major-change statement

但**不允许** Room 4 做：
- runtime owner shift completed
- ReviewPage local-serving full runtime cutover
- `review_group` 真实退场
- active DB/API baseline uplift 生效
- homepage route switch
- active continuation source switch
- final fact owner switch
- cleanup / old-path purge
- DB schema rewrite
- API core semantics rewrite

---

## 2. Room 1 正式 pin 的最小合同集合

### 2.1 `fuller_cutover_subset_v1`
当前正式 pin 为：

#### A. 当前唯一允许讨论并进入 execution-ready candidate 的扩大方向
只允许：
- **ReviewPage continuity-adjacent serving-adapter family**
- **与其强绑定的 source-neutral helper / summary / empty-state / completion 前置说明层**
- **首页 review helper / summary / no-review-state 的 retained-anchor-aware prep**
- **rollback / hold / fallback 的中性 copy / state contract**

#### B. 当前明确禁止扩大到：
1. 首页默认 route
2. active continuation source switch
3. 用户可见 auto-routing / planner-aware route
4. `review_group` 真退场
5. final fact owner shift
6. active DB/API baseline uplift 生效
7. cleanup / old-path purge

### 2.2 `review_group_exit_gate_v2`
当前正式 pin 为：

1. `review_group` 当前继续保持：
   - **current runtime serving owner**
   - **retained fallback anchor**
   - **compatibility anchor**
   - **deprecated candidate**

2. 本轮只允许执行：
   - exit-gate 前置条件清单
   - retained-anchor → exit-candidate 的资格判断
   - rollback target / fallback scope 的判断层

3. 当前不得写成：
   - 已退场
   - 已不再使用
   - 可直接清理
   - 已变成 fallback-only
   - 旧 cloud path 可回收

### 2.3 `db_api_uplift_judgment_v1`
当前正式 pin 为：

1. DB / API 当前只允许进入：
   - uplift-judgment-ready seam families
   - seam map
   - marker / migration note
   - rollback floor
   - hold note
   - write-back order

2. 当前明确不允许：
   - DB schema rewrite
   - API endpoint core semantics rewrite
   - active baseline uplift absorbed
   - 因 uplift judgment 直接改运行态事实

3. `DB / API v0.2.1` 继续是 active baseline 起点

### 2.4 `cutover_vs_fact_owner_boundary_v2`
当前正式 pin 为：

1. fuller cutover 当前允许前进一步，但只在 serving-adapter family / stronger-ingest candidate 的 very narrow 层
2. 以下最终事实当前仍必须以后端 / cloud fact layer 为准：
   - effective review fact
   - daily goal progress / completion
   - reward settlement / ledger arrival
   - `check_in / learning_day / streak`
   - completion / 到账类主反馈
3. stronger ingest path 当前最多只允许进入 uplift-judgment-ready / stronger-path-ready
4. 当前不得写成：
   - local evidence 已成为 final fact
   - reward 已到账
   - daily goal 已完成
   - streak 已续上
   - 学习事实已更新到最终结果

### 2.5 `retained_anchor_to_exit_transition_v1`
当前正式 pin 为：

1. 本轮允许判断：
   - retained anchor 何时才有资格进入 exit-candidate
   - rollback target 哪些 still-fixed、哪些 future-narrowable
   - 哪些 stop conditions 仍必须保留为硬挡板

2. 当前仍不允许：
   - retained anchor 改成 fallback-only
   - exit candidate 直接升级成 exit execution
   - rollback target 从 `cloud_review_group_current_runtime_path` 改掉

3. 当前主 rollback target 继续保持：
   - `cloud_review_group_current_runtime_path`

### 2.6 `phase4_writeback_order_v1`
当前正式 pin 为：

1. 本轮必须至少写硬：
   - judgment note
   - execution-ready candidate note
   - migration note
   - rollback floor
   - hold note
   - no-major-change statement

2. 当前推荐回写顺序：
   - Room 2：fuller-cutover / exit-gate / uplift judgment
   - Room 3：rule set / must-hold / must-escalate / fact-boundary
   - Room 5：runtime-truth guardrails / exit-gate UI guidance / uplift-judgment UI guidance
   - Room 1：决定是否形成 very narrow `R1 → R4` execution handoff
   - DB/API：只进入 uplift-judgment candidate 层，不进 active uplift

3. 当前不得写成：
   - 本轮已完成 fuller cutover
   - 本轮已完成 `review_group` 退场
   - 本轮已完成 active DB/API uplift
   - 本轮可直接 cleanup 旧 path

---

## 3. 给 Room4-治理层的任务定义

### 3.1 目标
完成 P3.3.10 的 **very narrow judgment-driven candidate execution**，具体包括：

1. 把 fuller-cutover 的下一拍扩大方向收成 **ReviewPage continuity-adjacent serving-adapter family**
2. 把 `review_group` retained-anchor → exit-candidate 的前置条件写硬
3. 把 DB/API uplift-judgment-ready seam families 收成 patch-draft / seam-map / hold-note / rollback floor
4. 把 stronger-ingest candidate 与 final fact owner 的边界继续写硬
5. 把 UI 的 source-neutral / retained-anchor-aware prep 扩大一小层
6. 交付 regression / write-back / no-major-change 的固定证据包

### 3.2 In Scope
1. ReviewPage continuity-adjacent serving-adapter family 的 seam-map / candidate execution prep
2. ReviewPage helper / summary / empty-state / completion 前置说明的 fuller source-neutral prep
3. 首页 review helper / summary / no-review-state 的 retained-anchor-aware prep
4. `review_group` exit-gate 前置条件清单
5. retained-anchor → exit-candidate judgment artifacts
6. uplift-judgment-ready seam families 的 patch-draft / marker / migration note / rollback floor / hold note
7. stronger-ingest candidate 的 boundary assertions
8. runtime truth regression
9. write-back patch draft
10. `no-major-change statement`

### 3.3 Out of Scope
1. full cutover completed
2. runtime owner shift completed
3. `review_group` 真退场
4. active DB/API baseline uplift absorbed
5. homepage route switch
6. active continuation source switch
7. auto-routing runtime
8. unified planner / planner merge
9. final fact owner shift
10. cleanup / old path purge
11. DB schema rewrite
12. API core semantics rewrite
13. 用户可见“已切到新主链路 / `review_group` 已退场 / uplift 已生效 / cutover 已完成”的宣告

---

## 4. 必守依据

Room4-治理层与执行层，本轮必须同时服从以下依据：

### 4.1 推进层 / 主线程
- `Main_updated_2026-04-10_v30.md`
- `STATUS_updated_2026-04-10_v28.md`
- `R1_P3_3_10_ScopePin_and_Handoff_Pack_v0.1.md`

### 4.2 规则 / 事实边界
- `BR-OPP-001_v0.2.11.md`
- `R3_P3_3_10_FullerCutover_ExitGate_and_DBUplift_Rules_Note_v0.1.md`

### 4.3 技术边界
- `R2_P3_3_10_FullerCutover_ExitGate_and_DBUplift_Tech_Note_v0.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

### 4.4 UI / UX 边界
- `UI_SPEC_v0.3.1.md`
- `UI_SPEC_P3_3_10_FullerCutover_ExitGate_and_DBUplift_UI_Preflight_v0.1.md`

---

## 5. Room 4 不得补脑的已收口项

以下点本轮 Room 1 已收口，Room 4 不得二次发明：

1. current runtime truth 继续大面积保持不变
2. ReviewPage 用户可见 serving truth 继续围绕 cloud `review_group`
3. `review_group` 当前仍是 current owner + retained fallback anchor + compatibility anchor + deprecated candidate
4. fuller cutover 当前只允许扩大到 ReviewPage continuity-adjacent serving-adapter family
5. 首页继续 `study_default`
6. active continuation 继续独立承接，不得 silent reroute
7. final fact / settlement truth 继续以后端为准
8. DB / API 仍不进入 active uplift，更不进入 core rewrite
9. 任何 judgment / candidate / uplift-ready 结果都不得冒充 runtime truth
10. 用户端不得感知“新主链路已生效”

---

## 6. Room 4 执行护栏

### 6.1 Serving / Owner 护栏
当前继续禁止：
- local 已接管 ReviewPage 全量 current truth
- ReviewPage 主队列全量来自 local due
- `review_group` 已退出运行态
- owner shift 已完成
- full cutover 已完成

### 6.2 Route / Continuation 护栏
当前继续禁止：
- 首页 route 从 `study_default` 被切走
- active continuation 被切到 local path
- planner-aware 首页已生效
- auto-routing / mixed routing 已启用
- silent reroute

### 6.3 Fact / Settlement 护栏
当前继续禁止：
- 已记为有效复习
- 今日目标已推进 / 已完成
- 奖励已到账
- streak 已续上
- 学习事实已更新到最终结果
- local evidence 已成为 final fact

除非 backend fact layer 已明确返回对应 final truth。

### 6.4 Exit / Uplift / Cleanup 护栏
当前继续禁止：
- `review_group` 已退场
- 旧方案即将不可用
- active DB/API baseline 已升级
- 旧 cloud path 可直接清理
- 本轮已完成迁移
- 可直接进入 cleanup absorbed

### 6.5 user-visible overclaim 护栏
当前继续禁止：
- 本地 serving 已全面启用
- ReviewPage 已切到本地队列
- 新主链路已生效
- `review_group` 已退出
- uplift 已完成
- cutover 已完成
- 本地结果已写回最终事实

### 6.6 Major 红线
以下任一动作出现，都视为越界：
1. 把 local wider subset 写成 current ReviewPage full truth
2. 把 `review_group` 写成已退出运行态
3. 一轮内同时做 fuller cutover + exit + uplift + cleanup
4. 一轮内把 active continuation source switch 拉进来
5. 一轮内把 homepage route switch 拉进来
6. 一轮内把 final fact owner switch 拉进来
7. 改 DB schema
8. 改 API core semantics
9. 引入用户可见 cutover / exit / uplift 生效宣告
10. 没有 rollback / hold / stop-condition / observability 成套证据就推进 fuller subset

---

## 7. 推荐执行方式（Room 4 本轮）

### Track A — Fuller Cutover Candidate Prep
做：
1. ReviewPage continuity-adjacent serving-adapter family 的 seam-map
2. ReviewPage helper / summary / empty-state / completion 前置说明的 fuller source-neutral prep
3. 首页 review helper / summary / no-review-state 的 retained-anchor-aware prep

不做：
- homepage route 切换
- active continuation 切换
- full ReviewPage serving switch

### Track B — Exit-Gate Prep
做：
1. `review_group` retained-anchor → exit-candidate 的前置条件清单
2. rollback target / fallback scope / still-dependent paths 清单
3. must-hold / must-escalate / stop-condition 证据位

不做：
- `review_group` 真实退场
- old path cleanup
- fallback-only 宣告

### Track C — DB/API Uplift Judgment Prep
做：
1. uplift-judgment-ready seam families 的 seam-map
2. marker / migration note / rollback floor / hold note
3. no-major-change statement

不做：
- active DB/API uplift
- schema rewrite
- endpoint core semantics rewrite

### Track D — Fact Boundary / Regression / Write-back
做：
1. stronger-ingest candidate 的边界断言
2. no-final-fact-owner-switch assertions
3. runtime truth regression
4. patch draft / write-back plan
5. observability packet

不做：
- final fact owner switch
- 把 stronger ingest candidate 写成 final fact path 已生效

---

## 8. 必测项

Room 4 本轮至少覆盖以下测试 / 自测：

### 8.1 Runtime Truth Regression
1. 首页继续 `study_default`
2. active continuation 继续独立承接
3. ReviewPage 用户可见 serving truth 继续围绕 `review_group`
4. current ReviewPage 主队列未被 local 全量接管
5. 用户端不出现 owner shift / exit / uplift / cutover completed 类事实

### 8.2 Fuller-Cutover Candidate Layer
1. widened subset 只落在 ReviewPage continuity-adjacent serving-adapter family
2. helper / summary / empty-state / completion 前置说明的 fuller source-neutral prep 可断言
3. 首页 review helper / no-review-state 的 retained-anchor-aware prep 可断言
4. execution-ready candidate 与 runtime truth 明确分开

### 8.3 `review_group` Exit-Gate
1. `review_group` 仍是 current runtime owner
2. `review_group` 同时具备 retained fallback anchor / compatibility anchor / deprecated candidate 标记
3. exit-gate 前置条件清单完整
4. rollback target 继续是 `cloud_review_group_current_runtime_path`
5. 未出现 exit / cleanup / fallback-only 的实现或文案

### 8.4 DB/API Uplift Judgment
1. uplift-judgment-ready seam families 清单存在
2. DB/API 仍是 `v0.2.1` active baseline 起点
3. 未改 DB schema
4. 未改 API core semantics
5. hold / rollback / migration note / no-major-change statement 存在

### 8.5 Fact Boundary / Observability
1. local evidence 不直接改 ledger
2. local evidence 不直接改 daily goal final state
3. local evidence 不直接改 streak / learning day final fact
4. no-final-fact-owner-switch assertion 存在
5. observability / stop-condition / must-hold / must-escalate 证据包齐全

---

## 9. 交付物要求

Room4-治理层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **current runtime truth 是否保持不变**
5. **fuller subset 是否只落在 ReviewPage continuity-adjacent serving-adapter family**
6. **`review_group` exit-gate 前置条件是否齐全**
7. **DB/API uplift judgment 是否仍停留在 seam families / note / rollback / hold 层**
8. **final fact / settlement boundary 是否守住**
9. **rollback / hold / observability 证据包**
10. **no-major-change statement**
11. **需要哪些文档回写**
    - BR / UI / Main / Status / DB / API / TEST / 其他
12. **是否可 close / 是否需 revise / 是否需 escalate**

---

## 10. Room 1 预期完成定义（Done）

当 Room4-治理层交回结果，且满足以下条件时，Room 1 认为 P3.3.10 本轮可以进入 absorb / close 判断：

1. fuller-cutover judgment 的 very narrow subset 已被执行化
2. current runtime truth 大面积保持不变
3. `review_group` retained-anchor / exit-gate 前置条件被继续写硬
4. DB/API uplift judgment 仍停留在 seam readiness / note / rollback / hold 层
5. final fact / settlement owner 未被偷切
6. rollback / hold / stop-condition / observability 成套存在
7. 未触碰 DB schema / API core semantics / homepage route / active continuation / full exit / uplift absorbed / cleanup bundling
8. 用户端无 overclaim

---

## 11. 一句话 handoff

> **请 Room4-治理层按“P3.3.10 = fuller cutover / `review_group` exit-gate / DB-API uplift judgment”的 very narrow subset 推进：继续只在 ReviewPage continuity-adjacent serving-adapter family 扩大一小层，继续把 `review_group` 保留在 current owner + retained fallback anchor 姿态，继续把 DB/API uplift 只写成 seam readiness judgment，并把 rollback / hold / observability 做全；不要把本轮做成 full cutover，更不要把 exit / uplift / cleanup 绑进来。**
