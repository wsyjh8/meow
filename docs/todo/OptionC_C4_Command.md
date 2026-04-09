# Cursor_OptionC_C4_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是直接推进 C5，也不是补做 C0 / C1 / C2 / C3，而是：

> **在且仅在 C3 已判定 `ready for C4` 的前提下，完成 Option C 的 Phase C4：Streak truth-boundary hardening。**

---

## 0. 先说清楚：这是一份“带前置门槛”的 C4 指令

这份指令默认前提不是“C3 已经自动通过”，而是：

> **你必须先读取 C3 的产物，并确认 C3 的最终判断是 `ready for C4 = YES`。**

如果你读完 C3 产物后发现：
- C3 还没完成
- C3 明确写了 `ready for C4 = NO`
- 或 C3 发现当前 active truth 还不足以安全进入 streak truth-boundary hardening

那么你这轮**不得继续实现 C4**，而必须：

1. 停止进入 C4 开发
2. 输出一份简短阻塞说明
3. 明确写出：
   - 哪条 blocker 还没解除
   - 为什么现在不能安全进入 C4

也就是说：

> **C4 是 conditional start，不是 unconditional start。**

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
- C3（Statistics minimal spec）
- C5（Test & closeout）

你现在只做：

> **C4 — Streak truth-boundary hardening**

---

## 2. C4 的核心目标

C4 不是切换 `streak_basis_type`，也不是补签系统，更不是重新定义主机制事实。

C4 的唯一核心目标是：

> **把当前 frozen 的 `check_in / learning_day / streak` 关系在实现、文案、页面表达和测试里彻底守住，并把 future stance 仅保留为方向，不写成 current fact。**

更具体地说，C4 要解决的是：

1. `check_in`
2. `learning_day`
3. `streak`

这三类事实在 Today / 结果承接 / statistics / helper / 文案中不再混写。

当前 frozen 关系必须被实现和表达层严格服从：

- `check_in` 只表示签到事实成立
- `learning_day` 只表示当日满足后端口径的有效学习事实成立
- `streak` 当前阶段按 **`check_in`** 延续
- `learning_day` 成立不自动等于 `streak` 已按学习日延续
- future stance 只能记录方向，不能作为当前页面事实

一句话：

> **C4 做的是 truth-boundary hardening，不是 streak 规则升级。**

---

## 3. 你必须先接受的前提

### 3.1 先读 C3 产物（必须）
你必须先读取：

- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_C3_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C3_v0.1.md`

并明确确认：

> **C3 的最终判断是 `ready for C4 = YES`。**

### 3.2 默认仍按当前 runtime active baseline 工作
除非 C0 / C1 / C2 / C3 的正式产物明确写了已有新 pin，否则你默认仍必须按：

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

- `streak_basis_type` 的 future switch
- `learning_day` 驱动 streak 的 future stance
- 补签 / 宽限逻辑
- 任何组合条件延续 streak 的未来口径

如果 C0 / C1 / C2 / C3 没明确写这些已进入 active truth，就按当前 frozen 关系实现。

---

## 4. 这轮你到底要做什么

这轮只做：

1. **先读 C3 产物**
2. 判断是否 **ready for C4**
3. 如果 ready：
   - 审计并修正 Today / stats / result / helper / copy 中对 `check_in / learning_day / streak` 的表达边界
   - 明确把“学习天数 = learning_day”的展示，与 `check_in / streak` 分开
   - 确保 streak 当前仍按签到延续
   - 清理任何会把 future stance 写成 current fact 的表达
   - 补 truth-boundary 相关测试
   - 输出 C4 状态 / 结果 / round summary
4. 如果 not ready：
   - 不实现 C4
   - 输出阻塞说明并停止

这轮**不做**：
- 不切换 `streak_basis_type`
- 不进入 C5
- 不做补签
- 不做宽限策略
- 不新增 endpoint / 主结构 / 状态机
- 不默认引入未 pin 的 future-basis contract

---

## 5. C4 的正确实现边界

### 5.1 Frozen 层（当前必须服从）
以下是你这轮可以直接服从的最小边界：

1. 当前 MVP 下，`check_in / learning_day / streak` 是三类独立事实
2. `check_in=true` 只表示签到事实成立
3. `learning_day=true` 只表示当日满足后端口径的有效学习事实成立
4. 当前 `streak_basis_type = check_in`
5. `learning_day=true` **不自动等于** streak 已按学习日延续
6. `check_in=true` 也**不自动等于** learning_day 成立
7. “学习天数”若展示，必须基于 `learning_day`
8. future stance 只能写成未来方向，不得写成当前已经切换

### 5.2 继续 Pending 的层（这轮不能偷实现）
以下内容本轮继续属于 pending，不得自己补全为“正式规则升级”：

1. `streak_basis_type` 切换到 `learning_day`
2. `check_in + learning_day` 组合条件驱动 streak
3. 补签
4. 宽限期
5. 历史 streak 迁移逻辑
6. future basis 切换后的兼容策略
7. 更细的 statistics 产品化口径

---

## 6. 两种合法实现路径

你必须根据 C0 / C1 / C2 / C3 结论在以下两条路径中选一条。

---

### Path C4-A（默认保守路径）
适用条件：
- C0 明确写：
  - future streak-basis switch = **NOT PRESENT / candidate only**
- 且 C1 / C2 / C3 没有新增任何 Room 1 已 pin 的 streak-basis contract

此时你必须：

1. 完全按当前 frozen 关系做 truth-boundary hardening
2. 重点清理的是：
   - Today 页面 copy
   - result / settlement copy
   - statistics copy
   - helper / selector / label 命名
3. 确保：
   - “学习天数” = `learning_day`
   - “连签 / 连续签到” = `streak`
   - “今天已签到” = `check_in`
4. 不得把未来方向写成“当前已按学习日连续”

---

### Path C4-B（仅在 C0 / C1 / C2 / C3 明确写可用时）
适用条件：
- C0 / C1 / C2 / C3 明确写：
  - Room 1 已 pin future-basis related clarification
  - 且允许按 active truth 执行

此时你可以：

1. 基于 Room 1 已 pin 的 contract 做最小同步
2. 但仍只能做到“对齐已 pin 真相”，不能额外扩展补签 / 宽限 / 历史迁移
3. 如无 Room 1 明确 pin，不得使用此路径

---

## 7. 这轮 in scope

### 7.1 `check_in / learning_day / streak` 的页面与文案隔离（必须）
请审计并修正至少以下层面：

- Today 页面
- stats summary / entry
- 学习完成结果承接
- 任何显示“连续学习 / 连签 / 学习天数”的地方
- 相关 helper / selector / label 命名

要求：
- 用户不会因为页面表达而误以为：
  - 签到 = 学习日
  - 学习日 = streak 已按学习日延续
  - streak = 学习天数

### 7.2 “学习天数 = learning_day” 的一致性（必须）
如果 C3 已引入 statistics minimal spec，则这轮必须保证：

- learning days count / label / card
- 仅绑定 `learning_day`
- 不借用 `check_in_count`
- 不借用 `streak_count`

### 7.3 Today / result / stats 三处一致性（必须）
你必须保证以下三处不打架：

1. Today 页
2. 学习完成后的承接表达
3. statistics minimal spec

它们不能分别说出三个不同的“今天算不算连续学习 / 学习天数 / streak”的口径。

### 7.4 future stance 只保留为方向（必须）
如果页面或文档中需要提到未来方向，只能写成：
- “未来可能……”
- “后续可评估……”
- “当前仍按签到……”

不能写成：
- “已切到按学习日连续”
- “现在连续学习天数决定 streak”
- “学习天数就是 streak”

### 7.5 命名与 helper 层风险清理（必须）
请检查并修正任何会误导的命名，例如：
- `learningStreak`
- `studyStreakDays`
- `dailyStreak`
- 把 `learning_day` 误叫成 `streak` 的 helper
- 把 `check_in` 误叫成 `learningDay` 的 label

---

## 8. 这轮明确不做什么

### 8.1 不做规则切换
不做：
- `streak_basis_type` 变更
- 补签
- 宽限
- 历史 streak 修复

### 8.2 不做 C5
不进入：
- unified closeout
- 全量 Option C close bar judgment

### 8.3 不新增主结构
不新增：
- endpoint
- DB 主结构
- 主状态机
- 新 contract patch

除非 C0 / C1 / C2 / C3 明确写某个 clarification 已被 pin 且本轮必须消费。

---

## 9. 你必须先读 repo 里什么

### 9.1 C0 / C1 / C2 / C3 产物（必须优先）
- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_Entry_Sync_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C0_v0.1.md`
- `docs/R4_OptionC_C1_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C1_v0.1.md`
- `docs/R4_OptionC_C2_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C2_v0.1.md`
- `docs/R4_OptionC_C3_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C3_v0.1.md`

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

1. Today 页面中签到 / 学习日 / streak 的摘要与标签位置
2. statistics minimal spec 的 summary / card / entry
3. result / settlement / completion copy
4. 相关 helper / selector / mapper / label
5. 当前 `learning_day`、`check_in`、`streak` 的 model / parsing / UI binding
6. 当前相关 widget / integration / regression tests 在哪

---

## 10. C4 你必须明确回答的问题

### Q1. C3 是否真的允许进入 C4
请明确：
- `ready for C4 = YES / NO`
- 依据是什么

### Q2. 你走的是 Path C4-A 还是 C4-B
请明确：
- 走哪条路径
- 为什么
- 依据 C0 / C1 / C2 / C3 的哪条结论

### Q3. `check_in / learning_day / streak` 最终怎么分开的
请明确：
- 哪些页面 / 文案 / helper 改了
- 哪些没有改
- 为什么现在不会再混写

### Q4. future stance 最终怎么处理的
请明确：
- 哪些表达被保留为方向
- 哪些表达被禁止
- 为什么不会被误读成 current fact

### Q5. 这轮如何保证没越界
请明确：
- 没有切换 `streak_basis_type`
- 没有引入补签 / 宽限
- 没有进入 C5
- 没有新增主结构

### Q6. 当前最大的剩余风险是什么
至少明确：
- future-basis switch 仍未 pin 的风险
- 文案层继续回潮混写的风险
- C5 closeout 前仍需统一审计的风险

---

## 11. 这轮允许做什么，不允许做什么

### 允许做的
1. 页面与文案层 truth-boundary 修正
2. helper / selector / label / mapping 修正
3. stats / Today / result 一致性修正
4. truth-boundary 相关 widget / integration / regression tests
5. Room 4 状态文档与 round summary 更新

### 不允许做的
1. 不默认把 candidate input 当 active truth
2. 不切换 `streak_basis_type`
3. 不做补签 / 宽限
4. 不进入 C5
5. 不新增 DB / API 主结构
6. 不跳过 C3 gate

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
如果你只做前端文案 / 展示 / helper / binding 修正，backend 不一定要改。  
若你触碰了聚合读取 / selector / integration / e2e 入口，请至少执行：
```bash
npm test
npm run test:e2e
```

### 12.3 C4 专项验证
至少完成这些验证：

1. `check_in / learning_day / streak` 三类事实在页面层不再混写
2. “学习天数 = learning_day” 保持成立
3. future stance 没被写成 current fact
4. 未 pin 的 future-basis switch 没被偷转成 active truth
5. 没有进入 C5

### 12.4 建议额外覆盖
- learning_day vs check_in vs streak boundary tests
- Today / stats / result 三处一致性 tests
- helper / label / copy regressions
- statistics minimal spec 与 C3 回归联测

---

## 13. 本轮必须产出的文件（硬要求）

### Deliverable A — 状态文件更新
请更新：

```text
docs/R4_OptionC_Status_v0.1.md
```

至少包含：
1. 当前完成到哪个 phase（必须写 C4）
2. 当前走的是 C4-A 还是 C4-B
3. 当前 streak truth-boundary hardening 的落地结果
4. 是否出现 scope creep
5. 当前是否建议进入 C5

### Deliverable B — 测试摘要 / C4 结果
请新增：

```text
docs/R4_OptionC_C4_Result_v0.1.md
```

至少包含：
1. `check_in / learning_day / streak` current mapping
2. path selection（A / B）
3. future stance handling
4. 哪些页面 / helper / copy 被修正
5. 哪些边界仍 pending
6. 当前最大的剩余风险

### Deliverable C — Round summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionC_C4_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **Whether C3 truly allowed C4**
3. **Which path (A or B) was used**
4. **How streak truth-boundary now works**
5. **What truth boundary was kept**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current blockers / assumptions / risks**
11. **Whether ready for C5**

### Optional
如果你发现 C3 并不允许进入 C4，才允许新增：

```text
docs/R4_OptionC_Issue_Note_v0.1.md
```

内容必须写清：
- 为什么当前不能安全进入 C4
- 是哪个 blocker 未解除
- 需要 Room 1 / 上游补什么

---

## 14. 这轮完成标准（严格）

以下全部满足，才算 C4 完成：

1. 已先核对 C3 产物
2. `ready for C4` 已被明确判断
3. `check_in / learning_day / streak` truth-boundary 已落地
4. “学习天数 = learning_day” 已继续守住
5. future stance 未被写成 current fact
6. 未 pin 的 future-basis switch 未被偷转成 active truth
7. 没有进入 C5
8. `docs/R4_OptionC_Status_v0.1.md` 已更新
9. `docs/R4_OptionC_C4_Result_v0.1.md` 已生成
10. `docs/R4_cursor_round_summary_OptionC_C4_v0.1.md` 已生成
11. 最终能明确回答：是否 ready for **C5**

---

## 15. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 **Option C / C4 / Streak truth-boundary hardening**
- 明确说明是否先核过 C3

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 C4 结果
请按这几项写清楚：
1. C3 gate result
2. path used（A / B）
3. mapping result
4. future stance handling
5. truth-boundary
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 若 backend / e2e 被影响：`npm test` / `npm run test:e2e`
- C4 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_C4_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C4_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **C4**
2. 是否 ready for **C5**
3. 当前最大的剩余风险是什么

---

## 16. 最后提醒

这轮不是让你切换 streak 规则，也不是让你偷偷把 future stance 实施掉。

这轮唯一要做好的事情是：

> **在 C3 允许的前提下，把 `check_in / learning_day / streak` 的当前 truth-boundary 收口好。**

不要扩 scope。  
不要偷拍板。  
不要把 candidate input 写成 active truth。  
现在开始执行。
