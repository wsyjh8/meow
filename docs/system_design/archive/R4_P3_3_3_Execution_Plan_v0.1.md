# R4_P3_3_3_Execution_Plan_v0.1.md

- **Owner:** Room 4（治理层）
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** ready for execution
- **Role basis:** `ROOM04_治理版_v0.2`
- **Direct upstream input:** `R1_to_R4_P3_3_3_Execution_Handoff_v0.1.md`

---

## 0. 一句话定位

本稿不是代码实现记录，也不是新的 BR / DB / API / UI 主文档。  
本稿只做一件事：

> **把 Room 1 已经收口完成的 P3.3.3 决定，压成一份可直接交给 Room 4 执行层（Claude Code）的短而硬执行任务单。**

---

## 1. Room 4 当前判断

### 1.1 本轮是否可以开工
> **可以开工。**

### 1.2 本轮开工的性质
> **这是“Review Planning Contract v1 的 very narrow minimal-contract 落地与补强”开工，不是完整 SRS / 完整复习规划产品开工。**

### 1.3 本轮是否需要先升级
> **默认不需要先升级。**

但若执行层在实现中发现以下情况，必须立即升级，不得自行补脑推进：
1. 需要改 DB schema
2. 需要改 API core semantics
3. 需要改 `review_group` 最小合同
4. 需要把 local FSRS 升格成页面级 readiness truth 或唯一 planner owner
5. 需要把首页“背单词”做成 silent reroute / auto-routing
6. 需要重开 `previewDurations`
7. 需要把本轮做成 unified planner / planner merge / unified Study-Review page 的既成事实
8. 需要把 exact group size / full scoring / full generation algorithm 偷偷做成 active contract

---

## 2. 本轮目标

完成 **P3.3.3 — Review Planning Contract v1 / SRS Boundary Round** 的最小合同落地与补强，具体包括：

1. 把 `review_readiness_policy_v1` 落成最小可承接状态层
2. 把 `review_priority_policy_v1` 落成最小层级承接逻辑
3. 把 `review_group_generation_policy_v1` 落成最小 gating / non-overclaim 行为
4. 把 `schedule_source_contract_v1` 落成 truth split 护栏
5. 明确保持 `previewDurations` deferred，不被顺手拉回页面或合同
6. 做一轮 UI / 文案 / 测试补强，并产出需要回写的 patch draft / sync note

---

## 3. In Scope

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

---

## 4. Out of Scope

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
12. 不改 `review_group` 最小合同
13. 不把首页 CTA winner 重写成完整状态驱动系统
14. 不把 local FSRS candidate signals 写成页面级或用户级主真相

---

## 5. 必守依据 

### 要按需读文档，不需要一次性读完

### 5.1 推进层 / 主线程
- `Main_updated_2026-04-10_v21.md`
- `STATUS_updated_2026-04-10_v20.md`
- `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md`
- `R1_to_R4_P3_3_3_Execution_Handoff_v0.1.md`

### 5.2 规则 / 文案边界
- `BR-OPP-001_v0.2.4.md`
- `R3_P3_3_3_ReviewPlanningContractV1_Rules_Note_v0.1.md`

### 5.3 技术边界
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `R2_P3_3_3_ReviewPlanningContractV1_Tech_Note_v0.1.md`

### 5.4 UI / UX 表达边界
- `UI_SPEC_v0.2.4.md`
- `UI_SPEC_P3_3_3_ReviewPlanningContractV1_UI_Preflight_v0.1.md`

### 5.5 版本口径说明
- 本轮执行分析 **服从 Room 1 handoff 指定的 review basis：BR / UI 使用 `v0.2.4`**。
- 但 Room 4 **不把 `v0.2.4` 自动写成已被推进层正式 pin 的 runtime truth**。
- 若本轮结论被 Room 1 吸收，再由 Room 1 决定是否同步更新 active baseline。

---

## 6. Room 4 执行护栏

### 6.1 Readiness 护栏
- 页面级 readiness truth 继续以后端 review-serving layer / cloud aggregate 为准
- local FSRS 只能是 scheduling candidate input / device-side scheduling owner
- 前端不得用 local due count / local card state / remaining 自行推导 readiness 最终事实

### 6.2 Priority 护栏
- 本轮只落层级，不落完整算法
- continuation 高优先 **不等于** silent reroute
- `study_default` 仍是默认 fallback 主线
- session 当前继续保守，不自动升为最高优先

### 6.3 Generation 护栏
- generation owner = cloud review-serving layer
- 同一用户同一时刻最多一个 active `review_group`
- active group 未完成前，不进入 next-group 可服务路径
- `next_group_eligible` ≠ `next_group_generated`
- 当前允许 on-demand / lazy generation，不强制 pre-generation

### 6.4 Schedule Source / Truth Split 护栏
- local FSRS 输出的是 scheduling candidate signals，例如：
  - `local_card_state exists / not exists`
  - `local_due_at / next_due_candidate`
  - `last_reviewed_at`
  - `interval / stability / difficulty`
  - `review logs`
- cloud `review_group` 继续承担 serving outputs，例如：
  - review queue serving
  - active group continuation
  - next review work serving
  - completion / settlement truth
- 两边当前只允许存在 **minimal planning-facing conceptual interface**
- 这 **不等于** unified planner / planner merge 已成立

### 6.5 文案 / 假事实护栏
以下表达，本轮不得出现在：
- 首页 helper / priority block
- ReviewPage 主反馈
- 状态解释、副文案、summary block
- submit / bridge / fallback 反馈

禁止：
- 系统已自动为你分流
- 已为你安排今天复习模式
- 已切换到最佳学习路径
- 已整合你的学习计划
- 复习规划已更新
- 本地计划已同步
- 统一学习模式已启用
- 已根据 FSRS 自动切换入口
- 下一组已生成（若当前只是 eligible）
- 现在就该复习（若当前只是 local candidate）
- 你的复习已由本地计划接管

### 6.6 `previewDurations` 护栏
- 本轮继续 deferred
- 不进入 current UI truth
- 不进入 helper / explanation / subtitle / badge
- 不进入 current contract / selector / assertion winner

### 6.7 升级护栏
若执行层发现必须触碰以下任一项，立即停下并回报：
- DB schema
- API core semantics
- `review_group` 最小合同
- planner owner 升格
- auto-routing / mixed routing 合同化
- unified Study / Review page
- `previewDurations` 合同化
- exact group size / full scoring / full generation algorithm 合同化

---

## 7. 必测项

### 7.1 Readiness 状态承接
1. `ready_now` 可被最小承接，但 truth source 仍是 cloud serving layer
2. `not_ready_now` 不制造“你今天没有复习资格”负面假事实
3. `next_group_eligible` 最多表达资格态，不写成“下一组已生成”
4. `temporarily_unservable` 表达为阶段性不可立即服务，不写成永久否定

### 7.2 首页与 ReviewPage 承接
1. 首页“背单词”默认继续进入 `StudyPage`
2. 不存在 silent reroute
3. active `review_group` continuation 若被承接，必须通过独立 CTA / helper / priority block
4. 上述承接不得吞掉默认“背单词”入口
5. ReviewPage 主流程事实继续围绕 cloud `review_group`

### 7.3 Priority 层级
1. continuation > due review > high-priority review > new words > session
2. due / high-priority 仅限 cloud-confirmed / serving-confirmed 才能进入页面层
3. local overdue / local FSRS 候选结果不得直接升格为 priority winner
4. session 当前不进入本轮首页优先级 winner

### 7.4 Generation / Gating
1. 同一用户同一时刻最多一个 active group
2. active group 未完成前不进入 next-group path
3. `next_group_eligible` 不被实现成 `next_group_generated`
4. on-demand / lazy generation 若被采用，不制造“下一组已在后台准备好”的假事实

### 7.5 Schedule Source / Truth Split
1. local FSRS candidate signals 不被写成页面级 readiness truth
2. cloud serving outputs 继续承担 queue / continuation / completion / settlement truth
3. 页面不出现“本地计划已接管主复习流程”之类表达

### 7.6 文案 / 假事实清理
1. 不出现“自动分流 / 已自动安排 / 已统一规划 / 本地计划已同步”
2. 不出现“已根据 FSRS 自动切换入口”
3. 不出现“下一组已生成”（若只是 eligible）
4. 不出现“现在就该复习”（若只是 local candidate）
5. 不借本轮写出 unified planner / planner merge / previewDurations 已成立事实

---

## 8. 执行层交付物要求

执行层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **是否触碰核心契约的判断**
5. **是否需要升级**
6. **仍未解决的问题**
7. **需要哪些文档回写**
   - BR / UI / Main / Status / 其他
8. **是否可 accept / revise / escalate / hold**

---

## 9. Room 4 验收判断口径

只有同时满足以下条件，Room 4 才会给出 `accept / 可 closeout` 倾向：

1. `review_readiness_policy_v1` 的最小状态层已落地
2. `review_priority_policy_v1` 的最小层级承接已落地
3. `review_group_generation_policy_v1` 的最小 gating / non-overclaim 已落地
4. `schedule_source_contract_v1` 的 truth split 护栏已落地
5. 首页“背单词”默认继续进入 `StudyPage`
6. 没有 silent reroute
7. ReviewPage 主流程事实继续围绕 cloud `review_group`
8. local FSRS 仍只表现为 device-side scheduling owner / candidate source，不被写成用户主真相
9. `previewDurations` 继续 deferred
10. 假事实文案已清理
11. 未越界触碰 DB / API / `review_group` / planner owner / full planner contract
12. 测试补强已交付

---

## 10. 给执行层的一句话

> **请按“cloud serving truth 不变、local FSRS 继续只做 scheduling candidate、首页 study_default 不变、只补 very narrow review-planning minimal contract”的边界推进 P3.3.3；不要把本轮做成完整复习规划产品扩张。**
