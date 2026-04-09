# OPP-001 / 背单词喵喵 App — Room 4 → Cursor Handoff
# P3 Phase 0 Implementation Instruction v0.1

- **From:** Room 4（Eng + QA + Debug Tech Lead）
- **To:** Cursor
- **Date:** 2026-04-05
- **Phase:** P3 / Phase 0 — Baseline-safe Entry / Guard / Test Seam
- **Status:** executable handoff
- **You must assume:** 你**看不到**项目文档；本指令已把你本轮需要知道的事实、边界、目标、禁止项、交付要求写全。

---

## 0. 你这轮到底要做什么

你这轮**不是**去实现 P3 的 CTA 深化、Review 深化、Statistics 独立页、或 Streak basis 切换。

你这轮只做：

> **为 P3 后续阶段建立一个“安全入口层”**：guard、fallback、test seam、contract-absence regression、feature / route / render protection。

一句话：

> **先把“未 pin contract 时系统仍然安全、稳定、不误导”的工程挡板搭好。**

---

## 1. 项目背景（你必须知道）

这是一个 **学习驱动型轻养成 App**。
主线是：
- 今日页
- 新词学习
- 复习
- Session
- check-in / streak
- 主机制结算

副线是喵喵承接，但这轮不是副机制主线开发。

当前项目已经完成：
- P1 主机制最小闭环
- P2 副机制 MVP 承接
- Option A / A.1 persistence hardening
- Option B / B2 polish
- Option C 主机制最小增强收口

现在正式进入：

> **P3 — Main Mechanism Deepening**

但 P3 当前仍是：

> **contract-first**

意思是：
- 当前已经有一批 P3 输入文档
- 但这些输入**还不等于全部 runtime active truth**
- Room 1 还没有把所有 P3 candidate contract 全部 pin 成 active baseline

所以：

> **你现在不能因为页面或代码结构看起来“应该有”，就提前把候选字段、候选路由、候选状态实现成事实。**

---

## 2. 当前必须服从的 active truth（你本轮只能建立在这些之上）

### 2.1 事实边界
以下事实继续成立，不能被你改写：

1. **学习优先，副机制承接**。
2. **主机制事实以后端为准**，前端不能自行推导最终业务真相。
3. `daily_goal_status` 不包含 Session，也不包含签到。
4. `session_validation_status` 只有满足已冻结 MVP 条件才算 `valid`。
5. 主机制结算层与副机制承接层边界不能回退。
6. `review_group` 最小业务合同已经存在，且：
   - active group continuation-first
   - 本组完成 ≠ 今日完成
7. 当前 MVP 下：
   - `check_in`
   - `learning_day`
   - `streak`
   是三类独立事实。
8. 当前 `streak` 仍按 **check-in** 延续。
9. Option C 已冻结最小层不能回退：
   - Today 单一最强主 CTA
   - continuation-first
   - statistics 默认 `summary-first`
   - future streak 只能记录方向，不能写成当前已切换

### 2.2 你必须当作“尚未 pin，不得假设存在”的候选项
以下都视为 **candidate / pending / decision-support only**：

1. `today_primary_action` 或等价 CTA decision-support block
2. 更细的 `review_summary` / readiness contract
3. statistics 独立 minimal page contract
4. future streak decision-support / migration-support fields
5. 更完整的 CTA reason / priority band / blocking helper 全集
6. 更深 review priority / 完整 SRS / 分组算法细节

原则：

> **未 pin = 按 absent 处理。**

---

## 3. 你本轮的目标（Phase 0 scope）

### 3.1 核心目标
在**不改变 runtime truth** 的前提下，完成以下 5 类工作：

1. 建立 **contract present vs contract absent** 的工程与测试双路径
2. 建立 **fallback-safe** 行为
3. 建立后续 P3 Phase 1–4 可复用的 **test seam / harness / fixture strategy**
4. 建立 **feature / route / render / selector guard**
5. 建立 **regression fences**，确保未 pin 的候选 contract 不会被误实现成当前事实

### 3.2 你本轮产出应该解决什么风险
你要优先拦住这些风险：

1. 因为 UI 需要，提前本地生成候选字段
2. 先开独立 statistics route / shell page / 一级导航占位
3. 用 remaining count 或本地 selector 推导 readiness / today completion
4. 把 future streak stance 写成 current truth
5. contract 缺失时页面崩溃、误导、或 silently degrade 成假成功

---

## 4. 这轮允许做什么（In scope）

### A. Guard / fallback / seam 层
你可以做：

1. 为候选 contract 建立统一读取入口
   - 允许做 “存在则使用，不存在则回退” 的 adapter / selector / normalization seam
   - 但**不能伪造缺失数据**

2. 建立 contract absence fallback
   - CTA 相关：缺少新 decision-support block 时，必须回退到当前 active Option C 行为
   - Review deeper state：缺少更细 summary / readiness contract 时，必须回退到当前 active review group 表达
   - Statistics：缺少独立页 contract 时，只能维持 `summary-first`
   - Streak：缺少 future decision-support 时，只能保持 current check-in-based truth

3. 建立 feature / route / render guard
   - 禁止未 pin contract 时渲染更深模块
   - 禁止未 pin 独立 statistics page 时开放 route / 一级导航 / page-level regression target
   - 禁止未 pin future streak switch 时启用任何 basis-switch UI

4. 建立 selector / parser / renderer 的边界保护
   - absent / partial / delayed / unknown payload 时页面不能崩
   - 未知字段不得默认解释为“已完成 / 已可用 / 已切换”

### B. 测试与回归层
你可以做：

1. 建立统一 fixture / factory / helper
   - current active baseline fixture
   - candidate contract absent fixture
   - partial payload fixture
   - delayed / degraded / fallback fixture

2. 建立测试断言，至少覆盖：
   - contract absent 时安全回退
   - current truth 与 future candidate path 严格分离
   - `summary-first` 不被独立页实现偷穿
   - `streak current truth vs future explanation` 不混写
   - `active_group_completed` 不自动等于 `daily_goal_status=completed`
   - `check_in` / `learning_day` / `streak` 不混写

3. 为后续 phases 预留统一 test seam
   - 不要求实现 P3 feature
   - 但要让后续 phase 能在统一 seam 上扩展，不重复造轮子

### C. 代码结构层
你可以做：

1. 提炼守卫函数 / helper
2. 提炼 fallback-safe selector / adapter
3. 提炼 render gating / feature gating
4. 调整测试目录、测试工具、fixture 组织方式
5. 在不改变 truth boundary 的前提下做小范围重构，以减少后续 phase 的 implementation risk

---

## 5. 这轮明确禁止什么（Hard no）

以下任何一项都**不要做**：

1. **不要实现 `today_primary_action`**
2. **不要本地生成 CTA winner 的最终业务判断**
3. **不要实现 deeper `review_summary` 真逻辑**
4. **不要用 remaining count 推导 readiness / next-group availability / today review completion**
5. **不要新增 statistics 独立 route / 一级导航 / 空页面壳**
6. **不要把 `learning_day` 写成当前 streak 依据**
7. **不要改 streak runtime truth**
8. **不要写“即将改按学习日算”这类超前文案逻辑**
9. **不要造 fake contract / dummy payload / hard-coded placeholder field 来让 UI 看起来完整**
10. **不要因为 Phase 0 是基础设施轮，就顺手混入 Phase 1–4 的 feature implementation**
11. **不要把任何 candidate input 当成 active baseline**
12. **不要新增会改变业务语义的逻辑分支，但没有对应 regression 与测试**

如果你发现某个实现动作已经需要：
- 新业务字段
- 新 API 语义
- 新 route
- 新 page contract
- 新 truth boundary

请立刻停止该部分，把它留在注释 / TODO / follow-up note 中，不要偷做。

---

## 6. 你应该怎样做（推荐执行顺序）

### Step 1 — 先盘点当前代码里哪些位置最容易误把 candidate 当 truth
请检查至少这些点：

1. Today CTA 选择逻辑
2. Review summary / readiness / progress 展示逻辑
3. Statistics 入口、route、page 渲染逻辑
4. Streak / learning_day / check_in 展示逻辑
5. 任何会因为字段“看起来可能会来”而提前分支的 selector / parser / component

### Step 2 — 补 guard，而不是补 feature
你的优先目标不是“把 UI 做得更完整”，而是：
- contract absent 时不崩
- absent 时不误导
- absent 时稳定回退到当前 active Option C baseline

### Step 3 — 先建测试，再允许小范围结构整理
若某块逻辑太散，允许你做小范围重构，但前提是：
- 重构目的是更清楚地建立 guard / seam / fallback
- 不是为了偷接未来 feature

### Step 4 — 输出清楚的后续 phase 接口点
本轮最后，请给 Room 4 留一个简短 follow-up note：
- 哪些 seam 已准备好
- Phase 1（CTA）后续应该接哪里
- Phase 2（Review）后续应该接哪里
- Phase 3（Statistics）后续应该接哪里
- Phase 4（Streak）后续应该接哪里

---

## 7. 建议你重点覆盖的测试断言

至少要有这些测试：

### 7.1 CTA / Today fallback
1. candidate CTA contract 缺失时，Today 仍按当前 active Option C 规则工作
2. 不存在双主 CTA
3. active review group continuation 相关现有行为不回退

### 7.2 Review truth boundary
1. `active_group_completed=true` 不自动变成 `daily_goal_status=completed`
2. 缺失 readiness contract 时，不会用 local remaining 自行推导“下一组可用”
3. 当前 review group 边界行为不被 Phase 0 破坏

### 7.3 Statistics boundary
1. 未 pin 独立页 contract 时，仍然只走 `summary-first`
2. 没有 route / 一级导航 / page-level shell 被提前打开
3. delayed / absent stats 时有 fallback，但不误导成 fresh truth

### 7.4 Streak boundary
1. 当前 streak 仍按 check-in 展示
2. `learning_day` 与 `streak` 不混写
3. future stance 若有展示入口，只能是解释边界，不得暗示已切换

### 7.5 Contract absence robustness
1. payload 缺字段时不 crash
2. unknown / partial payload 时不展示假完成态
3. degraded / delayed / absent 时不 silently fake success

---

## 8. 交付物要求（必须一起交）

你完成后，必须一次性交这些内容：

### 8.1 代码
- Phase 0 相关代码改动
- 只限 guard / fallback / seam / regression support / test harness

### 8.2 测试
- 新增或更新的测试
- 你跑过的测试命令
- 测试结果摘要

### 8.3 变更说明
请按这个格式给我：

#### A. Summary
- 这轮做了什么
- 没做什么
- 为什么没做

#### B. Files changed
- 文件路径列表
- 每个文件一句说明

#### C. Guardrails added
- 新增了哪些 guard / fallback / seam

#### D. Tests
- 新增 / 更新了哪些测试
- 跑了哪些命令
- 结果如何

#### E. Explicit non-goals respected
- 明确列出你没有越界做的点

#### F. Follow-up handoff
- Phase 1–4 后续从哪里接最稳

---

## 9. 代码风格与实现纪律

### 9.1 优先级
优先顺序是：
1. 不误导
2. 不崩
3. 回退正确
4. 测试可覆盖
5. 结构清楚
6. 再谈未来扩展性

### 9.2 实现风格
- 倾向于小而硬的 guard
- 倾向于明确的 fallback 分支
- 倾向于可以直接断言的 selector / adapter / helper
- 不要写“为了以后可能有用”的大抽象
- 不要为了“优雅”牺牲清楚

### 9.3 关于注释
对所有可能被误解成“未来 feature 已经接上”的地方，请加短注释，明确：
- 这是 Phase 0 seam / guard
- 不是 active contract implementation

---

## 10. 你完成本轮的判定标准（Completion bar）

只有同时满足以下条件，这轮才算完成：

1. **当前 active Option C 行为不回退**
2. **candidate contract 缺失时系统稳定回退，不崩、不误导**
3. **没有偷实现新 route / 新 contract / 新 truth**
4. **后续 P3 Phase 1–4 已有可复用 seam / harness**
5. **测试能清楚区分 current active baseline 与 future candidate path**
6. **我能从你的交付中一眼看出：Phase 0 做的是“安全入口层”，不是 feature layer**

---

## 11. 给你的最后一句执行总令

> **只按当前 active versions 实现；未 pin 的 contract 一律按 absent 处理；先做 guard / fallback / test seam，再做 feature；不准先开空路由、空页面、假字段。**

