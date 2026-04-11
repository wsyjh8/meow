# UI_SPEC_P3_3_2_SessionEntry_and_PlannerOwner_UI_Preflight_v0.1

- **Owner:** Room 5
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** Room 5 专项输入 / ready for Room 1 review
- **Role basis:** `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- **Runtime basis:** `Main_updated_2026-04-10_v20.md` + `STATUS_updated_2026-04-10_v19.md`
- **Direct upstream input:** `R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1.md`
- **Related inputs:** `UI_SPEC_v0.2.3.md` + `R2_P3_3_2_SessionEntry_PlannerOwner_Tech_Note_v0.1.md` + `R3_P3_3_2_SessionEntry_PlannerOwner_Rules_Note_v0.1.md`

---

## 0. 文档目标

本稿只做四件事：

1. 从 Room 5 视角，回答 **首页“背单词”点进去之后，UI 应该如何承接**
2. 把 **session_entry_policy_v1** 翻成页面层与状态层可执行的表达
3. 把 **planner_owner_split_v1** 翻成 UI 的显示边界与禁区
4. 告诉 Room 1：P3.3.2 当前是否值得从 pure preflight 进入 **next-layer minimal contract**

本稿不是：
- 新主 UI 文档
- 新 BR / DB / API 主文档
- Room 4 执行单
- 完整 review planning 产品稿
- 自动分流或 unified planner 的实现指令

一句话：

> **P3.3.2 在 Room 5 视角，不是要把复习规划做厚，而是先把“默认入口怎么解释、active review continuation 怎么承接、哪些状态现在还绝不能写成系统事实”写硬。**

---

## 1. 输入依据

### 1.1 当前推进层 / 治理层依据
- `ORG_v0.3.1.md`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`
- `Main_updated_2026-04-10_v20.md`
- `STATUS_updated_2026-04-10_v19.md`

### 1.2 当前 active runtime basis
- `BR-OPP-001_v0.2.3.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `UI_SPEC_v0.2.3.md`

### 1.3 本轮直接输入
- `R1_P3_3_2_ScopePin_and_Handoff_Pack_v0.1.md`
- `R2_P3_3_2_SessionEntry_PlannerOwner_Tech_Note_v0.1.md`
- `R3_P3_3_2_SessionEntry_PlannerOwner_Rules_Note_v0.1.md`

---

## 2. Room 5 总判断

### 2.1 Room 5 一句话结论
> **Room 5 同意进入 `next-layer minimal contract`，但只进入很窄的一层 UI 合同：把 `home_word_entry = study_default` 与 `planner_owner_split_v1` 写成页面承接边界；mixed / auto-routing / unified planner 继续保持 pending。**

### 2.2 为什么 Room 5 同意前进一步
如果这轮还继续完全停在 pure preflight，UI 侧会持续悬空 3 个问题：

1. 首页“背单词”到底只是一直点进 StudyPage，还是其实已经暗含自动分流
2. active `review_group` continuation 到底应该以什么形式被用户看到
3. local FSRS 与 cloud `review_group` 的分层共存，在页面上哪些能说、哪些绝不能说

这些如果不写清，Room 4 以后很容易：
- 在首页 CTA 上偷偷做 silent reroute
- 在 ReviewPage 写出“已更新你的复习计划”
- 把本地 planner side-effect 写成用户可依赖事实

### 2.3 为什么 Room 5 也不同意走更深
因为再往下就会越过本轮明确 out-of-scope：
- mixed / auto-routing runtime contract
- unified planner / planner merge
- 完整 review planning 产品层
- unified Study / Review page
- `previewDurations` 重开
- 更强的 planner explanation / schedule preview

所以，P3.3.2 这轮 Room 5 只支持进入 **“入口策略 + owner split 的页面合同层”**。

---

## 3. `session_entry_policy_v1`（Room 5 页面版）

## 3.1 UI-P3.3.2-001 — 首页“背单词”继续是 `study_default`
- **Status:** Frozen for this round
- **UI rule:** 首页“背单词”入口，当前轮在 UI 上继续解释为：
  - 默认进入 **StudyPage**
  - 不是 review dispatcher
  - 不是 mixed dispatcher
  - 不是“系统已经自动帮你决定今天该走哪条学习模式”的入口
- **Applies to:** Home / CTA / helper copy / navigation / testing
- **UI checkable:**
  1. 点击“背单词”仍默认进入 StudyPage
  2. 页面文案不得暗示“系统已自动帮你切到复习”
  3. 页面 helper 不得写成“系统已为你自动规划今天学习模式”

## 3.2 UI-P3.3.2-002 — active `review_group` continuation 应通过独立承接，不等于吞掉默认入口
- **Status:** Frozen for this round
- **UI rule:** 若要体现 active `review_group` continuation 高优先级，当前应通过：
  - 独立 CTA
  - helper / priority block
  - 首页摘要提示
  来承接；而不是把“背单词”默认改造成 silent reroute 入口
- **Recommended UI forms:**
  1. 首页独立次强 CTA：“继续复习”
  2. 首页小提示：“你有一组复习未完成”
  3. 轻量 priority block：位于“背单词”主入口下方或旁侧
- **Must not do:**
  1. 不得把 active `review_group` 的存在写成“点击背单词时必然吞掉 `/study`”
  2. 不得把 continuation 优先解释成“背单词其实已经变成复习按钮”

## 3.3 UI-P3.3.2-003 — mixed / auto-routing / unified planner 继续 Pending
- **Status:** Frozen as pending-boundary
- **UI rule:** 本轮页面与状态表达中，不得出现以下既成事实：
  1. “系统将自动为你分流到新词 / 复习 / 混合”
  2. “当前已进入混合学习模式”
  3. “统一学习页已成立”
  4. “完整复习规划已启用”
- **UI checkable:**
  1. 文案不得出现“自动安排 / 智能分配 / 已规划完成”之类表达
  2. 首页不得新增依赖 mixed planner 的状态区块
  3. StudyPage / ReviewPage 不得被包装成 unified planner 的既成事实

---

## 4. `planner_owner_split_v1`（Room 5 页面版）

## 4.1 UI-P3.3.2-004 — ReviewPage 的主真相层继续是 cloud `review_group`
- **Status:** Frozen for this round
- **UI rule:** ReviewPage 当前所有用户可感知的主流程事实，继续基于 cloud `review_group` 承接：
  - 当前复习队列
  - 当前组 continuation
  - 本组完成
  - review 路径下的 settlement 承接
- **UI implication:**
  1. 页面主进度条 / remaining count / 完成本组提示，应继续围绕 cloud `review_group`
  2. 不得把本地 due cards 或本地 scheduler 结果写成 ReviewPage 主队列事实
  3. 不得把本地 FSRS 成功写成“当前复习任务主状态已更新”

## 4.2 UI-P3.3.2-005 — local FSRS 继续是 device-side scheduling owner，但不是用户主真相
- **Status:** Frozen for this round
- **UI rule:** local FSRS 当前在页面上的处理应是：
  - 允许作为幕后调度层存在
  - 允许作为 future preview / local planning 的候选能力来源
  - 但不允许在本轮被用户直接理解为“你的主复习计划就是它说了算”
- **Must not do:**
  1. 不写“本地已为你更新复习计划”
  2. 不写“系统已重新安排下次复习”
  3. 不写“你的复习规划已刷新”
  4. 不在 ReviewPage 展示依赖 local FSRS 成功的解释性状态

## 4.3 UI-P3.3.2-006 — ReviewPage 继续 `cloud-first + local side-effect`
- **Status:** Frozen for this round
- **UI rule:** 页面可见层继续只接受：
  - cloud submit success 作为主流程继续条件
  - local side-effect 继续保持幕后补强
  - local fallback 不额外制造误导
- **UI consequence:**
  1. 用户能感知的是：答题继续、组完成、云端主流程继续正确
  2. 用户不能感知的是：本地 bridge / planner 成功细节
  3. fallback 不弹用户错误，但 dev/test 可观察性必须保留

## 4.4 UI-P3.3.2-007 — owner split 不等于 planner merge
- **Status:** Frozen for this round
- **UI rule:** 当前页面层允许表达“分层共存”，不允许表达“统一规划已成立”。
- **Must not do:**
  1. 不得新增“统一学习计划”标题
  2. 不得新增“系统已整合新词与复习计划”
  3. 不得新增“下一阶段学习安排已完成”
- **Allowed phrasing:**
  - “继续复习”
  - “背单词”
  - “本组复习完成”
  - “开始今天的学习”
  - “你有一组复习未完成”

---

## 5. 页面与状态层影响

## 5.1 SpecHomePage
### 本轮应保持
1. “背单词”继续作为首页最强主 CTA
2. 默认导航仍进入 StudyPage
3. 若存在 active `review_group` continuation，可增加：
   - 次强 CTA
   - helper
   - summary block
4. 但不改动“背单词”主入口的默认承接逻辑

### Room 5 推荐 UI 结构
- **主 CTA：** 背单词
- **次强 CTA / helper：** 继续复习（仅在 active `review_group` 时出现）
- **弱提示：**
  - 你有一组复习未完成
  - 继续完成本组复习

### 本轮不建议新增
- 自动分流 badge
- mixed mode badge
- planner explanation 区块
- “今天系统已帮你规划好学习路径”之类说明

## 5.2 StudyPage
### 当前口径
1. StudyPage 仍是默认学习入口页
2. 不承担 review planner dispatcher 的页面职责
3. 不新增“系统根据规划把你送到这里”的解释型文案
4. 保持已有 4 按钮、final wording、低阻力提交流程不变

## 5.3 ReviewPage
### 当前口径
1. ReviewPage 继续是 cloud `review_group` 的承接页
2. 可继续展示 group progress / remaining / group completion
3. 不应展示 planner merge / unified planning / preview explanation
4. local FSRS bridge 的存在继续保持用户不可见
5. fallback 不弹用户错误，但执行层必须保留 dev/test 可观测性

---

## 6. 文案与事实边界（Room 5 给 Room 4 / Room 1 的 UI 挡板）

## 6.1 当前允许的表达
- 背单词
- 继续复习
- 你有一组复习未完成
- 本组复习完成
- 开始今天的学习
- 先学一组新词

## 6.2 当前不允许的表达
- 系统已自动为你分流
- 已为你安排今天复习模式
- 已切换到最佳学习路径
- 已整合你的学习计划
- 复习规划已更新
- 本地计划已同步
- 统一学习模式已启用

## 6.3 Fact Copy 禁区（本轮新增）
以下表达当前轮不得进入页面事实层：
- 自动分流
- 混合学习已开启
- 统一规划已完成
- 复习路径已重排
- 本地规划已接管
- 已根据 FSRS 自动切换入口

---

## 7. State Contract Matrix（P3.3.2 最小版）

## 7.1 Home 主入口
- **UI state:** 首页“背单词”主入口可见
- **Trigger rule / BR:** `home_word_entry = study_default`
- **Required fields / API:** 无需新增 API 才能保持当前入口
- **Local-only or source-of-truth:** 页面结构级 UI state
- **Loading / retry / stale behavior:** 无新增要求
- **Fact copy:** “背单词”
- **Tone copy:** “开始今天的学习 / 先学一组新词”
- **Gap / blocker:** 若未来要自动分流，需新一轮 contract pin

## 7.2 active `review_group` continuation
- **UI state:** 可出现次强 CTA / helper / priority block
- **Trigger rule / BR:** active `review_group` continuation 高优先
- **Required fields / API:** 当前可先基于既有 group / remaining / continuation 相关聚合信号；若未来要做更强 priority block，需 Room 1 单独吸收 contract
- **Local-only or source-of-truth:** 依赖 cloud-side review truth
- **Loading / retry / stale behavior:** 不得让它吞掉默认 `背单词` 入口
- **Fact copy:** “继续复习 / 你有一组复习未完成”
- **Tone copy:** 可轻提示，不可宣告 auto-routing
- **Gap / blocker:** 更强 CTA winner 状态驱动仍 pending

## 7.3 planner_owner_split_v1
- **UI state:** 页面只表现 cloud-first 主流程 + local side-effect 不可见
- **Trigger rule / BR:** `planner_owner_split_v1`
- **Required fields / API:** 当前不新增 planner merge contract
- **Local-only or source-of-truth:** cloud `review_group` = ReviewPage serving truth；local FSRS = device-side scheduling owner
- **Loading / retry / stale behavior:** local fallback 不弹用户错误，但必须可被 dev/test 观察
- **Fact copy:** 不得写“规划已更新 / 已自动调整”
- **Tone copy:** 无
- **Gap / blocker:** stronger planner contract 继续 pending

---

## 8. Room 5 对 Room 1 的建议

### 8.1 Room 5 建议 Room 1 吸收
Room 1 若要吸收本轮结论，建议只吸收以下 3 条：

1. **进入 `next-layer minimal contract`**
2. **冻结 `session_entry_policy_v1`**
   - `home_word_entry = study_default`
   - active `review_group` continuation 高优先，但当前不等于 silent reroute
3. **冻结 `planner_owner_split_v1`**
   - ReviewPage = cloud `review_group` serving truth owner
   - local FSRS = device-side scheduling owner
   - ReviewPage 继续 `cloud-first + local side-effect`

### 8.2 Room 5 不建议本轮吸收成 runtime truth 的内容
1. mixed / auto-routing runtime contract
2. unified planner / planner merge
3. unified Study / Review page
4. `previewDurations` 重开
5. planner explanation / next interval UI

---

## 9. Room 5 一句话结论

> **P3.3.2 在 Room 5 视角，可以前进一步，但只应前进到“默认入口语义 + owner split 的页面合同层”：首页“背单词”继续默认进入 StudyPage；active `review_group` continuation 继续通过独立 CTA / helper 承接，而不是吞掉默认入口；ReviewPage 继续只表现 `cloud-first + local side-effect`，不把 local FSRS 或 planner merge 写成用户可依赖事实。**
