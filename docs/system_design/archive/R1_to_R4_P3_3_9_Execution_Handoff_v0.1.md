# R1_to_R4_P3_3_9_Execution_Handoff_v0.1.md

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-11
- **Status:** execution handoff / ready for Room4-治理层
- **Role basis:** `room1_v0.2.0.md`
- **Governance basis:** `ORG_v0.3.1.md`
- **Runtime basis used for this round:** `Main_updated_2026-04-10_v29.md` + `STATUS_updated_2026-04-10_v27.md`
- **Direct upstream inputs:**
  - `R1_P3_3_9_ScopePin_and_Handoff_Pack_v0.1.md`
  - `R2_P3_3_9_FirstVeryNarrowCutover_Tech_Note_v0.1.md`
  - `R3_P3_3_9_FirstVeryNarrowCutover_Rules_Note_v0.1.md`
  - `UI_SPEC_P3_3_9_FirstVeryNarrowCutover_UI_Preflight_v0.1.md`
  - `BR-OPP-001_v0.2.10.md`
  - `UI_SPEC_v0.3.0.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`
  - `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`
  - `P3.3.8_Claude_res.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 P3.3.9 这轮已经完成 cross-room 收口的内容，
正式压成一份可交给 **Room4-治理层** 的统一执行任务单。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- runtime owner shift 完成宣告
- `review_group` 退场公告
- full cutover / cleanup / baseline uplift 方案书
- P3.3.9 closeout

本文件只做一件事：

> **把 P3.3.9 已被 Room 2 / Room 3 / Room 5 收成一致的“第一轮 very narrow cutover”，压成一份 very narrow、可执行、可测试、不可误写成 full cutover / cleanup bundling 的执行 handoff。**

---

## 1. Room 1 吸收后的统一结论

### 1.1 本轮允许进入执行，但只允许进入 **First Very Narrow Cutover Execution Layer**
Room 1 当前接受：

1. **`first_cutover_subset_v1` 可进入执行**
   - 但只允许切 **ReviewPage 的 non-continuation serving subset**
   - 不得写成 ReviewPage 全量 current truth 切换

2. **`runtime_truth_switch_boundary_v1` 可进入执行**
   - 但只允许切 **ReviewPage 内部 queue-source / serving-adapter seam**
   - 不得切首页 route、active continuation、或 final fact owner

3. **`review_group_retained_anchor_v1` 可进入执行**
   - `review_group` 当前继续是 **current runtime owner**
   - 同时进入 **retained fallback anchor + compatibility anchor + deprecated candidate**
   - 不得写成已退场、已不再使用、或可直接清理

4. **`fact_owner_guardrail_v1` 必须进入执行**
   - serving seam 可以 very narrow 切一小段
   - 但 final fact / settlement truth 继续以后端 / cloud fact layer 为准
   - local-serving 结果不得直接改 reward / ledger / daily_goal / streak / learning_day

5. **`db_api_cutover_candidate_v2` 可进入执行**
   - 但只允许进入 first-cutover-ready seam families
   - 不得改 DB schema、不得改 API core semantics、不得做 active baseline uplift

6. **`rollback_holdnote_and_observability_v1` 必须进入执行**
   - rollback floor / hold note / stop conditions / observability floor 必须成套进入
   - 没有这些就不允许 first cutover 真落地

### 1.2 Room 1 因此给 Room 4 的不是“full cutover 单”，而是：
> **First Very Narrow Cutover / ReviewPage internal serving seam execution handoff。**

也就是说，本轮允许 Room 4 做：
- ReviewPage **non-continuation serving subset** 的极窄 source seam 切换
- retained anchor / fallback / rollback hooks
- source-neutral state contract / helper / summary / empty-state / continuation copy neutralization
- stronger ingest candidate 的最小 evidence path
- hold / rollback / stop-condition / observability floor
- regression / write-back / no-major-change statement

但**不允许** Room 4 做：
- runtime owner shift completed
- ReviewPage local-serving full runtime cutover
- `review_group` 退出运行态
- 首页 route 切换
- active continuation 改到 local path
- auto-routing runtime
- planner merge / unified planner
- final fact owner shift
- cleanup bundling
- active DB/API baseline uplift
- DB schema rewrite
- API core semantics rewrite

---

## 2. Room 1 正式 pin 的最小合同集合

### 2.1 `first_cutover_subset_v1`
当前正式 pin 为：

#### A. 本轮唯一允许的 first-cutover 子集
只允许：
- **ReviewPage 的 non-continuation serving subset**
- 仅限 “当前不存在 active `review_group` continuation，且满足更窄 eligibility / stop-condition / hold-note 的情形”

#### B. 本轮真正允许切的层
只允许：
1. queue source selection 的一小段 runtime seam
2. local-serving candidate 对 item stream / next-review payload 的 very narrow 提供能力
3. retained-anchor + rollback hooks + observability
4. 与该 seam 强绑定的 source-neutral state / helper / summary / empty-state / continuation copy neutralization

#### C. 本轮明确不切的层
不切：
1. 首页 `study_default`
2. active continuation 承接方式
3. `review_group` 真实退场
4. final fact / settlement owner
5. reward ledger / daily_goal / streak / learning_day 最终事实
6. active DB/API baseline uplift

### 2.2 `runtime_truth_switch_boundary_v1`
当前正式 pin 为：

1. 当前唯一允许进入 first-cutover 的 runtime-truth switch 候选，是：
   - **ReviewPage 内部“当前一组复习项从哪里来”的极小 serving seam**
2. 以下 runtime truth 继续保持不变：
   - 首页继续 `home_word_entry = study_default`
   - active continuation 继续独立承接，不得 silent reroute
   - `review_group` 当前继续是 current runtime serving owner
   - final fact / settlement truth 继续以后端为准
   - preview / explanation 不得借本轮升级成 committed plan fact
3. 即使这个 seam 进入 very narrow switch，也不得顺手改写：
   - 首页 summary truth
   - active continuation 高优先语义
   - group completion / settlement truth
   - reward / daily goal / streak / learning day 结果表达

### 2.3 `review_group_retained_anchor_v1`
当前正式 pin 为：

1. `review_group` 当前最稳姿态是：
   - **current runtime owner**
   - **retained fallback anchor**
   - **compatibility anchor**
   - **deprecated candidate**
2. 本轮 `review_group` 的保留作用包括：
   - current visible owner
   - rollback target
   - fallback anchor
   - compatibility anchor
3. 当前不得写成：
   - 已退场
   - 已不再使用
   - 可直接清理旧 path
   - 已切换成 fallback-only
4. 任何需要把 `review_group` 从 dual posture 提前改成 fallback-only 的动作，必须升级，不得在本轮自行吸收

### 2.4 `fact_owner_guardrail_v1`
当前正式 pin 为：

1. first cutover 当前只允许切 serving seam，不允许切 final fact owner
2. 以下最终事实当前仍必须以后端 / cloud fact layer 为准：
   - effective review fact
   - daily goal progress / completion
   - reward settlement / ledger arrival
   - `check_in / learning_day / streak`
   - completion / 到账类主反馈
3. 即使 future local-serving subset 真被切一小段，当前也只能写：
   - 继续复习
   - 当前可继续
   - 当前暂不可继续
   - 当前暂无可继续内容
4. 当前继续禁止：
   - 已记为有效复习
   - 今日目标已推进 / 已完成
   - 奖励已到账
   - streak 已续上
   - 学习事实已更新到最终结果
   - 本地结果已写回最终事实

### 2.5 `db_api_cutover_candidate_v2`
当前正式 pin 为：

1. 当前只允许 pin：
   - first-cutover-ready seam families
   - seam / marker / evidence / rollback floor
2. UI / helper / state 至少需要能表达以下 seam：
   - ReviewPage source seam
   - continuation / helper seam
   - fact / settlement seam
   - migration posture seam
3. 当前明确不进入：
   - DB schema rewrite
   - API endpoint core semantics rewrite
   - new active baseline uplift
   - `review_group` exit wording
   - route 切换结果字段的用户展示

### 2.6 `rollback_holdnote_and_observability_v1`
当前正式 pin 为：

1. rollback floor 至少必须有：
   - rollback trigger
   - rollback target（回到 `review_group` cloud-serving truth）
   - rollback owner
   - rollback evidence
   - rollback 完成后的 runtime truth 明示语句
   - “本轮未切 final fact owner” 的明示语句

2. hold note 最低结构至少要有：
   - hold reason
   - affected subset
   - current fallback path
   - user-visible truth remains unchanged 说明
   - next action / owner

3. stop conditions 触发任一项，默认必须 hold 或 rollback：
   - local subset 被写成 current ReviewPage full truth
   - active continuation 被误切到 local path
   - local evidence 直接改 final ledger / daily_goal / streak / learning_day / settlement
   - 首页 route 被 silent 改成 planner-aware / auto-routing
   - 用户端出现 local-serving enabled / owner shift completed / review_group exited / cutover completed 类 overclaim
   - 需要改 DB schema 或 API core semantics 才能让本轮 subset 成立
   - 回滚路径不存在或不可验证
   - compare / QA / debug evidence 无法稳定复现

4. observability floor 至少要补：
   - subset hit / miss evidence
   - retained-anchor engaged evidence
   - rollback engaged evidence
   - hold engaged evidence
   - compare mismatch bucket evidence
   - no-final-fact-owner-switch assertion evidence
   - user-visible overclaim guard check

---

## 3. 给 Room4-治理层的任务定义

### 3.1 目标
完成 P3.3.9 的 **First Very Narrow Cutover**，具体包括：

1. 在 ReviewPage 中，对 **non-continuation serving subset** 做第一拍极窄 source seam 切换
2. 保留 `review_group` 的 current owner + retained fallback anchor 双重姿态
3. 不切首页 route、不切 active continuation、不切 final fact owner
4. 让 stronger ingest candidate 只停在最小 evidence-path / guardrail 层
5. 把 rollback / hold / stop-condition / observability 成套落地
6. 交付 regression / write-back / no-major-change 的固定证据包

### 3.2 In Scope
1. ReviewPage **non-continuation serving subset** first-cutover
2. ReviewPage source-neutral state contract
3. ReviewPage serving-adapter seam
4. 与其强绑定的 helper / summary / CTA / empty-state / continuation copy neutralization
5. retained-anchor / fallback / rollback hooks
6. stronger ingest candidate 的最小 evidence path
7. hold / rollback / stop-condition / observability floor
8. runtime truth regression
9. write-back patch draft
10. `no-major-change statement`

### 3.3 Out of Scope
1. runtime owner shift completed
2. ReviewPage local-serving full runtime cutover
3. `review_group` 退出运行态
4. 首页默认 route 切换
5. active continuation 改到 local path
6. auto-routing runtime
7. planner merge / unified planner
8. final fact owner shift
9. cleanup / old path purge
10. active DB/API baseline uplift
11. DB schema 重构
12. API core semantics 重写
13. 用户可见“已切到本地规划 / 本地已接管复习 / `review_group` 已退场 / cutover 已完成”的宣告

---

## 4. 必守依据

Room4-治理层与执行层，本轮必须同时服从以下依据：

### 4.1 推进层 / 主线程
- `Main_updated_2026-04-10_v29.md`
- `STATUS_updated_2026-04-10_v27.md`
- `R1_P3_3_9_ScopePin_and_Handoff_Pack_v0.1.md`

### 4.2 规则 / 事实边界
- `BR-OPP-001_v0.2.10.md`
- `R3_P3_3_9_FirstVeryNarrowCutover_Rules_Note_v0.1.md`

### 4.3 技术边界
- `R2_P3_3_9_FirstVeryNarrowCutover_Tech_Note_v0.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

### 4.4 UI / UX 边界
- `UI_SPEC_v0.3.0.md`
- `UI_SPEC_P3_3_9_FirstVeryNarrowCutover_UI_Preflight_v0.1.md`

---

## 5. Room 4 不得补脑的已收口项

以下点本轮 Room 1 已收口，Room 4 不得二次发明：

1. current runtime truth 继续大面积保持不变
2. ReviewPage current visible serving truth 继续围绕 cloud `review_group`
3. `review_group` 当前仍是 current owner + retained fallback anchor + compatibility anchor + deprecated candidate
4. 本轮真正允许切的，只有 ReviewPage 内部 **non-continuation serving seam**
5. 首页继续 `study_default`
6. active continuation 继续高优先且独立承接，不得 silent reroute
7. final fact / settlement truth 继续以后端为准
8. DB / API 仍不进入 core rewrite
9. cleanup / `review_group` exit / active DB/API uplift 继续后置
10. 用户端不得感知“新 serving 已生效”

---

## 6. Room 4 执行护栏

### 6.1 Serving / Owner 护栏
当前继续禁止：
- local 已接管 ReviewPage 全量 current truth
- 当前复习队列全量来自 local due
- `review_group` 已退出运行态
- current ReviewPage 已不再依赖 `review_group`
- owner shift 已完成
- local-serving full cutover 已完成

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
- 今日目标已推进
- 奖励已到账
- streak 已续上
- 学习事实已更新到最终结果
- local evidence 已成为 final fact

除非 backend fact layer 已明确返回对应 final truth。

### 6.4 `review_group` / Cleanup 护栏
当前继续禁止：
- `review_group` 已退场
- 旧方案即将不可用
- 当前已不再使用 `review_group`
- 可直接清理旧 cloud path
- 已完成兼容切换 / cutover
- active DB/API baseline 已升级

### 6.5 user-visible overclaim 护栏
当前继续禁止：
- 本地 serving 已启用
- ReviewPage 已切到本地队列
- 当前复习队列来自本地 due
- 已自动安排学习路径
- cutover 已完成
- 本地结果已写回最终事实
- 新主链路已生效
- 现在已按本地主 serving 运行

### 6.6 Major 红线
以下任一动作出现，都视为越界：
1. 把 local subset 写成 current ReviewPage full truth
2. 把 `review_group` 写成已退出运行态
3. 一轮内同时做 serving cutover + fact owner shift
4. 一轮内同时做 cutover + cleanup
5. 一轮内同时做 cutover + active DB/API baseline uplift
6. 改 DB schema
7. 改 current endpoint core semantics
8. 开启首页 planner-aware / auto-routing runtime
9. 引入用户可见 cutover-completed / owner-shift-completed 宣告
10. 没有 rollback floor 就进入 cutover execution

---

## 7. 推荐执行方式（Room 4 本轮）

### Track A — ReviewPage Very Narrow Serving Cutover
做：
1. 只切 ReviewPage **non-continuation serving subset**
2. 只切 queue-source / serving-adapter seam
3. 保留 `review_group` current visible owner + retained fallback anchor
4. source-neutral state naming / helper / summary / empty-state / continuation copy neutralization

不做：
- 全量 ReviewPage serving switch
- active continuation 切换
- 首页 route 切换

### Track B — Retained Anchor / Rollback / Hold
做：
1. retained-anchor hooks
2. rollback hooks
3. hold note
4. stop-condition enforcement
5. rollback-ready / hold-if-crossed 的证据位

不做：
- `review_group` exit
- 旧 path 清理
- 用户可见“已切换 / 已回退 / 已升级”术语

### Track C — Fact / Settlement Guardrails
做：
1. stronger ingest candidate 的最小 evidence path
2. no-final-fact-owner-switch assertions
3. backend-confirmed final fact 才允许结果型反馈

不做：
- final fact owner switch
- reward / daily goal / streak / learning day 结果跟随 serving seam 一起切

### Track D — Regression / Write-back
做：
1. runtime truth regression
2. subset hit / miss evidence
3. retained-anchor engaged evidence
4. rollback / hold / mismatch bucket evidence
5. patch draft / write-back plan
6. `no-major-change statement`

不做：
- 把 first cutover 写成 full cutover 完成
- 跳过 closeout 直接要求 Room 1 吸收到 cleanup / exit / uplift 阶段

---

## 8. 必测项

Room 4 本轮至少覆盖以下测试 / 自测：

### 8.1 Runtime Truth Regression
1. 首页继续 `study_default`
2. active continuation 继续独立承接
3. ReviewPage 用户可见 serving truth 仍围绕 `review_group`
4. current ReviewPage 主队列未被 local 全量接管
5. 用户端不出现 local serving enabled / owner shift completed / cutover completed 类事实

### 8.2 First-Cutover Subset
1. `first_cutover_subset_v1` 只落在 ReviewPage non-continuation serving subset
2. queue-source / serving-adapter seam 可断言
3. local subset 只进入 very narrow 范围
4. helper / summary / empty-state / continuation copy 中和后不误导

### 8.3 Retained Anchor / Rollback / Hold
1. `review_group` 仍是 current runtime owner
2. `review_group` 同时具备 retained fallback anchor / compatibility anchor / deprecated candidate 标记
3. rollback target = cloud `review_group` truth
4. hold / rollback / stop-condition 可断言
5. 回滚后页面仍能被解释为 current runtime truth

### 8.4 Fact / Settlement Guardrails
1. local evidence 不直接改 ledger
2. local evidence 不直接改 daily goal final state
3. local evidence 不直接改 streak / learning day final fact
4. backend-confirmed final fact 才驱动结果型反馈
5. UI / helper / summary / toast 不出现 overclaim

### 8.5 No Major Change / Write-back
1. 未改 DB schema
2. 未改 API core semantics
3. 未做 cleanup / `review_group` exit / active DB/API uplift
4. `no-major-change statement` 存在
5. patch draft / write-back plan 清单齐全

---

## 9. 交付物要求

Room4-治理层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **current runtime truth 是否保持不变**
5. **first-cutover subset 是否只落在 ReviewPage non-continuation serving seam**
6. **`review_group` retained-anchor / rollback target 是否守住**
7. **final fact / settlement boundary 是否守住**
8. **是否触碰核心契约的判断**
9. **rollback / hold / observability 证据包**
10. **no-major-change statement**
11. **需要哪些文档回写**
    - BR / UI / Main / Status / DB / API / TEST / 其他
12. **是否可 close / 是否需 revise / 是否需 escalate**

---

## 10. Room 1 预期完成定义（Done）

当 Room4-治理层交回结果，且满足以下条件时，Room 1 认为 P3.3.9 本轮可以进入 absorb / close 判断：

1. first very narrow cutover 的 very narrow subset 已落地
2. current runtime truth 大面积保持不变
3. `review_group` retained-anchor / rollback target / current owner 姿态被守住
4. final fact / settlement owner 未被偷切
5. rollback / hold / stop-condition / observability 成套存在
6. 未触碰 DB schema / API core semantics / runtime route / active continuation / cleanup bundling / active DB/API uplift
7. 用户端无 overclaim

---

## 11. 一句话 handoff

> **请 Room4-治理层按“第一轮 very narrow cutover”的极窄子集推进 P3.3.9：只切 ReviewPage 的 non-continuation serving seam，保留 `review_group` 为 current owner + retained fallback anchor，守住 final fact / settlement cloud-owner 边界，并把 rollback / hold / observability 做全；不要把本轮做成 full cutover，更不要把 cleanup / `review_group` exit / active DB/API uplift 绑进来。**
