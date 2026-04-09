# Cursor_OptionC_C3_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是直接推进 C4 / C5，也不是补做 C0 / C1 / C2，而是：

> **在且仅在 C2 已判定 `ready for C3` 的前提下，完成 Option C 的 Phase C3：Statistics minimal spec。**

---

## 0. 先说清楚：这是一份“带前置门槛”的 C3 指令

这份指令默认前提不是“C2 已经自动通过”，而是：

> **你必须先读取 C2 的产物，并确认 C2 的最终判断是 `ready for C3 = YES`。**

如果你读完 C2 产物后发现：
- C2 还没完成
- C2 明确写了 `ready for C3 = NO`
- 或 C2 发现当前 active truth 还不足以安全进入 statistics minimal spec

那么你这轮**不得继续实现 C3**，而必须：

1. 停止进入 C3 开发
2. 输出一份简短阻塞说明
3. 明确写出：
   - 哪条 blocker 还没解除
   - 为什么现在不能安全进入 C3

也就是说：

> **C3 是 conditional start，不是 unconditional start。**

---

## 1. 当前项目一句话

这是一个：

> **学习驱动型轻养成 App（背单词 + 云养猫）**

当前项目已完成并 close：
- P1
- P2
- Option A
- Option A.1
- Option B（B1）
- B2-1
- B2-2
- B2-3

Room 1 已正式把主线程切到：

> **Option C — Main Mechanism Enhancement**

而你现在接的不是：
- C0（Entry sync / active-version pin check）
- C1（Today CTA winner）
- C2（Review continuation / minimal review boundary）
- C4（Streak truth-boundary hardening）
- C5（Test & closeout）

你现在只做：

> **C3 — Statistics minimal spec**

---

## 2. C3 的核心目标

C3 不是做完整统计产品，也不是做 BI 平台，更不是补全所有图表。

C3 的唯一核心目标是：

> **把 statistics 收到 `summary-first / minimal summary` 的最小可运行规格，让用户获得最小结果感，但不把统计页做厚。**

更具体地说，C3 要解决的是：

1. 本轮 statistics 是否真正进入实现范围
2. 若进入：
   - 默认先落在 **summary block / summary card / minimal entry**
   - 不自动承诺独立完整页面
3. “学习天数”必须明确基于 **`learning_day`**
4. 不把：
   - `check_in`
   - `streak`
   混写成学习天数
5. 不在 Room 1 未 pin 独立 minimal page 时，自己扩成“完整统计页”

一句话：

> **C3 做的是最小统计结果感，不是统计系统毕业版。**

---

## 3. 你必须先接受的前提

### 3.1 先读 C2 产物（必须）
你必须先读取：

- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_C2_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C2_v0.1.md`

并明确确认：

> **C2 的最终判断是 `ready for C3 = YES`。**

### 3.2 默认仍按当前 runtime active baseline 工作
除非 C0 / C1 / C2 的正式产物明确写了已有新 pin，否则你默认仍必须按：

#### 当前 runtime active BR baseline
- `BR-OPP-001_v0.1.5.md`

#### 当前 runtime active DB baseline
- `背单词喵喵app_DB设计草案_v0.1.4.md`

#### 当前 runtime active API baseline
- `背单词喵喵app_API设计草案_v0.1.3.md`

#### 当前 runtime active UI baseline
- `UI_SPEC_OptionB_v0.1.2.md`

#### Option C candidate inputs（默认不是自动 active）
- `R2_OptionC_MainMechanism_Preflight_v0.1.1.md`
- `BR-OPP-001_v0.1.7.md`
- `UI_SPEC_OptionC_MainMechanism_v0.1.1.md`
- `R4_OptionC_Preflight_Implementation_Plan_v0.1.1.md`
- `optionc_phases.md`

### 3.3 Room 4 的执行纪律
你必须继续服从：

> **未被 Room 1 pin 的内容，不得被实现层偷转成 active truth。**

尤其是：

- Room 2 提到的 **minimal stats summary contract clarification**
- Room 5 提到的 statistics 独立 minimal page 形态
- BR v0.1.7 中对 statistics 的更细 candidate 口径

如果 C0 / C1 / C2 没明确写这些已进入 active truth，就按保守路径。

---

## 4. 这轮你到底要做什么

这轮只做：

1. **先读 C2 产物**
2. 判断是否 **ready for C3**
3. 如果 ready：
   - 做 statistics 的 `summary-first / minimal summary`
   - 默认先落在 summary block / summary card / minimal entry
   - 明确“学习天数 = learning_day”
   - 确保不把 `check_in / streak` 混写成学习天数
   - 补最小统计展示与 truth-boundary 测试
   - 输出 C3 状态 / 结果 / round summary
4. 如果 not ready：
   - 不实现 C3
   - 输出阻塞说明并停止

这轮**不做**：
- 不进入 C4
- 不进入 C5
- 不做独立完整统计产品
- 不做趋势分析后台
- 不做重 BI
- 不默认引入未 pin 的 minimal stats summary contract clarification
- 不新增 endpoint / 主结构 / 状态机

---

## 5. C3 的正确实现边界

### 5.1 Frozen 层（当前必须服从）
以下是你这轮可以直接服从的最小边界：

1. Option C 允许 statistics 进入，但只到 **`summary-first / minimal summary`**
2. “学习天数”必须基于 **`learning_day`**
3. `check_in` 只表示签到事实，不等于学习天数
4. `streak` 当前按签到延续，不得被写成学习天数
5. statistics 的默认落地形态应优先是：
   - summary block
   - summary card
   - minimal entry
6. 若 Room 1 未 pin独立 minimal page，不得默认扩成完整统计页

### 5.2 继续 Pending 的层（这轮不能偷实现）
以下内容本轮继续属于 pending，不得自己补全为“正式统计产品”：

1. 独立完整统计页
2. 趋势分析、长期曲线、大图表
3. 更深的数据分析后台
4. 与 streak future basis switch 绑定的统计口径切换
5. 更细 minimal stats summary contract clarification（除非 C0/C1/C2 明确写已 pin）

---

## 6. 两种合法实现路径

你必须根据 C0 / C1 / C2 结论在以下两条路径中选一条。

---

### Path C3-A（默认保守路径）
适用条件：
- C0 明确写：
  - minimal stats summary clarification = **NOT PRESENT**
- 且 C1 / C2 没有新增任何 Room 1 已 pin 的 stats summary block
- Room 1 未 pin 独立 minimal page

此时你必须：

1. 仅基于当前 active API / active UI baseline 已稳定存在的信息落地
2. statistics 默认只做：
   - summary block
   - summary card
   - minimal entry
3. 不新增独立完整页面
4. 若当前 active API 只能提供基础 summary，就只按基础 summary 落地
5. 明确把“学习天数”映射到 `learning_day`
6. 不在 UI 上把 `check_in` 或 `streak` 写成学习天数

---

### Path C3-B（仅在 C0 / C1 / C2 明确写可用时）
适用条件：
- C0 / C1 / C2 明确写：
  - minimal stats summary clarification
  - 已被 Room 1 接受 / 已可按 active truth 执行
- 或 Room 1 明确 pin 了独立 minimal page 进入

此时你可以：

1. 基于后端明确返回的 summary block / summary contract 做更稳实现
2. 若 Room 1 已 pin 独立 minimal page，可进入 page-level 最小实现
3. 但仍不能把统计做成完整产品，更不能与 C4 的 future basis switch 混写

---

## 7. 这轮 in scope

### 7.1 summary-first / minimal summary（必须）
请做 statistics 的最小展示，只到：

- summary block
- summary card
- minimal entry

而不是：
- 完整分析页
- 大图表页
- 重 BI 页

### 7.2 “学习天数 = learning_day”（必须）
你必须把这条做成明确的实现与页面表达边界：

- 学习天数 = `learning_day`
- 不能由 `check_in` 代替
- 不能由 `streak` 代替

### 7.3 不混写 `check_in / learning_day / streak`（必须）
统计相关展示不得出现以下误导：

- 签到成功 → 直接算学习天数
- streak 连续天数 → 直接算学习天数
- 学习天数 → 写成连续签到天数

### 7.4 默认不承诺独立 minimal page（必须）
如果当前没有被 Room 1 pin 的独立 page 进入判断，你必须：

- 先按 summary-first 的 block / card / entry 落地
- 不自行扩成独立完整统计页
- 不因为“做起来也不难”而扩大范围

### 7.5 与 Today / 结果承接层的最小一致性（必须）
如果 statistics 有入口 / summary 卡：

- 不能与 Today / 结果层的 `learning_day` 语义打架
- 不能和 streak 当前口径打架
- 不能反向改写 C1 / C2 的页面表达

---

## 8. 这轮明确不做什么

### 8.1 不做完整统计产品
不做：
- 趋势折线图
- 周/月维度深分析
- 排名、对比、洞察
- 高级图表集

### 8.2 不做 C4 / C5
不进入：
- streak truth-boundary hardening
- unified closeout

### 8.3 不新增主结构
不新增：
- endpoint
- DB 主结构
- 主状态机
- 新 contract patch

除非 C0 / C1 / C2 明确写某个 clarification 已被 pin 且本轮必须消费。

---

## 9. 你必须先读 repo 里什么

### 9.1 C0 / C1 / C2 产物（必须优先）
- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_Entry_Sync_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C0_v0.1.md`
- `docs/R4_OptionC_C1_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C1_v0.1.md`
- `docs/R4_OptionC_C2_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C2_v0.1.md`

### 9.2 Option C 输入
- `R1_OptionC_Formal_Handoff_Pack_v0.1.md`
- `R2_OptionC_MainMechanism_Preflight_v0.1.1.md`
- `BR-OPP-001_v0.1.7.md`
- `UI_SPEC_OptionC_MainMechanism_v0.1.1.md`
- `R4_OptionC_Preflight_Implementation_Plan_v0.1.1.md`
- `optionc_phases.md`

### 9.3 当前 runtime active baseline
- `Main_updated_2026-04-05_v13.md`
- `STATUS_updated_2026-04-05_v12.md`
- `BR-OPP-001_v0.1.5.md`
- `背单词喵喵app_DB设计草案_v0.1.4.md`
- `背单词喵喵app_API设计草案_v0.1.3.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `UI_SPEC_v0.1.4.md`
- `plan_v0.1.2.md`
- `TEST_PLAN_v0.1.2.md`

### 9.4 代码层必须盘点的位置
至少检查：

1. 当前 statistics / summary / stats entry 在哪里
2. 当前 `learning_day` 数据从哪里来
3. 当前 `check_in` / `streak` 的展示和 helper 在哪里
4. 当前 Today / result / stats 之间有没有共享 summary 组件
5. 当前是否已有独立 stats page / route / placeholder
6. 当前与 stats 相关的 widget / integration / regression tests 在哪

---

## 10. C3 你必须明确回答的问题

### Q1. C2 是否真的允许进入 C3
请明确：
- `ready for C3 = YES / NO`
- 依据是什么

### Q2. 你走的是 Path C3-A 还是 C3-B
请明确：
- 走哪条路径
- 为什么
- 依据 C0 / C1 / C2 的哪条结论

### Q3. statistics 最终怎么落的
请明确：
- 是 summary block / summary card / minimal entry，还是独立 minimal page
- 为什么
- 是否有 Room 1 pin 依据

### Q4. “学习天数 = learning_day” 最终怎么守住的
请明确：
- 哪些页面 / 状态 / 文案改了
- 哪些没有改
- 为什么不会再混写 `check_in / streak`

### Q5. 这轮如何保证没越界
请明确：
- 没有偷实现完整统计产品
- 没有默认引入未 pin 的 stats summary clarification
- 没有进入 C4 / C5
- 没有新增主结构

### Q6. 当前最大的剩余风险是什么
至少明确：
- stats clarification 未 pin 的保守路径风险
- summary block 仍不是最终 Room 5 polish 的风险
- 与 future streak basis switch 继续分离的风险

---

## 11. 这轮允许做什么，不允许做什么

### 允许做的
1. statistics minimal spec 的最小实现
2. “学习天数 = learning_day”的展示与状态修正
3. stats / Today / result 相关最小一致性修正
4. stats 相关 widget / integration / regression tests
5. Room 4 状态文档与 round summary 更新

### 不允许做的
1. 不默认把 candidate input 当 active truth
2. 不实现完整统计产品
3. 不进入 streak basis switch
4. 不进入 C4 / C5
5. 不新增 DB / API 主结构
6. 不跳过 C2 gate

---

## 12. 这轮最小测试 / 验证要求

### 12.1 Flutter / front-end
至少执行：
```bash
flutter pub get
flutter test
flutter analyze
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 12.2 Node / backend
如果你只做前端 summary block / stats entry / 展示层修正，backend 不一定要改。  
若你触碰了 stats aggregation / integration / e2e 入口，请至少执行：
```bash
npm test
npm run test:e2e
```

### 12.3 C3 专项验证
至少完成这些验证：

1. statistics 只做到 summary-first / minimal summary
2. “学习天数 = learning_day”
3. `check_in / streak` 未混写成学习天数
4. 未 pin 的 stats clarification 没被偷转成 active truth
5. 没有进入 C4 / C5

### 12.4 建议额外覆盖
- stats summary widget tests
- learning_day vs check_in vs streak boundary tests
- stats entry / summary card / empty state tests
- Today / result / stats 三处一致性 tests

---

## 13. 本轮必须产出的文件（硬要求）

### Deliverable A — 状态文件更新
请更新：

```text
docs/R4_OptionC_Status_v0.1.md
```

至少包含：
1. 当前完成到哪个 phase（必须写 C3）
2. 当前走的是 C3-A 还是 C3-B
3. 当前 statistics minimal spec 的落地结果
4. 是否出现 scope creep
5. 当前是否建议进入 C4

### Deliverable B — 测试摘要 / C3 结果
请新增：

```text
docs/R4_OptionC_C3_Result_v0.1.md
```

至少包含：
1. Statistics current mapping
2. path selection（A / B）
3. “学习天数 = learning_day”的落地结果
4. stats entry / summary shape
5. 哪些边界仍 pending
6. 当前最大的剩余风险

### Deliverable C — Round summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionC_C3_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **Whether C2 truly allowed C3**
3. **Which path (A or B) was used**
4. **How statistics minimal spec now works**
5. **What truth boundary was kept**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current blockers / assumptions / risks**
11. **Whether ready for C4**

### Optional
如果你发现 C2 并不允许进入 C3，才允许新增：

```text
docs/R4_OptionC_Issue_Note_v0.1.md
```

内容必须写清：
- 为什么当前不能安全进入 C3
- 是哪个 blocker 未解除
- 需要 Room 1 / 上游补什么

---

## 14. 这轮完成标准（严格）

以下全部满足，才算 C3 完成：

1. 已先核对 C2 产物
2. `ready for C3` 已被明确判断
3. statistics minimal spec 已落地
4. “学习天数 = learning_day” 已落地
5. `check_in / streak` 未混写成学习天数
6. 未 pin 的 stats clarification 未被偷转成 active truth
7. 没有进入 C4 / C5
8. `docs/R4_OptionC_Status_v0.1.md` 已更新
9. `docs/R4_OptionC_C3_Result_v0.1.md` 已生成
10. `docs/R4_cursor_round_summary_OptionC_C3_v0.1.md` 已生成
11. 最终能明确回答：是否 ready for **C4**

---

## 15. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 **Option C / C3 / Statistics minimal spec**
- 明确说明是否先核过 C2

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 C3 结果
请按这几项写清楚：
1. C2 gate result
2. path used（A / B）
3. statistics mapping
4. learning_day boundary
5. truth-boundary
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 若 backend / e2e 被影响：`npm test` / `npm run test:e2e`
- C3 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_C3_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C3_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **C3**
2. 是否 ready for **C4**
3. 当前最大的剩余风险是什么

---

## 16. 最后提醒

这轮不是让你做完整统计产品，也不是让你偷偷推进 streak 口径切换。

这轮唯一要做好的事情是：

> **在 C2 允许的前提下，把 statistics 的 minimal spec 收口好。**

不要扩 scope。  
不要偷拍板。  
不要把 candidate input 写成 active truth。  
现在开始执行。
