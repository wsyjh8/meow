# R1_to_R4_P3_3_4_Execution_Handoff_v0.1

- **Owner:** Room 1
- **Project:** 背单词喵喵 App
- **Version:** v0.1
- **Date:** 2026-04-10
- **Status:** execution handoff / ready for Room4-治理层
- **Role basis:** `room1_v0.2.0.md`
- **Governance basis:** `ORG_v0.3.1.md`
- **Runtime basis used for this round:** `Main_updated_2026-04-10_v24.md` + `STATUS_updated_2026-04-10_v22.md`
- **Direct upstream inputs:**
  - `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md`
  - `R2_P3_3_4_PreviewReentry_and_StrongerBridge_Tech_Note_v0.1.md`
  - `R3_P3_3_4_PreviewReentry_and_StrongerBridge_Rules_Note_v0.1.md`
  - `UI_SPEC_P3_3_4_PreviewReentry_and_StrongerBridge_UI_Preflight_v0.1.md`
  - `BR-OPP-001_v0.2.5.md`
  - `UI_SPEC_v0.2.5.md`

---

## 0. 文档目的

本文件由 **Room 1** 产出，用于把 P3.3.4 这轮已经完成 cross-room 收口的内容，
正式压成一份可交给 **Room4-治理层** 的统一执行任务单。

本文件不是：
- 新 PRD
- 新 BR 主文档
- 新 DB / API 主文档
- Room 4 的 closeout
- 完整复习规划产品稿

本文件只做一件事：

> **把 P3.3.4 已被 Room 2 / Room 3 / Room 5 收成一致的“preview 最小回归 + stronger bridge 最小强化”压成一份短而硬、边界明确、可测试、可回写的执行 handoff。**

---

## 1. Room 1 吸收后的统一结论

### 1.1 `preview_durations_reentry_contract_v1`（本轮允许进入执行）
Room 1 现正式 pin 以下最小合同：

1. `previewDurations` 当前若回归，**source = local FSRS preview candidate**
2. 它**不是** cloud serving truth
3. 它**不是**稳定计划事实
4. 它当前**只允许进入 StudyPage**
5. 它当前**继续禁止进入 ReviewPage / 首页**
6. 它只能以 **hint / estimated / reference-only** 形态出现
7. 它必须显式带 **“预计 / 仅供参考”** 语气
8. 它不得参与：
   - readiness truth
   - priority truth
   - generation truth
   - route decision
   - settlement / reward / group completion

### 1.2 Preview 当前允许的最小 UI 形态
Room 1 现正式接受：

- 页面：**StudyPage only**
- 位置：**4 按钮区下方一行极轻 secondary hint**
- 强度：低强调 / 中性 / 不抢主反馈
- 推荐文案范式：
  - `预计间隔：1 天（仅供参考）`
  - `预计间隔：3 天（仅供参考）`
  - `预计间隔：7 天（仅供参考）`

### 1.3 Preview 当前明确禁止
以下当前继续写死为禁区：

1. ReviewPage 显示 preview
2. 首页显示 preview
3. 写成“下次将在 X 天后复习”
4. 写成“系统已安排”
5. 写成“已更新计划”
6. 写成“已同步复习安排”
7. 写成“云端与本地已统一”
8. 让 preview 参与 Study → Review 自动分流
9. 让 preview 进入 API / DB active contract
10. 让 preview 变成完整 explanation system

### 1.4 `reviewpage_stronger_bridge_contract_v1`（本轮允许进入执行）
Room 1 现正式 pin 以下最小 stronger bridge 合同：

#### A. stronger ensure / init floor
允许进入：
1. ReviewPage 进入或提交前的 **idempotent local ensure**
2. local card state 缺失时的 **minimal init / ensure-local-card-state**
3. bridge side-effect 前的 **precondition gating**

#### B. observability floor
允许进入：
1. bridge miss / ensure fail / local apply fail 的 **dev/test 可观察事件**
2. 可被测试断言的最小错误分层
3. 不影响用户主流程的内部 telemetry / debug logging / test hook

#### C. failure handling floor
允许进入：
1. cloud submit success 不因 local bridge fail 而回滚
2. local failure 继续 non-blocking
3. failure 必须进入 **可测试 / 可调试 / 可追踪** 的 fallback path
4. fallback 后不得在 UI 上误写成“计划已稳定更新”

#### D. minimal repair path
Room 1 现吸收 Room 2 推荐路径：

1. **pre-submit ensure**
2. **post-cloud-submit local ensure + apply**
3. 若仍失败，则进入 **internal observable fallback**
4. fallback 允许在未来再次被 idempotent re-ensure / local repair 消化

### 1.5 Stronger bridge 当前明确禁止
以下当前继续写死为禁区：

1. must-succeed bridge
2. 因 local bridge fail 回滚 cloud submit
3. 阻断 next item / group completion / settlement 主链路
4. 把 local FSRS 写成 ReviewPage truth owner
5. 把 stronger bridge 写成 planner owner shift
6. 把 stronger bridge 写成 planner merge / unified planner
7. 为 stronger bridge 改 DB schema
8. 为 stronger bridge 改 API core semantics
9. 产生任何用户可依赖计划事实

---

## 2. 本轮一句话定义

> **P3.3.4 本轮不是做更完整复习系统，而是把 `previewDurations` 从 deferred 推进到 StudyPage first-shot 的 estimated hint 候选，并把 ReviewPage bridge 从 `controlled best-effort` 收紧到 stronger-but-still-non-blocking 的最小技术合同。**

---

## 3. 给 Room4-治理层的任务定义

### 3.1 目标
完成 P3.3.4 的 very narrow landing，具体包括：

1. 在 StudyPage 以最小合同方式引入 preview hint
2. 保持 ReviewPage / 首页继续不显示 preview
3. 将 ReviewPage bridge 从 `controlled best-effort` 收紧到最小 stronger bridge
4. 补齐 preview / bridge 的文案禁区与测试断言
5. 交回 patch / sync draft 与 no-major-change statement

### 3.2 In Scope
1. StudyPage preview hint re-entry
2. preview source 只取 local FSRS preview candidate
3. preview 只以 estimated / reference-only secondary hint 出现
4. ReviewPage 继续不显示 preview
5. 首页继续不显示 preview
6. stronger ensure / init
7. bridge observability floor
8. failure handling floor
9. minimal repair path
10. 文案禁区收口
11. 最小测试补强
12. BR / UI patch draft
13. 必要时补一份 API / DB no-contract-change note

### 3.3 Out of Scope
1. mixed / auto-routing runtime
2. unified planner / planner merge
3. unified Study / Review page
4. exact group size contract
5. full priority scoring
6. 完整 SRS / 完整复习调度产品
7. 完整 preview explanation system
8. 完整 planner explanation product
9. DB schema 重构
10. API core semantics 重构
11. ReviewPage preview re-entry
12. preview 参与 routing / readiness / settlement

---

## 4. 必守依据

Room4-治理层与执行层，本轮必须同时服从以下依据：

### 4.1 推进层 / 主线程
- `Main_updated_2026-04-10_v24.md`
- `STATUS_updated_2026-04-10_v22.md`
- `R1_P3_3_4_ScopePin_and_Handoff_Pack_v0.1.md`

### 4.2 规则 / 事实边界
- `BR-OPP-001_v0.2.5.md`
- `R3_P3_3_4_PreviewReentry_and_StrongerBridge_Rules_Note_v0.1.md`

### 4.3 技术边界
- `R2_P3_3_4_PreviewReentry_and_StrongerBridge_Tech_Note_v0.1.md`
- `背单词喵喵app_DB设计草案_v0.2.1.md`
- `背单词喵喵app_API设计草案_v0.2.1.md`

### 4.4 UI / UX 表达边界
- `UI_SPEC_v0.2.5.md`
- `UI_SPEC_P3_3_4_PreviewReentry_and_StrongerBridge_UI_Preflight_v0.1.md`

---

## 5. Room 4 不得补脑的已收口项

以下点本轮 Room 1 已收口，Room 4 不得二次发明：

1. preview 只允许 **StudyPage only**
2. preview 只允许 **hint / estimated / reference-only**
3. preview source 只允许 **local FSRS preview candidate**
4. ReviewPage 继续 **禁止 preview**
5. stronger bridge 继续 **non-blocking**
6. stronger bridge 只允许收紧到：
   - stronger ensure / init
   - observability
   - failure handling floor
   - minimal repair path
7. deeper planner / merge / routing 继续 pending

---

## 6. Room 4 执行护栏

### 6.1 Preview 文案 / 事实护栏
当前允许的表达风格：
- `预计间隔：1 天（仅供参考）`
- `预计间隔：3 天（仅供参考）`
- `预计间隔：7 天（仅供参考）`

当前禁止的表达：
- 下次将在 X 天后复习
- 系统已安排
- 已更新计划
- 已同步复习安排
- 已根据 FSRS 自动调整路径
- 本地计划已接管
- 统一规划已完成
- 已切换到最佳复习模式
- 已为你确认最佳复习路径

### 6.2 Preview 页面护栏
1. 只允许 StudyPage 显示
2. ReviewPage 不得显示
3. 首页不得显示
4. 只能放在 4 按钮区下方极轻 secondary hint
5. 不得变成主 CTA
6. 不得变成主反馈
7. 不得变成 route switch 理由

### 6.3 Stronger bridge 技术护栏
1. cloud submit first remains hard rule
2. local bridge / ensure 仍然 second
3. local failure 仍 non-blocking
4. stronger bridge 不得改变 cloud truth owner
5. stronger bridge 不得写成 planner merge handshake
6. stronger bridge 不得要求 user-visible blocking success
7. stronger bridge 不得引入 API / DB core change

### 6.4 用户体验护栏
1. stronger bridge failure 仍不弹用户错误
2. 不新增结果型用户文案
3. 不把内部 repair / fallback 写成成功计划事实
4. 对用户保持“温柔无惊扰”，对 dev/test 保持“可见可断言”

---

## 7. 必测项

Room 4 本轮至少覆盖以下测试 / 自测：

### 7.1 Preview 显示 / 不显示
1. StudyPage 在 contract 满足时，preview 可显示
2. StudyPage 在 contract 不满足时，preview 不显示
3. ReviewPage 始终不显示 preview
4. 首页不显示 preview

### 7.2 Preview source / contract
1. preview source 来自 local FSRS candidate，而不是 cloud readiness truth
2. preview 不影响 routing / readiness / completion
3. preview 不进入 reward / settlement / generation truth
4. preview 不被写入 active API / DB contract

### 7.3 Preview 文案边界
1. preview 必须包含“预计 / 仅供参考”语气
2. preview 不得出现“下次将在 X 天后复习”
3. preview 不得出现“系统已安排 / 已更新计划 / 已同步复习安排”
4. preview 不得出现 planner merge / unified planner 假事实

### 7.4 Stronger bridge 行为
1. pre-submit ensure 行为断言
2. post-cloud-submit local ensure + apply 行为断言
3. bridge miss 进入 observable fallback 的断言
4. local failure non-blocking 的断言
5. stronger bridge 不改变 cloud-first 主链路
6. stronger bridge 不引入新的结果型用户文案
7. stronger bridge 的 dev/test 可观测性保留

---

## 8. 交付物要求

Room4-治理层交回时，至少要包含：

1. **受影响文件清单**
2. **改动摘要**
3. **测试结果 / 自测结果**
4. **preview source / scope / copy boundary 是否守住**
5. **bridge fallback 如何可观察**
6. **是否触碰核心契约的判断**
7. **no-major-change statement**
8. **需要哪些文档回写**
   - BR / UI / Main / Status / 其他
9. **是否可 close / 是否需 revise / 是否需 escalate**

---

## 9. Room 1 预期完成定义（Done）

当 Room4-治理层交回结果，且满足以下条件时，Room 1 认为 P3.3.4 本轮可以进入 absorb / close 判断：

1. StudyPage preview 已按最小合同落地
2. ReviewPage / 首页继续不显示 preview
3. preview 明确是 estimated hint，而不是计划事实
4. ReviewPage bridge 已收紧到 stronger-but-still-non-blocking
5. dev/test 可观察性与最小 repair path 已交付
6. 文案禁区未被越界
7. 未触碰 DB schema / API core semantics / planner owner / planner merge

---

## 10. 一句话 handoff

> **请 Room4-治理层按“StudyPage only 的 estimated preview hint + stronger-but-still-non-blocking bridge”这一 very narrow minimal contract 推进 P3.3.4；不要把本轮做成完整复习规划产品，也不要把 preview 或 stronger bridge 写成稳定计划事实。**
