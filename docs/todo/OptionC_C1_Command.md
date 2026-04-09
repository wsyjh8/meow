# Cursor_OptionC_C1_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是直接推进 C2 / C3 / C4 / C5，也不是补做 C0，而是：

> **在且仅在 C0 已判定 `ready for C1` 的前提下，完成 Option C 的 Phase C1：Today CTA winner。**

---

## 0. 先说清楚：这是一份“带前置门槛”的 C1 指令

这份指令默认前提不是“C0 已经自动通过”，而是：

> **你必须先读取 C0 的产物，并确认 C0 的最终判断是 `ready for C1 = YES`。**

如果你读完 C0 产物后发现：
- C0 还没完成
- C0 明确写了 `ready for C1 = NO`
- 或 C0 发现 Room 1 还未 pin 某个你必须依赖的 active truth

那么你这轮**不得继续实现 C1**，而必须：

1. 停止进入 C1 开发
2. 输出一份简短阻塞说明
3. 明确写出：
   - 哪条 blocker 还没解除
   - 为什么现在不能安全进入 C1

也就是说：

> **C1 是 conditional start，不是 unconditional start。**

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
- C2（Review continuation / minimal review boundary）
- C3（Statistics minimal spec）
- C4（Streak truth-boundary hardening）
- C5（Test & closeout）

你现在只做：

> **C1 — Today CTA winner**

---

## 2. C1 的核心目标

Option C 的 C1 不是“美化 Today”，也不是“把 CTA 做复杂”。

C1 的唯一核心目标是：

> **把 Today 页“用户现在最该做什么”落成一个单一最强主 CTA，并且不靠 UI 自己补脑最终业务事实。**

更具体地说，C1 要解决的是：

1. Today 页任何时刻只能有 **一个最强主 CTA**
2. 若存在 active `review_group`，默认先承接 **继续本组复习**
3. 若不存在 active `review_group`，但后端确认存在待复习 / 高优先复习任务，允许 **先去复习** 高于 **去学新词**
4. Session 在本轮默认作为 **辅助区块 CTA**，而不是 Today 主 winner
5. 若 Room 1 未 pin `today_primary_action` 或等价 decision-support block，则 UI 必须走 **保守路径**，不得自行发明更细算法

一句话：

> **C1 做的是 Today 的 single-strong-CTA 收口，不是完整 CTA 算法毕业。**

---

## 3. 你必须先接受的前提

### 3.1 当前 runtime active baseline（除非 C0 明确写了已变更）
默认你必须先按以下理解工作：

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

### 3.2 你必须以 C0 的结果覆盖默认假设
如果 `docs/R4_OptionC_Entry_Sync_Result_v0.1.md` 明确写了：
- 某些 candidate input 已被 Room 1 接受并可按 active truth 执行
- 或某个 very small clarification 已被 pin

那么你可以按 **C0 明确写出的状态** 工作。

如果 C0 没明确写到，就按保守路径。

### 3.3 Room 4 的执行纪律
你必须服从：

> **未被 Room 1 pin 的内容，不得被实现层偷转成 active truth。**

也就是说：
- 不能因为 repo 里看起来已经有某个 helper / selector / model，就自动当它是正式 winner rule
- 不能因为 UI 稿里有更细表达，就自动把 candidate UI input 当 active runtime UI
- 不能因为 BR v0.1.7 写了更细口径，就自动把 v0.1.7 当 runtime active BR

---

## 4. 这轮你到底要做什么

这轮只做：

1. **先读 C0 产物**
   - `docs/R4_OptionC_Status_v0.1.md`
   - `docs/R4_OptionC_Entry_Sync_Result_v0.1.md`
   - `docs/R4_cursor_round_summary_OptionC_C0_v0.1.md`
2. 判断是否 **ready for C1**
3. 如果 ready：
   - 落 Today 的 **single-strong-CTA**
   - 把 active `review_group` continuation-first 做稳
   - 把复习优先于新词的最小仲裁表达做稳
   - 把 Session 放在辅助区，不与主 CTA 争位
   - 做对应前端 / 页面 / 状态测试
   - 输出 C1 状态 / 测试摘要 / round summary
4. 如果 not ready：
   - 不实现 C1
   - 输出阻塞说明并停止

这轮**不做**：
- 不进入 C2
- 不进入 C3
- 不进入 C4
- 不进入 C5
- 不实现完整 CTA 优先级算法
- 不默认引入 `today_primary_action`
- 不改 review_group 完整算法
- 不做 statistics
- 不切换 streak 口径
- 不新增 endpoint / 主结构 / 状态机

---

## 5. C1 的正确实现边界

### 5.1 Frozen 层（当前必须服从）
以下是你这轮可以直接服从的最小边界：

1. Today 页任何时刻只能有 **一个最强主 CTA**
2. 若存在 active `review_group`：
   - 主 CTA 默认优先为 **`继续本组复习`**
3. 若不存在 active `review_group`，但后端确认存在待复习 / 高优先复习任务：
   - 主 CTA 可为 **`先去复习`**
4. 若上述两者都不成立，且仍有新词任务：
   - 主 CTA 可为 **`开始新词学习` / `继续新词学习`**
5. Session 在本轮默认只作为 **辅助区块 CTA**
6. UI 不得仅凭：
   - 本地计数
   - 页面进入状态
   - 按钮点击
   - 临时 UI 状态
   自行推断最终业务 winner

### 5.2 继续 Pending 的层（这轮不能偷实现）
以下内容本轮继续属于 pending，不得自己补全为“正式算法”：

1. `go_review` 与 `go_new_words` 的详细评分算法
2. `session_pending` 是否进入统一 CTA 仲裁
3. `reason` 枚举全集
4. 完整 loading / error / fallback 下的细 CTA 文案策略
5. `today_primary_action` 是否成为正式 active contract（除非 C0 明确写已 pin）

---

## 6. 两种合法实现路径

你必须根据 C0 结论在以下两条路径中选一条。

---

### Path C1-A（默认保守路径）
适用条件：
- C0 没明确写 `today_primary_action` 或等价 decision-support block 已进入 active truth
- 或 C0 明确写它仍是 candidate only / not present

此时你必须：

1. 仅基于当前 runtime active baseline 已稳定存在的聚合结果落地
2. 采用保守 winner 规则：
   - active `review_group` → `继续本组复习`
   - 无 active group 且存在后端确认待复习 / 高优先复习任务 → `先去复习`
   - 否则 → `开始新词学习 / 继续新词学习`
3. 不自行发明新的中间 decision-support 结构
4. 不把 UI 写成好像后端已经返回 `today_primary_action`

---

### Path C1-B（仅在 C0 明确写可用时）
适用条件：
- C0 明确写：
  - `today_primary_action`（或等价 decision-support / CTA support block）
  - 已被 Room 1 接受 / 已可按 active truth 执行

此时你可以：

1. 基于后端返回的 decision-support / reason block 驱动 CTA
2. UI 只消费，不自己拼 winner
3. 但仍不能把 pending 的完整 CTA 算法写死成“已经最终毕业”

---

## 7. 这轮 in scope

### 7.1 Today 主 CTA 结构（必须）
请检查并最小改动 Today 页主任务区，使它满足：

1. 一个最强主 CTA
2. 文案不冲突
3. 层级清楚
4. Session 不抢主位
5. 辅助状态不会和主 CTA 打架

### 7.2 active `review_group` continuation-first（必须）
只要当前 active truth 下已经能确认存在 active `review_group`，就必须优先承接：

> **继续本组复习**

并且不得在同层再放一个等强的“开始新词学习”。

### 7.3 review-over-new 的最小落地（必须）
当没有 active group，但后端已确认存在待复习 / 高优先复习任务时，Today 应优先表达：

> **先去复习**

前提是：
- 这条判断必须建立在后端已确认的聚合事实上
- 不能由 UI 用本地 remaining count 自己拍板

### 7.4 Session 退回辅助层（必须）
Session 在本轮默认只做：
- Session 摘要
- Session 辅助 CTA
- Session 状态展示

但不能：
- 与主 CTA 并列争夺 winner
- 被表达成“今天最该做的第一动作”除非后续规则另行 pin

### 7.5 fallback / empty / loading / error（必须）
至少要考虑：

1. Today 数据 loading
2. Today 数据局部缺失
3. active group 不存在
4. 待复习为空
5. Session 状态缺失
6. 出错时如何不误导 winner

但注意：
- 你这轮只做到 **实现稳定 + 测试可断言**
- 不需要把所有 copy polish 到最终版

---

## 8. 这轮明确不做什么

### 8.1 不做完整 CTA 算法系统
不做：
- 复杂评分
- 多维优先级计算器
- 多种 reason 文案池
- 全量 CTA 状态机毕业版

### 8.2 不做 C2
不进入：
- `review_group` readiness summary contract
- `next group readiness`
- review priority 深化
- 完整 SRS

### 8.3 不做 C3 / C4 / C5
不进入：
- statistics minimal spec
- streak truth-boundary hardening
- unified closeout

### 8.4 不新增主结构
不新增：
- endpoint
- DB 主结构
- 主状态机
- 新 contract patch

除非 C0 明确写某个 clarification 已被 pin 且本轮必须消费。

---

## 9. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 9.1 C0 产物（必须优先）
- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_Entry_Sync_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C0_v0.1.md`

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

1. Today 页当前 widget / page / section 结构
2. 当前主 CTA 在哪里决定
3. 当前 `review_group` continuation 线索从哪里来
4. 当前待复习 / 今日任务聚合从哪里读
5. Session 区块当前在哪里
6. 当前有无 `today_primary_action` / decision-support block / selector / helper
7. 当前 Today 相关 widget / integration / regression tests 在哪

---

## 10. C1 你必须明确回答的问题

### Q1. C0 是否真的允许进入 C1
请明确：
- `ready for C1 = YES / NO`
- 依据是什么

### Q2. 你走的是 Path C1-A 还是 C1-B
请明确：
- 走哪条路径
- 为什么
- 依据 C0 的哪条结论

### Q3. Today 的主 CTA 最终怎么落的
请明确：
- 当前主 CTA 决定在哪
- 什么时候显示 `继续本组复习`
- 什么时候显示 `先去复习`
- 什么时候显示 `开始新词学习 / 继续新词学习`

### Q4. 你如何证明只有一个最强主 CTA
请明确：
- Session 如何退回辅助区
- 新词 / 复习 / Session 如何避免并列 winner
- 页面层级是否有变化

### Q5. 这轮如何保证没越界
请明确：
- 没有偷实现完整 CTA 算法
- 没有默认引入未 pin 的 `today_primary_action`
- 没有进入 C2 / C3 / C4 / C5
- 没有新增主结构

### Q6. 当前最大的剩余风险是什么
至少明确：
- candidate vs active truth 误读风险
- review summary clarification 未 pin 的保守路径风险
- CTA fallback copy 仍不够最终化的风险

---

## 11. 这轮允许做什么，不允许做什么

### 允许做的
1. Today 页 CTA 逻辑与页面表达最小落地
2. Session 降为辅助区的页面调整
3. Today 相关 state mapping / selector / helper 最小修正
4. Today 相关 widget / integration / regression tests
5. Room 4 状态文档与 round summary 更新

### 不允许做的
1. 不默认把 candidate input 当 active truth
2. 不实现完整 CTA 算法
3. 不进入 review continuation 深逻辑
4. 不进入 statistics
5. 不进入 streak truth-boundary hardening
6. 不新增 DB / API 主结构
7. 不跳过 C0 结论

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
如果你只做前端 Today 页面与映射层，backend 不一定要改。  
若你触碰了 today 聚合消费 / selector / integration / e2e 入口，请至少执行：
```bash
npm test
npm run test:e2e
```

### 12.3 C1 专项验证
至少完成这些验证：

1. Today 始终只有一个最强主 CTA
2. active `review_group` → `继续本组复习`
3. 无 active group 且后端确认待复习 / 高优先复习任务 → `先去复习`
4. 其它情况 → 新词 CTA
5. Session 不抢主位
6. fallback / loading / missing-data 时不误导 winner
7. 未 pin 的 candidate contract 没被偷转成 active truth

### 12.4 建议额外覆盖
- Today widget tests
- CTA state matrix tests
- loading / partial data / error tests
- active group / no active group / review-needed / no-review-needed 四类分支

---

## 13. 本轮必须产出的文件（硬要求）

### Deliverable A — 状态文件更新
请更新：

```text
docs/R4_OptionC_Status_v0.1.md
```

至少包含：
1. 当前完成到哪个 phase（必须写 C1）
2. 当前走的是 C1-A 还是 C1-B
3. 当前 CTA winner 的最小落地结果
4. 是否出现 scope creep
5. 当前是否建议进入 C2

### Deliverable B — 测试摘要 / C1 结果
请新增：

```text
docs/R4_OptionC_C1_Result_v0.1.md
```

至少包含：
1. Today CTA current mapping
2. path selection（A / B）
3. fallback / loading / empty / error handling
4. Session 如何退回辅助区
5. 哪些边界仍 pending
6. 当前最大的剩余风险

### Deliverable C — Round summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionC_C1_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **Whether C0 truly allowed C1**
3. **Which path (A or B) was used**
4. **How Today CTA winner now works**
5. **What truth boundary was kept**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current blockers / assumptions / risks**
11. **Whether ready for C2**

### Optional
如果你发现 C0 并不允许进入 C1，才允许新增：

```text
docs/R4_OptionC_Issue_Note_v0.1.md
```

内容必须写清：
- 为什么当前不能安全进入 C1
- 是哪个 blocker 未解除
- 需要 Room 1 / 上游补什么

---

## 14. 这轮完成标准（严格）

以下全部满足，才算 C1 完成：

1. 已先核对 C0 产物
2. `ready for C1` 已被明确判断
3. Today 的 single-strong-CTA 已落地
4. active `review_group` continuation-first 已落地
5. Session 已退回辅助区
6. 未 pin 的 contract clarification 未被偷转成 active truth
7. 没有进入 C2 / C3 / C4 / C5
8. `docs/R4_OptionC_Status_v0.1.md` 已更新
9. `docs/R4_OptionC_C1_Result_v0.1.md` 已生成
10. `docs/R4_cursor_round_summary_OptionC_C1_v0.1.md` 已生成
11. 最终能明确回答：是否 ready for **C2**

---

## 15. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 **Option C / C1 / Today CTA winner**
- 明确说明是否先核过 C0

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 C1 结果
请按这几项写清楚：
1. C0 gate result
2. path used（A / B）
3. CTA mapping
4. Session placement
5. truth-boundary
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 若 backend / e2e 被影响：`npm test` / `npm run test:e2e`
- C1 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_C1_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C1_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **C1**
2. 是否 ready for **C2**
3. 当前最大的剩余风险是什么

---

## 16. 最后提醒

这轮不是让你毕业 Option C，也不是让你偷偷补完 review continuation / statistics / streak。

这轮唯一要做好的事情是：

> **在 C0 允许的前提下，把 Today 的 single-strong-CTA 收口好。**

不要扩 scope。  
不要偷拍板。  
不要把 candidate input 写成 active truth。  
现在开始执行。
