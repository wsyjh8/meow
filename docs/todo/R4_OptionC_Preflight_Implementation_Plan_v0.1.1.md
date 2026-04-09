# R4_OptionC_Preflight_Implementation_Plan_v0.1.1.md

- **Owner:** Room 4
- **Role:** Eng + QA + Debug Tech Lead
- **Project:** 背单词喵喵 App
- **Type:** preflight implementation plan / test entry
- **Status:** ready for Room 1 review / review11 absorbed
- **Date:** 2026-04-05

---

## 0. TL;DR

Room 4 结论：

> **Option C 已经具备进入 Room 4 实现规划阶段的条件。**

但这里的“进入”有一个非常重要的边界：

> **当前可以进入的是 `preflight implementation planning`，而不是无条件直接开写全部实现。**

原因很清楚：

1. Room 1 已正式把主线程切到 **Option C — Main Mechanism Enhancement**。
2. Room 2 已给出 **Go with contract-first clarification** 的技术入口判断。
3. Room 3 已把 Option C 当前最关键的 Frozen / Pending 收口到 `BR-OPP-001_v0.1.7.md`。
4. Room 5 已把 Option C 的页面表达收成 `UI_SPEC_OptionC_MainMechanism_v0.1.1.md`。
5. 但当前 runtime active baseline 仍然以 Room 1 `Main / STATUS` 已 pin 的版本为准；  
   这些 Option C 输入在 Room 1 正式更新 active versions 之前，仍然是 **ready for review / ready for pin** 的 next-phase inputs，而不是自动生效的 runtime active baseline。

一句话：

> **Room 4 现在可以把 Option C 拆成工程批次、测试入口和回归集，但不能在上游未 pin 的地方自行补脑开做。**

---

## 1. 本稿定位

本稿不是：
- 主机制 PRD 重写稿
- DB / API 重写稿
- 规则冻结稿
- UI / UX 主稿
- 自动生效的 active runtime plan
- 直接开工命令合集

本稿只做一件事：

> **以 Room 4 视角，把当前 Option C 已经收敛到足够稳定的输入，翻译成可执行的 implementation slices、test entry、blocker list、regression strategy 与 close bar proposal。**

更直白一点：

- Room 2 决定“技术入口够不够”
- Room 3 决定“规则冻到哪”
- Room 5 决定“页面怎么表达”
- **Room 4 负责把这些输入变成：能实现、能测、能回归、能收口的工程计划**

---

## 2. 输入依据（Room 4 working basis）

### 2.1 直接 Option C 输入
1. `R1_OptionC_Formal_Handoff_Pack_v0.1.md`
2. `R2_OptionC_MainMechanism_Preflight_v0.1.1.md`
3. `BR-OPP-001_v0.1.7.md`
4. `UI_SPEC_OptionC_MainMechanism_v0.1.1.md`

### 2.2 当前仍需服从的 runtime active baseline
1. `Main_updated_2026-04-05_v13.md`
2. `STATUS_updated_2026-04-05_v12.md`
3. `BR-OPP-001_v0.1.5.md`（当前 runtime active BR baseline）
4. `背单词喵喵app_DB设计草案_v0.1.4.md`
5. `背单词喵喵app_API设计草案_v0.1.3.md`
6. `UI_SPEC_OptionB_v0.1.2.md`（当前 runtime active UI baseline）
7. `UI_SPEC_v0.1.4.md`（Option A / main mechanism guardrail reference）
8. `背单词喵喵app_主机制prd_v0.3.md`

### 2.2A candidate input vs runtime active truth（本轮增量写硬）
- `BR-OPP-001_v0.1.7.md` 目前只可作为 **Option C working rule input / planning input** 使用。
- 在 Room 1 未正式 pin 前，Room 4 **不得**把 `BR-OPP-001_v0.1.7.md` 视为 runtime active truth；当前 runtime active BR baseline 仍是 `BR-OPP-001_v0.1.5.md`。
- `UI_SPEC_OptionC_MainMechanism_v0.1.1.md` 目前只可作为 **Option C UI input / planning input** 使用。
- 在 Room 1 未正式 pin 前，Room 4 **不得**把 `UI_SPEC_OptionC_MainMechanism_v0.1.1.md` 视为 runtime active UI truth；当前 runtime active UI baseline 仍是 `UI_SPEC_OptionB_v0.1.2.md`。

### 2.3 Room 4 工作边界
Room 4 只负责：
- 实现切片
- 测试入口
- blocker list
- regression strategy
- close bar proposal

Room 4 不负责：
- 再拍产品方向
- 再拍 Frozen / Pending 规则
- 再拍 UI 主结构
- 在 Room 1 未 pin active versions 前，自动把 candidate input 视为 runtime active

---

## 3. Room 4 总判断

### 3.1 可以进入 Room 4 规划的原因
当前已足够稳定的输入有：

#### A. Room 1 已正式拍板
- post-B2-3 next direction = **Option C**
- Option C 只做主机制质量收口，不做大重构
- Room 4 本轮正式任务就是：
  - implementation slices
  - test entry
  - blocker list
  - regression strategy
  - close bar proposal

#### B. Room 2 已给出技术入口判断
- 总结论：**Go with contract-first clarification**
- 当前 active DB / API 基线总体足够支撑 Option C 进入
- 真正可能需要的 only very small sync patch 只有三类：
  1. Today 聚合决策支撑块
  2. Review / group summary contract
  3. Minimal stats summary contract
- 当前不建议：
  - 重写主 DB / API
  - 上完整 SRS
  - 切 `streak_basis_type`

#### C. Room 3 已写硬最小 Frozen 层
当前已足够进入 Room 4 planning 的核心 Frozen 有：
1. Today 永远只能有一个最强主 CTA
2. active `review_group` continuation-first
3. `本组完成 ≠ 今日复习完成`
4. `check_in` / `learning_day` / `streak` 是三类独立事实
5. 当前 `streak_basis_type = check_in` 保持不动
6. `summary-first` statistics minimal spec 已进入冻结范围
7. `today_primary_action` / 更细 review summary / future streak switch 仍未自动成为 active contract

#### D. Room 5 已给出最小页面表达输入
当前已够 Room 4 消费的 UI 输入有：
1. Today 单一最强主 CTA
2. active `review_group` continuation-first 的页面表达
3. `本组 / 今日 / 签到 / 学习日 / streak` 边界
4. summary-first 统计的最小页面形态
5. future streak stance 只能写方向，不写当前事实

### 3.2 当前仍不能直接“无阻塞开做”的原因
虽然可以进入 planning，但当前仍有几个上游未 pin / 未落到 active runtime 的点：

1. `BR-OPP-001_v0.1.7.md` 仍是 **candidate sync patch / ready for Room 1 review**
2. `UI_SPEC_OptionC_MainMechanism_v0.1.1.md` 仍是 **Option C UI input / ready for Room 1 review**
3. Room 2 提到的 very small contract clarification 是否真的进入，还要等 Room 1 pin

补一句写硬：
- Room 4 可以使用 `BR-OPP-001_v0.1.7.md` 与 `UI_SPEC_OptionC_MainMechanism_v0.1.1.md` 做 planning input，
  **但不得在 Room 1 未 pin 前把它们当成 runtime active truth。**

所以，Room 4 的当前结论不是：

> “直接写完 Option C 全实现”

而是：

> “先把 Option C 的工程切法、测试入口、阻塞条件和回归边界收清楚；Room 1 一旦 pin，就可以顺滑发给执行端。”

---

## 4. Option C 四块 pending → Room 4 最小实现切片

Room 1 当前推荐优先级是：

1. CTA winner
2. `review_group` / review priority / 最小 SRS 边界
3. statistics minimal spec
4. future streak stance

Room 4 同意这个顺序，并将其翻译成如下实现切片。

### 4.0 跨切片统一执行原则（本轮增量补强）
1. 当 Room 1 **未 pin** very small contract clarification 时，Room 4 的页面落地应回退到 **current runtime active UI baseline**，而不是在实现层自行发明新的中间态页面语义。
2. 这意味着：
   - 未 pin `today_primary_action` 或等价 decision-support block 时，C1 只能按当前 active API + active UI baseline 的保守路径实现。
   - 未 pin review / group summary clarification 时，C2 只能按当前 frozen rule + active API baseline 的保守路径实现。
   - 未 pin独立 minimal stats page 时，C3 默认只按 summary-first 的 summary block / entry 落地，不自动承诺独立页面。
3. 一句话：**Room 4 可以规划 Option C input，但未被 Room 1 pin 的 contract / UI input 不得被实现层偷转成 runtime active truth。**

---

# Slice C1 — Today CTA winner / single-strong-CTA 落地

## 4.1.1 目标
把 Today 页“现在最该做什么”落成一个**单一最强主 CTA**，并且不靠 UI 自己补脑最终业务事实。

## 4.1.2 本切片只做什么
1. Today 页主 CTA 视图与状态映射
2. active `review_group` continuation-first 的最小表达
3. “有待复习时先去复习” 的页面承接
4. Session 退回辅助区块，不与主 CTA 并列抢位
5. 对应 Today 的 widget / integration / e2e 验证入口

## 4.1.3 本切片不做什么
1. 不冻结完整 CTA 优先级算法
2. 不默认要求 `today_primary_action` 必须已经存在
3. 不把 Session 纳入复杂 CTA 算法仲裁
4. 不在 Room 1 未 pin very small contract clarification 前假设新聚合块已存在

## 4.1.4 两种实现路径
### Path C1-A（无新 contract patch）
如果 Room 1 没有 pin Room 2 的 today decision-support block：
- 仅基于当前 active API baseline 已稳定存在的聚合结果落地
- 采用保守 winner 规则：
  - active `review_group` → `继续本组复习`
  - 无 active group 且存在后端确认待复习 / 高优先复习任务 → `先去复习`
  - 否则 → `开始新词学习 / 继续新词学习`

### Path C1-B（有 very small contract patch）
如果 Room 1 pin 了 Today 聚合 decision-support block：
- 改为基于后端明确返回的 decision-support / reason block
- UI 只做表达，不再拼 winner
- 这条路径更稳，但不应在 Room 1 未 pin 时提前假设

## 4.1.5 通过标准
1. Today 永远只有一个最强主 CTA
2. active `review_group` continuation-first 成立
3. `Session` 不会压主 CTA
4. UI 不会把签到 / Session / 局部完成误写成“今天最该做的学习已完成”
5. 缺少 new decision-support block 时仍能保守运行

---

# Slice C2 — `review_group` continuation / readiness / minimal review priority

## 4.2.1 目标
把 `review_group` 的**最小 continuation / readiness / progress 边界** 落成稳定实现，避免 Today / Review / 结算表达层继续各自脑补。

## 4.2.2 本切片只做什么
1. active `review_group` continuation-first 的具体实现
2. “本组完成 ≠ 今日复习完成”的状态分离
3. `next group readiness` 的页面 / 逻辑承接
4. review priority 只做到主因子层，不做完整评分引擎
5. 对应复习流、Today 卡、组完成、今日完成的测试入口

## 4.2.3 本切片不做什么
1. 不做完整 SRS
2. 不做 group size / interval / 详细 priority 权重引擎
3. 不改 `review_queue` / `study_attempts` 主结构
4. 不把 Room 2 的 future summary contract 当成默认已存在

## 4.2.4 两种实现路径
### Path C2-A（仅按当前 frozen + active API）
- 基于当前 active `review_group` 最小合同
- UI / 实现不凭 remaining count 自行推 next-group readiness
- 尽量以后端已有聚合为准

### Path C2-B（Room 1 pin review/group summary clarification）
- 若 Room 1 接受 Room 2 的 very small patch：
  - 接更稳的 continuation / progress / readiness summary
- 这样可减少 Room 4 / Room 5 推断成本

## 4.2.5 通过标准
1. active group 继续优先成立
2. group completion 与 daily review completion 不混写
3. Today / Review / 结算层三处表达一致
4. UI 不靠 local remaining count 私判 next group readiness
5. review priority 仅停留主因子层，不偷扩成完整 SRS

---

# Slice C3 — Statistics minimal spec / summary-first

## 4.3.1 目标
决定并落下 statistics 的最小可运行规格，让用户有最小结果感，但不把统计页做成完整分析产品。

## 4.3.2 本切片只做什么
1. 判断本轮 statistics 是否真正进入实现范围
2. 若进入：
   - 只做 `summary-first / minimal summary`
   - **默认先落在 summary block / summary card / minimal entry**
   - 不自动承诺独立页面；独立 minimal page 只有在 Room 1 额外 pin 时再进入
3. 保证“学习天数 = learning_day”
4. 对应统计 summary 的最小测试入口

## 4.3.3 本切片不做什么
1. 不做重 BI
2. 不做大报表
3. 不做复杂趋势分析后台
4. 不默认要求独立完整统计页必须交付

## 4.3.4 推荐实现顺序
### Path C3-A（推荐）
- 先实现 summary-first
- 默认先按 Today / 统计入口附近的 **summary block / summary card / minimal entry** 落地
- 独立 minimal page 只有在 Room 1 额外 pin 时再进入

### Path C3-B（仅在 Room 1 pin 独立最小页后）
- 再做独立 minimal page
- 但仍只展示最小 summary，不做深度分析

## 4.3.5 通过标准
1. statistics 若进入，只做到 summary-first
2. `学习天数` 明确基于 `learning_day`
3. 不把 `check_in` / `streak` 混写成学习天数
4. 若独立页未 pin，不把它当 blocker

---

# Slice C4 — `check_in` / `learning_day` / `streak` truth-boundary hardening

## 4.4.1 目标
不是切换 `streak` basis，而是把当前 frozen 关系在实现、文案、测试中彻底守住，并把 future stance 仅保留为方向。

## 4.4.2 本切片只做什么
1. 当前 `streak_basis_type = check_in` 的页面和实现一致性
2. `check_in` / `learning_day` / `streak` 三类事实的表达隔离
3. summary / stats / Today / 结算相关 wording boundary
4. future stance 只作 direction，不作 runtime fact
5. 对应 truth-boundary cases 的测试入口

## 4.4.3 本切片不做什么
1. 不切 basis
2. 不引入补签 / 宽限逻辑
3. 不改 active contract
4. 不实施未来口径迁移

## 4.4.4 通过标准
1. `签到成功 ≠ learning_day`
2. `learning_day 成立 ≠ streak 已按学习日延续`
3. `streak` 当前仍按签到延续
4. future stance 不会被 UI / 实现误读为当前事实

---

# Slice C5 — Option C regression / closeout

## 4.5.1 目标
在 C1–C4 完成后，形成一轮能给 Room 1 做 close judgment 的统一验证包。

## 4.5.2 本切片只做什么
1. 主链路统一回归
2. 高风险 truth-boundary case 回归
3. P1 / P2 / B 系列不回归断言
4. 状态文件 / 测试摘要 / round summary / close bar judgement

## 4.5.3 本切片通过标准
1. Option C 进入项都能说明“做了什么 / 没做什么”
2. 最小回归集通过
3. 上游 Pending 没被 Room 4 偷冻结
4. Room 1 能直接判断：close / not close

---

## 5. 推荐 phases（Room 4 version）

Room 4 建议按下面顺序推进：

### Phase C0 — Entry sync / active-version pin check
- 不是实现 phase
- 而是 Room 4 开工前检查：
  1. Room 1 是否已接受 Option C 的 Room 2 / 3 / 5 输入
  2. 当前 active versions 是否已 pin
  3. 哪些 very small contract clarification 被接受，哪些没进

### Phase C1 — Today CTA winner
- 对应 Slice C1
- 当前第一优先级

### Phase C2 — Review continuation / minimal review boundary
- 对应 Slice C2
- 当前第二优先级

### Phase C3 — Stats minimal spec
- 对应 Slice C3
- 当前第三优先级

### Phase C4 — Streak truth-boundary hardening
- 对应 Slice C4
- 当前第四优先级
- 重点是守边界，不是切 basis

### Phase C5 — Test & closeout
- 对应 Slice C5
- 最后一轮统一收口

---

## 6. Room 4 blocker list

## 6.1 Hard blockers
以下情况，Room 4 应阻塞，而不是补脑推进：

### B-OC-001
**Room 1 未 pin Option C 当前 active input**
- 若 `BR-OPP-001_v0.1.7.md`
- 或 `UI_SPEC_OptionC_MainMechanism_v0.1.1.md`
- 或 Room 2 的 very small contract clarification 是否进入  
仍未被 Room 1 明确 pin，Room 4 不应把 candidate input 当成 runtime active truth。

### B-OC-002
**实现切片依赖新聚合块，但 Room 1 未 pin 该 patch**
例如：
- `today_primary_action`
- 更稳的 `review_group` readiness / progress summary
- minimal stats summary contract  
若这些没被 pin，就不能按“它已经存在”来写实现。

### B-OC-003
**上游 Frozen / Pending 边界再次漂移**
若 Room 3 / Room 5 / Room 2 对以下口径重新冲突：
- CTA winner
- `本组完成 ≠ 今日完成`
- `学习天数 = learning_day`
- `streak` 当前 basis = check_in  
Room 4 应先阻塞，等待 Room 1 收敛。

## 6.2 Non-blocking issues
### NB-OC-001
独立完整统计页是否进入  
- 若未 pin，Room 4 不应把它当 blocker
- 可先按 summary-first 路径推进

### NB-OC-002
future streak basis switch  
- 当前只是方向问题
- 不阻塞本轮 Option C

---

## 7. Test entry（Room 4 version）

## 7.1 测试入口总览
Room 4 建议按四层建测试入口：

### A. Today / CTA 层
- Today page widget / integration tests
- CTA winner state matrix tests
- fallback / loading / empty / error tests

### B. Review continuation 层
- active `review_group` continuation tests
- group completion vs daily review completion tests
- next group readiness boundary tests
- review priority 主因子路径 tests

### C. Stats / streak truth-boundary 层
- `学习天数 = learning_day`
- `check_in ≠ learning_day`
- `learning_day ≠ streak switch`
- summary-first stats display tests

### D. Full regression 层
- 新词学习
- 复习
- Session
- 主机制结算
- 副机制承接
- P2 secondary core loop smoke
- Option B / B2 visible behavior smoke

---

## 8. 哪些边界最容易出错（Room 4 risk map）

### R-OC-001 CTA 被 UI 自己补脑
表现：
- 只因有 active `review_group_id` 就强推 continuation
- 或前端自己拼出 winner 结论

### R-OC-002 `本组完成` 被错误写成 `今日复习完成`
这是主机制最容易“看起来对、其实错”的点。

### R-OC-003 `签到成功` 被误写成 `learning_day 成立`
这是统计页、Today、结果反馈中最容易越界的点。

### R-OC-004 Session 状态被写厚
- `started`
- `ended`
- `valid`
- `invalid`
若 UI 文案不稳，很容易重新混掉 `session_validation_status`。

### R-OC-005 Statistics 被偷做厚
最常见风险不是做不出来，而是：
- summary-first 被误做成完整统计页
- 或把 `check_in` / `streak` 混写成学习结果

### R-OC-006 Future stance 被误实现成 current fact
特别是 `streak` future basis：
- 最容易在 UI copy / stats copy / helper wording 中被提前“实施”。

---

## 9. Minimal regression set（Room 4 最小回归集）

Room 4 建议：只要下面这组通过，就能证明 Option C 没把 P1 / P2 / B 系列主闭环打坏。

### RG-OC-001 Today single-strong-CTA
1. 无 active group、无高优先复习 → 新词 CTA
2. 有 active group → continuation CTA
3. 无 active group、但有后端确认待复习 / 高优先复习 → review CTA
4. Session 仅在辅助区，不抢主 CTA

### RG-OC-002 review group truth-boundary
1. 本组完成后，只推进今日复习进度
2. 今日复习未整体满足时，不显示今日完成
3. 同组 continuation 不被重复结算

### RG-OC-003 check_in / learning_day / streak boundary
1. 仅签到成功，不显示“完成有效学习日”
2. 仅 learning_day 成立，不显示“按学习日延续 streak”
3. stats 中“学习天数”只按 learning_day

### RG-OC-004 Session boundary
1. started / ended 但未 valid 时，不显示“有效 Session 完成”
2. valid session 会正确进入主机制结果感，但不改写今日目标口径

### RG-OC-005 P1/P2/B smoke
1. 新词学习主链路可跑
2. 复习主链路可跑
3. 主机制结算可跑
4. Meow Home / secondary summary / existing Option B/B2 visible enhancements 不被打坏

---

## 10. Close bar proposal（Room 4 version）

Room 4 建议的 Option C close bar：

### CB-OC-001
Today 页始终只有一个最强主 CTA，且不靠前端私判最终业务事实。

### CB-OC-002
active `review_group` continuation-first 成立，且 `本组完成 ≠ 今日复习完成` 被实现和测试守住。

### CB-OC-003
statistics 若进入，只做到 summary-first；`学习天数 = learning_day` 被写硬。

### CB-OC-004
`check_in` / `learning_day` / `streak` 三类事实的当前 frozen 关系，在文案、状态、实现、测试中一致。

### CB-OC-005
未被 Room 1 pin 的 future contract / future switch / complete algorithm，Room 4 没有偷实现。

### CB-OC-006
最小回归集通过，且 P1 / P2 / B 系列主副机制闭环无明显回退。

---

## 11. Room 4 推荐的正式交付物

如果 Room 1 接受本稿作为 Option C Room 4 入口，后续建议使用这些文件：

1. `R4_OptionC_Preflight_Implementation_Plan_v0.1.md`  
   - 当前文件

2. `R4_OptionC_Test_Entry_v0.1.md`  
   - 由当前 plan 拆出更细测试入口

3. `OptionC_phases.md`  
   - 把 C1–C5 进一步拆成给 Cursor 的 phase map

4. `R4_OptionC_Status_v0.1.md`  
   - 真正进入执行后使用

5. `R4_OptionC_Test_Summary_v0.1.md`  
   - 执行后的统一测试摘要

---

## 12. Room 4 最终一句话

> **Option C 现在已经到了 Room 4 可以正式建 implementation slices 和 test entry 的时点；但 Room 4 仍必须继续服从“active versions 由 Room 1 pin、Pending 不得自行实现”的项目纪律。**

更直白一点：

> **现在可以规划，可以切批，可以建回归；但不能把还没 pin 的东西写成“已经存在”。**
