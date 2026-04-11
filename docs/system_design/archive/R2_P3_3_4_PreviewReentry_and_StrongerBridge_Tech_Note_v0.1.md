# R2_P3_3_4_PreviewReentry_and_StrongerBridge_Tech_Note_v0.1

- **Owner:** Room 2
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** tech framing / contract-gate input / ready for Room 1 review
- **Role basis:** `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- **Round:** `P3.3.4 — Preview Re-entry + Stronger Bridge Round`

---

## 0. 文档定位

本稿不是：
- 新 DB 主文档
- 新 API 主文档
- Room 4 执行单
- 完整复习规划产品稿
- unified planner / planner merge 方案
- `previewDurations` 的完整 explanation system

本稿只做一件事：

> **从 Room 2 / CTO 视角，把 P3.3.4 这一轮收口到“`previewDurations` 最小 re-entry + ReviewPage stronger bridge 最小强化”的可被 Room 1 判断是否 pin 的窄技术合同层。**

一句话：

> **前进，但只前进到“可安全进入合同、且不越过 core contract”的最小子集。**

---

## 1. 输入依据与本稿采用口径

## 1.1 Governance / Role basis
- `ORG_v0.3.1.md`
- `ROOM02_ROLE_CARD_CTO_ARCHITECT_v0.2.1`
- `ROOM03_ROLE_CARD_BUSINESS_RULES_ENGINE_v0.3.1`
- `ROOM04_治理版_v0.2`
- `ROOM05_ROLE_CARD_UI_UX_v0.2.1`

## 1.2 Main-thread handoff basis
- `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md`
- `p3.3.4_user.md`

## 1.3 Review basis for this round
- `BR-OPP-001_v0.2.5.md`
- `UI_SPEC_v0.2.5.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`

## 1.4 Room 2 对当前技术底座的采用口径
当前继续明确采用以下现实：
1. **dual-store 继续成立**：cloud 继续承接 today / `review_group` / settlement 等 serving truth；local 继续承接 FSRS scheduling / review logs / local settings / 设备侧运行态。
2. **P3.3.3 已冻结的 minimal contract 继续有效**：页面级 readiness 继续以 cloud review-serving layer 为准；local FSRS 只是 scheduling candidate input。
3. **`previewDurations` 当前仍是 deferred asset**，但 P3.3.4 可以讨论它的最小 re-entry contract。
4. **ReviewPage 当前 bridge 基线仍是 `cloud-first + local side-effect + failure non-blocking`**；P3.3.4 可以讨论是否把它收紧成 stronger bridge contract，但不能误写成 planner merge。

---

## 2. Room 2 总判断

## 2.1 总结论
> **Room 2 支持 P3.3.4 从 pure preflight 前进一步，但只支持进入 very narrow minimal contract：**
> 1. `preview_durations_reentry_contract_v1`
> 2. `reviewpage_stronger_bridge_contract_v1`

## 2.2 Room 2 本轮正式推荐
### 可进入下一层最小合同的部分
1. `preview_durations_reentry_contract_v1`
   - 仅冻结 source / owner / page scope / explanation boundary / copy guardrails
2. `reviewpage_stronger_bridge_contract_v1`
   - 仅冻结 stronger ensure / observability / failure handling floor / minimal repair path
3. `preview + bridge` 的最小测试与回写合同

### 当前仍应保持 deferred / pending 的部分
1. `previewDurations` 在 ReviewPage 的正式 re-entry
2. 将 preview 写成稳定计划事实
3. planner merge / unified planner
4. mixed / auto-routing runtime
5. DB schema 重构
6. API core semantics 重构
7. 完整 preview explanation system
8. stronger bridge 直接升级成 blocking user contract

## 2.3 Room 2 一句话立场
> **P3.3.4 不应该被做成“更完整复习系统”；它只应该把一个“轻提示候选”与一个“技术灰区”收成可控合同。**

---

## 3. Q1 — `preview_durations_reentry_contract_v1`

## 3.1 Room 2 结论
> **本轮可以推进 `preview_durations_reentry_contract_v1`，但只能以 `local FSRS generated preview candidate` 的形态重回，而且当前最稳只进入 StudyPage。**

## 3.2 为什么 source of truth 不能写成 cloud serving truth
因为当前已冻结的 owner split 仍是：
- cloud `review_group` = ReviewPage serving truth
- local FSRS = device-side scheduling / candidate source

`previewDurations` 本质更接近：
- 对 rating input 的本地后续候选解释
- 设备侧 scheduling candidate 的轻量提示

它当前**不属于**：
- cloud-confirmed serving truth
- review settlement truth
- unified planner explanation
- stable next-review commitment

所以 Room 2 的正式口径是：

> **`previewDurations` 的技术 source = local FSRS candidate output；它不是 cloud serving truth，也不是当前 active review contract 的稳定事实。**

## 3.3 页面范围：Room 2 推荐 `Study only`
Room 2 当前推荐：

> **P3.3.4 若允许 re-entry，先只允许 `StudyPage only`。**

原因：
1. ReviewPage 当前主真相层仍围绕 cloud `review_group`；一旦把 preview 也放进去，用户很容易把它理解成“当前复习路径已被系统重新安排”。
2. ReviewPage 当前还叠着 stronger bridge 议题；在 stronger bridge 还没单独 pin 前，把 preview 带进 ReviewPage，会把两个 pending 风险叠在一起。
3. StudyPage 的语义更接近“这次打分后，本地调度可能怎样变化”，技术上更容易保持 candidate / hint 边界。

## 3.4 表达层级：只能是 `hint / estimated / reference-only`
Room 2 正式推荐：

> **若 re-entry，本轮必须以 `hint / estimated contract` 进入，而不是以计划事实进入。**

最小技术表达要求：
1. 它只能是 **secondary hint**，不是主反馈。
2. 它必须默认带 **“预计 / 仅供参考 / 可能”** 一类不确定性语气。
3. 它必须允许 **不显示**，而不是强制显示。
4. 它不能成为任何 reward / completion / readiness / routing 的判断依据。

## 3.5 Room 2 推荐的最小 preview 合同
### A. source 层
- source = local FSRS preview candidate
- 不要求 cloud confirm
- 不回写为当前 active API / DB truth

### B. page scope 层
- 仅 StudyPage
- ReviewPage 当前继续禁止显示

### C. explanation 层
- 只允许 estimated / hint 语气
- 只允许轻提示，不允许强承诺

### D. contract 边界
- 不进入 readiness truth
- 不进入 priority truth
- 不进入 generation truth
- 不进入 route decision
- 不进入 settlement / reward / group completion

## 3.6 本轮不应出现的误写
1. 不得写成 “下次将在 X 天后复习” 的稳定承诺
2. 不得写成 “系统已安排”
3. 不得写成 “复习计划已更新”
4. 不得写成 “云端与本地已统一”
5. 不得让 preview 参与 Study → Review 自动分流

---

## 4. Q2 — `reviewpage_stronger_bridge_contract_v1`

## 4.1 Room 2 结论
> **值得从 `controlled best-effort` 前进一步，但只值得前进一步到“minimal stronger bridge contract”；不值得前进到 blocking bridge / planner merge。**

## 4.2 为什么值得收紧
因为当前 bridge 已经从“完全放任的 silent side-effect”收到了：
- cloud-first
- local side-effect
- failure non-blocking
- dev/test 可观察

但它仍留有一层技术灰区：
- 什么时候必须先 ensure local card state
- bridge miss 的最小修复路径
- failure observability 到什么粒度才算可调试
- 哪些失败仍能接受 non-blocking，哪些失败需要更强 internal signal

这类问题继续悬空，会导致后续执行层在不改 API / DB 的前提下继续各自补脑。

## 4.3 Room 2 推荐的 stronger bridge 上限
Room 2 推荐把 stronger bridge 只冻结到以下层级：

### A. stronger ensure / init floor
在不改 API / DB major 的前提下，允许冻结：
1. ReviewPage 进入或提交前的 **idempotent local ensure**
2. local card state 缺失时的 **minimal init / ensure-local-card-state**
3. bridge side-effect 前的 **precondition gating**

但不冻结：
- 新的 cloud API handshakes
- 新的 review_group schema coupling
- 新的 planner ownership transfer

### B. observability floor
允许冻结：
1. bridge miss / ensure fail / local apply fail 的 **dev/test 可观察事件**
2. 可被测试断言的最小错误分层
3. 不影响用户主流程的内部 telemetry / debug logging / test hook

但不冻结：
- 面向用户的强错误弹窗合同
- 新的服务端 observability 协议

### C. failure handling floor
允许冻结：
1. cloud submit 不因 local bridge fail 而回滚
2. local failure 继续 non-blocking
3. failure 必须进入 **可测试、可调试、可追踪** 的 fallback path
4. fallback 后不得在 UI 上误写成“计划已稳定更新”

但不冻结：
- 用户侧强一致保证
- 云端与本地的强同步一致性承诺

### D. minimal repair path
Room 2 推荐的最小修复路径是：
1. **pre-submit ensure**
2. **post-cloud-submit local ensure + apply**
3. 若仍失败，则进入 **internal observable fallback**
4. fallback 允许在未来再次被 idempotent re-ensure / local repair 消化

这条 repair path 的重点是：
- 可重试
- 不阻断 cloud truth
- 不制造用户假事实
- 不引入新的 planner owner

## 4.4 stronger bridge 不应走到哪一层
1. 不得升级成 user-visible blocking contract
2. 不得要求 cloud 等待 local bridge 成功后才算提交成功
3. 不得把 local bridge 写成 ReviewPage serving truth owner
4. 不得把 local ensure 扩写成 planner merge handshake
5. 不得为了 stronger bridge 去改 DB schema / API core semantics

---

## 5. Q3 — `preview + bridge` 的 UI / 文案事实边界（Room 2 版）

## 5.1 Room 2 结论
> **只要本轮允许 preview re-entry，就必须同步把“preview 与 bridge 仍不是稳定计划事实”写成硬挡板。**

## 5.2 Room 2 推荐的页面边界
### StudyPage
允许：
- 轻量 preview hint
- 低强调 estimated copy
- 仅依赖 local preview candidate 的 secondary explanation

不允许：
- 变成主 CTA
- 变成强结论
- 变成 route switch 理由

### ReviewPage
当前继续建议：
- 不显示 preview
- stronger bridge 完成后也不自动解禁 preview
- 先把 stronger bridge 收紧，再决定 preview 是否未来可进 ReviewPage

## 5.3 当前仍应列为 fact-copy 硬禁区的表达
1. 系统已安排
2. 已更新计划
3. 下次将在 X 天后复习
4. 已同步复习安排
5. 已根据 FSRS 自动调整路径
6. 本地计划已接管
7. 统一规划已完成

---

## 6. Q4 — `preview + bridge` 的最小测试与回写合同

## 6.1 Room 2 结论
> **若 Room 1 未来 pin 本轮最小合同，测试与回写必须作为合同内建项，而不是 closeout 后补。**

## 6.2 Room 2 推荐冻结的最小测试集合
### Preview
1. StudyPage 可显示 / 不显示断言
2. Preview source 来自 local FSRS candidate，而不是 cloud readiness truth
3. Preview 不影响 routing / readiness / completion
4. ReviewPage 继续不显示 preview

### Stronger bridge
5. stronger ensure / init 行为断言
6. bridge miss 进入 observable fallback 的断言
7. local failure non-blocking 的断言
8. 不改变 cloud submit success semantics 的断言

### Copy boundary
9. preview / bridge 不越 fact-copy 禁区的断言
10. 不出现 planner merge / unified planner 假事实的断言

## 6.3 Room 2 推荐冻结的最小回写集合
若本轮未来进入 execution 并落地，至少应准备：
1. BR patch draft
2. UI patch draft
3. 必要时补一份非常小的 API / DB “no contract change note”
4. Room 4 closeout 中的 affected-files + no-major-change statement

---

## 7. 越界红线（Room 2 版）

以下动作一旦出现，Room 2 视为越界，不属于 P3.3.4 minimal contract：

1. 把 preview 写成 stable plan fact
2. 让 preview 进入 ReviewPage 且被表述成 serving truth
3. 让 preview 参与 auto-routing / CTA winner / Study-Review dispatch
4. 为 stronger bridge 改 DB schema
5. 为 stronger bridge 改 API core semantics
6. 让 cloud submit success 依赖 local bridge success
7. 把 local FSRS 写成 ReviewPage truth owner
8. 把 stronger bridge 扩写成 planner merge / unified planner
9. 把 stronger bridge 顺手带成完整 explanation product

---

## 8. Room 2 推荐 Room 1 可 pin 的最小合同集合

## 8.1 可 pin 的最小子集
### Contract Set A — Preview Re-entry Minimal
1. source = local FSRS preview candidate
2. scope = StudyPage only
3. mode = hint / estimated / reference-only
4. ReviewPage 当前继续禁止 preview
5. preview 不得参与 readiness / routing / settlement / generation truth

### Contract Set B — Stronger Bridge Minimal
1. stronger ensure / init 可进入合同
2. bridge observability 可进入合同
3. bridge failure handling floor 可进入合同
4. minimal repair path 可进入合同
5. 继续保持 cloud submit first + local non-blocking fallback

### Contract Set C — Test / Writeback Minimal
1. preview 显示 / 禁显断言
2. stronger bridge 行为断言
3. copy 不越界断言
4. patch / sync plan 必须内建

## 8.2 当前不建议 pin 的子集
1. preview Study + Review 双页回归
2. preview 作为 stable plan statement
3. user-visible stronger bridge hard guarantee
4. planner merge / unified planner
5. API / DB major changes

## 8.3 Room 2 一句话判断
> **P3.3.4 最稳的收口方式，是把 `previewDurations` 作为 StudyPage 的 local estimated hint 收回来，把 ReviewPage bridge 收紧到更强但仍 non-blocking 的技术合同；除此之外一律不扩。**

---

## 9. 对 Room 4 的预判边界（仅供 Room 1 后续判断，不是执行单）

若 Room 1 未来决定发给 Room 4，本轮 Room 4 只应被允许做：
1. StudyPage preview minimal re-entry
2. ReviewPage stronger bridge minimal hardening
3. preview / bridge tests
4. patch drafts

不应被允许做：
1. ReviewPage preview 回归
2. auto-routing
3. planner merge
4. DB / API 重构
5. 完整 review explanation product

