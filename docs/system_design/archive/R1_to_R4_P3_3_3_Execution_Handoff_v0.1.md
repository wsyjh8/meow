# R1_to_R4_P3_3_3_Execution_Handoff_v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** execution handoff / ready for Room4-治理层
- **Role basis:** `room1_v0.2.0.md`
- **Runtime basis:** `Main_updated_2026-04-10_v21.md` + `STATUS_updated_2026-04-10_v20.md`
- **Round basis:** `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md`
- **Direct upstream inputs:**
  - `R2_P3_3_3_ReviewPlanningContractV1_Tech_Note_v0.1.md`
  - `R3_P3_3_3_ReviewPlanningContractV1_Rules_Note_v0.1.md`
  - `UI_SPEC_P3_3_3_ReviewPlanningContractV1_UI_Preflight_v0.1.md`
- **Review basis for this round:**
  - `BR-OPP-001_v0.2.4.md`
  - `UI_SPEC_v0.2.4.md`
  - `背单词喵喵app_DB设计草案_v0.2.1.md`
  - `背单词喵喵app_API设计草案_v0.2.1.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 P3.3.3 这一轮已经由 Room 2 / Room 3 / Room 5 收口出的共识，
压成一份可直接交给 **Room4-治理层** 的统一执行 handoff。

本文件不是：
- 新 PRD
- 新 BR / DB / API / UI 主文档
- 完整 SRS 方案
- 完整 review planning 产品稿
- unified planner / auto-routing 最终方案
- P3.3.3 closeout

本文件只做一件事：

> **把 P3.3.3 已足够稳定的 very narrow review-planning minimal contract 下发给 Room 4，要求只做“最小合同落地 + 假事实清理 + 测试补强 + 不越界回写草案”，不把本轮做成完整 planner 产品。**

---

## 1. Room 1 吸收后的统一结论

### 1.1 本轮允许从 pure preflight 前进一步
Room 1 现正式吸收三方共识：

> **P3.3.3 可以从 pure preflight 前进一步，进入 `Review Planning Contract v1` 的 very narrow execution layer。**

但这轮只允许进入：
1. `review_readiness_policy_v1`
2. `review_priority_policy_v1`（hierarchy only）
3. `review_group_generation_policy_v1`（entry boundary only）
4. `schedule_source_contract_v1`（truth split + conceptual interface only）

### 1.2 本轮继续 deferred / pending 的内容
以下内容本轮继续不得进入 active contract / current UI truth / execution winner：
1. `previewDurations` re-entry
2. exact group size contract
3. full priority scoring engine
4. full generation / regeneration algorithm
5. mixed / auto-routing runtime behavior
6. unified planner / planner merge
7. stronger ReviewPage bridge contract
8. unified Study / Review page
9. 完整 review planning product

### 1.3 review readiness truth source 已冻结
本轮正式冻结：
1. **页面级 readiness truth = cloud aggregate / review-serving layer**
2. **local FSRS = scheduling candidate input / device-side scheduling owner**
3. 前端不得用 local due count / local card state / remaining 自行推导 readiness 最终事实

同时，Room 1 现正式接受以下 4 个最小 readiness 语义：
1. `ready_now`
2. `not_ready_now`
3. `next_group_eligible`
4. `temporarily_unservable`

### 1.4 review priority hierarchy 已冻结
本轮正式冻结的最小优先级层级为：
1. **active `review_group` continuation**
2. **due review**（仅限 cloud-confirmed / serving-confirmed）
3. **high-priority review**（仅限 cloud-confirmed）
4. **new words**
5. **session**

补充规则：
- continuation 高优先 **不等于** silent reroute
- `study_default` 仍是默认 fallback 主线
- Session 当前继续保守，不自动升为最高优先

### 1.5 review_group generation 边界已冻结
本轮正式冻结：
1. **generation owner = cloud review-serving layer**
2. **同一用户同一时刻最多一个 active `review_group`**
3. **active group 未完成前，不进入 next-group 可服务路径**
4. **`next_group_eligible` ≠ `next_group_generated`**
5. **next-group decision 至少依赖 cloud-confirmed readiness，而不是 local-only readiness**
6. generation 当前允许 on-demand / lazy generation，不强制 pre-generation

### 1.6 schedule source truth split 已冻结
本轮正式冻结：
1. **local FSRS 输出的是 scheduling candidate signals**，例如：
   - `local_card_state exists / not exists`
   - `local_due_at / next_due_candidate`
   - `last_reviewed_at`
   - `interval / stability / difficulty`
   - `review logs`
   - future preview / explanation 的候选原料
2. **cloud `review_group` 继续承担 serving outputs**，例如：
   - review queue serving
   - active group continuation
   - next review work serving
   - completion / settlement truth
3. 两边当前只允许存在 **minimal planning-facing conceptual interface**
4. 这 **不等于** unified planner / planner merge 已成立

### 1.7 `previewDurations` 当前继续 deferred
Room 1 本轮正式冻结一句：

> **`previewDurations` 在 P3.3.3 继续 deferred；直到 `schedule_source_contract_v1` 与页面解释边界都被单独 pin 后，才允许 re-entry。**

---

## 2. 本轮一句话定义

> **P3.3.3 本轮不是做完整复习规划，而是把 review planning 从“入口与 owner split”继续推进到“页面可承接、规则可引用、测试可断言、实现不补脑”的最小合同层。**

---

## 3. 给 Room4-治理层的任务定义

### 3.1 目标
完成 P3.3.3 的 very narrow minimal-contract 落地，具体包括：

1. 把 `review_readiness_policy_v1` 落成最小可承接状态层
2. 把 `review_priority_policy_v1` 落成最小层级承接逻辑
3. 把 `review_group_generation_policy_v1` 落成最小 gating / non-overclaim 行为
4. 把 `schedule_source_contract_v1` 落成 truth split 护栏
5. 明确保持 `previewDurations` deferred，不被顺手拉回页面或合同
6. 做一轮 UI / 文案 / 测试补强，并给出需要回写的 patch draft / sync note

### 3.2 In Scope
1. 允许新增 / 清理用于表达以下最小状态层的实现：
   - `ready_now`
   - `not_ready_now`
   - `next_group_eligible`
   - `temporarily_unservable`
2. 允许新增 / 调整首页与 ReviewPage 的最小 review-ready 承接块、helper、priority block
3. 允许把 priority hierarchy 落到最小页面承接逻辑：
   - continuation > due review > high-priority review > new words > session
4. 允许补最小 gating：
   - active group 未完成前不进入 next-group path
   - `next_group_eligible` 不得被实现成 `next_group_generated`
5. 允许补 `serving truth` / `scheduling candidate` 的最小 truth split 防线
6. 允许补 UI / copy / test / assertion / logging / fallback branch observability
7. 允许在不改核心契约前提下，增加极小的 derived state / adapter / selector / helper / local model 字段
8. 允许产出 BR / UI / Main / Status 的 patch draft / sync note（草案，不代替 owner 正式回写）

### 3.3 Out of Scope
1. 不做完整 SRS
2. 不做完整 priority scoring
3. 不做 exact group size contract
4. 不做完整 generation / regeneration algorithm
5. 不做 unified planner / planner merge
6. 不做 mixed / auto-routing runtime behavior
7. 不做 stronger ReviewPage bridge contract
8. 不做 unified Study / Review page
9. 不做 `previewDurations` re-entry
10. 不重写 DB schema
11. 不重写 API core semantics
12. 不改 `review_group` 最小合同主基线
13. 不改 `planner_owner_split_v1` 已冻结边界

---

## 4. 必守依据

Room4-治理层与执行层，本轮必须同时服从以下依据：

### 4.1 推进层 / 主线程
- `Main_updated_2026-04-10_v21.md`
- `STATUS_updated_2026-04-10_v20.md`
- `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md`

### 4.2 本轮专项输入
- `R2_P3_3_3_ReviewPlanningContractV1_Tech_Note_v0.1.md`
- `R3_P3_3_3_ReviewPlanningContractV1_Rules_Note_v0.1.md`
- `UI_SPEC_P3_3_3_ReviewPlanningContractV1_UI_Preflight_v0.1.md`

### 4.3 review basis（本轮阅读与判断基准）
- `BR-OPP-001_v0.2.4.md`
- `UI_SPEC_v0.2.4.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`

### 4.4 重要口径说明
- 本轮 **分析与执行服从 `v0.2.4` 作为 review basis**
- 但 **不得把 `BR v0.2.4 / UI v0.2.4` 自动写成已经被推进层正式 pin 的 runtime truth**
- active baseline 是否更新，仍由 **Room 1** 后续决定

---

## 5. 待决项（本轮已收口，Room 4 不得补脑）

以下点本轮 Room 1 已收口，Room 4 不得自行二次发明：

1. **页面级 readiness truth 不在 local FSRS**
2. **priority 只冻结 hierarchy，不冻结 scoring**
3. **generation 只冻结 owner + gating，不冻结 exact group size**
4. **schedule source 只冻结 truth split + conceptual interface，不冻结新 schema / 新主 API**
5. **`previewDurations` 继续 deferred**
6. **current round 不是完整 planner 产品轮**

---

## 6. Room 4 执行护栏

### 6.1 Readiness 护栏
1. 不得把 local due count / local overdue / local remaining 直接升格为页面 readiness truth
2. 不得把 local scheduler 结果直接写成“现在就该复习”
3. `not_ready_now` 不得写成“你以后都不需要复习”
4. `temporarily_unservable` 不得写成“你今天没有复习资格”

### 6.2 Priority 护栏
1. continuation 高优先 **不等于** silent reroute
2. due / high-priority 只有在 cloud-confirmed 时才允许进入页面级承接
3. 不得把 local overdue bucket 直接变成 priority winner
4. 不得把 Session 升格成当前轮首页 winner
5. 不得把本轮实现写成完整 CTA winner 算法

### 6.3 Generation 护栏
1. generation / regeneration owner 继续是 cloud
2. local FSRS 不得直接写成 group producer
3. `next_group_eligible` 不得误写成：
   - 下一组已生成
   - 已下发到设备
   - 现在一定拿得到下一组内容
4. exact group size 不得写成硬事实 / 承诺型 UI 文案 / 测试真相

### 6.4 Schedule Source 护栏
1. 允许写成页面事实的只有：
   - 复习继续以当前 `review_group` 为主
   - 当前默认从背单词开始
   - 你有一组复习未完成
   - 现在可继续复习
   - 本地 FSRS 继续参与本地调度
2. 不允许写成页面事实的包括：
   - 本地 FSRS 已接管复习路径
   - 云端与本地已统一为同一 planner
   - 系统已自动为你决定今天先学什么
   - 已切换到最佳复习模式
   - 已根据 FSRS 自动重排你的学习路径
   - 已为你生成完整复习计划
   - 统一学习模式已启用
3. StudyPage 保持默认学习入口页定位，不承担 planner dispatcher 解释职责
4. ReviewPage 继续围绕 cloud `review_group` 展示 queue / continuation / remaining / group completion，不展示依赖 local FSRS 成功才能成立的解释层

### 6.5 `previewDurations` 护栏
1. 本轮不得拉回 StudyPage
2. 本轮不得拉回 ReviewPage
3. 本轮不得放到首页 CTA 下
4. 本轮不得写成 schedule explanation
5. 本轮不得借由它暗示 unified planner 已成立

### 6.6 文案事实禁区
本轮继续禁止以下表达：
1. 系统已自动为你决定今天先学什么
2. 已切换到最佳复习模式
3. 已根据 FSRS 自动重排你的学习路径
4. 已为你生成完整复习计划
5. 云端与本地已统一为同一 planner
6. 下次将在 X 天后复习
7. 预计 X 天后再次出现
8. 本地计划已接管复习路径
9. 自动分流已开启
10. 统一学习模式已启用

---

## 7. 必测项

Room 4 本轮至少覆盖以下测试 / 自测：

### 7.1 Readiness
1. `ready_now` 只在 cloud serving layer 可服务时成立
2. `not_ready_now` 不因 local due count 自动翻成 `ready_now`
3. `next_group_eligible` 与 `next_group_generated` 被正确区分
4. `temporarily_unservable` 不被写成永久否定

### 7.2 Priority
1. continuation 高于 due / high-priority / new words / session
2. due / high-priority 仅在 cloud-confirmed 时进入页面级承接
3. 没有 continuation 且没有 cloud-confirmed due / high-priority 时，首页继续落在 `study_default`
4. 本轮没有产生 silent reroute

### 7.3 Generation
1. 同一用户同一时刻最多一个 active `review_group`
2. active group 未完成前，不走 next-group path
3. `next_group_eligible` 不被实现成 generated fact
4. 没有任何文案 / 状态 / 断言把 exact group size 写成硬合同

### 7.4 Schedule Source
1. StudyPage 不新增 planner dispatcher 解释层
2. ReviewPage 继续围绕 cloud `review_group` 展示 queue / continuation / remaining / completion
3. 本地 FSRS 只作为 scheduling candidate / local scheduling side 的能力来源，不被写成 serving truth
4. 不出现 unified planner / planner merge 假事实

### 7.5 Preview Durations
1. `previewDurations` 当前不显示
2. 不出现在首页 / StudyPage / ReviewPage
3. 不作为当前通过标准
4. 不被写成“系统已安排 / 下次将在 X 天后复习”

### 7.6 文案 / 假事实清理
1. 不出现本轮文案禁区
2. 首页、StudyPage、ReviewPage 的承接不越过当前 very narrow contract
3. 不把 pending deeper-contract 写成既成事实

---

## 8. 交付物要求

Room4-治理层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **哪些点是纯 UI / copy / selector / adapter / local state 修正**
5. **哪些点若继续深入会触发 Major / 需要升级给 Room 2**
6. **仍未解决的问题**
7. **需要哪些文档回写**
   - BR / UI / Main / Status / 其他
8. **是否可 close / 是否需 revise / 是否需 escalate**
9. **patch draft / sync note**（若触发文档同步）

---

## 9. Room 1 预期完成定义（Done）

当 Room4-治理层交回结果，且满足以下条件时，Room 1 认为 P3.3.3 本轮可以进入吸收 / closeout 判断：

1. `review_readiness_policy_v1` 已以最小状态层落地，且页面级 truth 仍在 cloud serving layer
2. `review_priority_policy_v1` 已以 hierarchy-only 方式落地，且未产生完整 scoring 幻觉
3. `review_group_generation_policy_v1` 已以 owner + gating + non-overclaim 方式落地，且未把 exact group size 写成硬事实
4. `schedule_source_contract_v1` 已以 truth split 落地，且未产生 unified planner / local planner takeover 假事实
5. `previewDurations` 仍保持 deferred，未被顺手拉回页面或合同
6. 测试 / 自测 / fallback / assertion 已交付
7. 本轮未越界触碰 DB schema / API core semantics / `review_group` 最小合同 / `planner_owner_split_v1`

---

## 10. 一句话 handoff

> **请 Room4-治理层按“冻结 readiness / priority / generation / source split 的 very narrow minimal contract，继续保持 preview deferred，并严防 unified planner / auto-routing / preview explanation 假事实”的边界推进 P3.3.3；不要把本轮做成完整 review planning product。**
