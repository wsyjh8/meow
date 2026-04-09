# optionc_phases.md

# Option C — Main Mechanism Enhancement  
## Room 4 phased execution plan for Cursor

- **Owner:** Room 4
- **Role:** Eng + QA + Debug Tech Lead
- **Project:** 背单词喵喵 App
- **Round:** Option C
- **Version:** v0.1
- **Status:** ready for Cursor handoff
- **Date:** 2026-04-05

---

## 0. TL;DR

Room 4 结论：

> **Option C 最合适分成 6 个 phases。**

具体是：

1. **C0 — Entry sync / active-version pin check**
2. **C1 — Today CTA winner**
3. **C2 — Review continuation / minimal review boundary**
4. **C3 — Statistics minimal spec**
5. **C4 — Streak truth-boundary hardening**
6. **C5 — Test & closeout**

这不是机械照搬目录，而是因为 `R4_OptionC_Preflight_Implementation_Plan_v0.1.1.md` 已经把 Option C 的最小实现切片和推荐 phase 顺序写得很清楚；从 Room 4 的实现与验证视角看，这 6 段正好对应 6 个不同风险域：

- **C0** 管的是：能不能开工、哪些输入已 pin、哪些还只是 candidate
- **C1** 管的是：Today 单一最强主 CTA
- **C2** 管的是：`review_group` continuation / readiness / minimal review priority
- **C3** 管的是：statistics `summary-first`
- **C4** 管的是：`check_in / learning_day / streak` 边界 hardening
- **C5** 管的是：统一回归与 close judgment

一句话：

> **Cursor 很强，但 Option C 的风险不在“代码量”，而在“规则边界 + candidate input vs active truth + truth-boundary 回归”。所以最稳的切法不是更少，而是刚好 6 段。**

---

## 1. 当前基线判断（Room 4 version）

### 1.1 为什么现在可以开始拆 phases
`R4_OptionC_Preflight_Implementation_Plan_v0.1.1.md` 已经明确写了：

> **Option C 已具备进入 Room 4 实现规划阶段的条件。**

也就是：
- Room 1 已正式把主线程切到 **Option C — Main Mechanism Enhancement**
- Room 2 已给出 **Go with contract-first clarification**
- Room 3 已把最关键的 Frozen / Pending 收到 `BR-OPP-001_v0.1.7.md`
- Room 5 已把页面表达收成 `UI_SPEC_OptionC_MainMechanism_v0.1.1.md`

但同时也写得很硬：

> **当前能进入的是 preflight implementation planning，不是无条件直接开写全部实现。**

### 1.2 为什么不能直接切成 2–3 个大 phase
因为 plan 里已经明确指出，当前仍有三个最关键的上游 pin 问题：

1. `BR-OPP-001_v0.1.7.md` 还是 candidate sync patch
2. `UI_SPEC_OptionC_MainMechanism_v0.1.1.md` 还是 Option C UI input
3. Room 2 提到的 very small contract clarification 是否真正进入，还要等 Room 1 pin

也就是说，Option C 最大的风险不是“写不出来”，而是：

> **一旦 phase 切太大，Cursor 很容易把 candidate input 误当 active truth，或者在一个 phase 里同时混进 contract clarification、UI 表达、truth-boundary hardening 和 closeout。**

---

## 2. 为什么是 6 个，不是更少也不是更多

### 2.1 不是 4 个
如果只切 4 个，通常会变成：

- P1：Entry + CTA
- P2：Review + stats
- P3：streak
- P4：closeout

这会有三个问题：

1. **C0 会被吞掉**  
   但 C0 其实是硬门槛，不是装饰 phase。没它，Cursor 很容易把 candidate input 当 runtime active truth。

2. **C2 和 C3 不该混**  
   `review_group` / readiness / minimal review priority 是主学习流逻辑问题；  
   statistics `summary-first` 是展示范围和 minimal entry 问题。  
   它们不是同一风险域。

3. **C4 会被轻视**  
   `check_in / learning_day / streak` 这块代码量不一定大，但 truth-boundary 风险很高。  
   一旦并进别的 phase，最容易变成“顺手修一下”，然后把 future stance 写成 current fact。

### 2.2 不是 8 个或更多
如果切到 7–8 个以上，又会过碎：

- handoff 成本太高
- 每轮总结文档太多
- Cursor 上下文切换反而更多
- 很多 very small repair 会被切到不自然的位置

Option C 不是大重构，不值得切那么碎。

### 2.3 为什么 6 个最稳
因为 `R4_OptionC_Preflight_Implementation_Plan_v0.1.1.md` 已经把：
- **工程切片**
- **推荐顺序**
- **blocker**
- **test entry**
- **close bar**
都写成了最自然的 6 段。

Room 4 视角下，这已经不是“可选建议”，而是最适合交给 Cursor 的执行粒度。

---

## 3. 本轮总边界（Room 4 version）

## 3.1 In scope
Option C 本轮只包括以下四块主问题与最终收口：

1. CTA winner / Today 主按钮仲裁
2. `review_group` continuation / readiness / minimal review boundary
3. statistics minimal spec / summary-first
4. `check_in / learning_day / streak` truth-boundary hardening
5. 最后一轮统一 regression / closeout

## 3.2 Out of scope
本轮继续明确不做：

1. 不重开副机制 major phase
2. 不继续做 secondary small patch
3. 不自动进入 `companion_response` typing
4. 不自动进入 `source_fact_tags`
5. 不重写 DB / API 全结构
6. 不做完整 SRS 终版
7. 不做完整统计产品
8. 不切换 `streak_basis_type`
9. 不把 candidate contract 自动当 active truth
10. 不把 Option C 扩成大重构

---

## 4. 统一硬边界（所有 phases 都必须服从）

### 4.1 Room 1 未 pin 的东西，不得被实现层偷转成 active truth
这是 Option C 最重要的执行纪律。

### 4.2 Today 永远只能有一个最强主 CTA
不能把 Session、新词、复习做成并列 winner。

### 4.3 `本组完成 ≠ 今日复习完成`
这是 C2 的核心边界，也是全链路必须统一的边界。

### 4.4 `check_in / learning_day / streak` 是三类独立事实
当前仍是：
- `streak_basis_type = check_in`
- future stance 只能写方向，不能提前实施

### 4.5 statistics 默认是 summary-first
若 Room 1 没 pin 独立 minimal page，就不默认实现独立统计页。

### 4.6 任何未 pin 的 contract clarification，都只能按保守路径实现
- `today_primary_action`
- review/group summary clarification
- minimal stats summary contract  
只要没 pin，就不能假装它已存在。

---

## 5. 推荐 phases（Room 4 正式建议）

# Phase C0 — Entry sync / active-version pin check

## 目标
在真正写 Option C 代码前，先确认：
- Room 1 是否已 pin 当前 Option C 输入
- 哪些 very small contract clarification 进入
- 哪些还是 candidate

## 本 phase 要做的事
1. 对照 `Main / STATUS` 核当前 active versions
2. 明确：
   - `BR-OPP-001_v0.1.7.md` 是否已被 Room 1 pin
   - `UI_SPEC_OptionC_MainMechanism_v0.1.1.md` 是否已被 Room 1 pin
   - Room 2 的 three very small clarifications 哪些进入
3. 给后续 Cursor 明确：
   - 哪些是 active truth
   - 哪些只是 planning input
4. 若未 pin，写清保守路径，不自行补脑

## 本 phase 完成标准
- 当前 active versions 清楚
- candidate input vs runtime active truth 清楚
- 后续 phases 的保守路径是否启用清楚

## 本 phase 风险
- 若跳过 C0，后面每个 phase 都可能误读上游输入

---

# Phase C1 — Today CTA winner

## 目标
把 Today 页“现在最该做什么”落成一个**单一最强主 CTA**，并且不靠 UI 自己补脑最终业务事实。

## 本 phase 要做的事
1. Today 页主 CTA 视图与状态映射
2. active `review_group` continuation-first 的最小表达
3. “有待复习时先去复习” 的页面承接
4. Session 退回辅助区块，不与主 CTA 并列抢位
5. 对应 Today 的 widget / integration / e2e 验证入口

## 本 phase 不做什么
1. 不冻结完整 CTA 优先级算法
2. 不默认要求 `today_primary_action` 已经存在
3. 不把 Session 纳入复杂 CTA 算法仲裁
4. 不在 Room 1 未 pin very small contract clarification 前假设新聚合块已存在

## 两种路径
### Path C1-A（无新 contract patch）
- 仅基于当前 active API baseline 已稳定存在的聚合结果落地
- 保守 winner：
  - active `review_group` → `继续本组复习`
  - 无 active group 且存在后端确认待复习 / 高优先复习任务 → `先去复习`
  - 否则 → `开始新词学习 / 继续新词学习`

### Path C1-B（有 very small contract patch）
- 若 Room 1 pin 了 Today 聚合 decision-support block：
  - UI 只消费后端返回的 decision-support / reason
  - 不再拼 winner

## 本 phase 完成标准
1. Today 永远只有一个最强主 CTA
2. active `review_group` continuation-first 成立
3. Session 不会压主 CTA
4. UI 不会把签到 / Session / 局部完成误写成“今天最该做的学习已完成”
5. 缺少 new decision-support block 时仍能保守运行

---

# Phase C2 — Review continuation / minimal review boundary

## 目标
把 `review_group` 的 continuation / readiness / minimal review priority 边界做稳，避免 Today / Review / 结算各自补脑。

## 本 phase 要做的事
1. active `review_group` continuation-first 的具体实现
2. “本组完成 ≠ 今日复习完成”的状态分离
3. `next group readiness` 的页面 / 逻辑承接
4. review priority 只做到主因子层，不做完整评分引擎
5. 对应复习流、Today 卡、组完成、今日完成的测试入口

## 本 phase 不做什么
1. 不做完整 SRS
2. 不做 group size / interval / 详细 priority 权重引擎
3. 不改 `review_queue` / `study_attempts` 主结构
4. 不把 Room 2 的 future summary contract 当成默认已存在

## 两种路径
### Path C2-A（仅按当前 frozen + active API）
- 基于当前 active `review_group` 最小合同
- UI / 实现不凭 remaining count 自行推 next-group readiness
- 尽量以后端已有聚合为准

### Path C2-B（Room 1 pin review/group summary clarification）
- 若 Room 1 接受 Room 2 的 very small patch：
  - 接更稳的 continuation / progress / readiness summary

## 本 phase 完成标准
1. active group 继续优先成立
2. group completion 与 daily review completion 不混写
3. Today / Review / 结算层三处表达一致
4. UI 不靠 local remaining count 私判 next group readiness
5. review priority 仅停留主因子层，不偷扩成完整 SRS

---

# Phase C3 — Statistics minimal spec

## 目标
决定并落下 statistics 的最小可运行规格，让用户有最小结果感，但不把统计页做成完整分析产品。

## 本 phase 要做的事
1. 判断本轮 statistics 是否真正进入实现范围
2. 若进入：
   - 只做 `summary-first / minimal summary`
   - **默认先落在 summary block / summary card / minimal entry**
   - 不自动承诺独立页面；独立 minimal page 只有在 Room 1 额外 pin 时再进入
3. 保证 `学习天数 = learning_day`
4. 对应统计 summary 的最小测试入口

## 本 phase 不做什么
1. 不做重 BI
2. 不做大报表
3. 不做复杂趋势分析后台
4. 不默认要求独立完整统计页必须交付

## 两种路径
### Path C3-A（推荐）
- 先实现 summary-first
- 默认先按 Today / 统计入口附近的 **summary block / summary card / minimal entry** 落地
- 独立 minimal page 只有在 Room 1 额外 pin 时再进入

### Path C3-B（仅在 Room 1 pin 独立最小页后）
- 再做独立 minimal page
- 但仍只展示最小 summary，不做深度分析

## 本 phase 完成标准
1. statistics 若进入，只做到 summary-first
2. `学习天数` 明确基于 `learning_day`
3. 不把 `check_in` / `streak` 混写成学习天数
4. 若独立页未 pin，不把它当 blocker

---

# Phase C4 — Streak truth-boundary hardening

## 目标
不是切换 `streak` basis，而是把当前 frozen 关系在实现、文案、测试中彻底守住，并把 future stance 仅保留为方向。

## 本 phase 要做的事
1. 当前 `streak_basis_type = check_in` 的页面和实现一致性
2. `check_in` / `learning_day` / `streak` 三类事实的表达隔离
3. summary / stats / Today / 结算相关 wording boundary
4. future stance 只作 direction，不作 runtime fact
5. 对应 truth-boundary cases 的测试入口

## 本 phase 不做什么
1. 不切 basis
2. 不引入补签 / 宽限逻辑
3. 不改 active contract
4. 不实施未来口径迁移

## 本 phase 完成标准
1. `签到成功 ≠ learning_day`
2. `learning_day 成立 ≠ streak 已按学习日延续`
3. `streak` 当前仍按签到延续
4. future stance 不会被 UI / 实现误读为当前事实

---

# Phase C5 — Test & closeout

## 目标
在 C1–C4 完成后，形成一轮能给 Room 1 做 close judgment 的统一验证包。

## 本 phase 要做的事
1. 主链路统一回归
2. 高风险 truth-boundary case 回归
3. P1 / P2 / B 系列不回归断言
4. 状态文件 / 测试摘要 / round summary / close bar judgement

## 本 phase 通过标准
1. Option C 进入项都能说明“做了什么 / 没做什么”
2. 最小回归集通过
3. 上游 Pending 没被 Room 4 偷冻结
4. Room 1 能直接判断：close / not close

---

## 6. Room 4 的正式建议

### 推荐 phase 数
> **6 个 phases 最合适。**

### 推荐执行顺序
1. **C0 — Entry sync / active-version pin check**
2. **C1 — Today CTA winner**
3. **C2 — Review continuation / minimal review boundary**
4. **C3 — Statistics minimal spec**
5. **C4 — Streak truth-boundary hardening**
6. **C5 — Test & closeout**

### 为什么这样最稳
因为它正好对应：
- 1 个开工门槛 phase
- 4 个不同风险域的主实现切片
- 1 个统一收口 phase

这样不会把：
- candidate input pin check
- CTA winner
- review continuation
- stats minimal entry
- streak truth-boundary
- closeout

混在同一轮里。

---

## 7. 一句话版（给 Room 1 / 给 Cursor）

> **Option C 最合适按 C0 → C5 共 6 段推进：先做 active-version / contract pin check，再依次处理 Today CTA、review continuation、statistics minimal spec、streak truth-boundary，最后统一做 regression 和 closeout。Cursor 能力足够强，但这轮最需要的是边界控制，不是粗暴合并 phase。**
