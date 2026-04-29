# R1_to_R4_P3_3_13_Execution_Handoff_v0.1.md

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** execution handoff / ready for Room4-治理层
- **Role basis:** `room1_v0.2.0.md`
- **Governance basis:** `ORG_v0.3.1.md`
- **Runtime basis used for this round:** `Main_updated_2026-04-10_v33.md` + `STATUS_updated_2026-04-10_v31.md`
- **Direct upstream inputs:**
  - `R1_P3_3_13_ScopePin_and_Handoff_Pack_v0.1.md`
  - `R2_P3_3_13_FullerCutoverExecution_TrueExitCandidate_and_DBUpliftAbsorbReadiness_Tech_Note_v0.1.md`
  - `R3_P3_3_13_FullerCutoverExecution_TrueExitCandidate_and_DBUpliftAbsorbReadiness_Rules_Note_v0.1.md`
  - `UI_SPEC_P3_3_13_FullerCutoverExecution_TrueExitCandidate_and_DBUpliftAbsorbReadiness_UI_Preflight_v0.1.md`
  - `BR-OPP-001_v0.2.14.md`
  - `UI_SPEC_v0.3.4.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
  - `P3.3.12_Claude_res.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 P3.3.13 这轮已经完成 cross-room 收口的内容，
正式压成一份可交给 **Room4-治理层** 的统一执行任务单。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- runtime owner shift 完成宣告
- `review_group` true exit 公告
- active DB / API baseline uplift absorbed 生效稿
- full cutover / cleanup / old-path purge 方案书
- P3.3.13 closeout

本文件只做一件事：

> **把 P3.3.13 已被 Room 2 / Room 3 / Room 5 收成一致的 “fuller-cutover execution / true-exit-candidate / DB-API uplift-absorb-readiness” 压成一份 very narrow、可执行、可测试、不可误写成 full cutover / true exit / uplift absorbed 的执行 handoff。**

---

## 1. Room 1 吸收后的统一结论

### 1.1 本轮允许进入执行，但只允许进入 **Execution-Ready / Candidate / Readiness Layer**
Room 1 当前接受：

1. **`fuller_cutover_execution_subset_v2` 可进入执行**
   - 但只允许进入 **ReviewPage + 首页 review 承接层** 的 widened execution subset
   - 不得写成 full ReviewPage truth 已切换

2. **`review_group_true_exit_candidate_v1` 可进入执行**
   - 但只允许进入 **true-exit-candidate** 层
   - 不得写成 `review_group` 已 true exit、已不再使用、或可直接清理

3. **`db_api_uplift_absorb_readiness_v1` 可进入执行**
   - 但只允许进入 **uplift-absorb-readiness seam families / marker / migration note / rollback floor / hold note**
   - 不得写成 active DB / API baseline 已 uplift absorbed

4. **`cutover_vs_fact_owner_boundary_v5` 必须进入执行**
   - fuller cutover 当前最多只允许 stronger-ingest candidate 再前进一步
   - final fact / settlement owner 继续以后端为准

5. **`true_exit_candidate_narrowing_guardrail_v1` 可进入执行**
   - 但只允许 very narrow 缩窄 retained-anchor 依赖
   - 不得动 current owner / rollback target / completion gating / settlement trigger 骨架

6. **`phase7_writeback_order_v1` 必须进入执行**
   - execution-ready candidate / true-exit-candidate / uplift-absorb-readiness / runtime truth 的分层顺序必须写硬
   - 没有这个顺序，不允许 P3.3.13 往 fuller subset 真落地

### 1.2 Room 1 因此给 Room 4 的不是“full cutover 单”，而是：
> **P3.3.13 = Fuller-Cutover Execution / True-Exit-Candidate / Uplift-Absorb-Readiness 的 very narrow execution handoff。**

也就是说，本轮允许 Room 4 做：
- ReviewPage + 首页 review 承接层的 widened execution subset 落地
- `review_group` true-exit-candidate 前置条件清单与 very narrow narrowing guardrails
- uplift-absorb-readiness seam families 的 patch-draft / marker / migration / rollback / hold / observability
- stronger-ingest absorb-readiness binding prep
- source-neutral / retained-anchor-aware UI contract 扩大一小层
- regression / write-back / no-major-change statement

但**不允许** Room 4 做：
- runtime owner shift completed
- ReviewPage local-serving full runtime cutover
- `review_group` true exit
- active DB/API baseline uplift absorbed
- homepage route switch
- active continuation source switch
- auto-routing runtime
- final fact owner shift
- cleanup / old-path purge
- DB schema rewrite
- API core semantics rewrite

---

## 2. Room 1 正式 pin 的最小合同集合

### 2.1 `fuller_cutover_execution_subset_v2`
当前正式 pin 为：

#### A. 当前唯一允许进入 execution subset 的扩大方向
只允许：
- **ReviewPage continuity-adjacent serving-adapter family**
- **与其强绑定的 source-neutral helper / summary / empty-state / completion 前置说明层**
- **首页 review helper / summary / no-review-state 的 retained-anchor-aware prep**
- **rollback / hold / fallback 的中性 copy / state contract prep**
- **stronger-ingest absorb-readiness binding prep**

#### B. 当前明确禁止扩大到
1. 首页默认主 route
2. active continuation source switch
3. user-visible planner-aware route / auto-routing runtime
4. `review_group` true exit
5. final fact owner shift
6. active DB/API baseline uplift absorbed
7. cleanup / old-path purge

#### C. 当前语义边界
- `execution subset` = 配得上进入更完整一拍执行层
- 不等于 runtime truth 已整体切换
- 不等于 full cutover 已完成

### 2.2 `review_group_true_exit_candidate_v1`
当前正式 pin 为：

1. `review_group` 当前继续保持：
   - **current runtime serving owner**
   - **retained fallback anchor**
   - **compatibility anchor**
   - **deprecated candidate**

2. 本轮只允许执行：
   - true-exit-candidate 前置条件清单
   - still-dependent paths inventory
   - 哪些 retained-anchor 依赖未来允许 very narrow 缩窄
   - rollback / fallback scope 哪些 future-narrowable

3. 当前不得写成：
   - 已 true exit
   - 已不再使用
   - 已降成 fallback-only
   - old path 可回收
   - cleanup 可开始

4. 当前最小 immobile 骨架
   - rollback target = `cloud_review_group_current_runtime_path`
   - current visible owner 身份
   - retained fallback anchor 身份
   - active continuation 当前承接路径
   - completion gating / settlement trigger 的解释通路

### 2.3 `db_api_uplift_absorb_readiness_v1`
当前正式 pin 为：

1. DB / API 当前只允许进入：
   - uplift-absorb-readiness seam families
   - seam map
   - marker / migration note
   - rollback floor
   - hold note
   - write-back order

2. 当前明确不允许：
   - DB schema rewrite
   - API endpoint core semantics rewrite
   - active baseline uplift absorbed
   - 因 uplift-absorb-readiness 直接改运行态事实

3. `DB / API v0.2.1` 继续是 active baseline 起点

### 2.4 `cutover_vs_fact_owner_boundary_v5`
当前正式 pin 为：

1. fuller cutover 当前允许再前进一步，但只在 serving-adapter family / stronger-ingest candidate 的 very narrow 层
2. 以下最终事实当前仍必须以后端 / cloud fact layer 为准：
   - effective review fact
   - daily goal progress / completion
   - reward settlement / ledger arrival
   - `check_in / learning_day / streak`
   - completion / 到账类主反馈
3. stronger ingest path 当前最多只允许进入 **absorb-readiness-level binding prep**
4. 当前不得写成：
   - local evidence 已成为 final fact
   - reward 已到账
   - daily goal 已完成
   - streak 已续上
   - 学习事实已更新到最终结果

### 2.5 `true_exit_candidate_narrowing_guardrail_v1`
当前正式 pin 为：

1. 本轮最多只允许 very narrow 缩窄：
   - group-only wording 的依赖范围
   - source-neutral helper / summary / empty-state 对 group-only wording 的依赖
   - retained-anchor-aware fallback copy 的覆盖范围优化
   - QA / docs 中对哪些 UI 资产已不再必须 group-only 的判断

2. 当前仍不得缩窄：
   - current visible owner 身份
   - retained fallback anchor 身份
   - rollback target = `cloud_review_group_current_runtime_path`
   - active continuation 当前承接路径
   - current completion gating / settlement trigger 的解释通路
   - compatibility anchor / QA baseline reference

3. 当前 stop conditions 任一触发，默认必须 hold / rollback / escalate：
   - 用户可见 owner-shift / cutover overclaim
   - 用户可见 `review_group` true-exit overclaim
   - active continuation 被静默改写
   - final fact / settlement truth 被误写成新路径结果
   - rollback 后页面主路径解释不通
   - uplift-absorb-readiness 被误写成 uplift absorbed

### 2.6 `phase7_writeback_order_v1`
当前正式 pin 为：

1. 本轮必须至少写硬：
   - execution-preflight absorb
   - execution-ready candidate absorb
   - R1→R4 execution handoff absorb
   - migration note
   - rollback floor
   - hold note
   - no-major-change statement

2. 当前推荐回写顺序：
   - Room 2：execution subset / true-exit-candidate / uplift-absorb-readiness / fact-boundary / narrowing 红线
   - Room 3：业务语义、fact-copy guardrails、must-hold / must-escalate
   - Room 5：页面 / 状态 / wording / fallback guidance
   - Room 1：决定是否形成 very narrow `R1 → R4` execution handoff
   - DB/API：只进入 uplift-absorb-readiness candidate 层，不进 active uplift
   - runtime baseline update：最后单开判断

3. 当前不得写成：
   - 本轮已完成 fuller cutover
   - 本轮已完成 `review_group` true exit
   - 本轮已完成 active DB/API uplift absorbed
   - 本轮可直接 cleanup 旧 path

---

## 3. 给 Room4-治理层的任务定义

### 3.1 目标
完成 P3.3.13 的 **very narrow execution-ready candidate execution**，具体包括：

1. 把 widened subset 收成 **ReviewPage + 首页 review 承接层** 的 execution subset
2. 把 `review_group` true-exit-candidate 的前置条件与 narrowing guardrail 写硬
3. 把 DB / API uplift-absorb-readiness seam families 收成 patch-draft / seam-map / hold-note / rollback floor
4. 把 stronger-ingest absorb-readiness 与 final fact owner 的边界继续写硬
5. 把 UI 的 source-neutral / retained-anchor-aware execution prep 扩大一小层
6. 交付 regression / write-back / no-major-change 的固定证据包

### 3.2 In Scope
1. ReviewPage + 首页 review 承接层的 widened execution subset
2. ReviewPage helper / summary / empty-state / completion 前置说明的 fuller source-neutral prep
3. 首页 review helper / summary / no-review-state 的 retained-anchor-aware prep
4. `review_group` true-exit-candidate 前置条件清单
5. retained-anchor narrowing guardrails
6. uplift-absorb-readiness seam families 的 patch-draft / marker / migration note / rollback floor / hold note
7. stronger-ingest absorb-readiness binding prep
8. runtime truth regression
9. write-back patch draft
10. `no-major-change statement`

### 3.3 Out of Scope
1. full cutover completed
2. runtime owner shift completed
3. `review_group` true exit
4. active DB/API baseline uplift absorbed
5. homepage route switch
6. active continuation source switch
7. auto-routing runtime
8. unified planner / planner merge
9. final fact owner shift
10. cleanup / old-path purge
11. DB schema rewrite
12. API core semantics rewrite
13. 用户可见“已切到新主链路 / `review_group` 已退场 / uplift 已完成 / cutover 已完成”的宣告

---

## 4. 必守依据

Room4-治理层与执行层，本轮必须同时服从以下依据：

### 4.1 推进层 / 主线程
- `Main_updated_2026-04-10_v33.md`
- `STATUS_updated_2026-04-10_v31.md`
- `R1_P3_3_13_ScopePin_and_Handoff_Pack_v0.1.md`

### 4.2 规则 / 事实边界
- `BR-OPP-001_v0.2.14.md`
- `R3_P3_3_13_FullerCutoverExecution_TrueExitCandidate_and_DBUpliftAbsorbReadiness_Rules_Note_v0.1.md`

### 4.3 技术边界
- `R2_P3_3_13_FullerCutoverExecution_TrueExitCandidate_and_DBUpliftAbsorbReadiness_Tech_Note_v0.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

### 4.4 UI / UX 边界
- `UI_SPEC_v0.3.4.md`
- `UI_SPEC_P3_3_13_FullerCutoverExecution_TrueExitCandidate_and_DBUpliftAbsorbReadiness_UI_Preflight_v0.1.md`

---

## 5. Room 4 不得补脑的已收口项

以下点本轮 Room 1 已收口，Room 4 不得二次发明：

1. current runtime truth 继续大面积保持不变
2. ReviewPage 用户可见 serving truth 继续围绕 cloud `review_group`
3. `review_group` 当前仍是 current owner + retained fallback anchor + compatibility anchor + deprecated candidate
4. fuller cutover 当前只允许扩大到 ReviewPage + 首页 review 承接层的 very narrow execution subset
5. 首页继续 `study_default`
6. active continuation 继续独立承接，不得 silent reroute
7. final fact / settlement truth 继续以后端为准
8. DB / API 仍不进入 active uplift，更不进入 core rewrite
9. 任何 execution-ready / true-exit-candidate / uplift-absorb-readiness 结果都不得冒充 runtime truth
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
- `review_group` 已 true exit
- old path 可直接清理
- active DB/API baseline 已升级
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
2. 把 `review_group` 写成已 true exit
3. 一轮内同时做 fuller cutover + true exit + uplift absorbed + cleanup
4. 一轮内把 active continuation source switch 拉进来
5. 一轮内把 homepage route switch 拉进来
6. 一轮内把 final fact owner switch 拉进来
7. 改 DB schema
8. 改 API core semantics
9. 引入用户可见 cutover / true exit / uplift absorbed 生效宣告
10. 没有 rollback / hold / stop-condition / observability 成套证据就推进 widened subset

---

## 7. 推荐执行方式（Room 4 本轮）

### Track A — Fuller-Cutover Execution Subset v2
做：
1. ReviewPage + 首页 review 承接层的 widened execution subset
2. ReviewPage helper / summary / empty-state / completion 前置说明的 fuller source-neutral prep
3. 首页 review helper / summary / no-review-state 的 retained-anchor-aware prep

不做：
- homepage route 切换
- active continuation 切换
- full ReviewPage serving switch

### Track B — True-Exit-Candidate / Retained Anchor
做：
1. `review_group` true-exit-candidate 前置条件清单
2. retained-anchor narrowing guardrails
3. rollback target / fallback scope / still-dependent paths 清单
4. must-hold / must-escalate / stop-condition 证据位

不做：
- `review_group` true exit
- old path cleanup
- fallback-only 宣告

### Track C — DB/API Uplift-Absorb-Readiness
做：
1. uplift-absorb-readiness seam families 的 seam-map
2. marker / migration note / rollback floor / hold note
3. stronger-ingest absorb-readiness binding prep
4. no-major-change statement

不做：
- active DB/API uplift absorbed
- schema rewrite
- endpoint core semantics rewrite

### Track D — Fact Boundary / Regression / Write-back
做：
1. no-final-fact-owner-switch assertions
2. runtime truth regression
3. patch draft / write-back plan
4. observability packet

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
5. 用户端不出现 owner shift / true exit / uplift / cutover completed 类事实

### 8.2 Fuller-Cutover Execution-Ready Layer
1. widened subset 只落在 ReviewPage + 首页 review 承接层
2. ReviewPage continuity-adjacent serving-adapter family 可断言
3. helper / summary / empty-state / completion 前置说明的 fuller source-neutral prep 可断言
4. execution subset 与 runtime truth 明确分开

### 8.3 `review_group` True-Exit-Candidate
1. `review_group` 仍是 current runtime owner
2. `review_group` 同时具备 retained fallback anchor / compatibility anchor / deprecated candidate 标记
3. true-exit-candidate 前置条件清单完整
4. rollback target 继续是 `cloud_review_group_current_runtime_path`
5. 未出现 true exit / cleanup / fallback-only 的实现或文案

### 8.4 DB/API Uplift-Absorb-Readiness
1. uplift-absorb-readiness seam families 清单存在
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
5. **widened subset 是否只落在 ReviewPage + 首页 review 承接层**
6. **`review_group` true-exit-candidate 前置条件是否齐全**
7. **DB/API uplift-absorb-readiness 是否仍停留在 seam families / note / rollback / hold 层**
8. **final fact / settlement boundary 是否守住**
9. **rollback / hold / observability 证据包**
10. **no-major-change statement**
11. **需要哪些文档回写**
    - BR / UI / Main / Status / DB / API / TEST / 其他
12. **是否可 close / 是否需 revise / 是否需 escalate**

---

## 10. Room 1 预期完成定义（Done）

当 Room4-治理层交回结果，且满足以下条件时，Room 1 认为 P3.3.13 本轮可以进入 absorb / close 判断：

1. fuller-cutover execution-ready 的 very narrow subset 已被执行化
2. current runtime truth 大面积保持不变
3. `review_group` true-exit-candidate 前置条件被继续写硬
4. DB/API uplift-absorb-readiness 仍停留在 seam readiness / note / rollback / hold 层
5. final fact / settlement owner 未被偷切
6. rollback / hold / stop-condition / observability 成套存在
7. 未触碰 DB schema / API core semantics / homepage route / active continuation / true exit / uplift absorbed / cleanup bundling
8. 用户端无 overclaim

---

## 11. 一句话 handoff

> **请 Room4-治理层按“P3.3.13 = fuller-cutover execution / true-exit-candidate / DB-API uplift-absorb-readiness”的 very narrow subset 推进：继续只在 ReviewPage + 首页 review 承接层扩大一小层 execution subset，继续把 `review_group` 保留在 current owner + retained fallback anchor 姿态，继续把 DB/API uplift 只写成 absorb-readiness，并把 rollback / hold / observability 做全；不要把本轮做成 full cutover，更不要把 true exit / uplift absorbed / cleanup 绑进来。**
