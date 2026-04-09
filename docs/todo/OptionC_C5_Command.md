# Cursor_OptionC_C5_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是补做 C0 / C1 / C2 / C3 / C4，也不是顺手再加新功能，而是：

> **在且仅在 C4 已判定 `ready for C5` 的前提下，完成 Option C 的 Phase C5：Test & closeout。**

---

## 0. 先说清楚：这是一份“带前置门槛”的 C5 指令

这份指令默认前提不是“C4 已经自动通过”，而是：

> **你必须先读取 C4 的产物，并确认 C4 的最终判断是 `ready for C5 = YES`。**

如果你读完 C4 产物后发现：
- C4 还没完成
- C4 明确写了 `ready for C5 = NO`
- 或 C4 发现当前 active truth 还不足以安全进入 Option C closeout

那么你这轮**不得继续执行 C5**，而必须：

1. 停止进入 C5 closeout
2. 输出一份简短阻塞说明
3. 明确写出：
   - 哪条 blocker 还没解除
   - 为什么现在不能安全进入 C5

也就是说：

> **C5 是 conditional start，不是 unconditional start。**

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
- C4（Streak truth-boundary hardening）

你现在只做：

> **C5 — Test & closeout**

---

## 2. C5 的核心目标

C5 不是再写功能，也不是再扩规则，更不是把 future candidate 顺手塞进当前轮。

C5 的唯一核心目标是：

> **把 Option C 从“分段实现已完成”推进到“Room 1 可以直接做 close judgment”的状态。**

更具体地说，C5 要解决的是：

1. 统一回归验证 C1 / C2 / C3 / C4
2. 对照 Room 4 的 Option C close bar 逐项判断
3. 明确哪些 truth-boundary 已守住
4. 明确哪些风险仍然存在但不阻塞 close
5. 明确哪些 candidate input 仍未进入、且本轮没有偷实现
6. 输出一套可直接给 Room 1 的 closeout 包

一句话：

> **C5 做的是统一回归 + close judgment，不是新功能轮。**

---

## 3. 你必须先接受的前提

### 3.1 先读 C4 产物（必须）
你必须先读取：

- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_C4_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C4_v0.1.md`

并明确确认：

> **C4 的最终判断是 `ready for C5 = YES`。**

### 3.2 默认仍按当前 runtime active baseline 工作
除非 C0 / C1 / C2 / C3 / C4 的正式产物明确写了已有新 pin，否则你默认仍必须按：

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

所以 C5 必须显式核查：
- 没有把 `BR-OPP-001_v0.1.7.md` 当 runtime active BR
- 没有把 `UI_SPEC_OptionC_MainMechanism_v0.1.1.md` 当 runtime active UI baseline
- 没有把未 pin 的 very small clarifications 当既成事实
- 没有在 closeout 里偷偷“顺带毕业” future stance

---

## 4. 这轮你到底要做什么

这轮只做：

1. **先读 C4 产物**
2. 判断是否 **ready for C5**
3. 如果 ready：
   - 统一回归 C1 / C2 / C3 / C4
   - 对照 Option C close bar 逐项判断
   - 核查 candidate vs active truth 边界
   - 统一整理测试结果 / 风险 / blockers / non-blocking issues
   - 生成 Room 1 可直接消费的 closeout 包
4. 如果 not ready：
   - 不执行 C5 closeout
   - 输出阻塞说明并停止

这轮**不做**：
- 不新增功能
- 不重写 CTA / review / stats / streak 规则
- 不新增 contract patch
- 不切 `streak_basis_type`
- 不推进新的 Option C+ 子阶段
- 不做“顺手优化”

---

## 5. C5 的正确 close bar

你必须严格对照以下 close bar 做判断。

### CB-OC-001 Today CTA winner 已收口
必须满足：
1. Today 任何时刻只有一个最强主 CTA
2. active `review_group` continuation-first 成立
3. Session 已退回辅助区
4. 未 pin 的 `today_primary_action` / decision-support 没被偷转成 active truth

### CB-OC-002 Review continuation 最小边界已收口
必须满足：
1. active `review_group` continuation-first 已落地
2. `本组完成 ≠ 今日复习完成`
3. Today / Review / 结果承接层语义一致
4. 未 pin 的 review summary clarification 没被偷转成 active truth
5. 未实现完整 SRS / priority engine

### CB-OC-003 Statistics minimal spec 已收口
必须满足：
1. statistics 只做到 summary-first / minimal summary
2. “学习天数 = learning_day”
3. `check_in / streak` 未混写成学习天数
4. 未 pin 独立统计页时，没有偷偷扩成完整 stats page

### CB-OC-004 Streak truth-boundary 已收口
必须满足：
1. `check_in / learning_day / streak` 三类事实不混写
2. 当前 `streak_basis_type = check_in` 仍被守住
3. future stance 没被写成 current fact
4. 未引入补签 / 宽限 / basis 切换

### CB-OC-005 Candidate vs active truth 边界未被破坏
必须满足：
1. `BR-OPP-001_v0.1.7.md` 未被偷当 active BR
2. `UI_SPEC_OptionC_MainMechanism_v0.1.1.md` 未被偷当 active UI baseline
3. 未 pin 的 very small clarification 未被实现层偷转成 active truth
4. closeout 不得依赖 Room 1 尚未 pin 的未来口径

### CB-OC-006 最小回归集通过
至少要能证明：
1. C1–C4 新增 / 修改功能都可跑
2. 主学习链路未被打坏
3. 已完成的 B 系列 visible behavior 未被误伤
4. 没有新增 blocker / major bug

---

## 6. 这轮 in scope

### 6.1 统一回归 C1–C4（必须）
请对以下范围做统一回归：

#### C1
- Today single-strong-CTA
- Session 不抢主位
- conservative path 不越界

#### C2
- active `review_group` continuation
- group completion vs daily completion
- Review / Today / result 一致性

#### C3
- statistics summary-first
- learning_day count
- no independent stats page unless pinned

#### C4
- check_in / learning_day / streak truth-boundary
- future stance not implemented as current fact

### 6.2 统一风险盘点（必须）
请把风险分类成：

- Hard blocker
- Major
- Minor
- Assumption (temporary, not frozen)
- Non-blocking issue

不要只写一个模糊“有风险”。

### 6.3 统一 close recommendation（必须）
你必须明确给出：

- **Room 4 是否建议 Room 1 close Option C**
- 如果建议 close：
  - 最核心理由是什么
- 如果不建议 close：
  - 哪些 blocker 还没解除

---

## 7. 这轮明确不做什么

### 7.1 不再改功能
除非发现：
- blocker
- major bug
- close bar 未达标的明显缺口

否则这轮不再继续加新功能。

### 7.2 不顺手扩大范围
不做：
- 完整 stats page
- 完整 SRS
- streak future basis 切换
- 补签 / 宽限
- additional contract clarification
- 新的 UI polish round

### 7.3 不替 Room 1 pin active versions
你只能做 close recommendation，不能替 Room 1 宣布：
- “那现在 v0.1.7 / Option C UI 就算 active 了”

---

## 8. 你必须先读 repo 里什么

### 8.1 C0–C4 产物（必须优先）
- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_Entry_Sync_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C0_v0.1.md`
- `docs/R4_OptionC_C1_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C1_v0.1.md`
- `docs/R4_OptionC_C2_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C2_v0.1.md`
- `docs/R4_OptionC_C3_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C3_v0.1.md`
- `docs/R4_OptionC_C4_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C4_v0.1.md`

### 8.2 Option C 输入
- `R1_OptionC_Formal_Handoff_Pack_v0.1.md`
- `R2_OptionC_MainMechanism_Preflight_v0.1.1.md`
- `BR-OPP-001_v0.1.7.md`
- `UI_SPEC_OptionC_MainMechanism_v0.1.1.md`
- `R4_OptionC_Preflight_Implementation_Plan_v0.1.1.md`
- `optionc_phases.md`

### 8.3 当前 runtime active baseline
- `Main_updated_2026-04-05_v13.md`
- `STATUS_updated_2026-04-05_v12.md`
- `BR-OPP-001_v0.1.5.md`
- `背单词喵喵app_DB设计草案_v0.1.4.md`
- `背单词喵喵app_API设计草案_v0.1.3.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `UI_SPEC_v0.1.4.md`
- `plan_v0.1.2.md`
- `TEST_PLAN_v0.1.2.md`

### 8.4 代码层必须盘点的位置
至少检查：

1. Today CTA 相关实现与 tests
2. Review continuation 相关实现与 tests
3. stats summary / card / entry 相关实现与 tests
4. check_in / learning_day / streak 相关 helper / selector / copy / tests
5. 任何在 C1–C4 中新增的 DTO / response field / parser
6. 当前 e2e / widget / integration 回归入口

---

## 9. C5 你必须明确回答的问题

### Q1. C4 是否真的允许进入 C5
请明确：
- `ready for C5 = YES / NO`
- 依据是什么

### Q2. Option C 的 close bar 是否全部满足
请逐条回答：
- CB-OC-001 到 CB-OC-006
- 哪些满足
- 哪些仍有 gap
- gap 是 blocker 还是 non-blocking

### Q3. 当前最大的剩余风险是什么
至少明确：
- candidate vs active truth 风险
- future stance 回潮为 current fact 的风险
- stats / copy / helper 再次混写的风险

### Q4. 是否建议 Room 1 close Option C
请明确：
- YES / NO
- 理由
- 若 NO，列 blocker

### Q5. 当前是否需要 issue note
请明确：
- 是否需要 `docs/R4_OptionC_Issue_Note_v0.1.md`
- 为什么
- 如果不需要，也要明确说明原因

---

## 10. 这轮允许做什么，不允许做什么

### 允许做的
1. 统一回归
2. 统一 close bar 判断
3. 发现 blocker / major bug 时做 very small fix
4. 更新状态 / 测试摘要 / closeout summary
5. 形成 Room 1 可直接消费的 close recommendation

### 不允许做的
1. 不加新功能
2. 不扩规则
3. 不新增 contract patch
4. 不默认把 candidate input 当 active truth
5. 不替 Room 1 pin active versions

---

## 11. 这轮最小测试 / 验证要求

### 11.1 Flutter / front-end
至少执行：
```bash
flutter pub get
flutter test
flutter analyze
```

如果 repo 真实命令不同，请按真实命令执行，并在回传中更正。

### 11.2 Node / backend
如 C1–C4 中任何后端 / parser / e2e surface 被触碰或需要统一回归，请至少执行：
```bash
npm test
npm run test:e2e
```

### 11.3 C5 专项验证
至少完成这些验证：

1. C1–C4 新增行为都能跑
2. close bar 可逐项判断
3. 未 pin 的 candidate 未被偷实现成 active truth
4. 主机制主链路未回退
5. 已完成的 secondary visible behavior 未被误伤

---

## 12. 本轮必须产出的文件（硬要求）

### Deliverable A — 状态文件更新
请更新：

```text
docs/R4_OptionC_Status_v0.1.md
```

至少包含：
1. 当前完成到哪个 phase（必须写 C5）
2. 当前 close bar 总判断
3. 当前是否建议 Room 1 close Option C
4. 是否出现 scope creep
5. 当前是否仍有 blocker

### Deliverable B — 测试摘要
请新增：

```text
docs/R4_OptionC_Test_Summary_v0.1.md
```

至少包含：
1. C1–C4 覆盖范围
2. 统一测试结果
3. close bar 相关关键验证
4. blocker / major / minor 分类
5. 当前最大的剩余风险

### Deliverable C — Closeout summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionC_C5_v0.1.md
```

这份总结必须写给“Room 1 / 下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **Whether C4 truly allowed C5**
3. **How each close bar item evaluated**
4. **What truth boundary was kept**
5. **What is still not done**
6. **What not to touch**
7. **Current blockers / assumptions / risks**
8. **Whether Room 1 should close Option C**

### Optional
如果确有必要，才允许新增：

```text
docs/R4_OptionC_Issue_Note_v0.1.md
```

只有在你确认：
- close bar 有未过项
- 或存在 Room 1 必须先处理的 blocker / major issue
时才交。

---

## 13. 这轮完成标准（严格）

以下全部满足，才算 C5 完成：

1. 已先核对 C4 产物
2. `ready for C5` 已被明确判断
3. C1–C4 已统一回归
4. close bar 已逐项判断
5. `docs/R4_OptionC_Status_v0.1.md` 已更新
6. `docs/R4_OptionC_Test_Summary_v0.1.md` 已生成
7. `docs/R4_cursor_round_summary_OptionC_C5_v0.1.md` 已生成
8. 最终能明确回答：是否建议 **Room 1 close Option C**

---

## 14. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 **Option C / C5 / Test & closeout**
- 明确说明是否先核过 C4

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 C5 结果
请按这几项写清楚：
1. C4 gate result
2. close bar result
3. unified regression result
4. truth-boundary
5. issue note needed or not
6. no scope expansion

### D. 测试 / 自测结果
必须明确写：
- `flutter test` 结果
- `flutter analyze` 结果
- `npm test` / `npm run test:e2e` 结果
- C5 的专项验证做了哪些

### E. 交付物清单
- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_Test_Summary_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C5_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **C5**
2. 是否建议 **Room 1 close Option C**
3. 当前最大的剩余风险是什么

---

## 15. 最后提醒

这轮不是让你再发明 Option C 新功能。

这轮唯一要做好的事情是：

> **把 C1–C4 统一回归并收成一个 Room 1 可以直接做 close judgment 的完整交付包。**

不要扩 scope。  
不要偷拍板。  
不要把 candidate input 写成 active truth。  
现在开始执行。
