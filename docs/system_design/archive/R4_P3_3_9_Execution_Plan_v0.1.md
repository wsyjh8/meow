# R4_P3_3_9_Execution_Plan_v0.1.md

- **Owner:** Room 4（治理层）
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** ready for execution
- **Role basis:** `ROOM04_治理版_v0.2.md`
- **Direct upstream input:** `R1_to_R4_P3_3_9_Execution_Handoff_v0.1.md`

---

## 0. 一句话定位

本稿不是代码实现记录，也不是新的 BR / DB / API / UI 主文档。  
本稿只做一件事：

> **把 Room 1 已经收口完成的 P3.3.9 结论，压成一份可直接交给 Room 4 执行层（Claude Code）的短而硬执行任务单。**

---

## 1. Room 4 当前判断

### 1.1 本轮是否可以开工
> **可以开工。**

### 1.2 本轮开工的性质
> **这是 `First Very Narrow Cutover / ReviewPage internal serving seam` 的极窄执行层，不是 full cutover，也不是 runtime owner shift / local-serving full runtime cutover。**

### 1.3 Room 4 采用口径
- 继续服从 **Room 1 已 pin / 已指定的 review basis**
- 不自动把 `BR-OPP-001_v0.2.10.md` 与 `UI_SPEC_v0.3.0.md` 写成 runtime active truth
- `DB/API v0.2.1` 继续视为 current active baseline 起点
- 本轮只推进：
  - ReviewPage non-continuation serving subset 的极窄 source seam
  - retained anchor / rollback target / hold / observability
  - stronger ingest candidate 的最小 evidence path
  - 与该 seam 强绑定的 source-neutral state / helper / summary / empty-state / continuation copy neutralization
  - regression / write-back / no-major-change statement
- 不推进：
  - full cutover
  - runtime owner shift completed
  - ReviewPage local-serving full runtime cutover
  - `review_group` 退场
  - 首页 route 切换
  - active continuation 改走 local path
  - auto-routing runtime
  - planner merge / unified planner
  - final fact owner shift
  - cleanup bundling
  - active DB/API baseline uplift
  - DB schema rewrite
  - API core semantics rewrite

### 1.4 本轮是否需要先升级
> **默认不需要先升级。**

但若执行层在实现中发现以下情况，必须立即升级，不得自行补脑推进：

1. 需要改 DB schema
2. 需要改 API core semantics
3. 需要改 `review_group` 最小合同
4. 需要把 local-serving subset 写成 ReviewPage 全量 current truth
5. 需要把首页“背单词”做成 silent reroute / auto-routing runtime
6. 需要改 active continuation 的承接路径
7. 需要让 local 直接改 final fact / settlement / ledger / daily_goal / streak / learning_day
8. 需要把 `review_group` 写成已退场 / 已不再使用 / 可直接清理
9. 需要把本轮做成 full cutover / cleanup / uplift bundling

---

## 2. 本轮目标

完成 **P3.3.9 — First Very Narrow Cutover Round** 的 **First Very Narrow Cutover Execution Layer**，具体包括：

1. 落地 `first_cutover_subset_v1`
2. 落地 `runtime_truth_switch_boundary_v1`
3. 落地 `review_group_retained_anchor_v1`
4. 落地 `fact_owner_guardrail_v1`
5. 落地 `db_api_cutover_candidate_v2`
6. 落地 `rollback_holdnote_and_observability_v1`
7. 交回 patch / sync draft 与 `no-major-change statement`

---

## 3. In Scope

### 3.1 `first_cutover_subset_v1`
本轮纳入：
1. **ReviewPage 的 non-continuation serving subset**
2. 仅限“当前不存在 active `review_group` continuation，且满足更窄 eligibility / stop-condition / hold-note 的情形”
3. queue-source / serving-adapter seam 的极窄 runtime 切换
4. local-serving candidate 对 item stream / next-review payload 的 very narrow 提供能力
5. retained-anchor + rollback hooks + observability
6. 与该 seam 强绑定的 source-neutral state / helper / summary / empty-state / continuation copy neutralization

### 3.2 `runtime_truth_switch_boundary_v1`
本轮纳入：
1. 只切 **ReviewPage 内部 queue-source / serving-adapter seam**
2. 只在 ReviewPage 内部发生
3. 不切首页 route
4. 不切 active continuation
5. 不切 final fact owner
6. 不切 preview / explanation contract

### 3.3 `review_group_retained_anchor_v1`
本轮纳入：
1. `review_group` 继续是 **current runtime owner**
2. `review_group` 同时进入：
   - retained fallback anchor
   - compatibility anchor
   - deprecated candidate
3. rollback target = cloud `review_group` truth
4. hold / rollback / stop-condition 发生时，必须能稳定回落到 `review_group` 路径

### 3.4 `fact_owner_guardrail_v1`
本轮纳入：
1. stronger ingest candidate 的最小 evidence path
2. no-final-fact-owner-switch assertions
3. backend-confirmed final fact 才允许结果型反馈
4. local evidence 不直接改：
   - ledger
   - daily goal final state
   - streak / learning day final fact
   - settlement 最终事实

### 3.5 `db_api_cutover_candidate_v2`
本轮纳入：
1. first-cutover-ready seam families
2. seam / marker / evidence / rollback floor 层
3. patch draft / note draft / write-back reference
4. 但不触碰 schema / endpoint core rewrite / active baseline uplift

### 3.6 `rollback_holdnote_and_observability_v1`
本轮纳入：
1. rollback floor
2. hold note
3. stop conditions
4. observability floor
5. evidence / logging / QA packet
6. first-cutover 回写要求

---

## 4. Out of Scope

1. full cutover
2. runtime owner shift completed
3. ReviewPage local-serving full runtime cutover
4. `review_group` 真实退场
5. 首页 `study_default` route 切换
6. active continuation source switch
7. final fact owner shift
8. reward / ledger / daily_goal / streak / learning_day 最终事实切换
9. cleanup / old path purge
10. active DB/API baseline uplift
11. DB schema 重构
12. API core semantics 重写
13. auto-routing runtime
14. planner merge / unified planner
15. 用户可见“已切换 / 已回退 / 已升级”术语

---

## 5. 必守依据

### 要按需读文档，不需要一次性读完

### 5.1 推进层 / 主线程
- `R1_to_R4_P3_3_9_Execution_Handoff_v0.1.md`
- `R1_P3_3_9_ScopePin_and_Handoff_Pack_v0.1.md`
- `Main_updated_2026-04-10_v29.md`
- `STATUS_updated_2026-04-10_v27.md`

### 5.2 规则 / 事实边界
- `BR-OPP-001_v0.2.10.md`
- `R3_P3_3_9_FirstVeryNarrowCutover_Rules_Note_v0.1.md`

### 5.3 技术边界
- `R2_P3_3_9_FirstVeryNarrowCutover_Tech_Note_v0.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `背单词喵喵app_主机制prd_v0.3.1_P3.1.md`

### 5.4 UI / UX 边界
- `UI_SPEC_v0.3.0.md`
- `UI_SPEC_P3_3_9_FirstVeryNarrowCutover_UI_Preflight_v0.1.md`

### 5.5 治理依据
- `ORG_v0.3.1.md`
- `ROOM04_治理版_v0.2.md`

---

## 6. Room 4 不得补脑的已收口项

以下点本轮已被 Room 1 收口，Room 4 不得二次发明：

1. **P3.3.9 是 first very narrow cutover，不是 full cutover**
2. **current runtime truth 仍在 cloud `review_group`**
3. **首页继续 `home_word_entry = study_default`**
4. **active continuation 继续独立承接，不得 silent reroute**
5. **`review_group` 当前仍是 current runtime owner，同时也是 retained fallback anchor / compatibility anchor / deprecated candidate**
6. **final fact / settlement truth 继续以后端为准**
7. **本轮必须保留 rollback / hold / stop-condition / observability**
8. **cleanup / `review_group` exit / active DB/API uplift 继续后置**

---

## 7. Room 4 执行护栏

### 7.1 `first_cutover_subset_v1` 护栏
当前唯一允许进入 first-cutover 的 subset：
- **ReviewPage non-continuation serving subset**

当前允许切的层：
1. queue source selection 的一小段 runtime seam
2. local-serving candidate 对 item stream / next-review payload 的 very narrow 提供能力
3. retained-anchor + rollback hooks + observability
4. 与该 seam 强绑定的 source-neutral helper / summary / empty-state / continuation copy neutralization

当前禁止：
1. ReviewPage 全量 current truth 切换
2. 首页 route 切换
3. active continuation 改路由
4. final fact owner shift
5. `review_group` 真实退场
6. cleanup bundling
7. active DB/API baseline uplift

### 7.2 `runtime_truth_switch_boundary_v1` 护栏
当前允许 very narrow 切换的唯一 runtime truth：
- **ReviewPage 内部 queue-source / serving-adapter seam**

以下 runtime truths 继续保持不变：
1. 首页 `home_word_entry = study_default`
2. active continuation 独立承接
3. `review_group` 作为 current runtime owner 的主路径事实
4. Review summary / completion / settlement final fact
5. reward / ledger / daily_goal / streak / learning_day 的最终事实
6. 用户可见的 owner-shift / local-serving enabled / cutover completed 类模式声明

### 7.3 `review_group_retained_anchor_v1` 护栏
`review_group` 当前必须继续同时保持：
1. **current runtime owner**
2. **retained fallback anchor**
3. **compatibility anchor**
4. **deprecated candidate**

当前禁止写成：
- 已退场
- 已删除
- 已不再使用
- 已被 local 替代
- 可直接清理旧 cloud path

### 7.4 `fact_owner_guardrail_v1` 护栏
当前允许进入：
1. stronger ingest candidate 的最小 evidence path
2. no-final-fact-owner-switch assertions
3. backend-confirmed final fact 才驱动结果型反馈

当前禁止进入：
1. local 直接改 final fact
2. local 直接改 reward settlement / ledger
3. local 直接改 `daily_goal_status`
4. local 直接改 `check_in / learning_day / streak`
5. serving subset 切换带出 fact owner shift

### 7.5 UI / Copy / Overclaim 护栏
以下表达本轮不得出现于用户侧：
- 本地 serving 已启用
- ReviewPage 已切到本地队列
- owner shift 已完成
- `review_group` 已退场
- auto-routing 已开启
- planner-aware 首页已生效
- 本地 evidence 已直接成为 final fact
- 当前已完成兼容切换 / cutover
- 已切到本地规划
- 已接管奖励结算

### 7.6 Stop-condition 护栏
以下任一出现，本轮必须 hold / rollback / escalate：
1. current runtime truth 被偷切
2. active continuation 被 local path 接管
3. `study_default` 被静默改路由
4. local evidence 触发 final ledger / daily_goal / streak / learning_day write
5. `review_group` posture 被破坏
6. 没有 rollback floor 就要求继续 cutover
7. candidate framing 需要先改 DB schema / API core semantics 才能成立

---

## 8. 本轮最小执行策略（Room 4 默认采用）

执行层本轮如果要做 first-cutover，只允许：

1. **先切 ReviewPage non-continuation serving seam，不切其它主路径**
2. **先保留 `review_group` 为 current owner + retained fallback anchor**
3. **先把 rollback / hold / stop-condition / observability 做全**
4. **先把 helper / summary / empty-state / continuation copy 做 source-neutral 中和**
5. **先把 stronger ingest candidate 维持在 evidence-path，不切 final fact owner**
6. **先交 patch / sync draft 与 no-major-change statement**
7. **不做 cleanup / exit / uplift bundling**

---

## 9. 必测项

### 9.1 Runtime Truth Regression
1. 首页继续 `study_default`
2. active continuation 继续独立承接
3. ReviewPage 用户可见 serving truth 仍围绕 `review_group`
4. current ReviewPage 主队列未被 local 全量接管
5. 用户端不出现 local serving enabled / owner shift completed / cutover completed 类事实

### 9.2 First-Cutover Subset
1. `first_cutover_subset_v1` 只落在 ReviewPage non-continuation serving subset
2. queue-source / serving-adapter seam 可断言
3. local subset 只进入 very narrow 范围
4. helper / summary / empty-state / continuation copy 中和后不误导

### 9.3 Retained Anchor / Rollback / Hold
1. `review_group` 仍是 current runtime owner
2. `review_group` 同时具备 retained fallback anchor / compatibility anchor / deprecated candidate 标记
3. rollback target = cloud `review_group` truth
4. hold / rollback / stop-condition 可断言
5. 回滚后页面仍能被解释为 current runtime truth

### 9.4 Fact / Settlement Guardrails
1. local evidence 不直接改 ledger
2. local evidence 不直接改 daily goal final state
3. local evidence 不直接改 streak / learning day final fact
4. backend-confirmed final fact 才驱动结果型反馈
5. UI / helper / summary / toast 不出现 overclaim

### 9.5 No Major Change / Write-back
1. 未改 DB schema
2. 未改 API core semantics
3. 未做 cleanup / `review_group` exit / active DB/API uplift
4. `no-major-change statement` 存在
5. patch draft / write-back plan 清单齐全

---

## 10. 执行层交付物要求

执行层交回时，至少要包含：

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

## 11. Room 4 验收判断口径

只有同时满足以下条件，Room 4 才会给出 `accept / 可 closeout` 倾向：

1. first very narrow cutover 的 very narrow subset 已落地
2. current runtime truth 大面积保持不变
3. `review_group` retained-anchor / rollback target / current owner 姿态被守住
4. final fact / settlement owner 未被偷切
5. rollback / hold / stop-condition / observability 成套存在
6. 未触碰 DB schema / API core semantics / runtime route / active continuation / cleanup bundling / active DB/API uplift
7. 用户端无 overclaim

---

## 12. 给执行层的一句话

> **请按“第一轮 very narrow cutover”的极窄子集推进 P3.3.9：只切 ReviewPage 的 non-continuation serving seam，保留 `review_group` 为 current owner + retained fallback anchor，守住 final fact / settlement cloud-owner 边界，并把 rollback / hold / observability 做全；不要把本轮做成 full cutover，更不要把 cleanup / `review_group` exit / active DB/API uplift 绑进来。**
