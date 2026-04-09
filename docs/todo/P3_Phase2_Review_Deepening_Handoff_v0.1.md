# OPP-001 / 背单词喵喵 App — Room 4 → Cursor
# P3 Phase 2 — Review Structured Deepening Handoff v0.1

- **From:** Room 4（Eng + QA + Debug Tech Lead）
- **To:** Cursor
- **Date:** 2026-04-06
- **Status:** executable implementation handoff
- **Scope:** P3 — Main Mechanism Deepening / Phase 2 only
- **Important:** 你不能读取我们的项目文档；以下内容就是本轮唯一有效指令。请不要自行补脑业务规则。

---

## 0. 这轮你要做什么

你现在只做 **P3 Phase 2 — Review Structured Deepening**。

这轮不是重写 review system，也不是做完整 SRS / 完整 priority engine，而是：

> **把 Today / Review 页里最容易被误读的 review deeper state 做清楚，但仍以后端聚合结果为准。**

本轮重点只有 5 个：
1. active group deeper summary
2. current group progress
3. active_group_completed
4. daily_review_progress
5. next_group_readiness（只读）

---

## 1. 先服从这些硬边界

### 1.1 你必须继续服从的当前 frozen truth
1. 学习优先，副机制承接。
2. 主机制事实以后端为准；前端不得自己推导最终业务事实。
3. 当前 `daily_goal_status`、`session_validation_status`、主机制结算层边界都不能回退。
4. `review_group` 的最小合同不能回退：
   - 后端生成、后端持有
   - 单用户单 active group
   - 可跨 Session continuation
   - group completion 只推进 review progress，不自动等于今日完成
   - 不得重复完成 / 重复结算 / 重复发奖
5. Option C 已有最小层不能回退：
   - Today 单一最强主 CTA
   - continuation-first
   - statistics 仍是 summary-first
   - streak 当前仍按 check-in

### 1.2 这轮明确禁止
1. **禁止** 用 remaining count、本地排序、组内题数完成度去推断 `next_group_readiness`。
2. **禁止** 用 `active_group_completed=true` 推断“今日复习完成”。
3. **禁止** 在 UI 层自行排序 review priority。
4. **禁止** 趁机扩写完整 SRS / 完整分组算法 / 完整 priority engine。
5. **禁止** 新增 statistics route / 一级导航。
6. **禁止** 修改 streak runtime truth。
7. **禁止** 因为页面想更完整而造 fake contract / dummy payload / dead shell。

---

## 2. 本轮假定已被 Room 1 拍板的最小 contract（按 Room 4 推荐方案）

按当前主线程口径，这轮你可以把下面这组 **very small review deepening contract** 当成已被接受进入 active baseline 的目标形状；但你的实现仍必须保持 strict parsing：字段缺失 / 非法枚举 / 结构不完整时，一律视为 contract absent，然后回退到当前 baseline。

### 2.1 推荐最小 contract

```json
{
  "review_summary": {
    "has_active_group": true,
    "active_group_progress": {
      "completed_items": 3,
      "total_items": 8
    },
    "active_group_completed": false,
    "daily_review_progress": {
      "completed_units": 1,
      "required_units": 3,
      "status": "in_progress"
    },
    "next_group_readiness": "not_ready"
  }
}
```

### 2.2 允许的字段说明
- `has_active_group: boolean`
- `active_group_progress.completed_items: non-negative int`
- `active_group_progress.total_items: positive int`
- `active_group_completed: boolean`
- `daily_review_progress.completed_units: non-negative int`
- `daily_review_progress.required_units: positive int`
- `daily_review_progress.status: "not_started" | "in_progress" | "completed"`
- `next_group_readiness: "ready" | "not_ready"`

### 2.3 这轮明确不进入
1. 完整 SRS 字段
2. 完整 review priority 评分细节
3. next group 的原因解释全集
4. 本地生成的 readiness 推理层
5. 任何“智能学习引擎毕业版”语义

---

## 3. contract 缺失 / 非法时的统一处理

这轮必须继续沿用 P3 的 guard 哲学：

### 3.1 strict parsing
只要出现以下任一情况，都把 `review_summary` 当作 **absent**：
- 整块缺失
- 某个关键字段缺失
- 数字不合法
- `status` 非法
- `next_group_readiness` 非法
- 结构不完整

### 3.2 absent / invalid fallback
一旦 `review_summary` 被视为 absent：
1. Today 和 Review 页都**隐藏 deeper summary 展示**；
2. 完整回退到当前 active Option C baseline；
3. 仍保留 continuation-first 行为；
4. 不显示 next group readiness；
5. 不显示任何会误导用户以为“本组完成 = 今日完成”的新文案。

---

## 4. 你要改的东西（工程层）

请以当前 repo 实际文件为准定位，但总体改动应集中在以下几层：

### 4.1 Backend / contract 层
目标：让 Today 聚合与 Review 相关读取能稳定返回上面的 `review_summary`。

建议工作：
1. 在 API domain types 中新增 `ReviewSummary` 相关类型。
2. 在 dev store / today state 聚合 / review state 聚合中新增 `computeReviewSummary()` 或等价逻辑。
3. 逻辑必须坚持：
   - readiness 只来自后端聚合判断，不从 remaining count 临时推导给前端；
   - `active_group_completed` 和 `daily_review_progress.status` 分离；
   - 当前 contract 只做到 very small summary，不扩展为完整 review algorithm。

### 4.2 Mobile API parsing 层
目标：前端严格解析 `review_summary`，不合法就回退。

建议工作：
1. 在当前 TodayState / ReviewState 对应的数据模型里新增 `ReviewSummaryData` 或等价类。
2. 提供 strict `tryParse()`：unknown / missing / malformed → `null`。
3. 不要写“尽量解析”或“猜一个默认值”的宽松 parser。

### 4.3 Today 页
目标：补上弱展示层，但不改变 CTA winner 主路径。

建议工作：
1. 在 Today 主任务卡下方或合适位置新增 **review deeper state block**（弱于主 CTA）。
2. 只展示：
   - 当前 group progress：例如 `本组进度 3/8`
   - `active_group_completed` 的中性说明：例如 `本组已完成`
   - `daily_review_progress` 的边界说明：例如 `今日复习进度 1/3`
   - `next_group_readiness` 的弱说明（仅当 contract 存在且值合法时）
3. CTA 逻辑不要重写；Phase 1 已完成的 CTA deepening 继续保持。
4. 若 deeper summary 缺失，则不占位、不显示假壳子。

### 4.4 Review 页
目标：把 deeper state 说清，但不做成控制台。

建议工作：
1. 在当前 Review 页中增加与 Today 一致的 deeper summary 展示。
2. 要让用户能看懂三层边界：
   - 本组进度
   - 本组是否完成
   - 今日复习整体进度
3. 若 `next_group_readiness=not_ready`，可以展示弱说明，例如：
   - `完成本组后，是否能进入下一组仍以后端判断为准`
   或更短、更自然的中性文案。
4. 不要出现责备式文案。

### 4.5 Shared UI / copy / states
目标：Today 和 Review 的状态表达一致。

要求：
1. 同一状态不要在两个页面用相反表达。
2. `active_group_completed=true` 时：
   - 可以写“本组已完成”
   - 不能写“今日复习已完成”（除非后端 `daily_review_progress.status=completed`）
3. `next_group_readiness=ready` 时：
   - 只能表达“下一组可继续”
   - 不能写“今日目标已完成”

---

## 5. 你必须覆盖的测试

### 5.1 Backend tests
至少覆盖：
1. `review_summary` 存在且结构正确时，聚合返回正确。
2. `active_group_completed=true` 不会自动把 `daily_review_progress.status` 改成 completed。
3. `next_group_readiness` 只走后端聚合结果，不从局部 remaining count 反推。
4. absent / malformed contract 时，聚合层可以安全返回空。

### 5.2 Frontend parsing tests
至少覆盖：
1. 完整合法 contract → parse success。
2. 缺关键字段 → null。
3. 非法 status / readiness → null。
4. 数字不合法（负数、0 total、required=0）→ null。

### 5.3 Today page tests
至少覆盖：
1. contract present 时显示 deeper summary。
2. contract absent 时不显示 deeper summary，并保持当前 CTA baseline 行为。
3. `active_group_completed=true` 时不误显示“今日复习已完成”。
4. `next_group_readiness=ready` 时只出现弱说明，不改变 CTA winner。

### 5.4 Review page tests
至少覆盖：
1. no active group
2. active group in progress
3. active group completed but daily review not completed
4. readiness not ready
5. readiness ready
6. absent contract fallback

### 5.5 Regression
必须确保：
1. Phase 1 CTA 行为不回退。
2. statistics summary-first 路径不被误伤。
3. streak 相关现有展示不变化。
4. 现有 guard tests 继续通过。

---

## 6. 交付要求

你交付时必须给我下面 4 样东西：

### 6.1 Code summary
用表格列出：
- 改了哪些文件
- 每个文件做了什么
- 为什么改

### 6.2 Behavior summary
明确说明：
1. contract present 时页面如何表现
2. absent / invalid / degraded 时如何回退
3. 这轮明确没做什么

### 6.3 Test summary
至少给：
- flutter test
- flutter analyze
- 后端单测 / e2e
- 总测试数与通过情况

### 6.4 Risk / follow-up
单列：
- 这轮还没做的 deeper review / stats / streak 内容
- 下一轮可能衔接的 seam
- 任何你认为仍需 Room 4 审核的边界风险

---

## 7. Completion bar（只有全部满足才算完成）

以下 8 条全部满足，Room 4 才会认定 **Phase 2 可进入 review**：

1. `review_summary` 接入完成，且 strict parse 已做；
2. Today / Review deeper summary 已落地；
3. absent / invalid contract 能完整回退；
4. 没有任何 remaining-count 推导 readiness 的实现；
5. 没有把 `active_group_completed` 写成“今日复习完成”；
6. Phase 1 CTA 行为不回退；
7. 测试与回归一起交付；
8. 你给出 self-test summary，而不是只说“应该没问题”。

---

## 8. 一句收口

这轮你做的不是“把 review system 做复杂”，而是：

> **把 review deeper state 做清楚，但继续把最终业务判断留在后端。**

做完后停在 Phase 2，不要自动开 Phase 3 / Phase 4。
