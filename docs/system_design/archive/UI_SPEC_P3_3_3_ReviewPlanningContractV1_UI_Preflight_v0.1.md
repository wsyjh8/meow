# UI_SPEC_P3_3_3_ReviewPlanningContractV1_UI_Preflight_v0.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** Room 5 专项输入 / ready for Room 1 review
- **Role basis:** `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- **Round:** `P3.3.3 — Review Planning Contract v1 / SRS Boundary Round`
- **Direct upstream input:** `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md`
- **Related inputs:** `R2_P3_3_3_ReviewPlanningContractV1_Tech_Note_v0.1.md` + `R3_P3_3_3_ReviewPlanningContractV1_Rules_Note_v0.1.md` + `UI_SPEC_v0.2.4.md`

---

## 0. 文档目标

本稿只做一件事：

> **从 Room 5 的页面 / 状态 / 文案视角，把 P3.3.3 当前轮需要进一步收口的 5 个 review-planning 问题，翻成可被 Room 1 判断是否 pin 的最小 UI 合同层。**

本稿不是：
- 新 UI 主文档
- 新 BR / DB / API 主文档
- Room 4 执行单
- 完整复习规划产品稿
- 自动分流 / unified planner 最终方案

一句话：

> **P3.3.3 在 Room 5 视角，继续前进，但只前进到“页面怎么承接 readiness / priority / generation / source split / preview defer”的窄合同层。**

---

## 1. 输入依据

### 1.1 主线程 handoff basis
- `R1_P3_3_3_ScopePin_and_Handoff_Pack_v0.1.md`

### 1.2 Room 2 / Room 3 本轮输入
- `R2_P3_3_3_ReviewPlanningContractV1_Tech_Note_v0.1.md`
- `R3_P3_3_3_ReviewPlanningContractV1_Rules_Note_v0.1.md`

### 1.3 当前 review basis
- `BR-OPP-001_v0.2.4.md`
- `UI_SPEC_v0.2.4.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`

---

## 2. Room 5 总判断

### 2.1 Room 5 一句话结论
> **Room 5 支持本轮从 pure preflight 前进一步，但只支持进入 `Review Planning Contract v1` 的 very narrow UI contract。**

### 2.2 为什么应该前进一步
如果这轮仍完全停留在“只有入口语义与 owner split”，UI 侧会继续悬空以下问题：

1. 首页什么时候应该出现“继续复习”承接块，什么时候不该出现
2. ReviewPage 当前可服务 / 暂不可服务 / 可进入下一组，页面分别怎么解释
3. readiness / priority / generation 哪些可以变成状态块，哪些仍不能上页面
4. local FSRS 与 cloud serving truth 的分层，哪些能说，哪些绝不能说
5. `previewDurations` 若继续 deferred，页面上哪些“看起来无害”的小提示其实也不能加

### 2.3 为什么不能走更深
本轮仍不能越界到：
- 完整 SRS
- 完整 priority scoring
- auto-routing runtime 行为
- planner merge / unified planner
- unified Study / Review page
- stronger ReviewPage bridge contract
- `previewDurations` 正式回归可见 UI

---

## 3. `review_readiness_policy_v1` 的页面承接

## 3.1 Room 5 结论
> **本轮可以把 readiness 收成页面状态层，但页面级 readiness truth 继续以后端 review-serving layer 为准。**

## 3.2 会受影响的页面
1. **SpecHomePage**
2. **ReviewPage**
3. **StudyPage（只受弱影响）**

## 3.3 SpecHomePage 应承接到哪一层
首页当前可以承接以下最小状态：

### A. `ready_now`
可承接为：
- 次强 CTA：**继续复习**
- helper：**现在可继续复习**
- summary block：**你有一组复习可继续**

### B. `not_ready_now`
可承接为：
- 不展示 review-ready 强提示
- 保持“背单词”作为默认主入口
- 不新增“今天没有复习资格”之类负面解释

### C. `next_group_eligible`
可承接为：
- 最多作为轻量 helper / future-ready 候选说明
- 当前不建议单独升为主 CTA
- 更不建议写成“下一组已就绪”

### D. `temporarily_unservable`
可承接为：
- 不显示“现在就去复习”的强引导
- 可在必要时用中性 helper 表达“当前暂不可立即进入复习”
- 不写成“你今天不需要复习”

## 3.4 ReviewPage 应承接到哪一层
ReviewPage 当前可以承接：
- 有 active group 时：group progress / remaining / group completion
- 暂不可服务时：中性不可服务态 / loading / retry-safe hint
- 可进入下一组时：可进入下一组的资格态，但不自动写成“下一组已生成”

## 3.5 StudyPage 应承接到哪一层
StudyPage 当前只应承接：
- 默认学习入口仍成立
- 不在页面里新增“系统其实觉得你更该去复习”的解释文案
- 不把 readiness 变成 StudyPage 的主解释层

---

## 4. `review_priority_policy_v1` 的页面表达

## 4.1 Room 5 结论
> **本轮可以冻结优先级层级，但页面只表达“谁当前更该被承接”，不表达完整排序算法。**

## 4.2 首页表达规则
如果 Room 1 后续 pin 本轮最小合同，首页应按以下层级表达：

1. **active `review_group` continuation**
   - 最高优先
   - 通过独立次强 CTA / helper / priority block 表达
   - 但仍不吞掉默认“背单词”入口

2. **due review**
   - 仅当 cloud-confirmed 时，才允许出现 review-ready 提示
   - 不得仅凭 local due 写出“现在就该复习”

3. **high-priority review**
   - 仅当 cloud-confirmed 时，才允许进入页面层
   - 当前最多进入轻量优先提示，不直接压过 continuation

4. **new words**
   - 继续是默认 fallback 主线
   - 即：没有 continuation、没有 cloud-confirmed due / high-priority review 时，首页继续稳态落在“背单词”

5. **session**
   - 当前继续保守
   - 不进入本轮首页优先级 winner

## 4.3 页面不该承接到哪一层
本轮页面不应承接：
- 完整优先级分值
- due vs high-priority 细权重
- local overdue bucket
- CTA winner 完整状态驱动算法

---

## 5. `review_group_generation_policy_v1` 的页面承接边界

## 5.1 Room 5 结论
> **本轮页面只承接“generation 是否有资格进入下一层”的边界，不承接 exact group size、完整分组算法、或 next group 已生成的既成事实。**

## 5.2 页面可以承接的最小状态
### A. active group exists
- 可显示：
  - 继续复习
  - 本组剩余 X 个
  - 本组复习完成
- 不可显示：
  - 下一组已经准备好

### B. `next_group_eligible`
- 可显示：
  - 具备进入下一组的资格
  - 当前可继续进入下一轮 review
- 不可显示：
  - 下一组已生成
  - 已下发到设备
  - 现在一定能拿到下一组内容

### C. `temporarily_unservable`
- 可显示：
  - 当前暂不可立即进入复习
- 不可显示：
  - 没有复习资格
  - 今天不需要复习
  - 系统已判定 review 结束

## 5.3 Room 5 不建议页面接的内容
1. exact group size
2. regeneration cadence
3. next-group issuance 的完整时机
4. local-first generation 候选
5. “下一组一定有多少题”这类承诺型文案

---

## 6. `schedule_source_contract_v1` 的 UI truth / 禁区

## 6.1 Room 5 结论
> **本轮应把 `serving truth` 与 `scheduling candidate` 的 UI truth split 写硬。**

## 6.2 页面允许表达的 truth
### A. 可写成页面事实的
1. 复习继续以当前 `review_group` 为主
2. 当前默认从背单词开始
3. 你有一组复习未完成
4. 现在可继续复习
5. 本地 FSRS 继续参与本地调度

### B. 不可写成页面事实的
1. 本地 FSRS 已接管复习路径
2. 云端与本地已统一为同一 planner
3. 系统已自动为你决定今天先学什么
4. 已切换到最佳复习模式
5. 已根据 FSRS 自动重排你的学习路径
6. 已为你生成完整复习计划
7. 统一学习模式已启用

## 6.3 StudyPage / ReviewPage 的 truth split
### StudyPage
- 保持默认学习入口页定位
- 不承担 planner dispatcher 解释职责
- 不新增“系统根据规划把你送到这里”的说明

### ReviewPage
- 继续围绕 cloud `review_group` 展示：
  - queue / continuation
  - remaining
  - group completion
- 不展示依赖 local FSRS 成功才能成立的解释层

---

## 7. `preview_durations_contract_decision` 的 UI 风险判断

## 7.1 Room 5 当前正式结论
> **Room 5 支持本轮继续 deferred。**

## 7.2 若继续 deferred，UI 风险最小
当前继续 deferred 时，UI 的风险最小，因为可以继续明确：
- 不进入当前稳定可见 UI
- 不作为页面事实文案来源
- 不作为本轮通过标准
- 不诱导用户把它理解成稳定的下次安排

## 7.3 若未来最小 re-entry，Room 5 的最低要求
若未来 Room 1 要让它重新进入下一层合同，Room 5 至少要求先回答：

1. source of truth 是谁
2. 是 Study only 还是 Study + Review
3. explanation layer 怎么表达
4. 是否允许受 bridge 状态影响

### Room 5 的最小 UI 落位建议（仅 future candidate）
- **Study only 优先**
- 仅作为 4 按钮下方的极轻 secondary hint
- 小号字、中性灰、低强调
- 必须带“预计 / 仅供参考”语气
- 不得写成：
  - 下次将在 X 天后复习
  - 预计 X 天后再次出现
  - 系统已安排

## 7.4 Room 5 当前不建议的做法
本轮不应：
- 把 `previewDurations` 拉回 StudyPage
- 把它放到 ReviewPage
- 放在首页 CTA 下
- 写成 schedule explanation
- 借由它暗示 unified planner 已成立

---

## 8. Fact Copy 禁区（Room 5 当前轮）

以下表达在 P3.3.3 当前轮继续列为页面事实禁区：

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
11. 下一组已生成（若只有 eligible）
12. 今天没有复习资格
13. 系统已判定你不需要复习

---

## 9. State Contract Risk（Room 5 给 Room 1 的风险摘要）

## 9.1 当前可被 Room 1 pin 的最小 UI 合同层
Room 5 建议 Room 1 若要 pin，本轮只 pin 以下内容：

1. **页面级 readiness truth 继续以 cloud review-serving layer 为准**
2. **首页只承接 continuation / due / high-priority 的最小状态层，不承接完整排序算法**
3. **`next_group_eligible` 可以成为资格态，但不是生成完成态**
4. **页面 truth split 必须继续区分 cloud serving truth 与 local scheduling candidate**
5. **`previewDurations` 当前继续 deferred**

## 9.2 当前仍不建议 pin 的 UI 合同
1. preview explanation UI
2. auto-routing UI
3. mixed mode UI
4. unified planner UI
5. readiness reason enum 的完整页面表达
6. exact group size 的页面表达
7. local FSRS 主导的 readiness / priority 表达

---

## 10. Room 5 对 Room 1 的建议

### 10.1 建议 Room 1 可吸收
Room 1 若要吸收本轮结论，建议只吸收：

1. `review_readiness_policy_v1` 可进入页面状态层，但 truth-source 继续以 cloud serving layer 为准
2. `review_priority_policy_v1` 可冻结层级，但页面只表达最小承接，不表达完整算法
3. `review_group_generation_policy_v1` 可冻结 eligibility / owner / completion gating，不冻结 exact group size
4. `schedule_source_contract_v1` 可冻结 UI truth split
5. `previewDurations` 当前继续 deferred

### 10.2 不建议本轮吸收成 runtime truth 的内容
1. auto-routing runtime UI
2. mixed / unified planner UI
3. preview explanation UI
4. exact group size UI
5. readiness / priority 完整 reason system

---

## 11. Room 5 一句话结论

> **P3.3.3 在 Room 5 视角，可以前进一步，但只应前进到“页面级 readiness / priority / eligibility / truth split”的 very narrow UI contract：页面继续以后端 review-serving layer 作为 readiness 与 serving truth 的来源，首页只承接最小状态层与独立 review continuation 承接，不把 `previewDurations` 拉回当前 UI，也不把 pending deeper-contract 写成既成事实。**
