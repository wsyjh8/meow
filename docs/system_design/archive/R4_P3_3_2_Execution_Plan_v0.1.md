# R4_P3_3_2_Execution_Plan_v0.1.md

- **Owner:** Room 4（治理层）
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** ready for execution
- **Role basis:** `ROOM04_治理版_v0.2`
- **Direct upstream input:** `R1_to_R4_P3_3_2_Execution_Handoff_v0.1.md`

---

## 0. 一句话定位

本稿不是代码实现记录，也不是新的 BR / DB / API / UI 主文档。  
本稿只做一件事：

> **把 Room 1 已经收口完成的 P3.3.2 决定，压成一份可直接交给 Room 4 执行层（Claude Code）的短而硬执行任务单。**

---

## 1. Room 4 当前判断

### 1.1 本轮是否可以开工
> **可以开工。**

### 1.2 本轮开工的性质
> **这是“最小合同落地与补强”开工，不是完整 review planning 实现开工。**

### 1.3 本轮是否需要先升级
> **默认不需要先升级。**

但若执行层在实现中发现以下情况，必须立即升级，不得自行补脑推进：
1. 需要改 DB schema
2. 需要改 API core semantics
3. 需要改 `review_group` 最小合同
4. 需要把 local FSRS 升格成唯一 planner owner
5. 需要把首页“背单词”做成 silent reroute / auto-routing
6. 需要重开 `previewDurations`
7. 需要把 ReviewPage 写成 unified planner / unified Study-Review page 的既成事实

---

## 2. 本轮目标

完成 **P3.3.2 — Session Entry + Planner Owner 最小合同落地与补强**，具体包括：

1. 把 `session_entry_policy_v1` 落地为稳定页面 / 路由 / 文案 / 测试事实
2. 把 `planner_owner_split_v1` 落地为稳定 ReviewPage / 文案 / 测试事实
3. 清掉会误导为 auto-routing / unified planner / 本地已接管 planner 的假事实表达
4. 在不越界改动核心契约的前提下，补一轮最小 UI / copy / test / guardrail

---

## 3. In Scope

1. 首页“背单词”默认继续进入 `StudyPage`
2. 不允许把首页“背单词”做成 silent reroute
3. 若当前代码需要体现 active `review_group` continuation 高优先级，可通过以下最小承接之一落地：
   - 独立 CTA
   - helper
   - priority block
   - 首页摘要提示
4. 上述承接不得吞掉默认“背单词”入口
5. ReviewPage 的主流程事实继续围绕 cloud `review_group`
6. 页面不得把 local due cards / local scheduler 结果写成 ReviewPage 主队列事实
7. 页面不得把 local FSRS 成功写成“主复习计划已更新 / 已切到最佳路径 / 已统一规划”
8. 若当前实现涉及 local ensure / init / bridge fallback，允许做最小 guardrail / 可观察性 / 测试补强
9. 测试补强
10. 必要时产出 patch draft / doc sync note（仅草案，不代替 owner 正式改主文档）

---

## 4. Out of Scope

1. 不做完整 SRS / 完整复习调度算法
2. 不做 mixed / auto-routing runtime contract
3. 不做 unified planner / planner merge
4. 不做 unified Study / Review page
5. 不重开 `previewDurations`
6. 不改 DB schema
7. 不改 API core semantics
8. 不改 `review_group` 最小合同
9. 不把 local FSRS 升格成唯一 planner owner
10. 不把首页 CTA winner 重写成完整状态驱动系统

---

## 5. 必守依据

### 要按需读文档，不需要一次性读完

### 5.1 推进层 / 主线程
- `Main_updated_2026-04-10_v20.md`
- `STATUS_updated_2026-04-10_v19.md`
- `R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1.md`
- `R1_to_R4_P3_3_2_Execution_Handoff_v0.1.md`

### 5.2 规则 / 文案边界
- `BR-OPP-001_v0.2.3.md`
- `R3_P3_3_2_SessionEntry_PlannerOwner_Rules_Note_v0.1.md`

### 5.3 技术边界
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `R2_P3_3_2_SessionEntry_PlannerOwner_Tech_Note_v0.1.md`

### 5.4 UI / UX 表达边界
- `UI_SPEC_v0.2.3.md`
- `UI_SPEC_P3_3_2_SessionEntry_and_PlannerOwner_UI_Preflight_v0.1.md`

---

## 6. Room 4 执行护栏

### 6.1 Session Entry 护栏
- 首页“背单词”当前继续是 `study_default`
- 当前不是 review dispatcher
- 当前不是 mixed / auto-routing dispatcher
- 若要体现 active `review_group` continuation，只能通过独立承接，不得吞掉默认入口

### 6.2 Planner Owner 护栏
- ReviewPage 主真相层继续是 cloud `review_group`
- local FSRS 继续是 device-side scheduling owner
- ReviewPage 继续 `cloud-first + local side-effect`
- local scheduler / due cards / bridge 成败不得被写成用户主真相

### 6.3 文案 / 假事实护栏
以下表达，本轮不得出现在：
- 首页“背单词”主入口 helper
- ReviewPage 主反馈
- submit / bridge 反馈
- 任何摘要提示 / priority block

禁止：
- 系统已自动为你分流
- 已为你安排今天复习模式
- 已切换到最佳学习路径
- 已整合你的学习计划
- 复习规划已更新
- 本地计划已同步
- 统一学习模式已启用
- 已根据 FSRS 自动切换入口
- 主复习计划已更新

### 6.4 Bridge / Fallback 护栏
- ReviewPage 顺序保持：
  1. cloud submit first
  2. local FSRS side-effect second
  3. local failure non-blocking
  4. fallback 对 dev / test 可观察
- 允许补最小 guardrail，但不得借机扩成更强 planner contract

### 6.5 升级护栏
若执行层发现必须触碰以下任一项，立即停下并回报：
- DB schema
- API core semantics
- `review_group` 最小合同
- planner owner 升格
- auto-routing / mixed routing 合同化
- unified Study / Review page
- `previewDurations` 合同化

---

## 7. 必测项

### 7.1 首页入口与承接
1. 首页“背单词”默认继续进入 `StudyPage`
2. 不存在 silent reroute
3. active `review_group` continuation 若有承接，必须通过独立 CTA / helper / priority block
4. 上述承接不得吞掉默认“背单词”入口

### 7.2 ReviewPage 主真相层
1. ReviewPage 主流程事实继续围绕 cloud `review_group`
2. 页面不得把 local due cards / local scheduler 结果写成主队列事实
3. 页面不得把 local FSRS 成功写成“规划已更新 / 已切到最佳路径 / 已统一规划”

### 7.3 Bridge / Fallback
1. cloud submit first
2. local FSRS side-effect second
3. local failure non-blocking
4. fallback 分支可观察 / 可断言
5. local fallback 不弹用户错误，不制造假成功事实

### 7.4 文案 / 假事实清理
1. 不出现“自动分流 / 已自动安排 / 已统一规划 / 本地计划已同步”
2. 不出现“已根据 FSRS 自动切换入口”
3. 不出现“主复习计划已更新”
4. 不借本轮写出 unified planner / mixed routing 已成立事实

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

1. 首页“背单词”默认继续进入 `StudyPage`
2. 没有 silent reroute
3. active `review_group` continuation 如被体现，仍是独立承接，不吞入口
4. ReviewPage 主流程事实继续围绕 cloud `review_group`
5. local FSRS 仍只表现为 device-side side-effect，不被写成用户主真相
6. 假事实文案已清理
7. fallback 保持 dev / test 可观察
8. 未越界触碰 DB / API / `review_group` / planner owner
9. 测试补强已交付

---

## 10. 给执行层的一句话

> **请按“study_default 入口不变、continuation 高优先但不 silent reroute、ReviewPage 继续 cloud-first + local side-effect”的边界推进 P3.3.2；不要把本轮做成完整 review planning 产品扩张。**
