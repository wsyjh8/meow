# Cursor_OptionC_C0_Command.md

你现在作为这个项目的执行端工程助手工作。

你**看不到我们的项目文档**，所以你必须**只根据这条消息中的信息行动**。  
你可以读取当前 repo 代码，因此你这轮的职责不是直接开始写 Option C 主功能，也不是直接写 Today CTA / review continuation / stats / streak hardening，而是：

> **按这里给定的 Room 1 handoff、Room 2 preflight、Room 3 BR candidate、Room 5 UI input、以及 Room 4 implementation plan / phase map，完成 Option C 的 Phase C0：Entry sync / active-version pin check。**

---

## 0. 当前项目一句话

这是一个：

> **学习驱动型轻养成 App（背单词 + 云养猫）**

当前项目真实推进状态已经不是：
- P1
- P2
- Option A / A.1
- Option B / B2 / B2-3

这些都已经完成并 close。

Room 1 已正式记录：

> **post-B2-3 next direction = Option C — Main Mechanism Enhancement**

但注意：

> **Option C 当前进入的是 Room 4 的 preflight implementation planning，不是无条件直接开写全部实现。**

你这轮接的不是：
- C1（Today CTA winner）
- C2（Review continuation / minimal review boundary）
- C3（Statistics minimal spec）
- C4（Streak truth-boundary hardening）
- C5（Test & closeout）

你这轮只做：

> **C0 — Entry sync / active-version pin check**

---

## 1. 为什么 C0 必须先做

Room 4 已明确判断：

- `BR-OPP-001_v0.1.7.md` 目前仍是 **candidate sync patch / ready for Room 1 review**
- `UI_SPEC_OptionC_MainMechanism_v0.1.1.md` 目前仍是 **Option C UI input / ready for Room 1 review**
- Room 2 提到的 very small contract clarification 是否真正进入，还要等 Room 1 pin

也就是说，Option C 当前最大的工程风险不是“代码写不出来”，而是：

> **一旦跳过 C0，后续 Cursor 很容易把 candidate input 误当 runtime active truth。**

所以，C0 不是装饰 phase，而是**开工门槛 phase**。

---

## 2. 你必须接受的当前已知基线

### 2.1 当前推进层 SSOT（Room 1 已 pin）
Room 1 当前推进层 SSOT 已明确：

- **Stage:** MVP Readiness
- **Current Sub-stage:** Stage 4 — Option B2-3 Closed / Option C Planning & Entry

### 2.2 当前 runtime active versions（已 pin）
Room 1 当前已 pin 的 runtime active baseline 是：

#### Product / PRD
- `背单词喵喵app_主机制prd_v0.3.md`
- `背单词喵喵app_副机制prd_v_0.md`
- `背单词养猫app项目介绍书_v_0.md`
- `背单词喵喵app_副机制设计稿_v_0.md`

#### Rules / Governance
- `PROJECT_RULES_MASTER_v0.3.1.md`
- `ROOM1_v0.2.md`
- `room2.md`
- `ROOM3_v0.2.2.md`
- `room4_v0.1.1.md`
- `room5_v0.1.1.md`

#### Current runtime active BR baseline
- **`BR-OPP-001_v0.1.5.md`**

#### Current runtime active DB / API baseline
- **`背单词喵喵app_DB设计草案_v0.1.4.md`**
- **`背单词喵喵app_API设计草案_v0.1.3.md`**

#### Current runtime active UI baseline
- **`UI_SPEC_OptionB_v0.1.2.md`**

#### Retained reference
- `UI_SPEC_v0.1.4.md`（Option A / persistence guardrail reference）

#### Active plan / test basis
- `plan_v0.1.2.md`
- `TEST_PLAN_v0.1.2.md`

### 2.3 当前 Option C candidate inputs（未自动 active）
以下内容目前是 **Option C working inputs / candidate inputs**，**不是自动生效的 runtime active truth**：

- `R1_OptionC_Formal_Handoff_Pack_v0.1.md`
- `R2_OptionC_MainMechanism_Preflight_v0.1.1.md`
- `BR-OPP-001_v0.1.7.md`
- `UI_SPEC_OptionC_MainMechanism_v0.1.1.md`
- `R4_OptionC_Preflight_Implementation_Plan_v0.1.1.md`
- `optionc_phases.md`

### 2.4 Room 2 的当前技术判断
Room 2 的总判断不是 No-go，而是：

> **Go with contract-first clarification**

并且 Room 2 已明确：
- 当前 active DB / API 基线总体足够支撑 Option C
- 真正可能需要的 only very small sync patch 只有三类：
  1. Today 聚合 decision-support / CTA support
  2. Review / group summary contract
  3. Minimal stats summary contract

但这些是否真的进入，**仍要等 Room 1 pin**。

### 2.5 Room 3 的当前规则判断
Room 3 当前已给出 **Option C rules sync patch candidate**：

- `BR-OPP-001_v0.1.7.md`

它已写入的方向包括：
- Today 永远只有一个最强主 CTA
- active `review_group` continuation-first
- `本组完成 ≠ 今日复习完成`
- `check_in / learning_day / streak` 三类独立事实
- 当前 `streak_basis_type = check_in`
- statistics minimal spec 只到 `summary-first`

但注意：

> 这些目前仍是 **candidate sync patch / ready for Room 1 review**，不是已自动取代 `BR-OPP-001_v0.1.5.md` 的 runtime active BR。

### 2.6 Room 5 的当前 UI 判断
Room 5 当前已给出：

- `UI_SPEC_OptionC_MainMechanism_v0.1.1.md`

它已经把以下内容作为 Option C UI input 写清：
- Today 单一最强主 CTA
- active `review_group` continuation-first 的页面表达
- `本组 / 今日 / 签到 / 学习日 / streak` 的页面边界
- statistics 只到 `summary-first / minimal summary`
- future streak stance 只能写方向，不写当前事实

但注意：

> 这份 UI_SPEC 目前仍是 **Option C UI input / ready for Room 1 review**，不是已自动取代 `UI_SPEC_OptionB_v0.1.2.md` 的 runtime active UI baseline。

---

## 3. 这轮你到底要做什么

这轮只做：

1. **核清当前 repo / docs / code 层到底以哪些版本为 runtime active baseline**
2. **明确哪些 Option C 文件目前只是 candidate input**
3. **明确 Room 2 提到的 3 类 very small contract clarification，在当前 repo 里分别属于：**
   - already active
   - accepted but not yet pinned
   - candidate only
   - not present
4. **为后续 C1–C5 给出一份可执行的“active truth vs planning input”对照**
5. **识别真正的 hard blockers / non-blocking issues**
6. **输出 C0 的正式状态文档、round summary 和 entry sync result**
7. **最终明确回答：是否 ready for C1**

这轮**不做**：
- 不实现 Today CTA winner
- 不实现 review continuation
- 不实现 statistics minimal spec
- 不实现 streak truth-boundary hardening
- 不改业务逻辑
- 不改 UI 结构
- 不默认制造 sync patch
- 不把 candidate 文件写成 active truth
- 不直接进入 C1

一句话：

> **C0 是把“当前到底能按什么开工”查清，而不是开始写 Option C 功能。**

---

## 4. 你必须服从的强断言

### 4.1 未被 Room 1 pin 的内容，不得视为 runtime active truth
尤其是：
- `BR-OPP-001_v0.1.7.md`
- `UI_SPEC_OptionC_MainMechanism_v0.1.1.md`
- Room 2 提到的 very small contract clarification

你可以把它们当：
- planning input
- candidate input
- review-ready input

但不能把它们当：
- current runtime active truth
- current mandatory implementation truth

### 4.2 若 repo 中存在实现痕迹，也不能自动推翻 Room 1 的 active versions
就算你在代码里看到了某些更近似 Option C 的东西，也不能直接推导：
- “那这就算已经 active 了”

因为这个项目的执行纪律是：

> **active versions 由 Room 1 pin，不由实现痕迹反推。**

### 4.3 C0 的目标不是证明“已经可以全部开做”
C0 的目标是分清楚：
- 哪些可直接按 active baseline 做
- 哪些只有在 Room 1 pin 后才能做
- 哪些会让后续 phase 误踩 candidate vs active truth 的边界

### 4.4 任何结论都必须区分四种状态
对每个关键输入，你必须明确归类成以下之一：

1. **Runtime active**
2. **Accepted by Room 1 but not yet reflected in runtime active versions**
3. **Candidate input / ready for review**
4. **Not present / not entered**

不要只写“已存在 / 未存在”这种模糊判断。

---

## 5. 这轮的正确目标

根据 Room 1 handoff、Room 2 preflight、Room 3 BR candidate、Room 5 UI input、以及 Room 4 plan / phase map，C0 的目标是：

> **把 Option C 当前的 active baseline、candidate input、以及 very small contract clarification 的进入状态查清，为 C1–C5 建立不误读的开工基线。**

这轮必须交付的，不是代码功能，而是：

1. 一份 **Entry sync result**
2. 一份 **active truth vs candidate input matrix**
3. 一份 **Room 4 继续开工的 blocker list**
4. 一份 **是否 ready for C1 的正式判断**

---

## 6. 这轮 in scope

### 6.1 核当前 active versions（必须）
请以 Room 1 已 pin 的推进层 SSOT 为准，核清当前：

#### Runtime active
- PRD
- BR
- DB
- API
- UI baseline
- plan / test baseline

#### Option C candidate inputs
- Room 1 handoff
- Room 2 preflight
- Room 3 BR candidate
- Room 5 UI input
- Room 4 plan / phases

要求你最后输出一个清晰表格或列表，区分：
- **runtime active**
- **candidate only**
- **accepted-but-not-reflected**（若存在）

### 6.2 核 3 类 very small contract clarification 的进入状态（必须）
Room 2 已说过，真正可能进入的 very small clarification 只有 3 类：

1. Today 聚合 decision-support / CTA support
2. Review / group summary contract
3. Minimal stats summary contract

你必须分别回答它们在当前 repo / code / docs 层的状态：
- already active
- accepted but not yet pinned
- candidate only
- not present

### 6.3 核 candidate input vs code reality 的冲突风险（必须）
你必须检查：

- 当前代码 / docs 是否已经出现“更像 Option C”的实现痕迹
- 但 Room 1 active versions 仍未 pin

如果出现这种情况，要明确列成：

> **“Do not treat as runtime active truth until Room 1 pins it.”**

### 6.4 为 C1–C5 建一个开工规则表（必须）
请输出一份最小开工规则表，至少包括：

#### C1 Today CTA winner
- 当前是否可直接开做
- 走保守路径还是 decision-support path
- 哪些输入未 pin 不能假设

#### C2 Review continuation / minimal review boundary
- 当前是否可直接开做
- 哪些 summary clarification 未 pin
- 哪些规则可直接按 current frozen 做

#### C3 Statistics minimal spec
- 当前是否可直接开做
- 默认是 summary block / summary card / minimal entry
- 是否能做独立 page

#### C4 Streak truth-boundary hardening
- 当前是否可直接开做
- 哪些 future stance 不能提前实施

#### C5 Closeout
- 依赖哪些前置 phases 完成

### 6.5 如发现 gap，必须分类（必须）
如果你发现 gap，不要笼统写“还没好”。

必须明确它属于哪类：

- **Hard blocker**
- **Non-blocking issue**
- **Assumption (temporary, not frozen)**
- **Candidate only, wait for Room 1 pin**

---

## 7. 这轮明确不做什么

### 7.1 不做 C1–C5 的实现
这轮不能：
- 改 Today CTA
- 改 review continuation
- 改 stats UI
- 改 streak logic
- 跑 Option C closeout

### 7.2 不代替 Room 1 pin active versions
你只能判断当前状态，不能替 Room 1 下结论说：
- “那我们就按 v0.1.7 / v0.1.1 当 active 吧”

### 7.3 不制造新的 contract patch
你可以记录缺口，但不能在 C0 就顺手新增 patch proposal 并当成既成事实。

### 7.4 不把 code reality 反推成 governance truth
这条非常重要。  
就算 repo 代码里有相关字段 / 组件 / helper，也不能据此直接推导：
- “既然代码里有，那就算已经 active 了”

---

## 8. 你必须先读 repo 里什么

请先重点阅读 / 盘点：

### 8.1 推进层 SSOT / active baseline
- `Main_updated_2026-04-05_v13.md`
- `STATUS_updated_2026-04-05_v12.md`

### 8.2 当前 runtime active baseline
- `BR-OPP-001_v0.1.5.md`
- `背单词喵喵app_DB设计草案_v0.1.4.md`
- `背单词喵喵app_API设计草案_v0.1.3.md`
- `UI_SPEC_OptionB_v0.1.2.md`
- `UI_SPEC_v0.1.4.md`
- `plan_v0.1.2.md`
- `TEST_PLAN_v0.1.2.md`
- `背单词喵喵app_主机制prd_v0.3.md`

### 8.3 Option C candidate inputs
- `R1_OptionC_Formal_Handoff_Pack_v0.1.md`
- `R2_OptionC_MainMechanism_Preflight_v0.1.1.md`
- `R3_OptionC_Rules_Freeze_Note_v0.1.1.md`
- `BR-OPP-001_v0.1.7.md`
- `UI_SPEC_OptionC_MainMechanism_v0.1.1.md`
- `R4_OptionC_Preflight_Implementation_Plan_v0.1.1.md`
- `optionc_phases.md`

### 8.4 代码层必须盘点的位置
至少检查这些真实代码 / 结构入口：

1. Today 页当前 CTA 逻辑在哪
2. 是否已有类似 `today_primary_action` / decision-support block
3. `review_group` continuation / readiness 当前由谁决定
4. 是否已有 stats summary contract / minimal stats entry
5. `check_in / learning_day / streak` 当前展示 / helper / mapper / API parsing 在哪里
6. 当前 UI baseline 真正依赖哪几个 model / response / selector

---

## 9. C0 你必须明确回答的问题

### Q1. 当前 runtime active baseline 到底是什么
请按下面分类明确回答：
- active PRD
- active BR
- active DB
- active API
- active UI baseline
- active plan / test baseline

### Q2. 当前 Option C candidate inputs 到底是什么
请明确哪些文件只是：
- planning input
- review-ready input
- candidate sync patch

### Q3. Room 2 提到的三类 very small contract clarification 现在各自处于什么状态
对每一类，都必须判断：
- already active
- accepted but not yet pinned
- candidate only
- not present

### Q4. 当前 repo / code 是否存在“像 Option C 已经部分实现”的痕迹
若有，请明确：
- 它在哪
- 为什么仍不能直接当 runtime active truth
- 后续 phase 该如何避免误用

### Q5. 当前是否 ready for C1
必须明确：
- **YES / NO**
- 如果 YES，C1 应按哪条路径开工
- 如果 NO，哪条 blocker 必须先解

### Q6. 当前最大的误读风险是什么
至少明确写：
- candidate BR 被误当 active BR
- candidate UI input 被误当 active UI baseline
- 未 pin 的 contract clarification 被实现层偷转成 truth

---

## 10. 这轮允许做什么，不允许做什么

### 允许做的
1. 做 entry sync audit
2. 做 active-vs-candidate mapping
3. 做 code reality vs governance truth 风险识别
4. 更新 Room 4 的 Option C 状态文档
5. 写 round summary
6. 写是否 ready for C1 的正式判断

### 不允许做的
1. 不直接写 Option C 功能代码
2. 不默认接受 candidate input 为 active truth
3. 不代替 Room 1 pin 版本
4. 不新增 sync patch 并当成已进入
5. 不跳过 C0 直接开 C1

---

## 11. 这轮最小测试 / 验证要求

### 11.1 这轮不是功能测试轮，但要做 repo / code / docs 一致性核查
至少完成以下核查：

1. Docs active baseline vs candidate input 是否一致
2. Code reality 是否与 active baseline 冲突
3. Option C planning input 是否被误当 active
4. 后续 C1–C5 是否已有被误提前实现的风险

### 11.2 如需要跑测试，只做最小防误判检查
如果你确实需要跑测试，只为了确认“当前 active behavior”与 docs 没冲突，可以做最小 smoke / grep / model-level audit。  
但这轮**不是完整测试轮**，不要把它做成 C5。

---

## 12. 本轮必须产出的文件（硬要求）

### Deliverable A — 状态文件
请新增：

```text
docs/R4_OptionC_Status_v0.1.md
```

至少包含：
1. 当前完成到哪个 phase（必须写 C0）
2. 当前 runtime active baseline
3. 当前 Option C candidate inputs
4. three very small contract clarifications 的进入状态
5. 当前 hard blockers / non-blocking issues / assumptions
6. 当前是否建议进入 C1

### Deliverable B — Entry sync result
请新增：

```text
docs/R4_OptionC_Entry_Sync_Result_v0.1.md
```

至少包含：
1. active truth vs candidate input matrix
2. very small clarifications status matrix
3. code reality vs governance truth 风险点
4. C1–C5 开工规则表

### Deliverable C — Round summary（硬要求）
请新增：

```text
docs/R4_cursor_round_summary_OptionC_C0_v0.1.md
```

这份总结必须写给“下一个接手的 Cursor”看，至少包含：

1. **This round did what**
2. **What is runtime active truth**
3. **What is candidate only**
4. **Which clarifications are entered or not**
5. **What the biggest misread risks are**
6. **What is still not decided**
7. **What must be done next**
8. **What not to touch**
9. **Files / modules to read first**
10. **Current blockers / assumptions / risks**
11. **Whether ready for C1**

### Optional
仅在确有必要时，允许新增：

```text
docs/R4_OptionC_Issue_Note_v0.1.md
```

只有在你确认：
- docs / code / active versions 存在实质冲突
- 或 Room 1 pin 前无法安全进入 C1

时才交。

---

## 13. 这轮完成标准（严格）

以下全部满足，才算 C0 完成：

1. 当前 runtime active baseline 已核清
2. 当前 Option C candidate inputs 已核清
3. Room 2 的 3 类 very small contract clarification 进入状态已逐项判断
4. code reality vs governance truth 的误读风险已列清
5. `docs/R4_OptionC_Status_v0.1.md` 已生成
6. `docs/R4_OptionC_Entry_Sync_Result_v0.1.md` 已生成
7. `docs/R4_cursor_round_summary_OptionC_C0_v0.1.md` 已生成
8. 最终能明确回答：是否 ready for **C1**

---

## 14. 回传格式（固定）

请严格按下面结构回我。

### A. 本轮执行概览
- 这轮具体做了什么
- 明确指出：这是 **Option C / C0 / Entry sync / active-version pin check**
- 明确不是 C1–C5 实现轮

### B. 新增 / 改动文件清单
只列路径即可。

### C. 当前 C0 结果
请按这几项写清楚：
1. runtime active baseline
2. candidate inputs
3. clarifications status
4. code-vs-governance risks
5. blocker summary
6. no scope expansion

### D. 核查 / 自测结果
必须明确写：
- 你做了哪些 docs / code / repo consistency audit
- 若有最小 smoke / grep / model checks，也请列出

### E. 交付物清单
- `docs/R4_OptionC_Status_v0.1.md`
- `docs/R4_OptionC_Entry_Sync_Result_v0.1.md`
- `docs/R4_cursor_round_summary_OptionC_C0_v0.1.md`

### F. 当前 blockers / assumptions / risks
格式必须是：
- `Assumption (temporary, not frozen): ...`
- `Blocked if touched: ...`
- risk list 单列

### G. 最终判断
明确回答：
1. 当前是否完成 **C0**
2. 是否 ready for **C1**
3. 当前最大的误读风险是什么

---

## 15. 最后提醒

这轮不是让你写 Option C 功能。

这轮唯一要做好的事情是：

> **把当前到底能按什么开工、哪些只是 candidate input、哪些 clarification 真正进入了，查清并固化。**

不要扩 scope。  
不要偷拍板。  
不要把 candidate input 写成 active truth。  
现在开始执行。
