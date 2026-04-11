# R1_P3.3.1 Scope Pin and Unified Execution Entry v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** active / unified execution entry / ready for Room 2 / Room 3 / Room 5 input and Room 4 gated execution
- **Role basis:** `room1_v0.2.0.md`
- **Runtime basis:** `Main_updated_2026-04-10_v19.md` + `STATUS_updated_2026-04-10_v18.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 user 已直接拍板的下一轮 focus：

> **P3.3.1 — 收尾 / 体验补强**

正式收进主线程，并转译成一份 **统一执行入口**，供各 Room 依同一范围、同一缺口、同一验收口径推进。

本文件不是：
- 新 PRD
- Room 2 技术方案正文
- Room 3 BR 正文
- Room 5 UI SPEC 正文
- Room 4 代码执行记录

本文件只做一件事：

> **把 P3.3 First Pass Closed 之后的剩余关键 gap，收口成一轮可分派、可执行、可验收的 P3.3.1 主线程入口。**

---

## 1. 背景

当前推进层 SSOT 已明确：
- P3.3 第一拍已完成收口并通过 Room4-治理验收
- 当前子阶段为 **Stage 4 — P3.3 First Pass Closed / Next-Focus Pending**
- 当前仍挂着 3 个与 P3.3 后续体验收口直接相关的主 gap：
  1. 最终两字中文词面未 freeze
  2. `previewDurations` 仍 deferred
  3. ReviewPage FSRS bridge 仍是 best-effort

user 现直接拍板：
- 开始进行 **P3.3.1**
- 目标是：
  - 收尾 / 体验补强
  - 冻结最终两字中文词面
  - 决定是否补 `previewDurations`
  - 清理 ReviewPage FSRS bridge 的 best-effort 风险
  - 做一轮 UI / 文案 / 测试补强

Room 1 将以上内容吸收为 **P3.3.1 方向拍板输入**。

---

## 2. 当前阶段命名

### Stage naming
- **Current stage:** MVP Readiness
- **Current sub-stage:** Stage 4 — P3.3.1 Scope Pin / Unified Execution Entry

### 一句话定义
> **P3.3.1 的目标，不是重做学习系统，而是在 P3.3 第一拍已经跑通的基础上，把“按钮词面、即时解释性、ReviewPage FSRS bridge 风险、UI/文案/测试完整度”收成更稳的产品可交付状态。**

---

## 3. 本轮范围（In Scope）

### 3.1 最终两字中文词面 freeze
本轮纳入：
1. 冻结 Study / Review 4 按钮的最终两字中文词面
2. 明确最终词面必须满足：
   - 两个字
   - 表达 rating input
   - 不夸大成结果事实
3. 最终 frozen wording 需由 **Room 3 + Room 5** 联合提交，再由 **Room 1** 收口

### 3.2 `previewDurations` 是否纳入 active contract
本轮纳入：
1. 由 Room 2 判断 `previewDurations` 是否适合进入当前 active contract
2. 若纳入，需明确：
   - 它是显示层解释增强，还是 contract-level 稳定能力
   - 是否同时作用于 Study / Review
   - UI 如何表达，测试如何覆盖
3. 若不纳入，需明确 deferred 原因，不让 Room 4 补脑扩写

### 3.3 ReviewPage FSRS bridge 风险清理
本轮纳入：
1. 处理当前 ReviewPage 本地 FSRS bridge 的 best-effort 风险
2. 决定本轮要清理到哪一层：
   - 仅补 guard / init / fallback
   - 还是补更强 contract
3. 明确不能破坏：
   - `review_group` 云端主队列 / 主真相层
   - 现有 review completion / settlement 主链路
   - 当前 DB / API 核心语义

### 3.4 UI / 文案 / 测试补强
本轮纳入：
1. UI polish delta
2. 文案事实边界补强
3. 测试补强与回归补充
4. 防误报边界补强（避免把 rating input 写成 mastery/result fact）

---

## 4. 当前不纳入（Out of Scope）

以下内容 **不因 P3.3.1 自动纳入**：

1. 不重写完整 SRS / 完整复习调度算法
2. 不重做 `review_group` group size / priority / planner owner
3. 不重写 DB schema / API 核心契约
4. 不改 `review_group` 最小合同
5. 不做大规模 IA / Tab / 首页结构重构
6. 不把 Study / Review 直接合并成统一学习页
7. 不把 Session 自动分流 / 自动 session builder 接入写成已冻结事实
8. 不做“完整 FSRS 产品化”叙事

一句话：

> **本轮是“收尾补强”，不是“第二次大扩 scope”。**

---

## 5. 本轮主线程判断

### 5.1 为什么本轮不能直接只交给 Room 4 自行补完
因为这轮用户拍板同时包含：
1. 文案 freeze → Room 3 + Room 5
2. 解释增强 → Room 2 + Room 5
3. bridge 风险策略 → Room 2 + Room 3
4. 测试补强 → Room 4

如果 Room 1 不先统一收口，Room 4 会在以下问题上自行补脑：
- 最终词面到底是哪 4 个字
- `previewDurations` 只是 UI hint 还是 active contract
- FSRS bridge 应该补成“更稳 best-effort”还是“必须成功的更强合同”
- 哪些是本轮必须测，哪些只是 future enhancement

因此本轮正确顺序应为：

> **Room 1 先 scope pin → Room 2 / Room 3 / Room 5 提交专项收口输入 → Room 1 做统一吸收 → 再给 Room 4 下发执行单。**

### 5.2 Room 1 立场
- 已接受 user 对 P3.3.1 的直接拍板
- 已将其定义为 P3.3 第一拍之后的下一推进主题
- 当前 runtime active versions 暂不自动变更
- 先走 P3.3.1 scope pin / cross-room alignment / unified execution entry

---

## 6. 对 STATUS 的影响

### 6.1 本轮直接对准的 gap
P3.3.1 直接对准以下当前 gap：
1. **G-OPP-001-002** — 最终两字中文词面未 freeze
2. **G-OPP-001-003** — `previewDurations` 仍 deferred
3. **G-OPP-001-004** — ReviewPage FSRS bridge 仍是 best-effort

### 6.2 本轮预期结果
若本轮完成，Room 1 预期可达成：
1. 4 按钮 final wording freeze
2. `previewDurations` 明确进入 active contract 或正式 defer
3. ReviewPage bridge 风险清理到本轮 agreed level
4. UI / copy / test 第一轮体验补强完成
5. P3.3 从 “First Pass Closed / Next-Focus Pending” 推进到更稳定 closeout 状态

---

## 7. Room-specific Handoff

## 7.1 Room 3 — Rules / Copy Freeze
### 任务
产出：`R3_P3_3_1_Final_Wording_and_Bridge_Rules_Note_v0.1.md`

### 必做
1. 给出 4 按钮最终两字中文词面建议（最终候选收口版）
2. 明确每个词面是否符合 rating input 事实边界
3. 明确哪些词绝对不能用（因为会夸大成结果事实）
4. 对 ReviewPage bridge 风险给出规则层立场：
   - 本轮是否允许继续 best-effort
   - 若不允许，最低需要提升到什么程度

### Done 定义
> Room 1 能直接据此做 final wording freeze，并判断 bridge 风险在业务语义层是否已足够收口。

---

## 7.2 Room 5 — UI / Copy Polish Delta
### 任务
产出：`UI_SPEC_P3_3_1_Copy_Polish_and_PreviewDurations_Delta_v0.1.md`

### 必做
1. 给出 frozen wording 在 UI 上的最终落位建议
2. 给出 4 按钮文案替换后的页面表达 delta
3. 若 `previewDurations` 适合进入体验层，给出 UI 表达位置与轻量交互建议
4. 做一轮文案 / 防误报 / 低阻力交互补强

### Done 定义
> Room 4 可以据此明确该改哪些 UI 文案、哪些解释 hint、哪些状态边界，而不必自己猜表现层。

---

## 7.3 Room 2 — Tech Contract Decision
### 任务
产出：`R2_P3_3_1_PreviewDurations_and_FSRS_Bridge_Tech_Note_v0.1.md`

### 必做
1. 判断 `previewDurations` 是否适合进入 active contract
2. 若适合，明确：
   - contract level
   - data source
   - UI exposure boundary
   - test implication
3. 判断 ReviewPage FSRS bridge 本轮应清理到哪一层
4. 明确：
   - 允许的最小技术改动
   - 不允许触碰的 DB / API / review_group contract
   - 哪些属于本轮 Minor Change，哪些会越界成 Major

### Done 定义
> Room 1 能基于该稿决定：`previewDurations = in / deferred`，以及 ReviewPage bridge 的本轮技术清理上限。

---

## 7.4 Room 4 — 先等待，不先自行开工
### 当前状态
本轮 **Room 4 暂不直接开工**。

### 原因
Room 4 当前还缺：
1. final wording freeze
2. `previewDurations` in/defer 决策
3. ReviewPage bridge 清理上限

### 下一步
待 Room 2 / Room 3 / Room 5 输入收齐后，Room 1 再产出：
- `R1_to_R4_P3_3_1_Execution_Handoff_v0.1.md`

---

## 8. 本轮验收口径（Room 1 视角）

本轮要算完成，至少要同时满足：

1. **按钮词面已冻结**
   - Room 3 + Room 5 已提交
   - Room 1 已收口为 final wording

2. **`previewDurations` 已有明确状态**
   - 要么纳入 active contract
   - 要么正式 deferred，并给出理由

3. **ReviewPage bridge 风险已收口**
   - Room 2 已明确技术边界
   - Room 3 已明确业务语义边界
   - Room 1 已决定本轮清理层级

4. **UI / 文案 / 测试补强已形成执行单**
   - Room 4 能拿单执行
   - 不需要自行猜产品 / 规则 / 技术边界

---

## 9. 当前一句话结论

> **P3.3.1 可以正式启动，但当前仍停留在 Room 1 的统一收口阶段；在 Room 2 / Room 3 / Room 5 的专项输入回来前，不直接进入 Room 4 执行。**

