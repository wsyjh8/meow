# OPP-001 / 背单词喵喵 App — Room 4 → Cursor
# P3 Phase 4 — Streak Decision Preparation Handoff v0.1

- **From:** Room 4 (Eng + QA + Debug Tech Lead)
- **To:** Cursor
- **Date:** 2026-04-05
- **Phase:** P3 / Phase 4
- **Execution mode:** small / careful boundary-hardening round
- **IMPORTANT:** 你读不到我们项目文档；本 handoff 已补齐你执行本轮所需的边界、目标、禁止项和完成标准。

---

## 0. 你现在所处的项目上下文

这是一个 **学习驱动型轻养成 App（背单词 + 喵喵陪伴）**。
当前主线程是：

> **P3 — Main Mechanism Deepening**

Room 4 已把 P3 拆成 5 个 phase：
1. Phase 0 — Guard / Fallback / Test Seam
2. Phase 1 — CTA Deepening
3. Phase 2 — Review Structured Deepening
4. Phase 3 — Statistics Decision Path
5. **Phase 4 — Streak Decision Preparation**

本轮只做 **Phase 4**。

---

## 1. 这轮的核心目标

本轮 **不是** 切换 streak 口径。
本轮只做：

> **在不改变 current runtime truth 的前提下，把 streak 相关的展示边界、copy 边界、feature seam、test seam 做硬。**

一句话：

> **让系统对“未来可能改按 learning_day 或组合条件计算 streak”这件事有准备，但当前产品继续稳定地按 `check_in` 展示与计算 streak。**

---

## 2. 当前 frozen truth（必须严格服从）

当前项目里，以下都已经是 frozen truth：

1. `check_in`、`learning_day`、`streak` 是 **三类独立事实**。
2. 当前 MVP 下，`streak_basis_type = check_in`。
3. `check_in=true` **不自动等于** `learning_day=true`。
4. `learning_day=true` **不自动等于** streak 延续。
5. UI / copy **不得** 把当前 streak 写成“按学习日计算”。
6. UI / copy **不得** 暗示“即将改按学习日计算”，除非本轮有明确、完整、已 pin 的 future explanation contract。
7. 当前没有获准做 basis switch implementation；也没有获准改历史 streak 计算、补签逻辑、迁移策略或用户结算口径。

你必须默认：
- 当前生产真相还是 `check_in-based streak`
- future stance 仍然只是 future stance
- 用户看到的文字必须与 current runtime truth 完全一致

---

## 3. 本轮允许你做什么（In scope）

### 3.1 统一并收硬当前 streak 展示边界
请检查并修正 **Today / summary / 任何当前用户可见的 streak 标签与解释**，确保它们都满足：

- streak 仍按签到事实展示
- 如果同时展示 `learning_day`，两者不能混写
- 不出现“学习日连续”“按学习完成延续 streak”“今天学了所以 streak 必定延续”之类暗示性文案
- 如果当前已有“（基于签到）”或等价标签，保持一致，不要删掉导致语义变模糊

### 3.2 建立未来决策的 UI seam / test seam（不改变当前 truth）
可以做一个很小的、保守的 seam，用于未来可能接 `future streak policy / migration explanation`，但必须满足：

- **默认不显示任何新 explanation**
- 若没有明确完整 contract，UI 必须完全保持当前表现
- seam 的存在是为了未来好接，不是为了本轮提前露出新信息

推荐方式：
- 加一个 feature guard，例如：`P3FeatureGuard.isStreakDecisionPreparationEnabled`
- 加一个严格 optional parse seam（如果当前根本没有对应字段，就不要伪造 payload）
- 所有 absent / invalid / incomplete 情况一律视为：`no future explanation`

### 3.3 收硬 copy boundary / truth boundary regression
补测试，确保：

- 当前 streak 仍按签到口径显示
- `learning_day=true` 但未签到时，不会被文案写成 streak 已延续
- `check_in=true` 但未形成 learning day 时，不会被文案写成“完成了有效学习日”
- absent / invalid future policy seam 时，不会露出“规则将变化”的文案
- 当前 UI 不会出现“即将改按学习日计算”“新 streak 规则”等提前剧透式表达

### 3.4 做一个小的共享显示工具（若项目结构合适）
如果项目里 streak 的显示规则分散，允许你抽一个 **很轻的 shared display helper / formatter**，目的只有一个：

- 统一当前 truth 的展示
- 降低不同页面 future drift 的风险

注意：
- 这是 display helper，不是业务计算器
- 不要在前端自己推导 streak 是否延续
- 不要把 UI helper 做成业务事实判断入口

---

## 4. 本轮禁止你做什么（Out of scope / Forbidden）

### 4.1 绝对禁止
1. **不要切换 `streak_basis_type`**
2. **不要把 streak 从 `check_in` 改成 `learning_day`**
3. **不要改历史 streak 计数**
4. **不要加补签逻辑**
5. **不要改后端 streak 生产计算口径**
6. **不要把 future stance 写成 current fact**
7. **不要新增“用户现在按学习日连签”的任何文案或 UI**
8. **不要因为“为了未来更优雅”就先加 fake contract / dummy payload / 假字段**

### 4.2 本轮也不要顺手做
1. 不扩写 statistics page
2. 不回改 CTA
3. 不回改 review_summary
4. 不做新 route / 新一级导航
5. 不做 DB / API 主结构改写
6. 不做大范围 copy 重写；只改 truth boundary 相关表达

---

## 5. 推荐实现方式（保守路径）

### Step A — 先做 UI / copy audit
找出当前所有显示 streak / learning day / check-in 的用户可见点，重点看：
- Today 页
- 统计 summary（如果当前已有）
- 签到区块 / streak 简报
- 任何包含“连续”“坚持”“学习日”的提示文字

把它们统一到当前 frozen truth：
- streak = 签到口径
- learning_day = 独立学习事实
- 两者不互推

### Step B — 只建立 very small seam
如果你判断值得做 future seam，请只做 very small 级别：
- feature guard
- optional parser
- null-safe rendering path
- 默认隐藏

没有明确 contract 时，**不要** 造结构体和伪数据把页面先跑起来。

### Step C — 补回归
至少补以下测试：

#### UI / parsing / guard tests
1. 当前 streak 标签仍保持签到口径
2. `learning_day=true` 但 `check_in=false` 时，不出现“streak 延续”文案
3. `check_in=true` 但 `learning_day=false` 时，不出现“已完成学习日”文案
4. future explanation seam absent → 不展示任何未来规则说明
5. future explanation seam invalid / incomplete → 不展示
6. feature flag off → 不展示任何新 explanation

#### Regression / truth-boundary tests
7. Phase 1 CTA 不受影响
8. Phase 2 review_summary 不受影响
9. Phase 3 statistics 当前 summary-first 行为不受影响
10. 现有“(基于签到)”或等价 truth-label 不回退成模糊表达

---

## 6. 完成标准（Completion bar）

本轮只有在以下全部满足时，才算完成：

1. **Current truth 不变**：运行时 streak 仍然按 `check_in` 口径展示与消费
2. **用户不被误导**：没有任何 UI / copy 暗示“现在已按学习日算 streak”
3. **未来 seam 是保守的**：没有 fake contract / dummy payload / 假页面
4. **测试到位**：新增 regression 覆盖 truth boundary
5. **不打扰其他 phase**：CTA / Review / Statistics 行为不被回退或污染

如果你完成后发现：
- 需要新 API contract 才能继续
- 需要改后端 streak truth 才能继续
- 需要新增独立页面才说得清

那么请停下，并明确把它记为：

> **Blocked by new active contract / out of current phase scope**

不要自己往下扩。

---

## 7. 交付格式（必须按这个回）

请按以下结构回复：

### 7.1 Code summary
- 改了哪些文件
- 每个文件做了什么
- 为什么这轮这样改

### 7.2 Behavior summary
- 当前 streak 如何显示
- learning_day / check_in / streak 的边界如何被保护
- future seam 在 present / absent / invalid 时分别怎么表现

### 7.3 Test summary
- 跑了哪些测试
- 新增了哪些测试
- 总通过数
- analyze / lint 状态

### 7.4 Risk / follow-up
- 当前还剩什么非阻塞问题
- 如果未来真的要切 basis，需要新增什么 contract / decision
- 哪些点你刻意没做，以避免越界

---

## 8. 给你的最终一句执行令

> **把 streak 的当前真相守住，把未来切换的边界守住，把测试补足；不要提前切，不要提前说，不要提前暗示。**

