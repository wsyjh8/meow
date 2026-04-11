# R2_P3_3_1 PreviewDurations and FSRS Bridge Tech Note v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** technical closeout input / ready for Room 1 absorption
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Runtime basis:** `Main_updated_2026-04-10_v19.md` + `STATUS_updated_2026-04-10_v18.md`
- **Direct upstream input:** `R1_P3_3_1_ScopePin_and_Unified_Execution_Entry_v0.1.md`

---

## 0. 文档目标

本稿只做两件事：

1. 作为 **Room 2 的技术拍板输入**，回答 `previewDurations` 是否适合进入当前 active contract；
2. 给出 **ReviewPage FSRS bridge** 在 P3.3.1 本轮应清理到哪一层，以及 Room 4 后续执行时的技术护栏。

本稿不是：
- 新 DB / API 基线重写稿
- Room 4 的实现 patch
- Room 3 的 wording / rules note
- Room 5 的 UI polish delta

一句话：

> **P3.3.1 在 Room 2 视角是“收尾补强轮”，不是“再开一轮新的主契约扩张”。**

---

## 1. 输入依据

### 1.1 当前推进层 / 治理层基线
- `Main_updated_2026-04-10_v19.md`
- `STATUS_updated_2026-04-10_v18.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `ORG_v0.3.1.md`

### 1.2 当前 active runtime basis
- `BR-OPP-001_v0.2.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`
- `UI_SPEC_v0.2.1.md`

### 1.3 P3.3 / P3.3.1 直接相关输入
- `R1_P3_3_ScopePin_and_Handoff_Pack_v0.1.md`
- `R1_P3_3_1_ScopePin_and_Unified_Execution_Entry_v0.1.md`
- `BR-OPP-001_v0.2.2.md`
- `UI_SPEC_v0.2.2.md`
- `R4_P3_3_Impact_Map_v0.1.md`
- `R4_P3_3_Submit_Flow_Draft_v0.1.md`
- `R4_P3_3_Session_Entry_Draft_v0.1.md`
- `R4_P3_3_Test_Draft_v0.1.md`

---

## 2. Room 2 总判断

### 2.1 结论总览

Room 2 对 P3.3.1 的技术结论如下：

1. **`previewDurations`：本轮不进入 active contract，结论 = deferred**
2. **ReviewPage FSRS bridge：本轮目标不是升格为强合同，而是从“静默 best-effort”清理到“guard / init / fallback 的可控 best-effort”**
3. **本轮不改 DB schema，不扩 API schema，不改 `review_group` 最小合同，不改 planner owner**
4. **本轮允许的实现，必须保持 Room 4 可以在不猜测新产品事实的前提下做补强；不允许借体验补强把系统偷改成“完整 FSRS 产品”**

### 2.2 Room 2 一句话立场

> **本轮优先消除误导和隐性风险，不优先引入新的跨层契约。**

---

## 3. 当前技术现实（Room 2 视角）

### 3.1 双真相层现实仍然成立
当前 active v0.2.1 下，系统已经是明确的 dual-store / dual-truth 分工：

- **StudyPage 相关 FSRS 调度、review logs、部分运行态 = 本地 truth**
- **today 聚合、`review_group`、奖励、结算 = 云端 truth**

### 3.2 P3.3 第一拍没有改动这些主边界
P3.3 第一拍只接入了：
- 首页“背单词”入口
- Study / Review 4 按钮 rating input
- 最小 submit / throttle / bridge

P3.3 第一拍**没有**：
- 扩 API schema
- 改 `review_group` 最小合同
- 改奖励 / 结算主链路
- 把本地 FSRS 提升成 ReviewPage planner owner

### 3.3 ReviewPage 当前仍是 cloud-first
ReviewPage 目前继续：
- 由 `review_group` 提供主队列
- 先云端 `submitReviewAttempt()`
- 再做本地 FSRS `rateCard()` side-effect
- 当前 bridge 失败仍是 non-blocking / best-effort

---

## 4. `previewDurations` 是否进入 active contract

## 4.1 Room 2 结论

> **结论：`previewDurations = deferred`（本轮不进入 active contract）**

### 4.1.1 为什么不是 `in`
`previewDurations` 当前不适合进入 active contract，原因不是它没价值，而是它在当前技术现实下**没有稳定、单一、跨页一致的数据来源**：

1. **StudyPage 与 ReviewPage 的主真相层不同**
   - StudyPage 更接近 local FSRS 侧的本地写入
   - ReviewPage 仍以云端 `review_group` 为主真相层

2. **ReviewPage bridge 仍未收口到稳定解释源**
   - 当前本地 FSRS 只是在云端提交后做 side-effect
   - 现状里，bridge 失败可以 non-blocking 通过
   - 在这种前提下，任何把 interval preview 写成“当前稳定 contract”的做法，都会把本地计算结果误包装成跨层稳定事实

3. **active DB / API baseline 当前没有正式 `previewDurations` 合同**
   - 本轮 Room 1 明确要求先决定它是否进入 active contract
   - 但从 Room 2 角度看，当前并没有足够稳定的 DB / API / planner owner 事实支持它直接升格

4. **它天然更像解释性 UI hint，不像当前轮必须 pin 的核心 contract**
   - 若强行升格，会诱导 Room 4 和 Room 5 继续向下补脑：
     - 是本地算的，还是后端给的？
     - Study / Review 是否同一算法来源？
     - preview 是否代表后端最终安排？
   - 这些都超出了本轮 scope

## 4.2 Room 2 对 `previewDurations` 的正式表述

本轮对 `previewDurations` 的正式技术表述应为：

- 它当前是 **candidate experience enhancement**
- 它当前**不是 active DB / API / review contract**
- Room 4 不得因为本轮体验补强，就自行定义跨页统一的 `previewDurations` 数据源
- Room 5 可以继续对其做体验层建议，但不能把它写成“系统已稳定提供的解释字段”

## 4.3 本轮允许与不允许

### 允许
1. 在 Room 1 后续统一吸收时，将其保留为 **deferred item**
2. Room 5 在 UI delta 中对其做“若未来进入时”的预留表达建议
3. Room 4 在未来独立 round 中，基于新的 Room 1 pin 再做专项实现

### 不允许
1. 不允许在 P3.3.1 中把它写进 active API contract
2. 不允许在 P3.3.1 中把它写进 active DB contract
3. 不允许让 ReviewPage 用当前 best-effort bridge 结果去展示“下次多久后复习”的稳定事实
4. 不允许把 preview 文案写成后端已确认结果

## 4.4 Room 1 可直接吸收的决策句

> **Room 2 judgment：`previewDurations` 当前仍应保持 deferred；本轮不进入 active contract。原因是当前 Study / Review 双真相层未统一、ReviewPage FSRS bridge 仍在收尾补强阶段，技术上不足以支持把 preview 升格为稳定合同。**

---

## 5. ReviewPage FSRS bridge 本轮清理上限

## 5.1 Room 2 结论

> **结论：本轮把 ReviewPage FSRS bridge 从“静默 best-effort”提升到“guard / init / fallback 的可控 best-effort”；不提升为强合同。**

这意味着：
- **不是**继续完全放任 silent bridge drift
- **也不是**把本地 FSRS 提升成 ReviewPage 的强依赖

本轮技术上应清理到以下层级：

1. **Guard**
   - 明确 ReviewPage 只有在 cloud submit 成功后，才允许进入本地 bridge
   - 不允许本地 bridge 先于 cloud submit

2. **Init**
   - 允许补充对本地卡状态的 idempotent init / ensure 逻辑
   - 目标是减少“因为本地没有 card row 导致的无意义 bridge 失败”

3. **Fallback**
   - 若 bridge 仍失败，必须继续保持 non-blocking，不影响：
     - `review_group` continuation
     - group completion
     - settlement 既有流程
   - 但不应再是“完全无痕、完全无界限”的 silent drift；至少应进入可调试、可观测、可测试的 fallback 语义

## 5.2 为什么本轮不能升成更强 contract

因为一旦升到更强 contract，就会触碰以下越界点：

1. **planner owner 问题**
   - ReviewPage 谁是最终 planner owner 仍未拍板
   - 若 bridge 变成 must-succeed，就会实质上提升本地 FSRS 权重

2. **`review_group` 最小合同问题**
   - 当前 `review_group` 仍是主队列 / 主真相层
   - 强行提升本地 bridge，会模糊主从关系

3. **active contract 扩张问题**
   - 如果要求 ReviewPage 每个词都必须存在本地完整 FSRS state，Room 4 很容易继续补出新的 DB / API / preload / sync 假设
   - 这会越出 P3.3.1 的收尾补强范围

## 5.3 Room 2 推荐的本轮清理目标

### 推荐目标：Controlled Best-Effort Bridge

技术上定义为：

1. **Cloud-first remains hard rule**
   - `submitReviewAttempt()` 仍是主写入
   - 云端成功后才进入本地 side-effect

2. **Idempotent local ensure allowed**
   - 允许在 ReviewPage bridge 前增加 `initCardForWord()` 或等价 ensure-local-card-state 逻辑
   - 该逻辑必须是 idempotent
   - 它的目标是减少 bridge miss，不是改 planner owner

3. **Local failure remains non-blocking**
   - 本地 bridge 失败不得回滚已成功的 cloud submit
   - 不得阻断 next item / group completion / settlement flow

4. **Failure must become observable to dev / test**
   - 可以通过 debug log、diagnostic counter、testable fallback branch 等方式保留可观察性
   - 但不要求把它抛成 user-facing error

5. **No user-facing false fact**
   - 无论 bridge 成功或失败，都不得产生“已掌握 / 已完成 / 奖励到账 / 已重排完整计划”等结果事实文案

---

## 6. 允许的最小技术改动 vs 不允许触碰的边界

## 6.1 本轮允许的最小技术改动

以下变更，Room 2 视为 **P3.3.1 可接受范围内的最小技术改动**：

1. ReviewPage 本地 bridge 前增加 **idempotent local init / ensure**
2. 对 bridge failure 增加 **可调试、可测试的 fallback 语义**
3. 保持 cloud submit → local side-effect 的顺序不变
4. 增加不改变对外 contract 的局部 guard / null-check / defensive handling
5. 为本轮测试补强补充 bridge 成功 / 失败 / fallback 的更明确验证点

## 6.2 本轮不允许触碰

以下内容，Room 2 明确列为 **本轮禁止触碰**：

1. **DB schema 改动**
2. **API schema 改动**
3. **`review_group` 最小合同改动**
4. **planner owner 改动**（云端 vs 本地谁主导）
5. **把 Study / Review 合并成统一学习页**
6. **引入新的 sync / preload / backfill 叙事**
7. **把 `previewDurations` 偷升格为 active contract**
8. **让本地 bridge 成为 group completion / settlement 的前置成功条件**

---

## 7. Minor / Major 判断（Room 2 v0.2.1 对齐）

## 7.1 本轮可视为 Minor Change 的内容

只要同时满足“不改业务语义 / 不破坏 consumer / 不需要 migration / 不改变 Room 3 规则落点与 Room 5 页面事实口径”，下列可归为本轮 Minor：

1. ReviewPage 本地 `initCardForWord()` / ensure-row 的补充
2. bridge fallback 的局部日志 / debug 标记 / 防御式分支
3. 不改 payload 语义的 test hook / test branch 补强
4. 不改 contract 的 UI 提示删除 / 防误报文案补强

## 7.2 一旦发生就越界成 Major 的内容

以下内容一旦发生，默认转为 **Major**，不属于本轮 Room 4 可自行补的范围：

1. 新增或修改对外 API 字段承诺，给 `previewDurations` 正式 contract 位
2. 新增或修改 DB 实体 / 关系 / 必填状态，使 ReviewPage 依赖新的本地 planner 表达
3. 改变 `review_group` 的用途、主从关系或 completion 判定
4. 把 bridge 从 side-effect 提升为 must-succeed contract
5. 把本地 FSRS due / queue 接到 ReviewPage 主入口
6. 把本地 preview 结果暴露成用户可理解为“系统最终安排”的事实性文案

---

## 8. 给 Room 4 的后续实现护栏（待 Room 1 吸收后再下发）

若 Room 1 接受本稿，Room 4 后续执行时，Room 2 建议采用以下实现护栏：

1. **先不做 `previewDurations`**
   - 本轮 execution handoff 中直接标记为 deferred

2. **ReviewPage bridge 做到 controlled best-effort 即止**
   - 先云端提交
   - 再本地 ensure + rate
   - 失败 non-blocking
   - 增加可测 fallback

3. **不要把 bridge 成败带入用户层结果文案**
   - 用户只看到复习继续 / 本组完成 / settlement 等当前已有真实反馈
   - 不要出现新的“计划已更新”“间隔已重算成功”等事实型提示

4. **测试补强优先覆盖以下分支**
   - ensure row already exists
   - ensure row newly created
   - local bridge success
   - local bridge failure but cloud success
   - fallback branch observable but non-blocking

---

## 9. Room 1 可直接吸收的结论

### 9.1 关于 `previewDurations`
> **Room 2 judgment：本轮 `previewDurations` 不进入 active contract，结论为 deferred。**

### 9.2 关于 ReviewPage FSRS bridge
> **Room 2 judgment：本轮 ReviewPage FSRS bridge 的技术清理上限为 `guard / init / fallback` 的 controlled best-effort，不升格为更强 contract。**

### 9.3 关于执行边界
> **Room 2 judgment：本轮允许 Room 4 做局部 defensive cleanup 与测试补强；不允许触碰 DB / API / `review_group` / planner owner 的主契约。**

---

## 10. 一句话结论

> **P3.3.1 在 Room 2 视角应按“defer new contract, stabilize bridge boundary”推进：`previewDurations` defer，ReviewPage bridge 收到 controlled best-effort 为止。**
