# Cursor_OptionC_C2_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是直接推进 C3 / C4 / C5，也不是补做 C0 / C1，而是：

> **在且仅在 C1 已判定 `ready for C2` 的前提下，完成 Option C 的 Phase C2：Review continuation / minimal review boundary。**

---

## 0. 先说清楚：这是一份“带前置门槛”的 C2 指令

这份指令默认前提不是“C1 已经自动通过”，而是：

> **你必须先读取 C1 的产物，并确认 C1 的最终判断是 `ready for C2 = YES`。**

如果你读完 C1 产物后发现：
- C1 还没完成
- C1 明确写了 `ready for C2 = NO`
- 或 C1 发现当前 active truth 还不足以安全进入 review continuation 落地

那么你这轮**不得继续实现 C2**，而必须：

1. 停止进入 C2 开发
2. 输出一份简短阻塞说明
3. 明确写出：
   - 哪条 blocker 还没解除
   - 为什么现在不能安全进入 C2

也就是说：

> **C2 是 conditional start，不是 unconditional start。**

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
- C3（Statistics minimal spec）
- C4（Streak truth-boundary hardening）
- C5（Test & closeout）

你现在只做：

> **C2 — Review continuation / minimal review boundary**

---

## 2. C2 的核心目标

C2 不是做完整 SRS，也不是做 review algorithm 毕业版。

C2 的唯一核心目标是：

> **把 `review_group` 的 continuation / readiness / minimal review boundary 做稳，避免 Today / Review / 结算层继续各自补脑。**

更具体地说，C2 要解决的是：

1. active `review_group` continuation-first 的具体实现
2. `本组完成 ≠ 今日复习完成`
3. `next group readiness` 不得由 UI 用 local remaining count 自己拍板
4. review priority 只收到 **主因子层**，不进入完整评分引擎
5. Today / Review / 结果承接层在 review 语义上保持一致

一句话：

> **C2 做的是最小 review continuation 边界收口，不是完整复习系统升级。**

---

## 3. 你必须先接受的前提

### 3.1 先读 C1 产物（必须）
你必须先读取：

- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_C1_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C1_v0.1.md`

并明确确认：

> **C1 的最终判断是 `ready for C2 = YES`。**

### 3.2 默认仍按当前 runtime active baseline 工作
除非 C1 或 C0 的正式产物明确写了已有新 pin，否则你默认仍必须按：

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

- Room 2 提到的 review / group summary clarification
- `next group readiness` 更稳的聚合 block
- 更细 review priority / algorithm 结构

如果 C0 没明确写这些已进入 active truth，就按保守路径。

---

## 4. 这轮你到底要做什么

这轮只做：

1. **先读 C1 产物**
2. 判断是否 **ready for C2**
3. 如果 ready：
   - 做 active `review_group` continuation-first 的最小实现
   - 做 `本组完成 ≠ 今日复习完成` 的状态分离
   - 做 `next group readiness` 的保守路径承接
   - 做 review priority 的最小主因子层表达
   - 补 Today / Review / 结果承接层的一致性测试
   - 输出 C2 状态 / 结果 / round summary
4. 如果 not ready：
   - 不实现 C2
   - 输出阻塞说明并停止

这轮**不做**：
- 不进入 C3
- 不进入 C4
- 不进入 C5
- 不做完整 SRS
- 不做 group size / interval / 详细权重引擎
- 不默认引入 review/group summary clarification
- 不新增 endpoint / 主结构 / 状态机

---

## 5. C2 的正确实现边界

### 5.1 Frozen 层（当前必须服从）
以下是你这轮可以直接服从的最小边界：

1. `review_group` 是后端生成、后端持有的一次有限复习批次对象
2. 同一用户同一时刻只允许一个 active `review_group`
3. active `review_group` continuation-first 成立
4. `本组完成` 只推进今日复习进度，**不自动等于** `今日复习完成`
5. 同组不得重复完成、重复结算、重复发奖
6. Today / Review / 结果承接层不得各自发明 review completion 语义

### 5.2 继续 Pending 的层（这轮不能偷实现）
以下内容本轮继续属于 pending，不得自己补全为“正式算法”：

1. 完整 SRS
2. group size / interval / 详细 priority 权重
3. 完整 review scheduling / mastery progression
4. 更细 review/group summary contract（除非 C0 明确写已 pin）
5. 复杂 next-group readiness 算法

---

## 6. 两种合法实现路径

你必须根据 C0 / C1 结论在以下两条路径中选一条。

---

### Path C2-A（默认保守路径）
适用条件：
- C0 明确写：
  - review / group summary clarification = **NOT PRESENT**
- 或 C1 没有新增任何 Room 1 已 pin 的 review summary block

此时你必须：

1. 仅基于当前 active `review_group` 最小合同落地
2. UI / 实现不凭 local remaining count 自行推 `next group readiness`
3. 若后端当前只给到“active group 是否存在 / 当前组是否完成 / 今日复习进度”，就只按这层实现
4. 保持最小表达：
   - 有 active group → continuation
   - 本组完成 → 只说明本组结束 / 今日复习进度推进
   - 不直接宣称“今日复习完成”，除非后端的 `daily_goal_status` / review completion 已明确确认

---

### Path C2-B（仅在 C0 / C1 明确写可用时）
适用条件：
- C0 或 C1 明确写：
  - review / group summary clarification
  - 已被 Room 1 接受 / 已可按 active truth 执行

此时你可以：

1. 基于后端明确返回的 continuation / progress / readiness summary 做更稳实现
2. UI 只消费，不自己补 readiness
3. 但仍不能把 pending 的完整 SRS / full review algorithm 写成“已经毕业”

---

## 7. 这轮 in scope

### 7.1 active `review_group` continuation-first（必须）
请把 active `review_group` 的 continuation-first 做稳：

- Today 已有的 CTA winner 继续服从 C1
- 进入 review flow 后，应能正确继续当前组
- 不允许 UI 看见一点 local state 就新开组 / 推断 readiness

### 7.2 `本组完成 ≠ 今日复习完成`（必须）
你必须把这条做成明确的实现与页面表达边界：

- 本组完成：
  - 只说明当前组完成
  - 只推进今日复习进度
- 今日复习完成：
  - 只有在后端确认今日复习整体满足时才可表达

不能出现：
- 当前组一完就直接写“今日复习完成”
- 结果层和 Today 层对同一状态说法不一致

### 7.3 `next group readiness` 的保守承接（必须）
如果当前没有被 Room 1 pin 的 readiness summary contract，你必须：

- 不由前端用 local remaining count 自行判断“下一组现在可开”
- 不自己补出一个“推荐下一组”真相
- 可以保守表达为：
  - 当前组已完成
  - 今日复习进度已更新
  - 是否还有后续复习内容，以当前后端聚合为准

### 7.4 review priority 只做到主因子层（必须）
如果当前 UI / helper / state 需要表达“优先复习”：

- 只能停留在主因子层
- 不进入详细分数算法 / 多权重引擎 / 完整排序毕业版

### 7.5 Today / Review / 结果承接层一致性（必须）
你必须保证：
- Today CTA
- Review 页面 / review completion
- 当前组完成后的承接表达

三处不打架。

---

## 8. 这轮明确不做什么

### 8.1 不做完整 SRS / review engine
不做：
- 复杂调度
- mastery threshold 完整算法
- 详细 due score / interval / queue rebuild 引擎

### 8.2 不做 C3 / C4 / C5
不进入：
- statistics
- streak truth-boundary hardening
- unified closeout

### 8.3 不新增主结构
不新增：
- endpoint
- DB 主结构
- 主状态机
- 新 contract patch

除非 C0 / C1 明确写某个 clarification 已被 pin 且本轮必须消费。

---

## 9. 你必须先读 repo 里什么

### 9.1 C0 / C1 产物（必须优先）
- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_Entry_Sync_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C0_v0.1.md`
- `docs/R4_OptionC_C1_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C1_v0.1.md`

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

1. Review flow 当前入口
2. `review_group` 当前模型 / state / selector / DTO / parsing
3. Today 当前如何识别 active `review_group`
4. Review 完成后当前如何更新 Today / progress
5. 当前是否存在 readiness summary / next-group helper
6. 当前 result / completion / settlement 层如何表达 review completion
7. 当前 Today / Review / result 相关测试入口

---

## 10. C2 你必须明确回答的问题

### Q1. C1 是否真的允许进入 C2
请明确：
- `ready for C2 = YES / NO`
- 依据是什么

### Q2. 你走的是 Path C2-A 还是 C2-B
请明确：
- 走哪条路径
- 为什么
- 依据 C0 / C1 的哪条结论

### Q3. active `review_group` continuation 最终怎么落的
请明确：
- Today 如何继续承接
- Review flow 如何继续当前组
- 有没有避免 UI 自己私判 readiness

### Q4. `本组完成 ≠ 今日复习完成` 最终怎么守住的
请明确：
- 哪些页面 / 状态 / 文案改了
- 哪些没有改
- 为什么不会再混写

### Q5. 这轮如何保证没越界
请明确：
- 没有偷实现完整 SRS
- 没有默认引入未 pin 的 review summary clarification
- 没有进入 C3 / C4 / C5
- 没有新增主结构

### Q6. 当前最大的剩余风险是什么
至少明确：
- review summary clarification 未 pin 的保守路径风险
- `next group readiness` 仍不能由 UI 自己推断的风险
- review priority 仍只停留主因子层的风险

---

## 11. 这轮允许做什么，不允许做什么

### 允许做的
1. Review continuation 的最小实现
2. `本组完成 ≠ 今日复习完成` 的状态 / 文案 / 表达分离
3. Today / Review / 结果承接层一致性修正
4. review 相关 widget / integration / regression tests
5. Room 4 状态文档与 round summary 更新

### 不允许做的
1. 不默认把 candidate input 当 active truth
2. 不实现完整 SRS / 完整 priority engine
3. 不进入 statistics
4. 不进入 streak truth-boundary hardening
5. 不新增 DB / API 主结构
6. 不跳过 C1 gate

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
如果你只做前端 review flow / today result mapping，backend 不一定要改。  
若你触碰了 review flow integration / e2e 入口，请至少执行：
```bash
npm test
npm run test:e2e
```

### 12.3 C2 专项验证
至少完成这些验证：

1. active `review_group` continuation-first 成立
2. `本组完成 ≠ 今日复习完成`
3. Today / Review / 结果承接层语义一致
4. `next group readiness` 未由 UI 私判
5. 未 pin 的 review summary clarification 没被偷转成 active truth
6. 没有进入 C3 / C4 / C5

### 12.4 建议额外覆盖
- Review continuation tests
- group completion vs daily review completion tests
- next-group readiness boundary tests
- Today / Review / result 三处一致性 tests

---

## 13. 本轮必须产出的文件（硬要求）

### Deliverable A — 状态文件更新
请更新：

```text
docs/R4_OptionC_Status_v0.1.md
```

至少包含：
1. 当前完成到哪个 phase（必须写 C2）
2. 当前走的是 C2-A 还是 C2-B
3. 当前 review continuation 的最小落地结果
4. 是否出现 scope creep
5. 当前是否建议进入 C3

### Deliverable B — 测试摘要 / C2 结果
请新增：

```text
docs/R4_OptionC_C2_Result_v0.1.md
```

至少包含：
1. Review continuation current mapping
2. path selection（A / B）
3. `本组完成 ≠ 今日复习完成` 的落地结果
4. readiness handling
5. 哪些边界仍 pending
6. 当前最大的剩余风险

### Deliverable C — Round summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionC_C2_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **Whether C1 truly allowed C2**
3. **Which path (A or B) was used**
4. **How review continuation now works**
5. **What truth boundary was kept**
6. **What is still not done**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current blockers / assumptions / risks**
11. **Whether ready for C3**

### Optional
如果你发现 C1 并不允许进入 C2，才允许新增：

```text
docs/R4_OptionC_Issue_Note_v0.1.md
```

内容必须写清：
- 为什么当前不能安全进入 C2
- 是哪个 blocker 未解除
- 需要 Room 1 / 上游补什么

---

## 14. 这轮完成标准（严格）

以下全部满足，才算 C2 完成：

1. 已先核对 C1 产物
2. `ready for C2` 已被明确判断
3. active `review_group` continuation-first 已落地
4. `本组完成 ≠ 今日复习完成` 已落地
5. Today / Review / 结果承接层语义一致
6. 未 pin 的 review summary clarification 未被偷转成 active truth
7. 没有进入 C3 / C4 / C5
8. `docs/R4_OptionC_Status_v0.1.md` 已更新
9. `docs/R4_OptionC_C2_Result_v0.1.md` 已生成
10. `docs/R4_cursor_round_summary_OptionC_C2_v0.1.md` 已生成
11. 最终能明确回答：是否 ready for **C3**

---

## 15. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 **Option C / C2 / Review continuation / minimal review boundary**
- 明确说明是否先核过 C1

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 C2 结果
请按这几项写清楚：
1. C1 gate result
2. path used（A / B）
3. review continuation mapping
4. group-vs-daily boundary
5. truth-boundary
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- 若 backend / e2e 被影响：`npm test` / `npm run test:e2e`
- C2 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_C2_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C2_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **C2**
2. 是否 ready for **C3**
3. 当前最大的剩余风险是什么

---

## 16. 最后提醒

这轮不是让你毕业 review system，也不是让你偷偷补完 statistics / streak。

这轮唯一要做好的事情是：

> **在 C1 允许的前提下，把 review continuation 的最小边界收口好。**

不要扩 scope。  
不要偷拍板。  
不要把 candidate input 写成 active truth。  
现在开始执行。
