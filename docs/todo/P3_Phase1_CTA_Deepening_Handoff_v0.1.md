# OPP-001 / 背单词喵喵 App — Room 4 → Cursor
# Phase 1（CTA Deepening）Implementation Handoff v0.1

- **From:** Room 4（Eng + QA + Debug Tech Lead）
- **To:** Cursor
- **Date:** 2026-04-05
- **Status:** ready to execute
- **Phase:** P3 / Phase 1 — CTA Deepening
- **Execution mode:** contract-first, fallback-safe, test-led

---

## 0. 你现在为什么可以进入 Phase 1

这轮不是自由发挥，而是因为 Room 1 已经给出 **final recommendation**，足以满足 Phase 1 的 entry gate。

本轮按已拍板口径执行：

### 本轮已 pin（视为 active for this phase）
1. **接受 very small CTA contract pin**
2. `today_primary_action` 本轮进入的字段只有：
   - `action`
   - `reason`
3. **本轮明确不进入：**
   - `priority_band`
   - `blocking_condition`
4. **所有 absent / delayed / degraded 情况：**
   - 一律回退到 **current active Option C CTA baseline**

一句话：

> **这轮只把 CTA decision-support 做到 very small、可实现、可测试的程度；不把 CTA 做成大引擎。**

---

## 1. 你必须先理解的项目边界

你读不到我们的项目文件，所以以下边界直接以本 handoff 为准执行。

### 1.1 当前项目状态
项目已完成：
- P1 主机制最小闭环
- P2 副机制 MVP 承接
- Option A / A.1 persistence hardening
- Option B / B2 polish
- Option C 主机制最小增强

当前主线程已进入：
- **P3 — Main Mechanism Deepening**

### 1.2 Phase 1 的唯一主题
这轮只做：
- **CTA Deepening**

更具体地说，只做：
- Today 页主 CTA 的 very small decision-support 接入
- 让前端在 contract present 时，读后端给的 `action + reason`
- 在 contract absent / delayed / degraded 时，安全回退到 current active Option C CTA baseline

### 1.3 你必须继续服从的硬边界
1. **只按当前 active runtime baseline 实现，不要自己改需求。**
2. **前端不得自行推导最终 CTA winner。**
3. **`today_primary_action` 只是 decision-support block，不是“大型 CTA 引擎毕业版”。**
4. **本轮不实现 `priority_band` / `blocking_condition`。**
5. **不新增 route / page / 一级导航。**
6. **Today 页仍然只能有一个最强主 CTA。**
7. **Session 不能因为这轮实现而变成双主 CTA 之一。**
8. **不能为页面完整性而 fake contract / dummy payload / mock winner 进入 production path。**
9. **若 contract 不满足要求，宁可回退 current active Option C baseline，也不要本地补脑。**

---

## 2. 本轮 contract 定义（按 Room 1 最终推荐执行）

### 2.1 允许进入的 very small CTA decision-support contract

```ts
interface TodayPrimaryAction {
  action: 'continue_review_group' | 'go_review' | 'go_new_words' | 'go_session'
  reason: 'active_review_group' | 'review_due_priority' | 'new_words_remaining' | 'session_pending'
}
```

### 2.2 本轮明确不进入的字段
即使你在旧讨论里看到它们，也 **不要做**：

- `priority_band`
- `blocking_condition`
- 任何更细评分字段
- 任何“为什么算法这样判”的解释字段
- 任何 CTA 文案引擎式扩展字段

### 2.3 对 contract 的保守解释
- **只有当 `action` 和 `reason` 都可用时，才算 contract present。**
- 只缺一个字段，也按 **contract unavailable** 处理。
- contract unavailable 时：**整块 CTA 决策支撑回退到 current active Option C CTA baseline**。
- 不允许只凭 `action` 去“半接入、半补脑”。

---

## 3. 你要完成的任务（执行顺序）

## Task A — 找到现有 Today CTA 产出路径
先在代码里定位：
1. Today 页主 CTA 当前由哪里决定
2. 当前 active Option C CTA baseline 的 winner 逻辑在哪
3. 当前 Today aggregate / selector / model / viewmodel / widget / component / state mapper 的入口在哪
4. 哪一层最适合接入 `today_primary_action`

目标：
- 找到**单一入口**接这轮 contract
- 不要把 contract 判断散落到多个组件里

### 要求
- 优先改 selector / adapter / resolver / mapper 层
- 尽量不要把 fallback 判断写进 UI component 树的很多分支里

---

## Task B — 接入 very small CTA contract（action + reason）
在当前 Today aggregate / API response / model 层中，做 **最小且可选** 的接入：

1. 允许读取 `today_primary_action`
2. 允许读取其下的：
   - `action`
   - `reason`
3. 若当前本地类型系统还没有这个字段：
   - 可以加 **optional typing / parsing / adapter seam**
   - 但不能伪造 production 数据

### 实现目标
当 contract present 时：
- 主 CTA 使用 `today_primary_action.action` 驱动
- reason line 使用 `today_primary_action.reason` 驱动
- CTA 仍保持单一最强按钮
- UI 不展示 `priority_band` / `blocking_condition`

### 显示要求
- `reason` 只能作为 **弱说明 / supporting line**
- 不得把 `reason` 做成第二主按钮
- 不得把 `reason` 写成业务完成态
- 不得把 `reason` 做成新的复杂 badge 系统

---

## Task C — 明确回退路径（最重要）
你必须把以下情况统一回退到 **current active Option C CTA baseline**：

### C1. absent
以下任一情况都算 absent：
- `today_primary_action` 不存在
- `today_primary_action` 为 null / undefined
- `action` 缺失
- `reason` 缺失

### C2. delayed
若 Today 聚合明确处于 delayed / stale / not-ready / awaiting-decision-support 等延迟语义，也回退 current baseline。

### C3. degraded
若 Today 聚合明确处于 degraded / partial / fallback-only / degraded-decision-support 等降级语义，也回退 current baseline。

### C4. unexpected shape
若 `action` / `reason` 出现未知枚举值、非法值、空字符串、异常 shape，也回退 current baseline。

### 回退要求
- 主 CTA 继续由 current active Option C CTA baseline 产出
- 不展示 reason line
- 不展示任何 band / helper / extra badge
- 不新增错误弹层
- 允许弱提示（仅当当前 UI 体系本来就已有一致的弱提示容器），但不要新造一套提示系统

---

## Task D — 保持 Option C 已冻结最小层不回退
这轮不能破坏以下已存在行为：

1. Today 页任何时刻只有 **一个** 最强主 CTA
2. active `review_group` continuation-first 不回退
3. 在 fallback path 下，CTA 行为应与 current active Option C baseline 一致
4. Session 默认仍不是自动最高主 CTA
5. 不允许出现“双主 CTA”

也就是说：
- **新 contract 只是增强支撑，不是推翻 baseline。**

---

## Task E — 只做本轮 in scope 的 UI 变化
本轮 UI 只允许出现以下新增变化：

1. 当 contract present 时，Today 主 CTA 可由后端 decision-support block 直接驱动
2. CTA 下方可出现一行轻量 `reason line`
3. 当 contract 不可用时，页面安全回退

本轮明确不做：
1. `priority_band` badge
2. `blocking_condition` helper
3. 新的 CTA 解释面板
4. 新的独立统计页
5. review deeper summary
6. streak basis 切换相关实现
7. 任何 secondary backlog 回流

---

## Task F — 测试必须和实现同轮交付
你不是只交 feature；你必须同时交：
- tests
- fallback regression
- self-test summary

### 必测用例（至少覆盖）

#### F1. contract present
1. `action=continue_review_group, reason=active_review_group`
   - 主 CTA 正确
   - reason line 正确
   - 仍只有一个最强主 CTA

2. `action=go_review, reason=review_due_priority`
   - 主 CTA 正确
   - reason line 正确

3. `action=go_new_words, reason=new_words_remaining`
   - 主 CTA 正确
   - reason line 正确

4. `action=go_session, reason=session_pending`
   - 主 CTA 正确
   - 不出现双主 CTA

#### F2. contract absent / invalid
5. `today_primary_action` 缺失
   - 完整回退 current Option C CTA baseline
   - 不展示 reason line

6. `action` 有值、`reason` 缺失
   - 按 absent 处理
   - 完整回退 current baseline

7. `reason` 有值、`action` 缺失
   - 按 absent 处理
   - 完整回退 current baseline

8. 未知 `action` / 未知 `reason`
   - 完整回退 current baseline

#### F3. delayed / degraded
9. delayed state
   - CTA 按 current baseline 回退
   - 不展示 reason line

10. degraded state
    - CTA 按 current baseline 回退
    - 不展示 reason line

#### F4. non-regression
11. fallback path 下 continuation-first 不回退
12. 不出现双主 CTA
13. 不新增新 route / 新导航副作用
14. 即使后端多返回了 `priority_band` / `blocking_condition`，前端这轮也必须忽略，不显示、不依赖

### 测试层要求
- 能写单元测试就写单元测试
- 能写 widget / component / viewmodel 测试就一起写
- 若有 integration / e2e harness，可补最小一条高价值回归
- 重点不是“测很多”，而是“测准 present / absent / delayed / degraded / non-regression”

---

## 4. 实现策略建议（你可以按仓库现实微调，但不能越边界）

### 推荐结构
优先采用：
1. **adapter / parser / model layer**：吸收 optional contract
2. **CTA resolver / selector layer**：统一 present vs fallback 决策
3. **viewmodel / mapper layer**：产出主 CTA + optional reason line
4. **UI layer**：只渲染结果，不自行推 winner

### 不推荐
- 在 UI widget / component 内临时拼 winner 逻辑
- 在多个页面各自写一套 fallback
- 直接在 production 代码里 hardcode 假 contract
- 用测试 fixture 倒逼 production path 接受无定义 shape

---

## 5. 交付标准（completion bar）

只有同时满足以下条件，这轮才算完成：

1. Today CTA 能在 contract present 时正确消费 `action + reason`
2. absent / delayed / degraded / invalid shape 全部安全回退 current active Option C CTA baseline
3. 没有引入 `priority_band` / `blocking_condition` 的 UI 或依赖
4. 没有引入双主 CTA
5. 没有引入 fake contract / dummy payload production path
6. 测试通过，且有清楚的 self-test summary

---

## 6. 你最后要交付给我的内容

请按以下格式交付：

### 6.1 Code summary
- 改了哪些文件
- 每个文件改动的目的是什么

### 6.2 Behavior summary
- contract present 时行为
- absent / delayed / degraded 时行为
- 本轮明确没做什么

### 6.3 Test summary
- 新增了哪些测试
- 跑了哪些测试
- 是否全部通过

### 6.4 Risk / follow-up
- 还有哪些地方依赖后续 Phase 2+，但本轮没有碰
- 若仓库当前没有明确 delayed / degraded 标记，你是如何做“最保守实现”的

---

## 7. 最后一句话

> **你这轮的目标不是“让 CTA 更花”，而是“在 Room 1 已 pin 的 very small contract 下，把 CTA deepening 做得可运行、可测试、可回退”。**

